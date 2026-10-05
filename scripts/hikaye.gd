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
##         {"find": ikon, "back": kişi}   yere düşen şeyi ara, bulunca kişiye götür
##         {"build": yer}   bir sonraki adımın yeri kurulur (düğün meydanı)
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
	{
		"id": "dugun",
		"title": "Mahallede Düğün",
		"reward": 40,
		"steps": [
			{"who": "filiz", "goal": "Filiz Teyze'yle konuş",
				"lines": [
					"Evladım, müjdemi isterim! Torunum Elif evleniyor!",
					"Şehirde salonda yapacaklardı, ben dedim ki: Bizim mahallede, sokakta, eskisi gibi olacak! Fırın açıldı, mahalle canlandı, şimdi sıra düğünde.",
					"Ama tek başıma yetişemem. Önce Fatma'ya git, kına gecesini ondan iyi bilen yoktur.",
				],
				"btn": "Hemen gidiyorum", "do": {}},
			{"who": "fatma", "goal": "Fatma Teyze'ye düğünü haber ver",
				"lines": [
					"Düğün mü! Bu mahallede düğün olmayalı on yıl oldu evladım. Ah, ne günlerdi...",
					"Önce kına gecesi lazım. Miyase'nin annesinden kalma bir kına tepsisi var, git ondan iste.",
				],
				"btn": "Miyase Teyze'ye gideyim", "do": {}},
			{"who": "miyase", "goal": "Miyase Teyze'den kına tepsisini iste",
				"lines": [
					"Kına tepsisi mi? Tavan arasında duruyor. Ama örtüsünü güve yemiş, yenisini örmek lazım.",
					"Gel beraber örelim, dört elle çabuk biter.",
				],
				"btn": "Örelim", "do": {"game": "orgu"}},
			{"who": "miyase", "goal": "Miyase Teyze'yle konuş",
				"lines": ["Ne güzel oldu! Mumları da koydum. Al tepsiyi, örtüsüyle Filiz'e götür."],
				"btn": "Tepsiyi al", "do": {"deliver": ["filiz"], "carry": "kina"}},
			{"who": "filiz", "goal": "Kına tepsisini Filiz Teyze'ye götür",
				"lines": [
					"Ay tepsiye bak, gözlerim doldu! Ama başka bir derdim var evladım...",
					"Elif'in nişan yüzüğü kayboldu! Dün akşam {yer} dolaşmış, orada düşürmüş olmalı. Bir bak ne olur, parıltısından bulursun.",
				],
				"btn": "Ararım", "do": {"find": "yuzuk", "back": "filiz"}},
			{"who": "filiz", "goal": "Yüzüğü Filiz Teyze'ye götür",
				"lines": [
					"Buldun mu?! Elif ağlamaktan perişan olmuştu. Kurban olurum sana evladım!",
					"Şimdi en önemlisi: davul! Ahmet Amca gençken bütün düğünlerde davul çalardı. Ama bir şartı varmış, git kendisi söylesin.",
				],
				"btn": "Ahmet Amca'ya gideyim", "do": {}},
			{"who": "ahmet", "goal": "Ahmet Amca'yı davul çalmaya ikna et",
				"lines": [
					"Davul mu? Kırk yıldır elime sopa almadım evladım...",
					"Peki, bir şartım var: tavlada beni yenersen çalarım! Yenemezsen bir dahaki sefere.",
				],
				"btn": "Tavlaya oturalım", "do": {"game": "tavla"}},
			{"who": "ahmet", "goal": "Ahmet Amca'yla konuş",
				"lines": ["Yendin beni be! Söz söz, davulu tozundan silerim. Düğünde göbek atmayan bana gelsin!"],
				"btn": "Yaşasın!", "do": {}},
			{"who": "fatma", "goal": "Masa ve ışıklar için kurabiye biriktir",
				"lines": ["Masa, sandalye, ampuller lazım. Kirasının yarısını ben verdim, kalan 30 kurabiye senden."],
				"btn": "", "do": {"pay": 30}},
			{"who": "firin", "goal": "Fırından düğün pastasını al",
				"lines": [
					"Düğün pastası mı? Zehra'nın tarifiyle yaparım, mahallenin pastası olur!",
					"Al bakalım, iki katlı. Dikkat et düşürme evladım!",
				],
				"btn": "Pastayı al", "do": {"deliver": ["filiz"], "carry": "pasta"}},
			{"who": "filiz", "goal": "Pastayı Filiz Teyze'ye götür",
				"lines": ["Pasta da geldi! Her şey hazır. Hadi evladım, düğün meydanına! Pazarın yanında, ışıkları göreceksin."],
				"btn": "Düğüne!", "do": {"build": "dugun"}},
			{"who": "dugun", "goal": "Düğün meydanına git",
				"lines": [
					"Davul gümbür gümbür, Ahmet Amca döktürüyor! Elif'le damat el ele, bütün mahalle burada.",
					"Miyase'nin ördüğü örtü masada, Mehmet'in pastası ortada. Fatma Teyze mendil sallıyor...",
				],
				"btn": "Halaya katıl", "do": {"finale": true}},
		],
		"finale": [
			["filiz", "Allah mesut etsin! Bu mahalle yıllardır böyle bir gün görmedi. Senin sayende evladım, Elif seni hiç unutmayacak."],
			["fatma", "Gördün mü? Bir fırın açıldı, bir düğün oldu. Mahalle yeniden yaşıyor! Işıklar da kalsın, her akşam yansın."],
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
	"dugun": {
		"fatma": ["Düğünden kalan ışıklar her akşam yanıyor. Balkondan bakıp Elif'in halayını hatırlıyorum."],
		"ahmet": ["Davulu bir çaldım, bıraktıramıyorlar! Cumaya sünnet düğünü var, beni çağırmışlar.",
			"Kolum hâlâ ağrıyor ama değdi be evladım. Öyle halay görmedim."],
		"miyase": ["Elif'in kına örtüsünü sandığa kaldırdım. Onun kızı evlenirken de çıkarırız inşallah."],
		"hulya": ["Düğün yemeğinden bir tabak bile artmadı. Mehmet'in pastası da bitti, tadı damağımda."],
		"filiz": ["Elif balayından kartpostal gönderdi, sana da selam yazmış! Bak, buraya koydum."],
	},
}

## Sıradaki bölümün tanıtımı (henüz yapılmadı).
const NEXT_TEASER := "Sırada mahallenin bakımsız parkı var: çocuklar yine sokakta oynasın. Yakında!"


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
