class_name Portrait
extends SubViewportContainer
## Konuşma kutularında teyzenin canlı 3D portresi.

var _model: Node3D
var _t := 0.0


func _init(size_px := Vector2(96, 110), full_body := false) -> void:
	custom_minimum_size = size_px
	stretch = true
	mouse_filter = MOUSE_FILTER_IGNORE
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.msaa_3d = Viewport.MSAA_4X
	add_child(vp)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35, 30, 0)
	light.light_energy = 1.1
	vp.add_child(light)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_CLEAR_COLOR
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("e8eeff")
	env.environment.ambient_light_energy = 0.6
	vp.add_child(env)
	_model = Models.teyze()
	vp.add_child(_model)
	var cam := Camera3D.new()
	cam.fov = 30
	if full_body:
		vp.add_child(cam)
		cam.look_at_from_position(Vector3(0, 0.95, 3.6), Vector3(0, 0.8, 0))
	else:
		vp.add_child(cam)
		cam.look_at_from_position(Vector3(0, 1.3, 2.0), Vector3(0, 1.15, 0))


func _process(delta: float) -> void:
	_t += delta
	_model.rotation.y = sin(_t * 1.2) * 0.25
