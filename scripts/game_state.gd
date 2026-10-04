extends Node
## Oyuncunun ilerlemesi. Telefona kaydedilir, internet gerekmez.

signal changed
signal leveled_up(level: int)

const SAVE_PATH := "user://kayit.cfg"
const REWARD := 3
const XP_PER_ERRAND := 10
## Seviye eşikleri: index = seviye - 1. Son seviyeden sonra her 80 XP bir seviye.
const LEVEL_XP := [0, 30, 70, 120, 180, 250]
## Görev türü -> açıldığı seviye.
const UNLOCKS := {"pazar": 1, "haber": 1, "kedi": 1, "yemek": 2, "altin": 3}

var kurabiye := 0
var day := 1
var xp := 0
## Satın alınan perkler: id -> seviye.
var perks := {}
## Mahalleye eklenen süsler: id -> true.
var decor := {}
## Bugünün görevleri, sırayla. Her biri {"type": String, "seed": int}.
var errands: Array = []
var done_count := 0
## Bir sonraki günde mutlaka gelecek, yeni açılmış görev türleri.
var fresh_unlocks: Array = []
## Bugünün görevlerinin ait olduğu takvim günü (YYYY-MM-DD, telefonun saati).
var errands_date := ""
## Kaç gündür üst üste gelindi.
var streak := 0
## Oyuncu ayarları: yazı boyutu çarpanı, ses, müzik, rehber görüldü mü.
var settings := {"text": 1.0, "sound": true, "music": true, "tutorial": false}
## Henüz gösterilmemiş günlük hediye (kurabiye). Ana ekran gösterip sıfırlar.
var daily_gift := 0
## Komşularla dostluk: id -> kalp sayısı.
var friendship := {}
## Bugün ricası yapılan komşular: id -> true. Yeni günde sıfırlanır.
var favors_done := {}
## Komşu ricalarının bugünkü içerik tohumları: id -> seed.
var favor_seeds := {}


func _ready() -> void:
	load_game()
	if errands.is_empty():
		new_day(false)
		errands_date = today()
		streak = 1
		save_game()
	check_new_day()


func set_setting(key: String, value) -> void:
	settings[key] = value
	save_game()


# --- takvim -----------------------------------------------------------------

static func today() -> String:
	return Time.get_date_string_from_system()


static func days_between(a: String, b: String) -> int:
	if a == "" or b == "":
		return 0
	var ta := Time.get_unix_time_from_datetime_string(a)
	var tb := Time.get_unix_time_from_datetime_string(b)
	return int(round((tb - ta) / 86400.0))


## Telefonun takviminde yeni bir güne geçildiyse yeni görevleri ve günlük
## hediyeyi hazırlar. Oyun açılınca ve uygulamaya geri dönülünce çağrılır.
func check_new_day() -> bool:
	var now := today()
	var gap := days_between(errands_date, now)
	if errands_date != "" and gap <= 0:
		return false
	streak = streak + 1 if gap == 1 else 1
	daily_gift = 2 + mini(streak, 7)
	kurabiye += daily_gift
	errands_date = now
	new_day()
	return true


# --- seviye ---------------------------------------------------------------

func level() -> int:
	var lv := 1
	for i in LEVEL_XP.size():
		if xp >= LEVEL_XP[i]:
			lv = i + 1
	if xp > LEVEL_XP[-1]:
		lv += (xp - LEVEL_XP[-1]) / 80
	return lv


func level_progress() -> float:
	var lv := level()
	var lo := _xp_for(lv)
	var hi := _xp_for(lv + 1)
	return clampf(float(xp - lo) / float(hi - lo), 0.0, 1.0)


func _xp_for(lv: int) -> int:
	if lv - 1 < LEVEL_XP.size():
		return LEVEL_XP[lv - 1]
	return LEVEL_XP[-1] + (lv - LEVEL_XP.size()) * 80


func unlocked_types() -> Array:
	var lv := level()
	return UNLOCKS.keys().filter(func(t): return UNLOCKS[t] <= lv)


# --- komşular ----------------------------------------------------------------

func neighbors_unlocked() -> Array:
	return Neighbors.ALL.filter(func(n): return n["unlock"] <= level())


func hearts(id: String) -> int:
	return friendship.get(id, 0)


func favor_available(id: String) -> bool:
	return not favors_done.has(id)


func favor_seed(id: String) -> int:
	if not favor_seeds.has(id):
		favor_seeds[id] = randi()
	return favor_seeds[id]


## Ricayı bitirir. Dönen sözlük: reward (kurabiye), hearts, gift (eşik ya da 0).
func complete_favor(id: String) -> Dictionary:
	var before := level()
	favors_done[id] = true
	var h := mini(hearts(id) + 1, Neighbors.MAX_HEARTS)
	var gained := h > hearts(id)
	friendship[id] = h
	var reward := 2 + perk_level("dua")
	var gift := 0
	if gained and Neighbors.GIFTS.has(h):
		gift = h
		match Neighbors.GIFTS[h]:
			"kurabiye":
				reward += 10
			"can":
				reward += 25
			"sus":
				decor[Neighbors.get_neighbor(id)["gift_decor"]] = true
	kurabiye += reward
	xp += XP_PER_ERRAND / 2
	save_game()
	changed.emit()
	var after := level()
	if after > before:
		leveled_up.emit(after)
	return {"reward": reward, "hearts": h, "gift": gift}


