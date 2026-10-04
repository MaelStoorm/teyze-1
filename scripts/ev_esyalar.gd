class_name EvEsya
## Evin içi için kurabiyeyle alınan eşyalar. Her eşya bir yere (slot) konur;
## modeller, mahalledeki süsler gibi Godot'nun hazır şekillerinden kurulur.
##
## Yerleşim kuralı: her modelin kökü kendi yerinin noktasıdır ve önü +z'ye
## (odanın açık önüne) bakar. Yerdeki eşyalar y=0'dan, duvardakiler duvar
## yüzeyinden (z=0) başlar. "hang" olan lambalar tavandan sarkar.

## Yerler: odada sırasıyla düğme olarak görünür.
const SLOTS := [
	{"id": "hali", "name": "Halı"},
	{"id": "kanepe", "name": "Oturak"},
	{"id": "masa", "name": "Masa"},
	{"id": "duvar", "name": "Duvar"},
	{"id": "pencere", "name": "Perde"},
	{"id": "kose", "name": "Köşe"},
	{"id": "lamba", "name": "Lamba"},
]

const ALL := [
	# halı
	{"id": "paspas", "name": "Örgü Paspas", "slot": "hali", "price": 5,
		"desc": "Renk renk kumaştan örülmüş yuvarlak paspas."},
	{"id": "kilim", "name": "Kilim", "slot": "hali", "price": 15,
		"desc": "Anadolu desenli, saçaklı el dokuması kilim."},
	{"id": "cicekli_hali", "name": "Çiçekli Halı", "slot": "hali", "price": 25,
		"desc": "Pembe zeminli, gül desenli yumuşacık halı."},
	{"id": "gobekli_hali", "name": "Göbekli Halı", "slot": "hali", "price": 40,
		"desc": "Ortası madalyonlu, bordo lacivert yün halı."},
	# oturak
	{"id": "minder", "name": "Yer Minderi", "slot": "kanepe", "price": 8,
		"desc": "Püsküllü minderler. Yere bağdaş kurup oturmalık."},
	{"id": "berjer", "name": "Berjer Koltuk", "slot": "kanepe", "price": 25,
		"desc": "Ayak tabureli rahat koltuk. Örgü örmeye birebir."},
	{"id": "sedir", "name": "Sedir", "slot": "kanepe", "price": 30,
		"desc": "Duvar boyu sedir, kırmızı yastıklar, dantel kenar."},
	{"id": "kanepe", "name": "Kadife Kanepe", "slot": "kanepe", "price": 45,
		"desc": "Yeşil kadife kanepe, arkasında dantel örtü."},
	# masa
	{"id": "sehpa", "name": "Dantelli Sehpa", "slot": "masa", "price": 10,
		"desc": "Yuvarlak sehpa, üstünde dantel ve iki çay."},
	{"id": "sini", "name": "Sini Sofrası", "slot": "masa", "price": 15,
		"desc": "Pirinç sini, etrafında minderler. Herkes sofraya!"},
	{"id": "cezve", "name": "Cezve Takımı", "slot": "masa", "price": 20,
		"desc": "Sedef işlemeli sehpada bakır cezve ve fincanlar."},
	{"id": "yemek_masasi", "name": "Yemek Masası", "slot": "masa", "price": 40,
		"desc": "Örtülü masa, iki sandalye, bir tas meyve."},
	# duvar
	{"id": "nazarlik", "name": "Nazarlık", "slot": "duvar", "price": 5,
		"desc": "Kocaman mavi boncuk. Eve nazar değmesin."},
	{"id": "aile_foto", "name": "Aile Fotoğrafları", "slot": "duvar", "price": 10,
		"desc": "Torunların, düğün günü, bayram sabahı..."},
	{"id": "goblen", "name": "Goblen Tablo", "slot": "duvar", "price": 15,
		"desc": "Yaldızlı çerçevede el işi köy manzarası."},
	{"id": "guguklu", "name": "Guguklu Saat", "slot": "duvar", "price": 35,
		"desc": "Her saat başı kuşu çıkar: guguk, guguk!"},
	# perde
	{"id": "dantel_perde", "name": "Dantel Perde", "slot": "pencere", "price": 10,
		"desc": "Bembeyaz, fistolu dantel perde."},
	{"id": "cicekli_perde", "name": "Çiçekli Perde", "slot": "pencere", "price": 15,
		"desc": "Sarı zeminde kırmızı çiçekler. Ev güneş gibi olur."},
	{"id": "kadife_perde", "name": "Kadife Perde", "slot": "pencere", "price": 20,
		"desc": "Bordo kadife, altın püsküllü bağlar."},
	{"id": "sardunya", "name": "Sardunyalı Pencere", "slot": "pencere", "price": 25,
		"desc": "Mavi perde, pencere önünde kırmızı sardunyalar."},
	# köşe
	{"id": "saksi", "name": "Saksı Çiçeği", "slot": "kose", "price": 8,
		"desc": "Büyük toprak saksıda yemyeşil bir kauçuk."},
	{"id": "sandik", "name": "Çeyiz Sandığı", "slot": "kose", "price": 20,
		"desc": "Pirinç kuşaklı sandık, üstünde yorganlar."},
	{"id": "semaver", "name": "Semaver", "slot": "kose", "price": 30,
		"desc": "Pırıl pırıl semaver. Çay hep demde."},
	{"id": "tv_dolabi", "name": "Televizyon Dolabı", "slot": "kose", "price": 50,
		"desc": "Ahşap dolap, üstünde tüplü televizyon ve dantel."},
	# lamba
	{"id": "gaz_lambasi", "name": "Gaz Lambası", "slot": "lamba", "price": 6,
		"desc": "Tabure üstünde eski usul, tatlı ışıklı lamba."},
	{"id": "abajur", "name": "Püsküllü Abajur", "slot": "lamba", "price": 12,
		"desc": "Pembe şapkalı, püsküllü ayaklı abajur."},
	{"id": "mozaik", "name": "Mozaik Lamba", "slot": "lamba", "price": 25, "hang": true,
		"desc": "Rengârenk camlı Osmanlı lambası, tavandan sarkar."},
	{"id": "avize", "name": "Kristal Avize", "slot": "lamba", "price": 55, "hang": true,
		"desc": "Işıl ışıl kristal avize. Konak gibi ev!"},
]

const CREAM := "#fbf3e2"
const WOOD := "#a86f48"
const WOOD_DARK := "#6b4a35"
const BRASS := "#d9a72e"

static var _glows := {}


static func get_item(id: String) -> Dictionary:
	for it in ALL:
		if it["id"] == id:
			return it
	return {}


static func items_for(slot: String) -> Array:
	var out := []
	for it in ALL:
		if it["slot"] == slot:
			out.append(it)
	return out


static func slot_name(slot: String) -> String:
	for s in SLOTS:
		if s["id"] == slot:
			return s["name"]
	return slot


## Boş yerde görünen varsayılan (yalnız perde için: düz krem perde). Yoksa null.
static func build_default(slot: String) -> Node3D:
	if slot == "pencere":
		var n := Node3D.new()
		_curtains(n, "#efe0c2", "#e2cfa8")
		return n
	return null


