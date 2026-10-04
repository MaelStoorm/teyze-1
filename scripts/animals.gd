class_name Animals
## Mahallenin hayvanları: inek, tavuk, ördek, köpek ve kediler.
## Bacaklar LegL/LegR (ve dört ayaklılarda çapraz eşleri LegL2/LegR2) döndürme
## noktalarında; Walker bunlarla yürütür.



static func _eyes(n: Node3D, y: float, z: float, gap: float, r: float) -> void:
	for sx in [-1, 1]:
		Models.part(n, Models.ball(r, 8), "#1e1712", Vector3(sx * gap, y, z), Vector3.ZERO, Vector3(1, 1.15, 0.7))
		Models.part(n, Models.ball(r * 0.35, 6), "#ffffff", Vector3(sx * gap + r * 0.3, y + r * 0.4, z + r * 0.5))


## Dört bacak: ön-sol ile arka-sağ aynı adımda (çapraz yürüyüş).
static func _legs4(n: Node3D, hip_y: float, x: float, zf: float, zb: float, r: float, color: String, hoof: String) -> void:
	for spec in [["LegL", -1, zf], ["LegR", 1, zf], ["LegR2", -1, zb], ["LegL2", 1, zb]]:
		var leg := Models.pivot(n, spec[0], Vector3(spec[1] * x, hip_y, spec[2]))
		Models.part(leg, Models.cyl(r, r * 0.9, hip_y, 8), color, Vector3(0, -hip_y / 2, 0))
		Models.part(leg, Models.cyl(r * 1.05, r * 1.05, hip_y * 0.18, 8), hoof, Vector3(0, -hip_y * 0.92, 0))


static func cow() -> Node3D:
	var n := Node3D.new()
	n.name = "Inek"
	_legs4(n, 0.5, 0.2, 0.42, -0.42, 0.075, "#fbf8f2", "#3b2a1e")
	var b := Models.pivot(n, "Body", Vector3.ZERO)
	Models.part(b, Models.capsule(0.36, 1.35), "#fbf8f2", Vector3(0, 0.82, 0), Vector3(90, 0, 0))
	for p in [Vector3(0.22, 0.95, 0.15), Vector3(-0.25, 0.85, -0.3), Vector3(0.1, 1.12, -0.25), Vector3(-0.3, 0.9, 0.35)]:
		Models.part(b, Models.ball(0.2, 8), "#2b2420", p, Vector3.ZERO, Vector3(0.8, 0.9, 1.2))
	Models.part(b, Models.ball(0.27, 12), "#fbf8f2", Vector3(0, 1.08, 0.78))  # baş
	Models.part(b, Models.ball(0.2, 10), "#f2b8b0", Vector3(0, 0.96, 1.0), Vector3.ZERO, Vector3(1.2, 0.85, 0.8))  # burun
	for sx in [-1, 1]:
		Models.part(b, Models.ball(0.03, 6), "#8a4a4a", Vector3(sx * 0.07, 0.97, 1.15))
		Models.part(b, Models.cyl(0.02, 0.04, 0.16, 6), "#f4e6c8", Vector3(sx * 0.15, 1.33, 0.78), Vector3(0, 0, sx * -30))  # boynuz
		Models.part(b, Models.ball(0.09, 8), "#fbf8f2", Vector3(sx * 0.3, 1.18, 0.72), Vector3.ZERO, Vector3(1.4, 0.6, 0.8))  # kulak
	_eyes(b, 1.16, 1.0, 0.12, 0.045)
	Models.part(b, Models.cyl(0.02, 0.02, 0.5, 6), "#fbf8f2", Vector3(0, 0.8, -0.8), Vector3(20, 0, 0))  # kuyruk
	Models.part(b, Models.ball(0.12, 8), "#f2b8b0", Vector3(0, 0.5, -0.1), Vector3.ZERO, Vector3(1, 0.6, 1))  # meme
	Models.part(b, Models.cyl(0.07, 0.07, 0.06, 10), "#e8b33a", Vector3(0, 0.9, 0.72), Vector3(20, 0, 0))  # çan
	return n


static func chicken() -> Node3D:
	var n := Node3D.new()
	n.name = "Tavuk"
	for side in [["LegL", -1], ["LegR", 1]]:
		var leg := Models.pivot(n, side[0], Vector3(side[1] * 0.07, 0.16, 0))
		Models.part(leg, Models.cyl(0.015, 0.015, 0.16, 5), "#f2a03a", Vector3(0, -0.08, 0))
		Models.part(leg, Models.box(0.07, 0.015, 0.08), "#f2a03a", Vector3(0, -0.16, 0.02))
	var b := Models.pivot(n, "Body", Vector3.ZERO)
	Models.part(b, Models.ball(0.17, 12), "#fbf8f2", Vector3(0, 0.3, 0), Vector3.ZERO, Vector3(1, 0.95, 1.2))
	Models.part(b, Models.ball(0.11, 10), "#fbf8f2", Vector3(0, 0.48, 0.13))
	Models.part(b, Models.cyl(0.0, 0.04, 0.08, 6), "#f2b33a", Vector3(0, 0.47, 0.26), Vector3(90, 0, 0))  # gaga
	Models.part(b, Models.ball(0.045, 6), "#e0402e", Vector3(0, 0.6, 0.13), Vector3.ZERO, Vector3(0.6, 1.2, 1.4))  # ibik
	Models.part(b, Models.ball(0.03, 6), "#e0402e", Vector3(0, 0.42, 0.22))
	_eyes(b, 0.51, 0.21, 0.06, 0.02)
	Models.part(b, Models.ball(0.1, 8), "#f4efe6", Vector3(0, 0.38, -0.18), Vector3(-30, 0, 0), Vector3(0.8, 1.2, 0.5))  # kuyruk
	return n


