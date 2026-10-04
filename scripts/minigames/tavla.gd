extends Minigame
## Tavla: kahvehanede Ahmet Amca'yla kısa, sade bir tavla.
## 12 hane, kişi başı 5 pul. Açık pullar senin: sağ alttan başlar, alt sıradan
## sola, üst sıradan sağa gider ve sağ üstten toplanır. Tek duran pul kırılır,
## kırılan pul ortadaki çubuğa gider ve baştan girer. Zorunlu hamle, süre yok.
##
## setup(info): info boş olabilir; "neighbor" anahtarı varsa dokunulmaz.
## finished(true): oyuncu kazandı. finished(false): Ahmet Amca kazandı.

const BAR := -1  ## kaynak: kırık pullar (çubuk)
const OFF := 100  ## hedef: toplanmış
const NONE := -99
const ME := 1
const AHMET := 2
const NAMES := {1: "yek", 2: "dü", 3: "se", 4: "cihar", 5: "beş", 6: "şeş"}
const DOUBLES := {1: "Hep yek", 2: "Dubara", 3: "Dü se", 4: "Dört cihar", 5: "Dü beş", 6: "Düşeş"}
const CHEERS := ["Hadi bakalım evladım!", "Sıra sende delikanlı.", "Bakalım zar ne diyecek?",
		"Atıver zarı evladım.", "Hadi, göreyim seni!"]

## board[p] (p = 1..12): artı sayı benim pullarım, eksi sayı Ahmet Amca'nın.
var board: Array = []
var bar := [0, 0, 0]
var off := [0, 0, 0]
var dice_face: Array = []
var dice_used: Array = []
var dice_side := ME
var selected := NONE
var targets := {}  ## hedef -> zar
var busy := true
var over := false
## Animasyon hızı (test için küçültülebilir). Oyuncuya süre baskısı değildir.
var pace := 1.0
var _anim := {}
var _rolling := false
var roll_button: Button
var area: Control
var who: HBoxContainer
var end_panel: PanelContainer
var end_label: Label


func build() -> void:
	board.resize(13)
	board.fill(0)
	# başlangıç: benim pullarım 1, 3, 5'te; Ahmet Amca'nınkiler 12, 10, 8'de
	board[1] = 2
	board[3] = 2
	board[5] = 1
	board[12] = -2
	board[10] = -2
	board[8] = -1
	header("Tavla", "Ahmet Amca: Hadi bakalım evladım! Sen açık pullarsın. Zar at.")
	roll_button = UI.button("Zar At", _on_roll, 24)
	add_action(roll_button)
	area = Control.new()
	area.size_flags_vertical = SIZE_EXPAND_FILL
	area.size_flags_horizontal = SIZE_EXPAND_FILL
	area.mouse_filter = MOUSE_FILTER_STOP
	area.draw.connect(_draw_board)
	area.gui_input.connect(_on_input)
	area.resized.connect(_layout)
	content.add_child(area)
	# Ahmet Amca tahtanın sol ortasında oturur
	who = HBoxContainer.new()
	who.mouse_filter = MOUSE_FILTER_IGNORE
	who.add_theme_constant_override("separation", 2)
	var face := Portrait.new(Vector2(50, 56), false, Neighbors.get_neighbor("ahmet"))
	face.size_flags_vertical = SIZE_SHRINK_CENTER
	who.add_child(face)
	var name_label := UI.label("Ahmet\nAmca", 15, UI.INK)
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.add_theme_constant_override("line_spacing", -4)
	name_label.size_flags_vertical = SIZE_SHRINK_CENTER
	who.add_child(name_label)
	area.add_child(who)
	end_panel = PanelContainer.new()
	end_panel.visible = false
	end_label = UI.label("", 20, UI.INK, true)
	end_panel.add_child(end_label)
	area.add_child(end_panel)
	busy = false


# ---------------------------------------------------------------- kurallar

func _dir(s: int) -> int:
	return 1 if s == ME else -1


func _own(p: int, s: int) -> int:
	return maxi(board[p], 0) if s == ME else maxi(-board[p], 0)


func _is_home(p: int, s: int) -> bool:
	return p >= 9 if s == ME else p <= 4


