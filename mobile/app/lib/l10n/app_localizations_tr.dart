// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get secret_chat_title => 'Gizli sohbet';

  @override
  String get secret_chats_title => 'Gizli Sohbetler';

  @override
  String get secret_chat_locked_title => 'Gizli sohbet kilitli';

  @override
  String get secret_chat_locked_subtitle =>
      'Mesajları görüntülemek için PIN kodunuzu girin.';

  @override
  String get secret_chat_unlock_title => 'Gizli sohbetin kilidini aç';

  @override
  String get secret_chat_unlock_subtitle =>
      'Bu sohbeti açmak için PIN gereklidir.';

  @override
  String get secret_chat_unlock_action => 'Kilidi aç';

  @override
  String get secret_chat_set_pin_and_unlock => 'PIN belirle ve kilidi aç';

  @override
  String get secret_chat_pin_label => 'PIN (4 haneli)';

  @override
  String get secret_chat_pin_invalid => '4 haneli bir PIN girin';

  @override
  String get secret_chat_already_exists =>
      'Bu kullanıcıyla zaten bir gizli sohbet mevcut.';

  @override
  String get secret_chat_exists_badge => 'Oluşturuldu';

  @override
  String get secret_chat_unlock_failed =>
      'Kilit açılamadı. Lütfen tekrar deneyin.';

  @override
  String get secret_chat_action_not_allowed =>
      'Bu işlem gizli sohbette yapılamaz';

  @override
  String get secret_chat_remember_pin => 'Bu cihazda PIN\'i hatırla';

  @override
  String get secret_chat_unlock_biometric => 'Biyometrik ile kilidi aç';

  @override
  String get secret_chat_biometric_reason => 'Gizli sohbetin kilidini aç';

  @override
  String get secret_chat_biometric_no_saved_pin =>
      'Biyometrik kilidi etkinleştirmek için PIN\'i bir kez girin';

  @override
  String get secret_chat_ttl_title => 'Gizli sohbet ömrü';

  @override
  String get secret_chat_settings_title => 'Gizli sohbet ayarları';

  @override
  String get secret_chat_settings_subtitle => 'Ömür, erişim ve kısıtlamalar';

  @override
  String get secret_chat_settings_not_secret =>
      'Bu sohbet gizli bir sohbet değil';

  @override
  String get secret_chat_settings_ttl => 'Ömür';

  @override
  String secret_chat_settings_time_left(Object value) {
    return 'Kalan süre: $value';
  }

  @override
  String secret_chat_settings_expires_at(Object iso) {
    return 'Sona erme: $iso';
  }

  @override
  String get secret_chat_settings_unlock_grant_ttl => 'Kilit açma süresi';

  @override
  String get secret_chat_settings_unlock_grant_ttl_subtitle =>
      'Kilit açıldıktan sonra erişimin ne kadar süre aktif kalacağı';

  @override
  String get secret_chat_settings_no_copy => 'Kopyalamayı devre dışı bırak';

  @override
  String get secret_chat_settings_no_forward => 'İletmeyi devre dışı bırak';

  @override
  String get secret_chat_settings_no_save =>
      'Medya kaydetmeyi devre dışı bırak';

  @override
  String get secret_chat_settings_screenshot_protection =>
      'Ekran görüntüsü koruması (Android)';

  @override
  String get secret_chat_settings_media_views => 'Medya görüntüleme sınırları';

  @override
  String get secret_chat_settings_media_views_subtitle =>
      'Alıcı görüntülemeleri için en iyi sınırlar';

  @override
  String get secret_chat_media_type_image => 'Resimler';

  @override
  String get secret_chat_media_type_video => 'Videolar';

  @override
  String get secret_chat_media_type_voice => 'Sesli mesajlar';

  @override
  String get secret_chat_media_type_location => 'Konum';

  @override
  String get secret_chat_media_type_file => 'Dosyalar';

  @override
  String get secret_chat_media_views_unlimited => 'Sınırsız';

  @override
  String get secret_chat_compose_create => 'Gizli sohbet oluştur';

  @override
  String get secret_chat_compose_vault_pin_subtitle =>
      'İsteğe bağlı: gizli gelen kutusu kilidi için kullanılacak 4 haneli kasa PIN\'i belirleyin (biyometrik etkinleştirildiğinde bu cihazda saklanır).';

  @override
  String get secret_chat_compose_require_unlock_pin =>
      'Bu sohbeti açmak için PIN iste';

  @override
  String get secret_chat_settings_read_only_hint =>
      'Bu ayarlar oluşturma sırasında sabitlendiler ve değiştirilemez.';

  @override
  String get secret_chat_settings_delete => 'Gizli sohbeti sil';

  @override
  String get secret_chat_settings_delete_confirm_title =>
      'Bu gizli sohbet silinsin mi?';

  @override
  String get secret_chat_settings_delete_confirm_body =>
      'Mesajlar ve medya her iki katılımcı için de kaldırılacak.';

  @override
  String get privacy_secret_vault_title => 'Gizli kasa';

  @override
  String get privacy_secret_vault_subtitle =>
      'Gizli sohbetlere girmek için genel PIN ve biyometrik kontroller.';

  @override
  String get privacy_secret_vault_change_pin =>
      'Kasa PIN\'i belirle veya değiştir';

  @override
  String get privacy_secret_vault_change_pin_subtitle =>
      'PIN zaten varsa, eski PIN veya biyometrik ile onaylayın.';

  @override
  String get privacy_secret_vault_bio_subtitle =>
      'Biyometrik kontrolü çalıştır ve kaydedilmiş yerel PIN\'i doğrula.';

  @override
  String get privacy_secret_vault_bio_reason =>
      'Gizli sohbetlere erişimi onayla';

  @override
  String get privacy_secret_vault_current_pin => 'Mevcut PIN';

  @override
  String get privacy_secret_vault_new_pin => 'Yeni PIN';

  @override
  String get privacy_secret_vault_repeat_pin => 'Yeni PIN\'i tekrarla';

  @override
  String get privacy_secret_vault_pin_mismatch => 'PIN\'ler eşleşmiyor';

  @override
  String get privacy_secret_vault_pin_updated => 'Kasa PIN\'i güncellendi';

  @override
  String get privacy_secret_vault_bio_unavailable =>
      'Bu cihazda biyometrik kimlik doğrulama kullanılamıyor';

  @override
  String get privacy_secret_vault_bio_verified => 'Biyometrik kontrol başarılı';

  @override
  String get privacy_secret_vault_setup_required =>
      'Önce Gizlilik bölümünde PIN veya biyometrik erişim ayarlayın.';

  @override
  String get privacy_secret_vault_network_timeout =>
      'Ağ zaman aşımı. Lütfen tekrar deneyin.';

  @override
  String privacy_secret_vault_error(Object error) {
    return 'Gizli kasa hatası: $error';
  }

  @override
  String get tournament_title => 'Turnuva';

  @override
  String get tournament_subtitle => 'Sıralama ve oyun serisi';

  @override
  String get tournament_new_game => 'Yeni oyun';

  @override
  String get tournament_standings => 'Sıralama';

  @override
  String get tournament_standings_empty => 'Henüz sonuç yok';

  @override
  String get tournament_games => 'Oyunlar';

  @override
  String get tournament_games_empty => 'Henüz oyun yok';

  @override
  String tournament_points(Object pts) {
    return '$pts puan';
  }

  @override
  String tournament_games_played(Object n) {
    return '$n oyun';
  }

  @override
  String tournament_create_failed(Object err) {
    return 'Turnuva oluşturulamadı: $err';
  }

  @override
  String tournament_create_game_failed(Object err) {
    return 'Oyun oluşturulamadı: $err';
  }

  @override
  String tournament_game_players(Object names) {
    return 'Oyuncular: $names';
  }

  @override
  String get tournament_game_result_draw => 'Sonuç: berabere';

  @override
  String tournament_game_result_loser(Object name) {
    return 'Sonuç: durak — $name';
  }

  @override
  String tournament_game_place(Object place) {
    return '$place. sıra';
  }

  @override
  String get durak_dm_lobby_banner =>
      'Partneriniz bir Durak lobisi oluşturdu — katılın';

  @override
  String get durak_dm_lobby_open => 'Lobiyi aç';

  @override
  String get conversation_game_lobby_cancel => 'Beklemeyi bitir';

  @override
  String conversation_game_lobby_cancel_failed(Object err) {
    return 'Bekleme sonlandırılamadı: $err';
  }

  @override
  String secret_chat_media_views_count(Object count) {
    return '$count görüntüleme';
  }

  @override
  String secret_chat_settings_load_failed(Object error) {
    return 'Yüklenemedi: $error';
  }

  @override
  String secret_chat_settings_save_failed(Object error) {
    return 'Kaydedilemedi: $error';
  }

  @override
  String get secret_chat_settings_reset_strict => 'Katı varsayılanlara sıfırla';

  @override
  String get secret_chat_settings_reset_strict_subtitle =>
      'Tüm kısıtlamaları etkinleştirir ve medya görüntüleme sınırlarını 1\'e ayarlar';

  @override
  String get settings_language_title => 'Dil';

  @override
  String get settings_language_system => 'Sistem';

  @override
  String get settings_language_ru => 'Rusça';

  @override
  String get settings_language_en => 'İngilizce';

  @override
  String get settings_language_hint_system =>
      '“Sistem” seçildiğinde uygulama cihazınızın dil ayarlarını takip eder.';

  @override
  String get account_menu_profile => 'Profil';

  @override
  String get account_menu_features => 'Özellikler';

  @override
  String get account_menu_chat_settings => 'Sohbet ayarları';

  @override
  String get account_menu_notifications => 'Bildirimler';

  @override
  String get account_menu_privacy => 'Gizlilik';

  @override
  String get account_menu_devices => 'Cihazlar';

  @override
  String get account_menu_blacklist => 'Engellenenler';

  @override
  String get account_menu_language => 'Dil';

  @override
  String get account_menu_storage => 'Depolama';

  @override
  String get account_menu_theme => 'Tema';

  @override
  String get account_menu_sign_out => 'Çıkış yap';

  @override
  String get storage_settings_title => 'Depolama';

  @override
  String get storage_settings_subtitle =>
      'Bu cihazda hangi verilerin önbelleğe alınacağını kontrol edin ve sohbetlere veya dosyalara göre temizleyin.';

  @override
  String get storage_settings_total_label => 'Bu cihazda kullanılan';

  @override
  String storage_settings_budget_label(Object gb) {
    return 'Önbellek sınırı: $gb GB';
  }

  @override
  String get storage_unit_gb => 'Büyük Britanya';

  @override
  String get storage_settings_clear_all_button => 'Tüm önbelleği temizle';

  @override
  String get storage_settings_trim_button => 'Bütçeye göre kırp';

  @override
  String get storage_settings_policy_title => 'Yerel olarak ne saklanacak';

  @override
  String get storage_settings_budget_slider_title => 'Önbellek bütçesi';

  @override
  String get storage_settings_breakdown_title => 'Veri türüne göre';

  @override
  String get storage_settings_breakdown_empty =>
      'Henüz yerel önbellek verisi yok.';

  @override
  String get storage_settings_chats_title => 'Sohbetlere göre';

  @override
  String get storage_settings_chats_empty => 'Henüz sohbete özel önbellek yok.';

  @override
  String storage_settings_chat_subtitle(Object count, Object size) {
    return '$count öğe · $size';
  }

  @override
  String get storage_settings_general_title => 'Atanmamış önbellek';

  @override
  String get storage_settings_general_hint =>
      'Belirli bir sohbete bağlı olmayan girişler (eski/genel önbellek).';

  @override
  String get storage_settings_general_empty =>
      'Paylaşılan önbellek girişi yok.';

  @override
  String get storage_settings_chat_files_empty =>
      'Bu sohbet önbelleğinde yerel dosya yok.';

  @override
  String get storage_settings_clear_chat_action => 'Sohbet önbelleğini temizle';

  @override
  String get storage_settings_clear_all_title =>
      'Yerel önbellek temizlensin mi?';

  @override
  String get storage_settings_clear_all_body =>
      'Bu, önbelleğe alınmış dosyaları, önizlemeleri, taslakları ve çevrimdışı anlık görüntüleri bu cihazdan kaldıracak.';

  @override
  String storage_settings_clear_chat_title(Object chat) {
    return '“$chat” için önbellek temizlensin mi?';
  }

  @override
  String get storage_settings_clear_chat_body =>
      'Yalnızca bu sohbetin önbelleği silinecek. Buluttaki mesajlar bozulmadan kalacak.';

  @override
  String get storage_settings_snackbar_cleared => 'Yerel önbellek temizlendi';

  @override
  String get storage_settings_snackbar_budget_already_ok =>
      'Önbellek zaten hedef bütçeye uygun';

  @override
  String storage_settings_snackbar_budget_trimmed(Object size) {
    return 'Boşaltıldı: $size';
  }

  @override
  String get storage_settings_error_empty =>
      'Depolama istatistikleri oluşturulamıyor';

  @override
  String get storage_category_e2ee_media => 'E2EE medya önbelleği';

  @override
  String get storage_category_e2ee_media_subtitle =>
      'Daha hızlı yeniden açma için sohbet başına şifresi çözülmüş gizli medya dosyaları.';

  @override
  String get storage_category_e2ee_text => 'E2EE metin önbelleği';

  @override
  String get storage_category_e2ee_text_subtitle =>
      'Anında oluşturma için sohbet başına şifresi çözülmüş metin parçacıkları.';

  @override
  String get storage_category_drafts => 'Mesaj taslakları';

  @override
  String get storage_category_drafts_subtitle =>
      'Sohbetlere göre gönderilmemiş taslak metinler.';

  @override
  String get storage_category_chat_list_snapshot => 'Çevrimdışı sohbet listesi';

  @override
  String get storage_category_chat_list_snapshot_subtitle =>
      'Hızlı çevrimdışı başlatma için son sohbet listesi anlık görüntüsü.';

  @override
  String get storage_category_profile_cards => 'Profil mini önbelleği';

  @override
  String get storage_category_profile_cards_subtitle =>
      'Daha hızlı arayüz için kaydedilmiş isimler ve avatarlar.';

  @override
  String get storage_category_video_downloads => 'İndirilen video önbelleği';

  @override
  String get storage_category_video_downloads_subtitle =>
      'Galeri görünümlerinden yerel olarak indirilen videolar.';

  @override
  String get storage_category_video_thumbs => 'Video önizleme kareleri';

  @override
  String get storage_category_video_thumbs_subtitle =>
      'Videolar için oluşturulmuş ilk kare küçük resimleri.';

  @override
  String get storage_category_chat_images => 'Sohbet fotoğrafları';

  @override
  String get storage_category_chat_images_subtitle =>
      'Açık sohbetlerden önbelleğe alınmış fotoğraflar ve çıkartmalar.';

  @override
  String get storage_category_stickers_gifs_emoji =>
      'Çıkartmalar, GIF\'ler, emoji';

  @override
  String get storage_category_stickers_gifs_emoji_subtitle =>
      'Son kullanılan çıkartmalar ve GIPHY (gif/çıkartma/animasyonlu emoji) önbelleği.';

  @override
  String get storage_category_network_images => 'Ağ görüntü önbelleği';

  @override
  String get storage_category_network_images_subtitle =>
      'Avatarlar, önizlemeler ve ağdan alınan diğer görseller (libCachedImageData).';

  @override
  String get storage_media_type_video => 'Video';

  @override
  String get storage_media_type_photo => 'Fotoğraflar';

  @override
  String get storage_media_type_audio => 'Ses';

  @override
  String get storage_media_type_files => 'Dosyalar';

  @override
  String get storage_media_type_other => 'Diğer';

  @override
  String storage_settings_device_usage(Object pct) {
    return 'Önbellek bütçesinin %$pct\'sini kullanıyor';
  }

  @override
  String get storage_settings_clear_all_hint =>
      'Tüm medya bulutta kalacak. İstediğiniz zaman yeniden indirebilirsiniz.';

  @override
  String get storage_settings_categories_title => 'Kategoriye göre';

  @override
  String storage_settings_clear_category_title(String category) {
    return '\"$category\" temizlensin mi?';
  }

  @override
  String storage_settings_clear_category_body(String size) {
    return 'Yaklaşık $size boşaltılacak. Bu işlem geri alınamaz.';
  }

  @override
  String get storage_auto_delete_title =>
      'Önbelleğe alınmış medyayı otomatik sil';

  @override
  String get storage_auto_delete_personal => 'Kişisel sohbetler';

  @override
  String get storage_auto_delete_groups => 'Gruplar';

  @override
  String get storage_auto_delete_never => 'Asla';

  @override
  String get storage_auto_delete_3_days => '3 gün';

  @override
  String get storage_auto_delete_1_week => '1 hafta';

  @override
  String get storage_auto_delete_1_month => '1 ay';

  @override
  String get storage_auto_delete_3_months => '3 ay';

  @override
  String get storage_auto_delete_hint =>
      'Bu süre içinde açmadığınız fotoğraflar, videolar ve dosyalar alan kazanmak için cihazdan kaldırılacak.';

  @override
  String storage_chat_detail_share(Object pct) {
    return 'Bu sohbet önbelleğinizin %$pct\'sını kullanıyor';
  }

  @override
  String get storage_chat_detail_media_tab => 'Medya';

  @override
  String get storage_chat_detail_select_all => 'Tümünü seç';

  @override
  String get storage_chat_detail_deselect_all => 'Seçimi kaldır';

  @override
  String storage_chat_detail_clear_button(Object size) {
    return 'Önbelleği temizle $size';
  }

  @override
  String get storage_chat_detail_clear_button_empty =>
      'Silinecek dosyaları seçin';

  @override
  String get storage_chat_detail_tab_empty => 'Bu sekmede hiçbir şey yok.';

  @override
  String get storage_chat_detail_delete_title => 'Seçili dosyalar silinsin mi?';

  @override
  String storage_chat_detail_delete_body(Object count, Object size) {
    return '$count dosya ($size) cihazdan kaldırılacak. Bulut kopyaları bozulmadan kalacak.';
  }

  @override
  String get profile_delete_account => 'Hesabı sil';

  @override
  String get profile_delete_account_confirm_title =>
      'Hesabınız kalıcı olarak silinsin mi?';

  @override
  String get profile_delete_account_confirm_body =>
      'Hesabınız Firebase Auth\'tan kaldırılacak ve tüm Firestore belgeleriniz kalıcı olarak silinecek. Sohbetleriniz başkaları için salt okunur modda görünür kalacak.';

  @override
  String get profile_delete_account_confirm_action => 'Hesabı sil';

  @override
  String profile_delete_account_error(Object error) {
    return 'Hesap silinemedi: $error';
  }

  @override
  String get chat_readonly_deleted_user =>
      'Hesap silindi. Bu sohbet salt okunur.';

  @override
  String get blacklist_empty => 'Engellenen kullanıcı yok';

  @override
  String get blacklist_action_unblock => 'Engeli kaldır';

  @override
  String get blacklist_unblock_confirm_title => 'Engel kaldırılsın mı?';

  @override
  String get blacklist_unblock_confirm_body =>
      'Bu kullanıcı size tekrar mesaj gönderebilecek (iletişim politikası izin veriyorsa) ve aramada profilinizi görebilecek.';

  @override
  String get blacklist_unblock_success => 'Kullanıcının engeli kaldırıldı';

  @override
  String blacklist_unblock_error(Object error) {
    return 'Engel kaldırılamadı: $error';
  }

  @override
  String get partner_profile_block_confirm_title =>
      'Bu kullanıcı engellensin mi?';

  @override
  String get partner_profile_block_confirm_body =>
      'Sizinle sohbeti göremeyecek, sizi aramada bulamayacak veya kişilere ekleyemeyecek. Kişilerinden kaybolacaksınız. Sohbet geçmişini saklayacaksınız ama engelliyken mesaj gönderemezsiniz.';

  @override
  String get partner_profile_block_action => 'Engelle';

  @override
  String get partner_profile_block_success => 'Kullanıcı engellendi';

  @override
  String partner_profile_block_error(Object error) {
    return 'Engellenemedi: $error';
  }

  @override
  String get common_soon => 'Yakında';

  @override
  String common_theme_prefix(Object label) {
    return 'Tema: $label';
  }

  @override
  String common_error_cannot_save_theme(Object error) {
    return 'Tema kaydedilemedi: $error';
  }

  @override
  String common_error_cannot_sign_out(Object error) {
    return 'Çıkış yapılamadı: $error';
  }

  @override
  String account_error_profile(Object error) {
    return 'Profil hatası: $error';
  }

  @override
  String get notifications_title => 'Bildirimler';

  @override
  String get notifications_section_main => 'Ana';

  @override
  String get notifications_mute_all_title => 'Tümünü kapat';

  @override
  String get notifications_mute_all_subtitle =>
      'Tüm bildirimleri devre dışı bırak.';

  @override
  String get notifications_sound_title => 'Ses';

  @override
  String get notifications_sound_subtitle => 'Yeni mesajlar için ses çal.';

  @override
  String get notifications_preview_title => 'Önizleme';

  @override
  String get notifications_preview_subtitle =>
      'Bildirimlerde mesaj metnini göster.';

  @override
  String get notifications_section_quiet_hours => 'Sessiz saatler';

  @override
  String get notifications_quiet_hours_subtitle =>
      'Bu zaman aralığında bildirimler sizi rahatsız etmeyecek.';

  @override
  String get notifications_quiet_hours_enable_title =>
      'Sessiz saatleri etkinleştir';

  @override
  String get notifications_reset_button => 'Ayarları sıfırla';

  @override
  String notifications_error_cannot_save(Object error) {
    return 'Ayarlar kaydedilemedi: $error';
  }

  @override
  String notifications_error_load(Object error) {
    return 'Bildirimler yüklenemedi: $error';
  }

  @override
  String get privacy_title => 'Sohbet gizliliği';

  @override
  String privacy_error_cannot_save(Object error) {
    return 'Ayarlar kaydedilemedi: $error';
  }

  @override
  String privacy_error_load(Object error) {
    return 'Gizlilik ayarları yüklenemedi: $error';
  }

  @override
  String get privacy_e2ee_section => 'Uçtan uca şifreleme';

  @override
  String get privacy_e2ee_enable_for_all_chats =>
      'Tüm sohbetler için E2EE\'yi etkinleştir';

  @override
  String get privacy_e2ee_what_encrypt => 'E2EE sohbetlerinde neler şifrelenir';

  @override
  String get privacy_e2ee_text => 'Mesaj metni';

  @override
  String get privacy_e2ee_media => 'Ekler (medya/dosyalar)';

  @override
  String get privacy_my_devices_title => 'Cihazlarım';

  @override
  String get privacy_my_devices_subtitle =>
      'Yayınlanmış anahtarlara sahip cihazlar. Yeniden adlandır veya erişimi iptal et.';

  @override
  String get privacy_key_backup_title => 'Yedekleme ve anahtar aktarımı';

  @override
  String get privacy_key_backup_subtitle =>
      'Parola yedeği oluştur veya anahtarı QR ile aktar.';

  @override
  String get privacy_visibility_section => 'Görünürlük';

  @override
  String get privacy_online_title => 'Çevrimiçi durumu';

  @override
  String get privacy_online_subtitle =>
      'Başkalarının çevrimiçi olduğunuzu görmesine izin verin.';

  @override
  String get privacy_last_seen_title => 'Son görülme';

  @override
  String get privacy_last_seen_subtitle =>
      'Son aktif olma zamanınızı gösterin.';

  @override
  String get privacy_read_receipts_title => 'Okundu bilgisi';

  @override
  String get privacy_read_receipts_subtitle =>
      'Göndericilerin mesajı okuduğunuzu bilmesine izin verin.';

  @override
  String get privacy_group_invites_section => 'Grup davetleri';

  @override
  String get privacy_group_invites_subtitle =>
      'Sizi grup sohbetlerine kim ekleyebilir.';

  @override
  String get privacy_group_invites_everyone => 'Herkes';

  @override
  String get privacy_group_invites_contacts => 'Yalnızca kişiler';

  @override
  String get privacy_group_invites_nobody => 'Hiç kimse';

  @override
  String get privacy_global_search_section => 'Keşfedilebilirlik';

  @override
  String get privacy_global_search_subtitle =>
      'Tüm kullanıcılar arasında sizi adınızla kim bulabilir.';

  @override
  String get privacy_global_search_title => 'Genel arama';

  @override
  String get privacy_global_search_hint =>
      'Kapatılırsa, biri yeni sohbet başlattığında “Tüm kullanıcılar”\'da görünmezsiniz. Sizi kişi olarak ekleyen kişilere hâlâ görünür olursunuz.';

  @override
  String get privacy_profile_for_others_section => 'Başkaları için profil';

  @override
  String get privacy_profile_for_others_subtitle =>
      'Başkalarının profilinizde görebilecekleri.';

  @override
  String get privacy_email_subtitle => 'Profilinizdeki e-posta adresiniz.';

  @override
  String get privacy_phone_title => 'Telefon numarası';

  @override
  String get privacy_phone_subtitle =>
      'Profilinizde ve kişilerinizde gösterilir.';

  @override
  String get privacy_birthdate_title => 'Doğum tarihi';

  @override
  String get privacy_birthdate_subtitle => 'Profildeki doğum günü alanınız.';

  @override
  String get privacy_about_title => 'Hakkında';

  @override
  String get privacy_about_subtitle => 'Profildeki biyografi metniniz.';

  @override
  String get privacy_reset_button => 'Ayarları sıfırla';

  @override
  String get common_cancel => 'İptal';

  @override
  String get common_create => 'Oluştur';

  @override
  String get common_delete => 'Sil';

  @override
  String get common_choose => 'Seç';

  @override
  String get common_save => 'Kaydet';

  @override
  String get common_close => 'Kapat';

  @override
  String get common_nothing_found => 'Hiçbir şey bulunamadı';

  @override
  String get common_retry => 'Tekrar dene';

  @override
  String get auth_login_email_label => 'E-posta';

  @override
  String get auth_login_password_label => 'Şifre';

  @override
  String get auth_login_password_hint => 'Şifre';

  @override
  String get auth_login_sign_in => 'Giriş yap';

  @override
  String get auth_login_forgot_password => 'Şifrenizi mi unuttunuz?';

  @override
  String get auth_login_error_enter_email_for_reset =>
      'Şifrenizi sıfırlamak için e-postanızı girin';

  @override
  String get profile_title => 'Profil';

  @override
  String get profile_edit_tooltip => 'Düzenle';

  @override
  String get profile_full_name_label => 'Ad soyad';

  @override
  String get profile_full_name_hint => 'Ad';

  @override
  String get profile_username_label => 'Kullanıcı adı';

  @override
  String get profile_email_label => 'E-posta';

  @override
  String get profile_phone_label => 'Telefon';

  @override
  String get profile_birthdate_label => 'Doğum tarihi';

  @override
  String get profile_about_label => 'Hakkında';

  @override
  String get profile_about_hint => 'Kısa bir biyografi';

  @override
  String get profile_password_toggle_show => 'Şifre değiştir';

  @override
  String get profile_password_toggle_hide => 'Şifre değiştirmeyi gizle';

  @override
  String get profile_password_new_label => 'Yeni şifre';

  @override
  String get profile_password_confirm_label => 'Şifreyi onayla';

  @override
  String get profile_password_tooltip_show => 'Şifreyi göster';

  @override
  String get profile_password_tooltip_hide => 'Gizle';

  @override
  String get profile_placeholder_username => 'kullanıcı adı';

  @override
  String get profile_placeholder_email => 'ad@ornek.com';

  @override
  String get profile_placeholder_phone => '+90 500 000 00 00';

  @override
  String get profile_placeholder_birthdate => 'GG.AA.YYYY';

  @override
  String get profile_placeholder_password_dots => '••••••••';

  @override
  String get profile_password_error_fill_both =>
      'Yeni şifreyi ve onayı doldurun.';

  @override
  String get settings_chats_title => 'Sohbet ayarları';

  @override
  String get settings_chats_preview => 'Önizleme';

  @override
  String get settings_chats_outgoing => 'Giden mesajlar';

  @override
  String get settings_chats_incoming => 'Gelen mesajlar';

  @override
  String get settings_chats_font_size => 'Metin boyutu';

  @override
  String get settings_chats_font_small => 'Küçük';

  @override
  String get settings_chats_font_medium => 'Orta';

  @override
  String get settings_chats_font_large => 'Büyük';

  @override
  String get settings_chats_bubble_shape => 'Balon şekli';

  @override
  String get settings_chats_bubble_rounded => 'Yuvarlak';

  @override
  String get settings_chats_bubble_square => 'Kare';

  @override
  String get settings_chats_chat_background => 'Sohbet arka planı';

  @override
  String get settings_chats_chat_background_pick_hint =>
      'Bir fotoğraf seçin veya arka planı ayarlayın';

  @override
  String get settings_chats_advanced => 'Gelişmiş';

  @override
  String get settings_chats_show_time => 'Saati göster';

  @override
  String get settings_chats_show_time_subtitle =>
      'Balonların altında mesaj saatini göster';

  @override
  String get settings_chats_reset => 'Ayarları sıfırla';

  @override
  String settings_chats_error_cannot_save(Object error) {
    return 'Kaydedilemedi: $error';
  }

  @override
  String settings_chats_error_wallpaper_load(Object error) {
    return 'Arka plan yüklenemedi: $error';
  }

  @override
  String settings_chats_error_wallpaper_delete(Object error) {
    return 'Arka plan silinemedi: $error';
  }

  @override
  String get settings_chats_wallpaper_delete_confirm_title =>
      'Arka plan silinsin mi?';

  @override
  String get settings_chats_wallpaper_delete_confirm_body =>
      'Bu arka plan listenizden kaldırılacak.';

  @override
  String settings_chats_icon_picker_title(Object label) {
    return 'Simge: “$label”';
  }

  @override
  String get settings_chats_icon_picker_search_hint => 'Ada göre ara…';

  @override
  String get settings_chats_icon_color => 'Simge rengi';

  @override
  String get settings_chats_reset_icon_size => 'Boyutu sıfırla';

  @override
  String get settings_chats_reset_icon_stroke => 'Kalınlığı sıfırla';

  @override
  String get settings_chats_tile_background => 'Döşeme arka planı';

  @override
  String get settings_chats_default_gradient => 'Varsayılan gradyan';

  @override
  String get settings_chats_inherit_global => 'Genel ayarları kullan';

  @override
  String get settings_chats_no_background => 'Arka plan yok';

  @override
  String get settings_chats_no_background_on => 'Arka plan yok (açık)';

  @override
  String get chat_list_title => 'Sohbetler';

  @override
  String get chat_list_search_hint => 'Ara…';

  @override
  String get chat_list_loading_connecting => 'Bağlanıyor…';

  @override
  String get chat_list_loading_conversations => 'Sohbetler yükleniyor…';

  @override
  String get chat_list_loading_list => 'Sohbet listesi yükleniyor…';

  @override
  String get chat_list_loading_sign_out => 'Çıkış yapılıyor…';

  @override
  String get chat_list_empty_search_title => 'Sohbet bulunamadı';

  @override
  String get chat_list_empty_search_body =>
      'Farklı bir sorgu deneyin. Arama ad ve kullanıcı adına göre çalışır.';

  @override
  String get chat_list_empty_folder_title => 'Bu klasör boş';

  @override
  String get chat_list_empty_folder_body =>
      'Klasörleri değiştirin veya yukarıdaki düğmeyi kullanarak yeni bir sohbet başlatın.';

  @override
  String get chat_list_empty_all_title => 'Henüz sohbet yok';

  @override
  String get chat_list_empty_all_body =>
      'Mesajlaşmaya başlamak için yeni bir sohbet başlatın.';

  @override
  String get chat_list_action_new_folder => 'Yeni klasör';

  @override
  String get chat_list_action_new_chat => 'Yeni sohbet';

  @override
  String get chat_list_action_create => 'Oluştur';

  @override
  String get chat_list_action_close => 'Kapat';

  @override
  String get chat_list_folders_title => 'Klasörler';

  @override
  String get chat_list_folders_subtitle => 'Bu sohbet için klasör seçin.';

  @override
  String get chat_list_folders_empty => 'Henüz özel klasör yok.';

  @override
  String get chat_list_create_folder_title => 'Yeni klasör';

  @override
  String get chat_list_create_folder_subtitle =>
      'Sohbetlerinizi hızla filtrelemek için bir klasör oluşturun.';

  @override
  String get chat_list_create_folder_name_label => 'KLASÖR ADI';

  @override
  String get chat_list_create_folder_name_hint => 'Klasör adı';

  @override
  String chat_list_create_folder_chats_label(Object count) {
    return 'SOHBETLER ($count)';
  }

  @override
  String get chat_list_create_folder_select_all => 'TÜMÜNÜ SEÇ';

  @override
  String get chat_list_create_folder_reset => 'SIFIRLA';

  @override
  String get chat_list_create_folder_search_hint => 'Ada göre ara…';

  @override
  String get chat_list_create_folder_no_matches => 'Eşleşen sohbet yok';

  @override
  String get chat_list_folder_default_starred => 'Yıldızlı';

  @override
  String get chat_list_folder_default_all => 'Tümü';

  @override
  String get chat_list_folder_default_new => 'Yeni';

  @override
  String get chat_list_folder_default_direct => 'Direkt';

  @override
  String get chat_list_folder_default_groups => 'Gruplar';

  @override
  String get chat_list_yesterday => 'Dün';

  @override
  String get chat_list_folder_delete_action => 'Sil';

  @override
  String get chat_list_folder_delete_title => 'Klasör silinsin mi?';

  @override
  String chat_list_folder_delete_body(Object name) {
    return '\"$name\" klasörü silinecek. Sohbetler bozulmadan kalacak.';
  }

  @override
  String chat_list_error_open_starred(Object error) {
    return 'Yıldızlılar açılamadı: $error';
  }

  @override
  String chat_list_error_delete_folder(Object error) {
    return 'Klasör silinemedi: $error';
  }

  @override
  String get chat_list_pin_not_available =>
      'Bu klasörde sabitleme kullanılamaz.';

  @override
  String chat_list_pin_pinned_in_folder(Object name) {
    return '\"$name\" klasöründe sohbet sabitlendi';
  }

  @override
  String chat_list_pin_unpinned_in_folder(Object name) {
    return '\"$name\" klasöründen sohbet kaldırıldı';
  }

  @override
  String chat_list_error_toggle_pin(Object error) {
    return 'Sabitleme değiştirilemedi: $error';
  }

  @override
  String chat_list_error_update_folder(Object error) {
    return 'Klasör güncellenemedi: $error';
  }

  @override
  String get chat_list_clear_history_title => 'Geçmiş temizlensin mi?';

  @override
  String get chat_list_clear_history_body =>
      'Mesajlar yalnızca sizin sohbet görünümünüzden kaybolacak. Diğer katılımcı geçmişi saklayacak.';

  @override
  String get chat_list_clear_history_confirm => 'Temizle';

  @override
  String chat_list_error_clear_history(Object error) {
    return 'Geçmiş temizlenemedi: $error';
  }

  @override
  String chat_list_error_mark_read(Object error) {
    return 'Sohbet okundu olarak işaretlenemedi: $error';
  }

  @override
  String get chat_list_delete_chat_title => 'Sohbet silinsin mi?';

  @override
  String get chat_list_delete_chat_body =>
      'Konuşma tüm katılımcılar için kalıcı olarak silinecek. Bu işlem geri alınamaz.';

  @override
  String get chat_list_delete_chat_confirm => 'Sil';

  @override
  String chat_list_error_delete_chat(Object error) {
    return 'Sohbet silinemedi: $error';
  }

  @override
  String get chat_list_context_folders => 'Klasörler';

  @override
  String get chat_list_context_unpin => 'Sohbet sabitlemesini kaldır';

  @override
  String get chat_list_context_pin => 'Sohbeti sabitle';

  @override
  String get chat_list_context_mark_all_read => 'Tümünü okundu olarak işaretle';

  @override
  String get chat_list_context_clear_history => 'Geçmişi temizle';

  @override
  String get chat_list_context_delete_chat => 'Sohbeti sil';

  @override
  String get chat_list_snackbar_history_cleared => 'Geçmiş temizlendi.';

  @override
  String get chat_list_snackbar_marked_read => 'Okundu olarak işaretlendi.';

  @override
  String chat_list_error_generic(Object error) {
    return 'Hata: $error';
  }

  @override
  String get chat_calls_title => 'Aramalar';

  @override
  String get chat_calls_search_hint => 'Ada göre ara…';

  @override
  String get chat_calls_empty => 'Arama geçmişiniz boş.';

  @override
  String get chat_calls_nothing_found => 'Hiçbir şey bulunamadı.';

  @override
  String chat_calls_error_load(Object error) {
    return 'Aramalar yüklenemedi:\n$error';
  }

  @override
  String get chat_reply_cancel_tooltip => 'Yanıtı iptal et';

  @override
  String get voice_preview_tooltip_cancel => 'İptal';

  @override
  String get voice_preview_tooltip_send => 'Gönder';

  @override
  String get profile_qr_title => 'QR kodum';

  @override
  String get profile_qr_tooltip_close => 'Kapat';

  @override
  String get profile_qr_share_title => 'LighChat profilim';

  @override
  String get profile_qr_share_subject => 'LighChat profili';

  @override
  String chat_media_norm_pending_title(Object mediaKind) {
    return '$mediaKind işleniyor…';
  }

  @override
  String chat_media_norm_failed_title(Object mediaKind) {
    return '$mediaKind işlenemedi';
  }

  @override
  String get chat_media_norm_pending_subtitle =>
      'Dosya sunucu işlemesinden sonra kullanılabilir olacak.';

  @override
  String get chat_media_norm_failed_subtitle =>
      'İşlemi tekrar başlatmayı deneyin.';

  @override
  String get conversation_threads_title => 'Konular';

  @override
  String get conversation_threads_empty => 'Henüz konu yok';

  @override
  String get conversation_threads_root_attachment => 'Ek';

  @override
  String get conversation_threads_root_message => 'Mesaj';

  @override
  String conversation_threads_snippet_you(Object text) {
    return 'Siz: $text';
  }

  @override
  String get conversation_threads_day_today => 'Bugün';

  @override
  String get conversation_threads_day_yesterday => 'Dün';

  @override
  String conversation_threads_replies_badge(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count yanıt',
      one: '$count yanıt',
    );
    return '$_temp0';
  }

  @override
  String get chat_meetings_title => 'Toplantılar';

  @override
  String get chat_meetings_subtitle =>
      'Konferanslar oluşturun ve katılımcı erişimini yönetin';

  @override
  String get chat_meetings_section_new => 'Yeni toplantı';

  @override
  String get chat_meetings_field_title_label => 'Toplantı başlığı';

  @override
  String get chat_meetings_field_title_hint => 'Örn., Lojistik toplantısı';

  @override
  String get chat_meetings_field_duration_label => 'Süre';

  @override
  String get chat_meetings_duration_unlimited => 'Sınır yok';

  @override
  String get chat_meetings_duration_15m => '15 dakika';

  @override
  String get chat_meetings_duration_30m => '30 dakika';

  @override
  String get chat_meetings_duration_1h => '1 saat';

  @override
  String get chat_meetings_duration_90m => '1,5 saat';

  @override
  String get chat_meetings_field_access_label => 'Erişim';

  @override
  String get chat_meetings_access_private => 'Özel';

  @override
  String get chat_meetings_access_public => 'Herkese açık';

  @override
  String get chat_meetings_waiting_room_title => 'Bekleme odası';

  @override
  String get chat_meetings_waiting_room_desc =>
      'Bekleme odası modunda kimin katılacağını siz kontrol edersiniz. “Kabul Et”\'e basana kadar misafirler bekleme ekranında kalır.';

  @override
  String get chat_meetings_backgrounds_title => 'Sanal arka planlar';

  @override
  String get chat_meetings_backgrounds_desc =>
      'İsterseniz arka planları yükleyin ve arka planınızı bulanıklaştırın. Galeriden bir resim seçin veya kendi arka planlarınızı yükleyin.';

  @override
  String get chat_meetings_create_button => 'Toplantı oluştur';

  @override
  String get chat_meetings_snackbar_enter_title => 'Toplantı başlığı girin';

  @override
  String get chat_meetings_snackbar_auth_required =>
      'Toplantı oluşturmak için giriş yapmanız gerekiyor';

  @override
  String chat_meetings_error_create_failed(Object error) {
    return 'Toplantı oluşturulamadı: $error';
  }

  @override
  String get chat_meetings_history_title => 'Geçmişiniz';

  @override
  String get chat_meetings_history_empty => 'Toplantı geçmişi boş';

  @override
  String chat_meetings_history_error(Object error) {
    return 'Toplantı geçmişi yüklenemedi: $error';
  }

  @override
  String get chat_meetings_status_live => 'canlı';

  @override
  String get chat_meetings_status_finished => 'tamamlandı';

  @override
  String get chat_meetings_badge_private => 'özel';

  @override
  String get chat_contacts_search_hint => 'Kişilerde ara…';

  @override
  String get chat_contacts_permission_denied => 'Kişiler izni verilmedi.';

  @override
  String chat_contacts_sync_error(Object error) {
    return 'Kişiler senkronize edilemedi: $error';
  }

  @override
  String chat_contacts_invite_prepare_failed(Object error) {
    return 'Davet hazırlanamadı: $error';
  }

  @override
  String get chat_contacts_matches_not_found => 'Eşleşme bulunamadı.';

  @override
  String chat_contacts_added_count(Object count) {
    return 'Eklenen kişiler: $count.';
  }

  @override
  String get chat_contacts_invite_text =>
      'LighChat’ı yükle: https://lighchat.online\nSeni LighChat’a davet ediyorum — işte yükleme bağlantısı.';

  @override
  String get chat_contacts_invite_subject => 'LighChat\'e davet';

  @override
  String chat_contacts_error_load(Object error) {
    return 'Kişiler yüklenemedi: $error';
  }

  @override
  String chat_list_item_draft_line(Object line) {
    return 'Taslak · $line';
  }

  @override
  String get chat_list_item_chat_created => 'Sohbet oluşturuldu';

  @override
  String get chat_list_item_no_messages_yet => 'Henüz mesaj yok';

  @override
  String get chat_list_item_history_cleared => 'Geçmiş temizlendi';

  @override
  String get chat_list_firebase_not_configured =>
      'Firebase henüz yapılandırılmadı.';

  @override
  String get new_chat_title => 'Yeni sohbet';

  @override
  String get new_chat_subtitle =>
      'Bir sohbet başlatmak için birini seçin veya bir grup oluşturun.';

  @override
  String get new_chat_search_hint => 'Ad, kullanıcı adı veya @tanıtıcı…';

  @override
  String get new_chat_create_group => 'Grup oluştur';

  @override
  String get new_chat_section_phone_contacts => 'TELEFON KİŞİLERİ';

  @override
  String get new_chat_section_contacts => 'KİŞİLER';

  @override
  String get new_chat_section_all_users => 'TÜM KULLANICILAR';

  @override
  String get new_chat_empty_no_users => 'Henüz sohbet başlatacak kimse yok.';

  @override
  String get new_chat_empty_not_found => 'Eşleşme bulunamadı.';

  @override
  String new_chat_error_contacts(Object error) {
    return 'Kişiler: $error';
  }

  @override
  String get new_chat_fallback_user_display_name => 'Kullanıcı';

  @override
  String get new_group_role_badge_admin => 'YÖNETİCİ';

  @override
  String get new_group_role_badge_worker => 'ÜYE';

  @override
  String new_group_error_auth_session(Object error) {
    return 'Giriş doğrulanamadı: $error';
  }

  @override
  String get invite_subject => 'LighChat\'te bana katıl';

  @override
  String get invite_text =>
      'LighChat’ı yükle: https://lighchat.online\\nSeni LighChat’a davet ediyorum — işte yükleme bağlantısı.';

  @override
  String get new_group_title => 'Grup oluştur';

  @override
  String get new_group_search_hint => 'Kullanıcı ara…';

  @override
  String get new_group_pick_photo_tooltip =>
      'Grup fotoğrafı seçmek için dokunun. Kaldırmak için uzun basın.';

  @override
  String get new_group_name_label => 'Grup adı';

  @override
  String get new_group_name_hint => 'Ad';

  @override
  String get new_group_description_label => 'Açıklama';

  @override
  String get new_group_description_hint => 'İsteğe bağlı';

  @override
  String new_group_members_count(Object count) {
    return 'Üyeler ($count)';
  }

  @override
  String get new_group_add_members_section => 'ÜYE EKLE';

  @override
  String get new_group_empty_no_users => 'Henüz eklenecek kimse yok.';

  @override
  String get new_group_empty_not_found => 'Eşleşme bulunamadı.';

  @override
  String get new_group_error_name_required => 'Lütfen bir grup adı girin.';

  @override
  String get new_group_error_members_required => 'En az bir üye ekleyin.';

  @override
  String get new_group_action_create => 'Oluştur';

  @override
  String get group_members_title => 'Üyeler';

  @override
  String get group_members_invite_link => 'Bağlantıyla davet et';

  @override
  String get group_members_admin_badge => 'YÖNETİCİ';

  @override
  String group_members_invite_text(Object groupName, Object inviteLink) {
    return 'LighChat\'te $groupName grubuna katıl: $inviteLink';
  }

  @override
  String get group_members_error_min_admin =>
      'Grupta en az bir yönetici kalmalıdır.';

  @override
  String get group_members_error_cannot_remove_creator =>
      'Grup oluşturucusunun yönetici haklarını kaldıramazsınız.';

  @override
  String get group_members_remove_admin => 'Yönetici hakları kaldırıldı';

  @override
  String get group_members_make_admin => 'Kullanıcı yönetici yapıldı';

  @override
  String get auth_brand_tagline => 'Daha güvenli bir mesajlaşma uygulaması';

  @override
  String get auth_firebase_not_ready =>
      'Firebase hazır değil. `firebase_options.dart` ve GoogleService-Info.plist dosyasını kontrol edin.';

  @override
  String get auth_redirecting_to_chats => 'Sohbetlere yönlendiriliyorsunuz…';

  @override
  String get auth_or => 'veya';

  @override
  String get auth_create_account => 'Hesap oluştur';

  @override
  String get auth_entry_sign_in => 'Giriş yap';

  @override
  String get auth_entry_sign_up => 'Hesap oluştur';

  @override
  String get auth_qr_title => 'QR ile giriş yap';

  @override
  String get auth_qr_hint =>
      'Zaten giriş yaptığınız bir cihazda LighChat\'i açın → Ayarlar → Cihazlar → Yeni cihaz bağla, ardından bu kodu tarayın.';

  @override
  String auth_qr_refresh_in(int seconds) {
    return '$seconds saniyede yenilenir';
  }

  @override
  String get auth_qr_other_method => 'Başka bir yolla giriş yap';

  @override
  String get auth_qr_approving => 'Giriş yapılıyor…';

  @override
  String get auth_qr_rejected => 'İstek reddedildi';

  @override
  String get auth_qr_retry => 'Tekrar dene';

  @override
  String get auth_qr_unknown_error => 'QR kodu oluşturulamadı.';

  @override
  String get auth_qr_use_qr_login => 'QR ile giriş yap';

  @override
  String get auth_privacy_policy => 'Gizlilik politikası';

  @override
  String get auth_error_open_privacy_policy => 'Gizlilik politikası açılamadı';

  @override
  String get voice_transcript_show => 'Metni göster';

  @override
  String get voice_transcript_hide => 'Metni gizle';

  @override
  String get voice_transcript_copy => 'Kopyala';

  @override
  String get voice_transcript_loading => 'Yazıya dökülüyor…';

  @override
  String get voice_transcript_failed => 'Metin alınamadı.';

  @override
  String get voice_attachment_media_kind_audio => 'ses';

  @override
  String get voice_attachment_load_failed => 'Yüklenemedi';

  @override
  String get voice_attachment_title_voice_message => 'Sesli mesaj';

  @override
  String voice_transcript_error(Object error) {
    return 'Yazıya dönüştürülemedi: $error';
  }

  @override
  String get chat_messages_title => 'Mesajlar';

  @override
  String get chat_call_decline => 'Reddet';

  @override
  String get chat_call_open => 'Aç';

  @override
  String get chat_call_accept => 'Kabul et';

  @override
  String video_call_error_init(Object error) {
    return 'Görüntülü arama hatası: $error';
  }

  @override
  String get video_call_ended => 'Arama sona erdi';

  @override
  String get video_call_status_missed => 'Cevapsız arama';

  @override
  String get video_call_status_cancelled => 'Arama iptal edildi';

  @override
  String get video_call_error_offer_not_ready =>
      'Teklif henüz hazır değil. Tekrar deneyin.';

  @override
  String get video_call_error_invalid_call_data => 'Geçersiz arama verisi';

  @override
  String video_call_error_accept_failed(Object error) {
    return 'Arama kabul edilemedi: $error';
  }

  @override
  String get video_call_incoming => 'Gelen görüntülü arama';

  @override
  String get video_call_connecting => 'Görüntülü arama…';

  @override
  String get video_call_pip_tooltip => 'Pencere içinde pencere';

  @override
  String get video_call_mini_window_tooltip => 'Mini pencere';

  @override
  String get chat_delete_message_title_single => 'Mesaj silinsin mi?';

  @override
  String get chat_delete_message_title_multi => 'Mesajlar silinsin mi?';

  @override
  String get chat_delete_message_body_single =>
      'Bu mesaj herkes için gizlenecek.';

  @override
  String chat_delete_message_body_multi(Object count) {
    return 'Silinecek mesaj sayısı: $count';
  }

  @override
  String get chat_delete_file_title => 'Dosya silinsin mi?';

  @override
  String get chat_delete_file_body =>
      'Yalnızca bu dosya mesajdan kaldırılacak.';

  @override
  String get forward_title => 'İlet';

  @override
  String get forward_empty_no_messages => 'İletilecek mesaj yok';

  @override
  String get forward_error_not_authorized => 'Giriş yapılmadı';

  @override
  String get forward_empty_no_recipients => 'İletilecek kişi veya sohbet yok';

  @override
  String get forward_search_hint => 'Kişilerde ara…';

  @override
  String get forward_empty_no_available_recipients =>
      'Kullanılabilir alıcı yok.\nYalnızca kişilerinize ve aktif sohbetlerinize iletebilirsiniz.';

  @override
  String get forward_empty_not_found => 'Hiçbir şey bulunamadı';

  @override
  String get forward_action_pick_recipients => 'Alıcıları seçin';

  @override
  String get forward_action_send => 'Gönder';

  @override
  String forward_error_generic(Object error) {
    return 'Hata: $error';
  }

  @override
  String get forward_sender_fallback => 'Katılımcı';

  @override
  String get forward_error_profiles_load =>
      'Sohbeti açmak için profiller yüklenemedi';

  @override
  String get forward_error_send_no_permissions =>
      'İletilemedi: seçilen sohbetlerden birine erişiminiz yok veya sohbet artık mevcut değil.';

  @override
  String get forward_error_send_forbidden_chat =>
      'İletilemedi: sohbetlerden birine erişim reddedildi.';

  @override
  String get share_picker_title => 'LighChat\'a paylaş';

  @override
  String get share_picker_empty_payload => 'Paylaşılacak içerik yok';

  @override
  String get share_picker_summary_text_only => 'Metin';

  @override
  String share_picker_summary_files_count(int count) {
    return 'Dosyalar: $count';
  }

  @override
  String share_picker_summary_files_with_text(int count) {
    return 'Dosyalar: $count + metin';
  }

  @override
  String get devices_title => 'Cihazlarım';

  @override
  String get devices_subtitle =>
      'Şifreleme açık anahtarınızın yayınlandığı cihazlar. İptal etme, tüm şifreli sohbetler için yeni bir anahtar dönemi oluşturur — iptal edilen cihaz yeni mesajları okuyamaz.';

  @override
  String get devices_empty => 'Henüz cihaz yok.';

  @override
  String get devices_connect_new_device => 'Yeni cihaz bağla';

  @override
  String get devices_approve_title =>
      'Bu cihazın giriş yapmasına izin verilsin mi?';

  @override
  String get devices_approve_body_hint =>
      'Bu cihazın QR kodu gösteren kendi cihazınız olduğundan emin olun.';

  @override
  String get devices_approve_allow => 'İzin ver';

  @override
  String get devices_approve_deny => 'Reddet';

  @override
  String get devices_handover_progress_title =>
      'Şifreli sohbetler senkronize ediliyor…';

  @override
  String devices_handover_progress_body(int done, int total) {
    return '$done/$total güncellendi';
  }

  @override
  String get devices_handover_progress_starting => 'Başlatılıyor…';

  @override
  String get devices_handover_success_title => 'Yeni cihaz bağlandı';

  @override
  String devices_handover_success_body(String label) {
    return '$label cihazı artık şifreli sohbetlerinize erişebilir.';
  }

  @override
  String devices_progress_rekeying(Object done, Object total) {
    return 'Sohbetler güncelleniyor: $done / $total';
  }

  @override
  String get devices_chip_current => 'Bu cihaz';

  @override
  String get devices_chip_revoked => 'İptal edildi';

  @override
  String devices_meta_created_activity(Object createdAt, Object lastSeenAt) {
    return 'Oluşturulma: $createdAt  •  Aktivite: $lastSeenAt';
  }

  @override
  String devices_meta_revoked_at(Object revokedAt) {
    return 'İptal edilme: $revokedAt';
  }

  @override
  String get devices_action_rename => 'Yeniden adlandır';

  @override
  String get devices_action_revoke => 'İptal et';

  @override
  String get devices_dialog_rename_title => 'Cihazı yeniden adlandır';

  @override
  String get devices_dialog_rename_hint => 'örn. iPhone 15 — Safari';

  @override
  String devices_error_rename_failed(Object error) {
    return 'Yeniden adlandırılamadı: $error';
  }

  @override
  String get devices_dialog_revoke_title => 'Cihaz iptal edilsin mi?';

  @override
  String get devices_dialog_revoke_body_current =>
      'BU cihazı iptal etmek üzeresiniz. Bundan sonra bu istemciden uçtan uca şifreli sohbetlerdeki yeni mesajları okuyamayacaksınız.';

  @override
  String get devices_dialog_revoke_body_other =>
      'Bu cihaz uçtan uca şifreli sohbetlerdeki yeni mesajları okuyamayacak. Eski mesajlar cihazda erişilebilir kalacak.';

  @override
  String devices_snackbar_revoked(Object rekeyed, Object suffix) {
    return 'Cihaz iptal edildi. Güncellenen sohbetler: $rekeyed$suffix';
  }

  @override
  String devices_snackbar_failed_suffix(Object count) {
    return ', hatalar: $count';
  }

  @override
  String devices_error_revoke_failed(Object error) {
    return 'İptal hatası: $error';
  }

  @override
  String get e2ee_recovery_title => 'E2EE — yedekleme';

  @override
  String get e2ee_password_label => 'Şifre';

  @override
  String get e2ee_password_confirm_label => 'Şifreyi onayla';

  @override
  String e2ee_password_min_length(Object count) {
    return 'En az $count karakter';
  }

  @override
  String get e2ee_password_mismatch => 'Parolalar eşleşmiyor';

  @override
  String get e2ee_backup_create_title => 'Anahtar yedeği oluştur';

  @override
  String get e2ee_backup_restore_title => 'Şifreyle geri yükle';

  @override
  String get e2ee_backup_restore_action => 'Geri yükle';

  @override
  String e2ee_backup_create_error(Object error) {
    return 'Yedek oluşturulamadı: $error';
  }

  @override
  String e2ee_backup_restore_error(Object error) {
    return 'Geri yüklenemedi: $error';
  }

  @override
  String get e2ee_backup_wrong_password => 'Yanlış şifre';

  @override
  String get e2ee_backup_not_found => 'Yedek bulunamadı';

  @override
  String e2ee_recovery_error_generic(Object error) {
    return 'Hata: $error';
  }

  @override
  String get e2ee_backup_password_card_title => 'Şifre yedeği';

  @override
  String get e2ee_backup_password_card_description =>
      'Özel anahtarınızın şifreli bir yedeğini oluşturun. Tüm cihazlarınızı kaybederseniz, yalnızca parola ile yeni bir cihazda geri yükleyebilirsiniz. Parola kurtarılamaz — güvenli bir yerde saklayın.';

  @override
  String get e2ee_backup_overwrite => 'Yedeğin üzerine yaz';

  @override
  String get e2ee_backup_create => 'Yedek oluştur';

  @override
  String get e2ee_backup_restore => 'Yedekten geri yükle';

  @override
  String get e2ee_backup_already_have => 'Zaten bir yedeğim var';

  @override
  String get e2ee_qr_transfer_title => 'Anahtarı QR ile aktar';

  @override
  String get e2ee_qr_transfer_description =>
      'Yeni cihazda QR gösterirsiniz, eskisinde taratırsınız. 6 haneli kodu doğrulayın — özel anahtar güvenli bir şekilde aktarılır.';

  @override
  String get e2ee_qr_transfer_open => 'QR eşleştirmesini aç';

  @override
  String get media_viewer_action_reply => 'Yanıtla';

  @override
  String get media_viewer_action_forward => 'İlet';

  @override
  String get media_viewer_action_send => 'Gönder';

  @override
  String get media_viewer_action_save => 'Kaydet';

  @override
  String get media_viewer_action_show_in_chat => 'Sohbette göster';

  @override
  String get media_viewer_action_delete => 'Sil';

  @override
  String get media_viewer_error_no_gallery_access =>
      'Galeriye kaydetme izni yok';

  @override
  String get media_viewer_error_share_unavailable_web =>
      'Web\'de paylaşım kullanılamıyor';

  @override
  String get media_viewer_error_file_not_found => 'Dosya bulunamadı';

  @override
  String get media_viewer_error_bad_media_url => 'Geçersiz medya URL\'si';

  @override
  String get media_viewer_error_bad_url => 'Geçersiz URL';

  @override
  String get media_viewer_error_unsupported_media_scheme =>
      'Desteklenmeyen medya türü';

  @override
  String media_viewer_error_http_status(Object status) {
    return 'Sunucu hatası (HTTP $status)';
  }

  @override
  String media_viewer_error_save_failed(Object error) {
    return 'Kaydedilemedi: $error';
  }

  @override
  String media_viewer_error_send_failed(Object error) {
    return 'Gönderilemedi: $error';
  }

  @override
  String get media_viewer_video_playback_speed => 'Oynatma hızı';

  @override
  String get media_viewer_video_quality => 'Kalite';

  @override
  String get media_viewer_video_quality_auto => 'Otomatik';

  @override
  String get media_viewer_error_quality_switch_failed =>
      'Kalite değiştirilemedi';

  @override
  String get media_viewer_error_pip_open_failed => 'PiP açılamadı';

  @override
  String get media_viewer_pip_not_supported =>
      'Bu cihazda pencere içinde pencere desteklenmiyor.';

  @override
  String get media_viewer_video_processing =>
      'Bu video sunucuda işleniyor ve yakında kullanılabilir olacak.';

  @override
  String get media_viewer_video_playback_failed => 'Video oynatılamadı.';

  @override
  String get common_none => 'Yok';

  @override
  String get group_member_role_admin => 'Yönetici';

  @override
  String get group_member_role_worker => 'Üye';

  @override
  String get profile_no_photo_to_view => 'Görüntülenecek profil fotoğrafı yok.';

  @override
  String get profile_chat_id_copied_toast => 'Sohbet kimliği kopyalandı';

  @override
  String get auth_register_error_open_link => 'Bağlantı açılamadı.';

  @override
  String get new_chat_error_self_profile_not_found =>
      'Profiliniz dizinde bulunamadı. Çıkış yapıp tekrar giriş yapmayı deneyin.';

  @override
  String get disappearing_messages_title => 'Kaybolan mesajlar';

  @override
  String get disappearing_messages_intro =>
      'Yeni mesajlar, seçilen süre sonunda (gönderildiği andan itibaren) sunucudan otomatik olarak silinir. Daha önce gönderilen mesajlar değiştirilmez.';

  @override
  String disappearing_messages_admin_only(Object summary) {
    return 'Bunu yalnızca grup yöneticileri değiştirebilir. Mevcut: $summary.';
  }

  @override
  String get disappearing_messages_snackbar_off =>
      'Kaybolan mesajlar kapatıldı.';

  @override
  String get disappearing_messages_snackbar_updated =>
      'Zamanlayıcı güncellendi.';

  @override
  String get disappearing_preset_off => 'Kapalı';

  @override
  String get disappearing_preset_1h => '1 sa';

  @override
  String get disappearing_preset_24h => '24 sa';

  @override
  String get disappearing_preset_7d => '7 gün';

  @override
  String get disappearing_preset_30d => '30 gün';

  @override
  String get disappearing_ttl_summary_off => 'Kapalı';

  @override
  String disappearing_ttl_minutes(Object count) {
    return '$count dk';
  }

  @override
  String disappearing_ttl_hours(Object count) {
    return '$count sa';
  }

  @override
  String disappearing_ttl_days(Object count) {
    return '$count gün';
  }

  @override
  String disappearing_ttl_weeks(Object count) {
    return '$count hft';
  }

  @override
  String get conversation_profile_e2ee_on => 'Açık';

  @override
  String get conversation_profile_e2ee_off => 'Kapalı';

  @override
  String get conversation_profile_e2ee_subtitle_on =>
      'Uçtan uca şifreleme açık. Ayrıntılar için dokunun.';

  @override
  String get conversation_profile_e2ee_subtitle_off =>
      'Uçtan uca şifreleme kapalı. Etkinleştirmek için dokunun.';

  @override
  String get partner_profile_title_fallback_group => 'Grup sohbeti';

  @override
  String get partner_profile_title_fallback_saved => 'Kayıtlı mesajlar';

  @override
  String get partner_profile_title_fallback_chat => 'Sohbet';

  @override
  String partner_profile_subtitle_group_member_count(Object count) {
    return '$count üye';
  }

  @override
  String get partner_profile_subtitle_saved_messages =>
      'Yalnızca sizin için mesajlar ve notlar';

  @override
  String get partner_profile_error_cannot_contact_user =>
      'Mevcut iletişim ayarlarıyla bu kullanıcıya ulaşamazsınız.';

  @override
  String partner_profile_error_open_chat(Object error) {
    return 'Sohbet açılamadı: $error';
  }

  @override
  String get partner_profile_call_peer_fallback => 'Eş';

  @override
  String get partner_profile_chat_not_created => 'Sohbet henüz oluşturulmadı';

  @override
  String get partner_profile_notifications_muted =>
      'Bildirimler sessize alındı';

  @override
  String get partner_profile_notifications_unmuted =>
      'Bildirimlerin sesi açıldı';

  @override
  String get partner_profile_notifications_change_failed =>
      'Bildirimler güncellenemedi';

  @override
  String get partner_profile_removed_from_contacts => 'Kişilerden kaldırıldı';

  @override
  String get partner_profile_remove_contact_failed =>
      'Kişilerden kaldırılamadı';

  @override
  String get partner_profile_contact_sent => 'Kişi gönderildi';

  @override
  String get partner_profile_share_failed_copied =>
      'Paylaşım başarısız. Kişi metni kopyalandı.';

  @override
  String get partner_profile_share_contact_header => 'LighChat\'te kişi';

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
    return 'LighChat kişi: $name';
  }

  @override
  String get partner_profile_tooltip_back => 'Geri';

  @override
  String get partner_profile_tooltip_close => 'Kapat';

  @override
  String get partner_profile_edit_contact_short => 'Düzenle';

  @override
  String get partner_profile_tooltip_copy_chat_id => 'Sohbet kimliğini kopyala';

  @override
  String get partner_profile_action_chats => 'Sohbetler';

  @override
  String get partner_profile_action_voice_call => 'Ara';

  @override
  String get partner_profile_action_video => 'Görüntülü';

  @override
  String get partner_profile_action_share => 'Paylaş';

  @override
  String get partner_profile_action_notifications => 'Uyarılar';

  @override
  String get partner_profile_menu_members => 'Üyeler';

  @override
  String get partner_profile_menu_edit_group => 'Grubu düzenle';

  @override
  String get partner_profile_menu_media_links_files =>
      'Medya, bağlantılar ve dosyalar';

  @override
  String get partner_profile_menu_starred => 'Yıldızlı';

  @override
  String get partner_profile_menu_threads => 'Konular';

  @override
  String get partner_profile_menu_games => 'Oyunlar';

  @override
  String get partner_profile_menu_block => 'Engelle';

  @override
  String get partner_profile_menu_unblock => 'Engeli kaldır';

  @override
  String get partner_profile_menu_notifications => 'Bildirimler';

  @override
  String get partner_profile_menu_chat_theme => 'Sohbet teması';

  @override
  String get partner_profile_menu_advanced_privacy =>
      'Gelişmiş sohbet gizliliği';

  @override
  String get partner_profile_privacy_trailing_default => 'Varsayılan';

  @override
  String get partner_profile_menu_encryption => 'Şifreleme';

  @override
  String get partner_profile_no_common_groups => 'ORTAK GRUP YOK';

  @override
  String partner_profile_create_group_with(Object name) {
    return '$name ile grup oluştur';
  }

  @override
  String get partner_profile_leave_group => 'Gruptan ayrıl';

  @override
  String get partner_profile_contacts_and_data => 'Kişi bilgileri';

  @override
  String get partner_profile_field_system_role => 'Sistem rolü';

  @override
  String get partner_profile_field_email => 'E-posta';

  @override
  String get partner_profile_field_phone => 'Telefon';

  @override
  String get partner_profile_field_birthday => 'Doğum günü';

  @override
  String get partner_profile_field_bio => 'Hakkında';

  @override
  String get partner_profile_add_to_contacts => 'Kişilere ekle';

  @override
  String get partner_profile_remove_from_contacts => 'Kişilerden kaldır';

  @override
  String get thread_search_hint => 'Konuda ara…';

  @override
  String get thread_search_tooltip_clear => 'Temizle';

  @override
  String get thread_search_tooltip_search => 'Ara';

  @override
  String thread_reply_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count yanıt',
      one: '$count yanıt',
      zero: '$count yanıt',
    );
    return '$_temp0';
  }

  @override
  String get thread_message_not_found => 'Mesaj bulunamadı';

  @override
  String get thread_screen_title_fallback => 'Konu';

  @override
  String thread_load_replies_error(Object error) {
    return 'Konu hatası: $error';
  }

  @override
  String get chat_message_empty_placeholder => 'Mesaj';

  @override
  String get chat_sender_you => 'Siz';

  @override
  String get chat_clipboard_nothing_to_paste =>
      'Panodan yapıştırılacak bir şey yok';

  @override
  String chat_clipboard_paste_failed(Object error) {
    return 'Panodan yapıştırılamadı: $error';
  }

  @override
  String chat_send_failed(Object error) {
    return 'Gönderilemedi: $error';
  }

  @override
  String chat_send_video_circle_failed(Object error) {
    return 'Video notu gönderilemedi: $error';
  }

  @override
  String get chat_service_unavailable => 'Hizmet kullanılamıyor';

  @override
  String get chat_repository_unavailable => 'Sohbet hizmeti kullanılamıyor';

  @override
  String get chat_still_loading => 'Sohbet hâlâ yükleniyor';

  @override
  String get chat_no_participants => 'Sohbet katılımcısı yok';

  @override
  String get chat_location_ios_geolocator_missing =>
      'Bu iOS derlemesinde konum bağlı değil. mobile/app/ios dizininde pod install çalıştırın ve yeniden derleyin.';

  @override
  String get chat_location_services_disabled => 'Konum hizmetlerini açın';

  @override
  String get chat_location_permission_denied => 'Konum kullanma izni yok';

  @override
  String chat_location_send_failed(Object error) {
    return 'Konum gönderilemedi: $error';
  }

  @override
  String get chat_poll_send_timeout => 'Anket gönderilemedi: zaman aşımı';

  @override
  String chat_poll_send_firebase(Object details) {
    return 'Anket gönderilemedi (Firestore): $details';
  }

  @override
  String chat_poll_send_known_error(Object details) {
    return 'Anket gönderilemedi: $details';
  }

  @override
  String chat_poll_send_failed(Object error) {
    return 'Anket gönderilemedi: $error';
  }

  @override
  String chat_delete_action_failed(Object error) {
    return 'Silinemedi: $error';
  }

  @override
  String get chat_media_transcode_retry_started =>
      'Dönüştürme tekrar denemesi başlatıldı';

  @override
  String chat_media_transcode_retry_failed(Object error) {
    return 'Dönüştürme yeniden denemesi başlatılamadı: $error';
  }

  @override
  String chat_parent_load_error(Object error) {
    return 'Hata: $error';
  }

  @override
  String get chat_message_not_found_in_loaded_history =>
      'Mesaj yüklenen geçmişte bulunamadı';

  @override
  String get chat_finish_editing_first => 'Önce düzenlemeyi bitirin';

  @override
  String chat_send_voice_failed(Object error) {
    return 'Sesli mesaj gönderilemedi: $error';
  }

  @override
  String get chat_starred_removed => 'Yıldızlılardan kaldırıldı';

  @override
  String get chat_starred_added => 'Yıldızlılara eklendi';

  @override
  String chat_starred_toggle_failed(Object error) {
    return 'Yıldızlılar güncellenemedi: $error';
  }

  @override
  String chat_reaction_toggle_failed(Object error) {
    return 'Tepki eklenemedi: $error';
  }

  @override
  String chat_emoji_burst_sync_failed(Object error) {
    return 'Emoji efekti senkronize edilemedi: $error';
  }

  @override
  String get chat_pin_already_pinned => 'Mesaj zaten sabitlenmiş';

  @override
  String chat_pin_limit_reached(int count) {
    return 'Sabitlenmiş mesaj sınırı ($count)';
  }

  @override
  String chat_pin_failed(Object error) {
    return 'Sabitlenemedi: $error';
  }

  @override
  String chat_unpin_failed(Object error) {
    return 'Sabitleme kaldırılamadı: $error';
  }

  @override
  String get chat_text_copied => 'Metin kopyalandı';

  @override
  String get chat_edit_attachments_not_allowed =>
      'Düzenleme sırasında ekler kullanılamaz';

  @override
  String get chat_edit_text_empty => 'Metin boş olamaz';

  @override
  String chat_e2ee_unavailable(Object code) {
    return 'Şifreleme kullanılamıyor: $code';
  }

  @override
  String chat_save_failed(Object error) {
    return 'Kaydedilemedi: $error';
  }

  @override
  String chat_load_messages_error(Object error) {
    return 'Mesajlar yüklenemedi: $error';
  }

  @override
  String chat_conversation_error(Object error) {
    return 'Sohbet hatası: $error';
  }

  @override
  String chat_auth_error(Object error) {
    return 'Kimlik doğrulama hatası: $error';
  }

  @override
  String get chat_poll_label => 'Anket';

  @override
  String get chat_location_label => 'Konum';

  @override
  String get chat_attachment_label => 'Ek';

  @override
  String chat_media_pick_failed(Object error) {
    return 'Medya seçilemedi: $error';
  }

  @override
  String chat_file_pick_failed(Object error) {
    return 'Dosya seçilemedi: $error';
  }

  @override
  String get chat_call_ongoing_video => 'Görüntülü arama devam ediyor';

  @override
  String get chat_call_ongoing_audio => 'Sesli arama devam ediyor';

  @override
  String get chat_call_incoming_video => 'Gelen görüntülü arama';

  @override
  String get chat_call_incoming_audio => 'Gelen sesli arama';

  @override
  String get message_menu_action_reply => 'Yanıtla';

  @override
  String get message_menu_action_thread => 'Konu';

  @override
  String get message_menu_action_copy => 'Kopyala';

  @override
  String get message_menu_action_edit => 'Düzenle';

  @override
  String get message_menu_action_pin => 'Sabitle';

  @override
  String get message_menu_action_star_add => 'Yıldızlılara ekle';

  @override
  String get message_menu_action_star_remove => 'Yıldızlılardan kaldır';

  @override
  String get message_menu_action_create_sticker => 'Çıkartma oluştur';

  @override
  String get message_menu_action_save_to_my_stickers => 'Çıkartmalarıma kaydet';

  @override
  String get message_menu_action_forward => 'İlet';

  @override
  String get message_menu_action_select => 'Seç';

  @override
  String get message_menu_action_delete => 'Sil';

  @override
  String get message_menu_initiator_deleted => 'Mesaj silindi';

  @override
  String get message_menu_header_sent => 'GÖNDERİLDİ:';

  @override
  String get message_menu_header_read => 'OKUNDU:';

  @override
  String get message_menu_header_expire_at => 'KAYBOLMA:';

  @override
  String get chat_header_search_hint => 'Mesajlarda ara…';

  @override
  String get chat_header_tooltip_threads => 'Konular';

  @override
  String get chat_header_tooltip_search => 'Ara';

  @override
  String get chat_header_tooltip_video_call => 'Görüntülü arama';

  @override
  String get chat_header_tooltip_audio_call => 'Sesli arama';

  @override
  String get conversation_games_title => 'Oyunlar';

  @override
  String get conversation_games_durak => 'Durak';

  @override
  String get conversation_games_durak_subtitle => 'Lobi oluştur';

  @override
  String get conversation_game_lobby_title => 'Lobi';

  @override
  String get conversation_game_lobby_not_found => 'Oyun bulunamadı';

  @override
  String conversation_game_lobby_error(Object error) {
    return 'Hata: $error';
  }

  @override
  String conversation_game_lobby_create_failed(Object error) {
    return 'Oyun oluşturulamadı: $error';
  }

  @override
  String conversation_game_lobby_game_id(Object id) {
    return 'Kimlik: $id';
  }

  @override
  String conversation_game_lobby_status(Object status) {
    return 'Durum: $status';
  }

  @override
  String conversation_game_lobby_players(Object count, Object max) {
    return 'Oyuncular: $count/$max';
  }

  @override
  String get conversation_game_lobby_join => 'Katıl';

  @override
  String get conversation_game_lobby_start => 'Başlat';

  @override
  String conversation_game_lobby_join_failed(Object error) {
    return 'Katılınamadı: $error';
  }

  @override
  String conversation_game_lobby_start_failed(Object error) {
    return 'Oyun başlatılamadı: $error';
  }

  @override
  String get conversation_game_send_test_move => 'Test hamlesi';

  @override
  String conversation_game_move_failed(Object error) {
    return 'Hamle reddedildi: $error';
  }

  @override
  String get conversation_durak_table_title => 'Masa';

  @override
  String get conversation_durak_hand_title => 'El';

  @override
  String get conversation_durak_role_attacker => 'Saldırıyor';

  @override
  String get conversation_durak_role_defender => 'Savunuyor';

  @override
  String get conversation_durak_role_thrower => 'Atıyor';

  @override
  String get conversation_durak_action_attack => 'Saldır';

  @override
  String get conversation_durak_action_defend => 'Savun';

  @override
  String get conversation_durak_action_take => 'Al';

  @override
  String get conversation_durak_action_beat => 'Yendi';

  @override
  String get conversation_durak_action_transfer => 'Aktar';

  @override
  String get conversation_durak_action_pass => 'Pas';

  @override
  String get conversation_durak_badge_taking => 'Alıyorum';

  @override
  String get conversation_durak_game_finished_title => 'Oyun bitti';

  @override
  String get conversation_durak_game_finished_no_loser =>
      'Bu sefer kaybeden yok.';

  @override
  String conversation_durak_game_finished_loser(Object uid) {
    return 'Kaybeden: $uid';
  }

  @override
  String conversation_durak_game_finished_winners(Object uids) {
    return 'Kazananlar: $uids';
  }

  @override
  String get conversation_durak_winner => 'Kazanan!';

  @override
  String get conversation_durak_play_again => 'Tekrar oyna';

  @override
  String get conversation_durak_back_to_chat => 'Sohbete dön';

  @override
  String get conversation_game_lobby_waiting_opponent => 'Rakip bekleniyor…';

  @override
  String get conversation_durak_drop_zone =>
      'Oynamak için kartı buraya bırakın';

  @override
  String get durak_settings_mode => 'Mod';

  @override
  String get durak_mode_podkidnoy => 'Podkidnoy';

  @override
  String get durak_mode_perevodnoy => 'Perevodnoy';

  @override
  String get durak_settings_max_players => 'Oyuncular';

  @override
  String get durak_settings_deck => 'Deste';

  @override
  String get durak_deck_36 => '36 kart';

  @override
  String get durak_deck_52 => '52 kart';

  @override
  String get durak_settings_with_jokers => 'Jokerler';

  @override
  String get durak_settings_turn_timer => 'Tur zamanlayıcısı';

  @override
  String get durak_turn_timer_off => 'Kapalı';

  @override
  String get durak_settings_throw_in_policy => 'Kim atabilir';

  @override
  String get durak_throw_in_policy_all => 'Tüm oyuncular (savunan hariç)';

  @override
  String get durak_throw_in_policy_neighbors => 'Yalnızca savunanın komşuları';

  @override
  String get durak_settings_shuler => 'Şuler modu';

  @override
  String get durak_settings_shuler_subtitle =>
      'Biri ihlal çağrısı yapana kadar kurallara aykırı hamlelere izin verir.';

  @override
  String get conversation_durak_action_foul => 'İhlal!';

  @override
  String get conversation_durak_action_resolve => 'Yengiyi Onayla';

  @override
  String get conversation_durak_foul_toast => 'İhlal! Hileci cezalandırıldı.';

  @override
  String get durak_phase_prefix => 'Aşama';

  @override
  String get durak_phase_attack => 'Saldır';

  @override
  String get durak_phase_defense => 'Savunma';

  @override
  String get durak_phase_throw_in => 'Atma';

  @override
  String get durak_phase_resolution => 'Sonuçlandırma';

  @override
  String get durak_phase_finished => 'Tamamlandı';

  @override
  String get durak_phase_pending_foul => 'Yengi sonrası ihlal bekleniyor';

  @override
  String get durak_phase_pending_foul_hint_attacker =>
      'İhlal çağrısı bekleyin. Kimse çağrı yapmazsa Yengiyi Onaylayın.';

  @override
  String get durak_phase_pending_foul_hint_other =>
      'İhlal çağrısı bekleyin. Hile fark ettiyseniz İhlal! deyin.';

  @override
  String get durak_phase_hint_can_throw_in => 'Atabilirsiniz';

  @override
  String get durak_phase_hint_wait => 'Sıranızı bekleyin';

  @override
  String durak_now_throwing_in(Object name) {
    return 'Şimdi atan: $name';
  }

  @override
  String chat_selection_selected_count(int count) {
    return '$count seçili';
  }

  @override
  String get chat_selection_tooltip_forward => 'İlet';

  @override
  String get chat_selection_tooltip_delete => 'Sil';

  @override
  String get chat_composer_hint_message => 'Bir mesaj yazın…';

  @override
  String get chat_composer_tooltip_stickers => 'Çıkartmalar';

  @override
  String get chat_composer_tooltip_attachments => 'Ekler';

  @override
  String get chat_list_unread_separator => 'Okunmamış mesajlar';

  @override
  String get chat_e2ee_decrypt_failed_open_devices =>
      'Şifre çözülemedi. Ayarlar → Cihazlar bölümünü açın';

  @override
  String get chat_e2ee_encrypted_message_placeholder => 'Şifreli mesaj';

  @override
  String chat_forwarded_from(Object name) {
    return '$name adlı kişiden iletildi';
  }

  @override
  String get chat_outbox_retry => 'Tekrar dene';

  @override
  String get chat_outbox_remove => 'Kaldır';

  @override
  String get chat_outbox_cancel => 'İptal';

  @override
  String get chat_message_edited_badge_short => 'DÜZENLENDİ';

  @override
  String get register_error_enter_name => 'Adınızı girin.';

  @override
  String get register_error_enter_username => 'Bir kullanıcı adı girin.';

  @override
  String get register_error_enter_phone => 'Bir telefon numarası girin.';

  @override
  String get register_error_invalid_phone =>
      'Geçerli bir telefon numarası girin.';

  @override
  String get register_error_enter_email => 'Bir e-posta girin.';

  @override
  String get register_error_enter_password => 'Bir şifre girin.';

  @override
  String get register_error_repeat_password => 'Şifreyi tekrarlayın.';

  @override
  String get register_error_dob_format =>
      'Doğum tarihini gg.aa.yyyy biçiminde girin';

  @override
  String get register_error_accept_privacy_policy =>
      'Lütfen gizlilik politikasını kabul ettiğinizi onaylayın';

  @override
  String get register_privacy_required =>
      'Gizlilik politikasının kabul edilmesi gereklidir';

  @override
  String get register_label_name => 'Ad';

  @override
  String get register_hint_name => 'Adınızı girin';

  @override
  String get register_label_username => 'Kullanıcı adı';

  @override
  String get register_hint_username => 'Bir kullanıcı adı girin';

  @override
  String get register_label_phone => 'Telefon';

  @override
  String get register_hint_choose_country => 'Bir ülke seçin';

  @override
  String get register_label_email => 'E-posta';

  @override
  String get register_hint_email => 'E-postanızı girin';

  @override
  String get register_label_password => 'Şifre';

  @override
  String get register_hint_password => 'Şifrenizi girin';

  @override
  String get register_label_confirm_password => 'Şifreyi onayla';

  @override
  String get register_hint_confirm_password => 'Şifrenizi tekrarlayın';

  @override
  String get register_label_dob => 'Doğum tarihi';

  @override
  String get register_hint_dob => 'gg.aa.yyyy';

  @override
  String get register_label_bio => 'Hakkında';

  @override
  String get register_hint_bio => 'Kendinizden bahsedin…';

  @override
  String get register_privacy_prefix => 'Kabul ediyorum ';

  @override
  String get register_privacy_link_text => 'Kişisel verilerin işlenmesine onay';

  @override
  String get register_privacy_and => ' ve ';

  @override
  String get register_terms_link_text =>
      'Gizlilik politikası kullanıcı sözleşmesi';

  @override
  String get register_button_create_account => 'Hesap oluştur';

  @override
  String get register_country_search_hint => 'Ülke veya koda göre arayın';

  @override
  String get register_date_picker_help => 'Doğum tarihi';

  @override
  String get register_date_picker_cancel => 'İptal';

  @override
  String get register_date_picker_confirm => 'Seç';

  @override
  String get register_pick_avatar_title => 'Avatar seç';

  @override
  String get edit_group_title => 'Grubu düzenle';

  @override
  String get edit_group_save => 'Kaydet';

  @override
  String get edit_group_cancel => 'İptal';

  @override
  String get edit_group_name_label => 'Grup adı';

  @override
  String get edit_group_name_hint => 'Ad';

  @override
  String get edit_group_description_label => 'Açıklama';

  @override
  String get edit_group_description_hint => 'İsteğe bağlı';

  @override
  String get edit_group_pick_photo_tooltip =>
      'Grup fotoğrafı seçmek için dokunun. Kaldırmak için uzun basın.';

  @override
  String get edit_group_error_name_required => 'Lütfen bir grup adı girin.';

  @override
  String get edit_group_error_save_failed => 'Grup kaydedilemedi.';

  @override
  String get edit_group_error_not_found => 'Grup bulunamadı.';

  @override
  String get edit_group_error_permission_denied =>
      'Bu grubu düzenleme izniniz yok.';

  @override
  String get edit_group_success => 'Grup güncellendi.';

  @override
  String get edit_group_privacy_section => 'GİZLİLİK';

  @override
  String get edit_group_privacy_forwarding => 'Mesaj iletme';

  @override
  String get edit_group_privacy_forwarding_desc =>
      'Üyelerin bu gruptan mesaj iletmesine izin ver.';

  @override
  String get edit_group_privacy_screenshots => 'Ekran görüntüleri';

  @override
  String get edit_group_privacy_screenshots_desc =>
      'Bu grupta ekran görüntülerine izin ver (platforma bağlı).';

  @override
  String get edit_group_privacy_copy => 'Metin kopyalama';

  @override
  String get edit_group_privacy_copy_desc =>
      'Mesaj metnini kopyalamaya izin ver.';

  @override
  String get edit_group_privacy_save_media => 'Medyayı kaydet';

  @override
  String get edit_group_privacy_save_media_desc =>
      'Fotoğrafları ve videoları cihaza kaydetmeye izin ver.';

  @override
  String get edit_group_privacy_share_media => 'Medyayı paylaş';

  @override
  String get edit_group_privacy_share_media_desc =>
      'Medya dosyalarını uygulama dışında paylaşmaya izin ver.';

  @override
  String get schedule_message_sheet_title => 'Mesajı planla';

  @override
  String get schedule_message_long_press_hint => 'Planlanmış gönderim';

  @override
  String schedule_message_preset_today_at(String time) {
    return 'Bugün $time';
  }

  @override
  String schedule_message_preset_tomorrow_at(String time) {
    return 'Yarın $time';
  }

  @override
  String schedule_message_will_send_at(String datetime) {
    return 'Gönderilecek: $datetime';
  }

  @override
  String get schedule_message_must_be_in_future =>
      'Zaman gelecekte olmalıdır (en az bir dakika sonra).';

  @override
  String get schedule_message_e2ee_warning =>
      'Bu bir E2EE sohbetidir. Planlanmış mesaj sunucuda düz metin olarak saklanacak ve şifrelenmeden yayınlanacak.';

  @override
  String get schedule_message_cancel => 'İptal';

  @override
  String get schedule_message_confirm => 'Planla';

  @override
  String get schedule_message_save => 'Kaydet';

  @override
  String get schedule_message_text_required => 'Önce bir mesaj yazın';

  @override
  String get schedule_message_attachments_unsupported_mobile =>
      'Ek planlaması şu anda yalnızca web\'de destekleniyor';

  @override
  String schedule_message_scheduled_toast(String datetime) {
    return 'Planlandı: $datetime';
  }

  @override
  String schedule_message_failed_toast(String error) {
    return 'Planlama başarısız: $error';
  }

  @override
  String get scheduled_messages_screen_title => 'Planlanmış mesajlar';

  @override
  String get scheduled_messages_empty_title => 'Planlanmış mesaj yok';

  @override
  String get scheduled_messages_empty_hint =>
      'Mesaj planlamak için Gönder düğmesini basılı tutun.';

  @override
  String scheduled_messages_load_failed(String error) {
    return 'Yüklenemedi: $error';
  }

  @override
  String get scheduled_messages_e2ee_notice =>
      'E2EE sohbetinde, planlanmış mesajlar düz metin olarak saklanır ve yayınlanır.';

  @override
  String get scheduled_messages_cancel_dialog_title =>
      'Planlanmış gönderim iptal edilsin mi?';

  @override
  String get scheduled_messages_cancel_dialog_body =>
      'Planlanmış mesaj silinecek.';

  @override
  String get scheduled_messages_cancel_dialog_keep => 'Sakla';

  @override
  String get scheduled_messages_cancel_dialog_confirm => 'İptal';

  @override
  String get scheduled_messages_canceled_toast => 'İptal edildi';

  @override
  String scheduled_messages_time_changed_toast(String datetime) {
    return 'Zaman değiştirildi: $datetime';
  }

  @override
  String scheduled_messages_action_failed_toast(String error) {
    return 'Hata: $error';
  }

  @override
  String get scheduled_messages_tile_edit_tooltip => 'Zamanı değiştir';

  @override
  String get scheduled_messages_tile_cancel_tooltip => 'İptal';

  @override
  String scheduled_messages_preview_poll(String question) {
    return 'Anket: $question';
  }

  @override
  String get scheduled_messages_preview_location => 'Konum';

  @override
  String get scheduled_messages_preview_attachment => 'Ek';

  @override
  String scheduled_messages_preview_attachment_count(int count) {
    return 'Ek (×$count)';
  }

  @override
  String get scheduled_messages_preview_message => 'Mesaj';

  @override
  String get chat_header_tooltip_scheduled => 'Planlanmış mesajlar';

  @override
  String get schedule_date_label => 'Tarih';

  @override
  String get schedule_time_label => 'Saat';

  @override
  String get common_done => 'Bitti';

  @override
  String get common_send => 'Gönder';

  @override
  String get common_open => 'Aç';

  @override
  String get common_add => 'Ekle';

  @override
  String get common_search => 'Ara';

  @override
  String get common_edit => 'Düzenle';

  @override
  String get common_next => 'Sonraki';

  @override
  String get common_ok => 'Tamam';

  @override
  String get common_confirm => 'Onayla';

  @override
  String get common_ready => 'Hazır';

  @override
  String get common_error => 'Hata';

  @override
  String get common_yes => 'Evet';

  @override
  String get common_no => 'Hayır';

  @override
  String get common_back => 'Geri';

  @override
  String get common_continue => 'Devam et';

  @override
  String get common_loading => 'Yükleniyor…';

  @override
  String get common_copy => 'Kopyala';

  @override
  String get common_share => 'Paylaş';

  @override
  String get common_settings => 'Ayarlar';

  @override
  String get common_today => 'Bugün';

  @override
  String get common_yesterday => 'Dün';

  @override
  String get e2ee_qr_title => 'QR anahtar eşleştirmesi';

  @override
  String get e2ee_qr_uid_error => 'Kullanıcı uid alınamadı.';

  @override
  String get e2ee_qr_session_ended_error =>
      'İkinci cihaz yanıt vermeden oturum sona erdi.';

  @override
  String get e2ee_qr_no_data_error => 'Anahtarı uygulamak için veri yok.';

  @override
  String get e2ee_qr_key_transferred_toast =>
      'Anahtar aktarıldı. Oturumları yenilemek için sohbetlere tekrar girin.';

  @override
  String get e2ee_qr_wrong_account_error =>
      'QR farklı bir hesap için oluşturuldu.';

  @override
  String get e2ee_qr_explainer_title => 'Bu nedir';

  @override
  String get e2ee_qr_explainer_text =>
      'Özel anahtarı ECDH + QR ile bir cihazınızdan diğerine aktarın. Her iki taraf da manuel doğrulama için 6 haneli bir kod görür.';

  @override
  String get e2ee_qr_show_qr_label => 'Yeni cihazdayım — QR göster';

  @override
  String get e2ee_qr_scan_qr_label => 'Zaten anahtarım var — QR tara';

  @override
  String get e2ee_qr_scan_hint =>
      'Anahtarı zaten olan eski cihazdaki QR\'ı tarayın.';

  @override
  String get e2ee_qr_verify_code_label =>
      '6 haneli kodu eski cihazla doğrulayın:';

  @override
  String e2ee_qr_transfer_from_device_label(String label) {
    return 'Cihazdan aktar: $label';
  }

  @override
  String get e2ee_qr_code_match_apply_label => 'Kod eşleşiyor — uygula';

  @override
  String get e2ee_qr_key_success_label =>
      'Anahtar bu cihaza başarıyla aktarıldı. Sohbetlere tekrar girin.';

  @override
  String get e2ee_qr_unknown_error => 'Bilinmeyen hata';

  @override
  String get e2ee_qr_back_to_pick_label => 'Seçime geri dön';

  @override
  String get e2ee_qr_donor_scan_hint =>
      'Kamerayı yeni cihazda gösterilen QR\'a doğrultun.';

  @override
  String get e2ee_qr_donor_verify_code_label => 'Kodu yeni cihazla doğrulayın:';

  @override
  String get e2ee_qr_donor_verify_hint =>
      'Kod eşleşiyorsa — yeni cihazda onaylayın. Eşleşmiyorsa hemen İptal\'e basın.';

  @override
  String get e2ee_encrypt_title => 'Şifreleme';

  @override
  String get e2ee_encrypt_enable_dialog_title =>
      'Şifreleme etkinleştirilsin mi?';

  @override
  String get e2ee_encrypt_enable_dialog_body =>
      'Yeni mesajlar yalnızca sizin ve kişinizin cihazlarında kullanılabilir olacak. Eski mesajlar oldukları gibi kalacak.';

  @override
  String get e2ee_encrypt_enable_label => 'Etkinleştir';

  @override
  String get e2ee_encrypt_disable_dialog_title =>
      'Şifreleme devre dışı bırakılsın mı?';

  @override
  String get e2ee_encrypt_disable_dialog_body =>
      'Yeni mesajlar uçtan uca şifreleme olmadan gönderilecek. Daha önce gönderilen şifreli mesajlar akışta kalacak.';

  @override
  String get e2ee_encrypt_disable_label => 'Devre dışı bırak';

  @override
  String get e2ee_encrypt_status_on =>
      'Bu sohbet için uçtan uca şifreleme etkinleştirildi.';

  @override
  String get e2ee_encrypt_status_off => 'Uçtan uca şifreleme devre dışı.';

  @override
  String get e2ee_encrypt_description =>
      'Şifreleme etkinleştirildiğinde, yeni mesaj içeriği yalnızca sohbet katılımcılarının cihazlarında kullanılabilir. Devre dışı bırakmak yalnızca yeni mesajları etkiler.';

  @override
  String get e2ee_encrypt_switch_title => 'Şifrelemeyi etkinleştir';

  @override
  String e2ee_encrypt_switch_on(int epoch) {
    return 'Etkin (anahtar dönemi: $epoch)';
  }

  @override
  String get e2ee_encrypt_switch_off => 'Devre dışı';

  @override
  String get e2ee_encrypt_already_on_toast =>
      'Şifreleme zaten etkin veya anahtar oluşturma başarısız oldu. Ağı ve kişinizin anahtarlarını kontrol edin.';

  @override
  String get e2ee_encrypt_no_device_toast =>
      'Etkinleştirilemedi: kişinin anahtarlı aktif bir cihazı yok.';

  @override
  String e2ee_encrypt_enable_failed_toast(String error) {
    return 'Şifreleme etkinleştirilemedi: $error';
  }

  @override
  String e2ee_encrypt_disable_failed_toast(String error) {
    return 'Devre dışı bırakılamadı: $error';
  }

  @override
  String get e2ee_encrypt_data_types_title => 'Veri türleri';

  @override
  String get e2ee_encrypt_data_types_description =>
      'Bu ayar protokolü değiştirmez. Hangi veri türlerinin şifreli gönderileceğini kontrol eder.';

  @override
  String get e2ee_encrypt_override_title => 'Bu sohbet için şifreleme ayarları';

  @override
  String get e2ee_encrypt_override_on =>
      'Sohbet düzeyinde ayarlar kullanılıyor.';

  @override
  String get e2ee_encrypt_override_off => 'Genel ayarlar devralınıyor.';

  @override
  String get e2ee_encrypt_text_title => 'Mesaj metni';

  @override
  String get e2ee_encrypt_media_title => 'Ekler (medya/dosyalar)';

  @override
  String get e2ee_encrypt_override_hint =>
      'Bu sohbet için değiştirmek istiyorsanız — geçersiz kılmayı etkinleştirin.';

  @override
  String get sticker_default_pack_name => 'Paketim';

  @override
  String get sticker_new_pack_dialog_title => 'Yeni çıkartma paketi';

  @override
  String get sticker_pack_name_hint => 'Ad';

  @override
  String get sticker_save_to_pack => 'Çıkartma paketine kaydet';

  @override
  String get sticker_no_packs_hint =>
      'Paket yok. Çıkartmalar sekmesinde bir tane oluşturun.';

  @override
  String get sticker_new_pack_option => 'Yeni paket…';

  @override
  String get sticker_pick_image_or_gif => 'Bir resim veya GIF seçin';

  @override
  String sticker_send_failed(String error) {
    return 'Gönderme başarısız: $error';
  }

  @override
  String get sticker_saved_to_pack => 'Çıkartma paketine kaydedildi';

  @override
  String get sticker_save_gif_failed => 'GIF indirilemedi veya kaydedilemedi';

  @override
  String get sticker_delete_pack_title => 'Paket silinsin mi?';

  @override
  String sticker_delete_pack_body(String name) {
    return '\"$name\" ve içindeki tüm çıkartmalar silinecek.';
  }

  @override
  String get sticker_pack_deleted => 'Paket silindi';

  @override
  String get sticker_pack_delete_failed => 'Paket silinemedi';

  @override
  String get sticker_tab_emoji => 'EMOJİ';

  @override
  String get sticker_tab_stickers => 'ÇIKARTMALAR';

  @override
  String get sticker_tab_gif => 'GIF';

  @override
  String get sticker_scope_my => 'Benim';

  @override
  String get sticker_scope_public => 'Herkese açık';

  @override
  String get sticker_new_pack_tooltip => 'Yeni paket';

  @override
  String get sticker_pack_created => 'Çıkartma paketi oluşturuldu';

  @override
  String get sticker_no_packs_create =>
      'Çıkartma paketi yok. Bir tane oluşturun.';

  @override
  String get sticker_public_packs_empty =>
      'Herkese açık paket yapılandırılmadı';

  @override
  String get sticker_section_recent => 'SON KULLANILANLAR';

  @override
  String get sticker_pack_empty_hint =>
      'Paket boş. Cihazdan ekleyin (GIF sekmesi — \"Paketime\").';

  @override
  String get sticker_delete_sticker_title => 'Çıkartma silinsin mi?';

  @override
  String get sticker_deleted => 'Silindi';

  @override
  String get sticker_gallery => 'Galeri';

  @override
  String get sticker_gallery_subtitle =>
      'Cihazdan fotoğraflar, PNG, GIF — doğrudan sohbete';

  @override
  String get gif_search_hint => 'GIF ara…';

  @override
  String gif_translated_hint(String query) {
    return 'Aranan: $query';
  }

  @override
  String get gif_search_unavailable =>
      'GIF araması geçici olarak kullanılamıyor.';

  @override
  String get gif_filter_all => 'Tümü';

  @override
  String get sticker_section_animated => 'HAREKETLİ';

  @override
  String get sticker_emoji_unavailable =>
      'Bu pencere için emoji-metin dönüşümü kullanılamıyor.';

  @override
  String get sticker_create_pack_hint => '+ düğmesiyle bir paket oluşturun';

  @override
  String get sticker_public_packs_unavailable =>
      'Herkese açık paketler henüz mevcut değil';

  @override
  String get composer_link_title => 'Bağlantı';

  @override
  String get composer_link_apply => 'Uygula';

  @override
  String get composer_attach_title => 'Ekle';

  @override
  String get composer_attach_photo_video => 'Fotoğraf/Video';

  @override
  String get composer_attach_files => 'Dosyalar';

  @override
  String get composer_attach_video_circle => 'Video daire';

  @override
  String get composer_attach_location => 'Konum';

  @override
  String get composer_attach_poll => 'Anket';

  @override
  String get composer_attach_stickers => 'Çıkartmalar';

  @override
  String get composer_attach_clipboard => 'Pano';

  @override
  String get composer_attach_text => 'Metin';

  @override
  String get meeting_create_poll => 'Anket oluştur';

  @override
  String get meeting_min_two_options => 'En az 2 cevap seçeneği gereklidir';

  @override
  String meeting_error_with_details(String details) {
    return 'Hata: $details';
  }

  @override
  String meeting_polls_load_error(String details) {
    return 'Anketler yüklenemedi: $details';
  }

  @override
  String get meeting_no_polls_yet => 'Henüz anket yok';

  @override
  String get meeting_question_label => 'Soru';

  @override
  String get meeting_options_label => 'Seçenekler';

  @override
  String meeting_option_hint(int index) {
    return 'Seçenek $index';
  }

  @override
  String get meeting_add_option => 'Seçenek ekle';

  @override
  String get meeting_anonymous => 'Anonim';

  @override
  String get meeting_anonymous_subtitle =>
      'Başkalarının tercihlerini kim görebilir';

  @override
  String get meeting_save_as_draft => 'Taslak olarak kaydet';

  @override
  String get meeting_publish => 'Yayınla';

  @override
  String get meeting_action_start => 'Başlat';

  @override
  String get meeting_action_change_vote => 'Oyu değiştir';

  @override
  String get meeting_action_restart => 'Yeniden başlat';

  @override
  String get meeting_action_stop => 'Durdur';

  @override
  String meeting_vote_failed(String details) {
    return 'Oy sayılmadı: $details';
  }

  @override
  String get meeting_status_ended => 'Sona erdi';

  @override
  String get meeting_status_draft => 'Taslak';

  @override
  String get meeting_status_active => 'Aktif';

  @override
  String get meeting_status_public => 'Herkese açık';

  @override
  String meeting_votes_count(int count) {
    return '$count oy';
  }

  @override
  String meeting_goal_count(int count) {
    return 'Hedef: $count';
  }

  @override
  String get meeting_hide => 'Gizle';

  @override
  String get meeting_who_voted => 'Kim oy verdi';

  @override
  String meeting_participants_tab(int count) {
    return 'Üyeler ($count)';
  }

  @override
  String meeting_polls_tab_active(int count) {
    return 'Anketler ($count)';
  }

  @override
  String get meeting_polls_tab => 'Anketler';

  @override
  String meeting_chat_tab_unread(int count) {
    return 'Sohbet ($count)';
  }

  @override
  String get meeting_chat_tab => 'Sohbet';

  @override
  String meeting_requests_tab(int count) {
    return 'İstekler ($count)';
  }

  @override
  String meeting_you_suffix(String name) {
    return '$name (Siz)';
  }

  @override
  String get meeting_host_label => 'Ev sahibi';

  @override
  String get meeting_force_mute_mic => 'Mikrofonu sessize al';

  @override
  String get meeting_force_mute_camera => 'Kamerayı kapat';

  @override
  String get meeting_kick_from_room => 'Odadan kaldır';

  @override
  String meeting_chat_load_error(Object error) {
    return 'Sohbet yüklenemedi: $error';
  }

  @override
  String get meeting_no_requests => 'Yeni istek yok';

  @override
  String get meeting_no_messages_yet => 'Henüz mesaj yok';

  @override
  String meeting_file_too_large(String name) {
    return 'Dosya çok büyük: $name';
  }

  @override
  String meeting_send_failed(String details) {
    return 'Gönderilemedi: $details';
  }

  @override
  String get meeting_edit_message_title => 'Mesajı düzenle';

  @override
  String meeting_save_failed(String details) {
    return 'Kaydedilemedi: $details';
  }

  @override
  String get meeting_delete_message_title => 'Mesaj silinsin mi?';

  @override
  String get meeting_delete_message_body => 'Üyeler \"Mesaj silindi\" görecek.';

  @override
  String meeting_delete_failed(String details) {
    return 'Silinemedi: $details';
  }

  @override
  String get meeting_message_hint => 'Mesaj…';

  @override
  String get meeting_message_deleted => 'Mesaj silindi';

  @override
  String get meeting_message_edited => '• düzenlendi';

  @override
  String get meeting_copy_action => 'Kopyala';

  @override
  String get meeting_edit_action => 'Düzenle';

  @override
  String get meeting_join_title => 'Katıl';

  @override
  String meeting_loading_error(String details) {
    return 'Toplantı yüklenirken hata: $details';
  }

  @override
  String get meeting_not_found => 'Toplantı bulunamadı veya kapatıldı';

  @override
  String get meeting_private_description =>
      'Özel toplantı: ev sahibi isteğinizden sonra sizi kabul edip etmeyeceğine karar verecek.';

  @override
  String get meeting_public_description =>
      'Açık toplantı: bekleme olmadan bağlantıyla katılın.';

  @override
  String get meeting_your_name_label => 'Adınız';

  @override
  String get meeting_enter_name_error => 'Adınızı girin';

  @override
  String get meeting_guest_name => 'Misafir';

  @override
  String get meeting_enter_room => 'Odaya gir';

  @override
  String get meeting_request_join => 'Katılma isteği';

  @override
  String get meeting_approved_title => 'Onaylandı';

  @override
  String get meeting_approved_subtitle => 'Odaya yönlendiriliyor…';

  @override
  String get meeting_denied_title => 'Reddedildi';

  @override
  String get meeting_denied_subtitle => 'Ev sahibi isteğinizi reddetti.';

  @override
  String get meeting_pending_title => 'Onay bekleniyor';

  @override
  String get meeting_pending_subtitle =>
      'Ev sahibi isteğinizi görecek ve sizi ne zaman kabul edeceğine karar verecek.';

  @override
  String meeting_load_error(String details) {
    return 'Toplantı yüklenemedi: $details';
  }

  @override
  String meeting_init_error(Object error) {
    return 'Başlatma hatası: $error';
  }

  @override
  String meeting_participants_error(Object error) {
    return 'Üyeler: $error';
  }

  @override
  String meeting_bg_unavailable(Object error) {
    return 'Arka plan kullanılamıyor: $error';
  }

  @override
  String get meeting_leave => 'Ayrıl';

  @override
  String get meeting_screen_share_ios =>
      'iOS\'ta ekran paylaşımı Broadcast Extension gerektirir (bir sonraki sürümde gelecek)';

  @override
  String meeting_screen_share_failed(String details) {
    return 'Ekran paylaşımı başlatılamadı: $details';
  }

  @override
  String get meeting_tooltip_speaker_mode => 'Konuşmacı modu';

  @override
  String get meeting_tooltip_grid_mode => 'Izgara modu';

  @override
  String get meeting_tooltip_copy_link =>
      'Bağlantıyı kopyala (tarayıcıyla katılım)';

  @override
  String get meeting_mic_on => 'Sesi aç';

  @override
  String get meeting_mic_off => 'Sessize al';

  @override
  String get meeting_camera_on => 'Kamera açık';

  @override
  String get meeting_camera_off => 'Kamera kapalı';

  @override
  String get meeting_switch_camera => 'Değiştir';

  @override
  String get meeting_hand_lower => 'İndir';

  @override
  String get meeting_hand_raise => 'El';

  @override
  String get meeting_reaction => 'Tepki';

  @override
  String get meeting_screen_stop => 'Durdur';

  @override
  String get meeting_screen_label => 'Ekran';

  @override
  String get meeting_bg_off => 'AP';

  @override
  String get meeting_bg_blur => 'Bulanıklaştır';

  @override
  String get meeting_bg_image => 'Resim';

  @override
  String get meeting_participants_button => 'Üyeler';

  @override
  String get meeting_notifications_button => 'Etkinlik';

  @override
  String get meeting_pip_button => 'Küçült';

  @override
  String get settings_chats_bottom_nav_icons_title => 'Alt gezinme simgeleri';

  @override
  String get settings_chats_bottom_nav_icons_subtitle =>
      'Web\'deki gibi simgeler ve görsel stil seçin.';

  @override
  String get settings_chats_nav_colorful => 'Renkli';

  @override
  String get settings_chats_nav_minimal => 'Asgari';

  @override
  String get settings_chats_nav_global_title => 'Tüm simgeler için';

  @override
  String get settings_chats_nav_global_subtitle =>
      'Genel katman: renk, boyut, kalınlık ve döşeme arka planı.';

  @override
  String get settings_chats_reset_tooltip => 'Sıfırla';

  @override
  String get settings_chats_collapse => 'Daralt';

  @override
  String get settings_chats_customize => 'Özelleştir';

  @override
  String get settings_chats_reset_item_tooltip => 'Sıfırla';

  @override
  String get settings_chats_style_tooltip => 'Stil';

  @override
  String get settings_chats_icon_size => 'Simge boyutu';

  @override
  String get settings_chats_stroke_width => 'Kalınlık';

  @override
  String get settings_chats_default => 'Varsayılan';

  @override
  String get settings_chats_icon_search_hint_en => 'Ada göre ara...';

  @override
  String get settings_chats_emoji_effects => 'Emoji efektleri';

  @override
  String get settings_chats_emoji_effects_subtitle =>
      'Sohbette tek bir emojiye dokunulduğunda tam ekran emoji için animasyon profili.';

  @override
  String get settings_chats_emoji_lite_desc =>
      'Hafif: düşük performanslı cihazlarda minimum yük ve maksimum akıcılık.';

  @override
  String get settings_chats_emoji_balanced_desc =>
      'Dengeli: performans ve ifade gücü arasında otomatik uzlaşma.';

  @override
  String get settings_chats_emoji_cinematic_desc =>
      'Sinematik: etkileyici efekt için maksimum parçacık ve derinlik.';

  @override
  String get settings_chats_preview_incoming_msg => 'Selam! Nasılsın?';

  @override
  String get settings_chats_preview_outgoing_msg => 'Harika, teşekkürler!';

  @override
  String get settings_chats_preview_hello => 'Merhaba';

  @override
  String get chat_theme_title => 'Sohbet teması';

  @override
  String chat_theme_error_save(String error) {
    return 'Arka plan kaydedilemedi: $error';
  }

  @override
  String chat_theme_error_upload(String error) {
    return 'Arka plan yükleme hatası: $error';
  }

  @override
  String get chat_theme_delete_title => 'Arka plan galeriden silinsin mi?';

  @override
  String get chat_theme_delete_body =>
      'Görsel arka planlar listenizden kaldırılacak. Bu sohbet için başka bir tane seçebilirsiniz.';

  @override
  String chat_theme_error_delete(String error) {
    return 'Silme hatası: $error';
  }

  @override
  String get chat_theme_banner =>
      'Bu sohbetin arka planı yalnızca sizin içindir. \"Sohbet Ayarları\"ndaki genel sohbet ayarları değişmez.';

  @override
  String get chat_theme_current_bg => 'Mevcut arka plan';

  @override
  String get chat_theme_default_global => 'Varsayılan (genel ayarlar)';

  @override
  String get chat_theme_presets => 'Ön ayarlar';

  @override
  String get chat_theme_global_tile => 'Genel';

  @override
  String get chat_theme_pick_hint =>
      'Bir ön ayar veya galeriden fotoğraf seçin';

  @override
  String get contacts_title => 'Kişiler';

  @override
  String get contacts_add_phone_prompt =>
      'Numaraya göre kişi aramak için profilinize bir telefon numarası ekleyin.';

  @override
  String get contacts_fallback_profile => 'Profil';

  @override
  String get contacts_fallback_user => 'Kullanıcı';

  @override
  String get contacts_status_online => 'çevrimiçi';

  @override
  String get contacts_status_recently => 'Son zamanlarda görüldü';

  @override
  String contacts_status_today_at(String time) {
    return 'Son görülme $time';
  }

  @override
  String get contacts_status_yesterday => 'Dün görüldü';

  @override
  String get contacts_status_year_ago => 'Bir yıl önce görüldü';

  @override
  String contacts_status_years_ago(String years) {
    return '$years önce görüldü';
  }

  @override
  String contacts_status_date(String date) {
    return 'Son görülme $date';
  }

  @override
  String get contacts_empty_state =>
      'Kişi bulunamadı.\nTelefon rehberinizi senkronize etmek için sağdaki düğmeye dokunun.';

  @override
  String get add_contact_title => 'Yeni kişi';

  @override
  String get add_contact_sync_off => 'Uygulamada senkronizasyon kapalı.';

  @override
  String get add_contact_enable_system_access =>
      'Sistem ayarlarında LighChat için kişi erişimini etkinleştirin.';

  @override
  String get add_contact_sync_on => 'Senkronizasyon açık';

  @override
  String get add_contact_sync_failed =>
      'Kişi senkronizasyonu etkinleştirilemedi';

  @override
  String get add_contact_invalid_phone => 'Geçerli bir telefon numarası girin';

  @override
  String get add_contact_not_found_by_phone => 'Bu numara için kişi bulunamadı';

  @override
  String get add_contact_found => 'Kişi bulundu';

  @override
  String add_contact_search_error(String error) {
    return 'Arama başarısız: $error';
  }

  @override
  String get add_contact_qr_no_profile => 'QR kodu LighChat profili içermiyor';

  @override
  String get add_contact_qr_own_profile => 'Bu sizin kendi profiliniz';

  @override
  String get add_contact_qr_profile_not_found =>
      'QR kodundaki profil bulunamadı';

  @override
  String get add_contact_qr_found => 'QR kodu ile kişi bulundu';

  @override
  String add_contact_qr_read_error(String error) {
    return 'QR kodu okunamadı: $error';
  }

  @override
  String get add_contact_cannot_add_user => 'Bu kullanıcı eklenemiyor';

  @override
  String add_contact_add_error(String error) {
    return 'Kişi eklenemedi: $error';
  }

  @override
  String get add_contact_country_search_hint => 'Ülke veya kod ara';

  @override
  String get add_contact_sync_with_phone => 'Telefonla senkronize et';

  @override
  String get add_contact_add_by_qr => 'QR kodu ile ekle';

  @override
  String get add_contact_results_unavailable => 'Sonuçlar henüz mevcut değil';

  @override
  String add_contact_profile_load_error(String error) {
    return 'Kişi yüklenemedi: $error';
  }

  @override
  String get add_contact_profile_not_found => 'Profil bulunamadı';

  @override
  String get add_contact_badge_already_added => 'Zaten eklendi';

  @override
  String get add_contact_badge_new => 'Yeni kişi';

  @override
  String get add_contact_badge_unavailable => 'Kullanılamıyor';

  @override
  String get add_contact_open_contact => 'Kişiyi aç';

  @override
  String get add_contact_add_to_contacts => 'Kişilere ekle';

  @override
  String get add_contact_add_unavailable => 'Ekleme kullanılamıyor';

  @override
  String get add_contact_searching => 'Kişi aranıyor...';

  @override
  String get add_contact_scan_qr_title => 'QR kodu tara';

  @override
  String get add_contact_flash_tooltip => 'Flaş';

  @override
  String get add_contact_scan_qr_hint =>
      'Kameranızı bir LighChat profil QR koduna doğrultun';

  @override
  String get contacts_edit_enter_name => 'Kişi adını girin.';

  @override
  String contacts_edit_save_error(String error) {
    return 'Kişi kaydedilemedi: $error';
  }

  @override
  String get contacts_edit_first_name_hint => 'Ad';

  @override
  String get contacts_edit_last_name_hint => 'Soyad';

  @override
  String get contacts_edit_name_disclaimer =>
      'Bu ad yalnızca sizin görebildiğiniz bir addır: sohbetlerde, aramada ve kişi listesinde.';

  @override
  String contacts_edit_error(String error) {
    return 'Hata: $error';
  }

  @override
  String get chat_settings_color_default => 'Varsayılan';

  @override
  String get chat_settings_color_lilac => 'Leylak';

  @override
  String get chat_settings_color_pink => 'Pembe';

  @override
  String get chat_settings_color_green => 'Yeşil';

  @override
  String get chat_settings_color_coral => 'Mercan';

  @override
  String get chat_settings_color_mint => 'Nane';

  @override
  String get chat_settings_color_sky => 'Gökyüzü';

  @override
  String get chat_settings_color_purple => 'Mor';

  @override
  String get chat_settings_color_crimson => 'Koyu kırmızı';

  @override
  String get chat_settings_color_tiffany => 'Tiffany';

  @override
  String get chat_settings_color_yellow => 'Sarı';

  @override
  String get chat_settings_color_powder => 'Pudra';

  @override
  String get chat_settings_color_turquoise => 'Turkuaz';

  @override
  String get chat_settings_color_blue => 'Mavi';

  @override
  String get chat_settings_color_sunset => 'Gün batımı';

  @override
  String get chat_settings_color_tender => 'Zarif';

  @override
  String get chat_settings_color_lime => 'Yeşil limon';

  @override
  String get chat_settings_color_graphite => 'Grafit';

  @override
  String get chat_settings_color_no_bg => 'Arka plan yok';

  @override
  String get chat_settings_icon_color => 'Simge rengi';

  @override
  String get chat_settings_icon_size => 'Simge boyutu';

  @override
  String get chat_settings_stroke_width => 'Kalınlık';

  @override
  String get chat_settings_tile_background => 'Döşeme arka planı';

  @override
  String get chat_settings_bottom_nav_icons => 'Alt gezinme simgeleri';

  @override
  String get chat_settings_bottom_nav_description =>
      'Web\'deki gibi simgeler ve görsel stil seçin.';

  @override
  String get chat_settings_bottom_nav_global_description =>
      'Paylaşılan katman: renk, boyut, kalınlık ve döşeme arka planı.';

  @override
  String get chat_settings_colorful => 'Renkli';

  @override
  String get chat_settings_minimalism => 'Asgari';

  @override
  String get chat_settings_for_all_icons => 'Tüm simgeler için';

  @override
  String get chat_settings_customize => 'Özelleştir';

  @override
  String get chat_settings_hide => 'Gizle';

  @override
  String get chat_settings_reset => 'Sıfırla';

  @override
  String get chat_settings_reset_item => 'Sıfırla';

  @override
  String get chat_settings_style => 'Stil';

  @override
  String get chat_settings_select => 'Seç';

  @override
  String get chat_settings_reset_size => 'Boyutu sıfırla';

  @override
  String get chat_settings_reset_stroke => 'Kalınlığı sıfırla';

  @override
  String get chat_settings_default_gradient => 'Varsayılan gradyan';

  @override
  String get chat_settings_inherit_global => 'Genelden devral';

  @override
  String get chat_settings_no_bg_on => 'Arka plan yok (açık)';

  @override
  String get chat_settings_no_bg => 'Arka plan yok';

  @override
  String get chat_settings_outgoing_messages => 'Giden mesajlar';

  @override
  String get chat_settings_incoming_messages => 'Gelen mesajlar';

  @override
  String get chat_settings_font_size => 'Yazı tipi boyutu';

  @override
  String get chat_settings_font_small => 'Küçük';

  @override
  String get chat_settings_font_medium => 'Orta';

  @override
  String get chat_settings_font_large => 'Büyük';

  @override
  String get chat_settings_bubble_shape => 'Balon şekli';

  @override
  String get chat_settings_bubble_rounded => 'Yuvarlak';

  @override
  String get chat_settings_bubble_square => 'Kare';

  @override
  String get chat_settings_chat_background => 'Sohbet arka planı';

  @override
  String get chat_settings_background_hint =>
      'Galeriden bir fotoğraf seçin veya özelleştirin';

  @override
  String get chat_settings_emoji_effects => 'Emoji efektleri';

  @override
  String get chat_settings_emoji_description =>
      'Sohbette dokunmayla tam ekran emoji patlaması için animasyon profili.';

  @override
  String get chat_settings_emoji_lite =>
      'Hafif: minimum yük, düşük performanslı cihazlarda en akıcı.';

  @override
  String get chat_settings_emoji_cinematic =>
      'Sinematik: etkileyici bir efekt için maksimum parçacık ve derinlik.';

  @override
  String get chat_settings_emoji_balanced =>
      'Dengeli: performans ve ifade gücü arasında otomatik uzlaşma.';

  @override
  String get chat_settings_additional => 'Ek';

  @override
  String get chat_settings_show_time => 'Saati göster';

  @override
  String get chat_settings_show_time_hint =>
      'Mesajların altında gönderim zamanı';

  @override
  String get chat_settings_reset_all => 'Ayarları sıfırla';

  @override
  String get chat_settings_preview_incoming => 'Merhaba! Nasılsınız?';

  @override
  String get chat_settings_preview_outgoing => 'Harika, teşekkürler!';

  @override
  String get chat_settings_preview_hello => 'Merhaba';

  @override
  String chat_settings_icon_picker_title(String label) {
    return 'Simge: “$label”';
  }

  @override
  String get chat_settings_search_hint => 'Ada göre ara (İng.)...';

  @override
  String meeting_tab_participants(Object count) {
    return 'Üyeler ($count)';
  }

  @override
  String get meeting_tab_polls => 'Anketler';

  @override
  String meeting_tab_polls_count(Object count) {
    return 'Anketler ($count)';
  }

  @override
  String get meeting_tab_chat => 'Sohbet';

  @override
  String meeting_tab_chat_count(Object count) {
    return 'Sohbet ($count)';
  }

  @override
  String meeting_tab_requests(Object count) {
    return 'İstekler ($count)';
  }

  @override
  String get meeting_kick => 'Odadan kaldır';

  @override
  String meeting_file_too_big(Object name) {
    return 'Dosya çok büyük: $name';
  }

  @override
  String meeting_send_error(Object error) {
    return 'Gönderilemedi: $error';
  }

  @override
  String meeting_save_error(Object error) {
    return 'Kaydedilemedi: $error';
  }

  @override
  String meeting_delete_error(Object error) {
    return 'Silinemedi: $error';
  }

  @override
  String get meeting_no_messages => 'Henüz mesaj yok';

  @override
  String get meeting_join_enter_name => 'Adınızı girin';

  @override
  String get meeting_join_guest => 'Misafir';

  @override
  String get meeting_join_as_label => 'Şu adla katılacaksınız';

  @override
  String get meeting_lobby_camera_blocked =>
      'Kamera izni reddedildi. Kameranız kapalı şekilde katılacaksınız.';

  @override
  String get meeting_join_button => 'Katıl';

  @override
  String meeting_join_load_error(Object error) {
    return 'Toplantı yükleme hatası: $error';
  }

  @override
  String get meeting_private_hint =>
      'Özel toplantı: ev sahibi isteğinizden sonra sizi kabul edip etmeyeceğine karar verecek.';

  @override
  String get meeting_public_hint =>
      'Açık toplantı: bekleme olmadan bağlantıyla katılın.';

  @override
  String get meeting_name_label => 'Adınız';

  @override
  String get meeting_waiting_title => 'Onay bekleniyor';

  @override
  String get meeting_waiting_subtitle =>
      'Ev sahibi isteğinizi görecek ve sizi ne zaman kabul edeceğine karar verecek.';

  @override
  String get meeting_screen_share_ios_hint =>
      'iOS\'ta ekran paylaşımı bir Broadcast Extension gerektirir (geliştirme aşamasında).';

  @override
  String meeting_screen_share_error(Object error) {
    return 'Ekran paylaşımı başlatılamadı: $error';
  }

  @override
  String get meeting_speaker_mode => 'Konuşmacı modu';

  @override
  String get meeting_grid_mode => 'Izgara modu';

  @override
  String get meeting_copy_link_tooltip =>
      'Bağlantıyı kopyala (tarayıcı girişi)';

  @override
  String get group_members_subtitle_creator => 'Grup oluşturucu';

  @override
  String get group_members_subtitle_admin => 'Yönetici';

  @override
  String get group_members_subtitle_member => 'Üye';

  @override
  String group_members_total_count(int count) {
    return 'Toplam: $count';
  }

  @override
  String get group_members_copy_invite_tooltip => 'Davet bağlantısını kopyala';

  @override
  String get group_members_add_member_tooltip => 'Üye ekle';

  @override
  String get group_members_invite_copied => 'Davet bağlantısı kopyalandı';

  @override
  String group_members_copy_link_error(String error) {
    return 'Bağlantı kopyalanamadı: $error';
  }

  @override
  String get group_members_added => 'Üyeler eklendi';

  @override
  String get group_members_revoke_admin_title =>
      'Yönetici yetkileri iptal edilsin mi?';

  @override
  String group_members_revoke_admin_body(String name) {
    return '$name yönetici yetkilerini kaybedecek. Grupta normal üye olarak kalacak.';
  }

  @override
  String get group_members_grant_admin_title =>
      'Yönetici yetkileri verilsin mi?';

  @override
  String group_members_grant_admin_body(String name) {
    return '$name yönetici yetkilerini alacak: grubu düzenleyebilir, üyeleri kaldırabilir ve mesajları yönetebilir.';
  }

  @override
  String get group_members_revoke_admin_action => 'İptal et';

  @override
  String get group_members_grant_admin_action => 'Ver';

  @override
  String get group_members_remove_title => 'Üye kaldırılsın mı?';

  @override
  String group_members_remove_body(String name) {
    return '$name gruptan kaldırılacak. Üyeyi tekrar ekleyerek bunu geri alabilirsiniz.';
  }

  @override
  String get group_members_remove_action => 'Kaldır';

  @override
  String get group_members_removed => 'Üye kaldırıldı';

  @override
  String get group_members_menu_revoke_admin => 'Yöneticiyi kaldır';

  @override
  String get group_members_menu_grant_admin => 'Yönetici yap';

  @override
  String get group_members_menu_remove => 'Gruptan kaldır';

  @override
  String get group_members_creator_badge => 'OLUŞTURUCU';

  @override
  String get group_members_add_title => 'Üye ekle';

  @override
  String get group_members_search_contacts => 'Kişilerde ara';

  @override
  String get group_members_all_in_group => 'Tüm kişileriniz zaten grupta.';

  @override
  String get group_members_nobody_found => 'Kimse bulunamadı.';

  @override
  String get group_members_user_fallback => 'Kullanıcı';

  @override
  String get group_members_select_members => 'Üyeleri seçin';

  @override
  String group_members_add_count(int count) {
    return 'Ekle ($count)';
  }

  @override
  String group_members_contacts_load_error(String error) {
    return 'Kişiler yüklenemedi: $error';
  }

  @override
  String group_members_auth_error(String error) {
    return 'Yetkilendirme hatası: $error';
  }

  @override
  String group_members_add_failed(String error) {
    return 'Üyeler eklenemedi: $error';
  }

  @override
  String get group_not_found => 'Grup bulunamadı.';

  @override
  String get group_not_member => 'Bu grubun üyesi değilsiniz.';

  @override
  String get poll_create_title => 'Sohbet anketi';

  @override
  String get poll_question_label => 'Soru';

  @override
  String get poll_question_hint => 'Örn.: Saat kaçta buluşalım?';

  @override
  String get poll_description_label => 'Açıklama (isteğe bağlı)';

  @override
  String get poll_options_title => 'Seçenekler';

  @override
  String poll_option_hint(int index) {
    return 'Seçenek $index';
  }

  @override
  String get poll_add_option => 'Seçenek ekle';

  @override
  String get poll_switch_anonymous => 'Anonim oylama';

  @override
  String get poll_switch_anonymous_sub => 'Kimin neye oy verdiğini gösterme';

  @override
  String get poll_switch_multi => 'Birden fazla cevap';

  @override
  String get poll_switch_multi_sub => 'Birden fazla seçenek seçilebilir';

  @override
  String get poll_switch_add_options => 'Seçenek ekle';

  @override
  String get poll_switch_add_options_sub =>
      'Katılımcılar kendi seçeneklerini önerebilir';

  @override
  String get poll_switch_revote => 'Oy değiştirilebilir';

  @override
  String get poll_switch_revote_sub =>
      'Anket kapanana kadar yeniden oylamaya izin var';

  @override
  String get poll_switch_shuffle => 'Seçenekleri karıştır';

  @override
  String get poll_switch_shuffle_sub => 'Her katılımcı için farklı bir sıra';

  @override
  String get poll_switch_quiz => 'Bilgi yarışması modu';

  @override
  String get poll_switch_quiz_sub => 'Bir doğru cevap';

  @override
  String get poll_correct_option_label => 'Doğru seçenek';

  @override
  String get poll_quiz_explanation_label => 'Açıklama (isteğe bağlı)';

  @override
  String get poll_close_by_time => 'Zamana göre kapat';

  @override
  String get poll_close_not_set => 'Ayarlanmadı';

  @override
  String get poll_close_reset => 'Son tarihi sıfırla';

  @override
  String get poll_publish => 'Yayınla';

  @override
  String get poll_error_empty_question => 'Bir soru girin';

  @override
  String get poll_error_min_options => 'En az 2 seçenek gereklidir';

  @override
  String get poll_error_select_correct => 'Doğru seçeneği seçin';

  @override
  String get poll_error_future_time => 'Kapanış zamanı gelecekte olmalıdır';

  @override
  String get poll_unavailable => 'Anket kullanılamıyor';

  @override
  String get poll_loading => 'Anket yükleniyor…';

  @override
  String get poll_not_found => 'Anket bulunamadı';

  @override
  String get poll_status_cancelled => 'İptal edildi';

  @override
  String get poll_status_ended => 'Sona erdi';

  @override
  String get poll_status_draft => 'Taslak';

  @override
  String get poll_status_active => 'Aktif';

  @override
  String get poll_badge_public => 'Herkese açık';

  @override
  String get poll_badge_multi => 'Birden fazla cevap';

  @override
  String get poll_badge_quiz => 'Bilgi Yarışması';

  @override
  String get poll_menu_restart => 'Yeniden başlat';

  @override
  String get poll_menu_end => 'Bitir';

  @override
  String get poll_menu_delete => 'Sil';

  @override
  String get poll_submit_vote => 'Oyu gönder';

  @override
  String get poll_suggest_option_hint => 'Bir seçenek öner';

  @override
  String get poll_revote => 'Oyu değiştir';

  @override
  String poll_votes_count(int count) {
    return '$count oy';
  }

  @override
  String get poll_show_voters => 'Kim oy verdi';

  @override
  String get poll_hide_voters => 'Gizle';

  @override
  String get poll_vote_error => 'Oylama sırasında hata';

  @override
  String get poll_add_option_error => 'Seçenek eklenemedi';

  @override
  String get poll_error_generic => 'Hata';

  @override
  String get durak_your_turn => 'Sıranız';

  @override
  String get durak_winner_label => 'Kazanan';

  @override
  String get durak_rematch => 'Tekrar oyna';

  @override
  String get durak_surrender_tooltip => 'Oyunu bitir';

  @override
  String get durak_close_tooltip => 'Kapat';

  @override
  String get durak_fx_took => 'Aldı';

  @override
  String get durak_fx_beat => 'Yenildi';

  @override
  String get durak_opponent_role_defend => 'SAV';

  @override
  String get durak_opponent_role_attack => 'SLD';

  @override
  String get durak_opponent_role_throwin => 'AT';

  @override
  String get durak_foul_banner_title => 'Hileci! Kaçırılan:';

  @override
  String get durak_pending_resolution_attacker =>
      'İhlal kontrolü bekleniyor… Herkes hemfikirse \"Yengiyi Onayla\"ya basın.';

  @override
  String get durak_pending_resolution_other =>
      'İhlal kontrolü bekleniyor… Hile fark ettiyseniz \"İhlal!\" düğmesine basabilirsiniz.';

  @override
  String durak_tournament_played(int finished, int total) {
    return '$finished/$total oynandı';
  }

  @override
  String get durak_tournament_finished => 'Turnuva tamamlandı';

  @override
  String get durak_tournament_next => 'Sonraki turnuva oyunu';

  @override
  String get durak_single_game => 'Tek oyun';

  @override
  String get durak_tournament_total_games_title => 'Turnuvada kaç oyun?';

  @override
  String get durak_finish_game_tooltip => 'Oyunu bitir';

  @override
  String get durak_lobby_game_unavailable =>
      'Oyun kullanılamıyor veya silinmiş';

  @override
  String get durak_lobby_back_tooltip => 'Geri';

  @override
  String get durak_lobby_waiting => 'Rakip bekleniyor…';

  @override
  String get durak_lobby_start => 'Oyunu başlat';

  @override
  String get durak_lobby_waiting_short => 'Bekleniyor…';

  @override
  String get durak_lobby_ready => 'Hazır';

  @override
  String get durak_lobby_empty_slot => 'Bekleniyor…';

  @override
  String get durak_settings_timer_subtitle => 'Varsayılan 15 saniye';

  @override
  String get durak_dm_game_active => 'Durak oyunu devam ediyor';

  @override
  String get durak_dm_game_created => 'Durak oyunu oluşturuldu';

  @override
  String get game_durak_subtitle => 'Tek oyun veya turnuva';

  @override
  String get group_member_write_dm => 'Direkt mesaj gönder';

  @override
  String get group_member_open_dm_hint => 'Üyeyle direkt sohbet aç';

  @override
  String get group_member_profile_not_loaded => 'Üye profili henüz yüklenmedi.';

  @override
  String group_member_open_dm_error(String error) {
    return 'Direkt sohbet açılamadı: $error';
  }

  @override
  String get group_avatar_photo_title => 'Grup fotoğrafı';

  @override
  String get group_avatar_add_photo => 'Fotoğraf ekle';

  @override
  String get group_avatar_change => 'Avatarı değiştir';

  @override
  String get group_avatar_remove => 'Avatarı kaldır';

  @override
  String group_avatar_process_error(String error) {
    return 'Fotoğraf işlenemedi: $error';
  }

  @override
  String get group_mention_no_matches => 'Eşleşme yok';

  @override
  String get durak_error_defense_does_not_beat =>
      'Bu kart saldıran kartı yenmiyor';

  @override
  String get durak_error_only_attacker_first => 'Saldıran önce hamle yapar';

  @override
  String get durak_error_defender_cannot_attack => 'Savunan şu anda atamaz';

  @override
  String get durak_error_not_allowed_throwin => 'Bu turda atamazsınız';

  @override
  String get durak_error_throwin_not_your_turn =>
      'Başka bir oyuncu şu anda atıyor';

  @override
  String get durak_error_rank_not_allowed =>
      'Yalnızca aynı değerdeki kartları atabilirsiniz';

  @override
  String get durak_error_cannot_throw_in => 'Daha fazla kart atılamaz';

  @override
  String get durak_error_card_not_in_hand => 'Bu kart artık elinizde değil';

  @override
  String get durak_error_already_defended => 'Bu kart zaten savunuldu';

  @override
  String get durak_error_bad_attack_index =>
      'Savunulacak bir saldırı kartı seçin';

  @override
  String get durak_error_only_defender => 'Başka bir oyuncu şu anda savunuyor';

  @override
  String get durak_error_defender_already_taking =>
      'Savunan zaten kartları alıyor';

  @override
  String get durak_error_game_not_active => 'Oyun artık aktif değil';

  @override
  String get durak_error_not_in_lobby => 'Lobi zaten başladı';

  @override
  String get durak_error_game_already_active => 'Oyun zaten başladı';

  @override
  String get durak_error_active_game_exists =>
      'Bu sohbette zaten aktif bir oyun var';

  @override
  String get durak_error_resolution_pending =>
      'Önce tartışmalı hamleyi tamamlayın';

  @override
  String get durak_error_rematch_failed =>
      'Rövanş hazırlanamadı. Lütfen tekrar deneyin';

  @override
  String get durak_error_unauthenticated => 'Giriş yapmanız gerekiyor';

  @override
  String get durak_error_permission_denied =>
      'Bu işlem sizin için kullanılamıyor';

  @override
  String get durak_error_invalid_argument => 'Geçersiz hamle';

  @override
  String get durak_error_failed_precondition => 'Hamle şu anda kullanılamıyor';

  @override
  String get durak_error_server => 'Hamle yürütülemedi. Lütfen tekrar deneyin';

  @override
  String pinned_count(int count) {
    return 'Sabitlenen: $count';
  }

  @override
  String get pinned_single => 'Sabitlenmiş';

  @override
  String get pinned_unpin_tooltip => 'Sabitlemeyi kaldır';

  @override
  String get pinned_type_image => 'Resim';

  @override
  String get pinned_type_video => 'Video';

  @override
  String get pinned_type_video_circle => 'Video daire';

  @override
  String get pinned_type_voice => 'Sesli mesaj';

  @override
  String get pinned_type_poll => 'Anket';

  @override
  String get pinned_type_link => 'Bağlantı';

  @override
  String get pinned_type_location => 'Konum';

  @override
  String get pinned_type_sticker => 'Çıkartma';

  @override
  String get pinned_type_file => 'Dosya';

  @override
  String get call_entry_login_required_title => 'Giriş gerekli';

  @override
  String get call_entry_login_required_subtitle =>
      'Uygulamayı açın ve hesabınıza giriş yapın.';

  @override
  String get call_entry_not_found_title => 'Arama bulunamadı';

  @override
  String get call_entry_not_found_subtitle =>
      'Arama zaten sona erdi veya silindi. Aramalara dönülüyor…';

  @override
  String get call_entry_to_calls => 'Aramalara';

  @override
  String get call_entry_ended_title => 'Arama sona erdi';

  @override
  String get call_entry_ended_subtitle =>
      'Bu arama artık mevcut değil. Aramalara dönülüyor…';

  @override
  String get call_entry_caller_fallback => 'Arayan';

  @override
  String get call_entry_opening_title => 'Arama açılıyor…';

  @override
  String get call_entry_connecting_video => 'Görüntülü aramaya bağlanılıyor';

  @override
  String get call_entry_connecting_audio => 'Sesli aramaya bağlanılıyor';

  @override
  String get call_entry_loading_subtitle => 'Arama verileri yükleniyor';

  @override
  String get call_entry_error_title => 'Arama açılırken hata';

  @override
  String chat_theme_save_error(Object error) {
    return 'Arka plan kaydedilemedi: $error';
  }

  @override
  String chat_theme_load_error(Object error) {
    return 'Arka plan yükleme hatası: $error';
  }

  @override
  String chat_theme_delete_error(Object error) {
    return 'Silme hatası: $error';
  }

  @override
  String get chat_theme_description =>
      'Bu sohbetin arka planı yalnızca sizin tarafınızdan görülebilir. Sohbet Ayarları bölümündeki genel sohbet ayarları etkilenmez.';

  @override
  String get chat_theme_default_bg => 'Varsayılan (genel ayarlar)';

  @override
  String get chat_theme_global_label => 'Genel';

  @override
  String get chat_theme_hint => 'Bir ön ayar veya galeriden fotoğraf seçin';

  @override
  String get date_today => 'Bugün';

  @override
  String get date_yesterday => 'Dün';

  @override
  String get date_month_1 => 'Ocak';

  @override
  String get date_month_2 => 'Şubat';

  @override
  String get date_month_3 => 'Mart';

  @override
  String get date_month_4 => 'Nisan';

  @override
  String get date_month_5 => 'Mayıs';

  @override
  String get date_month_6 => 'Haziran';

  @override
  String get date_month_7 => 'Temmuz';

  @override
  String get date_month_8 => 'Ağustos';

  @override
  String get date_month_9 => 'Eylül';

  @override
  String get date_month_10 => 'Ekim';

  @override
  String get date_month_11 => 'Kasım';

  @override
  String get date_month_12 => 'Aralık';

  @override
  String get video_circle_camera_unavailable => 'Kamera kullanılamıyor';

  @override
  String video_circle_camera_error(Object error) {
    return 'Kamera açılamadı: $error';
  }

  @override
  String video_circle_record_error(Object error) {
    return 'Kayıt hatası: $error';
  }

  @override
  String get video_circle_file_not_found => 'Kayıt dosyası bulunamadı';

  @override
  String get video_circle_play_error => 'Kayıt oynatılamadı';

  @override
  String video_circle_send_error(Object error) {
    return 'Gönderme başarısız: $error';
  }

  @override
  String video_circle_switch_error(Object error) {
    return 'Kamera değiştirilemedi: $error';
  }

  @override
  String video_circle_pause_error_detail(Object description, Object code) {
    return 'Duraklatma kullanılamıyor: $description ($code)';
  }

  @override
  String video_circle_pause_error(Object error) {
    return 'Kayıt duraklatma: $error';
  }

  @override
  String get video_circle_camera_fallback_error => 'Kamera hatası';

  @override
  String get video_circle_retry => 'Tekrar dene';

  @override
  String get video_circle_sending => 'Gönderiliyor...';

  @override
  String get video_circle_recorded => 'Daire kaydedildi';

  @override
  String get video_circle_swipe_cancel => 'İptal etmek için sola kaydırın';

  @override
  String media_screen_error(Object error) {
    return 'Medya yüklenirken hata: $error';
  }

  @override
  String get media_screen_title => 'Medya, bağlantılar ve dosyalar';

  @override
  String get media_tab_media => 'Medya';

  @override
  String get media_tab_circles => 'Daireler';

  @override
  String get media_tab_files => 'Dosyalar';

  @override
  String get media_tab_links => 'Bağlantılar';

  @override
  String get media_tab_audio => 'Ses';

  @override
  String get media_empty_files => 'Dosya yok';

  @override
  String get media_empty_media => 'Medya yok';

  @override
  String get media_attachment_fallback => 'Ek';

  @override
  String get media_empty_circles => 'Daire yok';

  @override
  String get media_empty_links => 'Bağlantı yok';

  @override
  String get media_empty_audio => 'Sesli mesaj yok';

  @override
  String get media_sender_you => 'Siz';

  @override
  String get media_sender_fallback => 'Katılımcı';

  @override
  String get call_detail_login_required => 'Giriş gerekli.';

  @override
  String get call_detail_not_found => 'Arama bulunamadı veya erişim yok.';

  @override
  String get call_detail_unknown => 'Bilinmeyen';

  @override
  String get call_detail_title => 'Arama ayrıntıları';

  @override
  String get call_detail_video => 'Görüntülü arama';

  @override
  String get call_detail_audio => 'Sesli arama';

  @override
  String get call_detail_outgoing => 'Giden';

  @override
  String get call_detail_incoming => 'Gelen';

  @override
  String get call_detail_date_label => 'Tarih:';

  @override
  String get call_detail_duration_label => 'Süre:';

  @override
  String get call_detail_call_button => 'Ara';

  @override
  String get call_detail_video_button => 'Görüntülü';

  @override
  String call_detail_error(Object error) {
    return 'Hata: $error';
  }

  @override
  String get durak_took => 'Aldı';

  @override
  String get durak_beaten => 'Yenildi';

  @override
  String get durak_end_game_tooltip => 'Oyunu bitir';

  @override
  String get durak_role_beats => 'SAV';

  @override
  String get durak_role_move => 'HAM';

  @override
  String get durak_role_throw => 'AT';

  @override
  String get durak_cheater_label => 'Hileci! Kaçırılan:';

  @override
  String get durak_waiting_foll_confirm =>
      'İhlal çağrısı bekleniyor… Herkes hemfikirse \"Yengiyi Onayla\"ya basın.';

  @override
  String get durak_waiting_foll_call =>
      'İhlal çağrısı bekleniyor… Hile fark ettiyseniz \"İhlal!\" düğmesine basabilirsiniz.';

  @override
  String get durak_winner => 'Kazanan';

  @override
  String get durak_play_again => 'Tekrar oyna';

  @override
  String durak_games_progress(Object finished, Object total) {
    return '$finished/$total oynandı';
  }

  @override
  String get durak_next_round => 'Sonraki turnuva turu';

  @override
  String audio_call_error(Object error) {
    return 'Arama hatası: $error';
  }

  @override
  String get audio_call_ended => 'Arama sona erdi';

  @override
  String get audio_call_missed => 'Cevapsız arama';

  @override
  String get audio_call_cancelled => 'Arama iptal edildi';

  @override
  String get audio_call_offer_not_ready =>
      'Teklif henüz hazır değil, tekrar deneyin';

  @override
  String get audio_call_invalid_data => 'Geçersiz arama verisi';

  @override
  String audio_call_accept_error(Object error) {
    return 'Arama kabul edilemedi: $error';
  }

  @override
  String get audio_call_incoming => 'Gelen sesli arama';

  @override
  String get audio_call_calling => 'Sesli arama…';

  @override
  String privacy_save_error(Object error) {
    return 'Ayarlar kaydedilemedi: $error';
  }

  @override
  String privacy_load_error(Object error) {
    return 'Gizlilik yüklenirken hata: $error';
  }

  @override
  String get privacy_visibility => 'Görünürlük';

  @override
  String get privacy_online_status => 'Çevrimiçi durumu';

  @override
  String get privacy_last_visit => 'Son görülme';

  @override
  String get privacy_read_receipts => 'Okundu bilgisi';

  @override
  String get privacy_profile_info => 'Profil bilgileri';

  @override
  String get privacy_phone_number => 'Telefon numarası';

  @override
  String get privacy_birthday => 'Doğum günü';

  @override
  String get privacy_about => 'Hakkında';

  @override
  String starred_load_error(Object error) {
    return 'Yıldızlılar yüklenirken hata: $error';
  }

  @override
  String get starred_title => 'Yıldızlı';

  @override
  String get starred_empty => 'Bu sohbette yıldızlı mesaj yok';

  @override
  String get starred_message_fallback => 'Mesaj';

  @override
  String get starred_sender_you => 'Siz';

  @override
  String get starred_sender_fallback => 'Katılımcı';

  @override
  String get starred_type_poll => 'Anket';

  @override
  String get starred_type_location => 'Konum';

  @override
  String get starred_type_attachment => 'Ek';

  @override
  String starred_today_prefix(Object time) {
    return 'Bugün, $time';
  }

  @override
  String get contact_edit_name_required => 'Kişi adını girin.';

  @override
  String contact_edit_save_error(Object error) {
    return 'Kişi kaydedilemedi: $error';
  }

  @override
  String get contact_edit_user_fallback => 'Kullanıcı';

  @override
  String get contact_edit_first_name_hint => 'Ad';

  @override
  String get contact_edit_last_name_hint => 'Soyad';

  @override
  String get contact_edit_description =>
      'Bu ad yalnızca sizin görebildiğiniz bir addır: sohbetlerde, aramada ve kişi listesinde.';

  @override
  String contact_edit_error(Object error) {
    return 'Hata: $error';
  }

  @override
  String get voice_no_mic_access => 'Mikrofon erişimi yok';

  @override
  String get voice_start_error => 'Kayıt başlatılamadı';

  @override
  String get voice_file_not_received => 'Kayıt dosyası alınamadı';

  @override
  String get voice_stop_error => 'Kayıt durdurulamadı';

  @override
  String get voice_title => 'Sesli mesaj';

  @override
  String get voice_recording => 'Kayıt';

  @override
  String get voice_ready => 'Kayıt hazır';

  @override
  String get voice_stop_button => 'Durdur';

  @override
  String get voice_record_again => 'Tekrar kaydet';

  @override
  String get attach_photo_video => 'Fotoğraf/Video';

  @override
  String get attach_files => 'Dosyalar';

  @override
  String get attach_circle => 'Daire';

  @override
  String get attach_location => 'Konum';

  @override
  String get attach_poll => 'Anket';

  @override
  String get attach_stickers => 'Çıkartmalar';

  @override
  String get attach_clipboard => 'Pano';

  @override
  String get attach_text => 'Metin';

  @override
  String get attach_title => 'Ekle';

  @override
  String notif_save_error(Object error) {
    return 'Kaydedilemedi: $error';
  }

  @override
  String get notif_title => 'Bu sohbetteki bildirimler';

  @override
  String get notif_description =>
      'Aşağıdaki ayarlar yalnızca bu sohbet için geçerlidir ve genel uygulama bildirimlerini değiştirmez.';

  @override
  String get notif_this_chat => 'Bu sohbet';

  @override
  String get notif_mute_title => 'Bildirimleri sessize al ve gizle';

  @override
  String get notif_mute_subtitle => 'Bu cihazda bu sohbet için rahatsız etme.';

  @override
  String get notif_preview_title => 'Metin önizlemesi göster';

  @override
  String get notif_preview_subtitle =>
      'Kapalıyken — mesaj parçacığı olmadan bildirim başlığı (desteklenen yerlerde).';

  @override
  String get poll_create_enter_question => 'Bir soru girin';

  @override
  String get poll_create_min_options => 'En az 2 seçenek gereklidir';

  @override
  String get poll_create_select_correct => 'Doğru seçeneği seçin';

  @override
  String get poll_create_future_time => 'Kapanış zamanı gelecekte olmalıdır';

  @override
  String get poll_create_question_label => 'Soru';

  @override
  String get poll_create_question_hint => 'Örneğin: Saat kaçta buluşuyoruz?';

  @override
  String get poll_create_explanation_label => 'Açıklama (isteğe bağlı)';

  @override
  String get poll_create_options_title => 'Seçenekler';

  @override
  String poll_create_option_hint(Object index) {
    return 'Seçenek $index';
  }

  @override
  String get poll_create_add_option => 'Seçenek ekle';

  @override
  String get poll_create_anonymous_title => 'Anonim oylama';

  @override
  String get poll_create_anonymous_subtitle =>
      'Kimin neye oy verdiğini gösterme';

  @override
  String get poll_create_multi_title => 'Birden fazla cevap';

  @override
  String get poll_create_multi_subtitle => 'Birden fazla seçenek seçilebilir';

  @override
  String get poll_create_user_options_title =>
      'Kullanıcı tarafından gönderilen seçenekler';

  @override
  String get poll_create_user_options_subtitle =>
      'Katılımcılar kendi seçeneklerini önerebilir';

  @override
  String get poll_create_revote_title => 'Yeniden oylamaya izin ver';

  @override
  String get poll_create_revote_subtitle =>
      'Anket kapanana kadar oy değiştirilebilir';

  @override
  String get poll_create_shuffle_title => 'Seçenekleri karıştır';

  @override
  String get poll_create_shuffle_subtitle =>
      'Her katılımcı farklı bir sıra görür';

  @override
  String get poll_create_quiz_title => 'Bilgi yarışması modu';

  @override
  String get poll_create_quiz_subtitle => 'Bir doğru cevap';

  @override
  String get poll_create_correct_option_label => 'Doğru seçenek';

  @override
  String get poll_create_close_by_time => 'Zamana göre kapat';

  @override
  String get poll_create_not_set => 'Ayarlanmadı';

  @override
  String get poll_create_reset_deadline => 'Son tarihi sıfırla';

  @override
  String get poll_create_publish => 'Yayınla';

  @override
  String get poll_error => 'Hata';

  @override
  String get poll_status_finished => 'Tamamlandı';

  @override
  String get poll_restart => 'Yeniden başlat';

  @override
  String get poll_finish => 'Bitir';

  @override
  String get poll_suggest_hint => 'Bir seçenek öner';

  @override
  String get poll_voters_toggle_hide => 'Gizle';

  @override
  String get poll_voters_toggle_show => 'Kim oy verdi';

  @override
  String get e2ee_disable_title => 'Şifreleme devre dışı bırakılsın mı?';

  @override
  String get e2ee_disable_body =>
      'Yeni mesajlar uçtan uca şifreleme olmadan gönderilecek. Daha önce gönderilen şifreli mesajlar akışta kalacak.';

  @override
  String get e2ee_disable_button => 'Devre dışı bırak';

  @override
  String e2ee_disable_error(Object error) {
    return 'Devre dışı bırakılamadı: $error';
  }

  @override
  String get e2ee_screen_title => 'Şifreleme';

  @override
  String get e2ee_enabled_description =>
      'Bu sohbet için uçtan uca şifreleme etkinleştirildi.';

  @override
  String get e2ee_disabled_description => 'Uçtan uca şifreleme devre dışı.';

  @override
  String get e2ee_info_text =>
      'Şifreleme etkinleştirildiğinde, yeni mesajların içeriği yalnızca sohbet katılımcılarının cihazlarında kullanılabilir. Devre dışı bırakmak yalnızca yeni mesajları etkiler.';

  @override
  String get e2ee_enable_title => 'Şifrelemeyi etkinleştir';

  @override
  String e2ee_status_enabled(Object epoch) {
    return 'Etkin (anahtar dönemi: $epoch)';
  }

  @override
  String get e2ee_status_disabled => 'Devre dışı';

  @override
  String get e2ee_data_types_title => 'Veri türleri';

  @override
  String get e2ee_data_types_info =>
      'Bu ayar protokolü değiştirmez. Hangi veri türlerinin şifreli gönderileceğini kontrol eder.';

  @override
  String get e2ee_chat_settings_title => 'Bu sohbet için şifreleme ayarları';

  @override
  String get e2ee_chat_settings_override =>
      'Sohbete özel ayarlar kullanılıyor.';

  @override
  String get e2ee_chat_settings_global => 'Genel ayarlar devralınıyor.';

  @override
  String get e2ee_text_messages => 'Metin mesajları';

  @override
  String get e2ee_attachments => 'Ekler (medya/dosyalar)';

  @override
  String get e2ee_override_hint =>
      'Bu sohbet için değiştirmek istiyorsanız — \"Geçersiz Kılma\"yı etkinleştirin.';

  @override
  String get group_member_fallback => 'Katılımcı';

  @override
  String get group_role_creator => 'Grup oluşturucu';

  @override
  String get group_role_admin => 'Yönetici';

  @override
  String group_total_count(Object count) {
    return 'Toplam: $count';
  }

  @override
  String get group_copy_invite_tooltip => 'Davet bağlantısını kopyala';

  @override
  String get group_add_member_tooltip => 'Üye ekle';

  @override
  String get group_invite_copied => 'Davet bağlantısı kopyalandı';

  @override
  String group_copy_invite_error(Object error) {
    return 'Bağlantı kopyalanamadı: $error';
  }

  @override
  String get group_demote_confirm => 'Yönetici hakları kaldırılsın mı?';

  @override
  String get group_promote_confirm => 'Yönetici yapılsın mı?';

  @override
  String group_demote_body(Object name) {
    return '$name kişisinin yönetici hakları kaldırılacak. Üye grupta normal üye olarak kalacak.';
  }

  @override
  String get group_demote_button => 'Hakları kaldır';

  @override
  String get group_promote_button => 'Yükselt';

  @override
  String get group_kick_confirm => 'Üye kaldırılsın mı?';

  @override
  String get group_kick_button => 'Kaldır';

  @override
  String get group_member_kicked => 'Üye kaldırıldı';

  @override
  String get group_badge_creator => 'OLUŞTURUCU';

  @override
  String get group_demote_action => 'Yöneticiyi kaldır';

  @override
  String get group_promote_action => 'Yönetici yap';

  @override
  String get group_kick_action => 'Gruptan kaldır';

  @override
  String group_contacts_load_error(Object error) {
    return 'Kişiler yüklenemedi: $error';
  }

  @override
  String get group_add_members_title => 'Üye ekle';

  @override
  String get group_search_contacts_hint => 'Kişilerde ara';

  @override
  String get group_all_contacts_in_group => 'Tüm kişileriniz zaten grupta.';

  @override
  String get group_nobody_found => 'Kimse bulunamadı.';

  @override
  String get group_user_fallback => 'Kullanıcı';

  @override
  String get group_select_members => 'Üyeleri seçin';

  @override
  String group_add_count(Object count) {
    return 'Ekle ($count)';
  }

  @override
  String group_auth_error(Object error) {
    return 'Yetkilendirme hatası: $error';
  }

  @override
  String group_add_error(Object error) {
    return 'Üyeler eklenemedi: $error';
  }

  @override
  String get add_contact_own_profile => 'Bu sizin kendi profiliniz';

  @override
  String get add_contact_qr_not_found => 'QR kodundaki profil bulunamadı';

  @override
  String add_contact_qr_error(Object error) {
    return 'QR kodu okunamadı: $error';
  }

  @override
  String get add_contact_not_allowed => 'Bu kullanıcı eklenemiyor';

  @override
  String add_contact_save_error(Object error) {
    return 'Kişi eklenemedi: $error';
  }

  @override
  String get add_contact_country_search => 'Ülke veya kod ara';

  @override
  String get add_contact_sync_phone => 'Telefonla senkronize et';

  @override
  String get add_contact_qr_button => 'QR kodu ile ekle';

  @override
  String add_contact_load_error(Object error) {
    return 'Kişi yükleme hatası: $error';
  }

  @override
  String get add_contact_user_fallback => 'Kullanıcı';

  @override
  String get add_contact_already_in_contacts => 'Zaten kişilerde';

  @override
  String get add_contact_new => 'Yeni kişi';

  @override
  String get add_contact_unavailable => 'Kullanılamıyor';

  @override
  String get add_contact_scan_qr => 'QR kodu tara';

  @override
  String get add_contact_scan_hint =>
      'Kamerayı LighChat profil QR koduna doğrultun';

  @override
  String get auth_validate_name_min_length => 'Ad en az 2 karakter olmalıdır';

  @override
  String get auth_validate_username_min_length =>
      'Kullanıcı adı en az 3 karakter olmalıdır';

  @override
  String get auth_validate_username_max_length =>
      'Kullanıcı adı 30 karakteri aşmamalıdır';

  @override
  String get auth_validate_username_format =>
      'Kullanıcı adı geçersiz karakterler içeriyor';

  @override
  String get auth_validate_phone_11_digits =>
      'Telefon numarası 11 haneli olmalıdır';

  @override
  String get auth_validate_email_format => 'Geçerli bir e-posta girin';

  @override
  String get auth_validate_dob_invalid => 'Geçersiz doğum tarihi';

  @override
  String get auth_validate_bio_max_length =>
      'Biyografi 200 karakteri aşmamalıdır';

  @override
  String get auth_validate_password_min_length =>
      'Şifre en az 6 karakter olmalıdır';

  @override
  String get auth_validate_passwords_mismatch => 'Şifreler eşleşmiyor';

  @override
  String get sticker_new_pack => 'Yeni paket…';

  @override
  String get sticker_select_image_or_gif => 'Bir resim veya GIF seçin';

  @override
  String sticker_send_error(Object error) {
    return 'Gönderme başarısız: $error';
  }

  @override
  String get sticker_saved => 'Çıkartma paketine kaydedildi';

  @override
  String get sticker_save_failed => 'GIF indirilemedi veya kaydedilemedi';

  @override
  String get sticker_tab_my => 'Benim';

  @override
  String get sticker_tab_shared => 'Paylaşılan';

  @override
  String get sticker_no_packs =>
      'Çıkartma paketi yok. Yeni bir tane oluşturun.';

  @override
  String get sticker_shared_not_configured =>
      'Paylaşılan paketler yapılandırılmadı';

  @override
  String get sticker_recent => 'SON KULLANILANLAR';

  @override
  String get sticker_gallery_description =>
      'Cihazdan fotoğraflar, PNG, GIF — doğrudan sohbete';

  @override
  String get sticker_shared_unavailable =>
      'Paylaşılan paketler henüz mevcut değil';

  @override
  String get sticker_gif_search_hint => 'GIF ara…';

  @override
  String sticker_gif_searched(Object query) {
    return 'Aranan: $query';
  }

  @override
  String get sticker_gif_search_unavailable =>
      'GIF araması geçici olarak kullanılamıyor.';

  @override
  String get sticker_gif_nothing_found => 'Hiçbir şey bulunamadı';

  @override
  String get sticker_gif_all => 'Tümü';

  @override
  String get sticker_gif_animated => 'HAREKETLİ';

  @override
  String get sticker_emoji_text_unavailable =>
      'Bu pencere için metin emojisi kullanılamıyor.';

  @override
  String get wallpaper_sender => 'Kişi';

  @override
  String get wallpaper_incoming => 'Bu gelen bir mesajdır.';

  @override
  String get wallpaper_outgoing => 'Bu giden bir mesajdır.';

  @override
  String get wallpaper_incoming_time => '11:40';

  @override
  String get wallpaper_outgoing_time => '11:41';

  @override
  String get wallpaper_system => 'Sohbet duvar kağıdını değiştirdiniz';

  @override
  String get wallpaper_you => 'Siz';

  @override
  String get wallpaper_today => 'Bugün';

  @override
  String system_event_e2ee_enabled(Object epoch) {
    return 'Uçtan uca şifreleme etkinleştirildi (anahtar dönemi: $epoch)';
  }

  @override
  String get system_event_e2ee_disabled =>
      'Uçtan uca şifreleme devre dışı bırakıldı';

  @override
  String get system_event_unknown => 'Sistem olayı';

  @override
  String get system_event_group_created => 'Grup oluşturuldu';

  @override
  String system_event_member_added(Object name) {
    return '$name eklendi';
  }

  @override
  String system_event_member_removed(Object name) {
    return '$name kaldırıldı';
  }

  @override
  String system_event_member_left(Object name) {
    return '$name gruptan ayrıldı';
  }

  @override
  String system_event_name_changed(Object name) {
    return 'Ad \"$name\" olarak değiştirildi';
  }

  @override
  String get image_editor_title => 'Düzenleyici';

  @override
  String get image_editor_undo => 'Geri al';

  @override
  String get image_editor_clear => 'Temizle';

  @override
  String get image_editor_pen => 'Fırça';

  @override
  String get image_editor_text => 'Metin';

  @override
  String get image_editor_crop => 'Kırp';

  @override
  String get image_editor_rotate => 'Döndür';

  @override
  String get location_title => 'Konum gönder';

  @override
  String get location_loading => 'Harita yükleniyor…';

  @override
  String get location_send_button => 'Gönder';

  @override
  String get location_live_label => 'Canlı';

  @override
  String get location_error => 'Harita yüklenemedi';

  @override
  String get location_no_permission => 'Konum erişimi yok';

  @override
  String get group_member_admin => 'Yönetici';

  @override
  String get group_member_creator => 'Oluşturucu';

  @override
  String get group_member_member => 'Üye';

  @override
  String get group_member_open_chat => 'Mesaj';

  @override
  String get group_member_open_profile => 'Profil';

  @override
  String get group_member_remove => 'Kaldır';

  @override
  String get durak_lobby_title => 'Durak';

  @override
  String get durak_lobby_new_game => 'Yeni oyun';

  @override
  String get durak_lobby_decline => 'Reddet';

  @override
  String get durak_lobby_accept => 'Kabul et';

  @override
  String get durak_lobby_invite_sent => 'Davet gönderildi';

  @override
  String get voice_preview_cancel => 'İptal';

  @override
  String get voice_preview_send => 'Gönder';

  @override
  String get voice_preview_recorded => 'Kaydedildi';

  @override
  String get voice_preview_playing => 'Oynatılıyor…';

  @override
  String get voice_preview_paused => 'Duraklatıldı';

  @override
  String get group_avatar_camera => 'Kamera';

  @override
  String get group_avatar_gallery => 'Galeri';

  @override
  String get group_avatar_upload_error => 'Yükleme hatası';

  @override
  String get avatar_picker_title => 'avatar';

  @override
  String get avatar_picker_camera => 'Kamera';

  @override
  String get avatar_picker_gallery => 'Galeri';

  @override
  String get avatar_picker_crop => 'Kırp';

  @override
  String get avatar_picker_save => 'Kaydet';

  @override
  String get avatar_picker_remove => 'Avatarı kaldır';

  @override
  String get avatar_picker_error => 'Avatar yüklenemedi';

  @override
  String get avatar_picker_crop_error => 'Kırpma hatası';

  @override
  String get webview_telegram_title => 'Telegram ile giriş yap';

  @override
  String get webview_telegram_loading => 'Yükleniyor…';

  @override
  String get webview_telegram_error => 'Sayfa yüklenemedi';

  @override
  String get webview_telegram_back => 'Geri';

  @override
  String get webview_telegram_retry => 'Tekrar dene';

  @override
  String get webview_telegram_close => 'Kapat';

  @override
  String get webview_telegram_no_url => 'Yetkilendirme URL\'si sağlanmadı';

  @override
  String get webview_yandex_title => 'Yandex ile giriş yap';

  @override
  String get webview_yandex_loading => 'Yükleniyor…';

  @override
  String get webview_yandex_error => 'Sayfa yüklenemedi';

  @override
  String get webview_yandex_back => 'Geri';

  @override
  String get webview_yandex_retry => 'Tekrar dene';

  @override
  String get webview_yandex_close => 'Kapat';

  @override
  String get webview_yandex_no_url => 'Yetkilendirme URL\'si sağlanmadı';

  @override
  String get google_profile_title => 'Profilinizi tamamlayın';

  @override
  String get google_profile_name => 'Ad';

  @override
  String get google_profile_username => 'Kullanıcı adı';

  @override
  String get google_profile_phone => 'Telefon';

  @override
  String get google_profile_email => 'E-posta';

  @override
  String get google_profile_dob => 'Doğum tarihi';

  @override
  String get google_profile_bio => 'Hakkında';

  @override
  String get google_profile_save => 'Kaydet';

  @override
  String get google_profile_error => 'Profil kaydedilemedi';

  @override
  String get system_event_e2ee_epoch_rotated => 'Şifreleme anahtarı döndürüldü';

  @override
  String system_event_e2ee_device_added(String actor, String device) {
    return '$actor \"$device\" cihazını ekledi';
  }

  @override
  String system_event_e2ee_device_revoked(String actor, String device) {
    return '$actor \"$device\" cihazını iptal etti';
  }

  @override
  String system_event_e2ee_fingerprint_changed(String actor) {
    return '$actor için güvenlik parmak izi değişti';
  }

  @override
  String get system_event_game_lobby_created => 'Oyun lobisi oluşturuldu';

  @override
  String get system_event_game_started => 'Oyun başladı';

  @override
  String get system_event_call_missed => 'Cevapsız çağrı';

  @override
  String get system_event_call_cancelled => 'Çağrı reddedildi';

  @override
  String get system_event_default_actor => 'Kullanıcı';

  @override
  String get system_event_default_device => 'cihaz';

  @override
  String get image_editor_add_caption => 'Açıklama ekle...';

  @override
  String get image_editor_crop_failed => 'Resim kırpılamadı';

  @override
  String get image_editor_draw_hint => 'Çizim modu: resim üzerinde kaydırın';

  @override
  String get image_editor_crop_title => 'Kırp';

  @override
  String get location_preview_title => 'Konum';

  @override
  String get location_preview_accuracy_unknown => 'Doğruluk: —';

  @override
  String location_preview_accuracy_meters(String meters) {
    return 'Doğruluk: ~$meters m';
  }

  @override
  String location_preview_accuracy_km(String km) {
    return 'Doğruluk: ~$km km';
  }

  @override
  String get group_member_profile_default_name => 'Üye';

  @override
  String get group_member_profile_dm => 'Direkt mesaj gönder';

  @override
  String get group_member_profile_dm_hint => 'Bu üyeyle direkt sohbet aç';

  @override
  String group_member_profile_dm_failed(Object error) {
    return 'Direkt sohbet açılamadı: $error';
  }

  @override
  String get conversation_game_lobby_unavailable =>
      'Oyun kullanılamıyor veya silindi';

  @override
  String get conversation_game_lobby_back => 'Geri';

  @override
  String get conversation_game_lobby_waiting => 'Rakibin katılması bekleniyor…';

  @override
  String get conversation_game_lobby_start_game => 'Oyunu başlat';

  @override
  String get conversation_game_lobby_waiting_short => 'Bekleniyor…';

  @override
  String get conversation_game_lobby_ready => 'Hazır';

  @override
  String get voice_preview_trim_confirm_title =>
      'Yalnızca seçilen parça korunsun mu?';

  @override
  String get voice_preview_trim_confirm_body =>
      'Seçilen parça dışındaki her şey silinecek. Düğmeye bastıktan sonra kayıt hemen devam edecek.';

  @override
  String get voice_preview_continue => 'Devam et';

  @override
  String get voice_preview_continue_recording => 'Kaydı sürdür';

  @override
  String get group_avatar_change_short => 'Değiştir';

  @override
  String get avatar_picker_cancel => 'İptal';

  @override
  String get avatar_picker_choose => 'Avatar seç';

  @override
  String get avatar_picker_delete_photo => 'Fotoğrafı sil';

  @override
  String get avatar_picker_loading => 'Yükleniyor…';

  @override
  String get avatar_picker_choose_avatar => 'Avatar seç';

  @override
  String get avatar_picker_change_avatar => 'Avatarı değiştir';

  @override
  String get avatar_picker_remove_tooltip => 'Kaldır';

  @override
  String get telegram_sign_in_title => 'Telegram ile giriş yap';

  @override
  String get telegram_sign_in_open_in_browser => 'Tarayıcıda aç';

  @override
  String get telegram_sign_in_open_telegram_failed =>
      'Telegram açılamadı. Lütfen Telegram uygulamasını yükleyin.';

  @override
  String get telegram_sign_in_page_load_error => 'Sayfa yükleme hatası';

  @override
  String get telegram_sign_in_login_error => 'Telegram giriş hatası.';

  @override
  String get telegram_sign_in_firebase_not_ready => 'Firebase hazır değil.';

  @override
  String get telegram_sign_in_browser_failed => 'Tarayıcı açılamadı.';

  @override
  String telegram_sign_in_login_failed(Object error) {
    return 'Giriş başarısız: $error';
  }

  @override
  String get yandex_sign_in_title => 'Yandex ile giriş yap';

  @override
  String get yandex_sign_in_open_in_browser => 'Tarayıcıda aç';

  @override
  String get yandex_sign_in_page_load_error => 'Sayfa yükleme hatası';

  @override
  String get yandex_sign_in_login_error => 'Yandex giriş hatası.';

  @override
  String get yandex_sign_in_firebase_not_ready => 'Firebase hazır değil.';

  @override
  String get yandex_sign_in_browser_failed => 'Tarayıcı açılamadı.';

  @override
  String yandex_sign_in_login_failed(Object error) {
    return 'Giriş başarısız: $error';
  }

  @override
  String get google_complete_title => 'Kaydı tamamla';

  @override
  String get google_complete_subtitle =>
      'Google ile giriş yaptıktan sonra, lütfen profilinizi web sürümünde olduğu gibi doldurun.';

  @override
  String get google_complete_name_label => 'Ad';

  @override
  String get google_complete_username_label => 'Kullanıcı adı (@kullanıcı_adı)';

  @override
  String get google_complete_phone_label => 'Telefon (11 haneli)';

  @override
  String get google_complete_email_label => 'E-posta';

  @override
  String get google_complete_email_hint => 'siz@ornek.com';

  @override
  String get google_complete_dob_label =>
      'Doğum tarihi (YYYY-AA-GG, isteğe bağlı)';

  @override
  String get google_complete_bio_label =>
      'Hakkında (en fazla 200 karakter, isteğe bağlı)';

  @override
  String get google_complete_save => 'Kaydet ve devam et';

  @override
  String get google_complete_back => 'Girişe geri dön';

  @override
  String get game_error_defense_not_beat => 'Bu kart saldıran kartı yenmiyor';

  @override
  String get game_error_attacker_first => 'Saldıran önce hamle yapar';

  @override
  String get game_error_defender_no_attack => 'Savunan şu anda saldıramaz';

  @override
  String get game_error_not_allowed_throwin => 'Bu turda atamazsınız';

  @override
  String get game_error_throwin_not_turn => 'Başka bir oyuncu şu anda atıyor';

  @override
  String get game_error_rank_not_allowed =>
      'Yalnızca aynı değerdeki kartı atabilirsiniz';

  @override
  String get game_error_cannot_throw_in => 'Daha fazla kart atılamaz';

  @override
  String get game_error_card_not_in_hand => 'Bu kart artık elinizde değil';

  @override
  String get game_error_already_defended => 'Bu kart zaten savunuldu';

  @override
  String get game_error_bad_attack_index =>
      'Savunulacak bir saldırı kartı seçin';

  @override
  String get game_error_only_defender => 'Başka bir oyuncu şu anda savunuyor';

  @override
  String get game_error_defender_taking => 'Savunan zaten kartları alıyor';

  @override
  String get game_error_game_not_active => 'Oyun artık aktif değil';

  @override
  String get game_error_not_in_lobby => 'Lobi zaten başladı';

  @override
  String get game_error_game_already_active => 'Oyun zaten başladı';

  @override
  String get game_error_active_exists => 'Bu sohbette zaten aktif bir oyun var';

  @override
  String get game_error_round_pending => 'Önce tartışmalı hamleyi tamamlayın';

  @override
  String get game_error_rematch_failed =>
      'Rövanş hazırlanamadı. Tekrar deneyin';

  @override
  String get game_error_unauthenticated => 'Giriş yapmanız gerekiyor';

  @override
  String get game_error_permission_denied =>
      'Bu işlem sizin için kullanılamıyor';

  @override
  String get game_error_invalid_argument => 'Geçersiz hamle';

  @override
  String get game_error_precondition => 'Hamle şu anda kullanılamıyor';

  @override
  String get game_error_server => 'Hamle yapılamadı. Tekrar deneyin';

  @override
  String get reply_sticker => 'Çıkartma';

  @override
  String get reply_gif => 'GIF';

  @override
  String get reply_video_circle => 'Video daire';

  @override
  String get reply_voice_message => 'Sesli mesaj';

  @override
  String get reply_video => 'Video';

  @override
  String get reply_photo => 'Fotoğraf';

  @override
  String get reply_file => 'Dosya';

  @override
  String get reply_location => 'Konum';

  @override
  String get reply_poll => 'Anket';

  @override
  String get reply_link => 'Bağlantı';

  @override
  String get reply_message => 'Mesaj';

  @override
  String get reply_sender_you => 'Siz';

  @override
  String get reply_sender_member => 'Üye';

  @override
  String get call_format_today => 'Bugün';

  @override
  String get call_format_yesterday => 'Dün';

  @override
  String get call_format_second_short => 'sn';

  @override
  String get call_format_minute_short => 'dk';

  @override
  String get call_format_hour_short => 'sa';

  @override
  String get call_format_day_short => 'g';

  @override
  String get call_month_january => 'Ocak';

  @override
  String get call_month_february => 'Şubat';

  @override
  String get call_month_march => 'Mart';

  @override
  String get call_month_april => 'Nisan';

  @override
  String get call_month_may => 'Mayıs';

  @override
  String get call_month_june => 'Haziran';

  @override
  String get call_month_july => 'Temmuz';

  @override
  String get call_month_august => 'Ağustos';

  @override
  String get call_month_september => 'Eylül';

  @override
  String get call_month_october => 'Ekim';

  @override
  String get call_month_november => 'Kasım';

  @override
  String get call_month_december => 'Aralık';

  @override
  String get push_incoming_call => 'Gelen arama';

  @override
  String get push_incoming_video_call => 'Gelen görüntülü arama';

  @override
  String get push_new_message => 'Yeni mesaj';

  @override
  String get push_channel_calls => 'Aramalar';

  @override
  String get push_channel_messages => 'Mesajlar';

  @override
  String contacts_years_one(Object count) {
    return '$count yıl';
  }

  @override
  String contacts_years_few(Object count) {
    return '$count yıl';
  }

  @override
  String contacts_years_many(Object count) {
    return '$count yıl';
  }

  @override
  String contacts_years_other(Object count) {
    return '$count yıl';
  }

  @override
  String get durak_entry_single_game => 'Tek oyun';

  @override
  String get durak_entry_finish_game_tooltip => 'Oyunu bitir';

  @override
  String get durak_entry_tournament_games_dialog_title => 'Turnuvada kaç oyun?';

  @override
  String get durak_entry_cancel => 'İptal';

  @override
  String get durak_entry_create => 'Oluştur';

  @override
  String video_editor_load_failed(Object error) {
    return 'Video yüklenemedi: $error';
  }

  @override
  String video_editor_process_failed(Object error) {
    return 'Video işlenemedi: $error';
  }

  @override
  String video_editor_duration(Object duration) {
    return 'Süre: $duration';
  }

  @override
  String get video_editor_brush => 'Fırça';

  @override
  String get video_editor_caption_hint => 'Açıklama ekle...';

  @override
  String get video_effects_speed => 'Скорость';

  @override
  String get video_filter_none => 'Оригинал';

  @override
  String get video_filter_enhance => 'Улучшить';

  @override
  String get share_location_title => 'Konum paylaş';

  @override
  String get share_location_how => 'Paylaşım yöntemi';

  @override
  String get share_location_cancel => 'İptal';

  @override
  String get share_location_send => 'Gönder';

  @override
  String get photo_source_gallery => 'Galeri';

  @override
  String get photo_source_take_photo => 'Fotoğraf çek';

  @override
  String get photo_source_record_video => 'Video kaydet';

  @override
  String get video_attachment_media_kind => 'video';

  @override
  String get video_attachment_title => 'Video';

  @override
  String get video_attachment_playback_error =>
      'Video oynatılamıyor. Bağlantıyı ve ağ bağlantısını kontrol edin.';

  @override
  String get location_card_broadcast_ended_mine =>
      'Konum yayını sona erdi. Diğer kişi artık mevcut konumunuzu göremiyor.';

  @override
  String get location_card_broadcast_ended_other =>
      'Bu kişinin konum yayını sona erdi. Mevcut konum kullanılamıyor.';

  @override
  String get location_card_title => 'Konum';

  @override
  String location_card_accuracy(Object meters) {
    return '±$meters m';
  }

  @override
  String get link_webview_copy_tooltip => 'Bağlantıyı kopyala';

  @override
  String get link_webview_copied_snackbar => 'Bağlantı kopyalandı';

  @override
  String get link_webview_open_browser_tooltip => 'Tarayıcıda aç';

  @override
  String get hold_record_pause => 'Duraklatıldı';

  @override
  String get hold_record_release_cancel => 'İptal etmek için bırakın';

  @override
  String get hold_record_slide_hints =>
      'Sola kaydır — iptal · Yukarı — duraklatma';

  @override
  String get e2ee_badge_loading => 'Parmak izi yükleniyor…';

  @override
  String e2ee_badge_error(Object error) {
    return 'Parmak izi alınamadı: $error';
  }

  @override
  String get e2ee_badge_label => 'E2EE Parmak İzi';

  @override
  String e2ee_badge_label_with_user(Object user) {
    return 'E2EE Parmak İzi • $user';
  }

  @override
  String e2ee_badge_devices(Object count) {
    return '$count cihaz';
  }

  @override
  String get composer_link_cancel => 'İptal';

  @override
  String message_search_results_count(Object count) {
    return 'ARAMA SONUÇLARI: $count';
  }

  @override
  String get message_search_not_found => 'HİÇBİR ŞEY BULUNAMADI';

  @override
  String get message_search_participant_fallback => 'Katılımcı';

  @override
  String get wallpaper_purple => 'Mor';

  @override
  String get wallpaper_pink => 'Pembe';

  @override
  String get wallpaper_blue => 'Mavi';

  @override
  String get wallpaper_green => 'Yeşil';

  @override
  String get wallpaper_sunset => 'Gün batımı';

  @override
  String get wallpaper_tender => 'Zarif';

  @override
  String get wallpaper_lime => 'Yeşil limon';

  @override
  String get wallpaper_graphite => 'Grafit';

  @override
  String get avatar_crop_title => 'Avatarı ayarla';

  @override
  String get avatar_crop_hint =>
      'Sürükleyin ve yakınlaştırın — daire listelerde ve mesajlarda görünecek; tam çerçeve profil için kalacak.';

  @override
  String get avatar_crop_cancel => 'İptal';

  @override
  String get avatar_crop_reset => 'Sıfırla';

  @override
  String get avatar_crop_save => 'Kaydet';

  @override
  String get meeting_entry_connecting => 'Toplantıya bağlanılıyor…';

  @override
  String meeting_entry_auth_failed(Object error) {
    return 'Giriş yapılamadı: $error';
  }

  @override
  String get meeting_entry_participant_fallback => 'Katılımcı';

  @override
  String get meeting_entry_back => 'Geri';

  @override
  String get meeting_chat_copy => 'Kopyala';

  @override
  String get meeting_chat_edit => 'Düzenle';

  @override
  String get meeting_chat_delete => 'Sil';

  @override
  String get meeting_chat_deleted => 'Mesaj silindi';

  @override
  String get meeting_chat_edited_mark => '• düzenlendi';

  @override
  String get meeting_chat_reply => 'Ответить';

  @override
  String get meeting_chat_react => 'Реакция';

  @override
  String get meeting_chat_copied => 'Скопировано';

  @override
  String get meeting_chat_editing => 'Редактирование';

  @override
  String meeting_chat_reply_to(Object name) {
    return 'Ответ $name';
  }

  @override
  String get meeting_chat_attachment_placeholder => 'Вложение';

  @override
  String meeting_timer_remaining(Object time) {
    return 'Осталось $time';
  }

  @override
  String meeting_timer_elapsed(Object time) {
    return '$time';
  }

  @override
  String get meeting_back_to_chats => 'К чатам';

  @override
  String get meeting_open_chats => 'Открыть чаты';

  @override
  String get meeting_in_call_chat => 'Чат конференции';

  @override
  String get meeting_lobby_open_settings => 'Открыть настройки';

  @override
  String get meeting_lobby_retry => 'Повторить';

  @override
  String get meeting_minimized_resume => 'Нажмите, чтобы вернуться';

  @override
  String get e2ee_decrypt_image_failed => 'Resmin şifresi çözülemedi';

  @override
  String get e2ee_decrypt_video_failed => 'Videonun şifresi çözülemedi';

  @override
  String get e2ee_decrypt_audio_failed => 'Sesin şifresi çözülemedi';

  @override
  String get e2ee_decrypt_attachment_failed => 'Ekin şifresi çözülemedi';

  @override
  String get search_preview_attachment => 'Ek';

  @override
  String get search_preview_location => 'Konum';

  @override
  String get search_preview_message => 'Mesaj';

  @override
  String get outbox_attachment_singular => 'Ek';

  @override
  String outbox_attachments_count(int count) {
    return 'Ekler ($count)';
  }

  @override
  String get outbox_chat_unavailable => 'Sohbet hizmeti kullanılamıyor';

  @override
  String outbox_encryption_error(String code) {
    return 'Şifreleme: $code';
  }

  @override
  String get nav_chats => 'Sohbetler';

  @override
  String get nav_contacts => 'Kişiler';

  @override
  String get nav_meetings => 'Toplantılar';

  @override
  String get nav_calls => 'Aramalar';

  @override
  String get e2ee_media_decrypt_failed_image => 'Resmin şifresi çözülemedi';

  @override
  String get e2ee_media_decrypt_failed_video => 'Videonun şifresi çözülemedi';

  @override
  String get e2ee_media_decrypt_failed_audio => 'Sesin şifresi çözülemedi';

  @override
  String get e2ee_media_decrypt_failed_attachment => 'Ekin şifresi çözülemedi';

  @override
  String get chat_search_snippet_attachment => 'Ek';

  @override
  String get chat_search_snippet_location => 'Konum';

  @override
  String get chat_search_snippet_message => 'Mesaj';

  @override
  String get bottom_nav_chats => 'Sohbetler';

  @override
  String get bottom_nav_contacts => 'Kişiler';

  @override
  String get bottom_nav_meetings => 'Toplantılar';

  @override
  String get bottom_nav_calls => 'Aramalar';

  @override
  String get chat_list_swipe_folders => 'KLASÖRLER';

  @override
  String get chat_list_swipe_clear => 'TEMİZLE';

  @override
  String get chat_list_swipe_delete => 'SİL';

  @override
  String get composer_editing_title => 'MESAJ DÜZENLENİYOR';

  @override
  String get composer_editing_cancel_tooltip => 'Düzenlemeyi iptal et';

  @override
  String get composer_formatting_title => 'BİÇİMLENDİRME';

  @override
  String get composer_link_preview_loading => 'Önizleme yükleniyor…';

  @override
  String get composer_link_preview_hide_tooltip => 'Önizlemeyi gizle';

  @override
  String get chat_invite_button => 'Davet et';

  @override
  String get forward_preview_unknown_sender => 'Bilinmeyen';

  @override
  String get forward_preview_attachment => 'Ek';

  @override
  String get forward_preview_message => 'Mesaj';

  @override
  String get chat_mention_no_matches => 'Eşleşme yok';

  @override
  String get live_location_sharing => 'Konumunuzu paylaşıyorsunuz';

  @override
  String get live_location_stop => 'Durdur';

  @override
  String get chat_message_deleted => 'Mesaj silindi';

  @override
  String get profile_qr_share => 'Paylaş';

  @override
  String get shared_location_open_browser_tooltip => 'Tarayıcıda aç';

  @override
  String get reply_preview_message_fallback => 'Mesaj';

  @override
  String get video_circle_media_kind => 'video';

  @override
  String reactions_rated_count(int count) {
    return 'Tepki veren: $count';
  }

  @override
  String reactions_today_time(String time) {
    return 'Bugün, $time';
  }

  @override
  String get durak_create_timer_subtitle => 'Varsayılan 15 saniye';

  @override
  String get dm_game_banner_active => 'Durak oyunu devam ediyor';

  @override
  String get dm_game_banner_created => 'Durak oyunu oluşturuldu';

  @override
  String get chat_folder_favorites => 'Favoriler';

  @override
  String get chat_folder_new => 'Yeni';

  @override
  String get contact_profile_user_fallback => 'Kullanıcı';

  @override
  String contact_profile_error(String error) {
    return 'Hata: $error';
  }

  @override
  String get conversation_threads_loading_title => 'Konular';

  @override
  String get theme_label_light => 'Açık';

  @override
  String get theme_label_dark => 'Koyu';

  @override
  String get theme_label_auto => 'Otomatik';

  @override
  String get chat_draft_reply_fallback => 'Yanıtla';

  @override
  String get mention_default_label => 'Üye';

  @override
  String get contacts_fallback_name => 'Kişi';

  @override
  String get sticker_pack_default_name => 'Paketim';

  @override
  String get profile_error_phone_taken =>
      'Bu telefon numarası zaten kayıtlı. Lütfen farklı bir numara kullanın.';

  @override
  String get profile_error_email_taken =>
      'Bu e-posta zaten kullanılıyor. Lütfen farklı bir adres kullanın.';

  @override
  String get profile_error_username_taken =>
      'Bu kullanıcı adı zaten alınmış. Lütfen başka bir tane seçin.';

  @override
  String get e2ee_banner_default_context => 'Mesaj';

  @override
  String e2ee_banner_encrypted_chat_web_only(String prefix) {
    return '$prefix şifreli bir sohbete şu anda yalnızca web istemcisinden gönderilebilir.';
  }

  @override
  String get chat_attachment_decrypt_error => 'Ekin şifresi çözülemedi';

  @override
  String get mention_fallback_label => 'üye';

  @override
  String get mention_fallback_label_capitalized => 'Üye';

  @override
  String get meeting_speaking_label => 'Konuşuyor';

  @override
  String meeting_local_you_suffix(String name) {
    return '$name (Siz)';
  }

  @override
  String get video_crop_title => 'Kırp';

  @override
  String video_crop_load_error(String error) {
    return 'Video yüklenemedi: $error';
  }

  @override
  String get gif_section_recent => 'SON KULLANILANLAR';

  @override
  String get gif_section_trending => 'TREND';

  @override
  String get auth_create_account_title => 'Hesap Oluştur';

  @override
  String yandex_sign_in_yandex_error(String error) {
    return 'Yandex: $error';
  }

  @override
  String get call_status_missed => 'Cevapsız';

  @override
  String get call_status_cancelled => 'İptal edildi';

  @override
  String get call_status_ended => 'Sona erdi';

  @override
  String get presence_offline => 'Çevrimdışı';

  @override
  String get presence_online => 'Çevrimiçi';

  @override
  String get dm_title_fallback => 'Sohbet';

  @override
  String get dm_title_partner_fallback => 'Kişi';

  @override
  String get group_title_fallback => 'Grup sohbeti';

  @override
  String get block_call_viewer_blocked =>
      'Bu kullanıcıyı engellediniz. Arama kullanılamıyor — Profil → Engellenenler\'den engeli kaldırın.';

  @override
  String get block_call_partner_blocked =>
      'Bu kullanıcı sizinle iletişimi kısıtladı. Arama kullanılamıyor.';

  @override
  String get block_call_unavailable => 'Arama kullanılamıyor.';

  @override
  String get block_composer_viewer_blocked =>
      'Bu kullanıcıyı engellediniz. Gönderim kullanılamıyor — Profil → Engellenenler\'den engeli kaldırın.';

  @override
  String get block_composer_partner_blocked =>
      'Bu kullanıcı sizinle iletişimi kısıtladı. Gönderim kullanılamıyor.';

  @override
  String get forward_group_fallback => 'Grup';

  @override
  String get forward_unknown_user => 'Bilinmeyen';

  @override
  String get live_location_once => 'Tek seferlik (yalnızca bu mesaj)';

  @override
  String get live_location_5min => '5 dakika';

  @override
  String get live_location_15min => '15 dakika';

  @override
  String get live_location_30min => '30 dakika';

  @override
  String get live_location_1hour => '1 saat';

  @override
  String get live_location_2hours => '2 saat';

  @override
  String get live_location_6hours => '6 saat';

  @override
  String get live_location_1day => '1 gün';

  @override
  String get live_location_forever => 'Sonsuza kadar (ben kapatana kadar)';

  @override
  String get e2ee_send_too_many_files =>
      'Şifreli gönderim için çok fazla ek: mesaj başına en fazla 5 dosya.';

  @override
  String get e2ee_send_too_large =>
      'Toplam ek boyutu çok büyük: bir şifreli mesaj için en fazla 96 MB.';

  @override
  String get presence_last_seen_prefix => 'Son görülme ';

  @override
  String get presence_less_than_minute_ago => 'bir dakikadan kısa süre önce';

  @override
  String get presence_yesterday => 'dün';

  @override
  String get dm_fallback_title => 'Sohbet';

  @override
  String get dm_fallback_partner => 'Kişi';

  @override
  String get group_fallback_title => 'Grup sohbeti';

  @override
  String get block_send_viewer_blocked =>
      'Bu kullanıcıyı engellediniz. Gönderim kullanılamıyor — Profil → Engellenenler\'den engeli kaldırın.';

  @override
  String get block_send_partner_blocked =>
      'Bu kullanıcı sizinle iletişimi kısıtladı. Gönderim kullanılamıyor.';

  @override
  String get mention_fallback_name => 'Üye';

  @override
  String get profile_conflict_phone =>
      'Bu telefon numarası zaten kayıtlı. Lütfen farklı bir numara kullanın.';

  @override
  String get profile_conflict_email =>
      'Bu e-posta zaten kullanılıyor. Lütfen farklı bir adres kullanın.';

  @override
  String get profile_conflict_username =>
      'Bu kullanıcı adı zaten alınmış. Lütfen farklı bir tane seçin.';

  @override
  String get mention_fallback_participant => 'Katılımcı';

  @override
  String get sticker_gif_recent => 'SON KULLANILANLAR';

  @override
  String get meeting_screen_sharing => 'Ekran';

  @override
  String get meeting_speaking => 'Konuşuyor';

  @override
  String auth_sign_in_failed(Object error) {
    return 'Giriş başarısız: $error';
  }

  @override
  String yandex_error_prefix(Object error) {
    return 'Yandex: $error';
  }

  @override
  String auth_error_prefix(Object error) {
    return 'Kimlik doğrulama hatası: $error';
  }

  @override
  String presence_minutes_ago(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dakika önce',
      one: 'bir dakika önce',
    );
    return '$_temp0';
  }

  @override
  String presence_hours_ago(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count saat önce',
      one: 'bir saat önce',
    );
    return '$_temp0';
  }

  @override
  String presence_days_ago(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gün önce',
      one: 'bir gün önce',
    );
    return '$_temp0';
  }

  @override
  String presence_months_ago(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ay önce',
      one: 'bir ay önce',
    );
    return '$_temp0';
  }

  @override
  String presence_years_months_ago(int years, int months) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years yıl',
      one: '1 yıl',
    );
    String _temp1 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$months ay önce',
      one: '1 ay önce',
    );
    return '$_temp0 $_temp1';
  }

  @override
  String presence_years_ago(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count yıl önce',
      one: 'bir yıl önce',
    );
    return '$_temp0';
  }

  @override
  String get wallpaper_gradient_purple => 'Mor';

  @override
  String get wallpaper_gradient_pink => 'Pembe';

  @override
  String get wallpaper_gradient_blue => 'Mavi';

  @override
  String get wallpaper_gradient_green => 'Yeşil';

  @override
  String get wallpaper_gradient_sunset => 'Gün batımı';

  @override
  String get wallpaper_gradient_gentle => 'Zarif';

  @override
  String get wallpaper_gradient_lime => 'Yeşil limon';

  @override
  String get wallpaper_gradient_graphite => 'Grafit';

  @override
  String get sticker_tab_recent => 'SON KULLANILANLAR';

  @override
  String get block_call_you_blocked =>
      'Bu kullanıcıyı engellediniz. Arama kullanılamıyor — Profil → Engellenenler\'den engeli kaldırın.';

  @override
  String get block_call_they_blocked =>
      'Bu kullanıcı sizinle iletişimi kısıtladı. Arama kullanılamıyor.';

  @override
  String get block_call_generic => 'Arama kullanılamıyor.';

  @override
  String get block_send_you_blocked =>
      'Bu kullanıcıyı engellediniz. Gönderim kullanılamıyor — Profil → Engellenenler\'den engeli kaldırın.';

  @override
  String get block_send_they_blocked =>
      'Bu kullanıcı sizinle iletişimi kısıtladı. Gönderim kullanılamıyor.';

  @override
  String get forward_unknown_fallback => 'Bilinmeyen';

  @override
  String get dm_title_chat => 'Sohbet';

  @override
  String get dm_title_partner => 'Ortak';

  @override
  String get dm_title_group => 'Grup sohbeti';

  @override
  String get e2ee_too_many_attachments =>
      'Şifreli gönderim için çok fazla ek: mesaj başına en fazla 5 dosya.';

  @override
  String get e2ee_total_size_exceeded =>
      'Toplam ek boyutu çok büyük: şifreli mesaj başına en fazla 96 MB.';

  @override
  String composer_limit_too_many_files(int current, int max, int diff) {
    return 'Çok fazla ek: $current/$max. Göndermek için $diff tanesini kaldırın.';
  }

  @override
  String composer_limit_total_size_exceeded(String currentMb, String maxMb) {
    return 'Ekler çok büyük: $currentMb MB / $maxMb MB. Göndermek için bazılarını kaldırın.';
  }

  @override
  String get composer_limit_blocking_send => 'Ek sınırı aşıldı';

  @override
  String yandex_sign_in_error_prefix(String error) {
    return 'Yandex: $error';
  }

  @override
  String get meeting_participant_screen => 'Ekran';

  @override
  String get meeting_participant_speaking => 'Konuşuyor';

  @override
  String get nav_error_title => 'Gezinme hatası';

  @override
  String get nav_error_invalid_secret_compose =>
      'Geçersiz gizli oluşturma gezinmesi';

  @override
  String get sign_in_title => 'Giriş yap';

  @override
  String get sign_in_firebase_ready =>
      'Firebase başlatıldı. Giriş yapabilirsiniz.';

  @override
  String get sign_in_firebase_not_ready =>
      'Firebase hazır değil. Günlükleri ve firebase_options.dart dosyasını kontrol edin.';

  @override
  String get sign_in_continue => 'Devam et';

  @override
  String get sign_in_anonymously => 'Anonim olarak giriş yap';

  @override
  String sign_in_auth_error(String error) {
    return 'Kimlik doğrulama hatası: $error';
  }

  @override
  String generic_error(String error) {
    return 'Hata: $error';
  }

  @override
  String get storage_label_video => 'Video';

  @override
  String get storage_label_photo => 'Fotoğraf';

  @override
  String get storage_label_audio => 'Ses';

  @override
  String get storage_label_files => 'Dosyalar';

  @override
  String get storage_label_other => 'Diğer';

  @override
  String get storage_label_recent_stickers => 'Son kullanılan çıkartmalar';

  @override
  String get storage_label_giphy_search => 'GIPHY · arama önbelleği';

  @override
  String get storage_label_giphy_recent => 'GIPHY · son GIF\'ler';

  @override
  String get storage_chat_unattributed => 'Sohbete atanmamış';

  @override
  String storage_label_draft(String key) {
    return 'Taslak · $key';
  }

  @override
  String get storage_label_offline_snapshot =>
      'Çevrimdışı sohbet listesi anlık görüntüsü';

  @override
  String storage_label_profile_cache(String name) {
    return 'Profil önbelleği · $name';
  }

  @override
  String get call_mini_end => 'Aramayı sonlandır';

  @override
  String get animation_quality_lite => 'Hafif';

  @override
  String get animation_quality_balanced => 'Dengeli';

  @override
  String get animation_quality_cinematic => 'Sinematik';

  @override
  String get crop_aspect_original => 'Orijinal';

  @override
  String get crop_aspect_square => 'Kare';

  @override
  String get push_notification_title => 'Bildirimlere izin ver';

  @override
  String get push_notification_rationale =>
      'Uygulamanın gelen aramalar için bildirimlere ihtiyacı var.';

  @override
  String get push_notification_required =>
      'Gelen aramaları görüntülemek için bildirimleri etkinleştirin.';

  @override
  String get push_notification_grant => 'İzin ver';

  @override
  String get push_call_accept => 'Kabul et';

  @override
  String get push_call_decline => 'Reddet';

  @override
  String get push_channel_incoming_calls => 'Gelen aramalar';

  @override
  String get push_channel_missed_calls => 'Cevapsız aramalar';

  @override
  String get push_channel_messages_desc => 'Sohbetlerdeki yeni mesajlar';

  @override
  String get push_channel_silent => 'Sessiz mesajlar';

  @override
  String get push_channel_silent_desc => 'Sessiz bildirim';

  @override
  String get push_caller_unknown => 'Biri';

  @override
  String get outbox_attachment_single => 'Ek';

  @override
  String outbox_attachment_count(int count) {
    return 'Ekler ($count)';
  }

  @override
  String get bottom_nav_label_chats => 'Sohbetler';

  @override
  String get bottom_nav_label_contacts => 'Kişiler';

  @override
  String get bottom_nav_label_conferences => 'Konferanslar';

  @override
  String get bottom_nav_label_calls => 'Aramalar';

  @override
  String get welcomeBubbleTitle => 'LighChat\'e Hoş Geldiniz';

  @override
  String get welcomeBubbleSubtitle => 'Deniz feneri yanıyor';

  @override
  String get welcomeSkip => 'Atla';

  @override
  String get welcomeReplayDebugTile =>
      'Karşılama animasyonunu tekrar oynat (hata ayıklama)';

  @override
  String get sticker_scope_library => 'Kütüphane';

  @override
  String get sticker_library_search_hint => 'Çıkartma ara...';

  @override
  String get account_menu_energy_saving => 'Güç tasarrufu';

  @override
  String get energy_saving_title => 'Güç tasarrufu';

  @override
  String get energy_saving_section_mode => 'Güç tasarrufu modu';

  @override
  String get energy_saving_section_resource_heavy => 'Kaynak yoğun işlemler';

  @override
  String get energy_saving_threshold_off => 'Kapalı';

  @override
  String get energy_saving_threshold_always => 'Açık';

  @override
  String get energy_saving_threshold_off_full => 'Asla';

  @override
  String get energy_saving_threshold_always_full => 'Her zaman';

  @override
  String energy_saving_threshold_at(int percent) {
    return 'Pil %$percent\'in altındayken';
  }

  @override
  String get energy_saving_hint_off =>
      'Kaynak yoğun efektler asla otomatik olarak devre dışı bırakılmaz.';

  @override
  String get energy_saving_hint_always =>
      'Kaynak yoğun efektler pil seviyesinden bağımsız olarak her zaman devre dışıdır.';

  @override
  String energy_saving_hint_threshold(int percent) {
    return 'Pil %$percent\'in altına düştüğünde tüm kaynak yoğun işlemleri otomatik olarak devre dışı bırak.';
  }

  @override
  String energy_saving_current_battery(int percent) {
    return 'Mevcut pil: %$percent';
  }

  @override
  String get energy_saving_active_now => 'mod aktif';

  @override
  String get energy_saving_active_threshold =>
      'Pil eşik değerine ulaştı — aşağıdaki her efekt geçici olarak devre dışı.';

  @override
  String get energy_saving_active_system =>
      'Sistem güç tasarrufu açık — aşağıdaki her efekt geçici olarak devre dışı.';

  @override
  String get energy_saving_autoplay_video_title => 'Videoları otomatik oynat';

  @override
  String get energy_saving_autoplay_video_subtitle =>
      'Sohbetlerdeki video mesajlarını ve videoları otomatik oynat ve döngüye al.';

  @override
  String get energy_saving_autoplay_gif_title => 'GIF\'leri otomatik oynat';

  @override
  String get energy_saving_autoplay_gif_subtitle =>
      'Sohbetlerde ve klavyede GIF\'leri otomatik oynat ve döngüye al.';

  @override
  String get energy_saving_animated_stickers_title => 'Hareketli çıkartmalar';

  @override
  String get energy_saving_animated_stickers_subtitle =>
      'Döngülü çıkartma animasyonları ve tam ekran Premium çıkartma efektleri.';

  @override
  String get energy_saving_animated_emoji_title => 'Hareketli emoji';

  @override
  String get energy_saving_animated_emoji_subtitle =>
      'Mesajlarda, tepkilerde ve durumlarda döngülü emoji animasyonu.';

  @override
  String get energy_saving_interface_animations_title => 'Arayüz animasyonları';

  @override
  String get energy_saving_interface_animations_subtitle =>
      'LighChat\'i daha akıcı ve daha etkileyici yapan efektler ve animasyonlar.';

  @override
  String get energy_saving_media_preload_title => 'Medya ön yükleme';

  @override
  String get energy_saving_media_preload_subtitle =>
      'Sohbet listesi açılırken medya dosyalarını indirmeye başla.';

  @override
  String get energy_saving_background_update_title => 'Arka plan güncelleme';

  @override
  String get energy_saving_background_update_subtitle =>
      'Uygulamalar arasında geçiş yaparken hızlı sohbet güncellemeleri.';

  @override
  String get legal_index_title => 'Hukuki belgeler';

  @override
  String get legal_index_subtitle =>
      'Gizlilik politikası, hizmet şartları ve LighChat kullanımını düzenleyen diğer hukuki belgeler.';

  @override
  String get legal_settings_section_title => 'Hukuki bilgiler';

  @override
  String get legal_settings_section_subtitle =>
      'Gizlilik politikası, hizmet şartları, EULA ve daha fazlası.';

  @override
  String get legal_not_found => 'Belge bulunamadı';

  @override
  String get legal_title_privacy_policy => 'Gizlilik Politikası';

  @override
  String get legal_title_terms_of_service => 'Hizmet Şartları';

  @override
  String get legal_title_cookie_policy => 'Çerez Politikası';

  @override
  String get legal_title_eula => 'Son Kullanıcı Lisans Sözleşmesi';

  @override
  String get legal_title_dpa => 'Veri İşleme Sözleşmesi';

  @override
  String get legal_title_children => 'Çocuk Politikası';

  @override
  String get legal_title_moderation => 'İçerik Moderasyon Politikası';

  @override
  String get legal_title_aup => 'Kabul Edilebilir Kullanım Politikası';

  @override
  String get chat_list_item_sender_you => 'Siz';

  @override
  String get chat_preview_message => 'Mesaj';

  @override
  String get chat_preview_sticker => 'Çıkartma';

  @override
  String get chat_preview_attachment => 'Ek';

  @override
  String get contacts_disclosure_title => 'LighChat\'ta tanıdıkları bul';

  @override
  String get contacts_disclosure_body =>
      'LighChat, adres defterinizdeki telefon numaralarını ve e-posta adreslerini okur, bunları hash\'ler ve hangi kişilerinizin uygulamayı kullandığını göstermek için sunucumuzla karşılaştırır. Kişileriniz asla sunucularımızda saklanmaz.';

  @override
  String get contacts_disclosure_allow => 'İzin Ver';

  @override
  String get contacts_disclosure_deny => 'Şimdi değil';

  @override
  String get report_title => 'Şikayet Et';

  @override
  String get report_subtitle_message => 'Mesajı şikayet et';

  @override
  String get report_subtitle_user => 'Kullanıcıyı şikayet et';

  @override
  String get report_reason_spam => 'Spam';

  @override
  String get report_reason_offensive => 'Rahatsız edici içerik';

  @override
  String get report_reason_violence => 'Şiddet veya tehdit';

  @override
  String get report_reason_fraud => 'Dolandırıcılık';

  @override
  String get report_reason_other => 'Diğer';

  @override
  String get report_comment_hint => 'Ek ayrıntılar (isteğe bağlı)';

  @override
  String get report_submit => 'Gönder';

  @override
  String get report_success => 'Şikayet gönderildi. Teşekkürler!';

  @override
  String get report_error => 'Şikayet gönderilemedi';

  @override
  String get message_menu_action_report => 'Şikayet Et';

  @override
  String get partner_profile_menu_report => 'Kullanıcıyı şikayet et';

  @override
  String get call_bubble_voice_call => 'Sesli arama';

  @override
  String get call_bubble_video_call => 'Görüntülü arama';

  @override
  String get chat_preview_poll => 'Anket';

  @override
  String get chat_preview_forwarded => 'İletilen mesaj';

  @override
  String get birthday_banner_celebrates => 'doğum gününü kutluyor!';

  @override
  String get birthday_banner_action => 'Kutla →';

  @override
  String get birthday_screen_title_today => 'Bugün doğum günü';

  @override
  String birthday_screen_age(int age) {
    return '$age yaşında';
  }

  @override
  String get birthday_section_actions => 'KUTLA';

  @override
  String get birthday_action_template => 'Hazır mesaj';

  @override
  String get birthday_action_cake => 'Mumu üfle';

  @override
  String get birthday_action_confetti => 'Konfeti';

  @override
  String get birthday_action_serpentine => 'Şerit';

  @override
  String get birthday_action_voice => 'Sesli kutlama kaydet';

  @override
  String get birthday_action_remind_next_year => 'Gelecek yıl hatırlat';

  @override
  String get birthday_action_open_chat => 'Kendi mesajını yaz';

  @override
  String get birthday_cake_prompt => 'Söndürmek için muma dokun';

  @override
  String birthday_cake_wish_placeholder(Object name) {
    return '$name için ne diliyorsun?';
  }

  @override
  String get birthday_cake_wish_hint => 'Örneğin: tüm dilekleri gerçek olsun…';

  @override
  String get birthday_cake_send => 'Gönder';

  @override
  String birthday_cake_message(Object name, Object wish) {
    return '🎂 Doğum günün kutlu olsun, $name! Dileğim: «$wish»';
  }

  @override
  String birthday_confetti_message(Object name) {
    return '🎉 Doğum günün kutlu olsun, $name! 🎉';
  }

  @override
  String birthday_template_1(Object name) {
    return 'Doğum günün kutlu olsun, $name! Bu yıl en güzeli olsun!';
  }

  @override
  String birthday_template_2(Object name) {
    return '$name, tebrikler! Mutluluk, sıcaklık ve dileklerin gerçekleşmesi 🎉';
  }

  @override
  String birthday_template_3(Object name) {
    return 'Mutlu yıllar, $name! Sağlık, şans ve nice mutlu anlar 🎂';
  }

  @override
  String birthday_template_4(Object name) {
    return '$name, doğum günün kutlu olsun! Tüm planların kolay gerçekleşsin ✨';
  }

  @override
  String birthday_template_5(Object name) {
    return 'Tebrikler, $name! Var olduğun için teşekkürler. Doğum günün kutlu olsun! 🎁';
  }

  @override
  String get birthday_toast_sent => 'Kutlama gönderildi';

  @override
  String birthday_reminder_set(Object name) {
    return '$name\'nin doğum gününden bir gün önce hatırlatacağız';
  }

  @override
  String get birthday_reminder_notif_title => 'Yarın doğum günü 🎂';

  @override
  String birthday_reminder_notif_body(Object name) {
    return 'Yarın $name\'yi kutlamayı unutma';
  }

  @override
  String get birthday_empty => 'Bugün kişilerinde doğum günü yok';

  @override
  String get birthday_error_self => 'Profilin yüklenemedi';

  @override
  String get birthday_error_send => 'Mesaj gönderilemedi. Lütfen tekrar dene.';

  @override
  String get birthday_error_reminder => 'Hatırlatma ayarlanamadı';
}
