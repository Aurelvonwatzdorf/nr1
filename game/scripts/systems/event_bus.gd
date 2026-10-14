extends Node
## Globaler Signal-Verteiler (Autoload „EventBus“).
##
## Systeme, die sich nicht direkt kennen sollen (HUD, Gegner, Speichern …),
## kommunizieren über diese Signale. Wer etwas meldet, ruft `EventBus.x.emit(...)`,
## wer zuhören will, verbindet sich mit `EventBus.x.connect(...)`.

## Die Spielfigur ist in der Szene bereit.
signal player_spawned(player: Player)
## Die gespielte Figur wurde gewählt oder gewechselt.
signal character_changed(data: CharacterData)
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
## Text der Interaktion in Reichweite („Rasten“) oder "" für keine.
signal interaction_prompt_changed(prompt: String)
## Ein Menü wurde geöffnet (true) oder alle Menüs geschlossen (false).
signal menu_state_changed(is_open: bool)
## Der Spielstand wurde gespeichert.
signal game_saved
## Eine Mission wurde angenommen.
signal mission_started(mission: MissionData)
## Eine Mission wurde erfüllt.
signal mission_completed(mission: MissionData)
## Eine Mission ist gescheitert.
signal mission_failed(mission: MissionData)
## Eine Fähigkeit wurde freigeschaltet.
signal skill_unlocked(skill: SkillData)
## Story-Fortschritt erreicht.
signal story_flag_set(flag: StringName)
## Kurze Meldung für das HUD.
signal message_requested(text: String)
## Die Spielfigur hat an einem Ankerspiegel gerastet.
signal anchor_mirror_rested(mirror: Node3D, player: Player)
## Ein Ankerspiegel wurde zum ersten Mal benutzt (neuer Wiederbelebungsort).
signal checkpoint_activated(checkpoint: Node3D)
## Die verlorenen Erinnerungen wurden an der Todesstelle zurückgeholt.
signal memories_recovered(amount: int)
## Die Erinnerungen der vorherigen Todesstelle sind endgültig verloren.
signal memories_lost(amount: int)
## Das Geld hat sich geändert.
signal money_changed(amount: int)
## Die Währung „Erinnerungen“ hat sich geändert.
signal memories_changed(amount: int)
