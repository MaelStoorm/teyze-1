extends Minigame
## Çay demleme: çaydanlığa su koy, demliğe çay koy, demliği üstüne koy,
## demlenmesini bekle; sonra ince belli bardağa tavşan kanı çay doldur.
## Süre yok: "Demlendi mi?" diye sorarak beklenir, bardak istenen renkte değilse
## boşaltıp yeniden doldurulur.
##
## setup(info): info boş olabilir; "neighbor" anahtarı varsa dokunulmaz.
## finished(true): çay hazır (bu oyunda kaybetmek yok).

enum { SU, YAPRAK, DOK, USTUNE, DEMLEN, BARDAK, DOLDUR, BITTI }

const DEM := 0.3  ## bardağa önce konan demin seviyesi
const BAND_LO := 0.72  ## tavşan kanı aralığı (bardak seviyesi)
const BAND_HI := 0.88
const POUR_SPEED := 0.1  ## saniyede bardak seviyesi
const STEEP_LINES := [
	"Daha yeni koyduk evladım. Biraz daha bekleyelim, acelemiz yok.",
	"Kokusu çıkmaya başladı. Az kaldı, bir daha bak.",
]
const LEAF_OPTIONS := [[1, "1 kaşık"], [3, "3 kaşık"], [8, "8 kaşık"]]

var stage := SU
var kettle_water := 0.0
var dem_water := 0.0
var leaves := 0
var on_top := 0.0  ## 0: demlik yanda, 1: çaydanlığın üstünde
var steep := 0
var level := 0.0  ## bardaktaki çay seviyesi (0..1)
var pouring := false
var _t := 0.0
var scene: Control
var buttons: HBoxContainer
var empty_button: Button
var fill_button: Button


func build() -> void:
	header("Çay Demleme", "")
	scene = Control.new()
	scene.size_flags_vertical = SIZE_EXPAND_FILL
	scene.size_flags_horizontal = SIZE_EXPAND_FILL
	scene.mouse_filter = MOUSE_FILTER_IGNORE
	scene.draw.connect(_draw_scene)
	content.add_child(scene)
	buttons = HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 10)
	content.add_child(buttons)
	_enter(SU)


func _process(delta: float) -> void:
	_t += delta
	if pouring and stage == DOLDUR:
		level = minf(level + POUR_SPEED * delta, 1.0)
		if level >= 1.0:
			stop_pour()
	scene.queue_redraw()


# ---------------------------------------------------------------- adımlar

func _clear_buttons() -> void:
	for c in buttons.get_children():
		c.queue_free()


func _add_button(text: String, cb: Callable) -> Button:
	var b := UI.button(text, cb, 22)
	# büyük yazıda yan yana üç düğme de sığsın
	b.add_theme_font_size_override("font_size", int(22 * minf(UI.text_scale, 1.1)))
	b.clip_text = true
	b.custom_minimum_size = Vector2(0, 64)
	b.size_flags_horizontal = SIZE_EXPAND_FILL
	buttons.add_child(b)
	return b


func _enter(s: int) -> void:
	stage = s
	_clear_buttons()
	match s:
		SU:
			say("Önce çaydanlığa su koyalım evladım.")
			_add_button("Su koy", add_water)
		YAPRAK:
			say("Su ısınıyor. Demliğe kaç kaşık kuru çay koyalım?")
			for o in LEAF_OPTIONS:
				_add_button(o[1], choose_leaves.bind(o[0]))
		DOK:
			say("Su kaynadı! Biraz kaynar suyu demliğe dök.")
			_add_button("Kaynar su dök", pour_hot_water)
		USTUNE:
			say("Şimdi demliği çaydanlığın üstüne koy.")
			_add_button("Üstüne koy", put_on_top)
		DEMLEN:
			say("Demlensin bakalım. Hazır olunca sor.")
			_add_button("Demlendi mi?", check_steep)
		BARDAK:
			say("Oldu! Yapraklar dibe çöktü, çay demlendi. İnce belli bardağa önce dem koyalım.")
			_add_button("Dem koy", pour_dem)
		DOLDUR:
			say("Şimdi üstüne su ekle: \"Doldur\" düğmesine basılı tut, yeşil çizgiye gelince bırak.")
			fill_button = _add_button("Doldur", func(): pass)
			fill_button.button_down.connect(start_pour)
			fill_button.button_up.connect(stop_pour)
			empty_button = _add_button("Bardağı boşalt", empty_glass)
			empty_button.visible = false


