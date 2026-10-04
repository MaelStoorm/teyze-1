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

## Seviye 4'ten sonra gelen, dört kelimelik uzun haberler.
const LONG_MESSAGES := [
	{"icons": ["gunes", "cay", "simit", "ev"], "text": "Sabah çay demleyeceğim, simit alsın, bize gelsin de."},
	{"icons": ["ay", "borek", "kurabiye", "kapi"], "text": "Akşam börek de kurabiye de var, gelince kapıyı çalsın de."},
	{"icons": ["ev", "yumurta", "peynir", "cay"], "text": "Bize gelsin; yumurta, peynir, çay, hepsi hazır de."},
]

## Yemek tarifleri: ad -> malzemeler. Kiler: malzeme -> görünen ad.
const RECIPES := [
	{"name": "Menemen", "items": ["domates", "biber", "yumurta"]},
	{"name": "Mercimek Çorbası", "items": ["mercimek", "sogan", "havuc"]},
	{"name": "Sütlaç", "items": ["sut", "pirinc", "seker"]},
]
const PANTRY := {
	"domates": "domates", "biber": "biber", "yumurta": "yumurta", "mercimek": "mercimek",
	"sogan": "soğan", "havuc": "havuç", "sut": "süt", "pirinc": "pirinç", "seker": "şeker",
	"peynir": "peynir",
}

## Altın günü teyzeleri. likes: sevdiği ikram, hint: yanlışta söylediği ipucu.
const TEYZELER := [
	{"name": "Filiz Teyze", "scarf": "#3e8fb0", "cardigan": "#c96a43", "likes": "cay",
		"hint": "Ben demli bir şey içmeden konuşamam evladım."},
	{"name": "Miyase Teyze", "scarf": "#e8b33a", "cardigan": "#5b6fb5", "likes": "borek",
		"hint": "Tatlı değil, tuzlu ve hamurlu bir şey severim ben."},
	{"name": "Hülya Teyze", "scarf": "#8e5bb5", "cardigan": "#d6577a", "likes": "kurabiye",
		"hint": "Ah, tatlı bir şey olsa ne iyi olurdu."},
	{"name": "Nermin Hanım", "scarf": "#4f8a5b", "cardigan": "#8a5a3b", "likes": "simit",
		"hint": "Susamlı, çıtır bir şey olsun yavrum."},
]
const IKRAM := ["cay", "borek", "kurabiye", "simit"]


## Görevin içeriğini seed'den üretir; aynı görev hep aynı içerikle açılır.
static func build(errand: Dictionary) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = errand.get("seed", 0)
	var lv: int = errand.get("level", 1)
	match errand.get("type"):
		"pazar":
			var keys := MARKET.keys()
			_shuffle(keys, rng)
			var want := {}
			var kinds := 3 if lv >= 3 else rng.randi_range(2, 3)
			for k in keys.slice(0, kinds):
				want[k] = rng.randi_range(1, 3 if lv >= 5 else 2)
			var parts := []
			for k in want:
				parts.append("%d %s" % [want[k], MARKET[k]])
			return {
				"want": want,
				"intro": "Evladım, pazara gidiver de bana %s al. Allah razı olsun!" % _join(parts),
				"thanks": "Maşallah, hepsi tamam! Eline sağlık yavrum.",
			}
		"haber":
			var list: Array = LONG_MESSAGES if lv >= 4 else MESSAGES
			var msg: Dictionary = list[rng.randi() % list.size()]
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
		"yemek":
			var r: Dictionary = RECIPES[rng.randi() % RECIPES.size()]
			var names := []
			for k in r["items"]:
				names.append(PANTRY[k])
			return {
				"recipe": r["name"],
				"items": r["items"],
				"stirs": 8 + mini(lv, 6),
				"intro": "Evladım, akşama %s yapalım mı? Bana %s lazım. Sonra güzelce karıştırırsın." % [r["name"], _join(names)],
				"thanks": "Mis gibi kokuyor! Ellerine sağlık, %s olmuş maşallah." % r["name"],
			}
		"altin":
			var guests: Array = TEYZELER.slice(0, 4 if lv >= 5 else 3)
			return {
				"guests": guests,
				"intro": "Bu ay altın günü bende! %s altınlarını toplayıverir misin? Giderken ikramlarını unutma." % _join(guests.map(func(g): return g["name"])),
				"thanks": "Altınlar tamam! Altın günü bu sefer çok güzel olacak.",
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
