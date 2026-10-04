extends Minigame
## Altın günü: teyzelere uğra, sevdiği ikramı ver, çeyrek altınını al.

var guests: Array
var gold := 0
var visited := {}
var gold_label: Label
var list_box: VBoxContainer
var visit_box: VBoxContainer
var current := -1


func build() -> void:
	guests = data["guests"]
	data["bonus"] = 0
	header("Altın Günü", "Teyzelere uğra, sevdiği ikramı ver, altınını al.")

	var counter := PanelContainer.new()
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(UI.sprite("altin", 40))
	gold_label = UI.label("0 çeyrek", 24)
	row.add_child(gold_label)
	counter.add_child(row)
	content.add_child(counter)

	list_box = VBoxContainer.new()
	list_box.add_theme_constant_override("separation", 10)
	content.add_child(list_box)
	visit_box = VBoxContainer.new()
	visit_box.add_theme_constant_override("separation", 12)
	content.add_child(visit_box)
	_show_list()


func _clear(box: Control) -> void:
	for c in box.get_children():
		c.queue_free()


func _show_list() -> void:
	current = -1
	_clear(list_box)
	visit_box.visible = false
	list_box.visible = true
	for i in guests.size():
		var g: Dictionary = guests[i]
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 76)
		var h := HBoxContainer.new()
		h.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		h.offset_left = 8
		h.mouse_filter = MOUSE_FILTER_IGNORE
		h.add_child(Portrait.new(Vector2(64, 70), false, g["scarf"], g["cardigan"]))
		var name := UI.label(g["name"], 22)
		name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		name.size_flags_horizontal = SIZE_EXPAND_FILL
		name.mouse_filter = MOUSE_FILTER_IGNORE
		h.add_child(name)
		if visited.has(i):
			var ok := UI.sprite("altin", 36)
			ok.size_flags_vertical = SIZE_SHRINK_CENTER
			h.add_child(ok)
			b.disabled = true
		b.add_child(h)
		b.pressed.connect(_visit.bind(i))
		list_box.add_child(b)


func _visit(i: int) -> void:
	current = i
	var g: Dictionary = guests[i]
	list_box.visible = false
	visit_box.visible = true
	_clear(visit_box)
	var p := Portrait.new(Vector2(110, 100), false, g["scarf"], g["cardigan"])
	p.size_flags_horizontal = SIZE_SHRINK_CENTER
	visit_box.add_child(p)
	say("%s: Hoş geldin evladım! Önce bir ikram, sonra altın." % g["name"])
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = SIZE_SHRINK_CENTER
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
		UI.shake(b)
		say("%s: %s" % [g["name"], g["hint"]], UI.ACCENT)
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
	_show_list()
