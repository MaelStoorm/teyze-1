extends SceneTree
## Hikayenin 1. bölümünü baştan sona oynar: godot --headless -s tools/test_hikaye.gd

var main
var gs


func _initialize() -> void:
	create_timer(90).timeout.connect(func(): print("ZAMAN AŞIMI"); quit(1))
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
	assert(main._story_who() == "" and main._story_goal() == "")
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
	print("TAMAM: 1. bölüm (Fırının Işığı) baştan sona oynandı")
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
