# abaqus-remote

Run Python scripts inside a running **Abaqus/CAE** session from **WSL**, and get their output back in the terminal.

> **Status: v1.0.0.** Tested on Abaqus/CAE 2026 Learning Edition (Windows 11 + WSL2).

```
$ ./abq.sh examples/ping.py 20
OK
python 3.x.x
models: ['Model-1']
...
```

## How it works

```
WSL                                   Windows: Abaqus/CAE
abq.sh script.py ──copy──▶ %USERPROFILE%\.abq_remote\inbox\job_*.py
        └─ PowerShell SendKeys types "abqrun⏎" into CAE's >>> line
                                      abq_server.py runs the job in the CAE kernel
abq.sh prints  ◀──read── outbox\job_*.log  (OK/ERROR + stdout + traceback)
```

The script runs in CAE's own namespace on the main thread, so `mdb`, `session` and every `abaqus` module are available as if you had typed them at `>>>`.

## Requirements

- Windows 10/11 with **WSL** (`powershell.exe` and `cmd.exe` reachable from WSL — the default)
- **Abaqus/CAE 2024 or newer** (Python 3 kernel). Abaqus 2023 and older (Python 2.7) are not supported.
- Abaqus/CAE GUI open (the CAE process is `ABQcaeG`)

## Install

```bash
git clone https://github.com/seyongpak/abaqus-remote.git
cd abaqus-remote
./install.sh
```

This copies `abq_server.py` to `%USERPROFILE%\.abq_remote\` and creates `inbox\` and `outbox\`.
To use another folder, set `ABQ_REMOTE` (a WSL path) before both `install.sh` and `abq.sh`.

## Use

1. In Abaqus/CAE: **File > Run Script…** → `%USERPROFILE%\.abq_remote\abq_server.py`.
   Do this **once per CAE session**; it prints `abq_server ready`.
2. Click the **>>>** command line at the bottom of the CAE window.
3. From WSL:
   ```bash
   ./abq.sh your_script.py [timeout_seconds]   # default timeout 600 s
   ```
   The first output line is `OK` or `ERROR`; on error the traceback follows.
   `abq.sh` exits with 0 for `OK`, 1 for `ERROR` or timeout, 2 for setup problems (CAE not running, not installed).

## Known issues

- **Focus.** The keystrokes go to whatever has focus in CAE. If the `>>>` line loses focus (this can happen between jobs), `abq.sh` times out. Click the `>>>` line and try again.
- **Server not loaded.** If CAE was restarted, run step 1 again. From WSL you can only tell by sending `examples/ping.py`.
- **Timeouts.** On timeout `abq.sh` deletes its queued job so it does not run later by surprise.
- **Keyboard layouts / IME.** The trigger word `abqrun` has no Shift characters on purpose: SendKeys randomly drops Shift with some input methods (seen with the Korean IME). Keep the CAE window in English input mode.
- **Long jobs.** CAE is busy while a job runs; pass a timeout longer than the job.

## Security

`abq_server.py` executes **any** `.py` file placed in `inbox\`, with full access to CAE and your files.
Keep the queue folder on your own machine. Do not put it in a shared, network or cloud-synced folder.

## Using it with Claude Code (optional)

`skill/SKILL.md` describes the tool for Claude Code. Copy the folder to `~/.claude/skills/abaqus-remote/` and set the `abq.sh` path inside it; Claude can then build and run Abaqus models through this tool.

## License

MIT — see [LICENSE](LICENSE).
