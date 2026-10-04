extends Minigame
## Evim: teyzenin evini kurabiyelerle döşe. Önü açık bir oda (maket gibi),
## her yerde (halı, oturak, masa...) seçilen eşya durur. Süre yok, ceza yok.
##
## Akış: alttaki yer düğmesine dokun -> o yerin eşyaları büyük kartlarla açılır
## -> karta dokun (sahipsen koyar, değilsen kurabiyeyle alıp koyar) -> kartlar
## kapanır, eşya odada belirir.

## Her yerin odadaki noktası, dönüşü (y derece) ve büyüklüğü.
const SLOT_AT := {
	"hali": [Vector3(-0.35, 0, 0.2), 0.0, 1.0],
	"kanepe": [Vector3(-1.05, 0, -1.68), 0.0, 1.0],
	"masa": [Vector3(-0.55, 0, 0.15), 0.0, 1.0],
	"duvar": [Vector3(-1.2, 2.15, -2.2), 0.0, 1.3],
	"pencere": [Vector3(1.3, 1.75, -2.2), 0.0, 1.0],
	"kose": [Vector3(2.5, 0, -1.6), -25.0, 1.15],
	"lamba": [Vector3(-2.6, 0, -1.75), 0.0, 1.15],
}
## Tavandan sarkan lambaların noktası (duvar süsüyle perdenin arasında görünür).
const HANG_AT := Vector3(0.3, 3.0, -0.9)
## Fatma'nın durduğu yer.
const AVATAR_AT := Vector3(1.45, 0, 0.75)

var view: View3D
var cam: Camera3D
var world: Node3D
var holders := {}  # slot -> Node3D (içine eşya kurulur)
var slot_buttons := {}
var cookie_label: Label
var slot := "hali"
var lamp_light: OmniLight3D
var avatar: Node3D
## Eşya seçme katmanı (açık değilse null).
var picker: Control
var picker_title: Label
var _t := 0.0


func build() -> void:
	header("Evim", "Aşağıdan bir yer seç, beğendiğin eşyayı koy.")
	var bal := HBoxContainer.new()
	bal.alignment = BoxContainer.ALIGNMENT_CENTER
	bal.add_child(UI.sprite("kurabiye", 32))
	cookie_label = UI.label("", 24)
	bal.add_child(cookie_label)
	# kaymayan yerde: ipucu uzasa da kurabiye sayısı hep görünür
	_side_col.add_child(bal)
	_side_col.move_child(bal, 1)

	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UI.box(Color("fbe9cc"), UI.INK, 4, 4))
	frame.size_flags_vertical = SIZE_EXPAND_FILL
	view = View3D.new()
	view.size_flags_vertical = SIZE_EXPAND_FILL
	view.size_flags_horizontal = SIZE_EXPAND_FILL
	view.mouse_filter = MOUSE_FILTER_IGNORE
	view.resized.connect(_fit_camera)
	frame.add_child(view)
	content.add_child(frame)

	var grid := GridContainer.new()
	grid.columns = 4 if UI.text_scale < 1.15 else 3
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	for s in EvEsya.SLOTS:
		var b := UI.button(s["name"], open_slot.bind(s["id"]), 18)
		b.custom_minimum_size = Vector2(0, 44)
		b.size_flags_horizontal = SIZE_EXPAND_FILL
		slot_buttons[s["id"]] = b
		grid.add_child(b)
	content.add_child(grid)

	_build_world()
	for s in EvEsya.SLOTS:
		_place(s["id"], false)
	_refresh()


func _process(delta: float) -> void:
	_t += delta
	if avatar:
		avatar.rotation.y = deg_to_rad(-25) + sin(_t * 0.9) * 0.12


func _refresh() -> void:
	cookie_label.text = str(GameState.kurabiye)
	for k in slot_buttons:
		var filled: bool = GameState.ev.get(k, "") != ""
		var b: Button = slot_buttons[k]
		# dolu yerler yeşil çerçeveli: neyin konduğu bir bakışta görünsün
		var st := UI.box(Color("dff0d0") if filled else UI.CREAM, UI.GOOD if filled else UI.INK, 3, 4)
		b.add_theme_stylebox_override("normal", st)
		b.add_theme_stylebox_override("hover", st)


