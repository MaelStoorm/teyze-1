extends Minigame
## Mantı: Hülya Teyze'yle mutfak masasında mantı yapma.
## 1) Oklavayla hamuru aç, 2) kare kare kes, 3) her kareye kıyma koy,
## 4) uçlarını birleştirip bohça gibi kapat, 5) tabağa al; sırayla yoğurt,
## tereyağlı pul biberli sos ve nane dök. Süre yok, yanlış yok: yanlış kaba
## dokununca Hülya Teyze sırayı tatlı dille hatırlatır.
##
## setup(info): info boş olabilir; hiçbir anahtar gerekmez ("neighbor"
## varsa dokunulmaz).
## finished(true): mantı hazır (bu oyunda kaybetmek yok; vazgeçmek isteyen
## dışarıdaki "geri" düğmesiyle çıkar).

enum { ACMA, KESME, KIYMA, KAPAMA, SERVIS, BITTI }

const N := 3  ## kenar başına kare sayısı (3x3 = 9 mantı)
const ROLLS := 6  ## hamuru açmak için kaç kez oklava
const STEP_NAMES := ["Aç", "Kes", "Kıyma", "Kapat", "Servis"]
const TOPPINGS := [["Yoğurt", "yoğurdu"], ["Sos", "tereyağlı sosu"], ["Nane", "naneyi"]]

const DOUGH := Color("f7e6c4")
const DOUGH_EDGE := Color("d2aa72")
const DOUGH_SHADE := Color("e9cf9f")
const MEAT := Color("9c4f37")
const MEAT_DARK := Color("6e3324")
const WOOD := Color("e5bf88")
const WOOD_EDGE := Color("b98a52")
const YOGURT := Color("fffdf3")
const SAUCE := Color("d9531e")

const LINES_START := "Gel bakalım güzelim, bugün beraber mantı yapacağız. Annemden öğrendim, şimdi de sana öğretiyorum."
const LINES_ROLL := ["Aferin, böyle bastıra bastıra.", "Oh, açılıyor bak!", "İncecik olsun, ışık geçsin içinden.",
		"Az kaldı, kolların yorulmasın.", "Maşallah, ne güzel açıyorsun!"]
const LINES_CUT := ["Bıçağı yavaşça çek, acele yok.", "Ne güzel düz kestin!", "Bir tane daha, aynı böyle.",
		"Son çizgi kaldı."]
const LINES_FILL := ["Azıcık koy, çok olursa kapanmaz.", "Tam kararında!", "Kokusu şimdiden geldi.",
		"Soğanını da rendeledim, mis gibi."]
const LINES_PINCH := ["Dört ucunu birleştir, sıkıca bastır.", "Bohça gibi oldu, ne tatlı!",
		"Bizim kızın düğününde böyle yapmıştık.", "Küçücük olanı makbul derler."]

var stage := ACMA
var busy := false
## Animasyon hızı (test için küçültülebilir). Oyuncuya süre baskısı değildir.
var pace := 1.0

var rolls := 0
var dough_r := 0.36  ## hamurun yarıçapı (kenar S'nin oranı olarak, en çok 0.5)
var squareness := 0.0  ## 0: yuvarlak, 1: köşeli tabaka
var pin_off := 0.0  ## oklavanın dikey kayması (S oranı)
var pin_alpha := 1.0
var cuts := 0
var cut_prog := [0.0, 0.0, 0.0, 0.0]
var spread := 0.0  ## kesilen karelerin birbirinden ayrılması
var filled: Array = []  ## kare başına kıyma (0..1)
var folded: Array = []  ## kare başına kapanma (0..1)
var cell_pop: Array = []  ## kare başına küçük zıplama ölçeği
var serve_t := 0.0  ## tahtadan tabağa geçiş
var topping := [0.0, 0.0, 0.0]
var next_topping := 0
var bowl_pop := [1.0, 1.0, 1.0]

var _t := 0.0
var _drag := 0.0
var _line_i := {}
var area: Control
var hulya_label: Label

# yerleşim (her çizimde yeniden hesaplanır)
var u := 1.0
var S := 200.0  ## tabaka kenarı
var bc := Vector2.ZERO  ## tahta/tabak merkezi
var right_x := 0.0
var bowl_rects: Array = []


func build() -> void:
	for i in N * N:
		filled.append(0.0)
		folded.append(0.0)
		cell_pop.append(1.0)
	header("Mantı", "")
	# Hülya Teyze'nin sözleri: küçük portresiyle
	var talk := PanelContainer.new()
	talk.add_theme_stylebox_override("panel", UI.box(Color("fde7ef"), UI.INK, 3, 8))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var face := Portrait.new(Vector2(46, 54), false, Neighbors.get_neighbor("hulya"))
	face.size_flags_vertical = SIZE_SHRINK_BEGIN
	row.add_child(face)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 0)
	var name_label := UI.label("Hülya Teyze", 15, Color("8e3b62"))
	name_label.add_theme_font_size_override("font_size", int(15 * minf(UI.text_scale, 1.2)))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	col.add_child(name_label)
	hulya_label = UI.label("", 16, UI.INK, true)
	hulya_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	col.add_child(hulya_label)
	row.add_child(col)
	talk.add_child(row)
	side.add_child(talk)

	area = Control.new()
	area.size_flags_vertical = SIZE_EXPAND_FILL
	area.size_flags_horizontal = SIZE_EXPAND_FILL
	area.mouse_filter = MOUSE_FILTER_STOP
	area.clip_contents = true
	area.draw.connect(_draw_scene)
	area.gui_input.connect(_on_input)
	content.add_child(area)
	hulya(LINES_START)
	_enter(ACMA)


