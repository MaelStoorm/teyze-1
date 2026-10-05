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
const SETTINGS := preload("res://scripts/minigames/settings.gd")
const KOMSULAR := preload("res://scripts/minigames/komsular.gd")
const KARAKTER := preload("res://scripts/minigames/karakter.gd")
const TYPE_NAMES := {"pazar": "Pazar", "haber": "Komşuya Haber", "kedi": "Kayıp Kedi", "yemek": "Yemek", "altin": "Altın Günü"}

var world: Mahalle3D
var hud_cookies: Label
var hud_day: Label
var hud_level: Label
var hud_xp: ProgressBar
var shop_button: Button
var settings_button: Button
var joystick: Joystick
var bottom_bar: HBoxContainer
var hud_panel: PanelContainer
var tutorial_step := -1
var hint_panel: PanelContainer
var drop_button: Button
var album_button: Button
var _toasts: Array[String] = []
var _toast_busy := false
var _world_check := 0.0
var _story_game := false
var hint_label: Label
var level_note := ""
var hud_hearts: HBoxContainer
var dialog: PanelContainer
var dialog_text: Label
var dialog_scroll: ScrollContainer
var dialog_name: Label
var dialog_face: Portrait
var dialog_who := ""
var friends_button: Button
var home_button: Button
var dialog_buttons: GridContainer
var game: Minigame
var busy := false
var overlay: VBoxContainer
## Dünyada yürüyerek yapılan iş (pazar, çay, gözlük). Boşsa iş yok.
## kind, giver, info, want/got, pickup/carrying/targets/served, found
var task := {}
var task_panel: PanelContainer
var task_label: Label
var top_row: HBoxContainer


func _ready() -> void:
	UI.text_scale = GameState.settings["text"]
	if _arg("--text") != "":  # ekran görüntüsü turu büyük yazıyla da denenir
		UI.text_scale = float(_arg("--text"))
	theme = UI.make_theme()
	_build_world()
	overlay = UI.page(self, 10)
	top_row = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 10)
	top_row.mouse_filter = MOUSE_FILTER_IGNORE
	overlay.add_child(top_row)
	_build_hud()
	_build_task_panel()
	overlay.add_child(UI.spacer())
	bottom_bar = HBoxContainer.new()
	bottom_bar.mouse_filter = MOUSE_FILTER_IGNORE
	var gap := Control.new()
	gap.size_flags_horizontal = SIZE_EXPAND_FILL
	gap.mouse_filter = MOUSE_FILTER_IGNORE
	bottom_bar.add_child(gap)
	album_button = UI.button("", _open_album, 20)
	album_button.icon = UI.tex("album")
	album_button.add_theme_constant_override("icon_max_width", 34)
	album_button.custom_minimum_size = Vector2(60, 56)
	album_button.size_flags_vertical = SIZE_SHRINK_END
	bottom_bar.add_child(album_button)
	var gap4 := Control.new()
	gap4.custom_minimum_size.x = 10
	gap4.mouse_filter = MOUSE_FILTER_IGNORE
	bottom_bar.add_child(gap4)
	settings_button = UI.button("", _open_settings, 20)
	settings_button.icon = UI.tex("ayar")
	settings_button.add_theme_constant_override("icon_max_width", 34)
	settings_button.custom_minimum_size = Vector2(60, 56)
	settings_button.size_flags_vertical = SIZE_SHRINK_END
	bottom_bar.add_child(settings_button)
	var gap1 := Control.new()
	gap1.custom_minimum_size.x = 10
	gap1.mouse_filter = MOUSE_FILTER_IGNORE
	bottom_bar.add_child(gap1)
	friends_button = UI.button("", _open_friends, 20)
	friends_button.icon = UI.tex("heart")
	friends_button.add_theme_constant_override("icon_max_width", 34)
	friends_button.custom_minimum_size = Vector2(60, 56)
	friends_button.size_flags_vertical = SIZE_SHRINK_END
	bottom_bar.add_child(friends_button)
	var gap3 := Control.new()
	gap3.custom_minimum_size.x = 10
	gap3.mouse_filter = MOUSE_FILTER_IGNORE
	bottom_bar.add_child(gap3)
	home_button = UI.button("", _open_home, 20)
	home_button.icon = UI.tex("ev")
	home_button.add_theme_constant_override("icon_max_width", 34)
	home_button.custom_minimum_size = Vector2(60, 56)
	home_button.size_flags_vertical = SIZE_SHRINK_END
	bottom_bar.add_child(home_button)
	var gap2 := Control.new()
	gap2.custom_minimum_size.x = 10
	gap2.mouse_filter = MOUSE_FILTER_IGNORE
	bottom_bar.add_child(gap2)
	shop_button = UI.button("Dükkan", _open_shop, 20)
	shop_button.icon = UI.tex("file")
	shop_button.add_theme_constant_override("icon_max_width", 34)
	shop_button.custom_minimum_size = Vector2(150, 56)
	shop_button.size_flags_vertical = SIZE_SHRINK_END
	bottom_bar.add_child(shop_button)
	overlay.add_child(bottom_bar)
	# yürüme kolu alt çubuğun dışında, sol altta: çubuk ince kalsın
	joystick = Joystick.new()
	joystick.anchor_top = 1.0
	joystick.anchor_bottom = 1.0
	joystick.offset_left = 12
	joystick.offset_right = 136
	joystick.offset_top = -136
	joystick.offset_bottom = -12
	add_child(joystick)
	world.joystick = joystick
	_build_hint()
	_build_dialog()
	GameState.changed.connect(_refresh)
	GameState.remembered.connect(func(id): _toasts.append(id); _next_toast())
	GameState.leveled_up.connect(_on_level_up)
	Sfx.set_music(GameState.settings["music"])
	_refresh()
	var shots := _arg("--shots")
	if shots != "":
		_screenshot_tour(shots)
		return
	var splash := Splash.new()
	add_child(splash)
	splash.done.connect(_after_splash)


func _after_splash() -> void:
	if GameState.avatar.is_empty():
		_open_avatar(true)
	elif not GameState.settings["tutorial"]:
		_tutorial(0)
	else:
		_show_daily_gift()


## Karakter oluşturma ekranı. first: ilk açılışta, bitince rehber başlar.
func _open_avatar(first := false) -> void:
	if game != null:
		_quit_game()
	_close_dialog()
	game = KARAKTER.new().setup({})
	game.finished.connect(func(_ok):
		_quit_game()
		world.set_player_look(GameState.avatar)
		if first and not GameState.settings["tutorial"]:
			_tutorial(0))
	add_child(game)
	_refresh()


# --- mahalle ---------------------------------------------------------------

func _build_world() -> void:
	world = Mahalle3D.new()
	world.tapped.connect(_on_tapped)
	add_child(world)


# --- üst bilgi -----------------------------------------------------------------

func _build_hud() -> void:
	var p := PanelContainer.new()
	hud_panel = p
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
	p.custom_minimum_size.x = 300
	p.size_flags_vertical = SIZE_SHRINK_BEGIN
	top_row.add_child(p)


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
	world.refresh_decor()
	world.refresh_neighbors()
	world.refresh_bostan()
	world.set_firin_open(GameState.chapter_done("firin"))
	world.set_bowl_full(GameState.sutlu_fed_today())
	world.sutlu_follow = GameState.sutlu_fed_today()
	friends_button.visible = not GameState.neighbors_unlocked().is_empty()
	world.visible = game == null
	var free := game == null and not dialog.visible
	bottom_bar.visible = free and not _tut_moving()
	joystick.visible = free and (tutorial_step < 0 or _tut_moving())
	hint_panel.visible = free and _tut_moving()
	if hint_panel.visible:
		hint_label.text = _tut_hint()
	top_row.visible = free and _tut_kind() != "walk"  # yürürken teyze göstergenin altında kalmasın
	_refresh_task()


