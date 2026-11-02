# Waffen-Aufsätze und Gütestufen

- **Status:** Idee
- **Vorbild (nur Inspiration):** Waffenmods und Seltenheitsstufen in Cyberpunk
  2077 (auch Souls-Verstärkung am Schmied). Eigene Stufennamen und -farben, keine
  Werte übernommen.
- **Für wen:** beide; Waffenschmied, Schwarzmarkt, Funde

## Was der Spieler erlebt
Waffen gibt es in **fünf Gütestufen**, erkennbar an Farbe und Namen:
**Rostig** (grau) · **Gefertigt** (weiß) · **Geschliffen** (grün) · **Meisterwerk**
(blau) · **Ahnenstück** (gold, einzigartig, mit eigener Geschichte und Fähigkeit).
Beim Waffenschmied kann man eine Waffe für Geld und Material eine Stufe hochziehen
(Souls-Gefühl: die Lieblingswaffe behalten). Je nach Stufe hat sie 0–3
**Aufsatz-Plätze**: z. B. Glutkern (Brandschaden), Ruhepunkt (weniger Ausdauer
pro Schlag), Spiegelschliff (mehr Schaden gegen Illusionswesen),
Schalldämpfer (Schusswaffe leise), Lauf-Verlängerung (Reichweite).

## Warum es zu unserem Spiel passt
- Wir haben bisher wenige feste Waffen. Gütestufen + Aufsätze geben Langzeitziele
  und Gründe, Geld zu verdienen (und sich bei Caspar zu verschulden!).
- **Hochstufen statt ständig neue Waffen** passt besser zu Souls als
  zufällige Beute im Loot-Stil. Keine zufälligen Werte (Rerolls): jede Waffe ist
  vorhersehbar.
- Ahnenstücke = Story-Belohnungen (Bosse, Geisterwelt, Konzernhelden).
- „Spiegelschliff“ verbindet Ausrüstung mit den Spiegelrealitäten.

## Eigene Startwerte (zum Feintunen)
| Stufe | Schaden | Plätze | Hochstufen (Geld + Material) |
|---|---|---|---|
| Rostig | × 0,85 | 0 | – |
| Gefertigt | × 1,0 | 1 | 200 + 2 Schrott |
| Geschliffen | × 1,15 | 1 | 500 + 3 Legierung |
| Meisterwerk | × 1,3 | 2 | 1200 + 2 Kernsplitter |
| Ahnenstück | × 1,45 + Fähigkeit | 3 | nur als Fund/Belohnung |

| Aufsatz | Wirkung | Preis |
|---|---|---|
| Glutkern | 15 % Chance Brand (nutzt `apply_burn`) | 400 |
| Ruhepunkt | −20 % Ausdauer je Schlag | 450 |
| Spiegelschliff | +30 % gegen Illusionswesen/Spiegeljäger | 600 |
| Schalldämpfer | Schuss erhöht Fahndung nicht, Lärm 5 m | 500 |
| Visierstein | Streuung −30 % | 350 |

## Umsetzung im Projekt
- `ItemData`: `tier` (int 0–4), `mod_slots`; neue Art `ItemData.Kind.MOD` mit
  `mod_effect` (StringName) und Werten.
- Ausrüstungs-Stand pro Waffe in `GameState.weapon_states` (Stufe + Aufsätze),
  in `to_dict()/from_dict()/reset()`.
- `Player.get_damage_multiplier()` + `_modify_outgoing_damage()` lesen Stufe/Aufsätze.
- Waffenschmied: neue Dialog-Option „Verbessern“ (`Merchant` erweitern oder
  `Blacksmith` erbt von `Merchant`).
- Material als CONSUMABLE-Items (Schrott, Legierung, Kernsplitter) von Gegnern
  und Fundorten.
- Inventar: Farbe der Gütestufe am Namen.
- Test im Rauchtest: Kurzschwert auf Stufe 2 → Schaden × 1,15; Glutkern ein →
  `apply_burn` wird mit Zufall 0 ausgelöst (Zufall im Test fest einstellen).

## Offene Fragen an den Nutzer
- Fünf Stufen gut, oder lieber nur „normal / verbessert / Ahnenstück“?