func _process(delta: float) -> void:
	_t += delta
	area.queue_redraw()


func hulya(text: String) -> void:
	hulya_label.text = text


## Sıradaki cümle (listenin sonuna gelince başa döner).
func _line(key: String, lines: Array) -> String:
	var i: int = _line_i.get(key, 0)
	_line_i[key] = i + 1
	return lines[i % lines.size()]


func _enter(s: int) -> void:
	stage = s
	match s:
		ACMA:
			say("Oklavaya dokun, hamuru açalım.")
		KESME:
			say("Kesik çizgiye dokun, hamuru keselim.")
		KIYMA:
			say("Karelere dokun, kıyma koyalım.")
		KAPAMA:
			say("Kıymalı karelere dokun, kapatalım.")
		SERVIS:
			say("Kaplara sırayla dokun: 1, 2, 3.")


func _tw() -> Tween:
	return create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


# ---------------------------------------------------------------- adımlar

## 1) Oklavayı bir kez gezdir: hamur biraz büyür.
func roll() -> void:
	if stage != ACMA or busy:
		return
	busy = true
	rolls += 1
	Sfx.play("whoosh", -8.0, randf_range(0.85, 1.0))
	var target := lerpf(0.36, 0.5, float(rolls) / ROLLS)
	var tw := _tw()
	tw.tween_property(self, "pin_off", 0.22, 0.14 * pace)
	tw.parallel().tween_property(self, "dough_r", lerpf(dough_r, target, 0.5), 0.14 * pace)
	tw.tween_property(self, "pin_off", -0.22, 0.2 * pace)
	tw.parallel().tween_property(self, "dough_r", target, 0.2 * pace)
	tw.tween_property(self, "pin_off", 0.0, 0.12 * pace)
	await tw.finished
	if rolls < ROLLS:
		hulya(_line("roll", LINES_ROLL))
		busy = false
		return
	# açıldı: kenarları düzeltilip tabaka olur, oklava kalkar
	Sfx.play("good", -2.0)
	hulya("Maşallah, çarşaf gibi oldu! Kenarlarını da düzelttim, bak.")
	tw = _tw()
	tw.tween_property(self, "squareness", 1.0, 0.5 * pace)
	tw.parallel().tween_property(self, "pin_alpha", 0.0, 0.4 * pace)
	await tw.finished
	busy = false
	_enter(KESME)


## 2) Sıradaki çizgiyi kes.
func cut() -> void:
	if stage != KESME or busy or cuts >= 2 * (N - 1):
		return
	busy = true
	var k := cuts
	Sfx.play("stir", -6.0, 1.6)
	var tw := _tw()
	tw.tween_method(func(v: float): cut_prog[k] = v, 0.0, 1.0, 0.4 * pace)
	await tw.finished
	cuts += 1
	hulya(_line("cut", LINES_CUT) if cuts < 2 * (N - 1) else "Oh, ne güzel kareler oldu!")
	if cuts < 2 * (N - 1):
		busy = false
		return
	Sfx.play("good", -2.0)
	tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "spread", 1.0, 0.45 * pace)
	await tw.finished
	busy = false
	_enter(KIYMA)


## 3) i. kareye kıyma koy (doluysa en yakın boş kareye).
func fill(i: int) -> void:
	if stage != KIYMA:
		return
	i = _nearest_left(i, filled)
	if i < 0 or filled[i] > 0.0:
		return
	filled[i] = 0.01
	Sfx.play("tap", -2.0, randf_range(0.9, 1.15))
	_pop(i)
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_method(func(v: float): filled[i] = v, 0.01, 1.0, 0.3 * pace)
	var left := filled.count(0.0)
	if left == 0:
		hulya("Hepsine koyduk. Bu kıymayı kasaptan kendim seçtim.")
		await tw.finished
		Sfx.play("good", -2.0)
		_enter(KAPAMA)
	elif (N * N - left) % 3 == 1:
		hulya(_line("fill", LINES_FILL))


