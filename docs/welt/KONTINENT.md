# Der Kontinent: Aurion

Entwurf von Claude (der Nutzer hat für diese Aufgabe freie Hand gegeben).
Alles hier ist **vorläufig** und kann jederzeit geändert werden. Daten stehen in
`game/resources/world/continent.tres`, der Aufbau in
`game/scripts/world/continent_generator.gd`.

## Grundidee: Zeitinseln
Vor Generationen testeten die Konzerne ihre Spiegeltechnik zum ersten Mal an
einem ganzen Land. Der Versuch misslang: Beim **Zeitbruch** zersprang der
Kontinent in **Zeitinseln**. Jede Region blieb in einer anderen Epoche
stehen, aber die Menschen darin sind echt und leben ihr Leben weiter.
Die Grenzen zwischen den Regionen sind spürbar (Wetter, Licht, Pflanzen
wechseln), aber man kann frei wandern.

- Die Regionen sind **echt**, keine Spiegelrealitäten.
- Die Konzerne wollen die Zeitinseln ausbeuten (Rohstoffe, Wissen,
  Arbeitskraft). Das treibt spätere Missionen an.
- Ob in einigen Regionen doch Illusionen stecken, bleibt ein Story-Geheimnis
  (Idee für später: Der Realitätsblick zeigt an manchen Orten Risse).

## Vorbilder (nur Inspiration, nichts übernommen)
- **Große Fantasy-Open-Worlds**: Wahrzeichen, die man von weit her sieht und
  die einen hinlocken; jede Region hat ihre eigene Stimmung.
- **Regionsnamen als Titelkarte** beim ersten Betreten (großer Schriftzug
  in der Bildmitte).
- **Japanische Samurai-Abenteuer**: Farbfelder (rote Ahornbäume, goldenes Gras),
  Schreine auf Bergen.
- **Historische Abenteuer im alten Ägypten**: Pyramiden am Horizont, grüner
  Flussstreifen in der Wüste.
- **Cyberpunk-Städte**: leuchtende Skyline der Hauptstadt.

## Die Regionen
| Region | Epoche | Lage | Stil und Wahrzeichen |
|---|---|---|---|
| **Santo Santiago** | Zukunft (Cyberpunk) | Mitte | Hauptstadt, leuchtende Skyline, Stadtmauer, Südtor. Betreten über das Tor. |
| **Die Narbe** | Verwüstete Zukunft | Norden | Krater, Konzern-Bohrtürme, Schrott, rostiger Boden. Erste Gefahrenzone. |
| **Kagerō-Gebirge** | Zeit der Schreine (japanisch inspiriert) | Nordosten | Hohe Berge, rote Ahornwälder, Torii-Pfad hinauf zum **Bergtempel** (Ritualort für M8.5), Pagode. |
| **Die Ewige Steppe** | Zeit der Reiterclans (mongolisch inspiriert) | Nordwesten | Weites Grasland, Jurtenlager, Steinhügel (Ovoo) mit blauen Tüchern, Hirschsteine. |
| **Grauwald-Mark** | Mittelalter | Westen | Bewaldete Hügel, Burg auf dem Hügel, Fachwerkdorf, Windmühle, Kapelle, Steinbrücke. |
| **Nebelwald** | Zeitlos (Geister) | Südwesten | Riesige leuchtende Bäume, Nebel, ein zweiter Geisterschrein (Spiritualität 5). |
| **Sonnenreich Kemet** | Altes Ägypten | Süden | Wüste, Fluss mit Palmen, Pyramiden, Obelisken, Säulentempel, Wächterlöwe. |
| **Neu-Vallis** | Gegenwart | Osten | Vorstadt mit Häusern, Tankstelle, Funkmast, Stadion, Landstraße. |
| **Die Gläserne Küste** | Ferne Zukunft | Osten am Meer | Weiße Türme, schwebende Bahn, Glaskuppeln. Konzernsitz der Zukunft. |

Respekt: Japanische, mongolische und ägyptische Elemente zeigen Architektur
und Alltag, nie Klischees. Heilige Orte (Schreine, Kapelle, Ovoo) sind
friedliche Orte.

## Spielmechanik der Welt
- **Entdecken**: Beim ersten Betreten einer Region erscheint ihr Name groß
  (Titelkarte). Erst dann steht sie auf der großen Karte; vorher "???".
  Gespeichert in `GameState.discovered_regions`.
- **Ankerspiegel** in jeder Region (Rasten, Speichern, Wiederbeleben).
- **Wege**: Landstraßen verbinden alle Regionen mit Santo Santiago.
- **Reisen**: Südtor von Santo Santiago ↔ Tor vor der Stadt auf dem Kontinent.
- **Bewohner**: In jeder Region leben ein paar Menschen mit eigenen Sätzen.

## Später (Ideen)
- Schnellreise zwischen entdeckten Ankerspiegeln.
- Eigene Gegner je Region, Missionen, Händler.
- Wetter je Region (Sand in Kemet, Schnee im Gebirge, Nebel im Nebelwald).
- Die Narbe als Konzern-Schauplatz mit Spiegeljägern.
