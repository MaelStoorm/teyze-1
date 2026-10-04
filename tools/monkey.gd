extends SceneTree
## Rastgele dokunuşlarla oyunu uzun süre oynar, takılma ve hata arar:
## xvfb-run godot --path . --resolution 1280x720 -s tools/monkey.gd -- --taps=3000

var main
var gs
var busy_since := -1.0
## Sahneyi yeniden yükleyen düğmeler (test main'i kaybeder).
const SKIP := ["Oyunu sıfırla", "Emin misin? Her şey silinir", "Hızlı", "Dengeli", "Güzel"]


func _initialize() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	gs = root.get_node("GameState")
	gs.reset()
	gs.set_setting("grafik", 0)
	gs.avatar = {"gender": "kiz"}
	for c in main.get_children():
		if c.get_script() and c.get_script().resource_path.ends_with("splash.gd"):
			c.queue_free()
	main._tutorial(0)
	var taps := 3000
	var seed_v := 1
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--taps="):
			taps = int(a.substr(7))
		if a.begins_with("--seed="):
			seed_v = int(a.substr(7))
	seed(seed_v)
	var size: Vector2 = root.get_visible_rect().size
	var t0 := Time.get_ticks_msec()
	var opened := {}
	for i in taps:
		var p := Vector2(randf() * size.x, randf() * size.y)
		if randf() < 0.1 and main.joystick and main.joystick.is_visible_in_tree():
			# yürüme kolunu bir süre bir yöne it
			main.joystick.value = Vector2.from_angle(randf() * TAU)
			for k in randi_range(5, 40):
				await process_frame
			main.joystick.value = Vector2.ZERO
			continue
		if randf() < 0.15 and main.game == null and not main.dialog.visible:
			# mahallede birine/bir şeye dokun
			var ids: Array = main.world.targets.keys()
			var t: Dictionary = main.world.targets[ids.pick_random()]
			var cam: Camera3D = main.world.camera
			var tp: Vector3 = t["node"].global_position + Vector3(0, t["h"] * 0.6, 0)
			if not cam.is_position_behind(tp):
				p = cam.unproject_position(tp) / main.world.pixel_scale + main.world.get_global_rect().position
		elif randf() < 0.5:
			# görünen bir düğmeye bas (rastgele noktadan daha verimli)
			var btns: Array = main.find_children("*", "BaseButton", true, false).filter(
				func(b): return b.is_visible_in_tree() and not b.disabled and not (b is Button and b.text in SKIP))
			if not btns.is_empty():
				var b: Control = btns.pick_random()
				p = b.get_global_rect().get_center()
		_click(p)
		for k in randi_range(2, 12):
			await process_frame
		if main.game != null:
			opened[main.game.get_script().resource_path.get_file()] = true
		var now := Time.get_ticks_msec() / 1000.0
		if main.busy:
			if busy_since < 0:
				busy_since = now
			elif now - busy_since > 15.0:
				print("TAKILDI: busy 15 sn'den uzun, dokunuş ", i)
				busy_since = now
		else:
			busy_since = -1.0
		if i % 50 == 0:
			print("DURUM %d tut=%d busy=%s dialog=%s game=%s task=%s errand=%s" % [i, main.tutorial_step, main.busy, main.dialog.visible, main.game != null, main.task.get("kind", "-"), gs.current_errand().get("type", "-")])
		if i % 500 == 0:
			print("MONKEY %d dokunuş: gün %d, Sv %d, kurabiye %d, açılan ekranlar %s" % [i, gs.day, gs.level(), gs.kurabiye, opened.keys()])
	print("MONKEY BİTTİ %d dokunuş, %d sn, gün %d, kurabiye %d, xp %d, ekranlar %s" % [taps, (Time.get_ticks_msec() - t0) / 1000, gs.day, gs.kurabiye, gs.xp, opened.keys()])
	quit()


func _click(p: Vector2) -> void:
	for pressed in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = pressed
		e.position = p
		e.global_position = p
		root.push_input(e, true)  # tasarım (640x360) koordinatında
