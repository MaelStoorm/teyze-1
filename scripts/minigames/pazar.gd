extends Minigame
## Pazar: teyzenin listesindeki ürünleri tezgahtan seç.

var want: Dictionary
var got := {}
var counters := {}
var done := false


func build() -> void:
	want = data["want"]
	header("Pazar", "Listedekileri tezgahtan seç.")

	var v := content

	# Alışveriş listesi
	var list_panel := PanelContainer.new()
	var list := HBoxContainer.new()
	list.alignment = BoxContainer.ALIGNMENT_CENTER
	list.add_theme_constant_override("separation", 18)
	for k in want:
		got[k] = 0
		var item := HBoxContainer.new()
		item.add_child(UI.sprite(k, 44))
		var c := UI.label("0/%d" % want[k], 24)
		counters[k] = c
		item.add_child(c)
		list.add_child(item)
	list_panel.add_child(list)
	v.add_child(list_panel)

	var stall := UI.sprite("stall", 100)
	stall.size_flags_horizontal = SIZE_SHRINK_CENTER
	v.add_child(stall)

	# Tezgah: listedekiler + birkaç fazladan ürün, karışık
	var keys := want.keys()
	for k in Errands.MARKET:
		if keys.size() >= 6:
			break
		if k not in keys:
			keys.append(k)
	keys.shuffle()
	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	for k in keys:
		var b := UI.icon_button(k, Errands.MARKET[k], Callable())
		b.pressed.connect(_pick.bind(k, b))
		if GameState.has_perk("file") and not want.has(k):
			b.modulate.a = 0.45
		grid.add_child(b)
	v.add_child(grid)


func _pick(k: String, b: Button) -> void:
	if done:
		return
	if not want.has(k):
		UI.shake(b)
		say("Teyze %s istemedi ki." % Errands.MARKET[k], UI.ACCENT)
		return
	if got[k] >= want[k]:
		UI.shake(b)
		say("Yeterince %s aldın." % Errands.MARKET[k], UI.ACCENT)
		return
	got[k] += 1
	UI.pop(b)
	var c: Label = counters[k]
	c.text = "%d/%d" % [got[k], want[k]]
	if got[k] == want[k]:
		c.add_theme_color_override("font_color", UI.GOOD)
	say("Sepete koydun.")
	for key in want:
		if got[key] < want[key]:
			return
	done = true
	win("Hepsi tamam! Teyzeye götürelim.")
