class_name View3D
extends Control
## 3D sahneyi telefonun gerçek piksel çözünürlüğünde çizen kutu.
##
## SubViewportContainer, oyunun 360x640'lık tasarım boyutunda çizip büyüttüğü
## için telefonda görüntü bulanık oluyordu. Burada SubViewport'u ekrandaki
## gerçek piksel sayısında çizip kutuya sığdırıyoruz.

var viewport := SubViewport.new()
var _rect := TextureRect.new()
## Tasarım biriminden gerçek piksele çarpan (telefonda genelde 2-3).
var pixel_scale := 1.0
## Grafik ayarına göre en fazla kaç piksel yükseklikte çizilir (0: sınırsız).
const MAX_HEIGHT := [480, 720, 0]


func _init() -> void:
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = Viewport.MSAA_DISABLED if GameState.settings.get("grafik", 1) == 0 else Viewport.MSAA_2X
	add_child(viewport)
	_rect.texture = viewport.get_texture()
	_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_rect.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_rect.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_rect)
	resized.connect(_update_size)


func _ready() -> void:
	get_viewport().size_changed.connect(_update_size)
	_update_size()


func _update_size() -> void:
	if not is_inside_tree():
		return
	pixel_scale = clampf(get_viewport().get_final_transform().x.x, 1.0, 3.0)
	# telefonun tam çözünürlüğü çok piksel demek; ayara göre sınırla
	var cap: int = MAX_HEIGHT[clampi(GameState.settings.get("grafik", 1), 0, 2)]
	if cap > 0 and size.y > 0:
		pixel_scale = clampf(minf(pixel_scale, cap / size.y), 1.0, 3.0)
	viewport.size = Vector2i((size * pixel_scale).round()).max(Vector2i.ONE)


## Kutudaki bir noktayı SubViewport pikseline çevirir (dokunma için).
func to_viewport(p: Vector2) -> Vector2:
	return p * pixel_scale
