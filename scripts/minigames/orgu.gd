extends Minigame
## Örgü: Miyase Teyze'yle desene bakarak atkı örmek.
## Miyase bir desen gösterir (çizgili, zikzaklı ya da damalı). Oyuncu sıradaki
## ilmeğin rengini yumak düğmelerinden seçer; atkı ilmek ilmek uzar. Yanlış
## yumakta "ilmek kaçtı" denir ve aynı ilmek yeniden denenir (sadece sayılır,
## iki kez kaçınca Miyase doğru rengi söyler). Süre yok.
##
## setup(info): info boş olabilir. İsteğe bağlı anahtarlar:
##   "seed": int     -> desen ve renkler bu tohumla seçilir
##   "pattern": "cizgili" | "zikzak" | "dama" -> deseni zorla
##   "max_miss": int -> en çok kaç kaçan ilmekte hâlâ başarı sayılır (vars. 8)
##   "neighbor" anahtarına dokunulmaz.
## finished(true): atkı bitti, kaçan ilmek az. finished(false): atkı yine
## biter ama çok ilmek kaçtı (teselli sözüyle).

const ROWS := 4
const COLS := 6
const MAX_MISS := 8
## Yumak renkleri: ad, renk
const YARNS := [
	["Kırmızı", Color("d2453a")],
	["Sarı", Color("efc23d")],
	["Mavi", Color("4a7cc9")],
	["Yeşil", Color("5ea35f")],
	["Mor", Color("9a62c2")],
	["Beyaz", Color("f6f1e4")],
]
const PATTERNS := {
	"cizgili": "Çizgili",
	"zikzak": "Zikzaklı",
	"dama": "Damalı",
}
const INTRO := {
	"cizgili": "Gel evladım, çizgili bir atkı örelim.",
	"zikzak": "Gel evladım, zikzaklı bir atkı örelim.",
	"dama": "Gel evladım, damalı bir atkı örelim.",
}
const ROW_LINES := [
	"Aferin! Bir sıra bitti bile.",
	"Ellerine sağlık, ne düzgün ilmekler.",
	"Bak bak, nasıl da uzuyor! Son sıra kaldı.",
]
const WHO := [
	"Torunuma hediye edeceğim, çok sevinecek.",
	"Bu sana olsun evladım, boynun sıcacık olsun.",
	"Ellerine sağlık evladım, kışa hazırız.",
]

var rng := RandomNumberGenerator.new()
var pattern_id := "cizgili"
var max_miss := MAX_MISS
## Bu turdaki yumaklar (YARNS indisleri), düğme sırasıyla.
var yarns: Array = []
## pattern[r][c]: yarns içindeki indis. r = 0 en alttaki (ilk) sıra.
var pattern: Array = []
## knit[r][c]: örülen yumak indisi ya da -1.
var knit: Array = []
var cur_r := 0
var cur_c := 0
var misses := 0
var tries_here := 0
var done := false
## Son ilmeğin büyüme animasyonu.
var grow := 1.0
var grow_cell := Vector2i(-1, -1)
## Bitiş gösterisi (0..1).
var reveal := 0.0
## Animasyon hızı (test için küçültülebilir). Oyuncuya süre baskısı değildir.
var pace := 1.0
var _t := 0.0
var area: Control
var face: Control
var buttons: HBoxContainer
var progress := ""
var yarn_buttons: Array[Button] = []


