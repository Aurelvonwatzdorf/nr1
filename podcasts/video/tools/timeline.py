# Zeitplan je Szene aus scenes.json + lines.json -> timeline.json
# Regeln: Intro 6 s, Outro 5 s; Kling-Szenen höchstens 5 s (der Clip ist 5 s lang, danach
# gäbe es ein Standbild) – der Rest geht an die Nachbarszene. Jede Szene 3 bis ~9 s.
import json, os
os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
S=json.load(open('scenes.json')); L=json.load(open('lines.json'))
INTRO=6.0; OUTRO=5.0; KLING_MAX=5.0; MIN=3.0; MAX=9.3
dur=[0.0]*len(S)
by={}
for k,s in enumerate(S): by.setdefault(s["line"],[]).append(k)
for k in by.get(-1,[]): dur[k]=INTRO/len(by[-1])
last=by[-1][-1]
for l in L:
    ks=by.get(l["i"])
    if not ks: dur[last]+=l["dur"]; continue      # Zeile ohne eigenes Bild teilt sich das vorige
    # Wird eine Zeile kürzer gesprochen als geplant, bekommt sie weniger Bilder (jedes mind. 3 s)
    ks=ks[:max(1,min(len(ks),int(l["dur"]//MIN)))]
    w=sum(S[k]["w"] for k in ks)
    for k in ks: dur[k]+=l["dur"]*S[k]["w"]/w
    last=ks[-1]
for k in by.get(-2,[]): dur[k]=OUTRO/len(by[-2])
# Kling-Deckel: Überschuss an eine Nachbarszene ohne Kling abgeben
for k,s in enumerate(S):
    if s["kling"] and dur[k]>KLING_MAX:
        ex=dur[k]-KLING_MAX; dur[k]=KLING_MAX
        same=[j for j in (k+1,k-1) if 0<=j<len(S) and not S[j]["kling"] and S[j]["line"]==s["line"]]
        other=[j for j in (k+1,k-1) if 0<=j<len(S) and not S[j]["kling"]]
        same=[j for j in same if dur[j]>0]; other=[j for j in other if dur[j]>0]
        if same or other: dur[(same or other)[0]]+=ex
        else: dur[k]+=ex
t=0; T=[]
for k,s in enumerate(S):
    if dur[k]<=0: continue                          # Bild entfällt (Zeile zu kurz für alle ihre Bilder)
    T.append({"k":k,"line":s["line"],"img":s["img"],"start":round(t,3),"dur":round(dur[k],3),"kling":s["kling"]}); t+=dur[k]
json.dump(T,open('timeline.json','w'),indent=0)
bad=[(x["k"],x["img"],x["dur"]) for x in T if x["dur"]<MIN or x["dur"]>MAX]
if __name__=="__main__":
    print("Szenen",len(T),"gesamt",round(t,2),"s; kürzeste",min(x["dur"] for x in T),"längste",max(x["dur"] for x in T))
    print("außerhalb 3–9 s:",bad or "keine")
