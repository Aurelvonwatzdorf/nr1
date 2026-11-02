# Trefferzonen (Kopf, Körper, Glieder)

- **Status:** Idee
- **Vorbild (nur Inspiration):** Körperteiltreffer in Cyberpunk 2077 (Kopfschuss
  mehr Schaden, Gliedmaßen abtrennen). Keine Werte übernommen.
- **Für wen:** beide; Gegner

## Was der Spieler erlebt
Treffer am Kopf machen mehr Schaden (eigene Trefferzahl in Gold, helles
Klicken), Treffer an Armen/Beinen weniger, aber mit Wirkung: Ein getroffener
Waffenarm lässt den nächsten Gegnerschlag schwächer ausfallen, getroffene Beine
machen ihn kurz langsamer. Besonders brutale Treffer (Tahirous Vollstrecker-Ast,
schwere Waffen, Fadenpeitsche) können Gliedmaßen abtrennen. Blut ist ja sichtbar.

## Warum es zu unserem Spiel passt
- Belohnt Präzision: Tahirou („präzise und ruhig, aber brutal“).
- Aurels Fähigkeit „Schwachstellenwissen“ kann zu „Konzernwachen haben eine
  Schwachstelle am Nacken-Anschluss“ werden.
- Im Nahkampf nur grob (hoher Schlag/tiefer Schlag), sonst wird es fummelig;
  vor allem für Schusswaffen und Wurfmesser.

## Eigene Startwerte (zum Feintunen)
| Zone | Schaden | Wirkung |
|---|---|---|
| Kopf | × 1,8 (Schuss), × 1,25 (Nahkampf) | goldene Zahl |
| Rumpf | × 1,0 | – |
| Arme | × 0,8 | nächster Gegnerangriff −30 % für 4 s |
| Beine | × 0,8 | Tempo −40 % für 3 s |
| Abtrennen | nur bei tödlichem Treffer, Waffe mit `can_dismember` | rein optisch + Moral: zählt als Grausamkeit nur bei wehrlosen Opfern |

## Umsetzung im Projekt
- Gegner bekommen mehrere `Hurtbox`-Kinder mit `zone` (&"head", &"torso",
  &"arm", &"leg") statt einer. `Hurtbox` erhält `zone_multiplier`; `HitData` die
  getroffene Zone, damit `Enemy._on_hit_received()` Wirkungen setzen kann.
- Nahkampf-Hitboxen treffen weiterhin pro Ziel nur einmal (`Hitbox` merkt den
  Besitzer, nicht die Hurtbox).
- `BloodEffect`: stärkerer Ausstoß bei Kopf/Abtrennen.
- `MoralMemory`: Abtrennen an wehrlosen NPCs → „Grausamkeit“.
- Test im Rauchtest: Schuss auf Kopfhöhe der Puppe → Schaden 25; auf Beinhöhe → 11
  und Puppe-Tempo halbiert.

## Offene Fragen an den Nutzer
- Abtrennen von Gliedmaßen ja/nein (es passt zum „brutal“, ist aber Aufwand für
  Modelle)?
