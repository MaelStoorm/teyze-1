extends Control
## Mahalle ekranı: teyzeye dokun, görevi al, mini oyunu oyna, kurabiyeni kap.

const MINIGAMES := {
	"pazar": preload("res://scripts/minigames/pazar.gd"),
	"haber": preload("res://scripts/minigames/haber.gd"),
	"kedi": preload("res://scripts/minigames/kedi.gd"),
	"yemek": preload("res://scripts/minigames/yemek.gd"),
	"altin": preload("res://scripts/minigames/altin.gd"),
}
const SHOP := preload("res://scripts/minigames/shop.gd")
const TYPE_NAMES := {"pazar": "Pazar", "haber": "Komşuya Haber", "kedi": "Kayıp Kedi", "yemek": "Yemek", "altin": "Altın Günü"}

var world: Mahalle3D
var hud_cookies: Label
var hud_day: Label
var hud_level: Label
var hud_xp: ProgressBar
var shop_button: Button
var level_note := ""
var hud_hearts: HBoxContainer
var dialog: PanelContainer
var dialog_text: Label
var dialog_buttons: HBoxContainer
var game: Minigame
var busy := false
var overlay: VBoxContainer


func _ready() -> void:
	theme = UI.make_theme()
	_build_world()
	overlay = UI.page(self, 10)
	_build_hud()
	overlay.add_child(UI.spacer())
	shop_button = UI.button("Dükkan", _open_shop, 20)
	shop_button.icon = UI.tex("file")
	shop_button.add_theme_constant_override("icon_max_width", 34)
	shop_button.custom_minimum_size = Vector2(150, 56)
	shop_button.size_flags_horizontal = SIZE_SHRINK_END
	overlay.add_child(shop_button)
	_build_dialog()
	GameState.changed.connect(_refresh)
	GameState.leveled_up.connect(_on_level_up)
	Sfx.set_music(true)
	_refresh()
	if not _show_daily_gift() and GameState.done_count == 0 and GameState.day == 1:
		_say("Hoş geldin evladım! Bana bir dokun bakayım, işlerim var.", [["Tamam teyzecim", _close_dialog]])
	var shots := _arg("--shots")
	if shots != "":
		_screenshot_tour(shots)


# --- mahalle ---------------------------------------------------------------

func _build_world() -> void:
	world = Mahalle3D.new()
	world.teyze_tapped.connect(_on_teyze)
	add_child(world)


# --- üst bilgi -----------------------------------------------------------------

func _build_hud() -> void:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UI.box(UI.CREAM, UI.INK, 3, 6))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	h.add_child(UI.sprite("kurabiye", 34))
	hud_cookies = UI.label("0", 24)
	h.add_child(hud_cookies)
	var spacer := Control.new()
	spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	h.add_child(spacer)
	hud_hearts = HBoxContainer.new()
	h.add_child(hud_hearts)
	var spacer2 := Control.new()
	spacer2.size_flags_horizontal = SIZE_EXPAND_FILL
	h.add_child(spacer2)
	h.add_child(UI.sprite("yildiz", 30))
	hud_level = UI.label("Sv 1", 22)
	h.add_child(hud_level)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	v.add_child(h)
	var h2 := HBoxContainer.new()
	hud_xp = ProgressBar.new()
	hud_xp.max_value = 1.0
	hud_xp.show_percentage = false
	hud_xp.custom_minimum_size = Vector2(0, 12)
	hud_xp.size_flags_horizontal = SIZE_EXPAND_FILL
	hud_xp.size_flags_vertical = SIZE_SHRINK_CENTER
	hud_xp.add_theme_stylebox_override("background", UI.box(UI.CREAM_DARK, UI.INK, 2, 0))
	hud_xp.add_theme_stylebox_override("fill", UI.box(Color("f2c23a"), UI.INK, 2, 0))
	h2.add_child(hud_xp)
	hud_day = UI.label("Gün 1", 16)
	h2.add_child(hud_day)
	v.add_child(h2)
	p.add_child(v)
	overlay.add_child(p)


func _refresh() -> void:
	hud_cookies.text = str(GameState.kurabiye)
	hud_day.text = "  Gün %d" % GameState.day
	hud_level.text = "Sv %d" % GameState.level()
	hud_xp.value = GameState.level_progress()
	for c in hud_hearts.get_children():
		c.queue_free()
	for i in GameState.errands.size():
		var heart := UI.sprite("heart", 28)
		if i >= GameState.done_count:
			heart.modulate = Color(0, 0, 0, 0.25)
		hud_hearts.add_child(heart)
	world.bubble.visible = not GameState.is_day_over() and game == null
	world.visible = game == null
	shop_button.visible = game == null and not dialog.visible


# --- teyze konuşma kutusu -------------------------------------------------------

func _build_dialog() -> void:
	dialog = PanelContainer.new()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	var face := Portrait.new(Vector2(92, 104))
	face.size_flags_vertical = SIZE_SHRINK_BEGIN
	top.add_child(face)
	var tv := VBoxContainer.new()
	tv.size_flags_horizontal = SIZE_EXPAND_FILL
	var name_label := UI.label(Errands.TEYZE, 20, UI.ACCENT)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	tv.add_child(name_label)
	dialog_text = UI.label("", 22, UI.INK, true)
	dialog_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	tv.add_child(dialog_text)
	top.add_child(tv)
	v.add_child(top)
	dialog_buttons = HBoxContainer.new()
	dialog_buttons.add_theme_constant_override("separation", 10)
	v.add_child(dialog_buttons)
	dialog.add_child(v)
	dialog.visible = false
	overlay.add_child(dialog)


