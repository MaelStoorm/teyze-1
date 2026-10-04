class_name Avatar
## Oyuncunun karakteri: kız/erkek, ten, saç modeli ve rengi, kıyafet renkleri.
## Mii tarzı: iri baş, büyük gözler, kısa gövde.

const SKINS := ["#fbe0c4", "#f6cfa5", "#e8b48a", "#c98e62", "#8d5a3b"]
const HAIR_COLORS := ["#2b1d14", "#5c3a26", "#a0652e", "#e8c070", "#c4402c", "#9aa0a6"]
const TOPS := ["#3d6fb6", "#d6577a", "#4f9a4a", "#e8b33a", "#8e5bb5", "#f4efe6", "#c4402c", "#2c3e50"]
const BOTTOMS := ["#2c3e50", "#3d6fb6", "#7a4e8a", "#8a5a3b", "#4f6a3a", "#d6577a"]
const HAIRSTYLES := {
	"erkek": [["kisa", "Kısa"], ["dikenli", "Dikenli"], ["kivircik", "Kıvırcık"], ["yana", "Yana"]],
	"kiz": [["atkuyrugu", "At kuyruğu"], ["uzun", "Uzun"], ["topuz", "Topuz"], ["orgu", "Örgülü"]],
}
const BOTTOM_STYLES := {
	"erkek": [["pantolon", "Pantolon"], ["sort", "Şort"]],
	"kiz": [["etek", "Etek"], ["pantolon", "Pantolon"]],
}
const DEFAULT := {"gender": "kiz", "skin": 1, "hair": 0, "hair_color": 1, "top": 1, "bottom_style": 0, "bottom": 0, "name": ""}


static func normalized(look: Dictionary) -> Dictionary:
	var l := DEFAULT.duplicate()
	l.merge(look, true)
	return l


static func hairstyle(l: Dictionary) -> String:
	var list: Array = HAIRSTYLES[l["gender"]]
	return list[clampi(l["hair"], 0, list.size() - 1)][0]


static func bottom_style(l: Dictionary) -> String:
	var list: Array = BOTTOM_STYLES[l["gender"]]
	return list[clampi(l["bottom_style"], 0, list.size() - 1)][0]


static func build(look: Dictionary) -> Node3D:
	var l := normalized(look)
	var skin: String = SKINS[l["skin"] % SKINS.size()]
	var hair: String = HAIR_COLORS[l["hair_color"] % HAIR_COLORS.size()]
	var top: String = TOPS[l["top"] % TOPS.size()]
	var bottom: String = BOTTOMS[l["bottom"] % BOTTOMS.size()]
	var girl: bool = l["gender"] == "kiz"
	var bs := bottom_style(l)
	var n := Node3D.new()
	n.name = "Oyuncu"
	for side in [["LegL", -1], ["LegR", 1]]:
		var leg := Models.pivot(n, side[0], Vector3(side[1] * 0.1, 0.46, 0))
		match bs:
			"pantolon":
				Models.part(leg, Models.capsule(0.085, 0.46), bottom, Vector3(0, -0.21, 0))
			"sort":
				Models.part(leg, Models.cyl(0.09, 0.09, 0.18, 8), bottom, Vector3(0, -0.05, 0))
				Models.part(leg, Models.cyl(0.055, 0.055, 0.3, 8), skin, Vector3(0, -0.27, 0))
			_:
				Models.part(leg, Models.cyl(0.055, 0.055, 0.4, 8), skin, Vector3(0, -0.2, 0))
		Models.part(leg, Models.ball(0.085, 8), "#f4efe6" if girl else "#5c3a26", Vector3(0, -0.42, 0.04), Vector3.ZERO, Vector3(1, 0.7, 1.45))
	var body := Models.pivot(n, "Body", Vector3.ZERO)
	Models.part(body, Models.cyl(0.18 if girl else 0.2, 0.22, 0.4), top, Vector3(0, 0.7, 0))
	Models.part(body, Models.ball(0.2, 12), top, Vector3(0, 0.88, 0), Vector3.ZERO, Vector3(1, 0.45, 0.9))  # omuzlar
	if bs == "etek":
		Models.part(body, Models.cyl(0.2, 0.3, 0.26), bottom, Vector3(0, 0.47, 0))
	elif bs != "sort":
		Models.part(body, Models.cyl(0.215, 0.215, 0.06), "#3b2a1e", Vector3(0, 0.5, 0))  # kemer
	for side in [["ArmL", -1], ["ArmR", 1]]:
		var sx: int = side[1]
		var arm := Models.pivot(body, side[0], Vector3(sx * 0.23, 0.86, 0))
		Models.part(arm, Models.capsule(0.065, 0.36), top, Vector3(sx * 0.03, -0.17, 0), Vector3(0, 0, sx * 10))
		Models.part(arm, Models.ball(0.065, 8), skin, Vector3(sx * 0.06, -0.37, 0))
	var hy := 1.24
	var r := 0.34
	Models.part(body, Models.ball(r, 20), skin, Vector3(0, hy, 0))
	Models.face(body, hy, r, {"skin": skin, "brow": hair})
	_hair(body, hy, r, hair, hairstyle(l))
	return n


