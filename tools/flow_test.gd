extends SceneTree
## Birkaç günü baştan sona oynar: godot --headless -s tools/flow_test.gd

var main
var gs


func _initialize() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	gs = root.get_node("GameState")
	gs.reset()
	var seen := {}
	for d in 6:
		while not gs.is_day_over():
			var errand: Dictionary = gs.current_errand()
			seen[errand["type"]] = true
			await _play(errand)
		print("Gün %d bitti: Sv %d, xp %d, kurabiye %d, görevler %s" % [gs.day, gs.level(), gs.xp, gs.kurabiye, gs.errands.map(func(e): return e["type"])])
		gs.new_day()
	assert(seen.has("yemek") and seen.has("altin"), "yeni görevler gelmedi")
	assert(gs.errands.size() >= 4, "Sv 4'te günde 4 görev olmalı")
	# dükkan
	var before: int = gs.kurabiye
	assert(gs.buy_perk("zil"))
	assert(gs.kurabiye == before - 15)
	assert(not gs.buy_perk("zil"), "tek seferlik perk iki kez alınmamalı")
	gs.kurabiye = 100
	assert(gs.buy_perk("dua"))
	assert(gs.errand_reward("kedi") == 4)
	# takvim: dün oynanmışsa bugün yeni gün, seri artar, hediye gelir
	assert(not gs.check_new_day(), "aynı gün ikinci kez yeni gün olmamalı")
	var day_before: int = gs.day
	gs.errands_date = Time.get_date_string_from_unix_time(Time.get_unix_time_from_system() - 86400)
	gs.streak = 3
	assert(gs.check_new_day())
	assert(gs.streak == 4 and gs.daily_gift == 6 and gs.day == day_before + 1)
	gs.errands_date = Time.get_date_string_from_unix_time(Time.get_unix_time_from_system() - 3 * 86400)
	assert(gs.check_new_day() and gs.streak == 1, "ara verilince seri sıfırlanmalı")
	# süsler
	gs.kurabiye = 25
	assert(gs.buy_decor("kedievi") and gs.kurabiye == 5)
	assert(not gs.buy_decor("kedievi"), "aynı süs iki kez alınmamalı")
	assert(not gs.buy_decor("fener"), "parası yetmeyen süs alınmamalı")
	main.world.refresh_decor()
	assert(main.world._decor_nodes.has("kedievi"))
	# komşular: her gün bir rica, kalpler, hediyeler
	assert(gs.neighbors_unlocked().size() == 3, "Sv 5'te üç komşu da açık olmalı")
	main._refresh()
	assert(main.world.neighbors.size() == 3)
	gs.kurabiye = 0
	for d in 6:
		for n in gs.neighbors_unlocked():
			var id: String = n["id"]
			assert(gs.favor_available(id))
			await _play({"type": n["type"]}, Neighbors.favor(id, gs.favor_seed(id), gs.level()))
			assert(not gs.favor_available(id), "rica bitince tekrar verilmemeli")
		gs.new_day()
	assert(gs.hearts("filiz") == 6 and gs.hearts("hulya") == 6)
	assert(gs.decor.has("kusevi") and gs.decor.has("sardunya") and gs.decor.has("salincak"), "6 kalpte süs hediyesi gelmeli")
	main.world.refresh_decor()
	assert(main.world._decor_nodes.has("salincak"))
	print("Komşular: kalpler %s, kurabiye %d" % [gs.friendship, gs.kurabiye])
	print("TAMAM: 6 gün oynandı, yeni görevler açıldı, dükkan ve komşular çalışıyor")
	quit(0)


func _play(errand: Dictionary, info := {}) -> void:
	if info.is_empty():
		info = Errands.build(errand)
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
			for k in info["icons"]:
				g._choose(k, Button.new())
		"kedi":
			g._tap(info["spot"], TextureButton.new())
		"yemek":
			var wrong: String = Errands.PANTRY.keys().filter(func(k): return k not in info["items"])[0]
			g._add(wrong, Button.new())
			for k in info["items"]:
				g._add(k, Button.new())
			for n in g.stirs_needed:
				g._stir()
		"altin":
			for i in info["guests"].size():
				g._visit(i)
				g._offer("yanlis", Button.new())
				g._offer(info["guests"][i]["likes"], Button.new())
				await create_timer(1.1).timeout
	await create_timer(1.5).timeout
	assert(main.game == null, "%s bitmedi" % errand["type"])
