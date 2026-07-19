# Chezmoi dotfile management plugin
#
# Commands:
#   czu [msg]          Re-add all managed files, commit & push
#   czu --brew [msg]   Also regenerate Brewfile before updating
#   czu --dry          Dry-run: show what would change without committing
#   czs                chezmoi status (shortcut)
#   czd                cd to chezmoi source directory

_CHEZMOI_SOURCE=$(chezmoi source-path 2>/dev/null)

# ── Shortcuts ───────────────────────────────────────────
alias czs='chezmoi status'
alias czd="cd $_CHEZMOI_SOURCE"

# ── Main update function ────────────────────────────────
function czu() {
  local with_brew=false
  local dry_run=false
  local msg=""

  # Parse flags
  for arg in "$@"; do
    case "$arg" in
      --brew) with_brew=true ;;
      --dry)  dry_run=true ;;
      *)      msg="$arg" ;;
    esac
  done

  # Default commit message
  if [[ -z "$msg" ]]; then
    msg="chore: update dotfiles"
  fi

  # Step 1: Regenerate Brewfile if requested
  if $with_brew; then
    echo "⟳  Regenerating Brewfile..."
    brew bundle dump --file="$HOME/.config/brew/Brewfile" --force 2>&1 || {
      echo "✕  Brewfile dump failed" >&2
      return 1
    }
    echo "✓  Brewfile regenerated"
  fi

  # Step 2: Re-add all chezmoi-managed files
  echo "⟳  Re-adding all managed files..."
  local failed=0
  while IFS= read -r target; do
    chezmoi re-add "$target" 2>/dev/null || ((failed++))
  done < <(chezmoi managed --path-style=absolute 2>/dev/null)

  if (( failed > 0 )); then
    echo "⚠  $failed file(s) failed to re-add" >&2
  fi
  echo "✓  Files re-added"

  # Step 3: Commit and push (in subshell to avoid cd side-effect)
  (
    cd "$_CHEZMOI_SOURCE" || exit 1

    if git diff --quiet && git diff --cached --quiet; then
      echo "✓  No changes to commit"
      exit 0
    fi

    echo ""
    echo "── Changes ──────────────────────────────"
    git diff --stat --cached 2>/dev/null
    git diff --stat 2>/dev/null
    echo "──────────────────────────────────────────"

    if $dry_run; then
      echo "🔍  Dry-run: skipping commit & push"
      exit 0
    fi

    echo ""
    git add -A
    git commit -m "$msg

  Co-Authored-By: Claude <noreply@anthropic.com>" 2>&1 || {
      echo "✕  Commit failed" >&2
      exit 1
    }

    git push 2>&1 || {
      echo "✕  Push failed" >&2
      exit 1
    }

    echo "✓  Committed: $msg"
    echo "✓  Pushed to remote"
  ) || return 1

  echo ""
  echo "✅  Dotfiles updated successfully"
}
