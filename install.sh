#!/usr/bin/env bash
# Install abaqus-remote:
#   - abq_server.py into %USERPROFILE%\.abq_remote (or $ABQ_REMOTE), with inbox/outbox
#   - the `abq` command into ~/.local/bin
#   - the /abq skill for every AI coding CLI found (Claude Code, Codex, Gemini CLI)
# usage: ./install.sh [--no-agents]
set -e
cd "$(dirname "$(readlink -f "$0")")"
REPO=$(pwd)
command -v powershell.exe >/dev/null || { echo "powershell.exe not found - this tool needs WSL on Windows"; exit 1; }
if [ -z "$ABQ_REMOTE" ]; then
  win_home=$(cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r')
  ABQ_REMOTE="$(wslpath "$win_home")/.abq_remote"
fi
mkdir -p "$ABQ_REMOTE/inbox" "$ABQ_REMOTE/outbox"
cp server/abq_server.py "$ABQ_REMOTE/abq_server.py"
chmod +x abq.sh
echo "Server:  $(wslpath -w "$ABQ_REMOTE")\\abq_server.py"

# `abq` command on PATH (a link, so `git pull` updates it)
mkdir -p "$HOME/.local/bin"
ln -sf "$REPO/abq.sh" "$HOME/.local/bin/abq"
echo "Command: ~/.local/bin/abq -> $REPO/abq.sh"
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *)
  echo "         (add to ~/.bashrc:  export PATH=\$HOME/.local/bin:\$PATH)";; esac

# AI agent integrations: install for each CLI that is present
if [ "${1:-}" != --no-agents ]; then
  link_skill() {  # $1 = skills dir, $2 = label
    mkdir -p "$1"
    rm -rf "$1/abq"
    ln -s "$REPO/skill/abq" "$1/abq"
    echo "Agent:   $2 -> $1/abq"
  }
  if [ -d "$HOME/.claude" ] || command -v claude >/dev/null; then
    link_skill "$HOME/.claude/skills" "Claude Code  (type /abq)"
  fi
  if [ -d "${CODEX_HOME:-$HOME/.codex}" ] || command -v codex >/dev/null; then
    link_skill "${CODEX_HOME:-$HOME/.codex}/skills" "Codex        (type \$abq)"
  fi
  if [ -d "$HOME/.gemini" ] || command -v gemini >/dev/null; then
    mkdir -p "$HOME/.gemini/commands"
    rm -f "$HOME/.gemini/commands/abq.toml"
    cat > "$HOME/.gemini/commands/abq.toml" <<TOML
description = "Connect to / drive the running Abaqus/CAE session (abaqus-remote)"
prompt = """
Read and follow the instructions in $REPO/skill/abq/SKILL.md.
User request (empty means: just check the connection): {{args}}
"""
TOML
    echo "Agent:   Gemini CLI   (type /abq) -> ~/.gemini/commands/abq.toml"
  fi
fi

echo
echo "Next:"
echo "  1. In Abaqus/CAE: File > Run Script...  ->  $(wslpath -w "$ABQ_REMOTE")\\abq_server.py"
echo "  2. Click the >>> command line at the bottom of CAE."
echo "  3. Test:  abq ping        (or type /abq in your AI CLI)"
