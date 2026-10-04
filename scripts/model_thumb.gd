class_name ModelThumb
extends SubViewportContainer
## Dükkanda süslerin küçük, yavaşça dönen 3D önizlemesi.

var _pivot := Node3D.new()


func _init(model: Node3D, size_px := Vector2(64, 64), distance := 4.5) -> void:
	custom_minimum_size = size_px
	stretch = true
	mouse_filter = MOUSE_FILTER_IGNORE
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.msaa_3d = Viewport.MSAA_2X
	add_child(vp)
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
	cam.look_at_from_position(Vector3(0, distance * 0.7, distance), Vector3(0, 0.7, 0))


func _process(delta: float) -> void:
	_pivot.rotation.y += delta * 0.6
