# Arm-Implantate (Sichelarme, Fadenpeitsche, Rammfäuste, Armwerfer)

- **Status:** Idee
- **Vorbild (nur Inspiration):** Die vier Arm-Implantate in Cyberpunk 2077
  (Klingen im Unterarm, Draht-Peitsche, verstärkte Fäuste, Raketenwerfer im Arm).
  Eigene Namen, eigenes Aussehen, keine Werte übernommen.
- **Für wen:** beide; Schwarzmarkt (Senke) und später Implantat-Arzt
  (`implantat_arzt.md`); **immer nur eins** eingebaut

## Was der Spieler erlebt
Ein Arm-Implantat ersetzt die Nahkampfwaffe: Statt Schwert oder Stab kämpft man
mit dem eigenen Körper. Jedes hat leichten und schweren Angriff und eine Besonderheit:
1. **Sichelarme**: zwei Klingen fahren aus den Unterarmen. Sehr schnell, kurze
   Reichweite. Besonderheit: Sprung + schwerer Angriff = Stoß von oben.
2. **Fadenpeitsche**: ein glühender Faden aus dem Handgelenk. Weite Bögen,
   trifft mehrere. Besonderheit: schwerer Angriff gehalten lädt einen
   Rundumschlag; Aurel mit Glut-Ast: Faden setzt Brand.
3. **Rammfäuste**: schwere Metallfäuste. Langsam, enorme Wucht, brechen
   Blockaden. Besonderheit: schwerer Angriff öffnet verschlossene Gittertüren
   (Weg-Rätsel, „Wucht“-System).
4. **Armwerfer**: ein Rohr im Unterarm. Kein Nahkampf-Ersatz, sondern Zusatz:
   F/Spezialtaste schießt einen kleinen Sprengkörper (Fläche), danach lange
   Abklingzeit. Nur einer der vier.

## Warum es zu unserem Spiel passt
- Cyborg-Implantate gibt es schon (Beine, Haut, Herz). Arme sind der fehlende
  Teil und das deutlichste Cyberpunk-Bild der Hauptstadt.
- Nutzen die **Wucht-Werte** (`AttackData`): keine neue Kampflogik nötig, nur
  neue Angriffsdaten.
- Fadenpeitsche + Glut-Ast, Sichelarme + Tahirous Vollstrecker: Synergien mit
  vorhandenen Bäumen.

## Eigene Startwerte (zum Feintunen)
| Wert | Sichelarme | Fadenpeitsche | Rammfäuste | Armwerfer |
|---|---|---|---|---|
| Leicht: Schaden / Ausdauer | 9 / 10 | 11 / 14 | 16 / 20 | – |
| Leicht: Ausholen | 0,08 s | 0,2 s | 0,3 s | – |
| Schwer: Schaden | 22 | 26 (Kreis 3,5 m) | 45, Wucht bis 20 | 40 Fläche 3 m |
| Reichweite | 1,0 m | 3,2 m | 1,1 m | 25 m |
| Besonderheit | Stoß von oben ×1,5 | Brand mit Glut | bricht Block | Abklingzeit 20 s, 25 Fokus |
| Preis | 1200 | 1500 | 1300 | 1800 |

## Umsetzung im Projekt
- `ItemData.Kind` bekommt `ARM_IMPLANT` (oder WEAPON mit `slot = &"arm"`), damit
  es in `GameState.equipped_weapon` passt; Ausrüsten im Inventar wie heute.
- Angriffe als `.tres` in `resources/attacks/`; Wucht-Felder nutzen.
- Fadenpeitsche: Hitbox als lange flache Box, `windup_turn_factor` hoch.
- Rammfäuste: neues `AttackData.guard_break` (Block des Gegners bricht).
- Armwerfer: kleine Szene `scenes/combat/arm_grenade.tscn`, Fläche mit Rückstoß;
  Aurel nutzt F schon für Hacken → Armwerfer auf `fire` (V), wenn keine
  Schusswaffe ausgerüstet ist.
- `PlayerAnimator._update_weapon_visual()`: Platzhalter-Klingen/Faden/Fäuste.
- Test im Rauchtest: Sichelarme ausrüsten → leichter Angriff hat 0,08 s Ausholen;
  Rammfäuste gegen blockende Wache → Wache taumelt.

## Offene Fragen an den Nutzer
- Darf nur ein Arm-Implantat eingebaut sein, oder zwei (linker/rechter Arm)?
- Armwerfer überhaupt (Sprengstoff passt evtl. weniger zum Soulslike)?
