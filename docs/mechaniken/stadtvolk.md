# Stadtvolk (Menschenmengen und ihre Reaktion auf Gewalt)

- **Status:** teilweise gebaut: 70 Einwohner + Kulissen-Passanten, Flucht vor
  Gewalt (`EventBus.violence_seen`, 15 m), Zeugen (30 %) rufen nach 4 s die Wache
  (Fahndung +6), außer die Figur steht ≤ 4 m bei ihnen. Offen: Zuschauen,
  Verstecken, Gruppen-Gespräche, Moral für Bedrohen, Rückkehr zur Normalität.
- **Vorbild (nur Inspiration):** Dichte Menschenmengen und Panik bei Schüssen in
  Cyberpunk 2077 (und GTA). Keine Werte oder Verhaltenslisten übernommen.
- **Für wen:** Welt (Santo Santiago, Städte auf dem Kontinent)

## Was der Spieler erlebt
Der Große Markt ist **voll**: Viele Menschen schieben sich zwischen Ständen,
bleiben an Auslagen stehen, unterhalten sich in Gruppen. In der Senke sitzen
Leute vor Hütten, im Konzernviertel eilen Angestellte. Bei Gewalt reagieren sie
abgestuft: Wer einen Streit sieht, bleibt stehen und schaut; bei gezogener Waffe
weichen sie zurück; bei Schüssen oder Blut rennen sie schreiend weg, ducken sich
oder verstecken sich in Hauseingängen. Manche **rufen die Konzernwache**
(sichtbar: Hand am Ohr), wenn man ihnen nicht vorher Angst macht oder sie
beruhigt. Nach einer Weile kehrt das Leben zurück.

## Warum es zu unserem Spiel passt
- Heute: 46 Einwohner (`Citizen`), die bei `shot_fired` fliehen. Für eine
  Hauptstadt wirkt das leer.
- **Zeugen** verbinden Stadtleben mit Fahndung (siehe `fahndung_stufen.md`) und
  Moral (Bedrohen von Unbeteiligten).
- Die Viertel unterscheiden sich im Verhalten (respektvoll, ohne Klischee):
  unterschiedliche Tagesabläufe, Orte, an denen man sich trifft.

## Eigene Startwerte (zum Feintunen)
| Wert | Start | Begründung |
|---|---|---|
| Volle Einwohner (Logik) | 46 heute → 70 | mehr Leben, bezahlbar |
| Zusätzliche „Kulissen-Leute“ | bis 200 nahe der Kamera, ohne Gespräche | Masse günstig, siehe `viele_figuren.md` |
| Reaktion Waffe gezogen | 8 m Rückzug | abgestuft |
| Reaktion Schuss/Blut | Flucht 25 m Umkreis, 20 s | wie heute + mehr |
| Wache rufen | 30 % der Zeugen, 4 s Zeit (unterbrechbar) | Zeugen sind ein Ziel |
| Zurück zur Normalität | 45 s ohne Vorfall | Stadt beruhigt sich |
| Bedrohen (Waffe auf Bürger) | Moral −2 „Barmherzigkeit“, je Person einmal | Tat zählt |

## Umsetzung im Projekt
- `Citizen` bekommt Zustände (Spaziergang, Stehen an „Interessenpunkten“
  `CityGenerator.idle_spots`, Gespräch in Gruppe, Zuschauen, Fliehen, Verstecken,
  Wache-Rufen). Heute ist das eine `_npc_physics()`-Logik → kleine State Machine.
- `EventBus.violence_seen(position, severity)`; Schüsse, Treffer, Tote,
  Waffe-ziehen senden es.
- Kulissen-Leute: siehe `viele_figuren.md` (MultiMesh, keine Physik).
- Test im Stadt-Test: Schuss auf dem Markt → alle Bürger in 25 m wechseln in
  `flee`; nach 45 s wieder `roam`.

## Offene Fragen an den Nutzer
- Wie voll soll der Markt wirken (bezahlbar auf dem iPhone)?
