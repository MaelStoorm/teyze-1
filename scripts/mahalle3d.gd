class_name Mahalle3D
extends View3D
## 3D mahalle: evler, kahvehane, pazar yeri, çiftlik ve gölet. Oyuncu dokunduğu
## yere yürür; teyzelere, tezgahlara, hayvanlara dokununca etkileşir.

## Bir kişiye ya da yere dokunuldu (oyuncu oraya yürüdükten sonra main işler).
signal tapped(id: String)

const TEYZE_SPOT := Vector3(-2.6, 0, -3.7)
const PLAYER_START := Vector3(0.4, 0, 0.5)
const CAM_OFFSET := Vector3(0, 13.0, 9.6)
const BOUNDS := Rect2(-19.5, -5.3, 39.0, 30.0)
const STALL_POS := {"manav": Vector3(-4.2, 0, 12.2), "firin": Vector3(0.0, 0, 12.2), "sarkuteri": Vector3(4.2, 0, 12.2)}
const KAHVE_POS := Vector3(-8.5, 0, -0.6)
const FARM := Rect2(6.5, 1.5, 6.5, 7.0)
const POND_POS := Vector3(-9.5, 0, 7.5)
const BOWL_POS := Vector3(-0.9, 0, -5.0)
## Satın alınabilen süslerin kapladığı yer.
const DECOR_BLOCKERS := {
	"kedievi": Rect2(-4.9, -1.9, 1.2, 1.4), "semaver": Rect2(1.4, -0.9, 2.0, 1.2),
	"cesme": Rect2(1.6, 5.8, 1.0, 1.6), "gul": Rect2(-4.1, 8.9, 3.0, 1.0), "tavla": Rect2(-6.8, 3.2, 2.0, 0.8),
}

var camera: Camera3D
var teyze: Node3D
var player: Node3D
var bubble: Label3D
var _root: Node3D
var _decor_nodes := {}
var _t := 0.0
var player_walker: Walker
var teyze_walker: Walker
var _marker: MeshInstance3D
var _cam_focus := Vector3.ZERO
var _blockers: Array[Rect2] = []
## Dokunulabilen her şey: id -> {"node", "h", "walker" (varsa), "spot" (varsa)}
var targets := {}
## Dolaşan karakter ve hayvanlar: id -> {"walker", "area", "wait"}
var wanderers := {}
var neighbors := {}
var _talking := ""
var _bubbles := {}
var _goal_marks: Array[MeshInstance3D] = []
var _goals: Array = []
var _carry: Node3D
var _glasses: Node3D
var _ducks: Array[Node3D] = []
var sutlu: Node3D
var sutlu_follow := false
## Uçan böcekler: {"node", "center", "r", "speed", "phase", "kind"}
var _flyers: Array[Dictionary] = []


func _ready() -> void:
	super()
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	viewport.positional_shadow_atlas_size = 2048
	_build()


