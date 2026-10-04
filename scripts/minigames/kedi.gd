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


func build() -> void:
	cat_spot = data["spot"]
	header("Kayıp Kedi", "Pamuk nereye saklandı? Saklanabileceği yerlere dokun.")
	for i in SPOTS.size():
		var b := TextureButton.new()
		b.texture_normal = UI.tex(SPOTS[i][0])
		b.ignore_texture_size = true
		b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		b.size = b.texture_normal.get_size() * UI.PX
		b.position = SPOTS[i][1] - b.size / 2
		b.pressed.connect(_tap.bind(i, b))
		add_child(b)


func _tap(i: int, b: TextureButton) -> void:
	if found:
		return
	if i == cat_spot:
		found = true
		var cat := UI.sprite("cat")
		add_child(cat)
		cat.position = b.position + Vector2(b.size.x / 2 - cat.size.x / 2, -20)
		var tw := cat.create_tween()
		tw.tween_property(cat, "position:y", cat.position.y - 40, 0.25).set_trans(Tween.TRANS_BACK)
		win("Miyav! Buldun, işte Pamuk!")
		return
	UI.shake(b)
	b.modulate = Color(1, 1, 1, 0.6) if not tried.has(i) else b.modulate
	tried[i] = true
	say("Burada yok. Miyav sesi %s geliyor." % _direction(i), UI.ACCENT)


func _direction(from: int) -> String:
	var d: Vector2 = SPOTS[cat_spot][1] - SPOTS[from][1]
	if abs(d.y) > abs(d.x):
		return "aşağıdan" if d.y > 0 else "yukarıdan"
	return "sağdan" if d.x > 0 else "soldan"
