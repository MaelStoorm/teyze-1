class_name Minigame
extends Control
## Tüm mini oyunların ortak tabanı. Süre baskısı yok, yanlışta ceza yok;
## oyuncu her an çıkıp sonra devam edebilir.

signal finished(success: bool)

var data: Dictionary
var hint: Label
var content: VBoxContainer
## Yatay ekranda sol sütun: başlık, ipucu ve geri düğmesi.
var side: VBoxContainer


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
	side = VBoxContainer.new()
	side.custom_minimum_size.x = 210
	side.add_theme_constant_override("separation", 10)
	side.mouse_filter = MOUSE_FILTER_IGNORE
	cols.add_child(side)
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


## Sol sütunun altına "geri" düğmesi.
func add_back(button: Button) -> void:
	side.add_child(UI.spacer())
	button.size_flags_horizontal = SIZE_FILL
	side.add_child(button)


func say(text: String, color := UI.INK) -> void:
	hint.text = text
	hint.add_theme_color_override("font_color", color)


func win(text: String) -> void:
	say(text, UI.GOOD)
	Sfx.play("win")
	mouse_filter = MOUSE_FILTER_STOP
	await get_tree().create_timer(1.3).timeout
	finished.emit(true)
