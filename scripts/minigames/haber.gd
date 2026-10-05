extends Minigame
## Komşuya haber: teyzenin sözünü aklında tut, komşuya sırasıyla anlat.
## Yanlış kelime ve ikinciden sonraki "teyze ne demişti?" bakışları yıldızdan
## götürür. Seviye 3'ten sonra seçenek çoğalır, 4'ten sonra haber uzar.

const DISTRACTORS := ["ay", "gunes", "cay", "borek", "ev", "kurabiye", "simit", "kapi", "yumurta", "peynir"]

var icons: Array
var step := 0
var learn: Control
var tell: Control
var slots: Array = []
var option_buttons := {}
var go_button: Button
var again_button: Button
var level := 1
var peeks := 0


func build() -> void:
	rated = true
	icons = data["icons"]
	level = data.get("level", 1)
	header("Komşuya Haber", "")
	# düğmeler sol sütunda: ekran ne kadar kısa olursa olsun hep görünür
	go_button = UI.button("Aklımda, götürüyorum", _show_tell, 18)
	add_action(go_button)
	again_button = UI.button("Teyze ne demişti?", peek, 18)
	add_action(again_button)
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
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	var t := Portrait.new(Vector2(80, 80))
	t.size_flags_vertical = SIZE_SHRINK_CENTER
	top.add_child(t)
	var p := PanelContainer.new()
	p.size_flags_horizontal = SIZE_EXPAND_FILL
	p.add_child(UI.label("“%s”" % data["text"], 19, UI.INK, true))
	top.add_child(p)
	v.add_child(top)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var many := icons.size() > 3  # 4 kart ekrana sığsın diye biraz küçült
	row.add_theme_constant_override("separation", 6 if many else 10)
	for i in icons.size():
		var card := PanelContainer.new()
		var c := VBoxContainer.new()
		c.add_child(UI.label(str(i + 1), 16, UI.ACCENT))
		var s := UI.sprite(icons[i], 44 if many else 50)
		s.size_flags_horizontal = SIZE_SHRINK_CENTER
		c.add_child(s)
		c.add_child(UI.label(Errands.ICON_NAMES[icons[i]], 15 if many else 17))
		card.add_child(c)
		row.add_child(card)
	v.add_child(row)
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
	var count := 8 if level >= 3 else 6
	options.append_array(extra.slice(0, count - icons.size()))
	options.shuffle()
	var grid := GridContainer.new()
	grid.columns = 4 if count > 6 else 3
	grid.size_flags_horizontal = SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	for k in options:
		var b := UI.icon_button(k, Errands.ICON_NAMES[k], Callable())
		b.custom_minimum_size = Vector2(96, 94)
		b.pressed.connect(_choose.bind(k, b))
		option_buttons[k] = b
		grid.add_child(b)
	v.add_child(grid)
	return v


func _show_learn() -> void:
	learn.visible = true
	tell.visible = false
	go_button.visible = true
	again_button.visible = false
	if peeks == 0:
		say("Teyzenin sözünü sırasıyla aklında tut.")


## Teyzenin sözüne yeniden bakmak: ilki serbest, sonrakiler yıldızdan götürür.
func peek() -> void:
	if step >= icons.size():
		return
	peeks += 1
	_show_learn()
	if peeks == 1:
		say("Bu bakış serbest; sonrakiler yıldız götürür.")
	else:
		mistake("Olsun, bir daha bakalım.")


func _show_tell() -> void:
	learn.visible = false
	tell.visible = true
	go_button.visible = false
	again_button.visible = true
	say("%s: Hoş geldin evladım! Fatma ne dedi? Sırasıyla seç." % Errands.KOMSU)


func _choose(k: String, b: Button) -> void:
	if step >= icons.size():
		return
	if k != icons[step]:
		mistake("Hmm, öyle mi dedi? Bir daha düşün.", b)
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