static func build(id: String) -> Node3D:
	var n := Node3D.new()
	n.name = id
	match id:
		"paspas": _paspas(n)
		"kilim": _kilim(n)
		"cicekli_hali": _cicekli_hali(n)
		"gobekli_hali": _gobekli_hali(n)
		"minder": _minder(n)
		"berjer": _berjer(n)
		"sedir": _sedir(n)
		"kanepe": _kanepe(n)
		"sehpa": _sehpa(n)
		"sini": _sini(n)
		"cezve": _cezve(n)
		"yemek_masasi": _yemek_masasi(n)
		"nazarlik": _nazarlik(n)
		"aile_foto": _aile_foto(n)
		"goblen": _goblen(n)
		"guguklu": _guguklu(n)
		"dantel_perde": _dantel_perde(n)
		"cicekli_perde": _cicekli_perde(n)
		"kadife_perde": _kadife_perde(n)
		"sardunya": _sardunya(n)
		"saksi": _saksi(n)
		"sandik": _sandik(n)
		"semaver": _semaver(n)
		"tv_dolabi": _tv_dolabi(n)
		"gaz_lambasi": _gaz_lambasi(n)
		"abajur": _abajur(n)
		"mozaik": _mozaik(n)
		"avize": _avize(n)
	return n


# --- yardımcılar --------------------------------------------------------------

static func _p(n: Node3D, mesh: Mesh, color: String, pos: Vector3, rot := Vector3.ZERO, scl := Vector3.ONE) -> MeshInstance3D:
	return Models.part(n, mesh, color, pos, rot, scl)


## Kendinden ışıklı (lamba camı, ampul) malzeme; birleştirmede ayrı yüzey olur.
static func _glow(n: Node3D, mesh: Mesh, color: String, pos: Vector3, energy := 0.9, scl := Vector3.ONE) -> MeshInstance3D:
	var mi := _p(n, mesh, color, pos, Vector3.ZERO, scl)
	var key := color + str(energy)
	if not _glows.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(color)
		m.roughness = 0.6
		m.emission_enabled = true
		m.emission = Color(color)
		m.emission_energy_multiplier = energy
		_glows[key] = m
	mi.material_override = _glows[key]
	return mi


## Yuvarlak dantel: düz disk + kenarında fisto boncukları.
static func _doily(n: Node3D, at: Vector3, r: float, rot := Vector3.ZERO) -> void:
	var b := Basis.from_euler(rot * PI / 180.0)
	_p(n, Models.cyl(r, r, 0.012, 16), CREAM, at, rot)
	var k := maxi(10, int(r * 40))
	for i in k:
		var a := TAU * i / k
		_p(n, Models.ball(r * 0.13, 6), CREAM, at + b * Vector3(cos(a) * r, 0, sin(a) * r), rot, Vector3(1, 0.4, 1))


## Çay bardağı ve tabağı.
static func _tea(n: Node3D, at: Vector3) -> void:
	_p(n, Models.cyl(0.06, 0.06, 0.012, 10), "#ffffff", at + Vector3(0, 0.006, 0))
	_p(n, Models.cyl(0.035, 0.026, 0.1, 8), "#b8321f", at + Vector3(0, 0.06, 0))
	_p(n, Models.cyl(0.037, 0.037, 0.012, 8), "#f2d48a", at + Vector3(0, 0.11, 0))


static func _tassel(n: Node3D, at: Vector3, color: String) -> void:
	_p(n, Models.ball(0.035, 6), color, at)
	_p(n, Models.cyl(0.012, 0.035, 0.07, 6), color, at + Vector3(0, -0.05, 0))


static func _flower(n: Node3D, at: Vector3, r: float, petal: String, mid: String, rot := Vector3.ZERO) -> void:
	var b := Basis.from_euler(rot * PI / 180.0)
	for i in 5:
		var a := TAU * i / 5.0
		_p(n, Models.ball(r * 0.55, 6), petal, at + b * Vector3(cos(a) * r * 0.6, 0, sin(a) * r * 0.6), rot, Vector3(1, 0.35, 1))
	_p(n, Models.ball(r * 0.35, 6), mid, at + b * Vector3(0, r * 0.08, 0), rot, Vector3(1, 0.5, 1))


# --- halılar -----------------------------------------------------------------

static func _paspas(n: Node3D) -> void:
	var colors := ["#e8b33a", "#d6577a", "#3e8fb0", "#f4efe6", "#4f9a4a", "#c8412f"]
	for i in 6:
		var r := 0.95 - i * 0.16
		_p(n, Models.cyl(r, r, 0.03, 24), colors[i], Vector3(0, 0.015 + i * 0.004, 0), Vector3.ZERO, Vector3(1.25, 1, 1))


static func _kilim(n: Node3D) -> void:
	var w := 2.6
	var d := 1.7
	_p(n, Models.box(w, 0.03, d), "#c8412f", Vector3(0, 0.015, 0))
	for sz in [-1, 1]:
		_p(n, Models.box(w, 0.035, 0.14), "#2f3f6e", Vector3(0, 0.017, sz * (d / 2 - 0.07)))
		_p(n, Models.box(w, 0.036, 0.05), "#f2c94c", Vector3(0, 0.018, sz * (d / 2 - 0.2)))
	for sx in [-1, 1]:
		_p(n, Models.box(0.1, 0.035, d), "#2f3f6e", Vector3(sx * (w / 2 - 0.05), 0.017, 0))
		for i in 12:
			_p(n, Models.box(0.12, 0.012, 0.035), CREAM, Vector3(sx * (w / 2 + 0.05), 0.006, -d / 2 + 0.1 + i * (d - 0.2) / 11.0))
	var cols := ["#f2c94c", "#f4efe6", "#f2c94c", "#f4efe6"]
	for i in 4:
		var x := -0.93 + i * 0.62
		_p(n, Models.box(0.42, 0.036, 0.42), cols[i], Vector3(x, 0.018, 0), Vector3(0, 45, 0))
		_p(n, Models.box(0.24, 0.038, 0.24), "#2f3f6e", Vector3(x, 0.019, 0), Vector3(0, 45, 0))
		_p(n, Models.box(0.09, 0.04, 0.09), "#c8412f", Vector3(x, 0.02, 0), Vector3(0, 45, 0))
		for sz in [-1, 1]:
			_p(n, Models.box(0.12, 0.037, 0.12), "#4f8a5b", Vector3(x + 0.31, 0.018, sz * 0.48), Vector3(0, 45, 0))


static func _cicekli_hali(n: Node3D) -> void:
	var w := 2.5
	var d := 1.7
	_p(n, Models.box(w, 0.03, d), "#e7a3b4", Vector3(0, 0.015, 0))
	_p(n, Models.box(w - 0.3, 0.032, d - 0.3), "#f6d4dc", Vector3(0, 0.016, 0))
	_p(n, Models.box(w - 0.4, 0.034, d - 0.4), "#efbccb", Vector3(0, 0.017, 0))
	for i in 7:
		var x := -0.9 + (i % 4) * 0.6 + (0.3 if i >= 4 else 0.0)
		var z := -0.3 if i < 4 else 0.3
		_flower(n, Vector3(x, 0.04, z), 0.18, "#d6455f" if i % 2 == 0 else "#fdf6ea", "#f2c94c")
		_p(n, Models.ball(0.07, 6), "#5aa852", Vector3(x + 0.16, 0.035, z + 0.1), Vector3(0, 40, 0), Vector3(1.6, 0.25, 0.8))
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			_flower(n, Vector3(sx * (w / 2 - 0.08), 0.036, sz * (d / 2 - 0.08)), 0.09, "#d6455f", "#f2c94c")