## İşin üstteki kartını ve dünyadaki işaretleri (ünlem, altın ok) günceller.
func _refresh_task() -> void:
	var bubbles := []
	var goals := []
	if task.is_empty():
		if not GameState.is_day_over():
			bubbles.append("fatma")
		for n in GameState.neighbors_unlocked():
			if GameState.favor_available(n["id"]):
				bubbles.append(n["id"])
		if not GameState.sutlu_fed_today():
			goals.append("sutlu")
	else:
		goals = _task_goals()
	var story_who := _story_who() if task.is_empty() else ""
	if story_who == "fatma":
		bubbles.erase("fatma")  # hikaye işareti yeter
	if _tut_kind() == "walk":
		bubbles = ["fatma"]
		goals = ["fatma"]
		story_who = ""
	world.set_marks(bubbles, goals if game == null else [])
	world.set_story_mark(story_who if game == null else "")
	var goal := _story_goal() if task.is_empty() and tutorial_step < 0 else ""
	task_panel.visible = (not task.is_empty() or goal != "") and game == null
	if task.is_empty():
		task_label.text = goal
		drop_button.visible = false
		return
	task_label.text = _task_text()
	# rehberin ve hikayenin işi bırakılmaz
	drop_button.visible = not task["info"].get("tutorial", false) and task["kind"] != "story"


func _task_done() -> bool:
	match task["kind"]:
		"shop":
			for k in task["want"]:
				if task["got"].get(k, 0) < task["want"][k]:
					return false
			return true
		"deliver":
			return task["served"].size() >= task["targets"].size()
		"find":
			return task["found"]
	return false  # "story": her teslimde kendisi biter


func _task_goals() -> Array:
	if _task_done():
		return [task["giver"]]
	match task["kind"]:
		"shop":
			var g := []
			for kind in Props.STALLS:
				for item in Props.STALLS[kind]["items"]:
					if task["want"].has(item) and task["got"].get(item, 0) < task["want"][item] and not g.has("stall_" + kind):
						g.append("stall_" + kind)
			return g
		"deliver":
			if not task["carrying"]:
				return [task["pickup"]]
			return task["targets"].filter(func(t): return t not in task["served"])
		"find":
			return ["gozluk"]
		"story":
			return task["targets"].filter(func(t): return t not in task["served"])
	return []


func _task_text() -> String:
	var who := Neighbors.name_of(task["giver"])
	if _task_done():
		return "Tamam! %s'ye dön." % who
	match task["kind"]:
		"shop":
			var parts := []
			for k in task["want"]:
				parts.append("%s %d/%d" % [Errands.MARKET[k], task["got"].get(k, 0), task["want"][k]])
			return "Pazar listesi: " + ", ".join(parts)
		"deliver":
			if not task["carrying"]:
				return "Kahvehaneye git, Ahmet Amca'dan çayı al."
			var left: Array = task["targets"].filter(func(t): return t not in task["served"])
			return "Çay götür: " + ", ".join(left.map(func(t): return Neighbors.name_of(t)))
		"find":
			return "%s'nin gözlüğünü mahallede ara." % who
		"story":
			var left: Array = task["targets"].filter(func(t): return t not in task["served"])
			return "%s götür: %s" % [task["what"], ", ".join(left.map(func(t): return _who_name(t)))]
	return ""


func _build_task_panel() -> void:
	task_panel = PanelContainer.new()
	task_panel.add_theme_stylebox_override("panel", UI.box(Color("fff4c8"), UI.INK, 3, 8))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	h.add_child(UI.sprite("defter", 30))
	task_label = UI.label("", 17, UI.INK, true)
	task_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	task_label.size_flags_horizontal = SIZE_EXPAND_FILL
	h.add_child(task_label)
	var x := UI.button("Bırak", _ask_drop_task, 15)
	drop_button = x
	x.custom_minimum_size = Vector2(56, 36)
	x.size_flags_vertical = SIZE_SHRINK_CENTER
	h.add_child(x)
	task_panel.add_child(h)
	task_panel.visible = false
	task_panel.size_flags_horizontal = SIZE_EXPAND_FILL
	task_panel.size_flags_vertical = SIZE_SHRINK_BEGIN
	top_row.add_child(task_panel)


func _ask_drop_task() -> void:
	if busy:
		return
	_say("Bu işi şimdilik bırakalım mı? Sonra yine gelip alabilirsin.",
		[["Bırak", func(): _drop_task(); _close_dialog()], ["Devam", _close_dialog]], task["giver"])


func _drop_task() -> void:
	if task.get("kind", "") == "find":
		world.remove_glasses()
	task = {}
	world.set_carry("")
	_refresh()


# --- teyze konuşma kutusu -------------------------------------------------------

func _build_dialog() -> void:
	dialog = PanelContainer.new()
	dialog.gui_input.connect(func(e: InputEvent):
		# yazı akarken kutuya dokunmak hepsini bir anda gösterir
		if e is InputEventMouseButton and e.pressed and _type_tw and _type_tw.is_running():
			_type_tw.kill()
			dialog_text.visible_characters = -1)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	var face := Portrait.new(Vector2(92, 104))
	face.size_flags_vertical = SIZE_SHRINK_BEGIN
	dialog_face = face
	top.add_child(face)
	var tv := VBoxContainer.new()
	tv.size_flags_horizontal = SIZE_EXPAND_FILL
	var name_label := UI.label(Errands.TEYZE, 20, UI.ACCENT)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	dialog_name = name_label
	tv.add_child(name_label)
	# uzun yazılar (büyük yazı boyutunda) ekrandan taşmasın, kaysın
	dialog_scroll = ScrollContainer.new()
	dialog_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tv.add_child(dialog_scroll)
	dialog_text = UI.label("", 20, UI.INK, true)
	dialog_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	dialog_text.size_flags_horizontal = SIZE_EXPAND_FILL
	dialog_scroll.add_child(dialog_text)
	top.add_child(tv)
	dialog_buttons = GridContainer.new()
	dialog_buttons.add_theme_constant_override("h_separation", 8)
	dialog_buttons.add_theme_constant_override("v_separation", 8)
	dialog_buttons.custom_minimum_size.x = 190
	dialog_buttons.size_flags_vertical = SIZE_SHRINK_CENTER
	top.add_child(dialog_buttons)
	dialog.add_child(top)
	dialog.visible = false
	overlay.add_child(dialog)


## Konuşanların ses perdesi (mırıltı). Listede olmayan (Sütlü) mırıldanmaz.
const VOICE := {"fatma": 1.0, "filiz": 1.12, "miyase": 1.24, "hulya": 0.92, "ahmet": 0.6, "nermin": 1.05,
	"stall_manav": 0.72, "stall_firin": 0.8, "stall_sarkuteri": 0.95}
const VOWEL_SOUND := {"a": "ses_a", "ı": "ses_i", "e": "ses_e", "i": "ses_i", "o": "ses_o", "ö": "ses_o", "u": "ses_u", "ü": "ses_u"}
var _type_tw: Tween
var _voiced := 0


## Yazıyı harf harf açar; ünlülerde konuşanın sesiyle kısa bir hece çıkar.
func _type_dialog(who: String) -> void:
	if _type_tw:
		_type_tw.kill()
	var text := dialog_text.text
	# satırlar baştan bütün metne göre kurulsun; yoksa kutu tek satır sanılır
	dialog_text.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	dialog_text.visible_characters = 0
	_voiced = 0
	var pitch: float = VOICE.get(who, 0.0)
	var dur := clampf(text.length() / 42.0, 0.25, 3.5)
	_type_tw = create_tween()
	_type_tw.tween_method(func(n: int):
		dialog_text.visible_characters = n
		if pitch > 0.0 and n - _voiced >= 3 and n <= text.length():
			# son birkaç harfteki ünlünün hecesini çal
			for k in range(n - 1, maxi(n - 4, 0) - 1, -1):
				var ch := text[k].to_lower()
				if VOWEL_SOUND.has(ch):
					Sfx.play(VOWEL_SOUND[ch], -10.0, pitch * randf_range(0.94, 1.08))
					_voiced = n
					break,
		0, text.length(), dur)
	_type_tw.tween_callback(func(): dialog_text.visible_characters = -1)


