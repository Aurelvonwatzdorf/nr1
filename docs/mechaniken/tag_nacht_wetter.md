# Tageszeit und Wetter

- **Status:** Idee
- **Vorbild (nur Inspiration):** Tag/Nacht-Wechsel und Wetter (Regen, Nebel,
  Smog) in Cyberpunk 2077. Keine Werte oder Abläufe übernommen.
- **Für wen:** Welt (alle offenen Gebiete), Spielregeln

## Was der Spieler erlebt
Die Zeit läuft: Morgendämmerung, grauer Tag, goldener Abend, Neon-Nacht. Nachts
leuchten Neon, Fenster und Pflanzen stärker, Händler schließen ihre Stände
(manche, z. B. der Schwarzmarkt, öffnen erst nachts), Bürger gehen nach Hause,
andere Leute kommen heraus. Wetter wechselt: Nieselregen, Starkregen mit
spiegelnden Straßen, Nebel aus der Senke, Smog im Konzernviertel, auf dem
Kontinent je Region (Schnee im Kagerō-Gebirge, Sandsturm in Kemet). Am
Ankerspiegel kann man **bis zum Abend/Morgen warten**.

## Warum es zu unserem Spiel passt
- Der Stil (dunkel, Nebel, Neon leuchtet) kommt nachts und im Regen am stärksten
  zur Geltung.
- **Spielregeln**: Nachts sehen Wachen schlechter (Schleichen), **Geister
  erscheinen eher nachts** (Einladung am Schrein), manche Missionen nur zu einer
  Zeit, spiritueller Druck in der Nacht stärker.
- Beten zu bestimmten Zeiten (Morgen, Abend) könnte mehr bringen – Vorschlag,
  respektvoll und für alle Häuser gleich.

## Eigene Startwerte (zum Feintunen)
| Wert | Start | Begründung |
|---|---|---|
| Spieltag | 48 Minuten echte Zeit | ein Abend pro Spielsitzung |
| Nacht | 35 % des Tages | Neon-Look überwiegt nicht ganz |
| Wetterwechsel | alle 6–12 Spielstunden | Abwechslung |
| Regen: Sichtweite Wachen | × 0,8 | Schleichen |
| Nacht: Sichtweite Wachen | × 0,7 (Laternen heben auf) | Licht zählt |
| Nebel | × 0,6 | Senke bleibt gefährlich-geheimnisvoll |
| Warten am Ankerspiegel | „bis Abend“, „bis Morgen“ | einfache Wahl |
| Zeit im Menü / Realitäten | steht / eigene Zeit je Realität | Realitäten sind fremd |

## Umsetzung im Projekt
- Autoload oder Level-Knoten `WorldClock` (`scripts/systems/world_clock.gd`):
  `GameState.time_of_day` (gespeichert), Signal `EventBus.hour_changed`.
- Licht: `DirectionalLight3D` + `WorldEnvironment` je Tageszeit (Farbverläufe als
  `Gradient`-Resource), `building.gdshader`-Fensterleuchten nachts stärker
  (globaler Shader-Parameter `night`).
- Wetter: `WeatherSystem` (Regen-Partikel nahe der Kamera, Nebel-Dichte,
  globaler Shader-Parameter `wetness` für nasse Straßen, siehe
  `nasse_strassen_regen.md`).
- NPC-Tagesabläufe: `NPC.schedule` (Stunden → Ort), Händler `open_hours`.
- `RestMenu`: Warten-Knöpfe.
- Test im Rauchtest: Zeit auf 22 Uhr setzen → `night` > 0,8, Händler „geschlossen“;
  Regen an → `wetness` steigt.

## Offene Fragen an den Nutzer
- Soll Beten zu bestimmten Tageszeiten mehr bringen? (Nur, wenn es für alle
  Häuser gleich und respektvoll ist.)
