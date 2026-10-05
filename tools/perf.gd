extends SceneTree
## Mahallenin çizim yükünü ölçer (gerçek çizici gerekir, xvfb ile):
## xvfb-run godot --path . --resolution 1280x720 -s tools/perf.gd

func _initialize() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	root.get_node("GameState").avatar = {"gender": "kiz"}
	for c in main.get_children():
		if c.get_script() and c.get_script().resource_path.ends_with("splash.gd"):
			c.queue_free()
	for i in 90:
		await process_frame
	var w = main.find_children("*", "Mahalle3D", true, false)
	var meshes := 0
	var shadow_cast := 0
	if w.size() > 0:
		for n in w[0].find_children("*", "GeometryInstance3D", true, false):
			meshes += 1
			if n.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
				shadow_cast += 1
		print("viewport ", w[0].viewport.size)
	var vp: Viewport = w[0].viewport if w.size() > 0 else root
	print("PERF geometry nodes=%d shadow_casters=%d" % [meshes, shadow_cast])
	print("PERF draw_calls=%d objects=%d primitives=%d" % [
		RenderingServer.viewport_get_render_info(vp.get_viewport_rid(), RenderingServer.VIEWPORT_RENDER_INFO_TYPE_VISIBLE, RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME),
		RenderingServer.viewport_get_render_info(vp.get_viewport_rid(), RenderingServer.VIEWPORT_RENDER_INFO_TYPE_VISIBLE, RenderingServer.VIEWPORT_RENDER_INFO_OBJECTS_IN_FRAME),
		RenderingServer.viewport_get_render_info(vp.get_viewport_rid(), RenderingServer.VIEWPORT_RENDER_INFO_TYPE_VISIBLE, RenderingServer.VIEWPORT_RENDER_INFO_PRIMITIVES_IN_FRAME)])
	print("PERF shadow draw_calls=%d" % RenderingServer.viewport_get_render_info(vp.get_viewport_rid(), RenderingServer.VIEWPORT_RENDER_INFO_TYPE_SHADOW, RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME))
	# en çok üçgen çizenler
	var rows := []
	for n in w[0].find_children("*", "GeometryInstance3D", true, false):
		var mesh: Mesh = null
		var count := 1
		if n is MeshInstance3D:
			mesh = n.mesh
		elif n is MultiMeshInstance3D:
			mesh = n.multimesh.mesh
			count = n.multimesh.instance_count
		if mesh == null:
			continue
		var tris := 0
		for si in mesh.get_surface_count():
			var arr := mesh.surface_get_arrays(si)
			var idx = arr[Mesh.ARRAY_INDEX]
			tris += (idx.size() if idx != null and idx.size() > 0 else arr[Mesh.ARRAY_VERTEX].size()) / 3
		rows.append([tris * count, "%s x%d %s" % [n.name, count, n.get_parent().name]])
	rows.sort_custom(func(a, b): return a[0] > b[0])
	var total := 0
	for r in rows:
		total += r[0]
	print("PERF toplam üçgen %d" % total)
	for r in rows.slice(0, 12):
		print("PERF  %7d %s" % r)
	var t0 := Time.get_ticks_msec()
	for i in 60:
		await process_frame
	print("PERF 60 frames ms=%d" % (Time.get_ticks_msec() - t0))
	quit()
