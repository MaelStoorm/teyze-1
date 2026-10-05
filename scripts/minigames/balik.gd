extends Minigame
## Balık tutma: ördekli gölün kenarında Ahmet Amca'yla olta.
## "Olta at" de, şamandırayı izle; şamandıra batınca "Çek!" de. Erken çekmenin
## cezası yok. Her atışta balık iki kez vurur; ikisi de kaçarsa o atış boşa gider.
## 6 atışta 3 balık tutan kazanır. Eski ayakkabı ve yosun da çıkabilir (gülmelik);
## ama kazanmak hâlâ mümkünken, kazanmayı imkânsız kılacak bir çöp hiç çıkmaz.
##
## setup(info): info boş olabilir. İsteğe bağlı "seed" (int): rastgeleliği sabitler.
## finished(true): 3 balık tutuldu. finished(false): olta hakları bitti.

enum { READY, CASTING, WAITING, DIPPING, REELING, OVER }

const NEED := 3  ## kazanmak için gereken balık
const CASTS := 6  ## olta hakkı
const BITES := 2  ## her atışta balığın vurma sayısı
const WINDOW := 1.2  ## ilk balıkta "Çek!" süresi (sn)
const WINDOW_STEP := 0.1  ## her tutulan balıkta bu kadar kısalır
const WINDOW_MIN := 0.95
const FISH := ["sazan", "alabalik", "kefal"]
const CATCH := {
	"sazan": {"name": "Sazan", "line": "Tombul mu tombul bir sazan!",
		"say": "Maşallah evladım! Sazan bu gölün beyidir."},
	"alabalik": {"name": "Alabalık", "line": "Benek benek, ne güzel bir alabalık!",
		"say": "Vay vay! Akşama tavada kızartırız."},
	"kefal": {"name": "Kefal", "line": "Pırıl pırıl bir kefal.",
		"say": "Eline sağlık! Izgarası pek güzel olur."},
	"altin": {"name": "Altın Balık", "line": "Aman! Altın balık! Hemen bir dilek tut.",
		"say": "Ömrümde bir kere gördüm bunu! Şanslısın."},
	"ayakkabi": {"name": "Eski Ayakkabı", "line": "Balık değil ama tek ayakkabı çıktı!",
		"say": "Hah! Geçen yaz kaybettiğim ayakkabım bu!"},
	"yosun": {"name": "Yosun", "line": "Balık değil, bir tutam yosun çıktı.",
		"say": "Olsun, ördekler sever bunu. Bir daha atalım."},
}
const WAIT_LINES := [
	"Sabır evladım. Balık acele sevmez.",
	"Şşş... Sessiz olalım, ürkmesinler.",
	"Şamandıraya göz kulak ol. Batınca hemen çek!",
	"Gençken burada kocaman bir sazan tutmuştum.",
	"Hava da ne güzel, değil mi?",
]
const EARLY_LINES := [
	"Daha değil evladım. Şamandıra batınca çek.",
	"Az bekle, balık daha yeme bakıyor.",
]
## Göldeki nilüferler: göl merkezine göre konum (-1..1), boyut, çiçek.
const PADS := [[-0.62, -0.3, 1.0, true], [-0.4, 0.5, 0.8, false], [0.55, 0.4, 1.1, true],
		[0.68, -0.38, 0.75, false], [0.18, -0.6, 0.65, false]]

var state := READY
var caught: Array = []  ## tutulan balık türleri
var junk := 0
var casts_left := CASTS
var bites_left := BITES
var wait_left := 0.0
var dip_left := 0.0
var cue_done := false
var last_kind := ""
var golden_seen := false
## Animasyon/bekleme hızı (test için küçültülebilir). Oyuncuya süre baskısı değildir.
var pace := 1.0
var rng := RandomNumberGenerator.new()

# çizim durumu
var bob := Vector2(0.1, 0.05)  ## şamandıranın göldeki yeri (göl koordinatı)
var fly := 0.0  ## 0: oltanın ucunda, 1: suda
var sink := 0.0  ## 0: yüzer, 1: batmış
var jiggle := 0.0
var hooked := ""  ## çekilirken oltanın ucunda sallanan şey
var ripples: Array = []  ## {p: göl koordinatı, age, big}
var drops: Array = []  ## {p: göl koordinatı, o: piksel ofset, v, age}
var _t := 0.0

var area: Control
var action_button: Button
var tally: Control
var card: PanelContainer
var card_pic: Control
var card_name: Label
var card_line: Label
var card_kind := ""
var who: Control


