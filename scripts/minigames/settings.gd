extends Minigame
## Ayarlar: yazı boyutu, ses, müzik, rehber, sıfırlama.

signal show_tutorial
signal edit_avatar

var reset_button: Button
var reset_armed := false


func build() -> void:
	header("Ayarlar", "")
	hint.visible = false
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 12)
	scroll.add_child(box)

	box.add_child(_text_slider())
	box.add_child(_row("Ses efektleri", [["Açık", true], ["Kapalı", false]], "sound",
		func(v): GameState.set_setting("sound", v); Sfx.sound_on = v))
	box.add_child(_row("Müzik", [["Açık", true], ["Kapalı", false]], "music",
		func(v): GameState.set_setting("music", v); Sfx.set_music(v)))

	box.add_child(UI.button("Karakterini değiştir", func(): edit_avatar.emit()))
	box.add_child(UI.button("Rehberi tekrar göster", func(): show_tutorial.emit()))
	reset_button = UI.button("Oyunu sıfırla", _reset, 20)
	reset_button.add_theme_color_override("font_color", UI.ACCENT)
	box.add_child(reset_button)


## Yazı boyutu kaydırma çubuğu: sürüklerken örnek yazı büyür, bırakınca uygulanır.
func _text_slider() -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UI.box(UI.CREAM, UI.INK, 3, 8))
	var v := VBoxContainer.new()
	var top := HBoxContainer.new()
	var l := UI.label("Yazı boyutu", 20, UI.ACCENT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l.size_flags_horizontal = SIZE_EXPAND_FILL
	top.add_child(l)
	var pct := UI.label("", 18)
	top.add_child(pct)
	v.add_child(top)
	var sample := Label.new()
	sample.text = "Aa  Merhaba evladım"
	sample.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sample.custom_minimum_size.y = 40
	v.add_child(sample)
	var s := HSlider.new()
	s.min_value = 0.9
	s.max_value = 1.4
	s.step = 0.05
	s.value = GameState.settings["text"]
	s.custom_minimum_size.y = 44
	var knob := UI.tex_small("kurabiye", 36)
	s.add_theme_icon_override("grabber", knob)
	s.add_theme_icon_override("grabber_highlight", knob)
	s.add_theme_stylebox_override("slider", UI.box(UI.CREAM_DARK, UI.INK, 2, 5))
	s.add_theme_stylebox_override("grabber_area", UI.box(Color("f2c23a"), UI.INK, 2, 5))
	s.add_theme_stylebox_override("grabber_area_highlight", UI.box(Color("f2c23a"), UI.INK, 2, 5))
	var show := func(val: float):
		pct.text = "%%%d" % roundi(val * 100)
		sample.add_theme_font_size_override("font_size", int(20 * val))
	show.call(s.value)
	s.value_changed.connect(show)
	s.drag_ended.connect(func(changed: bool):
		if changed and not is_equal_approx(s.value, GameState.settings["text"]):
			GameState.set_setting("text", s.value)
			get_tree().reload_current_scene())
	v.add_child(s)
	p.add_child(v)
	return p


## Bir başlık ve yan yana seçenek butonları; seçili olan yeşil çerçeveli.
func _row(title: String, options: Array, key: String, apply: Callable) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UI.box(UI.CREAM, UI.INK, 3, 8))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	var l := UI.label(title, 20, UI.ACCENT, true)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	h.add_child(l)
	var buttons: Array[Button] = []
	for opt in options:
		var b := UI.button(opt[0], func(): pass, 18)
		b.custom_minimum_size = Vector2(92, 52)
		buttons.append(b)
		h.add_child(b)
	var mark := func():
		for i in buttons.size():
			var on: bool = GameState.settings[key] == options[i][1]
			buttons[i].add_theme_stylebox_override("normal", UI.box(Color("dff0d0") if on else UI.CREAM, UI.GOOD if on else UI.INK, 4 if on else 3))
	for i in buttons.size():
		buttons[i].pressed.connect(func(): apply.call(options[i][1]); mark.call())
	mark.call()
	p.add_child(h)
	return p


func _reset() -> void:
	if not reset_armed:
		reset_armed = true
		reset_button.text = "Emin misin? Her şey silinir"
		return
	GameState.reset()
	GameState.set_setting("tutorial", false)
	get_tree().reload_current_scene()
