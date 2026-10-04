class_name UI
## Ortak görünüm: büyük yazı, büyük butonlar, sıcak renkler.

const INK := Color("3b2a1e")
const CREAM := Color("fff4dc")
const CREAM_DARK := Color("f0dcb4")
const ACCENT := Color("c8412f")
const GOOD := Color("4f8a5b")

static var _textures := {}


static func tex(name: String) -> Texture2D:
	if not _textures.has(name):
		_textures[name] = load("res://assets/icons/%s.png" % name)
	return _textures[name]


static func make_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = 22
	t.set_color("font_color", "Label", INK)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		t.set_color(state, "Button", INK)
	t.set_stylebox("normal", "Button", box(CREAM, INK, 3))
	t.set_stylebox("hover", "Button", box(CREAM, INK, 3))
	t.set_stylebox("pressed", "Button", box(CREAM_DARK, INK, 3))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_stylebox("disabled", "Button", box(Color("e0d6c4"), Color("9a8b78"), 3))
	t.set_color("font_disabled_color", "Button", Color("9a8b78"))
	t.set_stylebox("panel", "PanelContainer", box(CREAM, INK, 4, 14))
	return t


static func box(bg: Color, border: Color, width := 3, margin := 12) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(10)
	s.set_content_margin_all(margin)
	s.shadow_color = Color(0, 0, 0, 0.25)
	s.shadow_offset = Vector2(0, 3)
	return s


## Verilen yükseklikte (piksel) bir ikon; en-boy oranı korunur.
static func sprite(name: String, height := 56.0) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex(name)
	var ts := r.texture.get_size()
	r.custom_minimum_size = Vector2(ts.x * height / ts.y, height)
	r.size = r.custom_minimum_size
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


## wrap: uzun metinler için. Sarılan etiketin genişliği kabından gelmeli.
static func label(text: String, size := 22, color := INK, wrap := false) -> Label:
	var l := Label.new()
	l.text = text
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func button(text: String, on_press: Callable, size := 22) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 60)
	b.add_theme_font_size_override("font_size", size)
	b.pressed.connect(func(): Sfx.play("tap", -4.0))
	b.pressed.connect(on_press)
	return b


## Resimli büyük buton (pazar ürünleri, mesaj kartları).
static func icon_button(icon: String, caption: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(100, 108)
	if on_press.is_valid():
		b.pressed.connect(on_press)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 2)
	var s := sprite(icon, 54)
	s.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(s)
	var l := label(caption, 18)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(l)
	b.add_child(v)
	return b


## Tam ekran, kenar boşluklu dikey düzen.
static func page(parent: Control, margin := 12) -> VBoxContainer:
	var m := MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, margin)
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 12)
	m.add_child(v)
	parent.add_child(m)
	return v


static func spacer() -> Control:
	var c := Control.new()
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


static func shake(node: Control) -> void:
	Sfx.play("bad", -3.0)
	var x := node.position.x
	var tw := node.create_tween()
	for d in [8, -8, 6, -6, 0]:
		tw.tween_property(node, "position:x", x + d, 0.05)


static func pop(node: Control) -> void:
	Sfx.play("good", -2.0, randf_range(0.95, 1.08))
	node.pivot_offset = node.size / 2
	var tw := node.create_tween()
	tw.tween_property(node, "scale", Vector2(1.15, 1.15), 0.08)
	tw.tween_property(node, "scale", Vector2.ONE, 0.12)
