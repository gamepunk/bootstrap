# ffmpeg.plugin.zsh
# 简易 ffmpeg 快捷命令插件
# 用法: ff <子命令> [参数...]

_ff_usage() {
  cat <<'EOF'
用法: ff <子命令> [参数...]

子命令:
  scale <input> [output] [选项]
      按宽度等比缩放视频 (默认宽 1080，高度自动)，
      再将高度居中裁切到目标高度 (默认 1920，上下对称裁切多余部分)

      不指定 output 时，默认输出到与输入文件相同的目录，
      文件名为: <输入文件名>_<时间戳>.mp4 (如 input_20260727_153012.mp4)

      选项:
        -w, --width   <px>     目标宽度 (默认 1080)
        -h, --height  <px>     裁切后的目标高度 (默认 1920)
        -c, --crf     <n>      画质 CRF 值 (默认 23，越小画质越好)
        -p, --preset  <name>   编码速度预设 (默认 medium)
        --no-copy-audio        重新编码音频而非直接拷贝

      注意: 若原视频缩放后高度本身就小于目标高度 (即视频偏"宽"而非"窄长"),
            则不会裁切，输出高度会小于设定的目标高度。

      示例:
        ff scale input.mp4                     # 自动命名: input_时间戳.mp4，输出到 input.mp4 所在目录
        ff scale /videos/a.mp4                 # 输出为 /videos/a_时间戳.mp4
        ff scale input.mp4 out.mp4             # 手动指定输出文件名
        ff scale input.mp4 out.mp4 -w 1080 -h 1920 -c 20

  help
      显示此帮助信息
EOF
}

_ff_scale() {
  local input="" output=""
  local width=1080 height=1920 crf=23 preset="medium"
  local audio_copy=1

  # 第一个非选项参数是 input
  if [[ -n "$1" && "$1" != -* ]]; then
    input="$1"
    shift
  fi
  # 第二个非选项参数是 output（如果存在且不是选项）
  if [[ -n "$1" && "$1" != -* ]]; then
    output="$1"
    shift
  fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -w|--width)   width="$2";  shift 2 ;;
      -h|--height)  height="$2"; shift 2 ;;
      -c|--crf)     crf="$2";    shift 2 ;;
      -p|--preset)  preset="$2"; shift 2 ;;
      --no-copy-audio) audio_copy=0; shift ;;
      *)
        echo "ff: 未知参数 '$1'" >&2
        return 1
        ;;
    esac
  done

  if [[ -z "$input" ]]; then
    echo "ff scale: 缺少输入文件" >&2
    _ff_usage
    return 1
  fi

  if [[ ! -f "$input" ]]; then
    echo "ff scale: 找不到输入文件 '$input'" >&2
    return 1
  fi

  if [[ -z "$output" ]]; then
    local base="${input:t:r}"          # 去掉路径和扩展名，只保留文件名
    local dir="${input:h}"             # 输入文件所在目录
    local ts="$(date +%Y%m%d_%H%M%S)"  # 时间戳，例如 20260727_153012
    output="${dir}/${base}_${ts}.mp4"
  fi

  local audio_args=(-c:a copy)
  [[ $audio_copy -eq 0 ]] && audio_args=(-c:a aac -b:a 192k)

  echo "▶ 输入:  $input"
  echo "▶ 输出:  $output"
  echo "▶ 尺寸:  ${width}x${height}"
  echo "▶ CRF:   $crf   预设: $preset"
  echo

  ffmpeg -i "$input" \
    -vf "scale=${width}:-2:flags=lanczos,crop=${width}:min(ih\,${height}):0:(ih-min(ih\,${height}))/2" \
    -c:v libx264 -crf "$crf" -preset "$preset" \
    "${audio_args[@]}" \
    "$output"
}

ff() {
  if [[ $# -eq 0 ]]; then
    _ff_usage
    return 0
  fi

  local cmd="$1"
  shift

  case "$cmd" in
    scale)
      _ff_scale "$@"
      ;;
    help|-h|--help)
      _ff_usage
      ;;
    *)
      echo "ff: 未知子命令 '$cmd'" >&2
      _ff_usage
      return 1
      ;;
  esac
}