## Konuşma kutusunu yazıya göre boylandırır; ekrana sığmazsa kaydırılır.
func _fit_dialog() -> void:
	dialog_scroll.scroll_vertical = 0
	await get_tree().process_frame
	if not is_instance_valid(dialog_text):
		return
	var lines := dialog_text.get_line_count()
	var need := lines * (dialog_text.get_line_height() + dialog_text.get_theme_constant("line_spacing")) + 4
	var room := size.y - 20 - dialog_name.size.y - 30
	if top_row.visible:  # rehberde üst gösterge de açık kalır
		room -= top_row.size.y + 10
	dialog_scroll.custom_minimum_size.y = minf(need, room)


## buttons: [[metin, Callable], ...]. who: konuşanın id'si ("fatma", komşu,
## "stall_manav", "sutlu"); boşsa Fatma Teyze.
func _say(text: String, buttons: Array, who := "") -> void:
	if who == "":
		who = "fatma"
	if who != dialog_who:
		dialog_who = who
		if who == "fatma":
			dialog_name.text = Errands.TEYZE
			dialog_face.set_look({})
		elif who.begins_with("stall_"):
			var st: Dictionary = Props.STALLS[who.substr(6)]
			dialog_name.text = st["seller"]
			dialog_face.set_look(st["look"])
		elif who == "sutlu":
			dialog_name.text = "Sütlü"
			dialog_face.set_look({"animal": "cat"})
		else:
			var n := Neighbors.get_neighbor(who)
			dialog_name.text = n["name"]
			dialog_face.set_look(n)
	dialog_text.text = text
	for c in dialog_buttons.get_children():
		c.queue_free()
	dialog_buttons.columns = 1 if buttons.size() <= 4 else 2
	for pair in buttons:
		var b := UI.button(pair[0], pair[1], 20)
		b.size_flags_horizontal = SIZE_EXPAND_FILL
		b.custom_minimum_size.y = 48
		dialog_buttons.add_child(b)
	dialog.visible = true
	bottom_bar.visible = false
	joystick.visible = false
	_fit_dialog()
	_type_dialog(who)
	top_row.visible = _tut_kind() == "hud"
	hint_panel.visible = false


func _close_dialog() -> void:
	dialog.visible = false
	world.end_talk()
	_refresh()


# --- akış ----------------------------------------------------------------------

## Dünyada bir şeye dokunuldu: oraya yürü, sonra ne olduğuna göre konuş.
func _on_tapped(id: String) -> void:
	if busy or game != null or (tutorial_step >= 0 and not _tut_moving()):
		return
	busy = true
	Sfx.play("tap")
	var arrived: bool = await world.walk_to_target(id)
	busy = false
	if arrived:  # yolda yürüme koluyla başka yöne gidildiyse vazgeç
		_interact(id)


## Yürüdükten sonraki etkileşim (testler doğrudan bunu çağırır).
func _interact(id: String) -> void:
	if _tut_kind() == "walk":
		if id == "fatma":
			_tutorial(tutorial_step + 1)
		return
	if not task.is_empty() and _task_step(id):
		return
	if task.is_empty() and id == _story_who():
		_story_talk()
		return
	if id == "firin":
		_talk_firin()
		return
	if id == "fatma":
		_talk_fatma()
	elif id.begins_with("stall_"):
		var st: Dictionary = Props.STALLS[id.substr(6)]
		_say("Hoş geldin! Taze taze %s var. Teyzen bir şey isterse gel, ayırırım." % Errands._join(st["items"].map(func(k): return Errands.MARKET[k])),
			[["Kolay gelsin", _close_dialog]], id)
	elif id == "sutlu":
		_talk_sutlu()
	elif id.begins_with("tarh"):
		_talk_bed(int(id.substr(4)))
	elif id == "gozluk":
		pass
	else:
		_talk_neighbor(id)


func _talk_fatma() -> void:
	if not task.is_empty():
		_say("Önce elindeki işi bitir evladım, ben buradayım.", [["Tamam teyzecim", _close_dialog]])
		return
	if GameState.is_day_over():
		var extra: Array = Hikaye.after_lines("fatma")
		_say("Bugünlük bu kadar %s. Yarın yine gel, sana kurabiye ayırdım.%s" % [GameState.call_name(), (" " + extra[0]) if extra.size() > 0 else ""],
			[["Yarın görüşürüz teyzecim", _close_dialog]])
		return
	var errand := GameState.current_errand()
	var info := Errands.build(errand)
	if errand["type"] == "pazar":
		info["kind"] = "shop"
		info["intro"] = "Evladım, pazara gidiver de bana %s al. Pazar yeri yolun sonunda, tezgahlardan alırsın." % Errands.want_text(info["want"])
		_say(info["intro"], [["Hemen teyzecim", _start_task.bind("fatma", info)], ["Sonra", _close_dialog]])
		return
	_say(info["intro"], [["Hemen teyzecim", _start_game.bind(errand["type"], info)], ["Sonra", _close_dialog]])


func _talk_neighbor(id: String) -> void:
	var n := Neighbors.get_neighbor(id)
	if not GameState.favor_available(id) or not task.is_empty():
		var pool: Array = Hikaye.after_lines(id)
		if pool.is_empty() or randf() < 0.4:  # mahallede olan biten daha çok konuşulur
			pool = n["chat"]
		var line: String = pool[randi() % pool.size()]
		_say(line, _neighbor_extras(id) + [["Hadi kolay gelsin", _close_dialog]], id)
		return
	var others := ["fatma"]
	for o in GameState.neighbors_unlocked():
		others.append(o["id"])
	var info := Neighbors.favor(id, GameState.favor_seed(id), GameState.level(), others)
	if GameState.hearts(id) == 0:
		info["intro"] = "Sen Fatma'nın yardımcısısın değil mi? Ben %s. %s" % [n["name"], info["intro"]]
	var go := _start_game.bind("yemek", info) if info["kind"] == "game" else _start_task.bind(id, info)
	_say(info["intro"], [["Olur", go]] + _neighbor_extras(id) + [["Sonra", _close_dialog]], id)


## Komşuyla konuşurken ricanın dışında yapılabilecekler (bostan hediyesi vb.).
func _neighbor_extras(id: String) -> Array:
	var out := []
	if GameState.can_gift(id):
		out.append(["Bostandan hediye ver", _gift_harvest.bind(id)])
	if id == "ahmet":
		out.append(["Bir el tavla atalım", _open_fun.bind("tavla", "ahmet")])
		out.append(["Göle balığa gidelim", _open_fun.bind("balik", "ahmet")])
	if id == "filiz":
		out.append(["Çay demlemeyi öğret", _open_fun.bind("cay", "filiz")])
	if id == "miyase":
		out.append(["Örgü örelim", _open_fun.bind("orgu", "miyase")])
	if id == "hulya":
		out.append(["Mantı yapalım", _open_fun.bind("manti", "hulya")])
	return out


## Dünyada yürüyerek yapılacak bir işi başlatır.
func _start_task(giver: String, info: Dictionary) -> void:
	task = {"kind": info["kind"], "giver": giver, "info": info}
	match info["kind"]:
		"shop":
			task["want"] = info["want"]
			task["got"] = {}
			world.set_carry("file")
		"deliver":
			task["pickup"] = info["pickup"] if info["pickup"] != "" else giver
			task["targets"] = info["targets"]
			task["served"] = []
			task["carrying"] = info["pickup"] == ""
			if task["carrying"]:
				world.set_carry("cay")
		"find":
			task["found"] = false
			world.spawn_glasses(info["spot"])
	Sfx.play("whoosh")
	_close_dialog()


