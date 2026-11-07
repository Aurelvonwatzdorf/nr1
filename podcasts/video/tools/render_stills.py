import json, os, subprocess
from concurrent.futures import ThreadPoolExecutor
T=json.load(open('timeline.json'))
def job(x):
    k=x["k"]; src=f"img/s{k:02d}.png"; out=f"clips/kb{k:02d}.mp4"
    if os.path.exists(src) and not os.path.exists(out):
        subprocess.run(['python3','tools/kb.py',src,out+'.tmp.mp4',str(x["dur"]),str(k)]); os.rename(out+'.tmp.mp4',out); return k
with ThreadPoolExecutor(3) as ex: print([r for r in ex.map(job,T) if r is not None])