# --- oda -----------------------------------------------------------------------

func _build_world() -> void:
	var vp := view.viewport
	vp.own_world_3d = true
	vp.transparent_bg = true
	world = Node3D.new()
	vp.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_CLEAR_COLOR
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("ffe6c8")
	env.environment.ambient_light_energy = 0.55
	world.add_child(env)
	var sun := DirectionalLight3D.new()  # pencereden giren ılık güneş
	sun.light_color = Color("fff0d8")
	sun.light_energy = 1.0
	sun.rotation_degrees = Vector3(-50, 35, 0)
	world.add_child(sun)
	lamp_light = OmniLight3D.new()  # lamba konunca odaya sarı bir sıcaklık
	lamp_light.light_color = Color("ffc37a")
	lamp_light.visible = false
	world.add_child(lamp_light)

	var room := Node3D.new()
	room.name = "Oda"
	_room(room)
	world.add_child(room)
	Bake.merge_rig(room)

	for s in EvEsya.SLOTS:
		var h := Node3D.new()
		h.name = "Yer_" + s["id"]
		world.add_child(h)
		holders[s["id"]] = h

	avatar = Models.player(GameState.avatar)
	avatar.position = AVATAR_AT
	world.add_child(avatar)
	Bake.merge_rig(avatar)

	cam = Camera3D.new()
	world.add_child(cam)
	cam.look_at_from_position(Vector3(2.4, 3.5, 6.4), Vector3(-0.3, 1.05, -0.55))
	_fit_camera()


## Dar kutuda odanın eni, geniş kutuda boyu sığsın.
func _fit_camera() -> void:
	if cam == null or view.size.y <= 0:
		return
	var aspect := view.size.x / view.size.y
	if aspect < 1.5:
		cam.keep_aspect = Camera3D.KEEP_WIDTH
		cam.fov = 58
	else:
		cam.keep_aspect = Camera3D.KEEP_HEIGHT
		cam.fov = 40


