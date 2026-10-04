class_name Decor
## Kurabiyeyle alınan, mahalleye eklenen süsler. Her biri 3D model olarak
## mahallede kendi yerinde belirir.

const ALL := [
	{"id": "kedievi", "name": "Pamuk'un Evi", "desc": "Pamuk'a ahşap bir kulübe. Pamuk artık mahallede uyukluyor.",
		"price": 20, "pos": Vector3(-4.3, 0, -1.3), "rot": 30.0},
	{"id": "semaver", "name": "Çay Bahçesi", "desc": "Semaverli bir masa ve iki tabure. Çaylar teyzeden.",
		"price": 25, "pos": Vector3(2.4, 0, -0.3), "rot": 0.0},
	{"id": "cesme", "name": "Mahalle Çeşmesi", "desc": "Taş bir çeşme, şırıl şırıl akar.",
		"price": 30, "pos": Vector3(2.1, 0, 6.6), "rot": -90.0},
	{"id": "cardak", "name": "Asma Çardağı", "desc": "Bankın üstüne asma yapraklı bir çardak.",
		"price": 35, "pos": Vector3(-2.3, 0, 2.2), "rot": 90.0},
	{"id": "gul", "name": "Gül Bahçesi", "desc": "Rengârenk güllerle dolu bir çiçek tarhı.",
		"price": 40, "pos": Vector3(-2.6, 0, 9.4), "rot": 0.0},
	{"id": "fener", "name": "Bayram Işıkları", "desc": "Sokağın üstüne renkli ampuller. Mahalle bayram yerine döner.",
		"price": 60, "pos": Vector3(0, 0, -3.7), "rot": 0.0},
	# Komşuların dostluk hediyeleri: dükkanda satılmaz.
	{"id": "kusevi", "name": "Filiz'in Kuş Evi", "desc": "Direğin ucunda serçelere küçük bir ev.",
		"price": 0, "gift": true, "pos": Vector3(5.2, 0, -5.0), "rot": -30.0},
	{"id": "sardunya", "name": "Miyase'nin Sardunyaları", "desc": "Teneke saksılarda kırmızı sardunyalar.",
		"price": 0, "gift": true, "pos": Vector3(-11.4, 0, -5.0), "rot": 0.0},
	{"id": "salincak", "name": "Hülya'nın Salıncağı", "desc": "Mahalle çocukları için ahşap bir salıncak.",
		"price": 0, "gift": true, "pos": Vector3(11.3, 0, -1.2), "rot": 0.0},
	{"id": "tavla", "name": "Ahmet'in Tavla Masası", "desc": "Gölgede bir tavla masası, iki tabure.",
		"price": 0, "gift": true, "pos": Vector3(-5.8, 0, 3.6), "rot": 0.0},
]


static func get_decor(id: String) -> Dictionary:
	for d in ALL:
		if d["id"] == id:
			return d
	return {}


