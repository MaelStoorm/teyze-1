class_name Hikaye
## Mahallenin hikayesi: bölüm bölüm mahalleyi yeniden canlandırırsın.
## Her bölüm bir yeri açar ve mahalle gözle görülür biçimde değişir.
##
## Adım alanları:
##   who   kimle konuşulacak (dünyadaki hedef id: "fatma", "stall_firin", "ahmet"...)
##   goal  üstte yazan hedef
##   lines o kişinin sırayla söylediği sözler; sonuncusunda "do" çalışır
##   btn   son sözün düğmesi
##   do    {} sadece konuşma
##         {"deliver": [hedefler], "carry": ikon}   taşıyıp götür
##         {"invite": ikon}   açık her komşuya ve Fatma'ya götür
##         {"pay": n}   n kurabiye ver (günlük işlerle biriktirilir)
##         {"game": tür}   komşuyla oyun (manti, cay, orgu, balik, tavla)
##         {"choice": [[düğme, bayrak, cevap], ...]}   seçim; bayrak saklanır
##         {"finale": true}   bölüm biter, ödül
## "who_name": hedefin konuşma kutusundaki adı (tezgahlar için).

const CHAPTERS := [
	{
		"id": "firin",
		"title": "Fırının Işığı",
		"reward": 30,
		"steps": [
			{"who": "fatma", "goal": "Fatma Teyze'yle konuş",
				"lines": [
					"Evladım, sana bir şey anlatayım. Eskiden bu mahalle sabahları simit kokardı. Mehmet Usta'nın fırını sokağın başındaydı, herkes orada buluşurdu.",
					"Ama fırın kapandı. O gün bugündür mahalle sanki söndü. Gençler taşınıyor, kimse kimseye uğramıyor.",
					"Gel, ikimiz bu mahalleyi yeniden canlandıralım. Önce fırını açalım! Mehmet şimdi pazarda küçük bir tezgahta ekmek satıyor, git bir konuş onunla.",
				],
				"btn": "Hemen gidiyorum", "do": {}},
			{"who": "stall_firin", "goal": "Pazarda Fırıncı Mehmet'le konuş",
				"lines": [
					"Fatma Teyze mi gönderdi seni? Fırını açmak mı... Ah evladım, kolay mı?",
					"Taş ocak aylardır soğuk, odunum yok. Kapı da kırıldı, tamir parası lazım. Rahmetli Zehra'm gideli beri içim de gitmiyor zaten.",
				],
				"btn": "", "do": {"choice": [
					["Biz yardım ederiz usta", "soz_yardim", "Sahi mi? Hay Allah razı olsun. Peki, bir deneyelim bakalım."],
					["Mahalle sizi özledi usta", "soz_ozlem", "Özlediler mi? Ben de onları özledim be evladım. Peki, bir deneyelim."],
				]}},
			{"who": "ahmet", "goal": "Ahmet Amca'dan odun iste (kahvehane)",
				"lines": [
					"Fırın mı açılıyor? Oh be! Kahvenin arkasında kışlık odunum var, al götür Mehmet'e.",
					"Söyle ona, tavlada bana bir yenilgi borcu var hâlâ!",
				],
				"btn": "Odunları al", "do": {"deliver": ["stall_firin"], "carry": "odun"}},
			{"who": "stall_firin", "goal": "Odunları Mehmet Usta'ya götür",
				"lines": [
					"Odun geldi! Ahmet'in odunu mu bu? Kuru kuru, mis gibi yanar.",
					"Bir kapı kaldı. Usta 20 kurabiyeye tamir ederim diyor. Biriktirebilir misin? Fatma Teyze'nin işlerini yaptıkça kurabiye kazanırsın.",
				],
				"btn": "Biriktiririm", "do": {}},
			{"who": "stall_firin", "goal": "Kapı tamiri için kurabiye biriktir",
				"lines": ["Kapının tamiri 20 kurabiye tutuyor evladım."],
				"btn": "", "do": {"pay": 20}},
			{"who": "hulya", "goal": "Hülya Teyze'den eski tarifi öğren",
				"lines": [
					"Zehra'nın simit tarifi mi? Bende yazılı! Beraber hamur yoğururduk onunla.",
					"Ama önce elin hamura alışsın. Gel şöyle bir mantı açalım, hamuru tutturan simidi de tutturur!",
				],
				"btn": "Hamuru açalım", "do": {"game": "manti"}},
			{"who": "hulya", "goal": "Hülya Teyze'yle konuş",
				"lines": ["Maşallah, elin hamura yatkın! Al bakalım, Zehra'nın tarifi. Mehmet görünce çok sevinecek."],
				"btn": "Tarifi götür", "do": {"deliver": ["stall_firin"], "carry": "defter"}},
			{"who": "stall_firin", "goal": "Tarifi Mehmet Usta'ya götür",
				"lines": [
					"Bu... Zehra'nın el yazısı. Kırk yıl önce bu kağıda yazmıştı.",
					"Tamam evladım, kararımı verdim. Yarın sabah fırını açıyoruz! Mahalleye haber verir misin? Filiz bütün mahalleyi tanır, davetiyeleri ona yazdırdım.",
				],
				"btn": "Haber veririm", "do": {}},
			{"who": "filiz", "goal": "Filiz Teyze'den davetiyeleri al",
				"lines": ["Davetiyeler hazır, güzelce yazdım. Herkese bir tane götür, kimse küsmesin!"],
				"btn": "Dağıtayım", "do": {"invite": "davetiye"}},
			{"who": "firin", "goal": "Fırının açılışına git",
				"lines": [
					"Geldin mi evladım! Bak, kapı tamir, ocak yandı, ilk simitler fırında.",
					"Fatma Teyze, Ahmet, Hülya, Filiz... Herkes geldi. Mahalle yine bir arada.",
				],
				"btn": "Açılışı yap", "do": {"finale": true}},
		],
		"finale": [
			["firin", "Bismillah! Fırın açıldı! İlk simit senin evladım. Her sabah gel, sana sıcak simit ayırırım. Bir komşuna götürürsün, gönlü olur."],
			["fatma", "Gördün mü evladım? Bir fırın açıldı, mahallenin yüzü güldü. Bundan sonra daha neler yaparız sen bilirsin!"],
		],
	},
]

