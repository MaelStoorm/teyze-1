extends Node
## Oyuncunun ilerlemesi. Telefona kaydedilir, internet gerekmez.

signal changed
signal leveled_up(level: int)
## Albüme yeni bir anı kartı eklendi.
signal remembered(id: String)

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
var settings := {"text": 1.0, "sound": true, "music": true, "tutorial": false, "grafik": 1}
## Henüz gösterilmemiş günlük hediye (kurabiye). Ana ekran gösterip sıfırlar.
var daily_gift := 0
## Haftanın 7. gününün sürprizi: hediye edilen ev eşyasının id'si (gösterilince silinir).
var daily_surprise := ""
## Hediye takviminin günleri: üst üste gelinen her gün biraz daha çok kurabiye,
## 7. gün büyük hediye ve evin için bir sürpriz eşya. Sonra hafta baştan başlar.
const GIFT_DAYS := [3, 4, 5, 6, 7, 8, 12]
## Komşularla dostluk: id -> kalp sayısı.
var friendship := {}
## Bugün ricası yapılan komşular: id -> true. Yeni günde sıfırlanır.
var favors_done := {}
## Komşu ricalarının bugünkü içerik tohumları: id -> seed.
var favor_seeds := {}
## Oyuncunun karakteri (Avatar.DEFAULT anahtarları). Boşsa henüz oluşturulmadı.
var avatar := {}
## Sütlü'nün son beslendiği gün ve kaç gün beslendiği.
var sutlu_fed := ""
var sutlu_love := 0
## Evin içi: yer (slot) id -> eşya id. Kurabiyeyle alınan eşyalar: id -> true.
var ev := {}
var ev_items := {}
## Bostan: her tarh {"crop": "domates", "planted": "YYYY-MM-DD"} ya da boş {}.
var bostan: Array = [{}, {}, {}, {}]
## Bostandan toplanıp henüz verilmemiş sebzeler: id -> adet.
var harvest := {}
## Bugün bostandan hediye verilen komşular: id -> true. Yeni günde sıfırlanır.
var gifts_today := {}
## Ahmet Amca'yla tavla: kazanılan ve oynanan oyunlar.
var tavla_won := 0
var tavla_played := 0
## Mahalle albümü: açılan anı kartları, id -> tarih (YYYY-MM-DD).
var album := {}
## Hikaye: hangi bölümde, hangi adımda; seçimlerle konan bayraklar.
var story_ch := 0
var story_step := 0
var story_flags := {}
## Fırından bugün sıcak simit alındı mı (tarih).
var simit_day := ""


func _ready() -> void:
	load_game()
	if errands.is_empty():
		new_day(false)
		errands_date = today()
		streak = 1
		save_game()
	check_new_day()


func set_avatar(look: Dictionary) -> void:
	avatar = look.duplicate()
	save_game()
	changed.emit()


## Teyzelerin sana seslenişi: adın varsa adın, yoksa "evladım".
func call_name() -> String:
	var n: String = avatar.get("name", "")
	return n if n != "" else "evladım"


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
	daily_gift = GIFT_DAYS[gift_day() - 1]
	kurabiye += daily_gift
	daily_surprise = ""
	if gift_day() == 7:
		daily_surprise = _surprise_item()
		if daily_surprise != "":
			ev_items[daily_surprise] = true
	errands_date = now
	new_day()
	return true


## Hediye takviminde bugün kaçıncı gün (1-7).
func gift_day() -> int:
	return (maxi(streak, 1) - 1) % 7 + 1


## Henüz alınmamış ev eşyalarından en ucuzlardan biri (hepsi alındıysa "").
func _surprise_item() -> String:
	var free: Array = EvEsya.ALL.filter(func(it): return not ev_items.has(it["id"]))
	if free.is_empty():
		return ""
	free.sort_custom(func(a, b): return a["price"] < b["price"])
	free = free.slice(0, 6)
	return free[hash(today()) % free.size()]["id"]


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


# --- Sütlü -----------------------------------------------------------------

func sutlu_fed_today() -> bool:
	return sutlu_fed == today()


func feed_sutlu() -> int:
	if not sutlu_fed_today():
		sutlu_fed = today()
		sutlu_love += 1
		save_game()
		changed.emit()
	return sutlu_love


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
	favors_done[id] = true
	return _befriend(id, 2 + perk_level("dua"), XP_PER_ERRAND / 2)