## 4) i. mantıyı kapat (kapalıysa en yakın açık olanı).
func pinch(i: int) -> void:
	if stage != KAPAMA:
		return
	i = _nearest_left(i, folded)
	if i < 0 or folded[i] > 0.0:
		return
	folded[i] = 0.01
	Sfx.play("good", -6.0, randf_range(1.05, 1.25))
	_pop(i)
	var tw := _tw()
	tw.tween_method(func(v: float): folded[i] = v, 0.01, 1.0, 0.35 * pace)
	var left := folded.count(0.0)
	if left == 0:
		hulya("Dokuz tane minicik bohça! Şimdi bunları haşlayalım.")
		await tw.finished
		await get_tree().create_timer(0.4 * pace).timeout
		_serve()
	elif (N * N - left) % 3 == 1:
		hulya(_line("pinch", LINES_PINCH))


func _serve() -> void:
	busy = true
	Sfx.play("whoosh", -4.0, 0.9)
	var tw := _tw()
	tw.tween_property(self, "serve_t", 1.0, 0.9 * pace)
	await tw.finished
	busy = false
	hulya("Gelsin yoğurdu, gelsin sosu! Sırayla dökelim.")
	_enter(SERVIS)


## 5) k. kaptakini dök (0 yoğurt, 1 sos, 2 nane). Sıra yanlışsa sadece hatırlatır.
func pour(k: int) -> void:
	if stage != SERVIS or busy:
		return
	if k != next_topping:
		hulya("Dur bakalım güzelim, önce %s dökelim. Sırası var." % TOPPINGS[next_topping][1])
		Sfx.play("tap", -6.0, 0.8)
		_pop_bowl(next_topping)
		return
	busy = true
	_pop_bowl(k)
	Sfx.play("stir" if k < 2 else "tap", -4.0, 1.0 + k * 0.15)
	var tw := _tw()
	tw.tween_method(func(v: float): topping[k] = v, 0.0, 1.0, 0.7 * pace)
	await tw.finished
	next_topping += 1
	busy = false
	match k:
		0:
			hulya("Sarımsaklı yoğurdu da bol koydum, sever misin?")
		1:
			hulya("Tereyağında pul biberi cızırdattım, kokusu sokağa çıktı!")
		2:
			stage = BITTI
			hulya("Ellerine sağlık! Hadi sıcak sıcak yiyelim.")
			win("Afiyet olsun! Mis gibi mantı oldu.")


func _pop(i: int) -> void:
	var tw := create_tween()
	tw.tween_method(func(v: float): cell_pop[i] = v, 1.0, 1.18, 0.08 * pace)
	tw.tween_method(func(v: float): cell_pop[i] = v, 1.18, 1.0, 0.16 * pace)


func _pop_bowl(k: int) -> void:
	var tw := create_tween()
	tw.tween_method(func(v: float): bowl_pop[k] = v, 1.0, 1.15, 0.08 * pace)
	tw.tween_method(func(v: float): bowl_pop[k] = v, 1.15, 1.0, 0.18 * pace)


## i boşsa i; değilse kalan boşlardan i'ye en yakın olan; hiç yoksa -1.
func _nearest_left(i: int, arr: Array) -> int:
	if i >= 0 and i < arr.size() and arr[i] == 0.0:
		return i
	var best := -1
	var bd := INF
	var from := cell_center(clampi(i, 0, N * N - 1))
	for j in arr.size():
		if arr[j] == 0.0:
			var d := from.distance_to(cell_center(j))
			if d < bd:
				bd = d
				best = j
	return best


# ---------------------------------------------------------------- dokunma

func _on_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		_drag = 0.0
		tap(e.position)
	elif e is InputEventMouseMotion and (e.button_mask & MOUSE_BUTTON_MASK_LEFT) and stage == ACMA:
		_drag += e.relative.length()
		if _drag > 70.0 * u:
			_drag = 0.0
			roll()


## Alandaki bir noktaya dokunma (testler de bunu çağırabilir).
func tap(p: Vector2) -> void:
	_layout()
	match stage:
		ACMA:
			roll()
		KESME:
			cut()
		KIYMA, KAPAMA:
			var sheet := Rect2(bc - Vector2(S, S) * 0.6, Vector2(S, S) * 1.2)
			if not sheet.has_point(p):
				return
			var best := 0
			for j in N * N:
				if p.distance_to(cell_center(j)) < p.distance_to(cell_center(best)):
					best = j
			if stage == KIYMA:
				fill(best)
			else:
				pinch(best)
		SERVIS:
			# sağ sütunda en yakın kap (cömert hedef)
			if p.x < right_x:
				return
			var best := 0
			for k in bowl_rects.size():
				if absf(p.y - bowl_rects[k].get_center().y) < absf(p.y - bowl_rects[best].get_center().y):
					best = k
			pour(best)


# ---------------------------------------------------------------- yerleşim

func _layout() -> void:
	var sz := area.size
	u = maxf(minf(sz.x / 420.0, sz.y / 300.0), 0.3)
	var left_w := sz.x * 0.7
	var top := _steps_h()
	S = minf(left_w * 0.78, (sz.y - top - 8 * u) / 1.24)
	bc = Vector2(left_w * 0.5 + 4 * u, top + (sz.y - top) / 2.0)
	right_x = left_w
	bowl_rects.clear()
	var slot := (sz.y - 12 * u) / 3.0
	var fs := _small_fs()
	var bw := minf(sz.x - right_x - 30 * u, (slot * 0.92 - fs - 6 * u) / 0.42)
	for k in 3:
		# kap: ağzı + gövdesi (0.42 bw) + altında adı
		var y0 := 6 * u + slot * k + (slot - 0.42 * bw - fs - 4 * u) / 2.0
		bowl_rects.append(Rect2(Vector2(right_x + (sz.x - right_x - bw) / 2.0 + 6 * u, y0 - bw * 0.145), Vector2(bw, bw * 0.5)))


