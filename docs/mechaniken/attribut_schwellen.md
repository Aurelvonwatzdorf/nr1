# Attribut-Schwellen (Attribute schalten Vorteile frei)

- **Status:** Idee
- **Vorbild (nur Inspiration):** Attribute, die bestimmen, welche Vorteile
  (Perks) man wählen kann, in Cyberpunk 2077 (und Waffen-Anforderungen in
  Souls-Spielen). Keine Perk-Namen, Bäume oder Werte übernommen.
- **Für wen:** beide; vorhandene Stats (`PlayerStats`) und Fähigkeitenbäume

## Was der Spieler erlebt
Heute gibt jede Stufe eines Attributs einen kleinen Prozentwert (z. B. Stärke +5 %
Schaden). Neu: Bei **Stufe 5, 10 und 15** eines Attributs schaltet sich zusätzlich
ein **spürbarer Vorteil** frei, angezeigt im Rast-Menü („Nächster Vorteil bei 10:
…“). Beispiele (eigene Ideen):
| Attribut | 5 | 10 | 15 |
|---|---|---|---|
| Stärke | schwere Waffen ohne Abzug | Rammfäuste brechen Türen | Aufschlag-Fläche +50 % |
| Schnelligkeit | Gleitschritt länger | Ausweichen kostet −20 % | zweite Rolle direkt nacheinander |
| Ausdauer | Sprint kostet −25 % | Ausdauer erholt beim Blocken | Wandlauf +0,5 s |
| Widerstand | Körpergrenze +2 | Fallschaden −30 % | Überlastung leicht ohne Strafe |
| Fokus | Realitätsblick +2 s | Hacks/Tarnung −20 % Fokus | Musterblick zeigt Schwachstellen |
| Spiritualität | Raben/Ehrgeiz-Bonus nahe Geistern | Druckquellen-Schaden −50 % | Geister sprechen einen an |

Außerdem haben **Waffen und Implantate Mindestwerte** (z. B. Zweihand-Hammer
Stärke 6): Darunter geht es, aber mit Abzug (langsamer, mehr Ausdauer).

## Warum es zu unserem Spiel passt
- Macht das Leveln am Ankerspiegel spannender: Man plant auf Schwellen hin.
- Die **Fähigkeitenbäume** (je Figur) bleiben das Herz; Schwellen sind gemeinsam
  und neutral.
- Spiritualität bekommt Belohnungen über den Druck hinaus (sie levelt nur durch
  Beten – das wird damit wertvoller, gleich für alle Häuser).
- Mindestwerte = Souls-Gefühl („Ich brauche noch zwei Stärke für den Hammer“).

## Eigene Startwerte (zum Feintunen)
| Wert | Start | Begründung |
|---|---|---|
| Schwellen | 5 / 10 / 15 | klar, merkbar |
| Unter Mindestwert | Schaden × 0,7, Ausdauer × 1,3 | spürbar, nicht verboten |
| Höchststufe | 20 | Platz für die Schwellen |

## Umsetzung im Projekt
- `PlayerStats`: `THRESHOLDS` (Dictionary Stat → Liste von {Stufe, id, Text});
  `has_threshold(id)`.
- Wirkung im Code an den betroffenen Stellen (wie `GameState.has_skill()`).
- `ItemData`: `required_stats` (Dictionary). `Player.get_damage_multiplier()` und
  `AttackState` prüfen es.
- `RestMenu`: Zeile „Nächster Vorteil“ unter jedem Attribut.
- Test im Rauchtest: Schnelligkeit auf 10 → Ausweichen kostet 16 statt 20.

## Offene Fragen an den Nutzer
- Sind dir die Beispiel-Vorteile recht, oder willst du die Liste selbst mitgestalten?
