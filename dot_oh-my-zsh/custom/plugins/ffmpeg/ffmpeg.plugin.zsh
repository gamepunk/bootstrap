# ffmpeg.plugin.zsh
# 简易 ffmpeg 快捷命令插件
# 用法: ff [选项] <文件1> [文件2 ...]

_ff_usage() {
  cat <<'EOF'
用法: ff [选项] <文件...>

按宽度等比缩放视频 (默认宽 1080，高度自动)，
再将高度居中裁切到目标高度 (默认 1920，上下对称裁切多余部分)。
支持传入多个文件，依次处理。

选项:
  -w, --width   <px>     目标宽度 (默认 1080)
  -h, --height  <px>     裁切后的目标高度 (默认 1920)
  -c, --crf     <n>      画质 CRF 值 (默认 23，越小画质越好)
  -p, --preset  <name>   编码速度预设 (默认 medium)
  --no-copy-audio        重新编码音频而非直接拷贝

注意: 若原视频缩放后高度本身就小于目标高度 (即视频偏"宽"而非"窄长"),
      则不会裁切，输出高度会小于设定的目标高度。

输出命名: <输入文件名>_<时间戳>.mp4，保存到输入文件所在目录
          (如 input_20260727_153012.mp4)

示例:
  ff video1.mp4                          # 处理单个文件
  ff video1.mp4 video2.mp4               # 依次处理多个文件
  ff -w 720 -h 1280 video.mp4            # 自定义尺寸
  ff -c 20 -p fast /videos/a.mp4         # 自定义画质与编码速度
EOF
}

ff() {
  local width=1080 height=1920 crf=23 preset="medium"
  local audio_copy=1
  local inputs=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -w|--width)   width="$2";  shift 2 ;;
      -h|--height)  height="$2"; shift 2 ;;
      -c|--crf)     crf="$2";    shift 2 ;;
      -p|--preset)  preset="$2"; shift 2 ;;
      --no-copy-audio) audio_copy=0; shift ;;
      --help)
        _ff_usage
        return 0
        ;;
      -*)
        echo "ff: 未知参数 '$1'" >&2
        _ff_usage
        return 1
        ;;
      *)
        inputs+=("$1")
        shift
        ;;
    esac
  done

  if [[ ${#inputs[@]} -eq 0 ]]; then
    _ff_usage
    return 0
  fi

  local audio_args=(-c:a copy)
  [[ $audio_copy -eq 0 ]] && audio_args=(-c:a aac -b:a 192k)

  local total=${#inputs[@]}
  local idx=0

  for input in "${inputs[@]}"; do
    idx=$((idx + 1))

    if [[ ! -f "$input" ]]; then
      echo "ff: 找不到输入文件 '$input'，跳过" >&2
      continue
    fi

    local base="${input:t:r}"           # 去掉路径和扩展名，只保留文件名
    local dir="${input:h}"              # 输入文件所在目录
    local ts="$(date +%Y%m%d_%H%M%S)"   # 时间戳，例如 20260727_153012
    local output="${dir}/${base}_${ts}.mp4"

    echo "========================================"
    echo "▶ [${idx}/${total}] 处理: $input"
    echo "▶ 输出:  $output"
    echo "▶ 尺寸:  ${width}x${height}"
    echo "▶ CRF:   $crf   预设: $preset"
    echo "========================================"
    echo

    ffmpeg -hide_banner -loglevel warning -stats \
      -i "$input" \
      -vf "scale=${width}:-2:flags=lanczos,crop=${width}:min(ih\,${height}):0:(ih-min(ih\,${height}))/2" \
      -c:v libx264 -crf "$crf" -preset "$preset" \
      "${audio_args[@]}" \
      "$output"

    if [[ $? -ne 0 ]]; then
      echo "ff: 处理 '$input' 时出错" >&2
    fi
  done
}