static func _gobekli_hali(n: Node3D) -> void:
	var w := 2.8
	var d := 1.9
	_p(n, Models.box(w, 0.03, d), "#24365e", Vector3(0, 0.015, 0))
	_p(n, Models.box(w - 0.3, 0.032, d - 0.3), "#f2c94c", Vector3(0, 0.016, 0))
	_p(n, Models.box(w - 0.38, 0.034, d - 0.38), "#9a2a2a", Vector3(0, 0.017, 0))
	_p(n, Models.cyl(0.55, 0.55, 0.036, 8), "#24365e", Vector3(0, 0.018, 0), Vector3(0, 22.5, 0), Vector3(1.45, 1, 1))
	_p(n, Models.cyl(0.38, 0.38, 0.038, 8), "#f4efe6", Vector3(0, 0.019, 0), Vector3(0, 22.5, 0), Vector3(1.45, 1, 1))
	_p(n, Models.cyl(0.2, 0.2, 0.04, 8), "#c8412f", Vector3(0, 0.02, 0), Vector3(0, 22.5, 0), Vector3(1.45, 1, 1))
	for sx in [-1, 1]:
		_p(n, Models.prism(0.5, 0.036, 0.3), "#24365e", Vector3(sx * 0.95, 0.018, 0), Vector3(0, sx * 90, 0))
		for sz in [-1, 1]:
			_p(n, Models.box(0.3, 0.036, 0.3), "#24365e", Vector3(sx * 1.07, 0.018, sz * 0.62), Vector3(0, 45, 0))
			_p(n, Models.box(0.13, 0.038, 0.13), "#f2c94c", Vector3(sx * 1.07, 0.019, sz * 0.62), Vector3(0, 45, 0))
		for i in 14:
			_p(n, Models.box(0.12, 0.012, 0.035), CREAM, Vector3(sx * (w / 2 + 0.05), 0.006, -d / 2 + 0.1 + i * (d - 0.2) / 13.0))


# --- oturaklar ---------------------------------------------------------------

static func _cushion(n: Node3D, at: Vector3, size: Vector3, color: String, tassel := "") -> void:
	_p(n, Models.box(size.x, size.y, size.z), color, at)
	# yumuşak görünsün: üstü kubbe
	_p(n, Models.ball(0.5, 10), color, at + Vector3(0, size.y * 0.35, 0), Vector3.ZERO, Vector3(size.x * 0.96, size.y * 0.7, size.z * 0.96))
	if tassel != "":
		for sx in [-1, 1]:
			for sz in [-1, 1]:
				_p(n, Models.ball(0.04, 6), tassel, at + Vector3(sx * size.x / 2, 0, sz * size.z / 2))


static func _minder(n: Node3D) -> void:
	var cols := [["#c8412f", "#f2c94c"], ["#7a4e8a", "#f2c94c"], ["#e8892e", "#c8412f"]]
	for i in 3:
		var x := -0.75 + i * 0.75
		_cushion(n, Vector3(x, 0.08, 0.05), Vector3(0.62, 0.16, 0.62), cols[i][0], cols[i][1])
		# duvara dayalı arka yastık
		_cushion(n, Vector3(x, 0.4, -0.3), Vector3(0.55, 0.45, 0.14), cols[(i + 1) % 3][0])
		_p(n, Models.ball(0.07, 8), cols[i][1], Vector3(x, 0.4, -0.2), Vector3.ZERO, Vector3(1, 1, 0.4))
	_p(n, Models.cyl(0.24, 0.26, 0.28, 12), "#4f8a5b", Vector3(1.3, 0.14, 0.45))  # puf
	_p(n, Models.ball(0.25, 12, true), "#5aa06a", Vector3(1.3, 0.28, 0.45), Vector3.ZERO, Vector3(1, 0.4, 1))


static func _berjer(n: Node3D) -> void:
	var c := "#3e7fb0"
	var c2 := "#4f93c4"
	var at := Vector3(-0.3, 0, 0)
	_p(n, Models.box(1.0, 0.22, 0.8), WOOD_DARK, at + Vector3(0, 0.2, 0))
	_cushion(n, at + Vector3(0, 0.38, 0.05), Vector3(0.8, 0.16, 0.7), c2)
	_p(n, Models.box(1.0, 0.8, 0.2), c, at + Vector3(0, 0.75, -0.32), Vector3(-8, 0, 0))
	_p(n, Models.capsule(0.12, 1.0), c, at + Vector3(0, 1.15, -0.35), Vector3(0, 0, 90))
	for sx in [-1, 1]:
		_p(n, Models.box(0.16, 0.4, 0.78), c, at + Vector3(sx * 0.46, 0.5, 0))
		_p(n, Models.cyl(0.11, 0.11, 0.8, 10), c2, at + Vector3(sx * 0.46, 0.72, 0), Vector3(90, 0, 0))
		for sz in [-1, 1]:
			_p(n, Models.cyl(0.035, 0.025, 0.12, 6), WOOD_DARK, at + Vector3(sx * 0.42, 0.06, sz * 0.32))
	_doily(n, at + Vector3(0, 1.0, -0.21), 0.2, Vector3(80, 0, 0))
	_cushion(n, at + Vector3(0.05, 0.62, -0.18), Vector3(0.38, 0.3, 0.12), "#e8b33a")
	# ayak taburesi ve örgü sepeti
	_cushion(n, Vector3(0.75, 0.22, 0.45), Vector3(0.5, 0.14, 0.4), c2)
	_p(n, Models.box(0.46, 0.15, 0.36), WOOD_DARK, Vector3(0.75, 0.08, 0.45))
	_p(n, Models.cyl(0.18, 0.15, 0.22, 10), "#c9a46a", Vector3(1.25, 0.11, -0.05))
	_p(n, Models.ball(0.08, 8), "#d6577a", Vector3(1.2, 0.25, -0.05))
	_p(n, Models.ball(0.07, 8), "#4f9a4a", Vector3(1.32, 0.24, 0.0))
	_p(n, Models.cyl(0.008, 0.008, 0.35, 4), "#dddddd", Vector3(1.26, 0.35, -0.05), Vector3(0, 0, 25))


static func _sedir(n: Node3D) -> void:
	var w := 2.5
	_p(n, Models.box(w, 0.32, 0.8), WOOD, Vector3(0, 0.16, 0))
	_p(n, Models.box(w + 0.04, 0.04, 0.84), WOOD_DARK, Vector3(0, 0.32, 0))
	_cushion(n, Vector3(0, 0.42, 0.02), Vector3(w, 0.16, 0.78), "#b8322a")
	for i in 5:  # kilim çizgileri
		_p(n, Models.box(w, 0.012, 0.05), "#f2c94c" if i % 2 == 0 else "#2f3f6e", Vector3(0, 0.555, -0.25 + i * 0.12))
	# dantel saçak
	_p(n, Models.box(w, 0.07, 0.015), CREAM, Vector3(0, 0.35, 0.42))
	for i in 24:
		_p(n, Models.ball(0.035, 6), CREAM, Vector3(-w / 2 + 0.05 + i * (w - 0.1) / 23.0, 0.305, 0.425), Vector3.ZERO, Vector3(1, 1, 0.4))
	var cols := ["#d6577a", "#e8b33a", "#d6577a"]
	for i in 3:
		var x := -0.8 + i * 0.8
		_cushion(n, Vector3(x, 0.85, -0.3), Vector3(0.72, 0.5, 0.16), cols[i])
		_flower(n, Vector3(x, 0.88, -0.2), 0.11, CREAM, "#c8412f", Vector3(80, 0, 0))
	for sx in [-1, 1]:  # yanlarda silindir yastık
		_p(n, Models.cyl(0.15, 0.15, 0.6, 12), "#2f3f6e", Vector3(sx * (w / 2 - 0.15), 0.66, 0.0), Vector3(90, 0, 0))
		_p(n, Models.cyl(0.155, 0.155, 0.05, 12), "#f2c94c", Vector3(sx * (w / 2 - 0.15), 0.66, 0.3), Vector3(90, 0, 0))