## Bölüm bitince komşuların ağzına giren yeni sözler: mahalle değişimi fark eder.
const AFTER := {
	"firin": {
		"fatma": ["Sabahları yine simit kokusu geliyor evladım. Pencereyi açıp kokluyorum, gençleşiyorum sanki."],
		"ahmet": ["Mehmet'le her akşam fırının önünde tavla atıyoruz. Yenildikçe simit ısmarlıyor, ben de hep yeniyorum!",
			"Fırın açıldı, kahvenin de müşterisi arttı. Simidin yanına çay, mahallenin keyfi yerinde."],
		"miyase": ["Mehmet'e bir atkı ördüm, fırının önünde sabahları ayaz oluyor. Bayıldı, hiç çıkarmıyor!"],
		"hulya": ["Zehra'nın tarifiyle yapılan simidi yedim, gözlerim doldu. Aynı tadı, aynı kokusu..."],
		"filiz": ["Açılışta bütün mahalle oradaydı, kırk yıllık komşular yeniden konuştu. Senin sayende evladım."],
	},
}

## Sıradaki bölümün tanıtımı (henüz yapılmadı).
const NEXT_TEASER := "Sırada mahallenin kuruyan çeşmesi var. Yakında!"


static func chapter(i: int) -> Dictionary:
	return CHAPTERS[i] if i >= 0 and i < CHAPTERS.size() else {}


static func step(ch: int, st: int) -> Dictionary:
	var c := chapter(ch)
	if c.is_empty() or st >= c["steps"].size():
		return {}
	return c["steps"][st]


## Bitmiş bölümlere göre kişinin söyleyebileceği yeni sözler.
static func after_lines(who: String) -> Array:
	var out := []
	for i in CHAPTERS.size():
		var id: String = CHAPTERS[i]["id"]
		if GameState.chapter_done(id) and AFTER.get(id, {}).has(who):
			out.append_array(AFTER[id][who])
	return out