## Dostluğa bir kalp ekler, eşikteyse hediyesini verir.
func _befriend(id: String, base_reward: int, gain_xp: int) -> Dictionary:
	var before := level()
	var h := mini(hearts(id) + 1, Neighbors.MAX_HEARTS)
	var gained := h > hearts(id)
	friendship[id] = h
	var reward := base_reward
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
	xp += gain_xp
	save_game()
	changed.emit()
	var after := level()
	if after > before:
		leveled_up.emit(after)
	return {"reward": reward, "hearts": h, "gift": gift}


## Bugün yağmurlu mu? Takvim gününe göre sabit (her dört günden biri kadar).
func is_rainy() -> bool:
	return hash(today() + "yagmur") % 4 == 0


# --- bostan -----------------------------------------------------------------

const CROPS := {
	"domates": {"name": "domates", "yield": 3},
	"biber": {"name": "biber", "yield": 3},
	"havuc": {"name": "havuç", "yield": 3},
	"karpuz": {"name": "karpuz", "yield": 1},
}


## "empty", "growing" (bugün ekildi) ya da "ripe" (ertesi gün olgunlaşır).
func bed_state(i: int) -> String:
	var b: Dictionary = bostan[i]
	if b.is_empty():
		return "empty"
	return "ripe" if days_between(b["planted"], today()) >= 1 else "growing"


func plant(i: int, crop: String) -> void:
	bostan[i] = {"crop": crop, "planted": today()}
	save_game()
	changed.emit()


## Olgun tarhı toplar; kaç tane toplandığını döner.
func harvest_bed(i: int) -> int:
	if bed_state(i) != "ripe":
		return 0
	var crop: String = bostan[i]["crop"]
	var n: int = CROPS[crop]["yield"]
	harvest[crop] = harvest.get(crop, 0) + n
	bostan[i] = {}
	remember("hasat")
	xp += 2
	save_game()
	changed.emit()
	return n


func harvest_count() -> int:
	var n := 0
	for k in harvest:
		n += harvest[k]
	return n


func add_kurabiye(n: int) -> void:
	kurabiye += n
	save_game()
	changed.emit()


func can_gift(id: String) -> bool:
	return harvest_count() > 0 and not gifts_today.has(id)


## Komşuya bostandan bir sebze hediye eder: bir kalp ve biraz kurabiye.
func gift_harvest(id: String) -> Dictionary:
	var crop: String = ""
	for k in harvest:
		if harvest[k] > 0:
			crop = k
			break
	if crop == "" or gifts_today.has(id):
		return {}
	harvest[crop] -= 1
	if harvest[crop] <= 0:
		harvest.erase(crop)
	gifts_today[id] = true
	remember("hediye")
	var r := _befriend(id, 3, 4)
	r["crop"] = crop
	return r


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
	if type == "pazar":
		remember("pazar")
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
	gifts_today.clear()
	for t in types:
		errands.append({"type": t, "seed": randi(), "level": level()})
	done_count = 0
	save_game()
	changed.emit()


# --- kayıt -------------------------------------------------------------------

# --- hikaye -------------------------------------------------------------------

## Şu anki hikaye adımı; bölümler bittiyse boş.
func story_now() -> Dictionary:
	return Hikaye.step(story_ch, story_step)


## Bir bölüm bitti mi (fırın açık mı vb.).
func chapter_done(id: String) -> bool:
	for i in mini(story_ch, Hikaye.CHAPTERS.size()):
		if Hikaye.CHAPTERS[i]["id"] == id:
			return true
	return false


func advance_story() -> void:
	story_step += 1
	var c := Hikaye.chapter(story_ch)
	if not c.is_empty() and story_step >= c["steps"].size():
		story_ch += 1
		story_step = 0
	save_game()
	changed.emit()


## Fırından alınan sıcak simit bir komşuya: bir kalp ve biraz kurabiye.
func gift_simit(id: String) -> Dictionary:
	remember("simit")
	return _befriend(id, 2, 3)


func simit_ready() -> bool:
	return chapter_done("firin") and simit_day != today()


## Albüme bir anı ekler; yeniyse true. (Kaydı çağıran yapar.)
func remember(id: String, silent := false) -> bool:
	if album.has(id) or Album.get_card(id).is_empty():
		return false
	album[id] = today()
	if not silent:
		remembered.emit(id)
	return true


