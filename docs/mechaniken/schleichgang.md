# Schleichgang (Ducken, leise sein, Sichtkegel)

- **Status:** Idee
- **Vorbild (nur Inspiration):** Schleichen/Ducken in Cyberpunk 2077 (auch
  Dishonored, Metal Gear). Keine Werte, Symbole oder Namen übernommen.
- **Für wen:** beide; Grundlage für Lautlos-Erledigen (siehe `erledigen.md`),
  Tarnung (`schattenhaut.md`) und das „Gehege der Schweine“

## Was der Spieler erlebt
Mit **Ducken** (ohne zu rennen) geht die Figur geduckt und leise. Gegner sehen
nur noch nach vorn in einem Kegel und erst auf kürzere Entfernung. Über ihrem
Kopf zeigt ein kleiner Bogen, wie misstrauisch sie werden: Er füllt sich, solange
sie einen sehen; voll heißt entdeckt. Unterbricht man die Sicht (Ecke, Kiste,
Nebel), leert er sich langsam und der Gegner sucht an der letzten Stelle.
Rennen, Kämpfen und Schießen in der Nähe machen Lärm und holen Gegner herbei.

## Warum es zu unserem Spiel passt
- Kernmechanik 3 (Tarnung / Verdacht) braucht genau diese Grundlage: Sichtkegel,
  Verdacht, Suchen. Der Schleichgang ist die einfache Version davon für die
  normale Welt, das Gehege der Schweine die harte.
- Gibt Tahirou (ruhig, präzise) eine eigene Spielweise und Aurels Insider-Ast
  Ziele (Kameras, Ablenkung).
- Der versteckte Zustand „sie ahnen etwas“ aus Kernmechanik 3 kann derselbe
  Verdachts-Wert sein, nur ohne sichtbaren Bogen; mit dem Realitätsblick wird er
  sichtbar.

## Eigene Startwerte (zum Feintunen)
| Wert | Start | Begründung |
|---|---|---|
| Tempo geduckt | 2,2 m/s | halbes Gehtempo |
| Höhe geduckt | 1,1 m | hinter Kisten verschwinden |
| Sichtkegel Gegner | 110° nach vorn | Rücken ist eine Lücke |
| Sichtweite stehend / geduckt | 10 m / 6 m | heutige `detection_radius` = 10 |
| Rundum-Wahrnehmung (Nähe) | 2,5 m / geduckt 1,2 m | direkt daneben merkt jeder |
| Verdacht füllen | 1,2 s auf 6 m, schneller je näher | Zeit zum Reagieren |
| Verdacht leeren | 4 s | Gegner vergessen nicht sofort |
| Suchen an letzter Stelle | 8 s | dann zurück auf Posten |
| Lärm: Rennen / Kampf / Schuss | 6 m / 12 m / 25 m | Schuss holt die halbe Straße |
| Nacht/Nebel | Sichtweite × 0,7 | Verbindung zu Tag/Nacht |

## Umsetzung im Projekt
- Aktion `crouch` (gemeinsam mit `gleitschritt.md`), Zustand `Crouch`
  (`crouch_state.gd`), kleinere Kapsel, Aufstehen nur mit Platz.
- Neue Komponente `scripts/enemies/enemy_perception.gd` (`EnemyPerception`):
  Sichtkegel + Sichtstrahl (Ebene Welt), Verdacht 0–1, Signal `alerted`,
  `last_seen_position`. `EnemyIdleState` nutzt sie statt nur
  `get_detection_radius()`. Neuer Zustand `EnemySearchState`.
- Lärm über `EventBus.noise_made(position, radius)` (Schüsse nutzen schon
  `shot_fired`; einfach mit hineinleiten).
- HUD: kleiner Bogen über dem Gegner (wie der Hack-Ring), nur wenn Verdacht > 0.
- `GameState.reality_sight_active` zeigt den versteckten Verdacht in Realitäten.
- Test im Rauchtest: Wache schaut weg, Spieler geduckt 4 m hinter ihr → kein
  Alarm nach 2 s; vor ihr → Alarm nach ~1 s; Schuss 20 m entfernt → Wache sucht.

## Offene Fragen an den Nutzer
- Sichtbarer Verdachts-Bogen in der normalen Welt ja/nein? (In Realitäten bleibt
  er versteckt, siehe Kernmechanik 3.)
