extends SceneTree
## Hikayenin 1. bölümünü baştan sona oynar: godot --headless -s tools/test_hikaye.gd

var main
var gs


func _initialize() -> void:
	create_timer(150).timeout.connect(func(): print("ZAMAN AŞIMI"); quit(1))
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	gs = root.get_node("GameState")
	gs.reset()
	gs.avatar = {"gender": "kiz"}
	for c in main.get_children():
		if c.get_script() and c.get_script().resource_path.ends_with("splash.gd"):
			c.queue_free()
	gs.settings["tutorial"] = true
	main.tutorial_step = -1
	main._refresh()
	await process_frame
	assert(not gs.chapter_done("firin"))
	assert(not main.world._firin.get_node("Acik").visible, "fırın başta kapalı")
	assert(main._story_who() == "fatma")
	assert(main.world._story_mark.visible and main.world._story_id == "fatma", "Fatma'nın başında altın işaret")
	assert(not main.world.bubble.visible, "mavi ünlem yerine altın işaret")
	assert(main.task_panel.visible and main._story_goal().begins_with("Bölüm 1"), "hedef her zaman görünmeli")
	# kapalı fırına dokununca tozlu kapı
	main._interact("firin")
	assert(main.dialog.visible)
	main._close_dialog()
	# 1. Fatma anlatır
	main._interact("fatma")
	await _press_until_closed()
	assert(main._story_who() == "stall_firin", "sırada Mehmet Usta")
	# 2. Mehmet: seçim
	main._interact("stall_firin")
	await _press(0)
	await _press(1)  # "Mahalle sizi özledi usta"
	await _press(0)  # Devam
	assert(gs.story_flags.has("soz_ozlem"))
	assert(main._story_who() == "ahmet", "sırada Ahmet: %s" % main._story_who())
	# 3. Ahmet odunu verir, Mehmet'e götürülür
	main._interact("ahmet")
	await _press_until_closed()
	assert(main.task.get("kind", "") == "story" and main._task_goals() == ["stall_firin"])
	assert(not main.drop_button.visible, "hikaye işi bırakılmaz")
	main._interact("stall_firin")  # teslim, aynı kişi konuşmayı sürdürür
	await _press_until_closed()
	assert(main.task.is_empty())
	# 4-5. kurabiye: yetmezse söyler, yetince öder
	gs.kurabiye = 5
	main._interact("stall_firin")
	assert(main.dialog.visible)
	await _press(0)
	assert(gs.story_step == 4, "para yetmedi, adım ilerlememeli")
	gs.kurabiye = 25
	main._refresh_task()
	assert(main._story_goal().contains("20/20"))
	main._interact("stall_firin")
	await _press(0)  # 20 kurabiye ver
	assert(gs.kurabiye == 5)
	await _press_until_closed()
	# 6. Hülya 3. seviyede taşınır: o zamana kadar hedef seviye atlamayı söyler
	assert(main._story_who() == "", "Hülya daha taşınmadı")
	assert(main._story_goal().contains("seviye"))
	gs.xp = 200
	main._refresh()
	assert(main._story_who() == "hulya")
	main._interact("hulya")
	await _press(0)
	await _press(0)  # Hamuru açalım
	assert(main.game != null and main._story_game)
	main._quit_game()  # vazgeçerse hikaye oyunu sayılmaz
	assert(not main._story_game and main._story_who() == "hulya")
	main._interact("hulya")
	await _press(0)
	await _press(0)
	main.game.finished.emit(true)
	assert(main.game == null and gs.album.has("manti"))
	await _press_until_closed()  # tarif
	assert(main._task_goals() == ["stall_firin"])
	main._interact("stall_firin")
	await _press_until_closed()
	# 9. Filiz davetiyeleri verir; herkese dağıtılır
	assert(main._story_who() == "filiz")
	main._interact("filiz")
	await _press_until_closed()
	var goals: Array = main._task_goals()
	assert("fatma" in goals and not ("filiz" in goals) and goals.size() == 4, "davetiye hedefleri: %s" % str(goals))
	for id in goals:
		main._interact(id)
		await _press_until_closed()
	assert(main.task.is_empty() and main._story_who() == "firin")
	# 10. açılış
	var k0: int = gs.kurabiye
	main._interact("firin")
	await _press(0)
	await _press(0)  # Açılışı yap
	assert(main.world._firin.get_node("Acik").visible and main.world._firinci.visible, "fırın açıldı")
	assert(main.dialog_text.text.begins_with("Mahalle beni özlemiş"), "seçim açılışta hatırlanmalı")
	await _press_until_closed()
	assert(gs.chapter_done("firin") and gs.album.has("firin"))
	assert(gs.kurabiye == k0 + 30)
	assert(main._story_who() == "filiz", "1. bölüm bitince 2. bölüm başlar")
	# her sabah simit: bir komşuya götür, kalp kazan
	main._interact("firin")
	await _press(0)  # Simidi al
	assert(main.task.get("simit", false) and not gs.simit_ready())
	var h0: int = gs.hearts("ahmet")
	main._interact("ahmet")
	assert(gs.hearts("ahmet") > h0 and gs.album.has("simit") and main.task.is_empty())
	await _press_until_closed()
	main._interact("firin")
	assert(main.dialog.visible)
	main._close_dialog()
	assert(not main.task.get("simit", false), "günde bir simit")
	# kayıttan geri yüklenince fırın açık kalır
	gs.save_game()
	gs.load_game()
	main._refresh()
	assert(gs.chapter_done("firin") and main.world._firin.get_node("Acik").visible)
	print("1. bölüm tamam")
	# --- 2. bölüm: Mahallede Düğün ---
	assert(main._story_who() == "filiz" and main._story_goal().begins_with("Bölüm 2"))
	assert(not main.world._dugun.visible, "düğün meydanı başta yok")
	main._interact("filiz")
	await _press_until_closed()
	assert(main._story_who() == "fatma")
	main._interact("fatma")
	await _press_until_closed()
	assert(main._story_who() == "miyase")
	main._interact("miyase")
	await _press(0)
	await _press(0)  # Örelim
	assert(main.game != null)
	main.game.finished.emit(true)
	await _press_until_closed()  # tepsiyi al
	assert(main._task_goals() == ["filiz"])
	main._interact("filiz")
	await _press(0)
	var yer: Array = main._yuzuk_yer()
	assert(main.dialog_text.text.contains(yer[0]), "Filiz yüzüğün yerini söylemeli")
	await _press(0)  # Ararım
	assert(main._task_goals() == ["bul"] and main.world.targets.has("bul"))
	assert(not ("bul" in main.world._goals), "aranan şeyin üstünde ok olmaz")
	assert(main.task_label.text.contains(yer[0]))
	assert(main.world._ring.position.distance_to(yer[1]) < 0.01)
	main._interact("bul")
	assert(main.dialog.visible and gs.album.has("yuzuk"))
	await _press_until_closed()
	assert(not main.world.targets.has("bul") and main._task_goals() == ["filiz"])
	main._interact("filiz")
	await _press_until_closed()
	assert(main._story_who() == "ahmet", "sırada davul: %s" % main._story_who())
	main._interact("ahmet")
	await _press(0)
	await _press(0)  # tavla
	main.game.finished.emit(false)  # yenilirse hikaye ilerlemez
	await _press_until_closed()
	assert(main._story_who() == "ahmet")
	main._interact("ahmet")
	await _press(0)
	await _press(0)
	main.game.finished.emit(true)
	await _press_until_closed()
	assert(main._story_who() == "fatma")
	gs.kurabiye = 40
	main._interact("fatma")
	await _press(0)  # 30 kurabiye ver
	await _press_until_closed()
	assert(gs.kurabiye == 10 and main._story_who() == "firin")
	main._interact("firin")
	await _press_until_closed()  # pastayı al
	assert(main._task_goals() == ["filiz"])
	main._interact("filiz")
	await _press_until_closed()  # Düğüne!
	assert(main.world._dugun.visible and main.world._dugun.get_node("Gelin").visible, "meydan kuruldu")
	assert(main._story_who() == "dugun")
	var k1: int = gs.kurabiye
	main._interact("dugun")
	await _press_until_closed()
	assert(gs.chapter_done("dugun") and gs.album.has("dugun") and gs.kurabiye == k1 + 40)
	assert(main._story_goal() == "" and main._story_who() == "")
	gs.save_game()
	gs.load_game()
	main._refresh()
	assert(main.world._dugun.visible and main.world._dugun.get_node("Gelin").visible, "düğün günü gelin damat orada")
	gs.story_flags["dugun_gunu"] = "2000-01-01"
	main._refresh()
	assert(main.world._dugun.visible and not main.world._dugun.get_node("Gelin").visible, "ertesi gün ışıklar kalır")
	assert(load("res://scripts/hikaye.gd").after_lines("ahmet").size() == 4)
	print("TAMAM: 1. bölüm (Fırının Işığı) ve 2. bölüm (Mahallede Düğün) baştan sona oynandı")
	quit(0)


## Konuşma kutusundaki n. düğmeye basar.
func _press(n: int) -> void:
	await process_frame
	assert(main.dialog.visible, "konuşma kutusu açık olmalı")
	main.dialog_buttons.get_child(n).pressed.emit()
	await process_frame


## Kutu kapanana kadar ilk düğmeye basar.
func _press_until_closed() -> void:
	for i in 12:
		await process_frame
		if not main.dialog.visible:
			return
		main.dialog_buttons.get_child(0).pressed.emit()
	assert(false, "konuşma bitmedi")
