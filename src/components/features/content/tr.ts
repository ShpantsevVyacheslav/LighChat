import type { FeaturesContent } from '../features-content';

export const tr: FeaturesContent = {
  pageTitle: 'LighChat özellikleri',
  pageSubtitle:
    'LighChat\'ı sıradan bir mesajlaşma uygulamasından daha hızlı, güvenli ve kullanışlı yapan özelliklere kısa bir tur. Her özelliğin kendi sayfası, örneği ve adımları var.',
  pageHeroPrimary: 'LighChat ile tanışın',
  pageHeroSecondary:
    'İsteğe bağlı uçtan uca şifreleme, kendini imha eden gizli sohbetler, zamanlanmış mesajlar, görüntülü toplantılar ve hatta oyunlar — hepsi reklamsız tek bir uygulamada. Birkaç dakikada keşfedin.',
  highlightTitle: 'En kullanışlı',
  highlightSubtitle: 'İnsanların LighChat\'ı tercih etmesinin beş nedeni.',
  moreTitle: 'Keşfedilecek daha çok şey',
  moreSubtitle:
    'Uygulamanın sohbet dışında yapabilecekleri — klasörler, konu dizileri, canlı konum ve daha fazlası.',
  helpfulTitle: 'Ne elde edersiniz',
  howToTitle: 'Nasıl etkinleştirilir',
  relatedTitle: 'Ayrıca bakın',
  backToList: 'Özelliklere dön',
  fromWelcomeBadge: 'Tur',
  welcomeOverlay: {
    title: 'LighChat özelliklerini keşfedin',
    subtitle:
      'LighChat\'ı farklı kılan şeyleri görmek için iki dakika: şifreleme, gizli sohbetler, oyunlar ve toplantılar. Tura istediğiniz zaman ayarlar menüsünden geri dönebilirsiniz.',
    primaryCta: 'Bir göz atın',
    secondaryCta: 'Sonra',
    bullets: [
      'Sohbetler ve aramalar için isteğe bağlı uçtan uca şifreleme',
      'Kendini imha eden gizli sohbetler',
      'Sohbet içinde oyunlar ve görüntülü toplantılar',
    ],
  },
  topics: {
    encryption: {
      title: 'Uçtan uca şifreleme',
      tagline: 'Açın — ve yalnızca siz ve alıcı okuyabilsin.',
      summary:
        'LighChat\'ta uçtan uca şifreleme (E2EE) isteğe bağlı bir moddur. Her yeni sohbet için genel olarak veya yalnızca belirli bir konuşma için etkinleştirin. E2EE açıkken mesajlar ve medya doğrudan cihazınızda şifrelenir ve yalnızca karşı tarafta çözülür — sunucular teknik olarak bile içeriği okuyamaz.',
      ctaLabel: 'Cihazları aç',
      sections: [
        {
          title: 'Başka kimse okuyamaz',
          body: 'Şifreleme anahtarları yalnızca cihazlarınızda bulunur ve hiçbir zaman düz metin olarak dışarı çıkmaz. Sunucu şifreli trafiği ve teslimat meta verilerini görür, ancak metin, ses, dosya veya bağlantı önizlemelerini görmez. Veritabanı bir gün ele geçirilse bile konuşmalarınız gizli kalır.',
        },
        {
          title: 'Karşı tarafı doğrulayın',
          body: 'Her cihazın bir parmak izi — kısa bir kodu vardır. Bunu karşı tarafla yüz yüze veya ayrı bir kanaldan karşılaştırın: kodlar eşleşiyorsa arada kimse yok demektir. Signal ve WhatsApp\'ın güvenli sohbetlerinde kullandığı güven modelinin aynısı.',
        },
        {
          title: 'İhtiyaç duyduğunuz yerde açın',
          body: 'Ayarlar\'da E2EE\'yi her yeni sohbet için toplu olarak etkinleştirebilir veya belirli bir konuşma için başlığından açabilirsiniz. Mod etkinleştirildiğinde o sohbetteki her şey şifreli gider — yalnızca metin değil:',
          bullets: [
            'Metin mesajları ve tepkiler',
            'Sesli ve görüntülü daireler',
            'Fotoğraflar, videolar ve dosyalar',
            'Bağlantı önizlemeleri ve çıkartmalar',
          ],
        },
        {
          title: 'Ödünsüz kurtarma',
          body: 'Telefonunuzu mu kaybettiniz? Anahtarlarınızın şifreli bir yedeğini parola ile saklayabilirsiniz. Kurtarma yalnızca o parola ile çalışır — biz dahil kimse parola olmadan anahtarlara ulaşamaz.',
        },
      ],
      howTo: [
        'Ayarlar → Gizlilik bölümünde yeni sohbetler için varsayılan olarak E2EE\'yi etkinleştirin.',
        'Mevcut bir sohbette açmak için sohbet başlığını açın ve "Şifreleme"yi seçin.',
        'Ayarlar → Cihazlar bölümünde karşı tarafla anahtar parmak izlerini karşılaştırın ve yedeği etkinleştirin.',
      ],
    },
    'secret-chats': {
      title: 'Gizli sohbetler',
      tagline: 'Kaybolan ve iletilmeyi reddeden sohbetler.',
      summary:
        'Gizli sohbet, daha katı bir konuşma modudur. Mesajlar zamanlayıcıyla otomatik silinir, iletme ve kopyalamayı tamamen engelleyebilirsiniz, fotoğraf ve videolar bir kez görüntülenir, sohbetin kendisi ayrı bir parola veya biyometrik ile kilitlenebilir.',
      ctaLabel: 'Gizli sohbet başlat',
      sections: [
        {
          title: 'Kendini imha eden zamanlayıcı',
          body: 'Mesajların ne kadar yaşayacağını seçin, 5 dakikadan bir güne kadar. Zamanlayıcı her iki tarafta da geri sayar — mesaj silindikten sonra hiçbir cihazda kurtarılamaz.',
        },
        {
          title: 'Katı kısıtlamalar',
          body: 'İletme, alıntılama, metin kopyalama ve medya kaydetmeyi engelleyin. Sunucu tarafı politikası her kuralı zorunlu kılar ve ekran görüntüsü denemeleri karşı tarafa bildirilir.',
          bullets: [
            'İletme veya alıntılama yok',
            'Metin kopyalama yok',
            'Medya kaydetme yok',
            'Bir kez görüntülenen fotoğraf ve videolar',
          ],
        },
        {
          title: 'Şifrelemenin üstüne kilit',
          body: 'Normal E2EE\'nin üstüne sohbetin kendisine ayrı bir parola veya Face ID/Touch ID koyabilirsiniz. Masada bırakılmış kilitsiz bir telefon bile sohbeti ortaya çıkarmaz — o belirli sohbet için ikinci faktör gereklidir.',
        },
        {
          title: 'Erişimin tam kontrolü',
          body: 'Konuşmayı istediğiniz an her iki taraftan silebilir veya sohbeti kilitleyebilirsiniz. İş konuları, hukuki meseleler ve azın çok olduğu her durum için idealdir.',
        },
      ],
      howTo: [
        'Sohbet başlığına dokunun ve Gizlilik\'i açın.',
        'Gizli sohbeti açın ve zamanlayıcı ayarlayın.',
        'İsteğe bağlı olarak kısıtlamaları ve kilidi etkinleştirin.',
      ],
    },
    'disappearing-messages': {
      title: 'Kaybolan mesajlar',
      tagline: 'Eski konuşmaları biriktirmeyi bırakın.',
      summary:
        'Her şeyi sonsuza kadar saklamak zorunda değilsiniz. Bir zamanlayıcı ayarlayın ve mesajlar 1 saat, bir gün, bir hafta veya bir ay sonra herkes için sessizce kaybolsun. İş konuları, gündelik sohbetler ve temel konuşma hijyeni için mükemmel.',
      ctaLabel: 'Sohbetleri aç',
      sections: [
        {
          title: 'Mantıklı ön ayarlar',
          body: 'Saniyeleri saymaya gerek yok — bir ön ayar seçin. Süre gönderim zamanında başlar ve 1:1 sohbetlerde ve gruplarda aynı şekilde çalışır.',
          bullets: [
            'Tek seferlik konular için 1 saat',
            'Günlük konular için 24 saat',
            'Haftalık görevler için 7 gün',
            'Bir aylık tampon için 30 gün',
          ],
        },
        {
          title: 'Tüm cihazlarda temiz',
          body: 'Mesajlar eşzamanlı olarak kaybolur — telefon, web ve masaüstünde. Arşiv temizliği yok, bir yerde kalan kopya endişesi yok.',
        },
        {
          title: 'Bulutta kalıntı yok',
          body: 'Silinen mesajlar sunucu tarafında da gider. Yedekten ortaya çıkmazlar — bu "gizlenmiş" değil, gerçekten silinmiştir.',
        },
      ],
      howTo: [
        'Bir sohbet açın ve başlığa dokunun.',
        'Kaybolan mesajlar — bir zamanlayıcı seçin.',
        'Yeni mesajlar tam o kadar süre yaşar.',
      ],
    },
    'scheduled-messages': {
      title: 'Zamanlanmış mesajlar',
      tagline: 'Şimdi yazın, sonra gönderin.',
      summary:
        'Sabah selamı veya Pazartesi ekip hatırlatması mı hazırlıyorsunuz? Mesajı kuyruğa alın, LighChat sunucusu doğru anda iletecektir. Cihazı kapatabilir, uygulamayı kapatabilir veya pili bitirebilirsiniz — mesajınız yine de gönderilir.',
      ctaLabel: 'Sohbetleri aç',
      sections: [
        {
          title: 'Her zaman zamanında',
          body: 'Teslimat telefonunuzda değil, sunucuda gerçekleşir. Diğer mesajlaşma uygulamalarındaki yerel zamanlayıcıların aksine, cihaz uçakta, tünelde veya çevrimdışıyken gönderim başarısız olmaz.',
        },
        {
          title: 'Kuyruğun tam kontrolü',
          body: 'Ayrı bir panel zamanlanmış her mesajı gösterir. Zamanı veya metni düzenleyin, daha erken gönderin veya iptal edin — mesaj gidene kadar tamamen sizin kontrolünüzde.',
        },
        {
          title: 'Ekipler ve hayat için harika',
          body: 'Doğum günleri, hatırlatmalar, sabah toplantıları ve "göndermeyi unutmamalıyım" mesajları. Saat dilimleri otomatik olarak yönetilir.',
        },
      ],
      howTo: [
        'Mesajınızı her zamanki gibi yazın.',
        'Gönder düğmesine uzun basın → Zamanla.',
        'Tarih ve saat seçin. Tamam.',
      ],
    },
    games: {
      title: 'Sohbette oyunlar',
      tagline: 'Arkadaşlarınızı sohbet içinde kart oyununa davet edin.',
      summary:
        'Ayrı uygulama yok, ayrı kayıt yok. Durak oyununu doğrudan sohbet içinde başlatın — gerçek zamanlı, güzel kartlar, anlık hamleler. Akşam bir araya gelmek için basit bir neden.',
      ctaLabel: 'Sohbetleri aç',
      sections: [
        {
          title: 'Gerçek zamanlı ve atmosfer',
          body: 'Oyuncular birbirlerinin hamlelerini anında görür. Maç sohbetteyken devam eder, birisi ayrıldığında duraklar. Aynı konuşmada laf atın ve tartışın, pencere değiştirmeye gerek yok.',
        },
        {
          title: 'İpuçlarıyla tanıdık kurallar',
          body: 'Klasik "Aktarmalı Durak" — çocukluktan bildiğiniz kurallar. İpuçları yeni başlayanlara yardımcı olur; deneyimliler oyunlarını hemen tanır.',
        },
        {
          title: 'Sohbete entegre',
          body: 'Masa mesajın içinde açılır ve sonuç sohbet geçmişinde kalır. Arkadaşlar arasındaki konuşmanın bir parçasıdır, ayrı bir hyper-casual uygulama değil.',
        },
      ],
      howTo: [
        'Herhangi bir sohbet veya grubu açın.',
        'Giriş alanında "+" ya dokunun ve Oyun\'u seçin.',
        'Rakipleri davet edin ve dağıtın.',
      ],
    },
    meetings: {
      title: 'Görüntülü toplantılar',
      tagline: 'Bir ekranda onlarca kişiye kadar.',
      summary:
        'Katılımcı ızgarası, paylaşılan sohbet, anketler ve katılım istekleriyle tam görüntülü toplantılar. Misafirler hesap olmadan bağlantıyla katılabilir — sayfa doğrudan tarayıcılarında açılır. İş görüşmeleri ve aile buluşmaları için eşit derecede uygundur.',
      ctaLabel: 'Toplantıları aç',
      sections: [
        {
          title: 'Kullanışlı ızgara ve aktif konuşmacı',
          body: 'Aktif konuşmacı otomatik olarak vurgulanır. İhtiyacınız olan katılımcıyı sabitleyin, birisini tek dokunuşla sessize alın veya yerinizi kaybetmeden bir süreliğine ayrılın.',
        },
        {
          title: 'Anketler ve katılım istekleri',
          body: 'Görüşme sırasında anket yapın: tekli, çoklu seçimli veya anonim. Kapalı odalar misafirleri istek üzerine kabul eder — moderatör her birini elle onaylar.',
        },
        {
          title: 'Uygulama yok, hesap yok',
          body: 'Misafirler için toplantı doğrudan tarayıcıda bağlantıyla açılır. Yüklenecek istemci yok, kayıt yok, güncelleme beklentisi yok.',
        },
      ],
      howTo: [
        'Toplantılar sekmesini açın.',
        'Oda oluşturun veya bağlantıyla katılın.',
        'Bağlantıyı katılımcılarla paylaşın.',
      ],
    },
    calls: {
      title: 'Aramalar ve görüntülü daireler',
      tagline: 'Sesli aramadan görüntülü kartpostala bir saniyede.',
      summary:
        'Yüksek kaliteli 1:1 WebRTC aramaları ve sohbet akışında kısa görüntülü daireler — yazmak yavaş kaldığında ve sesli not yetmediğinde hızlı yanıtlar için. Yüz, duygu, ses — hepsi saniyeler içinde. E2EE\'nin açık olduğu sohbetlerde aramalar ve daireler de şifreli gider.',
      ctaLabel: 'Arama geçmişi',
      sections: [
        {
          title: 'Hareket halinde kararlı',
          body: 'Arama Wi-Fi ve hücresel arasında sorunsuz geçiş yapar, herhangi bir tünelde sesi korur ve video çözünürlüğünü bant genişliğine göre ayarlar. Her otuz saniyede bir "beni duyuyor musun?" yok.',
        },
        {
          title: 'Görüntülü daireler',
          body: '60 saniyeye kadar bir daire kaydedin: yüz, duygu, kısa bir yorum. Alıcı satır içinde izler — daire otomatik oynar, tam ekran yok, ekstra dokunuş yok.',
        },
        {
          title: 'Etkinleştirildiğinde uçtan uca şifreli',
          body: 'Sohbette E2EE açıkken aramalar ve daireler cihazdan cihaza gider — sunucu ne ses ne de görüntü alır, yalnızca teslimat için akışı alır. Sohbet başlığında şifrelemeyi açın, aramalar ve daireler korumayı otomatik olarak devralır.',
        },
      ],
      howTo: [
        'Sohbet başlığındaki telefon veya kamera simgesine dokunun.',
        'Daire için: kayıt düğmesine uzun basın.',
        'Anında göndermek için bırakın.',
      ],
    },
    'folders-threads': {
      title: 'Klasörler ve konu dizileri',
      tagline: 'Kaos olmadan yüzlerce sohbet.',
      summary:
        'Sohbetleri klasörlere ayırın — İş, Aile, Eğitim, size uygun ne varsa — ve tek dokunuşla aralarında geçiş yapın. Grup konuşmalarında belirli konularda konu dizisi açın, böylece ana sohbet temiz kalsın.',
      ctaLabel: 'Sohbetleri aç',
      sections: [
        {
          title: 'İstediğiniz kadar klasör',
          body: 'Kendi klasörlerinizi oluşturun ve herhangi bir sohbeti içine sürükleyin — özel mesajlar, gruplar, kanallar. Klasörler telefon, web ve masaüstü arasında senkronize olur, sıra korunur.',
        },
        {
          title: 'Gruplarda konu dizileri',
          body: 'Bir mesaja konu dizisi içinde yanıt verin — tartışma orada kalır, ana sohbet okunabilir kalır. Büyük ekiplerde ve aktif topluluklarda özellikle değerlidir.',
        },
        {
          title: 'Gürültülü sohbetleri susturun',
          body: '"Sessiz" sohbetler klasörü bildirimlerle çalmaz: ses ve rozet ayarları sohbet başına değil, klasör düzeyinde yaşar.',
        },
      ],
      howTo: [
        'Klasör çubuğunu açın ve Oluştur\'a dokunun.',
        'Sohbetleri bir klasöre sürükleyin veya kurallar belirleyin.',
        'Bir grupta herhangi bir mesajın altında "Konu dizisinde yanıtla"ya dokunun.',
      ],
    },
    'live-location': {
      title: 'Canlı konum paylaşımı',
      tagline: 'Harita ile uğraşmadan nerede olduğunuzu gösterin.',
      summary:
        'Ekran görüntüsü takas etmek yerine canlı konumu açın ve karşı taraf sizi gerçek zamanlı hareket ederken görsün. Yeni bir noktada buluşmak, yolculuklar ve sevdiklerinizi takip etmek için harika.',
      ctaLabel: 'Sohbetleri aç',
      sections: [
        {
          title: 'Süreli paylaşım',
          body: 'Ne kadar süre paylaşacağınızı seçin: 15 dakika, bir saat veya 8 saat. Bundan sonra akış kendiliğinden durur — kapatmayı unutmazsınız.',
        },
        {
          title: 'Sürpriz yok',
          body: 'Paylaşırken sohbette açıkça görünür bir kırmızı başlık kalır. Tek dokunuş akışı durdurur — tam olarak gereken kadar adım.',
        },
        {
          title: 'Pil dostu',
          body: 'Yerel Haritalar uygulamalarıyla aynı sistem API\'lerini kullanır, bu nedenle arka plan paylaşımı pili neredeyse hiç tüketmez ve bildirimleri engellemez.',
        },
      ],
      howTo: [
        'Sohbette "+" → Konum\'a dokunun.',
        'Canlı\'yı açın ve süre seçin.',
        'Durdurmak için üstteki kırmızı başlığa dokunun.',
      ],
    },
    'multi-device': {
      title: 'Birden fazla cihaz',
      tagline: 'Bir hesap, birçok ekran, hiçbir şey kaybolmaz.',
      summary:
        'Telefon, tablet, web ve masaüstünü tek bir hesaba bağlayın. Şifreleme anahtarları QR eşleştirme ve parola korumalı şifreli yedek ile senkronize olur — tüm eski cihazlarınızı kaybetseniz bile konuşmalarınız sizinle kalır.',
      ctaLabel: 'Cihazları yönet',
      sections: [
        {
          title: 'Güvenli QR eşleştirme',
          body: 'Eski bir cihazdan QR kodu tarayarak yeni bir cihaz eşleştirin. Anahtarlar doğrudan cihazlar arasında aktarılır ve sunucuda hiçbir zaman düz metin olarak bulunmaz. Saniyeler sürer, uzun parola yazmaya gerek yok.',
        },
        {
          title: 'Parola yedeklemesi',
          body: 'Anahtarlarınızın yedeğini kendi parolanızla şifreleyin — ve tüm eski cihazları kaybetseniz bile herhangi bir yeni cihazda sohbetleri kurtarın. Yedek, o parola olmadan biz dahil herkes için işe yaramaz.',
        },
        {
          title: 'Her yerde aynı deneyim',
          body: 'Web, masaüstü ve mobil aynı platform üzerine inşa edilmiştir. Sohbet geçmişi, klasörler, temalar ve ayarlar cihazlar arasında gecikmesiz senkronize olur.',
        },
      ],
      howTo: [
        'Yeni bir cihazda QR ile giriş yap\'ı seçin.',
        'Eski bir cihazda Ayarlar → Cihazlar\'ı açın.',
        'QR kodunu gösterin. Tamam — anahtarlar yeni cihazda.',
      ],
    },
    'stickers-media': {
      title: 'Çıkartmalar ve medya',
      tagline: 'Duygu, anketler ve hızlı fotoğraf düzenlemeleri.',
      summary:
        'Zengin çıkartma paketleri, giriş alanında GIF arama, tek dokunuşla anketler ve yerleşik fotoğraf ve video düzenleyicileri. Daha parlak ve hızlı iletişim için her şey — uygulama değiştirme yok, kalite kaybı yok.',
      ctaLabel: 'Sohbetleri aç',
      sections: [
        {
          title: 'Çıkartmalar ve GIF\'ler',
          body: 'Kendi paketlerinizi ekleyin ve herkese açık kataloğu kullanın. GIF\'leri doğrudan giriş alanından arayın — favorileriniz otomatik olarak Son Kullanılanlar\'a eklenir.',
        },
        {
          title: 'Anketler ve tepkiler',
          body: 'İki dokunuşta anket başlatın: tekli veya çoklu seçimli, anonim veya açık. Hızlı geri bildirim için mesaj tepkileri, böylece sohbetler tek kelimelik yanıtlarla dolmaz.',
        },
        {
          title: 'Fotoğraf ve video düzenleyicileri',
          body: 'Kırpın, çizin, video kesin ve altyazı ekleyin — yerleşik araçlar kalite kaybı olmadan anında çalışır. Göndermeden önce medyayı düzenlemek için üçüncü parti uygulamaya gerek yok.',
        },
      ],
      howTo: [
        'Giriş alanındaki gülen yüze dokunun — çıkartmalar ve GIF\'ler.',
        'Anket için: "+" → Anket.',
        'Düzenleyici için: önizlemedeki fotoğraf veya videoya dokunun.',
      ],
    },
    privacy: {
      title: 'Ayrıntılı gizlilik',
      tagline: 'Başkalarının ne göreceğine siz karar verin.',
      summary:
        'Her ayrıntı kendi düğmesidir: Çevrimiçi durumu, Son görülme, Okundu bilgisi, sizi kimin bulabileceği ve kimin sizi gruba ekleyebileceği. Bir dakikada ayarlayın — her cihazda çalışır.',
      ctaLabel: 'Gizliliği aç',
      sections: [
        {
          title: 'Etkinlik görünürlüğü',
          body: 'Çevrimiçi ve Son görülme bilgisini istenmeyen gözlerden gizleyin. Okundu bilgisi de kapatılabilir — karşı taraf mavi tik görmez, siz de onlarınkini görmezsiniz.',
        },
        {
          title: 'Sizi kim bulabilir',
          body: 'Genel arama kapatılabilir — o zaman yalnızca kişi listenizde sizi kayıtlı olanlar ulaşabilir. Rastgele mesajlar istemiyorsanız kullanışlıdır.',
        },
        {
          title: 'Başkaları için profil',
          body: 'Profil kartında e-posta, telefon, doğum tarihi ve biyografiyi gösterip göstermemeye karar verin. Her alan kendi düğmesidir, "ya hep ya hiç" modu yok.',
        },
        {
          title: 'Kurallarınıza göre gruplar',
          body: 'Sizi kimin gruba ekleyebileceğini seçin: herkes, yalnızca kişiler veya kimse. Bu, engel listeleri veya otomatik davetlerle uğraşmadan pazarlama gruplarının %99\'unu ortadan kaldırır.',
        },
      ],
      howTo: [
        'Ayarlar → Gizlilik\'i açın.',
        'Düğmeleri gözden geçirin ve varsayılanlarınızı seçin.',
        'Sıfırla güvenli varsayılanları geri getirir.',
      ],
    },
  },
  mockText: {
    e2eeBadge: 'Uçtan uca şifreleme',
    peerAlice: 'Alice',
    peerBob: 'Bob',
    peerHello: 'Merhaba, nasılsın?',
    fingerprintMatch: 'eşleşme',
    groupProject: 'Grup · Proje',
    secretStatus: '6 üye',
    secretSettingsTitle: 'Gizli sohbet kuralları',
    secretSettingTtl: 'Zamanlayıcı',
    secretSettingTtlValue: '1 saat sonra',
    secretSettingNoForward: 'İletmeyi yasakla',
    secretSettingLock: 'Sohbet kilidi',
    secretMsg1: 'Fiyat dosyasını bir kez görüntülenir olarak gönderiyorum.',
    secretMsg2: 'Aldım. Kopyalama engeli açık.',
    teamDesign: 'Ekip · Tasarım',
    disappearingStatus: 'çevrimiçi',
    disappearingMsg1: 'Taslağı paylaşıyorum — sonra kaybolacak.',
    disappearingMsg2: 'Tamam, akşama kadar inceleyeceğim.',
    disappearingMsg3: 'Daha koyu bir başlık daha iyi görünür.',
    disappearingMsg4: 'Katılıyorum. Uygulayıp gönderiyorum.',
    peerMikhail: 'Mikhail',
    mikhailStatus: 'son görülme bugün 21:40',
    scheduledMsg1: 'Standup hatırlatmasını unutma.',
    scheduledMsg2: 'Sabah için zaten kuyruğa aldım.',
    scheduledMsg3: 'Günaydın! Standup 15 dakika sonra başlıyor.',
    scheduledQueueTitle: 'Zamanlanmış',
    scheduledQueueDate: 'yarın, 08:45',
    gamesBadge: 'Durak · sıra sende',
    gamesTrump: 'Koz',
    gamesDeck: 'Deste',
    gamesYou: 'Sen',
    gamesOpponent: 'Alice',
    gamesYourTurn: 'Senin sıran',
    gamesActionBeat: 'Yen',
    gamesActionTake: 'Al',
    meetingDuration: 'Toplantı · 24:18',
    meetingSpeaking: 'konuşuyor',
    callsAudioTitle: 'Sesli arama',
    callsAudioMeta: '3:42 · HD kalite',
    callsCircleTitle: 'Görüntülü daire',
    callsCircleMeta: '0:42 / 1:00',
    folderAll: 'Tümü',
    folderUnread: 'Okunmamış',
    folderPersonal: 'Birebir',
    folderGroups: 'Gruplar',
    folderWork: 'İş',
    folderFamily: 'Aile',
    folderStudy: 'Eğitim',
    folderStarred: 'Yıldızlı',
    folderWorkChats: 'İş · sohbetler',
    chat1Name: 'Ekip · Tasarım',
    chat1Last: 'Julia: yeni varyantı gönderdi',
    chat2Name: 'Pazarlama',
    chat2Last: 'Konstantin: rapor hazır',
    chat3Name: 'CRM sürümleri',
    chat3Last: 'Alina: onay bekliyor',
    threadTitle: 'Konu dizisi · "Plan fiyatı" · 6 yanıt',
    threadReply1: 'Bence 4990 en uygun',
    threadReply2: 'Katılıyorum',
    liveLocationBanner: 'Konumunuzu paylaşıyorsunuz',
    liveLocationStop: 'Durdur',
    multiDevicePhone: 'Telefon',
    multiDeviceDesktop: 'Masaüstü',
    multiDevicePairing: 'QR eşleştirme',
    multiDeviceBackup: 'Anahtar yedekleme',
    multiDeviceBackupSub: 'parola korumalı',
    stickerSearchHint: 'çıkartma ve GIF ara',
    stickerTabEmoji: 'Emoji',
    stickerTabStickers: 'Çıkartmalar',
    stickerTabGif: 'GIF',
    stickerOtherUis: 'Ayrı diyaloglar',
    pollLabel: 'Anket',
    pollTitle: 'Cumartesi nereye gidiyoruz?',
    pollOption1: 'Dağlara',
    pollOption2: 'Kıra',
    editorLabel: 'Düzenleyici',
    editorHint: 'kırp · altyazı',
    privacyTitle: 'Gizlilik',
    privacySubtitle: 'Başkalarının ne göreceğine siz karar verin.',
    privacyOnline: 'Çevrimiçi durumu',
    privacyOnlineHint: 'Diğerleri şu an çevrimiçi olduğunuzu görür',
    privacyLastSeen: 'Son görülme',
    privacyLastSeenHint: 'Son ziyaretinizin tam zamanı',
    privacyReceipts: 'Okundu bilgisi',
    privacyReceiptsHint: 'Gönderen için çift tik',
    privacyGlobalSearch: 'Genel arama',
    privacyGlobalSearchHint: 'Herkes sizi ada göre bulabilir',
    privacyGroupAdd: 'Gruplara ekleme',
    privacyGroupAddHint: 'Yalnızca kişiler',
    privacyInvitesTitle: 'Grup davetleri',
    privacyInviteEveryone: 'Tüm kullanıcılar',
    privacyInviteContacts: 'Yalnızca kişiler',
    privacyInviteNone: 'Hiç kimse',
    privacySearchTitle: 'Sizi bulmak',
    privacyProfileTitle: 'Diğerleri için profil',
    privacyShowEmail: 'E-posta',
    privacyShowPhone: 'Telefon',
    privacyMoreFields: 've daha: doğum tarihi, bio',
  },
};
