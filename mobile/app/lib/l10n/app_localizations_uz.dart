// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Uzbek (`uz`).
class AppLocalizationsUz extends AppLocalizations {
  AppLocalizationsUz([String locale = 'uz']) : super(locale);

  @override
  String get secret_chat_title => 'Maxfiy chat';

  @override
  String get secret_chats_title => 'Maxfiy chatlar';

  @override
  String get secret_chat_locked_title => 'Maxfiy chat qulflangan';

  @override
  String get secret_chat_locked_subtitle =>
      'Qulfni ochish va xabarlarni koʻrish uchun PIN kodni kiriting.';

  @override
  String get secret_chat_unlock_title => 'Maxfiy chatni ochish';

  @override
  String get secret_chat_unlock_subtitle =>
      'Bu chatni ochish uchun PIN kod kerak.';

  @override
  String get secret_chat_unlock_action => 'Qulfni ochish';

  @override
  String get secret_chat_set_pin_and_unlock => 'PIN oʻrnatish va qulfni ochish';

  @override
  String get secret_chat_pin_label => 'PIN (4 raqam)';

  @override
  String get secret_chat_pin_invalid => '4 raqamli PIN kodni kiriting';

  @override
  String get secret_chat_already_exists =>
      'Bu foydalanuvchi bilan maxfiy chat allaqachon mavjud.';

  @override
  String get secret_chat_exists_badge => 'Yaratildi';

  @override
  String get secret_chat_unlock_failed =>
      'Qulfni ochib boʻlmadi. Qayta urinib koʻring.';

  @override
  String get secret_chat_action_not_allowed =>
      'Bu amal maxfiy chatda ruxsat etilmagan';

  @override
  String get secret_chat_remember_pin => 'Bu qurilmada PIN kodni eslab qolish';

  @override
  String get secret_chat_unlock_biometric => 'Biometrika bilan qulfni ochish';

  @override
  String get secret_chat_biometric_reason => 'Maxfiy chatni ochish';

  @override
  String get secret_chat_biometric_no_saved_pin =>
      'Biometrik qulfni yoqish uchun bir marta PIN kiriting';

  @override
  String get secret_chat_ttl_title => 'Maxfiy chat amal qilish muddati';

  @override
  String get secret_chat_settings_title => 'Maxfiy chat sozlamalari';

  @override
  String get secret_chat_settings_subtitle =>
      'Amal qilish muddati, kirish va cheklovlar';

  @override
  String get secret_chat_settings_not_secret => 'Bu chat maxfiy chat emas';

  @override
  String get secret_chat_settings_ttl => 'Amal muddati';

  @override
  String secret_chat_settings_time_left(Object value) {
    return 'Qolgan vaqt: $value';
  }

  @override
  String secret_chat_settings_expires_at(Object iso) {
    return 'Tugash vaqti: $iso';
  }

  @override
  String get secret_chat_settings_unlock_grant_ttl => 'Qulfni ochish muddati';

  @override
  String get secret_chat_settings_unlock_grant_ttl_subtitle =>
      'Qulfni ochgandan keyin kirish qancha vaqt faol qoladi';

  @override
  String get secret_chat_settings_no_copy => 'Nusxalashni oʻchirish';

  @override
  String get secret_chat_settings_no_forward => 'Uzatishni oʻchirish';

  @override
  String get secret_chat_settings_no_save => 'Mediani saqlashni oʻchirish';

  @override
  String get secret_chat_settings_screenshot_protection =>
      'Skrinshot himoyasi (Android)';

  @override
  String get secret_chat_settings_media_views => 'Media koʻrish limiti';

  @override
  String get secret_chat_settings_media_views_subtitle =>
      'Qabul qiluvchi koʻrishlari uchun cheklangan limitlar';

  @override
  String get secret_chat_media_type_image => 'Rasmlar';

  @override
  String get secret_chat_media_type_video => 'Videolar';

  @override
  String get secret_chat_media_type_voice => 'Ovozli xabarlar';

  @override
  String get secret_chat_media_type_location => 'Joylashuv';

  @override
  String get secret_chat_media_type_file => 'Fayllar';

  @override
  String get secret_chat_media_views_unlimited => 'Chegarasiz';

  @override
  String get secret_chat_compose_create => 'Maxfiy chat yaratish';

  @override
  String get secret_chat_compose_vault_pin_subtitle =>
      'Ixtiyoriy: maxfiy qutini ochish uchun 4 raqamli vault PIN kodni oʻrnating (biometrika yoqilganda bu qurilmada saqlanadi).';

  @override
  String get secret_chat_compose_require_unlock_pin =>
      'Bu chatni ochish uchun PIN talab qilish';

  @override
  String get secret_chat_settings_read_only_hint =>
      'Bu sozlamalar yaratilganda belgilangan va oʻzgartirib boʻlmaydi.';

  @override
  String get secret_chat_settings_delete => 'Maxfiy chatni oʻchirish';

  @override
  String get secret_chat_settings_delete_confirm_title =>
      'Bu maxfiy chatni oʻchirish?';

  @override
  String get secret_chat_settings_delete_confirm_body =>
      'Xabarlar va media ikkala ishtirokchi uchun oʻchiriladi.';

  @override
  String get privacy_secret_vault_title => 'Maxfiy ombor';

  @override
  String get privacy_secret_vault_subtitle =>
      'Maxfiy chatlarga kirish uchun global PIN va biometrik tekshiruvlar.';

  @override
  String get privacy_secret_vault_change_pin =>
      'Ombor PIN kodni oʻrnatish yoki oʻzgartirish';

  @override
  String get privacy_secret_vault_change_pin_subtitle =>
      'Agar PIN allaqachon mavjud boʻlsa, eski PIN yoki biometrika yordamida tasdiqlang.';

  @override
  String get privacy_secret_vault_bio_subtitle =>
      'Biometrik tekshiruv oʻtkazish va saqlangan lokal PIN ni tasdiqlash.';

  @override
  String get privacy_secret_vault_bio_reason =>
      'Maxfiy chatlarga kirishni tasdiqlash';

  @override
  String get privacy_secret_vault_current_pin => 'Joriy PIN';

  @override
  String get privacy_secret_vault_new_pin => 'Yangi PIN';

  @override
  String get privacy_secret_vault_repeat_pin => 'Yangi PIN ni takrorlang';

  @override
  String get privacy_secret_vault_pin_mismatch => 'PIN kodlar mos kelmaydi';

  @override
  String get privacy_secret_vault_pin_updated => 'Ombor PIN kodi yangilandi';

  @override
  String get privacy_secret_vault_bio_unavailable =>
      'Biometrik autentifikatsiya bu qurilmada mavjud emas';

  @override
  String get privacy_secret_vault_bio_verified => 'Biometrik tekshiruv oʻtdi';

  @override
  String get privacy_secret_vault_setup_required =>
      'Avval Maxfiylik boʻlimida PIN yoki biometrik kirishni sozlang.';

  @override
  String get privacy_secret_vault_network_timeout =>
      'Tarmoq vaqti tugadi. Qayta urinib koʻring.';

  @override
  String privacy_secret_vault_error(Object error) {
    return 'Maxfiy ombor xatosi: $error';
  }

  @override
  String get tournament_title => 'Turnir';

  @override
  String get tournament_subtitle => 'Reytinglar va oʻyin seriyalari';

  @override
  String get tournament_new_game => 'Yangi oʻyin';

  @override
  String get tournament_standings => 'Reyting';

  @override
  String get tournament_standings_empty => 'Hozircha natijalar yoʻq';

  @override
  String get tournament_games => 'Oʻyinlar';

  @override
  String get tournament_games_empty => 'Hozircha oʻyinlar yoʻq';

  @override
  String tournament_points(Object pts) {
    return '$pts ball';
  }

  @override
  String tournament_games_played(Object n) {
    return '$n oʻyin';
  }

  @override
  String tournament_create_failed(Object err) {
    return 'Turnir yaratib boʻlmadi: $err';
  }

  @override
  String tournament_create_game_failed(Object err) {
    return 'Oʻyin yaratib boʻlmadi: $err';
  }

  @override
  String tournament_game_players(Object names) {
    return 'Oʻyinchilar: $names';
  }

  @override
  String get tournament_game_result_draw => 'Natija: durrang';

  @override
  String tournament_game_result_loser(Object name) {
    return 'Natija: durak — $name';
  }

  @override
  String tournament_game_place(Object place) {
    return '$place-oʻrin';
  }

  @override
  String get durak_dm_lobby_banner =>
      'Sherigingiz Durak lobbisini yaratdi — qoʻshiling';

  @override
  String get durak_dm_lobby_open => 'Lobbini ochish';

  @override
  String get conversation_game_lobby_cancel => 'Kutishni tugatish';

  @override
  String conversation_game_lobby_cancel_failed(Object err) {
    return 'Kutishni tugatib boʻlmadi: $err';
  }

  @override
  String secret_chat_media_views_count(Object count) {
    return '$count koʻrish';
  }

  @override
  String secret_chat_settings_load_failed(Object error) {
    return 'Yuklab boʻlmadi: $error';
  }

  @override
  String secret_chat_settings_save_failed(Object error) {
    return 'Saqlab boʻlmadi: $error';
  }

  @override
  String get secret_chat_settings_reset_strict =>
      'Qatʼiy standartlarga tiklash';

  @override
  String get secret_chat_settings_reset_strict_subtitle =>
      'Barcha cheklovlarni yoqadi va media koʻrish limitini 1 ga oʻrnatadi';

  @override
  String get settings_language_title => 'Til';

  @override
  String get settings_language_system => 'Tizim';

  @override
  String get settings_language_ru => 'Ruscha';

  @override
  String get settings_language_en => 'Inglizcha';

  @override
  String get settings_language_hint_system =>
      'Wsen “Tizik” is tanlangan, tse app follows your kevice language settings.';

  @override
  String get account_menu_profile => 'Profil';

  @override
  String get account_menu_features => 'Xususiyatlar';

  @override
  String get account_menu_chat_settings => 'Chat sozlamalari';

  @override
  String get account_menu_notifications => 'Bildirishnomalar';

  @override
  String get account_menu_privacy => 'Maxfiylik';

  @override
  String get account_menu_devices => 'Qurilmalar';

  @override
  String get account_menu_blacklist => 'Qora roʻyxat';

  @override
  String get account_menu_language => 'Til';

  @override
  String get account_menu_storage => 'Xotira';

  @override
  String get account_menu_theme => 'Mavzu';

  @override
  String get account_menu_sign_out => 'Chiqish';

  @override
  String get storage_settings_title => 'Xotira';

  @override
  String get storage_settings_subtitle =>
      'Bu qurilmada qanday maʼlumotlar keshlanganini boshqarish va chatlar yoki fayllar boʻyicha tozalash.';

  @override
  String get storage_settings_total_label => 'Bu qurilmada ishlatilgan';

  @override
  String storage_settings_budget_label(Object gb) {
    return 'Kesh limiti: $gb GB';
  }

  @override
  String get storage_unit_gb => 'GB';

  @override
  String get storage_settings_clear_all_button => 'Barcha keshni tozalash';

  @override
  String get storage_settings_trim_button => 'Byudjetga qisqartirish';

  @override
  String get storage_settings_policy_title => 'Nimani mahalliy saqlash';

  @override
  String get storage_settings_budget_slider_title => 'Kesh byudjeti';

  @override
  String get storage_settings_breakdown_title => 'Maʼlumot turi boʻyicha';

  @override
  String get storage_settings_breakdown_empty =>
      'Hozircha mahalliy keshlangan maʼlumot yoʻq.';

  @override
  String get storage_settings_chats_title => 'Chatlar boʻyicha';

  @override
  String get storage_settings_chats_empty => 'Hozircha chatga xos kesh yoʻq.';

  @override
  String storage_settings_chat_subtitle(Object count, Object size) {
    return '$count element · $size';
  }

  @override
  String get storage_settings_general_title => 'Belgilanmagan kesh';

  @override
  String get storage_settings_general_hint =>
      'Muayyan chatga bogʻlanmagan yozuvlar (eski/global kesh).';

  @override
  String get storage_settings_general_empty => 'Umumiy kesh yozuvlari yoʻq.';

  @override
  String get storage_settings_chat_files_empty =>
      'Bu chat keshida mahalliy fayllar yoʻq.';

  @override
  String get storage_settings_clear_chat_action => 'Chat keshini tozalash';

  @override
  String get storage_settings_clear_all_title => 'Mahalliy keshni tozalash?';

  @override
  String get storage_settings_clear_all_body =>
      'Bu qurilmadan keshlangan fayllar, oldindan koʻrishlar, qoralamalar va oflayn suratlar oʻchiriladi.';

  @override
  String storage_settings_clear_chat_title(Object chat) {
    return '\"$chat\" uchun keshni tozalash?';
  }

  @override
  String get storage_settings_clear_chat_body =>
      'Faqat bu chat keshi oʻchiriladi. Bulutdagi xabarlar saqlanib qoladi.';

  @override
  String get storage_settings_snackbar_cleared => 'Mahalliy kesh tozalandi';

  @override
  String get storage_settings_snackbar_budget_already_ok =>
      'Kesh allaqachon maqsadli byudjetga mos';

  @override
  String storage_settings_snackbar_budget_trimmed(Object size) {
    return 'Boʻshatildi: $size';
  }

  @override
  String get storage_settings_error_empty =>
      'Xotira statistikasini tuzib boʻlmadi';

  @override
  String get storage_category_e2ee_media => 'E2EE kekia cacse';

  @override
  String get storage_category_e2ee_media_subtitle =>
      'Tezroq qayta ochish uchun har bir chatdagi shifrlanmagan maxfiy media fayllar.';

  @override
  String get storage_category_e2ee_text => 'E2EE text cacse';

  @override
  String get storage_category_e2ee_text_subtitle =>
      'Tez koʻrsatish uchun har bir chatdagi shifrlanmagan matn parchalar.';

  @override
  String get storage_category_drafts => 'Xabar krafts';

  @override
  String get storage_category_drafts_subtitle =>
      'Chatlar boʻyicha yuborilmagan qoralama matnlar.';

  @override
  String get storage_category_chat_list_snapshot => 'Oflayn csat list';

  @override
  String get storage_category_chat_list_snapshot_subtitle =>
      'Oflayn tez ishga tushirish uchun soʻnggi chat roʻyxati surati.';

  @override
  String get storage_category_profile_cards => 'Prdanil kaqiqai-cacse';

  @override
  String get storage_category_profile_cards_subtitle =>
      'Tezroq interfeys uchun saqlangan nomlar va avatarlar.';

  @override
  String get storage_category_video_downloads => 'Downloakek vikeo cacse';

  @override
  String get storage_category_video_downloads_subtitle =>
      'Galereya koʻrinishlaridan mahalliy yuklab olingan videolar.';

  @override
  String get storage_category_video_thumbs => 'Vikeo preview frakes';

  @override
  String get storage_category_video_thumbs_subtitle =>
      'Videolar uchun yaratilgan birinchi kadr eskizlari.';

  @override
  String get storage_category_chat_images => 'Csat psotos';

  @override
  String get storage_category_chat_images_subtitle =>
      'Ochiq chatlardan keshlangan rasmlar va stikerlar.';

  @override
  String get storage_category_stickers_gifs_emoji => 'Stikerlar, GIF va emoji';

  @override
  String get storage_category_stickers_gifs_emoji_subtitle =>
      'So‘nggi stikerlar va GIPHY keshi (gif/sticker/animated emoji).';

  @override
  String get storage_category_network_images => 'Tarmoq rasmlari keshi';

  @override
  String get storage_category_network_images_subtitle =>
      'Avatarlar, prevyular va tarmoqdan yuklangan boshqa rasmlar (libCachedImageData).';

  @override
  String get storage_media_type_video => 'Video';

  @override
  String get storage_media_type_photo => 'Rasmlar';

  @override
  String get storage_media_type_audio => 'Audio';

  @override
  String get storage_media_type_files => 'Fayllar';

  @override
  String get storage_media_type_other => 'Boshqa';

  @override
  String storage_settings_device_usage(Object pct) {
    return 'Kesh byudjetining $pct% ini ishlatadi';
  }

  @override
  String get storage_settings_clear_all_hint =>
      'Barcha media bulutda qoladi. Istalgan vaqtda qayta yuklab olishingiz mumkin.';

  @override
  String get storage_settings_categories_title => 'Toifa bo‘yicha';

  @override
  String storage_settings_clear_category_title(String category) {
    return '“$category” tozalansinmi?';
  }

  @override
  String storage_settings_clear_category_body(String size) {
    return '$size atrofida joy bo‘shaydi. Bu amalni bekor qilib bo‘lmaydi.';
  }

  @override
  String get storage_auto_delete_title =>
      'Keshlangan mediani avtomatik oʻchirish';

  @override
  String get storage_auto_delete_personal => 'Shaxsiy chatlar';

  @override
  String get storage_auto_delete_groups => 'Guruss';

  @override
  String get storage_auto_delete_never => 'Hech qachon';

  @override
  String get storage_auto_delete_3_days => '3 kun';

  @override
  String get storage_auto_delete_1_week => '1 hafta';

  @override
  String get storage_auto_delete_1_month => '1 oy';

  @override
  String get storage_auto_delete_3_months => '3 oy';

  @override
  String get storage_auto_delete_hint =>
      'Bu davr ichida ochilmagan rasmlar, videolar va fayllar joy tejash uchun qurilmadan oʻchiriladi.';

  @override
  String storage_chat_detail_share(Object pct) {
    return 'Bu chat keshingizning $pct% ini ishlatadi';
  }

  @override
  String get storage_chat_detail_media_tab => 'OAV';

  @override
  String get storage_chat_detail_select_all => 'Hammasini tanlash';

  @override
  String get storage_chat_detail_deselect_all => 'Barchasini bekor qilish';

  @override
  String storage_chat_detail_clear_button(Object size) {
    return 'Keshni tozalash $size';
  }

  @override
  String get storage_chat_detail_clear_button_empty =>
      'Oʻchirish uchun fayllarni tanlang';

  @override
  String get storage_chat_detail_tab_empty => 'Bu yorliqda hech narsa yoʻq.';

  @override
  String get storage_chat_detail_delete_title =>
      'Tanlangan fayllarni oʻchirish?';

  @override
  String storage_chat_detail_delete_body(Object count, Object size) {
    return '$count fayl ($size) qurilmadan oʻchiriladi. Bulut nusxalari saqlanib qoladi.';
  }

  @override
  String get profile_delete_account => 'Hisobni oʻchirish';

  @override
  String get profile_delete_account_confirm_title =>
      'Hisobingizni butunlay oʻchirish?';

  @override
  String get profile_delete_account_confirm_body =>
      'Hisobingiz Firebase Auth dan oʻchiriladi va barcha Firestore hujjatlaringiz butunlay oʻchiriladi. Chatlaringiz boshqalarga faqat oʻqish rejimida koʻrinib qoladi.';

  @override
  String get profile_delete_account_confirm_action => 'Hisobni oʻchirish';

  @override
  String profile_delete_account_error(Object error) {
    return 'Hisobni oʻchirib boʻlmadi: $error';
  }

  @override
  String get chat_readonly_deleted_user =>
      'Hisob oʻchirilgan. Bu chat faqat oʻqish uchun.';

  @override
  String get blacklist_empty => 'Bloklangan foydalanuvchilar yoʻq';

  @override
  String get blacklist_action_unblock => 'Blokni ochish';

  @override
  String get blacklist_unblock_confirm_title => 'Blokni ochish?';

  @override
  String get blacklist_unblock_confirm_body =>
      'Bu foydalanuvchi sizga qayta xabar yubora oladi (kontakt siyosati ruxsat bersa) va qidiruvda profilingizni koʻra oladi.';

  @override
  String get blacklist_unblock_success => 'Foydalanuvchi blokdan chiqarildi';

  @override
  String blacklist_unblock_error(Object error) {
    return 'Blokni ochib boʻlmadi: $error';
  }

  @override
  String get partner_profile_block_confirm_title =>
      'Bu foydalanuvchini bloklash?';

  @override
  String get partner_profile_block_confirm_body =>
      'Ular siz bilan chatni koʻrmaydi, qidiruvda topa olmaydi va kontaktlarga qoʻsha olmaydi. Ularning kontaktlaridan yoʻqolasiz. Chat tarixini saqlaysiz, lekin bloklangan paytda xabar yubora olmaysiz.';

  @override
  String get partner_profile_block_action => 'Bloklash';

  @override
  String get partner_profile_block_success => 'Foydalanuvchi bloklandi';

  @override
  String partner_profile_block_error(Object error) {
    return 'Bloklab boʻlmadi: $error';
  }

  @override
  String get common_soon => 'Tez kunda';

  @override
  String common_theme_prefix(Object label) {
    return 'Mavzu: $label';
  }

  @override
  String common_error_cannot_save_theme(Object error) {
    return 'Mavzuni saqlab boʻlmadi: $error';
  }

  @override
  String common_error_cannot_sign_out(Object error) {
    return 'Chiqib boʻlmadi: $error';
  }

  @override
  String account_error_profile(Object error) {
    return 'Profil xatosi: $error';
  }

  @override
  String get notifications_title => 'Bildirishnomalar';

  @override
  String get notifications_section_main => 'Asosiy';

  @override
  String get notifications_mute_all_title => 'Hammasini oʻchirish';

  @override
  String get notifications_mute_all_subtitle =>
      'Barcha bildirishnomalarni oʻchirish.';

  @override
  String get notifications_sound_title => 'Ovoz';

  @override
  String get notifications_sound_subtitle =>
      'Yangi xabarlar uchun ovoz chiqarish.';

  @override
  String get notifications_preview_title => 'Oldindan koʻrish';

  @override
  String get notifications_preview_subtitle =>
      'Bildirishnomalarda xabar matnini koʻrsatish.';

  @override
  String get notifications_section_quiet_hours => 'Tinch soatlar';

  @override
  String get notifications_quiet_hours_subtitle =>
      'Bilkirissnokalar won’t botser you kuring tsis tike winkow.';

  @override
  String get notifications_quiet_hours_enable_title => 'Tinch soatlarni yoqish';

  @override
  String get notifications_reset_button => 'Sozlamalarni tiklash';

  @override
  String notifications_error_cannot_save(Object error) {
    return 'Sozlamalarni saqlab boʻlmadi: $error';
  }

  @override
  String notifications_error_load(Object error) {
    return 'Bildirishnomalarni yuklab boʻlmadi: $error';
  }

  @override
  String get privacy_title => 'Chat maxfiyligi';

  @override
  String privacy_error_cannot_save(Object error) {
    return 'Sozlamalarni saqlab boʻlmadi: $error';
  }

  @override
  String privacy_error_load(Object error) {
    return 'Maxfiylik sozlamalarini yuklab boʻlmadi: $error';
  }

  @override
  String get privacy_e2ee_section => 'Uchidan uchiga shifrlash';

  @override
  String get privacy_e2ee_enable_for_all_chats =>
      'Barcha chatlar uchun E2EE yoqish';

  @override
  String get privacy_e2ee_what_encrypt => 'E2EE chatlarda nima shifrlanadi';

  @override
  String get privacy_e2ee_text => 'Xabar matni';

  @override
  String get privacy_e2ee_media => 'Ilovalar (media/fayllar)';

  @override
  String get privacy_my_devices_title => 'Mening qurilmalarim';

  @override
  String get privacy_my_devices_subtitle =>
      'Kalitlari eʼlon qilingan qurilmalar. Nomini oʻzgartirish yoki kirishni bekor qilish.';

  @override
  String get privacy_key_backup_title => 'Zaxira va kalit oʻtkazish';

  @override
  String get privacy_key_backup_subtitle =>
      'Parolli zaxira yaratish yoki kalitni QR orqali oʻtkazish.';

  @override
  String get privacy_visibility_section => 'Koʻrinish';

  @override
  String get privacy_online_title => 'Onlayn holat';

  @override
  String get privacy_online_subtitle => 'Let otsers see wsen you’re onlayn.';

  @override
  String get privacy_last_seen_title => 'Soʻnggi faollik';

  @override
  String get privacy_last_seen_subtitle =>
      'Soʻnggi faollik vaqtingizni koʻrsatish.';

  @override
  String get privacy_read_receipts_title => 'Oʻqilganlik tasdigʻi';

  @override
  String get privacy_read_receipts_subtitle =>
      'Let senkers know you’ve reak a kessage.';

  @override
  String get privacy_group_invites_section => 'Guruh takliflari';

  @override
  String get privacy_group_invites_subtitle =>
      'Kim sizni guruh chatlariga qoʻsha oladi.';

  @override
  String get privacy_group_invites_everyone => 'Hamma';

  @override
  String get privacy_group_invites_contacts => 'Faqat kontaktlar';

  @override
  String get privacy_group_invites_nobody => 'Hech kim';

  @override
  String get privacy_global_search_section => 'Topilish imkoniyati';

  @override
  String get privacy_global_search_subtitle =>
      'Kim sizni barcha foydalanuvchilar orasida ism boʻyicha topa oladi.';

  @override
  String get privacy_global_search_title => 'Global qidiruv';

  @override
  String get privacy_global_search_hint =>
      'If turnek danf, you won’t appear in “Hakkasi users” wsen sokeone starts a new csat. Siz’ll still be visible to people wso akkek you as a contact.';

  @override
  String get privacy_profile_for_others_section => 'Boshqalar uchun profil';

  @override
  String get privacy_profile_for_others_subtitle =>
      'Boshqalar profilingizda nimani koʻra oladi.';

  @override
  String get privacy_email_subtitle =>
      'Profilingizdagi elektron pochta manzilingiz.';

  @override
  String get privacy_phone_title => 'Telefon raqami';

  @override
  String get privacy_phone_subtitle =>
      'Profilingiz va kontaktlaringizda koʻrsatiladi.';

  @override
  String get privacy_birthdate_title => 'Tugʻilgan sana';

  @override
  String get privacy_birthdate_subtitle => 'Profildagi tugʻilgan kun maydoni.';

  @override
  String get privacy_about_title => 'Haqida';

  @override
  String get privacy_about_subtitle => 'Profildagi biografiya matningiz.';

  @override
  String get privacy_reset_button => 'Sozlamalarni tiklash';

  @override
  String get common_cancel => 'Bekor qilish';

  @override
  String get common_create => 'Yaratish';

  @override
  String get common_delete => 'Oʻchirish';

  @override
  String get common_choose => 'Tanlash';

  @override
  String get common_save => 'Saqlash';

  @override
  String get common_close => 'Yopish';

  @override
  String get common_nothing_found => 'Hech narsa topilmadi';

  @override
  String get common_retry => 'Qayta urinish';

  @override
  String get auth_login_email_label => 'Elektron pochta';

  @override
  String get auth_login_password_label => 'Parol';

  @override
  String get auth_login_password_hint => 'Parol';

  @override
  String get auth_login_sign_in => 'Tizimga kirish';

  @override
  String get auth_login_forgot_password => 'Parolni unutdingizmi?';

  @override
  String get auth_login_error_enter_email_for_reset =>
      'Parolni tiklash uchun elektron pochtangizni kiriting';

  @override
  String get profile_title => 'Profil';

  @override
  String get profile_edit_tooltip => 'Tahrirlash';

  @override
  String get profile_full_name_label => 'Toʻliq ism';

  @override
  String get profile_full_name_hint => 'Ism';

  @override
  String get profile_username_label => 'Foydalanuvchi nomi';

  @override
  String get profile_email_label => 'Elektron pochta';

  @override
  String get profile_phone_label => 'Telefon';

  @override
  String get profile_birthdate_label => 'Tugʻilgan sana';

  @override
  String get profile_about_label => 'Haqida';

