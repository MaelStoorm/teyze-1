class_name Minigame
extends Control
## Tüm mini oyunların ortak tabanı. Süre baskısı yok, yanlışta ceza yok;
## oyuncu her an çıkıp sonra devam edebilir.

signal finished(success: bool)

var data: Dictionary
var hint: Label
var content: VBoxContainer
## Yatay ekranda sol sütun: başlık ve ipucu (kayar). Geri düğmesi altında
## sabit durur; yazı büyük olsa da hep görünür.
var side: VBoxContainer
var _side_col: VBoxContainer


func setup(d: Dictionary) -> Minigame:
	data = d
	return self


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var bg := TextureRect.new()
	var grad := Gradient.new()
	grad.set_color(0, Color("a6d687"))
	grad.set_color(1, Color("7fb862"))
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	bg.texture = gt
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	bg.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(bg)
	var page := UI.page(self, 10)
	var cols := HBoxContainer.new()
	cols.size_flags_vertical = SIZE_EXPAND_FILL
	cols.add_theme_constant_override("separation", 12)
	cols.mouse_filter = MOUSE_FILTER_IGNORE
	page.add_child(cols)
	_side_col = VBoxContainer.new()
	_side_col.custom_minimum_size.x = 210 * clampf(UI.text_scale, 1.0, 1.25)
	_side_col.add_theme_constant_override("separation", 10)
	_side_col.mouse_filter = MOUSE_FILTER_IGNORE
	cols.add_child(_side_col)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_side_col.add_child(scroll)
	side = VBoxContainer.new()
	side.size_flags_horizontal = SIZE_EXPAND_FILL
	side.add_theme_constant_override("separation", 10)
	side.mouse_filter = MOUSE_FILTER_IGNORE
	scroll.add_child(side)
	content = VBoxContainer.new()
	content.size_flags_horizontal = SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	content.mouse_filter = MOUSE_FILTER_IGNORE
	cols.add_child(content)
	build()


## Alt sınıflar arayüzü burada kurar.
func build() -> void:
	pass


## Başlık + ipucu içeren üst kutu.
func header(title: String, text: String) -> PanelContainer:
	var p := PanelContainer.new()
	var v := VBoxContainer.new()
	v.add_child(UI.label(title, 26, UI.ACCENT))
	hint = UI.label(text, 20, UI.INK, true)
	hint.custom_minimum_size.y = 56
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	v.add_child(hint)
	p.add_child(v)
	side.add_child(p)
	return p


## Sol sütunda kaymayan, hep görünen bir düğme (geri düğmesinin üstünde).
func add_action(button: Button) -> void:
	button.size_flags_horizontal = SIZE_FILL
	_side_col.add_child(button)
	_side_col.move_child(button, 1)


## Sol sütunun altına "geri" düğmesi.
func add_back(button: Button) -> void:
	button.size_flags_horizontal = SIZE_FILL
	_side_col.add_child(button)


func say(text: String, color := UI.INK) -> void:
	hint.text = text
	hint.add_theme_color_override("font_color", color)


func win(text: String) -> void:
	say(text, UI.GOOD)
	mouse_filter = MOUSE_FILTER_STOP
	if not rated:
		Sfx.play("win")
		await get_tree().create_timer(1.3).timeout
		finished.emit(true)
		return
	stars = star_count()
	_show_stars(text)
	await get_tree().create_timer(STAR_TIME).timeout
	finished.emit(true)


# --- yıldızlar ---------------------------------------------------------------
# Günün işleri (rated = true) bitince 1-3 yıldız verir: hatasız üç yıldız,
# star_limit kadar hataya iki yıldız, fazlasına bir yıldız. Sıfır yıldız yok,
# oyun hep kazanılır; hata yalnızca yıldızdan götürür.

const STAR_TIME := 2.0
const STAR_LINES := ["", "Bir yıldız. Olsun, yine gel!", "İki yıldız, çok iyi!", "Üç yıldız! Maşallah!"]

var rated := false
var star_limit := 2
var stars := 3
var mistakes := 0


## Yanlış hamle: hatayı sayar, yumuşak bir ses çalar, ipucunu (ya da verilen
## düğmeyi) sallar. Oyun durmaz, ceza yok.
func mistake(text := "", node: Control = null) -> void:
	mistakes += 1
	Sfx.play("bad", -6.0)
	if text != "":
		say(text, UI.ACCENT)
	nudge(node if node != null else hint)


func star_count() -> int:
	if mistakes == 0:
		return 3
	return 2 if mistakes <= star_limit else 1


## Sessiz sallama (sesi mistake() çalar).
func nudge(node: Control) -> void:
	if node == null or not node.is_inside_tree():
		return
	var x := node.position.x
	var tw := node.create_tween()
	for d in [8, -8, 6, -6, 0]:
		tw.tween_property(node, "position:x", x + d, 0.05)


## Kazanınca yıldızları tek tek gösteren pano.
func _show_stars(text: String) -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.2, 0.12, 0.05, 0.0)
	dim.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	dim.mouse_filter = MOUSE_FILTER_STOP
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	center.mouse_filter = MOUSE_FILTER_IGNORE
	dim.add_child(center)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UI.box(UI.CREAM, UI.INK, 4, 16))
	p.custom_minimum_size.x = 400
	center.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	p.add_child(v)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	v.add_child(row)
	var icons := []
	for i in 3:
		var s := UI.sprite("yildiz", 76)
		s.custom_minimum_size = Vector2(76, 76)
		s.pivot_offset = Vector2(38, 38)
		s.scale = Vector2.ZERO
		if i >= stars:
			s.modulate = Color(0.42, 0.36, 0.3, 0.5)
		row.add_child(s)
		icons.append(s)
	var line := UI.label(STAR_LINES[stars], 26, UI.GOOD if stars == 3 else UI.ACCENT if stars == 1 else UI.INK, true)
	line.modulate.a = 0.0
	v.add_child(line)
	var sub := UI.label(text, 18, UI.INK, true)
	sub.modulate.a = 0.0
	v.add_child(sub)
	p.resized.connect(func(): p.pivot_offset = p.size / 2)
	p.scale = Vector2(0.85, 0.85)
	var tw := dim.create_tween()
	tw.tween_property(dim, "color:a", 0.45, 0.15)
	tw.parallel().tween_property(p, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for i in 3:
		tw.tween_interval(0.1)
		if i < stars:
			tw.tween_callback(Sfx.play.bind("coin", -3.0, 1.0 + 0.12 * i))
		else:
			tw.tween_callback(Sfx.play.bind("tap", -8.0, 0.8))
		tw.tween_property(icons[i], "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(Sfx.play.bind("win" if stars == 3 else "good", -2.0))
	tw.tween_property(line, "modulate:a", 1.0, 0.15)
	tw.parallel().tween_property(sub, "modulate:a", 1.0, 0.15)
