# Radiosender der Stadt

- **Status:** Idee
- **Vorbild (nur Inspiration):** Radiosender im Fahrzeug und in der Welt in
  Cyberpunk 2077 (und GTA). Keine Sender, Lieder, Sprecher oder Namen
  übernommen; Musik nur eigen oder frei lizenziert.
- **Für wen:** Welt; Fahrzeuge, Läden, Unterschlupf

## Was der Spieler erlebt
Im Fahrzeug (und aus Radios an Ständen, in Bars, in Hütten) laufen **Sender**,
zwischen denen man wechselt. Jeder Sender hat eine Stimmung und einen
Sprecher, der zwischen den Liedern **Neuigkeiten aus der Welt** erzählt – auch
über das, was der Spieler getan hat („Unruhe am Großen Markt, Konzernwache
verletzt …“). Vorschläge:
1. **Radio Senke**: Straßenmusik, Trommeln, rau, Sprecherin aus der Senke.
2. **Konzernfunk**: ruhige Musik, Werbung für „Erholungswelten“ (Spiegelwerk),
   Durchsagen zur Fahndung.
3. **Steppenwind** (Kontinent): Kehlgesang, Pferdekopfgeige-ähnliche Klänge,
   Elektronik.
4. **Stiller Sender**: nur Rauschen … und manchmal Stimmen der Geister (ab
   Spiritualität 3 verständlich).

## Warum es zu unserem Spiel passt
- Nachrichten im Radio erzählen die Welt und zeigen, dass Taten Folgen haben
  (Fahndung, Ruf, Missionen).
- **Stiller Sender** verbindet Radio mit der Geisterwelt: eigene Idee.
- In Spiegelrealitäten laufen auf allen Sendern dieselben Lieder in Schleife:
  Hinweis auf die Illusion.

## Eigene Startwerte (zum Feintunen)
| Wert | Start | Begründung |
|---|---|---|
| Sender | 4 | Anfang |
| Lieder je Sender | 4–6 (je 2–3 Min.) | Aufwand für Musik |
| Neuigkeiten | 1 zwischen 2 Liedern, aus Ereignis-Liste | lebendig |
| Sprecher | erst Text-Untertitel, Stimme später | Kosten |

## Umsetzung im Projekt
- `RadioStation` (Resource: Lieder, Sprecher-Sätze, Stil);
  `RadioPlayer` (Autoload): spielt „weiter“, auch wenn man nicht zuhört (Sender
  laufen in Echtzeit, Position aus der Spielzeit berechnet).
- Ereignis-Liste aus `EventBus` (Fahndung, Missionen) → Neuigkeiten-Sätze.
- Radios in der Welt: `AudioStreamPlayer3D` mit gedämpftem Filter.
- Musik: eigene Stücke (Nutzer, Freunde, KI-Musik mit klarer Lizenz) oder CC0;
  Eintrag in `CREDITS.md`.
- Test im Rauchtest: Fahrzeug, Sender wechseln → anderer Stream läuft.

## Offene Fragen an den Nutzer
- Woher soll die Musik kommen (eigene, KI mit Lizenz, freie Stücke)?
