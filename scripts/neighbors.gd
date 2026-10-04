class_name Neighbors
## Mahallenin komşuları. Her biri kendi evinin önünde dolaşır, günde bir rica
## eder ve her birinin işi farklıdır: Filiz pazar ya da kahvehaneden çay ister,
## Miyase yemek yaptırır, Hülya kaybettiği gözlüğünü aratır, Ahmet Amca çay
## dağıttırır. Ricayı yapınca dostluk kalbi kazanılır, kalpler dolunca hediye.

const MAX_HEARTS := 10
## Kalp eşiği -> hediye türü. "kurabiye" ve "can" kurabiye verir, "sus" mahalleye süs koyar.
const GIFTS := {3: "kurabiye", 6: "sus", 10: "can"}

## Hülya Teyze'nin gözlüğünü unutabileceği yerler.
const GLASSES_SPOTS := [
	Vector3(-6.2, 0, 2.8), Vector3(5.2, 0, 9.6), Vector3(-10.6, 0, 4.2), Vector3(11.8, 0, -3.2),
	Vector3(-3.4, 0, 10.6), Vector3(6.5, 0, -1.0), Vector3(-12.4, 0, -3.5), Vector3(3.6, 0, 15.2),
]

const ALL := [
	{"id": "filiz", "name": "Filiz Teyze", "scarf": "#3e8fb0", "cardigan": "#c96a43", "skirt": "#5c3a26", "hair": "#c9c4bd", "glasses": false,
		"unlock": 1, "house": Vector3(2.9, 0, -6.8), "home": Vector3(3.0, 0, -4.2), "area": Rect2(1.6, -4.4, 2.8, 1.4),
		"walls": "#f2d58a", "trim": "#5c3a26", "door": "#8a5a3b", "gift_decor": "kusevi",
		"intro_shop": "Evladım, bana kahvaltıya misafir gelecek. Pazardan %s alıverir misin? Çayı ben demlerim.",
		"intro_tea": "Ahmet'in kahvehanesinden bana bir çay kaptırıver evladım, demli olsun. Bacaklarım tutmuyor.",
		"thanks": "Sağ ol yavrum! Gel bir bardak çay iç, sonra gidersin.",
		"chat": [
			"Fatma Teyze'nin kurabiyelerinin sırrı tereyağıymış, kimseye söyleme.",
			"Benim çayım demli olur evladım, açık çay içen misafiri sevmem.",
			"Oğlum Almanya'dan aradı, yazın gelecekmiş. Hele şükür!",
			"Pamuk dün yine benim balkonda uyumuş. Pek tatlı şey.",
		]},
	{"id": "ahmet", "name": "Ahmet Amca", "gender": "erkek", "hair": 0, "hair_color": 5, "skin": 2, "top": 5, "bottom": 3,
		"mustache": true, "cap": true, "vest": "#5c3a26",
		"unlock": 1, "home": Vector3(-8.5, 0, 2.0), "area": Rect2(-10.0, 1.6, 3.0, 0.8), "gift_decor": "tavla",
		"intro": "Gel bakalım delikanlı! Çaylar demlendi, şu tepsiyi %s götürüver. Sonra bana dön.",
		"thanks": "Eline sağlık! Mahallenin çaycısı oldun valla.",
		"chat": [
			"Kırk yıldır bu kahvehaneyi işletirim, tavlada beni yenen olmadı.",
			"Çay ince belli bardakta içilir, kupa bardak çay değil.",
			"Pazardaki Hasan'ın domatesleri bu sene pek güzel.",
			"Sütlü her sabah kapıma gelir, ona peynir ayırırım.",
		]},
	{"id": "miyase", "name": "Miyase Teyze", "scarf": "#e8b33a", "cardigan": "#5b6fb5", "skirt": "#3f6a4a", "hair": "#6b4a35", "glasses": false,
		"unlock": 2, "house": Vector3(-9.0, 0, -6.7), "home": Vector3(-9.0, 0, -4.2), "area": Rect2(-10.4, -4.4, 2.8, 1.4),
		"walls": "#e8f0f4", "trim": "#3e6fb5", "door": "#c96a43", "gift_decor": "sardunya",
		"intro": "Akşama gelinim gelecek, %s yapacağım ama dizlerim tutmuyor. Mutfağa gel de yardım et evladım.",
		"thanks": "Oh, eline sağlık! Gelinim bayılacak, sen de tadına bak bakalım.",
		"chat": [
			"Börek dediğin el açması olur, hazır yufka börek değildir.",
			"Hülya yine yeni hırka almış, sorsan ucuzmuş.",
			"Bizim zamanımızda mahallede herkes birbirini tanırdı. Sen de tanı herkesi.",
			"Sardunyalarımı her sabah sularım, o yüzden böyle açarlar.",
		]},
	{"id": "hulya", "name": "Hülya Teyze", "scarf": "#8e5bb5", "cardigan": "#d6577a", "skirt": "#3e4f7a", "hair": "#a0452e", "glasses": false,
		"unlock": 3, "house": Vector3(9.0, 0, -6.8), "home": Vector3(9.0, 0, -4.2), "area": Rect2(7.6, -4.4, 2.8, 1.4),
		"walls": "#f6dfe4", "trim": "#8e5bb5", "door": "#4f8a5b", "gift_decor": "salincak",
		"intro": "Yavrum, gözlüğümü kaybettim! Bugün mahallede gezerken bir yerde bırakmışım. Bulur musun? Ben göremiyorum ki!",
		"thanks": "Gözlüğüm! Hah, şimdi her şey net. Aferin sana, al şu şekerlerden.",
		"chat": [
			"Duydun mu, Fırıncı Mehmet'in oğlu evleniyormuş!",
			"Altın gününde Miyase'nin böreği yine bitti, ben bir dilim alabildim.",
			"Ben gençken bu sokağın en iyi ip atlayanıydım, bilesin.",
			"Kurabiye mi? Bir tane alayım, perhizdeyim ama.",
		]},
]