static func _kanepe(n: Node3D) -> void:
	var c := "#3f8a5a"
	var c2 := "#4f9e68"
	var w := 2.3
	_p(n, Models.box(w, 0.25, 0.78), "#2f6a46", Vector3(0, 0.22, 0))
	for sx in [-1, 1]:
		_cushion(n, Vector3(sx * 0.48, 0.42, 0.06), Vector3(0.94, 0.16, 0.66), c2)
		_p(n, Models.box(0.24, 0.42, 0.8), c, Vector3(sx * (w / 2 - 0.1), 0.45, 0))
		_p(n, Models.cyl(0.14, 0.14, 0.8, 12), c, Vector3(sx * (w / 2 - 0.1), 0.68, 0), Vector3(90, 0, 0))
		_p(n, Models.cyl(0.08, 0.08, 0.81, 12), "#2f6a46", Vector3(sx * (w / 2 - 0.1), 0.68, 0), Vector3(90, 0, 0))
		for sz in [-1, 1]:
			_p(n, Models.ball(0.06, 8), BRASS, Vector3(sx * (w / 2 - 0.1), 0.06, sz * 0.32))
	_p(n, Models.box(w - 0.2, 0.62, 0.22), c, Vector3(0, 0.75, -0.3), Vector3(-6, 0, 0))
	_p(n, Models.capsule(0.13, w - 0.1), c, Vector3(0, 1.07, -0.32), Vector3(0, 0, 90))
	for i in 5:  # kadife kapitone düğmeleri
		_p(n, Models.ball(0.025, 6), "#2f6a46", Vector3(-0.8 + i * 0.4, 0.82, -0.18))
	_doily(n, Vector3(0, 1.02, -0.18), 0.22, Vector3(70, 0, 0))
	_cushion(n, Vector3(-0.7, 0.66, -0.12), Vector3(0.4, 0.34, 0.12), "#e8b33a", "#c8412f")
	_cushion(n, Vector3(0.7, 0.66, -0.12), Vector3(0.4, 0.34, 0.12), "#d6577a", "#f2c94c")


# --- masalar -----------------------------------------------------------------

static func _sehpa(n: Node3D) -> void:
	_p(n, Models.cyl(0.48, 0.48, 0.06, 18), WOOD, Vector3(0, 0.5, 0))
	_p(n, Models.cyl(0.05, 0.07, 0.48, 8), WOOD_DARK, Vector3(0, 0.25, 0))
	for i in 3:
		var a := TAU * i / 3.0
		_p(n, Models.box(0.36, 0.05, 0.07), WOOD_DARK, Vector3(cos(a) * 0.14, 0.03, sin(a) * 0.14), Vector3(0, -rad_to_deg(a), 0))
	_doily(n, Vector3(0, 0.535, 0), 0.4)
	_tea(n, Vector3(-0.15, 0.54, 0.1))
	_tea(n, Vector3(0.18, 0.54, 0.05))
	_p(n, Models.cyl(0.12, 0.08, 0.06, 10), "#e8e2d6", Vector3(0.0, 0.57, -0.17))  # şekerlik
	for i in 4:
		_p(n, Models.box(0.04, 0.04, 0.04), "#ffffff", Vector3(-0.03 + (i % 2) * 0.05, 0.61, -0.18 + (i / 2) * 0.04))


static func _sini(n: Node3D) -> void:
	for sx in [-1, 1]:  # katlanır ayak
		_p(n, Models.box(0.06, 0.38, 0.06), WOOD_DARK, Vector3(sx * 0.3, 0.17, 0), Vector3(0, 0, sx * 20))
		_p(n, Models.box(0.06, 0.38, 0.06), WOOD_DARK, Vector3(0, 0.17, sx * 0.3), Vector3(sx * 20, 0, 0))
	_p(n, Models.cyl(0.72, 0.72, 0.05, 22), BRASS, Vector3(0, 0.36, 0))
	_p(n, Models.cyl(0.62, 0.62, 0.052, 22), "#c9962a", Vector3(0, 0.362, 0))
	var t := TorusMesh.new()
	t.inner_radius = 0.68
	t.outer_radius = 0.75
	t.rings = 24
	t.ring_segments = 4
	_p(n, t, BRASS, Vector3(0, 0.39, 0))
	# yemekler
	_p(n, Models.cyl(0.18, 0.12, 0.08, 12), "#f4efe6", Vector3(0, 0.43, 0))
	_p(n, Models.ball(0.15, 10, true), "#e8a33a", Vector3(0, 0.44, 0), Vector3.ZERO, Vector3(1, 0.6, 1))  # pilav
	_p(n, Models.cyl(0.11, 0.08, 0.07, 10), "#3e6fb5", Vector3(0.38, 0.42, 0.12))
	_p(n, Models.cyl(0.09, 0.09, 0.02, 10), "#c8412f", Vector3(0.38, 0.46, 0.12))  # çorba
	_p(n, Models.cyl(0.11, 0.08, 0.07, 10), "#3e6fb5", Vector3(-0.36, 0.42, 0.18))
	_p(n, Models.ball(0.08, 8), "#5aa852", Vector3(-0.36, 0.47, 0.18), Vector3.ZERO, Vector3(1, 0.6, 1))
	for i in 3:
		_p(n, Models.box(0.22, 0.05, 0.08), "#d99a4e", Vector3(-0.1 + i * 0.1, 0.415, -0.38), Vector3(0, i * 15, 0))  # ekmek
	for a in [0.4, 2.0, 3.6, 5.0]:
		_cushion(n, Vector3(cos(a) * 1.05, 0.07, sin(a) * 0.95), Vector3(0.5, 0.14, 0.5), "#c8412f" if a < 3 else "#7a4e8a", "#f2c94c")