## İş sürerken birine dokunulunca işin adımı. Bir şey yaptıysa true döner.
func _task_step(id: String) -> bool:
	if task["kind"] == "story":
		if id in task["targets"] and id not in task["served"]:
			_story_delivered(id)
			return true
		return false
	if id == task["giver"] and _task_done():
		_finish_task()
		return true
	match task["kind"]:
		"shop":
			if id.begins_with("stall_"):
				_stall_dialog(id)
				return true
		"deliver":
			if not task["carrying"] and id == task["pickup"]:
				task["carrying"] = true
				world.set_carry("cay")
				Sfx.play("good")
				_say("Al bakalım, tavşan kanı çay! Dökme sakın.", [["Tamam amca", _close_dialog]], id)
				return true
			if task["carrying"] and id in task["targets"] and id not in task["served"]:
				task["served"].append(id)
				Sfx.play("coin")
				if id == task["giver"]:
					_finish_task()
					return true
				var left: int = task["targets"].size() - task["served"].size()
				var line := "Oh, tam zamanında! Çay gibisi yok." if left > 0 else "Çok makbule geçti. Ahmet'e selamımı söyle!"
				if left == 0:
					world.set_carry("")
				_say(line, [["Afiyet olsun", _close_dialog]], id)
				return true
		"find":
			if id == "gozluk":
				task["found"] = true
				world.remove_glasses()
				world.set_carry("gozluk")
				Sfx.play("good")
				_refresh()
				return true
	return false


## Tezgahtan alışveriş: listedekileri al.
func _stall_dialog(id: String, note := "") -> void:
	var st: Dictionary = Props.STALLS[id.substr(6)]
	var buttons := []
	for item in st["items"]:
		buttons.append([Errands.MARKET[item].capitalize(), _buy_item.bind(id, item)])
	buttons.append(["Tamam", _close_dialog])
	var text := note if note != "" else "Buyur, ne alırsın? Listene bak istersen."
	_say(text, buttons, id)
	_refresh_task()


func _buy_item(id: String, item: String) -> void:
	var want: int = task["want"].get(item, 0)
	var got: int = task["got"].get(item, 0)
	if want == 0:
		Sfx.play("bad")
		_stall_dialog(id, "Bu listende yok galiba, teyzen kızmasın.")
		return
	if got >= want:
		_stall_dialog(id, "Bundan yeterince aldın, %d tane yeter." % want)
		return
	task["got"][item] = got + 1
	Sfx.play("coin")
	if _task_done():
		_stall_dialog(id, "Liste tamam! Haydi, %s'ye götür." % Neighbors.name_of(task["giver"]))
	else:
		_stall_dialog(id, "%s poşete! Başka?" % Errands.MARKET[item].capitalize())


## İş bitti: ödül, teşekkür.
func _finish_task() -> void:
	var giver: String = task["giver"]
	var info: Dictionary = task["info"]
	if task["kind"] == "find":
		world.remove_glasses()
	task = {}
	world.set_carry("")
	level_note = ""
	if info.get("tutorial", false):  # rehberdeki ilk iş: günün işlerinden sayılmaz
		GameState.remember("ilk_is")
		GameState.add_kurabiye(TUT_REWARD)
		Sfx.play("levelup", -4.0)
		_say("Eline sağlık evladım, domatesler mis gibi! Al bakalım, ilk %d kurabiyen." % TUT_REWARD,
			[["Sağ ol teyzecim", _tutorial.bind(tutorial_step + 1)]])
	elif giver == "fatma":
		var reward := GameState.complete_errand("pazar")
		_say("%s Al bakalım, %d kurabiye senin!%s" % [Errands.build({"type": "pazar"})["thanks"], reward, level_note],
			[["Afiyet olsun bana", _close_dialog]])
	else:
		_finish_favor(info)


func _talk_sutlu() -> void:
	if GameState.sutlu_fed_today():
		_say("Mırrr... Sütlü karnı tok, mutlu mutlu peşinden geliyor. Başını okşadın, gözlerini kıstı.",
			[["Pisi pisi", _close_dialog]], "sutlu")
		Sfx.play("meow", -8.0, 1.1)
		return
	_say("Miyav! Sütlü sana bakıyor, kabı boş. Mama verelim mi?",
		[["Mama ver", _feed_sutlu], ["Sonra", _close_dialog]], "sutlu")
	Sfx.play("meow", -7.0)


# --- bostan -------------------------------------------------------------------

func _talk_bed(i: int) -> void:
	match GameState.bed_state(i):
		"empty":
			var btns := []
			for crop in GameState.CROPS:
				btns.append([GameState.CROPS[crop]["name"].capitalize(), _plant.bind(i, crop)])
			btns.append(["Sonra", _close_dialog])
			_say("Bu tarh boş. Ne ekelim? Yarın gelip toplarsın, komşulara da hediye edersin.", btns)
		"growing":
			var crop: String = GameState.bostan[i]["crop"]
			_say("%s filizlendi bile! Yarın olgunlaşır, gel topla." % GameState.CROPS[crop]["name"].capitalize(),
				[["Tamam", _close_dialog]])
		"ripe":
			var crop: String = GameState.bostan[i]["crop"]
			var n := GameState.harvest_bed(i)
			Sfx.play("good")
			_say("Maşallah, %d %s topladın! Komşulara götür, çok sevinirler. Tarh yine boşaldı, yenisini ekebilirsin." % [n, GameState.CROPS[crop]["name"]],
				[["Yine ek", _talk_bed.bind(i)], ["Tamam", _close_dialog]])


func _plant(i: int, crop: String) -> void:
	GameState.plant(i, crop)
	Sfx.play("tap")
	_say("%s ektin, suyunu da verdin. Yarın olgunlaşır." % GameState.CROPS[crop]["name"].capitalize(), [["Tamam", _close_dialog]])


func _gift_harvest(id: String) -> void:
	var r := GameState.gift_harvest(id)
	if r.is_empty():
		_close_dialog()
		return
	Sfx.play("good")
	var text := "Aa, bostanından %s mı getirdin? Ellerine sağlık evladım! Al bakalım, %d kurabiye." % [GameState.CROPS[r["crop"]]["name"], r["reward"]]
	text += "\n\nDostluk: %d/%d kalp." % [r["hearts"], Neighbors.MAX_HEARTS]
	if r["gift"] != 0:
		Sfx.play("levelup", -4.0)
		text += " Sana bir de hediyem var!"
	_say(text, [["Afiyet olsun", _close_dialog]], id)


func _feed_sutlu() -> void:
	var love := GameState.feed_sutlu()
	world.feed_sutlu()
	Sfx.play("meow", -6.0, 1.12)
	var text := "Sütlü mamasını afiyetle yedi! Artık bugün peşinden ayrılmaz."
	match love:
		3:
			text += " Üç gündür besliyorsun, seni çok sevdi. Sana mırlıyor!"
		7:
			text += " Bir haftadır besliyorsun, artık Sütlü senin kedin!"
	text += "\n\nSütlü'nün sevgisi: %d gün." % love
	_say(text, [["Afiyet olsun Sütlü", _close_dialog]], "sutlu")


func _start_game(type: String, info: Dictionary) -> void:
	_close_dialog()
	game = MINIGAMES[type].new().setup(info)
	game.finished.connect(_on_game_finished.bind(info))
	add_child(game)
	var back := UI.button("Mahalleye dön" if info.has("neighbor") else "Teyzeye dön", _quit_game, 18)
	back.custom_minimum_size = Vector2(160, 44)
	back.size_flags_horizontal = SIZE_SHRINK_BEGIN
	game.add_back(back)
	_refresh()


func _open_shop() -> void:
	if game != null or busy or tutorial_step >= 0:  # rehber sürerken açılmaz
		return
	_close_dialog()
	game = SHOP.new().setup({})
	add_child(game)
	var back := UI.button("Mahalleye dön", _quit_game, 18)
	back.custom_minimum_size = Vector2(180, 48)
	back.size_flags_horizontal = SIZE_SHRINK_BEGIN
	game.add_back(back)
	_refresh()


func _open_friends() -> void:
	if game != null or busy or tutorial_step >= 0:  # rehber sürerken açılmaz
		return
	_close_dialog()
	game = KOMSULAR.new().setup({})
	add_child(game)
	var back := UI.button("Mahalleye dön", _quit_game, 18)
	back.custom_minimum_size = Vector2(180, 48)
	back.size_flags_horizontal = SIZE_SHRINK_BEGIN
	game.add_back(back)
	_refresh()


