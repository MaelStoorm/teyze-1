class_name Mahalle3D
extends View3D
## 3D mahalle: oyuncak maket gibi, kamera hafif yukarıdan bakar.

signal teyze_tapped

const TEYZE_SPOT := Vector3(-2.6, 0, -3.7)
const PLAYER_START := Vector3(0.4, 0, 2.5)

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
var _cam_focus := Vector3(0, 0, -2.2)
var _talk_after_walk := false

const CAM_OFFSET := Vector3(0, 18.5, 13.2)
## Yürünemeyen yerler (x, z): evler, ağaçlar, tezgah, bank...
const BLOCKERS := [
	Rect2(-4.4, -8.4, 3.6, 3.4), Rect2(1.1, -8.6, 3.6, 3.4),
	Rect2(3.6, -1.7, 1.4, 1.4), Rect2(-5.1, 0.3, 1.4, 1.4), Rect2(3.9, 5.3, 1.4, 1.4), Rect2(-4.9, 6.8, 1.4, 1.4),
	Rect2(-2.8, -1.5, 1.2, 1.0), Rect2(1.8, 8.0, 1.2, 1.0), Rect2(-3.2, 4.1, 1.2, 1.0),
	Rect2(2.3, 1.3, 1.3, 2.6), Rect2(3.4, 0.2, 1.3, 1.5), Rect2(-2.6, 1.5, 0.6, 1.4),
	Rect2(0.7, -2.6, 0.4, 0.4), Rect2(-3.1, -4.2, 1.0, 1.0),
]
const DECOR_BLOCKERS := {
	"kedievi": Rect2(-4.9, -1.9, 1.2, 1.4), "semaver": Rect2(1.4, -0.9, 2.0, 1.2),
	"cesme": Rect2(1.6, 5.8, 1.0, 1.6), "gul": Rect2(-4.1, 8.9, 3.0, 1.0),
}


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

	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("bfe3f0")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("d8e6ff")
	env.environment.ambient_light_energy = 0.3
	env.environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	root.add_child(env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, 38, 0)
	sun.light_color = Color("fff1d6")
	sun.light_energy = 0.75
	sun.shadow_enabled = true
	sun.shadow_opacity = 0.75
	sun.directional_shadow_max_distance = 40.0
	root.add_child(sun)

	camera = Camera3D.new()
	camera.fov = 45
	root.add_child(camera)
	camera.look_at_from_position(Vector3(0, 18.5, 11.0), Vector3(0, 0, -2.2))

	# zemin, yollar, arnavut kaldırımı
	Models.part(root, Models.box(30, 0.2, 40), "#6aa84f", Vector3(0, -0.1, 0))
	_cobbles(root, Rect2(-8, -4.6, 16, 1.8))
	_cobbles(root, Rect2(-0.8, -2.8, 1.6, 14))
	_flowers(root)

	_place(root, Models.house("#f6f0e4", "#8a5a3b", "#3e6fb5"), Vector3(-2.6, 0, -6.6))
	_place(root, Models.house("#f2d58a", "#5c3a26", "#8a5a3b"), Vector3(2.9, 0, -6.8))
	_place(root, Models.pot(), Vector3(-4.5, 0, -5.0))
	_place(root, Models.pot(), Vector3(-0.7, 0, -5.0))
	_place(root, Models.pot(), Vector3(1.2, 0, -5.1))
	_place(root, Models.lamp(), Vector3(0.9, 0, -2.4))
	_place(root, Models.tree(), Vector3(4.3, 0, -1.0))
	_place(root, Models.tree(), Vector3(-4.4, 0, 1.0), 40)
	_place(root, Models.tree(), Vector3(4.6, 0, 6.0), 80)
	_place(root, Models.tree(), Vector3(-4.2, 0, 7.5), 10)
	_place(root, Models.bush(), Vector3(-2.2, 0, -1.0))
	_place(root, Models.bush(), Vector3(2.4, 0, 8.5), 30)
	_place(root, Models.bush(), Vector3(-2.6, 0, 4.6), 60)
	_place(root, Models.stall(), Vector3(2.9, 0, 2.6), -90)
	_place(root, Models.crate(), Vector3(3.8, 0, 0.6))
	_place(root, Models.crate(), Vector3(4.3, 0, 1.3))
	_place(root, Models.bench(), Vector3(-2.3, 0, 2.2), 90)

	teyze = Models.teyze()
	teyze.position = TEYZE_SPOT
	teyze.scale = Vector3.ONE * 1.5
	root.add_child(teyze)
	teyze_walker = Walker.new()
	teyze.add_child(teyze_walker)
	player = Models.player()
	player.position = PLAYER_START
	player.rotation_degrees.y = 0
	player.scale = Vector3.ONE * 1.4
	root.add_child(player)
	player_walker = Walker.new()
	player.add_child(player_walker)
	player_walker.arrived.connect(_on_player_arrived)
	_update_blockers()

	# dokunulan yerde beliren halka
	var ring := TorusMesh.new()
	ring.inner_radius = 0.22
	ring.outer_radius = 0.3
	_marker = Models.part(root, ring, "#fff4dc", Vector3(0, 0.05, 0))
	_marker.visible = false

	bubble = Label3D.new()
	bubble.text = "!"
	bubble.font_size = 160
	bubble.outline_size = 40
	bubble.modulate = Color("c8412f")
	bubble.pixel_size = 0.006
	bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	bubble.no_depth_test = true
	bubble.position = TEYZE_SPOT + Vector3(0, 3.0, 0)
	root.add_child(bubble)
	refresh_decor()


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


