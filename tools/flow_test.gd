extends SceneTree
## Bir günü baştan sona oynar: godot --headless -s tools/flow_test.gd

func _initialize() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var gs = root.get_node("GameState")
	gs.reset()
	var start_cookies: int = gs.kurabiye
	for i in 3:
		var errand: Dictionary = gs.current_errand()
		var info := Errands.build(errand)
		main._start_game(errand["type"], info)
		await process_frame
		var g = main.game
		match errand["type"]:
			"pazar":
				for k in info["want"]:
					for n in info["want"][k]:
						g._pick(k, Button.new())
			"haber":
				g._show_tell()
				g._choose("yanlis", Button.new())
				assert(g.step == 0)
				for k in info["icons"]:
					g._choose(k, Button.new())
			"kedi":
				var wrong: int = (info["spot"] + 1) % 6
				g._tap(wrong, TextureButton.new())
				print("  ipucu: ", g.hint.text)
				g._tap(info["spot"], TextureButton.new())
		await create_timer(1.5).timeout
		print("%s bitti -> biten=%d kurabiye=%d" % [errand["type"], gs.done_count, gs.kurabiye])
		assert(main.game == null)
	assert(gs.is_day_over())
	assert(gs.kurabiye == start_cookies + 9)
	gs.new_day()
	assert(gs.day == 2 and gs.done_count == 0)
	print("TAMAM: bir gün oynandı, gün 2 başladı")
	quit(0)
