class_name Walker
extends Node
## Bir karakteri yürütür: hedefe döner, adım atar, kol sallar, durunca nefes alır.
## Karakter Models.teyze()/player() iskeletini (Body, LegL/R, ArmL/R) kullanmalı.

signal arrived

@export var speed := 2.4
## Yürünemeyen alanlar (x, z dikdörtgenleri). Engelde eksen boyunca kayar.
var blockers: Array[Rect2] = []
var bounds := Rect2(-6.2, -4.7, 12.4, 16.5)

var target := Vector3.ZERO
var moving := false
var _phase := 0.0
var _idle := 0.0
var _turn_to := 0.0
var _char: Node3D
var _body: Node3D
var _legs: Array[Node3D] = []
var _leg_signs: Array[float] = []
## Adım sıklığı çarpanı (kısa bacaklı hayvanlarda daha sık adım).
var step_rate := 1.0
var _arms: Array[Node3D] = []


func _ready() -> void:
	_char = get_parent()
	_body = _char.get_node_or_null("Body")
	for n in ["LegL", "LegR", "LegL2", "LegR2"]:
		if _char.has_node(n):
			_legs.append(_char.get_node(n))
			_leg_signs.append(1.0 if n.begins_with("LegL") else -1.0)
	if _body:
		for n in ["ArmL", "ArmR"]:
			if _body.has_node(n):
				_arms.append(_body.get_node(n))
	_turn_to = _char.rotation.y


func walk_to(p: Vector3) -> void:
	target = Vector3(clampf(p.x, bounds.position.x, bounds.end.x), 0, clampf(p.z, bounds.position.y, bounds.end.y))
	target = _push_out(target)
	moving = true


func stop() -> void:
	moving = false


func face(p: Vector3) -> void:
	var d := p - _char.position
	if d.length() > 0.01:
		_turn_to = atan2(d.x, d.z)


func _process(delta: float) -> void:
	var walking_now := false
	if moving:
		var d := target - _char.position
		d.y = 0
		var dist := d.length()
		if dist < 0.06:
			moving = false
			arrived.emit()
		else:
			var step := d / dist * minf(speed * delta, dist)
			var next := _char.position + step
			if _blocked(next):
				# engel: önce yalnız x, sonra yalnız z ekseninde kaymayı dene
				var nx := _char.position + Vector3(step.x, 0, 0)
				var nz := _char.position + Vector3(0, 0, step.z)
				if not _blocked(nx) and absf(step.x) > 0.001:
					next = nx
				elif not _blocked(nz) and absf(step.z) > 0.001:
					next = nz
				else:
					moving = false
					arrived.emit()
					next = _char.position
			if next != _char.position:
				_turn_to = atan2(next.x - _char.position.x, next.z - _char.position.z)
				_char.position = next
				walking_now = true
	_char.rotation.y = lerp_angle(_char.rotation.y, _turn_to, minf(1.0, delta * 10.0))
	_animate(delta, walking_now)


func _animate(delta: float, walking_now: bool) -> void:
	if walking_now:
		_phase += delta * speed * 4.2 * step_rate
		var sw := sin(_phase)
		for i in _legs.size():
			_legs[i].rotation.x = lerpf(_legs[i].rotation.x, sw * 0.55 * _leg_signs[i], 0.5)
		for i in _arms.size():
			_arms[i].rotation.x = lerpf(_arms[i].rotation.x, -sw * 0.6 * (1 if i == 0 else -1), 0.5)
		if _body:
			_body.position.y = absf(cos(_phase)) * 0.05
			_body.rotation.z = sw * 0.04
	else:
		_idle += delta
		for l in _legs:
			l.rotation.x = lerpf(l.rotation.x, 0.0, minf(1.0, delta * 8.0))
		for i in _arms.size():
			var rest := sin(_idle * 1.6 + i) * 0.05
			_arms[i].rotation.x = lerpf(_arms[i].rotation.x, rest, minf(1.0, delta * 6.0))
		if _body:
			_body.position.y = lerpf(_body.position.y, 0.0, minf(1.0, delta * 8.0))
			_body.rotation.z = lerpf(_body.rotation.z, 0.0, minf(1.0, delta * 8.0))
			_body.scale.y = 1.0 + sin(_idle * 2.2) * 0.012  # nefes


func _blocked(p: Vector3) -> bool:
	for r in blockers:
		if r.has_point(Vector2(p.x, p.z)):
			return true
	return false


## Hedef bir engelin içindeyse en yakın kenarın hemen dışına taşır.
func _push_out(p: Vector3) -> Vector3:
	for r in blockers:
		var q := Vector2(p.x, p.z)
		if r.has_point(q):
			var opts := [
				Vector2(r.position.x - 0.1, q.y), Vector2(r.end.x + 0.1, q.y),
				Vector2(q.x, r.position.y - 0.1), Vector2(q.x, r.end.y + 0.1),
			]
			opts.sort_custom(func(a, b): return a.distance_to(q) < b.distance_to(q))
			p = Vector3(opts[0].x, 0, opts[0].y)
	return p
