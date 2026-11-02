# Konzernnetz (vernetzte Gegner und Geräte)

- **Status:** Idee
- **Vorbild (nur Inspiration):** Gegner und Geräte in einem gemeinsamen lokalen
  Netz, über das sich Hacks ausbreiten und das man über einen Zugangspunkt
  aufdeckt (Cyberpunk 2077). Keine Namen oder Werte übernommen.
- **Für wen:** Aurel (Insider-Ast), Gegner-Design

## Was der Spieler erlebt
Konzernwachen und -geräte eines Gebiets hängen an einem **Netzknoten** (ein
Wachposten, ein Sendemast oder ein Netzwächter). Im Realitätsblick/Scanner sieht
Aurel feine Linien zwischen ihnen. Knackt er den Zugangsknoten des Gebiets oder
erledigt er den Netzwächter, sieht er alle im Netz, und Programme wie
„Kurzschluss“ springen über. Schaltet er den Netzknoten ab, können die Wachen
**keine Verstärkung rufen** (Fahndung steigt langsamer). Umgekehrt: Wird Aurel
von einem Teil des Netzes gesehen, wissen alle, wo er war.

## Warum es zu unserem Spiel passt
- Konzerne beherrschen die Welt über Technik und Kontrolle: Das Netz macht das
  spielbar.
- Gibt Gebieten im Konzernviertel ein Ziel („erst den Knoten, dann die Wachen“),
  ohne Missionstext.
- Verbindet Fahndung (Verstärkung), Schleichen (gemeinsame Sicht) und Hacking.

## Eigene Startwerte (zum Feintunen)
| Wert | Start | Begründung |
|---|---|---|
| Netzgröße | 3–8 Gegner + Geräte | überschaubar |
| Gemeinsame Sicht | Alarm eines Mitglieds → alle suchen dort | Gefahr |
| Knoten abgeschaltet | keine Verstärkung, Fahndungsanstieg × 0,5 im Gebiet | Belohnung |
| Kurzschluss | Störung auf alle im Netz | Endprogramm |
| Netz neu starten | 120 s nach Abschalten | nicht dauerhaft |

## Umsetzung im Projekt
- `CorporateNetwork` (`scripts/systems/corporate_network.gd`, Knoten im Level)
  mit Mitgliederliste; Gegner/Geräte bekommen `network_id` (Export).
- Signale: `member_alerted(position)` → alle `EnemyPerception.investigate()`.
- `WantedSystem` fragt `network.is_online()` für Verstärkung.
- Linien im Realitätsblick: `ImmediateMesh` zwischen Mitgliedern, nur sichtbar,
  wenn `GameState.reality_sight_active` und Figur = Aurel.
- Test im Rauchtest: zwei Wachen im selben Netz, eine sieht den Spieler → die
  andere wechselt in `search`; Knoten aus → nicht mehr.

## Offene Fragen an den Nutzer
- Gibt es das Netz nur im Konzernviertel, oder auch in der Senke (Banden mit
  eigenem, schwächerem Netz)?