func build() -> void:
	if data.has("seed"):
		rng.seed = int(data["seed"])
	else:
		rng.randomize()
	header("Balık Tutma", "Ahmet Amca: Gel evladım, otur şöyle. Oltayı at, şamandırayı izle.")
	action_button = UI.button("Olta at", _on_action, 26)
	action_button.custom_minimum_size.y = 64
	add_action(action_button)
	area = Control.new()
	area.size_flags_vertical = SIZE_EXPAND_FILL
	area.size_flags_horizontal = SIZE_EXPAND_FILL
	area.clip_contents = true
	area.mouse_filter = MOUSE_FILTER_STOP
	area.draw.connect(_draw_pond)
	area.gui_input.connect(_on_input)
	area.resized.connect(_layout)
	content.add_child(area)
	# göl köşesinde "kova": tutulan balıklar ve kalan olta hakları (yazısız)
	tally = Control.new()
	tally.size = Vector2(156, 62)
	tally.mouse_filter = MOUSE_FILTER_IGNORE
	tally.draw.connect(_draw_tally)
	area.add_child(tally)
	who = Portrait.new(Vector2(56, 64), false, Neighbors.get_neighbor("ahmet"))
	area.add_child(who)
	_build_card()
	_refresh()


func _build_card() -> void:
	card = PanelContainer.new()
	card.visible = false
	card.mouse_filter = MOUSE_FILTER_IGNORE
	card.add_theme_stylebox_override("panel", UI.box(UI.CREAM, UI.INK, 4, 10))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	v.mouse_filter = MOUSE_FILTER_IGNORE
	card.add_child(v)
	card_pic = Control.new()
	card_pic.custom_minimum_size = Vector2(150, 76)
	card_pic.mouse_filter = MOUSE_FILTER_IGNORE
	card_pic.draw.connect(func():
		var s := card_pic.size
		card_pic.draw_style_box(UI.box(Color("cfeaf2"), Color("8fbfcc"), 2, 0), Rect2(Vector2.ZERO, s))
		draw_catch(card_pic, s / 2 + Vector2(0, 2), minf(s.x * 0.62, s.y * 1.5), card_kind, sin(_t * 5) * 0.06))
	v.add_child(card_pic)
	card_name = UI.label("", 24, UI.ACCENT, true)
	v.add_child(card_name)
	card_line = UI.label("", 17, UI.INK, true)
	v.add_child(card_line)
	area.add_child(card)


func _process(delta: float) -> void:
	_t += delta
	match state:
		WAITING:
			wait_left -= delta
			if not cue_done and wait_left <= 0.7 * pace:
				cue_done = true
				_nibble()
			if wait_left <= 0.0:
				_bite()
		DIPPING:
			dip_left -= delta
			if dip_left <= 0.0:
				_missed()
	for r in ripples:
		r["age"] += delta
	ripples = ripples.filter(func(r): return r["age"] < 1.6)
	for d in drops:
		d["age"] += delta
		var v: Vector2 = d["v"]
		v.y += 260.0 * delta
		d["v"] = v
		d["o"] += v * delta
	drops = drops.filter(func(d): return d["age"] < 0.7)
	area.queue_redraw()
	if card.visible:
		card_pic.queue_redraw()


# ---------------------------------------------------------------- oyun

func window() -> float:
	return maxf(WINDOW_MIN, WINDOW - WINDOW_STEP * caught.size())


func _on_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		_on_action()
	elif e is InputEventScreenTouch and e.pressed:
		_on_action()


## Tek düğme: hazırken olta atar, beklerken/batınca çeker. Göle dokunmak da aynısı.
func _on_action() -> void:
	match state:
		READY:
			cast()
		WAITING, DIPPING:
			pull()


func cast() -> void:
	if state != READY or casts_left <= 0:
		return
	state = CASTING
	casts_left -= 1
	bites_left = BITES
	card.visible = false
	hooked = ""
	sink = 0.0
	bob = Vector2(rng.randf_range(-0.15, 0.35), rng.randf_range(-0.12, 0.22))
	say("Hooop! Güzel attın.")
	_refresh()
	Sfx.play("whoosh", -4.0, 1.2)
	var tw := create_tween()
	tw.tween_property(self, "fly", 1.0, 0.8 * pace).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tw.finished
	if state != CASTING:
		return
	_splash(true)
	Sfx.play("tap", -2.0, 0.6)
	_start_wait(rng.randf_range(2.2, 4.0))
	say(WAIT_LINES[rng.randi() % WAIT_LINES.size()])


func _start_wait(sec: float) -> void:
	state = WAITING
	wait_left = sec * pace
	cue_done = false
	_refresh()


## Vurmadan az önce şamandıra hafifçe titrer: göz için küçük bir ipucu.
func _nibble() -> void:
	ripples.append({"p": bob, "age": 0.0, "big": false})
	var tw := create_tween()
	tw.tween_property(self, "jiggle", 1.0, 0.12 * pace)
	tw.tween_property(self, "jiggle", -1.0, 0.12 * pace)
	tw.tween_property(self, "jiggle", 0.0, 0.12 * pace)


func _bite() -> void:
	state = DIPPING
	dip_left = window() * pace
	say("Vurdu! Çek, çek!", UI.ACCENT)
	Sfx.play("whoosh", -3.0, 1.7)
	_splash(true)
	var tw := create_tween()
	tw.tween_property(self, "sink", 1.0, 0.15 * pace).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_refresh()