func add_water() -> void:
	if stage != SU:
		return
	_clear_buttons()
	Sfx.play("whoosh", -4.0, 0.8)
	var tw := create_tween()
	tw.tween_property(self, "kettle_water", 1.0, 0.9)
	await tw.finished
	Sfx.play("good", -2.0)
	_enter(YAPRAK)


func choose_leaves(n: int) -> void:
	if stage != YAPRAK:
		return
	if n < 3:
		say("Bu kadar azla çay açık olur evladım. Biraz daha koyalım.", UI.ACCENT)
		Sfx.play("tap", -4.0)
		return
	if n > 3:
		say("Aman, o kadar çok olursa acı olur! Daha az koyalım.", UI.ACCENT)
		Sfx.play("tap", -4.0)
		return
	leaves = n
	Sfx.play("good", -2.0)
	_enter(DOK)


func pour_hot_water() -> void:
	if stage != DOK:
		return
	_clear_buttons()
	Sfx.play("whoosh", -4.0, 1.1)
	var tw := create_tween().set_parallel()
	tw.tween_property(self, "dem_water", 1.0, 0.9)
	tw.tween_property(self, "kettle_water", 0.6, 0.9)
	await tw.finished
	_enter(USTUNE)


func put_on_top() -> void:
	if stage != USTUNE:
		return
	_clear_buttons()
	Sfx.play("whoosh", -6.0)
	var tw := create_tween()
	tw.tween_property(self, "on_top", 1.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished
	Sfx.play("tap")
	_enter(DEMLEN)


## "Demlendi mi?" Her soruşta biraz daha demlenir; üçüncüde hazırdır.
func check_steep() -> void:
	if stage != DEMLEN:
		return
	steep += 1
	if steep <= STEEP_LINES.size():
		say(STEEP_LINES[steep - 1])
		return
	Sfx.play("good")
	_enter(BARDAK)


func pour_dem() -> void:
	if stage != BARDAK:
		return
	_clear_buttons()
	Sfx.play("whoosh", -6.0, 1.3)
	var tw := create_tween()
	tw.tween_property(self, "level", DEM, 0.8)
	await tw.finished
	_enter(DOLDUR)


func start_pour() -> void:
	if stage != DOLDUR:
		return
	if level >= BAND_HI:
		_too_light()
		return
	pouring = true
	Sfx.play("stir", -6.0, 1.4)


func stop_pour() -> void:
	if not pouring:
		return
	pouring = false
	if level < BAND_LO:
		say("Biraz koyu oldu. Biraz daha su ekle, basılı tut.")
	elif level <= BAND_HI:
		stage = BITTI
		_clear_buttons()
		win("Tam tavşan kanı! Ellerine sağlık, mis gibi çay oldu.")
	else:
		_too_light()


func _too_light() -> void:
	say("Bu biraz açık oldu evladım. Bardağı boşaltıp yeniden dolduralım.", UI.ACCENT)
	fill_button.visible = false
	empty_button.visible = true


func empty_glass() -> void:
	if stage != DOLDUR:
		return
	pouring = false
	empty_button.visible = false
	level = 0.0
	_enter(BARDAK)
	say("Boşalttık. Bardağa yine önce dem koyalım.")


# ---------------------------------------------------------------- çizim

## Bardaktaki çayın rengi: seviye arttıkça açılır.
static func tea_color(lv: float) -> Color:
	var t := clampf((lv - DEM) / (1.0 - DEM), 0.0, 1.0)
	var dark := Color("3a0e05")
	var mid := Color("b0361a")  # tavşan kanı
	var light := Color("eab062")
	var m := (BAND_LO + BAND_HI) / 2.0
	var tm := (m - DEM) / (1.0 - DEM)
	if t < tm:
		return dark.lerp(mid, t / tm)
	return mid.lerp(light, (t - tm) / (1.0 - tm))


func _draw_scene() -> void:
	var sz := scene.size
	scene.draw_style_box(UI.box(Color("fbe9c6"), UI.INK, 3, 0), Rect2(Vector2.ZERO, sz))
	# tezgâh
	scene.draw_rect(Rect2(3, sz.y * 0.82, sz.x - 6, sz.y * 0.18 - 3), Color("c9915a"))
	scene.draw_line(Vector2(3, sz.y * 0.82), Vector2(sz.x - 3, sz.y * 0.82), UI.INK, 2)
	if stage >= BARDAK:
		_draw_glasses(sz)
	else:
		_draw_stove(sz)


func _draw_stove(sz: Vector2) -> void:
	var u := minf(sz.x / 430.0, sz.y / 300.0)
	var base_y := sz.y * 0.82
	var cx := sz.x * 0.4
	# ocak
	var stove := Rect2(cx - 90 * u, base_y - 26 * u, 180 * u, 26 * u)
	scene.draw_style_box(UI.box(Color("4a4a52"), UI.INK, 2, 0), stove)
	var burner_y := stove.position.y
	if kettle_water > 0.0:
		for i in 5:
			var fx := cx + (i - 2) * 14 * u
			var fh := (10 + 4 * sin(_t * 9 + i * 1.7)) * u
			scene.draw_colored_polygon([Vector2(fx - 6 * u, burner_y), Vector2(fx + 6 * u, burner_y),
				Vector2(fx, burner_y - fh)], Color("ff9a2e"))
			scene.draw_colored_polygon([Vector2(fx - 3 * u, burner_y), Vector2(fx + 3 * u, burner_y),
				Vector2(fx, burner_y - fh * 0.6)], Color("4aa3ff"))
	# çaydanlık
	var kw := 140 * u
	var kh := 96 * u
	var kettle := Rect2(cx - kw / 2, burner_y - 6 * u - kh, kw, kh)
	_draw_pot(kettle, Color("c8ccd4"), kettle_water, Color("8fc8f0"), u, on_top < 0.5)
	# demlik: yanda ya da üstte
	var dw := 96 * u
	var dh := 66 * u
	var side_pos := Vector2(sz.x - dw - dh * 0.3 - 14 * u, base_y - dh)
	var top_pos := Vector2(cx - dw / 2, kettle.position.y - dh + 4 * u)
	var p := side_pos.lerp(top_pos, on_top)
	p.y -= sin(on_top * PI) * 30 * u
	var dem_col := Color("c97a3c").lerp(Color("5a1a08"), clampf(0.35 + steep * 0.3, 0.0, 1.0))
	if leaves > 0 and dem_water == 0.0:
		dem_col = Color("3b2a1e")
	_draw_pot(Rect2(p, Vector2(dw, dh)), Color("e9e2d4"), maxf(dem_water, 0.18 if leaves > 0 else 0.0),
		dem_col, u, true, Color("c8412f"))
	# buhar
	if kettle_water > 0.0 and stage >= DOK:
		var top_y := p.y if on_top > 0.5 else kettle.position.y
		var sx := cx if on_top > 0.5 else kettle.end.x + 6 * u
		for i in 3:
			var ph := fmod(_t * 0.6 + i / 3.0, 1.0)
			var pts := PackedVector2Array()
			for k in 8:
				var yy := maxf(top_y - 8 * u - ph * 40 * u - k * 4 * u, 6.0)
				pts.append(Vector2(sx + (i - 1) * 16 * u + sin(_t * 3 + k * 0.9 + i) * 4 * u, yy))
			scene.draw_polyline(pts, Color(1, 1, 1, 0.8 * (1.0 - ph)), 3 * u)


## Basit bir demlik/çaydanlık: gövde, ağız, kulp, kapak ve içini gösteren pencere.
func _draw_pot(r: Rect2, body: Color, fill: float, liquid: Color, u: float, lid := true,
		band := Color("3e6fb5")) -> void:
	# ağız (sol) ve kulp (sağ)
	scene.draw_colored_polygon([r.position + Vector2(8 * u, r.size.y * 0.75),
		r.position + Vector2(-r.size.x * 0.22, r.size.y * 0.1),
		r.position + Vector2(-r.size.x * 0.17, r.size.y * 0.02),
		r.position + Vector2(6 * u, r.size.y * 0.45)], body.darkened(0.15))
	scene.draw_arc(Vector2(r.end.x, r.position.y + r.size.y * 0.45), r.size.y * 0.3, -PI / 2, PI / 2, 16,
		UI.INK, 5 * u)
	var sb := UI.box(body, UI.INK, maxi(2, int(2 * u)), 0)
	sb.set_corner_radius_all(int(r.size.y * 0.35))
	sb.corner_radius_top_left = int(r.size.y * 0.18)
	sb.corner_radius_top_right = int(r.size.y * 0.18)
	scene.draw_style_box(sb, r)
	scene.draw_rect(Rect2(r.position.x + 4 * u, r.position.y + r.size.y * 0.25, r.size.x - 8 * u, 6 * u), band)
	# pencere
	var wr := Rect2(r.position.x + r.size.x * 0.3, r.position.y + r.size.y * 0.4, r.size.x * 0.4, r.size.y * 0.48)
	scene.draw_rect(wr, Color(1, 1, 1, 0.55))
	if fill > 0.0:
		var h := wr.size.y * fill
		scene.draw_rect(Rect2(wr.position.x, wr.end.y - h, wr.size.x, h), liquid)
	scene.draw_rect(wr, UI.INK, false, 2)
	if lid:
		var lr := Rect2(r.position.x + r.size.x * 0.25, r.position.y - 8 * u, r.size.x * 0.5, 10 * u)
		scene.draw_style_box(UI.box(body.darkened(0.1), UI.INK, 2, 0), lr)
		scene.draw_circle(Vector2(r.get_center().x, r.position.y - 12 * u), 6 * u, UI.INK)


## İnce belli bardağın yarı genişliği (y: 0 dip, 1 ağız).
static func _glass_hw(y: float) -> float:
	var knots := [[0.0, 0.56], [0.24, 0.72], [0.56, 0.42], [1.0, 0.82]]
	for i in knots.size() - 1:
		var a: Array = knots[i]
		var b: Array = knots[i + 1]
		if y <= b[0]:
			var t: float = (y - a[0]) / (b[0] - a[0])
			return lerpf(a[1], b[1], smoothstep(0.0, 1.0, t))
	return 0.80


func _glass_poly(c: Vector2, w: float, h: float, top: float) -> PackedVector2Array:
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	var n := 24
	for i in n + 1:
		var y := top * i / n
		var hw := _glass_hw(y) * w / 2
		var py := c.y - y * h
		right.append(Vector2(c.x + hw, py))
		left.append(Vector2(c.x - hw, py))
	left.reverse()
	right.append_array(left)
	return right


func _draw_glass(c: Vector2, w: float, h: float, lv: float, u: float) -> void:
	# tabak
	var plate := PackedVector2Array()
	for i in 32:
		var a := TAU * i / 32
		plate.append(c + Vector2(cos(a) * w * 0.85, sin(a) * 9 * u + 2 * u))
	scene.draw_colored_polygon(plate, Color("c8412f"))
	scene.draw_polyline(plate + PackedVector2Array([plate[0]]), UI.INK, 2)
	scene.draw_colored_polygon(_glass_poly(c, w, h, 1.0), Color(1, 1, 1, 0.45))
	if lv > 0.01:
		scene.draw_colored_polygon(_glass_poly(c, w, h, lv), tea_color(lv))
	var outline := _glass_poly(c, w, h, 1.0)
	outline.append(outline[0])
	scene.draw_polyline(outline, UI.INK, 2.5 * u)


func _draw_glasses(sz: Vector2) -> void:
	var u := minf(sz.x / 400.0, sz.y / 250.0)
	var base_y := sz.y * 0.86
	var gh := sz.y * 0.62
	var gw := gh * 0.5
	var c := Vector2(sz.x * 0.36, base_y)
	_draw_glass(c, gw, gh, level, u)
	# hedef işareti: tavşan kanı aralığı
	var x := c.x + gw * 0.62
	var y1 := c.y - BAND_LO * gh
	var y2 := c.y - BAND_HI * gh
	scene.draw_line(Vector2(x, y1), Vector2(x, y2), UI.GOOD, 5 * u)
	scene.draw_line(Vector2(x, y1), Vector2(x - 8 * u, y1), UI.GOOD, 4 * u)
	scene.draw_line(Vector2(x, y2), Vector2(x - 8 * u, y2), UI.GOOD, 4 * u)
	# örnek bardak
	var sc := Vector2(sz.x * 0.8, base_y)
	_draw_glass(sc, gw * 0.55, gh * 0.55, (BAND_LO + BAND_HI) / 2.0, u)
	var font := get_theme_default_font()
	var fs := int(16 * UI.text_scale)
	var label := "Tavşan kanı"
	var tw := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	scene.draw_string(font, Vector2(sc.x - tw / 2, sc.y - gh * 0.55 - 12 * u), label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UI.INK)
	if pouring:
		# çaydanlıktan akan su
		var top := c.y - gh - 18 * u
		scene.draw_line(Vector2(c.x - 4 * u, top), Vector2(c.x - 4 * u, c.y - level * gh), Color(0.75, 0.88, 1.0, 0.9), 5 * u)
	if stage == BITTI:
		for i in 3:
			var ph := fmod(_t * 0.6 + i / 3.0, 1.0)
			var pts := PackedVector2Array()
			for k in 6:
				pts.append(Vector2(c.x + (i - 1) * 12 * u + sin(_t * 3 + k + i) * 4 * u, c.y - gh - 6 * u - ph * 30 * u - k * 4 * u))
			scene.draw_polyline(pts, Color(1, 1, 1, 0.8 * (1.0 - ph)), 3 * u)
