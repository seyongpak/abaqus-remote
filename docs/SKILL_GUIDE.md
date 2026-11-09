# How `/abq` works, and how to make your own skill

## The idea in one picture

```
 you type  /abq make a cantilever and run it
      │
      ▼
 AI agent (Claude Code / Codex / Gemini)  ── reads skill/abq/SKILL.md (plain text instructions)
      │  writes an Abaqus Python script, then runs a shell command:
      ▼
 abq script.py 600            ← the only "connection"; any agent that can run a shell command can use it
      │  copies the script to %USERPROFILE%\.abq_remote\inbox\ and types "abqrun⏎" into CAE
      ▼
 Abaqus/CAE (abq_server.py loaded)  ── runs the script, writes OK/ERROR + output to outbox\
      │
      ▼
 abq prints the output → the agent reads it → fixes the script or answers you
```

On Windows (VS Code opened on Windows, Claude desktop app), the agent calls `abq.cmd`, which runs
the same `abq` inside WSL with `wsl.exe` - the rest of the picture is identical.

So there is no plugin, API or network server. A **skill** is just a Markdown file that tells the agent
*when* to use the `abq` command and *how*. The agent does the rest with its normal shell tool.

## Setup recap (once)

```bash
git clone https://github.com/seyongpak/abaqus-remote.git
cd abaqus-remote && ./install.sh
```

Each CAE session: **File > Run Script… → `%USERPROFILE%\.abq_remote\abq_server.py`**, then click the `>>>` line.

## Using it

| You type | What the agent does |
|---|---|
| `/abq` | runs `abq ping`, reports "Connected" + the models/parts/materials in CAE |
| `/abq make a 2 m steel cantilever, 1 kN tip load, give me the tip deflection` | writes the script in steps (part → material → step/load → mesh → job), runs each with `abq`, reads the ODB, answers |
| `/abq what's in Model-1?` | writes a small read-only script, runs it, summarises |

In Codex type `$abq` instead of `/abq`.

## The smallest skill that works

Everything in `skill/abq/SKILL.md` beyond this is advice that makes the agent better at it.
This is the minimum - save it as `~/.claude/skills/abq-mini/SKILL.md` (Claude Code) or
`~/.codex/skills/abq-mini/SKILL.md` (Codex) and it already works:

```markdown
---
name: abq-mini
description: Run Abaqus/CAE Python scripts in the user's open Abaqus session. Use for any Abaqus task.
---
Write the Abaqus Python script to a file and run `abq script.py 600`.
The first output line is OK or ERROR; fix and rerun on ERROR.
Use print() for anything you need back. Run `abq ping` first to check the connection.
```

The two required parts are:

- **`description`** - the agent reads this to decide *when* the skill applies, so name the trigger
  ("Abaqus", "/abq") and what it does.
- **The body** - the steps, in plain language. Mention the exact command (`abq ...`) and how to read its output.

For Gemini CLI the same thing is a TOML file, `~/.gemini/commands/abq-mini.toml`:

```toml
description = "Run Abaqus scripts in the open CAE session"
prompt = """
Write the Abaqus Python script to a file and run `abq script.py 600`.
First output line is OK or ERROR; fix and rerun on ERROR. Use print() for results.
Task: {{args}}
"""
```

## Making a task-specific skill

Copy the minimum skill and add the knowledge for one job. Example - a skill that always checks
a beam the same way:

```markdown
---
name: abq-beam-check
description: Check a steel beam in Abaqus - build, run static analysis, report max Mises stress and deflection. Use for /abq-beam-check or "check this beam in Abaqus".
---
1. Run `abq ping`; stop and tell the user to load abq_server.py if it fails.
2. Ask for span, section and load if the user did not give them.
3. Build a B31 beam model in a new model named BeamCheck (never modify other models),
   steel E=210 GPa, nu=0.3, run a Static step, and print max Mises stress (MPa) and max U2 (mm).
4. Compare with hand calculation (M L^2 / 8 E I style formula) and report both.
```

Tips:
- Keep one skill per job; short skills are followed more reliably than long ones.
- Say what *not* to touch (other models, files) - the server runs whatever it is sent.
- Put long reference material (material tables, section libraries) in a separate file next to
  `SKILL.md` and say "read `materials.md` when you need properties".
