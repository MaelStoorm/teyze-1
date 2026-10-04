extends Minigame
## Mahalle albümü: açılan anılar fotoğraf kartı gibi dizilir. Karta dokununca
## Fatma Teyze'nin notu solda okunur; kapalı kartlar ne yapılacağını söyler.

const MONTHS := ["Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran", "Temmuz",
	"Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"]

var _grid: GridContainer
var _count: Label


func build() -> void:
	var n := GameState.album.size()
	header("Mahalle Albümü", "Bir karta dokun, teyzenin notunu oku.")
	_count = UI.label("%d / %d anı" % [n, Album.CARDS.size()], 19, UI.ACCENT)
	side.add_child(_count)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = 5 if UI.text_scale < 1.2 else 4
	_grid.size_flags_horizontal = SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 10)
	_grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(_grid)
	# açılanlar önce, sonra kapalılar
	var open := Album.CARDS.filter(func(c): return GameState.album.has(c["id"]))
	var closed := Album.CARDS.filter(func(c): return not GameState.album.has(c["id"]))
	for c in open + closed:
		_grid.add_child(_card(c))


func _card(c: Dictionary) -> Control:
	var have: bool = GameState.album.has(c["id"])
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 128)
	b.size_flags_horizontal = SIZE_EXPAND_FILL
	var col := Color(c["color"])
	var bg := Color("fffaf0") if have else Color("e6ddd0")
	for st in ["normal", "hover", "pressed", "focus"]:
		var box := UI.box(bg if st != "pressed" else bg.darkened(0.08), col if have else Color("b0a594"), 4 if have else 2, 6)
		b.add_theme_stylebox_override(st, box)
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(PRESET_FULL_RECT, PRESET_MODE_MINSIZE, 6)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 2)
	v.mouse_filter = MOUSE_FILTER_IGNORE
	b.add_child(v)
	# fotoğraf: renkli zemin üstünde ikon
	var photo := PanelContainer.new()
	var ps := StyleBoxFlat.new()
	ps.bg_color = col.lightened(0.55) if have else Color("cfc5b6")
	ps.set_corner_radius_all(6)
	ps.set_content_margin_all(4)
	photo.add_theme_stylebox_override("panel", ps)
	photo.mouse_filter = MOUSE_FILTER_IGNORE
	photo.size_flags_horizontal = SIZE_SHRINK_CENTER
	if have:
		photo.add_child(UI.sprite(c["icon"], 46))
	else:
		var q := UI.label("?", 34, Color("a0957f"))
		q.custom_minimum_size = Vector2(46, 46)
		photo.add_child(q)
	v.add_child(photo)
	var t := UI.label(c["title"] if have else "Kapalı anı", 15, UI.INK if have else Color("8a7f6e"), true)
	t.mouse_filter = MOUSE_FILTER_IGNORE
	v.add_child(t)
	if have:
		var d := UI.label(_date(GameState.album[c["id"]]), 13, Color("8a6a4a"))
		d.mouse_filter = MOUSE_FILTER_IGNORE
		v.add_child(d)
	b.pressed.connect(_show.bind(c, b))
	return b


func _show(c: Dictionary, b: Control) -> void:
	Sfx.play("tap", -4.0)
	if GameState.album.has(c["id"]):
		say("%s\n\n%s" % [c["title"], c["note"]], UI.INK)
	else:
		say("Bu anı henüz kapalı.\n\n%s" % c["hint"], Color("6a5a48"))
	UI.pop(b)


func _date(iso: String) -> String:
	var p := iso.split("-")
	if p.size() != 3:
		return iso
	return "%d %s %s" % [int(p[2]), MONTHS[clampi(int(p[1]) - 1, 0, 11)], p[0]]
