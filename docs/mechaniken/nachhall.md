# Nachhall (Zeit verlangsamen)

- **Status:** Idee
- **Vorbild (nur Inspiration):** Cyber-Implantate, die die Zeit dehnen
  (z. B. Cyberpunk 2077), und das „perfekte Ausweichen“ aus Action-Spielen.
  Keine Werte oder Namen übernommen.
- **Für wen:** beide (Implantat vom Schwarzmarkt)

## Was der Spieler erlebt
Weicht man **im letzten Moment** aus, kurz bevor ein Gegnerschlag trifft,
wird die Welt für einen Moment langsam (Gegner, NPCs, Geschosse), die eigene
Figur aber nicht. Das Bild wird an den Rändern kühl und leicht verwischt, Töne
klingen dumpf. In dieser Zeit kann man einen Konter setzen oder fliehen. Der
Nachhall kostet Fokus. Ist nicht genug Fokus da, gibt es nur das normale
Ausweichen.

## Warum es zu unserem Spiel passt
- Kein neuer Knopf: Belohnt genaues Timing im Ausdauer-Kampf, wie ein Parieren.
- Kostet **Fokus**, steht damit in Konkurrenz zum Realitätsblick (Q). Man muss
  sich entscheiden.
- Unterschied zu Tahirous „Rabenauge“ (Gabe der Ahnen, gratis, selten) und
  „Stillstand“ (beim Parieren): Nachhall ist Technik, man kauft ihn, und er
  hängt am Ausweichen.

## Eigene Startwerte (zum Feintunen)
| Wert | Start | Begründung |
|---|---|---|
| Zeitfenster vor dem Treffer | 0,15 s | streng, aber machbar |
| Zeitlupe der Welt | 25 % Tempo | deutlich spürbar |
| Dauer (Echtzeit) | 2,5 s | Zeit für 1 bis 2 Schläge |
| Fokus-Kosten | 20 | etwas mehr als Q (15) |
| Abklingzeit | 6 s | nicht in jeder Rolle |
| Preis Schwarzmarkt | 900 Geld | starkes Implantat |

## Umsetzung im Projekt
- Neues `ItemData` (PERMANENT) mit Flag `grants_afterimage`, Eintrag in
  `ItemDatabase.PATHS`, `Merchant.stock` am Schwarzmarkt.
- `PlayerDodgeState`: Kommt während der I-Frames ein Treffer an (Hurtbox meldet
  „ignoriert wegen I-Frames“), wird der Nachhall ausgelöst.
- Zeitlupe **nicht** über `Engine.time_scale` (das würde den Spieler mit
  verlangsamen), sondern wie bei `GameState.time_stopped`: ein Faktor
  `GameState.world_time_scale`, den Gegner und NPCs auf ihr `delta` anwenden.
- Overlay-Shader: neuer Parameter `afterimage` (Ränder kühl/verwischt).
- Test im Rauchtest: Gegner-Treffer während I-Frames → Zeitlupe aktiv, Fokus
  −20; nach 2,5 s wieder normal; ohne Implantat passiert nichts.

## Offene Fragen an den Nutzer
- Lieber Implantat (für beide) oder Fähigkeit nur für Aurel?
- Soll die Welt langsam werden oder fast stehen (z. B. 10 %)?