func _can_bear(s: int) -> bool:
	if bar[s] > 0:
		return false
	for p in range(1, 13):
		if _own(p, s) > 0 and not _is_home(p, s):
			return false
	return true


## src'deki puldan d kadar gidilince varılan yer; gidilemiyorsa NONE.
func _dest(s: int, src: int, d: int) -> int:
	var f: int
	if src == BAR:
		if bar[s] == 0:
			return NONE
		f = 0 if s == ME else 13
	else:
		if _own(src, s) == 0:
			return NONE
		f = src
	var t := f + d * _dir(s)
	if t >= 1 and t <= 12:
		return NONE if _own(t, 3 - s) >= 2 else t
	if src != BAR and _can_bear(s):
		return OFF
	return NONE


func _remaining() -> Array:
	var r := []
	for i in dice_face.size():
		if not dice_used[i] and dice_face[i] not in r:
			r.append(dice_face[i])
	return r


## Oynanabilecek tüm hamleler: [kaynak, zar, hedef].
func legal_moves(s: int) -> Array:
	var out := []
	var srcs := [BAR] if bar[s] > 0 else []
	for p in range(1, 13):
		if _own(p, s) > 0:
			srcs.append(p)
	for d in _remaining():
		for src in srcs:
			var t := _dest(s, src, d)
			if t != NONE:
				out.append([src, d, t])
	return out


func _use_die(d: int) -> void:
	for i in dice_face.size():
		if not dice_used[i] and dice_face[i] == d:
			dice_used[i] = true
			return


func _dice_name(a: int, b: int) -> String:
	if a == b:
		return DOUBLES[a] + "!"
	if maxi(a, b) == 6 and mini(a, b) == 5:
		return "Şeşbeş!"
	return "%s %s!" % [NAMES[maxi(a, b)].capitalize(), NAMES[mini(a, b)]]


# ---------------------------------------------------------------- akış

func _on_roll() -> void:
	if busy or over or dice_side == ME and not _remaining().is_empty():
		return
	roll([])


## Oyuncunun zarı. values verilirse o zar gelir (test için).
func roll(values: Array) -> void:
	busy = true
	roll_button.disabled = true
	selected = NONE
	targets.clear()
	await _roll_dice(ME, values)
	var d: Array = dice_face
	var text := _dice_name(d[0], d[1])
	if legal_moves(ME).is_empty():
		say(text + " Bu zarla oynayacak yer yok. Sıra Ahmet Amca'da.")
		await _pause(1.6)
		_ahmet_turn()
		return
	if bar[ME] > 0:
		text += " Önce ortadaki kırık pulunu oyuna sok."
	else:
		text += " Bir pula dokun, sonra yeşil yere."
	say(text)
	busy = false


func _roll_dice(s: int, values: Array) -> void:
	dice_side = s
	var a: int = values[0] if values.size() > 0 else randi_range(1, 6)
	var b: int = values[1] if values.size() > 1 else randi_range(1, 6)
	_rolling = true
	Sfx.play("stir", -4.0, 1.3)
	for i in 6:
		dice_face = [randi_range(1, 6), randi_range(1, 6)]
		dice_used = [false, false]
		area.queue_redraw()
		await _pause(0.07)
	_rolling = false
	dice_face = [a, a, a, a] if a == b else [a, b]
	dice_used = []
	dice_used.resize(dice_face.size())
	dice_used.fill(false)
	Sfx.play("tap")
	area.queue_redraw()


## Oyuncu hamlesi: src'deki pulu d zarıyla oynar. Olmazsa false.
func play(src: int, d: int) -> bool:
	if busy or over or d not in _remaining():
		return false
	var t := _dest(ME, src, d)
	if t == NONE:
		return false
	busy = true
	selected = NONE
	targets.clear()
	var hit: bool = await _move(ME, src, t, d)
	if over:
		return true
	if off[ME] == 5:
		_end(true)
		return true
	if hit:
		say("Ahmet Amca: Vay, kırdın beni! Aferin evladım.")
	if _remaining().is_empty():
		await _pause(0.5)
		_ahmet_turn()
	elif legal_moves(ME).is_empty():
		say("Kalan zarla oynayacak yer yok. Sıra Ahmet Amca'da.")
		await _pause(1.4)
		_ahmet_turn()
	else:
		if not hit:
			say("Güzel! Kalan zar: %s. Bir pul daha seç." % ", ".join(PackedStringArray(_remaining().map(func(x): return str(x)))))
		busy = false
	return true


