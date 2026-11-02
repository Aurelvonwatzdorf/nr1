# Schattenhaut (Tarnung durch Lichtbrechung)

- **Status:** Idee
- **Vorbild (nur Inspiration):** Optische Tarnung als Implantat in Cyberpunk 2077
  (auch Crysis). Keine Namen, Werte oder Effekte übernommen.
- **Für wen:** beide; Implantat (Haut) vom Schwarzmarkt bzw. Implantat-Arzt

## Was der Spieler erlebt
Eine Taste macht die Figur für kurze Zeit fast unsichtbar: Sie wird zu einem
flimmernden Umriss, der das Licht hinter ihr verzerrt. Gegner verlieren sie aus
der Sicht, sobald sie nicht sehr nah sind. Angreifen, Schießen oder Getroffenwerden
beendet die Tarnung sofort, und der erste Schlag aus der Tarnung trifft härter.
Im Realitätsblick sieht man, dass manche Gegner (Spiegeljäger, Geister) die
Tarnung durchschauen.

## Warum es zu unserem Spiel passt
- Schleichen (Schleichgang, Erledigen) braucht ein Notfall-Werkzeug.
- **Eigene Wendung:** Die Konzerne bauen solche Technik und kennen sie. Ihre
  **Spiegeljäger sehen hindurch**; Wesen der Geisterwelt auch. Nur einfache
  Wachen und Bürger fallen darauf herein. Das passt zur Welt (Technik gegen
  Spirituelles) und verhindert, dass die Tarnung alles löst.
- Kostet Fokus (Geist-Ressource), damit sie mit dem Realitätsblick konkurriert.

## Eigene Startwerte (zum Feintunen)
| Wert | Start | Begründung |
|---|---|---|
| Dauer | 5 s | kurz |
| Kosten | 20 Fokus | gleiche Tasche wie Realitätsblick |
| Abklingzeit | 25 s | kein Dauerzustand |
| Gegner erkennen trotzdem | ≤ 2 m | direkt daneben merkt man es |
| Erster Schlag aus Tarnung | × 1,5 | Belohnung |
| Spiegeljäger, Geister | immun | Welt-Regel |
| Fahndung sinkt in Tarnung | × 2 schneller | Flucht möglich |
| Preis | 1400 | spätes Implantat |

## Umsetzung im Projekt
- `ItemData.grants_camouflage`; Item `resources/items/shadow_skin.tres`.
- `Player.start_camouflage()`; Zustand als Zähler wie `reality_sight_left`;
  Taste: neue Aktion `ability` (Vorschlag Taste G / Gamepad Steuerkreuz) oder
  auf Rad (siehe offene Fragen).
- Optik: eigener Shader `assets/materials/camouflage.gdshader`
  (`SCREEN_TEXTURE`-Verzerrung + Umriss; auf Web/iPhone nur Umriss mit
  Transparenz, weil Bildschirm-Textur teuer ist).
- `EnemyPerception.can_see()` prüft `GameState.player_camouflaged` und
  `EnemyData.sees_camouflage`.
- Test im Rauchtest: Tarnung an → Wache 5 m entfernt bemerkt Spieler nicht;
  Spiegeljäger schon; Angriff → Tarnung aus.

## Offene Fragen an den Nutzer
- Wir brauchen bald eine Taste für **aktive Implantate** (Tarnung, Zeitdehnung,
  Armwerfer). Eine Taste für das eingebaute aktive Implantat, oder ein Rad?
