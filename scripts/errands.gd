class_name Errands
## Teyzenin görevleri: metinler ve rastgele içerik. Yeni görev eklemek için
## burada bir tür ve main.gd içinde bir mini oyun eklemek yeterli.

const TEYZE := "Fatma Teyze"
const KOMSU := "Nermin Hanım"

const MARKET := {
	"domates": "domates",
	"ekmek": "ekmek",
	"simit": "simit",
	"peynir": "peynir",
	"zeytin": "zeytin",
	"karpuz": "karpuz",
	"yumurta": "yumurta",
}

const ICON_NAMES := {
	"ay": "akşam", "gunes": "sabah", "cay": "çay", "borek": "börek",
	"ev": "bize", "kurabiye": "kurabiye", "simit": "simit", "kapi": "kapı",
	"yumurta": "yumurta", "peynir": "peynir",
}

const MESSAGES := [
	{"icons": ["ay", "cay", "borek"], "text": "Akşam çaya buyursun, börek yaptım de."},
	{"icons": ["gunes", "simit", "ev"], "text": "Sabah simit alıp bize kahvaltıya gelsin de."},
	{"icons": ["ay", "kurabiye", "kapi"], "text": "Akşam kurabiye getireceğim, kapıyı açık bıraksın de."},
	{"icons": ["gunes", "yumurta", "peynir"], "text": "Sabah yumurtayla peynir getirsin de."},
	{"icons": ["ev", "cay", "kurabiye"], "text": "Bize gelsin, çay demledim, kurabiye de var de."},
]


## Görevin içeriğini seed'den üretir; aynı görev hep aynı içerikle açılır.
static func build(errand: Dictionary) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = errand.get("seed", 0)
	match errand.get("type"):
		"pazar":
			var keys := MARKET.keys()
			_shuffle(keys, rng)
			var want := {}
			for k in keys.slice(0, rng.randi_range(2, 3)):
				want[k] = rng.randi_range(1, 2)
			var parts := []
			for k in want:
				parts.append("%d %s" % [want[k], MARKET[k]])
			return {
				"want": want,
				"intro": "Evladım, pazara gidiver de bana %s al. Allah razı olsun!" % _join(parts),
				"thanks": "Maşallah, hepsi tamam! Eline sağlık yavrum.",
			}
		"haber":
			var msg: Dictionary = MESSAGES[rng.randi() % MESSAGES.size()]
			return {
				"icons": msg["icons"],
				"text": msg["text"],
				"intro": "Karşı komşu %s'a bir haber götürür müsün? %s" % [KOMSU, msg["text"]],
				"thanks": "%s gelecekmiş, sağ ol evladım. Ne iyi çocuksun!" % KOMSU,
			}
		"kedi":
			return {
				"spot": rng.randi() % 6,
				"intro": "Pamuk yine kaçtı! Bahçede bir yere saklanmıştır, bulur musun yavrum?",
				"thanks": "Pamuğum gel buraya! Sen olmasan ne yapardım evladım.",
			}
	return {}


static func _shuffle(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp


static func _join(parts: Array) -> String:
	if parts.size() == 1:
		return parts[0]
	return ", ".join(parts.slice(0, -1)) + " ve " + parts[-1]
