class_name Props
## Mahallenin büyüyen kısmı: kahvehane, pazar tezgahları, çit, gölet, kümes,
## Sütlü'nün mama kabı ve görevlerde taşınan eşyalar.


## Pazar tezgahları: ne satarlar, kim satar.
const STALLS := {
	"manav": {"name": "Manav", "seller": "Manav Hasan", "items": ["domates", "karpuz"], "awning": "#4f9a4a",
		"look": {"gender": "erkek", "hair": 2, "hair_color": 0, "skin": 2, "top": 2, "bottom": 3, "apron": true}},
	"firin": {"name": "Fırın", "seller": "Fırıncı Mehmet", "items": ["ekmek", "simit"], "awning": "#d8452f",
		"look": {"gender": "erkek", "hair": 0, "hair_color": 1, "skin": 1, "top": 5, "bottom": 0, "apron": true, "baker": true}},
	"sarkuteri": {"name": "Şarküteri", "seller": "Zeynep Abla", "items": ["peynir", "zeytin", "yumurta"], "awning": "#3e8fb0",
		"look": {"gender": "kiz", "hair": 2, "hair_color": 2, "skin": 1, "top": 1, "bottom_style": 1, "bottom": 0, "apron": true}},
}


static func label3d(text: String, size := 64, color := Color("3b2a1e")) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.outline_size = 12
	l.outline_modulate = Color("fff4dc")
	l.modulate = color
	l.pixel_size = 0.006
	l.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	return l


## Ahmet Amca'nın kahvehanesi: tek katlı, geniş saçaklı, önünde çay masaları.
static func kahvehane() -> Node3D:
	var n := Node3D.new()
	Models.part(n, Models.box(4.2, 2.0, 2.6), "#efe3c8", Vector3(0, 1.0, 0))
	Models.part(n, Models.box(4.4, 0.25, 2.8), "#8a5a3b", Vector3(0, 2.1, 0))
	Models.part(n, Models.prism(4.6, 0.8, 3.0), "#c8553a", Vector3(0, 2.6, 0))
	for i in 9:  # tente
		Models.part(n, Models.box(0.47, 0.05, 1.2), "#8e2f2a" if i % 2 == 0 else "#f4efe6", Vector3(-1.9 + i * 0.47, 1.85, 1.75), Vector3(18, 0, 0))
	Models.part(n, Models.box(0.9, 1.4, 0.08), "#6b4a35", Vector3(0, 0.7, 1.31))  # kapı
	for x in [-1.4, 1.4]:
		Models.part(n, Models.box(1.0, 0.8, 0.06), "#9ad3e0", Vector3(x, 1.0, 1.31))
		Models.part(n, Models.box(1.1, 0.08, 0.15), "#8a5a3b", Vector3(x, 0.58, 1.36))
	var sign := label3d("KAHVEHANE", 80, Color("8e2f2a"))
	sign.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	sign.position = Vector3(0, 2.25, 1.45)
	n.add_child(sign)
	# masalar: tavla ve çay
	for x in [-1.3, 1.3]:
		var t := Vector3(x, 0, 2.9)
		Models.part(n, Models.cyl(0.4, 0.4, 0.05, 14), "#a86f48", t + Vector3(0, 0.7, 0))
		Models.part(n, Models.cyl(0.05, 0.08, 0.7, 6), "#5c3a26", t + Vector3(0, 0.35, 0))
		Models.part(n, Models.box(0.36, 0.04, 0.26), "#7a4e2a", t + Vector3(0, 0.74, 0))  # tavla
		Models.part(n, Models.box(0.32, 0.045, 0.02), "#f4efe6", t + Vector3(0, 0.75, 0))
		Models.part(n, Models.cyl(0.04, 0.03, 0.1, 8), "#c4402c", t + Vector3(0.25, 0.78, 0.12))
		for sx in [-1, 1]:
			Models.part(n, Models.cyl(0.18, 0.18, 0.05, 10), "#3e6fb5", t + Vector3(sx * 0.6, 0.42, 0))
			for k in 4:
				Models.part(n, Models.cyl(0.02, 0.02, 0.42, 4), "#5c3a26", t + Vector3(sx * 0.6 + (0.1 if k % 2 else -0.1), 0.21, 0.1 if k < 2 else -0.1))
	# semaver
	Models.part(n, Models.box(0.6, 0.8, 0.5), "#8a5a3b", Vector3(-2.5, 0.4, 1.6))
	Models.part(n, Models.cyl(0.14, 0.18, 0.35, 12), "#c9962a", Vector3(-2.5, 0.98, 1.6))
	Models.part(n, Models.ball(0.11, 10), "#d9a72e", Vector3(-2.5, 1.2, 1.6))
	return n


