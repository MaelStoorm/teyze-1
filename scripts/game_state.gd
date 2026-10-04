extends Node
## Oyuncunun ilerlemesi. Telefona kaydedilir, internet gerekmez.

signal changed

const SAVE_PATH := "user://kayit.cfg"
const ERRAND_TYPES := ["pazar", "haber", "kedi"]
const REWARD := 3

var kurabiye := 0
var day := 1
## Bugünün görevleri, sırayla. Her biri {"type": String, "seed": int}.
var errands: Array = []
var done_count := 0


func _ready() -> void:
	load_game()
	if errands.is_empty():
		new_day(false)


func current_errand() -> Dictionary:
	if done_count < errands.size():
		return errands[done_count]
	return {}


func is_day_over() -> bool:
	return done_count >= errands.size()


func complete_errand() -> void:
	done_count += 1
	kurabiye += REWARD
	save_game()
	changed.emit()


func new_day(advance := true) -> void:
	if advance:
		day += 1
	var types := ERRAND_TYPES.duplicate()
	types.shuffle()
	errands.clear()
	for t in types:
		errands.append({"type": t, "seed": randi()})
	done_count = 0
	save_game()
	changed.emit()


func save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("oyuncu", "kurabiye", kurabiye)
	cfg.set_value("oyuncu", "gun", day)
	cfg.set_value("gun", "gorevler", errands)
	cfg.set_value("gun", "biten", done_count)
	cfg.save(SAVE_PATH)


func load_game() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	kurabiye = cfg.get_value("oyuncu", "kurabiye", 0)
	day = cfg.get_value("oyuncu", "gun", 1)
	errands = cfg.get_value("gun", "gorevler", [])
	done_count = cfg.get_value("gun", "biten", 0)


func reset() -> void:
	kurabiye = 0
	day = 1
	new_day(false)
