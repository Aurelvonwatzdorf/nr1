# Körpergrenze (Implantat-Kapazität, Überlastung, Spiritualität)

- **Status:** Idee
- **Vorbild (nur Inspiration):** Begrenzte Implantat-Kapazität mit Risiko bei
  Überladung in Cyberpunk 2077 (und die Idee, dass zu viel Technik den Menschen
  verändert). Eigene Regeln, eigene Werte.
- **Für wen:** beide; alle Implantate

## Was der Spieler erlebt
Jedes Implantat belegt **Last** und einen **Platz** (Beine, Arme, Haut,
Nervensystem, Augen, Herz). Pro Platz passt eins. Die **Körpergrenze** sagt, wie
viel Last man tragen kann; sie wächst mit **Widerstand** (Level-Up). Man darf sie
überschreiten, aber dann gibt es **Überlastung**: Ab und zu flackert das Bild, die
Figur hört Stimmen, die nicht da sind, und in Spiegelrealitäten steigt die
Verankerung schneller. Und: **Viel Technik im Körper senkt die spirituelle
Belastbarkeit**: Spiritueller Druck wirkt stärker, Beten bringt etwas weniger.

## Warum es zu unserem Spiel passt
- **Eigene, starke Wendung**: Unsere Welt hat zwei Kräfte, Technik (Konzerne) und
  Geist (Geisterwelt, Rafa, Raben). Die Körpergrenze zwingt zu einer Wahl:
  Cyborg oder spirituell, oder ein vorsichtiger Weg dazwischen. Das ist
  Rollenspiel, das zur Story passt.
- Tahirou, im Bund mit Geistern, spürt Überlastung früher (die Raben mögen keine
  Technik); Aurel, aus dem Konzern, verträgt mehr.
- Begrenzt, wie viele der vielen neuen Implantate man gleichzeitig hat.
- Überlastung als Verzerrung nutzt vorhandene Effekte (Verankerung, Overlay).

## Eigene Startwerte (zum Feintunen)
| Wert | Start | Begründung |
|---|---|---|
| Körpergrenze Start | Aurel 10, Tahirou 8 | Figuren-Unterschied |
| + je Widerstand-Stufe | +1 | Levelweg |
| Last: Beine/Haut/Herz/Augen | 2–3 | einfache Teile |
| Last: Arme/Nervensystem | 4–5 | starke Teile |
| Überlastung leicht (bis +3) | Flackern alle ~60 s, Verankerung +25 % | spürbar, spielbar |
| Überlastung schwer (> +3) | dazu Ausdauer-Erholung −20 %, falsche Gegner-Schemen | harte Wahl |
| Spirituelle Last | je 4 Last −1 Spiritualität (nur für Druck) | Technik gegen Geist |
| Beten | Erfahrung −10 % je 4 Last | Gegenkraft |

## Umsetzung im Projekt
- `ItemData`: `implant_slot` (StringName), `implant_load` (int).
- `Inventory`: eingebaute Implantate je Platz (`GameState.installed_implants`);
  heute wirken PERMANENT-Items durch Besitz → für Implantate nur noch, wenn
  eingebaut (Übergang: alles Gekaufte gilt als eingebaut, solange Plätze frei).
- `PlayerStats`: `get_body_limit()`; `Player._apply_stats()` berechnet Überlastung.
- `Player._update_spiritual_pressure()`: effektive Spiritualität −(Last/4).
- Überlastungs-Flackern über Overlay-Parameter (wie Verankerung).
- Test im Rauchtest: zwei Bein-Implantate → nur eins eingebaut; Last 14 bei
  Grenze 10 → `is_overloaded()`; Druckquelle mit Spiritualität 3 und Last 8 →
  wirkt wie Spiritualität 1.

## Offene Fragen an den Nutzer
- Gefällt dir die Regel „Technik senkt Spiritualität“? Sie ist eine große
  Design-Entscheidung (betrifft Rafa, Geisterwelt, Raben).