## Şamandıra batıkken çek: balık geldi. Beklerken çekmenin cezası yok.
func pull() -> void:
	if state == WAITING:
		say(EARLY_LINES[rng.randi() % EARLY_LINES.size()])
		Sfx.play("tap", -8.0)
		var tw := create_tween()
		tw.tween_property(self, "jiggle", 0.6, 0.1)
		tw.tween_property(self, "jiggle", 0.0, 0.15)
		return
	if state != DIPPING:
		return
	state = REELING
	_refresh()
	var kind := _pick_catch()
	hooked = kind
	_splash(true)
	Sfx.play("stir", -4.0, 1.3)
	say("Geliyor, geliyor!")
	var tw := create_tween()
	tw.tween_property(self, "sink", 0.0, 0.15 * pace)
	tw.tween_property(self, "fly", 0.0, 0.9 * pace).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished
	if kind in CATCH and kind not in ["ayakkabi", "yosun"]:
		caught.append(kind)
	else:
		junk += 1
	last_kind = kind
	_show_card(kind)
	say(str(CATCH[kind]["say"]))
	_refresh()
	_after_cast()


## Ne çıkacak? Kazanmak hâlâ mümkünse ve çöp kazanmayı imkânsız kılacaksa çöp çıkmaz.
func _pick_catch() -> String:
	var need := NEED - caught.size()
	var must_fish := need > casts_left  # bu atış balık değilse yetişilemez
	if not must_fish and junk < 2 and caught.size() > 0 and rng.randf() < 0.3:
		return "ayakkabi" if last_kind != "ayakkabi" and rng.randf() < 0.5 else "yosun"
	if not golden_seen and caught.size() > 0 and rng.randf() < 0.12:
		golden_seen = true
		return "altin"
	var pool: Array = FISH.filter(func(f): return f != last_kind and f not in caught)
	if pool.is_empty():
		pool = FISH.filter(func(f): return f != last_kind)
	return pool[rng.randi() % pool.size()]


func _missed() -> void:
	bites_left -= 1
	var tw := create_tween()
	tw.tween_property(self, "sink", 0.0, 0.3 * pace)
	if bites_left > 0:
		say("Kaçtı ama yem duruyor. Bekle, yine gelir.")
		_start_wait(rng.randf_range(1.6, 2.6))
		return
	state = REELING
	_refresh()
	say("Haylaz balık yemi yedi kaçtı! Olsun, yine atarız.")
	Sfx.play("tap", -6.0, 0.8)
	tw.tween_property(self, "fly", 0.0, 0.8 * pace).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished
	_after_cast()


func _after_cast() -> void:
	if caught.size() >= NEED:
		state = OVER
		_refresh()
		await get_tree().create_timer(1.2 * pace).timeout
		win("Üç balık! Maşallah, akşama balık ekmek var!")
	elif casts_left <= 0:
		state = OVER
		_refresh()
		await get_tree().create_timer(1.2 * pace).timeout
		lose("Bugün balıklar nazlıydı. Olsun, sohbet de güzeldi! Yine gel.")
	else:
		state = READY
		_refresh()


## Kaybedince: teselli sözü, sonra finished(false).
func lose(text: String) -> void:
	say(text, UI.INK)
	Sfx.play("good", -2.0)
	mouse_filter = MOUSE_FILTER_STOP
	await get_tree().create_timer(2.5 * pace).timeout
	finished.emit(false)


func _show_card(kind: String) -> void:
	card_kind = kind
	card_name.text = CATCH[kind]["name"]
	card_name.add_theme_color_override("font_color",
		UI.INK if kind in ["ayakkabi", "yosun"] else (Color("c98a00") if kind == "altin" else UI.GOOD))
	card_line.text = CATCH[kind]["line"]
	card.visible = true
	_layout()
	UI.pop(card)
	if kind == "altin":
		Sfx.play("coin")
	elif kind in ["ayakkabi", "yosun"]:
		Sfx.play("quack", -4.0)


func _refresh() -> void:
	var dipping := state == DIPPING
	action_button.text = "Olta at" if state in [READY, CASTING, OVER] else "Çek!"
	action_button.disabled = state in [CASTING, REELING, OVER]
	var hot: StyleBoxFlat = UI.box(Color("ffd36b"), UI.ACCENT, 4) if dipping else null
	for s in ["normal", "hover", "pressed"]:
		if hot:
			action_button.add_theme_stylebox_override(s, hot)
		else:
			action_button.remove_theme_stylebox_override(s)
	tally.queue_redraw()


func _splash(big: bool) -> void:
	ripples.append({"p": bob, "age": 0.0, "big": big})
	ripples.append({"p": bob, "age": -0.25, "big": false})
	for i in 7:
		var a := rng.randf_range(-PI * 0.85, -PI * 0.15)
		var sp := rng.randf_range(60, 120)
		drops.append({"p": bob, "o": Vector2.ZERO, "v": Vector2(cos(a), sin(a)) * sp, "age": 0.0})


