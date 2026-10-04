extends Minigame
## Karakter oluşturma: kız/erkek, ad, ten, saç modeli ve rengi, kıyafet.

var look := {}
var preview: ModelThumb
var name_edit: LineEdit
var rows: VBoxContainer


func build() -> void:
	look = Avatar.normalized(GameState.avatar)
	header("Karakterin", "")
	hint.visible = false
	preview = ModelThumb.new(Avatar.build(look), Vector2(200, 190), 2.5, 0.85)
	preview.size_flags_horizontal = SIZE_SHRINK_CENTER
	content.add_child(preview)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rows = VBoxContainer.new()
	rows.size_flags_horizontal = SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 8)
	scroll.add_child(rows)
	content.add_child(scroll)
	var ok := UI.button("Tamam, mahalleye çık", _done, 22)
	ok.custom_minimum_size.y = 56
	content.add_child(ok)
	_fill()


func _fill() -> void:
	for c in rows.get_children():
		c.queue_free()
	var nh := HBoxContainer.new()
	var nl := UI.label("Adın", 18, UI.ACCENT)
	nl.custom_minimum_size.x = 70
	nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	nh.add_child(nl)
	name_edit = LineEdit.new()
	name_edit.text = look["name"]
	name_edit.placeholder_text = "İstersen yaz"
	name_edit.max_length = 14
	name_edit.size_flags_horizontal = SIZE_EXPAND_FILL
	name_edit.custom_minimum_size.y = 44
	name_edit.add_theme_font_size_override("font_size", int(20 * UI.text_scale))
	name_edit.add_theme_stylebox_override("normal", UI.box(Color.WHITE, UI.INK, 3, 8))
	name_edit.add_theme_stylebox_override("focus", UI.box(Color.WHITE, UI.GOOD, 3, 8))
	name_edit.add_theme_color_override("font_color", UI.INK)
	name_edit.add_theme_color_override("font_placeholder_color", Color("9a8b78"))
	name_edit.text_changed.connect(func(t): look["name"] = t.strip_edges())
	nh.add_child(name_edit)
	rows.add_child(nh)
	rows.add_child(_choices("", [["Kız", "kiz"], ["Erkek", "erkek"]], "gender", true))
	rows.add_child(_swatches("Ten", Avatar.SKINS, "skin"))
	var styles := []
	for i in Avatar.HAIRSTYLES[look["gender"]].size():
		styles.append([Avatar.HAIRSTYLES[look["gender"]][i][1], i])
	rows.add_child(_choices("Saç", styles, "hair"))
	rows.add_child(_swatches("Saç rengi", Avatar.HAIR_COLORS, "hair_color"))
	rows.add_child(_swatches("Üst", Avatar.TOPS, "top"))
	var bottoms := []
	for i in Avatar.BOTTOM_STYLES[look["gender"]].size():
		bottoms.append([Avatar.BOTTOM_STYLES[look["gender"]][i][1], i])
	rows.add_child(_choices("Alt", bottoms, "bottom_style"))
	rows.add_child(_swatches("Alt rengi", Avatar.BOTTOMS, "bottom"))


## Yazılı seçenek düğmeleri. regroup: değişince satırlar yeniden kurulur.
func _choices(title: String, options: Array, key: String, regroup := false) -> Control:
	var v := VBoxContainer.new()
	if title != "":
		var t := UI.label(title, 18, UI.ACCENT)
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		v.add_child(t)
	var grid := GridContainer.new()
	grid.columns = mini(options.size(), 4 if options.size() != 4 else 2)
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	for opt in options:
		var on: bool = look[key] == opt[1]
		var b := UI.button(opt[0], func(): _pick(key, opt[1], regroup), 18)
		b.size_flags_horizontal = SIZE_EXPAND_FILL
		b.custom_minimum_size.y = 46
		b.add_theme_stylebox_override("normal", UI.box(Color("dff0d0") if on else UI.CREAM, UI.GOOD if on else UI.INK, 4 if on else 3))
		grid.add_child(b)
	v.add_child(grid)
	return v


## Renk kutucukları; seçili olan kalın yeşil çerçeveli.
func _swatches(title: String, colors: Array, key: String) -> Control:
	var v := VBoxContainer.new()
	var t := UI.label(title, 18, UI.ACCENT)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.add_child(t)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	for i in colors.size():
		var on: bool = look[key] == i
		var b := Button.new()
		b.custom_minimum_size = Vector2(34, 34)
		for st in ["normal", "hover", "pressed", "focus"]:
			var sb := UI.box(Color(colors[i]), UI.GOOD if on else UI.INK, 5 if on else 2, 4)
			sb.set_corner_radius_all(17)
			b.add_theme_stylebox_override(st, sb)
		b.pressed.connect(func(): Sfx.play("tap"); _pick(key, i, false))
		h.add_child(b)
	v.add_child(h)
	return v


func _pick(key: String, value, regroup: bool) -> void:
	look[key] = value
	if regroup:  # kız/erkek değişince saç ve alt listeleri değişir
		look["hair"] = 0
		look["bottom_style"] = 0
	preview.set_model(Avatar.build(look))
	_fill.call_deferred()


func _done() -> void:
	look["name"] = name_edit.text.strip_edges()
	GameState.set_avatar(look)
	finished.emit(true)
