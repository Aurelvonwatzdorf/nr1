extends SceneTree
## Erzeugt resources/world/continent.tres (Startdaten des Kontinents).
## Danach wird die .tres-Datei direkt bearbeitet; dieses Skript nur für einen
## kompletten Neuanfang benutzen:
##   godot --headless --path game -s res://tools/make_continent.gd


func _initialize() -> void:
	var layout := ContinentLayout.new()
	layout.regions = [
		_region(&"santo_santiago", "Santo Santiago", "Die Hauptstadt · Zukunft", ContinentRegion.Style.CITY,
			Vector2(0, 0), 230.0, 2.0, 1.0, Color(0.32, 0.33, 0.38), Color(0.2, 0.2, 0.25), Color(0.18, 0.18, 0.2), 0, 0,
			[], [], [], Color(0.75, 0.6, 0.85), 0.0006,
			"Die leuchtende Hauptstadt der Konzerne. Hinein kommt man durch das Südtor."),
		_region(&"narbe", "Die Narbe", "Verwüstete Zukunft", ContinentRegion.Style.WASTELAND,
			Vector2(20, -560), 220.0, 6.0, 6.0, Color(0.45, 0.32, 0.24), Color(0.6, 0.35, 0.2), Color(0.3, 0.27, 0.25), 90, 2,
			["Schrottsammlerin", "Schrottsammler"],
			["Die Bohrtürme saugen alles aus dem Boden. Das Wasser hier ist rot.",
			"Früher war hier ein Wald. Dann kamen die Konzerne mit ihren Maschinen.",
			"Geh nicht zu nah an den Krater. Wer runterfällt, kommt anders wieder hoch."],
			[Color(0.45, 0.4, 0.35), Color(0.55, 0.35, 0.25)], Color(0.75, 0.5, 0.35), 0.0016,
			"Ein ausgebeutetes Land voller Krater und Bohrtürme der Konzerne."),
		_region(&"kagero", "Kagerō-Gebirge", "Zeit der Schreine", ContinentRegion.Style.MOUNTAINS,
			Vector2(560, -520), 340.0, 22.0, 120.0, Color(0.42, 0.45, 0.32), Color(0.8, 0.3, 0.2), Color(0.5, 0.42, 0.32), 520, 3,
			["Pilgerin", "Pilger", "Mönch"],
			["Der Weg zum Bergtempel ist steil. Viele kehren auf halber Höhe um.",
			"Unter jedem Torbogen bleibt man kurz stehen. So zeigt man den Bergen Respekt.",
			"Das Tor des Bergtempels ist seit Jahren versiegelt. Man sagt, es öffnet sich nur für ein Ritual.",
			"Im Herbst werden die Ahornwälder rot wie Glut."],
			[Color(0.75, 0.7, 0.6), Color(0.3, 0.35, 0.45), Color(0.6, 0.25, 0.2)], Color(0.7, 0.74, 0.8), 0.0005,
			"Hohe Berge mit roten Ahornwäldern, Schreinen und dem versiegelten Bergtempel."),
		_region(&"steppe", "Die Ewige Steppe", "Zeit der Reiterclans", ContinentRegion.Style.STEPPE,
			Vector2(-560, -480), 380.0, 6.0, 10.0, Color(0.6, 0.6, 0.32), Color(0.75, 0.7, 0.4), Color(0.55, 0.48, 0.35), 160, 4,
			["Hirtin", "Hirte", "Reiterin"],
			["Wer an einem Steinhügel vorbeikommt, legt einen Stein dazu und geht dreimal herum.",
			"Unsere Jurten ziehen mit den Herden. Nächsten Monat stehen wir am Fluss.",
			"Hier ist der Himmel größer als irgendwo sonst. Die Stadt sieht von hier aus klein aus.",
			"Komm rein und trink Tee mit uns. Ein Gast bringt Glück ins Lager."],
			[Color(0.7, 0.25, 0.2), Color(0.25, 0.4, 0.65), Color(0.8, 0.65, 0.3)], Color(0.85, 0.85, 0.75), 0.0003,
			"Weites Grasland unter einem riesigen Himmel. Jurtenlager und Steinhügel mit blauen Tüchern."),
		_region(&"grauwald", "Grauwald-Mark", "Mittelalter", ContinentRegion.Style.MEDIEVAL,
			Vector2(-640, 160), 320.0, 6.0, 24.0, Color(0.3, 0.45, 0.26), Color(0.45, 0.55, 0.3), Color(0.45, 0.38, 0.28), 420, 4,
			["Bäuerin", "Bauer", "Schmied", "Wache der Burg"],
			["Die Burg auf dem Hügel schützt uns, solange wir unsere Abgaben zahlen.",
			"Die Mühle dreht sich Tag und Nacht. Ohne sie gäbe es kein Brot.",
			"In der Kapelle läutet die Glocke zur Abendandacht. Jeder ist willkommen.",
			"Leute aus der Stadt mit leuchtenden Augen? Die sehen wir hier nicht gern."],
			[Color(0.45, 0.35, 0.25), Color(0.3, 0.4, 0.3), Color(0.55, 0.2, 0.2)], Color(0.7, 0.75, 0.7), 0.0009,
			"Bewaldete Hügel, eine Burg, ein Fachwerkdorf mit Windmühle und Kapelle."),
		_region(&"nebelwald", "Nebelwald", "Zeitlos", ContinentRegion.Style.MYSTIC_FOREST,
			Vector2(-380, 620), 280.0, 5.0, 14.0, Color(0.18, 0.3, 0.32), Color(0.4, 0.9, 0.85), Color(0.3, 0.35, 0.35), 260, 2,
			["Einsiedlerin", "Einsiedler"],
			["Hör genau hin. Die Bäume flüstern, wenn jemand Neues kommt.",
			"Im Herzen des Waldes ist die Luft so schwer, dass man kaum atmen kann. Nur wer innerlich stark ist, kommt durch.",
			"Hier vergeht die Zeit anders. Ich bin seit gestern hier, sagen die anderen. Mir kommt es wie Jahre vor."],
			[Color(0.3, 0.4, 0.45), Color(0.5, 0.55, 0.5)], Color(0.55, 0.85, 0.8), 0.006,
			"Riesige leuchtende Bäume und dichter Nebel. Ein Ort, an dem die Geisterwelt nah ist."),
		_region(&"kemet", "Sonnenreich Kemet", "Altes Ägypten", ContinentRegion.Style.DESERT,
			Vector2(220, 660), 340.0, 4.0, 6.0, Color(0.85, 0.72, 0.45), Color(0.95, 0.8, 0.5), Color(0.7, 0.6, 0.42), 120, 4,
			["Schreiberin", "Bauer am Fluss", "Steinmetz", "Händlerin"],
			["Der Fluss ist unser Leben. Wo sein Wasser hinkommt, wächst alles.",
			"An den Pyramiden wird seit Generationen gebaut. Jeder Stein wurde von Hand gesetzt.",
			"Der Wächterlöwe sieht nach Osten, zur aufgehenden Sonne.",
			"Ich schreibe auf, was die Leute ernten. Ohne Schrift würde jeder alles vergessen."],
			[Color(0.92, 0.9, 0.82), Color(0.25, 0.45, 0.6), Color(0.8, 0.6, 0.25)], Color(0.95, 0.85, 0.65), 0.0004,
			"Goldene Wüste, ein grüner Fluss, Pyramiden, Obelisken und ein Säulentempel."),
		_region(&"neu_vallis", "Neu-Vallis", "Gegenwart", ContinentRegion.Style.PRESENT,
			Vector2(650, 160), 280.0, 4.0, 3.0, Color(0.4, 0.55, 0.32), Color(0.6, 0.6, 0.6), Color(0.22, 0.22, 0.24), 140, 4,
			["Pendlerin", "Tankwart", "Schüler", "Rentnerin"],
			["Hier ist die Zeit einfach stehen geblieben. Kein Neon, keine Implantate. Mir gefällt das.",
			"Samstags ist Spiel im Stadion. Dann ist die ganze Stadt auf den Beinen.",
			"Mein Handy findet nie Empfang. Der Funkmast sendet nur Rauschen.",
			"Die Leute aus Santo Santiago kaufen hier alte Sachen. Sie nennen es Nostalgie."],
			[Color(0.3, 0.35, 0.55), Color(0.6, 0.3, 0.3), Color(0.4, 0.4, 0.42)], Color(0.8, 0.85, 0.9), 0.0004,
			"Eine ganz normale Vorstadt wie aus der Gegenwart: Häuser, Tankstelle, Funkmast, Stadion."),
		_region(&"glaskueste", "Die Gläserne Küste", "Ferne Zukunft", ContinentRegion.Style.FUTURE,
			Vector2(800, -180), 200.0, 4.0, 3.0, Color(0.75, 0.8, 0.82), Color(0.45, 0.85, 1.0), Color(0.88, 0.9, 0.92), 80, 2,
			["Konzernforscherin", "Wartungsdrohne"],
			["Willkommen an der Küste der Zukunft. Bitte berühren Sie nichts.",
			"Was hier gebaut wird, sieht Santo Santiago erst in hundert Jahren.",
			"Die Bahn fährt ohne Schienen. Niemand weiß genau, wie."],
			[Color(0.9, 0.92, 0.95), Color(0.3, 0.6, 0.8)], Color(0.85, 0.92, 1.0), 0.0004,
			"Weiße Türme, Glaskuppeln und eine schwebende Bahn. Der Sitz der Konzerne von morgen."),
	]
	# Straßen: Ring um die Stadt und Wege in jede Region.
	var ring := PackedVector2Array()
	for i in 33:
		ring.append(Vector2.from_angle(TAU * float(i) / 32.0) * 255.0)
	layout.roads = [
		ring,
		PackedVector2Array([Vector2(0, 230), Vector2(0, 255)]),
		PackedVector2Array([Vector2(0, -255), Vector2(-10, -380), Vector2(20, -560)]),
		PackedVector2Array([Vector2(180, -180), Vector2(320, -330), Vector2(470, -440), Vector2(560, -520)]),
		PackedVector2Array([Vector2(560, -520), Vector2(625, -515), Vector2(600, -565), Vector2(655, -572), Vector2(625, -612), Vector2(672, -618), Vector2(660, -640)]),
		PackedVector2Array([Vector2(-180, -180), Vector2(-360, -320), Vector2(-560, -480)]),
		PackedVector2Array([Vector2(-255, 0), Vector2(-450, 70), Vector2(-640, 160)]),
		PackedVector2Array([Vector2(-180, 180), Vector2(-280, 400), Vector2(-380, 620)]),
		PackedVector2Array([Vector2(0, 255), Vector2(80, 450), Vector2(220, 660)]),
		PackedVector2Array([Vector2(255, 0), Vector2(450, 80), Vector2(650, 160)]),
		PackedVector2Array([Vector2(650, 160), Vector2(740, 0), Vector2(800, -180)]),
		PackedVector2Array([Vector2(800, -180), Vector2(700, -370), Vector2(560, -520)]),
	]
	layout.rivers = [
		PackedVector2Array([Vector2(420, 330), Vector2(400, 480), Vector2(430, 640), Vector2(390, 800), Vector2(420, 1060)]),
	]
	var error := ResourceSaver.save(layout, "res://resources/world/continent.tres")
	print("continent.tres gespeichert: ", error_string(error))
	quit()


