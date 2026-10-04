extends Minigame
## Komşuya haber: teyzenin sözünü aklında tut, komşuya sırasıyla anlat.

const DISTRACTORS := ["ay", "gunes", "cay", "borek", "ev", "kurabiye", "simit", "kapi", "yumurta", "peynir"]

var icons: Array
var step := 0
var learn: Control
var tell: Control
var slots: Array = []
var option_buttons := {}


func build() -> void:
	icons = data["icons"]
	header("Komşuya Haber", "")
	learn = _build_learn()
	tell = _build_tell()
	_show_learn()
	if GameState.has_perk("defter"):
		_choose(icons[0], option_buttons[icons[0]])
		_show_learn()


func _page() -> VBoxContainer:
	var v := VBoxContainer.new()
	v.size_flags_vertical = SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 14)
	content.add_child(v)
	return v


func _build_learn() -> Control:
	var v := _page()
	var t := Portrait.new(Vector2(104, 104))
	t.size_flags_horizontal = SIZE_SHRINK_CENTER
	v.add_child(t)
	var p := PanelContainer.new()
	p.add_child(UI.label("“%s”" % data["text"], 22, UI.INK, true))
	v.add_child(p)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var many := icons.size() > 3  # 4 kart ekrana sığsın diye biraz küçült
	row.add_theme_constant_override("separation", 6 if many else 10)
	for i in icons.size():
		var card := PanelContainer.new()
		var c := VBoxContainer.new()
		c.add_child(UI.label(str(i + 1), 18, UI.ACCENT))
		var s := UI.sprite(icons[i], 46 if many else 54)
		s.size_flags_horizontal = SIZE_SHRINK_CENTER
		c.add_child(s)
		c.add_child(UI.label(Errands.ICON_NAMES[icons[i]], 15 if many else 18))
		card.add_child(c)
		row.add_child(card)
	v.add_child(row)
	v.add_child(UI.spacer())
	v.add_child(UI.button("Aklımda, götürüyorum", _show_tell))
	return v


func _build_tell() -> Control:
	var v := _page()

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	for i in icons.size():
		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(72, 72)
		slot.add_child(UI.label(str(i + 1), 28, Color("b8a68a")))
		slots.append(slot)
		row.add_child(slot)
	v.add_child(row)

	var options := icons.duplicate()
	var extra := DISTRACTORS.filter(func(x): return x not in icons)
	extra.shuffle()
	options.append_array(extra.slice(0, 6 - icons.size()))
	options.shuffle()
	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	for k in options:
		var b := UI.icon_button(k, Errands.ICON_NAMES[k], Callable())
		b.custom_minimum_size = Vector2(96, 96)
		b.pressed.connect(_choose.bind(k, b))
		option_buttons[k] = b
		grid.add_child(b)
	v.add_child(grid)

	var again := UI.button("Teyze ne demişti?", _show_learn, 18)
	again.custom_minimum_size.y = 44
	v.add_child(again)
	return v


func _show_learn() -> void:
	learn.visible = true
	tell.visible = false
	say("Teyzenin sözünü aklında tut. İstediğin kadar bakabilirsin.")


func _show_tell() -> void:
	learn.visible = false
	tell.visible = true
	say("%s: Hoş geldin evladım! Fatma ne dedi? Sırasıyla seç." % Errands.KOMSU)


func _choose(k: String, b: Button) -> void:
	if step >= icons.size():
		return
	if k != icons[step]:
		UI.shake(b)
		say("Hmm, öyle mi dedi? Bir daha düşün.", UI.ACCENT)
		return
	var slot: PanelContainer = slots[step]
	for c in slot.get_children():
		c.queue_free()
	var got := UI.sprite(k, 52)
	got.size_flags_horizontal = SIZE_SHRINK_CENTER
	got.size_flags_vertical = SIZE_SHRINK_CENTER
	slot.add_child(got)
	slot.add_theme_stylebox_override("panel", UI.box(Color("dff0d0"), UI.GOOD, 4))
	b.disabled = true
	step += 1
	if step == icons.size():
		win("%s: Tamam evladım, geleceğim de Fatma'ya!" % Errands.KOMSU)
	else:
		say("Evet, sonra?")
