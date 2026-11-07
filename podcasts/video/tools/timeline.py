import json
S=json.load(open('scenes.json')); L=json.load(open('lines.json'))
INTRO=6.0; OUTRO=5.0
# Zeit je Zeile auf ihre Szenen verteilen; Zeilen ohne Szene verlängern die vorige Szene
dur=[0.0]*len(S)
dur[0]=INTRO
by={}
for k,s in enumerate(S): by.setdefault(s[0],[]).append(k)
last=0
for l in L:
    ks=by.get(l["i"])
    if not ks: dur[last]+=l["dur"]; continue
    w=sum(S[k][1] for k in ks)
    for k in ks: dur[k]+=l["dur"]*S[k][1]/w
    last=ks[-1]
dur[-1]+=OUTRO
t=0; T=[]
for k,s in enumerate(S):
    T.append({"k":k,"line":s[0],"start":round(t,3),"dur":round(dur[k],3),"kling":s[2]}); t+=dur[k]
json.dump(T,open('timeline.json','w'),indent=0)
if __name__=="__main__":
    print("total",round(t,2)); print(max(x["dur"] for x in T), min(x["dur"] for x in T))
