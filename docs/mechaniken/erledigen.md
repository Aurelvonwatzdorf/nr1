# Erledigen (lautlos: tödlich oder betäuben)

- **Status:** gebaut (geduckt von hinten: E = betäuben 2 s, E halten = töten 1 s,
  Treffer bricht ab, Bewusstlose liegen 5 Min.). **Nutzer-Entscheidung Moral:**
  Töten von hinten ist neutral; nur einen Wehrlosen (Bewusstlosen) zu töten zählt
  (−6 „Schwache schützen“). Offen: Körper tragen/verstecken, Wachen finden
  Körper, Fahndung nur bei Zeugen.
- **Vorbild (nur Inspiration):** Gegner von hinten greifen und wahlweise töten
  oder ausschalten in Cyberpunk 2077 (auch Dishonored). Keine Animationen/Namen.
- **Für wen:** beide; Moral-Gedächtnis

## Was der Spieler erlebt
Schleicht man unbemerkt hinter einen Gegner, erscheint „E: Betäuben · Halten:
Töten“. Betäuben würgt ihn in ca. 2 s bewusstlos (leise), Töten geht schneller,
aber blutig, und ist hörbar für Gegner sehr nah dabei. Bewusstlose und Tote kann
man aufheben und verstecken (Container, dunkle Ecken), damit andere Wachen sie
nicht finden. Finden sie einen Körper, werden sie misstrauisch und suchen.

## Warum es zu unserem Spiel passt
- **Moral-Gedächtnis**: die Wahl Töten/Betäuben ist genau, was Rafa später
  prüft. Betäuben zählt nicht negativ; Töten von Wehrlosen zählt als „Rache an
  Wehrlosen“ nur, wenn das Opfer keine Gefahr war (z. B. eine schlafende
  Wache in einem Gebiet, in dem man nur durch wollte). Das macht die Wahl spannend.
- Abgrenzung zu Tahirous **Hinrichtung** (Vollstrecker-Ast): die gilt im offenen
  Kampf gegen wehrlose/parierte Gegner. Erledigen ist leise und von hinten.
- Für die Fahndung: Lautlos erledigte Konzernwachen erhöhen sie nur, wenn es
  jemand gesehen hat.

## Eigene Startwerte (zum Feintunen)
| Wert | Start | Begründung |
|---|---|---|
| Winkel hinter dem Gegner | ±60° vom Rücken | nicht von der Seite |
| Abstand | ≤ 1,6 m | Nähe nötig |
| Betäuben | 2,0 s, angreifbar, bricht bei Treffer ab | Risiko |
| Töten | 1,0 s | schneller, aber Moral |
| Lärm Töten | 4 m | sehr nah hört man es |
| Bewusstlos | bis man das Gebiet verlässt bzw. 5 Min. | einfach |
| Körper tragen | Tempo 2,5 m/s, kein Sprint, kein Kampf | Verletzlichkeit |
| Moral Töten wehrlos | −6 „Schwache schützen“ einmal je Gegner | nicht zu hart |
| Erinnerungen | Töten volle Belohnung, Betäuben 60 % | kleine Versuchung |

## Umsetzung im Projekt
- `Enemy` wird zusätzlich `Interactable`-artig: Kind `TakedownPrompt`
  (Interaktion-Ebene), nur aktiv, wenn `EnemyPerception` nicht alarmiert und
  Spieler im Rückenwinkel. Lange Taste über `Input.is_action_pressed` mit Zeit.
- Neue Gegnerzustände `Unconscious` (liegt, nicht anvisierbar) und
  `PlayerTakedownState` beim Spieler (Position an den Gegner einrasten).
- Tragen: Zustand `Carry`, Körper als Kind des Spielers; Verstecken in
  `BodyHideout` (Interactable).
- `MoralMemory.record()` mit Tat-ID `takedown_kill_<enemy_id>`.
- `GameState`: bewusstlose/versteckte Körper nicht speichern (Gebiet setzt sich
  beim Rasten zurück wie Gegner).
- Test im Rauchtest: Spieler hinter Wache, E kurz → nach 2 s Zustand
  `unconscious`; Moral unverändert; Halten → tot, Moral −6.

## Offene Fragen an den Nutzer
- Zählt Töten einer Konzernwache von hinten moralisch negativ, oder nur bei
  wirklich Wehrlosen (Schlafende, Gefesselte)?
