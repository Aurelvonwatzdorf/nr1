# Implantat-Ärztin (Einbauen, Ausbauen, Werkstatt)

- **Status:** Idee
- **Vorbild (nur Inspiration):** Die Implantat-Ärzte in Cyberpunk 2077 (Händler +
  Einbau in einer Hinterhof-Praxis). Eigene Figur, eigener Name, eigene Regeln.
- **Für wen:** beide; neuer Service-NPC in der Senke (Schwarzmarkt) und eine
  saubere, teure Konzern-Klinik im Konzernviertel

## Was der Spieler erlebt
In einem Hinterzimmer der Senke arbeitet **Nuria Ferro** (Vorschlag), eine
Schrauberin mit ruhigen Händen. Bei ihr baut man Implantate ein und aus (der
Schwarzmarkt verkauft nur), sieht seine Körpergrenze und kann Implantate
**verbessern**. Einbau kostet Geld; man setzt sich in den Stuhl, das Bild wird
schwarz, man wacht mit kurzem Flackern auf. Die **Konzern-Klinik** baut
sicherer ein (keine Nebenwirkung), ist aber doppelt so teuer und meldet Aurel
bei hoher Fahndung an die Spiegeljäger.

## Warum es zu unserem Spiel passt
- Die Körpergrenze braucht einen Ort zum Ein-/Ausbauen.
- Zwei Orte = Arm/Reich der Stadt spielbar (Senke vs. Konzernviertel).
- Gute Figur für Nebenaufträge und Moral (sie behandelt Arme umsonst; hilft man
  ihr, bekommt man Rabatt). Caspar-Verbindung: Wer Schulden hat, wird hier
  manchmal von Assassinen erwartet.

## Eigene Startwerte (zum Feintunen)
| Wert | Start | Begründung |
|---|---|---|
| Einbau Senke | 10 % des Kaufpreises | billig |
| Nebenwirkung Senke | 10 % Chance: 10 Min. leichte Überlastung | Risiko |
| Einbau Klinik | 20 %, keine Nebenwirkung | Sicherheit kostet |
| Klinik bei Fahndung ≥ 60 | ruft Spiegeljäger | Konzern bleibt Konzern |
| Ausbau | gratis, Implantat zurück ins Inventar | Ausprobieren erlauben |
| Verbessern | 2 Stufen je Implantat, Preis × 0,6 / × 1,0 | Langzeitziel |

## Umsetzung im Projekt
- NPC `scripts/npcs/implant_doctor.gd` (erbt von `Merchant` oder `NPC`),
  Menü `scenes/ui/implant_menu.tscn` (Plätze, Last-Balken, Ein/Aus).
- Stand in `GameState.installed_implants`, `implant_levels`.
- Platz in der Senke über `keep_clear` im Level, `MapMarker` (Art Service).
- Test im Rauchtest: Implantat kaufen → nicht eingebaut; bei der Ärztin einbauen
  → `has_permanent_flag()` wahr; ausbauen → falsch.

## Offene Fragen an den Nutzer
- Name und Figur der Ärztin: Vorschlag „Nuria Ferro“. Andere Idee?
- Soll Kaufen direkt einbauen (einfacher), und die Ärztin nur zum Umbauen da sein?