func _room(n: Node3D) -> void:
	var d := 4.0  # oda derinliği (z: -2.2 .. 1.8)
	var zc := -0.2
	# zemin: ahşap tahtalar
	Models.part(n, Models.box(6.6, 0.3, d + 0.2), "#8a5a3b", Vector3(-0.05, -0.15, zc))
	for i in 11:
		Models.part(n, Models.box(0.55, 0.04, d), "#c98f5c" if i % 2 == 0 else "#bd8452", Vector3(-2.95 + i * 0.6 + 0.28, 0.0, zc + 0.1))
	# arka duvar ve sol duvar
	var wall := "#f6e3c4"
	var lower := "#e3b98a"
	Models.part(n, Models.box(6.6, 3.2, 0.2), wall, Vector3(-0.05, 1.6, -2.3))
	Models.part(n, Models.box(0.2, 3.2, d + 0.2), wall, Vector3(-3.25, 1.6, zc))
	# lambri ve süpürgelik
	Models.part(n, Models.box(6.4, 0.9, 0.04), lower, Vector3(0.05, 0.45, -2.19))
	Models.part(n, Models.box(0.04, 0.9, d), lower, Vector3(-3.14, 0.45, zc + 0.1))
	Models.part(n, Models.box(6.4, 0.06, 0.07), "#9a6640", Vector3(0.05, 0.92, -2.18))
	Models.part(n, Models.box(0.07, 0.06, d), "#9a6640", Vector3(-3.13, 0.92, zc + 0.1))
	Models.part(n, Models.box(6.4, 0.1, 0.06), "#7a4e2a", Vector3(0.05, 0.05, -2.17))
	Models.part(n, Models.box(0.06, 0.1, d), "#7a4e2a", Vector3(-3.12, 0.05, zc + 0.1))
	# tavan kornişi ve duvar kenarları
	Models.part(n, Models.box(6.7, 0.16, 0.34), "#e9cfa6", Vector3(-0.05, 3.2, -2.25))
	Models.part(n, Models.box(0.34, 0.16, d + 0.3), "#e9cfa6", Vector3(-3.2, 3.2, zc))
	Models.part(n, Models.box(0.24, 3.36, 0.24), "#e9cfa6", Vector3(3.27, 1.6, -2.3))
	Models.part(n, Models.box(0.24, 3.36, 0.24), "#e9cfa6", Vector3(-3.25, 1.6, zc + d / 2 + 0.07))
	# duvar kağıdında küçük çiçekler
	for i in 9:
		for j in 3:
			var x := -2.8 + i * 0.7 + (0.35 if j % 2 else 0.0)
			if x > 0.35 and x < 2.25:
				continue  # pencerenin arkası
			Models.part(n, Models.ball(0.04, 6), "#e8b0a0", Vector3(x, 1.35 + j * 0.62, -2.2), Vector3.ZERO, Vector3(1, 1, 0.3))
	for i in 6:
		for j in 3:
			var z := -1.75 + i * 0.7 + (0.35 if j % 2 else 0.0)
			if z > -0.1 and z < 1.3 or z > 1.7:
				continue  # kapının arkası
			Models.part(n, Models.ball(0.04, 6), "#e8b0a0", Vector3(-3.15, 1.35 + j * 0.62, z), Vector3.ZERO, Vector3(0.3, 1, 1))
	# pencere (arka duvar)
	var wc := SLOT_AT["pencere"][0] as Vector3
	Models.part(n, Models.box(1.5, 1.5, 0.06), "#ffffff", wc + Vector3(0, 0, 0.02))
	Models.part(n, Models.box(1.3, 1.3, 0.07), "#a9dcef", wc + Vector3(0, 0, 0.03))
	Models.part(n, Models.ball(0.5, 8), "#6fb860", wc + Vector3(-0.35, -0.75, 0.04), Vector3.ZERO, Vector3(1.0, 0.8, 0.05))  # dışarıda ağaç
	Models.part(n, Models.ball(0.4, 8), "#5aa852", wc + Vector3(0.4, -0.7, 0.045), Vector3.ZERO, Vector3(1.0, 0.7, 0.05))
	Models.part(n, Models.ball(0.12, 8), "#ffffff", wc + Vector3(0.25, 0.35, 0.045), Vector3.ZERO, Vector3(1.6, 0.8, 0.05))  # bulut
	Models.part(n, Models.ball(0.1, 8), "#ffffff", wc + Vector3(0.4, 0.38, 0.046), Vector3.ZERO, Vector3(1.4, 0.9, 0.05))
	Models.part(n, Models.box(0.07, 1.3, 0.1), "#ffffff", wc + Vector3(0, 0, 0.05))
	Models.part(n, Models.box(1.3, 0.07, 0.1), "#ffffff", wc + Vector3(0, 0.1, 0.05))
	Models.part(n, Models.box(1.7, 0.08, 0.26), "#ffffff", wc + Vector3(0, -0.76, 0.1))  # denizlik
	# kapı (sol duvar)
	var dz := 0.6
	Models.part(n, Models.box(0.08, 2.25, 1.15), "#e9cfa6", Vector3(-3.13, 1.12, dz))
	Models.part(n, Models.box(0.1, 2.1, 0.98), "#9a5f3a", Vector3(-3.11, 1.05, dz))
	for k in 2:
		Models.part(n, Models.box(0.12, 0.7, 0.7), "#b07448", Vector3(-3.1, 0.55 + k * 0.95, dz))
	Models.part(n, Models.ball(0.05, 8), "#e8b33a", Vector3(-3.04, 1.0, dz + 0.36))
	Models.part(n, Models.cyl(0.09, 0.09, 0.02, 12), "#1f4fa0", Vector3(-3.05, 2.45, dz), Vector3(0, 0, 90))  # kapının nazarı
	Models.part(n, Models.cyl(0.055, 0.055, 0.025, 10), "#ffffff", Vector3(-3.045, 2.45, dz), Vector3(0, 0, 90))
	Models.part(n, Models.cyl(0.03, 0.03, 0.03, 8), "#14182a", Vector3(-3.04, 2.45, dz), Vector3(0, 0, 90))
	# kapı önünde terlikler
	for k in 2:
		Models.part(n, Models.ball(0.08, 8), "#5c3a26" if k == 0 else "#c8412f", Vector3(-2.75, 0.05, dz - 0.15 + k * 0.25), Vector3(0, 10, 0), Vector3(1.6, 0.6, 0.9))


