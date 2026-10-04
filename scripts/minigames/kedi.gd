extends Minigame
## Kayıp kedi: Pamuk bahçede bir yere saklandı. Sesine göre bul.

## Saklanılacak yerler; 3 sütun x 2 sıra bahçe.
const SPOTS := ["bush", "tree", "crate", "pot", "cart", "bush"]
const COLS := 3

var cat_spot: int
var found := false
var tried := {}
var buttons: Array = []


func build() -> void:
	cat_spot = data["spot"]
	header("Kayıp Kedi", "Pamuk nereye saklandı? Saklanabileceği yerlere dokun.")
	var grid := GridContainer.new()
	grid.columns = COLS
	grid.size_flags_horizontal = SIZE_SHRINK_CENTER
	grid.size_flags_vertical = SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 26)
	grid.add_theme_constant_override("v_separation", 18)
	content.add_child(UI.spacer())
	content.add_child(grid)
	content.add_child(UI.spacer())
	for i in SPOTS.size():
		var b := TextureButton.new()
		b.texture_normal = UI.tex(SPOTS[i])
		b.ignore_texture_size = true
		b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		b.custom_minimum_size = Vector2(110, 120)
		b.pivot_offset = Vector2(55, 60)
		b.pressed.connect(_tap.bind(i, b))
		buttons.append(b)
		grid.add_child(b)


func _tap(i: int, b: TextureButton) -> void:
	if found:
		return
	if i == cat_spot:
		found = true
		Sfx.play("meow", -5.0)
		var cat := UI.sprite("cat", 70)
		add_child(cat)
		cat.position = b.global_position + Vector2(b.size.x / 2 - cat.size.x / 2, -20)
		var tw := cat.create_tween()
		tw.tween_property(cat, "position:y", cat.position.y - 40, 0.25).set_trans(Tween.TRANS_BACK)
		win("Miyav! Buldun, işte Pamuk!")
		return
	UI.shake(b)
	b.modulate = Color(1, 1, 1, 0.6) if not tried.has(i) else b.modulate
	tried[i] = true
	if GameState.has_perk("zil") and tried.size() == 1:
		var target: TextureButton = buttons[cat_spot]
		var tw := target.create_tween().set_loops(6)
		tw.tween_property(target, "modulate", Color(1.5, 1.4, 0.7), 0.25)
		tw.tween_property(target, "modulate", Color.WHITE, 0.25)
		say("Zil sesi! Çın çın... Pamuk parlayan yerde.", UI.GOOD)
		return
	say("Burada yok. Miyav sesi %s geliyor." % _direction(i), UI.ACCENT)
	Sfx.play("meow", -14.0, 1.15)


func _direction(from: int) -> String:
	var d := Vector2(cat_spot % COLS - from % COLS, cat_spot / COLS - from / COLS)
	if absf(d.y) > absf(d.x):
		return "aşağıdan" if d.y > 0 else "yukarıdan"
	return "sağdan" if d.x > 0 else "soldan"
