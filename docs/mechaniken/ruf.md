# Ruf in der Stadt (sichtbar, je Viertel)

- **Status:** Idee
- **Vorbild (nur Inspiration):** Straßen-Ruf in Cyberpunk 2077, der mit
  Aufträgen wächst und Händler/Angebote freischaltet. Eigene Regeln (je Viertel,
  getrennt von der Moral).
- **Für wen:** beide; Welt, Vermittler, Händler

## Was der Spieler erlebt
Was man tut, spricht sich herum – **je Viertel**. Hilft man in der Senke, kennen
einen die Leute dort, grüßen, geben bessere Preise und Hinweise, und Mama Ojuola
(Vermittlerin) gibt größere Aufträge. Im Konzernviertel kann man einen anderen Ruf
haben: als Störenfried gefürchtet, oder als zuverlässig. Der Ruf ist **sichtbar**
(Karte: Stufe je Viertel) und kann auch **sinken** (Gewalt gegen Bewohner,
Auftrag verraten).

## Warum es zu unserem Spiel passt
- **Abgrenzung zum Moral-Gedächtnis**: Die Moral ist **unsichtbar** und misst,
  wer man ist (für Rafa). Der Ruf ist **sichtbar** und misst, was die Leute über
  einen denken. Beides kann auseinanderfallen: Man kann in der Senke als Held
  gelten und trotzdem heimlich grausam gewesen sein – oder umgekehrt.
- Gibt jedem Viertel eine Beziehung zur Figur, ohne Glauben zu bewerten
  (Ruf gilt für Viertel, Taten zählen, nicht der Glaube).

## Eigene Startwerte (zum Feintunen)
| Wert | Start | Begründung |
|---|---|---|
| Viertel mit Ruf | Konzernviertel, Markt, Senke, die vier Glaubensviertel | 7 Werte |
| Stufen | Fremd · Bekannt · Geschätzt · Einer von uns (0/100/300/700) | klar |
| Auftrag erledigt | +40 bis +120 im Viertel | Hauptweg |
| Hilfe (Missionen, Heilen) | +20 | kleine Taten zählen |
| Gewalt gegen Bewohner | −50 | spürbar |
| Händler-Rabatt | 0 / 5 / 10 / 15 % | Belohnung |
| Konzernviertel und Fahndung | hoher Ruf → Fahndung startet erst bei Zeugen ×2 | Vorteil |

## Umsetzung im Projekt
- `GameState.reputation` (Dictionary Viertel → int), `add_reputation(quarter, amount)`
  (gespeichert). Viertel des Spielers: `CityGenerator` kennt die Bezirke.
- Quellen: `MissionData.reputation_reward`, NPC-Schaden (`NPC`), Heilen.
- `Merchant`: Preis × Rabatt; `Citizen`: Grußsätze je Stufe.
- Karte: Viertel-Namen mit Stufe; HUD-Meldung bei Stufenwechsel.
- Test im Rauchtest: Mission in der Senke abschließen → Ruf Senke +; Preis beim
  Händler dort sinkt ab „Bekannt“.

## Offene Fragen an den Nutzer
- Ruf je Viertel (7 Werte) oder einfacher ein Ruf für die ganze Stadt?
