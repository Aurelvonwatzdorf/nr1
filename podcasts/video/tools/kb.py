# Ken-Burns-Clip aus einem Standbild: python3 kb.py in.png out.mp4 dauer variante
import sys, subprocess
from PIL import Image
src, out, D, v = sys.argv[1], sys.argv[2], float(sys.argv[3]), int(sys.argv[4])
W,H,FPS=1920,1080,30
im=Image.open(src).convert('RGB')
iw,ih=im.size
n=max(1,round(D*FPS))
# Varianten: 0 zoom rein, 1 zoom raus, 2 schwenk rechts, 3 schwenk links, 4 schwenk hoch
z0,z1,dx,dy={0:(1.0,1.10,0,0),1:(1.10,1.0,0,0),2:(1.08,1.08,-1,0),3:(1.08,1.08,1,0),4:(1.08,1.08,0,1)}[v%5]
p=subprocess.Popen(['ffmpeg','-v','error','-y','-f','rawvideo','-pix_fmt','rgb24','-s',f'{W}x{H}','-r',str(FPS),'-i','-',
  '-c:v','libx264','-preset','veryfast','-crf','20','-pix_fmt','yuv420p',out],stdin=subprocess.PIPE)
base=min(iw/W, ih/H)
for f in range(n):
    a=f/(n-1) if n>1 else 0
    a=a*a*(3-2*a)*0.6+a*0.4   # sanft ein- und ausblenden
    z=z0+(z1-z0)*a
    cw,ch=W*base/z, H*base/z
    mx,my=(iw-cw)/2,(ih-ch)/2
    cx=mx+dx*mx*(2*a-1)*0.9; cy=my+dy*my*(1-2*a)*0.9
    fr=im.transform((W,H),Image.Transform.EXTENT,(cx,cy,cx+cw,cy+ch),Image.Resampling.BILINEAR)
    p.stdin.write(fr.tobytes())
p.stdin.close(); p.wait()