func errands_per_day() -> int:
	var n := 3
	if level() >= 4:
		n += 1
	return n + perk_level("takvim")


# --- perkler -----------------------------------------------------------------

func perk_level(id: String) -> int:
	return perks.get(id, 0)


func has_perk(id: String) -> bool:
	return perk_level(id) > 0


func buy_perk(id: String) -> bool:
	var p: Dictionary = Perks.get_perk(id)
	var lv := perk_level(id)
	if lv >= p["max"]:
		return false
	var price := Perks.price(id, lv)
	if kurabiye < price:
		return false
	kurabiye -= price
	perks[id] = lv + 1
	save_game()
	changed.emit()
	return true


func buy_decor(id: String) -> bool:
	var d: Dictionary = Decor.get_decor(id)
	if d.is_empty() or decor.has(id) or kurabiye < d["price"]:
		return false
	kurabiye -= d["price"]
	decor[id] = true
	save_game()
	changed.emit()
	return true


# --- gün akışı ---------------------------------------------------------------

func current_errand() -> Dictionary:
	if done_count < errands.size():
		return errands[done_count]
	return {}


func is_day_over() -> bool:
	return done_count >= errands.size()


func errand_reward(type: String) -> int:
	var r := REWARD + perk_level("dua")
	if type == "pazar" and has_perk("file"):
		r += 1
	return r


## Görev bitince verilen kurabiyeyi döndürür.
func complete_errand(type: String, bonus := 0) -> int:
	var before := level()
	var reward := errand_reward(type) + bonus
	done_count += 1
	kurabiye += reward
	xp += XP_PER_ERRAND
	var after := level()
	for t in UNLOCKS:
		if UNLOCKS[t] > before and UNLOCKS[t] <= after:
			fresh_unlocks.append(t)
	save_game()
	changed.emit()
	if after > before:
		leveled_up.emit(after)
	return reward


func new_day(advance := true) -> void:
	if advance:
		day += 1
	var pool := unlocked_types()
	var types: Array = fresh_unlocks.duplicate()
	fresh_unlocks.clear()
	var n := errands_per_day()
	# Önce hiç tekrar etmeden, havuz biterse baştan.
	while types.size() < n:
		var bag := pool.filter(func(t): return t not in types)
		if bag.is_empty():
			bag = pool.duplicate()
		bag.shuffle()
		types.append(bag[0])
	types.shuffle()
	errands.clear()
	favors_done.clear()
	favor_seeds.clear()
	for t in types:
		errands.append({"type": t, "seed": randi(), "level": level()})
	done_count = 0
	save_game()
	changed.emit()


# --- kayıt -------------------------------------------------------------------

func save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("oyuncu", "kurabiye", kurabiye)
	cfg.set_value("oyuncu", "gun", day)
	cfg.set_value("oyuncu", "xp", xp)
	cfg.set_value("oyuncu", "perkler", perks)
	cfg.set_value("oyuncu", "susler", decor)
	cfg.set_value("gun", "gorevler", errands)
	cfg.set_value("gun", "biten", done_count)
	cfg.set_value("gun", "yeni", fresh_unlocks)
	cfg.set_value("gun", "tarih", errands_date)
	cfg.set_value("oyuncu", "seri", streak)
	cfg.set_value("ayarlar", "hepsi", settings)
	cfg.set_value("komsular", "dostluk", friendship)
	cfg.set_value("komsular", "ricalar", favors_done)
	cfg.set_value("komsular", "tohumlar", favor_seeds)
	cfg.save(SAVE_PATH)


func load_game() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	kurabiye = cfg.get_value("oyuncu", "kurabiye", 0)
	day = cfg.get_value("oyuncu", "gun", 1)
	xp = cfg.get_value("oyuncu", "xp", 0)
	perks = cfg.get_value("oyuncu", "perkler", {})
	decor = cfg.get_value("oyuncu", "susler", {})
	errands = cfg.get_value("gun", "gorevler", [])
	done_count = cfg.get_value("gun", "biten", 0)
	fresh_unlocks = cfg.get_value("gun", "yeni", [])
	errands_date = cfg.get_value("gun", "tarih", "")
	streak = cfg.get_value("oyuncu", "seri", 0)
	settings.merge(cfg.get_value("ayarlar", "hepsi", {}), true)
	friendship = cfg.get_value("komsular", "dostluk", {})
	favors_done = cfg.get_value("komsular", "ricalar", {})
	favor_seeds = cfg.get_value("komsular", "tohumlar", {})


func reset() -> void:
	kurabiye = 0
	day = 1
	xp = 0
	perks = {}
	decor = {}
	friendship = {}
	fresh_unlocks = []
	streak = 1
	daily_gift = 0
	errands_date = today()
	new_day(false)
