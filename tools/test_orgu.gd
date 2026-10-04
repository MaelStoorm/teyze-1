extends SceneTree
## Örgü mini oyunu testi: godot --headless -s tools/test_orgu.gd
## Ekran görüntüsü için: -- --shot=<klasör> (pencereli çalıştır).

var shot_dir := ""
var result := []


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="):
			shot_dir = a.substr(7)
	var ui = load("res://scripts/ui.gd")
	root.theme = ui.make_theme()
	# 1) dikkatli oyuncu: birkaç kaçan ilmekle bitirir -> finished(true)
	var g = await _start({"seed": 7}, 1.0)
	await _shot("1_baslangic")
	g.pick((g.needed() + 1) % g.yarns.size())
	assert(g.misses == 1 and g.cur_c == 0, "yanlış seçim ilmeği ilerletmemeli")
	g.pick((g.needed() + 1) % g.yarns.size())
	assert(g.misses == 2 and g.tries_here == 2)
	await _wait(0.4)
	await _shot("2_ilmek_kacti")
	for k in 9:
		g.pick(g.needed())
	await _wait(0.4)
	await _shot("3_ortasi")
	g.pace = 0.05
	while not g.done:
		g.pick(g.needed())
	assert(g.cur_r == g.ROWS and g.misses == 2)
	if shot_dir != "":
		g.pace = 1.0
	await _wait(1.0 if shot_dir == "" else 1.9)
	await _shot("4_bitti")
	await _until_finished()
	assert(result == [true], "az kaçan ilmekle başarı olmalı: %s" % [result])
	g.queue_free()
	# 2) çok kaçıran oyuncu -> finished(false), yine de biter
	result.clear()
	g = await _start({"seed": 3, "pattern": "dama", "max_miss": 2}, 0.05)
	while not g.done:
		g.pick((g.needed() + 1) % g.yarns.size())
		g.pick(g.needed())
	assert(g.misses == 24)
	await _until_finished()
	assert(result == [false], "çok kaçan ilmekte false: %s" % [result])
	g.queue_free()
	# 3) her desen kurulur, desende 2+ renk ve en az bir şaşırtmaca yumak var
	for p in ["cizgili", "zikzak", "dama"]:
		var h = await _start({"pattern": p}, 1.0)
		var used := {}
		for row in h.pattern:
			for c in row:
				used[c] = true
		assert(h.pattern_id == p and used.size() >= 2 and used.size() < h.yarns.size(), "desen %s" % p)
		h.queue_free()
	# 4) büyük yazı (1.4) ekran görüntüsü
	ui.text_scale = 1.4
	g = await _start({"seed": 21, "pattern": "zikzak"}, 1.0)
	for k in 8:
		g.pick(g.needed())
	g.pick((g.needed() + 1) % g.yarns.size())
	await _wait(0.4)
	await _shot("5_buyuk_yazi")
	g.queue_free()
	ui.text_scale = 1.0
	g = await _start({"seed": 5, "pattern": "dama"}, 1.0)
	for k in 13:
		g.pick(g.needed())
	await _wait(0.4)
	await _shot("6_dama")
	print("test_orgu: OK")
	quit()


func _start(info: Dictionary, pace: float):
	var g = load("res://scripts/minigames/orgu.gd").new().setup(info)
	g.pace = pace
	g.finished.connect(func(ok): result.append(ok))
	root.add_child(g)
	await process_frame
	var ui = load("res://scripts/ui.gd")
	var back = ui.button("Teyzeye dön", func(): pass, 18)
	back.custom_minimum_size = Vector2(160, 44)
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	g.add_back(back)
	await process_frame
	await process_frame
	return g


func _wait(s: float) -> void:
	await create_timer(s).timeout


func _until_finished() -> void:
	var t := 0
	while result.is_empty() and t < 400:
		await process_frame
		t += 1


func _shot(name: String) -> void:
	if shot_dir == "":
		return
	await process_frame
	await process_frame
	DirAccess.make_dir_recursive_absolute(shot_dir)
	root.get_texture().get_image().save_png(shot_dir.path_join(name + ".png"))
