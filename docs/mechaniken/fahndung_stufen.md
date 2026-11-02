# Fahndung in Stufen (Zeugen, Suchgebiet, anrückende Kräfte, Spiegeljäger)

- **Status:** teilweise gebaut: Stufen 1–5, Suchkreis (60/90/120 m, Karte und
  Minimap), Sinken nur ungesehen und außerhalb des Kreises, Verstärkung (2 Wachen
  ab Stufe 2, 2 weitere ab Stufe 4), Wachen in 40 m gehen nachsehen, 6 s
  Vorwarnung vor den Spiegeljägern. Offen: Zeugen (kommt mit Stadtvolk),
  Streifen (Fahrzeuge), Sperren, Drohnen, Kameras, Verstecke, Zuflucht in
  Gotteshäusern (Frage an den Nutzer).
- **Vorbild (nur Inspiration):** Fahndungssystem mit anrückender Polizei in
  Cyberpunk 2077 (und GTA). Keine Werte, Stufen-Namen oder Symbole übernommen.
- **Für wen:** Welt (Santo Santiago), Konzernkräfte

## Was der Spieler erlebt
Heute: Fahndung 0–100 (5 Sterne), bei 100 kommen 2 Spiegeljäger. Neu, in Stufen:
1. **Gesehen** (Zeugen/Kameras melden): Wachen in der Nähe gehen zur Stelle.
2. **Gesucht**: Auf der Minimap erscheint ein **Suchkreis**; Wachen suchen darin.
   Wer den Kreis verlässt und nicht gesehen wird, verliert die Fahndung nach und
   nach.
3. **Streifen**: Konzern-Streifen fahren an (siehe `fahrzeugkampf_verfolgung.md`).
4. **Sperren**: Straßen an Viertelgrenzen werden abgeriegelt, Drohnen suchen von
   oben (Schattenhaut hilft, Dächer helfen).
5. **Spiegeljäger** (heute bei 100): Sie fangen statt zu töten → Spiegelrealität
   am Fangort (gebaut). Neu: Sie kündigen sich an (das Licht wird kalt, Spiegel-
   flächen flackern), damit man fliehen kann.
Verstecken senkt die Fahndung schneller: in Hauseingängen, Containern,
Gotteshäusern (Konzernkräfte betreten sie nicht, siehe offene Frage).

## Warum es zu unserem Spiel passt
- Verbindet Stadtvolk (Zeugen), Hacking (Kameras, Konzernnetz), Schleichen,
  Fahrzeuge und die vorhandenen Spiegeljäger zu einem Kreislauf.
- Der Fang durch Spiegeljäger bleibt die **Story-Mechanik**: gefangen statt tot.
- Abstufung macht Fahndung spielbar statt „alles oder nichts“.

## Eigene Startwerte (zum Feintunen)
| Stufe | Fahndung | Was kommt | Sinken |
|---|---|---|---|
| 1 Gesehen | 1–19 | Wachen in 40 m kommen | nach 10 s Ruhe |
| 2 Gesucht | 20–39 | Suchkreis 60 m, 4 Wachen | außerhalb Kreis + ungesehen 15 s |
| 3 Streifen | 40–69 | 1–2 Streifen | wie 2, Kreis 90 m |
| 4 Sperren | 70–99 | Sperren an Viertelgrenzen, 2 Drohnen | Kreis 120 m, 25 s |
| 5 Spiegeljäger | 100 | 2 Jäger, Vorwarnung 6 s | erst nach Fang oder Sieg über beide |
| Zeuge meldet | +6 | – | Zeugen erschrecken/beruhigen verhindert |
| Kamera sieht Tat | +10 | – | Kamera abschalten |
| Verstecken | Sinken × 2 | – | – |

## Umsetzung im Projekt
- `WantedSystem` (vorhanden): Stufen aus `GameState.wanted_level` ableiten;
  `search_center`/`search_radius`, Sichtprüfung (Wachen, Kameras, Drohnen
  „sehen“ den Spieler über `EnemyPerception`).
- Zeugen über `stadtvolk.md` (`Citizen` → `report_crime()`).
- Suchkreis auf Minimap/Karte (`MapView`): gestrichelter Kreis.
- Drohnen: einfacher fliegender Gegner (`scripts/enemies/drone.gd`), Licht-Kegel.
- Verstecke: `HidingSpot` (Interactable).
- Test im Rauchtest/Stadt-Test: Fahndung 25 → Suchkreis aktiv; Spieler 70 m
  außerhalb, ungesehen 15 s → Fahndung sinkt; Fahndung 100 → Vorwarnung, nach 6 s
  2 Jäger.

## Offene Fragen an den Nutzer
- Sollen Gotteshäuser **Zuflucht** sein (Konzernkräfte betreten sie nicht)? Das
  wäre eine starke Aussage über die Welt.