## Mehmet Usta'nın fırını. Hikayenin ilk bölümünde kapalıdır; açılınca
## camlar ışıldar, bacadan duman tüter. İki hali "Kapali" ve "Acik" adlı
## alt düğümlerde durur; kod görünürlüklerini değiştirir.
static func firin() -> Node3D:
	var n := Node3D.new()
	# ortak gövde: taş duvar, kırmızı kiremit, taş ocak bacası
	Models.part(n, Models.box(3.6, 2.2, 2.6), "#ecdcc0", Vector3(0, 1.1, 0))
	Models.part(n, Models.box(3.8, 0.22, 2.8), "#8a5a3b", Vector3(0, 2.3, 0))
	Models.part(n, Models.prism(4.0, 0.9, 3.0), "#c8553a", Vector3(0, 2.85, 0))
	Models.part(n, Models.box(0.7, 1.6, 0.7), "#b5a48a", Vector3(1.1, 3.2, -0.5))  # baca
	Models.part(n, Models.box(0.8, 0.12, 0.8), "#8a7a62", Vector3(1.1, 4.0, -0.5))
	for x in [-1.75, 1.75]:
		Models.part(n, Models.box(0.12, 2.2, 0.12), "#c9b796", Vector3(x, 1.1, 1.31))
	var sign := label3d("FIRIN", 110, Color("fff4dc"))  # yukarıdan bakan kameraya dönük, kırmızı çatıda okunur
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.outline_size = 26
	sign.outline_modulate = Color("5c2418")
	sign.position = Vector3(0, 2.9, 1.9)
	n.add_child(sign)

	var shut := Node3D.new()  # kapalı: tahtalar çakılı, kepenk inik, toz
	shut.name = "Kapali"
	n.add_child(shut)
	Models.part(shut, Models.box(1.0, 1.5, 0.08), "#6b5a4a", Vector3(0, 0.75, 1.32))
	for k in 2:
		Models.part(shut, Models.box(1.3, 0.14, 0.06), "#a08060", Vector3(0, 0.55 + k * 0.5, 1.38), Vector3(0, 0, 18 if k == 0 else -15))
	for x in [-1.15, 1.15]:
		Models.part(shut, Models.box(1.0, 0.9, 0.06), "#8a8070", Vector3(x, 1.15, 1.32))
		for k in 4:
			Models.part(shut, Models.box(1.0, 0.03, 0.04), "#6f665a", Vector3(x, 0.8 + k * 0.22, 1.36))
	var closed := label3d("KAPALI", 40, Color("5c4a3a"))
	closed.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	closed.position = Vector3(0, 1.75, 1.4)
	shut.add_child(closed)
	for p in [Vector3(-1.4, 0.15, 1.7), Vector3(1.5, 0.1, 1.6)]:  # yerde kuru yaprak
		Models.part(shut, Models.ball(0.12, 6), "#b08a4a", p, Vector3.ZERO, Vector3(1, 0.3, 1))

	var open := Node3D.new()  # açık: sıcak ışık, tezgahta simitler, tente, saksılar
	open.name = "Acik"
	open.visible = false
	n.add_child(open)
	Models.part(open, Models.box(1.0, 1.5, 0.08), "#8a5a3b", Vector3(0, 0.75, 1.32))
	Models.part(open, Models.box(0.6, 0.9, 0.04), "#ffe2a0", Vector3(0, 0.95, 1.37))
	for x in [-1.15, 1.15]:
		var w := Models.part(open, Models.box(1.0, 0.9, 0.06), "#ffd98a", Vector3(x, 1.15, 1.32))
		var m := StandardMaterial3D.new()
		m.albedo_color = Color("ffe2a0")
		m.emission_enabled = true
		m.emission = Color("ffb84a")
		m.emission_energy_multiplier = 0.9
		w.material_override = m
		Models.part(open, Models.box(1.1, 0.08, 0.2), "#8a5a3b", Vector3(x, 0.66, 1.4))
	for i in 9:  # tente
		Models.part(open, Models.box(0.4, 0.05, 1.0), "#d8452f" if i % 2 == 0 else "#f4efe6", Vector3(-1.6 + i * 0.4, 1.95, 1.75), Vector3(18, 0, 0))
	# önde simit tezgahı
	Models.part(open, Models.box(1.3, 0.7, 0.6), "#a86f48", Vector3(-1.1, 0.35, 2.3))
	for k in 5:
		var t := TorusMesh.new()
		t.inner_radius = 0.05
		t.outer_radius = 0.12
		t.rings = 10
		t.ring_segments = 6
		Models.part(open, t, "#c8873a", Vector3(-1.5 + k * 0.2, 0.74, 2.3 + (0.08 if k % 2 else -0.08)))
	for x in [0.9, 1.6]:
		_saksi(open, Vector3(x, 0, 1.7))
	return n


