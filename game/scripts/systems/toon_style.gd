class_name ToonStyle
## Der gezeichnete Look: Licht und Schatten in klaren Stufen (Toon-Shading) und
## ein dunkler Umriss um jedes Objekt (zweiter, leicht vergrößerter Durchgang,
## der nur von hinten gezeichnet wird).
##
## `apply_to_tree(level)` stellt alle Materialien eines Levels um. Neu erzeugte
## Materialien mit `ToonStyle.make(farbe)` anlegen.

const OUTLINE_COLOR := Color(0.05, 0.04, 0.07)
const OUTLINE_WIDTH := 0.03


## Neues Material im gezeichneten Look.
static func make(color: Color, outline: bool = true) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	apply(material, outline)
	return material


## Stellt ein vorhandenes Material um (mehrfaches Aufrufen schadet nicht).
static func apply(material: BaseMaterial3D, outline: bool = true) -> void:
	if material == null or material.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED:
		return
	material.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	material.specular_mode = BaseMaterial3D.SPECULAR_TOON
	var transparent := material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED
	# Meta "no_outline": z. B. Gelände, dort sähe ein Umriss falsch aus.
	if outline and not transparent and material.next_pass == null and not material.has_meta(&"no_outline"):
		material.next_pass = make_outline()


static func make_outline() -> StandardMaterial3D:
	var outline := StandardMaterial3D.new()
	outline.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	outline.albedo_color = OUTLINE_COLOR
	outline.cull_mode = BaseMaterial3D.CULL_FRONT
	outline.grow = true
	outline.grow_amount = OUTLINE_WIDTH
	return outline


## Alle Meshes unter `root` umstellen (Materialien aus Szenen und aus Code).
static func apply_to_tree(root: Node) -> void:
	for node: Node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.material_override is BaseMaterial3D:
			apply(mesh_instance.material_override as BaseMaterial3D)
		elif mesh_instance.mesh:
			for i in mesh_instance.mesh.get_surface_count():
				apply(mesh_instance.mesh.surface_get_material(i) as BaseMaterial3D)
