#!/usr/bin/env ruby
# frozen_string_literal: true

# ============================================================
# xbar 元数据（用于插件管理面板显示）
# ============================================================
# <xbar.title>Crypto & Stock Ticker</xbar.title>
# <xbar.version>v1.0</xbar.version>
# <xbar.author>You</xbar.author>
# <xbar.author.github>you</xbar.author.github>
# <xbar.desc>状态栏轮播显示自选股票和加密货币价格（30秒刷新）</xbar.desc>
# <xbar.dependencies>ruby</xbar.dependencies>

require "json"
require "net/http"
require "uri"
require "tmpdir"
require "time"

# ============================================================
# 📝 在这里修改你的自选行情配置
# ============================================================

STOCK_SYMBOLS = %w[
  AAPL
  TSLA
  NVDA
  MSFT
  IBKR
]

CRYPTO_SYMBOLS = {
  "BTCUSDT" => "BTC",
  "ETHUSDT" => "ETH",
  "SOLUSDT" => "SOL",
  "DOGEUSDT" => "DOGE"
}

CACHE_FILE = File.join(Dir.tmpdir, "xbar_price_cache.json")
CACHE_TTL = 25

def http_get(url)
  uri = URI(url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.open_timeout = 10
  http.read_timeout = 10

  req = Net::HTTP::Get.new(uri)
  req["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"

  res = http.request(req)
  return nil unless res.is_a?(Net::HTTPSuccess)

  JSON.parse(res.body)
rescue StandardError
  nil
end

def fetch_stock(symbol)
  url = "https://query1.finance.yahoo.com/v8/finance/chart/#{symbol}?interval=2m&range=1d"
  data = http_get(url)

  meta = data&.dig("chart", "result", 0, "meta")
  return nil unless meta

  price = meta["regularMarketPrice"]
  old = meta["previousClose"]
  return nil unless price

  {
    price: price,
    change: old && old != 0 ? ((price - old) / old * 100) : 0
  }
rescue StandardError
  nil
end

def fetch_crypto
  symbols = CRYPTO_SYMBOLS.keys.to_json
  url = "https://api.binance.com/api/v3/ticker/24hr?symbols=#{URI.encode_www_form_component(symbols)}"

  data = http_get(url)
  return {} unless data.is_a?(Array)

  result = {}
  data.each do |item|
    next unless item["symbol"] && item["lastPrice"]
    result[item["symbol"]] = {
      price: item["lastPrice"].to_f,
      change: item["priceChangePercent"].to_f
    }
  end
  result
rescue StandardError
  {}
end

def load_cache
  return nil unless File.exist?(CACHE_FILE)
  JSON.parse(File.read(CACHE_FILE), symbolize_names: true)
rescue StandardError
  nil
end

def save_cache(data)
  File.write(CACHE_FILE, JSON.generate(data))
rescue StandardError
  nil
end

def get_all_data
  cache = load_cache
  now = Time.now.to_f

  if cache && (now - cache[:time].to_f) < CACHE_TTL
    return cache[:items]
  end

  items = []

  STOCK_SYMBOLS.each do |symbol|
    data = fetch_stock(symbol)
    items << {
      name: symbol,
      price: data&.dig(:price),
      change: data&.dig(:change),
      url: "https://finance.yahoo.com/quote/#{symbol}"
    }
  end

  crypto_data = fetch_crypto
  CRYPTO_SYMBOLS.each do |symbol, name|
    data = crypto_data[symbol]
    items << {
      name: name,
      price: data&.dig(:price),
      change: data&.dig(:change),
      url: "https://www.binance.com/en/trade/#{symbol}"
    }
  end

  save_cache({ time: now, items: items })
  items
end

# ============================================================
# 价格格式化：固定7个字符
# ============================================================
def format_price(price)
  return "   N/A" unless price

  formatted = if price >= 1000
    k_price = price / 1000.0
    if k_price >= 100
      "$#{format('%.1f', k_price)}K"
    elsif k_price >= 10
      "$#{format('%.2f', k_price)}K"
    else
      "$#{format('%.3f', k_price)}K"
    end
  elsif price >= 1
    if price >= 100
      "$#{format('%.2f', price)}"
    else
      "$#{format('%.3f', price)}"
    end
  elsif price >= 0.01
    "$#{format('%.4f', price)}"
  else
    "$#{format('%.6f', price)}"
  end

  while formatted.length < 7
    formatted += "0"
  end

  formatted[0, 7]
end

def triangle(change)
  return "◉" unless change
  change >= 0 ? "▲" : "▼"
end

def print_ticker_line(name, price, change)
  tri = triangle(change)
  name_str = name.ljust(4)
  price_str = format_price(price)

  puts "#{tri} #{name_str} #{price_str} | font=Menlo size=13"
end

def print_menu_line(name, price, change, url)
  tri = triangle(change)
  name_str = name.ljust(4)
  price_str = format_price(price)

  if change
    change_str = format("%+.2f%%", change)
    puts "#{tri} #{name_str} #{price_str} #{change_str} | font=Menlo size=14 href=#{url}"
  else
    puts "#{tri} #{name_str} #{price_str}   N/A | font=Menlo size=14 href=#{url}"
  end
end

def main
  items = get_all_data

  if items.empty?
    puts "◉ 获取数据失败 | font=Menlo size=13"
    puts "---"
    puts "请检查网络连接"
    puts "重试 | refresh=true"
    return
  end

  items.each do |item|
    print_ticker_line(item[:name], item[:price], item[:change])
  end

  puts "---"

  items.each do |item|
    if item[:url]
      print_menu_line(item[:name], item[:price], item[:change], item[:url])
    end
  end

  puts "---"
  puts "立即刷新 | refresh=true"
  puts "更新时间: #{Time.now.strftime('%H:%M:%S')}"
end

main if __FILE__ == $PROGRAM_NAME