# ---------------------------------------------------------------- yerleşim

func _geo() -> Dictionary:
	var sz := area.size
	var u := minf(sz.x / 420.0, sz.y / 320.0)
	var c := Vector2(sz.x * 0.57, sz.y * 0.62)
	var rad := Vector2(sz.x * 0.42, sz.y * 0.3)
	var tip := Vector2(sz.x * 0.27, sz.y * 0.34)
	return {"sz": sz, "u": u, "c": c, "r": rad, "tip": tip}


func _pp(g: Dictionary, f: Vector2) -> Vector2:
	return g["c"] + f * g["r"]


func _layout() -> void:
	if card == null:
		return
	var sz := area.size
	tally.position = Vector2(6, 6)
	who.size = who.custom_minimum_size
	who.position = Vector2(4, sz.y - who.size.y - 2)
	var w := clampf(sz.x * 0.52, 210.0, 330.0)
	card_name.custom_minimum_size.x = w - 20
	card_line.custom_minimum_size.x = w - 20
	card.size = Vector2(w, 0)
	card.size = Vector2(w, card.get_combined_minimum_size().y)
	card.position = Vector2(sz.x - w - 8, maxf(6.0, (sz.y - card.size.y) / 2))
	area.queue_redraw()


# ---------------------------------------------------------------- çizim

static func _ellipse(c: Vector2, r: Vector2, n := 40) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
	return pts


func _draw_pond() -> void:
	var g := _geo()
	var sz: Vector2 = g["sz"]
	var u: float = g["u"]
	var c: Vector2 = g["c"]
	var r: Vector2 = g["r"]
	# gökyüzü ve çimen
	var hz := sz.y * 0.27
	area.draw_polygon([Vector2(0, 0), Vector2(sz.x, 0), Vector2(sz.x, hz), Vector2(0, hz)],
		[Color("a9dcf2"), Color("a9dcf2"), Color("e6f6ec"), Color("e6f6ec")])
	area.draw_circle(Vector2(sz.x * 0.86, sz.y * 0.09), 16 * u, Color("fff1a8"))
	for i in 3:
		var cx := fmod(sz.x * (0.15 + i * 0.33) + _t * 4.0, sz.x + 80) - 40
		var cy := sz.y * (0.07 + 0.04 * (i % 2))
		for k in 3:
			area.draw_circle(Vector2(cx + (k - 1) * 13 * u, cy + (2 if k != 1 else -3) * u), (9 + 3 * (k % 2)) * u, Color(1, 1, 1, 0.9))
	# uzak ağaçlar
	for i in 11:
		var tx := sz.x * (i / 10.0) + (8 if i % 2 else -6) * u
		var tr := (20 + (i * 7) % 11) * u
		area.draw_circle(Vector2(tx, hz - tr * 0.3), tr, Color("6aa756") if i % 2 else Color("5c9a4b"))
	area.draw_polygon([Vector2(0, hz), Vector2(sz.x, hz), Vector2(sz.x, sz.y), Vector2(0, sz.y)],
		[Color("98cc72"), Color("98cc72"), Color("78b257"), Color("78b257")])
	# göl: kıyı taşları, sonra derinleşen su
	area.draw_colored_polygon(_ellipse(c + Vector2(0, 3 * u), r + Vector2(9, 8) * u), Color("cdbb8a"))
	var layers := 6
	for i in layers:
		var t := float(i) / (layers - 1)
		var rr := r * (1.0 - t * 0.6)
		var cc := c + Vector2(0, r.y * 0.12 * t)
		area.draw_colored_polygon(_ellipse(cc, rr, 48), Color("86cfdc").lerp(Color("2f7f9c"), t))
	# gökyüzü yansıması (uzak kıyı)
	var refl := _ellipse(c - Vector2(0, r.y * 0.55), Vector2(r.x * 0.7, r.y * 0.22), 32)
	area.draw_colored_polygon(refl, Color(1, 1, 1, 0.12))
	var rim := _ellipse(c, r, 48)
	rim.append(rim[0])
	area.draw_polyline(rim, Color("3f6f5a"), 2.5 * u, true)
	# parıltılar
	for i in 6:
		var f := Vector2(-0.6 + i * 0.24, -0.35 + 0.13 * ((i * 5) % 6))
		var p := _pp(g, f) + Vector2(sin(_t * 0.7 + i) * 6 * u, 0)
		var a := 0.25 + 0.2 * sin(_t * 1.3 + i * 2.0)
		area.draw_line(p - Vector2(9 * u, 0), p + Vector2(9 * u, 0), Color(1, 1, 1, a), 2 * u)
	# nilüferler
	for pd in PADS:
		_draw_pad(_pp(g, Vector2(pd[0], pd[1])), 15 * u * pd[2], pd[3], u, pd[0] * 3.0)
	# ördekler (uzak kıyıda yavaşça yüzer)
	for i in 2:
		var ph := _t * 0.07 + i * 2.6
		var dx := sin(ph) * 0.55
		var dp := _pp(g, Vector2(dx, -0.66 + i * 0.12))
		_draw_duck(dp + Vector2(0, sin(_t * 2 + i) * u), (9 + i * 1.5) * u, cos(ph) < 0.0, i == 1)
	# halkalar ve damlalar
	for rp in ripples:
		var age: float = rp["age"]
		if age < 0:
			continue
		var k := 1.6 if rp["big"] else 1.0
		var rad := (5 + age * 26) * u * k
		var col := Color(1, 1, 1, 0.75 * (1.0 - age / 1.6))
		var ring := _ellipse(_pp(g, rp["p"]), Vector2(rad, rad * 0.38), 28)
		ring.append(ring[0])
		area.draw_polyline(ring, col, 2 * u, true)
	for d in drops:
		var dpos: Vector2 = _pp(g, d["p"]) + d["o"] * u
		area.draw_circle(dpos, 2.4 * u, Color(0.92, 0.98, 1.0, 1.0 - d["age"] / 0.7))
	# sazlık
	_draw_reeds(_pp(g, Vector2(-0.98, -0.25)), u, 5, 0.85)
	_draw_reeds(_pp(g, Vector2(0.95, 0.55)), u, 6, 1.15)
	# olta, misina, şamandıra
	_draw_rod_and_bobber(g)