func _small_fs() -> int:
	return int(15 * minf(UI.text_scale, 1.3))


func _steps_h() -> float:
	return 11.0 * maxf(u, 0.8) * 2.0 + 16 * u


func cell_center(i: int) -> Vector2:
	var cs := S / N
	var local := Vector2((i % N + 0.5) * cs - S / 2.0, (i / N + 0.5) * cs - S / 2.0)
	var on_board := bc + local * (1.0 + 0.14 * spread)
	if serve_t <= 0.0:
		return on_board
	return on_board.lerp(_plate_spot(i), smoothstep(0.0, 1.0, serve_t))


## Tabakta i. mantının yeri: biri ortada, sekizi çevresinde.
func _plate_spot(i: int) -> Vector2:
	if i == 4:
		return bc
	var j := i if i < 4 else i - 1
	var a := TAU * j / 8.0 - PI / 2.0
	return bc + Vector2(cos(a), sin(a)) * S * 0.27


# ---------------------------------------------------------------- çizim

func _draw_scene() -> void:
	_layout()
	var sz := area.size
	_draw_table(sz)
	# tahta ve plaka birbirine karışarak geçer
	if serve_t < 1.0:
		_draw_board(1.0 - serve_t)
	if serve_t > 0.0:
		_draw_plate(serve_t)
	if stage <= KESME:
		_draw_dough()
		_draw_cuts()
	if serve_t > 0.0:
		_draw_yogurt_pool()
	_draw_cells()
	if serve_t > 0.0:
		_draw_toppings()
	if pin_alpha > 0.0:
		_draw_pin()
	_draw_side_items(sz)
	_draw_steps()


func _draw_table(sz: Vector2) -> void:
	var sb := UI.box(Color("cf9a63"), UI.INK, 3, 0)
	area.draw_style_box(sb, Rect2(Vector2.ZERO, sz))
	# tahta masa: yatay kalaslar
	var plank := 46.0 * u
	var y := plank
	while y < sz.y - 4:
		area.draw_line(Vector2(4, y), Vector2(sz.x - 4, y), Color("a8733f"), 2)
		y += plank
	for i in 7:
		var gy := fmod(i * 37.0 + 11.0, sz.y - 20) + 10
		var gx := fmod(i * 113.0 + 30.0, sz.x - 80)
		area.draw_line(Vector2(gx, gy), Vector2(gx + 50 * u, gy + 2 * u), Color(0.55, 0.33, 0.15, 0.25), 2)
	# sağda kareli bez örtü
	var cloth := Rect2(right_x + 2 * u, 6 * u, sz.x - right_x - 8 * u, sz.y - 12 * u)
	var csb := StyleBoxFlat.new()
	csb.bg_color = Color("fbf3e6")
	csb.set_corner_radius_all(int(12 * u))
	csb.shadow_color = Color(0, 0, 0, 0.18)
	csb.shadow_size = int(3 * u)
	area.draw_style_box(csb, cloth)
	var cell := 16.0 * u
	var cx := cloth.position.x + 4 * u
	var ci := 0
	while cx < cloth.end.x - 4 * u:
		var w := minf(cell, cloth.end.x - 4 * u - cx)
		if ci % 2 == 0:
			area.draw_rect(Rect2(cx, cloth.position.y + 4 * u, w, cloth.size.y - 8 * u), Color(0.85, 0.3, 0.3, 0.16))
		cx += cell
		ci += 1
	var cy := cloth.position.y + 4 * u
	ci = 0
	while cy < cloth.end.y - 4 * u:
		var h := minf(cell, cloth.end.y - 4 * u - cy)
		if ci % 2 == 0:
			area.draw_rect(Rect2(cloth.position.x + 4 * u, cy, cloth.size.x - 8 * u, h), Color(0.85, 0.3, 0.3, 0.16))
		cy += cell
		ci += 1


func _draw_board(alpha: float) -> void:
	var r := Rect2(bc - Vector2(S, S) * 0.62, Vector2(S, S) * 1.24)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(WOOD, alpha)
	sb.border_color = Color(WOOD_EDGE, alpha)
	sb.set_border_width_all(int(3 * u))
	sb.set_corner_radius_all(int(S * 0.12))
	sb.corner_detail = 12
	sb.shadow_color = Color(0, 0, 0, 0.22 * alpha)
	sb.shadow_size = int(5 * u)
	sb.shadow_offset = Vector2(0, 3 * u)
	area.draw_style_box(sb, r)
	# tahtanın damarları ve un serpintisi
	for i in 5:
		var yy := r.position.y + r.size.y * (0.15 + i * 0.18)
		area.draw_line(Vector2(r.position.x + 14 * u, yy), Vector2(r.end.x - 14 * u, yy + 3 * u),
			Color(0.6, 0.4, 0.2, 0.18 * alpha), 2)
	for i in 26:
		var p := r.position + Vector2(fmod(i * 61.3, r.size.x - 16 * u) + 8 * u, fmod(i * 37.7, r.size.y - 16 * u) + 8 * u)
		area.draw_circle(p, (1.2 + fmod(i * 0.7, 1.5)) * u, Color(1, 1, 1, 0.55 * alpha))