func _region(id: StringName, region_name: String, epoch: String, style: ContinentRegion.Style,
		center: Vector2, radius: float, base_height: float, relief: float, ground: Color, accent: Color,
		road: Color, plants: int, npcs: int, names: Array, lines: Array, colors: Array,
		fog_color: Color, fog_density: float, description: String) -> ContinentRegion:
	var region := ContinentRegion.new()
	region.id = id
	region.region_name = region_name
	region.epoch = epoch
	region.style = style
	region.center = center
	region.radius = radius
	region.base_height = base_height
	region.relief = relief
	region.ground_color = ground
	region.accent_color = accent
	region.road_color = road
	region.plant_count = plants
	region.npc_count = npcs
	region.npc_names = PackedStringArray(names)
	var typed_lines: Array[String] = []
	for line: String in lines:
		typed_lines.append(line)
	region.npc_lines = typed_lines
	var typed_colors: Array[Color] = []
	for color: Color in colors:
		typed_colors.append(color)
	region.npc_colors = typed_colors
	region.fog_color = fog_color
	region.fog_density = fog_density
	region.description = description
	if style == ContinentRegion.Style.MOUNTAINS:
		region.relief_frequency = 0.0035
	elif style == ContinentRegion.Style.MEDIEVAL or style == ContinentRegion.Style.MYSTIC_FOREST:
		region.relief_frequency = 0.006
	return region