static func _cezve(n: Node3D) -> void:
	_p(n, Models.cyl(0.42, 0.42, 0.06, 8), WOOD_DARK, Vector3(0, 0.45, 0), Vector3(0, 22.5, 0))
	_p(n, Models.cyl(0.38, 0.32, 0.4, 8), "#5c3a26", Vector3(0, 0.22, 0), Vector3(0, 22.5, 0))
	for i in 8:  # sedef kakma
		var a := TAU * (i + 0.5) / 8.0 + PI / 8.0
		_p(n, Models.box(0.08, 0.14, 0.02), "#f4f0e8", Vector3(cos(a) * 0.35, 0.24, sin(a) * 0.35), Vector3(0, 90 - rad_to_deg(a), 0))
		_p(n, Models.ball(0.025, 6), "#f4f0e8", Vector3(cos(a) * 0.4, 0.45, sin(a) * 0.4))
	_p(n, Models.cyl(0.3, 0.3, 0.03, 16), "#c8743a", Vector3(0, 0.495, 0))
	_p(n, Models.cyl(0.29, 0.29, 0.035, 16), "#d98a4a", Vector3(0, 0.5, 0), Vector3.ZERO, Vector3(0.9, 1, 0.9))
	# cezve
	_p(n, Models.cyl(0.07, 0.09, 0.16, 10), "#c8743a", Vector3(-0.1, 0.6, 0.0))
	_p(n, Models.cyl(0.08, 0.06, 0.04, 10), "#d98a4a", Vector3(-0.1, 0.7, 0.0))
	_p(n, Models.box(0.25, 0.025, 0.025), "#c8743a", Vector3(-0.27, 0.66, 0.0), Vector3(0, 0, 15))
	for x in [0.1, 0.22]:  # fincanlar
		var z := 0.08 if x < 0.15 else -0.08
		_p(n, Models.cyl(0.065, 0.065, 0.012, 10), "#ffffff", Vector3(x, 0.52, z))
		_p(n, Models.cyl(0.045, 0.035, 0.07, 10), "#ffffff", Vector3(x, 0.56, z))
		_p(n, Models.cyl(0.046, 0.046, 0.012, 10), "#c8412f", Vector3(x, 0.59, z))
		_p(n, Models.cyl(0.038, 0.038, 0.01, 10), "#3b2a1e", Vector3(x, 0.595, z))
	_p(n, Models.box(0.1, 0.04, 0.1), "#f2c0d0", Vector3(0.05, 0.53, -0.15))  # lokum
	_p(n, Models.box(0.08, 0.04, 0.08), "#ffffff", Vector3(0.0, 0.53, -0.2))


static func _yemek_masasi(n: Node3D) -> void:
	_p(n, Models.box(1.5, 0.06, 0.85), WOOD, Vector3(0, 0.72, 0))
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			_p(n, Models.cyl(0.04, 0.03, 0.7, 8), WOOD_DARK, Vector3(sx * 0.65, 0.35, sz * 0.34))
	_p(n, Models.box(1.56, 0.02, 0.6), "#ffffff", Vector3(0, 0.76, 0))  # örtü
	for i in 16:
		_p(n, Models.ball(0.03, 6), "#ffffff", Vector3(-0.75 + i * 0.1, 0.75, 0.3), Vector3.ZERO, Vector3(1, 1, 0.5))
		_p(n, Models.ball(0.03, 6), "#ffffff", Vector3(-0.75 + i * 0.1, 0.75, -0.3), Vector3.ZERO, Vector3(1, 1, 0.5))
	_p(n, Models.cyl(0.18, 0.1, 0.1, 12), "#3e8fb0", Vector3(0, 0.82, 0))  # meyve tası
	for p in [Vector3(-0.07, 0.9, 0), Vector3(0.07, 0.9, 0.04), Vector3(0, 0.92, -0.06), Vector3(0.02, 0.97, 0.01)]:
		_p(n, Models.ball(0.07, 8), "#e04a35" if p.x <= 0 else "#f5a93a", p)
	_p(n, Models.capsule(0.03, 0.2), "#f2d04a", Vector3(0.1, 0.94, -0.03), Vector3(0, 30, 70))
	for sx in [-1, 1]:
		_p(n, Models.cyl(0.08, 0.08, 0.012, 12), "#ffffff", Vector3(sx * 0.45, 0.775, 0.05))
		var ch := Vector3(sx * 0.98, 0, 0)
		_p(n, Models.box(0.45, 0.05, 0.42), WOOD, ch + Vector3(0, 0.45, 0))
		_cushion(n, ch + Vector3(0, 0.5, 0), Vector3(0.38, 0.06, 0.36), "#c8412f")
		_p(n, Models.box(0.05, 0.6, 0.42), WOOD, ch + Vector3(sx * 0.21, 0.75, 0))
		_p(n, Models.box(0.04, 0.14, 0.3), WOOD_DARK, ch + Vector3(sx * 0.22, 0.85, 0))
		for dx in [-1, 1]:
			for dz in [-1, 1]:
				_p(n, Models.box(0.04, 0.44, 0.04), WOOD_DARK, ch + Vector3(dx * 0.19, 0.22, dz * 0.18))


# --- duvar -------------------------------------------------------------------

static func _nazarlik(n: Node3D) -> void:
	_p(n, Models.cyl(0.006, 0.006, 0.35, 4), "#c8412f", Vector3(0, 0.2, 0.03))
	_p(n, Models.ball(0.03, 6), BRASS, Vector3(0, 0.37, 0.03))
	var layers := [[0.3, "#1f4fa0"], [0.21, "#ffffff"], [0.13, "#5ab4e0"], [0.06, "#14182a"]]
	for i in layers.size():
		_p(n, Models.cyl(layers[i][0], layers[i][0], 0.04, 20), layers[i][1], Vector3(0, -0.15, 0.04 + i * 0.012), Vector3(90, 0, 0))
	_p(n, Models.ball(0.022, 6), "#ffffff", Vector3(0.03, -0.12, 0.1))
	for i in 4:  # alttan sarkan boncuklar
		_p(n, Models.ball(0.035, 6), "#1f4fa0" if i % 2 == 0 else "#f2c94c", Vector3(0, -0.5 - i * 0.07, 0.04))
	_tassel(n, Vector3(0, -0.8, 0.04), "#c8412f")


static func _frame(n: Node3D, at: Vector3, w: float, h: float, frame: String, inside: String) -> void:
	_p(n, Models.box(w, h, 0.05), frame, at + Vector3(0, 0, 0.025))
	_p(n, Models.box(w - 0.08, h - 0.08, 0.052), inside, at + Vector3(0, 0, 0.028))


static func _aile_foto(n: Node3D) -> void:
	# büyük düğün fotoğrafı
	_frame(n, Vector3(0, 0.05, 0), 0.5, 0.6, BRASS, "#efe6d0")
	_p(n, Models.ball(0.07, 8), "#f6cfa5", Vector3(-0.08, 0.12, 0.06), Vector3.ZERO, Vector3(1, 1, 0.3))
	_p(n, Models.ball(0.07, 8), "#f6cfa5", Vector3(0.08, 0.12, 0.06), Vector3.ZERO, Vector3(1, 1, 0.3))
	_p(n, Models.ball(0.08, 8), "#ffffff", Vector3(-0.08, 0.19, 0.055), Vector3.ZERO, Vector3(1, 0.6, 0.3))  # duvak
	_p(n, Models.box(0.12, 0.18, 0.02), "#ffffff", Vector3(-0.08, -0.04, 0.06))
	_p(n, Models.box(0.12, 0.18, 0.02), "#2c3e50", Vector3(0.08, -0.04, 0.06))
	# torunlar
	_frame(n, Vector3(-0.52, -0.02, 0), 0.36, 0.3, WOOD, "#bfe3f0")
	for i in 3:
		var x := -0.62 + i * 0.1
		_p(n, Models.ball(0.04, 8), "#f6cfa5", Vector3(x, -0.0, 0.06), Vector3.ZERO, Vector3(1, 1, 0.3))
		_p(n, Models.box(0.07, 0.07, 0.02), ["#d6577a", "#3e8fb0", "#e8b33a"][i], Vector3(x, -0.08, 0.06))
	# bayram
	_frame(n, Vector3(0.5, 0.12, 0), 0.32, 0.38, WOOD, "#d8eac8")
	_p(n, Models.ball(0.06, 8), "#f6cfa5", Vector3(0.5, 0.15, 0.06), Vector3.ZERO, Vector3(1, 1, 0.3))
	_p(n, Models.ball(0.065, 8), "#d6577a", Vector3(0.5, 0.18, 0.055), Vector3.ZERO, Vector3(1.1, 0.8, 0.3))
	_p(n, Models.box(0.12, 0.12, 0.02), "#4f8a5b", Vector3(0.5, 0.04, 0.06))
	_frame(n, Vector3(0.48, -0.25, 0), 0.24, 0.2, WOOD_DARK, "#f2d8a8")


