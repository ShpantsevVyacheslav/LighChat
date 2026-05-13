import type { FeaturesContent } from '../features-content';

export const uz: FeaturesContent = {
  pageTitle: 'LighChat imkoniyatlari',
  pageSubtitle:
    'LighChatni oddiy messenjerdan tezroq, xavfsizroq va foydaliroq qiladigan narsalar haqida qisqacha sayohat. Har bir imkoniyatning oʻz sahifasi, namunasi va qadamlari bor.',
  pageHeroPrimary: 'LighChat bilan tanishing',
  pageHeroSecondary:
    'Ixtiyoriy uchidan-uchiga shifrlash, oʻz-oʻzini yoʻq qiladigan maxfiy chatlar, rejalashtirilgan xabarlar, video uchrashuvlar va hatto oʻyinlar — barchasi bitta reklama­siz ilovada. Bir necha daqiqada barchasini kashf eting.',
  highlightTitle: 'Eng foydali',
  highlightSubtitle: 'Odamlar LighChatda qolishining beshta sababi.',
  moreTitle: 'Yana koʻproq',
  moreSubtitle: 'Ilova chatdan tashqari nima qila oladi — papkalar, mavzular, jonli joylashuv va boshqalar.',
  helpfulTitle: 'Siz nima olasiz',
  howToTitle: 'Qanday yoqish mumkin',
  relatedTitle: 'Shuningdek qarang',
  backToList: 'Imkoniyatlarga qaytish',
  fromWelcomeBadge: 'Sayohat',
  welcomeOverlay: {
    title: 'LighChat imkoniyatlarini kashf eting',
    subtitle:
      'LighChatni boshqalardan nima ajratib turishini koʻrish uchun ikki daqiqa: shifrlash, maxfiy chatlar, oʻyinlar va uchrashuvlar. Sozlamalar menyusidan istalgan vaqtda sayohatga qaytishingiz mumkin.',
    primaryCta: 'Koʻrib chiqish',
    secondaryCta: 'Keyinroq',
    bullets: [
      'Chatlar va qoʻngʻiroqlar uchun ixtiyoriy uchidan-uchiga shifrlash',
      'Oʻz-oʻzini yoʻq qiladigan maxfiy chatlar',
      'Chat ichidagi oʻyinlar va video uchrashuvlar',
    ],
  },
  topics: {
    encryption: {
      title: 'Uchidan-uchiga shifrlash',
      tagline: 'Yoqing — va faqat siz va qabul qiluvchi oʻqiy oladi.',
      summary:
        'LighChatdagi uchidan-uchiga shifrlash (E2EE) ixtiyoriy rejim. Uni har bir yangi chat uchun global yoqing yoki faqat bitta muayyan suhbat uchun yoqing. E2EE yoqilganda, xabarlar va media qurilmangizda shifrlanadi va faqat ikkinchi tomonda shifrdan chiqariladi — serverlar texnik jihatdan ham kontentni oʻqiy olmaydi.',
      ctaLabel: 'Qurilmalarni ochish',
      sections: [
        {
          title: 'Hech kim boshqa oʻqimaydi',
          body: 'Shifrlash kalitlari faqat qurilmalaringizda saqlanadi va ulardan ochiq matn koʻrinishida hech qachon chiqmaydi. Server shifrlangan trafikni va yetkazib berish metama\'lumotlarini koʻradi, lekin matn, ovoz, fayllar yoki havola oldindan koʻrishlarini emas. Hatto ma\'lumotlar bazasi buzilgan taqdirda ham suhbatlaringiz maxfiy qoladi.',
        },
        {
          title: 'Suhbatdoshingizni tasdiqlang',
          body: 'Har bir qurilmaning barmoq izi — qisqa kod bor. Uni suhbatdoshingiz bilan shaxsan yoki alohida kanal orqali solishtiring: agar kodlar mos kelsa, oʻrtada hech kim yoʻq. Xuddi Signal va WhatsApp xavfsiz chatlarida ishlatadigan ishonch modeli.',
        },
        {
          title: 'Kerak joyda yoqing',
          body: 'Sozlamalarda barcha yangi chatlar uchun E2EEni bir vaqtda yoqishingiz yoki muayyan suhbatning sarlavhasidan uni yoqishingiz mumkin. Rejim faollashganda, oʻsha chatdagi hamma narsa shifrlangan holda uzatiladi — faqat matn emas:',
          bullets: [
            'Matnli xabarlar va reaktsiyalar',
            'Ovozli va video doiralar',
            'Rasmlar, videolar va fayllar',
            'Havola oldindan koʻrishlari va stikerlar',
          ],
        },
        {
          title: 'Murosasiz tiklash',
          body: 'Telefoningizni yoʻqotdingizmi? Kalitlaringizning shifrlangan zaxira nusxasini parol bilan saqlashingiz mumkin. Tiklash faqat shu parol bilan ishlaydi — hech kim, jumladan biz ham, parolsiz kalitlarga erisha olmaydi.',
        },
      ],
      howTo: [
        'Sozlamalar → Maxfiylik boʻlimida yangi chatlar uchun E2EEni sukut boʻyicha yoqing.',
        'Mavjud chatda yoqish uchun chat sarlavhasini oching va "Shifrlash"ni tanlang.',
        'Sozlamalar → Qurilmalar boʻlimida suhbatdoshingiz bilan kalit barmoq izlarini solishtiring va zaxirani yoqing.',
      ],
    },
    'secret-chats': {
      title: 'Maxfiy chatlar',
      tagline: 'Yoʻqoladigan va yoʻnaltirishni rad etadigan chatlar.',
      summary:
        'Maxfiy chat — suhbatning qattiqroq rejimi. Xabarlar taymer boʻyicha avtomatik oʻchiriladi, yoʻnaltirish va nusxalashni toʻliq bloklashingiz mumkin, rasm va videolar bir marta ochiladi, va chatning oʻzi alohida parol yoki biometrika bilan qulflanishi mumkin.',
      ctaLabel: 'Maxfiy chatni boshlash',
      sections: [
        {
          title: 'Oʻz-oʻzini yoʻq qilish taymeri',
          body: 'Xabarlar qancha yashashini tanlang — 5 daqiqadan bir kungacha. Taymer ikkala tomonda ham sanaydi — xabar yoʻqolgach, uni hech qanday qurilmada tiklab boʻlmaydi.',
        },
        {
          title: 'Qattiq cheklovlar',
          body: 'Yoʻnaltirish, iqtibos keltirish, matn nusxalash va mediani saqlashni bloklash. Server tomonidagi siyosat har bir qoidani bajaradi va skrinshot urinishlari suhbatdoshingizga xabar beradi.',
          bullets: [
            'Yoʻnaltirish va iqtibos keltirish yoʻq',
            'Matn nusxalash yoʻq',
            'Mediani saqlash yoʻq',
            'Bir martalik rasm va videolar',
          ],
        },
        {
          title: 'Shifrlash ustiga qulf',
          body: 'Oddiy E2EEga qoʻshimcha ravishda, chatning oʻziga alohida parol yoki Face ID/Touch ID qoʻyishingiz mumkin. Hatto stolda qoldirilgan qulfsiz telefon ham uni koʻrsatmaydi — oʻsha muayyan chat uchun ikkinchi omil talab qilinadi.',
        },
        {
          title: 'Kirishni toʻliq boshqarish',
          body: 'Suhbatni istalgan vaqtda ikkala tomonda oʻchirishingiz yoki chatni qulflashingiz mumkin. Ish mavzulari, huquqiy masalalar va kamroq boʻlishi yaxshiroq boʻlgan har qanday narsa uchun qulay.',
        },
      ],
      howTo: [
        'Chat sarlavhasiga bosing va Maxfiylikni oching.',
        'Maxfiy chatni yoqing va taymer oʻrnating.',
        'Ixtiyoriy ravishda cheklovlarni va qulfni yoqing.',
      ],
    },
    'disappearing-messages': {
      title: 'Yoʻqoladigan xabarlar',
      tagline: 'Eski suhbatlarni toʻplashni toʻxtating.',
      summary:
        'Hammasini abadiy saqlashingiz shart emas. Taymer oʻrnating va xabarlar 1 soat, bir kun, bir hafta yoki bir oydan keyin hamma uchun jimgina yoʻqoladi. Ish mavzulari, norasmiy suhbatlar va oddiy suhbat gigiyenasi uchun juda yaxshi.',
      ctaLabel: 'Chatlarni ochish',
      sections: [
        {
          title: 'Qulay oldindan sozlamalar',
          body: 'Soniyalarni sanashning hojati yoʻq — oldindan sozlamani tanlang. Soat yuborish vaqtida boshlanadi va 1:1 chatlar va guruhlarda bir xil ishlaydi.',
          bullets: [
            'Bir martalik narsalar uchun 1 soat',
            'Kunlik mavzular uchun 24 soat',
            'Haftalik vazifalar uchun 7 kun',
            'Bir oylik bufer uchun 30 kun',
          ],
        },
        {
          title: 'Barcha qurilmalarda toza',
          body: 'Xabarlar sinxron yoʻqoladi — telefon, veb va kompyuterda. Arxivni tozalash kerak emas, biror joyda nusxa qolganidan tashvishlanish yoʻq.',
        },
        {
          title: 'Bulutda qoldiq yoʻq',
          body: 'Oʻchirilgan xabarlar server tomonida ham yoʻqoladi. Ular zaxiradan chiqmaydi — bu "yashirilgan" emas, haqiqatan ham oʻchirilgan.',
        },
      ],
      howTo: [
        'Chatni oching va sarlavhaga bosing.',
        'Yoʻqoladigan xabarlar — taymer tanlang.',
        'Yangi xabarlar aynan shu muddat yashaydi.',
      ],
    },
    'scheduled-messages': {
      title: 'Rejalashtirilgan xabarlar',
      tagline: 'Hozir yozing, keyinroq yuboring.',
      summary:
        'Ertalabki salomlashish yoki dushanba jamoaviy eslatmasini tayyorlayapsizmi? Xabarni navbatga qoʻying va LighChat serveri uni toʻgʻri vaqtda yetkazadi. Qurilmani oʻchirishingiz, ilovani yopishingiz yoki hatto batareyani tamom qilishingiz mumkin — xabaringiz baribir ketadi.',
      ctaLabel: 'Chatlarni ochish',
      sections: [
        {
          title: 'Doimo oʻz vaqtida',
          body: 'Yetkazish serverda amalga oshiriladi, telefoningizda emas. Boshqa messenjerlardagi mahalliy taymerlardan farqli oʻlaroq, qurilma samolyotda, tunnelda yoki shunchaki oflayn boʻlgani uchun yuborish muvaffaqiyatsiz boʻlmaydi.',
        },
        {
          title: 'Navbatni toʻliq boshqarish',
          body: 'Alohida panel har bir rejalashtirilgan xabarni koʻrsatadi. Vaqt yoki matnni tahrirlang, oldinroq yuboring yoki bekor qiling — u ketguniga qadar xabar toʻliq nazorat ostida.',
        },
        {
          title: 'Jamoalar va hayot uchun ajoyib',
          body: 'Tugʻilgan kunlar, eslatmalar, ertalabki stendaplar va har qanday "yuborishni unutmaslik kerak" xabarlar. Vaqt zonalari avtomatik boshqariladi.',
        },
      ],
      howTo: [
        'Xabaringizni odatdagidek yozing.',
        'Yuborish tugmasini uzoq bosing → Rejalashtirish.',
        'Sana va vaqtni tanlang. Tayyor.',
      ],
    },
    games: {
      title: 'Chatdagi oʻyinlar',
      tagline: 'Doʻstlaringizni chat ichidagi karta oʻyiniga taklif qiling.',
      summary:
        'Alohida ilova yoʻq, alohida roʻyxatdan oʻtish yoʻq. Durak oʻyinini toʻgʻridan-toʻgʻri chat ichida boshlang — real vaqtda, chiroyli kartalar, tezkor yurishlar. Kechqurun yigʻilish uchun oddiy sabab.',
      ctaLabel: 'Chatlarni ochish',
      sections: [
        {
          title: 'Real vaqt va muhit',
          body: 'Oʻyinchilar bir-birining yurishlarini darhol koʻradi. Oʻyin siz chatda boʻlganingizda davom etadi va kimdir chiqib ketganda toʻxtaydi. Xuddi shu suhbatda gaplashing va muhokama qiling, oyna almashtirishsiz.',
        },
        {
          title: 'Tanish qoidalar maslahatlar bilan',
          body: 'Klassik "Podkidnoy durak" — bolalikdan bilgan qoidalaringiz. Maslahatlar yangi oʻyinchilarga yordam beradi; tajribalilar oʻyinlarini darhol taniydi.',
        },
        {
          title: 'Chatga oʻrnatilgan',
          body: 'Stol xabar ichida ochiladi va natija chat tarixida qoladi. Bu doʻstlar orasidagi suhbatning bir qismi, alohida giperkazual ilova emas.',
        },
      ],
      howTo: [
        'Istalgan chat yoki guruhni oching.',
        'Kiritish maydonida "+" bosing va Oʻyinni tanlang.',
        'Raqiblarni taklif qiling va tarqating.',
      ],
    },
    meetings: {
      title: 'Video uchrashuvlar',
      tagline: 'Bitta ekranda oʻnlab kishi.',
      summary:
        'Ishtirokchilar panjarasi, umumiy chat, soʻrovnomalar va qoʻshilish soʻrovlari bilan toʻliq video uchrashuvlar. Mehmonlar havola orqali akkaunt yaratmasdan qoʻshilishi mumkin — sahifa toʻgʻridan-toʻgʻri brauzerda ochiladi. Ish qoʻngʻiroqlari va oilaviy yigʻilishlar uchun bir xil ishlaydi.',
      ctaLabel: 'Uchrashuvlarni ochish',
      sections: [
        {
          title: 'Qulay panjara va faol soʻzlovchi',
          body: 'Faol soʻzlovchi avtomatik ajratiladi. Kerakli ishtirokchini mahkamlang, bitta bosish bilan kimnidir ovozsiz qiling yoki joyingizni yoʻqotmasdan bir oz chiqib keting.',
        },
        {
          title: 'Soʻrovnomalar va qoʻshilish soʻrovlari',
          body: 'Qoʻngʻiroq davomida soʻrovnomalar oʻtkazing: bitta javobli, koʻp tanlovli yoki anonim. Yopiq xonalar mehmonlarni soʻrov boʻyicha qabul qiladi — moderator har birini qoʻlda tasdiqlaydi.',
        },
        {
          title: 'Ilova ham, akkount ham kerak emas',
          body: 'Mehmonlar uchun uchrashuv toʻgʻridan-toʻgʻri brauzerda havola orqali ochiladi. Mijoz oʻrnatish kerak emas, roʻyxatdan oʻtish yoʻq, yangilanishlarni kutish yoʻq.',
        },
      ],
      howTo: [
        'Uchrashuvlar yorligʻini oching.',
        'Xona yarating yoki havola orqali qoʻshiling.',
        'Havolani ishtirokchilar bilan ulashing.',
      ],
    },
    calls: {
      title: 'Qoʻngʻiroqlar va video doiralar',
      tagline: 'Ovozli qoʻngʻiroqdan video otkritka­ga bir soniyada.',
      summary:
        'Yuqori sifatli 1:1 WebRTC qoʻngʻiroqlar va chat oqimidagi qisqa video doiralar — yozish sekin va ovozli xabar yetarli boʻlmaganda tezkor javoblar uchun. Yuz, hissiyot, ovoz — barchasi soniyalarda. E2EE yoqilgan chatlarda qoʻngʻiroqlar va doiralar ham shifrlangan holda uzatiladi.',
      ctaLabel: 'Qoʻngʻiroqlar tarixi',
      sections: [
        {
          title: 'Harakatda barqaror',
          body: 'Qoʻngʻiroq Wi-Fi va mobil tarmoq orasida muammosiz oʻtadi, har qanday tunnelda ovozni ushlab turadi va video sifatini tarmoqli kengligiga moslaydi. Har oʻttiz soniyada "meni eshityapsizmi?" deyish shart emas.',
        },
        {
          title: 'Video doiralar',
          body: '60 soniyagacha doira yozib oling: yuz, hissiyot, qisqa izoh. Qabul qiluvchi uni satr ichida koʻradi — doira avtomatik ijro etiladi, toʻliq ekran yoʻq, qoʻshimcha bosishlar yoʻq.',
        },
        {
          title: 'Yoqilganda uchidan-uchiga shifrlangan',
          body: 'Chatda E2EE yoqilganda, qoʻngʻiroqlar va doiralar qurilmadan qurilmaga uzatiladi — server na audio, na tasvirni oladi, faqat yetkazish uchun oqim. Chat sarlavhasida shifrlashni yoqing va qoʻngʻiroqlar hamda doiralar himoyani avtomatik oladi.',
        },
      ],
      howTo: [
        'Chat sarlavhasidagi telefon yoki kamera belgisiga bosing.',
        'Doira uchun: yozish tugmasini uzoq bosing.',
        'Darhol yuborish uchun qoʻyib yuboring.',
      ],
    },
    'folders-threads': {
      title: 'Papkalar va mavzular',
      tagline: 'Yuzlab chat tartibsizliksiz.',
      summary:
        'Chatlarni papkalarga saralang — Ish, Oila, Oʻqish, nima mos kelsa — va bitta bosish bilan ular orasida almashing. Guruh suhbatlarida muayyan mavzular boʻyicha mavzular oching, shunda asosiy chat toza qoladi.',
      ctaLabel: 'Chatlarni ochish',
      sections: [
        {
          title: 'Qancha papka kerak boʻlsa',
          body: 'Oʻz papkalaringizni yarating va istalgan chatni ularga tortib oʻtkazing — shaxsiy xabarlar, guruhlar, kanallar. Papkalar telefon, veb va kompyuter boʻylab sinxronlanadi, tartib saqlanadi.',
        },
        {
          title: 'Guruhlarda mavzular',
          body: 'Xabarga mavzu ichida javob bering — muhokama oʻsha yerda qoladi, asosiy chat oʻqilishi oson boʻlib qoladi. Katta jamoalar va faol jamoalarda ayniqsa qimmatli.',
        },
        {
          title: 'Shovqinli chatlarni jim qiling',
          body: '"Jim" chatlar papkasi bildirishnomalar bilan jiringlamaydi: ovoz va belgi sozlamalari papka darajasida yashaydi, har bir chat uchun emas.',
        },
      ],
      howTo: [
        'Papkalar panelini oching va Yaratishga bosing.',
        'Chatlarni papkaga torting yoki qoidalar oʻrnating.',
        'Guruhda istalgan xabar ostida "Mavzuda javob berish" bosing.',
      ],
    },
    'live-location': {
      title: 'Jonli joylashuvni ulashish',
      tagline: 'Xarita bilan ovora boʻlmasdan qayerdaligingizni koʻrsating.',
      summary:
        'Skrinshotlar almashish oʻrniga, jonli joylashuvni yoqing va suhbatdoshingiz sizning real vaqtda harakatlanishingizni koʻradi. Yangi joyda uchrashish, yoʻl sayohatlari va yaqinlaringizni kuzatib borish uchun ajoyib.',
      ctaLabel: 'Chatlarni ochish',
      sections: [
        {
          title: 'Vaqtga asoslangan ulashish',
          body: 'Qancha vaqt ulashishni tanlang: 15 daqiqa, bir soat yoki 8 soat. Shundan keyin oqim oʻz-oʻzidan toʻxtaydi — oʻchirishni unutmaysiz.',
        },
        {
          title: 'Kutilmagan hodisalar yoʻq',
          body: 'Ulashish davomida chatda aniq koʻrinadigan qizil banner turadi. Bitta bosish oqimni toʻxtatadi — aynan kerakli qadamlar soni.',
        },
        {
          title: 'Batareya uchun tejamli',
          body: 'Mahalliy Xaritalar ilovalari bilan bir xil tizim APIlarini ishlatadi, shuning uchun fon rejimida ulashish batareyani deyarli sarf qilmaydi va bildirishnomalar bilan aralashmaydi.',
        },
      ],
      howTo: [
        'Chatda "+" → Joylashuv bosing.',
        'Jonlini yoqing va davomiylikni tanlang.',
        'Toʻxtatish uchun yuqoridagi qizil bannerga bosing.',
      ],
    },
    'multi-device': {
      title: 'Bir nechta qurilma',
      tagline: 'Bitta akkount, koʻp ekran, hech narsa yoʻqolmaydi.',
      summary:
        'Telefon, planshet, veb va kompyuterni bitta akkauntga ulang. Shifrlash kalitlari QR juftlash va parol bilan shifrlangan zaxira orqali sinxronlanadi — suhbatlaringiz siz bilan qoladi, hatto barcha eski qurilmalarni yoʻqotsangiz ham.',
      ctaLabel: 'Qurilmalarni boshqarish',
      sections: [
        {
          title: 'Xavfsiz QR juftlash',
          body: 'Yangi qurilmani eskisidan QR kodni skanerlash orqali juftlang. Kalitlar qurilmalar orasida toʻgʻridan-toʻgʻri uzatiladi va hech qachon serverda ochiq matn koʻrinishida saqlanmaydi. Soniyalar ichida bajariladi, uzun parollarni yozish shart emas.',
        },
        {
          title: 'Parolli zaxira',
          body: 'Kalitlaringizning zaxira nusxasini oʻz parolingiz bilan shifrlang — va har qanday yangi qurilmada chatlarni tiklang, hatto barcha eskilarini yoʻqotsangiz ham. Zaxira shu parolsiz hech kimga foydasiz, jumladan bizga ham.',
        },
        {
          title: 'Hamma joyda bir xil tajriba',
          body: 'Veb, kompyuter va mobil bir xil platformada qurilgan. Chat tarixi, papkalar, mavzular va sozlamalar qurilmalar boʻylab kechikishsiz sinxronlanadi.',
        },
      ],
      howTo: [
        'Yangi qurilmada QR bilan kirish tanlang.',
        'Eski qurilmada Sozlamalar → Qurilmalarni oching.',
        'QR kodni koʻrsating. Tayyor — kalitlar yangi qurilmada.',
      ],
    },
    'stickers-media': {
      title: 'Stikerlar va media',
      tagline: 'Hissiyot, soʻrovnomalar va tezkor rasm tahrirlash.',
      summary:
        'Boy stiker paketlari, kiritish maydonida GIF qidiruvi, bitta bosishda soʻrovnomalar va ichki rasm hamda video tahrirlagichlar. Yorqinroq va tezroq muloqot qilish uchun hamma narsa — ilova almashtirishsiz, sifat yoʻqolishsiz.',
      ctaLabel: 'Chatlarni ochish',
      sections: [
        {
          title: 'Stikerlar va GIFlar',
          body: 'Oʻz paketlaringizni qoʻshing va ommaviy katalogdan foydalaning. GIFlarni toʻgʻridan-toʻgʻri kiritish maydonidan qidiring — sevimlilaringiz avtomatik Soʻnggiga tushadi.',
        },
        {
          title: 'Soʻrovnomalar va reaktsiyalar',
          body: 'Ikki bosishda soʻrovnoma boshlang: bitta tanlovli yoki koʻp tanlovli, anonim yoki ochiq. Tezkor fikr-mulohaza uchun xabar reaktsiyalari, shuning uchun chatlar bir soʻzli javoblar bilan toʻlmaydi.',
        },
        {
          title: 'Rasm va video tahrirlagichlar',
          body: 'Kesish, chizish, videoni qirqish va sarlavha — ichki vositalar sifat yoʻqolishsiz darhol ishlaydi. Yuborishdan oldin mediani tartibga solish uchun uchinchi tomon ilova kerak emas.',
        },
      ],
      howTo: [
        'Kiritish maydonidagi tabassum belgisiga bosing — stikerlar va GIFlar.',
        'Soʻrovnoma uchun: "+" → Soʻrovnoma.',
        'Tahrirlagich uchun: oldindan koʻrishda rasm yoki videoga bosing.',
      ],
    },
    privacy: {
      title: 'Nozik maxfiylik sozlamalari',
      tagline: 'Boshqalar nimani koʻrishini siz hal qilasiz.',
      summary:
        'Har bir tafsilot oʻz alohida tugmasi: Onlayn holati, Oxirgi tashrif, Oʻqildi belgilari, kim sizni topa oladi va kim sizni guruhga qoʻsha oladi. Bir daqiqada sozlang — barcha qurilmalarda ishlaydi.',
      ctaLabel: 'Maxfiylikni ochish',
      sections: [
        {
          title: 'Faollik koʻrinuvchanlik',
          body: 'Onlayn va Oxirgi tashrif maʻlumotlarini notoʻgʻri koʻzlardan yashiring. Oʻqildi belgilarini ham oʻchirish mumkin — suhbatdoshlar koʻk belgini koʻrmaydi va siz ham ularnikini koʻrmaysiz.',
        },
        {
          title: 'Sizni kim topadi',
          body: 'Global qidiruvni oʻchirish mumkin — shunda sizga faqat kontaktingizni allaqachon saqlagan odamlar yetib boradi. Tasodifiy xabarlarni xohlamasangiz foydali.',
        },
        {
          title: 'Boshqalar uchun profil',
          body: 'Profil kartasida elektron pochta, telefon, tugʻilgan sana va tarjimai holni koʻrsatish yoki koʻrsatmaslikni hal qiling. Har bir maydon oʻz alohida tugmasi, "hammasi yoki hech narsa" rejimi yoʻq.',
        },
        {
          title: 'Sizning qoidalaringiz boʻyicha guruhlar',
          body: 'Sizni guruhga kim qoʻsha olishini tanlang: hamma, faqat kontaktlar yoki hech kim. Bu bloklash roʻyxatlari yoki avtomatik takliflar bilan kurashmasdan marketing guruhlarining 99 foizini yoʻq qiladi.',
        },
      ],
      howTo: [
        'Sozlamalar → Maxfiylikni oching.',
        'Tugmalarni koʻrib chiqing va sukut qiymatlaringizni tanlang.',
        'Qayta tiklash xavfsiz sukut qiymatlarini qaytaradi.',
      ],
    },
  },
  mockText: {
    e2eeBadge: 'Uchidan-uchiga shifrlash',
    peerAlice: 'Alisa',
    peerBob: 'Bobur',
    peerHello: 'Salom, qandaysiz?',
    fingerprintMatch: 'mos',
    groupProject: 'Guruh · Loyiha',
    secretStatus: '6 ta aʼzo',
    secretSettingsTitle: 'Maxfiy chat qoidalari',
    secretSettingTtl: 'Taymer',
    secretSettingTtlValue: '1 soatdan keyin',
    secretSettingNoForward: 'Yoʻnaltirishni taqiqlash',
    secretSettingLock: 'Chat qulfi',
    secretMsg1: 'Narx faylini bir martalik koʻrish sifatida yuborayapman.',
    secretMsg2: 'Oldim. Nusxalash bloki yoqilgan.',
    teamDesign: 'Jamoa · Dizayn',
    disappearingStatus: 'onlayn',
    disappearingMsg1: 'Qoralamani ulashyapman — keyinroq yoʻqoladi.',
    disappearingMsg2: 'OK, bugun kechqurun koʻrib chiqaman.',
    disappearingMsg3: 'Sarlavhani quyuqroq qilish yaxshiroq boʻlardi.',
    disappearingMsg4: 'Roziman. Qoʻllayapman va yuklayapman.',
    peerMikhail: 'Mirzohid',
    mikhailStatus: 'oxirgi tashrif bugun 21:40 da',
    scheduledMsg1: 'Stendap eslatmasini unutmang.',
    scheduledMsg2: 'Allaqachon ertalab uchun navbatga qoʻyilgan.',
    scheduledMsg3: 'Xayrli tong! Stendap 15 daqiqada boshlanadi.',
    scheduledQueueTitle: 'Rejalashtirilgan',
    scheduledQueueDate: 'ertaga, 08:45',
    gamesBadge: 'Durak · sizning navbatingiz',
    gamesTrump: 'Koʻzir',
    gamesDeck: 'Tashlab',
    gamesYou: 'Siz',
    gamesOpponent: 'Alisa',
    gamesYourTurn: 'Sizning navbatingiz',
    gamesActionBeat: 'Urish',
    gamesActionTake: 'Olish',
    meetingDuration: 'Uchrashuv · 24:18',
    meetingSpeaking: 'gapirmoqda',
    callsAudioTitle: 'Ovozli qoʻngʻiroq',
    callsAudioMeta: '3:42 · HD sifat',
    callsCircleTitle: 'Video doira',
    callsCircleMeta: '0:42 / 1:00',
    folderAll: 'Hammasi',
    folderWork: 'Ish',
    folderFamily: 'Oila',
    folderStudy: 'Oʻqish',
    folderStarred: 'Tanlangan',
    folderWorkChats: 'Ish · chatlar',
    chat1Name: 'Jamoa · Dizayn',
    chat1Last: 'Yuliya: yangi variant yukladi',
    chat2Name: 'Marketing',
    chat2Last: 'Konstantin: hisobot tayyor',
    chat3Name: 'CRM relizlari',
    chat3Last: 'Alina: tasdiqlashni kutyapman',
    threadTitle: 'Mavzu · "Reja narxi" · 6 ta javob',
    threadReply1: 'Menimcha 4990 eng mos',
    threadReply2: 'Roziman',
    liveLocationBanner: 'Joylashuvingizni ulashyapsiz',
    liveLocationStop: 'Toʻxtatish',
    multiDevicePhone: 'Telefon',
    multiDeviceDesktop: 'Kompyuter',
    multiDevicePairing: 'QR juftlash',
    multiDeviceBackup: 'Kalit zaxirasi',
    multiDeviceBackupSub: 'parol bilan himoyalangan',
    stickerSearchHint: 'stikerlar va GIFlarni qidirish',
    pollLabel: 'Soʻrovnoma',
    pollTitle: 'Shanba kuni qayerga boramiz?',
    pollOption1: 'Togʻlarga',
    pollOption2: 'Qishloqqa',
    editorLabel: 'Tahrirlagich',
    editorHint: 'kesish · sarlavha',
    privacyTitle: 'Maxfiylik',
    privacySubtitle: 'Boshqalar nimani koʻrishini siz hal qilasiz.',
    privacyOnline: 'Onlayn holati',
    privacyOnlineHint: 'Boshqalar hozir onlayn ekanligingizni koʻradi',
    privacyLastSeen: 'Oxirgi tashrif',
    privacyLastSeenHint: 'Oxirgi tashrifingizning aniq vaqti',
    privacyReceipts: 'Oʻqildi belgilari',
    privacyReceiptsHint: 'Yuboruvchi uchun ikki marta belgilash',
    privacyGlobalSearch: 'Global qidiruv',
    privacyGlobalSearchHint: 'Har kim sizni ism boʻyicha topishi mumkin',
    privacyGroupAdd: 'Guruhlarga qoʻshish',
    privacyGroupAddHint: 'Faqat kontaktlar',
  },
};
