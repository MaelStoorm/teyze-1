extends SceneTree
## Günün işlerinde yıldız testi: godot --headless -s tools/test_yildiz.gd
## Her iş için Sv 1 ve Sv 5'te hatasız oyun (3 yıldız) ve hatalı oyun (daha az
## yıldız) oynanır. Ekran görüntüsü için: -- --shot=<klasör> (pencereli çalıştır).

const TYPES := ["pazar", "haber", "kedi", "yemek", "altin"]

var shot_dir := ""
var result := []
var ui
var errands


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="):
			shot_dir = a.substr(7)
	ui = load("res://scripts/ui.gd")
	errands = load("res://scripts/errands.gd")
	root.theme = ui.make_theme()
	for t in TYPES:
		for lv in [1, 5]:
			var g = await _start(t, lv)
			await call("_perfect_" + t, g)
			await _until_finished()
			assert(result == [true], "%s Sv%d: hatasız bitmeli %s" % [t, lv, result])
			assert(g.mistakes == 0 and g.stars == 3, "%s Sv%d: 3 yıldız olmalı (hata %d)" % [t, lv, g.mistakes])
			g.queue_free()
			g = await _start(t, lv)
			await call("_sloppy_" + t, g)
			await _until_finished()
			assert(result == [true], "%s Sv%d: hatalı da bitmeli" % [t, lv])
			assert(g.mistakes > 0 and g.stars < 3, "%s Sv%d: daha az yıldız olmalı (hata %d, yıldız %d)" % [t, lv, g.mistakes, g.stars])
			print("%s Sv%d: hatasız 3 yıldız, %d hatayla %d yıldız" % [t, lv, g.mistakes, g.stars])
			g.queue_free()
	await _check_thresholds()
	if shot_dir != "":
		for s in [1.0, 1.4]:
			await _shots(s)
	print("test_yildiz: OK")
	quit()


func _check_thresholds() -> void:
	var g = await _start("kedi", 1)
	for m in [0, 1, 2, 3, 5]:
		g.mistakes = m
		assert(g.star_count() == (3 if m == 0 else 2 if m <= g.star_limit else 1))
	g.queue_free()


func _start(t: String, lv: int, seed := 3):
	result.clear()
	var info: Dictionary = errands.build({"type": t, "seed": seed, "level": lv})
	var g = load("res://scripts/minigames/%s.gd" % t).new().setup(info)
	g.finished.connect(func(ok): result.append(ok))
	root.add_child(g)
	await process_frame
	var back = ui.button("Teyzeye dön", func(): pass, 18)
	back.custom_minimum_size = Vector2(160, 44)
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	g.add_back(back)
	await process_frame
	await process_frame
	return g


func _until_finished() -> void:
	var t := 0
	while result.is_empty() and t < 2000:
		await process_frame
		t += 1


func _wait(s: float) -> void:
	await create_timer(s).timeout


## Bir kaptaki, verilen ikonu taşıyan düğme.
func _btn(box: Node, icon: String) -> Button:
	for c in box.get_children():
		if c is Button and _has_icon(c, icon):
			return c
		var found := _btn(c, icon)
		if found != null:
			return found
	return null


func _has_icon(n: Node, icon: String) -> bool:
	if n is TextureRect and n.texture != null and n.texture.resource_path.ends_with("/%s.png" % icon):
		return true
	for c in n.get_children():
		if _has_icon(c, icon):
			return true
	return false


func _tap(box: Node, icon: String) -> void:
	var b := _btn(box, icon)
	assert(b != null, "düğme yok: " + icon)
	b.pressed.emit()


# --- pazar -------------------------------------------------------------------

func _perfect_pazar(g) -> void:
	assert(g.memory == (g.level >= 4))
	if g.memory:
		assert(not g.grid.visible, "akılda tutma modunda tezgah önce gizli")
		g._go_shop()
		g.peek()  # ilk bakış serbest
		assert(g.mistakes == 0)
		g._go_shop()
	for k in g.want:
		for n in g.want[k]:
			_tap(g.grid, k)


