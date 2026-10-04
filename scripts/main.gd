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
var level_note := ""
var hud_hearts: HBoxContainer
var dialog: PanelContainer
var dialog_text: Label
var dialog_name: Label
var dialog_face: Portrait
var dialog_who := ""
var friends_button: Button
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
	joystick = Joystick.new()
	bottom_bar.add_child(joystick)
	world.joystick = joystick
	var gap := Control.new()
	gap.size_flags_horizontal = SIZE_EXPAND_FILL
	gap.mouse_filter = MOUSE_FILTER_IGNORE
	bottom_bar.add_child(gap)
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
	_build_dialog()
	GameState.changed.connect(_refresh)
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
	world.set_bowl_full(GameState.sutlu_fed_today())
	world.sutlu_follow = GameState.sutlu_fed_today()
	friends_button.visible = not GameState.neighbors_unlocked().is_empty()
	world.visible = game == null
	bottom_bar.visible = game == null and not dialog.visible
	top_row.visible = game == null and not dialog.visible
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
	world.set_marks(bubbles, goals if game == null else [])
	task_panel.visible = not task.is_empty() and game == null
	if task.is_empty():
		return
	task_label.text = _task_text()


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
	return false


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
	dialog_text = UI.label("", 20, UI.INK, true)
	dialog_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	tv.add_child(dialog_text)
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
	dialog_buttons.columns = 1 if buttons.size() <= 2 else 2
	for pair in buttons:
		var b := UI.button(pair[0], pair[1], 20)
		b.size_flags_horizontal = SIZE_EXPAND_FILL
		b.custom_minimum_size.y = 48
		dialog_buttons.add_child(b)
	dialog.visible = true
	bottom_bar.visible = false
	top_row.visible = tutorial_step >= 0 and TUTORIAL[tutorial_step][1] == "hud"


func _close_dialog() -> void:
	dialog.visible = false
	world.end_talk()
	_refresh()


# --- akış ----------------------------------------------------------------------

## Dünyada bir şeye dokunuldu: oraya yürü, sonra ne olduğuna göre konuş.
func _on_tapped(id: String) -> void:
	if busy or game != null or tutorial_step >= 0:
		return
	busy = true
	Sfx.play("tap")
	var arrived: bool = await world.walk_to_target(id)
	busy = false
	if arrived:  # yolda yürüme koluyla başka yöne gidildiyse vazgeç
		_interact(id)


## Yürüdükten sonraki etkileşim (testler doğrudan bunu çağırır).
func _interact(id: String) -> void:
	if not task.is_empty() and _task_step(id):
		return
	if id == "fatma":
		_talk_fatma()
	elif id.begins_with("stall_"):
		var st: Dictionary = Props.STALLS[id.substr(6)]
		_say("Hoş geldin! Taze taze %s var. Teyzen bir şey isterse gel, ayırırım." % Errands._join(st["items"].map(func(k): return Errands.MARKET[k])),
			[["Kolay gelsin", _close_dialog]], id)
	elif id == "sutlu":
		_talk_sutlu()
	elif id == "gozluk":
		pass
	else:
		_talk_neighbor(id)