func _open_settings() -> void:
	if game != null or busy or tutorial_step >= 0:  # rehber sürerken açılmaz
		return
	_close_dialog()
	game = SETTINGS.new().setup({})
	game.show_tutorial.connect(func(): _quit_game(); _tutorial(0))
	game.edit_avatar.connect(func(): _open_avatar())
	add_child(game)
	var back := UI.button("Mahalleye dön", _quit_game, 18)
	back.custom_minimum_size = Vector2(180, 48)
	back.size_flags_horizontal = SIZE_SHRINK_BEGIN
	game.add_back(back)
	_refresh()


# --- hikaye ------------------------------------------------------------------------

## Hikayede sıradaki kişi; ona şu an gidilemiyorsa "".
func _story_who() -> String:
	if not GameState.settings["tutorial"]:
		return ""
	var st := GameState.story_now()
	if st.is_empty():
		return ""
	var who: String = st["who"]
	if Neighbors.get_neighbor(who).size() > 0 and GameState.level() < Neighbors.get_neighbor(who)["unlock"]:
		return ""  # o komşu henüz taşınmadı
	return who


## Üstteki hedef yazısı: bölümün adı ve sıradaki iş.
func _story_goal() -> String:
	var st := GameState.story_now()
	if st.is_empty():
		return ""
	var c := Hikaye.chapter(GameState.story_ch)
	var text: String = st["goal"]
	var who: String = st["who"]
	var n := Neighbors.get_neighbor(who)
	if n.size() > 0 and GameState.level() < n["unlock"]:
		text = "%s %d. seviyede mahalleye taşınacak. İşleri yap, seviye atla." % [n["name"], n["unlock"]]
	elif st["do"].has("pay"):
		text = "%s: %d/%d kurabiye" % [st["goal"], mini(GameState.kurabiye, st["do"]["pay"]), st["do"]["pay"]]
	return "Bölüm %d · %s: %s" % [GameState.story_ch + 1, c["title"], text]


## Dünyadaki hedefin konuşma kutusundaki konuşanı.
func _story_speaker(who: String) -> String:
	return "stall_firin" if who == "firin" else who


func _who_name(id: String) -> String:
	if id == "stall_firin" or id == "firin":
		return "Fırıncı Mehmet"
	return Neighbors.name_of(id)


func _story_talk(i := 0) -> void:
	var st := GameState.story_now()
	if st.is_empty():
		_close_dialog()
		return
	var who: String = _story_speaker(st["who"])
	var lines: Array = st["lines"]
	if i < lines.size() - 1:
		_say(lines[i], [["Devam", _story_talk.bind(i + 1)]], who)
		return
	var line: String = lines[i]
	var act: Dictionary = st["do"]
	if act.has("choice"):
		var btns := []
		for ch in act["choice"]:
			btns.append([ch[0], _story_choose.bind(ch[1], ch[2], who)])
		_say(line, btns, who)
	elif act.has("pay"):
		var need: int = act["pay"]
		if GameState.kurabiye >= need:
			_say(line, [["%d kurabiye ver" % need, _story_pay.bind(need)], ["Sonra", _close_dialog]], who)
		else:
			_say("%s Daha %d kurabiye lazım. Fatma Teyze'nin işlerini yap, biriktir." % [line, need - GameState.kurabiye],
				[["Tamam", _close_dialog]], who)
	elif act.has("game"):
		_say(line, [[st["btn"], _story_play.bind(act["game"], who)], ["Sonra", _close_dialog]], who)
	elif act.has("deliver") or act.has("invite"):
		_say(line, [[st["btn"], _story_carry.bind(act)]], who)
	elif act.has("finale"):
		_say(line, [[st["btn"], _story_finale.bind(0)]], who)
	else:
		_say(line, [[st["btn"], _story_next.bind(st["who"])]], who)


## Adım bitti: sıradaki adım aynı kişideyse konuşma sürer, değilse kutu kapanır.
func _story_next(from: String) -> void:
	GameState.advance_story()
	Sfx.play("good", -6.0)
	if _story_who() == from:
		_story_talk()
	else:
		_close_dialog()


func _story_choose(flag: String, answer: String, who: String) -> void:
	GameState.story_flags[flag] = true
	_say(answer, [["Devam", _story_next.bind(GameState.story_now()["who"])]], who)


func _story_pay(n: int) -> void:
	GameState.kurabiye -= n
	Sfx.play("coin")
	var who: String = GameState.story_now()["who"]
	GameState.advance_story()
	_say("Al bakalım usta, kapının parası. Kapı tamir edildi, gıcır gıcır!", [["Devam", func():
		if _story_who() == who:
			_story_talk()
		else:
			_close_dialog()]], _story_speaker(who))


func _story_play(kind: String, who: String) -> void:
	_story_game = true
	_open_fun(kind, who)


func _story_carry(act: Dictionary) -> void:
	var targets: Array
	var icon: String
	if act.has("invite"):
		icon = act["invite"]
		targets = ["fatma"]
		for n in GameState.neighbors_unlocked():
			if n["id"] != GameState.story_now()["who"]:
				targets.append(n["id"])
	else:
		icon = act["carry"]
		targets = act["deliver"]
	var what: String = {"odun": "Odunları", "defter": "Tarifi", "davetiye": "Davetiyeleri", "simit": "Simidi"}.get(icon, "Bunu")
	task = {"kind": "story", "giver": "", "info": {}, "targets": targets, "served": [], "what": what}
	world.set_carry(icon)
	Sfx.play("whoosh")
	_close_dialog()


## Hikayede taşınan şey birine ulaştı.
func _story_delivered(id: String) -> void:
	task["served"].append(id)
	Sfx.play("coin")
	if task.get("simit", false):
		_simit_given(id)
		return
	var left: Array = task["targets"].filter(func(t): return t not in task["served"])
	if left.is_empty():
		task = {}
		world.set_carry("")
		GameState.advance_story()
		if _story_who() == id:
			_story_talk()
			return
		_say(INVITE_THANKS.get(id, "Sağ ol evladım, gelirim!"), [["Görüşürüz", _close_dialog]], _story_speaker(id))
		return
	_say(INVITE_THANKS.get(id, "Sağ ol evladım, gelirim!"), [["Görüşürüz", _close_dialog]], _story_speaker(id))
	_refresh_task()


const INVITE_THANKS := {
	"fatma": "Davetiye mi? Ben zaten oradayım evladım, ilk simidi ben yiyeceğim!",
	"ahmet": "Fırın açılışı mı? Gelirim tabii, tavlayı da getiririm. Mehmet'le bir el atarız.",
	"miyase": "Ay ne güzel! Mehmet'e bir atkı öreyim, fırının önü soğuk olur.",
	"hulya": "Gelirim tabii, Zehra'nın tarifini kimse benden iyi bilemez!",
	"filiz": "Ben zaten yazdım davetiyeleri evladım, kendime de bir tane ayırdım!",
}


## Bölümün sonu: fırın açılır, herkes konuşur, ödül gelir.
func _story_finale(i: int) -> void:
	var c := Hikaye.chapter(GameState.story_ch)
	var lines: Array = c["finale"]
	if i == 0:
		world.set_firin_open(true, true)
		Sfx.play("levelup")
		GameState.remember(c["id"])
	if i < lines.size():
		var text: String = lines[i][1]
		if i == 0 and GameState.story_flags.has("soz_ozlem"):
			text = "Mahalle beni özlemiş, sen söylemiştin ya... Haklıymışsın evladım. " + text
		_say(text, [["Devam", _story_finale.bind(i + 1)]], _story_speaker(lines[i][0]))
		return
	var reward: int = c["reward"]
	GameState.add_kurabiye(reward)
	GameState.simit_day = ""
	GameState.advance_story()
	Sfx.play("win")
	var tail := " %s" % Hikaye.NEXT_TEASER if GameState.story_now().is_empty() else ""
	_say("Bölüm bitti: %s! Ödülün %d kurabiye.%s" % [c["title"], reward, tail], [["Çok güzel!", _close_dialog]])


