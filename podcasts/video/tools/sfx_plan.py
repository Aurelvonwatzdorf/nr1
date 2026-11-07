import json, os, subprocess
os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
L=json.load(open('lines.json')); T=json.load(open('timeline.json'))
TOTAL=581.8; GAP=3.0; WPEAK=0.9  # whoosh.wav peak at ~0.9 s
def flen(f): return float(subprocess.run(['/opt/homebrew/bin/ffprobe','-v','error','-show_entries','format=duration','-of','csv=p=0',f],capture_output=True,text=True).stdout)
ev=[]
def E(t,name,g,note,dur=None,fo=None):
    f=f'sfx/{name}.wav'; d=min(dur or flen(f), flen(f))
    e={"t":round(t,2),"file":f,"gain_db":g,"dur":round(d,2)}
    if fo: e["fade_out"]=fo
    e["note"]=note; ev.append(e)
S=lambda k:T[k]['start']
E(0,'intro_drone',-20,'Szene 0 / Intro: dunkle Drone unter dem Auge über der Stadt',6.0,1.5)
E(S(3)+0.1,'daten_glitch',-24,'Szene 3 / Zeile 1: Handy, Kamera, Laptop senden Datenlinien')
E(S(5)+0.1,'muenzen_kasse',-22,'Szene 5 / Zeile 2: Münzstapel als Treppe ("cuánta plata")',2.0,0.5)
for li in (4,12,20,28,38,46):
    E(L[li]['start']-WPEAK,'whoosh',-22,f'Zeile {li}: Abschnittswechsel, Whoosh-Höhepunkt (0,9 s in der Datei) liegt auf dem Schnitt bei {L[li]["start"]} s')
