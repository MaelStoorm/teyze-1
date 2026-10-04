class_name Takvim
extends Control
## Günün ilk açılışında çıkan hediye takvimi: haftanın yedi günü yan yana,
## geçen günler işaretli, bugün parlıyor, 7. günde sürpriz kese var.

signal closed

var _today_card: Control


func setup(gift: int, surprise: String) -> Takvim:
	set_anchors_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP  # arkadaki mahalleye dokunulmasın
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.35)
	dim.set_anchors_preset(PRESET_FULL_RECT)
	dim.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(PRESET_FULL_RECT)
	center.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UI.box(Color("fff8ea"), UI.INK, 4, 16))
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)
	var head := HBoxContainer.new()
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_theme_constant_override("separation", 8)
	head.add_child(UI.sprite("takvim", 34))
	head.add_child(UI.label("Teyzenin Hediye Takvimi", _cap(26)))
	v.add_child(head)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	v.add_child(row)
	var today := GameState.gift_day()
	for d in range(1, 8):
		var card := _day_card(d, today)
		row.add_child(card)
		if d == today:
			_today_card = card
	var text := "Günaydın %s! Bugün de geldin, al sana %d kurabiye." % [GameState.call_name(), gift]
	if surprise != "":
		text = "Maşallah %s, tam bir hafta oldu! %d kurabiye bir de evin için %s senin. Evim'de seni bekliyor." \
				% [GameState.call_name(), gift, EvEsya.get_item(surprise)["name"]]
	elif today == 7:
		text = "Maşallah %s, tam bir hafta oldu! Al sana %d kurabiye." % [GameState.call_name(), gift]
	elif GameState.streak > 1:
		text += " %d gündür hiç aksatmadın!" % GameState.streak
	if today < 7:
		text += " Yarın da gel, %d kurabiye olur." % GameState.GIFT_DAYS[today]
	var msg := UI.label(text, _cap(19), UI.INK, true)
	msg.custom_minimum_size.x = 520
	v.add_child(msg)
	var ok := UI.button("Günaydın teyzecim", _close, _cap(21))
	ok.custom_minimum_size = Vector2(260, 52)
	ok.size_flags_horizontal = SIZE_SHRINK_CENTER
	v.add_child(ok)
	return self


func _ready() -> void:
	Sfx.play("levelup" if GameState.gift_day() == 7 else "coin", -4.0)
	if _today_card:
		_today_card.pivot_offset = _today_card.size / 2
		var tw := _today_card.create_tween().set_loops(3)
		tw.tween_property(_today_card, "scale", Vector2(1.12, 1.12), 0.25)
		tw.tween_property(_today_card, "scale", Vector2.ONE, 0.25)


func _day_card(d: int, today: int) -> Control:
	var past := d < today
	var now := d == today
	var bg := Color("ffe9a8") if now else (Color("e9e2d4") if past else Color("ffffff"))
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UI.box(bg, Color("d9a21b") if now else UI.INK, 4 if now else 2, 6))
	p.custom_minimum_size = Vector2(70, 0)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 2)
	p.add_child(v)
	v.add_child(UI.label("%d. gün" % d, _cap(15)))
	var icon := UI.sprite("kese" if d == 7 else "kurabiye", 34)
	icon.size_flags_horizontal = SIZE_SHRINK_CENTER
	if past:
		icon.modulate = Color(1, 1, 1, 0.45)
	v.add_child(icon)
	v.add_child(UI.label("✓" if past else str(GameState.GIFT_DAYS[d - 1]), _cap(18), Color("3f8a3a") if past else UI.INK))
	return p


## Takvim tek ekrana sığsın: büyük yazı ayarında yazılar biraz daha az büyür.
func _cap(size: int) -> int:
	return int(size * minf(UI.text_scale, 1.15) / UI.text_scale)


func _close() -> void:
	closed.emit()
	queue_free()
