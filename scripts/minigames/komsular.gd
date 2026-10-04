extends Minigame
## Komşular: her komşuyla dostluğun, bugünkü ricası ve sıradaki hediyesi.


func build() -> void:
	header("Komşular", "Ricalarına koş, dostluk kalplerini doldur. Kalpler dolunca hediye verirler.")
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 10)
	scroll.add_child(rows)
	content.add_child(scroll)
	for n in Neighbors.ALL:
		rows.add_child(_row(n))


func _row(n: Dictionary) -> Control:
	var id: String = n["id"]
	var open: bool = GameState.level() >= n["unlock"]
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UI.box(UI.CREAM, UI.INK, 3, 8))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	var face := Portrait.new(Vector2(70, 80), false, n)
	face.size_flags_vertical = SIZE_SHRINK_CENTER
	if not open:
		face.modulate = Color(0, 0, 0, 0.35)
	h.add_child(face)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 4)
	var t := UI.label(n["name"], 19, UI.ACCENT)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.add_child(t)
	if not open:
		var l := UI.label("Seviye %d olunca mahalleye taşınacak." % n["unlock"], 16, UI.INK, true)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		v.add_child(l)
	else:
		var hearts := GameState.hearts(id)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 1)
		for i in Neighbors.MAX_HEARTS:
			var s := UI.sprite("heart", 20)
			if i >= hearts:
				s.modulate = Color(0, 0, 0, 0.22)
			row.add_child(s)
		v.add_child(row)
		var at := Neighbors.next_gift_at(hearts)
		var gift := "Can dostusunuz!" if at == 0 else "%d kalpte hediye: %s" % [at, Neighbors.gift_text(id, at)]
		var g := UI.label(gift, 16, UI.INK, true)
		g.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		v.add_child(g)
		var today := "Bugün bir ricası var, mahallede bul." if GameState.favor_available(id) else "Bugünkü ricası tamam."
		var d := UI.label(today, 16, UI.GOOD if not GameState.favor_available(id) else Color("2f7fc8"), true)
		d.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		v.add_child(d)
	h.add_child(v)
	panel.add_child(h)
	return panel