func _ahmet_turn() -> void:
	busy = true
	roll_button.disabled = true
	selected = NONE
	targets.clear()
	say("Ahmet Amca zar atıyor...")
	await _pause(0.5)
	await _roll_dice(AHMET, [])
	var d: Array = dice_face
	var line := _dice_name(d[0], d[1])
	if d[0] == d[1]:
		line += " Çift geldi, dört hamle!"
	say("Ahmet Amca: " + line)
	await _pause(0.9)
	var hits := 0
	while true:
		var moves := legal_moves(AHMET)
		if moves.is_empty():
			break
		var best: Array = moves[0]
		var best_score := -1000.0
		for m in moves:
			var sc := _score(m) + randf() * 1.5
			if sc > best_score:
				best_score = sc
				best = m
		if await _move(AHMET, best[0], best[2], best[1]):
			hits += 1
		await _pause(0.45)
		if off[AHMET] == 5:
			_end(false)
			return
	if not _remaining().is_empty() and hits == 0:
		say("Ahmet Amca: Hıh, oynayacak yerim kalmadı. Sıra sende.")
		await _pause(1.0)
	elif hits > 0:
		say("Ahmet Amca: Kusura bakma evladım, kırdım! Ortadaki pulunu tekrar sok.")
		await _pause(1.4)
	dice_side = ME
	dice_face = []
	dice_used = []
	area.queue_redraw()
	if hits == 0:
		say("Ahmet Amca: " + CHEERS.pick_random() + " Zar at.")
	roll_button.disabled = false
	busy = false


## Ahmet Amca'nın basit aklı: kırmak, toplamak, kapı yapmak iyi; açık pul bırakmak kötü.
func _score(m: Array) -> float:
	var src: int = m[0]
	var d: int = m[1]
	var t: int = m[2]
	var sc := d * 0.2
	if src == BAR:
		sc += 4.0
	if t == OFF:
		return sc + 5.0
	if _own(t, ME) == 1:
		sc += 5.0
	var mine := _own(t, AHMET)
	if mine == 1:
		sc += 3.0
	elif mine == 0:
		sc -= 1.5
	if src != BAR and _own(src, AHMET) == 2:
		sc -= 1.5
	return sc


## Pulu taşır (animasyonlu). Kırma olduysa true.
func _move(s: int, src: int, t: int, d: int) -> bool:
	var from_pos := _bar_pos(s, bar[s] - 1) if src == BAR else _point_pos(src, _own(src, s) - 1)
	if src == BAR:
		bar[s] -= 1
	else:
		board[src] -= 1 if s == ME else -1
	_use_die(d)
	var to_pos: Vector2
	if t == OFF:
		to_pos = _tray_pos(s, off[s])
	else:
		var hit := _own(t, 3 - s) == 1
		to_pos = _point_pos(t, 0 if hit else _own(t, s))
	_anim = {"from": from_pos, "to": to_pos, "side": s, "t": 0.0}
	Sfx.play("whoosh", -8.0, 1.2)
	var tw := create_tween()
	tw.tween_method(_set_anim_t, 0.0, 1.0, 0.35 * pace)
	await tw.finished
	_anim = {}
	var hit := false
	if t == OFF:
		off[s] += 1
		Sfx.play("coin", -4.0)
	else:
		if _own(t, 3 - s) == 1:
			hit = true
			board[t] = 0
			bar[3 - s] += 1
			Sfx.play("bad" if s == AHMET else "good", -4.0)
		else:
			Sfx.play("tap", -2.0)
		board[t] += 1 if s == ME else -1
	area.queue_redraw()
	return hit


func _set_anim_t(x: float) -> void:
	_anim["t"] = x
	area.queue_redraw()


func _pause(sec: float) -> void:
	await get_tree().create_timer(sec * pace).timeout