static func _saksi(n: Node3D, at: Vector3) -> void:
	Models.part(n, Models.cyl(0.18, 0.14, 0.32, 10), "#c8553a", at + Vector3(0, 0.16, 0))
	Models.part(n, Models.ball(0.22, 8), "#4f8a3a", at + Vector3(0, 0.45, 0))
	for k in 3:
		Models.part(n, Models.ball(0.06, 6), "#e04a4a", at + Vector3(cos(k * 2.1) * 0.15, 0.55, sin(k * 2.1) * 0.15))


## Pazar tezgahı: renkli tente, önde ürünler, tabela.
static func market_stall(kind: String) -> Node3D:
	var s: Dictionary = STALLS[kind]
	var n := Node3D.new()
	for x in [-1.2, 1.2]:
		for z in [-0.5, 0.5]:
			Models.part(n, Models.box(0.1, 2.0, 0.1), "#8a5a3b", Vector3(x, 1.0, z))
	Models.part(n, Models.box(2.6, 0.15, 1.2), "#a86f48", Vector3(0, 0.8, 0))
	Models.part(n, Models.box(2.5, 0.75, 0.06), "#8a5a3b", Vector3(0, 0.42, 0.56))
	for i in 9:
		Models.part(n, Models.box(0.31, 0.06, 1.5), s["awning"] if i % 2 == 0 else "#f4efe6", Vector3(-1.24 + i * 0.31, 2.1, 0.08), Vector3(14, 0, 0))
	var items: Array = s["items"]
	for i in items.size():
		var cx := -0.9 + i * (1.8 / maxf(1.0, items.size() - 1.0)) if items.size() > 1 else 0.0
		_goods(n, items[i], Vector3(cx, 0.88, 0.15))
	var sign := label3d(s["name"], 72)
	sign.position = Vector3(0, 2.75, 0.75)
	n.add_child(sign)
	return n