func build() -> void:
	if data.has("seed"):
		rng.seed = int(data["seed"])
	else:
		rng.randomize()
	max_miss = int(data.get("max_miss", MAX_MISS))
	pattern_id = String(data.get("pattern", ""))
	if not PATTERNS.has(pattern_id):
		pattern_id = PATTERNS.keys()[rng.randi() % PATTERNS.size()]
	_make_pattern()
	header("Örgü Örme", "")
	area = Control.new()
	area.size_flags_vertical = SIZE_EXPAND_FILL
	area.size_flags_horizontal = SIZE_EXPAND_FILL
	area.mouse_filter = MOUSE_FILTER_IGNORE
	area.draw.connect(_draw_area)
	area.resized.connect(_layout)
	content.add_child(area)
	face = Portrait.new(Vector2(54, 62), false, Neighbors.get_neighbor("miyase"))
	face.mouse_filter = MOUSE_FILTER_IGNORE
	area.add_child(face)
	buttons = HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 10)
	content.add_child(buttons)
	for i in yarns.size():
		var b := _yarn_button(i)
		yarn_buttons.append(b)
		buttons.add_child(b)
	say(INTRO[pattern_id] + " Parlayan karenin yumağını seç.")
	_update_progress()


func _process(delta: float) -> void:
	_t += delta
	area.queue_redraw()


# ---------------------------------------------------------------- desen

func _make_pattern() -> void:
	# 4 yumak: desen bunların 2-3'ünü kullanır, kalanlar şaşırtmaca
	var pool := range(YARNS.size())
	_shuffle(pool)
	yarns = pool.slice(0, 4)
	pattern.clear()
	knit.clear()
	for r in ROWS:
		var row := []
		var krow := []
		for c in COLS:
			row.append(_cell(r, c))
			krow.append(-1)
		pattern.append(row)
		knit.append(krow)
	# düğmeler desendeki sırayla değil, karışık dursun
	var order := range(yarns.size())
	_shuffle(order)
	var new_yarns := []
	var remap := {}
	for k in order.size():
		new_yarns.append(yarns[order[k]])
		remap[order[k]] = k
	yarns = new_yarns
	for r in ROWS:
		for c in COLS:
			pattern[r][c] = remap[pattern[r][c]]


func _shuffle(a: Array) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = a[i]
		a[i] = a[j]
		a[j] = tmp


## Desendeki hücrenin rengi (yarns indisi, karıştırmadan önce: 0, 1, 2 kullanılır).
func _cell(r: int, c: int) -> int:
	match pattern_id:
		"zikzak":
			var z: int = [0, 1, 2, 3, 2, 1][c]
			if r == z:
				return 1
			return 0 if r < z else 2
		"dama":
			return (r + int(c / 2.0)) % 2
		_:
			return [0, 1, 2, 1][r]


func needed() -> int:
	return pattern[cur_r][cur_c]


func yarn_name(i: int) -> String:
	return YARNS[yarns[i]][0]


func yarn_color(i: int) -> Color:
	return YARNS[yarns[i]][1]


# ---------------------------------------------------------------- oyun

## Oyuncu i. yumağı seçti.
func pick(i: int) -> void:
	if done or i < 0 or i >= yarns.size():
		return
	if i != needed():
		misses += 1
		tries_here += 1
		Sfx.play("bad", -9.0, 1.15)
		_wobble(yarn_buttons[i])
		if tries_here >= 2:
			say("İlmek kaçtı! Dert etme, burası %s olacak." % yarn_name(needed()).to_lower(),
				UI.ACCENT)
			_nudge(yarn_buttons[needed()])
		else:
			say("İlmek kaçtı! Olur öyle, desene bir daha bak.", UI.ACCENT)
		_update_progress()
		return
	tries_here = 0
	knit[cur_r][cur_c] = i
	grow_cell = Vector2i(cur_c, cur_r)
	grow = 0.0
	var tw := create_tween()
	tw.tween_property(self, "grow", 1.0, 0.22 * pace).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Sfx.play("stir", -10.0, 1.3 + 0.06 * cur_c)
	cur_c += 1
	if cur_c >= COLS:
		cur_c = 0
		cur_r += 1
		if cur_r >= ROWS:
			_finish()
			return
		Sfx.play("good", -4.0)
		say(ROW_LINES[mini(cur_r - 1, ROW_LINES.size() - 1)], UI.GOOD)
	else:
		say("Güzel, devam!")
	_update_progress()


func _update_progress() -> void:
	var row := mini(cur_r + 1, ROWS)
	progress = "Sıra %d / %d   Kaçan ilmek: %d" % [row, ROWS, misses]
	if done:
		progress = "Kaçan ilmek: %d" % misses


