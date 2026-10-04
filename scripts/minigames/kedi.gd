extends Minigame
## Kayıp kedi: Pamuk bahçede bir yere saklandı. Sesine göre bul.

## [sprite, ekrandaki konum (merkez)]
const SPOTS := [
	["bush", Vector2(85, 230)],
	["tree", Vector2(270, 220)],
	["crate", Vector2(90, 380)],
	["pot", Vector2(265, 390)],
	["cart", Vector2(95, 530)],
	["bush", Vector2(270, 540)],
]

var cat_spot: int
var found := false
var tried := {}
var buttons: Array = []


func build() -> void:
	cat_spot = data["spot"]
	header("Kayıp Kedi", "Pamuk nereye saklandı? Saklanabileceği yerlere dokun.")
	for i in SPOTS.size():
		var b := TextureButton.new()
		b.texture_normal = UI.tex(SPOTS[i][0])
		b.ignore_texture_size = true
		b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		b.size = b.texture_normal.get_size() * 0.425  # ikonlar 2x çözünürlükte
		b.position = SPOTS[i][1] - b.size / 2
		b.pressed.connect(_tap.bind(i, b))
		buttons.append(b)
		add_child(b)


func _tap(i: int, b: TextureButton) -> void:
	if found:
		return
	if i == cat_spot:
		found = true
		Sfx.play("meow")
		var cat := UI.sprite("cat", 70)
		add_child(cat)
		cat.position = b.position + Vector2(b.size.x / 2 - cat.size.x / 2, -20)
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
	var d: Vector2 = SPOTS[cat_spot][1] - SPOTS[from][1]
	if abs(d.y) > abs(d.x):
		return "aşağıdan" if d.y > 0 else "yukarıdan"
	return "sağdan" if d.x > 0 else "soldan"