## Tezgahın üstündeki ürün yığınları.
static func _goods(n: Node3D, item: String, at: Vector3) -> void:
	match item:
		"domates":
			for i in 7:
				Models.part(n, Models.ball(0.1, 8), "#e04a35", at + Vector3(randf_range(-0.3, 0.3), 0.08 + (0.1 if i > 4 else 0.0), randf_range(-0.25, 0.25)))
		"karpuz":
			for i in 3:
				Models.part(n, Models.ball(0.22, 10), "#3f7a3a", at + Vector3(-0.25 + i * 0.25, 0.18, 0), Vector3.ZERO, Vector3(1, 0.85, 1.2))
			Models.part(n, Models.cyl(0.18, 0.18, 0.04, 10), "#e8505a", at + Vector3(0.1, 0.42, 0.15), Vector3(70, 0, 0))
		"ekmek":
			for i in 3:
				Models.part(n, Models.capsule(0.09, 0.42), "#d99a4e", at + Vector3(-0.25 + i * 0.25, 0.1, 0), Vector3(90, 20, 0))
		"simit":
			for i in 4:
				var t := TorusMesh.new()
				t.inner_radius = 0.06
				t.outer_radius = 0.12
				t.rings = 12
				t.ring_segments = 6
				Models.part(n, t, "#c9803f", at + Vector3(-0.2 + (i % 2) * 0.28, 0.04 + (i / 2) * 0.05, -0.1 + (i / 2) * 0.2))
		"peynir":
			Models.part(n, Models.box(0.35, 0.2, 0.25), "#f8f3e0", at + Vector3(0, 0.1, 0))
			Models.part(n, Models.box(0.2, 0.15, 0.15), "#f4e6a8", at + Vector3(0.3, 0.08, 0.1))
		"zeytin":
			Models.part(n, Models.cyl(0.2, 0.17, 0.2, 12), "#c0c6cc", at + Vector3(0, 0.1, 0))
			for i in 8:
				Models.part(n, Models.ball(0.04, 6), "#2b2a2a", at + Vector3(randf_range(-0.12, 0.12), 0.22, randf_range(-0.12, 0.12)))
		"yumurta":
			Models.part(n, Models.box(0.4, 0.06, 0.3), "#c9b48a", at + Vector3(0, 0.03, 0))
			for i in 6:
				Models.part(n, Models.ball(0.05, 8), "#fbf3e4", at + Vector3(-0.12 + (i % 3) * 0.12, 0.1, -0.06 + (i / 3) * 0.12), Vector3.ZERO, Vector3(1, 1.25, 1))


## Ahmet Amca ve pazarcılar gibi erkek/kadın esnaf: Avatar + bıyık, kasket, önlük.
static func person(look: Dictionary) -> Node3D:
	var n := Avatar.build(look)
	var body := n.get_node("Body")
	var hy := 1.24
	var r := 0.34
	if look.get("mustache", false):
		for sx in [-1, 1]:
			Models.part(body, Models.ball(0.075, 8), "#d8d2ca", Vector3(sx * 0.06, hy - r * 0.22, r * 0.93), Vector3(0, 0, sx * -15), Vector3(1.4, 0.55, 0.6))
	if look.get("cap", false):  # kasket
		Models.part(body, Models.ball(r * 1.1, 16, true), "#6b5a4a", Vector3(0, hy + r * 0.35, -r * 0.02), Vector3.ZERO, Vector3(1, 0.6, 1))
		Models.part(body, Models.cyl(r * 0.6, r * 0.6, 0.03, 12), "#6b5a4a", Vector3(0, hy + r * 0.42, r * 0.65), Vector3(-10, 0, 0), Vector3(1, 1, 0.6))
	if look.get("baker", false):  # beyaz fırıncı şapkası
		Models.part(body, Models.cyl(r * 0.85, r * 0.75, r * 0.7, 14), "#ffffff", Vector3(0, hy + r * 0.95, 0))
	if look.has("vest"):
		Models.part(body, Models.cyl(0.205, 0.235, 0.36), look["vest"], Vector3(0, 0.72, -0.02))
	if look.get("apron", false):
		Models.part(body, Models.box(0.3, 0.42, 0.04), "#ffffff", Vector3(0, 0.62, 0.21))
	return n


