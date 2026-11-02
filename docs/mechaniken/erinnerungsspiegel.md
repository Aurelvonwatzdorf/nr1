# Erinnerungsspiegel (aufgezeichnete Erinnerungen nacherleben)

- **Status:** Idee
- **Vorbild (nur Inspiration):** Aufgezeichnete Erinnerungen, die man nacherlebt,
  vor- und zurückspult und in verschiedenen Ebenen (Bild, Ton, Wärme) nach
  Spuren absucht (Cyberpunk 2077). Eigene Regeln und eigene Bedeutung in unserer
  Welt.
- **Für wen:** beide; Spiegelrealitäten, Missionen, Story

## Was der Spieler erlebt
Man findet **Erinnerungsscherben**: Splitter aus Spiegelglas, in denen der
Konzern Erinnerungen gefangener Menschen aufbewahrt. Am Ankerspiegel (oder mit
einem Gerät von Adam) taucht man hinein und erlebt eine kurze Szene **mit den
Augen eines anderen**, als stille, farblose Spiegelwelt. Man kann die Zeit **vor-
und zurückspulen** und zwischen drei Schichten wechseln:
1. **Bild** (was die Person sah),
2. **Klang** (Stimmen hinter Wänden, Schritte),
3. **Wahrheit** (Realitätsblick: was die Person **nicht** sehen durfte – die
   Illusion, in der sie steckte).
Man markiert Spuren (Gegenstand, Stimme, Riss). Mit genug Spuren erfährt man,
wo die Person gefangen ist, wer sie verraten hat, oder findet einen
Riss-Hinweis, der eine Tür in die echte Welt öffnet.

## Warum es zu unserem Spiel passt
- **Passt perfekt zum Kern** des Spiels: Spiegelrealitäten, Realitätsblick,
  Hinweise sammeln, Illusionen durchschauen. Die Schicht „Wahrheit“ ist der
  Realitätsblick in neuer Form.
- Gute Art, Story zu erzählen (Rafas Geschichte in der Spiegelstadt, der
  Verräter, Adams Vergangenheit), ohne teure Zwischensequenzen: die Szene ist
  ein kleines, eingefrorenes Diorama.
- Nebenaufträge „Spiegelauftrag“ (Vermittler) starten mit einer Scherbe.
- **Name**: nicht „Erinnerungen“ (das ist unsere Level-Währung) → Gegenstand
  heißt **Erinnerungsscherbe**, das Nacherleben **Spiegelsicht**.

## Eigene Startwerte (zum Feintunen)
| Wert | Start | Begründung |
|---|---|---|
| Szenenlänge | 30–90 s | kurz, dicht |
| Spuren je Szene | 3–6 | kleines Rätsel |
| Schicht „Wahrheit“ | kostet 5 Fokus je Wechsel | verbindet mit Fokus |
| Verankerung in der Szene | steigt 2/s, bei 100 fliegt man raus | Zeitdruck aus vorhandener Mechanik |
| Belohnung | Story-Flag, Missions-Hinweis, Erinnerungen 100 | lohnt sich |

## Umsetzung im Projekt
- Neue Szene-Art `MemoryReplay` (erbt von `RealityLevel`, ohne Kampf):
  Figuren als eingefrorene Puppen mit `AnimationPlayer`-Spuren (Position/Pose
  über Zeit), Zeitregler (`replay_time`) steuert alle.
- Schichten: Bild (normal), Klang (Audio-Quellen als sichtbare Wellen),
  Wahrheit (`RealityLayerObject` mit `exists_in = TRUE_WORLD`).
- Spuren = abgewandelte `RealityClue` mit `layer` und Zeitfenster.
- Item `memory_shard` (CONSUMABLE, `replay_scene`), Start am `AnchorMirror`.
- Test im Rauchtest: Replay laden, Zeit auf 20 s setzen → Puppe an erwarteter
  Stelle; Spur in Schicht Klang nur dort sichtbar.

## Offene Fragen an den Nutzer
- Erinnerungsspiegel als Story-Werkzeug für Rafas Geschichte nutzen?