func _draw_pad(p: Vector2, rad: float, flower: bool, u: float, rot: float) -> void:
	var pts := PackedVector2Array([p])
	var n := 22
	for i in n + 1:
		var a := rot + 0.45 + (TAU - 0.9) * i / n
		pts.append(p + Vector2(cos(a) * rad, sin(a) * rad * 0.5))
	area.draw_colored_polygon(pts, Color("5fae4f"))
	pts.append(p)
	area.draw_polyline(pts, Color("2f6b33"), 1.5 * u, true)
	for i in 3:
		var a := rot + 1.2 + i * 1.6
		area.draw_line(p, p + Vector2(cos(a) * rad * 0.7, sin(a) * rad * 0.35), Color("4b9640"), 1.2 * u)
	if flower:
		var fp := p + Vector2(rad * 0.15, -rad * 0.2)
		for i in 6:
			var a := TAU * i / 6 + 0.3
			var pe := _ellipse(fp + Vector2(cos(a) * 4.5 * u, sin(a) * 2.5 * u - 2 * u), Vector2(4, 3) * u, 10)
			area.draw_colored_polygon(pe, Color("f6a3c0"))
		area.draw_circle(fp - Vector2(0, 2 * u), 2.6 * u, Color("ffd34d"))


func _draw_duck(p: Vector2, s: float, left: bool, brown: bool) -> void:
	var dir := -1.0 if left else 1.0
	var body := Color("8a6a48") if brown else Color("fbfbf4")
	area.draw_colored_polygon(_ellipse(p + Vector2(0, s * 0.45), Vector2(s * 1.1, s * 0.22), 18), Color(0, 0, 0, 0.12))
	var pts := _ellipse(p, Vector2(s, s * 0.55), 20)
	area.draw_colored_polygon(pts, body)
	area.draw_colored_polygon([p + Vector2(-dir * s * 0.8, -s * 0.1), p + Vector2(-dir * s * 1.25, -s * 0.55),
		p + Vector2(-dir * s * 0.55, -s * 0.35)], body)
	var hp := p + Vector2(dir * s * 0.7, -s * 0.7)
	area.draw_circle(hp, s * 0.42, Color("3f7f4a") if brown else body)
	area.draw_colored_polygon([hp + Vector2(dir * s * 0.3, -s * 0.06), hp + Vector2(dir * s * 0.75, s * 0.05),
		hp + Vector2(dir * s * 0.3, s * 0.16)], Color("f2a227"))
	area.draw_circle(hp + Vector2(dir * s * 0.12, -s * 0.1), s * 0.08, UI.INK)
	area.draw_arc(p + Vector2(-dir * s * 0.1, -s * 0.05), s * 0.4, 0.2, 2.6, 8, body.darkened(0.2), s * 0.12)


