class_name Splash
extends ColorRect
## Açılış: önce hareketli "MaelStoorm Studios" logosu (girdap gibi dönerek gelir,
## harfler tek tek yazılır), sonra oyunun başlık ekranı. Dokununca oyun başlar.

signal done

var _logo: TextureRect
var _studio: Control
var _title: Control
var _closing := false
var _phase := 0
var _t := 0.0
var _spin := 6.0
var _swirl_alpha := 1.0
var _tap_label: Label
var _studio_tw: Tween


func _ready() -> void:
	color = Color("121e3a")
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	_build_studio()
	_play_studio()


# --- 1. studio logosu ------------------------------------------------------

func _build_studio() -> void:
	_studio = Control.new()
	_studio.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_studio.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_studio)
	var h := HBoxContainer.new()
	h.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 26)
	h.mouse_filter = MOUSE_FILTER_IGNORE
	_studio.add_child(h)
	_logo = TextureRect.new()
	_logo.texture = load("res://assets/brand/logo.png")
	_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_logo.custom_minimum_size = Vector2(150, 150)
	_logo.size_flags_vertical = SIZE_SHRINK_CENTER
	_logo.pivot_offset = Vector2(75, 75)
	_logo.scale = Vector2.ZERO
	h.add_child(_logo)
	var v := VBoxContainer.new()
	v.size_flags_vertical = SIZE_SHRINK_CENTER
	v.custom_minimum_size.x = 250
	h.add_child(v)
	var nm := Label.new()
	nm.name = "Name"
	nm.text = "MaelStoorm"
	nm.add_theme_font_size_override("font_size", 44)
	nm.add_theme_color_override("font_color", Color.WHITE)
	nm.visible_characters = 0
	v.add_child(nm)
	var sub := Label.new()
	sub.name = "Sub"
	sub.text = "S T U D I O S"
	sub.add_theme_font_size_override("font_size", 20)
	sub.add_theme_color_override("font_color", Color("8cc8ff"))
	sub.modulate.a = 0.0
	v.add_child(sub)
	var pres := Label.new()
	pres.name = "Pres"
	pres.text = "sunar"
	pres.add_theme_font_size_override("font_size", 16)
	pres.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	pres.modulate.a = 0.0
	v.add_child(pres)