static func build(id: String) -> Node3D:
	var n := Node3D.new()
	match id:
		"kedievi":
			Models.part(n, Models.box(0.9, 0.7, 0.9), "#b07a4a", Vector3(0, 0.35, 0))
			Models.part(n, Models.prism(1.1, 0.5, 1.1), "#c8553a", Vector3(0, 0.95, 0))
			Models.part(n, Models.cyl(0.22, 0.22, 0.05, 12), "#3b2a1e", Vector3(0, 0.32, 0.46), Vector3(90, 0, 0))
			var cat := Models.cat()
			cat.position = Vector3(0.1, 0, 0.85)
			cat.rotation_degrees.y = 20
			n.add_child(cat)
		"semaver":
			Models.part(n, Models.cyl(0.5, 0.5, 0.06, 16), "#a86f48", Vector3(0, 0.7, 0))
			Models.part(n, Models.cyl(0.06, 0.08, 0.7, 8), "#5c3a26", Vector3(0, 0.35, 0))
			Models.part(n, Models.cyl(0.14, 0.18, 0.35, 12), "#c9962a", Vector3(0, 0.9, 0))  # semaver
			Models.part(n, Models.ball(0.12, 10), "#d9a72e", Vector3(0, 1.12, 0))
			Models.part(n, Models.cyl(0.06, 0.08, 0.1, 10), "#f4efe6", Vector3(0, 1.26, 0))  # demlik
			for a in [0.0, 2.1, 4.2]:
				Models.part(n, Models.cyl(0.045, 0.03, 0.1, 8), "#c4402c", Vector3(cos(a) * 0.32, 0.78, sin(a) * 0.32))
			for x in [-0.8, 0.8]:
				Models.part(n, Models.cyl(0.2, 0.2, 0.08, 12), "#c96a43", Vector3(x, 0.42, 0))
				Models.part(n, Models.cyl(0.04, 0.05, 0.4, 6), "#5c3a26", Vector3(x, 0.2, 0))
		"cesme":
			Models.part(n, Models.box(1.4, 0.4, 0.6), "#b8a68a", Vector3(0, 0.2, 0.3))  # yalak
			Models.part(n, Models.box(1.2, 0.08, 0.45), "#79c2d0", Vector3(0, 0.38, 0.3))  # su
			Models.part(n, Models.box(1.5, 1.5, 0.3), "#d9cbb0", Vector3(0, 0.75, -0.1))
			Models.part(n, Models.cyl(0.75, 0.75, 0.3, 16), "#d9cbb0", Vector3(0, 1.5, -0.1), Vector3(90, 0, 0))
			Models.part(n, Models.box(0.5, 0.6, 0.06), "#9aa0a6", Vector3(0, 1.05, 0.06))  # kitabe
			Models.part(n, Models.cyl(0.03, 0.03, 0.2, 6), "#c9962a", Vector3(0, 0.8, 0.12), Vector3(90, 0, 0))  # lüle
			Models.part(n, Models.cyl(0.015, 0.015, 0.4, 6), "#a8e0ec", Vector3(0, 0.58, 0.22))  # akan su
		"cardak":
			for x in [-0.8, 0.8]:
				for z in [-0.5, 0.5]:
					Models.part(n, Models.box(0.1, 2.0, 0.1), "#8a5a3b", Vector3(x, 1.0, z))
			for z in [-0.5, 0.0, 0.5]:
				Models.part(n, Models.box(1.9, 0.06, 0.08), "#8a5a3b", Vector3(0, 2.0, z))
			for i in 14:
				Models.part(n, Models.ball(0.22, 6), "#4f9a4a" if i % 3 else "#5aa852",
					Vector3(randf_range(-0.9, 0.9), 2.1 + randf_range(0, 0.1), randf_range(-0.6, 0.6)))
			for i in 4:  # üzüm salkımları
				Models.part(n, Models.ball(0.07, 6), "#7a4e8a", Vector3(randf_range(-0.7, 0.7), 1.85, randf_range(-0.4, 0.4)))
		"gul":
			Models.part(n, Models.box(3.0, 0.15, 1.0), "#8a5a3b", Vector3(0, 0.08, 0))
			Models.part(n, Models.box(2.8, 0.1, 0.8), "#5c3a26", Vector3(0, 0.16, 0))
			var colors := ["#e04a4a", "#f2a0c0", "#f7cf4a", "#f4efe6"]
			for i in 12:
				var p := Vector3(-1.2 + (i % 6) * 0.48, 0.3, -0.2 + (i / 6) * 0.4)
				Models.part(n, Models.ball(0.16, 6), "#3f8a46", p)
				Models.part(n, Models.ball(0.09, 6), colors[i % 4], p + Vector3(0, 0.16, 0.04))
		"fener":
			var colors := ["#e04a4a", "#f7cf4a", "#5aa0d8", "#5aa852", "#f2a0c0"]
			for side in [-1, 1]:
				for i in 13:
					var x: float = side * (0.4 + i * 0.42)
					var sag: float = 0.25 * sin(PI * i / 12.0)
					var bulb := Models.part(n, Models.ball(0.07, 6), colors[i % 5], Vector3(x, 2.5 - sag, 0))
					var m := Models.mat(colors[i % 5]).duplicate() as StandardMaterial3D
					m.emission_enabled = true
					m.emission = Color(colors[i % 5])
					m.emission_energy_multiplier = 0.8
					bulb.material_override = m
		"kusevi":
			Models.part(n, Models.cyl(0.05, 0.06, 1.8, 6), "#8a5a3b", Vector3(0, 0.9, 0))
			Models.part(n, Models.box(0.45, 0.4, 0.4), "#e8b33a", Vector3(0, 1.95, 0))
			Models.part(n, Models.prism(0.6, 0.25, 0.5), "#3e8fb0", Vector3(0, 2.28, 0))
			Models.part(n, Models.cyl(0.08, 0.08, 0.03, 10), "#3b2a1e", Vector3(0, 1.98, 0.2), Vector3(90, 0, 0))
			Models.part(n, Models.ball(0.07, 6), "#8a6a4a", Vector3(0.12, 2.45, 0.05))  # serçe
		"tavla":
			Models.part(n, Models.box(0.9, 0.06, 0.6), "#a86f48", Vector3(0, 0.7, 0))
			Models.part(n, Models.box(0.6, 0.03, 0.4), "#7a4e2a", Vector3(0, 0.75, 0))
			Models.part(n, Models.box(0.56, 0.035, 0.02), "#f4efe6", Vector3(0, 0.76, 0))
			for x in [-0.35, 0.35]:
				for z in [-0.22, 0.22]:
					Models.part(n, Models.box(0.06, 0.7, 0.06), "#5c3a26", Vector3(x, 0.35, z))
			for sx in [-1, 1]:
				Models.part(n, Models.cyl(0.18, 0.18, 0.05, 10), "#3e6fb5", Vector3(sx * 0.75, 0.42, 0))
				Models.part(n, Models.cyl(0.03, 0.03, 0.42, 4), "#5c3a26", Vector3(sx * 0.75, 0.21, 0))
		"sardunya":
			for i in 4:
				var p := Vector3(-0.75 + i * 0.5, 0, 0)
				Models.part(n, Models.cyl(0.17, 0.15, 0.32, 10), "#c0c6cc", p + Vector3(0, 0.16, 0))
				Models.part(n, Models.ball(0.2, 6), "#3f8a46", p + Vector3(0, 0.42, 0))
				for k in 3:
					Models.part(n, Models.ball(0.07, 6), "#e04a4a", p + Vector3(cos(k * 2.1) * 0.12, 0.55, sin(k * 2.1) * 0.12))
		"salincak":
			for x in [-0.8, 0.8]:
				Models.part(n, Models.box(0.1, 1.9, 0.1), "#8a5a3b", Vector3(x, 0.95, -0.25), Vector3(-8, 0, 0))
				Models.part(n, Models.box(0.1, 1.9, 0.1), "#8a5a3b", Vector3(x, 0.95, 0.25), Vector3(8, 0, 0))
			Models.part(n, Models.box(1.8, 0.1, 0.1), "#8a5a3b", Vector3(0, 1.9, 0))
			for x in [-0.25, 0.25]:
				Models.part(n, Models.cyl(0.015, 0.015, 1.2, 4), "#3b2a1e", Vector3(x, 1.3, 0))
			Models.part(n, Models.box(0.65, 0.06, 0.28), "#d6577a", Vector3(0, 0.7, 0))
	return n