## Fırına dokununca: kapalıysa tozlu kapı, açıksa Mehmet Usta ve sıcak simit.
func _talk_firin() -> void:
	if not GameState.chapter_done("firin"):
		_say("Fırının kepenkleri inik, kapısına tahta çakılmış. Camlar tozlu, içi karanlık. Eskiden burası simit kokarmış...",
			[["Üzüldüm", _close_dialog]])
		return
	if not task.is_empty():
		_say("Hoş geldin evladım! Elindeki işi bitir, sonra uğra, simidin hazır.", [["Tamam usta", _close_dialog]], "stall_firin")
		return
	if GameState.simit_ready():
		_say("Günaydın evladım! Al, fırından yeni çıktı, sıcacık simit. Bir komşuna götür, gönlü olsun.",
			[["Simidi al", _take_simit], ["Sonra", _close_dialog]], "stall_firin")
		return
	_say(FIRIN_CHAT[randi() % FIRIN_CHAT.size()], [["Kolay gelsin usta", _close_dialog]], "stall_firin")


const FIRIN_CHAT := [
	"Sabah dörtte kalkıyorum yine, ama değer. Mahalle simit kokuyor ya!",
	"Ahmet dün geldi, tavlada beni yendi. Borcumu ödedim sayılır!",
	"Zehra'nın tarifiyle yaptığım simitleri herkes soruyor. Senin sayende evladım.",
	"Yarın yine gel, sana sıcak simit ayırırım.",
]


func _take_simit() -> void:
	GameState.simit_day = GameState.today()
	GameState.save_game()
	var targets := ["fatma"]
	for n in GameState.neighbors_unlocked():
		targets.append(n["id"])
	task = {"kind": "story", "giver": "", "info": {}, "targets": targets, "served": [], "what": "Simidi", "simit": true}
	world.set_carry("simit")
	Sfx.play("whoosh")
	_close_dialog()


## Sıcak simit bir komşuya ulaştı: bir kalp ve teşekkür.
func _simit_given(id: String) -> void:
	task = {}
	world.set_carry("")
	if id == "fatma":
		GameState.add_kurabiye(3)
		_say("Sıcak simit mi? Çayın yanına ne iyi gider! Al sana 3 kurabiye evladım.", [["Afiyet olsun", _close_dialog]])
		return
	var r := GameState.gift_simit(id)
	var text := "Aaa sıcak simit! Mehmet'in fırınından mı? Eline sağlık evladım. Al bakalım, %d kurabiye." % r["reward"]
	text += "\n\nDostluk: %d/%d kalp." % [r["hearts"], Neighbors.MAX_HEARTS]
	_say(text, [["Afiyet olsun", _close_dialog]], id)


# --- ilk açılış rehberi ------------------------------------------------------

## Fatma Teyze yeni oyuncuyu ilk işinde elinden tutar: önce yanına yürütür,
## sonra pazardan iki domates aldırır, en sonda ekranı tanıtır.
## [söz, tür]: "" konuşma, "walk" teyzeye yürü, "task" ilk işi yap,
## "hud"/"bar" o kısmı parlatır.
const TUTORIAL := [
	["Hoş geldin evladım! Ben Fatma Teyze. Mahallenin bütün işleri bende, sen de bana yardım edeceksin. Hele bir yanıma gel bakalım.", ""],
	["", "walk"],
	["Aferin, ne güzel yürüyorsun! İlk işin kolay: pazardan bana 2 domates al. Altın ok nereye gideceğini gösterir.", ""],
	["", "task"],
	["Üstteki kalpler bugünkü işlerin, yıldız da seviyen. İşleri bitirdikçe seviye atlarsın, yeni işler açılır.", "hud"],
	["Kurabiyelerinle Dükkan'dan işini kolaylaştıran hediyeler alırsın. Yazıyı büyütmek ya da sesi kısmak için de dişli düğmesine bas.", "bar"],
	["Her gün uğra, her gün yeni işler ve sana bir hediye olur. Haydi, şimdi bana bir dokun, sana bugünün işini vereyim!", ""],
]
const TUT_WANT := {"domates": 2}
const TUT_REWARD := 5


func _tut_kind() -> String:
	return TUTORIAL[tutorial_step][1] if tutorial_step >= 0 and tutorial_step < TUTORIAL.size() else ""


## Rehberde oyuncunun kendisinin gezdiği adımlar (yürüme, ilk iş).
func _tut_moving() -> bool:
	return _tut_kind() in ["walk", "task"]


func _tut_hint() -> String:
	if _tut_kind() == "walk":
		return "Fatma Teyze'nin yanına git: ekrana dokun ya da sol alttaki kolu kaydır."
	if not task.is_empty() and _task_done():
		return "Domatesler tamam! Fatma Teyze'ye dön, ona dokun."
	return "Altın oku takip et. Manav'a dokun, domates al."


func _build_hint() -> void:
	hint_panel = PanelContainer.new()
	hint_panel.add_theme_stylebox_override("panel", UI.box(Color("fff4c8"), UI.INK, 3, 10))
	hint_panel.mouse_filter = MOUSE_FILTER_IGNORE
	hint_label = UI.label("", 18)
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.custom_minimum_size.x = 300
	hint_panel.add_child(hint_label)
	hint_panel.anchor_left = 0.5
	hint_panel.anchor_right = 0.5
	hint_panel.anchor_top = 1.0
	hint_panel.anchor_bottom = 1.0
	hint_panel.grow_horizontal = GROW_DIRECTION_BOTH
	hint_panel.grow_vertical = GROW_DIRECTION_BEGIN
	hint_panel.offset_bottom = -14
	hint_panel.visible = false
	add_child(hint_panel)


func _process(delta: float) -> void:
	# mahallede gezerken sabah, gece ve yağmur anıları
	_world_check -= delta
	if _world_check <= 0.0:
		_world_check = 3.0
		var splash_on := get_children().any(func(c): return c is Splash)  # açılış ekranının üstüne çıkmasın
		if game == null and world.visible and not splash_on and tutorial_step < 0 and GameState.settings["tutorial"]:
			var ph := Mahalle3D.phase_now()
			var got := false
			if ph == "sabah":
				got = GameState.remember("sabah") or got
			elif ph == "gece":
				got = GameState.remember("gece") or got
			if GameState.is_rainy():
				got = GameState.remember("yagmur") or got
			if got:
				GameState.save_game()
	# rehberde teyzenin yanına kendi yürüyerek de varılabilir
	if _tut_kind() == "walk" and not busy and not dialog.visible \
			and world.player.position.distance_to(world.teyze.position) < 2.2:
		_tutorial(tutorial_step + 1)
	elif hint_panel.visible and _tut_kind() == "task":
		hint_label.text = _tut_hint()


func _tutorial(step: int) -> void:
	tutorial_step = step
	if step >= TUTORIAL.size():
		tutorial_step = -1
		GameState.set_setting("tutorial", true)
		GameState.daily_gift = 0
		_close_dialog()
		return
	match TUTORIAL[step][1]:
		"walk":
			if not task.is_empty():  # ayarlardan yeniden açıldı, elde iş var
				_tutorial(4)
				return
			_close_dialog()
			return
		"task":
			_start_task("fatma", {"kind": "shop", "want": TUT_WANT.duplicate(), "tutorial": true})
			return
	var text: String = TUTORIAL[step][0]
	var button := "Devam"
	match step:
		0:
			button = "Geliyorum teyzecim"
		2:
			button = "Hemen teyzecim"
			world.player_walker.stop()
	if step == TUTORIAL.size() - 1:
		button = "Tamam teyzecim"
	_say(text, [[button, _tutorial.bind(step + 1)]])
	match TUTORIAL[step][1]:
		"hud":
			_pulse(hud_panel)
		"bar":
			bottom_bar.visible = true
			_pulse(bottom_bar)


func _pulse(node: Control) -> void:
	var tw := node.create_tween().set_loops(4)
	tw.tween_property(node, "modulate", Color(1.25, 1.15, 0.7), 0.35)
	tw.tween_property(node, "modulate", Color.WHITE, 0.35)


## Mahalle albümü: açılan anı kartları.
func _open_album() -> void:
	if game != null or busy or tutorial_step >= 0:
		return
	_close_dialog()
	game = load("res://scripts/minigames/album.gd").new().setup({})
	add_child(game)
	var back := UI.button("Mahalleye dön", _quit_game, 18)
	back.custom_minimum_size = Vector2(180, 48)
	game.add_back(back)
	_refresh()