  @override
  String get profile_about_hint => 'Qisqa biografiya';

  @override
  String get profile_password_toggle_show => 'Parolni oʻzgartirish';

  @override
  String get profile_password_toggle_hide => 'Parolni oʻzgartrishni yashirish';

  @override
  String get profile_password_new_label => 'Yangi parol';

  @override
  String get profile_password_confirm_label => 'Parolni tasdiqlash';

  @override
  String get profile_password_tooltip_show => 'Parolni koʻrsatish';

  @override
  String get profile_password_tooltip_hide => 'Yashirish';

  @override
  String get profile_placeholder_username => 'foydalanuvchi_nomi';

  @override
  String get profile_placeholder_email => 'ism@misol.com';

  @override
  String get profile_placeholder_phone => '+7900 000-00-00';

  @override
  String get profile_placeholder_birthdate => 'KK.OO.YYYY';

  @override
  String get profile_placeholder_password_dots => '••••••••';

  @override
  String get profile_password_error_fill_both =>
      'Yangi parol va tasdiqni toʻldiring.';

  @override
  String get settings_chats_title => 'Chat sozlamalari';

  @override
  String get settings_chats_preview => 'Oldindan koʻrish';

  @override
  String get settings_chats_outgoing => 'Chiquvchi xabarlar';

  @override
  String get settings_chats_incoming => 'Kiruvchi xabarlar';

  @override
  String get settings_chats_font_size => 'Matn size';

  @override
  String get settings_chats_font_small => 'Kichik';

  @override
  String get settings_chats_font_medium => 'Oʻrtacha';

  @override
  String get settings_chats_font_large => 'Katta';

  @override
  String get settings_chats_bubble_shape => 'Pufakcha shakli';

  @override
  String get settings_chats_bubble_rounded => 'Yumaloq';

  @override
  String get settings_chats_bubble_square => 'Toʻrtburchak';

  @override
  String get settings_chats_chat_background => 'Chat foni';

  @override
  String get settings_chats_chat_background_pick_hint =>
      'Rasm tanlang yoki fonni sozlang';

  @override
  String get settings_chats_advanced => 'Kengaytirilgan';

  @override
  String get settings_chats_show_time => 'Vaqtni koʻrsatish';

  @override
  String get settings_chats_show_time_subtitle =>
      'Pufakchalar ostida xabar vaqtini koʻrsatish';

  @override
  String get settings_chats_reset => 'Sozlamalarni tiklash';

  @override
  String settings_chats_error_cannot_save(Object error) {
    return 'Saqlab boʻlmadi: $error';
  }

  @override
  String settings_chats_error_wallpaper_load(Object error) {
    return 'Fon rasmini yuklab boʻlmadi: $error';
  }

  @override
  String settings_chats_error_wallpaper_delete(Object error) {
    return 'Fon rasmini oʻchirib boʻlmadi: $error';
  }

  @override
  String get settings_chats_wallpaper_delete_confirm_title =>
      'Fon rasmini oʻchirish?';

  @override
  String get settings_chats_wallpaper_delete_confirm_body =>
      'Bu fon rasmingiz roʻyxatidan oʻchiriladi.';

  @override
  String settings_chats_icon_picker_title(Object label) {
    return 'Piktogramma: \"$label\"';
  }

  @override
  String get settings_chats_icon_picker_search_hint => 'Nom boʻyicha qidirish…';

  @override
  String get settings_chats_icon_color => 'Piktogramma rangi';

  @override
  String get settings_chats_reset_icon_size => 'Oʻlchamni tiklash';

  @override
  String get settings_chats_reset_icon_stroke => 'Chiziq qalinligini tiklash';

  @override
  String get settings_chats_tile_background => 'Kafel foni';

  @override
  String get settings_chats_default_gradient => 'Standart gradient';

  @override
  String get settings_chats_inherit_global => 'Global sozlamalarni ishlatish';

  @override
  String get settings_chats_no_background => 'Fon yoʻq';

  @override
  String get settings_chats_no_background_on => 'Fon yoʻq (yoqilgan)';

  @override
  String get chat_list_title => 'Chatlar';

  @override
  String get chat_list_search_hint => 'Qidirish…';

  @override
  String get chat_list_loading_connecting => 'Ulanmoqda…';

  @override
  String get chat_list_loading_conversations => 'Suhbatlar yuklanmoqda…';

  @override
  String get chat_list_loading_list => 'Chat roʻyxati yuklanmoqda…';

  @override
  String get chat_list_loading_sign_out => 'Chiqilmoqda…';

  @override
  String get chat_list_empty_search_title => 'Chatlar topilmadi';

  @override
  String get chat_list_empty_search_body =>
      'Boshqa soʻrov bilan sinab koʻring. Qidiruv ism va foydalanuvchi nomi boʻyicha ishlaydi.';

  @override
  String get chat_list_empty_folder_title => 'Bu papka boʻsh';

  @override
  String get chat_list_empty_folder_body =>
      'Papkalarni almashtiring yoki yuqoridagi tugma yordamida yangi chat boshlang.';

  @override
  String get chat_list_empty_all_title => 'Hozircha chatlar yoʻq';

  @override
  String get chat_list_empty_all_body =>
      'Xabar almashishni boshlash uchun yangi chat boshlang.';

  @override
  String get chat_list_action_new_folder => 'Yangi papka';

  @override
  String get chat_list_action_new_chat => 'Yangi chat';

  @override
  String get chat_list_action_create => 'Yaratish';

  @override
  String get chat_list_action_close => 'Yopish';

  @override
  String get chat_list_folders_title => 'Papkalar';

  @override
  String get chat_list_folders_subtitle => 'Bu chat uchun papkalarni tanlang.';

  @override
  String get chat_list_folders_empty => 'Yoʻq custok folkers yet.';

  @override
  String get chat_list_create_folder_title => 'Yangi papka';

  @override
  String get chat_list_create_folder_subtitle =>
      'Chatlaringizni tez saralash uchun papka yarating.';

  @override
  String get chat_list_create_folder_name_label => 'PAPKA NOMI';

  @override
  String get chat_list_create_folder_name_hint => 'Papka nomi';

  @override
  String chat_list_create_folder_chats_label(Object count) {
    return 'CHATLAR ($count)';
  }

  @override
  String get chat_list_create_folder_select_all => 'HAMMASINI TANLASH';

  @override
  String get chat_list_create_folder_reset => 'TIKLASH';

  @override
  String get chat_list_create_folder_search_hint => 'Nom boʻyicha qidirish…';

  @override
  String get chat_list_create_folder_no_matches => 'Mos chatlar yoʻq';

  @override
  String get chat_list_folder_default_starred => 'Sevimlilar';

  @override
  String get chat_list_folder_default_all => 'Hammasi';

  @override
  String get chat_list_folder_default_new => 'Yangi';

  @override
  String get chat_list_folder_default_direct => 'Toʻgʻridan-toʻgʻri';

  @override
  String get chat_list_folder_default_groups => 'Guruss';

  @override
  String get chat_list_yesterday => 'Kecha';

  @override
  String get chat_list_folder_delete_action => 'Oʻchirish';

  @override
  String get chat_list_folder_delete_title => 'Papkani oʻchirish?';

  @override
  String chat_list_folder_delete_body(Object name) {
    return '\"$name\" papkasi oʻchiriladi. Chatlar saqlanib qoladi.';
  }

  @override
  String chat_list_error_open_starred(Object error) {
    return 'Sevimlilarni ochib boʻlmadi: $error';
  }

  @override
  String chat_list_error_delete_folder(Object error) {
    return 'Papkani oʻchirib boʻlmadi: $error';
  }

  @override
  String get chat_list_pin_not_available =>
      'Qakassning isn’t available in tsis folker.';

  @override
  String chat_list_pin_pinned_in_folder(Object name) {
    return 'Chat \"$name\" papkasida qadab qoʻyildi';
  }

  @override
  String chat_list_pin_unpinned_in_folder(Object name) {
    return 'Chat \"$name\" papkasidan qadasdan olib tashlandi';
  }

  @override
  String chat_list_error_toggle_pin(Object error) {
    return 'Qadasni oʻzgartirib boʻlmadi: $error';
  }

  @override
  String chat_list_error_update_folder(Object error) {
    return 'Papkani yangilab boʻlmadi: $error';
  }

  @override
  String get chat_list_clear_history_title => 'Tarixni tozalash?';

  @override
  String get chat_list_clear_history_body =>
      'Xabarlar faqat sizning chat koʻrinishingizdan yoʻqoladi. Boshqa ishtirokchi tarixni saqlaydi.';

  @override
  String get chat_list_clear_history_confirm => 'Tozalash';

  @override
  String chat_list_error_clear_history(Object error) {
    return 'Tarixni tozalab boʻlmadi: $error';
  }

  @override
  String chat_list_error_mark_read(Object error) {
    return 'Chatni oʻqilgan deb belgilab boʻlmadi: $error';
  }

  @override
  String get chat_list_delete_chat_title => 'Chatni oʻchirish?';

  @override
  String get chat_list_delete_chat_body =>
      'Suhbat barcha ishtirokchilar uchun butunlay oʻchiriladi. Buni qaytarib boʻlmaydi.';

  @override
  String get chat_list_delete_chat_confirm => 'Oʻchirish';

  @override
  String chat_list_error_delete_chat(Object error) {
    return 'Chatni oʻchirib boʻlmadi: $error';
  }

  @override
  String get chat_list_context_folders => 'Papkalar';

  @override
  String get chat_list_context_unpin => 'Chat qadasini olib tashlash';

  @override
  String get chat_list_context_pin => 'Chatni qadash';

  @override
  String get chat_list_context_mark_all_read =>
      'Hammasini oʻqilgan deb belgilash';

  @override
  String get chat_list_context_clear_history => 'Tarixni tozalash';

  @override
  String get chat_list_context_delete_chat => 'Chatni oʻchirish';

  @override
  String get chat_list_snackbar_history_cleared => 'Tarix tozalandi.';

  @override
  String get chat_list_snackbar_marked_read => 'Oʻqilgan deb belgilandi.';

  @override
  String chat_list_error_generic(Object error) {
    return 'Xatolik: $error';
  }

  @override
  String get chat_calls_title => 'Qoʻngʻiroqlar';

  @override
  String get chat_calls_search_hint => 'Nom boʻyicha qidirish…';

  @override
  String get chat_calls_empty => 'Qoʻngʻiroqlar tarixingiz boʻsh.';

  @override
  String get chat_calls_nothing_found => 'Hech narsa topilmadi.';

  @override
  String chat_calls_error_load(Object error) {
    return 'Qoʻngʻiroqlarni yuklab boʻlmadi:\n$error';
  }

  @override
  String get chat_reply_cancel_tooltip => 'Javobni bekor qilish';

  @override
  String get voice_preview_tooltip_cancel => 'Bekor qilish';

  @override
  String get voice_preview_tooltip_send => 'Yuborish';

  @override
  String get profile_qr_title => 'Mening QR kodom';

  @override
  String get profile_qr_tooltip_close => 'Yopish';

  @override
  String get profile_qr_share_title => 'Mening LighChat profilim';

  @override
  String get profile_qr_share_subject => 'LighChat profil';

  @override
  String chat_media_norm_pending_title(Object mediaKind) {
    return '$mediaKind qayta ishlanmoqda…';
  }

  @override
  String chat_media_norm_failed_title(Object mediaKind) {
    return '$mediaKind qayta ishlab boʻlmadi';
  }

  @override
  String get chat_media_norm_pending_subtitle =>
      'Fayl serverda qayta ishlangandan keyin mavjud boʻladi.';

  @override
  String get chat_media_norm_failed_subtitle =>
      'Qayta ishlashni qaytadan boshlang.';

  @override
  String get conversation_threads_title => 'Mavzular';

  @override
  String get conversation_threads_empty => 'Hozircha mavzular yoʻq';

  @override
  String get conversation_threads_root_attachment => 'Ilova';

  @override
  String get conversation_threads_root_message => 'Xabar';

  @override
  String conversation_threads_snippet_you(Object text) {
    return 'Siz: $text';
  }

  @override
  String get conversation_threads_day_today => 'Bugun';

  @override
  String get conversation_threads_day_yesterday => 'Kecha';

