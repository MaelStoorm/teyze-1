class_name Neighbors
## Mahallede dolaşan komşu teyzeler. Her biri günde bir rica eder; ricayı
## yapınca dostluk kalbi kazanılır, kalpler dolunca hediye verirler.

const MAX_HEARTS := 10
## Kalp eşiği -> hediye türü. "kurabiye" ve "can" kurabiye verir, "sus" mahalleye süs koyar.
const GIFTS := {3: "kurabiye", 6: "sus", 10: "can"}

const ALL := [
	{"id": "filiz", "name": "Filiz Teyze", "scarf": "#3e8fb0", "cardigan": "#c96a43", "skirt": "#5c3a26",
		"unlock": 1, "type": "pazar", "home": Vector3(3.0, 0, -3.7), "area": Rect2(1.4, -4.4, 4.0, 1.6),
		"gift_decor": "kusevi",
		"intro": "Evladım, bana kahvaltıya misafir gelecek. Pazardan %s alıverir misin? Çayı ben demlerim.",
		"thanks": "Sağ ol yavrum, sofra tamam! Gel bir bardak çay iç, sonra gidersin.",
		"chat": [
			"Fatma Teyze'nin kurabiyelerinin sırrı tereyağıymış, kimseye söyleme.",
			"Benim çayım demli olur evladım, açık çay içen misafiri sevmem.",
			"Oğlum Almanya'dan aradı, bayramda gelecekmiş. Hele şükür!",
			"Pamuk dün yine benim balkonda uyumuş. Pek tatlı şey.",
		]},
	{"id": "miyase", "name": "Miyase Teyze", "scarf": "#e8b33a", "cardigan": "#5b6fb5", "skirt": "#3f6a4a",
		"unlock": 2, "type": "yemek", "home": Vector3(-3.6, 0, 3.4), "area": Rect2(-5.4, 2.9, 3.2, 1.0),
		"gift_decor": "sardunya",
		"intro": "Akşama gelinim gelecek, %s yapacağım ama dizlerim tutmuyor. Yardım eder misin evladım?",
		"thanks": "Oh, eline sağlık! Gelinim bayılacak, sen de tadına bak bakalım.",
		"chat": [
			"Börek dediğin el açması olur, hazır yufka börek değildir.",
			"Hülya yine yeni hırka almış, sorsan ucuzmuş.",
			"Bizim zamanımızda mahallede herkes birbirini tanırdı. Sen de tanı herkesi.",
			"Sardunyalarımı her sabah sularım, o yüzden böyle açarlar.",
		]},
	{"id": "hulya", "name": "Hülya Teyze", "scarf": "#8e5bb5", "cardigan": "#d6577a", "skirt": "#3e4f7a",
		"unlock": 3, "type": "haber", "home": Vector3(2.0, 0, 4.6), "area": Rect2(1.2, 4.2, 2.6, 3.2),
		"gift_decor": "salincak",
		"intro": "Yavrum, %s'a bir haber götürür müsün? Telefonu açmıyor yine. Şöyle de: %s",
		"thanks": "Haber yerine ulaştı mı? Aferin sana! Al şu şekerlerden.",
		"chat": [
			"Duydun mu, köşedeki bakkal torununu evlendiriyormuş!",
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


## Ricanın mini oyun içeriği: teyzenin görevleriyle aynı oyunlar, komşunun sözleriyle.
static func favor(id: String, seed: int, level: int) -> Dictionary:
	var n := get_neighbor(id)
	var info := Errands.build({"type": n["type"], "seed": seed, "level": mini(level, 4)})
	match n["type"]:
		"pazar":
			var parts := []
			for k in info["want"]:
				parts.append("%d %s" % [info["want"][k], Errands.MARKET[k]])
			info["intro"] = n["intro"] % Errands._join(parts)
		"yemek":
			info["intro"] = n["intro"] % info["recipe"]
		"haber":
			info["intro"] = n["intro"] % [Errands.KOMSU, info["text"]]
	info["thanks"] = n["thanks"]
	info["neighbor"] = id
	return info


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
