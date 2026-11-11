# Tonplan: Musik (durchgehend) + sparsame Soundeffekte -> sfx_plan.json
# Die Effekte hängen an Bildnamen (img), nicht an festen Sekunden: Ändern sich die Zeiten
# (neuer Text oder "assemble.py anpassen"), wandern sie mit. Effekte sind leiser als die Stimmen
# (Stimmen −16 LUFS; Effekte −22 bis −26 dB unter Vollpegel).
import json, os, subprocess
os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
L=json.load(open('lines.json')); T=json.load(open('timeline.json'))
TOTAL=round(T[-1]['start']+T[-1]['dur'],3); GAP=3.0; WPEAK=0.9  # whoosh.wav: Höhepunkt bei ~0,9 s
BLOCKS=(4,10,15,21,29,35,37)   # erste Zeile jedes Abschnitts
def flen(f): return float(subprocess.run(['/opt/homebrew/bin/ffprobe','-v','error','-show_entries','format=duration','-of','csv=p=0',f],capture_output=True,text=True).stdout)
S={x['img']:x for x in T}
ev=[]
def E(t,name,g,note,dur=None,fo=None):
    f=f'sfx/{name}.wav'; d=min(dur or flen(f), flen(f))
    e={"t":round(t,2),"file":f,"gain_db":g,"dur":round(d,2)}
    if fo: e["fade_out"]=fo
    e["note"]=note; ev.append(e)
def B(img,name,g,note,dur=None,fo=None,off=0.1):
    if img in S: E(S[img]['start']+off,name,g,f'{img} / Zeile {S[img]["line"]}: {note}',min(dur or 99,S[img]['dur']) if dur else None,fo)
for li in BLOCKS:
    E(L[li]['start']-WPEAK,'whoosh',-24,f'Zeile {li}: Abschnittswechsel, Höhepunkt auf dem Schnitt')
B('s03','daten_glitch',-26,'Handy, Kamera, Laptop senden Datenlinien')
B('s08','kamera_servo',-24,'Gesichtserkennung')
B('n07','daten_glitch',-26,'KI setzt ein Bild aus WLAN-Wellen zusammen')
B('s39','telefonrauschen',-26,'Daten von Millionen Telefonen',4.0,1.5)
B('n16','daten_glitch',-26,'ein Punkt wird bis nach Hause verfolgt')
B('s19','auto_vorbei',-26,'Vorstadtstraße mit Kennzeichen-Kamera',4.0,1.0)
B('s21','scanner_piep',-24,'Kennzeichen wird gescannt')
B('n19','daten_glitch',-26,'Daten gehen an die Border Patrol')
B('s28','kamera_servo',-24,'Kamera wird abgebaut',3.0,0.8)
B('s29','menschenmenge',-26,'Bürger vor dem Rathaus',3.7,1.5)
B('s32','papier',-24,'viele lose Daten')
B('s45','spannung_riser',-26,'Palantir zieht alle Datenquellen zusammen',4.5,0.5)
B('n22','papier',-24,'Vertrag ohne Ausschreibung')
B('s49','kamera_servo',-24,'Grenzzaun, ImmigrationOS')
B('n25','scanner_piep',-26,'Tablet mit Karte (ELITE)')
B('n28','papier',-24,'Adressen sortieren')
B('n29','daten_glitch',-26,'Datenstrom vom Krankenhaus zur Behörde')
B('s36','server_brummen',-26,'Militäranlage',4.0,1.5)
B('n34','scanner_piep',-24,'KI markiert ein Ziel')
B('n39','muenzen_kasse',-24,'Vertragsgrenze steigt',2.0,0.5)
B('n41','menschenmenge',-28,'Publikum vor der Bühne',4.0,1.5)
B('n50','tastatur',-24,'Soldaten an Laptops',4.0,1.0)
B('n54','server_brummen',-26,'Polizei-Server in Bayern',4.0,1.5)
B('n58','papier',-24,'kleine Fälle')
B('s53','richterhammer',-22,'Bundesverfassungsgericht')
B('n60','server_brummen',-26,'Server ohne Internet',5.0,2.0)
B('s55','tastatur',-24,'Kritiker: Code ist geheim',4.0,1.0)
B('s56','muenzen_kasse',-24,'Umsatz steigt',2.0,0.5)
B('s69','muenzen_kasse',-24,'Geld wiegt schwer',1.5,0.4)
B('n71','hebel_strom_aus',-22,'Kamera wird ausgesteckt',1.5,0.5)
B('n72','papier',-24,'Journalisten veröffentlichen Dokumente')
ev.sort(key=lambda e:e['t'])
# Mindestabstand 3 s: Effekt, der zu dicht auf den vorigen folgt, entfällt (Whoosh hat Vorrang)
keep=[]
for e in ev:
    if e['t']<6.5 or e['t']+e['dur']>TOTAL-7.5: print('entfällt (Intro/Outro gehört der Musik):',e['note']); continue
    if keep and e['t']-(keep[-1]['t']+keep[-1]['dur'])<GAP:
        if 'whoosh' in e['file'] and 'whoosh' not in keep[-1]['file']: print('entfällt (zu dicht):',keep[-1]['note']); keep[-1]=e
        else: print('entfällt (zu dicht):',e['note'])
        continue
    keep.append(e)
for e in keep: assert os.path.exists(e['file']), e['file']
plan={"total":TOTAL,"min_gap_s":GAP,
 "info":"music = eine Datei über die ganze Länge (tools/musik.py), mit Intro- und Outro-Melodie, ohne Schleife. Effekt-WAVs 48 kHz, Spitze -1 dBFS; gain_db relativ dazu; dur = Länge ab Dateianfang.",
 "music":{"file":"sfx/musik.wav","gain_db":0,"note":"Teppich ca. -25 dBFS RMS, gleich laut von Anfang bis Ende; mit Stimmen wird alles um 6 dB abgesenkt"},
 "events":keep}
json.dump(plan,open('sfx_plan.json','w'),ensure_ascii=False,indent=1)
print(len(keep),'Effekte, Gesamt',TOTAL,'s')