func _talk_fatma() -> void:
	if not task.is_empty():
		_say("Önce elindeki işi bitir evladım, ben buradayım.", [["Tamam teyzecim", _close_dialog]])
		return
	if GameState.is_day_over():
		_say("Bugünlük bu kadar %s. Yarın yine gel, sana kurabiye ayırdım." % GameState.call_name(),
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
		var line: String = n["chat"][randi() % n["chat"].size()]
		_say(line, [["Hadi kolay gelsin", _close_dialog]], id)
		return
	var others := ["fatma"]
	for o in GameState.neighbors_unlocked():
		others.append(o["id"])
	var info := Neighbors.favor(id, GameState.favor_seed(id), GameState.level(), others)
	if GameState.hearts(id) == 0:
		info["intro"] = "Sen Fatma'nın yardımcısısın değil mi? Ben %s. %s" % [n["name"], info["intro"]]
	var go := _start_game.bind("yemek", info) if info["kind"] == "game" else _start_task.bind(id, info)
	_say(info["intro"], [["Olur", go], ["Sonra", _close_dialog]], id)


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
	if giver == "fatma":
		var reward := GameState.complete_errand("pazar")
		_say("%s Al bakalım, %d kurabiye senin!%s" % [Errands.build({"type": "pazar"})["thanks"], reward, level_note],
			[["Afiyet olsun bana", _close_dialog]])
	else:
		_finish_favor(info)


func _talk_sutlu() -> void:
	if GameState.sutlu_fed_today():
		_say("Mırrr... Sütlü karnı tok, mutlu mutlu peşinden geliyor. Başını okşadın, gözlerini kıstı.",
			[["Pisi pisi", _close_dialog]], "sutlu")
		Sfx.play("meow", -4.0, 1.15)
		return
	_say("Miyav! Sütlü sana bakıyor, kabı boş. Mama verelim mi?",
		[["Mama ver", _feed_sutlu], ["Sonra", _close_dialog]], "sutlu")
	Sfx.play("meow", -3.0)


func _feed_sutlu() -> void:
	var love := GameState.feed_sutlu()
	world.feed_sutlu()
	Sfx.play("meow", -2.0, 1.2)
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
	if game != null or busy:
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
	if game != null or busy:
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
	if game != null or busy:
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


# --- ilk açılış rehberi ------------------------------------------------------

const TUTORIAL := [
	["Hoş geldin evladım! Ben Fatma Teyze. Mahallenin bütün işleri bende, sen de bana yardım edeceksin.", ""],
	["Bana dokununca sana bir iş veririm. Her iş birkaç dakika sürer. Acele yok, istediğin an bırakıp sonra devam edebilirsin.", ""],
	["İşi bitirince kurabiye kazanırsın. Üstteki kalpler bugünkü işlerin, yıldız da seviyen. Seviye atladıkça yeni işler açılır.", "hud"],
	["Kurabiyelerinle Dükkan'dan işini kolaylaştıran hediyeler alırsın. Yazıyı büyütmek ya da sesi kısmak için de dişli düğmesine bas.", "bar"],
	["Her gün uğra, her gün yeni işler ve sana bir hediye olur. Haydi, şimdi bana bir dokun bakalım!", ""],
]


func _tutorial(step: int) -> void:
	tutorial_step = step
	if step >= TUTORIAL.size():
		tutorial_step = -1
		GameState.set_setting("tutorial", true)
		GameState.daily_gift = 0
		_close_dialog()
		return
	var last := step == TUTORIAL.size() - 1
	_say(TUTORIAL[step][0], [["Tamam teyzecim" if last else "Devam", _tutorial.bind(step + 1)]])
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


func _quit_game() -> void:
	game.queue_free()
	game = null
	_refresh()


func _on_game_finished(_success: bool, info: Dictionary) -> void:
	var type := GameState.current_errand().get("type", "") as String
	game.queue_free()
	game = null
	level_note = ""
	if info.has("neighbor"):
		_finish_favor(info)
		return
	var reward := GameState.complete_errand(type, info.get("bonus", 0))
	var text := "%s Al bakalım, %d kurabiye senin!" % [info["thanks"], reward]
	_say(text + level_note, [["Afiyet olsun bana", _close_dialog]])


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
	GameState.daily_gift = 0
	var text := "Günaydın %s! Bugün de geldin, al sana %d kurabiye." % [GameState.call_name(), gift]
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
	_tutorial(3)
	await _shot(dir, "1_rehber")
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
	UI.text_scale = 1.2
	_start_game("yemek", Errands.build({"type": "yemek", "seed": 3, "level": 5}))
	await _shot(dir, "6_buyuk_yazi")
	_quit_game()
	get_tree().quit()


## Tur için oyuncuyu bir yere ışınlar, kamera da hemen gelir.
func _tp(pos: Vector3) -> void:
	world.player_walker.stop()
	world.player.position = pos
	world._cam_focus = Vector3(clampf(pos.x, -15.5, 15.5), 0, clampf(pos.z - 0.8, -2.8, 22.5))


func _shot(dir: String, name: String) -> void:
	await get_tree().create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [dir, name])