func _draw_reeds(base: Vector2, u: float, n: int, k: float) -> void:
	for i in n:
		var bx := base + Vector2((i - n / 2.0) * 7 * u * k, (i % 2) * 3 * u)
		var h := (48 + (i * 13) % 26) * u * k
		var sway := sin(_t * 0.9 + i * 0.8) * 3 * u
		var top := bx + Vector2(sway + (i - n / 2.0) * 2 * u, -h)
		var mid := bx.lerp(top, 0.5) + Vector2(sway * 0.3, 0)
		area.draw_polyline([bx, mid, top], Color("4e8a3a"), 2.4 * u * k, true)
		if i % 2 == 0:
			var cat_a := bx.lerp(top, 0.62)
			var cat_b := bx.lerp(top, 0.84)
			area.draw_line(cat_a, cat_b, Color("7a4a26"), 5.5 * u * k)
			area.draw_circle(cat_a, 2.75 * u * k, Color("7a4a26"))
			area.draw_circle(cat_b, 2.75 * u * k, Color("7a4a26"))
		else:
			# yaprak
			var leaf := [bx - Vector2(1.5 * u, 0), bx + Vector2(12 * u * k + sway, -h * 0.55), bx + Vector2(3 * u, 0)]
			area.draw_colored_polygon(leaf, Color("6aa04b"))


func _draw_rod_and_bobber(g: Dictionary) -> void:
	var sz: Vector2 = g["sz"]
	var u: float = g["u"]
	var tip: Vector2 = g["tip"]
	var hand := Vector2(who.position.x + who.size.x * 0.75, sz.y - 22)
	var bend := tip + Vector2(0, 6 * u * sink)
	# olta kamışı
	area.draw_line(hand, bend, Color("6b4423"), 5 * u, true)
	area.draw_line(hand.lerp(bend, 0.5), bend, Color("8a5a30"), 3 * u, true)
	area.draw_circle(hand.lerp(bend, 0.12), 6 * u, Color("4a4a52"))
	area.draw_circle(hand.lerp(bend, 0.12), 3 * u, Color("c8ccd4"))
	# şamandıra nerede?
	var rad := 9.0 * u
	var hang := bend + Vector2(0, 34 * u)
	var water := _pp(g, bob)
	var on_water := fly >= 0.999 and hooked == ""
	var pos: Vector2
	if on_water:
		pos = water + Vector2(jiggle * 3 * u, sin(_t * 2.2) * 1.2 * u)
	else:
		pos = hang.lerp(water, fly) - Vector2(0, sin(PI * fly) * 70 * u)
	# misina (biraz sarkık)
	var ctrl := (bend + pos) / 2 + Vector2(0, 16 * u if on_water else 4 * u)
	var line := PackedVector2Array()
	for i in 13:
		var t := i / 12.0
		line.append(bend.lerp(ctrl, t).lerp(ctrl.lerp(pos, t), t))
	area.draw_polyline(line, Color(1, 1, 1, 0.85), 1.2 * u, true)
	if on_water:
		var wl := pos.y
		var cc := pos + Vector2(0, lerpf(-0.35, 0.75, sink) * rad)
		_draw_bobber_clipped(cc, rad, wl, u)
		var ring := _ellipse(Vector2(pos.x, wl), Vector2(rad * 1.3, rad * 0.4), 18)
		ring.append(ring[0])
		area.draw_polyline(ring, Color(1, 1, 1, 0.55), 1.2 * u, true)
	else:
		if hooked != "" and fly > 0.0:
			draw_catch(area, pos + Vector2(0, rad + 16 * u), 36 * u, hooked, sin(_t * 12) * 0.5 + PI * 0.5)
		_draw_bobber_clipped(pos, rad, 1e9, u)