func _draw_plate(alpha: float) -> void:
	var R := S * 0.56
	area.draw_circle(bc + Vector2(0, 4 * u), R, Color(0, 0, 0, 0.18 * alpha))
	area.draw_circle(bc, R, Color(Color("eef1f4"), alpha))
	area.draw_arc(bc, R, 0, TAU, 64, Color(Color("cfc3ad"), alpha), 2.5 * u, true)
	area.draw_arc(bc, R * 0.9, 0, TAU, 64, Color(Color("4e74b8"), alpha), 3 * u, true)
	# lale motifli kenar süsü
	for i in 12:
		var a := TAU * i / 12.0
		area.draw_circle(bc + Vector2(cos(a), sin(a)) * R * 0.95, 2.6 * u, Color(Color("4e74b8"), alpha))
	area.draw_arc(bc, R * 0.78, 0, TAU, 64, Color(Color("e8e0d0"), alpha), 1.5 * u, true)


func _draw_dough() -> void:
	var r := dough_r * S
	var size := Vector2(r, r) * 2.0
	var rect := Rect2(bc - size / 2.0, size)
	var sb := StyleBoxFlat.new()
	sb.bg_color = DOUGH
	sb.border_color = DOUGH_EDGE
	sb.set_border_width_all(maxi(2, int(2 * u)))
	sb.set_corner_radius_all(int(lerpf(r, S * 0.08, squareness)))
	sb.corner_detail = 16
	sb.anti_aliasing = true
	sb.shadow_color = Color(0.4, 0.25, 0.1, 0.25)
	sb.shadow_size = int(4 * u)
	sb.shadow_offset = Vector2(0, 2 * u)
	area.draw_style_box(sb, rect)
	# yumuşak parlaklık ve un lekeleri
	area.draw_circle(bc + Vector2(-r * 0.35, -r * 0.4), r * 0.22, Color(1, 1, 1, 0.28 * (1.0 - 0.7 * squareness)))
	area.draw_circle(bc + Vector2(-r * 0.2, -r * 0.5), r * 0.1, Color(1, 1, 1, 0.3 * (1.0 - 0.7 * squareness)))
	for i in 9:
		var a := i * 2.4
		var d := r * (0.25 + fmod(i * 0.37, 0.5))
		area.draw_circle(bc + Vector2(cos(a), sin(a)) * d, (1.5 + fmod(i * 0.9, 2.0)) * u, Color(DOUGH_SHADE, 0.9))


## Kesme çizgileri: kesilenler düz, sıradaki kesik kesik ve yanıp söner.
func _draw_cuts() -> void:
	if squareness < 1.0:
		return
	var tl := bc - Vector2(S, S) / 2.0
	for k in 2 * (N - 1):
		var vertical := k < N - 1
		var f := float(k % (N - 1) + 1) / N
		var a := tl + (Vector2(S * f, 0) if vertical else Vector2(0, S * f))
		var b := a + (Vector2(0, S) if vertical else Vector2(S, 0))
		if k == cuts and stage == KESME and cut_prog[k] == 0.0:
			var pulse := 0.55 + 0.45 * sin(_t * 5.0)
			area.draw_dashed_line(a, b, Color(Color("8a5a2b"), pulse), 3 * u, 9 * u)
		if cut_prog[k] > 0.0:
			var e: Vector2 = a.lerp(b, cut_prog[k])
			area.draw_line(a + Vector2(1, 1.5) * u, e + Vector2(1, 1.5) * u, Color(1, 1, 1, 0.6), 2 * u)
			area.draw_line(a, e, DOUGH_EDGE.darkened(0.15), 2 * u)
			if cut_prog[k] < 1.0:
				_draw_knife(e, vertical)


func _draw_knife(tip: Vector2, vertical: bool) -> void:
	var d := Vector2(0, -1) if vertical else Vector2(-1, 0)
	var n := Vector2(d.y, -d.x)
	var L := 34.0 * u
	var blade := PackedVector2Array([tip, tip + d * L + n * 7 * u, tip + d * L - n * 1 * u])
	area.draw_colored_polygon(blade, Color("d8dde4"))
	area.draw_polyline(blade + PackedVector2Array([tip]), UI.INK, 1.5 * u)
	var h0 := tip + d * L + n * 3 * u
	area.draw_line(h0, h0 + d * 24 * u, Color("7a4a26"), 8 * u)


