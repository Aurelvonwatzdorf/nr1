# Klangwelt (Grundlage: Geräusche, Raumklang, Stimmen)

- **Status:** Idee
- **Vorbild (nur Inspiration):** Dichter Stadtklang in Cyberpunk 2077 (Gemurmel,
  Verkehr, Regen, Werbung, Hall in Gassen). Keine Klänge übernommen; nur eigene
  oder freie (CC0) Aufnahmen.
- **Für wen:** alles; Grundlage für `radio.md` und `musik_lage.md`

## Was der Spieler erlebt
Heute ist das Spiel **stumm**. Neu: Schritte auf Stein, Metall, Holz, Pfützen;
Schläge, Treffer, Paraden (helles „Ting“, gibt Souls-Rhythmus), Blut, Schüsse mit
Hall; die Stadt summt (Markt-Gemurmel, Neon-Brummen, ferne Gleiter, Regen auf
Blech). Jedes Viertel klingt anders (Gebetsruf, Glocken, Gesang zu ihren Zeiten,
respektvoll und gleich gewichtet; Stille im Haus der Stille). In Spiegel-
realitäten fehlt etwas (kein Echo, Stimmen zu leise). Der Begleiter flüstert
gedämpft „im Kopf“.

## Warum es zu unserem Spiel passt
- Ton ist die Hälfte des Treffer-Gefühls (Hitstop + Klang).
- **Realitätsblick** kann klingen (Welt wird dumpf, wahres Summen darunter);
  Spiegelrealitäten verraten sich durch falschen Klang.
- Viertel-Klänge erzählen, dass hier verschiedene Menschen leben.

## Eigene Startwerte (zum Feintunen)
| Wert | Start | Begründung |
|---|---|---|
| Busse | Master, Musik, Effekte, Stimmen, Umgebung | Lautstärke-Regler im Menü |
| Gleichzeitige Effekte | 32 (iPhone 16) | Leistung |
| Hall | Gassen kurz, Hallen lang, Spiegelrealität keiner | Raumgefühl |
| Quellen | eigene Aufnahmen, CC0 (z. B. freesound CC0, Kenney) | Lizenz sauber, `CREDITS.md` |

## Umsetzung im Projekt
- `default_bus_layout.tres` mit den Bussen; `AudioEffectReverb` je Zone über
  `Area3D` (`ReverbZone`) bzw. Godot-`Area3D.reverb_bus`.
- `SoundBank` (Autoload): Namen → `AudioStreamRandomizer` (Tonhöhen-Streuung),
  `play_at(name, position)`. Aufrufe an den Stellen, die heute schon Signale
  senden (`hit_landed`, `shot_fired`, Schritte über `PlayerAnimator`).
- Schritt-Material: Meta `surface` an Böden/Bauteilen, Strahl nach unten.
- Lautstärke-Regler im Pausenmenü, gespeichert.
- Test im Rauchtest: Treffer → `SoundBank` hat einen Ton gestartet (Zähler).

## Offene Fragen an den Nutzer
- Sollen Gebetsruf/Glocken zu hören sein? (Wir würden sie respektvoll und für
  alle Häuser gleichwertig einsetzen.)
