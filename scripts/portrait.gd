class_name Portrait
extends View3D
## Konuşma kutularında teyzenin canlı 3D portresi.

var _model: Node3D
var _t := 0.0


## look: Models.teyze() görünüşü (boşsa Fatma Teyze).
func _init(size_px := Vector2(96, 110), full_body := false, look := {}) -> void:
	super()
	custom_minimum_size = size_px
	mouse_filter = MOUSE_FILTER_IGNORE
	var vp := viewport
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.msaa_3d = Viewport.MSAA_4X
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
	_model = Models.person(look)
	vp.add_child(_model)
	var cam := Camera3D.new()
	cam.fov = 30
	if full_body:
		vp.add_child(cam)
		cam.look_at_from_position(Vector3(0, 0.95, 3.6), Vector3(0, 0.8, 0))
	else:
		vp.add_child(cam)
		cam.look_at_from_position(Vector3(0, 1.3, 2.0), Vector3(0, 1.15, 0))


## Portredeki teyzeyi başka renklerle (başka bir teyzeyle) değiştirir.
func set_look(look: Dictionary) -> void:
	var rot := _model.rotation
	_model.queue_free()
	_model = Models.person(look)
	_model.rotation = rot
	viewport.add_child(_model)


func _process(delta: float) -> void:
	_t += delta
	_model.rotation.y = sin(_t * 1.2) * 0.25