func _end(won: bool) -> void:
	over = true
	busy = true
	roll_button.disabled = true
	GameState.tavla_played += 1
	if won:
		GameState.tavla_won += 1
	GameState.save_game()
	end_label.text = ("Kazandın!\n" if won else "Ahmet Amca kazandı.\n") + (
			"Maşallah evladım, yendin beni!" if won else "Çok iyi oynadın, bir dahakine sen yenersin!")
	end_label.add_theme_color_override("font_color", UI.GOOD if won else UI.INK)
	end_panel.visible = true
	who.visible = false
	_layout()
	await get_tree().process_frame
	_layout()
	if won:
		win("Ahmet Amca: Maşallah, yendin beni!")
	else:
		lose("Ahmet Amca: Bu sefer ben aldım. Eline sağlık, güzel oyundu!")


## Kaybedince: teselli sözü, sonra finished(false).
func lose(text: String) -> void:
	say(text, UI.INK)
	Sfx.play("good", -2.0)
	mouse_filter = MOUSE_FILTER_STOP
	await get_tree().create_timer(2.5).timeout
	finished.emit(false)


# ---------------------------------------------------------------- dokunma

func _on_input(e: InputEvent) -> void:
	if not (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT):
		return
	if over:
		return
	if busy:
		if dice_side == AHMET:
			say("Ahmet Amca oynuyor, az bekle evladım.")
		return
	if _remaining().is_empty() or dice_side != ME:
		say("Önce soldaki \"Zar At\" düğmesine bas.", UI.ACCENT)
		return
	var spot := _spot_at(e.position)
	if spot == NONE:
		return
	if selected != NONE and targets.has(spot):
		play(selected, targets[spot])
		return
	_select(spot)


func _select(spot: int) -> void:
	targets.clear()
	selected = NONE
	var own: bool = bar[ME] > 0 if spot == BAR else spot != OFF and _own(spot, ME) > 0
	if not own:
		say("Orada senin pulun yok. Açık renkli bir pula dokun.", UI.ACCENT)
		area.queue_redraw()
		return
	for d in _remaining():
		var t := _dest(ME, spot, d)
		if t != NONE and not targets.has(t):
			targets[t] = d
	if targets.is_empty():
		if spot != BAR and bar[ME] > 0:
			say("Bu pul gidemiyor. Ortadaki kırık pulunu sokmayı dene.", UI.ACCENT)
		else:
			say("Bu pul bu zarla gidemiyor, başka pul seç.", UI.ACCENT)
	else:
		selected = spot
		Sfx.play("tap", -4.0)
		if OFF in targets:
			say("Yeşil yere dokun. Sağdaki kutuya dokunursan pulu toplarsın.")
		else:
			say("Şimdi yeşil yere dokun.")
	area.queue_redraw()


# ---------------------------------------------------------------- çizim

func _layout() -> void:
	var g := _geo()
	var inner: Rect2 = g["inner"]
	var half: float = g["pw"] * 3
	who.size = who.get_combined_minimum_size()
	who.position = Vector2(inner.position.x + (half - who.size.x) / 2, inner.get_center().y - who.size.y / 2)
	var w := inner.size.x * 0.9
	end_label.custom_minimum_size.x = w - 28
	end_label.size.x = w - 28
	end_panel.size = Vector2(w, end_panel.get_combined_minimum_size().y)
	end_panel.position = (area.size - end_panel.size) / 2
	area.queue_redraw()


## Tahtanın ölçüleri.
func _geo() -> Dictionary:
	var sz := area.size
	var fr := 8.0
	var inner := Rect2(fr, fr, sz.x - fr * 2, sz.y - fr * 2)
	var r := minf(inner.size.x * 0.13 * 0.44, inner.size.y * 0.075)
	var bar_w := r * 2 + 8
	var tray_w := r * 2 + 12
	var pw := (inner.size.x - tray_w - bar_w) / 6.0
	r = minf(r, pw * 0.47)
	return {"inner": inner, "r": r, "pw": pw, "bar_w": bar_w, "tray_w": tray_w,
		"tri_h": inner.size.y * 0.41}


func _col_x(g: Dictionary, col: int) -> float:
	var inner: Rect2 = g["inner"]
	return inner.position.x + col * g["pw"] + (g["bar_w"] if col >= 3 else 0.0)


func _col_of(p: int) -> int:
	return 6 - p if p <= 6 else p - 7


