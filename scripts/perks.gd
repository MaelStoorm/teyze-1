class_name Perks
## Dükkanda kurabiyeyle alınan kalıcı özellikler.
## Gerçek parayla satın alma, Google Play hesabı onaylanınca buraya eklenebilir.

const ALL := [
	{"id": "zil", "icon": "zil", "name": "Pamuk'un Zili",
		"desc": "Kayıp kedide Pamuk'un zili çalar: ilk dokunuştan sonra saklandığı yer parlar.",
		"price": 15, "max": 1},
	{"id": "defter", "icon": "defter", "name": "Not Defteri",
		"desc": "Komşuya haberde ilk kelime deftere yazılı gelir.",
		"price": 15, "max": 1},
	{"id": "file", "icon": "file", "name": "Pazar Filesi",
		"desc": "Pazarda istenmeyen ürünler soluk görünür, her pazardan +1 kurabiye.",
		"price": 20, "max": 1},
	{"id": "kepce", "icon": "tencere", "name": "Bakır Kepçe",
		"desc": "Yemekte karıştırmak yarı yarıya kısalır.",
		"price": 20, "max": 1},
	{"id": "kese", "icon": "kese", "name": "Altın Kesesi",
		"desc": "Altın gününde teyzeler bir çeyrek fazla verir.",
		"price": 30, "max": 1},
	{"id": "dua", "icon": "heart", "name": "Teyzenin Duası",
		"desc": "Her görevden +1 kurabiye. 3 kez alınabilir.",
		"price": 25, "max": 3},
	{"id": "takvim", "icon": "takvim", "name": "Dolu Takvim",
		"desc": "Her gün +1 görev, daha çok kurabiye ve tecrübe.",
		"price": 40, "max": 2},
]


static func get_perk(id: String) -> Dictionary:
	for p in ALL:
		if p["id"] == id:
			return p
	return {}


## Bir sonraki seviyenin fiyatı (her seviye %60 daha pahalı).
static func price(id: String, current_level: int) -> int:
	var base: int = get_perk(id)["price"]
	return int(round(base * pow(1.6, current_level)))