static func get_neighbor(id: String) -> Dictionary:
	for n in ALL:
		if n["id"] == id:
			return n
	return {}


## Ricanın içeriği. kind: "shop" (pazardan al), "deliver" (çay götür),
## "find" (gözlüğü bul) ya da "game" (mini oyun, type alanında).
## others: ricayı alabilecek diğer kişilerin id'leri (çay dağıtımı için).
static func favor(id: String, seed: int, level: int, others := []) -> Dictionary:
	var n := get_neighbor(id)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var info := {}
	match id:
		"filiz":
			if seed % 2 == 0:
				info = Errands.build({"type": "pazar", "seed": seed, "level": mini(level, 4)})
				info["kind"] = "shop"
				info["intro"] = n["intro_shop"] % Errands.want_text(info["want"])
			else:
				info = {"kind": "deliver", "pickup": "ahmet", "targets": ["filiz"], "intro": n["intro_tea"]}
		"ahmet":
			var pool: Array = others.filter(func(o): return o != "ahmet")
			Errands._shuffle(pool, rng)
			var targets: Array = pool.slice(0, mini(pool.size(), 2 if level < 4 else 3))
			var names := targets.map(func(t): return name_of(t) + "'ye")
			info = {"kind": "deliver", "pickup": "", "targets": targets, "intro": n["intro"] % Errands._join(names)}
		"miyase":
			info = Errands.build({"type": "yemek", "seed": seed, "level": mini(level, 4)})
			info["kind"] = "game"
			info["type"] = "yemek"
			info["intro"] = n["intro"] % info["recipe"]
		"hulya":
			info = {"kind": "find", "spot": GLASSES_SPOTS[seed % GLASSES_SPOTS.size()], "intro": n["intro"]}
	info["thanks"] = n["thanks"]
	info["neighbor"] = id
	return info


static func name_of(id: String) -> String:
	if id == "fatma":
		return Errands.TEYZE
	return get_neighbor(id).get("name", id)


## Bir sonraki hediyenin kalp eşiği; hepsi alındıysa 0.
static func next_gift_at(hearts: int) -> int:
	for h in GIFTS:
		if hearts < h:
			return h
	return 0


static func gift_text(id: String, at: int) -> String:
	match GIFTS.get(at, ""):
		"kurabiye":
			return "10 kurabiye"
		"sus":
			return Decor.get_decor(get_neighbor(id)["gift_decor"]).get("name", "Bir süs")
		"can":
			return "Can dostu ve 25 kurabiye"
	return ""
