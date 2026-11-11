# Prüft Bild für Bild, ob die Bewegung eines Clips gleichmäßig ist.
#   python3 tools/kb_check.py clip.mp4 [clip2.mp4 …]
# Misst die Verschiebung zwischen aufeinanderfolgenden Bildern an 4 Stellen (Lucas-Kanade,
# subpixelgenau) und meldet Sprünge: "ruck" = größte Änderung der Verschiebung von Bild zu Bild (Pixel).
import sys, subprocess, numpy as np
FF='/opt/homebrew/opt/ffmpeg-full/bin/ffmpeg'
W,H=960,540
def frames(p):
    raw=subprocess.run([FF,'-v','error','-i',p,'-vf',f'scale={W}:{H}:flags=area,format=gray','-f','rawvideo','-'],capture_output=True).stdout
    return np.frombuffer(raw,np.uint8).reshape(-1,H,W).astype(np.float32)
def shift(a,b):
    # Lucas-Kanade für kleine Verschiebungen (genau im Subpixel-Bereich)
    m=(a+b)/2
    gx=(m[1:-1,2:]-m[1:-1,:-2])/2; gy=(m[2:,1:-1]-m[:-2,1:-1])/2; gt=(b-a)[1:-1,1:-1]
    A=np.array([[np.sum(gx*gx),np.sum(gx*gy)],[np.sum(gx*gy),np.sum(gy*gy)]])
    v=np.linalg.solve(A+np.eye(2)*1e-6,-np.array([np.sum(gx*gt),np.sum(gy*gt)]))
    return v[0]*2,v[1]*2      # zurück auf 1920er-Pixel
for p in sys.argv[1:]:
    F=frames(p); P=256
    boxes=[(60,60),(60,W-P-60),(H-P-20,60),(H-P-20,W-P-60)]
    worst=0; speed=0
    for (y,x) in boxes:
        s=np.array([shift(F[i][y:y+P,x:x+P],F[i+1][y:y+P,x:x+P]) for i in range(len(F)-1)])
        d=np.abs(np.diff(s,axis=0))            # Änderung der Geschwindigkeit
        worst=max(worst,float(d.max())); speed=max(speed,float(np.abs(s).max()))
    print(f'{p}: {len(F)} Bilder, max. Tempo {speed:.2f} px/Bild, größter Ruck {worst:.3f} px ->','gleichmäßig' if worst<0.2 else 'UNRUHIG')
