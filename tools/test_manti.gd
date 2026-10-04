extends SceneTree
## Mantı mini oyununu baştan sona oynar.
##   godot --headless -s tools/test_manti.gd
##   godot -s tools/test_manti.gd -- --shot=<klasör> [--text=1.4]   (her adımın ekran görüntüsü)

var g
var shot_dir := ""
var result := []


func _initialize() -> void:
	create_timer(150).timeout.connect(func():
		printerr("TIMEOUT")
		quit(1))
	if load("res://scripts/minigames/manti.gd") == null or not load("res://scripts/minigames/manti.gd").can_instantiate():
		printerr("manti.gd yüklenemedi")
		quit(1)
		return
	var text := 1.0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="):
			shot_dir = a.substr(7)
		elif a.begins_with("--text="):
			text = float(a.substr(7))
	var ui = load("res://scripts/ui.gd")
	ui.text_scale = text
	var holder := Control.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.theme = ui.make_theme()
	root.add_child(holder)
	g = load("res://scripts/minigames/manti.gd").new().setup({})
	g.finished.connect(func(ok): result.append(ok))
	holder.add_child(g)
	if shot_dir == "":
		g.pace = 0.02
	await _frames(2)
	var back = ui.button("Mahalleye dön", func(): pass, 18)
	back.custom_minimum_size = Vector2(180, 48)
	g.add_back(back)
	await _frames(3)
	var tag := "_t%s" % str(text).replace(".", "")
	await _shot("1_acma" + tag)
	# 1) hamur açma: gerçek dokunma olayı + sürükleme
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = g.area.size / 2
	g.area.gui_input.emit(ev)
	await _idle()
	assert(g.rolls == 1, "dokununca oklava gezmeli")
	var mv := InputEventMouseMotion.new()
	mv.button_mask = MOUSE_BUTTON_MASK_LEFT
	mv.relative = Vector2(0, 200)
	g.area.gui_input.emit(mv)
	await _idle()
	assert(g.rolls == 2, "sürükleyince oklava gezmeli")
	while g.stage == 0:
		if g.rolls == 4:
			await _shot("1b_acma" + tag)
		g.tap(g.bc)
		await _idle()
	assert(g.stage == 1 and g.squareness == 1.0)
	await _shot("2_kesme" + tag)
	# 2) kesme
	var n := 0
	while g.stage == 1:
		g.tap(g.bc)
		await _idle()
		n += 1
		if n == 2:
			await _shot("2b_kesme" + tag)
		assert(n < 10)
	assert(g.cuts == 4)
	await _shot("3_kiyma" + tag)
	# 3) kıyma: aynı kareye iki kez dokunmak da ilerletir (en yakın boşa gider)
	g.tap(g.cell_center(0))
	g.tap(g.cell_center(0))
	assert(g.filled.count(0.0) == 7)
	g.tap(Vector2(1, 1))  # tahtanın dışı: bir şey olmaz
	assert(g.filled.count(0.0) == 7)
	for i in 9:
		if i == 5:
			await _shot("3b_kiyma" + tag)
		g.tap(g.cell_center(i))
		await _frames(1)
	await _idle()
	await _wait_stage(3)
	await _shot("4_kapama" + tag)
	# 4) kapama
	for i in 9:
		if i == 5:
			await _frames(30)
			await _shot("4b_kapama" + tag)
		g.tap(g.cell_center(8 - i))
		await _frames(1)
	await _wait_stage(4)
	await _shot("5_servis" + tag)
	# 5) servis: yanlış kap sadece hatırlatır
	g.tap(g.bowl_rects[2].get_center())
	await _idle()
	assert(g.next_topping == 0 and g.topping[2] == 0.0)
	await _shot("5b_yanlis" + tag)
	for k in 3:
		g.tap(g.bowl_rects[k].get_center())
		await _idle()
		if k == 1:
			await _shot("5c_sos" + tag)
	assert(g.stage == 5)
	await _shot("6_bitti" + tag)
	var t := 0
	while result.is_empty() and t < 600:
		await process_frame
		t += 1
	assert(result == [true], "finished(true) gelmeli")
	print("MANTI OK ", result)
	quit(0)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _idle() -> void:
	await process_frame
	var t := 0
	while g.busy and t < 600:
		await process_frame
		t += 1
	await _frames(2)


func _wait_stage(s: int) -> void:
	var t := 0
	while g.stage != s and t < 900:
		await process_frame
		t += 1
	assert(g.stage == s, "adım %d gelmedi" % s)
	await _idle()


func _shot(name: String) -> void:
	if shot_dir == "":
		return
	await _frames(20)
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [shot_dir, name])
