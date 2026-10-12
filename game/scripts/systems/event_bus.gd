extends Node
## Globaler Signal-Verteiler (Autoload „EventBus“).
##
## Systeme, die sich nicht direkt kennen sollen (HUD, Gegner, Speichern …),
## kommunizieren über diese Signale. Wer etwas meldet, ruft `EventBus.x.emit(...)`,
## wer zuhören will, verbindet sich mit `EventBus.x.connect(...)`.

## Die Spielfigur ist in der Szene bereit.
signal player_spawned(player: Player)
## Die Spielfigur ist gestorben (M2: Erinnerungen fallen lassen).
signal player_died(player: Player)
## Irgendein Ziel hat Schaden genommen (z. B. für Statistiken oder Tutorials).
signal damage_dealt(target: Node, amount: float)
## Die Währung „Erinnerungen“ hat sich geändert.
signal memories_changed(amount: int)
