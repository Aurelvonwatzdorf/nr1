# Wucht (schweres Waffengefühl)

- **Status:** gebaut
- **Vorbild (nur Inspiration):** Wie Soulslikes und Monster Hunter schwere
  Waffen spürbar machen (Ausholen, Festlegen, Durchhalten). Keine Werte übernommen.
- **Für wen:** beide (schwerer Angriff, schwere Waffen), auch Gegner

## Was der Spieler erlebt
Schwere Schläge **fühlen sich schwer an**: Die Figur holt sichtbar aus (man kann
sich in dieser Zeit kaum noch drehen), der Treffer hält das Bild länger an,
die Kamera ruckt in Schlagrichtung, Gegner werden weiter weggestoßen und
taumeln. Während des Schlags lässt sich die Figur von leichten Treffern **nicht
unterbrechen** („Wucht“). Dafür ist man festgelegt: Abbrechen geht nur früh
mit Ausweichen und kostet extra Ausdauer.

## Warum es zu unserem Spiel passt
- Macht den Unterschied zwischen leichtem und schwerem Angriff (Shift +
  Linksklick) klar: Risiko gegen Wirkung, passend zum Ausdauer-Kampf.
- Nutzt, was schon da ist: `HitStop`, `camera_shake_requested`, `knockback`.
- Passt zu beiden Stilen: Aurel (aggressiv, Ehrgeiz für Wucht-Treffer) und
  Tahirou (ruhig, aber brutal).
- Eröffnet eine neue Waffenart: z. B. ein Zweihand-Hammer am Waffenschmied.

## Eigene Startwerte (zum Feintunen)
| Wert | Start | Begründung |
|---|---|---|
| Drehtempo beim Ausholen | 20 % | festgelegt, aber nicht starr |
| Wucht (nicht unterbrechbar) | ab 30 % bis 80 % des Schlags | Fenster sichtbar |
| Wucht hält aus | bis 25 Schaden je Treffer | Bosse brechen sie |
| Hitstop schwer | 0,12 s (statt 0,09) | Wucht spüren |
| Kamera-Ruck | Stärke 0,5 in Schlagrichtung | Richtung statt Zittern |
| Abbrechen (früh) | +10 Ausdauer | Festlegen hat Preis |
| Zweihand-Hammer | 60 Schaden schwer, 35 Ausdauer | neue Waffe, 500 Geld |

## Umsetzung im Projekt
- `AttackData` bekommt: `windup_turn_factor`, `poise_window_start/end`,
  `poise_max_damage`, `hitstop`, `shake_strength`, `cancel_stamina_cost`.
  Standardwerte so, dass leichte Angriffe sich nicht ändern.
- `PlayerAttackState`: Drehtempo und Abbrechen nach den Werten; Hurtbox
  meldet Treffer während Wucht → kein Wechsel zu `hurt`, nur Schaden.
- `player.gd`: `HitStop.apply()` und Kamerawackeln aus den Angriffsdaten.
- `PlayerAnimator`: längeres, sichtbares Ausholen (Platzhalter-Tween).
- Neue Waffe `resources/items/war_hammer.tres` (WEAPON) am Waffenschmied.
- Test im Rauchtest: Spieler im schweren Angriff (Wucht-Fenster) bekommt
  Treffer mit 10 Schaden → bleibt im Angriff; mit 30 Schaden → `hurt`.

## Offene Fragen an den Nutzer
- ~~Hammer mitbauen?~~ Gebaut: Zweihand-Hammer beim Waffenschmied (500 Geld).
- Sollen auch Gegner Wucht bekommen (z. B. schwere Konzernwachen)?
