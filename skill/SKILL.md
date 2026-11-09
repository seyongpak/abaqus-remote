---
name: abaqus-remote
description: Drive a running Abaqus/CAE session on Windows from WSL - build models, run analyses and read ODB results by sending Python scripts through abq.sh. Use whenever the user asks to model, mesh, run or post-process something in Abaqus.
---

# Driving Abaqus/CAE from WSL

Tool: `ABQ=/path/to/abaqus-remote/abq.sh` (edit this path after installing).

## Before the first job each session
1. Ask the user to confirm CAE is open, `abq_server.py` was loaded with File > Run Script…, and the `>>>` line is clicked.
2. Run `$ABQ examples/ping.py 20`. A reply starting with `OK` means the link works.

## Running a job
- Write an Abaqus Python script (it runs in the CAE kernel namespace: `mdb`, `session`, `from abaqus import *`, etc. are available).
- Run `$ABQ script.py <timeout_s>`. Output line 1 is `OK` or `ERROR`, then stdout/traceback.
- `print()` what you need back. For results, open the ODB in the script and print the values.

## When it times out
- CAE is probably fine but the `>>>` line lost focus. Ask the user to click it; do not retry repeatedly.
- If CAE was restarted, the server must be loaded again (step 1).
