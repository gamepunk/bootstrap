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

  # Step 3: Check for changes in source repo
  cd "$_CHEZMOI_SOURCE" || return 1

  if git diff --quiet && git diff --cached --quiet; then
    echo "✓  No changes to commit"
    return 0
  fi

  # Show what changed
  echo ""
  echo "── Changes ──────────────────────────────"
  git diff --stat --cached 2>/dev/null
  git diff --stat 2>/dev/null
  echo "──────────────────────────────────────────"

  if $dry_run; then
    echo "🔍  Dry-run: skipping commit & push"
    return 0
  fi

  # Step 4: Commit and push
  echo ""
  git add -A
  if git commit -m "$msg

  Co-Authored-By: Claude <noreply@anthropic.com>" 2>&1; then
    echo "✓  Committed: $msg"
  else
    echo "✕  Commit failed" >&2
    return 1
  fi

  if git push 2>&1; then
    echo "✓  Pushed to remote"
  else
    echo "✕  Push failed" >&2
    return 1
  fi

  echo ""
  echo "✅  Dotfiles updated successfully"
}
