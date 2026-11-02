# Kämpfen aus dem Fahrzeug und Verfolgungsjagden

- **Status:** Idee
- **Vorbild (nur Inspiration):** Schießen aus dem Fahrzeug und Verfolgungen
  durch die Stadt in Cyberpunk 2077. Keine Werte, Missionen oder Namen übernommen.
- **Für wen:** beide; Fahndung, Missionen, Caspars Assassinen

## Was der Spieler erlebt
Während der Fahrt kann man mit der Schusswaffe zur Seite und nach hinten
schießen (Zielen mit der Maus, Fahrzeug fährt langsamer weiter). Auf dem Motorrad
geht auch ein **Seitenhieb** mit der Nahkampfwaffe gegen Fahrer neben einem.
Bei hoher Fahndung verfolgen einen **Konzern-Streifen** (Fahrzeuge mit Wachen),
die einen rammen und aus dem Fenster schießen; Spiegeljäger kommen bei vollen
Sternen weiterhin zu Fuß an Straßensperren. **Verfolgungsjagden** in Missionen:
einem fliehenden Ziel folgen, ohne es zu verlieren, oder Caspars Assassinen
abhängen.

## Warum es zu unserem Spiel passt
- Die Fahndung bekommt eine zweite Stufe zwischen „Wachen laufen herbei“ und
  „Spiegeljäger“: Streifen machen die Flucht im Fahrzeug spannend.
- Caspars Assassinen (M10) können auf Motorrädern kommen.
- Souls-Fairness: Aus dem Fahrzeug schießt man ungenauer und kann nicht
  ausweichen. Wer kämpfen will, steigt aus.

## Eigene Startwerte (zum Feintunen)
| Wert | Start | Begründung |
|---|---|---|
| Fahrzeug beim Schießen | Tempo auf 60 % | Gefühl „Zielen kostet“ |
| Streuung aus Fahrzeug | × 2 | ungenauer |
| Seitenhieb (Motorrad) | 20 Schaden, Fahrer fällt bei Tempo > 10 m/s | Motorrad-Stärke |
| Streifen ab Fahndung | 2 Sterne (40) | Zwischenstufe |
| Streifen Anzahl | 1 (40) / 2 (70) | wächst mit Fahndung |
| Verlieren (Verfolgung) | Ziel 60 m entfernt + 8 s außer Sicht | fair |
| Abhängen (Flucht) | 80 m + 10 s außer Sicht → Fahndung beginnt zu sinken | wie heute, nur mit Sicht |

## Umsetzung im Projekt
- `Player`-Zustand `Drive` erlaubt `fire` (Ziel über `CameraRig`), kein
  Lock-on-Wechsel.
- `VehicleAI` (siehe `fahrzeug_rufen_kaufen.md`) mit Modus CHASE (Ziel = Spieler,
  rammen) und FLEE (Missionsziel).
- `WantedSystem`: Stufe 2+ startet Streifen (Fahrzeug + 2 Wachen), Sichtprüfung
  für das Sinken (heute nur Abstand zu Jägern).
- Missions-Bausteine: `ChaseObjective` (folgen), `EscapeObjective` (abhängen).
- Test im Rauchtest: Fahndung 45 → eine Streife erscheint; Spieler 90 m weg und
  außer Sicht → nach 10 s sinkt die Fahndung.

## Offene Fragen an den Nutzer
- Streifen mit Fahrzeugen in der Fahndung: ja, oder bleibt es zu Fuß?
