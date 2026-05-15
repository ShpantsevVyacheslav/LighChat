import type { FeaturesContent } from '../features-content';

export const id_ID: FeaturesContent = {
  pageTitle: 'Fitur LighChat',
  pageSubtitle:
    'Tur singkat tentang apa yang membuat LighChat lebih cepat, aman, dan berguna dibanding messenger biasa. Setiap fitur punya halaman sendiri dengan contoh dan langkah-langkahnya.',
  pageHeroPrimary: 'Kenali LighChat',
  pageHeroSecondary:
    'Enkripsi ujung-ke-ujung opsional, obrolan rahasia yang hancur sendiri, pesan terjadwal, rapat video, bahkan game — semuanya dalam satu aplikasi bebas iklan. Temukan semuanya dalam beberapa menit.',
  highlightTitle: 'Paling berguna',
  highlightSubtitle: 'Lima alasan orang tetap menggunakan LighChat.',
  moreTitle: 'Jelajahi lebih lanjut',
  moreSubtitle: 'Apa saja yang bisa dilakukan aplikasi selain chat — folder, thread, lokasi langsung, dan lainnya.',
  helpfulTitle: 'Apa yang Anda dapatkan',
  howToTitle: 'Cara mengaktifkan',
  relatedTitle: 'Lihat juga',
  backToList: 'Kembali ke fitur',
  fromWelcomeBadge: 'Tur',
  showreelCta: 'Tonton tur dengan narasi',
  welcomeOverlay: {
    title: 'Temukan fitur-fitur LighChat',
    subtitle:
      'Dua menit untuk melihat apa yang membuat LighChat berbeda: enkripsi, obrolan rahasia, game, dan rapat. Anda bisa kembali ke tur ini kapan saja dari menu pengaturan.',
    primaryCta: 'Lihat sekarang',
    secondaryCta: 'Nanti',
    bullets: [
      'Enkripsi ujung-ke-ujung opsional untuk obrolan dan panggilan',
      'Obrolan rahasia yang hancur sendiri',
      'Game dan rapat video di dalam obrolan',
    ],
  },
  topics: {
    encryption: {
      title: 'Enkripsi ujung-ke-ujung',
      tagline: 'Aktifkan — dan hanya Anda serta penerima yang bisa membacanya.',
      summary:
        'Enkripsi ujung-ke-ujung (E2EE) di LighChat adalah mode opsional. Aktifkan secara global untuk setiap obrolan baru atau hanya untuk percakapan tertentu. Selama E2EE aktif, pesan dan media dienkripsi langsung di perangkat Anda dan didekripsi hanya di sisi penerima — server secara teknis tidak bisa membaca isinya.',
      ctaLabel: 'Buka perangkat',
      sections: [
        {
          title: 'Tidak ada orang lain yang membacanya',
          body: 'Kunci enkripsi hanya ada di perangkat Anda dan tidak pernah meninggalkannya dalam bentuk teks biasa. Server hanya melihat lalu lintas terenkripsi dan metadata pengiriman, bukan teks, suara, file, atau pratinjau tautan. Bahkan jika basis data diretas, percakapan Anda tetap aman.',
        },
        {
          title: 'Verifikasi lawan bicara Anda',
          body: 'Setiap perangkat memiliki sidik jari — kode pendek. Bandingkan dengan lawan bicara secara langsung atau melalui saluran terpisah: jika kodenya cocok, tidak ada pihak ketiga di antaranya. Model kepercayaan yang sama seperti Signal dan WhatsApp gunakan dalam obrolan aman mereka.',
        },
        {
          title: 'Aktifkan di mana Anda butuhkan',
          body: 'Di Pengaturan Anda bisa mengaktifkan E2EE untuk setiap obrolan baru sekaligus, atau mengaktifkannya untuk percakapan tertentu dari headernya. Begitu mode aktif, semua yang ada di obrolan itu berjalan terenkripsi — bukan hanya teks:',
          bullets: [
            'Pesan teks dan reaksi',
            'Lingkaran suara dan video',
            'Foto, video, dan file',
            'Pratinjau tautan dan stiker',
          ],
        },
        {
          title: 'Pemulihan tanpa kompromi',
          body: 'Kehilangan ponsel? Anda bisa menyimpan cadangan terenkripsi kunci Anda yang dilindungi kata sandi. Pemulihan hanya berfungsi dengan kata sandi itu — tidak ada siapa pun, termasuk kami, yang bisa mengakses kunci tanpa kata sandi tersebut.',
        },
      ],
      howTo: [
        'Di Pengaturan → Privasi aktifkan E2EE secara default untuk obrolan baru.',
        'Untuk mengaktifkannya di obrolan yang sudah ada, buka header obrolan dan pilih "Enkripsi".',
        'Di Pengaturan → Perangkat bandingkan sidik jari kunci dengan lawan bicara dan aktifkan cadangan.',
      ],
    },
    'secret-chats': {
      title: 'Obrolan rahasia',
      tagline: 'Obrolan yang menghilang dan menolak diteruskan.',
      summary:
        'Obrolan rahasia adalah mode percakapan yang lebih ketat. Pesan otomatis terhapus sesuai timer, Anda bisa memblokir sepenuhnya penerusan dan penyalinan, foto dan video hanya bisa dibuka sekali, dan obrolan itu sendiri bisa dikunci dengan kata sandi terpisah atau biometrik.',
      ctaLabel: 'Mulai obrolan rahasia',
      sections: [
        {
          title: 'Timer penghancuran otomatis',
          body: 'Pilih berapa lama pesan bertahan, dari 5 menit hingga sehari. Timer berjalan di kedua sisi — begitu pesan hilang, tidak bisa dipulihkan di perangkat mana pun.',
        },
        {
          title: 'Pembatasan ketat',
          body: 'Blokir penerusan, pengutipan, penyalinan teks, dan penyimpanan media. Kebijakan sisi server menegakkan setiap aturan, dan upaya tangkapan layar memberi notifikasi ke lawan bicara Anda.',
          bullets: [
            'Tidak bisa meneruskan atau mengutip',
            'Tidak bisa menyalin teks',
            'Tidak bisa menyimpan media',
            'Foto dan video sekali lihat',
          ],
        },
        {
          title: 'Kunci di atas enkripsi',
          body: 'Selain E2EE biasa, Anda bisa memasang kata sandi terpisah atau Face ID/Touch ID pada obrolan itu sendiri. Bahkan ponsel yang tidak terkunci di atas meja tidak akan membukanya — faktor kedua diperlukan untuk obrolan spesifik itu.',
        },
        {
          title: 'Kontrol penuh atas akses',
          body: 'Anda bisa menghapus percakapan di kedua sisi kapan saja, atau mengunci obrolan. Berguna untuk topik kerja, urusan hukum, dan segala hal di mana lebih sedikit lebih baik.',
        },
      ],
      howTo: [
        'Ketuk header obrolan dan buka Privasi.',
        'Aktifkan Obrolan rahasia dan atur timer.',
        'Opsional, aktifkan pembatasan dan kunci.',
      ],
    },
    'disappearing-messages': {
      title: 'Pesan menghilang',
      tagline: 'Berhenti menimbun percakapan lama.',
      summary:
        'Anda tidak harus menyimpan semuanya selamanya. Atur timer dan pesan diam-diam menghilang untuk semua orang setelah 1 jam, sehari, seminggu, atau sebulan. Sempurna untuk thread kerja, topik kasual, dan kebersihan percakapan dasar.',
      ctaLabel: 'Buka obrolan',
      sections: [
        {
          title: 'Preset yang masuk akal',
          body: 'Tidak perlu menghitung detik — pilih preset. Penghitung waktu dimulai dari saat pengiriman dan berfungsi sama di obrolan 1:1 maupun grup.',
          bullets: [
            '1 jam untuk hal sekali pakai',
            '24 jam untuk thread harian',
            '7 hari untuk tugas mingguan',
            '30 hari untuk buffer sebulan',
          ],
        },
        {
          title: 'Bersih di semua perangkat',
          body: 'Pesan menghilang secara sinkron — di ponsel, web, dan desktop. Tidak perlu membersihkan arsip, tidak perlu khawatir tentang salinan yang tertinggal.',
        },
        {
          title: 'Tidak ada sisa di cloud',
          body: 'Pesan yang dihapus juga hilang dari sisi server. Mereka tidak akan muncul dari cadangan — ini bukan "tersembunyi", ini benar-benar dihapus.',
        },
      ],
      howTo: [
        'Buka obrolan dan ketuk header.',
        'Pesan menghilang — pilih timer.',
        'Pesan baru akan bertahan selama waktu yang ditentukan.',
      ],
    },
    'scheduled-messages': {
      title: 'Pesan terjadwal',
      tagline: 'Tulis sekarang, kirim nanti.',
      summary:
        'Menyiapkan ucapan selamat pagi atau pengingat tim hari Senin? Antrekan pesan dan server LighChat akan mengirimnya tepat waktu. Anda bisa mematikan perangkat, menutup aplikasi, atau bahkan kehabisan baterai — pesan Anda tetap terkirim.',
      ctaLabel: 'Buka obrolan',
      sections: [
        {
          title: 'Selalu tepat waktu',
          body: 'Pengiriman terjadi di server, bukan di ponsel Anda. Tidak seperti timer lokal di messenger lain, pengiriman tidak akan gagal karena perangkat sedang di pesawat, di terowongan, atau sekadar offline.',
        },
        {
          title: 'Kontrol penuh atas antrian',
          body: 'Panel terpisah menampilkan setiap pesan terjadwal. Edit waktu atau teks, kirim lebih awal atau batalkan — selama belum terkirim, pesan sepenuhnya di bawah kendali Anda.',
        },
        {
          title: 'Cocok untuk tim dan kehidupan',
          body: 'Ulang tahun, pengingat, standup pagi, dan semua pesan "jangan lupa kirim". Zona waktu ditangani secara otomatis.',
        },
      ],
      howTo: [
        'Ketik pesan Anda seperti biasa.',
        'Tekan lama tombol kirim → Jadwalkan.',
        'Pilih tanggal dan waktu. Selesai.',
      ],
    },
    games: {
      title: 'Game di dalam obrolan',
      tagline: 'Ajak teman bermain kartu di dalam obrolan.',
      summary:
        'Tidak perlu aplikasi terpisah, tidak perlu daftar akun. Mulai permainan Durak langsung di dalam obrolan — real-time, kartu yang indah, gerakan instan. Alasan sederhana untuk berkumpul di malam hari.',
      ctaLabel: 'Buka obrolan',
      sections: [
        {
          title: 'Real-time dan atmosfer',
          body: 'Pemain melihat gerakan satu sama lain secara instan. Pertandingan berjalan selama Anda tetap di obrolan dan berhenti jika seseorang pergi. Berdiskusi dan berkomentar langsung di percakapan yang sama, tanpa berpindah jendela.',
        },
        {
          title: 'Aturan familiar dengan petunjuk',
          body: 'Klasik "Durak dengan lempar" — aturan yang Anda kenal sejak kecil. Petunjuk membantu pemula; pemain berpengalaman langsung mengenali permainan mereka.',
        },
        {
          title: 'Terintegrasi dalam obrolan',
          body: 'Meja permainan terbuka di dalam pesan, dan hasilnya tersimpan di riwayat obrolan. Ini bagian dari percakapan antar teman, bukan aplikasi hyper-casual terpisah.',
        },
      ],
      howTo: [
        'Buka obrolan atau grup mana pun.',
        'Ketuk "+" di input dan pilih Game.',
        'Undang lawan dan mulai bagi kartu.',
      ],
    },
    meetings: {
      title: 'Rapat video',
      tagline: 'Hingga puluhan orang dalam satu layar.',
      summary:
        'Rapat video lengkap dengan grid peserta, obrolan bersama, polling, dan permintaan bergabung. Tamu bisa bergabung lewat tautan tanpa akun — halaman langsung terbuka di browser mereka. Cocok untuk panggilan kerja maupun kumpul keluarga.',
      ctaLabel: 'Buka rapat',
      sections: [
        {
          title: 'Grid yang nyaman dan pembicara aktif',
          body: 'Pembicara aktif disorot secara otomatis. Sematkan peserta yang Anda butuhkan, bisukan seseorang dengan satu ketukan, atau keluar sebentar tanpa kehilangan tempat.',
        },
        {
          title: 'Polling dan permintaan bergabung',
          body: 'Jalankan polling selama panggilan: pilihan tunggal, pilihan ganda, atau anonim. Ruangan tertutup menerima tamu melalui permintaan — moderator menyetujui satu per satu secara manual.',
        },
        {
          title: 'Tanpa aplikasi, tanpa akun',
          body: 'Untuk tamu, rapat langsung terbuka di browser melalui tautan. Tidak perlu menginstal klien, tidak perlu mendaftar, tidak perlu menunggu pembaruan.',
        },
      ],
      howTo: [
        'Buka tab Rapat.',
        'Buat ruangan atau bergabung melalui tautan.',
        'Bagikan tautan kepada peserta.',
      ],
    },
    calls: {
      title: 'Panggilan dan lingkaran video',
      tagline: 'Dari panggilan suara ke kartu pos video dalam sekejap.',
      summary:
        'Panggilan WebRTC 1:1 berkualitas tinggi dan lingkaran video pendek langsung di feed obrolan — untuk balasan cepat saat mengetik terlalu lambat dan pesan suara tidak cukup. Wajah, emosi, suara — semuanya dalam hitungan detik. Di obrolan dengan E2EE aktif, panggilan dan lingkaran juga terenkripsi.',
      ctaLabel: 'Riwayat panggilan',
      sections: [
        {
          title: 'Stabil saat bergerak',
          body: 'Panggilan beralih antara Wi-Fi dan seluler dengan mulus, menjaga audio di terowongan mana pun, dan menyesuaikan resolusi video dengan bandwidth. Tidak ada lagi "bisa dengar saya?" setiap tiga puluh detik.',
        },
        {
          title: 'Lingkaran video',
          body: 'Rekam lingkaran hingga 60 detik: wajah, emosi, komentar singkat. Penerima menontonnya inline — lingkaran diputar otomatis, tanpa layar penuh, tanpa ketukan tambahan.',
        },
        {
          title: 'Terenkripsi ujung-ke-ujung saat diaktifkan',
          body: 'Saat E2EE aktif di obrolan, panggilan dan lingkaran berjalan antar perangkat — server tidak mendapat audio maupun gambar, hanya stream untuk pengiriman. Aktifkan enkripsi di header obrolan dan panggilan serta lingkaran otomatis mendapat perlindungan.',
        },
      ],
      howTo: [
        'Ketuk ikon telepon atau kamera di header obrolan.',
        'Untuk lingkaran: tekan lama tombol rekam.',
        'Lepas untuk mengirim langsung.',
      ],
    },
    'folders-threads': {
      title: 'Folder dan thread',
      tagline: 'Ratusan obrolan tanpa kekacauan.',
      summary:
        'Urutkan obrolan ke dalam folder — Kerja, Keluarga, Belajar, apa pun yang cocok — dan beralih antar folder dengan satu ketukan. Di dalam percakapan grup, buka thread pada topik tertentu agar obrolan utama tetap bersih.',
      ctaLabel: 'Buka obrolan',
      sections: [
        {
          title: 'Sebanyak mungkin folder yang Anda butuhkan',
          body: 'Buat folder sendiri dan seret obrolan apa pun ke dalamnya — DM, grup, channel. Folder tersinkronisasi di ponsel, web, dan desktop, urutannya dipertahankan.',
        },
        {
          title: 'Thread di grup',
          body: 'Balas pesan di dalam thread — diskusi tetap di sana sementara obrolan utama tetap mudah dibaca. Sangat berguna di tim besar dan komunitas aktif.',
        },
        {
          title: 'Bisukan obrolan berisik',
          body: 'Folder obrolan "senyap" tidak berdering dengan notifikasi: pengaturan suara dan lencana ada di level folder, bukan per obrolan.',
        },
      ],
      howTo: [
        'Buka bilah folder dan ketuk Buat.',
        'Seret obrolan ke folder atau atur aturan.',
        'Di grup, ketuk "Balas di thread" di bawah pesan mana pun.',
      ],
    },
    'live-location': {
      title: 'Berbagi lokasi langsung',
      tagline: 'Tunjukkan di mana Anda berada tanpa repot dengan peta.',
      summary:
        'Alih-alih bertukar tangkapan layar, aktifkan lokasi langsung dan lawan bicara Anda melihat Anda bergerak secara real-time. Cocok untuk bertemu di tempat baru, perjalanan darat, dan memantau orang tersayang.',
      ctaLabel: 'Buka obrolan',
      sections: [
        {
          title: 'Berbagi berwaktu',
          body: 'Pilih berapa lama berbagi: 15 menit, satu jam, atau 8 jam. Setelah itu streaming berhenti sendiri — Anda tidak akan lupa mematikannya.',
        },
        {
          title: 'Tanpa kejutan',
          body: 'Selama Anda berbagi, banner merah yang jelas terlihat tetap ada di obrolan. Satu ketukan menghentikan streaming — persis langkah yang dibutuhkan.',
        },
        {
          title: 'Hemat baterai',
          body: 'Menggunakan API sistem yang sama seperti aplikasi Maps bawaan, sehingga berbagi di latar belakang hampir tidak menguras baterai dan tidak mengganggu notifikasi.',
        },
      ],
      howTo: [
        'Di obrolan, ketuk "+" → Lokasi.',
        'Aktifkan Langsung dan pilih durasi.',
        'Ketuk banner merah di atas untuk berhenti.',
      ],
    },
    'multi-device': {
      title: 'Banyak perangkat',
      tagline: 'Satu akun, banyak layar, tidak ada yang hilang.',
      summary:
        'Hubungkan ponsel, tablet, web, dan desktop ke satu akun. Kunci enkripsi tersinkronisasi via pairing QR dan cadangan terenkripsi dengan kata sandi — percakapan Anda tetap bersama Anda, bahkan jika Anda kehilangan semua perangkat lama.',
      ctaLabel: 'Kelola perangkat',
      sections: [
        {
          title: 'Pairing QR yang aman',
          body: 'Pasangkan perangkat baru dengan memindai kode QR dari perangkat lama. Kunci berpindah langsung antar perangkat dan tidak pernah tersimpan dalam teks biasa di server. Hanya butuh beberapa detik, tanpa kata sandi panjang untuk diketik.',
        },
        {
          title: 'Cadangan dengan kata sandi',
          body: 'Enkripsi cadangan kunci Anda dengan kata sandi Anda sendiri — dan pulihkan obrolan di perangkat baru mana pun, bahkan jika Anda kehilangan semua perangkat lama. Cadangan tidak berguna bagi siapa pun tanpa kata sandi tersebut, termasuk kami.',
        },
        {
          title: 'Pengalaman yang sama di mana-mana',
          body: 'Web, desktop, dan mobile dibangun di platform yang sama. Riwayat obrolan, folder, tema, dan pengaturan tersinkronisasi di seluruh perangkat tanpa penundaan.',
        },
      ],
      howTo: [
        'Di perangkat baru, pilih Masuk dengan QR.',
        'Di perangkat lama, buka Pengaturan → Perangkat.',
        'Tampilkan kode QR. Selesai — kunci sudah ada di perangkat baru.',
      ],
    },
    'stickers-media': {
      title: 'Stiker dan media',
      tagline: 'Emosi, polling, dan edit foto cepat.',
      summary:
        'Paket stiker yang kaya, pencarian GIF langsung di kolom input, polling satu ketukan, dan editor foto serta video bawaan. Semuanya untuk berkomunikasi lebih ekspresif dan cepat — tanpa berpindah aplikasi, tanpa kehilangan kualitas.',
      ctaLabel: 'Buka obrolan',
      sections: [
        {
          title: 'Stiker dan GIF',
          body: 'Tambahkan paket Anda sendiri dan gunakan katalog publik. Cari GIF langsung dari kolom input — favorit Anda otomatis masuk ke Terbaru.',
        },
        {
          title: 'Polling dan reaksi',
          body: 'Mulai polling dalam dua ketukan: pilihan tunggal atau ganda, anonim atau terbuka. Reaksi pesan untuk umpan balik cepat, agar obrolan tidak penuh dengan balasan satu kata.',
        },
        {
          title: 'Editor foto dan video',
          body: 'Potong, gambar, trim video, dan tambah keterangan — alat bawaan bekerja instan tanpa kehilangan kualitas. Tidak perlu aplikasi pihak ketiga untuk merapikan media sebelum mengirim.',
        },
      ],
      howTo: [
        'Ketuk emoji di kolom input — stiker dan GIF.',
        'Untuk polling: "+" → Polling.',
        'Untuk editor: ketuk foto atau video di pratinjau.',
      ],
    },
    privacy: {
      title: 'Privasi terperinci',
      tagline: 'Anda yang menentukan apa yang dilihat orang lain.',
      summary:
        'Setiap detail punya toggle sendiri: Status online, Terakhir dilihat, Tanda dibaca, siapa yang bisa menemukan Anda, dan siapa yang bisa menambahkan Anda ke grup. Atur dalam semenit — berfungsi di semua perangkat.',
      ctaLabel: 'Buka privasi',
      sections: [
        {
          title: 'Visibilitas aktivitas',
          body: 'Sembunyikan Online dan Terakhir dilihat dari mata yang salah. Tanda dibaca juga bisa dimatikan — lawan bicara tidak akan melihat centang biru, dan Anda pun tidak melihat milik mereka.',
        },
        {
          title: 'Siapa yang menemukan Anda',
          body: 'Pencarian global bisa dimatikan — maka Anda hanya bisa dihubungi oleh orang yang sudah menyimpan kontak Anda. Berguna jika Anda tidak ingin pesan acak.',
        },
        {
          title: 'Profil untuk orang lain',
          body: 'Tentukan apakah akan menampilkan email, nomor telepon, tanggal lahir, dan bio di kartu profil. Setiap kolom punya toggle sendiri, tidak ada mode "semua atau tidak sama sekali".',
        },
        {
          title: 'Grup sesuai aturan Anda',
          body: 'Pilih siapa yang bisa menambahkan Anda ke grup: semua orang, hanya kontak, atau tidak ada. Ini menghilangkan 99% grup pemasaran tanpa daftar blokir atau melawan undangan otomatis.',
        },
      ],
      howTo: [
        'Buka Pengaturan → Privasi.',
        'Telusuri toggle dan pilih pengaturan default Anda.',
        'Reset mengembalikan pengaturan default yang aman.',
      ],
    },
  },
  mockText: {
    e2eeBadge: 'Enkripsi ujung-ke-ujung',
    peerAlice: 'Alice',
    peerBob: 'Bob',
    peerHello: 'Hai, apa kabar?',
    fingerprintMatch: 'cocok',
    groupProject: 'Grup · Proyek',
    secretStatus: '6 anggota',
    secretSettingsTitle: 'Aturan chat rahasia',
    secretSettingTtl: 'Pengatur waktu',
    secretSettingTtlValue: 'dalam 1 jam',
    secretSettingNoForward: 'Larang penerusan',
    secretSettingLock: 'Kunci chat',
    secretMsg1: 'Mengirim file harga sebagai sekali lihat.',
    secretMsg2: 'Diterima. Blokir salin aktif.',
    teamDesign: 'Tim · Desain',
    disappearingStatus: 'online',
    disappearingMsg1: 'Berbagi draf — nanti akan menghilang.',
    disappearingMsg2: 'OK, saya review malam ini.',
    disappearingMsg3: 'Header yang lebih gelap akan lebih bagus.',
    disappearingMsg4: 'Setuju. Menerapkan dan push.',
    peerMikhail: 'Michael',
    mikhailStatus: 'terakhir dilihat hari ini pukul 21:40',
    scheduledMsg1: 'Jangan lupa pengingat standup.',
    scheduledMsg2: 'Sudah dijadwalkan untuk pagi.',
    scheduledMsg3: 'Selamat pagi! Standup dimulai 15 menit lagi.',
    scheduledQueueTitle: 'Terjadwal',
    scheduledQueueDate: 'besok, 08:45',
    gamesBadge: 'Durak · giliran Anda',
    gamesTrump: 'Truf',
    gamesDeck: 'Dek',
    gamesYou: 'Anda',
    gamesOpponent: 'Alice',
    gamesYourTurn: 'Giliran Anda',
    gamesActionBeat: 'Pukul',
    gamesActionTake: 'Ambil',
    meetingDuration: 'Rapat · 24:18',
    meetingSpeaking: 'berbicara',
    callsAudioTitle: 'Panggilan suara',
    callsAudioMeta: '3:42 · Kualitas HD',
    callsCircleTitle: 'Lingkaran video',
    callsCircleMeta: '0:42 / 1:00',
    folderAll: 'Semua',
    folderUnread: 'Belum dibaca',
    folderPersonal: 'Pribadi',
    folderGroups: 'Grup',
    folderWork: 'Kerja',
    folderFamily: 'Keluarga',
    folderStudy: 'Belajar',
    folderStarred: 'Berbintang',
    folderWorkChats: 'Kerja · obrolan',
    chat1Name: 'Tim · Desain',
    chat1Last: 'Julia: mengunggah varian baru',
    chat2Name: 'Pemasaran',
    chat2Last: 'Konstantin: laporan sudah siap',
    chat3Name: 'Rilis CRM',
    chat3Last: 'Alina: menunggu persetujuan',
    threadTitle: 'Thread · "Harga paket" · 6 balasan',
    threadReply1: 'Menurut saya 4990 paling cocok',
    threadReply2: 'Setuju',
    liveLocationBanner: 'Membagikan lokasi Anda',
    liveLocationStop: 'Berhenti',
    multiDevicePhone: 'Ponsel',
    multiDeviceDesktop: 'Desktop',
    multiDevicePairing: 'Pairing QR',
    multiDeviceBackup: 'Cadangan kunci',
    multiDeviceBackupSub: 'dilindungi kata sandi',
    stickerSearchHint: 'cari stiker dan GIF',
    stickerTabEmoji: 'Emoji',
    stickerTabStickers: 'Stiker',
    stickerTabGif: 'GIF',
    stickerOtherUis: 'Dialog terpisah',
    pollLabel: 'Jajak Pendapat',
    pollTitle: 'Kita pergi ke mana hari Sabtu?',
    pollOption1: 'Ke gunung',
    pollOption2: 'Ke pedesaan',
    editorLabel: 'Editor',
    editorHint: 'potong · keterangan',
    privacyTitle: 'Privasi',
    privacySubtitle: 'Anda yang menentukan apa yang dilihat orang lain.',
    privacyOnline: 'Status online',
    privacyOnlineHint: 'Orang lain melihat Anda sedang online',
    privacyLastSeen: 'Terakhir dilihat',
    privacyLastSeenHint: 'Waktu tepat kunjungan terakhir Anda',
    privacyReceipts: 'Tanda dibaca',
    privacyReceiptsHint: 'Centang ganda untuk pengirim',
    privacyGlobalSearch: 'Pencarian global',
    privacyGlobalSearchHint: 'Siapa pun bisa menemukan Anda berdasarkan nama',
    privacyGroupAdd: 'Penambahan ke grup',
    privacyGroupAddHint: 'Hanya kontak',
    privacyInvitesTitle: 'Undangan grup',
    privacyInviteEveryone: 'Semua pengguna',
    privacyInviteContacts: 'Hanya kontak',
    privacyInviteNone: 'Tidak ada',
    privacySearchTitle: 'Menemukan Anda',
    privacyProfileTitle: 'Profil untuk orang lain',
    privacyShowEmail: 'Email',
    privacyShowPhone: 'Telepon',
    privacyMoreFields: 'dan lainnya: tanggal lahir, bio',
    aiPickerTitle: 'Pilih gaya',
    navOpenInMaps: 'Buka di peta',
    navOpenInTaxi: 'Panggil taksi',
    navAddToCalendar: 'Tambah ke kalender',
  },
};