func _build() -> void:
	seed(4)  # süslerin rastgele dizilimi hep aynı olsun
	var root := Node3D.new()
	_root = root
	viewport.add_child(root)

	# Wii oyunları gibi: yumuşak, aydınlık, hafif parlak oyuncak görünüşü
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("bfe3f0")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("dfe9ff")
	env.environment.ambient_light_energy = 0.42
	env.environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	root.add_child(env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 32, 0)
	sun.light_color = Color("fff3dc")
	sun.light_energy = 0.8
	sun.light_specular = 0.35
	sun.shadow_enabled = true
	sun.shadow_opacity = 0.6
	sun.shadow_blur = 1.5
	sun.directional_shadow_max_distance = 30.0
	root.add_child(sun)

	camera = Camera3D.new()
	camera.fov = 45
	root.add_child(camera)

	# zemin, yollar, arnavut kaldırımı
	Models.part(root, Models.box(64, 0.2, 66), "#6aa84f", Vector3(0, -0.1, 10))
	_cobbles(root, Rect2(-14, -4.6, 28, 1.8))
	_cobbles(root, Rect2(-0.8, -2.8, 1.6, 13.4))
	_cobbles(root, Rect2(-6.6, 10.6, 13.2, 5.0))
	_cobbles(root, Rect2(-8.0, 0.8, 7.2, 1.0))  # kahvehaneye giden yol
	_flowers(root)

	# evler: Miyase, Fatma, Filiz, Hülya
	_solid(Models.house("#e8f0f4", "#3e6fb5", "#c96a43"), Vector3(-9.0, 0, -6.7), 0, Rect2(-10.8, -8.1, 3.6, 2.9))
	_solid(Models.house("#f6f0e4", "#8a5a3b", "#3e6fb5"), Vector3(-2.6, 0, -6.6), 0, Rect2(-4.4, -8.0, 3.6, 2.9))
	_solid(Models.house("#f2d58a", "#5c3a26", "#8a5a3b"), Vector3(2.9, 0, -6.8), 0, Rect2(1.1, -8.2, 3.6, 2.9))
	_solid(Models.house("#f6dfe4", "#8e5bb5", "#4f8a5b"), Vector3(9.0, 0, -6.8), 0, Rect2(7.2, -8.2, 3.6, 2.9))
	for x in [-11.0, -7.1, -4.5, -0.7, 1.2, 4.9, 7.2, 10.9]:
		_place(root, Models.pot(), Vector3(x, 0, -5.0))
	_solid(Models.lamp(), Vector3(0.9, 0, -2.4), 0, Rect2(0.7, -2.6, 0.4, 0.4))
	_solid(Models.lamp(), Vector3(-6.0, 0, -2.4), 0, Rect2(-6.2, -2.6, 0.4, 0.4))
	_solid(Models.lamp(), Vector3(6.0, 0, -2.4), 0, Rect2(5.8, -2.6, 0.4, 0.4))
	for spec in [[Vector3(4.3, 0, -1.0), 0], [Vector3(-4.4, 0, 1.0), 40], [Vector3(4.6, 0, 6.0), 80], [Vector3(-4.2, 0, 7.5), 10],
			[Vector3(-12.6, 0, 1.2), 20], [Vector3(-12.2, 0, 12.8), 50], [Vector3(9.2, 0, 12.6), 70], [Vector3(12.6, 0, 11.0), 0],
			[Vector3(-6.4, 0, -1.6), 30], [Vector3(12.8, 0, -1.8), 60], [Vector3(-9.0, 0, 13.6), 15]]:
		var p: Vector3 = spec[0]
		_solid(Models.tree(), p, spec[1], Rect2(p.x - 0.7, p.z - 0.7, 1.4, 1.4))
	_solid(Models.bush(), Vector3(-2.2, 0, -1.0), 0, Rect2(-2.8, -1.5, 1.2, 1.0))
	_solid(Models.bush(), Vector3(2.4, 0, 8.5), 30, Rect2(1.8, 8.0, 1.2, 1.0))
	_solid(Models.bush(), Vector3(-2.6, 0, 4.6), 60, Rect2(-3.2, 4.1, 1.2, 1.0))
	_solid(Models.bush(), Vector3(7.4, 0, 10.4), 10, Rect2(6.8, 9.9, 1.2, 1.0))
	_solid(Models.crate(), Vector3(3.8, 0, 0.6), 0, Rect2(3.4, 0.2, 1.4, 1.5))
	_place(root, Models.crate(), Vector3(4.3, 0, 1.3))
	_solid(Models.bench(), Vector3(-2.3, 0, 2.2), 90, Rect2(-2.6, 1.5, 0.6, 1.4))

	# Ahmet Amca'nın kahvehanesi
	_solid(Props.kahvehane(), KAHVE_POS, 0, Rect2(-10.7, -1.9, 4.4, 2.7))
	for x in [-9.8, -7.2]:
		_blockers.append(Rect2(x - 0.8, 1.9, 1.6, 0.8))  # çay masaları
	_blockers.append(Rect2(-11.3, 0.7, 0.8, 0.8))  # semaver

	# pazar yeri
	for kind in STALL_POS:
		var p: Vector3 = STALL_POS[kind]
		_solid(Props.market_stall(kind), p, 0, Rect2(p.x - 1.35, p.z - 0.7, 3.5, 1.5))
		var seller := Props.person(Props.STALLS[kind]["look"])
		seller.position = p + Vector3(1.75, 0, 0.35)
		seller.rotation.y = -0.35
		seller.scale = Vector3.ONE * 1.3
		root.add_child(seller)
		targets["stall_" + kind] = {"node": seller, "h": 1.7, "spot": p + Vector3(0.9, 0, 1.4)}
	var pz := Props.label3d("PAZAR YERİ", 96, Color("8e2f2a"))
	pz.position = Vector3(0, 3.4, 10.4)
	root.add_child(pz)

	# çiftlik: çit, kümes, yalak, saman; inekler ve tavuklar
	_place(root, Props.fence(FARM, Vector2(FARM.position.x, 5.0)), Vector3.ZERO)
	_blockers.append(Rect2(FARM.position.x, FARM.position.y - 0.1, FARM.size.x, 0.2))
	_blockers.append(Rect2(FARM.position.x, FARM.end.y - 0.1, FARM.size.x, 0.2))
	_blockers.append(Rect2(FARM.end.x - 0.1, FARM.position.y, 0.2, FARM.size.y))
	_blockers.append(Rect2(FARM.position.x - 0.1, FARM.position.y, 0.2, 5.0 - 0.8 - FARM.position.y))
	_blockers.append(Rect2(FARM.position.x - 0.1, 5.8, 0.2, FARM.end.y - 5.8))
	_solid(Props.coop(), Vector3(12.0, 0, 2.6), -90, Rect2(11.3, 1.9, 1.4, 1.6))
	_solid(Props.trough(), Vector3(8.4, 0, 7.9), 0, Rect2(7.6, 7.5, 1.6, 0.8))
	_solid(Props.hay(), Vector3(12.0, 0, 7.8), 20, Rect2(11.4, 7.3, 1.2, 1.0))
	var inner := Rect2(FARM.position.x + 0.8, FARM.position.y + 0.8, FARM.size.x - 1.6, FARM.size.y - 1.6)
	for i in 2:
		_add_animal("inek%d" % i, Animals.cow(), Vector3(8.5 + i * 2.0, 0, 3.5 + i * 2.0), inner, 0.45, 0.8, 1.2)
	for i in 4:
		_add_animal("tavuk%d" % i, Animals.chicken(), Vector3(10.5 + (i % 2), 0, 3.0 + i * 0.5), Rect2(9.5, 2.4, 2.8, 3.6), 0.9, 2.5, 1.3)
	_add_animal("kopek", Animals.dog(), Vector3(-1.8, 0, 3.4), Rect2(-6.0, -2.4, 11.0, 9.0), 1.6, 1.8, 1.3)

	# gölet ve ördekler
	_place(root, Props.pond(2.0), POND_POS)
	_blockers.append(Rect2(POND_POS.x - 2.9, POND_POS.z - 2.3, 5.8, 4.6))
	for i in 3:
		var d := Animals.duck()
		d.scale = Vector3.ONE * 1.3
		root.add_child(d)
		_ducks.append(d)
		targets["ordek%d" % i] = {"node": d, "h": 0.4, "animal": "quack"}

	_build_outskirts(root)

	# Fatma Teyze
	teyze = Models.teyze()
	teyze.position = TEYZE_SPOT
	teyze.scale = Vector3.ONE * 1.4
	root.add_child(teyze)
	teyze_walker = Walker.new()
	teyze.add_child(teyze_walker)
	targets["fatma"] = {"node": teyze, "h": 1.7, "walker": teyze_walker, "spot": TEYZE_SPOT + Vector3(1.2, 0, 0.7)}

	# Sütlü ve mama kabı
	var bowl := Props.bowl()
	_place(root, bowl, BOWL_POS)
	bowl.name = "Kap"
	sutlu = Animals.cat()
	sutlu.scale = Vector3.ONE * 1.5
	_add_animal("sutlu", sutlu, BOWL_POS + Vector3(-0.6, 0, 0.2), Rect2(-4.4, -5.3, 4.0, 0.7), 1.2, 3.0, 1.6)
	targets["sutlu"]["animal"] = ""  # Sütlü'ye dokununca yanına gidilir

	_make_player(PLAYER_START, 0.0)
	_cam_focus = PLAYER_START

	# dokunulan yerde beliren halka
	var ring := TorusMesh.new()
	ring.inner_radius = 0.22
	ring.outer_radius = 0.3
	_marker = Models.part(root, ring, "#fff4dc", Vector3(0, 0.05, 0))
	_marker.visible = false

	bubble = _make_bubble(Color("c8412f"))
	refresh_decor()
	refresh_neighbors()
	_update_blockers()


