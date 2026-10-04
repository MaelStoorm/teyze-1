class_name Models
## Low-poly 3D modeller, hepsi Godot'nun hazır şekillerinden (kutu, küre,
## silindir, prizma) kod ile kuruluyor. Dışarıdan model dosyası gerekmez.

static var _mats := {}


static func mat(color: String, rough := 0.85) -> StandardMaterial3D:
	var key := color + str(rough)
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(color)
		m.roughness = rough
		_mats[key] = m
	return _mats[key]


static func part(parent: Node3D, mesh: Mesh, color: String, pos := Vector3.ZERO, rot_deg := Vector3.ZERO, scl := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat(color)
	mi.position = pos
	mi.rotation_degrees = rot_deg
	mi.scale = scl
	parent.add_child(mi)
	return mi


static func box(x: float, y: float, z: float) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = Vector3(x, y, z)
	return m


static func ball(r: float, segs := 12, hemi := false) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r if hemi else r * 2
	m.is_hemisphere = hemi
	m.radial_segments = segs
	m.rings = maxi(segs / 2, 4)
	return m


static func cyl(top: float, bottom: float, h: float, segs := 12) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = h
	m.radial_segments = segs
	m.rings = 1
	return m


static func prism(x: float, y: float, z: float) -> PrismMesh:
	var m := PrismMesh.new()
	m.size = Vector3(x, y, z)
	return m


static func capsule(r: float, h: float) -> CapsuleMesh:
	var m := CapsuleMesh.new()
	m.radius = r
	m.height = h
	m.radial_segments = 10
	m.rings = 4
	return m


# --- karakterler ---------------------------------------------------------------

static func _face(n: Node3D, y: float, r: float, glasses := false) -> void:
	for sx in [-1, 1]:
		part(n, ball(r * 0.11, 8), "#2b1d14", Vector3(sx * r * 0.36, y, r * 0.9))
		part(n, ball(r * 0.16, 8), "#f2a0a0", Vector3(sx * r * 0.5, y - r * 0.3, r * 0.8))
		if glasses:
			var t := TorusMesh.new()
			t.inner_radius = r * 0.17
			t.outer_radius = r * 0.23
			t.rings = 12
			t.ring_segments = 6
			part(n, t, "#3b2a1e", Vector3(sx * r * 0.36, y, r * 0.95), Vector3(90, 0, 0))
	part(n, ball(r * 0.12, 8), "#e0a46a", Vector3(0, y - r * 0.16, r * 0.98))


static func teyze() -> Node3D:
	var n := Node3D.new()
	n.name = "Teyze"
	part(n, ball(0.12, 8), "#3b2a1e", Vector3(-0.14, 0.06, 0.06))
	part(n, ball(0.12, 8), "#3b2a1e", Vector3(0.14, 0.06, 0.06))
	part(n, cyl(0.27, 0.4, 0.55), "#7a4e8a", Vector3(0, 0.33, 0))  # etek
	for i in 8:  # eteğin çiçekleri
		var a := TAU * i / 8.0
		part(n, ball(0.035, 6), "#f4efe6", Vector3(sin(a) * 0.36, 0.25, cos(a) * 0.36))
	part(n, cyl(0.22, 0.28, 0.42), "#4f8a5b", Vector3(0, 0.8, 0))  # hırka
	for sx in [-1, 1]:
		part(n, capsule(0.08, 0.4), "#4f8a5b", Vector3(sx * 0.3, 0.78, 0.04), Vector3(0, 0, sx * 14))
		part(n, ball(0.075, 8), "#f1c27d", Vector3(sx * 0.35, 0.56, 0.08))
	part(n, ball(0.32, 16), "#f1c27d", Vector3(0, 1.3, 0))  # baş
	_face(n, 1.3, 0.32, true)
	# yazma (başörtüsü) ve puantiyeleri
	part(n, ball(0.35, 16, true), "#d6577a", Vector3(0, 1.36, -0.02))
	part(n, cyl(0.3, 0.34, 0.3), "#d6577a", Vector3(0, 1.22, -0.1), Vector3(-12, 0, 0))
	for i in 7:
		var a := lerpf(-1.2, 1.2, i / 6.0)
		part(n, ball(0.035, 6), "#fff4dc", Vector3(sin(a) * 0.3, 1.52, cos(a) * 0.17 - 0.02))
	part(n, prism(0.16, 0.14, 0.06), "#d6577a", Vector3(0, 1.02, 0.2), Vector3(180, 0, 0))
	return n


static func player() -> Node3D:
	var n := Node3D.new()
	n.name = "Oyuncu"
	for sx in [-1, 1]:
		part(n, capsule(0.09, 0.45), "#2c3e50", Vector3(sx * 0.11, 0.24, 0))
	part(n, cyl(0.2, 0.24, 0.45), "#3d6fb6", Vector3(0, 0.7, 0))
	for sx in [-1, 1]:
		part(n, capsule(0.07, 0.38), "#3d6fb6", Vector3(sx * 0.28, 0.7, 0), Vector3(0, 0, sx * 10))
		part(n, ball(0.07, 8), "#f1c27d", Vector3(sx * 0.31, 0.5, 0))
	part(n, ball(0.3, 16), "#f1c27d", Vector3(0, 1.2, 0))
	_face(n, 1.2, 0.3)
	part(n, ball(0.32, 16, true), "#3b2a1e", Vector3(0, 1.27, -0.05), Vector3(-15, 0, 0))
	return n


static func cat() -> Node3D:
	var n := Node3D.new()
	part(n, capsule(0.14, 0.5), "#f8f6f2", Vector3(0, 0.15, 0), Vector3(90, 0, 0))
	part(n, ball(0.15, 12), "#f8f6f2", Vector3(0, 0.3, 0.25))
	for sx in [-1, 1]:
		part(n, prism(0.09, 0.1, 0.04), "#f8f6f2", Vector3(sx * 0.08, 0.45, 0.25))
		part(n, ball(0.02, 6), "#2b1d14", Vector3(sx * 0.05, 0.32, 0.38))
	part(n, cyl(0.03, 0.03, 0.35, 6), "#f8f6f2", Vector3(0, 0.3, -0.3), Vector3(-40, 0, 0))
	return n


# --- binalar ve süsler --------------------------------------------------------

## Alaturka iki katlı ev: taş zemin kat, beyaz üst kat, ahşap cumba, kiremit çatı.
static func house(walls: String, trim: String, door: String) -> Node3D:
	var n := Node3D.new()
	var w := 3.2
	var d := 2.4
	part(n, box(w, 1.3, d), "#d9cbb0", Vector3(0, 0.65, 0))  # taş kat
	part(n, box(w + 0.1, 0.12, d + 0.1), trim, Vector3(0, 1.32, 0))  # kat silmesi
	part(n, box(w, 1.25, d), walls, Vector3(0, 1.98, 0))
	# cumba
	part(n, box(1.4, 1.05, 0.5), walls, Vector3(0, 2.0, d / 2 + 0.25))
	part(n, box(1.5, 0.1, 0.6), trim, Vector3(0, 1.45, d / 2 + 0.27))
	part(n, box(1.5, 0.1, 0.6), trim, Vector3(0, 2.55, d / 2 + 0.27))
	for x in [-0.4, 0.4]:
		part(n, box(0.5, 0.6, 0.04), "#9ad3e0", Vector3(x, 2.0, d / 2 + 0.51))
		part(n, box(0.06, 0.66, 0.06), trim, Vector3(x, 2.0, d / 2 + 0.52))
	# çatı
	part(n, prism(w + 0.6, 1.1, d + 0.8), "#c8553a", Vector3(0, 3.15, 0))
	part(n, box(0.3, 0.6, 0.3), "#b8a68a", Vector3(1.0, 3.4, -0.4))  # baca
	# kapı ve zemin kat pencereleri
	part(n, box(0.7, 1.0, 0.08), door, Vector3(0, 0.5, d / 2 + 0.02))
	part(n, ball(0.04, 6), "#f2c94c", Vector3(0.22, 0.5, d / 2 + 0.08))
	for x in [-1.05, 1.05]:
		part(n, box(0.6, 0.55, 0.06), "#9ad3e0", Vector3(x, 0.75, d / 2 + 0.01))
		part(n, box(0.72, 0.08, 0.2), trim, Vector3(x, 0.45, d / 2 + 0.08))
		for i in 3:  # pencere önü sardunyalar
			part(n, ball(0.08, 6), "#e04a4a", Vector3(x - 0.2 + i * 0.2, 0.55, d / 2 + 0.12))
	# üst kat yan pencereler
	for x in [-1.2, 1.2]:
		part(n, box(0.45, 0.55, 0.06), "#9ad3e0", Vector3(x, 2.0, d / 2 + 0.01))
		part(n, box(0.12, 0.6, 0.04), "#4f8a5b", Vector3(x - 0.3, 2.0, d / 2 + 0.03))
		part(n, box(0.12, 0.6, 0.04), "#4f8a5b", Vector3(x + 0.3, 2.0, d / 2 + 0.03))
	return n


static func tree() -> Node3D:
	var n := Node3D.new()
	part(n, cyl(0.12, 0.18, 1.0, 8), "#8a5a3b", Vector3(0, 0.5, 0))
	part(n, ball(0.75, 8), "#4f9e50", Vector3(0, 1.4, 0))
	part(n, ball(0.55, 8), "#5aa852", Vector3(0.35, 1.85, 0.1))
	part(n, ball(0.5, 8), "#3f8a46", Vector3(-0.4, 1.7, -0.1))
	return n


static func bush() -> Node3D:
	var n := Node3D.new()
	part(n, ball(0.45, 8), "#4f9a4a", Vector3(0, 0.3, 0))
	part(n, ball(0.35, 8), "#5aa852", Vector3(0.4, 0.25, 0.1))
	part(n, ball(0.35, 8), "#3f8a46", Vector3(-0.4, 0.22, 0))
	for p in [Vector3(0.1, 0.65, 0.25), Vector3(-0.3, 0.45, 0.3), Vector3(0.45, 0.45, 0.35)]:
		part(n, ball(0.06, 6), "#e04a4a", p)
	return n


static func pot() -> Node3D:
	var n := Node3D.new()
	part(n, cyl(0.25, 0.18, 0.4, 10), "#c96a43", Vector3(0, 0.2, 0))
	part(n, ball(0.18, 8), "#4f9a4a", Vector3(0, 0.45, 0))
	for i in 5:
		var a := TAU * i / 5.0
		part(n, ball(0.08, 6), "#e04a4a", Vector3(sin(a) * 0.14, 0.58, cos(a) * 0.14))
	return n


static func crate() -> Node3D:
	var n := Node3D.new()
	part(n, box(0.6, 0.5, 0.6), "#b07a4a", Vector3(0, 0.25, 0))
	part(n, box(0.62, 0.08, 0.62), "#8a5a3b", Vector3(0, 0.45, 0))
	for c in ["#e04a35", "#f5a93a", "#e04a35", "#f5a93a"]:
		part(n, ball(0.1, 6), c, Vector3(randf_range(-0.18, 0.18), 0.55, randf_range(-0.18, 0.18)))
	return n


## Çizgili tenteli pazar tezgahı.
static func stall() -> Node3D:
	var n := Node3D.new()
	for x in [-1.1, 1.1]:
		for z in [-0.45, 0.45]:
			part(n, box(0.1, 1.9, 0.1), "#8a5a3b", Vector3(x, 0.95, z))
	part(n, box(2.4, 0.15, 1.1), "#a86f48", Vector3(0, 0.75, 0))
	part(n, box(2.3, 0.6, 0.06), "#8a5a3b", Vector3(0, 0.42, 0.5))
	var colors := ["#e04a35", "#f5a93a", "#5aa852", "#f7cf4a", "#7a4e8a"]
	for i in 5:
		for j in 4:
			part(n, ball(0.11, 6), colors[i], Vector3(-0.9 + i * 0.45 + randf_range(-0.05, 0.05), 0.9, -0.3 + j * 0.2))
	for i in 8:  # tente çizgileri
		part(n, box(0.31, 0.06, 1.4), "#d8452f" if i % 2 == 0 else "#f4efe6", Vector3(-1.08 + i * 0.31, 2.0, 0.05), Vector3(14, 0, 0))
	return n


static func lamp() -> Node3D:
	var n := Node3D.new()
	part(n, cyl(0.05, 0.08, 2.2, 8), "#3b3b3b", Vector3(0, 1.1, 0))
	part(n, box(0.3, 0.35, 0.3), "#3b3b3b", Vector3(0, 2.3, 0))
	part(n, box(0.22, 0.25, 0.22), "#ffe9a8", Vector3(0, 2.3, 0))
	return n


static func bench() -> Node3D:
	var n := Node3D.new()
	part(n, box(1.3, 0.08, 0.4), "#a86f48", Vector3(0, 0.45, 0))
	part(n, box(1.3, 0.3, 0.06), "#a86f48", Vector3(0, 0.7, -0.18))
	for x in [-0.55, 0.55]:
		part(n, box(0.08, 0.45, 0.35), "#5c3a26", Vector3(x, 0.22, 0))
	# bankta çay ve simit
	part(n, cyl(0.05, 0.035, 0.12, 8), "#c4402c", Vector3(-0.3, 0.55, 0))
	var t := TorusMesh.new()
	t.inner_radius = 0.06
	t.outer_radius = 0.11
	t.rings = 12
	t.ring_segments = 6
	part(n, t, "#c9803f", Vector3(0.2, 0.51, 0.02))
	return n
