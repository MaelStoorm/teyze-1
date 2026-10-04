extends Minigame
## Yemek: tarifteki malzemeleri tencereye koy, sonra tencereye dokunarak karıştır.

var items: Array
var added := {}
var marks := {}
var pantry: GridContainer
var pot: TextureButton
var bar: ProgressBar
var stirs_needed: int
var stirs := 0
var stirring := false
var done := false


func build() -> void:
	items = data["items"]
	stirs_needed = data["stirs"]
	if GameState.has_perk("kepce"):
		stirs_needed = ceili(stirs_needed / 2.0)
	header(data["recipe"], "Tarifteki malzemeleri tencereye koy.")

	var list_panel := PanelContainer.new()
	var list := HBoxContainer.new()
	list.alignment = BoxContainer.ALIGNMENT_CENTER
	list.add_theme_constant_override("separation", 14)
	for k in items:
		var item := VBoxContainer.new()
		var s := UI.sprite(k, 40)
		s.size_flags_horizontal = SIZE_SHRINK_CENTER
		item.add_child(s)
		var m := UI.label(Errands.PANTRY[k], 16)
		marks[k] = m
		item.add_child(m)
		list.add_child(item)
	list_panel.add_child(list)
	content.add_child(list_panel)

	pot = TextureButton.new()
	pot.texture_normal = UI.tex("tencere")
	pot.ignore_texture_size = true
	pot.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	pot.custom_minimum_size = Vector2(110, 92)
	pot.size_flags_horizontal = SIZE_SHRINK_CENTER
	pot.pressed.connect(_stir)
	content.add_child(pot)

	bar = ProgressBar.new()
	bar.max_value = stirs_needed
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 22)
	bar.add_theme_stylebox_override("background", UI.box(UI.CREAM_DARK, UI.INK, 3, 0))
	bar.add_theme_stylebox_override("fill", UI.box(Color("e8892b"), UI.INK, 3, 0))
	bar.visible = false
	content.add_child(bar)

	var keys := items.duplicate()
	var extra := Errands.PANTRY.keys().filter(func(k): return k not in items)
	extra.shuffle()
	keys.append_array(extra.slice(0, 6 - keys.size()))
	keys.shuffle()
	pantry = GridContainer.new()
	pantry.columns = 3
	pantry.size_flags_horizontal = SIZE_SHRINK_CENTER
	pantry.add_theme_constant_override("h_separation", 10)
	pantry.add_theme_constant_override("v_separation", 10)
	for k in keys:
		var b := UI.icon_button(k, Errands.PANTRY[k], Callable())
		b.custom_minimum_size = Vector2(100, 96)
		b.pressed.connect(_add.bind(k, b))
		pantry.add_child(b)
	content.add_child(pantry)


func _add(k: String, b: Button) -> void:
	if stirring:
		return
	if k not in items:
		UI.shake(b)
		say("%s bu tarifte yok evladım." % Errands.PANTRY[k].capitalize(), UI.ACCENT)
		return
	if added.has(k):
		UI.shake(b)
		say("Onu zaten koydun.", UI.ACCENT)
		return
	added[k] = true
	b.disabled = true
	UI.pop(pot)
	var m: Label = marks[k]
	m.add_theme_color_override("font_color", UI.GOOD)
	m.text = "✓ " + m.text
	if added.size() < items.size():
		say("Tencereye koydun. Sırada ne var?")
		return
	stirring = true
	pantry.visible = false
	bar.visible = true
	say("Şimdi tencereye dokunarak karıştır!")


func _stir() -> void:
	if not stirring or done:
		return
	stirs += 1
	bar.value = stirs
	pot.pivot_offset = pot.size / 2
	var tw := pot.create_tween()
	tw.tween_property(pot, "rotation", 0.12 if stirs % 2 else -0.12, 0.06)
	tw.tween_property(pot, "rotation", 0.0, 0.08)
	if stirs >= stirs_needed:
		done = true
		win("Oldu! Mis gibi kokuyor.")
	elif stirs * 2 == stirs_needed or stirs * 2 == stirs_needed + 1:
		say("Yarısı oldu, devam!")
