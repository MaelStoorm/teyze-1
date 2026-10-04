extends Minigame
## Ayarlar: yazı boyutu, ses, müzik, rehber, sıfırlama.

signal show_tutorial

var reset_button: Button
var reset_armed := false


func build() -> void:
	header("Ayarlar", "")
	hint.visible = false
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	content.add_child(box)

	box.add_child(_row("Yazı boyutu", [["Normal", 1.0], ["Büyük", 1.2]], "text",
		func(v): GameState.set_setting("text", v); get_tree().reload_current_scene()))
	box.add_child(_row("Ses efektleri", [["Açık", true], ["Kapalı", false]], "sound",
		func(v): GameState.set_setting("sound", v); Sfx.sound_on = v))
	box.add_child(_row("Müzik", [["Açık", true], ["Kapalı", false]], "music",
		func(v): GameState.set_setting("music", v); Sfx.set_music(v)))

	box.add_child(UI.button("Rehberi tekrar göster", func(): show_tutorial.emit()))
	reset_button = UI.button("Oyunu sıfırla", _reset, 20)
	reset_button.add_theme_color_override("font_color", UI.ACCENT)
	box.add_child(reset_button)


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