static func _goblen(n: Node3D) -> void:
	_p(n, Models.box(1.1, 0.8, 0.06), "#b8862e", Vector3(0, 0, 0.03))
	_p(n, Models.box(1.16, 0.06, 0.08), BRASS, Vector3(0, 0.4, 0.04))
	_p(n, Models.box(1.16, 0.06, 0.08), BRASS, Vector3(0, -0.4, 0.04))
	_p(n, Models.box(0.95, 0.65, 0.062), "#a8d8e8", Vector3(0, 0, 0.035))
	_p(n, Models.box(0.95, 0.24, 0.064), "#6aa850", Vector3(0, -0.205, 0.036))  # çayır
	_p(n, Models.prism(0.6, 0.3, 0.02), "#4f8a46", Vector3(-0.2, -0.0, 0.07))  # tepeler
	_p(n, Models.prism(0.5, 0.22, 0.02), "#5e9a50", Vector3(0.25, -0.03, 0.072))
	_p(n, Models.cyl(0.07, 0.07, 0.02, 12), "#f7cf4a", Vector3(0.32, 0.2, 0.07), Vector3(90, 0, 0))  # güneş
	_p(n, Models.box(0.16, 0.12, 0.02), "#f4efe6", Vector3(-0.22, -0.13, 0.08))  # köy evi
	_p(n, Models.prism(0.2, 0.08, 0.02), "#c8553a", Vector3(-0.22, -0.03, 0.08))
	_p(n, Models.ball(0.06, 6), "#2f6a3a", Vector3(0.05, -0.12, 0.075), Vector3.ZERO, Vector3(1, 1.4, 0.3))  # ağaç
	for i in 6:
		_p(n, Models.ball(0.018, 6), ["#e04a4a", "#f4efe6", "#f2c94c"][i % 3], Vector3(-0.38 + i * 0.15, -0.27, 0.075))


static func _guguklu(n: Node3D) -> void:
	_p(n, Models.box(0.5, 0.55, 0.15), "#7a4e2a", Vector3(0, 0, 0.075))
	_p(n, Models.prism(0.7, 0.28, 0.2), "#5c3a26", Vector3(0, 0.41, 0.09))
	_p(n, Models.box(0.12, 0.12, 0.04), "#3b2a1e", Vector3(0, 0.2, 0.15))  # kuş kapısı
	_p(n, Models.ball(0.05, 8), "#f2c94c", Vector3(0, 0.2, 0.2))  # guguk kuşu
	_p(n, Models.prism(0.03, 0.03, 0.03), "#e8892e", Vector3(0, 0.2, 0.25), Vector3(-90, 0, 0))
	_p(n, Models.cyl(0.16, 0.16, 0.03, 18), CREAM, Vector3(0, -0.06, 0.16), Vector3(90, 0, 0))
	for i in 12:
		var a := TAU * i / 12.0
		_p(n, Models.box(0.015, 0.035, 0.01), "#3b2a1e", Vector3(sin(a) * 0.13, -0.06 + cos(a) * 0.13, 0.18), Vector3(0, 0, -rad_to_deg(a)))
	_p(n, Models.box(0.02, 0.1, 0.01), "#3b2a1e", Vector3(0, -0.02, 0.185))
	_p(n, Models.box(0.075, 0.018, 0.01), "#3b2a1e", Vector3(0.035, -0.06, 0.19))
	for sx in [-1, 1]:  # oyma yapraklar
		_p(n, Models.ball(0.07, 6), "#4f8a46", Vector3(sx * 0.22, 0.3, 0.12), Vector3.ZERO, Vector3(1.2, 0.6, 0.3))
		_p(n, Models.ball(0.04, 6), "#6a4a2a", Vector3(sx * 0.25, -0.27, 0.12))
	# sarkaç ve kozalaklar
	_p(n, Models.cyl(0.01, 0.01, 0.4, 4), BRASS, Vector3(0, -0.47, 0.1))
	_p(n, Models.cyl(0.07, 0.07, 0.02, 12), BRASS, Vector3(0, -0.68, 0.1), Vector3(90, 0, 0))
	for sx in [-1, 1]:
		_p(n, Models.cyl(0.006, 0.006, 0.55, 4), "#3b3b3b", Vector3(sx * 0.12, -0.55, 0.08))
		_p(n, Models.capsule(0.045, 0.18), "#7a4e2a", Vector3(sx * 0.12, -0.88 + (0.12 if sx > 0 else 0.0), 0.08))


# --- perdeler ----------------------------------------------------------------
# Pencere ortası kök; pencere yaklaşık 1.4 en, 1.4 boy.

static func _curtains(n: Node3D, color: String, shade: String, tie := "") -> void:
	_p(n, Models.cyl(0.03, 0.03, 2.1, 8), WOOD_DARK, Vector3(0, 0.95, 0.12), Vector3(0, 0, 90))
	for sx in [-1, 1]:
		_p(n, Models.ball(0.06, 8), WOOD_DARK, Vector3(sx * 1.07, 0.95, 0.12))
		for i in 3:  # kıvrımlı kumaş
			var x: float = sx * (0.98 - i * 0.12)
			_p(n, Models.capsule(0.075, 1.85), color if i % 2 == 0 else shade, Vector3(x, 0.02, 0.1 + (i % 2) * 0.02), Vector3(0, 0, sx * -2 * i))
		if tie != "":
			_p(n, Models.capsule(0.03, 0.42), tie, Vector3(sx * 0.86, -0.2, 0.2), Vector3(0, 0, 90))
			_tassel(n, Vector3(sx * 0.7, -0.24, 0.22), tie)


static func _valance(n: Node3D, color: String, w := 2.1) -> void:
	_p(n, Models.box(w, 0.26, 0.06), color, Vector3(0, 0.85, 0.16))


static func _dantel_perde(n: Node3D) -> void:
	_curtains(n, "#ffffff", "#f1ede4")
	_valance(n, "#ffffff")
	for i in 22:
		_p(n, Models.ball(0.05, 6), "#ffffff", Vector3(-1.0 + i * 2.0 / 21.0, 0.72, 0.17), Vector3.ZERO, Vector3(1, 1, 0.4))
	for i in 12:  # dantel delikleri
		_p(n, Models.ball(0.025, 6), "#e8e0d0", Vector3(-0.95 + i * 1.9 / 11.0, 0.86, 0.195), Vector3.ZERO, Vector3(1, 1, 0.3))
	# pencere ortasına ince tül
	_p(n, Models.box(1.3, 1.25, 0.01), "#fffaf0", Vector3(0, 0.0, 0.05))


