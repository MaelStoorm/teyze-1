extends SceneTree
## Karakter modellerini yan yana çizip PNG kaydeder (geliştirme için):
## godot --path . -s tools/model_sheet.gd -- --out=/tmp/x.png


func _initialize() -> void:
	var out := "res://model_sheet.png"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
	var w := Node3D.new()
	root.add_child(w)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("bfe3f0")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("e8eeff")
	env.environment.ambient_light_energy = 0.5
	w.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 25, 0)
	w.add_child(sun)
	var models := [Models.teyze()]
	for n in Neighbors.ALL:
		models.append(Models.teyze(n))
	var looks := [
		{"gender": "kiz", "hair": 0}, {"gender": "kiz", "hair": 1, "hair_color": 3, "top": 2, "bottom_style": 1},
		{"gender": "kiz", "hair": 2, "hair_color": 4, "skin": 3, "top": 4}, {"gender": "kiz", "hair": 3, "hair_color": 0, "top": 5},
		{"gender": "erkek", "hair": 0, "top": 0}, {"gender": "erkek", "hair": 1, "hair_color": 3, "top": 6, "bottom_style": 1},
		{"gender": "erkek", "hair": 2, "hair_color": 0, "skin": 4, "top": 3}, {"gender": "erkek", "hair": 3, "hair_color": 2, "top": 7},
	]
	for l in looks:
		models.append(Avatar.build(l))
	for i in models.size():
		var m: Node3D = models[i]
		m.position = Vector3((i % 6) * 1.1 - 2.75, 0, -(i / 6) * 2.2)
		w.add_child(m)
	var cam := Camera3D.new()
	cam.fov = 40
	w.add_child(cam)
	cam.look_at_from_position(Vector3(0, 2.6, 7.5), Vector3(0, 0.3, -1.1))
	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out)
	quit()