## Albüme yeni anı eklenince üstte kısa bir kart kayarak görünür.
func _next_toast() -> void:
	if _toast_busy or _toasts.is_empty():
		return
	_toast_busy = true
	var card := Album.get_card(_toasts.pop_front())
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UI.box(Color("fffaf0"), Color(card["color"]), 4, 10))
	p.mouse_filter = MOUSE_FILTER_IGNORE
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	h.add_child(UI.sprite(card["icon"], 40))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	var l1 := UI.label("Albüme yeni anı", 15, Color("8a6a4a"))
	l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.add_child(l1)
	var l2 := UI.label(card["title"], 21)
	l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.add_child(l2)
	h.add_child(v)
	p.add_child(h)
	p.anchor_left = 0.5
	p.anchor_right = 0.5
	p.grow_horizontal = GROW_DIRECTION_BOTH
	p.offset_top = -90
	p.offset_bottom = -90
	add_child(p)
	Sfx.play("levelup", -8.0, 1.2)
	var tw := p.create_tween()
	var y_end := top_row.size.y + 20.0 if top_row.visible else 10.0  # göstergenin altında
	tw.tween_method(func(y: float): p.offset_top = y; p.offset_bottom = y, -90.0, y_end, 0.35) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(2.4)
	tw.tween_property(p, "modulate:a", 0.0, 0.4)
	tw.tween_callback(func():
		p.queue_free()
		_toast_busy = false
		_next_toast())


## Kendi evinin içi: kurabiyeyle eşya alıp yerleştirme.
func _open_home() -> void:
	if game != null or busy or tutorial_step >= 0:
		return
	_close_dialog()
	game = load("res://scripts/minigames/evim.gd").new().setup({})
	add_child(game)
	var back := UI.button("Mahalleye dön", _quit_game, 18)
	back.custom_minimum_size = Vector2(180, 48)
	game.add_back(back)
	_refresh()


## Ahmet Amca'yla tavla ya da Filiz Teyze'yle çay demleme. Günün ilk
## oyununda küçük bir ödül var; sonra istediğin kadar oynarsın.
## Komşularla oynanan oyunların günün ilk oyunundaki ödülü: [kazanınca, kaybedince].
const FUN_REWARD := {"tavla": [6, 2], "cay": [4, 1], "orgu": [5, 2], "manti": [5, 2], "balik": [5, 2]}


func _open_fun(kind: String, who: String) -> void:
	_close_dialog()
	game = load("res://scripts/minigames/%s.gd" % kind).new().setup({})
	game.finished.connect(_on_fun_finished.bind(kind, who))
	add_child(game)
	var back := UI.button("Mahalleye dön", _quit_game, 18)
	back.custom_minimum_size = Vector2(180, 48)
	game.add_back(back)
	_refresh()


func _on_fun_finished(success: bool, kind: String, who: String) -> void:
	game.queue_free()
	game = null
	if _story_game:
		_story_game = false
		if success:
			GameState.remember(kind)
			GameState.advance_story()
			_story_talk()
		else:
			_say("Olsun evladım, bir daha deneriz. Hazır olunca gel.", [["Tamam", _close_dialog]], who)
		return
	var key := "oyun_" + kind
	if success and kind != "tavla" and GameState.remember(kind):  # tavla kendi sayar
		GameState.save_game()
	var first := not GameState.gifts_today.has(key)
	var reward := 0
	if first:
		GameState.gifts_today[key] = true
		reward = FUN_REWARD.get(kind, [4, 1])[0 if success else 1]
		GameState.add_kurabiye(reward)
	var text := ""
	match kind:
		"tavla":
			text = "Eline sağlık, beni yendin! Kırk yıldır yenilmemiştim valla." if success else "Bu sefer ben kazandım ama iyi oynadın delikanlı. Yarın rövanş!"
		"cay":
			text = "Tavşan kanı olmuş, mis gibi! Sen bu işi öğrendin." if success else "Olsun evladım, çay demlemek sabır ister. Yine gel."
		"orgu":
			text = "Atkın sıcacık oldu, kışın boynunu sarar! Elinin ayarı varmış senin." if success else "Birkaç ilmek kaçtı ama olsun, el emeği göz nuru. Yine öreriz."
		"manti":
			text = "Kaşığa dört tane sığıyor maşallah! Annem görse seni evlat edinirdi." if success else "Olsun, hamur da sabır ister. Yine yaparız."
		"balik":
			text = "Rastgele! Akşama tavada kızartırız, sen de gel." if success else "Balık bugün nazlıydı. Olsun, göl kenarında sohbet de güzel."
	if reward > 0:
		text += " Al bakalım, %d kurabiye." % reward
	_say(text, [["Sağ ol", _close_dialog]], who)


func _quit_game() -> void:
	game.queue_free()
	game = null
	_story_game = false
	_refresh()


func _on_game_finished(_success: bool, info: Dictionary) -> void:
	var type := GameState.current_errand().get("type", "") as String
	var stars: int = game.get("stars") if game.get("stars") != null else 0
	game.queue_free()
	game = null
	level_note = ""
	if info.has("neighbor"):
		_finish_favor(info)
		return
	var extra: int = STAR_BONUS.get(stars, 0)  # dikkatli oynayana fazladan kurabiye
	var reward := GameState.complete_errand(type, info.get("bonus", 0) + extra)
	var text := "%s Al bakalım, %d kurabiye senin!" % [info["thanks"], reward]
	if extra > 0:
		text += " Üç yıldız aldın, %d tanesi ondan!" % extra if stars == 3 else " %d tanesi iki yıldızın hakkı." % extra
	_say(text + level_note, [["Afiyet olsun bana", _close_dialog]])


## Yıldıza göre işin fazladan ödülü.
const STAR_BONUS := {3: 3, 2: 1}


func _finish_favor(info: Dictionary) -> void:
	var id: String = info["neighbor"]
	var n := Neighbors.get_neighbor(id)
	var r := GameState.complete_favor(id)
	var text := "%s Al bakalım, %d kurabiye." % [info["thanks"], r["reward"]]
	text += "\n\nDostluk: %d/%d kalp." % [r["hearts"], Neighbors.MAX_HEARTS]
	match Neighbors.GIFTS.get(r["gift"], ""):
		"kurabiye":
			text += " Sana bir tabak kurabiye de ayırdım, içinde 10 tane var!"
		"sus":
			text += " Sana bir hediyem var: %s. Mahallene koydum bile!" % Decor.get_decor(n["gift_decor"])["name"]
		"can":
			text += " Artık sen benim can dostumsun evladım! Bu 25 kurabiye de benden."
	if r["gift"] != 0:
		Sfx.play("levelup", -4.0)
	_say(text + level_note, [["Sağ ol teyzem", _close_dialog]], id)


func _on_level_up(lv: int) -> void:
	Sfx.play("levelup")
	level_note = "\n\nSeviye atladın, artık Sv %d!" % lv
	for t in GameState.UNLOCKS:
		if GameState.UNLOCKS[t] == lv:
			level_note += " Yeni görev açıldı: %s." % TYPE_NAMES[t]
	if lv == 4:
		level_note += " Artık günde bir görev fazla var."
	for n in Neighbors.ALL:
		if n["unlock"] == lv:
			level_note += " Mahalleye %s taşındı, bir uğra!" % n["name"]


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
	var surprise := GameState.daily_surprise
	GameState.daily_gift = 0
	GameState.daily_surprise = ""
	var cal := Takvim.new().setup(gift, surprise)
	cal.closed.connect(_refresh)
	add_child(cal)
	return true


# --- ekran görüntüsü turu (geliştirme için) -------------------------------------

