extends SceneTree
## Fatma Teyze'nin yakın 3D portresini şeffaf PNG olarak çizer (oyun simgesi ve
## başlık ekranı için): godot --path . -s tools/render_portrait.gd -- --out=x.png


func _initialize() -> void:
	var out := "res://assets/brand/teyze_portre.png"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
	root.transparent_bg = true
	var w := Node3D.new()
	root.add_child(w)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_CLEAR_COLOR
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("fff0e0")
	env.environment.ambient_light_energy = 0.65
	w.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-30, 25, 0)
	sun.light_energy = 1.0
	w.add_child(sun)
	var t := Models.teyze()
	t.rotation.y = deg_to_rad(-12)
	w.add_child(t)
	var cam := Camera3D.new()
	cam.fov = 26
	w.add_child(cam)
	cam.look_at_from_position(Vector3(0.25, 1.35, 2.6), Vector3(0, 1.18, 0))
	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out)
	quit()
