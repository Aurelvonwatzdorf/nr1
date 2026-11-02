# Kleidung mit Werten

- **Status:** Idee
- **Vorbild (nur Inspiration):** Kleidung mit Schutzwerten und Plätzen
  (Kopf, Gesicht, Oberkörper, Beine, Füße) in Cyberpunk 2077 (und Rüstungen in
  Souls-Spielen). Keine Kleidungsstücke, Namen oder Werte übernommen.
- **Für wen:** beide; Händler, Funde

## Was der Spieler erlebt
Die Figur trägt **vier Plätze**: Kopf (Kapuze, Hut, Helm), Tuch/Maske, Mantel/
Oberteil, Hose/Stiefel. Jedes Teil hat **Schutz** (weniger Schaden), **Gewicht**
(schwer = Rolle langsamer, Ausdauer erholt langsamer) und manchmal eine
**Eigenschaft**: Kapuze = schwerer zu erkennen (Schleichen), Wüstentuch =
weniger Druck von Sandstürmen in Kemet, Konzern-Anzug = Konzernwachen
misstrauen später (Fahndung sinkt schneller), zerfranster Mantel = leiser.
Kleidung sieht man an der Figur (nach den Figuren-Modellen).

## Warum es zu unserem Spiel passt
- Stil-Leitfaden: Kapuzen, Tücher, Masken, zerfranste Stoffe, große Silhouetten
  – Kleidung ist ein Kern des Looks.
- **Gewicht** statt reiner Werte: Souls-Gefühl (leichte Rolle gegen Schutz).
- Eigenschaften verbinden Kleidung mit Schleichen, Fahndung, Regionen.
- Aurels Weg sichtbar machen: Start im gepflegten Konzern-Anzug, später
  zerrissen (Stil-Leitfaden).

## Eigene Startwerte (zum Feintunen)
| Wert | Start | Begründung |
|---|---|---|
| Schutz gesamt | 0–35 % | Implantate (Dermalpanzerung) kommen dazu, Höchstwert 60 % |
| Gewicht | leicht < 30 %, mittel < 70 %, schwer darüber (von Tragkraft) | drei Rollen-Arten |
| Rolle schwer | Dauer +25 %, I-Frames gleich | Souls |
| Tragkraft | 20 + 2 × Ausdauer-Stufe | Attribut lohnt sich |
| Eigenschaften | 1 je besonderem Teil | übersichtlich |

## Umsetzung im Projekt
- `ItemData.Kind.CLOTHING` mit `wear_slot`, `armor`, `weight`, `clothing_trait`.
- `GameState.equipped_clothing` (Dictionary Platz → id), gespeichert.
- `Player._filter_incoming_hit()`: Schutz; `DodgeState`: Rollen-Art nach Gewicht.
- `PlayerAnimator`: Teile an der Figur (erst Platzhalter-Formen, später Modelle).
- Inventar: Reiter „Kleidung“.
- Test im Rauchtest: schwerer Mantel → Rolle dauert 0,625 s; Kapuze →
  `EnemyPerception`-Sichtweite × 0,9.

## Offene Fragen an den Nutzer
- Kleidung erst nach den echten Figuren-Modellen (damit man sie sieht)?