static func duck() -> Node3D:
	var n := Node3D.new()
	n.name = "Ordek"
	var b := Models.pivot(n, "Body", Vector3.ZERO)
	Models.part(b, Models.ball(0.18, 12), "#fbf8f2", Vector3(0, 0.12, 0), Vector3.ZERO, Vector3(1, 0.8, 1.35))
	Models.part(b, Models.ball(0.12, 10), "#4f9a4a", Vector3(0, 0.33, 0.16))  # yeşil baş
	Models.part(b, Models.box(0.1, 0.03, 0.12), "#f2a03a", Vector3(0, 0.3, 0.3))  # gaga
	Models.part(b, Models.cyl(0.07, 0.08, 0.04, 10), "#fbf8f2", Vector3(0, 0.23, 0.12))  # boyun halkası
	_eyes(b, 0.36, 0.26, 0.065, 0.02)
	Models.part(b, Models.ball(0.07, 6), "#fbf8f2", Vector3(0, 0.2, -0.24), Vector3(40, 0, 0), Vector3(0.8, 0.5, 1.2))
	return n


## Karabaş gibi açık renkli, siyah maskeli bir mahalle köpeği.
static func dog() -> Node3D:
	var n := Node3D.new()
	n.name = "Kopek"
	_legs4(n, 0.28, 0.12, 0.22, -0.22, 0.05, "#e3c48e", "#e3c48e")
	var b := Models.pivot(n, "Body", Vector3.ZERO)
	Models.part(b, Models.capsule(0.17, 0.7), "#e3c48e", Vector3(0, 0.42, 0), Vector3(90, 0, 0))
	Models.part(b, Models.ball(0.17, 12), "#e3c48e", Vector3(0, 0.62, 0.36))
	Models.part(b, Models.ball(0.1, 10), "#3b2a1e", Vector3(0, 0.58, 0.5), Vector3.ZERO, Vector3(1, 0.85, 1.1))  # maske
	Models.part(b, Models.ball(0.035, 6), "#1e1712", Vector3(0, 0.6, 0.6))
	for sx in [-1, 1]:
		Models.part(b, Models.ball(0.07, 8), "#3b2a1e", Vector3(sx * 0.14, 0.7, 0.32), Vector3(0, 0, sx * 20), Vector3(0.6, 1.3, 0.5))  # kulak
	_eyes(b, 0.68, 0.49, 0.07, 0.025)
	Models.part(b, Models.ball(0.03, 6), "#e05a6a", Vector3(0, 0.53, 0.57), Vector3.ZERO, Vector3(1, 0.5, 1.4))  # dil
	Models.part(b, Models.cyl(0.03, 0.04, 0.32, 6), "#e3c48e", Vector3(0, 0.58, -0.4), Vector3(-45, 0, 0))  # kuyruk
	return n


## Kedi: Sütlü sarı-beyaz, Pamuk bembeyaz.
static func cat(main := "#f2c46b", belly := "#fffaf0") -> Node3D:
	var n := Node3D.new()
	n.name = "Kedi"
	_legs4(n, 0.16, 0.07, 0.13, -0.13, 0.035, belly, belly)
	var b := Models.pivot(n, "Body", Vector3.ZERO)
	Models.part(b, Models.capsule(0.11, 0.42), main, Vector3(0, 0.24, 0), Vector3(90, 0, 0))
	Models.part(b, Models.ball(0.085, 8), belly, Vector3(0, 0.2, 0.08), Vector3.ZERO, Vector3(1, 0.8, 1.5))  # beyaz göğüs
	Models.part(b, Models.ball(0.14, 12), main, Vector3(0, 0.4, 0.22))
	Models.part(b, Models.ball(0.08, 10), belly, Vector3(0, 0.36, 0.31), Vector3.ZERO, Vector3(1.2, 0.8, 0.7))  # ağız çevresi
	Models.part(b, Models.ball(0.02, 6), "#f08a9a", Vector3(0, 0.39, 0.36))
	for sx in [-1, 1]:
		Models.part(b, Models.prism(0.09, 0.1, 0.04), main, Vector3(sx * 0.08, 0.55, 0.2))
		Models.part(b, Models.prism(0.05, 0.06, 0.02), "#f6b8b8", Vector3(sx * 0.08, 0.54, 0.22))
		for k in [-1, 1]:  # bıyıklar
			Models.part(b, Models.box(0.12, 0.006, 0.006), "#ffffff", Vector3(sx * 0.1, 0.36 + k * 0.012, 0.33), Vector3(0, 0, sx * k * 10))
	_eyes(b, 0.43, 0.33, 0.055, 0.025)
	for i in 3:  # sırt çizgileri
		Models.part(b, Models.box(0.2, 0.02, 0.03), "#d9a245" if main == "#f2c46b" else main, Vector3(0, 0.355, 0.05 - i * 0.1))
	Models.part(b, Models.capsule(0.025, 0.36), main, Vector3(0, 0.36, -0.3), Vector3(-35, 0, 0))  # kuyruk
	return n