# --- yerleştirme ---------------------------------------------------------------

func _place(s: String, animate := true) -> void:
	var h: Node3D = holders[s]
	for c in h.get_children():
		c.queue_free()
	var id: String = GameState.ev.get(s, "")
	var it := EvEsya.get_item(id)
	var node: Node3D = EvEsya.build_default(s) if it.is_empty() else EvEsya.build(id)
	var at: Array = SLOT_AT[s]
	h.position = at[0]
	h.rotation_degrees.y = at[1]
	h.scale = Vector3.ONE * float(at[2])
	if it.get("hang", false):
		h.position = HANG_AT
		h.rotation_degrees.y = 0
		h.scale = Vector3.ONE
	if s == "lamba":
		_update_light(it)
	if node == null:
		return
	h.add_child(node)
	Bake.merge_rig(node)
	if animate:
		node.scale = Vector3.ONE * 0.6
		var tw := node.create_tween()
		tw.tween_property(node, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _update_light(it: Dictionary) -> void:
	lamp_light.visible = not it.is_empty()
	if it.is_empty():
		return
	if it.get("hang", false):
		lamp_light.position = HANG_AT + Vector3(0, -0.6, 0)
		lamp_light.light_energy = 1.2
		lamp_light.omni_range = 4.0
	else:
		var top := 1.6 if it["id"] == "abajur" else 0.9
		lamp_light.position = (SLOT_AT["lamba"][0] as Vector3) + Vector3(0.3, top, 0.3)
		lamp_light.light_energy = 1.0
		lamp_light.omni_range = 3.0


# --- eşya seçme katmanı ----------------------------------------------------------

## Bir yerin eşyalarını büyük kartlarla açar.
func open_slot(s: String) -> void:
	slot = s
	close_picker()
	picker = Control.new()
	picker.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	picker.mouse_filter = MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.23, 0.16, 0.1, 0.45)
	dim.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	picker.add_child(dim)
	var page := UI.page(picker, 10)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UI.box(UI.CREAM, UI.INK, 4, 10))
	panel.size_flags_vertical = SIZE_EXPAND_FILL
	page.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)

	var top := HBoxContainer.new()
	picker_title = UI.label("%s: birini seç" % EvEsya.slot_name(s), 24, UI.ACCENT, true)
	picker_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	top.add_child(picker_title)
	top.add_theme_constant_override("separation", 8)
	picker_title.size_flags_vertical = SIZE_SHRINK_CENTER
	var ck := UI.sprite("kurabiye", 28)
	ck.size_flags_vertical = SIZE_SHRINK_CENTER
	top.add_child(ck)
	top.add_child(UI.label(str(GameState.kurabiye), 22))
	var current: String = GameState.ev.get(s, "")
	if current != "":
		var rm := UI.button("Kaldır", _remove, 19)
		rm.custom_minimum_size = Vector2(104, 46)
		rm.size_flags_vertical = SIZE_SHRINK_CENTER
		top.add_child(rm)
	var cancel := UI.button("Vazgeç", close_picker, 19)
	cancel.custom_minimum_size = Vector2(104, 46)
	cancel.size_flags_vertical = SIZE_SHRINK_CENTER
	top.add_child(cancel)
	v.add_child(top)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var row := GridContainer.new()
	var items := EvEsya.items_for(s)
	row.columns = items.size() if UI.text_scale < 1.3 else 2
	row.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_theme_constant_override("h_separation", 8)
	row.add_theme_constant_override("v_separation", 8)
	for it in items:
		row.add_child(_card(it, it["id"] == current))
	scroll.add_child(row)
	v.add_child(scroll)

	add_child(picker)
	# kartlar odayı örtüyor: arkadaki odayı çizmeye gerek yok
	view.viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED


func close_picker() -> void:
	if picker:
		picker.queue_free()
		picker = null
		picker_title = null
	if view:
		view.viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS


