# Trägt fertige Bilder ein und lädt sie: python3 tools/holen.py n01 JOBID URL [n02 JOBID URL …]
import sys, os, subprocess
os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
a = sys.argv[1:]
for i in range(0, len(a), 3):
    n, j, u = a[i:i+3]
    for f, v in (('bilder_job_ids.txt', j), ('bilder_urls.txt', u)):
        L = [l for l in open(f).read().splitlines() if l.split(' ')[0] != n] + [f'{n} {v}']
        open(f, 'w').write('\n'.join(L) + '\n')
    subprocess.run(['curl', '-sSf', '-o', f'img/{n}.png', u], check=True)
    print(n, os.path.getsize(f'img/{n}.png'))