static func _cicekli_perde(n: Node3D) -> void:
	_curtains(n, "#f6cf4a", "#efc03a", "#c8412f")
	_valance(n, "#f6cf4a")
	for sx in [-1, 1]:
		for i in 6:
			var c := "#d6455f" if i % 2 == 0 else "#ffffff"
			_flower(n, Vector3(sx * (0.92 + (i % 2) * 0.1), 0.7 - i * 0.28, 0.2), 0.07, c, "#4f8a46", Vector3(90, 0, 0))
	for i in 6:
		_flower(n, Vector3(-0.85 + i * 0.34, 0.85, 0.2), 0.07, "#d6455f", "#ffffff", Vector3(90, 0, 0))


static func _kadife_perde(n: Node3D) -> void:
	_curtains(n, "#8e1f2a", "#76182a", BRASS)
	_valance(n, "#8e1f2a", 2.2)
	for i in 22:  # altın saçak
		_p(n, Models.box(0.02, 0.1, 0.02), BRASS, Vector3(-1.05 + i * 2.1 / 21.0, 0.67, 0.19))
	_p(n, Models.box(2.2, 0.04, 0.07), BRASS, Vector3(0, 0.72, 0.17))


static func _sardunya(n: Node3D) -> void:
	_curtains(n, "#7ab8e0", "#5aa0d0", "#ffffff")
	_valance(n, "#ffffff")
	for i in 6:
		_p(n, Models.box(0.17, 0.26, 0.065), "#7ab8e0", Vector3(-0.92 + i * 0.368, 0.85, 0.17))
	for i in 3:
		var x := -0.42 + i * 0.42
		_p(n, Models.cyl(0.11, 0.08, 0.18, 10), "#c96a43", Vector3(x, -0.6, 0.18))
		_p(n, Models.ball(0.14, 8), "#3f8a46", Vector3(x, -0.43, 0.18))
		for k in 4:
			var a := k * TAU / 4.0 + i
			_p(n, Models.ball(0.055, 6), "#e03a3a", Vector3(x + cos(a) * 0.08, -0.33, 0.18 + sin(a) * 0.08))


# --- köşe --------------------------------------------------------------------

static func _saksi(n: Node3D) -> void:
	_p(n, Models.cyl(0.26, 0.19, 0.45, 12), "#c96a43", Vector3(0, 0.22, 0))
	_p(n, Models.cyl(0.28, 0.28, 0.07, 12), "#b05a38", Vector3(0, 0.45, 0))
	_p(n, Models.cyl(0.03, 0.04, 0.9, 6), "#6b4a35", Vector3(0, 0.85, 0))
	var leaves := [Vector3(0.18, 0.75, 0.1), Vector3(-0.2, 0.85, 0.05), Vector3(0.15, 1.05, -0.1), Vector3(-0.12, 1.15, 0.12),
		Vector3(0.05, 1.32, 0.0), Vector3(0.22, 1.25, 0.12), Vector3(-0.22, 1.02, -0.12)]
	for i in leaves.size():
		var p: Vector3 = leaves[i]
		_p(n, Models.ball(0.15, 8), "#3f8a46" if i % 2 == 0 else "#2f7a3e", p, Vector3(0, i * 50, atan2(p.x, 0.3) * 40), Vector3(1.5, 0.5, 0.9))


static func _sandik(n: Node3D) -> void:
	_p(n, Models.box(1.0, 0.5, 0.55), "#8a5a3b", Vector3(0, 0.25, 0))
	_p(n, Models.box(1.04, 0.12, 0.59), "#6b4a35", Vector3(0, 0.55, 0))
	for x in [-0.32, 0.32]:
		_p(n, Models.box(0.06, 0.62, 0.6), BRASS, Vector3(x, 0.31, 0))
	_p(n, Models.box(0.1, 0.12, 0.03), BRASS, Vector3(0, 0.42, 0.29))
	for i in 6:  # oyma
		_p(n, Models.ball(0.035, 6), "#c9a46a", Vector3(-0.15 + (i % 3) * 0.15, 0.2 + (i / 3) * 0.1, 0.28), Vector3.ZERO, Vector3(1, 1, 0.3))
	# katlanmış yorganlar
	var cols := ["#d6577a", "#e8b33a", "#4f8a5b"]
	for i in 3:
		_cushion(n, Vector3(0, 0.66 + i * 0.12, 0), Vector3(0.82 - i * 0.06, 0.1, 0.48 - i * 0.03), cols[i])
	_doily(n, Vector3(0, 0.98, 0), 0.18)


static func _semaver(n: Node3D) -> void:
	_p(n, Models.cyl(0.36, 0.36, 0.05, 14), WOOD, Vector3(0, 0.6, 0))
	for i in 3:
		var a := TAU * i / 3.0 + 0.5
		_p(n, Models.cyl(0.03, 0.025, 0.6, 6), WOOD_DARK, Vector3(cos(a) * 0.25, 0.3, sin(a) * 0.25))
	_doily(n, Vector3(0, 0.63, 0), 0.32)
	_p(n, Models.cyl(0.24, 0.24, 0.02, 14), "#c0c6cc", Vector3(0, 0.645, 0))  # tepsi
	_p(n, Models.cyl(0.11, 0.13, 0.08, 10), BRASS, Vector3(0, 0.69, 0))
	_p(n, Models.cyl(0.15, 0.12, 0.38, 14), "#d9a72e", Vector3(0, 0.92, 0))
	_p(n, Models.ball(0.15, 12), "#e8b33a", Vector3(0, 1.1, 0), Vector3.ZERO, Vector3(1, 0.6, 1))
	_p(n, Models.cyl(0.04, 0.05, 0.1, 8), BRASS, Vector3(0, 1.19, 0))
	_p(n, Models.cyl(0.08, 0.1, 0.12, 10), "#ffffff", Vector3(0, 1.3, 0))  # demlik
	_p(n, Models.ball(0.08, 10, true), "#ffffff", Vector3(0, 1.36, 0))
	_p(n, Models.ball(0.025, 6), "#3e6fb5", Vector3(0, 1.45, 0))
	for sx in [-1, 1]:
		var t := TorusMesh.new()
		t.inner_radius = 0.04
		t.outer_radius = 0.06
		t.rings = 10
		t.ring_segments = 4
		_p(n, t, BRASS, Vector3(sx * 0.17, 1.02, 0), Vector3(90, 0, 90))
	_p(n, Models.cyl(0.015, 0.02, 0.12, 6), BRASS, Vector3(0, 0.82, 0.16), Vector3(80, 0, 0))  # musluk
	for i in 3:
		var a := PI * 0.3 + i * 0.5
		_tea(n, Vector3(cos(a) * 0.24, 0.63, sin(a) * 0.24))


