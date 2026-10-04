class_name Bake
## Telefonda hız için: binlerce küçük parçayı birkaç büyük meshe birleştirir.
##
## Her parça ayrı bir çizim çağrısıydı (mahallede 3000'den fazla). Burada aynı
## türden düz renkli parçalar tek meshe toplanır; renk köşe rengine yazılır,
## böylece tek malzeme yeter. Yalnız otomatik adlı (adı "@" ile başlayan),
## çocuksuz ve görünür MeshInstance3D'ler birleştirilir; adı verilmiş parçalara
## kod sonradan eriştiği için dokunulmaz.

static var _mats := {}


## Kökün altındaki hareketsiz her şeyi bölgelere ayırıp birleştirir.
## exclude: kendisi ve altı birleştirilmeyecek düğümler (hareket edenler vb.).
static func merge_static(root: Node3D, exclude: Array, chunk := 10.0) -> int:
	var skip := {}
	for n in exclude:
		if n:
			skip[n] = true
	var groups := {}  # "bölge|malzeme" -> parça listesi
	var inv := root.global_transform.affine_inverse()
	var found: Array[MeshInstance3D] = []
	_collect(root, skip, found)
	for mi in found:
		var xf := inv * mi.global_transform
		var c := xf.origin
		var cell := Vector2i(floori(c.x / chunk), floori(c.z / chunk))
		_add(groups, "%d,%d" % [cell.x, cell.y], mi, xf)
	for mi in found:
		mi.get_parent().remove_child(mi)
		mi.free()
	return _emit(groups, root)


## Hareketli bir karakterde her eklem (Body, LegL, ArmR...) kendi doğrudan
## parçalarını tek meshe toplar; eklemler yine ayrı ayrı dönebilir.
static func merge_rig(node: Node3D) -> void:
	var parts: Array[MeshInstance3D] = []
	for c in node.get_children():
		if c is MeshInstance3D and _mergeable(c):
			parts.append(c)
		elif c is Node3D:
			merge_rig(c)
	if parts.size() < 2:
		return
	var groups := {}
	for mi in parts:
		_add(groups, "", mi, mi.transform)
	for mi in parts:
		node.remove_child(mi)
		mi.free()
	_emit(groups, node)


static func _collect(n: Node, skip: Dictionary, out: Array[MeshInstance3D]) -> void:
	for c in n.get_children():
		if skip.has(c):
			continue
		if c is MeshInstance3D and _mergeable(c):
			out.append(c)
		elif c is Node3D and c.visible:
			_collect(c, skip, out)


static func _mergeable(mi: MeshInstance3D) -> bool:
	if not mi.visible or mi.get_child_count() > 0 or mi.mesh == null:
		return false
	if not String(mi.name).begins_with("@"):
		return false
	for s in mi.mesh.get_surface_count():
		if _key(mi.get_active_material(s)) == "":
			return false
	return true


## Birleştirilebilecek düz malzemenin anahtarı; birleştirilemiyorsa "".
static func _key(m: Material) -> String:
	var sm := m as StandardMaterial3D
	if sm == null:
		return ""
	if sm.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or sm.albedo_texture != null \
			or sm.no_depth_test or sm.billboard_mode != BaseMaterial3D.BILLBOARD_DISABLED \
			or sm.shading_mode != BaseMaterial3D.SHADING_MODE_PER_PIXEL:
		return ""
	if sm.emission_enabled:
		return "e" + sm.emission.to_html() + str(sm.emission_energy_multiplier) + "r" + str(snappedf(sm.roughness, 0.05))
	return "r" + str(snappedf(sm.roughness, 0.05))


static func _add(groups: Dictionary, region: String, mi: MeshInstance3D, xf: Transform3D) -> void:
	var nb := xf.basis.inverse().transposed()
	for s in mi.mesh.get_surface_count():
		var m: StandardMaterial3D = mi.get_active_material(s)
		var key := region + "|" + _key(m)
		if not groups.has(key):
			groups[key] = {"v": PackedVector3Array(), "n": PackedVector3Array(), "c": PackedColorArray(), "i": PackedInt32Array(), "mat": m, "shadow": mi.cast_shadow}
		var g: Dictionary = groups[key]
		var arr := mi.mesh.surface_get_arrays(s)
		var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var norms: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
		var idx = arr[Mesh.ARRAY_INDEX]
		var base: int = g["v"].size()
		var col := m.albedo_color
		var vcol = arr[Mesh.ARRAY_COLOR] if m.vertex_color_use_as_albedo else null
		for k in verts.size():
			g["v"].append(xf * verts[k])
			g["n"].append((nb * norms[k]).normalized() if norms.size() > k else Vector3.UP)
			g["c"].append(vcol[k] * col if vcol != null and vcol.size() > k else col)
		var has_idx: bool = idx != null and idx.size() > 0
		var flip := xf.basis.determinant() < 0.0  # aynalanmış parça: üçgen yönü ters
		var count: int = idx.size() if has_idx else verts.size()
		var ia: PackedInt32Array = g["i"]
		for t in range(0, count, 3):
			var a: int = idx[t] if has_idx else t
			var b: int = idx[t + 1] if has_idx else t + 1
			var c: int = idx[t + 2] if has_idx else t + 2
			ia.append(base + a)
			ia.append(base + (c if flip else b))
			ia.append(base + (b if flip else c))
		g["i"] = ia


static func _emit(groups: Dictionary, parent: Node3D) -> int:
	var by_region := {}
	for key in groups:
		var region: String = key.get_slice("|", 0)
		if not by_region.has(region):
			by_region[region] = []
		by_region[region].append(groups[key])
	var calls := 0
	for region in by_region:
		var mesh := ArrayMesh.new()
		var shadow := false
		for g in by_region[region]:
			var arr := []
			arr.resize(Mesh.ARRAY_MAX)
			arr[Mesh.ARRAY_VERTEX] = g["v"]
			arr[Mesh.ARRAY_NORMAL] = g["n"]
			arr[Mesh.ARRAY_COLOR] = g["c"]
			arr[Mesh.ARRAY_INDEX] = g["i"]
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
			mesh.surface_set_material(mesh.get_surface_count() - 1, _vc_mat(g["mat"]))
			shadow = shadow or g["shadow"] != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			calls += 1
		var out := MeshInstance3D.new()
		out.name = "Birlesik" + region.replace(",", "_").replace("-", "m")
		out.mesh = mesh
		if not shadow:
			out.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(out)
	return calls


## Rengini köşelerden alan, aynı pürüzlülükte paylaşılan malzeme.
static func _vc_mat(src: StandardMaterial3D) -> StandardMaterial3D:
	var key := _key(src)
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.vertex_color_use_as_albedo = true
		m.vertex_color_is_srgb = true
		m.roughness = src.roughness
		m.metallic = src.metallic
		m.metallic_specular = src.metallic_specular
		if src.emission_enabled:
			m.emission_enabled = true
			m.emission = src.emission
			m.emission_energy_multiplier = src.emission_energy_multiplier
		_mats[key] = m
	return _mats[key]
