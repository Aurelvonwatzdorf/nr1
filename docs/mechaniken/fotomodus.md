# Fotomodus

- **Status:** Idee
- **Vorbild (nur Inspiration):** Fotomodus in Cyberpunk 2077 (und vielen
  modernen Spielen). Keine Rahmen, Sticker oder Posen übernommen.
- **Für wen:** beide; Spieler-Werkzeug, auch für Werbung des Spiels (Bilder für
  Videos des Nutzers)

## Was der Spieler erlebt
Im Pausenmenü (oder per Taste) friert das Spiel ein und man fliegt mit einer
freien Kamera um die Szene (begrenzt auf einen Umkreis). Man stellt Sichtfeld,
Schärfentiefe, Belichtung, Farbstimmung (Filter im Stil des Spiels: Tusche, Neon,
Spiegelwelt), Uhrzeit und Wetter ein, blendet HUD und Figur ein/aus, wählt eine
Pose der Figur und speichert das Bild. Im Fotomodus kann man den Realitätsblick
einschalten und die wahre Welt fotografieren.

## Warum es zu unserem Spiel passt
- Der gezeichnete Look lebt von schönen Bildern; Spieler teilen sie.
- Hilft dem Nutzer selbst: Bilder für Stil-Abstimmung und für Videos/Werbung.
- Nutzt Vorhandenes: `screenshot_tour.gd` speichert schon Bilder, Overlay-Shader
  hat Filter, Pausen-Logik gibt es.

## Eigene Startwerte (zum Feintunen)
| Wert | Start | Begründung |
|---|---|---|
| Kamera-Umkreis | 12 m um die Figur | nicht durch Wände schummeln |
| Sichtfeld | 20°–100° | Porträt bis weit |
| Schärfentiefe | Mac ja, iPhone/Web aus | Leistung |
| Filter | 4 eigene | Stil |
| Posen | 6 Platzhalter-Posen, später Animationen | erst Figuren-Modelle |
| Speicherort | `user://fotos/` + Hinweis, wo der Ordner ist | einfach |

## Umsetzung im Projekt
- `scenes/ui/photo_mode.tscn` (`GameMenu`, pausiert), eigene `Camera3D`
  (Prozess-Modus ALWAYS), `CameraAttributesPractical` für Schärfe/Belichtung.
- Filter = neue Parameter im Overlay-Shader (`grade_mode`).
- Bild speichern: `get_viewport().get_texture().get_image().save_png()`.
- iPhone: Bild in die Fotos-App braucht später ein Plugin; erst einmal nur speichern.
- Test im Rauchtest: Fotomodus öffnen → Spiel pausiert, Kamera bewegt sich,
  Speichern legt eine PNG-Datei an.

## Offene Fragen an den Nutzer
- Fotomodus erst, wenn echte Figuren-Modelle da sind (Posen)? (Empfehlung: ja.)