## Mahallenin çevresi: dere ve köprü, çiçek bahçesi ve arı kovanları,
## elma bahçesi, ayçiçeği tarlası; arılar ve kelebekler.
func _build_outskirts(root: Node3D) -> void:
	# güneyde dere, üstünde köprü, köprüden çiçek bahçesine yol
	Models.part(root, Models.box(64, 0.06, 1.6), "#5fb3d6", Vector3(0, 0.0, 17.0))
	for x in range(-19, 20, 2):
		if absf(x) > 1.5:
			Models.part(root, Models.ball(0.22, 6), "#a39b8b", Vector3(x + randf_range(-0.4, 0.4), 0.02, 16.15), Vector3.ZERO, Vector3(1, 0.4, 1))
			Models.part(root, Models.ball(0.22, 6), "#b8b0a0", Vector3(x + randf_range(-0.4, 0.4), 0.02, 17.85), Vector3.ZERO, Vector3(1, 0.4, 1))
	_place(root, Props.bridge(1.8, 2.6), Vector3(0, 0, 17.0))
	_blockers.append(Rect2(-20.0, 16.2, 19.1, 1.6))
	_blockers.append(Rect2(0.9, 16.2, 19.1, 1.6))
	_cobbles(root, Rect2(-0.8, 15.6, 1.6, 0.6))
	_cobbles(root, Rect2(-0.8, 18.3, 1.6, 6.0))
	var gs := Props.label3d("ÇİÇEK BAHÇESİ", 90, Color("8e2f6a"))
	gs.position = Vector3(0, 2.6, 18.6)
	root.add_child(gs)

	# çiçek tarhları
	var beds := [Rect2(-6.6, 19.2, 3.4, 1.6), Rect2(-6.6, 22.0, 3.4, 1.6), Rect2(3.2, 19.2, 3.4, 1.6), Rect2(3.2, 22.0, 3.4, 1.6), Rect2(-2.6, 24.6, 5.2, 1.2)]
	var stems := []
	var heads := []
	var head_colors := []
	var palette := [Color("e04a4a"), Color("f7cf4a"), Color("f2a0c0"), Color("f4efe6"), Color("b89be8"), Color("f5a93a")]
	for bi in beds.size():
		var b: Rect2 = beds[bi]
		_solid(Props.flower_bed(b.size), Vector3(b.get_center().x, 0, b.get_center().y), 0, b)
		var cols := int(b.size.x / 0.32)
		var rows := int(b.size.y / 0.32)
		for cx in cols:
			for cz in rows:
				var p := Vector3(b.position.x + 0.2 + cx * 0.32, 0.2, b.position.y + 0.2 + cz * 0.32)
				p += Vector3(randf_range(-0.06, 0.06), 0, randf_range(-0.06, 0.06))
				var h := randf_range(0.3, 0.45)
				stems.append(Transform3D(Basis(), p + Vector3(0, h / 2, 0)))
				heads.append(Transform3D(Basis().scaled(Vector3(1, 0.8, 1)), p + Vector3(0, h, 0)))
				head_colors.append(palette[(bi * 2 + cz) % palette.size()])
	_multimesh(root, Models.cyl(0.02, 0.02, 1.0, 5), stems, [], "#4f8a3a", Vector3(1, 0.38, 1))
	_multimesh(root, Models.ball(0.09, 8), heads, head_colors)
	_solid(Models.bench(), Vector3(-1.9, 0, 21.2), 90, Rect2(-2.2, 20.5, 0.6, 1.4))
	_solid(Models.bench(), Vector3(1.9, 0, 21.2), -90, Rect2(1.6, 20.5, 0.6, 1.4))
	_solid(Models.tree(), Vector3(-9.5, 0, 21.5), 30, Rect2(-10.2, 20.8, 1.4, 1.4))
	_solid(Models.tree(), Vector3(13.5, 0, 22.5), 0, Rect2(12.8, 21.8, 1.4, 1.4))
	# arı kovanları
	for p in [Vector3(8.6, 0, 20.4), Vector3(10.0, 0, 21.2), Vector3(9.0, 0, 22.6)]:
		_solid(Props.hive(), p, randf_range(-30, 30), Rect2(p.x - 0.5, p.z - 0.5, 1.0, 1.0))
	var ks := Props.label3d("Arıcı Rıza'nın kovanları", 56)
	ks.position = Vector3(9.3, 2.0, 21.4)
	root.add_child(ks)

	# doğuda elma bahçesi
	for x in [15.2, 17.8]:
		for z in [-1.0, 2.5, 6.0, 9.5, 13.0]:
			var p := Vector3(x, 0, z + (0.8 if x > 16 else 0.0))
			_solid(Props.apple_tree(), p, randf() * 360, Rect2(p.x - 0.7, p.z - 0.7, 1.4, 1.4))
	# batıda ayçiçeği tarlası
	var sf_stems := []
	var sf_heads := []
	var sf_mid := []
	for row in 5:
		for k in 9:
			var p := Vector3(-18.6 + row * 1.0, 0, 0.5 + k * 1.05 + (0.5 if row % 2 else 0.0))
			var h := randf_range(1.3, 1.7)
			sf_stems.append(Transform3D(Basis(), p + Vector3(0, h / 2, 0)).scaled_local(Vector3(1, h, 1)))
			var face := Basis(Vector3.RIGHT, deg_to_rad(70))  # kafalar güneye, kameraya bakar
			sf_heads.append(Transform3D(face, p + Vector3(0, h, 0.05)))
			sf_mid.append(Transform3D(face, p + Vector3(0, h, 0.09)))
	_blockers.append(Rect2(-19.0, 0.2, 5.2, 10.4))
	_multimesh(root, Models.cyl(0.04, 0.05, 1.0, 6), sf_stems, [], "#4f8a3a")
	_multimesh(root, Models.cyl(0.32, 0.32, 0.06, 14), sf_heads, [], "#f7c62a")
	_multimesh(root, Models.cyl(0.16, 0.16, 0.07, 12), sf_mid, [], "#6b4a25")

	# arılar kovan ve tarhların çevresinde, kelebekler çiçeklerin üstünde
	var bee_spots := [Vector3(9.2, 0, 21.4), Vector3(9.2, 0, 21.4), Vector3(9.2, 0, 21.4), Vector3(4.9, 0, 20.0),
		Vector3(4.9, 0, 22.8), Vector3(-4.9, 0, 20.0), Vector3(-4.9, 0, 22.8), Vector3(-16.5, 0, 5.0), Vector3(-16.5, 0, 3.0)]
	for c in bee_spots:
		var b := Props.bee()
		b.scale = Vector3.ONE * 1.8
		root.add_child(b)
		_flyers.append({"node": b, "center": c, "r": randf_range(0.6, 1.4), "speed": randf_range(1.2, 2.2), "phase": randf() * TAU, "kind": "bee"})
	var bf_colors := ["#f5a93a", "#5aa0d8", "#f2a0c0", "#f4efe6", "#b89be8", "#f7cf4a"]
	var bf_spots := [Vector3(-3.0, 0, 3.5), Vector3(5.0, 0, 9.0), Vector3(-5.0, 0, 21.0), Vector3(5.0, 0, 21.0), Vector3(0.0, 0, 25.0), Vector3(-14.0, 0, 9.0), Vector3(11.0, 0, -3.0), Vector3(-7.0, 0, 13.5)]
	for i in bf_spots.size():
		var b := Props.butterfly(bf_colors[i % bf_colors.size()])
		b.scale = Vector3.ONE * 2.2
		root.add_child(b)
		_flyers.append({"node": b, "center": bf_spots[i], "r": randf_range(1.2, 2.4), "speed": randf_range(0.35, 0.6), "phase": randf() * TAU, "kind": "butterfly"})