func _finish() -> void:
	done = true
	cur_r = ROWS
	_update_progress()
	for b in yarn_buttons:
		b.disabled = true
	say("Son ilmek de tamam! Püsküllerini takalım...")
	await get_tree().create_timer(0.4 * pace).timeout
	Sfx.play("whoosh", -4.0)
	buttons.visible = false
	var tw := create_tween()
	tw.tween_property(self, "reveal", 1.0, 1.2 * pace).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tw.finished
	if misses <= max_miss:
		win("Maşallah, ne güzel atkı oldu! " + WHO[rng.randi() % WHO.size()])
	else:
		say("Birkaç ilmek kaçtı ama olsun, yine sıcacık tutar.",
			UI.INK)
		Sfx.play("good", -4.0)
		mouse_filter = MOUSE_FILTER_STOP
		await get_tree().create_timer(1.3 * pace).timeout
		finished.emit(false)


func _wobble(b: Control) -> void:
	b.pivot_offset = b.size / 2
	var tw := b.create_tween()
	for a in [0.06, -0.06, 0.03, 0.0]:
		tw.tween_property(b, "rotation", a, 0.06)


func _nudge(b: Control) -> void:
	b.pivot_offset = b.size / 2
	var tw := b.create_tween()
	for k in 2:
		tw.tween_property(b, "scale", Vector2(1.1, 1.1), 0.12)
		tw.tween_property(b, "scale", Vector2.ONE, 0.14)


# ---------------------------------------------------------------- düğmeler

func _yarn_button(i: int) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 92)
	b.size_flags_horizontal = SIZE_EXPAND_FILL
	b.pressed.connect(pick.bind(i))
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 0)
	var ball := Control.new()
	ball.custom_minimum_size = Vector2(50, 46)
	ball.size_flags_horizontal = SIZE_SHRINK_CENTER
	ball.mouse_filter = MOUSE_FILTER_IGNORE
	ball.draw.connect(func(): _draw_ball(ball, ball.size / 2, 20.0, yarn_color(i)))
	v.add_child(ball)
	var l := UI.label(yarn_name(i), 18)
	# büyük yazıda dört düğme yan yana sığsın
	l.add_theme_font_size_override("font_size", int(18 * minf(UI.text_scale, 1.2)))
	l.mouse_filter = MOUSE_FILTER_IGNORE
	v.add_child(l)
	b.add_child(v)
	return b


