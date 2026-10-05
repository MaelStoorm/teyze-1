extends Minigame
## Altın günü: teyzelere uğra, sevdiği ikramı ver, çeyrek altınını al.
## Yanlış ikram yıldızdan götürür. Seviye 1-2'de kimin ne sevdiği listede
## yazar; seviye 3'ten sonra başta bir kez gösterilir, akılda tutulur
## (istenince yine bakılır: ilki serbest, sonrakiler yıldızdan götürür).

var guests: Array
var gold := 0
var visited := {}
var gold_label: Label
var list_box: GridContainer
var visit_box: HBoxContainer
var memo_box: GridContainer
var current := -1
var level := 1
var memory := false
var peeks := 0
var go_button: Button
var peek_button: Button


func build() -> void:
	rated = true
	guests = data["guests"]
	level = data.get("level", 1)
	memory = level >= 3
	data["bonus"] = 0
	header("Altın Günü", "Teyzelere uğra, sevdiği ikramı ver, altınını al.")

	var counter := PanelContainer.new()
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(UI.sprite("altin", 40))
	gold_label = UI.label("0 çeyrek", 24)
	row.add_child(gold_label)
	counter.add_child(row)
	side.add_child(counter)

	list_box = _grid()
	memo_box = _grid()
	visit_box = HBoxContainer.new()
	visit_box.alignment = BoxContainer.ALIGNMENT_CENTER
	visit_box.size_flags_vertical = SIZE_EXPAND_FILL
	visit_box.add_theme_constant_override("separation", 20)
	content.add_child(visit_box)
	if memory:
		_build_memo()
		go_button = UI.button("Aklımda, gidelim", _show_list, 18)
		add_action(go_button)
		peek_button = UI.button("Kim ne seviyordu?", peek, 18)
		add_action(peek_button)
		_show_memo()
	else:
		_show_list()


func _grid() -> GridContainer:
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 10)
	content.add_child(g)
	return g


func _clear(box: Control) -> void:
	for c in box.get_children():
		c.queue_free()


## Misafir kartı: portre, ad ve (istenirse) sevdiği ikram.
func _guest_row(g: Dictionary, likes: bool, gold_icon: bool) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	h.mouse_filter = MOUSE_FILTER_IGNORE
	h.add_child(Portrait.new(Vector2(52, 66), false, g))
	var name := UI.label(g["name"], 17, UI.INK, true)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name.mouse_filter = MOUSE_FILTER_IGNORE
	h.add_child(name)
	if likes:
		var s := UI.sprite(g["likes"], 40)
		s.size_flags_vertical = SIZE_SHRINK_CENTER
		h.add_child(s)
	if gold_icon:
		var ok := UI.sprite("altin", 34)
		ok.size_flags_vertical = SIZE_SHRINK_CENTER
		h.add_child(ok)
	return h


func _build_memo() -> void:
	for g in guests:
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", UI.box(UI.CREAM, UI.INK, 3, 6))
		p.custom_minimum_size = Vector2(200, 76)
		p.size_flags_horizontal = SIZE_EXPAND_FILL
		p.add_child(_guest_row(g, true, false))
		memo_box.add_child(p)


func _show_memo() -> void:
	current = -1
	memo_box.visible = true
	list_box.visible = false
	visit_box.visible = false
	go_button.visible = true
	peek_button.visible = false
	if peeks == 0:
		say("Kim ne sever? Aklında tut evladım.")


## Kim ne seviyordu? İlk bakış serbest, sonrakiler yıldızdan götürür.
func peek() -> void:
	if not memory or visited.size() == guests.size():
		return
	peeks += 1
	_show_memo()
	if peeks == 1:
		say("Bu bakış serbest; sonrakiler yıldız götürür.")
	else:
		mistake("Olsun, bir daha bakalım.")


func _show_list() -> void:
	current = -1
	_clear(list_box)
	visit_box.visible = false
	memo_box.visible = false
	list_box.visible = true
	if memory:
		go_button.visible = false
		peek_button.visible = true
	if visited.is_empty():
		say("Teyzelere uğra, sevdiği ikramı ver, altınını al.")
	for i in guests.size():
		var g: Dictionary = guests[i]
		var b := Button.new()
		b.custom_minimum_size = Vector2(200, 76)
		b.size_flags_horizontal = SIZE_EXPAND_FILL
		var h := _guest_row(g, not memory and not visited.has(i), visited.has(i))
		h.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		h.offset_left = 8
		h.offset_right = -8
		b.disabled = visited.has(i)
		b.add_child(h)
		b.pressed.connect(_visit.bind(i))
		list_box.add_child(b)


func _visit(i: int) -> void:
	current = i
	var g: Dictionary = guests[i]
	list_box.visible = false
	memo_box.visible = false
	visit_box.visible = true
	if memory:
		go_button.visible = false
		peek_button.visible = true
	_clear(visit_box)
	var p := Portrait.new(Vector2(120, 140), false, g)
	p.size_flags_vertical = SIZE_SHRINK_CENTER
	visit_box.add_child(p)
	say("%s: Hoş geldin! Ne ikram edersin?" % g["name"])
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_vertical = SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	for k in Errands.IKRAM:
		var b := UI.icon_button(k, Errands.ICON_NAMES[k], Callable())
		b.custom_minimum_size = Vector2(100, 96)
		b.pressed.connect(_offer.bind(k, b))
		grid.add_child(b)
	visit_box.add_child(grid)


func _offer(k: String, b: Button) -> void:
	if current < 0:
		return
	var g: Dictionary = guests[current]
	if k != g["likes"]:
		mistake("%s: %s" % [g["name"], g["hint"]], b)
		return
	var amount := 2 if GameState.has_perk("kese") else 1
	gold += amount
	data["bonus"] = gold
	visited[current] = true
	gold_label.text = "%d çeyrek" % gold
	Sfx.play("coin")
	UI.pop(gold_label)
	current = -1
	if visited.size() == guests.size():
		win("%s: Al bakalım altınını, Fatma'ya selam söyle!" % g["name"])
		return
	say("%s: Eline sağlık! Al bakalım, %d çeyrek." % [g["name"], amount], UI.GOOD)
	await get_tree().create_timer(1.0).timeout
	if current < 0 and is_inside_tree():
		_show_list()
