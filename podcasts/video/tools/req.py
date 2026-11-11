# Druckt fertige Higgsfield-Batch-Requests: python3 tools/req.py n01 n02 n03
import json,sys,os
os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
S={s["img"]:s for s in json.load(open('scenes.json'))}
REF=open('stilvorlage.txt').read().split()[0]
SUF=" New composition; borrow ONLY the art style of the reference image. Same flat muted grainy editorial illustration style as the reference image (petrol blue, teal, ochre, coral), paper grain, people as simple flat figures without detailed faces. No text, no letters, no numbers, no logos."
print(json.dumps([{"index":int(i[1:]),"params":{"model":"gpt_image_2_6","quality":"medium","resolution":"2k","aspect_ratio":"16:9","prompt":S[i]["prompt"].rstrip('.')+"."+SUF,"medias":[{"role":"image_references","value":REF}]}} for i in sys.argv[1:]],ensure_ascii=False))