func _draw_ball(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	var dark := col.darkened(0.3)
	ci.draw_circle(c + Vector2(0, 2), r, Color(0, 0, 0, 0.18))
	ci.draw_circle(c, r, col)
	# iplik sarımları
	for k in 3:
		var off := Vector2(-r * 0.25 + k * r * 0.25, 0)
		ci.draw_arc(c + off, r * (0.95 - k * 0.12), -1.2 + k * 0.3, 1.0 + k * 0.3, 14, dark, 2.0)
	ci.draw_arc(c, r * 0.55, 2.2, 4.4, 10, dark, 2.0)
	ci.draw_arc(c, r, 0, TAU, 32, UI.INK, 2.0)
	ci.draw_circle(c + Vector2(-r * 0.35, -r * 0.4), r * 0.16, Color(1, 1, 1, 0.55))
	# sarkan uç
	ci.draw_polyline([c + Vector2(r * 0.7, r * 0.7), c + Vector2(r * 1.0, r * 0.95),
		c + Vector2(r * 1.15, r * 0.85)], dark, 2.0)


# ---------------------------------------------------------------- çizim

func _layout() -> void:
	if face == null:
		return
	face.position = Vector2(10, 8)


## Sol taraf: desen kartı. Sağ taraf: örülen atkı.
func _left_w() -> float:
	return area.size.x * 0.36


func _draw_area() -> void:
	var sz := area.size
	area.draw_style_box(UI.box(Color("fbe9c6"), UI.INK, 3, 0), Rect2(Vector2.ZERO, sz))
	var rv := clampf(reveal, 0.0, 1.2)
	face.modulate.a = clampf(1.0 - reveal * 1.5, 0.0, 1.0)
	if reveal < 0.66:
		_draw_pattern_card(sz, 1.0 - clampf(reveal * 1.5, 0.0, 1.0))
	_draw_scarf(sz, rv)
	# sağ üstte ilerleme
	var font := get_theme_default_font()
	var fs := int(16 * minf(UI.text_scale, 1.25))
	var tw := font.get_string_size(progress, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	area.draw_string(font, Vector2(sz.x - tw - 14, 10 + fs), progress, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UI.INK)


func _draw_pattern_card(sz: Vector2, alpha: float) -> void:
	var lw := _left_w()
	var font := get_theme_default_font()
	var fs := int(16 * minf(UI.text_scale, 1.25))
	var tx := 72.0
	var ink := Color(UI.INK, alpha)
	area.draw_string(font, Vector2(tx, 10 + fs), "Desen:", HORIZONTAL_ALIGNMENT_LEFT, lw - tx, fs, ink)
	area.draw_string(font, Vector2(tx, 14 + fs * 2.2), PATTERNS[pattern_id], HORIZONTAL_ALIGNMENT_LEFT,
		lw - tx, fs, Color(UI.ACCENT, alpha))
	var top := 78.0
	var avail_h := sz.y - top - 12
	var cp := minf((lw - 34) / COLS, (avail_h - 16) / ROWS)
	cp = maxf(cp, 8.0)
	var gw := cp * COLS
	var gh := cp * ROWS
	var ox := (lw - gw) / 2 + 4
	var card := Rect2(ox - 8, top, gw + 16, gh + 16)
	var sb := UI.box(Color(1, 1, 1, 0.85 * alpha), Color(UI.INK, alpha), 2, 0)
	sb.shadow_color = Color(0, 0, 0, 0.15 * alpha)
	area.draw_style_box(sb, card)
	var oy := top + 8
	for r in ROWS:
		for c in COLS:
			var cell := Rect2(ox + c * cp, oy + (ROWS - 1 - r) * cp, cp, cp)
			var col := yarn_color(pattern[r][c])
			var past := r < cur_r or (r == cur_r and c < cur_c)
			if past:
				col = col.lerp(Color("e8dcc4"), 0.45)
			area.draw_rect(cell.grow(-1.5), Color(col, alpha))
			area.draw_rect(cell.grow(-1.5), Color(UI.INK, 0.35 * alpha), false, 1.0)
			if past:
				# örülmüş: küçük tik
				var m := cell.get_center()
				area.draw_polyline([m + Vector2(-cp * 0.18, 0), m + Vector2(-cp * 0.04, cp * 0.14),
					m + Vector2(cp * 0.2, -cp * 0.16)], Color(UI.INK, 0.5 * alpha), 2.0)
	if not done and cur_r < ROWS:
		var cell := Rect2(ox + cur_c * cp, oy + (ROWS - 1 - cur_r) * cp, cp, cp)
		var pulse := 0.5 + 0.5 * sin(_t * 5.0)
		area.draw_rect(cell.grow(1.5 + pulse * 2.0), Color(UI.ACCENT, alpha), false, 3.0)
		# sıranın solunda ok
		var ay := cell.get_center().y
		area.draw_colored_polygon([Vector2(ox - 7, ay - 6), Vector2(ox - 7, ay + 6), Vector2(ox - 1, ay)],
			Color(UI.ACCENT, alpha))


## Atkı yerel koordinatlarda çizilir (orta nokta 0,0). Bitişte desen üç kez
## tekrar eder (Miyase gerisini tamamlar), atkı yatar ve büyür.
const STITCH_H := 0.78
const REPEAT := 5


func _draw_scarf(sz: Vector2, rv: float) -> void:
	var lw := _left_w()
	var k := clampf(rv, 0.0, 1.0)
	# normal yerleşim: sağ tarafta
	var region := Rect2(lw + 6, 10, sz.x - lw - 16, sz.y - 20)
	var cs := minf((region.size.x - 30) / COLS, (region.size.y - 40) / (ROWS * STITCH_H + 0.5))
	var c1 := region.get_center() + Vector2(0, cs * 0.2)
	# bitiş: ortada, yatay ve uzun
	var full_len := ROWS * REPEAT * STITCH_H + 1.4  # püsküller dahil, ilmek birimi
	var cs2 := minf((sz.x - 70) / full_len, (sz.y - 90) / COLS)
	var center := c1.lerp(sz / 2, k)
	cs = lerpf(cs, cs2, k)
	var ch := cs * STITCH_H
	var w := cs * COLS
	var h := ch * ROWS
	area.draw_set_transform(center, lerpf(0.0, -PI / 2, k), Vector2.ONE)
	var o := Vector2(-w / 2, -h / 2)
	var extra := 0.0  # bitişte eklenen tekrarların görünürlüğü
	if rv > 0.0:
		extra = clampf(rv * 2.0 - 0.6, 0.0, 1.0)
	var span := 1 if rv <= 0.0 else (REPEAT - 1) / 2  # ortadakinin iki yanına
	# kumaş zemini (örülen kısım)
	var rows_done := mini(cur_r + (1 if cur_c > 0 else 0), ROWS)
	if rows_done > 0:
		var fab := Rect2(o.x - 4, o.y + (ROWS - rows_done) * ch - 3, w + 8, rows_done * ch + 6)
		if extra > 0.0:
			fab = Rect2(o.x - 4, o.y - span * h * extra - 3, w + 8, h + 2 * span * h * extra + 6)
		var sb := UI.box(Color("efe2c8"), UI.INK, 2, 0)
		sb.set_corner_radius_all(int(cs * 0.18))
		area.draw_style_box(sb, fab)
	# püsküller (bitişte, iki uçta)
	if extra > 0.0:
		var top := o.y - span * h - 2
		var bot := o.y + h + span * h + 2
		var ln := cs * 0.7 * extra
		for c in COLS * 2 + 1:
			var x := o.x + c * (w / (COLS * 2))
			var ci := mini(int(c / 2.0), COLS - 1)
			var sway := sin(_t * 2.0 + c) * 2.0
			var wdt := maxf(3.0, cs * 0.09)
			area.draw_line(Vector2(x, bot), Vector2(x + sway, bot + ln), Color(yarn_color(knit[0][ci]), extra), wdt)
			area.draw_line(Vector2(x, top), Vector2(x - sway, top - ln),
				Color(yarn_color(knit[ROWS - 1][ci]), extra), wdt)
	# ilmekler (bitişte üstüne ve altına tekrarları)
	for blk in range(-span, span + 1):
		if blk != 0 and extra <= 0.0:
			continue
		var alpha := 1.0 if blk == 0 else extra
		for r in ROWS:
			for c in COLS:
				var cell := Rect2(o.x + c * cs, o.y + (ROWS - 1 - r) * ch - blk * h, cs, ch)
				var kn: int = knit[r][c]
				if kn >= 0:
					var g := grow if blk == 0 and Vector2i(c, r) == grow_cell else 1.0
					_draw_stitch(cell.get_center(), cs * g, ch * g, yarn_color(kn), alpha)
				elif rv <= 0.0:
					area.draw_arc(cell.get_center(), cs * 0.12, 0, TAU, 12, Color(UI.INK, 0.18), 1.5)
	if not done:
		# şişler ve sıradaki ilmek
		var cur := Rect2(o.x + cur_c * cs, o.y + (ROWS - 1 - cur_r) * ch, cs, ch)
		var pulse := 0.5 + 0.5 * sin(_t * 5.0)
		var hl := UI.box(Color(1, 1, 1, 0.0), Color(UI.ACCENT, 0.6 + 0.4 * pulse), 3, 0)
		hl.shadow_size = 0
		hl.shadow_color = Color(0, 0, 0, 0)
		area.draw_style_box(hl, cur.grow(2))
		var ny := cur.position.y - 4
		var wood := Color("c98b4a")
		var knob := Color("8a4b2a")
		var nw := maxf(4.0, cs * 0.11)
		var lend := Vector2(o.x - cs * 0.55, ny - cs * 0.1)
		var rend := Vector2(o.x + w + cs * 0.55, ny - cs * 0.1)
		area.draw_line(lend, Vector2(cur.get_center().x + cs * 0.15, ny), wood, nw)
		area.draw_line(rend, Vector2(cur.get_center().x - cs * 0.15, ny), wood, nw)
		area.draw_circle(lend, nw * 1.4, knob)
		area.draw_circle(rend, nw * 1.4, knob)
	area.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if done:
		var lenpx := h * (1 + 2 * span * extra)
		var bb := Rect2(center - Vector2(lerpf(w, lenpx, k), lerpf(h, w, k)) / 2,
			Vector2(lerpf(w, lenpx, k), lerpf(h, w, k)))
		_draw_sparkles(bb, rv)


## Tek ilmek: iki eğik "yaprak"tan oluşan V.
func _draw_stitch(c: Vector2, w: float, h: float, col: Color, alpha := 1.0) -> void:
	if w < 1.0:
		return
	var dark := Color(col.darkened(0.35), alpha)
	var top_y := c.y - h * 0.5
	var bot_y := c.y + h * 0.5
	var l := _leaf(Vector2(c.x - w * 0.42, top_y), Vector2(c.x - w * 0.02, bot_y), w * 0.19)
	var r := _leaf(Vector2(c.x + w * 0.42, top_y), Vector2(c.x + w * 0.02, bot_y), w * 0.19)
	for p in [l, r]:
		area.draw_colored_polygon(p, Color(col, alpha))
		var outline: PackedVector2Array = p.duplicate()
		outline.append(p[0])
		area.draw_polyline(outline, dark, maxf(1.2, w * 0.04))
	# ışık
	area.draw_line(Vector2(c.x - w * 0.32, top_y + h * 0.2), Vector2(c.x - w * 0.17, c.y + h * 0.08),
		Color(1, 1, 1, 0.35 * alpha), maxf(1.5, w * 0.05))
	area.draw_line(Vector2(c.x + w * 0.2, top_y + h * 0.2), Vector2(c.x + w * 0.1, c.y),
		Color(1, 1, 1, 0.25 * alpha), maxf(1.5, w * 0.04))


func _leaf(a: Vector2, b: Vector2, bulge: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var d := (b - a).normalized()
	var perp := Vector2(-d.y, d.x)
	var n := 10
	for i in n + 1:
		var t := float(i) / n
		pts.append(a.lerp(b, t) + perp * sin(t * PI) * bulge)
	for i in range(n - 1, 0, -1):
		var t := float(i) / n
		pts.append(a.lerp(b, t) - perp * sin(t * PI) * bulge)
	return pts


func _draw_sparkles(r: Rect2, rv: float) -> void:
	var a := clampf(rv, 0.0, 1.0)
	for k in 8:
		var ang := TAU * k / 8.0 + _t * 0.3
		var rad := r.size * 0.5 + Vector2(18, 18)
		var p := r.get_center() + Vector2(cos(ang) * rad.x, sin(ang) * rad.y)
		var s := (5.0 + 3.0 * sin(_t * 4.0 + k)) * a
		var col := Color(1.0, 0.85, 0.3, a)
		area.draw_colored_polygon([p + Vector2(0, -s * 1.8), p + Vector2(s * 0.5, -s * 0.5),
			p + Vector2(s * 1.8, 0), p + Vector2(s * 0.5, s * 0.5), p + Vector2(0, s * 1.8),
			p + Vector2(-s * 0.5, s * 0.5), p + Vector2(-s * 1.8, 0), p + Vector2(-s * 0.5, -s * 0.5)], col)
