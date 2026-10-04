extends Minigame
## Dükkan: kurabiyelerle kalıcı perkler al.

var rows: VBoxContainer
var cookie_label: Label


func build() -> void:
	header("Teyzenin Dükkanı", "Kurabiyelerinle işini kolaylaştıran hediyeler al.")
	var bal := HBoxContainer.new()
	bal.alignment = BoxContainer.ALIGNMENT_CENTER
	bal.add_child(UI.sprite("kurabiye", 34))
	cookie_label = UI.label("", 24)
	bal.add_child(cookie_label)
	content.add_child(bal)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rows = VBoxContainer.new()
	rows.size_flags_horizontal = SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 10)
	scroll.add_child(rows)
	content.add_child(scroll)
	_fill()


func _fill() -> void:
	cookie_label.text = str(GameState.kurabiye)
	for c in rows.get_children():
		c.queue_free()
	for p in Perks.ALL:
		var lv := GameState.perk_level(p["id"])
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", UI.box(UI.CREAM, UI.INK, 3, 8))
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 8)
		var ic := UI.sprite(p["icon"], 48)
		ic.size_flags_vertical = SIZE_SHRINK_CENTER
		h.add_child(ic)
		var v := VBoxContainer.new()
		v.size_flags_horizontal = SIZE_EXPAND_FILL
		var title := p["name"] as String
		if p["max"] > 1:
			title += "  %d/%d" % [lv, p["max"]]
		var t := UI.label(title, 19, UI.ACCENT)
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		v.add_child(t)
		var d := UI.label(p["desc"], 16, UI.INK, true)
		d.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		v.add_child(d)
		h.add_child(v)
		var b := Button.new()
		b.custom_minimum_size = Vector2(72, 56)
		b.size_flags_vertical = SIZE_SHRINK_CENTER
		b.add_theme_font_size_override("font_size", 20)
		if lv >= p["max"]:
			b.text = "Var"
			b.disabled = true
		else:
			var price := Perks.price(p["id"], lv)
			b.text = str(price)
			b.icon = UI.tex("kurabiye")
			b.expand_icon = false
			b.add_theme_constant_override("icon_max_width", 22)
			b.disabled = GameState.kurabiye < price
			b.pressed.connect(_buy.bind(p))
		h.add_child(b)
		panel.add_child(h)
		rows.add_child(panel)


func _buy(p: Dictionary) -> void:
	if GameState.buy_perk(p["id"]):
		say("%s senin! Güle güle kullan evladım." % p["name"], UI.GOOD)
	_fill()
