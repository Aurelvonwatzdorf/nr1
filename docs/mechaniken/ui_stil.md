# Stil der Benutzeroberfläche (HUD und Menüs)

- **Status:** Idee
- **Vorbild (nur Inspiration):** Die durchgehend gestaltete Oberfläche in
  Cyberpunk 2077 (eigene Schrift, Farben, Kanten, Störungen, alles wirkt wie ein
  Gerät im Kopf der Figur). **Keine** Schrift, Farben, Formen oder Symbole
  übernommen.
- **Für wen:** beide; alle Menüs und das HUD

## Was der Spieler erlebt
Die Oberfläche fühlt sich an wie ein Teil der Welt und der Figur:
- **Aurel**: kühle Konzern-Optik, aber angebrannt – dünne Linien, eckige Rahmen,
  Glut-Orange als Akzent, Text erscheint wie getippt.
- **Tahirou**: Tinte und Federn – Pinselstriche als Balken, goldene eigene
  Ornamente, Raben-Silhouetten in den Ecken.
- **In Spiegelrealitäten**: dieselbe Oberfläche, aber zu sauber und zu ruhig;
  mit hoher Verankerung bröckelt sie (gibt es teilweise).
Balken (Leben, Ausdauer, Fokus, Ehrgeiz/Rabenbund) bleiben klar lesbar; die
Gestaltung sitzt in Rahmen, Schrift und kleinen Bewegungen.

## Warum es zu unserem Spiel passt
- Zwei Figuren mit sehr verschiedener Haltung: Die Oberfläche zeigt das jede
  Sekunde, ohne Text.
- Der Begleiter „lebt im Kopf“: Seine Zeilen können im Figuren-Stil erscheinen.
- Lesbarkeit zuerst (Souls-Kampf braucht klare Balken), Stil in Rahmen.

## Eigene Startwerte (zum Feintunen)
| Wert | Start | Begründung |
|---|---|---|
| Schrift | freie Schrift (z. B. aus Google Fonts, OFL-Lizenz) je Figur | eigene Wahl, Lizenz sauber |
| Akzentfarben | Aurel Glut-Orange, Tahirou Gold, Konzern Kaltblau | Stil-Leitfaden |
| Bewegung | Einblenden 0,15 s, kein Hüpfen | ernst, nicht verspielt |
| Mindestgröße Text | 18 px (iPhone 22 px) | lesbar |
| Kontrast | Text auf dunklem Grund ≥ 4,5 : 1 | Barrierefreiheit |

## Umsetzung im Projekt
- Godot-`Theme`-Resources: `resources/ui/theme_aurel.tres`,
  `theme_tahirou.tres`; `GameUI` setzt das Theme nach `GameState.character`.
- Balken als eigene `Control` mit `StyleBoxTexture`/Shader (Pinselstrich-
  Maske für Tahirou), statt Standard-`ProgressBar`.
- Schriften als Dateien in `assets/fonts/` + Lizenz in `CREDITS.md`.
- Prüfung: Screenshots HUD für beide Figuren, iPhone-Format (`06_iphone_steuerung`).

## Offene Fragen an den Nutzer
- Zwei verschiedene Oberflächen je Figur, oder eine gemeinsame mit Farbakzent?