## Ahşap çit: bir dikdörtgenin kenarları boyunca direk ve iki sıra tahta.
static func fence(area: Rect2, gap_at := Vector2(-999, -999)) -> Node3D:
	var n := Node3D.new()
	var corners := [area.position, Vector2(area.end.x, area.position.y), area.end, Vector2(area.position.x, area.end.y)]
	for i in 4:
		var a: Vector2 = corners[i]
		var b: Vector2 = corners[(i + 1) % 4]
		var len := a.distance_to(b)
		var steps := int(len / 1.0)
		for k in steps + 1:
			var p := a.lerp(b, float(k) / steps)
			if p.distance_to(gap_at) < 0.8:
				continue
			Models.part(n, Models.box(0.1, 0.8, 0.1), "#a86f48", Vector3(p.x, 0.4, p.y))
			if k < steps:
				var q := a.lerp(b, float(k + 1) / steps)
				if q.distance_to(gap_at) < 0.8:
					continue
				var mid := (p + q) / 2.0
				var ang := atan2(q.x - p.x, q.y - p.y)
				for y in [0.35, 0.65]:
					var rail := Models.part(n, Models.box(0.06, 0.08, p.distance_to(q)), "#c48a58", Vector3(mid.x, y, mid.y))
					rail.rotation.y = ang
	return n


static func pond(radius := 2.0) -> Node3D:
	var n := Node3D.new()
	Models.part(n, Models.cyl(radius, radius, 0.06, 28), "#5fb3d6", Vector3(0, 0.02, 0), Vector3.ZERO, Vector3(1.3, 1, 1))
	Models.part(n, Models.cyl(radius * 0.7, radius * 0.7, 0.07, 24), "#7fc8e4", Vector3(0.2, 0.03, -0.1), Vector3.ZERO, Vector3(1.3, 1, 1))
	for i in 22:  # kenar taşları
		var a := TAU * i / 22.0
		Models.part(n, Models.ball(0.22, 6), "#b8b0a0" if i % 2 else "#a39b8b", Vector3(cos(a) * radius * 1.32, 0.05, sin(a) * radius * 1.02), Vector3.ZERO, Vector3(1, 0.5, 1))
	for i in 6:  # sazlar
		var a := 2.2 + i * 0.25
		for k in 3:
			Models.part(n, Models.cyl(0.015, 0.02, 0.7, 4), "#4f8a3a", Vector3(cos(a) * radius * 1.2 + k * 0.06, 0.35, sin(a) * radius * 0.9), Vector3(randf_range(-10, 10), 0, randf_range(-10, 10)))
	Models.part(n, Models.cyl(0.35, 0.35, 0.03, 12), "#5aa852", Vector3(radius * 0.4, 0.06, radius * 0.3))  # nilüfer
	Models.part(n, Models.ball(0.08, 6), "#f2a0c0", Vector3(radius * 0.4, 0.1, radius * 0.3))
	return n


static func coop() -> Node3D:
	var n := Node3D.new()
	Models.part(n, Models.box(1.2, 0.8, 1.0), "#c96a43", Vector3(0, 0.6, 0))
	Models.part(n, Models.prism(1.4, 0.5, 1.2), "#8a5a3b", Vector3(0, 1.25, 0))
	for x in [-0.5, 0.5]:
		for z in [-0.4, 0.4]:
			Models.part(n, Models.box(0.08, 0.3, 0.08), "#8a5a3b", Vector3(x, 0.15, z))
	Models.part(n, Models.box(0.3, 0.35, 0.04), "#3b2a1e", Vector3(0, 0.55, 0.51))
	Models.part(n, Models.box(0.25, 0.04, 0.7), "#a86f48", Vector3(0, 0.2, 0.75), Vector3(-30, 0, 0))  # rampa
	return n


