class_name HitData
extends RefCounted
## Alle Infos zu einem einzelnen Treffer.

var damage: float = 0.0
var knockback: float = 0.0
## Wer hat getroffen (z. B. der Spieler)?
var source: Node3D
## Richtung vom Angreifer zum Ziel (für Rückstoß, ab M2).
var direction: Vector3 = Vector3.ZERO
