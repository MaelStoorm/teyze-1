extends Minigame
## Pazar: teyzenin listesindeki ürünleri tezgahtan seç.
## Seviye 3'ten sonra tezgahta benzer ürünler de olur; seviye 4'ten sonra
## liste önce gösterilir, sonra akılda tutulur (istenince yine bakılır).

## Tezgahta şaşırtmak için duran, pazar listesinde hiç olmayan ürünler.
const DECOYS := ["biber", "sogan", "havuc"]

var want: Dictionary
var got := {}
var counters := {}
var done := false
var level := 1
## Liste akılda tutulacak mı (seviye 4+)?
var memory := false
var peeks := 0
var list_panel: PanelContainer
var basket: HBoxContainer
var grid: GridContainer
var go_button: Button
var peek_button: Button


func build() -> void:
	rated = true
	want = data["want"]
	level = data.get("level", 1)
	memory = level >= 4
	header("Pazar", "")
	var stall := UI.sprite("stall", 92 if memory else 72)
	stall.size_flags_horizontal = SIZE_SHRINK_CENTER

	var v := content

	# Alışveriş listesi: akılda tutma modunda büyük kartlar ve tezgah resmi,
	# yoksa üstte sayaçlı küçük liste (tezgah resmi sol sütunda).
	list_panel = PanelContainer.new()
	var list := HBoxContainer.new()
	list.alignment = BoxContainer.ALIGNMENT_CENTER
	list.add_theme_constant_override("separation", 22 if memory else 18)
	for k in want:
		got[k] = 0
		var item: BoxContainer = VBoxContainer.new() if memory else HBoxContainer.new()
		var s := UI.sprite(k, 64 if memory else 44)
		s.size_flags_horizontal = SIZE_SHRINK_CENTER
		item.add_child(s)
		var c := UI.label(("%d %s" % [want[k], _name(k)]) if memory else ("0/%d" % want[k]), 22 if memory else 24)
		counters[k] = c
		item.add_child(c)
		list.add_child(item)
	list_panel.add_child(list)
	if memory:
		list_panel.size_flags_horizontal = SIZE_SHRINK_CENTER
		v.add_child(UI.spacer())
		v.add_child(stall)
		v.add_child(list_panel)
		v.add_child(UI.spacer())
	else:
		side.add_child(stall)
		v.add_child(list_panel)

	# Akılda tutma modunda listenin yerine sepet görünür
	basket = HBoxContainer.new()
	basket.alignment = BoxContainer.ALIGNMENT_CENTER
	basket.custom_minimum_size.y = 44
	basket.add_theme_constant_override("separation", 14)
	var basket_panel := PanelContainer.new()
	basket_panel.add_child(basket)
	basket_panel.visible = false
	v.add_child(basket_panel)
	_refresh_basket()

	# Tezgah: listedekiler + birkaç fazladan ürün, karışık. Üst seviyede daha
	# çok ürün ve benzer görünen şaşırtmacalar.
	var count := 8 if level >= 3 else 6
	var keys := want.keys()
	var extra: Array = Errands.MARKET.keys().filter(func(k): return k not in keys)
	extra.shuffle()
	if level >= 3:
		extra = DECOYS.slice(0, 1 if level < 5 else 2) + extra
	for k in extra:
		if keys.size() >= count:
			break
		keys.append(k)
	keys.shuffle()
	grid = GridContainer.new()
	grid.columns = 4 if count > 6 else 3
	grid.size_flags_horizontal = SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	for k in keys:
		var b := UI.icon_button(k, _name(k), Callable())
		b.custom_minimum_size = Vector2(96, 94)
		b.pressed.connect(_pick.bind(k, b))
		if GameState.has_perk("file") and not want.has(k):
			b.modulate.a = 0.45
		grid.add_child(b)
	v.add_child(grid)

	if memory:
		go_button = UI.button("Aklımda, tezgaha", _go_shop, 18)
		add_action(go_button)
		peek_button = UI.button("Listeye bak", peek, 18)
		add_action(peek_button)
		_show_list()
	else:
		say("Listedekileri tezgahtan seç.")


func _name(k: String) -> String:
	return Errands.MARKET.get(k, Errands.PANTRY.get(k, k))


## Akılda tutma: listeyi göster, tezgahı sakla.
func _show_list() -> void:
	_learn_view(true)
	basket.get_parent().visible = false
	grid.visible = false
	go_button.visible = true
	peek_button.visible = false
	if peeks == 0:
		say("Listeye iyi bak, aklında tut.")


func _go_shop() -> void:
	if not memory:
		return
	_learn_view(false)
	basket.get_parent().visible = true
	grid.visible = true
	go_button.visible = false
	peek_button.visible = true
	say("Teyze ne istemişti? Tezgahtan seç.")


func _learn_view(on: bool) -> void:
	list_panel.visible = on
	for c in content.get_children():
		if c is Control and c not in [list_panel, grid, basket.get_parent()]:
			c.visible = on


## Listeye yeniden bakmak: ilki serbest, sonrakiler yıldızdan götürür.
func peek() -> void:
	if not memory or done:
		return
	peeks += 1
	_show_list()
	if peeks == 1:
		say("Bu bakış serbest; sonrakiler yıldız götürür.")
	else:
		mistake("Olsun, bir daha bakalım.")


func _refresh_basket() -> void:
	for c in basket.get_children():
		c.queue_free()
	var any := false
	for k in got:
		if got[k] == 0:
			continue
		any = true
		var item := HBoxContainer.new()
		item.add_child(UI.sprite(k, 40))
		item.add_child(UI.label("%d" % got[k], 22))
		basket.add_child(item)
	if not any:
		basket.add_child(UI.label("Sepet boş", 20, Color("9a8b78")))


func _pick(k: String, b: Button) -> void:
	if done:
		return
	if memory and not grid.visible:
		_go_shop()
	if not want.has(k):
		mistake("Teyze %s istemedi ki." % _name(k), b)
		return
	if got[k] >= want[k]:
		mistake("Yeterince %s aldın." % _name(k), b)
		return
	got[k] += 1
	UI.pop(b)
	var c: Label = counters[k]
	if not memory:
		c.text = "%d/%d" % [got[k], want[k]]
	if got[k] == want[k]:
		c.add_theme_color_override("font_color", UI.GOOD)
	_refresh_basket()
	say("Sepete koydun.")
	for key in want:
		if got[key] < want[key]:
			return
	done = true
	if memory:
		for key in counters:
			counters[key].add_theme_color_override("font_color", UI.GOOD)
		_learn_view(true)
		grid.visible = false
		basket.get_parent().visible = false
	win("Hepsi tamam! Teyzeye götürelim.")
