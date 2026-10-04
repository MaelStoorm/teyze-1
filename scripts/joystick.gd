class_name Joystick
extends Control
## Sol alttaki küçük yürüme kolu. Parmakla sürüklenince value (-1..1) değişir;
## bırakınca topuz yerine döner.

var value := Vector2.ZERO
var radius := 46.0
var _knob := Vector2.ZERO
var _held := false


func _init() -> void:
	custom_minimum_size = Vector2(124, 124)
	mouse_filter = MOUSE_FILTER_STOP


func _gui_input(event: InputEvent) -> void:
	# Android'de dokunuşlar fare olayı olarak da gelir; yalnız onu dinliyoruz.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_held = event.pressed
		if _held:
			_move(event.position)
		else:
			_release()
		accept_event()
	elif event is InputEventMouseMotion and _held:
		_move(event.position)
		accept_event()


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT and not _held:
		_release()
	elif what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
		_held = false
		_release()


func _move(p: Vector2) -> void:
	var d := p - size / 2
	if d.length() > radius:
		d = d.normalized() * radius
	_knob = d
	value = d / radius
	queue_redraw()


func _release() -> void:
	_knob = Vector2.ZERO
	value = Vector2.ZERO
	queue_redraw()


func _draw() -> void:
	var c := size / 2
	draw_circle(c, radius + 14, Color(1, 0.97, 0.9, 0.38))
	draw_arc(c, radius + 14, 0, TAU, 48, Color(0.24, 0.16, 0.1, 0.5), 3.0, true)
	for i in 4:  # yön okları
		var a := i * PI / 2
		var dir := Vector2(cos(a), sin(a))
		var tip := c + dir * (radius + 6)
		var side := dir.orthogonal() * 6
		draw_colored_polygon(PackedVector2Array([tip, tip - dir * 8 + side, tip - dir * 8 - side]), Color(0.24, 0.16, 0.1, 0.45))
	var k := c + _knob
	draw_circle(k + Vector2(0, 3), 25, Color(0, 0, 0, 0.18))
	draw_circle(k, 25, Color("fff4dc"))
	draw_arc(k, 25, 0, TAU, 40, Color("3d2a1c"), 3.0, true)
	draw_circle(k + Vector2(-6, -7), 7, Color(1, 1, 1, 0.8))
