---
name: abq
description: Connect to and drive a running Abaqus/CAE session on Windows from WSL - check the link, build models, mesh, run analyses and read ODB results by sending Abaqus Python scripts with the `abq` command. Use when the user types /abq or $abq, or asks to model, mesh, run or post-process anything in Abaqus.
---

# abq - drive Abaqus/CAE from WSL

The `abq` shell command (installed by abaqus-remote's `install.sh`) sends an Abaqus Python
script into the user's open Abaqus/CAE and prints what it printed.
If `abq` is not on PATH, try `~/.local/bin/abq` (WSL) or `%USERPROFILE%\.abq_remote\bin\abq.cmd`
(Windows; from PowerShell `& "$env:USERPROFILE\.abq_remote\bin\abq.cmd" ping`).
The same `abq` works from WSL, PowerShell, cmd and Git Bash; on Windows give normal Windows
paths (`C:\...\script.py`) and it converts them.

## Invoked with no task: connect
1. Run `abq ping`.
2. On `OK`: report "Connected to Abaqus/CAE" plus the Python version and the models, parts
   and materials listed. Then wait for the user's task.
3. On failure, tell the user what to do based on the message:
   - `Abaqus/CAE is not running` -> open Abaqus/CAE.
   - `TIMEOUT` -> in CAE do File > Run Script... and choose `%USERPROFILE%\.abq_remote\abq_server.py`
     (once per CAE session), then click the `>>>` command line and say ready.
   - `No queue ... run ./install.sh` -> run `install.sh` from the abaqus-remote folder.
   Do not retry a timeout more than once without the user acting; repeated retries do not help.

## Invoked with a task (or any Abaqus request later)
1. If the link was not checked in this conversation, run `abq ping` first.
2. Write the Abaqus Python script to a file (in a scratch or project folder), then run
   `abq script.py <timeout_s>`. Give long analyses a long timeout (default 600 s).
3. Output line 1 is `OK` or `ERROR`; on `ERROR` the traceback follows (exit code 1).
   Fix the script and rerun.

## Writing scripts
- The script runs inside CAE's own kernel namespace, as if typed at `>>>`: `mdb`, `session`
  and `from abaqus import *`, `from abaqusConstants import *` work. Import what you use.
- `print()` everything you need back; nothing else is returned. For results, open the ODB
  (`session.openOdb(...)`) in the script and print the values you need.
- Work in steps (geometry -> material/section -> assembly -> step/BC/load -> mesh -> job)
  and check each step's output before the next, rather than one huge script.
- Before deleting or overwriting the user's existing models, parts or files, ask.
- Run jobs with `mdb.jobs[name].submit(); mdb.jobs[name].waitForCompletion()` and a matching
  `abq` timeout.

## Limits
- Keystrokes go to whatever has focus in CAE; if the `>>>` line loses focus, jobs time out.
  Ask the user to click it.
- `abq_server.py` runs any script it is given, with the user's permissions. Only send scripts
  the user's task calls for.
