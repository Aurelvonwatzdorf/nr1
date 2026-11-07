import re, json, sys
src = open('../vigilancia_ia_podcast_es.md').read()
body = src.split('[MÚSICA DE ENTRADA')[1].split('[MÚSICA DE SALIDA]')[0]
lines=[]
for m in re.finditer(r'^\*\*(JOSHUA|AUREL):\*\* (.+)$', body, re.M):
    sp, txt = m.group(1), m.group(2).strip()
    clean = re.sub(r'\[.*?\]','',txt).replace('*','').strip()
    w = len(clean.split())
    dur = round(w/2.45 + 0.6, 2)
    lines.append({"i":len(lines),"sp":sp,"text":clean,"words":w,"dur":dur})
t=6.0  # Intro
for l in lines:
    l["start"]=round(t,2); t+=l["dur"]
json.dump(lines, open('lines.json','w'), ensure_ascii=False, indent=1)
print(len(lines), "lines, total", round(t,1), "s")
for l in lines: print(l["i"], l["sp"][0], l["dur"], l["text"][:70])
