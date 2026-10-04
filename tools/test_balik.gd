extends SceneTree
## Balık tutma oyununun başsız testi.
##   godot --headless --path . -s tools/test_balik.gd
## Ekran görüntüsü için (pencereli):
##   xvfb-run -a godot --resolution 1560x720 --path . -s tools/test_balik.gd -- --shot=/yol/balik --text=1.4
## Kazanma ve kaybetme yollarını dener; finished(true/false) bekler.

var shot := ""
var ok := true


func _initialize() -> void:
	await process_frame
	var ts := 1.0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="):
			shot = a.substr(7)
		elif a.begins_with("--text="):
			ts = float(a.substr(7))
	var UIc = load("res://scripts/ui.gd")
	UIc.text_scale = ts
	var holder := Control.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.theme = UIc.make_theme()
	root.add_child(holder)

	# --- kazanma: her vuruşta çek
	var g = _make(holder, UIc, 7)
	var res := []
	g.finished.connect(func(s): res.append(s))
	await _wait(g, 0)
	await _snap(g, "1_start")
	var shots_taken := {}
	var casts := 0
	while res.is_empty() and casts < 10:
		await _wait_state(g, 0)  # READY
		if not res.is_empty():
			break
		if g.state != 0:
			break
		g._on_action()  # olta at
		casts += 1
		await _wait_state(g, 2)  # WAITING
		if casts == 1 and not shots_taken.has("wait"):
			shots_taken["wait"] = true
			g.pace = 1.0
			g.wait_left = 10.0
			await _frames(30)
			await _snap(g, "2_waiting")
			g.pull()  # erken çekme: ceza yok
			assert_true(g.state == 2, "erken çekince bekleme sürmeli")
			g.pace = 0.05
			g.wait_left = 0.1
		await _wait_state(g, 3)  # DIPPING
		if casts == 1:
			g.pace = 1.0
			g.dip_left = 5.0
			await _frames(12)
			await _snap(g, "3_dipping")
			g.pace = 0.05
		g._on_action()  # çek!
		if casts == 1:
			g.pace = 1.0
			await _frames(110)
			await _snap(g, "4_card")
			g.pace = 0.05
		await _wait_res_or_ready(g, res)
	await _wait_res(res)
	print("WIN run: casts=", casts, " caught=", g.caught, " junk=", g.junk, " res=", res)
	assert_true(res == [true], "kazanınca finished(true) gelmeli")
	assert_true(g.caught.size() >= 3, "3 balık tutulmalı")
	if shot != "":
		for k in ["alabalik", "kefal", "altin", "ayakkabi", "yosun"]:
			g._show_card(k)
			await _frames(20)
			await _snap(g, "5_card_" + k)
	g.queue_free()
	await process_frame

	# --- kaybetme: hiç çekmezse 6 atıştan sonra finished(false)
	var g2 = _make(holder, UIc, 3)
	var res2 := []
	g2.finished.connect(func(s): res2.append(s))
	await _wait(g2, 0)
	for i in 6:
		await _wait_state(g2, 0)
		g2._on_action()
	await _wait_res(res2)
	print("LOSE run: casts_left=", g2.casts_left, " res=", res2)
	assert_true(res2 == [false], "haklar bitince finished(false) gelmeli")
	g2.queue_free()

	# --- çok tohum: hep çekince her zaman kazanılır mı (çöp kazanmayı engellemez)
	var wins := 0
	for seed in range(20):
		var g3 = load("res://scripts/minigames/balik.gd").new().setup({"seed": seed})
		g3.pace = 0.0
		var r3 := []
		g3.finished.connect(func(s): r3.append(s))
		holder.add_child(g3)
		await process_frame
		var n := 0
		while r3.is_empty() and n < 2000:
			n += 1
			if g3.state == 0 or g3.state == 3:
				g3._on_action()
			await process_frame
		if r3 == [true]:
			wins += 1
		g3.queue_free()
	print("seed wins: ", wins, "/20")
	assert_true(wins == 20, "hep çekince hep kazanmalı")
	print("BALIK TEST ", "OK" if ok else "FAILED")
	quit(0 if ok else 1)


func _make(holder: Control, UIc, seed: int):
	var g = load("res://scripts/minigames/balik.gd").new().setup({"seed": seed})
	g.pace = 0.05
	holder.add_child(g)
	var back = UIc.button("Mahalleye dön", func(): pass, 18)
	back.custom_minimum_size = Vector2(180, 48)
	g.add_back(back)
	return g


func assert_true(c: bool, msg: String) -> void:
	if not c:
		ok = false
		push_error("FAIL: " + msg)
		print("FAIL: ", msg)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _wait(_g, _s) -> void:
	await _frames(3)


func _wait_state(g, s: int) -> void:
	var n := 0
	while g.state != s and g.state != 5 and n < 600:
		n += 1
		await process_frame


func _wait_res_or_ready(g, res: Array) -> void:
	var n := 0
	while res.is_empty() and g.state != 0 and n < 1200:
		n += 1
		await process_frame


func _wait_res(res: Array) -> void:
	var n := 0
	while res.is_empty() and n < 2000:
		n += 1
		await process_frame


func _snap(_g, name: String) -> void:
	if shot == "":
		return
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	var path := "%s_%s.png" % [shot, name]
	img.save_png(path)
	print("shot ", path)
