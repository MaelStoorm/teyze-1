extends Control
## Mahalle ekranı: teyzeye dokun, görevi al, mini oyunu oyna, kurabiyeni kap.

const MINIGAMES := {
	"pazar": preload("res://scripts/minigames/pazar.gd"),
	"haber": preload("res://scripts/minigames/haber.gd"),
	"kedi": preload("res://scripts/minigames/kedi.gd"),
}
const PX := UI.PX

var world: Control
var teyze: TextureButton
var player: TextureRect
var bubble: Label
var hud_cookies: Label
var hud_day: Label
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
	_build_dialog()
	GameState.changed.connect(_refresh)
	_refresh()
	if GameState.done_count == 0 and GameState.day == 1:
		_say("Hoş geldin evladım! Bana bir dokun bakayım, işlerim var.", [["Tamam teyzecim", _close_dialog]])
	var shots := _arg("--shots")
	if shots != "":
		_screenshot_tour(shots)


# --- mahalle ---------------------------------------------------------------

func _build_world() -> void:
	world = Control.new()
	world.scale = Vector2(PX, PX)
	world.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(world)

	var grass := _tile("grass", Rect2(0, 0, 96, 220))
	grass.mouse_filter = MOUSE_FILTER_IGNORE
	_tile("path", Rect2(0, 46, 96, 10))
	_tile("path", Rect2(40, 56, 10, 164))

	_prop("house", Vector2(4, 20))
	_prop("neighbor_house", Vector2(56, 24))
	_prop("pot", Vector2(36, 34))
	_prop("tree", Vector2(66, 60))
	_prop("tree", Vector2(2, 70))
	_prop("bush", Vector2(20, 64))
	_prop("stall", Vector2(56, 98))
	_prop("crate", Vector2(4, 104))
	_prop("bush", Vector2(70, 128))
	_prop("pot", Vector2(26, 120))

	teyze = TextureButton.new()
	teyze.texture_normal = UI.tex("teyze")
	teyze.position = Vector2(14, 38)
	teyze.pressed.connect(_on_teyze)
	world.add_child(teyze)
	var tw := teyze.create_tween().set_loops()
	tw.tween_property(teyze, "position:y", 37.0, 0.6).set_trans(Tween.TRANS_SINE)
	tw.tween_property(teyze, "position:y", 38.0, 0.6).set_trans(Tween.TRANS_SINE)

	player = UI.sprite("player", 1)
	player.position = Vector2(37, 80)
	world.add_child(player)

	# Teyzenin başındaki ünlem balonu (UI ölçeğinde)
	bubble = UI.label("!", 34, UI.ACCENT)
	bubble.add_theme_color_override("font_outline_color", Color.WHITE)
	bubble.add_theme_constant_override("outline_size", 10)
	bubble.position = Vector2(14 * PX + 22, 38 * PX - 52)
	add_child(bubble)
	var bt := bubble.create_tween().set_loops()
	bt.tween_property(bubble, "position:y", bubble.position.y - 8, 0.4)
	bt.tween_property(bubble, "position:y", bubble.position.y, 0.4)


func _tile(name: String, rect: Rect2) -> TextureRect:
	var r := TextureRect.new()
	r.texture = UI.tex(name)
	r.stretch_mode = TextureRect.STRETCH_TILE
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.position = rect.position
	r.size = rect.size
	r.mouse_filter = MOUSE_FILTER_IGNORE
	world.add_child(r)
	return r


func _prop(name: String, pos: Vector2) -> void:
	var s := UI.sprite(name, 1)
	s.position = pos
	world.add_child(s)


# --- üst bilgi -----------------------------------------------------------------

func _build_hud() -> void:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UI.box(UI.CREAM, UI.INK, 3, 6))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	h.add_child(UI.sprite("kurabiye", 2))
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
	hud_day = UI.label("Gün 1", 22)
	h.add_child(hud_day)
	p.add_child(h)
	overlay.add_child(p)


func _refresh() -> void:
	hud_cookies.text = str(GameState.kurabiye)
	hud_day.text = "Gün %d" % GameState.day
	for c in hud_hearts.get_children():
		c.queue_free()
	for i in GameState.errands.size():
		var heart := UI.sprite("heart", 2)
		if i >= GameState.done_count:
			heart.modulate = Color(0, 0, 0, 0.25)
		hud_hearts.add_child(heart)
	bubble.visible = not GameState.is_day_over() and game == null


# --- teyze konuşma kutusu -------------------------------------------------------

func _build_dialog() -> void:
	dialog = PanelContainer.new()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	var face := UI.sprite("teyze", 5)
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


func _close_dialog() -> void:
	dialog.visible = false


# --- akış ----------------------------------------------------------------------

func _on_teyze() -> void:
	if busy or game != null:
		return
	busy = true
	var tw := create_tween()
	tw.tween_property(player, "position", Vector2(30, 46), 0.5)
	await tw.finished
	busy = false
	if GameState.is_day_over():
		_say("Bugünlük bu kadar evladım. Yarın yine gel, sana kurabiye ayırdım.",
			[["Yeni gün (deneme)", _new_day]])
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


func _quit_game() -> void:
	game.queue_free()
	game = null
	_refresh()


func _on_game_finished(_success: bool, info: Dictionary) -> void:
	game.queue_free()
	game = null
	GameState.complete_errand()
	var next := "Al bakalım, %d kurabiye senin!" % GameState.REWARD
	_say("%s %s" % [info["thanks"], next], [["Afiyet olsun bana", _close_dialog]])


func _new_day() -> void:
	GameState.new_day()
	player.position = Vector2(37, 80)
	_say("Günaydın evladım! Yeni günde yeni işler var.", [["Günaydın teyzecim", _close_dialog]])


# --- ekran görüntüsü turu (geliştirme için) -------------------------------------

func _arg(key: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with(key + "="):
			return a.substr(key.length() + 1)
	return ""


func _screenshot_tour(dir: String) -> void:
	GameState.reset()
	await _shot(dir, "1_mahalle")
	_on_teyze()
	await get_tree().create_timer(0.8).timeout
	await _shot(dir, "2_gorev")
	for type in ["pazar", "haber", "kedi"]:
		var info := Errands.build({"type": type, "seed": 7})
		_start_game(type, info)
		await _shot(dir, "3_" + type)
		if type == "haber":
			game.call("_show_tell")
			await _shot(dir, "3_haber_2")
		_quit_game()
	get_tree().quit()


func _shot(dir: String, name: String) -> void:
	await get_tree().create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [dir, name])
