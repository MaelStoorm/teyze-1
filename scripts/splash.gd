class_name Splash
extends ColorRect
## Oyun açılırken "MaelStoorm Studios" ekranı. Dokununca geçilir.

signal done

var _logo: TextureRect
var _closing := false


func _ready() -> void:
	color = Color("121e3a")
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 6)
	v.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(v)
	_logo = TextureRect.new()
	_logo.texture = load("res://assets/brand/logo.png")
	_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_logo.custom_minimum_size = Vector2(150, 150)
	_logo.size_flags_horizontal = SIZE_SHRINK_CENTER
	_logo.pivot_offset = Vector2(75, 75)
	v.add_child(_logo)
	var gap := Control.new()
	gap.custom_minimum_size.y = 18
	v.add_child(gap)
	var t := Label.new()
	t.text = "MaelStoorm"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 36)
	t.add_theme_color_override("font_color", Color.WHITE)
	v.add_child(t)
	var s := Label.new()
	s.text = "S T U D I O S"
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s.add_theme_font_size_override("font_size", 18)
	s.add_theme_color_override("font_color", Color("8cc8ff"))
	v.add_child(s)
	var p := Label.new()
	p.text = "\nsunar"
	p.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_theme_font_size_override("font_size", 16)
	p.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	v.add_child(p)
	v.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(v, "modulate:a", 1.0, 0.6)
	tw.tween_interval(1.6)
	tw.tween_callback(close)


func _process(delta: float) -> void:
	_logo.rotation += delta * 0.8


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		close()


func close() -> void:
	if _closing:
		return
	_closing = true
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.45)
	tw.tween_callback(func(): done.emit(); queue_free())
