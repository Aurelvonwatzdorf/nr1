# Viele Figuren günstig darstellen

- **Status:** Idee
- **Vorbild (nur Inspiration):** Dichte Menschenmengen in Cyberpunk 2077 (ferne
  Figuren sind einfacher als nahe). Eigene Lösung mit Godot-Mitteln.
- **Für wen:** Technik; Stadtvolk (`stadtvolk.md`), Verkehr

## Was der Spieler erlebt
Der Markt wirkt voll, ohne dass das Spiel ruckelt. Man merkt nicht, dass die
meisten Leute in der Ferne nur „Kulisse“ sind: Sie laufen, bleiben stehen,
drehen sich. Kommt man näher, werden sie zu richtigen Bürgern, die man ansprechen
kann.

## Warum es zu unserem Spiel passt
- Heute ist jeder Bürger ein vollständiger `NPC` (CharacterBody3D, State-Logik,
  Hurtbox, Interaktion). Das ist für 46 gut, aber nicht für 200.
- Wenn echte Figuren-Modelle mit Skelett kommen (nächster Schritt laut STAND.md),
  werden Figuren noch teurer. Die Lösung sollte also **vor** vielen Modellen stehen.

## Eigene Startwerte (zum Feintunen)
| Stufe | Abstand | Was läuft |
|---|---|---|
| Voll | < 25 m | `Citizen` mit Physik, Gesprächen, Hurtbox, Animation 60/s |
| Einfach | 25–60 m | Bewegung ohne Physik entlang Wegpunkten, Logik 10/s, Animation 15/s |
| Kulisse | 60–150 m | MultiMesh-Instanzen, Bewegung im Shader / alle 0,2 s |
| Unsichtbar | > 150 m | nur Zahl je Straße, nichts gezeichnet |
| Wechsel Voll ↔ Einfach | mit 5 m Puffer | kein Flackern |

## Umsetzung im Projekt
- `CrowdManager` (Level-Knoten): verwaltet „Personen“ als leichte Daten (Position,
  Ziel, Aussehen, Viertel). Nur die nächsten N werden zu echten `Citizen`
  (aus einem **Pool**, nicht neu erzeugt).
- Kulisse: `MultiMeshInstance3D` je Aussehen; Laufbewegung über
  **Vertex-Animation-Textur** (Animation in eine Textur gebacken, eigener
  Shader) sobald es Modelle gibt; bis dahin Kapsel mit Wippen im Shader.
- Logik-Takt: `Citizen._npc_physics()` nur jeden n-ten Frame bei „Einfach“.
- Bürger-IDs (`citizen_<viertel>_<n>`) bleiben fest für das Moral-Gedächtnis:
  Der Pool übernimmt die ID der Person, die nah kommt.
- Test im Stadt-Test: 200 Personen, Spieler läuft 100 m → Zahl echter `Citizen`
  bleibt ≤ 30; Bildzeit stabil.

## Offene Fragen an den Nutzer
- Keine – rein technisch. Reihenfolge: nach Detailstufen, vor großen Mengen.