func _play_studio() -> void:
	Sfx.play("whoosh", -2.0, 0.8)
	var nm: Label = _studio.find_child("Name", true, false)
	var tw := create_tween()
	_studio_tw = tw
	tw.tween_property(_logo, "scale", Vector2.ONE, 0.9).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(self, "_spin", 0.6, 1.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_method(func(n: int):
		if n > nm.visible_characters:
			Sfx.play("tap", -16.0, 1.0 + n * 0.05)
		nm.visible_characters = n, 0, nm.text.length(), 0.55)
	tw.tween_property(_studio.find_child("Sub", true, false), "modulate:a", 1.0, 0.35)
	tw.tween_callback(func(): Sfx.play("levelup", -10.0))
	tw.tween_property(_studio.find_child("Pres", true, false), "modulate:a", 1.0, 0.3)
	tw.parallel().tween_property(self, "_swirl_alpha", 0.0, 0.6)
	tw.tween_interval(0.9)
	tw.tween_callback(_to_title)


func _process(delta: float) -> void:
	_t += delta
	if _phase == 0:
		_logo.rotation += delta * _spin
		queue_redraw()
	elif _tap_label:
		_tap_label.modulate.a = 0.55 + 0.45 * sin(_t * 4.0)


## Logonun çevresinde içe doğru dönen ışık noktaları (girdap).
func _draw() -> void:
	if _phase != 0 or _swirl_alpha <= 0.0:
		return
	var c := _logo.global_position + _logo.size / 2 - global_position
	for i in 48:
		var k := fmod(i / 48.0 + _t * 0.35, 1.0)
		var r := (1.0 - k) * 260.0 + 20.0
		var a := i * 0.9 + k * 9.0
		var p := c + Vector2(cos(a), sin(a) * 0.8) * r
		draw_circle(p, 1.5 + k * 3.0, Color(0.55, 0.8, 1.0, _swirl_alpha * k))


# --- 2. oyunun başlık ekranı ---------------------------------------------------

func _to_title() -> void:
	if _phase != 0:
		return
	if _studio_tw:
		_studio_tw.kill()  # dokunup geçince studio animasyonu yarıda kalır
	_phase = 1
	queue_redraw()
	var fade := create_tween()
	fade.tween_property(_studio, "modulate:a", 0.0, 0.4)
	fade.tween_callback(func():
		_studio.queue_free()
		_build_title())


func _build_title() -> void:
	var bg := TextureRect.new()
	var grad := Gradient.new()
	grad.set_color(0, Color("ffd666"))
	grad.set_color(1, Color("f78c40"))
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_to = Vector2(0, 1)
	bg.texture = gt
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	bg.mouse_filter = MOUSE_FILTER_IGNORE
	_title = Control.new()
	_title.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_title.mouse_filter = MOUSE_FILTER_IGNORE
	_title.modulate.a = 0.0
	add_child(_title)
	_title.add_child(bg)
	var face := TextureRect.new()
	face.texture = load("res://assets/brand/teyze_portre.png")
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	face.anchor_left = 0.02
	face.anchor_right = 0.46
	face.anchor_top = 0.08
	face.anchor_bottom = 1.0
	face.mouse_filter = MOUSE_FILTER_IGNORE
	_title.add_child(face)
	var v := VBoxContainer.new()
	v.anchor_left = 0.46
	v.anchor_right = 0.98
	v.anchor_top = 0.0
	v.anchor_bottom = 1.0
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 6)
	v.mouse_filter = MOUSE_FILTER_IGNORE
	_title.add_child(v)
	var nm := Label.new()
	nm.text = "Fatma Teyze"
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.add_theme_font_size_override("font_size", 52)
	nm.add_theme_color_override("font_color", Color("fff8e6"))
	nm.add_theme_color_override("font_outline_color", Color("8e2f2a"))
	nm.add_theme_constant_override("outline_size", 14)
	v.add_child(nm)
	var tag := Label.new()
	tag.text = "Mahallenin en tatlı işleri"
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.add_theme_font_size_override("font_size", 22)
	tag.add_theme_color_override("font_color", Color("6b2a1e"))
	v.add_child(tag)
	var gap := Control.new()
	gap.custom_minimum_size.y = 30
	v.add_child(gap)
	_tap_label = Label.new()
	_tap_label.text = "Başlamak için dokun"
	_tap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tap_label.add_theme_font_size_override("font_size", 24)
	_tap_label.add_theme_color_override("font_color", Color.WHITE)
	_tap_label.add_theme_color_override("font_outline_color", Color("b5502a"))
	_tap_label.add_theme_constant_override("outline_size", 8)
	v.add_child(_tap_label)
	var foot := Label.new()
	foot.text = "© 2026 MaelStoorm Studios · Tüm hakları saklıdır"
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	foot.anchor_left = 0.5
	foot.anchor_right = 0.98
	foot.anchor_top = 0.9
	foot.anchor_bottom = 0.98
	foot.add_theme_font_size_override("font_size", 14)
	foot.add_theme_color_override("font_color", Color(0.4, 0.15, 0.08, 0.8))
	_title.add_child(foot)
	color = Color("f78c40")
	var tw := create_tween()
	tw.tween_property(_title, "modulate:a", 1.0, 0.4)
	# başlık zıplayarak iner, teyze aşağıdan gelir
	nm.pivot_offset = Vector2(150, 30)
	nm.scale = Vector2(0.2, 0.2)
	tw.tween_property(nm, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	face.position.y += 200
	tw.parallel().tween_property(face, "position:y", face.position.y - 200, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func(): Sfx.play("good", -6.0))
	_phase = 2


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if _phase == 0:
			_to_title()
		elif _phase == 2:
			Sfx.play("tap")
			close()


func close() -> void:
	if _closing:
		return
	_closing = true
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.45)
	tw.tween_callback(func(): done.emit(); queue_free())