func _arg(key: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with(key + "="):
			return a.substr(key.length() + 1)
	return ""


func _show_daily_gift_test(gift: int, surprise := "") -> void:
	GameState.daily_gift = gift
	GameState.daily_surprise = surprise
	_show_daily_gift()


func _screenshot_tour(dir: String) -> void:
	GameState.reset()
	GameState.xp = 125
	GameState.kurabiye = 47
	GameState.decor = {"kedievi": true, "semaver": true, "cesme": true, "cardak": true, "gul": true, "fener": true}
	GameState.new_day(false)
	var splash := Splash.new()
	add_child(splash)
	await get_tree().create_timer(1.6).timeout
	await _shot(dir, "00_acilis")
	await get_tree().create_timer(2.6).timeout
	await _shot(dir, "00_baslik")
	splash.close()
	_open_avatar()
	await _shot(dir, "01_karakter")
	game.call("_pick", "gender", "erkek", true)
	game.call("_pick", "hair", 1, false)
	await _shot(dir, "01_karakter_erkek")
	_quit_game()
	GameState.avatar = {"gender": "kiz", "hair": 0, "hair_color": 1, "top": 1, "name": "Ayşe"}
	world.set_player_look(GameState.avatar)
	_tutorial(1)
	await _shot(dir, "1_rehber_yuru")
	_tutorial(3)
	await _shot(dir, "1_rehber_is")
	task = {}
	world.set_carry("")
	_refresh()
	_tutorial(4)
	await _shot(dir, "1_rehber")
	_close_dialog()
	tutorial_step = -1
	GameState.streak = 3
	_show_daily_gift_test(5)
	await _shot(dir, "1_takvim")
	get_children().filter(func(c): return c is Takvim)[-1].call("_close")
	GameState.streak = 7
	_show_daily_gift_test(12, "kilim")
	await _shot(dir, "1_takvim_7")
	get_children().filter(func(c): return c is Takvim)[-1].call("_close")
	GameState.streak = 1
	tutorial_step = 4
	_tutorial(TUTORIAL.size())
	await _shot(dir, "0_mahalle")
	_on_tapped("fatma")
	await get_tree().create_timer(3.0).timeout
	await _shot(dir, "2_gorev")
	_close_dialog()
	_start_task("fatma", {"kind": "shop", "want": {"domates": 2, "simit": 1}})
	_tp(Vector3(-1.5, 0, 14.0))
	await _shot(dir, "2_pazar")
	_interact("stall_manav")
	_buy_item("stall_manav", "domates")
	await _shot(dir, "2_tezgah")
	_close_dialog()
	_drop_task()
	_tp(Vector3(-8.0, 0, 3.6))
	await _shot(dir, "2_kahvehane")
	_tp(Vector3(8.5, 0, 9.8))
	await _shot(dir, "2_ciftlik")
	_tp(Vector3(-7.0, 0, 10.5))
	await _shot(dir, "2_golet")
	_tp(Vector3(0.0, 0, 21.0))
	await _shot(dir, "2_bahce")
	_tp(Vector3(7.5, 0, 22.5))
	await _shot(dir, "2_kovan")
	_tp(Vector3(-13.0, 0, 7.0))
	await _shot(dir, "2_aycicegi")
	_tp(Vector3(14.0, 0, 6.0))
	await _shot(dir, "2_elma")
	_tp(Vector3(6.0, 0, -3.0))
	await _shot(dir, "2_evler")
	_tp(world.FIRIN_POS + Vector3(0.6, 0, 3.4))
	await _shot(dir, "10_firin_kapali")
	_interact("firin")
	await _shot(dir, "10_firin_kapi")
	_close_dialog()
	var yesterday := Time.get_date_string_from_unix_time(Time.get_unix_time_from_system() - 86400)
	GameState.plant(0, "domates")
	GameState.bostan[0]["planted"] = yesterday
	GameState.plant(1, "biber")
	GameState.plant(2, "karpuz")
	GameState.bostan[2]["planted"] = yesterday
	GameState.plant(3, "havuc")
	GameState.bostan[3]["planted"] = yesterday
	_refresh()
	_tp(Vector3(3.5, 0, 5.4))
	await _shot(dir, "2_bostan")
	_interact("tarh0")
	await _shot(dir, "2_bostan_hasat")
	_close_dialog()
	world.update_sky(true, "aksam", 0)
	_tp(Vector3(0.4, 0, 0.5))
	await _shot(dir, "7_aksam")
	world.update_sky(true, "gece", 0)
	await _shot(dir, "7_gece")
	world.update_sky(true, "ogle", 1)
	await get_tree().create_timer(1.0).timeout
	await _shot(dir, "7_yagmur")
	world.update_sky(true, "ogle", 0)
	_tp(Vector3(-0.5, 0, -3.0))
	_interact("sutlu")
	await _shot(dir, "2_sutlu")
	_feed_sutlu()
	await _shot(dir, "2_sutlu_mama")
	_close_dialog()
	GameState.friendship = {"filiz": 5, "miyase": 2}
	_on_tapped("filiz")
	await get_tree().create_timer(3.0).timeout
	await _shot(dir, "2_komsu")
	_close_dialog()
	_finish_favor(Neighbors.favor("filiz", 1, 4))
	await _shot(dir, "2_komsu_hediye")
	_close_dialog()
	for type in ["haber", "kedi", "yemek", "altin"]:
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
	GameState.decor = {"kedievi": true, "cesme": true}
	game.set("tab", "decor")
	game.call("_fill")
	await _shot(dir, "4_dukkan_susler")
	_quit_game()
	_open_friends()
	await _shot(dir, "4_komsular")
	_quit_game()
	_open_settings()
	await _shot(dir, "5_ayarlar")
	_quit_game()
	GameState.kurabiye = 120
	_open_home()
	for id in ["kilim", "sedir", "semaver"]:
		if EvEsya.get_item(id).size() > 0:
			game.call("choose", id)
	await get_tree().create_timer(0.8).timeout
	await _shot(dir, "8_evim")
	_quit_game()
	_open_fun("tavla", "ahmet")
	await _shot(dir, "8_tavla")
	_quit_game()
	_open_fun("cay", "filiz")
	await _shot(dir, "8_cay")
	_quit_game()
	for kind in [["balik", "ahmet"], ["orgu", "miyase"], ["manti", "hulya"]]:
		_open_fun(kind[0], kind[1])
		await _shot(dir, "8_" + kind[0])
		_quit_game()
	_talk_neighbor("ahmet")
	await _shot(dir, "8_ahmet")
	_close_dialog()
	_toasts.clear()
	await get_tree().create_timer(4.0).timeout  # önceki anı kartları geçsin
	GameState.remember("cay")
	await get_tree().create_timer(0.4).timeout
	await _shot(dir, "9_ani_karti")
	_open_album()
	await _shot(dir, "9_album")
	game.call("_show", Album.get_card("cay"), game)
	await _shot(dir, "9_album_not")
	_quit_game()
	GameState.story_step = 1
	_tp(Vector3(-1.5, 0, 14.0))
	_interact("stall_firin")
	_story_talk(1)
	await _shot(dir, "10_secim")
	_close_dialog()
	GameState.story_step = Hikaye.chapter(0)["steps"].size() - 1
	_tp(world.FIRIN_POS + Vector3(0.6, 0, 3.4))
	_refresh_task()
	await _shot(dir, "10_hedef_acilis")
	_story_finale(0)
	await get_tree().create_timer(1.2).timeout
	await _shot(dir, "10_firin_acilis")
	_close_dialog()
	_story_finale(2)
	await _shot(dir, "10_bolum_bitti")
	_close_dialog()
	await _shot(dir, "10_firin_acik")
	UI.text_scale = 1.2
	_start_game("yemek", Errands.build({"type": "yemek", "seed": 3, "level": 5}))
	await _shot(dir, "6_buyuk_yazi")
	_quit_game()
	get_tree().quit()


## Tur için oyuncuyu bir yere ışınlar, kamera da hemen gelir.
func _tp(pos: Vector3) -> void:
	world.player_walker.stop()
	world.player.position = pos
	world._cam_focus = Vector3(clampf(pos.x, -15.5, 15.5), 0, clampf(pos.z - 0.8, -4.4, 22.5))


func _shot(dir: String, name: String) -> void:
	await get_tree().create_timer(0.6).timeout
	if _type_tw and _type_tw.is_running():
		_type_tw.kill()
		dialog_text.visible_characters = -1
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [dir, name])