static func hay() -> Node3D:
	var n := Node3D.new()
	Models.part(n, Models.cyl(0.45, 0.45, 0.8, 14), "#e8c86a", Vector3(0, 0.45, 0), Vector3(0, 0, 90))
	for x in [-0.2, 0.2]:
		Models.part(n, Models.cyl(0.46, 0.46, 0.04, 14), "#c9a24a", Vector3(x, 0.45, 0), Vector3(0, 0, 90))
	return n


static func trough() -> Node3D:
	var n := Node3D.new()
	Models.part(n, Models.box(1.4, 0.4, 0.5), "#8a5a3b", Vector3(0, 0.2, 0))
	Models.part(n, Models.box(1.3, 0.05, 0.4), "#79c2d0", Vector3(0, 0.38, 0))
	return n


## Sütlü'nün mama kabı; dolu mu boş mu gösterir.
static func bowl() -> Node3D:
	var n := Node3D.new()
	Models.part(n, Models.cyl(0.2, 0.15, 0.1, 14), "#d6577a", Vector3(0, 0.05, 0))
	var food := Models.part(n, Models.cyl(0.16, 0.16, 0.03, 12), "#b07a4a", Vector3(0, 0.1, 0))
	food.name = "Mama"
	return n


## Hülya Teyze'nin kaybolan gözlüğü.
static func glasses() -> Node3D:
	var n := Node3D.new()
	for sx in [-1, 1]:
		var t := TorusMesh.new()
		t.inner_radius = 0.07
		t.outer_radius = 0.1
		t.rings = 14
		t.ring_segments = 6
		Models.part(n, t, "#8e2f6a", Vector3(sx * 0.11, 0.12, 0), Vector3(90, 0, 0))
	Models.part(n, Models.box(0.06, 0.02, 0.02), "#8e2f6a", Vector3(0, 0.14, 0))
	var glow := Models.part(n, Models.cyl(0.35, 0.35, 0.01, 16), "#fff4a0", Vector3(0, 0.01, 0))
	var m := Models.mat("#fff4a0").duplicate() as StandardMaterial3D
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color.a = 0.5
	glow.material_override = m
	return n


## Saman kovan (geleneksel arı kovanı): üst üste daralan halkalar.
static func hive() -> Node3D:
	var n := Node3D.new()
	Models.part(n, Models.box(0.9, 0.5, 0.9), "#8a5a3b", Vector3(0, 0.25, 0))  # sehpa
	for i in 5:
		var r := 0.42 - i * 0.07
		Models.part(n, Models.cyl(r, r + 0.03, 0.16, 16), "#e2b552" if i % 2 == 0 else "#d4a040", Vector3(0, 0.58 + i * 0.15, 0))
	Models.part(n, Models.ball(0.14, 10), "#e2b552", Vector3(0, 1.28, 0))
	Models.part(n, Models.cyl(0.07, 0.07, 0.04, 10), "#3b2a1e", Vector3(0, 0.6, 0.42), Vector3(90, 0, 0))  # giriş
	return n


static func bee() -> Node3D:
	var n := Node3D.new()
	Models.part(n, Models.ball(0.07, 10), "#f2c23a", Vector3.ZERO, Vector3.ZERO, Vector3(0.9, 0.9, 1.3))
	for z in [-0.03, 0.03]:
		Models.part(n, Models.cyl(0.066, 0.066, 0.018, 10), "#2b2420", Vector3(0, 0, z), Vector3(90, 0, 0))
	Models.part(n, Models.ball(0.04, 8), "#2b2420", Vector3(0, 0.01, 0.09))
	for sx in [-1, 1]:
		var w := Models.part(n, Models.ball(0.06, 8), "#ffffff", Vector3(sx * 0.06, 0.07, -0.01), Vector3.ZERO, Vector3(1.2, 0.2, 0.7))
		w.name = "WingL" if sx < 0 else "WingR"
	return n