func _draw_pin() -> void:
	var plen := S * 1.22
	var th := S * 0.12
	var c := bc + Vector2(0, pin_off * S + sin(_t * 2.4) * 2 * u * float(stage == ACMA and not busy)) \
		- Vector2(0, (1.0 - pin_alpha) * S * 0.3)
	var a := pin_alpha
	# saplar
	for sgn in [-1.0, 1.0]:
		var hr := Rect2(c + Vector2(sgn * plen / 2.0 - (th * 0.9 if sgn < 0 else 0.0), -th * 0.28), Vector2(th * 0.9, th * 0.56))
		var hs := StyleBoxFlat.new()
		hs.bg_color = Color(Color("b97a43"), a)
		hs.border_color = Color(UI.INK, a)
		hs.set_border_width_all(2)
		hs.set_corner_radius_all(int(th * 0.28))
		area.draw_style_box(hs, hr)
	var body := Rect2(c - Vector2(plen / 2.0, th / 2.0), Vector2(plen, th))
	var bs := StyleBoxFlat.new()
	bs.bg_color = Color(Color("e3b47b"), a)
	bs.border_color = Color(UI.INK, a)
	bs.set_border_width_all(2)
	bs.set_corner_radius_all(int(th / 2.0))
	bs.shadow_color = Color(0, 0, 0, 0.2 * a)
	bs.shadow_size = int(4 * u)
	bs.shadow_offset = Vector2(0, 4 * u)
	area.draw_style_box(bs, body)
	area.draw_line(body.position + Vector2(th * 0.5, th * 0.3), Vector2(body.end.x - th * 0.5, body.position.y + th * 0.3),
		Color(1, 1, 1, 0.45 * a), 2 * u)
	if stage == ACMA and not busy and rolls == 0:
		# "buraya dokun" diye küçük oklar
		var bob := sin(_t * 4.0) * 3 * u
		for sgn in [-1.0, 1.0]:
			var tip := c + Vector2(0, sgn * (th * 0.9 + 6 * u + bob))
			var w := 9 * u
			area.draw_colored_polygon([tip, tip + Vector2(-w, -sgn * w), tip + Vector2(w, -sgn * w)], Color(UI.ACCENT, a))


func _draw_cells() -> void:
	if spread <= 0.0:
		return
	var cs := S / N
	for i in N * N:
		var c := cell_center(i)
		var sc: float = cell_pop[i] * lerpf(1.0, 0.9, serve_t)
		_draw_manti(c, cs * sc, filled[i], folded[i])