func _card(it: Dictionary, placed: bool) -> Control:
	var owned: bool = GameState.ev_items.has(it["id"])
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", UI.box(Color("dff0d0") if placed else Color.WHITE, UI.GOOD if placed else UI.INK, 4 if placed else 3, 6))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	var thumb := _thumb(it)
	thumb.size_flags_horizontal = SIZE_SHRINK_CENTER
	v.add_child(thumb)
	var title := UI.label(it["name"], 18, UI.ACCENT, true)
	v.add_child(title)
	var d := UI.label(it["desc"], 14, UI.INK, true)
	d.size_flags_vertical = SIZE_EXPAND_FILL
	v.add_child(d)
	var b := Button.new()
	b.custom_minimum_size.y = 42
	b.add_theme_font_size_override("font_size", int(19 * UI.text_scale))
	if placed:
		b.text = "Yerinde"
		b.disabled = true
	elif owned:
		b.text = "Senin · Koy"
	else:
		b.text = str(it["price"])
		b.icon = UI.tex("kurabiye")
		b.expand_icon = false
		b.add_theme_constant_override("icon_max_width", 26)
		if GameState.kurabiye < it["price"]:
			b.add_theme_color_override("font_color", Color("9a8b78"))
	b.pressed.connect(func(): Sfx.play("tap", -4.0))
	b.pressed.connect(choose.bind(it["id"]))
	v.add_child(b)
	panel.add_child(v)
	return panel


## Kartta eşyanın küçük 3D önizlemesi; eşyanın boyuna göre kadrajlanır.
func _thumb(it: Dictionary) -> ModelThumb:
	var model := EvEsya.build(it["id"])
	Bake.merge_rig(model)
	var box := AABB()
	var first := true
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		var xf := Transform3D.IDENTITY
		var p: Node = mi
		while p != model:
			xf = (p as Node3D).transform * xf
			p = p.get_parent()
		var b: AABB = xf * (mi as MeshInstance3D).get_aabb()
		box = b if first else box.merge(b)
		first = false
	var c := box.get_center()
	model.position = Vector3(-c.x, 0, -c.z)
	var r := maxf(box.size.length() * 0.5, 0.3)
	var h := 54.0 if UI.text_scale < 1.3 else 46.0
	var t := ModelThumb.new(model, Vector2(h * 1.4, h), r * 2.2, c.y)
	if it["slot"] in ["duvar", "pencere"]:
		t.set_process(false)  # duvardakiler dönmesin, arkaları düz
	return t


## Eşyayı seçer: sahipse koyar, değilse kurabiye yetiyorsa alıp koyar.
## Döner: eşya yerine kondu mu.
func choose(id: String) -> bool:
	var it := EvEsya.get_item(id)
	if it.is_empty():
		return false
	var s: String = it["slot"]
	slot = s
	if GameState.ev.get(s, "") == id:
		close_picker()
		return true
	if not GameState.ev_items.has(id):
		var price: int = it["price"]
		if GameState.kurabiye < price:
			Sfx.play("bad", -6.0)
			var msg := "Kurabiyen biraz az geldi evladım. %s için %d kurabiye lazım; işleri yaptıkça birikir." % [it["name"], price]
			say(msg, UI.ACCENT)
			if picker_title:  # kartlar açıkken sol yazı görünmez; mesaj başlıkta
				picker_title.text = "Biraz az geldi evladım, %d kurabiye lazım." % price
				picker_title.add_theme_font_size_override("font_size", int(19 * UI.text_scale))
			return false
		GameState.kurabiye -= price
		GameState.ev_items[id] = true
		Sfx.play("levelup", -4.0)
		say("Ne güzel oldu evladım! %s artık senin." % it["name"], UI.GOOD)
	else:
		Sfx.play("good", -4.0)
		say("%s yerine kondu. Pek yakıştı!" % it["name"], UI.GOOD)
	GameState.ev[s] = id
	GameState.save_game()
	GameState.changed.emit()
	close_picker()
	_place(s)
	_refresh()
	return true


func _remove() -> void:
	close_picker()
	if GameState.ev.get(slot, "") == "":
		return
	var it := EvEsya.get_item(GameState.ev[slot])
	GameState.ev.erase(slot)
	GameState.save_game()
	GameState.changed.emit()
	say("%s kaldırıldı. O hep senin, istersen yine koyarsın." % it.get("name", "Eşya"))
	_place(slot)
	_refresh()
