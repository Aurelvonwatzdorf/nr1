# Gespräche unter Zeitdruck (und Schweigen als Antwort)

- **Status:** Idee
- **Vorbild (nur Inspiration):** Dialogentscheidungen mit ablaufender Zeit in
  angespannten Szenen in Cyberpunk 2077 (und Telltale-Spielen). Keine Texte oder
  Darstellung übernommen.
- **Für wen:** beide; Gesprächssystem (`DialogueBox.ask()`)

## Was der Spieler erlebt
In **angespannten** Gesprächen (Erpressung, Geiselnahme, Konzernheld stellt einen,
Caspars Assassine) läuft unter den Antworten ein Balken ab. Wer nicht rechtzeitig
wählt, **schweigt** – und Schweigen ist eine echte Antwort mit eigenen Folgen
(manchmal die beste). Manche Antworten sind nur mit bestimmten Werten möglich
(Insider-Wissen bei Aurel, Raben-Rat bei Tahirou, hohe Spiritualität,
Ruf im Viertel) und zeigen das kleine Zeichen davor. Ruhige Gespräche haben
**keinen** Zeitdruck.

## Warum es zu unserem Spiel passt
- Tahirou ist ruhig: Bei ihm laufen manche Balken langsamer (Figurengefühl).
  Aurel ist ehrgeizig: Er bekommt manchmal eine zusätzliche, riskante Antwort.
- **Rafas Prüfung bleibt ohne Zeitdruck**: Dort zählt Wahrheit, nicht Tempo
  (unwahre Antworten sind ausgegraut). Bewusster Gegensatz.
- Schweigen als Antwort passt zur ernsten Stimmung; ins Moral-Gedächtnis kann es
  eingehen (z. B. Schweigen, wo man jemanden hätte verteidigen können).

## Eigene Startwerte (zum Feintunen)
| Wert | Start | Begründung |
|---|---|---|
| Zeit (angespannt) | 8 s | lesen + entscheiden |
| Tahirou | × 1,3 Zeit | ruhig |
| Welt währenddessen | steht (Gespräch pausiert) | fair; Spannung über Balken |
| Werte-Antworten | Zeichen + Bedingung im Hinweis | klar |
| Rafas Prüfung | kein Zeitdruck | bewusst |

## Umsetzung im Projekt
- `DialogueBox.ask(name, text, answers, timeout := 0.0, silence_index := -1)`:
  Rückgabe `-1` oder `silence_index` bei Ablauf; Balken-`Control` unter den Antworten.
- Antworten mit Bedingung: Struktur `{text, requires: {skill/stat/reputation}}`;
  heute sind Antworten einfache Strings → rückwärtskompatibel erweitern.
- Test im Rauchtest: `ask` mit 1 s Zeit, keine Eingabe → Ergebnis = Schweigen.

## Offene Fragen an den Nutzer
- Soll die Welt im Gespräch stehen bleiben, oder (spannender, schwerer)
  weiterlaufen?