## buttons: [[metin, Callable], ...]
func _say(text: String, buttons: Array) -> void:
	dialog_text.text = text
	for c in dialog_buttons.get_children():
		c.queue_free()
	for pair in buttons:
		var b := UI.button(pair[0], pair[1])
		b.size_flags_horizontal = SIZE_EXPAND_FILL
		dialog_buttons.add_child(b)
	dialog.visible = true
	shop_button.visible = false


func _close_dialog() -> void:
	dialog.visible = false
	_refresh()


# --- akış ----------------------------------------------------------------------

func _on_teyze() -> void:
	if busy or game != null:
		return
	busy = true
	Sfx.play("tap")
	await world.walk_to_teyze()
	busy = false
	if GameState.is_day_over():
		_say("Bugünlük bu kadar evladım. Yarın yine gel, sana kurabiye ayırdım.",
			[["Yarın görüşürüz teyzecim", _close_dialog]])
		return
	var errand := GameState.current_errand()
	var info := Errands.build(errand)
	_say(info["intro"], [["Hemen teyzecim", _start_game.bind(errand["type"], info)], ["Sonra", _close_dialog]])


func _start_game(type: String, info: Dictionary) -> void:
	_close_dialog()
	game = MINIGAMES[type].new().setup(info)
	game.finished.connect(_on_game_finished.bind(info))
	add_child(game)
	if type == "kedi":
		game.content.add_child(UI.spacer())
	var back := UI.button("Teyzeye dön", _quit_game, 18)
	back.custom_minimum_size = Vector2(160, 44)
	back.size_flags_horizontal = SIZE_SHRINK_BEGIN
	game.content.add_child(back)
	_refresh()


func _open_shop() -> void:
	if game != null or busy:
		return
	_close_dialog()
	game = SHOP.new().setup({})
	add_child(game)
	var back := UI.button("Mahalleye dön", _quit_game, 18)
	back.custom_minimum_size = Vector2(180, 48)
	back.size_flags_horizontal = SIZE_SHRINK_BEGIN
	game.content.add_child(back)
	_refresh()


func _quit_game() -> void:
	game.queue_free()
	game = null
	_refresh()


func _on_game_finished(_success: bool, info: Dictionary) -> void:
	var type := GameState.current_errand().get("type", "") as String
	game.queue_free()
	game = null
	level_note = ""
	var reward := GameState.complete_errand(type, info.get("bonus", 0))
	var text := "%s Al bakalım, %d kurabiye senin!" % [info["thanks"], reward]
	_say(text + level_note, [["Afiyet olsun bana", _close_dialog]])


func _on_level_up(lv: int) -> void:
	Sfx.play("levelup")
	level_note = "\n\nSeviye atladın, artık Sv %d!" % lv
	for t in GameState.UNLOCKS:
		if GameState.UNLOCKS[t] == lv:
			level_note += " Yeni görev açıldı: %s." % TYPE_NAMES[t]
	if lv == 4:
		level_note += " Artık günde bir görev fazla var."


## Uygulamaya geri dönülünce gün değiştiyse yeni günü başlatır.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_RESUMED or what == NOTIFICATION_APPLICATION_FOCUS_IN:
		if is_node_ready() and game == null and GameState.check_new_day():
			world.reset_player()
			_show_daily_gift()


func _show_daily_gift() -> bool:
	if GameState.daily_gift <= 0:
		return false
	var gift := GameState.daily_gift
	GameState.daily_gift = 0
	var text := "Günaydın evladım! Bugün de geldin, al sana %d kurabiye." % gift
	if GameState.streak > 1:
		text += " %d gündür hiç aksatmadın, maşallah!" % GameState.streak
	text += " Yeni günde yeni işler var."
	Sfx.play("coin")
	_say(text, [["Günaydın teyzecim", _close_dialog]])
	return true


# --- ekran görüntüsü turu (geliştirme için) -------------------------------------

func _arg(key: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with(key + "="):
			return a.substr(key.length() + 1)
	return ""


func _screenshot_tour(dir: String) -> void:
	GameState.reset()
	GameState.xp = 125
	GameState.kurabiye = 47
	GameState.new_day(false)
	_close_dialog()
	await _shot(dir, "0_mahalle")
	_on_teyze()
	await get_tree().create_timer(0.8).timeout
	await _shot(dir, "2_gorev")
	for type in ["pazar", "haber", "kedi", "yemek", "altin"]:
		var info := Errands.build({"type": type, "seed": 7, "level": 5})
		_start_game(type, info)
		await _shot(dir, "3_" + type)
		if type == "haber":
			game.call("_show_tell")
			await _shot(dir, "3_haber_2")
		if type == "yemek":
			for k in info["items"]:
				game.call("_add", k, Button.new())
			await _shot(dir, "3_yemek_2")
		if type == "altin":
			game.call("_visit", 1)
			game.call("_offer", "cay", Button.new())
			await _shot(dir, "3_altin_2")
		_quit_game()
	_open_shop()
	await _shot(dir, "4_dukkan")
	_quit_game()
	get_tree().quit()


func _shot(dir: String, name: String) -> void:
	await get_tree().create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [dir, name])