static func butterfly(color: String) -> Node3D:
	var n := Node3D.new()
	Models.part(n, Models.capsule(0.015, 0.14), "#3b2a1e", Vector3.ZERO, Vector3(90, 0, 0))
	for sx in [-1, 1]:
		var hinge := Models.pivot(n, "WingL" if sx < 0 else "WingR", Vector3.ZERO)
		Models.part(hinge, Models.ball(0.08, 8), color, Vector3(sx * 0.08, 0, 0.02), Vector3.ZERO, Vector3(1.0, 0.12, 1.2))
		Models.part(hinge, Models.ball(0.05, 8), color, Vector3(sx * 0.06, 0, -0.07), Vector3.ZERO, Vector3(1.0, 0.12, 1.0))
	return n


static func apple_tree() -> Node3D:
	var n := Models.tree()
	for i in 9:
		var a := TAU * i / 9.0
		Models.part(n, Models.ball(0.09, 8), "#d8352a", Vector3(cos(a) * 0.62, 1.35 + (i % 3) * 0.2, sin(a) * 0.62))
	return n


## Ahşap köprü (dere üstünde).
static func bridge(width := 1.8, length := 2.6) -> Node3D:
	var n := Node3D.new()
	for i in 9:
		var z := -length / 2 + i * length / 8.0
		Models.part(n, Models.box(width, 0.08, length / 9.0 - 0.03), "#b07a4a" if i % 2 else "#a86f48", Vector3(0, 0.12 + sin(PI * i / 8.0) * 0.18, z))
	for sx in [-1, 1]:
		for i in 4:
			var z := -length / 2 + i * length / 3.0
			Models.part(n, Models.box(0.08, 0.6, 0.08), "#8a5a3b", Vector3(sx * width / 2, 0.4 + sin(PI * i / 3.0) * 0.18, z))
		Models.part(n, Models.box(0.07, 0.07, length), "#8a5a3b", Vector3(sx * width / 2, 0.75, 0))
	return n


## Çiçek tarhı: ahşap kenarlı, toprak ve üstünde çiçekler (çiçekleri çağıran ekler).
## Bostan korkuluğu: sopa, saman şapka, ekose gömlek.
static func scarecrow() -> Node3D:
	var n := Node3D.new()
	Models.part(n, Models.cyl(0.04, 0.05, 1.7, 6), "#8a5a3b", Vector3(0, 0.85, 0))
	Models.part(n, Models.box(1.1, 0.06, 0.06), "#8a5a3b", Vector3(0, 1.25, 0))
	Models.part(n, Models.box(0.5, 0.5, 0.26), "#c8412f", Vector3(0, 1.15, 0))
	for x in [-0.36, 0.36]:
		Models.part(n, Models.box(0.24, 0.16, 0.18), "#c8412f", Vector3(x, 1.25, 0))
		Models.part(n, Models.ball(0.07, 6), "#e8c66a", Vector3(x * 1.5, 1.25, 0), Vector3.ZERO, Vector3(1.4, 0.6, 1))
	Models.part(n, Models.ball(0.2, 10), "#f2e2b0", Vector3(0, 1.58, 0))
	for x in [-0.07, 0.07]:
		Models.part(n, Models.ball(0.025, 6), "#3b2a1e", Vector3(x, 1.62, 0.18))
	Models.part(n, Models.cyl(0.36, 0.36, 0.03, 12), "#e8c66a", Vector3(0, 1.74, 0))
	Models.part(n, Models.cyl(0.14, 0.17, 0.18, 10), "#e8c66a", Vector3(0, 1.84, 0))
	Models.part(n, Models.cyl(0.175, 0.175, 0.04, 10), "#c8412f", Vector3(0, 1.79, 0))
	return n