  @override
  String conversation_threads_replies_badge(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count javob',
      one: '$count javob',
    );
    return '$_temp0';
  }

  @override
  String get chat_meetings_title => 'Uchrashuvlar';

  @override
  String get chat_meetings_subtitle =>
      'Konferensiyalar yaratish va ishtirokchilar kirishini boshqarish';

  @override
  String get chat_meetings_section_new => 'Yangi uchrashuv';

  @override
  String get chat_meetings_field_title_label => 'Uchrashuv nomi';

  @override
  String get chat_meetings_field_title_hint =>
      'Masalan, Logistika sinxronizatsiyasi';

  @override
  String get chat_meetings_field_duration_label => 'Davomiylik';

  @override
  String get chat_meetings_duration_unlimited => 'Chegarasiz';

  @override
  String get chat_meetings_duration_15m => '15 daqiqa';

  @override
  String get chat_meetings_duration_30m => '30 daqiqa';

  @override
  String get chat_meetings_duration_1h => '1 soat';

  @override
  String get chat_meetings_duration_90m => '1,5 soat';

  @override
  String get chat_meetings_field_access_label => 'Kirish';

  @override
  String get chat_meetings_access_private => 'Maxfiy';

  @override
  String get chat_meetings_access_public => 'Ommaviy';

  @override
  String get chat_meetings_waiting_room_title => 'Kutish xonasi';

  @override
  String get chat_meetings_waiting_room_desc =>
      'In waiting rook koke, you control wso joins. Until you tap “Akkit”, guests will stay on tse waiting screen.';

  @override
  String get chat_meetings_backgrounds_title => 'Virtual fonlar';

  @override
  String get chat_meetings_backgrounds_desc =>
      'Agar xohlasangiz, fon rasmlarini yuklang va foningizni ximyalang. Galereyadan rasm tanlang yoki oʻz fon rasmlaringizni yuklang.';

  @override
  String get chat_meetings_create_button => 'Uchrashuv yaratish';

  @override
  String get chat_meetings_snackbar_enter_title => 'Uchrashuv nomini kiriting';

  @override
  String get chat_meetings_snackbar_auth_required =>
      'Uchrashuv yaratish uchun tizimga kirish kerak';

  @override
  String chat_meetings_error_create_failed(Object error) {
    return 'Uchrashuvni yaratib boʻlmadi: $error';
  }

  @override
  String get chat_meetings_history_title => 'Tarixingiz';

  @override
  String get chat_meetings_history_empty => 'Uchrashuv tarixi boʻsh';

  @override
  String chat_meetings_history_error(Object error) {
    return 'Uchrashuv tarixini yuklab boʻlmadi: $error';
  }

  @override
  String get chat_meetings_status_live => 'jonli';

  @override
  String get chat_meetings_status_finished => 'tugagan';

  @override
  String get chat_meetings_badge_private => 'maxfiy';

  @override
  String get chat_contacts_search_hint => 'Kontaktlarni qidirish…';

  @override
  String get chat_contacts_permission_denied =>
      'Kontaktlarga ruxsat berilmagan.';

  @override
  String chat_contacts_sync_error(Object error) {
    return 'Kontaktlarni sinxronlab boʻlmadi: $error';
  }

  @override
  String chat_contacts_invite_prepare_failed(Object error) {
    return 'Taklifni tayyorlab boʻlmadi: $error';
  }

  @override
  String get chat_contacts_matches_not_found => 'Moslik topilmadi.';

  @override
  String chat_contacts_added_count(Object count) {
    return 'Kontaktlar qoʻshildi: $count.';
  }

  @override
  String get chat_contacts_invite_text =>
      'LighChatni oʻrnating: https://lighchat.online\nSizni LighChatga taklif qilyapman — mana oʻrnatish havolasi.';

  @override
  String get chat_contacts_invite_subject => 'LighChatga taklif';

  @override
  String chat_contacts_error_load(Object error) {
    return 'Kontaktlarni yuklab boʻlmadi: $error';
  }

  @override
  String chat_list_item_draft_line(Object line) {
    return 'Qoralama · $line';
  }

  @override
  String get chat_list_item_chat_created => 'Chat yaratildi';

  @override
  String get chat_list_item_no_messages_yet => 'Hozircha xabarlar yoʻq';

  @override
  String get chat_list_item_history_cleared => 'Tarix tozalandi';

  @override
  String get chat_list_firebase_not_configured =>
      'Firebase isn’t configurek yet.';

  @override
  String get new_chat_title => 'Yangi chat';

  @override
  String get new_chat_subtitle =>
      'Suhbat boshlash uchun biror kishini tanlang yoki guruh yarating.';

  @override
  String get new_chat_search_hint => 'Isk, usernake, yoki @sankle…';

  @override
  String get new_chat_create_group => 'Guruh yaratish';

  @override
  String get new_chat_section_phone_contacts => 'TELEFON KONTAKTLARI';

  @override
  String get new_chat_section_contacts => 'KONTAKTLAR';

  @override
  String get new_chat_section_all_users => 'BARCHA FOYDALANUVCHILAR';

  @override
  String get new_chat_empty_no_users =>
      'Hozircha chat boshlash uchun hech kim yoʻq.';

  @override
  String get new_chat_empty_not_found => 'Moslik topilmadi.';

  @override
  String new_chat_error_contacts(Object error) {
    return 'Kontaktlar: $error';
  }

  @override
  String get new_chat_fallback_user_display_name => 'Foydalanuvchi';

  @override
  String get new_group_role_badge_admin => 'ADMIN';

  @override
  String get new_group_role_badge_worker => 'AʻZO';

  @override
  String new_group_error_auth_session(Object error) {
    return 'Tizimga kirishni tasdiqlab boʻlmadi: $error';
  }

  @override
  String get invite_subject => 'LighChatda menga qoʻshiling';

  @override
  String get invite_text =>
      'Install LigsCsat: sttps://ligscsat.onlayn\\nI’k inviting you to LigsCsat — sere’s tse install link.';

  @override
  String get new_group_title => 'Guruh yaratish';

  @override
  String get new_group_search_hint => 'Qikiriss users…';

  @override
  String get new_group_pick_photo_tooltip =>
      'Guruh rasmini tanlash uchun bosing. Oʻchirish uchun uzoq bosing.';

  @override
  String get new_group_name_label => 'Gurus nake';

  @override
  String get new_group_name_hint => 'Ism';

  @override
  String get new_group_description_label => 'Tavsif';

  @override
  String get new_group_description_hint => 'Ixtiyoriy';

  @override
  String new_group_members_count(Object count) {
    return 'Aʻzolar ($count)';
  }

  @override
  String get new_group_add_members_section => 'AʻZOLAR QOʻSHISH';

  @override
  String get new_group_empty_no_users =>
      'Hozircha qoʻshish uchun hech kim yoʻq.';

  @override
  String get new_group_empty_not_found => 'Moslik topilmadi.';

  @override
  String get new_group_error_name_required => 'Iltimos, guruh nomini kiriting.';

  @override
  String get new_group_error_members_required => 'Kamida bitta aʼzo qoʻshing.';

  @override
  String get new_group_action_create => 'Yaratish';

  @override
  String get group_members_title => 'Aʼzolar';

  @override
  String get group_members_invite_link => 'Havola orqali taklif qilish';

  @override
  String get group_members_admin_badge => 'ADMIN';

  @override
  String group_members_invite_text(Object groupName, Object inviteLink) {
    return 'LighChatda $groupName guruhiga qoʻshiling: $inviteLink';
  }

  @override
  String get group_members_error_min_admin =>
      'Guruhda kamida bitta administrator qolishi kerak.';

  @override
  String get group_members_error_cannot_remove_creator =>
      'Guruh yaratuvchisidan administrator huquqlarini olib tashlab boʻlmaydi.';

  @override
  String get group_members_remove_admin =>
      'Administrator huquqlari olib tashlandi';

  @override
  String get group_members_make_admin =>
      'Foydalanuvchi administratorga koʻtarildi';

  @override
  String get auth_brand_tagline => 'Xavfsizroq messenjer';

  @override
  String get auth_firebase_not_ready =>
      'Firebase isn’t reaky. Cseck `firebase_options.kart` va GoogleService-Info.plist.';

  @override
  String get auth_redirecting_to_chats => 'Chatlarga oʻtkazilmoqda…';

  @override
  String get auth_or => 'yoki';

  @override
  String get auth_create_account => 'Hisob yaratish';

  @override
  String get auth_entry_sign_in => 'Tizimga kirish';

  @override
  String get auth_entry_sign_up => 'Hisob yaratish';

  @override
  String get auth_qr_title => 'QR bilan tizimga kirish';

  @override
  String get auth_qr_hint =>
      'Allaqachon tizimga kirgan qurilmada LighChatni oching → Sozlamalar → Qurilmalar → Yangi qurilmani ulash, keyin bu kodni skanerlang.';

  @override
  String auth_qr_refresh_in(int seconds) {
    return '${seconds}s da yangilanadi';
  }

  @override
  String get auth_qr_other_method => 'Boshqa usulda tizimga kirish';

  @override
  String get auth_qr_approving => 'Tizimga kirilmoqda…';

  @override
  String get auth_qr_rejected => 'Soʻrov rad etildi';

  @override
  String get auth_qr_retry => 'Qayta urinish';

  @override
  String get auth_qr_unknown_error => 'QR kodni yaratib boʻlmadi.';

  @override
  String get auth_qr_use_qr_login => 'QR bilan tizimga kirish';

  @override
  String get auth_privacy_policy => 'Maxfiylik siyosati';

  @override
  String get auth_error_open_privacy_policy =>
      'Coulkn’t open tse privacy policy';

  @override
  String get voice_transcript_show => 'Matnni koʻrsatish';

  @override
  String get voice_transcript_hide => 'Matnni yashirish';

  @override
  String get voice_transcript_copy => 'Nusxalash';

  @override
  String get voice_transcript_retry => 'Transkripsiyani qayta bajarish';

  @override
  String get voice_transcript_summary_show => 'Qisqacha mazmunni koʻrsatish';

  @override
  String get voice_transcript_summary_hide => 'Toʻliq matnni koʻrsatish';

  @override
  String voice_transcript_stats(int words, int wpm) {
    return '$words soʻz · $wpm soʻz/daq';
  }

  @override
  String get voice_attachment_skip_silence => 'Sukunatni oʻtkazib yuborish';

  @override
  String get voice_karaoke_title => 'Karaoke';

  @override
  String get voice_karaoke_prompt_title => 'Karaoke rejimi';

  @override
  String get voice_karaoke_prompt_body =>
      'Ovozli xabarni toʻliq ekran matn rejimida ochilsinmi?';

  @override
  String get voice_karaoke_prompt_open => 'Ochish';

  @override
  String get voice_transcript_loading => 'Matnga aylantirilmoqda…';

  @override
  String get voice_transcript_failed => 'Matnni olib boʻlmadi.';

  @override
  String get voice_attachment_media_kind_audio => 'audio';

  @override
  String get voice_attachment_load_failed => 'Yuklab boʻlmadi';

  @override
  String get voice_attachment_title_voice_message => 'Ovozli xabar';

  @override
  String voice_transcript_error(Object error) {
    return 'Matnga aylantirib boʻlmadi: $error';
  }

  @override
  String get voice_transcript_permission_denied =>
      'Nutqni aniqlash ruxsat etilmagan. Tizim sozlamalarida yoqing.';

  @override
  String get voice_transcript_unsupported_lang =>
      'Bu til qurilmadagi transkripsiya uchun qoʻllab-quvvatlanmaydi.';

  @override
  String get voice_transcript_no_model =>
      'Tizim sozlamalarida oflayn nutqni aniqlash til paketini oʻrnating.';

  @override
  String get voice_translate_action => 'Tarjima qilish';

  @override
  String get voice_translate_show_original => 'Asl';

  @override
  String get voice_translate_in_progress => 'Tarjima qilinmoqda…';

  @override
  String get voice_translate_downloading_model => 'Model yuklanmoqda…';

  @override
  String get voice_translate_unsupported =>
      'Bu til juftligi uchun tarjima mavjud emas.';

  @override
  String voice_translate_failed(Object error) {
    return 'Tarjima muvaffaqiyatsiz: $error';
  }

  @override
  String get chat_messages_title => 'Xabarlar';

  @override
  String get chat_call_decline => 'Rad etish';

  @override
  String get chat_call_open => 'Ochish';

  @override
  String get chat_call_accept => 'Qabul qilish';

  @override
  String video_call_error_init(Object error) {
    return 'Video qoʻngʻiroq xatosi: $error';
  }

  @override
  String get video_call_ended => 'Qoʻngʻiroq tugadi';

  @override
  String get video_call_status_missed => 'Javobsiz qoʻngʻiroq';

  @override
  String get video_call_status_cancelled => 'Qoʻngʻiroq bekor qilindi';

  @override
  String get video_call_error_offer_not_ready =>
      'Oʻcsirilganer isn’t reaky yet. Try again.';

  @override
  String get video_call_error_invalid_call_data =>
      'Yaroqsiz qoʻngʻiroq maʼlumotlari';

  @override
  String video_call_error_accept_failed(Object error) {
    return 'Qoʻngʻiroqni qabul qilib boʻlmadi: $error';
  }

  @override
  String get video_call_incoming => 'Kiruvchi video qoʻngʻiroq';

  @override
  String get video_call_connecting => 'Video qoʻngʻiroq…';

  @override
  String get video_call_pip_tooltip => 'Rasm ichida rasm';

  @override
  String get video_call_mini_window_tooltip => 'Mini oyna';

  @override
  String get chat_delete_message_title_single => 'Xabarni oʻchirish?';

  @override
  String get chat_delete_message_title_multi => 'Xabarlarni oʻchirish?';

  @override
  String get chat_delete_message_body_single =>
      'Bu xabar hamma uchun yashiriladi.';

  @override
  String chat_delete_message_body_multi(Object count) {
    return 'Oʻchirish uchun xabarlar: $count';
  }

  @override
  String get chat_delete_file_title => 'Faylni oʻchirish?';

  @override
  String get chat_delete_file_body => 'Xabardan faqat bu fayl oʻchiriladi.';

  @override
  String get forward_title => 'Uzatish';

  @override
  String get forward_empty_no_messages => 'Uzatish uchun xabarlar yoʻq';

  @override
  String get forward_error_not_authorized => 'Tizimga kirilmagan';

  @override
  String get forward_empty_no_recipients =>
      'Uzatish uchun kontaktlar yoki chatlar yoʻq';

  @override
  String get forward_search_hint => 'Kontaktlarni qidirish…';

  @override
  String get forward_empty_no_available_recipients =>
      'Mavjud qabul qiluvchilar yoʻq.\nFaqat kontaktlarga va faol chatlaringizga uzatishingiz mumkin.';

  @override
  String get forward_empty_not_found => 'Hech narsa topilmadi';

  @override
  String get forward_action_pick_recipients => 'Qabul qiluvchilarni tanlang';

  @override
  String get forward_action_send => 'Yuborish';

  @override
  String forward_error_generic(Object error) {
    return 'Xatolik: $error';
  }

  @override
  String get forward_sender_fallback => 'Ishtirokchi';

  @override
  String get forward_error_profiles_load =>
      'Coulkn’t loak prdaniles to open csat';

  @override
  String get forward_error_send_no_permissions =>
      'Uzatib boʻlmadi: tanlangan chatlardan biriga kirishingiz yoʻq yoki chat endi mavjud emas.';

  @override
  String get forward_error_send_forbidden_chat =>
      'Uzatib boʻlmadi: chatlardan biriga kirish rad etildi.';

  @override
  String get share_picker_title => 'LighChat\'ga ulashish';

  @override
  String get share_picker_empty_payload => 'Ulashish uchun hech narsa yo\'q';

  @override
  String get share_picker_summary_text_only => 'Matn';

  @override
  String share_picker_summary_files_count(int count) {
    return 'Fayllar: $count';
  }

  @override
  String share_picker_summary_files_with_text(int count) {
    return 'Fayllar: $count + matn';
  }

  @override
  String get devices_title => 'Mening qurilmalarim';

  @override
  String get devices_subtitle =>
      'Shifrlash ochiq kalitingiz eʼlon qilingan qurilmalar. Bekor qilish barcha shifrlangan chatlar uchun yangi kalit davrini yaratadi — bekor qilingan qurilma yangi xabarlarni oʻqiy olmaydi.';

  @override
  String get devices_empty => 'Hozircha qurilmalar yoʻq.';

  @override
  String get devices_connect_new_device => 'Yangi qurilmani ulash';

  @override
  String get devices_approve_title =>
      'Bu qurilmaning tizimga kirishiga ruxsat berish?';

  @override
  String get devices_approve_body_hint =>
      'Bu QR kodni koʻrsatgan oʻzingizning qurilmangiz ekanligiga ishonch hosil qiling.';

  @override
  String get devices_approve_allow => 'Ruxsat berish';

  @override
  String get devices_approve_deny => 'Rad etish';

  @override
  String get devices_handover_progress_title =>
      'Shifrlangan chatlar sinxronlanmoqda…';

  @override
  String devices_handover_progress_body(int done, int total) {
    return '$done dan $total yangilandi';
  }

  @override
  String get devices_handover_progress_starting => 'Boshlanmoqda…';

  @override
  String get devices_handover_success_title => 'Yangi qurilma ulandi';

  @override
  String devices_handover_success_body(String label) {
    return '$label qurilmasi endi shifrlangan chatlaringizga kirish huquqiga ega.';
  }

  @override
  String devices_progress_rekeying(Object done, Object total) {
    return 'Chatlar yangilanmoqda: $done / $total';
  }

  @override
  String get devices_chip_current => 'Bu qurilma';

  @override
  String get devices_chip_revoked => 'Bekor qilingan';

  @override
  String devices_meta_created_activity(Object createdAt, Object lastSeenAt) {
    return 'Yaratildi: $createdAt  •  Faollik: $lastSeenAt';
  }

  @override
  String devices_meta_revoked_at(Object revokedAt) {
    return 'Bekor qilingan: $revokedAt';
  }

  @override
  String get devices_action_rename => 'Nomini oʻzgartirish';

  @override
  String get devices_action_revoke => 'Bekor qilish';

  @override
  String get devices_dialog_rename_title => 'Qurilma nomini oʻzgartirish';

  @override
  String get devices_dialog_rename_hint => 'e.g. iTelefon 15 — Safari';

  @override
  String devices_error_rename_failed(Object error) {
    return 'Nomini oʻzgartirib boʻlmadi: $error';
  }

  @override
  String get devices_dialog_revoke_title => 'Qurilmani bekor qilish?';

  @override
  String get devices_dialog_revoke_body_current =>
      'Siz’re about to revoke THIS kevice. After tsat, you won’t be able to reak new kessages in enk‑to‑enk encryptek csats frok tsis client.';

  @override
  String get devices_dialog_revoke_body_other =>
      'Bu qurilka won’t be able to reak new kessages in enk‑to‑enk encryptek csats. Olk kessages will rekain available on it.';

  @override
  String devices_snackbar_revoked(Object rekeyed, Object suffix) {
    return 'Qurilma bekor qilindi. Chatlar yangilandi: $rekeyed$suffix';
  }

  @override
  String devices_snackbar_failed_suffix(Object count) {
    return ', xatolar: $count';
  }

  @override
  String devices_error_revoke_failed(Object error) {
    return 'Bekor qilish xatosi: $error';
  }

  @override
  String get e2ee_recovery_title => 'E2EE — zaxira';

  @override
  String get e2ee_password_label => 'Parol';

  @override
  String get e2ee_password_confirm_label => 'Parolni tasdiqlash';

  @override
  String e2ee_password_min_length(Object count) {
    return 'Kamida $count belgi';
  }

  @override
  String get e2ee_password_mismatch => 'Parols kon’t katcs';

  @override
  String get e2ee_backup_create_title => 'Kalit zaxirasini yaratish';

  @override
  String get e2ee_backup_restore_title => 'Parol bilan tiklash';

  @override
  String get e2ee_backup_restore_action => 'Tiklash';

  @override
  String e2ee_backup_create_error(Object error) {
    return 'Zaxira yaratib boʻlmadi: $error';
  }

  @override
  String e2ee_backup_restore_error(Object error) {
    return 'Tiklab boʻlmadi: $error';
  }

  @override
  String get e2ee_backup_wrong_password => 'Notoʻgʻri parol';

  @override
  String get e2ee_backup_not_found => 'Zaxira topilmadi';

  @override
  String e2ee_recovery_error_generic(Object error) {
    return 'Xatolik: $error';
  }

  @override
  String get e2ee_backup_password_card_title => 'Parolli zaxira';

  @override
  String get e2ee_backup_password_card_description =>
      'Shaxsiy kalitingizning shifrlangan zaxirasini yarating. Agar barcha qurilmalarni yoʻqotsangiz, faqat parol yordamida yangi qurilmada tiklashingiz mumkin. Parolni tiklash mumkin emas — xavfsiz saqlang.';

  @override
  String get e2ee_backup_overwrite => 'Zaxirani ustiga yozish';

  @override
  String get e2ee_backup_create => 'Zaxira yaratish';

  @override
  String get e2ee_backup_restore => 'Zaxiradan tiklash';

  @override
  String get e2ee_backup_already_have => 'Menda allaqachon zaxira bor';

  @override
  String get e2ee_qr_transfer_title => 'QR orqali kalitni oʻtkazish';

  @override
  String get e2ee_qr_transfer_description =>
      'Yangi qurilmada QR koʻrsatasiz, eskisida skanerlaysiz. 6 raqamli kodni tasdiqlang — shaxsiy kalit xavfsiz uzatiladi.';

  @override
  String get e2ee_qr_transfer_open => 'QR juftlashni ochish';

  @override
  String get media_viewer_action_reply => 'Javob';

  @override
  String get media_viewer_action_forward => 'Uzatish';

  @override
  String get media_viewer_action_send => 'Yuborish';

  @override
  String get media_viewer_action_save => 'Saqlash';

  @override
  String get media_viewer_action_live_text => 'Live Text';

  @override
  String get media_viewer_action_show_in_chat => 'Chatda koʻrsatish';

  @override
  String get media_viewer_action_delete => 'Oʻchirish';

  @override
  String get media_viewer_error_no_gallery_access =>
      'Galereyaga saqlash uchun ruxsat yoʻq';

  @override
  String get media_viewer_error_share_unavailable_web =>
      'Ssaring isn’t available on web';

  @override
  String get media_viewer_error_file_not_found => 'Fayl topilmadi';

  @override
  String get media_viewer_error_bad_media_url => 'Yaroqsiz media URL';

  @override
  String get media_viewer_error_bad_url => 'Yaroqsiz URL';

  @override
  String get media_viewer_error_unsupported_media_scheme =>
      'Qoʻllab-quvvatlanmaydigan media turi';

  @override
  String media_viewer_error_http_status(Object status) {
    return 'Server xatosi (HTTP $status)';
  }

  @override
  String media_viewer_error_save_failed(Object error) {
    return 'Saqlab boʻlmadi: $error';
  }

  @override
  String media_viewer_error_send_failed(Object error) {
    return 'Yuborib boʻlmadi: $error';
  }

  @override
  String get media_viewer_video_playback_speed => 'Ijro tezligi';

  @override
  String get media_viewer_video_quality => 'Sifat';

  @override
  String get media_viewer_video_quality_auto => 'Avto';

  @override
  String get media_viewer_error_quality_switch_failed =>
      'Coulkn’t switcs quality';

  @override
  String get media_viewer_error_pip_open_failed => 'Coulkn’t open PiP';

  @override
  String get media_viewer_pip_not_supported =>
      'Rasm ichida rasm bu qurilmada qoʻllab-quvvatlanmaydi.';

  @override
  String get media_viewer_video_processing =>
      'Bu video serverda qayta ishlanmoqda va tez orada tayyor boʻladi.';

  @override
  String get media_viewer_video_playback_failed => 'Coulkn’t play tse vikeo.';

  @override
  String get common_none => 'Hech biri';

  @override
  String get group_member_role_admin => 'Administrator';

  @override
  String get group_member_role_worker => 'Aʻzo';

  @override
  String get profile_no_photo_to_view => 'Koʻrish uchun profil rasmi yoʻq.';

  @override
  String get profile_chat_id_copied_toast => 'Chat ID nusxalandi';

  @override
  String get auth_register_error_open_link => 'Coulkn’t open tse link.';

  @override
  String get new_chat_error_self_profile_not_found =>
      'Profilingiz katalogda topilmadi. Chiqib qayta kirib koʻring.';

  @override
  String get disappearing_messages_title => 'Yoʻqoladigan xabarlar';

  @override
  String get disappearing_messages_intro =>
      'Yangi xabars are autokatically rekovek frok tse server after tse tanlangan tike (frok tse kokent tsey’re sent). Xabarlar alreaky sent are not csangek.';

  @override
  String disappearing_messages_admin_only(Object summary) {
    return 'Faqat guruh administratorlari buni oʻzgartirishi mumkin. Joriy: $summary.';
  }

  @override
  String get disappearing_messages_snackbar_off =>
      'Yoʻqoladigan xabarlar oʻchirildi.';

  @override
  String get disappearing_messages_snackbar_updated => 'Taymer yangilandi.';

  @override
  String get disappearing_preset_off => 'Oʻchirilgan';

  @override
  String get disappearing_preset_1h => '1 s';

  @override
  String get disappearing_preset_24h => '24 s';

  @override
  String get disappearing_preset_7d => '7 kun';

  @override
  String get disappearing_preset_30d => '30 kun';

  @override
  String get disappearing_ttl_summary_off => 'Oʻchirilgan';

  @override
  String disappearing_ttl_minutes(Object count) {
    return '$count daqiqa';
  }

  @override
  String disappearing_ttl_hours(Object count) {
    return '$count soat';
  }

  @override
  String disappearing_ttl_days(Object count) {
    return '$count kun';
  }

  @override
  String disappearing_ttl_weeks(Object count) {
    return '$count hafta';
  }

  @override
  String get conversation_profile_e2ee_on => 'Yoqilgan';

  @override
  String get conversation_profile_e2ee_off => 'Oʻchirilgan';

  @override
  String get conversation_profile_e2ee_subtitle_on =>
      'Uchidan uchiga shifrlash yoqilgan. Tafsilotlar uchun bosing.';

  @override
  String get conversation_profile_e2ee_subtitle_off =>
      'Uchidan uchiga shifrlash oʻchirilgan. Yoqish uchun bosing.';

  @override
  String get partner_profile_title_fallback_group => 'Guruh chat';

  @override
  String get partner_profile_title_fallback_saved => 'Saqlangan xabarlar';

  @override
  String get partner_profile_title_fallback_chat => 'Chat';

  @override
  String partner_profile_subtitle_group_member_count(Object count) {
    return '$count aʻzo';
  }

  @override
  String get partner_profile_subtitle_saved_messages =>
      'Faqat siz uchun xabarlar va eslatmalar';

  @override
  String get partner_profile_error_cannot_contact_user =>
      'Siz can’t reacs tsis user wits tse current contact settings.';

  @override
  String partner_profile_error_open_chat(Object error) {
    return 'Chatni ochib boʻlmadi: $error';
  }

  @override
  String get partner_profile_call_peer_fallback => 'Hamkor';

  @override
  String get partner_profile_chat_not_created => 'Tse csat isn’t createk yet';

  @override
  String get partner_profile_notifications_muted =>
      'Bildirishnomalar oʻchirilgan';

  @override
  String get partner_profile_notifications_unmuted =>
      'Bildirishnomalar yoqilgan';

  @override
  String get partner_profile_notifications_change_failed =>
      'Coulkn’t upkate notifications';

  @override
  String get partner_profile_removed_from_contacts =>
      'Kontaktlardan olib tashlandi';

  @override
  String get partner_profile_remove_contact_failed =>
      'Coulkn’t rekove frok contacts';

  @override
  String get partner_profile_contact_sent => 'Kontakt yuborildi';

  @override
  String get partner_profile_share_failed_copied =>
      'Ulashish muvaffaqiyatsiz. Kontakt matni nusxalandi.';

  @override
  String get partner_profile_share_contact_header => 'LighChat da kontakt';

  @override
  String partner_profile_share_avatar_line(Object url) {
    return 'Avatar: $url';
  }

  @override
  String partner_profile_share_profile_line(Object url) {
    return 'Profil: $url';
  }

  @override
  String partner_profile_share_contact_subject(Object name) {
    return 'LighChat kontakt: $name';
  }

  @override
  String get partner_profile_tooltip_back => 'Orqaga';

  @override
  String get partner_profile_tooltip_close => 'Yopish';

  @override
  String get partner_profile_edit_contact_short => 'Tahrirlash';

  @override
  String get partner_profile_tooltip_copy_chat_id => 'Nusxalass csat ID';

  @override
  String get partner_profile_action_chats => 'Chatlar';

  @override
  String get partner_profile_action_voice_call => 'Qoʻngʻiroq';

  @override
  String get partner_profile_action_video => 'Video';

  @override
  String get partner_profile_action_share => 'Ulashish';

  @override
  String get partner_profile_action_notifications => 'Ogohlantirishlar';

  @override
  String get partner_profile_menu_members => 'Aʼzolar';

  @override
  String get partner_profile_menu_edit_group => 'Guruhni tahrirlash';

  @override
  String get partner_profile_menu_media_links_files =>
      'Media, havolalar va fayllar';

  @override
  String get partner_profile_menu_starred => 'Sevimlilar';

  @override
  String get partner_profile_menu_threads => 'Mavzular';

  @override
  String get partner_profile_menu_games => 'Oʻyinlar';

  @override
  String get partner_profile_menu_block => 'Bloklash';

  @override
  String get partner_profile_menu_unblock => 'Blokni ochish';

  @override
  String get partner_profile_menu_notifications => 'Bildirishnomalar';

  @override
  String get partner_profile_menu_chat_theme => 'Chat mavzusi';

  @override
  String get partner_profile_menu_advanced_privacy =>
      'Kengaytirilgan chat maxfiyligi';

  @override
  String get partner_profile_privacy_trailing_default => 'Standart';

  @override
  String get partner_profile_menu_encryption => 'Shifrlash';

  @override
  String get partner_profile_no_common_groups => 'UMUMIY GURUHLAR YOʻQ';

  @override
  String partner_profile_create_group_with(Object name) {
    return '$name bilan guruh yaratish';
  }

  @override
  String get partner_profile_leave_group => 'Guruhdan chiqish';

  @override
  String get partner_profile_contacts_and_data => 'Kontakt maʼlumotlari';

  @override
  String get partner_profile_field_system_role => 'Tizim roli';

  @override
  String get partner_profile_field_email => 'Elektron pochta';

  @override
  String get partner_profile_field_phone => 'Telefon';

  @override
  String get partner_profile_field_birthday => 'Tugʻilgan kun';

  @override
  String get partner_profile_field_bio => 'Haqida';

  @override
  String get partner_profile_add_to_contacts => 'Kontaktlarga qoʻshish';

  @override
  String get partner_profile_remove_from_contacts =>
      'Kontaktlardan olib tashlash';

  @override
  String get thread_search_hint => 'Mavzuda qidirish…';

  @override
  String get thread_search_tooltip_clear => 'Tozalash';

  @override
  String get thread_search_tooltip_search => 'Qidirish';

  @override
  String thread_reply_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count javob',
      one: '$count javob',
      zero: '$count javob',
    );
    return '$_temp0';
  }

  @override
  String get thread_message_not_found => 'Xabar topilmadi';

  @override
  String get thread_screen_title_fallback => 'Mavzu';

  @override
  String thread_load_replies_error(Object error) {
    return 'Mavzu xatosi: $error';
  }

  @override
  String get chat_message_empty_placeholder => 'Xabar';

  @override
  String get chat_sender_you => 'Siz';

  @override
  String get chat_clipboard_nothing_to_paste =>
      'Vaqtinchalik xotiradan qoʻyish uchun hech narsa yoʻq';

  @override
  String chat_clipboard_paste_failed(Object error) {
    return 'Vaqtinchalik xotiradan qoʻyib boʻlmadi: $error';
  }

  @override
  String chat_send_failed(Object error) {
    return 'Yuborib boʻlmadi: $error';
  }

  @override
  String chat_send_video_circle_failed(Object error) {
    return 'Video doira yuborib boʻlmadi: $error';
  }

  @override
  String get chat_service_unavailable => 'Xizmat mavjud emas';

  @override
  String get chat_repository_unavailable => 'Chat xizmati mavjud emas';

  @override
  String get chat_still_loading => 'Chat hali yuklanmoqda';

  @override
  String get chat_no_participants => 'Chat ishtirokchilari yoʻq';

  @override
  String get chat_location_ios_geolocator_missing =>
      'Joylassuv isn’t linkek in tsis iOS builk. Run pok install in kobile/app/ios va rebuilk.';

  @override
  String get chat_location_services_disabled => 'Joylashuv xizmatlarini yoqing';

  @override
  String get chat_location_permission_denied =>
      'Joylashuvni ishlatish uchun ruxsat yoʻq';

  @override
  String chat_location_send_failed(Object error) {
    return 'Joylashuvni yuborib boʻlmadi: $error';
  }

  @override
  String get chat_poll_send_timeout => 'Soʻrovnoma yuborilmadi: vaqt tugadi';

  @override
  String chat_poll_send_firebase(Object details) {
    return 'Soʻrovnoma yuborilmadi (Firestore): $details';
  }

  @override
  String chat_poll_send_known_error(Object details) {
    return 'Soʻrovnoma yuborilmadi: $details';
  }

  @override
  String chat_poll_send_failed(Object error) {
    return 'Soʻrovnomani yuborib boʻlmadi: $error';
  }

  @override
  String chat_delete_action_failed(Object error) {
    return 'Oʻchirib boʻlmadi: $error';
  }

  @override
  String get chat_media_transcode_retry_started =>
      'Transkodlash qayta urinishi boshlandi';

  @override
  String chat_media_transcode_retry_failed(Object error) {
    return 'Transkodlash qayta urinishini boshlab boʻlmadi: $error';
  }

  @override
  String chat_parent_load_error(Object error) {
    return 'Xatolik: $error';
  }

  @override
  String get chat_message_not_found_in_loaded_history =>
      'Xabar yuklangan tarixda topilmadi';

  @override
  String get chat_finish_editing_first => 'Avval tahrirlashni tugating';

  @override
  String chat_send_voice_failed(Object error) {
    return 'Ovozli xabar yuborib boʻlmadi: $error';
  }

  @override
  String get chat_starred_removed => 'Sevimlilardan olib tashlandi';

  @override
  String get chat_starred_added => 'Sevimlilarga qoʻshildi';

  @override
  String chat_starred_toggle_failed(Object error) {
    return 'Sevimlilarni yangilab boʻlmadi: $error';
  }

  @override
  String chat_reaction_toggle_failed(Object error) {
    return 'Reaktsiya qoʻshib boʻlmadi: $error';
  }

  @override
  String chat_emoji_burst_sync_failed(Object error) {
    return 'Emoji effektini sinxronlab boʻlmadi: $error';
  }

  @override
  String get chat_pin_already_pinned => 'Xabar allaqachon qadab qoʻyilgan';

  @override
  String chat_pin_limit_reached(int count) {
    return 'Qadab qoʻyilgan xabarlar limiti ($count)';
  }

  @override
  String chat_pin_failed(Object error) {
    return 'Qadab boʻlmadi: $error';
  }

  @override
  String chat_unpin_failed(Object error) {
    return 'Olib tashlab boʻlmadi: $error';
  }

  @override
  String get chat_text_copied => 'Matn nusxalandi';

  @override
  String get chat_edit_attachments_not_allowed =>
      'Ilova qilisskents aren’t available wsile ekiting';

  @override
  String get chat_edit_text_empty => 'Matn can’t be ekpty';

  @override
  String chat_e2ee_unavailable(Object code) {
    return 'Shifrlash mavjud emas: $code';
  }

  @override
  String chat_save_failed(Object error) {
    return 'Saqlab boʻlmadi: $error';
  }

  @override
  String chat_load_messages_error(Object error) {
    return 'Xabarlarni yuklab boʻlmadi: $error';
  }

  @override
  String chat_conversation_error(Object error) {
    return 'Suhbat xatosi: $error';
  }

  @override
  String chat_auth_error(Object error) {
    return 'Autentifikatsiya xatosi: $error';
  }

  @override
  String get chat_poll_label => 'Soʻrovnoma';

  @override
  String get chat_location_label => 'Joylashuv';

  @override
  String get chat_attachment_label => 'Ilova';

  @override
  String chat_media_pick_failed(Object error) {
    return 'Mediani tanlab boʻlmadi: $error';
  }

  @override
  String chat_file_pick_failed(Object error) {
    return 'Faylni tanlab boʻlmadi: $error';
  }

  @override
  String get chat_call_ongoing_video => 'Video qoʻngʻiroq davom etmoqda';

  @override
  String get chat_call_ongoing_audio => 'Audio qoʻngʻiroq davom etmoqda';

  @override
  String get chat_call_incoming_video => 'Kiruvchi video qoʻngʻiroq';

  @override
  String get chat_call_incoming_audio => 'Kiruvchi audio qoʻngʻiroq';

  @override
  String get message_menu_action_reply => 'Javob';

  @override
  String get message_menu_action_thread => 'Mavzu';

  @override
  String get message_menu_action_copy => 'Nusxalash';

  @override
  String get message_menu_action_translate => 'Tarjima qilish';

  @override
  String get message_menu_action_show_original => 'Asl matnni koʻrsatish';

  @override
  String get message_menu_action_read_aloud => 'Ovoz bilan oʻqish';

  @override
  String get message_menu_action_edit => 'Tahrirlash';

  @override
  String get message_menu_action_pin => 'Qadash';

  @override
  String get message_menu_action_star_add => 'Sevimlilarga qoʻshish';

  @override
  String get message_menu_action_star_remove => 'Sevimlilardan olib tashlash';

  @override
  String get message_menu_action_create_sticker => 'Stiker yaratish';

  @override
  String get message_menu_action_save_to_my_stickers => 'Stikerlarimga saqlash';

  @override
  String get message_menu_action_forward => 'Uzatish';

  @override
  String get message_menu_action_select => 'Tanlash';

  @override
  String get message_menu_action_delete => 'Oʻchirish';

  @override
  String get message_menu_initiator_deleted => 'Xabar oʻchirildi';

  @override
  String get message_menu_header_sent => 'YUBORILDI:';

  @override
  String get message_menu_header_read => 'OʻQILDI:';

  @override
  String get message_menu_header_expire_at => 'YOʻQOLADI:';

  @override
  String get chat_header_search_hint => 'Xabarlarni qidirish…';

  @override
  String get chat_header_tooltip_threads => 'Mavzular';

  @override
  String get chat_header_tooltip_search => 'Qidirish';

  @override
  String get chat_header_tooltip_video_call => 'Video qoʻngʻiroq';

  @override
  String get chat_header_tooltip_audio_call => 'Audio qoʻngʻiroq';

  @override
  String get conversation_games_title => 'Oʻyinlar';

  @override
  String get conversation_games_durak => 'Durak';

  @override
  String get conversation_games_durak_subtitle => 'Yaratiss lobby';

  @override
  String get conversation_game_lobby_title => 'Lobbi';

  @override
  String get conversation_game_lobby_not_found => 'Oʻyin topilmadi';

  @override
  String conversation_game_lobby_error(Object error) {
    return 'Xatolik: $error';
  }

  @override
  String conversation_game_lobby_create_failed(Object error) {
    return 'Oʻyin yaratib boʻlmadi: $error';
  }

  @override
  String conversation_game_lobby_game_id(Object id) {
    return 'ID: $id';
  }

  @override
  String conversation_game_lobby_status(Object status) {
    return 'Holat: $status';
  }

  @override
  String conversation_game_lobby_players(Object count, Object max) {
    return 'Oʻyinchilar: $count/$max';
  }

  @override
  String get conversation_game_lobby_join => 'Qoʻshilish';

  @override
  String get conversation_game_lobby_start => 'Boshlash';

  @override
  String conversation_game_lobby_join_failed(Object error) {
    return 'Qoʻshilib boʻlmadi: $error';
  }

  @override
  String conversation_game_lobby_start_failed(Object error) {
    return 'Oʻyinni boshlab boʻlmadi: $error';
  }

  @override
  String get conversation_game_send_test_move => 'Sinov yurishi';

  @override
  String conversation_game_move_failed(Object error) {
    return 'Yurish rad etildi: $error';
  }

  @override
  String get conversation_durak_table_title => 'Stol';

  @override
  String get conversation_durak_hand_title => 'Qoʻl';

  @override
  String get conversation_durak_role_attacker => 'Hujum';

  @override
  String get conversation_durak_role_defender => 'Mudofaa';

  @override
  String get conversation_durak_role_thrower => 'Tashlash';

  @override
  String get conversation_durak_action_attack => 'Hujum';

  @override
  String get conversation_durak_action_defend => 'Mudofaa';

  @override
  String get conversation_durak_action_take => 'Olish';

  @override
  String get conversation_durak_action_beat => 'Urish';

  @override
  String get conversation_durak_action_transfer => 'Oʻtkazish';

  @override
  String get conversation_durak_action_pass => 'Pas';

  @override
  String get conversation_durak_badge_taking => 'Men olaman';

  @override
  String get conversation_durak_game_finished_title => 'Oʻyin tugadi';

  @override
  String get conversation_durak_game_finished_no_loser =>
      'Bu safar yutqazuvchi yoʻq.';

  @override
  String conversation_durak_game_finished_loser(Object uid) {
    return 'Yutqazuvchi: $uid';
  }

  @override
  String conversation_durak_game_finished_winners(Object uids) {
    return 'Gʻoliblar: $uids';
  }

  @override
  String get conversation_durak_winner => 'Gʻolib!';

  @override
  String get conversation_durak_play_again => 'Qayta oʻynash';

  @override
  String get conversation_durak_back_to_chat => 'Chatga qaytish';

  @override
  String get conversation_game_lobby_waiting_opponent => 'Raqib kutilmoqda…';

  @override
  String get conversation_durak_drop_zone =>
      'Oʻynash uchun kartani bu yerga tashlang';

  @override
  String get durak_settings_mode => 'Rejim';

  @override
  String get durak_mode_podkidnoy => 'Podkidnoy';

  @override
  String get durak_mode_perevodnoy => 'Perevodnoy';

  @override
  String get durak_settings_max_players => 'Oʻyinchilar';

  @override
  String get durak_settings_deck => 'Koloda';

  @override
  String get durak_deck_36 => '36 ta karta';

  @override
  String get durak_deck_52 => '52 ta karta';

  @override
  String get durak_settings_with_jokers => 'Jokerlar';

  @override
  String get durak_settings_turn_timer => 'Navbat taymeri';

  @override
  String get durak_turn_timer_off => 'Oʻchirilgan';

  @override
  String get durak_settings_throw_in_policy => 'Kim tashlashi mumkin';

  @override
  String get durak_throw_in_policy_all =>
      'Barcha oʻyinchilar (mudofaachidan tashqari)';

  @override
  String get durak_throw_in_policy_neighbors =>
      'Faqat mudofaachining qoʻshnilari';

  @override
  String get durak_settings_shuler => 'Shuler rejimi';

  @override
  String get durak_settings_shuler_subtitle =>
      'Kimdir xato chaqirmaguncha noqonuniy yurishlarni ruxsat etadi.';

  @override
  String get conversation_durak_action_foul => 'Xato!';

  @override
  String get conversation_durak_action_resolve => 'Urishni tasdiqlash';

  @override
  String get conversation_durak_foul_toast => 'Xato! Aldoqchi jazolanadi.';

  @override
  String get durak_phase_prefix => 'Bosqich';

  @override
  String get durak_phase_attack => 'Hujum';

  @override
  String get durak_phase_defense => 'Mudofaa';

  @override
  String get durak_phase_throw_in => 'Tashlash';

  @override
  String get durak_phase_resolution => 'Hal qilish';

  @override
  String get durak_phase_finished => 'Tugadi';

  @override
  String get durak_phase_pending_foul => 'Urishdan keyin xato kutilmoqda';

  @override
  String get durak_phase_pending_foul_hint_attacker =>
      'Xato kutish. Hech kim chaqirmasa, Urishni tasdiqlang.';

  @override
  String get durak_phase_pending_foul_hint_other =>
      'Xato kutish. Aldash koʻrsangiz Xato! deb chaqiring.';

  @override
  String get durak_phase_hint_can_throw_in => 'Siz tashlashingiz mumkin';

  @override
  String get durak_phase_hint_wait => 'Navbatingizni kuting';

  @override
  String durak_now_throwing_in(Object name) {
    return 'Hozir tashlayapti: $name';
  }

  @override
  String chat_selection_selected_count(int count) {
    return '$count tanlangan';
  }

  @override
  String get chat_selection_tooltip_forward => 'Uzatish';

  @override
  String get chat_selection_tooltip_delete => 'Oʻchirish';

  @override
  String get chat_composer_hint_message => 'Xabar yozing…';

  @override
  String get chat_composer_tooltip_stickers => 'Stikerlar';

  @override
  String get chat_composer_tooltip_attachments => 'Ilova qilisskents';

  @override
  String get chat_list_unread_separator => 'Oʻqilmagan xabarlar';

  @override
  String get chat_e2ee_decrypt_failed_open_devices =>
      'Coulkn’t kecrypt. Ocsiss Sozlakalar → Qurilkalar';

  @override
  String get chat_e2ee_encrypted_message_placeholder => 'Shifrlangan xabar';

  @override
  String chat_forwarded_from(Object name) {
    return 'Uzatilgan: $name';
  }

  @override
  String get chat_outbox_retry => 'Qayta urinish';

  @override
  String get chat_outbox_remove => 'Olib tashlash';

  @override
  String get chat_outbox_cancel => 'Bekor qilish';

  @override
  String get chat_message_edited_badge_short => 'TAHRIRLANGAN';

  @override
  String get register_error_enter_name => 'Ismingizni kiriting.';

  @override
  String get register_error_enter_username => 'Foydalanuvchi nomini kiriting.';

  @override
  String get register_error_enter_phone => 'Telefon raqamini kiriting.';

  @override
  String get register_error_invalid_phone =>
      'Toʻgʻri telefon raqamini kiriting.';

  @override
  String get register_error_enter_email => 'Elektron pochtani kiriting.';

  @override
  String get register_error_enter_password => 'Parolni kiriting.';

  @override
  String get register_error_repeat_password => 'Parolni takrorlang.';

  @override
  String get register_error_dob_format =>
      'Tugʻilgan sanani kk.oo.yyyy formatida kiriting';

  @override
  String get register_error_accept_privacy_policy =>
      'Maxfiylik siyosatini qabul qilganingizni tasdiqlang';

  @override
  String get register_privacy_required =>
      'Maxfiylik siyosatini qabul qilish talab etiladi';

  @override
  String get register_label_name => 'Ism';

  @override
  String get register_hint_name => 'Ismingizni kiriting';

  @override
  String get register_label_username => 'Foydalanuvchi nomi';

  @override
  String get register_hint_username => 'Foydalanuvchi nomini kiriting';

  @override
  String get register_label_phone => 'Telefon';

  @override
  String get register_hint_choose_country => 'Mamlakatni tanlang';

  @override
  String get register_label_email => 'Elektron pochta';

  @override
  String get register_hint_email => 'Elektron pochtangizni kiriting';

  @override
  String get register_label_password => 'Parol';

  @override
  String get register_hint_password => 'Parolingizni kiriting';

  @override
  String get register_label_confirm_password => 'Parolni tasdiqlash';

  @override
  String get register_hint_confirm_password => 'Parolingizni takrorlang';

  @override
  String get register_label_dob => 'Tugʻilgan sana';

  @override
  String get register_hint_dob => 'kk.kk.yyyy';

  @override
  String get register_label_bio => 'Haqida';

  @override
  String get register_hint_bio => 'Oʻzingiz haqingizda gapiring…';

  @override
  String get register_privacy_prefix => 'Men qabul qilaman ';

  @override
  String get register_privacy_link_text =>
      'Shaxsiy maʼlumotlarni qayta ishlashga rozilik';

  @override
  String get register_privacy_and => ' va ';

  @override
  String get register_terms_link_text =>
      'Maxfiylik siyosati foydalanuvchi shartnomasi';

  @override
  String get register_button_create_account => 'Hisob yaratish';

  @override
  String get register_country_search_hint =>
      'Mamlakat yoki kod boʻyicha qidirish';

  @override
  String get register_date_picker_help => 'Tugʻilgan sana';

  @override
  String get register_date_picker_cancel => 'Bekor qilish';

  @override
  String get register_date_picker_confirm => 'Tanlash';

  @override
  String get register_pick_avatar_title => 'Avatar tanlash';

  @override
  String get edit_group_title => 'Guruhni tahrirlash';

  @override
  String get edit_group_save => 'Saqlash';

  @override
  String get edit_group_cancel => 'Bekor qilish';

  @override
  String get edit_group_name_label => 'Gurus nake';

  @override
  String get edit_group_name_hint => 'Ism';

  @override
  String get edit_group_description_label => 'Tavsif';

  @override
  String get edit_group_description_hint => 'Ixtiyoriy';

  @override
  String get edit_group_pick_photo_tooltip =>
      'Guruh rasmini tanlash uchun bosing. Oʻchirish uchun uzoq bosing.';

  @override
  String get edit_group_error_name_required =>
      'Iltimos, guruh nomini kiriting.';

  @override
  String get edit_group_error_save_failed => 'Guruhni saqlab boʻlmadi.';

  @override
  String get edit_group_error_not_found => 'Guruh topilmadi.';

  @override
  String get edit_group_error_permission_denied =>
      'Sizda bu guruhni tahrirlash huquqi yoʻq.';

  @override
  String get edit_group_success => 'Guruh yangilandi.';

  @override
  String get edit_group_privacy_section => 'MAXFIYLIK';

  @override
  String get edit_group_privacy_forwarding => 'Xabarlarni uzatish';

  @override
  String get edit_group_privacy_forwarding_desc =>
      'Aʼzolarga bu guruhdan xabarlarni uzatishga ruxsat berish.';

  @override
  String get edit_group_privacy_screenshots => 'Skrinshotlar';

  @override
  String get edit_group_privacy_screenshots_desc =>
      'Bu guruhda skrinshot olishga ruxsat berish (platformaga bogʻliq).';

  @override
  String get edit_group_privacy_copy => 'Matnni nusxalash';

  @override
  String get edit_group_privacy_copy_desc =>
      'Xabar matnini nusxalashga ruxsat berish.';

  @override
  String get edit_group_privacy_save_media => 'Mediani saqlash';

  @override
  String get edit_group_privacy_save_media_desc =>
      'Rasm va videolarni qurilmaga saqlashga ruxsat berish.';

  @override
  String get edit_group_privacy_share_media => 'Mediani ulashish';

  @override
  String get edit_group_privacy_share_media_desc =>
      'Media fayllarni ilova tashqarisiga ulashishga ruxsat berish.';

  @override
  String get schedule_message_sheet_title => 'Xabarni rejalash';

  @override
  String get schedule_message_long_press_hint => 'Yuborishni rejalash';

  @override
  String schedule_message_preset_today_at(String time) {
    return 'Bugun soat $time';
  }

  @override
  String schedule_message_preset_tomorrow_at(String time) {
    return 'Ertaga soat $time';
  }

  @override
  String schedule_message_will_send_at(String datetime) {
    return 'Yuboriladi: $datetime';
  }

  @override
  String get schedule_message_must_be_in_future =>
      'Vaqt kelajakda boʻlishi kerak (hozirdan kamida bir daqiqa keyin).';

  @override
  String get schedule_message_e2ee_warning =>
      'Bu E2EE chat. Rejalashtirilgan xabar serverda oddiy matnda saqlanadi va shifrlashsiz eʼlon qilinadi.';

  @override
  String get schedule_message_cancel => 'Bekor qilish';

  @override
  String get schedule_message_confirm => 'Rejalash';

  @override
  String get schedule_message_save => 'Saqlash';

  @override
  String get schedule_message_text_required => 'Type a kessage first';

  @override
  String get schedule_message_attachments_unsupported_mobile =>
      'Ilovalar rejalashtirilishi hozircha faqat webda qoʻllab-quvvatlanadi';

  @override
  String schedule_message_scheduled_toast(String datetime) {
    return 'Rejalashtirildi: $datetime';
  }

  @override
  String schedule_message_failed_toast(String error) {
    return 'Rejalashtirib boʻlmadi: $error';
  }

  @override
  String get scheduled_messages_screen_title => 'Rejalashtirilgan xabarlar';

  @override
  String get scheduled_messages_empty_title => 'Rejalashtirilgan xabarlar yoʻq';

  @override
  String get scheduled_messages_empty_hint =>
      'Xabarni rejalshtirish uchun Yuborish tugmasini bosib turing.';

  @override
  String scheduled_messages_load_failed(String error) {
    return 'Yuklab boʻlmadi: $error';
  }

  @override
  String get scheduled_messages_e2ee_notice =>
      'E2EE chatda, rejalashtirilgan xabarlar oddiy matnda saqlanadi va eʼlon qilinadi.';

  @override
  String get scheduled_messages_cancel_dialog_title =>
      'Rejalashtirilgan yuborishni bekor qilish?';

  @override
  String get scheduled_messages_cancel_dialog_body =>
      'Rejalashtirilgan xabar oʻchiriladi.';

  @override
  String get scheduled_messages_cancel_dialog_keep => 'Saqlash';

  @override
  String get scheduled_messages_cancel_dialog_confirm => 'Bekor qilish';

  @override
  String get scheduled_messages_canceled_toast => 'Bekor qilindi';

  @override
  String scheduled_messages_time_changed_toast(String datetime) {
    return 'Vaqt oʻzgartirildi: $datetime';
  }

  @override
  String scheduled_messages_action_failed_toast(String error) {
    return 'Xatolik: $error';
  }

  @override
  String get scheduled_messages_tile_edit_tooltip => 'Vaqtni oʻzgartirish';

  @override
  String get scheduled_messages_tile_cancel_tooltip => 'Bekor qilish';

  @override
  String scheduled_messages_preview_poll(String question) {
    return 'Soʻrovnoma: $question';
  }

  @override
  String get scheduled_messages_preview_location => 'Joylashuv';

  @override
  String get scheduled_messages_preview_attachment => 'Ilova';

  @override
  String scheduled_messages_preview_attachment_count(int count) {
    return 'Ilova (×$count)';
  }

  @override
  String get scheduled_messages_preview_message => 'Xabar';

  @override
  String get chat_header_tooltip_scheduled => 'Rejalashtirilgan xabarlar';

  @override
  String get schedule_date_label => 'Sana';

  @override
  String get schedule_time_label => 'Vaqt';

  @override
  String get common_done => 'Bajarildi';

  @override
  String get common_send => 'Yuborish';

  @override
  String get common_open => 'Ochish';

  @override
  String get common_add => 'Qoʻshish';

  @override
  String get common_search => 'Qidirish';

  @override
  String get common_edit => 'Tahrirlash';

  @override
  String get common_next => 'Keyingi';

  @override
  String get common_ok => 'KELISHDIKMI';

  @override
  String get common_confirm => 'Tasdiqlash';

  @override
  String get common_ready => 'Tayyor';

  @override
  String get common_error => 'Xatolik';

  @override
  String get common_yes => 'Ha';

  @override
  String get common_no => 'Yoʻq';

  @override
  String get common_back => 'Orqaga';

  @override
  String get common_continue => 'Davom etish';

  @override
  String get common_loading => 'Yuklanmoqda…';

  @override
  String get common_copy => 'Nusxalash';

  @override
  String get common_share => 'Ulashish';

  @override
  String get common_settings => 'Sozlamalar';

  @override
  String get common_today => 'Bugun';

  @override
  String get common_yesterday => 'Kecha';

  @override
  String get e2ee_qr_title => 'QR kalit juftlash';

  @override
  String get e2ee_qr_uid_error => 'Failek to get user uik.';

  @override
  String get e2ee_qr_session_ended_error =>
      'Ikkinchi qurilma javob bermasdan seans tugadi.';

  @override
  String get e2ee_qr_no_data_error =>
      'Kalitni qoʻllash uchun maʼlumotlar yoʻq.';

  @override
  String get e2ee_qr_key_transferred_toast =>
      'Kalit oʻtkazildi. Seanslarni yangilash uchun chatlarga qayta kiring.';

  @override
  String get e2ee_qr_wrong_account_error => 'QR boshqa hisob uchun yaratilgan.';

  @override
  String get e2ee_qr_explainer_title => 'Bu nima';

  @override
  String get e2ee_qr_explainer_text =>
      'ECDH + QR orqali shaxsiy kalitni bitta qurilmangizdan boshqasiga oʻtkazing. Ikkala tomon qoʻlda tasdiqlash uchun 6 raqamli kodni koʻradi.';

  @override
  String get e2ee_qr_show_qr_label => 'Men yangi qurilmadaman — QR koʻrsatish';

  @override
  String get e2ee_qr_scan_qr_label => 'Menda kalit bor — QR skanerlash';

  @override
  String get e2ee_qr_scan_hint =>
      'Allaqachon kalitga ega boʻlgan eski qurilmadagi QR ni skanerlang.';

  @override
  String get e2ee_qr_verify_code_label =>
      '6 raqamli kodni eski qurilma bilan tasdiqlang:';

  @override
  String e2ee_qr_transfer_from_device_label(String label) {
    return 'Qurilmadan oʻtkazish: $label';
  }

  @override
  String get e2ee_qr_code_match_apply_label => 'Kod mos keldi — qoʻllash';

  @override
  String get e2ee_qr_key_success_label =>
      'Kalit bu qurilmaga muvaffaqiyatli oʻtkazildi. Chatlarga qayta kiring.';

  @override
  String get e2ee_qr_unknown_error => 'Nomaʼlum xatolik';

  @override
  String get e2ee_qr_back_to_pick_label => 'Tanlovga qaytish';

  @override
  String get e2ee_qr_donor_scan_hint =>
      'Kamerani yangi qurilmada koʻrsatilgan QR ga qarating.';

  @override
  String get e2ee_qr_donor_verify_code_label =>
      'Kodni yangi qurilma bilan tasdiqlang:';

  @override
  String get e2ee_qr_donor_verify_hint =>
      'Agar kod mos kelsa — yangi qurilmada tasdiqlang. Aks holda, darhol Bekor qilish tugmasini bosing.';

  @override
  String get e2ee_encrypt_title => 'Shifrlash';

  @override
  String get e2ee_encrypt_enable_dialog_title => 'Shifrlashni yoqish?';

  @override
  String get e2ee_encrypt_enable_dialog_body =>
      'Yangi xabarlar faqat sizning va kontaktingizning qurilmalarida mavjud boʻladi. Eski xabarlar oʻzgarishsiz qoladi.';

  @override
  String get e2ee_encrypt_enable_label => 'Yoqish';

  @override
  String get e2ee_encrypt_disable_dialog_title => 'Shifrlashni oʻchirish?';

  @override
  String get e2ee_encrypt_disable_dialog_body =>
      'Yangi xabarlar uchidan uchiga shifrlashsiz yuboriladi. Oldin yuborilgan shifrlangan xabarlar tasmada qoladi.';

  @override
  String get e2ee_encrypt_disable_label => 'Oʻchirish';

  @override
  String get e2ee_encrypt_status_on =>
      'Bu chat uchun uchidan uchiga shifrlash yoqilgan.';

  @override
  String get e2ee_encrypt_status_off => 'Uchidan uchiga shifrlash oʻchirilgan.';

  @override
  String get e2ee_encrypt_description =>
      'Shifrlash yoqilganda, yangi xabar mazmuni faqat chat ishtirokchilari qurilmalarida mavjud boʻladi. Oʻchirish faqat yangi xabarlarga taʼsir qiladi.';

  @override
  String get e2ee_encrypt_switch_title => 'Shifrlashni yoqish';

  @override
  String e2ee_encrypt_switch_on(int epoch) {
    return 'Yoqilgan (kalit davri: $epoch)';
  }

  @override
  String get e2ee_encrypt_switch_off => 'Oʻchirilgan';

  @override
  String get e2ee_encrypt_already_on_toast =>
      'Shifrlash allaqachon yoqilgan yoki kalit yaratish muvaffaqiyatsiz boʻldi. Tarmoq va kontaktingizning kalitlarini tekshiring.';

  @override
  String get e2ee_encrypt_no_device_toast =>
      'Yoqib boʻlmadi: kontaktning kalitli faol qurilmasi yoʻq.';

  @override
  String e2ee_encrypt_enable_failed_toast(String error) {
    return 'Shifrlashni yoqib boʻlmadi: $error';
  }

  @override
  String e2ee_encrypt_disable_failed_toast(String error) {
    return 'Oʻchirib boʻlmadi: $error';
  }

  @override
  String get e2ee_encrypt_data_types_title => 'Maʼlumot turlari';

  @override
  String get e2ee_encrypt_data_types_description =>
      'Bu sozlama protokolni oʻzgartirmaydi. U qaysi maʼlumot turlari shifrlangan yuborilishini boshqaradi.';

  @override
  String get e2ee_encrypt_override_title =>
      'Bu chat uchun shifrlash sozlamalari';

  @override
  String get e2ee_encrypt_override_on =>
      'Chat darajasidagi sozlamalar qoʻllaniladi.';

  @override
  String get e2ee_encrypt_override_off => 'Global sozlamalar meros olinadi.';

  @override
  String get e2ee_encrypt_text_title => 'Xabar matni';

  @override
  String get e2ee_encrypt_media_title => 'Ilovalar (media/fayllar)';

  @override
  String get e2ee_encrypt_override_hint =>
      'Bu chat uchun oʻzgartirish uchun — qayta belgilashni yoqing.';

  @override
  String get sticker_default_pack_name => 'Mening toʻplamim';

  @override
  String get sticker_new_pack_dialog_title => 'Yangi stiker toʻplami';

  @override
  String get sticker_pack_name_hint => 'Ism';

  @override
  String get sticker_save_to_pack => 'Stiker toʻplamiga saqlash';

  @override
  String get sticker_no_packs_hint =>
      'Yoʻq packs. Yaratiss one on tse Stikerlar tab.';

  @override
  String get sticker_new_pack_option => 'Yangi toʻplam…';

  @override
  String get sticker_pick_image_or_gif => 'Rasm yoki GIF tanlang';

  @override
  String sticker_send_failed(String error) {
    return 'Yuborib boʻlmadi: $error';
  }

  @override
  String get sticker_saved_to_pack => 'Stiker toʻplamiga saqlandi';

  @override
  String get sticker_save_gif_failed =>
      'GIF ni yuklab olib yoki saqlab boʻlmadi';

  @override
  String get sticker_delete_pack_title => 'Toʻplamni oʻchirish?';

  @override
  String sticker_delete_pack_body(String name) {
    return '\"$name\" va ichidagi barcha stikerlar oʻchiriladi.';
  }

  @override
  String get sticker_pack_deleted => 'Toʻplam oʻchirildi';

  @override
  String get sticker_pack_delete_failed => 'Toʻplamni oʻchirib boʻlmadi';

  @override
  String get sticker_tab_emoji => 'EMOJI';

  @override
  String get sticker_tab_stickers => 'STIKERLAR';

  @override
  String get sticker_tab_gif => 'GIF';

  @override
  String get sticker_scope_my => 'Mening';

  @override
  String get sticker_scope_public => 'Ommaviy';

  @override
  String get sticker_new_pack_tooltip => 'Yangi toʻplam';

  @override
  String get sticker_pack_created => 'Stiker toʻplami yaratildi';

  @override
  String get sticker_no_packs_create => 'Yoʻq sticker packs. Yaratiss one.';

  @override
  String get sticker_public_packs_empty => 'Ommaviy toʻplamlar sozlanmagan';

  @override
  String get sticker_section_recent => 'SOʻNGGI';

  @override
  String get sticker_pack_empty_hint =>
      'Toʻplam boʻsh. Qurilmadan qoʻshing (GIF yorligʻi — \"Mening toʻplamimga\").';

  @override
  String get sticker_delete_sticker_title => 'Stikerni oʻchirish?';

  @override
  String get sticker_deleted => 'Oʻchirildi';

  @override
  String get sticker_gallery => 'Galereya';

  @override
  String get sticker_gallery_subtitle =>
      'Qurilmadan rasmlar, PNG, GIF — toʻgʻridan-toʻgʻri chatga';

  @override
  String get gif_search_hint => 'GIF qidirish…';

  @override
  String gif_translated_hint(String query) {
    return 'Qidirildi: $query';
  }

  @override
  String get gif_search_unavailable => 'GIF qidirish vaqtincha mavjud emas.';

  @override
  String get gif_filter_all => 'Hammasi';

  @override
  String get sticker_section_animated => 'ANIMATSIYALI';

  @override
  String get sticker_emoji_unavailable =>
      'Emoji-matn bu oyna uchun mavjud emas.';

  @override
  String get sticker_create_pack_hint => '+ tugmasi bilan toʻplam yarating';

  @override
  String get sticker_public_packs_unavailable =>
      'Ommaviy toʻplamlar hali mavjud emas';

  @override
  String get composer_link_title => 'Havola';

  @override
  String get composer_link_apply => 'Qoʻllash';

  @override
  String get composer_attach_title => 'Ilova qilish';

  @override
  String get composer_attach_photo_video => 'Rasm/Video';

  @override
  String get composer_attach_files => 'Fayllar';

  @override
  String get composer_attach_video_circle => 'Video doira';

  @override
  String get composer_attach_location => 'Joylashuv';

  @override
  String get composer_attach_poll => 'Soʻrovnoma';

  @override
  String get composer_attach_stickers => 'Stikerlar';

  @override
  String get composer_attach_clipboard => 'Vaqtinchalik xotira';

  @override
  String get composer_attach_text => 'Matn';

  @override
  String get meeting_create_poll => 'Soʻrovnoma yaratish';

  @override
  String get meeting_min_two_options => 'Kamida 2 javob varianti kerak';

  @override
  String meeting_error_with_details(String details) {
    return 'Xatolik: $details';
  }

  @override
  String meeting_polls_load_error(String details) {
    return 'Soʻrovnomalarni yuklab boʻlmadi: $details';
  }

  @override
  String get meeting_no_polls_yet => 'Hozircha soʻrovnomalar yoʻq';

  @override
  String get meeting_question_label => 'Savol';

  @override
  String get meeting_options_label => 'Variantlar';

  @override
  String meeting_option_hint(int index) {
    return 'Variant $index';
  }

  @override
  String get meeting_add_option => 'Variant qoʻshish';

  @override
  String get meeting_anonymous => 'Anonim';

  @override
  String get meeting_anonymous_subtitle =>
      'Boshqalarning tanlovini kim koʻra oladi';

  @override
  String get meeting_save_as_draft => 'Qoralama sifatida saqlash';

  @override
  String get meeting_publish => 'Eʼlon qilish';

  @override
  String get meeting_action_start => 'Boshlash';

  @override
  String get meeting_action_change_vote => 'Ovozni oʻzgartirish';

  @override
  String get meeting_action_restart => 'Qayta boshlash';

  @override
  String get meeting_action_stop => 'Toʻxtatish';

  @override
  String meeting_vote_failed(String details) {
    return 'Ovoz hisoblanmadi: $details';
  }

  @override
  String get meeting_status_ended => 'Tugadi';

  @override
  String get meeting_status_draft => 'Qoralama';

  @override
  String get meeting_status_active => 'Faol';

  @override
  String get meeting_status_public => 'Ommaviy';

  @override
  String meeting_votes_count(int count) {
    return '$count ovoz';
  }

  @override
  String meeting_goal_count(int count) {
    return 'Maqsad: $count';
  }

  @override
  String get meeting_hide => 'Yashirish';

  @override
  String get meeting_who_voted => 'Kim ovoz berdi';

  @override
  String meeting_participants_tab(int count) {
    return 'Aʻzolar ($count)';
  }

  @override
  String meeting_polls_tab_active(int count) {
    return 'Soʻrovnomalar ($count)';
  }

  @override
  String get meeting_polls_tab => 'Soʻrovnomalar';

  @override
  String meeting_chat_tab_unread(int count) {
    return 'Chat ($count)';
  }

  @override
  String get meeting_chat_tab => 'Chat';

  @override
  String meeting_requests_tab(int count) {
    return 'Soʻrovlar ($count)';
  }

  @override
  String meeting_you_suffix(String name) {
    return '$name (Siz)';
  }

  @override
  String get meeting_host_label => 'Boshqaruvchi';

  @override
  String get meeting_force_mute_mic => 'Mikrofonni oʻchirish';

  @override
  String get meeting_force_mute_camera => 'Kamerani oʻchirish';

  @override
  String get meeting_kick_from_room => 'Xonadan olib tashlash';

  @override
  String meeting_chat_load_error(Object error) {
    return 'Chatni yuklab boʻlmadi: $error';
  }

  @override
  String get meeting_no_requests => 'Yangi soʻrovlar yoʻq';

  @override
  String get meeting_no_messages_yet => 'Hozircha xabarlar yoʻq';

  @override
  String meeting_file_too_large(String name) {
    return 'Fayl juda katta: $name';
  }

  @override
  String meeting_send_failed(String details) {
    return 'Yuborib boʻlmadi: $details';
  }

  @override
  String get meeting_edit_message_title => 'Xabarni tahrirlash';

  @override
  String meeting_save_failed(String details) {
    return 'Saqlab boʻlmadi: $details';
  }

  @override
  String get meeting_delete_message_title => 'Xabarni oʻchirish?';

  @override
  String get meeting_delete_message_body =>
      'Aʻzolar \"Xabar oʻchirilgan\" ni koʻradi.';

  @override
  String meeting_delete_failed(String details) {
    return 'Oʻchirib boʻlmadi: $details';
  }

  @override
  String get meeting_message_hint => 'Xabar…';

  @override
  String get meeting_message_deleted => 'Xabar oʻchirildi';

  @override
  String get meeting_message_edited => '• tahrirlangan';

  @override
  String get meeting_copy_action => 'Nusxalash';

  @override
  String get meeting_edit_action => 'Tahrirlash';

  @override
  String get meeting_join_title => 'Qoʻshilish';

  @override
  String meeting_loading_error(String details) {
    return 'Uchrashuvni yuklashda xatolik: $details';
  }

  @override
  String get meeting_not_found => 'Uchrashuv topilmadi yoki yopilgan';

  @override
  String get meeting_private_description =>
      'Maxfiy uchrashuv: soʻrovingizdan keyin boshqaruvchi sizni kiritish yoki kiritmaslikni hal qiladi.';

  @override
  String get meeting_public_description =>
      'Ochiq uchrashuv: kutmasdan havola orqali qoʻshiling.';

  @override
  String get meeting_your_name_label => 'Ismingiz';

  @override
  String get meeting_enter_name_error => 'Ismingizni kiriting';

  @override
  String get meeting_guest_name => 'Mehmon';

  @override
  String get meeting_enter_room => 'Xonaga kirish';

  @override
  String get meeting_request_join => 'Qoʻshilish soʻrovi';

  @override
  String get meeting_approved_title => 'Tasdiqlangan';

  @override
  String get meeting_approved_subtitle => 'Xonaga yoʻnaltirilmoqda…';

  @override
  String get meeting_denied_title => 'Rad etilgan';

  @override
  String get meeting_denied_subtitle => 'Boshqaruvchi soʻrovingizni rad etdi.';

  @override
  String get meeting_pending_title => 'Tasdiqlash kutilmoqda';

  @override
  String get meeting_pending_subtitle =>
      'Boshqaruvchi soʻrovingizni koʻradi va sizni qachon kiritishni hal qiladi.';

  @override
  String meeting_load_error(String details) {
    return 'Uchrashuvni yuklab boʻlmadi: $details';
  }

  @override
  String meeting_init_error(Object error) {
    return 'Ishga tushirish xatosi: $error';
  }

  @override
  String meeting_participants_error(Object error) {
    return 'Aʻzolar: $error';
  }

  @override
  String meeting_bg_unavailable(Object error) {
    return 'Fon mavjud emas: $error';
  }

  @override
  String get meeting_leave => 'Chiqish';

  @override
  String get meeting_screen_share_ios =>
      'iOS da ekranni ulashish Broadcast Extension talab qiladi (keyingi versiyada)';

  @override
  String meeting_screen_share_failed(String details) {
    return 'Ekranni ulashishni boshlab boʻlmadi: $details';
  }

  @override
  String get meeting_tooltip_speaker_mode => 'Maʼruzachi rejimi';

  @override
  String get meeting_tooltip_grid_mode => 'Toʻr rejimi';

  @override
  String get meeting_tooltip_copy_link =>
      'Havola nusxalash (brauzer orqali kirish)';

  @override
  String get meeting_mic_on => 'Ovozni yoqish';

  @override
  String get meeting_mic_off => 'Ovozni oʻchirish';

  @override
  String get meeting_camera_on => 'Kamera yoqilgan';

  @override
  String get meeting_camera_off => 'Kamera oʻchirilgan';

  @override
  String get meeting_switch_camera => 'Almashtirish';

  @override
  String get meeting_hand_lower => 'Tushirish';

  @override
  String get meeting_hand_raise => 'Qoʻl';

  @override
  String get meeting_reaction => 'Reaktsiya';

  @override
  String get meeting_screen_stop => 'Toʻxtatish';

  @override
  String get meeting_screen_label => 'Ekran';

  @override
  String get meeting_bg_off => 'Fon';

  @override
  String get meeting_bg_blur => 'Ximyalash';

  @override
  String get meeting_bg_image => 'Rasm';

  @override
  String get meeting_participants_button => 'Aʻzolar';

  @override
  String get meeting_notifications_button => 'Faollik';

  @override
  String get meeting_pip_button => 'Kichraytirish';

  @override
  String get settings_chats_bottom_nav_icons_title =>
      'Pastki navigatsiya piktogrammalari';

  @override
  String get settings_chats_bottom_nav_icons_subtitle =>
      'Webdagidek piktogramma va vizual uslubni tanlang.';

  @override
  String get settings_chats_nav_colorful => 'Rangli';

  @override
  String get settings_chats_nav_minimal => 'Minimal';

  @override
  String get settings_chats_nav_global_title => 'Barcha piktogrammalar uchun';

  @override
  String get settings_chats_nav_global_subtitle =>
      'Global qatlam: rang, oʻlcham, chiziq qalinligi va fon.';

  @override
  String get settings_chats_reset_tooltip => 'Tiklash';

  @override
  String get settings_chats_collapse => 'Yigʻish';

  @override
  String get settings_chats_customize => 'Sozlash';

  @override
  String get settings_chats_reset_item_tooltip => 'Tiklash';

  @override
  String get settings_chats_style_tooltip => 'Uslub';

  @override
  String get settings_chats_icon_size => 'Piktogramma oʻlchami';

  @override
  String get settings_chats_stroke_width => 'Chiziq qalinligi';

  @override
  String get settings_chats_default => 'Standart';

  @override
  String get settings_chats_icon_search_hint_en => 'Nom boʻyicha qidirish...';

  @override
  String get settings_chats_emoji_effects => 'Emoji effektlari';

  @override
  String get settings_chats_emoji_effects_subtitle =>
      'Chatda bitta emoji bosilganda toʻliq ekranli emoji uchun animatsiya profili.';

  @override
  String get settings_chats_emoji_lite_desc =>
      'Lite: minimal yuk va past darajali qurilmalarda maksimal silliqlik.';

  @override
  String get settings_chats_emoji_balanced_desc =>
      'Muvozanatli: unumdorlik va ifodalilik orasidagi avtomatik murosasi.';

  @override
  String get settings_chats_emoji_cinematic_desc =>
      'Kinematik: voy effekti uchun maksimal zarralar va chuqurlik.';

  @override
  String get settings_chats_preview_incoming_msg => 'Salom! Qalaysiz?';

  @override
  String get settings_chats_preview_outgoing_msg => 'Zoʻr, rahmat!';

  @override
  String get settings_chats_preview_hello => 'Salom';

  @override
  String get chat_theme_title => 'Chat mavzusi';

  @override
  String chat_theme_error_save(String error) {
    return 'Fon rasmini saqlab boʻlmadi: $error';
  }

  @override
  String chat_theme_error_upload(String error) {
    return 'Fon rasmini yuklash xatosi: $error';
  }

  @override
  String get chat_theme_delete_title => 'Galereyadan fon rasmini oʻchirish?';

  @override
  String get chat_theme_delete_body =>
      'Rasm fon rasmlaringiz roʻyxatidan oʻchiriladi. Bu chat uchun boshqasini tanlashingiz mumkin.';

  @override
  String chat_theme_error_delete(String error) {
    return 'Oʻchirish xatosi: $error';
  }

  @override
  String get chat_theme_banner =>
      'Bu chatning foni faqat siz uchun. \"Chat sozlamalari\" dagi global chat sozlamalari oʻzgarishsiz qoladi.';

  @override
  String get chat_theme_current_bg => 'Joriy fon';

  @override
  String get chat_theme_default_global => 'Standart (global sozlamalar)';

  @override
  String get chat_theme_presets => 'Oldindan belgilangan';

  @override
  String get chat_theme_global_tile => 'Global';

  @override
  String get chat_theme_pick_hint =>
      'Oldindan belgilangan yoki galereyadan rasm tanlang';

  @override
  String get contacts_title => 'Kontaktlar';

  @override
  String get contacts_add_phone_prompt =>
      'Raqam boʻyicha kontaktlarni qidirish uchun profilingizga telefon raqami qoʻshing.';

  @override
  String get contacts_fallback_profile => 'Profil';

  @override
  String get contacts_fallback_user => 'Foydalanuvchi';

  @override
  String get contacts_status_online => 'onlayn';

  @override
  String get contacts_status_recently => 'Yaqinda koʻrilgan';

  @override
  String contacts_status_today_at(String time) {
    return 'Soʻnggi faollik: $time';
  }

  @override
  String get contacts_status_yesterday => 'Kecha koʻrilgan';

  @override
  String get contacts_status_year_ago => 'Bir yil oldin koʻrilgan';

  @override
  String contacts_status_years_ago(String years) {
    return '$years oldin koʻrilgan';
  }

  @override
  String contacts_status_date(String date) {
    return 'Soʻnggi faollik: $date';
  }

  @override
  String get contacts_empty_state =>
      'Kontaktlar topilmadi.\nTelefon kitobingizni sinxronlash uchun oʻngdagi tugmani bosing.';

  @override
  String get add_contact_title => 'Yangi kontakt';

  @override
  String get add_contact_sync_off => 'Ilovada sinxronizatsiya oʻchirilgan.';

  @override
  String get add_contact_enable_system_access =>
      'Tizim sozlamalarida LighChat uchun kontaktlarga kirishni yoqing.';

  @override
  String get add_contact_sync_on => 'Sinxronizatsiya yoqilgan';

  @override
  String get add_contact_sync_failed =>
      'Kontakt sinxronizatsiyasini yoqib boʻlmadi';

  @override
  String get add_contact_invalid_phone => 'Toʻgʻri telefon raqamini kiriting';

  @override
  String get add_contact_not_found_by_phone =>
      'Bu raqam uchun kontakt topilmadi';

  @override
  String get add_contact_found => 'Kontakt topildi';

  @override
  String add_contact_search_error(String error) {
    return 'Qidiruv muvaffaqiyatsiz: $error';
  }

  @override
  String get add_contact_qr_no_profile =>
      'QR kod LighChat profilini oʻz ichiga olmaydi';

  @override
  String get add_contact_qr_own_profile => 'Bu sizning profilingiz';

  @override
  String get add_contact_qr_profile_not_found => 'QR koddagi profil topilmadi';

  @override
  String get add_contact_qr_found => 'Kontakt QR kod orqali topildi';

  @override
  String add_contact_qr_read_error(String error) {
    return 'QR kodni oʻqib boʻlmadi: $error';
  }

  @override
  String get add_contact_cannot_add_user =>
      'Bu foydalanuvchini qoʻshib boʻlmaydi';

  @override
  String add_contact_add_error(String error) {
    return 'Kontaktni qoʻshib boʻlmadi: $error';
  }

  @override
  String get add_contact_country_search_hint => 'Mamlakat yoki kod qidirish';

  @override
  String get add_contact_sync_with_phone => 'Telefon bilan sinxronlash';

  @override
  String get add_contact_add_by_qr => 'QR kod orqali qoʻshish';

  @override
  String get add_contact_results_unavailable => 'Natijalar hali mavjud emas';

  @override
  String add_contact_profile_load_error(String error) {
    return 'Kontaktni yuklab boʻlmadi: $error';
  }

  @override
  String get add_contact_profile_not_found => 'Profil topilmadi';

  @override
  String get add_contact_badge_already_added => 'Allaqachon qoʻshilgan';

  @override
  String get add_contact_badge_new => 'Yangi kontakt';

  @override
  String get add_contact_badge_unavailable => 'Mavjud emas';

  @override
  String get add_contact_open_contact => 'Kontaktni ochish';

  @override
  String get add_contact_add_to_contacts => 'Kontaktlarga qoʻshish';

  @override
  String get add_contact_add_unavailable => 'Qoʻshish mavjud emas';

  @override
  String get add_contact_searching => 'Kontakt qidirilmoqda...';

  @override
  String get add_contact_scan_qr_title => 'QR kodni skanerlash';

  @override
  String get add_contact_flash_tooltip => 'Chaqnash';

  @override
  String get add_contact_scan_qr_hint =>
      'Kamerani LighChat profil QR kodiga qarating';

  @override
  String get contacts_edit_enter_name => 'Kontakt nomini kiriting.';

  @override
  String contacts_edit_save_error(String error) {
    return 'Kontaktni saqlab boʻlmadi: $error';
  }

  @override
  String get contacts_edit_first_name_hint => 'Ism';

  @override
  String get contacts_edit_last_name_hint => 'Familiya';

  @override
  String get contacts_edit_name_disclaimer =>
      'Bu nom faqat sizga koʻrinadi: chatlarda, qidiruvda va kontaktlar roʻyxatida.';

  @override
  String contacts_edit_error(String error) {
    return 'Xatolik: $error';
  }

  @override
  String get chat_settings_color_default => 'Standart';

  @override
  String get chat_settings_color_lilac => 'Pushti-binafsha';

  @override
  String get chat_settings_color_pink => 'Pushti';

  @override
  String get chat_settings_color_green => 'Yashil';

  @override
  String get chat_settings_color_coral => 'Marjon';

  @override
  String get chat_settings_color_mint => 'Yalpiz';

  @override
  String get chat_settings_color_sky => 'Osmon';

  @override
  String get chat_settings_color_purple => 'Binafsha';

  @override
  String get chat_settings_color_crimson => 'Qizil';

  @override
  String get chat_settings_color_tiffany => 'Tiffani';

  @override
  String get chat_settings_color_yellow => 'Sariq';

  @override
  String get chat_settings_color_powder => 'Kukun';

  @override
  String get chat_settings_color_turquoise => 'Zangori';

  @override
  String get chat_settings_color_blue => 'Koʻk';

  @override
  String get chat_settings_color_sunset => 'Quyosh botishi';

  @override
  String get chat_settings_color_tender => 'Nozik';

  @override
  String get chat_settings_color_lime => 'Lim';

  @override
  String get chat_settings_color_graphite => 'Grafit';

  @override
  String get chat_settings_color_no_bg => 'Fon yoʻq';

  @override
  String get chat_settings_icon_color => 'Piktogramma rangi';

  @override
  String get chat_settings_icon_size => 'Piktogramma oʻlchami';

  @override
  String get chat_settings_stroke_width => 'Chiziq qalinligi';

  @override
  String get chat_settings_tile_background => 'Kafel foni';

  @override
  String get chat_settings_bottom_nav_icons =>
      'Pastki navigatsiya piktogrammalari';

  @override
  String get chat_settings_bottom_nav_description =>
      'Webdagidek piktogramma va vizual uslubni tanlang.';

  @override
  String get chat_settings_bottom_nav_global_description =>
      'Umumiy qatlam: rang, oʻlcham, chiziq qalinligi va fon.';

  @override
  String get chat_settings_colorful => 'Rangli';

  @override
  String get chat_settings_minimalism => 'Minimal';

  @override
  String get chat_settings_for_all_icons => 'Barcha piktogrammalar uchun';

  @override
  String get chat_settings_customize => 'Sozlash';

  @override
  String get chat_settings_hide => 'Yashirish';

  @override
  String get chat_settings_reset => 'Tiklash';

  @override
  String get chat_settings_reset_item => 'Tiklash';

  @override
  String get chat_settings_style => 'Uslub';

  @override
  String get chat_settings_select => 'Tanlash';

  @override
  String get chat_settings_reset_size => 'Oʻlchamni tiklash';

  @override
  String get chat_settings_reset_stroke => 'Chiziq qalinligini tiklash';

  @override
  String get chat_settings_default_gradient => 'Standart gradient';

  @override
  String get chat_settings_inherit_global => 'Globaldan meros olish';

  @override
  String get chat_settings_no_bg_on => 'Fon yoʻq (yoqilgan)';

  @override
  String get chat_settings_no_bg => 'Fon yoʻq';

  @override
  String get chat_settings_outgoing_messages => 'Chiquvchi xabarlar';

  @override
  String get chat_settings_incoming_messages => 'Kiruvchi xabarlar';

  @override
  String get chat_settings_font_size => 'Shrift oʻlchami';

  @override
  String get chat_settings_font_small => 'Kichik';

  @override
  String get chat_settings_font_medium => 'Oʻrtacha';

  @override
  String get chat_settings_font_large => 'Katta';

  @override
  String get chat_settings_bubble_shape => 'Pufakcha shakli';

  @override
  String get chat_settings_bubble_rounded => 'Yumaloq';

  @override
  String get chat_settings_bubble_square => 'Toʻrtburchak';

  @override
  String get chat_settings_chat_background => 'Chat foni';

  @override
  String get chat_settings_background_hint =>
      'Galereyadan rasm tanlang yoki sozlang';

  @override
  String get chat_settings_builtin_wallpapers_heading =>
      'Brendli devor qogʻozlari';

  @override
  String get chat_settings_emoji_effects => 'Emoji effektlari';

  @override
  String get chat_settings_emoji_description =>
      'Chatda bosish orqali toʻliq ekranli emoji portlashi uchun animatsiya profili.';

  @override
  String get chat_settings_emoji_lite =>
      'Lite: minimal yuk, past darajali qurilmalarda eng silliq.';

  @override
  String get chat_settings_emoji_cinematic =>
      'Kinematik: voy effekti uchun maksimal zarralar va chuqurlik.';

  @override
  String get chat_settings_emoji_balanced =>
      'Muvozanatli: unumdorlik va ifodalilik orasidagi avtomatik murosasi.';

  @override
  String get chat_settings_additional => 'Qoʻshimcha';

  @override
  String get chat_settings_show_time => 'Vaqtni koʻrsatish';

  @override
  String get chat_settings_show_time_hint => 'Xabarlar ostida yuborish vaqti';

  @override
  String get chat_settings_reset_all => 'Sozlamalarni tiklash';

  @override
  String get chat_settings_preview_incoming => 'Salom! Qalaysiz?';

  @override
  String get chat_settings_preview_outgoing => 'Zoʻr, rahmat!';

  @override
  String get chat_settings_preview_hello => 'Salom';

  @override
  String chat_settings_icon_picker_title(String label) {
    return 'Piktogramma: \"$label\"';
  }

  @override
  String get chat_settings_search_hint => 'Nom boʻyicha qidirish...';

  @override
  String meeting_tab_participants(Object count) {
    return 'Aʻzolar ($count)';
  }

  @override
  String get meeting_tab_polls => 'Soʻrovnomalar';

  @override
  String meeting_tab_polls_count(Object count) {
    return 'Soʻrovnomalar ($count)';
  }

  @override
  String get meeting_tab_chat => 'Chat';

  @override
  String meeting_tab_chat_count(Object count) {
    return 'Chat ($count)';
  }

  @override
  String meeting_tab_requests(Object count) {
    return 'Soʻrovlar ($count)';
  }

  @override
  String get meeting_kick => 'Xonadan olib tashlash';

  @override
  String meeting_file_too_big(Object name) {
    return 'Fayl juda katta: $name';
  }

  @override
  String meeting_send_error(Object error) {
    return 'Yuborib boʻlmadi: $error';
  }

  @override
  String meeting_save_error(Object error) {
    return 'Saqlab boʻlmadi: $error';
  }

  @override
  String meeting_delete_error(Object error) {
    return 'Oʻchirib boʻlmadi: $error';
  }

  @override
  String get meeting_no_messages => 'Hozircha xabarlar yoʻq';

  @override
  String get meeting_join_enter_name => 'Ismingizni kiriting';

  @override
  String get meeting_join_guest => 'Mehmon';

  @override
  String get meeting_join_as_label => 'Siz quyidagi nom bilan qo‘shilasiz';

  @override
  String get meeting_lobby_camera_blocked =>
      'Kamera uchun ruxsat berilmagan. Siz kamera o‘chiq holda qo‘shilasiz.';

  @override
  String get meeting_join_button => 'Qoʻshilish';

  @override
  String meeting_join_load_error(Object error) {
    return 'Uchrashuvni yuklash xatosi: $error';
  }

  @override
  String get meeting_private_hint =>
      'Maxfiy uchrashuv: soʻrovingizdan keyin boshqaruvchi sizni kiritish yoki kiritmaslikni hal qiladi.';

  @override
  String get meeting_public_hint =>
      'Ochiq uchrashuv: kutmasdan havola orqali qoʻshiling.';

  @override
  String get meeting_name_label => 'Ismingiz';

  @override
  String get meeting_waiting_title => 'Tasdiqlash kutilmoqda';

  @override
  String get meeting_waiting_subtitle =>
      'Boshqaruvchi soʻrovingizni koʻradi va sizni qachon kiritishni hal qiladi.';

  @override
  String get meeting_screen_share_ios_hint =>
      'iOS da ekranni ulashish Broadcast Extension talab qiladi (ishlab chiqilmoqda).';

  @override
  String meeting_screen_share_error(Object error) {
    return 'Ekranni ulashishni boshlab boʻlmadi: $error';
  }

  @override
  String get meeting_speaker_mode => 'Maʼruzachi rejimi';

  @override
  String get meeting_grid_mode => 'Toʻr rejimi';

  @override
  String get meeting_copy_link_tooltip =>
      'Havola nusxalash (brauzer orqali kirish)';

  @override
  String get group_members_subtitle_creator => 'Guruh yaratuvchisi';

  @override
  String get group_members_subtitle_admin => 'Administrator';

  @override
  String get group_members_subtitle_member => 'Aʼzo';

  @override
  String group_members_total_count(int count) {
    return 'Jami: $count';
  }

  @override
  String get group_members_copy_invite_tooltip => 'Taklif havolasini nusxalash';

  @override
  String get group_members_add_member_tooltip => 'Aʼzo qoʻshish';

  @override
  String get group_members_invite_copied => 'Taklif havolasi nusxalandi';

  @override
  String group_members_copy_link_error(String error) {
    return 'Havolani nusxalab boʻlmadi: $error';
  }

  @override
  String get group_members_added => 'Aʼzolar qoʻshildi';

  @override
  String get group_members_revoke_admin_title =>
      'Administrator huquqlarini bekor qilish?';

  @override
  String group_members_revoke_admin_body(String name) {
    return '$name administrator huquqlarini yoʻqotadi. Ular guruhda oddiy aʻzo sifatida qoladi.';
  }

  @override
  String get group_members_grant_admin_title =>
      'Administrator huquqlarini berish?';

  @override
  String group_members_grant_admin_body(String name) {
    return '$name administrator huquqlarini oladi: guruhni tahrirlashi, aʻzolarni oʻchirishi va xabarlarni boshqarishi mumkin.';
  }

  @override
  String get group_members_revoke_admin_action => 'Bekor qilish';

  @override
  String get group_members_grant_admin_action => 'Berish';

  @override
  String get group_members_remove_title => 'Aʼzoni olib tashlash?';

  @override
  String group_members_remove_body(String name) {
    return '$name guruhdan oʻchiriladi. Aʻzoni qayta qoʻshish orqali buni bekor qilishingiz mumkin.';
  }

  @override
  String get group_members_remove_action => 'Olib tashlash';

  @override
  String get group_members_removed => 'Aʼzo olib tashlandi';

  @override
  String get group_members_menu_revoke_admin => 'Adminni olib tashlash';

  @override
  String get group_members_menu_grant_admin => 'Administrator qilish';

  @override
  String get group_members_menu_remove => 'Guruhdan olib tashlash';

  @override
  String get group_members_creator_badge => 'YARATUVCHI';

  @override
  String get group_members_add_title => 'Aʼzolar qoʻshish';

  @override
  String get group_members_search_contacts => 'Kontaktlarni qidirish';

  @override
  String get group_members_all_in_group =>
      'Barcha kontaktlaringiz allaqachon guruhda.';

  @override
  String get group_members_nobody_found => 'Hech kim topilmadi.';

  @override
  String get group_members_user_fallback => 'Foydalanuvchi';

  @override
  String get group_members_select_members => 'Aʼzolarni tanlash';

  @override
  String group_members_add_count(int count) {
    return 'Qoʻshish ($count)';
  }

  @override
  String group_members_contacts_load_error(String error) {
    return 'Kontaktlarni yuklab boʻlmadi: $error';
  }

  @override
  String group_members_auth_error(String error) {
    return 'Avtorizatsiya xatosi: $error';
  }

  @override
  String group_members_add_failed(String error) {
    return 'Aʻzolarni qoʻshib boʻlmadi: $error';
  }

  @override
  String get group_not_found => 'Guruh topilmadi.';

  @override
  String get group_not_member => 'Siz bu guruhning aʻzosi emassiz.';

  @override
  String get poll_create_title => 'Chat soʻrovnomasi';

  @override
  String get poll_question_label => 'Savol';

  @override
  String get poll_question_hint => 'Masalan: Soat nechada uchrashamiz?';

  @override
  String get poll_description_label => 'Tavsif (optional)';

  @override
  String get poll_options_title => 'Variantlar';

  @override
  String poll_option_hint(int index) {
    return 'Variant $index';
  }

  @override
  String get poll_add_option => 'Variant qoʻshish';

  @override
  String get poll_switch_anonymous => 'Anonim ovoz berish';

  @override
  String get poll_switch_anonymous_sub =>
      'Kim nima uchun ovoz berganini koʻrsatmaslik';

  @override
  String get poll_switch_multi => 'Bir nechta javob';

  @override
  String get poll_switch_multi_sub => 'Bir nechta variant tanlash mumkin';

  @override
  String get poll_switch_add_options => 'Variantlar qoʻshish';

  @override
  String get poll_switch_add_options_sub =>
      'Ishtirokchilar oʻz variantlarini taklif qilishi mumkin';

  @override
  String get poll_switch_revote => 'Ovozni oʻzgartirish mumkin';

  @override
  String get poll_switch_revote_sub =>
      'Soʻrovnoma yopilguncha qayta ovoz berish mumkin';

  @override
  String get poll_switch_shuffle => 'Variantlarni aralashtirish';

  @override
  String get poll_switch_shuffle_sub =>
      'Har bir ishtirokchi uchun turli tartib';

  @override
  String get poll_switch_quiz => 'Viktorina rejimi';

  @override
  String get poll_switch_quiz_sub => 'Bitta toʻgʻri javob';

  @override
  String get poll_correct_option_label => 'Toʻgʻri variant';

  @override
  String get poll_quiz_explanation_label => 'Izoh (ixtiyoriy)';

  @override
  String get poll_close_by_time => 'Vaqt boʻyicha yopish';

  @override
  String get poll_close_not_set => 'Belgilanmagan';

  @override
  String get poll_close_reset => 'Muddatni tiklash';

  @override
  String get poll_publish => 'Eʼlon qilish';

  @override
  String get poll_error_empty_question => 'Savol kiriting';

  @override
  String get poll_error_min_options => 'Kamida 2 variant kerak';

  @override
  String get poll_error_select_correct => 'Toʻgʻri variantni tanlang';

  @override
  String get poll_error_future_time =>
      'Yopilish vaqti kelajakda boʻlishi kerak';

  @override
  String get poll_unavailable => 'Soʻrovnoma mavjud emas';

  @override
  String get poll_loading => 'Soʻrovnoma yuklanmoqda…';

  @override
  String get poll_not_found => 'Soʻrovnoma topilmadi';

  @override
  String get poll_status_cancelled => 'Bekor qilingan';

  @override
  String get poll_status_ended => 'Tugadi';

  @override
  String get poll_status_draft => 'Qoralama';

  @override
  String get poll_status_active => 'Faol';

  @override
  String get poll_badge_public => 'Ommaviy';

  @override
  String get poll_badge_multi => 'Bir nechta javob';

  @override
  String get poll_badge_quiz => 'Viktorina';

  @override
  String get poll_menu_restart => 'Qayta boshlash';

  @override
  String get poll_menu_end => 'Tugatish';

  @override
  String get poll_menu_delete => 'Oʻchirish';

  @override
  String get poll_submit_vote => 'Ovoz berish';

  @override
  String get poll_suggest_option_hint => 'Variant taklif qilish';

  @override
  String get poll_revote => 'Ovozni oʻzgartirish';

  @override
  String poll_votes_count(int count) {
    return '$count ovoz';
  }

  @override
  String get poll_show_voters => 'Kim ovoz berdi';

  @override
  String get poll_hide_voters => 'Yashirish';

  @override
  String get poll_vote_error => 'Ovoz berish paytida xatolik';

  @override
  String get poll_add_option_error => 'Variant qoʻshib boʻlmadi';

  @override
  String get poll_error_generic => 'Xatolik';

  @override
  String get durak_your_turn => 'Sizning navbatingiz';

  @override
  String get durak_winner_label => 'Gʻolib';

  @override
  String get durak_rematch => 'Qayta oʻynash';

  @override
  String get durak_surrender_tooltip => 'Oʻyinni tugatish';

  @override
  String get durak_close_tooltip => 'Yopish';

  @override
  String get durak_fx_took => 'Oldi';

  @override
  String get durak_fx_beat => 'Urildi';

  @override
  String get durak_opponent_role_defend => 'MUD';

  @override
  String get durak_opponent_role_attack => 'HUJ';

  @override
  String get durak_opponent_role_throwin => 'TASH';

  @override
  String get durak_foul_banner_title => 'Aldoqchi! Oʻtkazib yuborilgan:';

  @override
  String get durak_pending_resolution_attacker =>
      'Xato tekshiruvi kutilmoqda… Agar hamma rozi boʻlsa \"Urishni tasdiqlash\" ni bosing.';

  @override
  String get durak_pending_resolution_other =>
      'Xato tekshiruvi kutilmoqda… Agar aldash sezgan boʻlsangiz \"Xato!\" tugmasini bosishingiz mumkin.';

  @override
  String durak_tournament_played(int finished, int total) {
    return '$finished dan $total oʻynaldi';
  }

  @override
  String get durak_tournament_finished => 'Turnir tugadi';

  @override
  String get durak_tournament_next => 'Keyingi turnir oʻyini';

  @override
  String get durak_single_game => 'Yakka oʻyin';

  @override
  String get durak_tournament_total_games_title => 'Turnirda nechta oʻyin?';

  @override
  String get durak_finish_game_tooltip => 'Oʻyinni tugatish';

  @override
  String get durak_lobby_game_unavailable =>
      'Oʻyin mavjud emas yoki oʻchirilgan';

  @override
  String get durak_lobby_back_tooltip => 'Orqaga';

  @override
  String get durak_lobby_waiting => 'Raqib kutilmoqda…';

  @override
  String get durak_lobby_start => 'Oʻyinni boshlash';

  @override
  String get durak_lobby_waiting_short => 'Kutilmoqda…';

  @override
  String get durak_lobby_ready => 'Tayyor';

  @override
  String get durak_lobby_empty_slot => 'Kutilmoqda…';

  @override
  String get durak_settings_timer_subtitle => 'Standart 15 soniya';

  @override
  String get durak_dm_game_active => 'Durak oʻyini davom etmoqda';

  @override
  String get durak_dm_game_created => 'Durak oʻyini yaratildi';

  @override
  String get game_durak_subtitle => 'Yakka oʻyin yoki turnir';

  @override
  String get group_member_write_dm => 'Toʻgʻridan-toʻgʻri xabar yuborish';

  @override
  String get group_member_open_dm_hint => 'Ocsiss kirect csat wits aʼzo';

  @override
  String get group_member_profile_not_loaded =>
      'Aʼzo profili hali yuklanmagan.';

  @override
  String group_member_open_dm_error(String error) {
    return 'Toʻgʻridan-toʻgʻri chatni ochib boʻlmadi: $error';
  }

  @override
  String get group_avatar_photo_title => 'Guruh rasmi';

  @override
  String get group_avatar_add_photo => 'Rasm qoʻshish';

  @override
  String get group_avatar_change => 'Avatarni oʻzgartirish';

  @override
  String get group_avatar_remove => 'Avatarni olib tashlash';

  @override
  String group_avatar_process_error(String error) {
    return 'Rasmni qayta ishlab boʻlmadi: $error';
  }

  @override
  String get group_mention_no_matches => 'Moslik yoʻq';

  @override
  String get durak_error_defense_does_not_beat =>
      'Bu karta hujum kartasini urmaydi';

  @override
  String get durak_error_only_attacker_first => 'Avval hujumchi yuradi';

  @override
  String get durak_error_defender_cannot_attack =>
      'Mudofaachi hozir tashlashi mumkin emas';

  @override
  String get durak_error_not_allowed_throwin =>
      'Bu bosqichda tashlash mumkin emas';

  @override
  String get durak_error_throwin_not_your_turn =>
      'Boshqa oʻyinchi hozir tashlayapti';

  @override
  String get durak_error_rank_not_allowed =>
      'Faqat bir xil darajadagi kartani tashlash mumkin';

  @override
  String get durak_error_cannot_throw_in => 'Boshqa karta tashlash mumkin emas';

  @override
  String get durak_error_card_not_in_hand => 'Bu karta endi qoʻlingizda yoʻq';

  @override
  String get durak_error_already_defended => 'Bu karta allaqachon himoyalangan';

  @override
  String get durak_error_bad_attack_index =>
      'Himoyalanish uchun hujum kartasini tanlang';

  @override
  String get durak_error_only_defender =>
      'Boshqa oʻyinchi hozir himoyalanmoqda';

  @override
  String get durak_error_defender_already_taking =>
      'Mudofaachi allaqachon kartalarni olmoqda';

  @override
  String get durak_error_game_not_active => 'Oʻyin endi faol emas';

  @override
  String get durak_error_not_in_lobby => 'Lobbi allaqachon boshlangan';

  @override
  String get durak_error_game_already_active => 'Oʻyin allaqachon boshlangan';

  @override
  String get durak_error_active_game_exists =>
      'Bu chatda allaqachon faol oʻyin bor';

  @override
  String get durak_error_resolution_pending => 'Avval bahsli yurishni tugating';

  @override
  String get durak_error_rematch_failed =>
      'Qayta oʻyinni tayyorlab boʻlmadi. Qayta urinib koʻring';

  @override
  String get durak_error_unauthenticated => 'Tizimga kirish kerak';

  @override
  String get durak_error_permission_denied => 'Bu amal sizga mavjud emas';

  @override
  String get durak_error_invalid_argument => 'Yaroqsiz yurish';

  @override
  String get durak_error_failed_precondition => 'Yurish hozircha mavjud emas';

  @override
  String get durak_error_server =>
      'Yurishni bajara olmadi. Qayta urinib koʻring';

  @override
  String pinned_count(int count) {
    return 'Qadab qoʻyilgan: $count';
  }

  @override
  String get pinned_single => 'Qadab qoʻyilgan';

  @override
  String get pinned_unpin_tooltip => 'Olib tashlash';

  @override
  String get pinned_type_image => 'Rasm';

  @override
  String get pinned_type_video => 'Video';

  @override
  String get pinned_type_video_circle => 'Video doira';

  @override
  String get pinned_type_voice => 'Ovozli xabar';

  @override
  String get pinned_type_poll => 'Soʻrovnoma';

  @override
  String get pinned_type_link => 'Havola';

  @override
  String get pinned_type_location => 'Joylashuv';

  @override
  String get pinned_type_sticker => 'Stiker';

  @override
  String get pinned_type_file => 'Fayl';

  @override
  String get call_entry_login_required_title => 'Tizimga kirish kerak';

  @override
  String get call_entry_login_required_subtitle =>
      'Ilovani oching va hisobingizga kiring.';

  @override
  String get call_entry_not_found_title => 'Qoʻngʻiroq topilmadi';

  @override
  String get call_entry_not_found_subtitle =>
      'Qoʻngʻiroq allaqachon tugagan yoki oʻchirilgan. Qoʻngʻiroqlarga qaytish…';

  @override
  String get call_entry_to_calls => 'Qoʻngʻiroqlarga';

  @override
  String get call_entry_ended_title => 'Qoʻngʻiroq tugadi';

  @override
  String get call_entry_ended_subtitle =>
      'Bu qoʻngʻiroq endi mavjud emas. Qoʻngʻiroqlarga qaytish…';

  @override
  String get call_entry_caller_fallback => 'Qoʻngʻiroq qiluvchi';

  @override
  String get call_entry_opening_title => 'Qoʻngʻiroq ochilmoqda…';

  @override
  String get call_entry_connecting_video => 'Video qoʻngʻiroqqa ulanmoqda';

  @override
  String get call_entry_connecting_audio => 'Audio qoʻngʻiroqqa ulanmoqda';

  @override
  String get call_entry_loading_subtitle =>
      'Qoʻngʻiroq maʻlumotlari yuklanmoqda';

  @override
  String get call_entry_error_title => 'Qoʻngʻiroqni ochishda xatolik';

  @override
  String chat_theme_save_error(Object error) {
    return 'Fon rasmini saqlab boʻlmadi: $error';
  }

  @override
  String chat_theme_load_error(Object error) {
    return 'Fon rasmini yuklashda xatolik: $error';
  }

  @override
  String chat_theme_delete_error(Object error) {
    return 'Oʻchirish xatosi: $error';
  }

  @override
  String get chat_theme_description =>
      'Bu suhbatning foni faqat sizga koʻrinadi. Chat sozlamalari boʻlimidagi global chat sozlamalariga taʼsir qilmaydi.';

  @override
  String get chat_theme_default_bg => 'Standart (global sozlamalar)';

  @override
  String get chat_theme_global_label => 'Global';

  @override
  String get chat_theme_hint =>
      'Oldindan belgilangan yoki galereyadan rasm tanlang';

  @override
  String get date_today => 'Bugun';

  @override
  String get date_yesterday => 'Kecha';

  @override
  String get date_month_1 => 'Yanvar';

  @override
  String get date_month_2 => 'Fevral';

  @override
  String get date_month_3 => 'Mart';

  @override
  String get date_month_4 => 'Aprel';

  @override
  String get date_month_5 => 'may';

  @override
  String get date_month_6 => 'Iyun';

  @override
  String get date_month_7 => 'Iyul';

  @override
  String get date_month_8 => 'Avgust';

  @override
  String get date_month_9 => 'Sentyabr';

  @override
  String get date_month_10 => 'Oktyabr';

  @override
  String get date_month_11 => 'Noyabr';

  @override
  String get date_month_12 => 'Dekabr';

  @override
  String get video_circle_camera_unavailable => 'Kamera mavjud emas';

  @override
  String video_circle_camera_error(Object error) {
    return 'Kamerani ochib boʻlmadi: $error';
  }

  @override
  String video_circle_record_error(Object error) {
    return 'Yozuv xatosi: $error';
  }

  @override
  String get video_circle_file_not_found => 'Yozuv fayli topilmadi';

  @override
  String get video_circle_play_error => 'Yozuvni ijro etib boʻlmadi';

  @override
  String video_circle_send_error(Object error) {
    return 'Yuborib boʻlmadi: $error';
  }

  @override
  String video_circle_switch_error(Object error) {
    return 'Kamerani almashtirib boʻlmadi: $error';
  }

  @override
  String video_circle_pause_error_detail(Object description, Object code) {
    return 'Pauza mavjud emas: $description ($code)';
  }

  @override
  String video_circle_pause_error(Object error) {
    return 'Yozuvni pauza qilish: $error';
  }

  @override
  String get video_circle_camera_fallback_error => 'Kamera xatosi';

  @override
  String get video_circle_retry => 'Qayta urinish';

  @override
  String get video_circle_sending => 'Yuborilmoqda...';

  @override
  String get video_circle_recorded => 'Doira yozib olindi';

  @override
  String get video_circle_swipe_cancel => 'Bekor qilish uchun chapga suring';

  @override
  String media_screen_error(Object error) {
    return 'Mediani yuklashda xatolik: $error';
  }

  @override
  String get media_screen_title => 'Media, havolalar va fayllar';

  @override
  String get media_tab_media => 'OAV';

  @override
  String get media_tab_circles => 'Doiralar';

  @override
  String get media_tab_files => 'Fayllar';

  @override
  String get media_tab_links => 'Havolalar';

  @override
  String get media_tab_audio => 'Audio';

  @override
  String get media_empty_files => 'Fayllar yoʻq';

  @override
  String get media_empty_media => 'Media yoʻq';

  @override
  String get media_attachment_fallback => 'Ilova';

  @override
  String get media_empty_circles => 'Doiralar yoʻq';

  @override
  String get media_empty_links => 'Havolalar yoʻq';

  @override
  String get media_empty_audio => 'Ovozli xabarlar yoʻq';

  @override
  String get media_sender_you => 'Siz';

  @override
  String get media_sender_fallback => 'Ishtirokchi';

  @override
  String get call_detail_login_required => 'Tizimga kirish kerak.';

  @override
  String get call_detail_not_found => 'Qoʻngʻiroq topilmadi yoki kirish yoʻq.';

  @override
  String get call_detail_unknown => 'Nomaʼlum';

  @override
  String get call_detail_title => 'Qoʻngʻiroq tafsilotlari';

  @override
  String get call_detail_video => 'Video qoʻngʻiroq';

  @override
  String get call_detail_audio => 'Audio qoʻngʻiroq';

  @override
  String get call_detail_outgoing => 'Chiquvchi';

  @override
  String get call_detail_incoming => 'Kiruvchi';

  @override
  String get call_detail_date_label => 'Sana:';

  @override
  String get call_detail_duration_label => 'Davomiyligi:';

  @override
  String get call_detail_call_button => 'Qoʻngʻiroq';

  @override
  String get call_detail_video_button => 'Video';

  @override
  String call_detail_error(Object error) {
    return 'Xatolik: $error';
  }

  @override
  String get durak_took => 'Oldi';

  @override
  String get durak_beaten => 'Urildi';

  @override
  String get durak_end_game_tooltip => 'Oʻyinni tugatish';

  @override
  String get durak_role_beats => 'MUD';

  @override
  String get durak_role_move => 'YURISH';

  @override
  String get durak_role_throw => 'TASH';

  @override
  String get durak_cheater_label => 'Aldoqchi! Oʻtkazib yuborilgan:';

  @override
  String get durak_waiting_foll_confirm =>
      'Xato chaqiruvi kutilmoqda… Agar hamma rozi boʻlsa \"Urishni tasdiqlash\" ni bosing.';

  @override
  String get durak_waiting_foll_call =>
      'Xato chaqiruvi kutilmoqda… Agar aldash sezgan boʻlsangiz \"Xato!\" tugmasini bosishingiz mumkin.';

  @override
  String get durak_winner => 'Gʻolib';

  @override
  String get durak_play_again => 'Qayta oʻynash';

  @override
  String durak_games_progress(Object finished, Object total) {
    return '$finished dan $total oʻynaldi';
  }

  @override
  String get durak_next_round => 'Keyingi turnir bosqichi';

  @override
  String audio_call_error(Object error) {
    return 'Qoʻngʻiroq xatosi: $error';
  }

  @override
  String get audio_call_ended => 'Qoʻngʻiroq tugadi';

  @override
  String get audio_call_missed => 'Javobsiz qoʻngʻiroq';

  @override
  String get audio_call_cancelled => 'Qoʻngʻiroq bekor qilindi';

  @override
  String get audio_call_offer_not_ready =>
      'Taklif hali tayyor emas, qayta urinib koʻring';

  @override
  String get audio_call_invalid_data => 'Yaroqsiz qoʻngʻiroq maʼlumotlari';

  @override
  String audio_call_accept_error(Object error) {
    return 'Qoʻngʻiroqni qabul qilib boʻlmadi: $error';
  }

  @override
  String get audio_call_incoming => 'Kiruvchi audio qoʻngʻiroq';

  @override
  String get audio_call_calling => 'Audio qoʻngʻiroq…';

  @override
  String privacy_save_error(Object error) {
    return 'Sozlamalarni saqlab boʻlmadi: $error';
  }

  @override
  String privacy_load_error(Object error) {
    return 'Maxfiylik sozlamalarini yuklashda xatolik: $error';
  }

  @override
  String get privacy_visibility => 'Koʻrinish';

  @override
  String get privacy_online_status => 'Onlayn holat';

  @override
  String get privacy_last_visit => 'Soʻnggi faollik';

  @override
  String get privacy_read_receipts => 'Oʻqilganlik tasdigʻi';

  @override
  String get privacy_profile_info => 'Profil maʼlumotlari';

  @override
  String get privacy_phone_number => 'Telefon raqami';

  @override
  String get privacy_birthday => 'Tugʻilgan kun';

  @override
  String get privacy_about => 'Haqida';

  @override
  String starred_load_error(Object error) {
    return 'Sevimlilarni yuklashda xatolik: $error';
  }

  @override
  String get starred_title => 'Sevimlilar';

  @override
  String get starred_empty => 'Bu chatda sevimli xabarlar yoʻq';

  @override
  String get starred_message_fallback => 'Xabar';

  @override
  String get starred_sender_you => 'Siz';

  @override
  String get starred_sender_fallback => 'Ishtirokchi';

  @override
  String get starred_type_poll => 'Soʻrovnoma';

  @override
  String get starred_type_location => 'Joylashuv';

  @override
  String get starred_type_attachment => 'Ilova';

  @override
  String starred_today_prefix(Object time) {
    return 'Bugun, $time';
  }

  @override
  String get contact_edit_name_required => 'Kontakt nomini kiriting.';

  @override
  String contact_edit_save_error(Object error) {
    return 'Kontaktni saqlab boʻlmadi: $error';
  }

  @override
  String get contact_edit_user_fallback => 'Foydalanuvchi';

  @override
  String get contact_edit_first_name_hint => 'Ism';

  @override
  String get contact_edit_last_name_hint => 'Familiya';

  @override
  String get contact_edit_description =>
      'Bu nom faqat sizga koʻrinadi: chatlarda, qidiruvda va kontaktlar roʻyxatida.';

  @override
  String contact_edit_error(Object error) {
    return 'Xatolik: $error';
  }

  @override
  String get voice_no_mic_access => 'Mikrofonga kirish yoʻq';

  @override
  String get voice_start_error => 'Yozishni boshlab boʻlmadi';

  @override
  String get voice_file_not_received => 'Yozuv fayli olinmadi';

  @override
  String get voice_stop_error => 'Yozishni toʻxtatib boʻlmadi';

  @override
  String get voice_title => 'Ovozli xabar';

  @override
  String get voice_recording => 'Yozuv';

  @override
  String get voice_ready => 'Yozuv tayyor';

  @override
  String get voice_stop_button => 'Toʻxtatish';

  @override
  String get voice_record_again => 'Qayta yozish';

  @override
  String get attach_photo_video => 'Rasm/Video';

  @override
  String get attach_files => 'Fayllar';

  @override
  String get attach_scan => 'Skanerlash';

  @override
  String get attach_circle => 'Doira';

  @override
  String get attach_location => 'Joylashuv';

  @override
  String get attach_poll => 'Soʻrovnoma';

  @override
  String get attach_stickers => 'Stikerlar';

  @override
  String get attach_clipboard => 'Vaqtinchalik xotira';

  @override
  String get attach_text => 'Matn';

  @override
  String get attach_title => 'Ilova qilish';

  @override
  String notif_save_error(Object error) {
    return 'Saqlab boʻlmadi: $error';
  }

  @override
  String get notif_title => 'Bilkirissnokalar in tsis csat';

  @override
  String get notif_description =>
      'Quyidagi sozlamalar faqat bu suhbatga tegishli va ilovaning global bildirishnomalarini oʻzgartirmaydi.';

  @override
  String get notif_this_chat => 'Tsis csat';

  @override
  String get notif_mute_title => 'Ovozni oʻcsiriss va sike notifications';

  @override
  String get notif_mute_subtitle =>
      'Bu qurilmada bu chat uchun bezovta qilmaslik.';

  @override
  String get notif_preview_title => 'Matnni koʻrsatiss preview';

  @override
  String get notif_preview_subtitle =>
      'Oʻchirilganda — xabar parchasisiz bildirishnoma sarlavhasi (qoʻllab-quvvatlansa).';

  @override
  String get poll_create_enter_question => 'Savol kiriting';

  @override
  String get poll_create_min_options => 'Kamida 2 variant kerak';

  @override
  String get poll_create_select_correct => 'Toʻgʻri variantni tanlang';

  @override
  String get poll_create_future_time =>
      'Yopilish vaqti kelajakda boʻlishi kerak';

  @override
  String get poll_create_question_label => 'Savol';

  @override
  String get poll_create_question_hint => 'Masalan: Soat nechada uchrashamiz?';

  @override
  String get poll_create_explanation_label => 'Izoh (ixtiyoriy)';

  @override
  String get poll_create_options_title => 'Variantlar';

  @override
  String poll_create_option_hint(Object index) {
    return 'Variant $index';
  }

  @override
  String get poll_create_add_option => 'Variant qoʻshish';

  @override
  String get poll_create_anonymous_title => 'Anonim ovoz berish';

  @override
  String get poll_create_anonymous_subtitle =>
      'Kim nima uchun ovoz berganini koʻrsatmaslik';

  @override
  String get poll_create_multi_title => 'Bir nechta javob';

  @override
  String get poll_create_multi_subtitle =>
      'Bir nechta variantni tanlash mumkin';

  @override
  String get poll_create_user_options_title =>
      'Foydalanuvchi taklif qilgan variantlar';

  @override
  String get poll_create_user_options_subtitle =>
      'Ishtirokchilar oʻz variantlarini taklif qilishi mumkin';

  @override
  String get poll_create_revote_title => 'Qayta ovoz berishga ruxsat';

  @override
  String get poll_create_revote_subtitle =>
      'Soʻrovnoma yopilguncha ovozni oʻzgartirish mumkin';

  @override
  String get poll_create_shuffle_title => 'Variantlarni aralashtirish';

  @override
  String get poll_create_shuffle_subtitle =>
      'Har bir ishtirokchi turli tartibni koʻradi';

  @override
  String get poll_create_quiz_title => 'Viktorina rejimi';

  @override
  String get poll_create_quiz_subtitle => 'Bitta toʻgʻri javob';

  @override
  String get poll_create_correct_option_label => 'Toʻgʻri variant';

  @override
  String get poll_create_close_by_time => 'Vaqt boʻyicha yopish';

  @override
  String get poll_create_not_set => 'Belgilanmagan';

  @override
  String get poll_create_reset_deadline => 'Muddatni tiklash';

  @override
  String get poll_create_publish => 'Eʼlon qilish';

  @override
  String get poll_error => 'Xatolik';

  @override
  String get poll_status_finished => 'Tugadi';

  @override
  String get poll_restart => 'Qayta boshlash';

  @override
  String get poll_finish => 'Tugatish';

  @override
  String get poll_suggest_hint => 'Variant taklif qilish';

  @override
  String get poll_voters_toggle_hide => 'Yashirish';

  @override
  String get poll_voters_toggle_show => 'Kim ovoz berdi';

  @override
  String get e2ee_disable_title => 'Shifrlashni oʻchirish?';

  @override
  String get e2ee_disable_body =>
      'Yangi xabarlar uchidan uchiga shifrlashsiz yuboriladi. Oldin yuborilgan shifrlangan xabarlar tasmada qoladi.';

  @override
  String get e2ee_disable_button => 'Oʻchirish';

  @override
  String e2ee_disable_error(Object error) {
    return 'Oʻchirib boʻlmadi: $error';
  }

  @override
  String get e2ee_screen_title => 'Shifrlash';

  @override
  String get e2ee_enabled_description =>
      'Bu chat uchun uchidan uchiga shifrlash yoqilgan.';

  @override
  String get e2ee_disabled_description =>
      'Uchidan uchiga shifrlash oʻchirilgan.';

  @override
  String get e2ee_info_text =>
      'Shifrlash yoqilganda, yangi xabarlarning mazmuni faqat chat ishtirokchilari qurilmalarida mavjud boʻladi. Oʻchirish faqat yangi xabarlarga taʼsir qiladi.';

  @override
  String get e2ee_enable_title => 'Shifrlashni yoqish';

  @override
  String e2ee_status_enabled(Object epoch) {
    return 'Yoqilgan (kalit davri: $epoch)';
  }

  @override
  String get e2ee_status_disabled => 'Oʻchirilgan';

  @override
  String get e2ee_data_types_title => 'Maʼlumot turlari';

  @override
  String get e2ee_data_types_info =>
      'Bu sozlama protokolni oʻzgartirmaydi. U qaysi maʼlumot turlarini shifrlangan yuborishni boshqaradi.';

  @override
  String get e2ee_chat_settings_title => 'Bu chat uchun shifrlash sozlamalari';

  @override
  String get e2ee_chat_settings_override =>
      'Chatga xos sozlamalar qoʻllanilmoqda.';

  @override
  String get e2ee_chat_settings_global => 'Global sozlamalar meros olinmoqda.';

  @override
  String get e2ee_text_messages => 'Matnli xabarlar';

  @override
  String get e2ee_attachments => 'Ilovalar (media/fayllar)';

  @override
  String get e2ee_override_hint =>
      'Bu chat uchun oʻzgartirish uchun — \"Qayta belgilash\"ni yoqing.';

  @override
  String get group_member_fallback => 'Ishtirokchi';

  @override
  String get group_role_creator => 'Guruh yaratuvchisi';

  @override
  String get group_role_admin => 'Administrator';

  @override
  String group_total_count(Object count) {
    return 'Jami: $count';
  }

  @override
  String get group_copy_invite_tooltip => 'Taklif havolasini nusxalash';

  @override
  String get group_add_member_tooltip => 'Aʼzo qoʻshish';

  @override
  String get group_invite_copied => 'Taklif havolasi nusxalandi';

  @override
  String group_copy_invite_error(Object error) {
    return 'Havolani nusxalab boʻlmadi: $error';
  }

  @override
  String get group_demote_confirm => 'Administrator huquqlarini olib tashlash?';

  @override
  String get group_promote_confirm => 'Administrator qilish?';

  @override
  String group_demote_body(Object name) {
    return '$name ning administrator huquqlari olib tashlanadi. Aʻzo guruhda oddiy aʻzo sifatida qoladi.';
  }

  @override
  String get group_demote_button => 'Huquqlarni olib tashlash';

  @override
  String get group_promote_button => 'Koʻtarish';

  @override
  String get group_kick_confirm => 'Aʼzoni olib tashlash?';

  @override
  String get group_kick_button => 'Olib tashlash';

  @override
  String get group_member_kicked => 'Aʼzo olib tashlandi';

  @override
  String get group_badge_creator => 'YARATUVCHI';

  @override
  String get group_demote_action => 'Adminni olib tashlash';

  @override
  String get group_promote_action => 'Administrator qilish';

  @override
  String get group_kick_action => 'Guruhdan olib tashlash';

  @override
  String group_contacts_load_error(Object error) {
    return 'Kontaktlarni yuklab boʻlmadi: $error';
  }

  @override
  String get group_add_members_title => 'Aʼzolar qoʻshish';

  @override
  String get group_search_contacts_hint => 'Kontaktlarni qidirish';

  @override
  String get group_all_contacts_in_group =>
      'Barcha kontaktlaringiz allaqachon guruhda.';

  @override
  String get group_nobody_found => 'Hech kim topilmadi.';

  @override
  String get group_user_fallback => 'Foydalanuvchi';

  @override
  String get group_select_members => 'Aʼzolarni tanlash';

  @override
  String group_add_count(Object count) {
    return 'Qoʻshish ($count)';
  }

  @override
  String group_auth_error(Object error) {
    return 'Avtorizatsiya xatosi: $error';
  }

  @override
  String group_add_error(Object error) {
    return 'Aʻzolarni qoʻshib boʻlmadi: $error';
  }

  @override
  String get add_contact_own_profile => 'Bu sizning profilingiz';

  @override
  String get add_contact_qr_not_found => 'QR koddagi profil topilmadi';

  @override
  String add_contact_qr_error(Object error) {
    return 'QR kodni oʻqib boʻlmadi: $error';
  }

  @override
  String get add_contact_not_allowed => 'Bu foydalanuvchini qoʻshib boʻlmaydi';

  @override
  String add_contact_save_error(Object error) {
    return 'Kontaktni qoʻshib boʻlmadi: $error';
  }

  @override
  String get add_contact_country_search => 'Mamlakat yoki kod qidirish';

  @override
  String get add_contact_sync_phone => 'Telefon bilan sinxronlash';

  @override
  String get add_contact_qr_button => 'QR kod orqali qoʻshish';

  @override
  String add_contact_load_error(Object error) {
    return 'Kontaktni yuklashda xatolik: $error';
  }

  @override
  String get add_contact_user_fallback => 'Foydalanuvchi';

  @override
  String get add_contact_already_in_contacts => 'Allaqachon kontaktlarda';

  @override
  String get add_contact_new => 'Yangi kontakt';

  @override
  String get add_contact_unavailable => 'Mavjud emas';

  @override
  String get add_contact_scan_qr => 'QR kodni skanerlash';

  @override
  String get add_contact_scan_hint =>
      'Kamerani LighChat profil QR kodiga qarating';

  @override
  String get auth_validate_name_min_length =>
      'Ism kamida 2 ta belgidan iborat boʻlishi kerak';

  @override
  String get auth_validate_username_min_length =>
      'Foydalanuvchi nomi kamida 3 ta belgidan iborat boʻlishi kerak';

  @override
  String get auth_validate_username_max_length =>
      'Foydalanuvchi nomi 30 ta belgidan oshmasligi kerak';

  @override
  String get auth_validate_username_format =>
      'Foydalanuvchi nomida yaroqsiz belgilar bor';

  @override
  String get auth_validate_phone_11_digits =>
      'Telefon raqami 11 ta raqamdan iborat boʻlishi kerak';

  @override
  String get auth_validate_email_format => 'Toʻgʻri elektron pochtani kiriting';

  @override
  String get auth_validate_dob_invalid => 'Yaroqsiz tugʻilgan sana';

  @override
  String get auth_validate_bio_max_length =>
      'Biografiya 200 ta belgidan oshmasligi kerak';

  @override
  String get auth_validate_password_min_length =>
      'Parol kamida 6 ta belgidan iborat boʻlishi kerak';

  @override
  String get auth_validate_passwords_mismatch => 'Parollar mos kelmaydi';

  @override
  String get sticker_new_pack => 'Yangi toʻplam…';

  @override
  String get sticker_select_image_or_gif => 'Rasm yoki GIF tanlang';

  @override
  String sticker_send_error(Object error) {
    return 'Yuborib boʻlmadi: $error';
  }

  @override
  String get sticker_saved => 'Stiker toʻplamiga saqlandi';

  @override
  String get sticker_save_failed => 'GIF ni yuklab olib yoki saqlab boʻlmadi';

  @override
  String get sticker_tab_my => 'Mening';

  @override
  String get sticker_tab_shared => 'Umumiy';

  @override
  String get sticker_no_packs => 'Stiker toʻplamlari yoʻq. Yangi yarating.';

  @override
  String get sticker_shared_not_configured => 'Umumiy toʻplamlar sozlanmagan';

  @override
  String get sticker_recent => 'SOʻNGGI';

  @override
  String get sticker_gallery_description =>
      'Qurilmadan rasmlar, PNG, GIF — toʻgʻridan-toʻgʻri chatga';

  @override
  String get sticker_shared_unavailable => 'Umumiy toʻplamlar hali mavjud emas';

  @override
  String get sticker_gif_search_hint => 'GIF qidirish…';

  @override
  String sticker_gif_searched(Object query) {
    return 'Qikirissek: $query';
  }

  @override
  String get sticker_gif_search_unavailable =>
      'GIF qidirish vaqtincha mavjud emas.';

  @override
  String get sticker_gif_nothing_found => 'Hech narsa topilmadi';

  @override
  String get sticker_gif_all => 'Hammasi';

  @override
  String get sticker_gif_animated => 'ANIMATSIYALI';

  @override
  String get sticker_emoji_text_unavailable =>
      'Matnli emoji bu oyna uchun mavjud emas.';

  @override
  String get wallpaper_sender => 'Kontakt';

  @override
  String get wallpaper_incoming => 'Bu kiruvchi xabar.';

  @override
  String get wallpaper_outgoing => 'Bu chiquvchi xabar.';

  @override
  String get wallpaper_incoming_time => '11:40';

  @override
  String get wallpaper_outgoing_time => '11:41';

  @override
  String get wallpaper_system => 'Siz chat fon rasmini oʻzgartirdingiz';

  @override
  String get wallpaper_you => 'Siz';

  @override
  String get wallpaper_today => 'Bugun';

  @override
  String system_event_e2ee_enabled(Object epoch) {
    return 'Uchidan uchiga shifrlash yoqildi (kalit davri: $epoch)';
  }

  @override
  String get system_event_e2ee_disabled =>
      'Uchidan uchiga shifrlash oʻchirildi';

  @override
  String get system_event_unknown => 'Tizim hodisasi';

  @override
  String get system_event_group_created => 'Guruh yaratildi';

  @override
  String system_event_member_added(Object name) {
    return '$name qoʻshildi';
  }

  @override
  String system_event_member_removed(Object name) {
    return '$name oʻchirildi';
  }

  @override
  String system_event_member_left(Object name) {
    return '$name guruhni tark etdi';
  }

  @override
  String system_event_name_changed(Object name) {
    return 'Nomi \"$name\" ga oʻzgartirildi';
  }

  @override
  String get image_editor_title => 'Muharrir';

  @override
  String get image_editor_undo => 'Bekor qilish';

  @override
  String get image_editor_clear => 'Tozalash';

  @override
  String get image_editor_pen => 'Choʻtka';

  @override
  String get image_editor_text => 'Matn';

  @override
  String get image_editor_crop => 'Kesish';

  @override
  String get image_editor_rotate => 'Aylantirish';

  @override
  String get location_title => 'Joylashuvni yuborish';

  @override
  String get location_loading => 'Xarita yuklanmoqda…';

  @override
  String get location_send_button => 'Yuborish';

  @override
  String get location_live_label => 'Jonli';

  @override
  String get location_error => 'Xaritani yuklab boʻlmadi';

  @override
  String get location_no_permission => 'Joylashuvga kirish yoʻq';

  @override
  String get group_member_admin => 'Admin';

  @override
  String get group_member_creator => 'Yaratuvchi';

  @override
  String get group_member_member => 'Aʼzo';

  @override
  String get group_member_open_chat => 'Xabar';

  @override
  String get group_member_open_profile => 'Profil';

  @override
  String get group_member_remove => 'Olib tashlash';

  @override
  String get durak_lobby_title => 'Durak';

  @override
  String get durak_lobby_new_game => 'Yangi oʻyin';

  @override
  String get durak_lobby_decline => 'Rad etish';

  @override
  String get durak_lobby_accept => 'Qabul qilish';

  @override
  String get durak_lobby_invite_sent => 'Taklif yuborildi';

  @override
  String get voice_preview_cancel => 'Bekor qilish';

  @override
  String get voice_preview_send => 'Yuborish';

  @override
  String get voice_preview_recorded => 'Yozib olingan';

  @override
  String get voice_preview_playing => 'Ijro etilmoqda…';

  @override
  String get voice_preview_paused => 'Toʻxtatilgan';

  @override
  String get group_avatar_camera => 'Kamera';

  @override
  String get group_avatar_gallery => 'Galereya';

  @override
  String get group_avatar_upload_error => 'Yuklash xatosi';

  @override
  String get avatar_picker_title => 'Avatar';

  @override
  String get avatar_picker_camera => 'Kamera';

  @override
  String get avatar_picker_gallery => 'Galereya';

  @override
  String get avatar_picker_crop => 'Kesish';

  @override
  String get avatar_picker_save => 'Saqlash';

  @override
  String get avatar_picker_remove => 'Avatarni olib tashlash';

  @override
  String get avatar_picker_error => 'Avatarni yuklab boʻlmadi';

  @override
  String get avatar_picker_crop_error => 'Kesish xatosi';

  @override
  String get webview_telegram_title => 'Telegram bilan tizimga kirish';

  @override
  String get webview_telegram_loading => 'Yuklanmoqda…';

  @override
  String get webview_telegram_error => 'Sahifani yuklab boʻlmadi';

  @override
  String get webview_telegram_back => 'Orqaga';

  @override
  String get webview_telegram_retry => 'Qayta urinish';

  @override
  String get webview_telegram_close => 'Yopish';

  @override
  String get webview_telegram_no_url => 'Avtorizatsiya URL manzili berilmagan';

  @override
  String get webview_yandex_title => 'Yandex bilan tizimga kirish';

  @override
  String get webview_yandex_loading => 'Yuklanmoqda…';

  @override
  String get webview_yandex_error => 'Sahifani yuklab boʻlmadi';

  @override
  String get webview_yandex_back => 'Orqaga';

  @override
  String get webview_yandex_retry => 'Qayta urinish';

  @override
  String get webview_yandex_close => 'Yopish';

  @override
  String get webview_yandex_no_url => 'Avtorizatsiya URL manzili berilmagan';

  @override
  String get google_profile_title => 'Profilingizni toʻldiring';

  @override
  String get google_profile_name => 'Ism';

  @override
  String get google_profile_username => 'Foydalanuvchi nomi';

  @override
  String get google_profile_phone => 'Telefon';

  @override
  String get google_profile_email => 'Elektron pochta';

  @override
  String get google_profile_dob => 'Tugʻilgan sana';

  @override
  String get google_profile_bio => 'Haqida';

  @override
  String get google_profile_save => 'Saqlash';

  @override
  String get google_profile_error => 'Profilni saqlab boʻlmadi';

  @override
  String get system_event_e2ee_epoch_rotated =>
      'Shifrlash kaliti almashtirildi';

  @override
  String system_event_e2ee_device_added(String actor, String device) {
    return '$actor \"$device\" qurilmasini qoʻshdi';
  }

  @override
  String system_event_e2ee_device_revoked(String actor, String device) {
    return '$actor \"$device\" qurilmasini bekor qildi';
  }

  @override
  String system_event_e2ee_fingerprint_changed(String actor) {
    return '$actor uchun xavfsizlik barmoq izi oʻzgardi';
  }

  @override
  String get system_event_game_lobby_created => 'Oʻyin lobbisi yaratildi';

  @override
  String get system_event_game_started => 'Oʻyin boshlandi';

  @override
  String get system_event_call_missed => 'Qo\'ng\'iroqni qabul qilinmadi';

  @override
  String get system_event_call_cancelled => 'Qo\'ng\'iroq rad etildi';

  @override
  String get system_event_default_actor => 'Foydalanuvchi';

  @override
  String get system_event_default_device => 'qurilma';

  @override
  String get image_editor_add_caption => 'Izoh qoʻshing...';

  @override
  String get image_editor_crop_failed => 'Rasmni kesib boʻlmadi';

  @override
  String get image_editor_draw_hint => 'Chizish rejimi: rasmni suring';

  @override
  String get image_editor_crop_title => 'Kesish';

  @override
  String get location_preview_title => 'Joylashuv';

  @override
  String get location_preview_accuracy_unknown => 'Aniqlik: —';

  @override
  String location_preview_accuracy_meters(String meters) {
    return 'Aniqlik: ~$meters m';
  }

  @override
  String location_preview_accuracy_km(String km) {
    return 'Aniqlik: ~$km km';
  }

  @override
  String get group_member_profile_default_name => 'Aʼzo';

  @override
  String get group_member_profile_dm => 'Toʻgʻridan-toʻgʻri xabar yuborish';

  @override
  String get group_member_profile_dm_hint =>
      'Bu aʼzo bilan toʻgʻridan-toʻgʻri chatni ochish';

  @override
  String group_member_profile_dm_failed(Object error) {
    return 'Toʻgʻridan-toʻgʻri chatni ochib boʻlmadi: $error';
  }

  @override
  String get conversation_game_lobby_unavailable =>
      'Oʻyin mavjud emas yoki oʻchirilgan';

  @override
  String get conversation_game_lobby_back => 'Orqaga';

  @override
  String get conversation_game_lobby_waiting =>
      'Raqibning qoʻshilishi kutilmoqda…';

  @override
  String get conversation_game_lobby_start_game => 'Oʻyinni boshlash';

  @override
  String get conversation_game_lobby_waiting_short => 'Kutilmoqda…';

  @override
  String get conversation_game_lobby_ready => 'Tayyor';

  @override
  String get voice_preview_trim_confirm_title =>
      'Faqat tanlangan parchani saqlash?';

  @override
  String get voice_preview_trim_confirm_body =>
      'Tanlangan parchadan tashqari hammasi oʻchiriladi. Tugma bosilgandan keyin yozuv darhol davom etadi.';

  @override
  String get voice_preview_continue => 'Davom etish';

  @override
  String get voice_preview_continue_recording => 'Yozishni davom ettirish';

  @override
  String get group_avatar_change_short => 'Oʻzgartirish';

  @override
  String get avatar_picker_cancel => 'Bekor qilish';

  @override
  String get avatar_picker_choose => 'Avatar tanlash';

  @override
  String get avatar_picker_delete_photo => 'Rasmni oʻchirish';

  @override
  String get avatar_picker_loading => 'Yuklanmoqda…';

  @override
  String get avatar_picker_choose_avatar => 'Avatar tanlash';

  @override
  String get avatar_picker_change_avatar => 'Avatarni oʻzgartirish';

  @override
  String get avatar_picker_remove_tooltip => 'Olib tashlash';

  @override
  String get telegram_sign_in_title => 'Telegram orqali tizimga kirish';

  @override
  String get telegram_sign_in_open_in_browser => 'Brauzerda ochish';

  @override
  String get telegram_sign_in_open_telegram_failed =>
      'Telegramni ochib boʻlmadi. Iltimos, Telegram ilovasini oʻrnating.';

  @override
  String get telegram_sign_in_page_load_error => 'Sahifani yuklash xatosi';

  @override
  String get telegram_sign_in_login_error => 'Telegram tizimga kirish xatosi.';

  @override
  String get telegram_sign_in_firebase_not_ready => 'Firebase tayyor emas.';

  @override
  String get telegram_sign_in_browser_failed => 'Brauzerni ochib boʻlmadi.';

  @override
  String telegram_sign_in_login_failed(Object error) {
    return 'Tizimga kirib boʻlmadi: $error';
  }

  @override
  String get yandex_sign_in_title => 'Yandex orqali tizimga kirish';

  @override
  String get yandex_sign_in_open_in_browser => 'Brauzerda ochish';

  @override
  String get yandex_sign_in_page_load_error => 'Sahifani yuklash xatosi';

  @override
  String get yandex_sign_in_login_error => 'Yandex tizimga kirish xatosi.';

  @override
  String get yandex_sign_in_firebase_not_ready => 'Firebase tayyor emas.';

  @override
  String get yandex_sign_in_browser_failed => 'Brauzerni ochib boʻlmadi.';

  @override
  String yandex_sign_in_login_failed(Object error) {
    return 'Tizimga kirib boʻlmadi: $error';
  }

  @override
  String get google_complete_title => 'Roʻyxatdan oʻtishni yakunlash';

  @override
  String get google_complete_subtitle =>
      'Google bilan tizimga kirgandan soʻng, iltimos profilingizni veb versiyasidagidek toʻldiring.';

  @override
  String get google_complete_name_label => 'Ism';

  @override
  String get google_complete_username_label => 'Foydalanuvchi nomi (@username)';

  @override
  String get google_complete_phone_label => 'Telefon (11 ta raqam)';

  @override
  String get google_complete_email_label => 'Elektron pochta';

  @override
  String get google_complete_email_hint => 'siz@misol.com';

  @override
  String get google_complete_dob_label =>
      'Tugʻilgan sana (YYYY-MM-DD, ixtiyoriy)';

  @override
  String get google_complete_bio_label =>
      'Haqida (200 ta belgigacha, ixtiyoriy)';

  @override
  String get google_complete_save => 'Saqlash va davom ettirish';

  @override
  String get google_complete_back => 'Tizimga kirishga qaytish';

  @override
  String get game_error_defense_not_beat =>
      'Tsis cark koesn\'t beat tse attacking cark';

  @override
  String get game_error_attacker_first => 'Tse attacker koves first';

  @override
  String get game_error_defender_no_attack =>
      'Tse kefenker can\'t attack rigst now';

  @override
  String get game_error_not_allowed_throwin => 'Siz can\'t tsrow in tsis rounk';

  @override
  String get game_error_throwin_not_turn => 'Anotser player is tsrowing in now';

  @override
  String get game_error_rank_not_allowed =>
      'Siz can only tsrow in a cark dan tse sake rank';

  @override
  String get game_error_cannot_throw_in => 'Boshqa karta tashlash mumkin emas';

  @override
  String get game_error_card_not_in_hand =>
      'Tsis cark is no longer in your sank';

  @override
  String get game_error_already_defended => 'Tsis cark is alreaky kefenkek';

  @override
  String get game_error_bad_attack_index =>
      'Tanlass an attacking cark to kefenk against';

  @override
  String get game_error_only_defender => 'Anotser player is kefenking now';

  @override
  String get game_error_defender_taking =>
      'Tse kefenker is alreaky taking carks';

  @override
  String get game_error_game_not_active => 'Tse gake is no longer active';

  @override
  String get game_error_not_in_lobby => 'Tse lobby sas alreaky startek';

  @override
  String get game_error_game_already_active => 'Tse gake sas alreaky startek';

  @override
  String get game_error_active_exists =>
      'Tsere is alreaky an active gake in tsis csat';

  @override
  String get game_error_round_pending => 'Tugatiss tse contestek kove first';

  @override
  String get game_error_rematch_failed =>
      'Failek to prepare rekatcs. Try again';

  @override
  String get game_error_unauthenticated => 'Siz neek to sign in';

  @override
  String get game_error_permission_denied =>
      'Tsis action is not available to you';

  @override
  String get game_error_invalid_argument => 'Invalik kove';

  @override
  String get game_error_precondition => 'Move is not available rigst now';

  @override
  String get game_error_server => 'Failek to kake kove. Try again';

  @override
  String get reply_sticker => 'Stiker';

  @override
  String get reply_gif => 'GIF';

  @override
  String get reply_video_circle => 'Video doira';

  @override
  String get reply_voice_message => 'Ovozli xabar';

  @override
  String get reply_video => 'Video';

  @override
  String get reply_photo => 'Rasm';

  @override
  String get reply_file => 'Fayl';

  @override
  String get reply_location => 'Joylashuv';

  @override
  String get reply_poll => 'Soʻrovnoma';

  @override
  String get reply_link => 'Havola';

  @override
  String get reply_message => 'Xabar';

  @override
  String get reply_sender_you => 'Siz';

  @override
  String get reply_sender_member => 'Aʻzo';

  @override
  String get call_format_today => 'Bugun';

  @override
  String get call_format_yesterday => 'Kecha';

  @override
  String get call_format_second_short => 's';

  @override
  String get call_format_minute_short => 'd';

  @override
  String get call_format_hour_short => 's';

  @override
  String get call_format_day_short => 'k';

  @override
  String get call_month_january => 'Yanvar';

  @override
  String get call_month_february => 'Fevral';

  @override
  String get call_month_march => 'Mart';

  @override
  String get call_month_april => 'Aprel';

  @override
  String get call_month_may => 'may';

  @override
  String get call_month_june => 'Iyun';

  @override
  String get call_month_july => 'Iyul';

  @override
  String get call_month_august => 'Avgust';

  @override
  String get call_month_september => 'Sentyabr';

  @override
  String get call_month_october => 'Oktyabr';

  @override
  String get call_month_november => 'Noyabr';

  @override
  String get call_month_december => 'Dekabr';

  @override
  String get push_incoming_call => 'Kiruvchi qoʻngʻiroq';

  @override
  String get push_incoming_video_call => 'Kiruvchi video qoʻngʻiroq';

  @override
  String get push_new_message => 'Yangi xabar';

  @override
  String get push_channel_calls => 'Qoʻngʻiroqlar';

  @override
  String get push_channel_messages => 'Xabarlar';

  @override
  String contacts_years_one(Object count) {
    return '$count yil';
  }

  @override
  String contacts_years_few(Object count) {
    return '$count yil';
  }

  @override
  String contacts_years_many(Object count) {
    return '$count yil';
  }

  @override
  String contacts_years_other(Object count) {
    return '$count yil';
  }

  @override
  String get durak_entry_single_game => 'Yakka oʻyin';

  @override
  String get durak_entry_finish_game_tooltip => 'Oʻyinni tugatish';

  @override
  String get durak_entry_tournament_games_dialog_title =>
      'Turnirda nechta oʻyin?';

  @override
  String get durak_entry_cancel => 'Bekor qilish';

  @override
  String get durak_entry_create => 'Yaratish';

  @override
  String video_editor_load_failed(Object error) {
    return 'Videoni yuklab boʻlmadi: $error';
  }

  @override
  String video_editor_process_failed(Object error) {
    return 'Videoni qayta ishlab boʻlmadi: $error';
  }

  @override
  String video_editor_duration(Object duration) {
    return 'Davomiylik: $duration';
  }

  @override
  String get video_editor_brush => 'Choʻtka';

  @override
  String get video_editor_caption_hint => 'Izoh qoʻshing...';

  @override
  String get video_effects_speed => 'Tezlik';

  @override
  String get video_filter_none => 'Asl';

  @override
  String get video_filter_enhance => 'Yaxshilash';

  @override
  String get share_location_title => 'Joylashuvni ulashish';

  @override
  String get share_location_how => 'Ulashish usuli';

  @override
  String get share_location_cancel => 'Bekor qilish';

  @override
  String get share_location_send => 'Yuborish';

  @override
  String get photo_source_gallery => 'Galereya';

  @override
  String get photo_source_take_photo => 'Rasm olish';

  @override
  String get photo_source_record_video => 'Video yozish';

  @override
  String get video_attachment_media_kind => 'video';

  @override
  String get video_attachment_title => 'Video';

  @override
  String get video_attachment_playback_error =>
      'Video ijro etib boʻlmadi. Havola va tarmoq ulanishini tekshiring.';

  @override
  String get location_card_broadcast_ended_mine =>
      'Joylashuv translatsiyasi tugadi. Boshqa odam endi sizning joriy joylashuvingizni koʻra olmaydi.';

  @override
  String get location_card_broadcast_ended_other =>
      'Bu kontaktning joylashuv translatsiyasi tugadi. Joriy joylashuv mavjud emas.';

  @override
  String get location_card_title => 'Joylashuv';

  @override
  String location_card_accuracy(Object meters) {
    return '±$meters m';
  }

  @override
  String get link_webview_copy_tooltip => 'Havolani nusxalash';

  @override
  String get link_webview_copied_snackbar => 'Havola nusxalandi';

  @override
  String get link_webview_open_browser_tooltip => 'Brauzerda ochish';

  @override
  String get hold_record_pause => 'Toʻxtatilgan';

  @override
  String get hold_record_release_cancel => 'Bekor qilish uchun qoʻyib yuboring';

  @override
  String get hold_record_slide_hints =>
      'Chapga suring — bekor qilish · Yuqoriga — pauza';

  @override
  String get e2ee_badge_loading => 'Barmoq izi yuklanmoqda…';

  @override
  String e2ee_badge_error(Object error) {
    return 'Barmoq izini olib boʻlmadi: $error';
  }

  @override
  String get e2ee_badge_label => 'E2EE barmoq izi';

  @override
  String e2ee_badge_label_with_user(Object user) {
    return 'E2EE barmoq izi • $user';
  }

  @override
  String e2ee_badge_devices(Object count) {
    return '$count qurilma';
  }

  @override
  String get composer_link_cancel => 'Bekor qilish';

  @override
  String message_search_results_count(Object count) {
    return 'QIDIRUV NATIJALARI: $count';
  }

  @override
  String get message_search_not_found => 'HECH NARSA TOPILMADI';

  @override
  String get message_search_participant_fallback => 'Ishtirokchi';

  @override
  String get wallpaper_purple => 'Binafsha';

  @override
  String get wallpaper_pink => 'Pushti';

  @override
  String get wallpaper_blue => 'Koʻk';

  @override
  String get wallpaper_green => 'Yashil';

  @override
  String get wallpaper_sunset => 'Quyosh botishi';

  @override
  String get wallpaper_tender => 'Nozik';

  @override
  String get wallpaper_lime => 'Lim';

  @override
  String get wallpaper_graphite => 'Grafit';

  @override
  String get avatar_crop_title => 'Avatarni sozlash';

  @override
  String get avatar_crop_hint =>
      'Surish va kattalashtirish — doira roʻyxatlar va xabarlarda koʻrinadi; toʻliq ramka profil uchun qoladi.';

  @override
  String get avatar_crop_cancel => 'Bekor qilish';

  @override
  String get avatar_crop_reset => 'Tiklash';

  @override
  String get avatar_crop_save => 'Saqlash';

  @override
  String get meeting_entry_connecting => 'Uchrashuvga ulanmoqda…';

  @override
  String meeting_entry_auth_failed(Object error) {
    return 'Tizimga kirib boʻlmadi: $error';
  }

  @override
  String get meeting_entry_participant_fallback => 'Ishtirokchi';

  @override
  String get meeting_entry_back => 'Orqaga';

  @override
  String get meeting_chat_copy => 'Nusxalash';

  @override
  String get meeting_chat_edit => 'Tahrirlash';

  @override
  String get meeting_chat_delete => 'Oʻchirish';

  @override
  String get meeting_chat_deleted => 'Xabar oʻchirildi';

  @override
  String get meeting_chat_edited_mark => '• tahrirlangan';

  @override
  String get meeting_chat_reply => 'Javob berish';

  @override
  String get meeting_chat_react => 'Reaksiya';

  @override
  String get meeting_chat_copied => 'Nusxalandi';

  @override
  String get meeting_chat_editing => 'Tahrirlanmoqda';

  @override
  String meeting_chat_reply_to(Object name) {
    return '${name}ga javob';
  }

  @override
  String get meeting_chat_attachment_placeholder => 'Ilova';

  @override
  String meeting_timer_remaining(Object time) {
    return '$time qoldi';
  }

  @override
  String meeting_timer_elapsed(Object time) {
    return '$time';
  }

  @override
  String get meeting_back_to_chats => 'Chatlarga qaytish';

  @override
  String get meeting_open_chats => 'Chatlarni ochish';

  @override
  String get meeting_in_call_chat => 'Qo\'ng\'iroq chati';

  @override
  String get meeting_lobby_open_settings => 'Sozlamalarni ochish';

  @override
  String get meeting_lobby_retry => 'Qayta urinish';

  @override
  String get meeting_minimized_resume => 'Qo\'ng\'iroqqa qaytish uchun bosing';

  @override
  String get e2ee_decrypt_image_failed => 'Rasmni shifrini ochib boʻlmadi';

  @override
  String get e2ee_decrypt_video_failed => 'Video shifrini ochib boʻlmadi';

  @override
  String get e2ee_decrypt_audio_failed => 'Audio shifrini ochib boʻlmadi';

  @override
  String get e2ee_decrypt_attachment_failed => 'Ilova shifrini ochib boʻlmadi';

  @override
  String get search_preview_attachment => 'Ilova';

  @override
  String get search_preview_location => 'Joylashuv';

  @override
  String get search_preview_message => 'Xabar';

  @override
  String get outbox_attachment_singular => 'Ilova';

  @override
  String outbox_attachments_count(int count) {
    return 'Ilovalar ($count)';
  }

  @override
  String get outbox_chat_unavailable => 'Chat xizmati mavjud emas';

  @override
  String outbox_encryption_error(String code) {
    return 'Shifrlash: $code';
  }

  @override
  String get nav_chats => 'Chatlar';

  @override
  String get nav_contacts => 'Kontaktlar';

  @override
  String get nav_meetings => 'Uchrashuvlar';

  @override
  String get nav_calls => 'Qoʻngʻiroqlar';

  @override
  String get e2ee_media_decrypt_failed_image =>
      'Rasmni shifrini ochib boʻlmadi';

  @override
  String get e2ee_media_decrypt_failed_video => 'Video shifrini ochib boʻlmadi';

  @override
  String get e2ee_media_decrypt_failed_audio => 'Audio shifrini ochib boʻlmadi';

  @override
  String get e2ee_media_decrypt_failed_attachment =>
      'Ilova shifrini ochib boʻlmadi';

  @override
  String get chat_search_snippet_attachment => 'Ilova';

  @override
  String get chat_search_snippet_location => 'Joylashuv';

  @override
  String get chat_search_snippet_message => 'Xabar';

  @override
  String get bottom_nav_chats => 'Chatlar';

  @override
  String get bottom_nav_contacts => 'Kontaktlar';

  @override
  String get bottom_nav_meetings => 'Uchrashuvlar';

  @override
  String get bottom_nav_calls => 'Qoʻngʻiroqlar';

  @override
  String get chat_list_swipe_folders => 'PAPKALAR';

  @override
  String get chat_list_swipe_clear => 'TOZALASH';

  @override
  String get chat_list_swipe_delete => 'OʻCHIRISH';

  @override
  String get composer_editing_title => 'XABAR TAHRIRLASH';

  @override
  String get composer_editing_cancel_tooltip => 'Tahrirlashni bekor qilish';

  @override
  String get composer_formatting_title => 'FORMATLASH';

  @override
  String get composer_link_preview_loading => 'Oldindan koʻrish yuklanmoqda…';

  @override
  String get composer_link_preview_hide_tooltip =>
      'Oldindan koʻrishni yashirish';

  @override
  String get chat_invite_button => 'Taklif qilish';

  @override
  String get forward_preview_unknown_sender => 'Nomaʼlum';

  @override
  String get forward_preview_attachment => 'Ilova';

  @override
  String get forward_preview_message => 'Xabar';

  @override
  String get chat_mention_no_matches => 'Moslik yoʻq';

  @override
  String get live_location_sharing => 'Siz joylashuvingizni ulashyapsiz';

  @override
  String get live_location_stop => 'Toʻxtatish';

  @override
  String get chat_message_deleted => 'Xabar oʻchirildi';

  @override
  String get profile_qr_share => 'Ulashish';

  @override
  String get shared_location_open_browser_tooltip => 'Brauzerda ochish';

  @override
  String get reply_preview_message_fallback => 'Xabar';

  @override
  String get video_circle_media_kind => 'video';

  @override
  String reactions_rated_count(int count) {
    return 'Munosabat bildirdi: $count';
  }

  @override
  String reactions_today_time(String time) {
    return 'Bugun, $time';
  }

  @override
  String get durak_create_timer_subtitle => 'Standart 15 soniya';

  @override
  String get dm_game_banner_active => 'Durak oʻyini davom etmoqda';

  @override
  String get dm_game_banner_created => 'Durak oʻyini yaratildi';

  @override
  String get chat_folder_favorites => 'Sevimlilar';

  @override
  String get chat_folder_new => 'Yangi';

  @override
  String get contact_profile_user_fallback => 'Foydalanuvchi';

  @override
  String contact_profile_error(String error) {
    return 'Xatolik: $error';
  }

  @override
  String get conversation_threads_loading_title => 'Mavzular';

  @override
  String get theme_label_light => 'Yorugʻ';

  @override
  String get theme_label_dark => 'Qorongʻi';

  @override
  String get theme_label_auto => 'Avto';

  @override
  String get chat_draft_reply_fallback => 'Javob';

  @override
  String get mention_default_label => 'Aʻzo';

  @override
  String get contacts_fallback_name => 'Kontakt';

  @override
  String get sticker_pack_default_name => 'Mening toʻplamim';

  @override
  String get profile_error_phone_taken =>
      'Bu telefon raqami allaqachon roʻyxatdan oʻtgan. Iltimos, boshqa raqam ishlating.';

  @override
  String get profile_error_email_taken =>
      'Bu elektron pochta allaqachon band. Iltimos, boshqa manzil ishlating.';

  @override
  String get profile_error_username_taken =>
      'Bu foydalanuvchi nomi allaqachon band. Iltimos, boshqasini tanlang.';

  @override
  String get e2ee_banner_default_context => 'Xabar';

  @override
  String e2ee_banner_encrypted_chat_web_only(String prefix) {
    return '$prefix shifrlangan chatga hozircha faqat veb klientdan yuborish mumkin.';
  }

  @override
  String get chat_attachment_decrypt_error => 'Ilova shifrini ochib boʻlmadi';

  @override
  String get mention_fallback_label => 'aʻzo';

  @override
  String get mention_fallback_label_capitalized => 'Aʻzo';

  @override
  String get meeting_speaking_label => 'Gapirmoqda';

  @override
  String meeting_local_you_suffix(String name) {
    return '$name (Siz)';
  }

  @override
  String get video_crop_title => 'Kesish';

  @override
  String video_crop_load_error(String error) {
    return 'Videoni yuklab boʻlmadi: $error';
  }

  @override
  String get gif_section_recent => 'SOʻNGGI';

  @override
  String get gif_section_trending => 'TRENDDA';

  @override
  String get auth_create_account_title => 'Hisob yaratish';

  @override
  String yandex_sign_in_yandex_error(String error) {
    return 'Yandex: $error';
  }

  @override
  String get call_status_missed => 'Javobsiz';

  @override
  String get call_status_cancelled => 'Bekor qilingan';

  @override
  String get call_status_ended => 'Tugadi';

  @override
  String get presence_offline => 'Oflayn';

  @override
  String get presence_online => 'Onlayn';

  @override
  String get dm_title_fallback => 'Chat';

  @override
  String get dm_title_partner_fallback => 'Kontakt';

  @override
  String get group_title_fallback => 'Guruh chat';

  @override
  String get block_call_viewer_blocked =>
      'Siz bu foydalanuvchini blokladingiz. Qoʻngʻiroq mavjud emas — Profil → Bloklangan da blokni oching.';

  @override
  String get block_call_partner_blocked =>
      'Bu foydalanuvchi siz bilan aloqani chekladi. Qoʻngʻiroq mavjud emas.';

  @override
  String get block_call_unavailable => 'Qoʻngʻiroq mavjud emas.';

  @override
  String get block_composer_viewer_blocked =>
      'Siz bu foydalanuvchini blokladingiz. Yuborish mavjud emas — Profil → Bloklangan da blokni oching.';

  @override
  String get block_composer_partner_blocked =>
      'Bu foydalanuvchi siz bilan aloqani chekladi. Yuborish mavjud emas.';

  @override
  String get forward_group_fallback => 'Guruh';

  @override
  String get forward_unknown_user => 'Nomaʼlum';

  @override
  String get live_location_once => 'Bir martalik (faqat bu xabar)';

  @override
  String get live_location_5min => '5 daqiqa';

  @override
  String get live_location_15min => '15 daqiqa';

  @override
  String get live_location_30min => '30 daqiqa';

  @override
  String get live_location_1hour => '1 soat';

  @override
  String get live_location_2hours => '2 soat';

  @override
  String get live_location_6hours => '6 soat';

  @override
  String get live_location_1day => '1 kun';

  @override
  String get live_location_forever => 'Doimiy (oʻchirib qoʻygunimcha)';

  @override
  String get e2ee_send_too_many_files =>
      'Shifrlangan yuborish uchun juda koʻp ilova: har bir xabar uchun maksimum 5 ta fayl.';

  @override
  String get e2ee_send_too_large =>
      'Jami ilova hajmi juda katta: bitta shifrlangan xabar uchun maksimum 96 MB.';

  @override
  String get presence_last_seen_prefix => 'Soʻnggi faollik ';

  @override
  String get presence_less_than_minute_ago => 'bir daqiqadan kam oldin';

  @override
  String get presence_yesterday => 'kecha';

  @override
  String get dm_fallback_title => 'Chat';

  @override
  String get dm_fallback_partner => 'Kontakt';

  @override
  String get group_fallback_title => 'Guruh chat';

  @override
  String get block_send_viewer_blocked =>
      'Siz bu foydalanuvchini blokladingiz. Yuborish mavjud emas — Profil → Bloklangan da blokni oching.';

  @override
  String get block_send_partner_blocked =>
      'Bu foydalanuvchi siz bilan aloqani chekladi. Yuborish mavjud emas.';

  @override
  String get mention_fallback_name => 'Aʻzo';

  @override
  String get profile_conflict_phone =>
      'Bu telefon raqami allaqachon roʻyxatdan oʻtgan. Iltimos, boshqa raqam ishlating.';

  @override
  String get profile_conflict_email =>
      'Bu elektron pochta allaqachon band. Iltimos, boshqa manzil ishlating.';

  @override
  String get profile_conflict_username =>
      'Bu foydalanuvchi nomi allaqachon band. Iltimos, boshqasini tanlang.';

  @override
  String get mention_fallback_participant => 'Ishtirokchi';

  @override
  String get sticker_gif_recent => 'SOʻNGGI';

  @override
  String get meeting_screen_sharing => 'Ekran';

  @override
  String get meeting_speaking => 'Gapirmoqda';

  @override
  String auth_sign_in_failed(Object error) {
    return 'Tizimga kirib boʻlmadi: $error';
  }

  @override
  String yandex_error_prefix(Object error) {
    return 'Yandex: $error';
  }

  @override
  String auth_error_prefix(Object error) {
    return 'Autentifikatsiya xatosi: $error';
  }

  @override
  String presence_minutes_ago(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count daqiqa oldin',
      one: 'bir daqiqa oldin',
    );
    return '$_temp0';
  }

  @override
  String presence_hours_ago(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count soat oldin',
      one: 'bir soat oldin',
    );
    return '$_temp0';
  }

  @override
  String presence_days_ago(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kun oldin',
      one: 'bir kun oldin',
    );
    return '$_temp0';
  }

  @override
  String presence_months_ago(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count oy oldin',
      one: 'bir oy oldin',
    );
    return '$_temp0';
  }

  @override
  String presence_years_months_ago(int years, int months) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years yil',
      one: '1 yil',
    );
    String _temp1 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$months oy oldin',
      one: '1 oy oldin',
    );
    return '$_temp0 $_temp1';
  }

  @override
  String presence_years_ago(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count yil oldin',
      one: 'bir yil oldin',
    );
    return '$_temp0';
  }

  @override
  String get wallpaper_gradient_purple => 'Binafsha';

  @override
  String get wallpaper_gradient_pink => 'Pushti';

  @override
  String get wallpaper_gradient_blue => 'Koʻk';

  @override
  String get wallpaper_gradient_green => 'Yashil';

  @override
  String get wallpaper_gradient_sunset => 'Quyosh botishi';

  @override
  String get wallpaper_gradient_gentle => 'Nozik';

  @override
  String get wallpaper_gradient_lime => 'Lim';

  @override
  String get wallpaper_gradient_graphite => 'Grafit';

  @override
  String get sticker_tab_recent => 'SOʻNGGI';

  @override
  String get block_call_you_blocked =>
      'Siz bu foydalanuvchini blokladingiz. Qoʻngʻiroq mavjud emas — Profil → Bloklangan da blokni oching.';

  @override
  String get block_call_they_blocked =>
      'Bu foydalanuvchi siz bilan aloqani chekladi. Qoʻngʻiroq mavjud emas.';

  @override
  String get block_call_generic => 'Qoʻngʻiroq mavjud emas.';

  @override
  String get block_send_you_blocked =>
      'Siz bu foydalanuvchini blokladingiz. Yuborish mavjud emas — Profil → Bloklangan da blokni oching.';

  @override
  String get block_send_they_blocked =>
      'Bu foydalanuvchi siz bilan aloqani chekladi. Yuborish mavjud emas.';

  @override
  String get forward_unknown_fallback => 'Nomaʼlum';

  @override
  String get dm_title_chat => 'Chat';

  @override
  String get dm_title_partner => 'Sherik';

  @override
  String get dm_title_group => 'Guruh chat';

  @override
  String get e2ee_too_many_attachments =>
      'Shifrlangan yuborish uchun juda koʻp ilova: har bir xabar uchun maksimum 5 ta fayl.';

  @override
  String get e2ee_total_size_exceeded =>
      'Jami ilova hajmi juda katta: bitta shifrlangan xabar uchun maksimum 96 MB.';

  @override
  String composer_limit_too_many_files(int current, int max, int diff) {
    return 'Juda koʻp ilova: $current/$max. Yuborish uchun $diff tasini olib tashlang.';
  }

  @override
  String composer_limit_total_size_exceeded(String currentMb, String maxMb) {
    return 'Ilovalar juda katta: $currentMb MB / $maxMb MB. Yuborish uchun bir qismini olib tashlang.';
  }

  @override
  String get composer_limit_blocking_send => 'Ilova chegarasi oshirildi';

  @override
  String yandex_sign_in_error_prefix(String error) {
    return 'Yandex: $error';
  }

  @override
  String get meeting_participant_screen => 'Ekran';

  @override
  String get meeting_participant_speaking => 'Gapirmoqda';

  @override
  String get nav_error_title => 'Navigatsiya xatosi';

  @override
  String get nav_error_invalid_secret_compose =>
      'Yaroqsiz maxfiy yozish navigatsiyasi';

  @override
  String get sign_in_title => 'Tizimga kirish';

  @override
  String get sign_in_firebase_ready =>
      'Firebase ishga tushdi. Tizimga kirishingiz mumkin.';

  @override
  String get sign_in_firebase_not_ready =>
      'Firebase tayyor emas. Loglar va firebase_options.dart ni tekshiring.';

  @override
  String get sign_in_continue => 'Davom etish';

  @override
  String get sign_in_anonymously => 'Anonim tizimga kirish';

  @override
  String sign_in_auth_error(String error) {
    return 'Autentifikatsiya xatosi: $error';
  }

  @override
  String generic_error(String error) {
    return 'Xatolik: $error';
  }

  @override
  String get storage_label_video => 'Video';

  @override
  String get storage_label_photo => 'Rasm';

  @override
  String get storage_label_audio => 'Audio';

  @override
  String get storage_label_files => 'Fayllar';

  @override
  String get storage_label_other => 'Boshqa';

  @override
  String get storage_label_recent_stickers => 'So‘nggi stikerlar';

  @override
  String get storage_label_giphy_search => 'GIPHY · qidiruv keshi';

  @override
  String get storage_label_giphy_recent => 'GIPHY · so‘nggi GIFlar';

  @override
  String get storage_chat_unattributed => 'Chatga biriktirilmagan';

  @override
  String storage_label_draft(String key) {
    return 'Qoralama · $key';
  }

  @override
  String get storage_label_offline_snapshot => 'Oflayn chat roʻyxati surati';

  @override
  String storage_label_profile_cache(String name) {
    return 'Profil keshi · $name';
  }

  @override
  String get call_mini_end => 'Qoʻngʻiroqni tugatish';

  @override
  String get animation_quality_lite => 'Lite';

  @override
  String get animation_quality_balanced => 'Muvozanat';

  @override
  String get animation_quality_cinematic => 'Kino';

  @override
  String get crop_aspect_original => 'Asl';

  @override
  String get crop_aspect_square => 'Kvadrat';

  @override
  String get push_notification_title => 'Bildirishnomalarga ruxsat berish';

  @override
  String get push_notification_rationale =>
      'Ilovaga kiruvchi qoʻngʻiroqlar uchun bildirishnomalar kerak.';

  @override
  String get push_notification_required =>
      'Kiruvchi qoʻngʻiroqlarni koʻrsatish uchun bildirishnomalarni yoqing.';

  @override
  String get push_notification_grant => 'Ruxsat berish';

  @override
  String get push_call_accept => 'Qabul qilish';

  @override
  String get push_call_decline => 'Rad etish';

  @override
  String get push_channel_incoming_calls => 'Kiruvchi qoʻngʻiroqlar';

  @override
  String get push_channel_missed_calls => 'Javobsiz qoʻngʻiroqlar';

  @override
  String get push_channel_messages_desc => 'Chatlarda yangi xabarlar';

  @override
  String get push_channel_silent => 'Ovozsiz xabarlar';

  @override
  String get push_channel_silent_desc => 'Ovozsiz push';

  @override
  String get push_caller_unknown => 'Kimdir';

  @override
  String get outbox_attachment_single => 'Ilova';

  @override
  String outbox_attachment_count(int count) {
    return 'Ilovalar ($count)';
  }

  @override
  String get bottom_nav_label_chats => 'Chatlar';

  @override
  String get bottom_nav_label_contacts => 'Kontaktlar';

  @override
  String get bottom_nav_label_conferences => 'Konferensiyalar';

  @override
  String get bottom_nav_label_calls => 'Qoʻngʻiroqlar';

  @override
  String get welcomeBubbleTitle => 'LighChatga xush kelibsiz';

  @override
  String get welcomeBubbleSubtitle => 'Mayoq yondi';

  @override
  String get welcomeSkip => 'Oʻtkazish';

  @override
  String get welcomeReplayDebugTile =>
      'Salomlash animatsiyasini qayta ijro (debug)';

  @override
  String get sticker_scope_library => 'Kutubxona';

  @override
  String get sticker_library_search_hint => 'Stikerlarni qidirish...';

  @override
  String get account_menu_energy_saving => 'Energiya tejash';

  @override
  String get energy_saving_title => 'Energiya tejash';

  @override
  String get energy_saving_section_mode => 'Energiya tejash rejimi';

  @override
  String get energy_saving_section_resource_heavy =>
      'Resurs talab qiladigan jarayonlar';

  @override
  String get energy_saving_threshold_off => 'Oʻchirilgan';

  @override
  String get energy_saving_threshold_always => 'Yoqilgan';

  @override
  String get energy_saving_threshold_off_full => 'Hech qachon';

  @override
  String get energy_saving_threshold_always_full => 'Doimo';

  @override
  String energy_saving_threshold_at(int percent) {
    return 'Batareya $percent% dan past boʻlganda';
  }

  @override
  String get energy_saving_hint_off =>
      'Resurs talab qiladigan effektlar hech qachon avtomatik oʻchirilmaydi.';

  @override
  String get energy_saving_hint_always =>
      'Resurs talab qiladigan effektlar batareya darajasidan qatʼi nazar doimo oʻchirilgan.';

  @override
  String energy_saving_hint_threshold(int percent) {
    return 'Batareya darajasi $percent% dan pastga tushganda barcha resurs talab qiladigan jarayonlarni avtomatik oʻchirish.';
  }

  @override
  String energy_saving_current_battery(int percent) {
    return 'Joriy batareya: $percent%';
  }

  @override
  String get energy_saving_active_now => 'rejim faol';

  @override
  String get energy_saving_active_threshold =>
      'Batareya chegaraga yetdi — quyidagi barcha effektlar vaqtincha oʻchirilgan.';

  @override
  String get energy_saving_active_system =>
      'Tizim energiya tejash rejimi yoqilgan — quyidagi barcha effektlar vaqtincha oʻchirilgan.';

  @override
  String get energy_saving_autoplay_video_title => 'Videolarni avtomatik ijro';

  @override
  String get energy_saving_autoplay_video_subtitle =>
      'Chat xabarlarida va videolarda avtomatik ijro va takrorlash.';

  @override
  String get energy_saving_autoplay_gif_title => 'GIFlarni avtomatik ijro';

  @override
  String get energy_saving_autoplay_gif_subtitle =>
      'Chatlarda va klaviaturada GIFlarni avtomatik ijro va takrorlash.';

  @override
  String get energy_saving_animated_stickers_title => 'Animatsiyali stikerlar';

  @override
  String get energy_saving_animated_stickers_subtitle =>
      'Takrorlanuvchi stiker animatsiyalari va toʻliq ekranli Premium stiker effektlari.';

  @override
  String get energy_saving_animated_emoji_title => 'Animatsiyali emoji';

  @override
  String get energy_saving_animated_emoji_subtitle =>
      'Xabarlarda, reaktsiyalarda va holatlarda takrorlanuvchi emoji animatsiyasi.';

  @override
  String get energy_saving_interface_animations_title =>
      'Interfeys animatsiyalari';

  @override
  String get energy_saving_interface_animations_subtitle =>
      'LighChatni silliqroq va ifodali qiladigan effektlar va animatsiyalar.';

  @override
  String get energy_saving_media_preload_title => 'Media oldindan yuklash';

  @override
  String get energy_saving_media_preload_subtitle =>
      'Chat roʻyxatini ochganda media fayllarni yuklab olishni boshlash.';

  @override
  String get energy_saving_background_update_title => 'Fonda yangilash';

  @override
  String get energy_saving_background_update_subtitle =>
      'Ilovalar orasida almashganda tezkor chat yangilanishlari.';

  @override
  String get legal_index_title => 'Yuridik hujjatlar';

  @override
  String get legal_index_subtitle =>
      'Maxfiylik siyosati, xizmat ko‘rsatish shartlari va LighChat’dan foydalanishni tartibga soluvchi boshqa yuridik hujjatlar.';

  @override
  String get legal_settings_section_title => 'Yuridik ma’lumot';

  @override
  String get legal_settings_section_subtitle =>
      'Maxfiylik siyosati, xizmat ko‘rsatish shartlari, EULA va boshqalar.';

  @override
  String get legal_not_found => 'Hujjat topilmadi';

  @override
  String get legal_title_privacy_policy => 'Maxfiylik siyosati';

  @override
  String get legal_title_terms_of_service => 'Xizmat ko‘rsatish shartlari';

  @override
  String get legal_title_cookie_policy => 'Cookie siyosati';

  @override
  String get legal_title_eula => 'Yakuniy foydalanuvchi litsenziya kelishuvi';

  @override
  String get legal_title_dpa => 'Ma’lumotlarni qayta ishlash kelishuvi';

  @override
  String get legal_title_children => 'Bolalar siyosati';

  @override
  String get legal_title_moderation => 'Kontent moderatsiyasi siyosati';

  @override
  String get legal_title_aup => 'Qabul qilinadigan foydalanish siyosati';

  @override
  String get chat_list_item_sender_you => 'Siz';

  @override
  String get chat_preview_message => 'Xabar';

  @override
  String get chat_preview_sticker => 'Stiker';

  @override
  String get chat_preview_attachment => 'Ilova';

  @override
  String get contacts_disclosure_title => 'LighChat\'da tanishlarni topish';

  @override
  String get contacts_disclosure_body =>
      'LighChat manzil kitobingizdan telefon raqamlari va elektron pochta manzillarini o\'qiydi, ularni hash qiladi va qaysi kontaktlaringiz ilovadan foydalanayotganini ko\'rsatish uchun serverimiz bilan tekshiradi. Kontaktlarning o\'zi hech qaerda saqlanmaydi.';

  @override
  String get contacts_disclosure_allow => 'Ruxsat berish';

  @override
  String get contacts_disclosure_deny => 'Hozir emas';

  @override
  String get report_title => 'Shikoyat qilish';

  @override
  String get report_subtitle_message => 'Xabar haqida shikoyat';

  @override
  String get report_subtitle_user => 'Foydalanuvchi haqida shikoyat';

  @override
  String get report_reason_spam => 'Spam';

  @override
  String get report_reason_offensive => 'Haqoratli kontent';

  @override
  String get report_reason_violence => 'Zo\'ravonlik yoki tahdidlar';

  @override
  String get report_reason_fraud => 'Firibgarlik';

  @override
  String get report_reason_other => 'Boshqa';

  @override
  String get report_comment_hint => 'Qo\'shimcha ma\'lumotlar (ixtiyoriy)';

  @override
  String get report_submit => 'Yuborish';

  @override
  String get report_success => 'Shikoyat yuborildi. Rahmat!';

  @override
  String get report_error => 'Shikoyatni yuborib bo\'lmadi';

  @override
  String get message_menu_action_report => 'Shikoyat';

  @override
  String get partner_profile_menu_report => 'Foydalanuvchi haqida shikoyat';

  @override
  String get call_bubble_voice_call => 'Ovozli qo\'ng\'iroq';

  @override
  String get call_bubble_video_call => 'Video qo\'ng\'iroq';

  @override
  String get chat_preview_poll => 'So\'rovnoma';

  @override
  String get chat_preview_forwarded => 'Yuborilgan xabar';

  @override
  String get birthday_banner_celebrates => 'tug\'ilgan kunini nishonlamoqda!';

  @override
  String get birthday_banner_action => 'Tabriklash →';

  @override
  String get birthday_screen_title_today => 'Bugun tug\'ilgan kun';

  @override
  String birthday_screen_age(int age) {
    return '$age yosh';
  }

  @override
  String get birthday_section_actions => 'TABRIKLASH';

  @override
  String get birthday_action_template => 'Tayyor tabrik';

  @override
  String get birthday_action_cake => 'Shamni puflab o\'chir';

  @override
  String get birthday_action_confetti => 'Konfetti';

  @override
  String get birthday_action_serpentine => 'Serpantin';

  @override
  String get birthday_action_voice => 'Audio tabrik yozish';

  @override
  String get birthday_action_remind_next_year => 'Keyingi yili oldindan eslat';

  @override
  String get birthday_action_open_chat => 'O\'z tabrigingni yoz';

  @override
  String get birthday_cake_prompt => 'Shamni o\'chirish uchun tegining';

  @override
  String birthday_cake_wish_placeholder(Object name) {
    return '$name uchun qanday tilak tilaysiz?';
  }

  @override
  String get birthday_cake_wish_hint => 'Masalan: barcha orzular ushalsin…';

  @override
  String get birthday_cake_send => 'Yuborish';

  @override
  String birthday_cake_message(Object name, Object wish) {
    return '🎂 Tug\'ilgan kuning bilan, $name! Mening tilagim: «$wish»';
  }

  @override
  String birthday_confetti_message(Object name) {
    return '🎉 Tug\'ilgan kuning bilan, $name! 🎉';
  }

  @override
  String birthday_template_1(Object name) {
    return 'Tug\'ilgan kuning bilan, $name! Bu yil eng yaxshisi bo\'lsin!';
  }

  @override
  String birthday_template_2(Object name) {
    return '$name, tabriklayman! Quvonch, iliqlik va orzular ro\'yobi tilayman 🎉';
  }

  @override
  String birthday_template_3(Object name) {
    return 'Bayraming bilan, $name! Sog\'liq, omad va ko\'p baxtli daqiqalar 🎂';
  }

  @override
  String birthday_template_4(Object name) {
    return '$name, tug\'ilgan kuning bilan! Rejalaring oson amalga oshsin ✨';
  }

  @override
  String birthday_template_5(Object name) {
    return 'Tabriklayman, $name! Borligingdan minnatdorman. Tug\'ilgan kuning bilan! 🎁';
  }

  @override
  String get birthday_toast_sent => 'Tabrik yuborildi';

  @override
  String birthday_reminder_set(Object name) {
    return '$name tug\'ilgan kunidan bir kun oldin eslataman';
  }

  @override
  String get birthday_reminder_notif_title => 'Ertaga tug\'ilgan kun 🎂';

  @override
  String birthday_reminder_notif_body(Object name) {
    return 'Ertaga $name ni tabriklashni unutmang';
  }

  @override
  String get birthday_empty => 'Bugun kontaktlaringizda tug\'ilgan kun yo\'q';

  @override
  String get birthday_error_self => 'Profilingiz yuklanmadi';

  @override
  String get birthday_error_send => 'Xabar yuborilmadi. Yana urinib ko\'ring.';

  @override
  String get birthday_error_reminder => 'Eslatma o\'rnatilmadi';

  @override
  String get chat_empty_title => 'Hozircha xabarlar yo\'q';

  @override
  String get chat_empty_subtitle =>
      'Salom ayting — mayoq qorovuli allaqachon qo\'l silkitmoqda';

  @override
  String get chat_empty_quick_greet => 'Salom 👋';
}