func _sloppy_pazar(g) -> void:
	if g.memory:
		g._go_shop()
	var wrong := ""
	for b in g.grid.get_children():
		for k in ["biber", "sogan", "havuc", "domates", "ekmek", "simit", "peynir", "zeytin", "karpuz", "yumurta"]:
			if wrong == "" and not g.want.has(k) and _has_icon(b, k):
				wrong = k
	_tap(g.grid, wrong)
	_tap(g.grid, wrong)
	assert(g.mistakes == 2)
	var first: String = g.want.keys()[0]
	for n in g.want[first]:
		_tap(g.grid, first)
	_tap(g.grid, first)  # fazlası
	assert(g.mistakes == 3)
	if g.memory:
		g.peek()
		g.peek()
		assert(g.mistakes == 4, "ikinci bakış hata sayılmalı")
		g._go_shop()
	for k in g.want:
		while g.got[k] < g.want[k]:
			_tap(g.grid, k)


# --- haber -------------------------------------------------------------------

func _perfect_haber(g) -> void:
	assert(g.option_buttons.size() == (8 if g.level >= 3 else 6))
	g._show_tell()
	g.peek()
	assert(g.mistakes == 0, "ilk bakış serbest")
	g._show_tell()
	for k in g.icons:
		g.option_buttons[k].pressed.emit()


func _sloppy_haber(g) -> void:
	g._show_tell()
	var wrong: String = g.option_buttons.keys().filter(func(k): return k not in g.icons)[0]
	g.option_buttons[wrong].pressed.emit()
	g.option_buttons[g.icons[0]].pressed.emit()
	g.option_buttons[wrong].pressed.emit()
	g.peek()
	g.peek()
	assert(g.mistakes == 3)
	g._show_tell()
	for k in g.icons.slice(1):
		g.option_buttons[k].pressed.emit()


# --- kedi --------------------------------------------------------------------

func _perfect_kedi(g) -> void:
	assert(g.spots.size() == (8 if g.level >= 5 else 6))
	g.buttons[g.cat_spot].pressed.emit()


func _sloppy_kedi(g) -> void:
	var j: int = (g.cat_spot + 1) % g.spots.size()
	g.buttons[j].pressed.emit()
	assert(g.mistakes == 0, "ilk yoklama serbest")
	g.buttons[j].pressed.emit()  # zaten bakılmış yer
	assert(g.mistakes == 1)
	assert(g.moved == (g.level >= 3), "Sv3+ Pamuk bir kez yer değiştirir")
	assert(g.cat_spot in g.possible)
	g.buttons[j].pressed.emit()
	g.buttons[j].pressed.emit()
	assert(g.mistakes == 3)
	# sese uyan yerlerden birine bakmak hata değil
	var ok: Array = g.possible.filter(func(s): return s != g.cat_spot)
	if not ok.is_empty():
		g.buttons[ok[0]].pressed.emit()
		assert(g.mistakes == 3, "sese uyan yer hata sayılmaz")
	g.buttons[g.cat_spot].pressed.emit()


# --- yemek -------------------------------------------------------------------

func _perfect_yemek(g) -> void:
	assert(g.ordered == (g.level >= 3))
	for k in g.items:
		_tap(g.pantry, k)
	assert(g.stirring)
	for n in g.stirs_needed:
		g.pot.pressed.emit()


func _sloppy_yemek(g) -> void:
	var wrong := ""
	for b in g.pantry.get_children():
		for k in load("res://scripts/errands.gd").PANTRY:
			if k not in g.items and _has_icon(b, k):
				wrong = k
	_tap(g.pantry, wrong)
	_tap(g.pantry, wrong)
	if g.ordered:
		_tap(g.pantry, g.items[1])  # sırası değil
		assert(g.mistakes == 3 and not g.added.has(g.items[1]))
	for k in g.items:
		_tap(g.pantry, k)
	for n in g.stirs_needed:
		g.pot.pressed.emit()


# --- altın günü --------------------------------------------------------------

