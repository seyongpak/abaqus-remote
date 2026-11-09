# Abaqus/CAE remote-script server (File > Run Script... once per CAE session).
# Typing  abqrun  at >>> executes inbox\*.py in the CAE kernel namespace (main thread),
# writes captured output + traceback to outbox\<name>.log, then deletes the job.
# Requires Abaqus 2024 or newer (Python 3).
import os, sys, io, threading, traceback

try:
    ROOT = os.path.dirname(os.path.abspath(__file__))
except NameError:
    ROOT = os.environ.get('ABQ_REMOTE') or os.path.join(os.path.expanduser('~'), '.abq_remote')
INBOX = os.path.join(ROOT, 'inbox')
OUTBOX = os.path.join(ROOT, 'outbox')
for _d in (INBOX, OUTBOX):
    os.makedirs(_d, exist_ok=True)
NS = sys.modules['__main__'].__dict__

def _run(path):
    name = os.path.splitext(os.path.basename(path))[0]
    if threading.current_thread() is not threading.main_thread():
        return
    with open(path, encoding='utf-8') as f:
        src = f.read()
    os.remove(path)
    buf = io.StringIO()
    old_out, old_err = sys.stdout, sys.stderr
    sys.stdout = sys.stderr = buf
    ok = True
    try:
        exec(compile(src, name + '.py', 'exec'), NS)
    except Exception:
        ok = False
        traceback.print_exc()
    finally:
        sys.stdout, sys.stderr = old_out, old_err
    with open(os.path.join(OUTBOX, name + '.log'), 'w', encoding='utf-8') as f:
        f.write(('OK\n' if ok else 'ERROR\n') + buf.getvalue())
    open(os.path.join(OUTBOX, name + '.done'), 'w').close()

class _Q(object):
    """Typing  abqrun  + Enter at the >>> line runs queued inbox jobs on the main
    thread (no Shift chars: SendKeys drops Shift randomly with some IMEs, e.g. Korean)."""
    def __repr__(self):
        n = 0
        for fn in sorted(os.listdir(INBOX)):
            if fn.endswith('.py'):
                _run(os.path.join(INBOX, fn))
                n += 1
        return 'abq_server: ran %d job(s)' % n

NS['_q'] = NS['abqrun'] = _Q()

# Older versions started a polling thread; stop it if one is still alive.
NS['_ABQ_SERVER_STOP'] = True
print('abq_server ready: type  abqrun  at >>> to run jobs in ' + INBOX)
