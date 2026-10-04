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
	gs.avatar = {"gender": "kiz"}
	for c in main.get_children():
		if c is Splash:  # açılış ekranı testte beklenmez
			c.queue_free()
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
	# komşular: her gün bir rica, kalpler, hediyeler (dünyada yürüyerek yapılan işler)
	assert(gs.neighbors_unlocked().size() == 4, "Sv 5'te dört komşu da açık olmalı")
	main._refresh()
	assert(main.world.neighbors.size() == 4)
	gs.kurabiye = 0
	var kinds := {}
	for d in 6:
		var others := ["fatma"]
		for o in gs.neighbors_unlocked():
			others.append(o["id"])
		for n in gs.neighbors_unlocked():
			var id: String = n["id"]
			assert(gs.favor_available(id))
			gs.favor_seeds[id] = d * 7 + 2  # her gün farklı, tekrarlanabilir içerik
			var info := Neighbors.favor(id, gs.favor_seed(id), gs.level(), others)
			kinds[info["kind"]] = true
			if info["kind"] == "game":
				await _play({"type": info["type"]}, info)
			else:
				main._start_task(id, info)
				await _do_task(id, info)
			assert(not gs.favor_available(id), "%s ricası bitmedi" % id)
			assert(main.task.is_empty())
		gs.new_day()
	assert(kinds.has("shop") and kinds.has("deliver") and kinds.has("find") and kinds.has("game"), "her tür iş denenmeli: %s" % kinds)
	assert(gs.hearts("filiz") == 6 and gs.hearts("hulya") == 6 and gs.hearts("ahmet") == 6)
	assert(gs.decor.has("kusevi") and gs.decor.has("sardunya") and gs.decor.has("salincak") and gs.decor.has("tavla"), "6 kalpte süs hediyesi gelmeli")
	main.world.refresh_decor()
	assert(main.world._decor_nodes.has("salincak"))
	# Sütlü: günde bir kez beslenir
	assert(not gs.sutlu_fed_today())
	main._feed_sutlu()
	assert(gs.sutlu_fed_today() and gs.sutlu_love == 1 and main.world.sutlu_follow)
	gs.feed_sutlu()
	assert(gs.sutlu_love == 1, "aynı gün iki kez sevgi artmamalı")
	# karakter
	gs.set_avatar({"gender": "erkek", "hair": 2, "name": "Ali"})
	main.world.set_player_look(gs.avatar)
	assert(gs.call_name() == "Ali")
	print("Komşular: kalpler %s, kurabiye %d" % [gs.friendship, gs.kurabiye])
	print("TAMAM: 6 gün oynandı, yeni görevler açıldı, dükkan ve komşular çalışıyor")
	quit(0)


## Dünyadaki işi adım adım yapar (yürümeden, doğrudan etkileşimle).
func _do_task(giver: String, info: Dictionary) -> void:
	match info["kind"]:
		"shop":
			main._interact(giver)  # liste bitmeden dönünce iş bitmemeli
			assert(not main.task.is_empty())
			for item in info["want"]:
				for k in info["want"][item]:
					main._buy_item(_stall_of(item), item)
			main._buy_item(_stall_of(info["want"].keys()[0]), info["want"].keys()[0])  # fazlası alınmaz
		"deliver":
			if not main.task["carrying"]:
				main._interact(info["pickup"])
			for t in info["targets"]:
				main._interact(t)
		"find":
			main._interact("gozluk")
	if not main.task.is_empty():
		main._interact(giver)
	main._close_dialog()


func _stall_of(item: String) -> String:
	for k in Props.STALLS:
		if item in Props.STALLS[k]["items"]:
			return "stall_" + k
	return ""


func _play(errand: Dictionary, info := {}) -> void:
	if info.is_empty():
		info = Errands.build(errand)
	if errand["type"] == "pazar":  # Fatma'nın pazar işi artık pazar yerinde
		info["kind"] = "shop"
		main._start_task("fatma", info)
		await _do_task("fatma", info)
		return
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
	await create_timer(2.2).timeout
	assert(main.game == null, "%s bitmedi" % errand["type"])