func _point_pos(p: int, k: int) -> Vector2:
	var g := _geo()
	var inner: Rect2 = g["inner"]
	var r: float = g["r"]
	var n := maxi(absi(board[p]) + 1, 5)
	var sp := minf(r * 2, (g["tri_h"] - r * 2) / (n - 1))
	var x: float = _col_x(g, _col_of(p)) + g["pw"] / 2.0
	if p >= 7:
		return Vector2(x, inner.position.y + r + k * sp)
	return Vector2(x, inner.end.y - r - k * sp)


func _bar_pos(s: int, k: int) -> Vector2:
	var g := _geo()
	var inner: Rect2 = g["inner"]
	var r: float = g["r"]
	var x: float = _col_x(g, 3) - g["bar_w"] / 2.0
	var cy := inner.get_center().y
	var sp := r * 1.4
	return Vector2(x, cy + r + 4 + k * sp) if s == ME else Vector2(x, cy - r - 4 - k * sp)


func _tray_pos(s: int, k: int) -> Vector2:
	var g := _geo()
	var inner: Rect2 = g["inner"]
	var r: float = g["r"]
	var x: float = inner.end.x - g["tray_w"] / 2.0
	var hgt := r * 0.62
	return Vector2(x, inner.position.y + 6 + hgt / 2 + k * (hgt + 3)) if s == ME \
		else Vector2(x, inner.end.y - 6 - hgt / 2 - k * (hgt + 3))


func _spot_at(pos: Vector2) -> int:
	var g := _geo()
	var inner: Rect2 = g["inner"]
	if pos.x >= inner.end.x - g["tray_w"]:
		return OFF
	var bx: float = _col_x(g, 3) - g["bar_w"]
	if pos.x >= bx and pos.x < bx + g["bar_w"]:
		return BAR
	for col in 6:
		var x := _col_x(g, col)
		if pos.x >= x and pos.x < x + g["pw"]:
			return col + 7 if pos.y < inner.get_center().y else 6 - col
	return NONE


func _draw_board() -> void:
	var g := _geo()
	var inner: Rect2 = g["inner"]
	var r: float = g["r"]
	var pw: float = g["pw"]
	var tri_h: float = g["tri_h"]
	var font := get_theme_default_font()
	area.draw_style_box(UI.box(Color("7a4a26"), UI.INK, 3, 0), Rect2(Vector2.ZERO, area.size))
	area.draw_rect(inner, Color("ecd5a6"))
	# çubuk ve toplama kutusu
	var bx: float = _col_x(g, 3) - g["bar_w"]
	area.draw_rect(Rect2(bx, inner.position.y, g["bar_w"], inner.size.y), Color("7a4a26"))
	var tray := Rect2(inner.end.x - g["tray_w"], inner.position.y, g["tray_w"], inner.size.y)
	area.draw_rect(tray, Color("5e3a1e"))
	area.draw_line(Vector2(tray.position.x, inner.get_center().y), Vector2(tray.end.x, inner.get_center().y),
			Color("ecd5a6"), 2)
	# haneler
	for p in range(1, 13):
		var x := _col_x(g, _col_of(p))
		var col := Color("a0522d") if p % 2 else Color("2f5d50")
		var pts: PackedVector2Array
		if p >= 7:
			pts = [Vector2(x + 2, inner.position.y), Vector2(x + pw - 2, inner.position.y),
				Vector2(x + pw / 2, inner.position.y + tri_h)]
		else:
			pts = [Vector2(x + 2, inner.end.y), Vector2(x + pw - 2, inner.end.y),
				Vector2(x + pw / 2, inner.end.y - tri_h)]
		area.draw_colored_polygon(pts, col)
		if targets.has(p):
			area.draw_colored_polygon(pts, Color(0.35, 0.85, 0.35, 0.55))
	# pullar
	for p in range(1, 13):
		var n := absi(board[p])
		var s := ME if board[p] > 0 else AHMET
		for k in n:
			_draw_checker(_point_pos(p, k), r, s)
		if n >= 4:
			var top := _point_pos(p, n - 1)
			_text(font, top, str(n), r, UI.INK if s == ME else UI.CREAM)
		if selected == p:
			area.draw_arc(_point_pos(p, n - 1), r + 3, 0, TAU, 32, Color("ffd23f"), 4)
		if targets.has(p):
			var at := _point_pos(p, 0 if _own(p, AHMET) == 1 else _own(p, ME))
			area.draw_arc(at, r, 0, TAU, 32, Color("2e9b3e"), 4)
	for s in [ME, AHMET]:
		for k in bar[s]:
			_draw_checker(_bar_pos(s, k), r, s)
		for k in off[s]:
			var c := _tray_pos(s, k)
			var rc := Rect2(c.x - g["tray_w"] / 2 + 5, c.y - r * 0.31, g["tray_w"] - 10, r * 0.62)
			area.draw_style_box(UI.box(Color("fbf3e2") if s == ME else Color("5a2418"), UI.INK, 2, 0), rc)
	if selected == BAR:
		area.draw_arc(_bar_pos(ME, bar[ME] - 1), r + 3, 0, TAU, 32, Color("ffd23f"), 4)
	if targets.has(OFF):
		area.draw_rect(tray.grow(-2), Color(0.35, 0.85, 0.35, 0.5))
		area.draw_rect(tray.grow(-2), Color("2e9b3e"), false, 4)
		_text(font, Vector2(tray.get_center().x, inner.position.y + inner.size.y * 0.3), "↑", r * 1.6, UI.CREAM)
	for s in [ME, AHMET]:
		if off[s] > 0:
			var y := inner.position.y + inner.size.y * (0.42 if s == ME else 0.58)
			_text(font, Vector2(tray.get_center().x, y), str(off[s]), r * 1.1, UI.CREAM)
	# zarlar sağ yarıda: benimkiler beyaz, Ahmet Amca'nınkiler kırmızı
	if not dice_face.is_empty():
		var nd := dice_face.size()
		var x0 := _col_x(g, 3)
		var half := pw * 3
		var band := inner.size.y - tri_h * 2
		var ds := minf(minf(band * 0.8, 44), (half - 8) / nd - 6)
		var total := nd * ds + (nd - 1) * 6
		var cy := inner.get_center().y
		for i in nd:
			var rc := Rect2(x0 + (half - total) / 2 + i * (ds + 6), cy - ds / 2, ds, ds)
			_draw_die(rc, dice_face[i], dice_side, dice_used[i] and not _rolling)
	if not _anim.is_empty():
		var t: float = _anim["t"]
		var p: Vector2 = (_anim["from"] as Vector2).lerp(_anim["to"], t)
		p.y -= sin(t * PI) * r * 1.5
		_draw_checker(p, r * (1.0 + sin(t * PI) * 0.15), _anim["side"])