static func _tv_dolabi(n: Node3D) -> void:
	_p(n, Models.box(1.05, 0.6, 0.5), "#8a5a3b", Vector3(0, 0.34, 0))
	_p(n, Models.box(1.1, 0.05, 0.54), "#6b4a35", Vector3(0, 0.66, 0))
	for sx in [-1, 1]:
		_p(n, Models.box(0.44, 0.44, 0.02), "#a06a45", Vector3(sx * 0.25, 0.34, 0.255))
		_p(n, Models.ball(0.03, 6), BRASS, Vector3(sx * 0.06, 0.34, 0.27))
		for sz in [-1, 1]:
			_p(n, Models.cyl(0.04, 0.03, 0.06, 6), "#5c3a26", Vector3(sx * 0.45, 0.03, sz * 0.18))
	_doily(n, Vector3(0, 0.69, 0), 0.32)
	# tüplü televizyon
	_p(n, Models.box(0.72, 0.52, 0.42), "#d8d2c4", Vector3(-0.05, 0.96, -0.02))
	_p(n, Models.box(0.6, 0.42, 0.3), "#b8b2a4", Vector3(-0.05, 0.96, -0.2))
	_p(n, Models.box(0.5, 0.38, 0.02), "#2a3e5a", Vector3(-0.1, 0.97, 0.2))
	_p(n, Models.box(0.36, 0.08, 0.025), "#4a7aa8", Vector3(-0.14, 1.07, 0.2))  # ekranda ışık
	for i in 2:
		_p(n, Models.cyl(0.025, 0.025, 0.02, 8), "#3b3b3b", Vector3(0.24, 1.07 - i * 0.1, 0.2), Vector3(90, 0, 0))
	for sx in [-1, 1]:  # anten
		_p(n, Models.cyl(0.008, 0.008, 0.45, 4), "#5c5c5c", Vector3(-0.05 + sx * 0.1, 1.42, -0.05), Vector3(0, 0, sx * -25))
	_p(n, Models.ball(0.05, 8), "#3b3b3b", Vector3(-0.05, 1.23, -0.05))
	_p(n, Models.cyl(0.05, 0.07, 0.18, 10), "#3e8fb0", Vector3(0.43, 0.8, 0.1))  # vazo
	_p(n, Models.ball(0.05, 6), "#e04a4a", Vector3(0.43, 0.93, 0.1))


# --- lambalar ----------------------------------------------------------------

static func _gaz_lambasi(n: Node3D) -> void:
	_p(n, Models.cyl(0.22, 0.22, 0.05, 12), WOOD, Vector3(0, 0.45, 0))
	for i in 3:
		var a := TAU * i / 3.0
		_p(n, Models.cyl(0.025, 0.03, 0.45, 6), WOOD_DARK, Vector3(cos(a) * 0.15, 0.22, sin(a) * 0.15))
	_doily(n, Vector3(0, 0.48, 0), 0.18)
	_p(n, Models.cyl(0.08, 0.1, 0.08, 10), "#c8743a", Vector3(0, 0.53, 0))
	_p(n, Models.ball(0.1, 10), "#c8743a", Vector3(0, 0.6, 0), Vector3.ZERO, Vector3(1, 0.5, 1))
	_glow(n, Models.ball(0.09, 10), "#ffd890", Vector3(0, 0.75, 0), 1.0, Vector3(1, 1.4, 1))
	_glow(n, Models.ball(0.035, 6), "#ff9a3a", Vector3(0, 0.73, 0), 1.6)
	_p(n, Models.cyl(0.05, 0.06, 0.04, 10), "#3b3b3b", Vector3(0, 0.89, 0))


static func _abajur(n: Node3D) -> void:
	_p(n, Models.cyl(0.18, 0.2, 0.05, 14), BRASS, Vector3(0, 0.025, 0))
	_p(n, Models.cyl(0.025, 0.025, 1.3, 8), BRASS, Vector3(0, 0.68, 0))
	_p(n, Models.ball(0.05, 8), BRASS, Vector3(0, 0.6, 0))
	_glow(n, Models.cyl(0.17, 0.3, 0.36, 14), "#f6b8b0", Vector3(0, 1.42, 0), 0.7)
	_p(n, Models.cyl(0.18, 0.18, 0.03, 14), "#c8412f", Vector3(0, 1.6, 0))
	_p(n, Models.cyl(0.305, 0.305, 0.03, 14), "#c8412f", Vector3(0, 1.24, 0))
	for i in 14:  # püsküller
		var a := TAU * i / 14.0
		_p(n, Models.ball(0.025, 6), "#c8412f", Vector3(cos(a) * 0.3, 1.19, sin(a) * 0.3))


static func _chain(n: Node3D, top: float, bottom: float) -> void:
	_p(n, Models.cyl(0.012, 0.012, top - bottom, 4), BRASS, Vector3(0, (top + bottom) / 2, 0))
	_p(n, Models.cyl(0.12, 0.12, 0.04, 10), BRASS, Vector3(0, top, 0))


static func _mozaik(n: Node3D) -> void:
	_chain(n, 0.9, -0.15)
	_p(n, Models.cyl(0.06, 0.12, 0.08, 8), BRASS, Vector3(0, -0.18, 0))
	_glow(n, Models.ball(0.24, 10), "#ffcf7a", Vector3(0, -0.45, 0), 1.0)
	var cols := ["#e04a4a", "#3e8fb0", "#4f9a4a", "#f2c94c", "#8e5bb5", "#f07a3a"]
	for i in 18:  # renkli cam parçaları
		var a := TAU * i / 9.0 + (0.35 if i >= 9 else 0.0)
		var yy := -0.38 if i < 9 else -0.53
		var r := 0.235 if i < 9 else 0.22
		_glow(n, Models.ball(0.06, 6), cols[i % 6], Vector3(cos(a) * r, yy, sin(a) * r), 0.9, Vector3(1, 1, 1))
	_p(n, Models.cyl(0.12, 0.05, 0.08, 8), BRASS, Vector3(0, -0.7, 0))
	_p(n, Models.ball(0.03, 6), BRASS, Vector3(0, -0.77, 0))


static func _avize(n: Node3D) -> void:
	_chain(n, 0.9, -0.1)
	_p(n, Models.ball(0.08, 8), BRASS, Vector3(0, -0.12, 0))
	var t := TorusMesh.new()
	t.inner_radius = 0.38
	t.outer_radius = 0.42
	t.rings = 20
	t.ring_segments = 4
	_p(n, t, BRASS, Vector3(0, -0.42, 0))
	_p(n, Models.cyl(0.03, 0.03, 0.4, 6), BRASS, Vector3(0, -0.32, 0))
	_p(n, Models.ball(0.1, 8), BRASS, Vector3(0, -0.52, 0), Vector3.ZERO, Vector3(1, 0.7, 1))
	for i in 6:
		var a := TAU * i / 6.0
		var p := Vector3(cos(a) * 0.4, -0.42, sin(a) * 0.4)
		_p(n, Models.cyl(0.012, 0.012, 0.4, 4), BRASS, Vector3(p.x * 0.5, -0.42, p.z * 0.5), Vector3(0, -rad_to_deg(a), 90))
		_p(n, Models.cyl(0.05, 0.04, 0.05, 8), BRASS, p + Vector3(0, 0.03, 0))
		_glow(n, Models.cyl(0.025, 0.025, 0.12, 6), "#fff8e8", p + Vector3(0, 0.11, 0), 0.6)
		_glow(n, Models.ball(0.035, 6), "#ffd890", p + Vector3(0, 0.2, 0), 1.6, Vector3(1, 1.5, 1))
		for k in 2:  # kristal damlalar
			_glow(n, Models.ball(0.035 - k * 0.008, 6), "#cfeaff", p + Vector3(0, -0.09 - k * 0.07, 0), 0.5, Vector3(1, 1.4, 1))
	for i in 5:
		_glow(n, Models.ball(0.045, 6), "#cfeaff", Vector3(0, -0.66 - i * 0.07, 0), 0.5, Vector3(1, 1.3, 1))
