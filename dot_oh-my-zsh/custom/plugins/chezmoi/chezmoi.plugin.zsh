# Chezmoi dotfile management plugin
#
# Commands:
#   czu [msg]   Regenerate Brewfile, re-add all managed files, commit & push
#   czs         chezmoi status (shortcut)
#   czd         cd to chezmoi source directory

# ── Shortcuts ───────────────────────────────────────────
alias czs='chezmoi status'

# czd is a function (not a static alias) so the source path is
# re-resolved every time it's called, instead of being frozen at shell
# startup (which could silently `cd` to $HOME if chezmoi wasn't ready yet).
#
# If an older version of this plugin defined `czd` as an alias and is
# still loaded in the current session, zsh will try to expand that
# alias while parsing the `czd() { ... }` definition below and throw
# a parse error ("defining function based on alias `czd'"). Explicitly
# unalias it first so re-sourcing this file in an existing shell works.
unalias czd 2>/dev/null

czd() {
  local src
  if ! command -v chezmoi >/dev/null 2>&1; then
    echo "✕  chezmoi not found in PATH" >&2
    return 1
  fi
  src=$(chezmoi source-path 2>/dev/null)
  if [[ -z "$src" ]]; then
    echo "✕  Could not determine chezmoi source path" >&2
    return 1
  fi
  cd "$src" || return 1
}

# ── Main update function ────────────────────────────────
function czu() {
  local msg="${1:-chore: update dotfiles}"
  local src

  # Pre-flight checks
  if ! command -v chezmoi >/dev/null 2>&1; then
    echo "✕  chezmoi not found in PATH" >&2
    return 1
  fi
  src=$(chezmoi source-path 2>/dev/null)
  if [[ -z "$src" ]]; then
    echo "✕  Could not determine chezmoi source path" >&2
    return 1
  fi

  # Step 1: Regenerate Brewfile
  if command -v brew >/dev/null 2>&1; then
    echo "⟳  Regenerating Brewfile..."
    if brew bundle dump --file="$HOME/.config/brew/Brewfile" --force 2>&1; then
      echo "✓  Brewfile regenerated"
    else
      echo "✕  Brewfile dump failed" >&2
      return 1
    fi
  else
    echo "⚠  brew not found, skipping Brewfile regeneration" >&2
  fi

  # Step 2: Re-add all chezmoi-managed files
  # (a single `chezmoi re-add` call handles all managed files; no need
  # to loop and fork a process per file)
  echo "⟳  Re-adding all managed files..."
  if chezmoi re-add 2>&1; then
    echo "✓  Files re-added"
  else
    echo "⚠  Some files may have failed to re-add" >&2
  fi

  # Step 3: Commit and push (in subshell to avoid cd side-effect)
  (
    cd "$src" || exit 1

    # Disable pager so `git diff --stat` doesn't drop into `less`
    # and block the script waiting for a keypress.
    export GIT_PAGER=cat

    git add -A

    # Check for staged changes *after* `git add -A`, so newly created
    # (previously untracked) files are correctly detected.
    if git diff --cached --quiet; then
      echo "✓  No changes to commit"
      exit 0
    fi

    echo ""
    echo "── Changes ──────────────────────────────"
    git diff --stat --cached
    echo "──────────────────────────────────────────"
    echo ""

    if ! git commit --no-edit \
      -m "$msg" \
      -m "Co-Authored-By: Claude <noreply@anthropic.com>" 2>&1; then
      echo "✕  Commit failed" >&2
      exit 1
    fi

    if ! git push 2>&1; then
      echo "✕  Push failed" >&2
      exit 1
    fi

    echo "✓  Committed: $msg"
    echo "✓  Pushed to remote"
  ) || return 1

  echo ""
  echo "✓  Dotfiles updated successfully"
}