## Daire başlangıcı c, yarıçap r; su çizgisinin (c.y + d) üstünde kalan parçası.
static func _cap(c: Vector2, r: float, d: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	if d <= -r * 0.8:
		return pts
	if d >= r * 0.8:
		for i in 24:
			var t := TAU * i / 24.0
			pts.append(c + Vector2(cos(t), sin(t)) * r)
		return pts
	var a := asin(clampf(d / r, -1.0, 1.0))
	for i in 21:
		var t := lerpf(PI - a, TAU + a, i / 20.0)
		pts.append(c + Vector2(cos(t), sin(t)) * r)
	return pts


## Şamandıra: üstü kırmızı, altı beyaz; su çizgisinin altında kalan kısım görünmez.
func _draw_bobber_clipped(c: Vector2, r: float, wl: float, u: float) -> void:
	var d := wl - c.y
	if d > -r * 1.9:
		area.draw_line(Vector2(c.x, minf(c.y - r * 0.8, wl)), Vector2(c.x, minf(c.y - r * 1.9, wl)), UI.INK, 1.6 * u)
	var white := _cap(c, r, minf(d, r * 2))
	if white.size() < 3:
		return
	area.draw_colored_polygon(white, Color("fbfbf4"))
	var red := _cap(c, r, minf(d, 0.0))
	if red.size() >= 3:
		area.draw_colored_polygon(red, Color("e2412f"))
	white.append(white[0])
	area.draw_polyline(white, UI.INK, 1.4 * u, true)


## Bir balığı (ya da ayakkabı/yosunu) ortası c, boyu L olacak şekilde çizer.
## rot: radyan döndürme (oltada sallanırken). Kart ve oltanın ucu bunu kullanır.
static func draw_catch(ci: CanvasItem, c: Vector2, L: float, kind: String, rot := 0.0, ghost := false) -> void:
	ci.draw_set_transform(c, rot, Vector2.ONE)
	match kind:
		"ayakkabi":
			_draw_shoe(ci, L * 0.72)
		"yosun":
			_draw_weed(ci, L * 0.8)
		"":
			pass
		_:
			_draw_fish(ci, L, kind, ghost)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _draw_fish(ci: CanvasItem, L: float, kind: String, ghost: bool) -> void:
	var cols := {
		"sazan": [Color("c99a3a"), Color("f2dc93")],
		"alabalik": [Color("86a585"), Color("eef1e4")],
		"kefal": [Color("7d92aa"), Color("e2e8f0")],
		"altin": [Color("f39a1e"), Color("ffd45a")],
	}
	var pair: Array = cols.get(kind, cols["sazan"])
	var body: Color = pair[0]
	var belly: Color = pair[1]
	var ink := UI.INK
	if ghost:
		body = Color(1, 1, 1, 0.35)
		belly = Color(1, 1, 1, 0.35)
		ink = Color(UI.INK, 0.35)
	var H := L * (0.24 if kind != "sazan" else 0.29)
	var x0 := -L * 0.5
	var bl := L * 0.78
	var top := PackedVector2Array()
	var bot := PackedVector2Array()
	var n := 18
	for i in n + 1:
		var s := float(i) / n
		var h := H * pow(sin(PI * (0.05 + 0.88 * s)), 0.6)
		top.append(Vector2(x0 + s * bl, -h * 0.92))
		bot.append(Vector2(x0 + s * bl, h * 1.02))
	var xb := x0 + bl
	var hb := H * pow(sin(PI * 0.93), 0.6)
	# kuyruk
	var tail := PackedVector2Array([Vector2(xb - 2, -hb * 0.7), Vector2(L * 0.5, -H * 0.85),
		Vector2(L * 0.5 - L * 0.07, 0), Vector2(L * 0.5, H * 0.85), Vector2(xb - 2, hb * 0.7)])
	ci.draw_colored_polygon(tail, body.darkened(0.08))
	tail.append(tail[0])
	ci.draw_polyline(tail, ink, maxf(1.0, L * 0.018), true)
	# sırt yüzgeci
	var fin := PackedVector2Array([Vector2(x0 + bl * 0.35, -H * 0.85), Vector2(x0 + bl * 0.5, -H * 1.35),
		Vector2(x0 + bl * 0.72, -H * 0.7)])
	ci.draw_colored_polygon(fin, body.darkened(0.12))
	fin.append(fin[0])
	ci.draw_polyline(fin, ink, maxf(1.0, L * 0.015), true)
	# gövde
	var outline := top.duplicate()
	var rb := bot.duplicate()
	rb.reverse()
	outline.append_array(rb)
	ci.draw_colored_polygon(outline, body)
	var bel := PackedVector2Array()
	for p in bot:
		bel.append(Vector2(p.x, p.y * 0.15 + H * 0.08))
	bel.reverse()
	var belly_poly := bot.duplicate()
	belly_poly.append_array(bel)
	ci.draw_colored_polygon(belly_poly, belly)
	if not ghost:
		match kind:
			"sazan":
				for i in 4:
					for j in 2:
						var sp := Vector2(x0 + bl * (0.38 + i * 0.13), (j - 0.6) * H * 0.55)
						ci.draw_arc(sp, H * 0.2, -PI * 0.5, PI * 0.5, 6, body.darkened(0.25), maxf(1.0, L * 0.012))
			"alabalik":
				ci.draw_line(Vector2(x0 + bl * 0.25, H * 0.05), Vector2(xb, 0), Color("e8829b"), H * 0.28)
				for i in 7:
					var sp := Vector2(x0 + bl * (0.3 + 0.1 * i), -H * (0.35 + 0.2 * (i % 2)))
					ci.draw_circle(sp, H * 0.07, Color("2e3b2a"))
			"kefal":
				for i in 3:
					var y := -H * (0.15 + i * 0.2)
					ci.draw_line(Vector2(x0 + bl * 0.3, y), Vector2(xb - L * 0.02, y * 0.6), body.darkened(0.25), maxf(1.0, L * 0.012))
			"altin":
				for i in 3:
					var sp := Vector2(x0 + bl * (0.45 + i * 0.18), -H * 1.25 + (i % 2) * H * 0.3)
					var k := H * 0.22
					ci.draw_colored_polygon([sp + Vector2(0, -k), sp + Vector2(k * 0.3, 0), sp + Vector2(0, k),
						sp + Vector2(-k * 0.3, 0)], Color("fff6b0"))
					ci.draw_colored_polygon([sp + Vector2(-k, 0), sp + Vector2(0, k * 0.3), sp + Vector2(k, 0),
						sp + Vector2(0, -k * 0.3)], Color("fff6b0"))
	outline.append(outline[0])
	ci.draw_polyline(outline, ink, maxf(1.2, L * 0.02), true)
	# solungaç, yanak, göz, gülümseme
	ci.draw_arc(Vector2(x0 + bl * 0.22, 0), H * 0.55, -PI * 0.35, PI * 0.35, 8, ink, maxf(1.0, L * 0.014))
	if ghost:
		return
	ci.draw_circle(Vector2(x0 + bl * 0.14, H * 0.3), H * 0.13, Color(1, 0.55, 0.6, 0.6))
	var eye := Vector2(x0 + bl * 0.11, -H * 0.22)
	ci.draw_circle(eye, H * 0.2, Color.WHITE)
	ci.draw_circle(eye + Vector2(-H * 0.04, 0), H * 0.11, UI.INK)
	ci.draw_circle(eye + Vector2(-H * 0.07, -H * 0.05), H * 0.04, Color.WHITE)
	ci.draw_arc(Vector2(x0 + L * 0.03, H * 0.12), H * 0.12, 0.2, PI * 0.8, 6, UI.INK, maxf(1.0, L * 0.014))


static func _draw_shoe(ci: CanvasItem, L: float) -> void:
	var s := L
	var up := PackedVector2Array()
	for p in [Vector2(-0.22, -0.42), Vector2(0.02, -0.42), Vector2(0.06, -0.02), Vector2(0.3, 0.05),
			Vector2(0.46, 0.16), Vector2(0.48, 0.28), Vector2(-0.24, 0.28), Vector2(-0.26, -0.1)]:
		up.append(p * s)
	ci.draw_colored_polygon(up, Color("8a5a3a"))
	var sole := PackedVector2Array()
	for p in [Vector2(-0.27, 0.26), Vector2(0.5, 0.26), Vector2(0.5, 0.36), Vector2(-0.27, 0.36)]:
		sole.append(p * s)
	ci.draw_colored_polygon(sole, Color("4a3426"))
	up.append(up[0])
	ci.draw_polyline(up, UI.INK, maxf(1.2, L * 0.02), true)
	for i in 3:
		var y := (-0.3 + i * 0.11) * s
		ci.draw_line(Vector2(-0.12 * s, y), Vector2(0.0, y + 0.06 * s), Color.WHITE, maxf(1.0, L * 0.02))
		ci.draw_line(Vector2(0.0, y), Vector2(-0.12 * s, y + 0.06 * s), Color.WHITE, maxf(1.0, L * 0.02))
	# delik ve su damlası
	ci.draw_circle(Vector2(0.3 * s, 0.17 * s), 0.035 * s, Color("3a2416"))
	ci.draw_circle(Vector2(0.4 * s, 0.44 * s), 0.03 * s, Color("8fd3ea"))
	# yosun parçası
	ci.draw_polyline([Vector2(-0.2 * s, -0.42 * s), Vector2(-0.24 * s, -0.3 * s), Vector2(-0.19 * s, -0.18 * s)],
		Color("4e9a3a"), maxf(1.5, L * 0.03))


static func _draw_weed(ci: CanvasItem, L: float) -> void:
	for i in 6:
		var pts := PackedVector2Array()
		var x := (-0.25 + i * 0.1) * L
		for k in 9:
			var t := k / 8.0
			pts.append(Vector2(x + sin(t * 6 + i) * 0.05 * L + (i - 2.5) * t * 0.04 * L, (-0.3 + t * 0.6) * L * 0.8))
		ci.draw_polyline(pts, Color("3f8a3a") if i % 2 else Color("6db24e"), maxf(2.0, L * 0.05), true)
	ci.draw_circle(Vector2(0, -0.26 * L), 0.09 * L, Color("4e9a3a"))


## Göl köşesindeki "kova": üstte tutulan balıklar (boşlar soluk),
## altta kalan olta hakları (kırmızı şamandıralar; kullanılanlar soluk).
func _draw_tally() -> void:
	var sz := tally.size
	tally.draw_style_box(UI.box(Color(1, 0.97, 0.88, 0.92), UI.INK, 2, 0), Rect2(Vector2.ZERO, sz))
	var w := (sz.x - 8) / NEED
	for i in NEED:
		var c := Vector2(4 + w * (i + 0.5), 20)
		if i < caught.size():
			draw_catch(tally, c, w * 0.82, caught[i])
		else:
			draw_catch(tally, c, w * 0.82, "sazan", 0.0, true)
	var dw := (sz.x - 16) / CASTS
	for i in CASTS:
		var c := Vector2(8 + dw * (i + 0.5), sz.y - 12)
		var left := i < casts_left
		tally.draw_circle(c, 6.5, Color("e2412f") if left else Color(0.6, 0.55, 0.5, 0.35))
		tally.draw_rect(Rect2(c.x - 6.5, c.y, 13, 1.5), Color.WHITE if left else Color(1, 1, 1, 0.3))
		tally.draw_arc(c, 6.5, 0, TAU, 16, Color(UI.INK, 1.0 if left else 0.3), 1.2, true)
