#!/usr/bin/env bash
# Send a Python file to the running Abaqus/CAE (abq_server.py) and print its output.
# Drops the job in inbox\, then types  abqrun + Enter  into CAE's >>> command line.
# CAE drops fast synthetic keystrokes, so keys go one at a time, with retries.
# usage: abq.sh script.py [timeout_s]
# Queue folder: $ABQ_REMOTE if set, else %USERPROFILE%\.abq_remote on Windows.
set -e
[ -f "${1:-}" ] || { echo "usage: abq.sh script.py [timeout_s]"; exit 2; }
if [ -z "$ABQ_REMOTE" ]; then
  win_home=$(cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r')
  ABQ_REMOTE="$(wslpath "$win_home")/.abq_remote"
fi
R=$ABQ_REMOTE
[ -d "$R/inbox" ] || { echo "No queue at $R/inbox - run ./install.sh first"; exit 2; }
powershell.exe -NoProfile -Command 'if (-not (Get-Process ABQcaeG -ErrorAction SilentlyContinue)) { exit 1 }' \
  || { echo "Abaqus/CAE is not running (no ABQcaeG process) - open CAE first"; exit 2; }
name="job_$(date +%s%N)"
cp "$1" "$R/inbox/$name.tmp" && mv "$R/inbox/$name.tmp" "$R/inbox/$name.py"
poke() {
powershell.exe -NoProfile -Command '
$p = Get-Process ABQcaeG -ErrorAction Stop | Select-Object -First 1
$ws = New-Object -ComObject WScript.Shell
if (-not $ws.AppActivate($p.Id)) { exit 1 }
Start-Sleep -Milliseconds 400
foreach ($k in @("a","b","q","r","u","n","{ENTER}")) { $ws.SendKeys($k); Start-Sleep -Milliseconds 80 }' >/dev/null 2>&1 || true
}
for ((i=0; i<${2:-600}*2; i++)); do
  # (re)type the trigger at t=0, 4 s, 8 s while the job is still queued
  if [ -f "$R/inbox/$name.py" ] && (( i % 8 == 0 && i <= 16 )); then poke; fi
  if [ -f "$R/outbox/$name.done" ]; then
    log="$R/outbox/$name.log"; cat "$log"
    status=0; [ "$(head -n1 "$log" | tr -d "\r")" = OK ] || status=1
    rm -f "$R/outbox/$name".*; exit $status
  fi
  sleep 0.5
done
# Remove the queued job so it does not run unexpectedly on the next abqrun.
rm -f "$R/inbox/$name.py"
echo "TIMEOUT: no reply (is abq_server running in CAE, and is the >>> line focused?)"; exit 1