## Tek mantı: kare hamur -> üstünde kıyma -> dört ucu birleşmiş bohça.
func _draw_manti(c: Vector2, cs: float, meat: float, fold: float) -> void:
	var f := smoothstep(0.0, 1.0, fold)
	var h := lerpf(cs * 0.44 * (1.0 - 0.04 * spread), cs * 0.3, f)
	var rect := Rect2(c - Vector2(h, h), Vector2(h, h) * 2.0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = DOUGH.lerp(Color("fbecd0"), f)
	sb.border_color = DOUGH_EDGE
	sb.set_border_width_all(maxi(1, int(2 * u)))
	sb.set_corner_radius_all(int(lerpf(cs * 0.08, h * 0.85, f)))
	sb.corner_detail = 10
	sb.shadow_color = Color(0.4, 0.25, 0.1, 0.22)
	sb.shadow_size = int(lerpf(2.0, 4.0, f) * u)
	sb.shadow_offset = Vector2(0, 2 * u)
	area.draw_style_box(sb, rect)
	# kıyma: kapanırken bohçanın içine girer
	var m := meat * (1.0 - f)
	if m > 0.0:
		var mr := cs * 0.16 * m
		area.draw_circle(c, mr, MEAT)
		for k in 5:
			var a := k * 1.3 + 0.4
			area.draw_circle(c + Vector2(cos(a), sin(a)) * mr * 0.5, mr * 0.22, MEAT_DARK)
		area.draw_circle(c + Vector2(-mr * 0.35, -mr * 0.35), mr * 0.2, Color("c27258"))
		area.draw_circle(c + Vector2(mr * 0.45, -mr * 0.1), mr * 0.12, Color("6f9a3c"))
	if f > 0.0:
		# dört köşe ortaya katlanır: dört yumuşak yaprak ve tepede küçük düğüm
		var edge := Color(DOUGH_EDGE, f)
		for k in 4:
			var a := TAU * k / 4.0 + PI / 4.0
			var dir := Vector2(cos(a), sin(a))
			var nrm := Vector2(-dir.y, dir.x)
			var pc := c + dir * h * 0.42 * f
			var pts := PackedVector2Array()
			for j in 20:
				var b := TAU * j / 20.0
				pts.append(pc + dir * cos(b) * h * 0.5 + nrm * sin(b) * h * 0.36)
			var shade := Color("fdf0d6") if k % 2 == 0 else Color("f6e2bd")
			area.draw_colored_polygon(pts, Color(shade, f))
			area.draw_polyline(pts + PackedVector2Array([pts[0]]), edge, maxf(1.0, 1.5 * u), true)
		area.draw_circle(c + Vector2(-h * 0.3, -h * 0.45), h * 0.12, Color(1, 1, 1, 0.5 * f))
		area.draw_circle(c, h * 0.2 * f, Color("fff4e0"))
		area.draw_arc(c, h * 0.2 * f, 0, TAU, 16, edge, maxf(1.0, 1.5 * u), true)


## Yoğurt tabağa yayılır (mantıların altından görünür).
func _draw_yogurt_pool() -> void:
	if topping[0] <= 0.0:
		return
	var t: float = topping[0]
	var R := S * 0.44
	var pts := PackedVector2Array()
	for i in 48:
		var a := TAU * i / 48.0
		var rr := R * t * (0.92 + 0.05 * sin(a * 5.0 + 1.0) + 0.03 * sin(a * 9.0))
		pts.append(bc + Vector2(cos(a), sin(a)) * rr)
	area.draw_colored_polygon(pts, YOGURT)
	area.draw_polyline(pts + PackedVector2Array([pts[0]]), Color("d9cfb8"), 2 * u, true)


## Mantıların üstüne yoğurt kaşıkları, tereyağlı pul biberli sos ve nane.
func _draw_toppings() -> void:
	var R := S * 0.42
	var cs := S / N * 0.9
	if topping[0] > 0.0:
		for i in N * N:
			var c := cell_center(i)
			var r: float = cs * 0.11 * topping[0]
			var o := c + Vector2(-cs * 0.04, -cs * 0.05)
			area.draw_circle(o, r, Color(YOGURT, 0.92))
			area.draw_circle(o + Vector2(r * 0.8, r * 0.3), r * 0.7, Color(YOGURT, 0.92))
			area.draw_circle(o + Vector2(-r * 0.5, r * 0.6), r * 0.6, Color(YOGURT, 0.92))
	if topping[1] > 0.0:
		# sos: tabağın üstünde kıvrım kıvrım damlalar
		var strokes := ceili(9 * topping[1])
		for k in strokes:
			var a0 := k * 2.4 + 0.3
			var d0 := R * (0.15 + fmod(k * 0.41, 0.7))
			var p0 := bc + Vector2(cos(a0), sin(a0)) * d0
			var dir := Vector2(cos(a0 + 1.9), sin(a0 + 1.9))
			var nrm := Vector2(-dir.y, dir.x)
			var pts := PackedVector2Array()
			for j in 9:
				var s := j / 8.0
				pts.append(p0 + dir * s * R * 0.42 + nrm * sin(s * TAU * 1.3 + k) * 5 * u)
			area.draw_polyline(pts, Color(SAUCE, 0.82), 4.5 * u, true)
			area.draw_circle(pts[0], 4 * u, Color(SAUCE, 0.85))
			area.draw_circle(pts[8], 3 * u, Color(SAUCE, 0.85))
		for i in int(30 * topping[1]):
			var a := i * 2.1
			var p := bc + Vector2(cos(a), sin(a)) * R * (0.1 + fmod(i * 0.31, 0.85))
			area.draw_circle(p, 1.6 * u, Color("8e1f0e"))
	# nane: yeşil serpinti
	if topping[2] > 0.0:
		for i in int(34 * topping[2]):
			var a := i * 2.7 + 0.5
			var p := bc + Vector2(cos(a), sin(a)) * R * (0.08 + fmod(i * 0.23, 0.85))
			area.draw_circle(p, 1.9 * u, Color("5f8a32"))


## Sağdaki bez üstünde: önce un kabı, sonra kıyma kabı, serviste üç kap.
func _draw_side_items(sz: Vector2) -> void:
	var font := get_theme_default_font()
	var fs := _small_fs()
	var cx := (right_x + sz.x) / 2.0
	var bw := minf(sz.x - right_x - 18 * u, 100 * u)
	if stage < SERVIS:
		var meat := stage == KIYMA or stage == KAPAMA
		var r := Rect2(Vector2(cx - bw / 2.0, sz.y * 0.38), Vector2(bw, bw * 0.55))
		_draw_bowl(r, MEAT if meat else Color("fbf6ea"), Color("e8a33d") if meat else Color("7fa7d9"), meat)
		if stage == KIYMA:
			# kaşık kapta duruyor
			var sp := r.get_center() + Vector2(bw * 0.1, -bw * 0.02)
			area.draw_line(sp, sp + Vector2(bw * 0.32, -bw * 0.34), Color("9aa2ad"), 5 * u)
			area.draw_circle(sp, 6 * u, Color("9aa2ad"))
		_label_at(font, fs, Vector2(cx, r.end.y + r.size.y * 0.15 + fs), "Kıyma" if meat else "Un")
		if stage == KIYMA or stage == KAPAMA:
			var arr: Array = filled if stage == KIYMA else folded
			var done := N * N - arr.count(0.0)
			_label_at(font, int(fs * 1.25), Vector2(cx, r.end.y + r.size.y * 0.15 + fs * 2.6), "%d / %d" % [done, N * N], UI.ACCENT)
		return
	for k in 3:
		var r: Rect2 = bowl_rects[k]
		var s: float = bowl_pop[k]
		r = Rect2(r.get_center() - r.size * s / 2.0, r.size * s)
		var col := [YOGURT, SAUCE, Color("6f9a3c")][k] as Color
		var rim := [Color("6f9ad1"), Color("c8412f"), Color("d6a23b")][k] as Color
		var is_next := k == next_topping and stage == SERVIS and not busy
		if is_next:
			var glow := 0.35 + 0.25 * sin(_t * 4.0)
			var g := StyleBoxFlat.new()
			g.bg_color = Color(1, 0.93, 0.55, glow)
			g.set_corner_radius_all(int(r.size.y * 0.6))
			area.draw_style_box(g, Rect2(r.position + Vector2(-6 * u, r.size.y * 0.2), r.size + Vector2(12 * u, r.size.y * 0.25 + _small_fs() + 10 * u)))
		_draw_bowl(r, col, rim, k == 2, k < next_topping)
		# sıra numarası
		var nc := r.position + Vector2(-4 * u, r.size.y * 0.5)
		area.draw_circle(nc, 11 * u, UI.GOOD if k < next_topping else (UI.ACCENT if is_next else Color("bfae95")))
		_label_at(font, int(14 * minf(UI.text_scale, 1.2)), nc + Vector2(0, 5 * u), str(k + 1), Color.WHITE)
		_label_at(font, fs, Vector2(r.get_center().x, r.get_center().y + r.size.y * 0.625 + fs), TOPPINGS[k][0])


func _draw_bowl(r: Rect2, fill_col: Color, rim: Color, speckled := false, empty := false) -> void:
	var c := r.get_center()
	var w := r.size.x / 2.0
	var h := r.size.y / 2.0
	area.draw_set_transform(Vector2.ZERO)
	# gövde: alt yarım elips
	var body := PackedVector2Array()
	for i in 21:
		var a := PI * i / 20.0
		body.append(c + Vector2(cos(a) * w, sin(a) * h * 1.25))
	area.draw_colored_polygon(body, Color("f3ede2"))
	area.draw_polyline(body, UI.INK, 2, true)
	area.draw_line(c + Vector2(-w, 0), c + Vector2(w, 0), UI.INK, 2)
	var band := PackedVector2Array()
	for i in 13:
		var a := lerpf(0.18, 0.82, i / 12.0) * PI
		band.append(c + Vector2(cos(a) * w * 0.86, sin(a) * h * 0.75))
	area.draw_polyline(band, rim, 3 * u, true)
	# ağız: elips, içinde yemek
	var top := PackedVector2Array()
	for i in 32:
		var a := TAU * i / 32.0
		top.append(c + Vector2(cos(a) * w, sin(a) * h * 0.42))
	area.draw_colored_polygon(top, Color("e6dccb"))
	if not empty:
		var inner := PackedVector2Array()
		for i in 32:
			var a := TAU * i / 32.0
			inner.append(c + Vector2(cos(a) * w * 0.84, sin(a) * h * 0.34 + h * 0.03))
		area.draw_colored_polygon(inner, fill_col)
		if speckled:
			for i in 8:
				var a := i * 2.3
				area.draw_circle(c + Vector2(cos(a) * w * 0.5, sin(a) * h * 0.18), 2 * u, fill_col.darkened(0.3))
	area.draw_polyline(top + PackedVector2Array([top[0]]), UI.INK, 2, true)


func _label_at(font: Font, fs: int, pos: Vector2, text: String, col := UI.INK) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	area.draw_string(font, Vector2(pos.x - w / 2.0, pos.y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


## Sol üstte beş küçük adım yuvarlağı.
func _draw_steps() -> void:
	var font := get_theme_default_font()
	var fs := int(13 * minf(UI.text_scale, 1.2))
	var r := 11.0 * maxf(u, 0.8)
	for k in 5:
		var p := Vector2(10 * u + r + k * (r * 2.0 + 6 * u), 10 * u + r)
		var cur := k == mini(stage, SERVIS)
		var done := k < stage
		var col := UI.GOOD if done else (UI.ACCENT if cur else Color("fbf3e6"))
		area.draw_circle(p, r + (2 * u if cur else 0.0), col)
		area.draw_arc(p, r + (2 * u if cur else 0.0), 0, TAU, 20, UI.INK, 2, true)
		_label_at(font, fs, p + Vector2(0, fs * 0.36), str(k + 1), Color.WHITE if (done or cur) else UI.INK)
	var name_fs := int(15 * minf(UI.text_scale, 1.25))
	var x0 := 10 * u + 5 * (r * 2.0 + 6 * u) + 4 * u
	area.draw_string(font, Vector2(x0, 10 * u + r + name_fs * 0.36), STEP_NAMES[mini(stage, SERVIS)],
		HORIZONTAL_ALIGNMENT_LEFT, -1, name_fs, UI.INK)