func _draw_checker(c: Vector2, r: float, s: int) -> void:
	var fill := Color("fbf3e2") if s == ME else Color("5a2418")
	var ring := Color("d9c7a0") if s == ME else Color("8a3a26")
	area.draw_circle(c + Vector2(0, 2), r, Color(0, 0, 0, 0.3))
	area.draw_circle(c, r, fill)
	area.draw_arc(c, r * 0.6, 0, TAU, 24, ring, 2.5)
	area.draw_arc(c, r - 1, 0, TAU, 32, UI.INK, 2)


func _draw_die(rc: Rect2, v: int, s: int, used: bool) -> void:
	var bg := Color("fffaf0") if s == ME else Color("c8412f")
	var dot := UI.INK if s == ME else Color.WHITE
	if used:
		bg = bg.lerp(Color("9a8b78"), 0.6)
		dot = dot.lerp(Color("9a8b78"), 0.5)
	area.draw_style_box(UI.box(bg, UI.INK, 2, 0), rc)
	var c := rc.get_center()
	var o := rc.size.x * 0.26
	var pr := rc.size.x * 0.09
	var spots := {
		1: [Vector2.ZERO], 2: [Vector2(-1, -1), Vector2(1, 1)],
		3: [Vector2(-1, -1), Vector2.ZERO, Vector2(1, 1)],
		4: [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)],
		5: [Vector2(-1, -1), Vector2(1, -1), Vector2.ZERO, Vector2(-1, 1), Vector2(1, 1)],
		6: [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 0), Vector2(1, 0), Vector2(-1, 1), Vector2(1, 1)]}
	for sp in spots[v]:
		area.draw_circle(c + sp * o, pr, dot)


func _text(font: Font, c: Vector2, s: String, px: float, col: Color) -> void:
	var fs := int(px)
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_CENTER, -1, fs).x
	area.draw_string(font, Vector2(c.x - w / 2, c.y + fs * 0.35), s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
