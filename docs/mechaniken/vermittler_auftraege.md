# Vermittler und Nebenaufträge

- **Status:** Idee
- **Vorbild (nur Inspiration):** Auftraggeber in den Stadtteilen, die Nebenjobs
  per Nachricht anbieten (Cyberpunk 2077). Eigene Figuren, eigene Auftragsarten,
  keine Texte oder Namen übernommen.
- **Für wen:** beide; Missionssystem (vorhanden)

## Was der Spieler erlebt
In jedem Teil der Stadt gibt es einen **Vermittler**: eine Person, die Leute und
Probleme kennt und Aufträge weitergibt. Sie meldet sich per **Nachricht** (HUD:
kurzes Symbol, Text im neuen Nachrichten-Menü), sobald man sie kennt.
Auftragsarten (auch gemischt):
- **Bergen**: etwas oder jemanden aus einem bewachten Ort holen.
- **Ausschalten oder verschonen**: Ziel finden, dann entscheiden (Moral!).
- **Schützen**: jemanden sicher durch ein Viertel bringen.
- **Einbrechen**: Zugangsknoten knacken, Daten stehlen (Aurel) bzw. Raben spähen
  lassen (Tahirou).
- **Spiegelauftrag**: jemand ist in einer Spiegelrealität gefangen – ihn
  herausholen (siehe `erinnerungsspiegel.md` für die Spuren).
Gute Arbeit hebt den **Ruf** beim Vermittler (siehe `ruf.md`) und bringt bessere
Aufträge.

## Warum es zu unserem Spiel passt
- Missionen (`MissionData`) gibt es; es fehlt eine Quelle, die laufend neue
  liefert, und ein Grund, die Viertel zu besuchen.
- Vermittler-Vorschläge (Namen eigene, respektvoll, ohne Klischee):
  Markt: **Joaquín Sal**, Händler mit Augen überall. Senke: **Mama Ojuola**,
  Herrin über die Hüttentürme. Konzernviertel: **„Registratur“**, eine Stimme
  ohne Gesicht. **Caspar** gibt keine Aufträge, sondern Schulden (bleibt eigene
  Mechanik, M10).
- „Ausschalten oder verschonen“ füttert das Moral-Gedächtnis für Rafas Prüfung.

## Eigene Startwerte (zum Feintunen)
| Wert | Start | Begründung |
|---|---|---|
| Vermittler | 3 in Santo Santiago, 1 je Kontinent-Stadt | Anfang |
| Aufträge je Vermittler | 4–6 handgemacht + Ruf-Stufen | Qualität vor Menge |
| Belohnung | 150–600 Geld + Erinnerungen | über Gegnerbeute |
| Verschonen statt töten | −20 % Geld, +Moral | echte Wahl |
| Nachrichten | höchstens 1 neue alle 10 Min. | nicht nerven |

## Umsetzung im Projekt
- `MissionData` erweitern: `giver_id`, `mission_type`, `required_reputation`,
  Ziele als Liste von Bausteinen (`MissionObjective`-Resources: Ort erreichen,
  Gegenstand holen, NPC begleiten, Gegner besiegen/verschonen, Knoten knacken).
- `Fixer` (erbt von `NPC`) + `GameState.known_fixers`, `reputation`.
- Nachrichten: `EventBus.message_received(from, text)`, Menü
  `scenes/ui/messages_menu.tscn` (Taste N, im Pausenmenü auch erreichbar).
- Test im Rauchtest: Vermittler ansprechen → Mission angeboten und gestartet;
  Ziel „verschonen“ erfüllt → Moral-Eintrag + Belohnung.

## Offene Fragen an den Nutzer
- Gefallen dir die Vermittler-Vorschläge (Namen, Rollen)?
- Telefon/Nachrichten in der Welt: passt das zum Stil (es ist Zukunft), oder
  lieber Botenzettel/Raben?
