# Fernzugriff (Gegner hacken)

- **Status:** gebaut (Störung + Waffensperre; Fehlbefehl kommt später)
- **Vorbild (nur Inspiration):** Hacken von Gegnern aus der Ferne
  (z. B. Cyberpunk 2077, Watch Dogs). Keine Programme, Namen oder Werte übernommen.
- **Für wen:** Aurel (Ast **Insider**), nur gegen Konzern-Technik

## Was der Spieler erlebt
Aurel visiert eine Konzernwache an (Tab) und drückt **F**. Über der Wache
erscheint ein kurzer Ring, der sich füllt (Hochladen, ca. 1 s). In dieser Zeit
darf Aurel nicht getroffen werden, sonst bricht es ab. Gelingt es, passiert je
nach freigeschalteter Stufe etwas:
1. **Störung**: Die Wache zuckt und taumelt (wie nach einem Parieren).
2. **Waffensperre**: Ihre nächsten Angriffe sind schwach (halber Schaden, 8 s).
3. **Fehlbefehl** (spät, über Story): Sie greift kurz andere Konzernkräfte an.

## Warum es zu unserem Spiel passt
- Aurel kommt aus dem Konzern: Er kennt dessen Technik. Das füllt den
  Insider-Ast mit einer aktiven Fähigkeit (bisher nur passive Werte).
- **F** ist für Aurel frei (bei Tahirou ruft F die Raben). Gleiche Taste,
  gleiche Rolle: „die eigene Besonderheit einsetzen“.
- Kostet **Ehrgeiz** und Fokus: Wer aggressiv kämpft, kann öfter hacken.
- Wirkt nur auf `faction == &"corporate"`. Gegen Geister und Wesen nutzlos.
- Hacken zählt in Santo Santiago zur Fahndung wie ein Angriff auf Konzernkräfte (+12).

## Eigene Startwerte (zum Feintunen)
| Wert | Start | Begründung |
|---|---|---|
| Hochladen | 1,0 s | riskant mitten im Kampf |
| Reichweite | 15 m | auf Lock-on-Abstand |
| Kosten | 40 Ehrgeiz + 10 Fokus | spiegelt Rabenschwarm (ab halbem Balken) |
| Störung | 1,5 s taumeln | wie Parieren |
| Waffensperre | 8 s, −50 % Schaden | spürbar, aber nicht tödlich |
| Abklingzeit je Gegner | 12 s | keine Dauersperre |

## Umsetzung im Projekt
- Neue Fähigkeiten in `resources/skills/aurel_tree.tres` (Ast Insider):
  `aurel_hack_disrupt`, `aurel_hack_jam`, `aurel_hack_misdirect` (letzte mit
  `story_flag`). Die heutigen Knoten bleiben; ggf. Kosten neu verteilen.
- `Player`: Taste `call_spirit` → je nach `special_resource` Raben oder Hacken
  (`AmbitionComponent` bekommt `spend()`).
- `Enemy`: `receive_hack(kind)`, `hack_cooldown`, Wirkung über `stagger`-State
  bzw. einen Schadensfaktor auf der eigenen Hitbox.
- HUD: Ring über dem Ziel (Lock-on-Punkt).
- Test im Rauchtest: Aurel mit Ehrgeiz 50, Wache anvisiert, F → nach 1 s
  taumelt die Wache, Ehrgeiz −40; Treffer während des Ladens bricht ab.

## Offene Fragen an den Nutzer
- Gebaut sind „Fernzugriff“ (Störung) und „Waffensperre“ im Insider-Ast.
  „Fehlbefehl“ braucht Gegner, die einander angreifen können: später.
- Darf Aurel später auch Technik in der Welt hacken (Türen, Kameras)?
