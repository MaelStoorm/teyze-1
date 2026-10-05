extends Minigame
## Yemek: tarifteki malzemeleri tencereye koy, sonra tencereye dokunarak karıştır.
## Tarifte olmayan malzeme yıldızdan götürür. Seviye 3'ten sonra sıra da
## önemli; seviye 5'ten sonra tarifler dört malzemeli, kiler daha kalabalık.

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
var level := 1
## Malzemeler tarifteki sırayla mı konmalı?
var ordered := false
var list_panel: PanelContainer


func build() -> void:
	rated = true
	items = data["items"]
	level = data.get("level", 1)
	ordered = level >= 3
	stirs_needed = data["stirs"]
	if GameState.has_perk("kepce"):
		stirs_needed = ceili(stirs_needed / 2.0)
	header(data["recipe"], "Tarifteki malzemeleri sırasıyla tencereye koy." if ordered else "Tarifteki malzemeleri tencereye koy.")

	# üstte: tencere ve tarif yan yana
	var top := HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_theme_constant_override("separation", 14)
	content.add_child(top)

	pot = TextureButton.new()
	pot.texture_normal = UI.tex("tencere")
	pot.ignore_texture_size = true
	pot.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	pot.custom_minimum_size = Vector2(100, 84)
	pot.size_flags_horizontal = SIZE_SHRINK_CENTER
	pot.size_flags_vertical = SIZE_SHRINK_CENTER
	pot.pressed.connect(_stir)
	top.add_child(pot)

	list_panel = PanelContainer.new()
	list_panel.size_flags_vertical = SIZE_SHRINK_CENTER
	list_panel.add_theme_stylebox_override("panel", UI.box(UI.CREAM, UI.INK, 4, 8))
	var list := GridContainer.new()
	list.columns = 2
	list.add_theme_constant_override("h_separation", 12)
	list.add_theme_constant_override("v_separation", 4)
	for i in items.size():
		var k: String = items[i]
		var item := HBoxContainer.new()
		item.add_theme_constant_override("separation", 4)
		var s := UI.sprite(k, 32)
		s.size_flags_vertical = SIZE_SHRINK_CENTER
		item.add_child(s)
		var m := UI.label(("%d. %s" % [i + 1, Errands.PANTRY[k]]) if ordered else Errands.PANTRY[k], 16)
		m.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		marks[k] = m
		item.add_child(m)
		list.add_child(item)
	list_panel.add_child(list)
	top.add_child(list_panel)

	bar = ProgressBar.new()
	bar.max_value = stirs_needed
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 22)
	bar.add_theme_stylebox_override("background", UI.box(UI.CREAM_DARK, UI.INK, 3, 0))
	bar.add_theme_stylebox_override("fill", UI.box(Color("e8892b"), UI.INK, 3, 0))
	bar.visible = false
	content.add_child(bar)

	var count := 8 if items.size() > 3 else 6
	var keys := items.duplicate()
	var extra := Errands.PANTRY.keys().filter(func(k): return k not in items)
	extra.shuffle()
	keys.append_array(extra.slice(0, count - keys.size()))
	keys.shuffle()
	pantry = GridContainer.new()
	pantry.columns = 4 if count > 6 else 3
	pantry.size_flags_horizontal = SIZE_SHRINK_CENTER
	pantry.add_theme_constant_override("h_separation", 10)
	pantry.add_theme_constant_override("v_separation", 10)
	for k in keys:
		var b := UI.icon_button(k, Errands.PANTRY[k], Callable())
		b.custom_minimum_size = Vector2(96, 94)
		b.pressed.connect(_add.bind(k, b))
		pantry.add_child(b)
	content.add_child(pantry)


## Sıradaki malzeme (sıralı tarifte).
func _next() -> String:
	for k in items:
		if not added.has(k):
			return k
	return ""


func _add(k: String, b: Button) -> void:
	if stirring:
		return
	if k not in items:
		mistake("%s bu tarifte yok evladım." % Errands.PANTRY[k].capitalize(), b)
		return
	if added.has(k):
		mistake("Onu zaten koydun.", b)
		return
	if ordered and k != _next():
		mistake("Dur evladım, sırası değil. Tarife bir bak.", b)
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
	list_panel.visible = false
	bar.visible = true
	pot.custom_minimum_size = Vector2(170, 142)
	say("Şimdi tencereye dokunarak karıştır!")


func _stir() -> void:
	if not stirring or done:
		return
	stirs += 1
	bar.value = stirs
	Sfx.play("stir", -2.0, randf_range(0.9, 1.2))
	pot.pivot_offset = pot.size / 2
	var tw := pot.create_tween()
	tw.tween_property(pot, "rotation", 0.12 if stirs % 2 else -0.12, 0.06)
	tw.tween_property(pot, "rotation", 0.0, 0.08)
	if stirs >= stirs_needed:
		done = true
		win("Oldu! Mis gibi kokuyor.")
	elif stirs * 2 == stirs_needed or stirs * 2 == stirs_needed + 1:
		say("Yarısı oldu, devam!")
