extends Node
## Globaler Signal-Verteiler (Autoload „EventBus“).
##
## Systeme, die sich nicht direkt kennen sollen (HUD, Gegner, Speichern …),
## kommunizieren über diese Signale. Wer etwas meldet, ruft `EventBus.x.emit(...)`,
## wer zuhören will, verbindet sich mit `EventBus.x.connect(...)`.

## Die Spielfigur ist in der Szene bereit.
signal player_spawned(player: Player)
## Die Spielfigur ist gestorben.
signal player_died(player: Player)
## Die Spielfigur wurde am Checkpoint wiederbelebt.
signal player_respawned(player: Player)
## Die Kamera soll wackeln (0.0 bis 1.0, 1 = sehr stark).
signal camera_shake_requested(strength: float)
## Irgendein Ziel hat Schaden genommen (z. B. für Statistiken oder Tutorials).
signal damage_dealt(target: Node, amount: float)
## Ein Gegner wurde besiegt.
signal enemy_killed(enemy: Enemy)
## Ein Checkpoint wurde aktiviert (neuer Wiederbelebungsort).
signal checkpoint_activated(checkpoint: Node3D)
## Die verlorenen Erinnerungen wurden an der Todesstelle zurückgeholt.
signal memories_recovered(amount: int)
## Die Erinnerungen der vorherigen Todesstelle sind endgültig verloren.
signal memories_lost(amount: int)
## Die Währung „Erinnerungen“ hat sich geändert.
signal memories_changed(amount: int)
