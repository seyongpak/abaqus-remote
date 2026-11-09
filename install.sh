#!/usr/bin/env bash
# Install abq_server.py into %USERPROFILE%\.abq_remote (or $ABQ_REMOTE) and create the queue folders.
set -e
cd "$(dirname "$0")"
command -v powershell.exe >/dev/null || { echo "powershell.exe not found - this tool needs WSL on Windows"; exit 1; }
if [ -z "$ABQ_REMOTE" ]; then
  win_home=$(cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r')
  ABQ_REMOTE="$(wslpath "$win_home")/.abq_remote"
fi
mkdir -p "$ABQ_REMOTE/inbox" "$ABQ_REMOTE/outbox"
cp server/abq_server.py "$ABQ_REMOTE/abq_server.py"
chmod +x abq.sh
echo "Installed server to: $(wslpath -w "$ABQ_REMOTE")\\abq_server.py"
echo
echo "Next:"
echo "  1. In Abaqus/CAE: File > Run Script...  ->  $(wslpath -w "$ABQ_REMOTE")\\abq_server.py"
echo "  2. Click the >>> command line at the bottom of CAE."
echo "  3. Test:  ./abq.sh examples/ping.py 20"