## Oyunun durumundan anlaşılan anıları albüme ekler.
func _check_album(silent := false) -> void:
	var conds := {
		"sutlu": sutlu_love >= 1,
		"sutlu7": sutlu_love >= 7,
		"dost": friendship.values().any(func(h): return h > 0),
		"herkes": Neighbors.ALL.all(func(n): return hearts(n["id"]) > 0),
		"can_dost": friendship.values().any(func(h): return h >= Neighbors.MAX_HEARTS),
		"ekim": bostan.any(func(b): return not b.is_empty()),
		"ev": not ev.is_empty(),
		"ev_dolu": EvEsya.SLOTS.all(func(sl): return ev.get(sl["id"], "") != ""),
		"dukkan": not perks.is_empty(),
		"sus": not decor.is_empty(),
		"tavla": tavla_won > 0,
		"hafta": streak >= 7,
		"seviye5": level() >= 5,
		"kurabiye": kurabiye >= 100,
	}
	for id in conds:
		if conds[id]:
			remember(id, silent)


func save_game() -> void:
	_check_album()
	var cfg := ConfigFile.new()
	cfg.set_value("album", "anilar", album)
	cfg.set_value("hikaye", "bolum", story_ch)
	cfg.set_value("hikaye", "adim", story_step)
	cfg.set_value("hikaye", "bayraklar", story_flags)
	cfg.set_value("hikaye", "simit", simit_day)
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
	cfg.set_value("oyuncu", "karakter", avatar)
	cfg.set_value("sutlu", "beslendi", sutlu_fed)
	cfg.set_value("sutlu", "sevgi", sutlu_love)
	cfg.set_value("komsular", "dostluk", friendship)
	cfg.set_value("komsular", "ricalar", favors_done)
	cfg.set_value("komsular", "tohumlar", favor_seeds)
	cfg.set_value("ev", "yerler", ev)
	cfg.set_value("ev", "esyalar", ev_items)
	cfg.set_value("bostan", "tarhlar", bostan)
	cfg.set_value("bostan", "hasat", harvest)
	cfg.set_value("bostan", "hediyeler", gifts_today)
	cfg.set_value("tavla", "kazanilan", tavla_won)
	cfg.set_value("tavla", "oynanan", tavla_played)
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
	avatar = cfg.get_value("oyuncu", "karakter", {})
	sutlu_fed = cfg.get_value("sutlu", "beslendi", "")
	sutlu_love = cfg.get_value("sutlu", "sevgi", 0)
	friendship = cfg.get_value("komsular", "dostluk", {})
	favors_done = cfg.get_value("komsular", "ricalar", {})
	favor_seeds = cfg.get_value("komsular", "tohumlar", {})
	ev = cfg.get_value("ev", "yerler", {})
	ev_items = cfg.get_value("ev", "esyalar", {})
	bostan = cfg.get_value("bostan", "tarhlar", [{}, {}, {}, {}])
	harvest = cfg.get_value("bostan", "hasat", {})
	gifts_today = cfg.get_value("bostan", "hediyeler", {})
	tavla_won = cfg.get_value("tavla", "kazanilan", 0)
	tavla_played = cfg.get_value("tavla", "oynanan", 0)
	album = cfg.get_value("album", "anilar", {})
	story_ch = cfg.get_value("hikaye", "bolum", 0)
	story_step = cfg.get_value("hikaye", "adim", 0)
	story_flags = cfg.get_value("hikaye", "bayraklar", {})
	simit_day = cfg.get_value("hikaye", "simit", "")
	_check_album(true)  # eski kayıtlarda zaten yaşanmış anılar sessizce eklenir


func reset() -> void:
	kurabiye = 0
	day = 1
	xp = 0
	perks = {}
	decor = {}
	friendship = {}
	avatar = {}
	sutlu_fed = ""
	sutlu_love = 0
	ev = {}
	ev_items = {}
	bostan = [{}, {}, {}, {}]
	harvest = {}
	gifts_today = {}
	tavla_won = 0
	tavla_played = 0
	album = {}
	story_ch = 0
	story_step = 0
	story_flags = {}
	simit_day = ""
	fresh_unlocks = []
	streak = 1
	daily_gift = 0
	daily_surprise = ""
	errands_date = today()
	new_day(false)
