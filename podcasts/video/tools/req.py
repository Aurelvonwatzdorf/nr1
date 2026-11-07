import json,sys
S=json.load(open('scenes.json'))
SUF=" New composition and setting; borrow ONLY the art style of the reference image, not its street or buildings. Same flat muted grainy editorial illustration style as the reference image (petrol blue, teal, ochre, coral). No text, no letters, no logos."
idx=[int(x) for x in sys.argv[1:]]
print(json.dumps([{"index":i,"params":{"model":"gpt_image_2_6","quality":"medium","resolution":"2k","aspect_ratio":"16:9","prompt":S[i][3]+"."+SUF,"medias":[{"role":"image_references","value":"163411ee-08c1-4d1c-85db-af272a05d649"}]}} for i in idx],ensure_ascii=False))