## Aynı şeklin çok kopyası tek çizimde. colors boşsa hepsi color rengi.
func _multimesh(root: Node3D, mesh: Mesh, xforms: Array, colors: Array, color := "#ffffff", scale := Vector3.ONE) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = not colors.is_empty()
	var mat := StandardMaterial3D.new()
	mat.roughness = 0.75
	if colors.is_empty():
		mat.albedo_color = Color(color)
	else:
		mat.vertex_color_use_as_albedo = true
	mesh.material = mat
	mm.mesh = mesh
	mm.instance_count = xforms.size()
	for i in xforms.size():
		var t: Transform3D = xforms[i]
		if scale != Vector3.ONE:
			t = t.scaled_local(scale)
		mm.set_instance_transform(i, t)
		if not colors.is_empty():
			mm.set_instance_color(i, colors[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	root.add_child(mmi)


## Arılar sekiz çizerek vızıldar, kelebekler süzülüp kanat çırpar.
func _fly() -> void:
	for f in _flyers:
		var n: Node3D = f["node"]
		var a: float = _t * f["speed"] + f["phase"]
		var r: float = f["r"]
		var c: Vector3 = f["center"]
		var prev := n.position
		if f["kind"] == "bee":
			n.position = c + Vector3(sin(a) * r, 1.0 + sin(a * 2.3) * 0.25, sin(a * 2.0) * r * 0.6)
			var flap := sin(_t * 60.0) * 0.6
			n.get_node("WingL").rotation.z = flap
			n.get_node("WingR").rotation.z = -flap
		else:
			n.position = c + Vector3(cos(a) * r, 1.3 + sin(a * 3.0) * 0.4, sin(a * 1.4) * r * 0.8)
			var flap := sin(_t * 14.0 + f["phase"]) * 0.9
			n.get_node("WingL").rotation.z = flap
			n.get_node("WingR").rotation.z = -flap
		var d := n.position - prev
		if d.length() > 0.0001:
			n.rotation.y = atan2(d.x, d.z)


func _make_bubble(color: Color) -> Label3D:
	var b := Label3D.new()
	b.text = "!"
	b.font_size = 150
	b.outline_size = 38
	b.modulate = color
	b.pixel_size = 0.006
	b.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	b.no_depth_test = true
	_root.add_child(b)
	return b


func _make_player(pos: Vector3, rot_y: float) -> void:
	player = Models.player(GameState.avatar)
	player.position = pos
	player.rotation.y = rot_y
	player.scale = Vector3.ONE * 1.4
	_root.add_child(player)
	player_walker = Walker.new()
	player_walker.speed = 2.6
	player_walker.bounds = BOUNDS
	player.add_child(player_walker)
	player_walker.arrived.connect(_on_player_arrived)
	if _carry:
		_carry.reparent(player, false)


## Dolaşan bir hayvan ekler. step: adım sıklığı.
func _add_animal(id: String, node: Node3D, pos: Vector3, area: Rect2, speed: float, wait: float, step: float) -> void:
	node.position = pos
	node.rotation.y = randf() * TAU
	_root.add_child(node)
	var w := Walker.new()
	w.speed = speed
	w.step_rate = step
	w.bounds = BOUNDS
	node.add_child(w)
	wanderers[id] = {"walker": w, "area": area, "wait": randf_range(0.2, wait), "pause": wait}
	var sounds := {"inek": "moo", "tavuk": "cluck", "kopek": "woof", "sutlu": "meow"}
	var snd := ""
	for k in sounds:
		if id.begins_with(k):
			snd = sounds[k]
	targets[id] = {"node": node, "h": 0.9 if id.begins_with("inek") else 0.45, "walker": w, "animal": snd}


## Satın alınmış süsleri mahalleye koyar (yenileri ekler).
func refresh_decor() -> void:
	seed(11)
	for d in Decor.ALL:
		var id: String = d["id"]
		if GameState.decor.has(id) and not _decor_nodes.has(id):
			var n := Decor.build(id)
			n.position = d["pos"]
			n.rotation_degrees.y = d["rot"]
			_root.add_child(n)
			_decor_nodes[id] = n
			_update_blockers()
		elif not GameState.decor.has(id) and _decor_nodes.has(id):
			_decor_nodes[id].queue_free()
			_decor_nodes.erase(id)


## Açılmış komşuları evlerinin önüne koyar.
func refresh_neighbors() -> void:
	for n in GameState.neighbors_unlocked():
		var id: String = n["id"]
		if neighbors.has(id):
			continue
		var body := Models.person(n)
		body.position = n["home"]
		body.rotation.y = randf_range(-0.6, 0.6)
		body.scale = Vector3.ONE * 1.4
		_root.add_child(body)
		var w := Walker.new()
		w.speed = 1.1  # teyzeler acele etmez
		w.bounds = BOUNDS
		body.add_child(w)
		w.blockers = _blockers
		neighbors[id] = body
		wanderers[id] = {"walker": w, "area": n["area"], "wait": randf_range(0.5, 3.0), "pause": 5.0}
		targets[id] = {"node": body, "h": 1.7, "walker": w}


## bubbles: başında ünlem olacaklar (iş verecekler).
## goals: şu anki işte gidilecek yerler (altın ok).
func set_marks(bubbles: Array, goals: Array) -> void:
	for id in _bubbles.keys():
		if id not in bubbles:
			_bubbles[id].queue_free()
			_bubbles.erase(id)
	for id in bubbles:
		if id == "fatma" or not targets.has(id) or _bubbles.has(id):
			continue
		_bubbles[id] = _make_bubble(Color("2f7fc8"))
	bubble.visible = "fatma" in bubbles
	_goals = goals.filter(func(g): return targets.has(g))
	while _goal_marks.size() < _goals.size():
		var cone := Models.part(_root, Models.cyl(0.0, 0.28, 0.5, 12), "#f2c23a", Vector3.ZERO, Vector3(180, 0, 0))
		var m := Models.mat("#f2c23a").duplicate() as StandardMaterial3D
		m.emission_enabled = true
		m.emission = Color("f2c23a")
		m.emission_energy_multiplier = 0.4
		m.no_depth_test = true
		cone.material_override = m
		_goal_marks.append(cone)
	for i in _goal_marks.size():
		_goal_marks[i].visible = i < _goals.size()


## Oyuncunun taşıdığı şey: "" (hiç), "cay", "file", "gozluk".
func set_carry(kind: String) -> void:
	if _carry:
		_carry.queue_free()
		_carry = null
	if kind == "":
		return
	if kind == "gozluk":
		_carry = Props.glasses()
		_carry.get_child(_carry.get_child_count() - 1).visible = false
		_carry.scale = Vector3.ONE * 1.6
	else:
		var s := Sprite3D.new()
		s.texture = UI.tex(kind)
		s.pixel_size = 0.0028
		s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		s.no_depth_test = true
		_carry = s
	_carry.position = Vector3(0, 2.05, 0)
	player.add_child(_carry)


func spawn_glasses(pos: Vector3) -> void:
	remove_glasses()
	_glasses = Props.glasses()
	_glasses.position = pos
	_root.add_child(_glasses)
	targets["gozluk"] = {"node": _glasses, "h": 0.3, "spot": pos + Vector3(0, 0, 0.7)}


func remove_glasses() -> void:
	if _glasses:
		_glasses.queue_free()
		_glasses = null
	targets.erase("gozluk")


## Sütlü'nün kabı dolar, kedi koşup yer, sonra oyuncunun peşine takılır.
func feed_sutlu() -> void:
	var bowl := _root.get_node("Kap")
	bowl.get_node("Mama").visible = true
	sutlu_follow = true
	_hop(sutlu)


func set_bowl_full(full: bool) -> void:
	_root.get_node("Kap").get_node("Mama").visible = full


func end_talk() -> void:
	_talking = ""


func _place(root: Node3D, n: Node3D, pos: Vector3, rot_y := 0.0) -> void:
	n.position = pos
	n.rotation_degrees.y = rot_y
	root.add_child(n)


## Yere konan ve içinden geçilemeyen bir şey.
func _solid(n: Node3D, pos: Vector3, rot_y: float, block: Rect2) -> void:
	_place(_root, n, pos, rot_y)
	_blockers.append(block)


func _cobbles(root: Node3D, area: Rect2) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var m := Models.box(0.36, 0.08, 0.36)
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.9
	m.material = mat
	mm.mesh = m
	var cells := []
	var step := 0.4
	for x in range(int(area.size.x / step)):
		for z in range(int(area.size.y / step)):
			cells.append(Vector3(area.position.x + x * step + 0.2, 0.0, area.position.y + z * step + 0.2))
	mm.instance_count = cells.size()
	for i in cells.size():
		var t := Transform3D(Basis(Vector3.UP, randf_range(-0.15, 0.15)), cells[i] + Vector3(0, randf_range(0, 0.02), 0))
		mm.set_instance_transform(i, t)
		var g := randf_range(0.62, 0.78)
		mm.set_instance_color(i, Color(g, g * 0.97, g * 0.92))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	root.add_child(mmi)


## Çimenlerdeki çiçekler tek bir çoklu çizimde (telefonda hızlı olsun).
func _flowers(root: Node3D) -> void:
	var colors := [Color("f4efe6"), Color("f7cf4a"), Color("e88ab0"), Color("b89be8")]
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var m := Models.ball(0.07, 6)
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	m.material = mat
	mm.mesh = m
	var spots := []
	for i in 1100:
		var p := Vector3(randf_range(-19.5, 19.5), 0.05, randf_range(-2.6, 26))
		if absf(p.x) < 1.0 or (p.z > 10.4 and p.z < 15.8 and absf(p.x) < 6.8) or FARM.grow(0.3).has_point(Vector2(p.x, p.z)):
			continue
		if (p.z > 16.0 and p.z < 18.0) or (p.x < -13.8 and p.z > 0.0 and p.z < 11.0):
			continue
		if Vector2(p.x - POND_POS.x, p.z - POND_POS.z).length() < 3.0:
			continue
		spots.append(p)
	mm.instance_count = spots.size()
	for i in spots.size():
		mm.set_instance_transform(i, Transform3D(Basis(), spots[i]))
		mm.set_instance_color(i, colors[i % colors.size()])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	root.add_child(mmi)


func _update_blockers() -> void:
	var list: Array[Rect2] = _blockers.duplicate()
	for id in DECOR_BLOCKERS:
		if GameState.decor.has(id):
			list.append(DECOR_BLOCKERS[id])
	if player_walker:
		player_walker.blockers = list
	for id in wanderers:
		wanderers[id]["walker"].blockers = list


func _process(delta: float) -> void:
	_t += delta
	bubble.position = teyze.position + Vector3(0, 3.0 + sin(_t * 4.0) * 0.08, 0)
	for id in _bubbles:
		_bubbles[id].position = targets[id]["node"].position + Vector3(0, 2.9 + sin(_t * 4.0 + 1.0) * 0.08, 0)
	for i in _goals.size():
		var g: Dictionary = targets.get(_goals[i], {})
		if g.is_empty():
			continue
		_goal_marks[i].position = g["node"].position + Vector3(0, g["h"] + 0.9 + sin(_t * 5.0) * 0.15, 0)
		_goal_marks[i].rotation.y = _t * 2.0
	# kamera oyuncuyu yumuşakça takip eder
	var want := Vector3(clampf(player.position.x, -15.5, 15.5), 0, clampf(player.position.z - 0.8, -2.8, 22.5))
	_cam_focus = _cam_focus.lerp(want, minf(1.0, delta * 2.5))
	camera.look_at_from_position(_cam_focus + CAM_OFFSET, _cam_focus)
	if _marker.visible:
		_marker.scale = _marker.scale.lerp(Vector3.ONE * 0.4, delta * 3.0)
	_wander(delta)
	_swim()
	_fly()


func _wander(delta: float) -> void:
	for id in wanderers:
		var wd: Dictionary = wanderers[id]
		var w: Walker = wd["walker"]
		if id == _talking:
			continue
		if id == "sutlu" and sutlu_follow:
			# karnı doyan Sütlü oyuncunun peşinden gelir
			var gap := sutlu.position.distance_to(player.position)
			if gap > 1.6:
				w.speed = 3.0
				w.walk_to(player.position + (sutlu.position - player.position).normalized() * 0.9)
			elif gap < 1.0 and w.moving:
				w.stop()
			continue
		if w.moving:
			continue
		wd["wait"] -= delta
		if wd["wait"] <= 0.0:
			var a: Rect2 = wd["area"]
			w.walk_to(Vector3(randf_range(a.position.x, a.end.x), 0, randf_range(a.position.y, a.end.y)))
			wd["wait"] = randf_range(wd["pause"] * 0.5, wd["pause"] * 1.5)


## Ördekler göletin üstünde yavaşça daire çizer.
func _swim() -> void:
	for i in _ducks.size():
		var a := _t * (0.25 + i * 0.07) + i * 2.1
		var r := 1.0 + i * 0.35
		var d := _ducks[i]
		d.position = POND_POS + Vector3(cos(a) * r * 1.25, 0.05 + sin(_t * 3.0 + i) * 0.02, sin(a) * r)
		d.rotation.y = -a + PI


func _gui_input(event: InputEvent) -> void:
	# Android'de dokunuşlar fare tıklaması olarak da gelir; yalnız onu dinliyoruz.
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var vp_pos := to_viewport(event.position)
	# Bir şeyin ekrandaki yerine yakın her dokunuş sayılır (parmak dostu).
	var best := ""
	var best_d := 58.0 * pixel_scale
	for id in targets:
		var t: Dictionary = targets[id]
		var node: Node3D = t["node"]
		if not node.is_visible_in_tree():
			continue
		var p := camera.unproject_position(node.global_position + Vector3(0, t["h"] * 0.6, 0))
		var d := vp_pos.distance_to(p)
		if d < best_d:
			best_d = d
			best = id
	if best != "":
		var snd: String = targets[best].get("animal", "-")
		if snd != "-" and snd != "":
			_animal_react(best, snd)
		else:
			tapped.emit(best)
		return
	var origin := camera.project_ray_origin(vp_pos)
	var dir := camera.project_ray_normal(vp_pos)
	if absf(dir.y) < 0.001:
		return
	var hit := origin + dir * (-origin.y / dir.y)
	player_walker.walk_to(hit)
	_marker.position = player_walker.target + Vector3(0, 0.05, 0)
	_marker.scale = Vector3.ONE
	_marker.visible = true


## Hayvana dokununca sesini çıkarır ve zıplar.
func _animal_react(id: String, snd: String) -> void:
	Sfx.play(snd, -2.0, randf_range(0.92, 1.08))
	var node: Node3D = targets[id]["node"]
	var w: Walker = targets[id].get("walker")
	if w:
		w.face(player.position)
	_hop(node)


func _hop(node: Node3D) -> void:
	var base := node.position.y
	var tw := node.create_tween()
	tw.tween_property(node, "position:y", base + 0.35, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "position:y", base, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


func _on_player_arrived() -> void:
	_marker.visible = false


## Oyuncuyu bir kişinin ya da yerin yanına yürütür; kişi durup ona döner.
func walk_to_target(id: String) -> void:
	var t: Dictionary = targets.get(id, {})
	if t.is_empty():
		return
	var node: Node3D = t["node"]
	var w: Walker = t.get("walker")
	if w:
		_talking = id
		w.stop()
	var spot: Vector3
	if t.has("spot"):
		spot = t["spot"]
	else:
		var dir := player.position - node.position
		dir.y = 0
		dir = dir.normalized() if dir.length() > 0.01 else Vector3(0, 0, 1)
		spot = node.position + dir * (0.9 if node == sutlu else 1.3)
	_marker.visible = false
	if player.position.distance_to(spot) > 0.15:
		player_walker.walk_to(spot)
		await player_walker.arrived
	player_walker.face(node.position)
	if w:
		w.face(player.position)


func reset_player() -> void:
	player_walker.stop()
	player.position = PLAYER_START
	player.rotation_degrees.y = 0


## Karakter değişince oyuncuyu yeni görünüşüyle aynı yerde yeniden kurar.
func set_player_look(_look: Dictionary) -> void:
	var pos := player.position
	var rot := player.rotation.y
	if _carry:
		_carry.reparent(_root, false)
	player.queue_free()
	_make_player(pos, rot)
	_update_blockers()