func _place(root: Node3D, n: Node3D, pos: Vector3, rot_y := 0.0) -> void:
	n.position = pos
	n.rotation_degrees.y = rot_y
	root.add_child(n)


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


func _flowers(root: Node3D) -> void:
	var colors := ["#f4efe6", "#f7cf4a", "#e88ab0"]
	for i in 60:
		var p := Vector3(randf_range(-7, 7), 0.05, randf_range(-3, 12))
		if abs(p.x) < 1.0 or (p.z > -5 and p.z < -2.6):
			continue
		Models.part(root, Models.ball(0.06, 6), colors[i % 3], p)


func _update_blockers() -> void:
	var list: Array[Rect2] = []
	for r in BLOCKERS:
		list.append(r)
	for id in DECOR_BLOCKERS:
		if GameState.decor.has(id):
			list.append(DECOR_BLOCKERS[id])
	if player_walker:
		player_walker.blockers = list


func _process(delta: float) -> void:
	_t += delta
	bubble.position = teyze.position + Vector3(0, 3.0 + sin(_t * 4.0) * 0.08, 0)
	# kamera oyuncuyu yumuşakça takip eder
	var want := Vector3(clampf(player.position.x * 0.5, -1.5, 1.5), 0, clampf(-2.2 + (player.position.z - PLAYER_START.z) * 0.5, -3.0, 3.0))
	_cam_focus = _cam_focus.lerp(want, minf(1.0, delta * 2.5))
	camera.look_at_from_position(_cam_focus + CAM_OFFSET, _cam_focus)
	if _marker.visible:
		_marker.scale = _marker.scale.lerp(Vector3.ONE * 0.4, delta * 3.0)


func _gui_input(event: InputEvent) -> void:
	# Android'de dokunuşlar fare tıklaması olarak da gelir; yalnız onu dinliyoruz.
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var vp_pos := to_viewport(event.position)
	# Teyzenin ekrandaki yerine yakın her dokunuş sayılır (parmak dostu).
	var p := camera.unproject_position(teyze.global_position + Vector3(0, 1.2, 0))
	if vp_pos.distance_to(p) < 70 * pixel_scale:
		teyze_tapped.emit()
		return
	var origin := camera.project_ray_origin(vp_pos)
	var dir := camera.project_ray_normal(vp_pos)
	if absf(dir.y) < 0.001:
		return
	var hit := origin + dir * (-origin.y / dir.y)
	_talk_after_walk = false
	player_walker.walk_to(hit)
	_marker.position = player_walker.target + Vector3(0, 0.05, 0)
	_marker.scale = Vector3.ONE
	_marker.visible = true


func _on_player_arrived() -> void:
	_marker.visible = false
	if _talk_after_walk:
		_talk_after_walk = false
		player_walker.face(teyze.position)
		teyze_walker.face(player.position)


## Oyuncuyu teyzenin yanına yürütür ve varınca döner.
func walk_to_teyze() -> void:
	var spot := TEYZE_SPOT + Vector3(1.2, 0, 0.7)
	_talk_after_walk = true
	_marker.visible = false
	if player.position.distance_to(spot) > 0.15:
		player_walker.walk_to(spot)
		await player_walker.arrived
	player_walker.face(teyze.position)
	teyze_walker.face(player.position)


func reset_player() -> void:
	player_walker.stop()
	player.position = PLAYER_START
	player.rotation_degrees.y = 0