static func _hair(body: Node3D, hy: float, r: float, c: String, style: String) -> void:
	# her modelde başın üstünü ve arkasını saran kep
	Models.part(body, Models.ball(r * 1.07, 18, true), c, Vector3(0, hy + r * 0.08, -r * 0.06), Vector3(-22, 0, 0))
	Models.part(body, Models.ball(r * 1.04, 16), c, Vector3(0, hy - r * 0.05, -r * 0.18), Vector3.ZERO, Vector3(1, 0.9, 0.85))
	match style:
		"kisa":
			Models.part(body, Models.ball(r * 0.5, 10), c, Vector3(-r * 0.2, hy + r * 0.72, r * 0.55), Vector3.ZERO, Vector3(1.4, 0.45, 0.8))
		"dikenli":
			for i in 8:
				var a := TAU * i / 8.0
				var p := Vector3(sin(a) * r * 0.55, hy + r * 0.85, cos(a) * r * 0.5)
				Models.part(body, Models.cyl(0.0, r * 0.2, r * 0.45, 6), c, p, Vector3(cos(a) * 35, 0, -sin(a) * 35))
			Models.part(body, Models.cyl(0.0, r * 0.22, r * 0.5, 6), c, Vector3(0, hy + r * 1.05, 0))
		"kivircik":
			for i in 16:
				var a := TAU * i / 16.0
				var ring := 0.75 if i % 2 == 0 else 0.45
				Models.part(body, Models.ball(r * 0.26, 8), c, Vector3(sin(a) * r * ring, hy + r * (0.85 if ring < 0.6 else 0.6), cos(a) * r * ring * 0.9 - r * 0.05))
			Models.part(body, Models.ball(r * 0.3, 8), c, Vector3(0, hy + r * 1.0, 0))
		"yana":
			Models.part(body, Models.ball(r * 0.6, 12), c, Vector3(r * 0.3, hy + r * 0.62, r * 0.45), Vector3(0, 0, -20), Vector3(1.5, 0.5, 0.9))
		"atkuyrugu":
			_bangs(body, hy, r, c)
			Models.part(body, Models.ball(r * 0.12, 8), "#e04a6a", Vector3(0, hy + r * 0.45, -r * 1.02))
			Models.part(body, Models.capsule(r * 0.2, r * 1.3), c, Vector3(0, hy - r * 0.1, -r * 1.15), Vector3(18, 0, 0))
		"uzun":
			_bangs(body, hy, r, c)
			Models.part(body, Models.box(r * 1.9, r * 1.6, r * 0.5), c, Vector3(0, hy - r * 0.55, -r * 0.55))
			for sx in [-1, 1]:
				Models.part(body, Models.capsule(r * 0.2, r * 1.5), c, Vector3(sx * r * 0.88, hy - r * 0.45, r * 0.05))
		"topuz":
			_bangs(body, hy, r, c)
			Models.part(body, Models.ball(r * 0.42, 12), c, Vector3(0, hy + r * 0.95, -r * 0.45))
			Models.part(body, Models.cyl(r * 0.3, r * 0.3, r * 0.1, 12), "#e8b33a", Vector3(0, hy + r * 0.72, -r * 0.38), Vector3(-30, 0, 0))
		"orgu":
			_bangs(body, hy, r, c)
			for sx in [-1, 1]:
				for k in 4:
					Models.part(body, Models.ball(r * (0.2 - k * 0.02), 8), c, Vector3(sx * r * 0.95, hy - r * (0.2 + k * 0.33), -r * 0.1))
				Models.part(body, Models.ball(r * 0.09, 6), "#e04a6a", Vector3(sx * r * 0.95, hy - r * 1.4, -r * 0.1))


## Kızların alnına düşen kakül.
static func _bangs(body: Node3D, hy: float, r: float, c: String) -> void:
	Models.part(body, Models.ball(r * 0.95, 14, true), c, Vector3(0, hy + r * 0.32, r * 0.12), Vector3(-5, 0, 0), Vector3(1.05, 0.5, 1.0))