E(S(8)+0.1,'kamera_servo',-20,'Szene 8 / Zeile 5: Gesichtserkennung, Kamera schwenkt und klickt')
E(S(9)+0.1,'schritte',-22,'Szene 9 / Zeile 5: Gangerkennung, Fußgänger läuft',4.0,1.0)
E(S(11)+0.1,'verkehr',-24,'Szene 11 / Zeile 7: chinesische Straße bei Nacht mit Kamera',6.0,2.0)
E(S(12)+0.1,'herzmonitor',-22,'Szene 12 / Zeile 7: Kamera misst Puls',4.0,1.0)
E(S(13)+0.1,'daten_glitch',-22,'Szene 13 / Zeile 7: Bildschirm mit roter Warnung ("riesgo de cometer un delito")')
E(S(17)+0.1,'schulklingel',-24,'Szene 17 / Zeile 10: Klassenzimmer mit Kamera',3.0,1.0)
E(S(19)+3.2,'auto_vorbei',-24,'Szene 19 / Zeile 12: Vorstadtstraße mit Pickup und Flock-Kamera',5.0,1.0)
E(S(21)+0.1,'scanner_piep',-20,'Szene 21 / Zeile 13: Kennzeichen wird gescannt')
E(S(23)+0.1,'daten_glitch',-24,'Szene 23 / Zeile 15: Städte zu einem Netzwerk verbunden')
E(S(24)+0.1,'papier',-20,'Szene 24 / Zeile 15: Aktenordner werden an ICE durchgereicht')
E(S(28)+0.2,'kamera_servo',-22,'Szene 28 / Zeile 17: Kamera wird vom Mast abgebaut')
E(S(29)+0.1,'menschenmenge',-24,'Szene 29 / Zeile 18: Bürger vor dem Rathaus',3.7,1.5)
E(S(32)+0.1,'telefonrauschen',-24,'Szene 32 / Zeile 21: Berge aus Anrufen, Nachrichten, Satellitenbildern',3.5,1.0)
E(S(33)+1.0,'papier',-22,'Szene 33 / Zeile 21: Analyst unter Papierbergen')
E(S(36)+0.1,'server_brummen',-24,'Szene 36 / Zeile 23: NSA-Gebäude, Kabel zu KI-Chips',6.0,2.0)
E(S(37)+0.6,'tastatur',-22,'Szene 37 / Zeile 23: GCHQ, KI-Agenten in der Cyberabwehr',4.0,1.0)
E(S(38)+0.1,'server_brummen',-24,'Szene 38 / Zeile 25: Rechenzentrum in Europa (Microsoft-Cloud)',8.0,2.5)
E(S(39)+0.9,'telefonrauschen',-24,'Szene 39 / Zeile 25: Millionen Anrufe fließen in die Cloud',4.0,1.5)
E(S(40)+0.1,'hebel_strom_aus',-20,'Szene 40 / Zeile 25: Hebel wird umgelegt, Microsoft kappt den Zugang',1.5,0.5)
E(S(45)+0.1,'spannung_riser',-24,'Szene 45 / Zeile 29: Palantir zieht alle Datenquellen zusammen',5.0,0.5)
E(S(46)+2.0,'daten_glitch',-22,'Szene 46 / Zeile 29: Personennetz, Knoten leuchten rot')
E(S(49)+0.1,'kamera_servo',-22,'Szene 49 / Zeile 31: Grenzzaun mit Suchscheinwerfern, ImmigrationOS')
E(S(53)+0.1,'richterhammer',-20,'Szene 53 / Zeile 34: Gerichtssaal ("hubo críticas")')
E(S(55)+0.2,'tastatur',-22,'Szene 55 / Zeile 35: Hacker vom Chaos Computer Club',4.0,1.0)
E(S(56)+0.05,'muenzen_kasse',-22,'Szene 56 / Zeile 36: Börsenkurs steigt, Münzen fallen',2.0,0.5)
E(S(60)+0.1,'daten_glitch',-24,'Szene 60 / Zeile 39: Kamera-Icons breiten sich auf dem Globus aus')
E(S(61)+0.1,'spannung_riser',-24,'Szene 61 / Zeile 39: steil wachsendes Balkendiagramm',5.0,0.5)
E(S(63)+0.1,'verkehr',-24,'Szene 63 / Zeile 41: chinesische Megacity',7.0,2.0)
E(S(64)+0.1,'auto_vorbei',-24,'Szene 64 / Zeile 41: indische Straße mit Rikschas',5.0,1.0)
E(S(66)+0.1,'menschenmenge',-24,'Szene 66 / Zeile 43: Stadion, Personen werden verfolgt',7.0,2.0)
E(S(67)+1.6,'schiffshorn',-22,'Szene 67 / Zeile 43: Containerschiff exportiert Kameras',5.0,1.5)
E(S(69)+0.1,'muenzen_kasse',-22,'Szene 69 / Zeile 45: Geld wiegt schwerer als die Taube',1.5,0.4)
E(S(73)+0.1,'richterhammer',-22,'Szene 73 / Zeile 47: Gerichte setzen Grenzen, Kamera wird ausgesteckt')
E(576.5,'outro_strom_aus',-20,'Szene 76 / Zeile 51: Auge schließt sich, Lichter der Stadt gehen aus; endet bei 581,5 s',5.0,1.5)
ev.sort(key=lambda e:e['t'])
# checks
for a,b in zip(ev,ev[1:]):
    gap=b['t']-(a['t']+a['dur'])
    assert gap>=GAP-1e-6, (a['note'],b['note'],round(gap,2))
assert ev[-1]['t']+ev[-1]['dur']<=TOTAL
for e in ev: assert os.path.exists(e['file']) and e['t']>=0
plan={"total":TOTAL,
 "min_gap_s":GAP,
 "info":"Alle WAVs 48 kHz stereo, Spitze auf -1 dBFS normalisiert; gain_db gilt relativ dazu. dur = abzuspielende Länge ab Dateianfang. Mindestlücke zwischen Ende eines Effekts und Beginn des nächsten: 3 s.",
 "bed":{"file":"sfx/teppich.wav","gain_db":-30,"loop":True,"fade_in":2,"fade_out":3},
 "events":ev}
assert os.path.exists(plan['bed']['file'])
open('sfx_plan.json.tmp','w').write(json.dumps(plan,ensure_ascii=False,indent=1))
json.load(open('sfx_plan.json.tmp'))
os.replace('sfx_plan.json.tmp','sfx_plan.json')
print(len(ev),'events OK')
for e in ev: print(e['t'],e['dur'],e['file'][4:],e['gain_db'])
