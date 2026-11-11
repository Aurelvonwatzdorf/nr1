# Kontaktblatt: python3 tools/contact.py out.png s03 n12 …  (Bilder img/<name>.png, beschriftet mit Namen)
import sys
from PIL import Image, ImageDraw, ImageFont
out, idx = sys.argv[1], sys.argv[2:]
TW, TH, COLS = 480, 270, 4
rows = (len(idx) + COLS - 1) // COLS
sheet = Image.new('RGB', (COLS * TW, rows * TH), 'black')
d = ImageDraw.Draw(sheet)
try: f = ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial Bold.ttf', 28)
except OSError: f = ImageFont.load_default()
for n, i in enumerate(idx):
    x, y = (n % COLS) * TW, (n // COLS) * TH
    try: sheet.paste(Image.open(f'img/{i}.png').convert('RGB').resize((TW, TH)), (x, y))
    except FileNotFoundError: pass
    d.rectangle((x, y, x + 70, y + 34), fill='black'); d.text((x + 6, y + 2), str(i), fill='yellow', font=f)
sheet.save(out)