## Elde tutulan şemsiye (karakterin yerel ölçüsünde).
static func umbrella(color: String) -> Node3D:
	var n := Node3D.new()
	n.name = "Semsiye"
	Models.part(n, Models.cyl(0.015, 0.015, 1.1, 5), "#5c3a26", Vector3(0, 1.25, 0))
	Models.part(n, Models.ball(0.62, 12, true), color, Vector3(0, 1.72, 0), Vector3.ZERO, Vector3(1, 0.45, 1))
	Models.part(n, Models.ball(0.04, 6), "#fff4dc", Vector3(0, 2.0, 0))
	return n


## Bostan tarhındaki ekin: ripe değilse küçük filizler, olgunsa meyvesiyle.
static func crop(kind: String, ripe: bool) -> Node3D:
	var n := Node3D.new()
	var spots := [Vector3(-0.5, 0, -0.22), Vector3(0.0, 0, -0.22), Vector3(0.5, 0, -0.22), Vector3(-0.5, 0, 0.22), Vector3(0.0, 0, 0.22), Vector3(0.5, 0, 0.22)]
	if kind == "karpuz":
		spots = [Vector3(-0.4, 0, 0), Vector3(0.4, 0, 0)]
	for p in spots:
		if not ripe:
			for k in 2:  # iki küçük yaprak
				Models.part(n, Models.ball(0.06, 6), "#6cbf4a", p + Vector3((k - 0.5) * 0.08, 0.07, 0), Vector3(0, 0, (k - 0.5) * 60), Vector3(1.4, 0.5, 0.9))
			Models.part(n, Models.cyl(0.012, 0.012, 0.08, 4), "#4f8a3a", p + Vector3(0, 0.04, 0))
			continue
		match kind:
			"domates", "biber":
				Models.part(n, Models.cyl(0.02, 0.025, 0.42, 5), "#4f8a3a", p + Vector3(0, 0.21, 0))
				Models.part(n, Models.ball(0.16, 8), "#5aa83e", p + Vector3(0, 0.36, 0), Vector3.ZERO, Vector3(1, 0.8, 1))
				for k in 3:
					var a: float = k * TAU / 3.0 + p.x
					var q: Vector3 = p + Vector3(cos(a) * 0.13, 0.26 + k * 0.04, sin(a) * 0.13)
					if kind == "domates":
						Models.part(n, Models.ball(0.065, 8), "#e0402e", q)
					else:
						Models.part(n, Models.capsule(0.035, 0.16), "#3f9a35" if k != 1 else "#e0402e", q, Vector3(0, 0, 20))
			"havuc":
				Models.part(n, Models.cyl(0.05, 0.06, 0.06, 8), "#f08a24", p + Vector3(0, 0.02, 0))
				for k in 3:
					Models.part(n, Models.ball(0.05, 6), "#5aa83e", p + Vector3((k - 1) * 0.04, 0.14, 0), Vector3(0, 0, (k - 1) * 25), Vector3(0.5, 1.8, 0.5))
			"karpuz":
				Models.part(n, Models.ball(0.26, 12), "#3f8a35", p + Vector3(0, 0.2, 0), Vector3.ZERO, Vector3(1.2, 0.9, 1))
				for k in 4:
					Models.part(n, Models.box(0.04, 0.47, 0.5), "#2b6a2a", p + Vector3((k - 1.5) * 0.14, 0.2, 0), Vector3.ZERO, Vector3(1, 1, 1))
				Models.part(n, Models.ball(0.08, 6), "#5aa83e", p + Vector3(0.3, 0.05, 0.2), Vector3.ZERO, Vector3(1.5, 0.4, 1))
	return n


static func flower_bed(size: Vector2) -> Node3D:
	var n := Node3D.new()
	Models.part(n, Models.box(size.x, 0.18, size.y), "#8a5a3b", Vector3(0, 0.09, 0))
	Models.part(n, Models.box(size.x - 0.16, 0.06, size.y - 0.16), "#5c3a26", Vector3(0, 0.17, 0))
	return n
