extends Minigame
## Kayıp kedi: Pamuk bahçede bir yere saklandı. Sesine göre bul.
## İlk yoklama serbest; sonra sesin geldiği yöne uymayan (ya da zaten bakılmış)
## yere dokunmak yıldızdan götürür. Seviye 3'ten sonra Pamuk iki ıskadan sonra
## bir kez yer değiştirir; seviye 5'ten sonra bahçe daha büyük.

## Saklanılacak yerler; 3 (ya da 4) sütun x 2 sıra bahçe.
const SPOTS := ["bush", "tree", "crate", "pot", "cart", "bush"]
const BIG_SPOTS := ["bush", "tree", "crate", "pot", "cart", "bush", "pot", "tree"]

var cat_spot: int
var found := false
var tried := {}
var buttons: Array = []
var level := 1
var cols := 3
var spots: Array
var misses := 0
var moved := false
## Seslere göre Pamuk'un hâlâ olabileceği yerler.
var possible: Array = []


func build() -> void:
	rated = true
	cat_spot = data["spot"]
	level = data.get("level", 1)
	spots = BIG_SPOTS if level >= 5 else SPOTS
	cols = spots.size() / 2
	cat_spot = cat_spot % spots.size()
	possible = range(spots.size())
	header("Kayıp Kedi", "Pamuk nereye saklandı? Bir yere dokun, sesi dinle.")
	var grid := GridContainer.new()
	grid.columns = cols
	grid.size_flags_horizontal = SIZE_SHRINK_CENTER
	grid.size_flags_vertical = SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 26 if cols == 3 else 12)
	grid.add_theme_constant_override("v_separation", 18)
	content.add_child(UI.spacer())
	content.add_child(grid)
	content.add_child(UI.spacer())
	var w := 110 if cols == 3 else 100
	for i in spots.size():
		var b := TextureButton.new()
		b.texture_normal = UI.tex(spots[i])
		b.ignore_texture_size = true
		b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		b.custom_minimum_size = Vector2(w, 120)
		b.pivot_offset = Vector2(w / 2.0, 60)
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
		cat.size = cat.custom_minimum_size
		cat.position = b.global_position + Vector2(b.size.x / 2 - cat.size.x / 2, -20)
		var tw := cat.create_tween()
		tw.tween_property(cat, "position:y", cat.position.y - 40, 0.25).set_trans(Tween.TRANS_BACK)
		win("Miyav! Buldun, işte Pamuk!")
		return
	misses += 1
	var careless := i not in possible
	if careless:
		mistake("", b)
	else:
		UI.shake(b)
	b.modulate = Color(1, 1, 1, 0.6)
	tried[i] = true
	if GameState.has_perk("zil") and tried.size() == 1:
		var target: TextureButton = buttons[cat_spot]
		var tw := target.create_tween().set_loops(6)
		tw.tween_property(target, "modulate", Color(1.5, 1.4, 0.7), 0.25)
		tw.tween_property(target, "modulate", Color.WHITE, 0.25)
		say("Zil sesi! Çın çın... Pamuk parlayan yerde.", UI.GOOD)
		possible = [cat_spot]
		return
	if level >= 3 and misses == 2 and not moved:
		_sneak(i)
		return
	var dir := _direction(i, cat_spot)
	possible = possible.filter(func(s): return s != i and _direction(i, s) == dir)
	if careless:
		say("Sesi dinle! Miyav sesi %s geliyor." % dir, UI.ACCENT)
	else:
		say("Burada yok. Miyav sesi %s geliyor." % dir, UI.ACCENT)
	Sfx.play("meow", -14.0, 1.15)


## Pamuk bir kez sessizce başka yere geçer; eski ipuçları geçersiz olur.
func _sneak(from: int) -> void:
	moved = true
	var options: Array = range(spots.size()).filter(func(s): return s != cat_spot and s != from)
	var fresh: Array = options.filter(func(s): return not tried.has(s))
	if not fresh.is_empty():
		options = fresh
	cat_spot = options[randi() % options.size()]
	tried.clear()
	for btn in buttons:
		btn.modulate = Color.WHITE
	buttons[from].modulate = Color(1, 1, 1, 0.6)
	tried[from] = true
	var dir := _direction(from, cat_spot)
	possible = range(spots.size()).filter(func(s): return s != from and _direction(from, s) == dir)
	say("Hışır hışır! Pamuk kaçtı. Ses şimdi %s geliyor." % dir, UI.ACCENT)
	Sfx.play("whoosh", -6.0)
	Sfx.play("meow", -12.0, 1.2)


func _direction(from: int, to: int) -> String:
	var d := Vector2(to % cols - from % cols, to / cols - from / cols)
	if absf(d.y) > absf(d.x):
		return "aşağıdan" if d.y > 0 else "yukarıdan"
	return "sağdan" if d.x > 0 else "soldan"
