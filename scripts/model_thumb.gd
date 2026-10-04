class_name ModelThumb
extends View3D
## Dükkanda süslerin küçük, yavaşça dönen 3D önizlemesi.

var _pivot := Node3D.new()


func _init(model: Node3D, size_px := Vector2(64, 64), distance := 4.5, target_y := 0.7) -> void:
	super()
	custom_minimum_size = size_px
	mouse_filter = MOUSE_FILTER_IGNORE
	var vp := viewport
	vp.own_world_3d = true
	vp.transparent_bg = true
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, 35, 0)
	vp.add_child(light)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_CLEAR_COLOR
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("e8eeff")
	env.environment.ambient_light_energy = 0.5
	vp.add_child(env)
	vp.add_child(_pivot)
	_pivot.add_child(model)
	var cam := Camera3D.new()
	cam.fov = 35
	vp.add_child(cam)
	cam.look_at_from_position(Vector3(0, distance * 0.7, distance), Vector3(0, target_y, 0))


## Önizlemedeki modeli değiştirir (dönüş açısı korunur).
func set_model(model: Node3D) -> void:
	for c in _pivot.get_children():
		c.queue_free()
	_pivot.add_child(model)


func _process(delta: float) -> void:
	_pivot.rotation.y += delta * 0.6