func _perfect_altin(g) -> void:
	assert(g.memory == (g.level >= 3))
	if g.memory:
		assert(g.memo_box.visible and not g.list_box.visible)
		g._show_list()
	for i in g.guests.size():
		g._visit(i)
		_tap(g.visit_box, g.guests[i]["likes"])
		if i < g.guests.size() - 1:
			await _wait(1.05)


func _sloppy_altin(g) -> void:
	if g.memory:
		g._show_list()
		g.peek()
		g.peek()
		assert(g.mistakes == 1)
		g._show_list()
	for i in g.guests.size():
		g._visit(i)
		var likes: String = g.guests[i]["likes"]
		if i == 0:
			var wrong: String = ["cay", "borek", "kurabiye", "simit"].filter(func(k): return k != likes)[0]
			_tap(g.visit_box, wrong)
			_tap(g.visit_box, wrong)
		_tap(g.visit_box, likes)
		if i < g.guests.size() - 1:
			await _wait(1.05)


# --- ekran görüntüleri ---------------------------------------------------------

func _shot(name: String) -> void:
	await process_frame
	await process_frame
	DirAccess.make_dir_recursive_absolute(shot_dir)
	root.get_texture().get_image().save_png(shot_dir.path_join(name + ".png"))


func _shots(scale: float) -> void:
	ui.text_scale = scale
	root.theme = ui.make_theme()
	var p := "s%d_" % int(scale * 10)
	# pazar Sv5: liste, tezgah, 3 yıldız
	var g = await _start("pazar", 5)
	await _shot(p + "pazar_liste")
	g._go_shop()
	var first: String = g.want.keys()[0]
	_tap(g.grid, first)
	await _wait(0.3)
	await _shot(p + "pazar_tezgah")
	for k in g.want:
		while g.got[k] < g.want[k]:
			_tap(g.grid, k)
	await _wait(1.5)
	await _shot(p + "pazar_3yildiz")
	await _until_finished()
	g.queue_free()
	g = await _start("pazar", 1)
	await _shot(p + "pazar_sv1")
	g.queue_free()
	# haber Sv5
	g = await _start("haber", 5)
	await _shot(p + "haber_ogren")
	g._show_tell()
	g.option_buttons[g.icons[0]].pressed.emit()
	await _shot(p + "haber_anlat")
	g.queue_free()
	# kedi Sv5: bir ıska + 2 yıldız
	g = await _start("kedi", 5)
	var j: int = (g.cat_spot + 1) % g.spots.size()
	g.buttons[j].pressed.emit()
	await _wait(0.4)
	await _shot(p + "kedi_iska")
	g.buttons[j].pressed.emit()
	g.buttons[j].pressed.emit()
	await _wait(0.4)
	await _shot(p + "kedi_kacti")
	g.buttons[g.cat_spot].pressed.emit()
	await _wait(1.5)
	await _shot(p + "kedi_2yildiz")
	await _until_finished()
	g.queue_free()
	# yemek Sv5: kiler, karıştırma, 1 yıldız
	g = await _start("yemek", 5)
	await _shot(p + "yemek_kiler")
	_tap(g.pantry, g.items[1])
	_tap(g.pantry, g.items[2])
	_tap(g.pantry, g.items[3])
	for k in g.items:
		_tap(g.pantry, k)
	g.pot.pressed.emit()
	await _wait(0.3)
	await _shot(p + "yemek_karistir")
	for n in g.stirs_needed:
		g.pot.pressed.emit()
	await _wait(1.5)
	await _shot(p + "yemek_1yildiz")
	await _until_finished()
	g.queue_free()
	# altın günü Sv5: kim ne sever, liste, ziyaret
	g = await _start("altin", 5)
	await _shot(p + "altin_hafiza")
	g._show_list()
	await _shot(p + "altin_liste")
	g._visit(3)
	await _shot(p + "altin_ziyaret")
	g.queue_free()
	g = await _start("altin", 1)
	await _shot(p + "altin_sv1")
	g.queue_free()
	ui.text_scale = 1.0
	root.theme = ui.make_theme()
