# abaqus-remote

Run Python scripts inside a running **Abaqus/CAE** session from **WSL**, and get their output back in the terminal.

> **Status: v1.1.0.** Tested on Abaqus/CAE 2026 Learning Edition (Windows 11 + WSL2).

```
$ abq ping
OK
python 3.x.x
models: ['Model-1']
...
```

## Quick start with an AI agent

```bash
git clone https://github.com/seyongpak/abaqus-remote.git && cd abaqus-remote && ./install.sh
```
In Abaqus/CAE: **File > Run Script… → `%USERPROFILE%\.abq_remote\abq_server.py`**, click the `>>>` line,
then in Claude Code, Codex or Gemini CLI type **`/abq`** (Codex: **`$abq`**). Add a task after it, e.g.
`/abq make a 2 m steel cantilever with a 1 kN tip load and give me the tip deflection`.

How the skill works, and how to write your own in five lines: [docs/SKILL_GUIDE.md](docs/SKILL_GUIDE.md).

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

This copies `abq_server.py` to `%USERPROFILE%\.abq_remote\`, creates `inbox\` and `outbox\`, links the `abq` command into `~/.local/bin`, and sets up `/abq` for the AI CLIs it finds (see below).
To use another folder, set `ABQ_REMOTE` (a WSL path) before both `install.sh` and `abq.sh`.

## Use

1. In Abaqus/CAE: **File > Run Script…** → `%USERPROFILE%\.abq_remote\abq_server.py`.
   Do this **once per CAE session**; it prints `abq_server ready`.
2. Click the **>>>** command line at the bottom of the CAE window.
3. From WSL:
   ```bash
   abq ping                                   # check the connection
   abq your_script.py [timeout_seconds]       # default timeout 600 s
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

## Using it from AI coding agents: `/abq`

`install.sh` also sets up an `/abq` command for each AI CLI it finds:

| Agent | Installed to | Type |
|---|---|---|
| Claude Code | `~/.claude/skills/abq` (link to `skill/abq`) | `/abq` |
| OpenAI Codex CLI | `~/.codex/skills/abq` (link to `skill/abq`) | `$abq` (or pick it from `/skills`) |
| Gemini CLI | `~/.gemini/commands/abq.toml` | `/abq` |
| Any other agent | reads `AGENTS.md` in this repo | ask it to "use abq" |

After loading the server in CAE, type `/abq` alone to connect: the agent runs `abq ping` and reports
the models it sees. Type `/abq <task>` (for example `/abq make a 2 m cantilever I-beam and run a static step`)
to have it build and run the model. Install an agent CLI after abaqus-remote? Run `./install.sh` again.
Skip the agent setup with `./install.sh --no-agents`.

## License

MIT — see [LICENSE](LICENSE).
