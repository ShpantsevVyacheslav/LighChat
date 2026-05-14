// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get secret_chat_title => 'Chat rahasia';

  @override
  String get secret_chats_title => 'Chat rahasia';

  @override
  String get secret_chat_locked_title => 'Obrolan rahasia adalah locked';

  @override
  String get secret_chat_locked_subtitle =>
      'Masukkan Anda Sematkan to unlock dan view Pesan.';

  @override
  String get secret_chat_unlock_title => 'Unlock Obrolan rahasia';

  @override
  String get secret_chat_unlock_subtitle =>
      'Sematkan adalah wajib to Buka this Obrolan.';

  @override
  String get secret_chat_unlock_action => 'Membuka kunci';

  @override
  String get secret_chat_set_pin_and_unlock => 'Set Sematkan dan unlock';

  @override
  String get secret_chat_pin_label => 'Sematkan (4 digits)';

  @override
  String get secret_chat_pin_invalid => 'Masukkan a 4-digit Sematkan';

  @override
  String get secret_chat_already_exists =>
      'Obrolan rahasia with this Pengguna already exists.';

  @override
  String get secret_chat_exists_badge => 'Dibuat';

  @override
  String get secret_chat_unlock_failed =>
      'Unable to unlock. Silakan Coba lagi.';

  @override
  String get secret_chat_action_not_allowed =>
      'This action adalah not allowed in a Obrolan rahasia';

  @override
  String get secret_chat_remember_pin => 'Remember Sematkan on Perangkat ini';

  @override
  String get secret_chat_unlock_biometric => 'Buka kunci dengan biometrik';

  @override
  String get secret_chat_biometric_reason => 'Unlock Obrolan rahasia';

  @override
  String get secret_chat_biometric_no_saved_pin =>
      'Masukkan Sematkan once to Aktifkan biometric unlock';

  @override
  String get secret_chat_ttl_title => 'Obrolan rahasia lifetime';

  @override
  String get secret_chat_settings_title => 'Obrolan rahasia Pengaturan';

  @override
  String get secret_chat_settings_subtitle =>
      'Lifetime, access, dan restrictions';

  @override
  String get secret_chat_settings_not_secret =>
      'This Obrolan adalah not a Obrolan rahasia';

  @override
  String get secret_chat_settings_ttl => 'Seumur hidup';

  @override
  String secret_chat_settings_time_left(Object value) {
    return 'Waktu tersisa: $value';
  }

  @override
  String secret_chat_settings_expires_at(Object iso) {
    return 'Berakhir pada: $iso';
  }

  @override
  String get secret_chat_settings_unlock_grant_ttl => 'Buka kunci durasi';

  @override
  String get secret_chat_settings_unlock_grant_ttl_subtitle =>
      'How long access stays Aktif after unlocking';

  @override
  String get secret_chat_settings_no_copy => 'Nonaktifkan copying';

  @override
  String get secret_chat_settings_no_forward => 'Nonaktifkan forwarding';

  @override
  String get secret_chat_settings_no_save => 'Nonaktifkan saving Media';

  @override
  String get secret_chat_settings_screenshot_protection =>
      'Perlindungan tangkapan layar (Android)';

  @override
  String get secret_chat_settings_media_views => 'Batas tampilan media';

  @override
  String get secret_chat_settings_media_views_subtitle =>
      'Batas upaya terbaik untuk tampilan penerima';

  @override
  String get secret_chat_media_type_image => 'Gambar';

  @override
  String get secret_chat_media_type_video => 'Video';

  @override
  String get secret_chat_media_type_voice => 'Suara Pesan';

  @override
  String get secret_chat_media_type_location => 'Lokasi';

  @override
  String get secret_chat_media_type_file => 'Berkas';

  @override
  String get secret_chat_media_views_unlimited => 'Tak terbatas';

  @override
  String get secret_chat_compose_create => 'Buat Obrolan rahasia';

  @override
  String get secret_chat_compose_vault_pin_subtitle =>
      'opsional: set a 4-digit vault Sematkan used for secret inbox unlock (stored on Perangkat ini for biometrics when enabled).';

  @override
  String get secret_chat_compose_require_unlock_pin =>
      'Require Sematkan to Buka this Obrolan';

  @override
  String get secret_chat_settings_read_only_hint =>
      'These Pengaturan adalah fixed at creation dan tidak dapat be changed.';

  @override
  String get secret_chat_settings_delete => 'Hapus Obrolan rahasia';

  @override
  String get secret_chat_settings_delete_confirm_title =>
      'Hapus this Obrolan rahasia?';

  @override
  String get secret_chat_settings_delete_confirm_body =>
      'Pesan dan Media akan Dihapus for both participants.';

  @override
  String get privacy_secret_vault_title => 'Gudang rahasia';

  @override
  String get privacy_secret_vault_subtitle =>
      'Global Sematkan dan biometric checks for entering Obrolan rahasia.';

  @override
  String get privacy_secret_vault_change_pin =>
      'Set atau change vault Sematkan';

  @override
  String get privacy_secret_vault_change_pin_subtitle =>
      'If Sematkan already exists, Konfirmasi using old Sematkan atau biometrics.';

  @override
  String get privacy_secret_vault_bio_subtitle =>
      'Run biometric check dan validate Disimpan local Sematkan.';

  @override
  String get privacy_secret_vault_bio_reason =>
      'Konfirmasi access to Obrolan rahasia';

  @override
  String get privacy_secret_vault_current_pin => 'Current Sematkan';

  @override
  String get privacy_secret_vault_new_pin => 'Baru Sematkan';

  @override
  String get privacy_secret_vault_repeat_pin => 'Repeat Baru Sematkan';

  @override
  String get privacy_secret_vault_pin_mismatch => 'PIN tidak cocok';

  @override
  String get privacy_secret_vault_pin_updated => 'Vault Sematkan Diperbarui';

  @override
  String get privacy_secret_vault_bio_unavailable =>
      'Biometric authentication adalah not available on Perangkat ini';

  @override
  String get privacy_secret_vault_bio_verified =>
      'Pemeriksaan biometrik berhasil';

  @override
  String get privacy_secret_vault_setup_required =>
      'Set up Sematkan atau biometric access in Privasi first.';

  @override
  String get privacy_secret_vault_network_timeout =>
      'Jaringan timeout. Silakan Coba lagi.';

  @override
  String privacy_secret_vault_error(Object error) {
    return 'Secret vault Kesalahan: $error';
  }

  @override
  String get tournament_title => 'Turnamen';

  @override
  String get tournament_subtitle => 'Standings dan Permainan series';

  @override
  String get tournament_new_game => 'Baru Permainan';

  @override
  String get tournament_standings => 'Klasemen';

  @override
  String get tournament_standings_empty => 'Tidak ada hasil yet';

  @override
  String get tournament_games => 'Permainan';

  @override
  String get tournament_games_empty => 'Tidak Permainan yet';

  @override
  String tournament_points(Object pts) {
    return '$pts poin';
  }

  @override
  String tournament_games_played(Object n) {
    return '$n Permainan';
  }

  @override
  String tournament_create_failed(Object err) {
    return 'Unable to Buat tournament: $err';
  }

  @override
  String tournament_create_game_failed(Object err) {
    return 'Unable to Buat Permainan: $err';
  }

  @override
  String tournament_game_players(Object names) {
    return 'Pemain: $names';
  }

  @override
  String get tournament_game_result_draw => 'Result: Seri';

  @override
  String tournament_game_result_loser(Object name) {
    return 'Hasil: durak — $name';
  }

  @override
  String tournament_game_place(Object place) {
    return 'Tempatkan $place';
  }

  @override
  String get durak_dm_lobby_banner =>
      'Anda partner Dibuat a Durak lobby — Gabung';

  @override
  String get durak_dm_lobby_open => 'Buka lobby';

  @override
  String get conversation_game_lobby_cancel => 'Akhir menunggu';

  @override
  String conversation_game_lobby_cancel_failed(Object err) {
    return 'Tidak dapat mengakhiri penantian: $err';
  }

  @override
  String secret_chat_media_views_count(Object count) {
    return '$count penayangan';
  }

  @override
  String secret_chat_settings_load_failed(Object error) {
    return 'Gagal to load: $error';
  }

  @override
  String secret_chat_settings_save_failed(Object error) {
    return 'Gagal to Simpan: $error';
  }

  @override
  String get secret_chat_settings_reset_strict =>
      'Atur ulang to strict defaults';

  @override
  String get secret_chat_settings_reset_strict_subtitle =>
      'Enables Semua restrictions dan sets Media view limits to 1';

  @override
  String get settings_language_title => 'Bahasa';

  @override
  String get settings_language_system => 'Sistem';

  @override
  String get settings_language_ru => 'Rusia';

  @override
  String get settings_language_en => 'English';

  @override
  String get settings_language_hint_system =>
      'When “Sistem” adalah Dipilih,  app follows Anda Perangkat Bahasa Pengaturan.';

  @override
  String get account_menu_profile => 'Profil';

  @override
  String get account_menu_features => 'Fitur';

  @override
  String get account_menu_chat_settings => 'Obrolan Pengaturan';

  @override
  String get account_menu_notifications => 'Notifikasi';

  @override
  String get account_menu_privacy => 'Privasi';

  @override
  String get account_menu_devices => 'Perangkat';

  @override
  String get account_menu_blacklist => 'Daftar Hitam';

  @override
  String get account_menu_language => 'Bahasa';

  @override
  String get account_menu_storage => 'Penyimpanan';

  @override
  String get account_menu_theme => 'Tema';

  @override
  String get account_menu_sign_out => 'Keluar';

  @override
  String get storage_settings_title => 'Penyimpanan';

  @override
  String get storage_settings_subtitle =>
      'Control what Data adalah cached on Perangkat ini dan clean up by Obrolan atau Berkas.';

  @override
  String get storage_settings_total_label => 'Used on Perangkat ini';

  @override
  String storage_settings_budget_label(Object gb) {
    return 'Batas cache: $gb GB';
  }

  @override
  String get storage_unit_gb => 'GB';

  @override
  String get storage_settings_clear_all_button => 'Hapus Semua cache';

  @override
  String get storage_settings_trim_button => 'Pangkas sesuai anggaran';

  @override
  String get storage_settings_policy_title =>
      'Apa yang harus disimpan secara lokal';

  @override
  String get storage_settings_budget_slider_title => 'Anggaran cache';

  @override
  String get storage_settings_breakdown_title => 'By Data type';

  @override
  String get storage_settings_breakdown_empty => 'Tidak local cached Data yet.';

  @override
  String get storage_settings_chats_title => 'By Obrolan';

  @override
  String get storage_settings_chats_empty =>
      'Tidak Obrolan-specific cache yet.';

  @override
  String storage_settings_chat_subtitle(Object count, Object size) {
    return '$count item · $size';
  }

  @override
  String get storage_settings_general_title => 'Cache yang belum ditetapkan';

  @override
  String get storage_settings_general_hint =>
      'Entries not linked to a specific Obrolan (legacy/global cache).';

  @override
  String get storage_settings_general_empty => 'Tidak shared cache entries.';

  @override
  String get storage_settings_chat_files_empty =>
      'Tidak local Berkas in this Obrolan cache.';

  @override
  String get storage_settings_clear_chat_action => 'Hapus Obrolan cache';

  @override
  String get storage_settings_clear_all_title => 'Hapus local cache?';

  @override
  String get storage_settings_clear_all_body =>
      'This will Hapus cached Berkas, previews, drafts, dan Luring snapshots from Perangkat ini.';

  @override
  String storage_settings_clear_chat_title(Object chat) {
    return 'Hapus cache for “$chat”?';
  }

  @override
  String get storage_settings_clear_chat_body =>
      'Only this Obrolan cache akan Dihapus. Pesan in cloud stay intact.';

  @override
  String get storage_settings_snackbar_cleared => 'Cache lokal dibersihkan';

  @override
  String get storage_settings_snackbar_budget_already_ok =>
      'Cache already fits  target budget';

  @override
  String storage_settings_snackbar_budget_trimmed(Object size) {
    return 'Dibebaskan: $size';
  }

  @override
  String get storage_settings_error_empty =>
      'Unable to build Penyimpanan statistics';

  @override
  String get storage_category_e2ee_media => 'E2EE Media cache';

  @override
  String get storage_category_e2ee_media_subtitle =>
      'Decrypted secret Media Berkas per Obrolan for faster reopening.';

  @override
  String get storage_category_e2ee_text => 'E2EE cache teks';

  @override
  String get storage_category_e2ee_text_subtitle =>
      'Decrypted text snippets per Obrolan for instant rendering.';

  @override
  String get storage_category_drafts => 'Pesan drafts';

  @override
  String get storage_category_drafts_subtitle =>
      'Unsent draft text by Obrolan.';

  @override
  String get storage_category_chat_list_snapshot => 'Luring Obrolan list';

  @override
  String get storage_category_chat_list_snapshot_subtitle =>
      'Recent Obrolan list snapshot for quick startup Luring.';

  @override
  String get storage_category_profile_cards => 'Profil mini-cache';

  @override
  String get storage_category_profile_cards_subtitle =>
      'Names dan avatars Disimpan for faster UI.';

  @override
  String get storage_category_video_downloads => 'Downloaded Video cache';

  @override
  String get storage_category_video_downloads_subtitle =>
      'Locally downloaded Video from Galeri views.';

  @override
  String get storage_category_video_thumbs => 'Bingkai pratinjau video';

  @override
  String get storage_category_video_thumbs_subtitle =>
      'Generated first-frame thumbnails for Video.';

  @override
  String get storage_category_chat_images => 'Obrolan Foto';

  @override
  String get storage_category_chat_images_subtitle =>
      'Cached Foto dan Stiker from Buka Obrolan.';

  @override
  String get storage_category_stickers_gifs_emoji => 'Stiker, GIF, emoji';

  @override
  String get storage_category_stickers_gifs_emoji_subtitle =>
      'Cache stiker terbaru dan GIPHY (gif/stiker/emoji animasi).';

  @override
  String get storage_category_network_images => 'Cache gambar jaringan';

  @override
  String get storage_category_network_images_subtitle =>
      'Avatar, pratinjau, dan gambar lain yang diambil dari jaringan (libCachedImageData).';

  @override
  String get storage_media_type_video => 'Video';

  @override
  String get storage_media_type_photo => 'Foto';

  @override
  String get storage_media_type_audio => 'Audio';

  @override
  String get storage_media_type_files => 'Berkas';

  @override
  String get storage_media_type_other => 'Lainnya';

  @override
  String storage_settings_device_usage(Object pct) {
    return 'Uses $pct% dari cache budget';
  }

  @override
  String get storage_settings_clear_all_hint =>
      'Semua Media will stay in cloud. Anda dapat re-Unduh any time.';

  @override
  String get storage_settings_categories_title => 'Berdasarkan kategori';

  @override
  String storage_settings_clear_category_title(String category) {
    return 'Hapus \"$category\"?';
  }

  @override
  String storage_settings_clear_category_body(String size) {
    return 'Sekitar $size akan dibebaskan. Tindakan ini tidak dapat dibatalkan.';
  }

  @override
  String get storage_auto_delete_title => 'Auto-Hapus cached Media';

  @override
  String get storage_auto_delete_personal => 'Personal Obrolan';

  @override
  String get storage_auto_delete_groups => 'Grup';

  @override
  String get storage_auto_delete_never => 'Tidak pernah';

  @override
  String get storage_auto_delete_3_days => '3 hari';

  @override
  String get storage_auto_delete_1_week => '1 minggu';

  @override
  String get storage_auto_delete_1_month => '1 bulan';

  @override
  String get storage_auto_delete_3_months => '3 bulan';

  @override
  String get storage_auto_delete_hint =>
      'Foto, Video dan Berkas Anda haven\'t opened during this period akan Dihapus from  Perangkat to Simpan space.';

  @override
  String storage_chat_detail_share(Object pct) {
    return 'This Obrolan uses $pct% dari Anda cache';
  }

  @override
  String get storage_chat_detail_media_tab => 'Media';

  @override
  String get storage_chat_detail_select_all => 'Pilih Semua';

  @override
  String get storage_chat_detail_deselect_all => 'Deselect Semua';

  @override
  String storage_chat_detail_clear_button(Object size) {
    return 'Hapus cache $size';
  }

  @override
  String get storage_chat_detail_clear_button_empty => 'Pilih Berkas to Hapus';

  @override
  String get storage_chat_detail_tab_empty => 'Tidak ada apa pun di tab ini.';

  @override
  String get storage_chat_detail_delete_title => 'Hapus Dipilih Berkas?';

  @override
  String storage_chat_detail_delete_body(Object count, Object size) {
    return '$count Berkas ($size) akan Dihapus from  Perangkat. Cloud copies stay intact.';
  }

  @override
  String get profile_delete_account => 'Hapus Akun';

  @override
  String get profile_delete_account_confirm_title =>
      'Hapus Anda Akun permanently?';

  @override
  String get profile_delete_account_confirm_body =>
      'Anda Akun akan Dihapus from Firebase Auth dan Semua Anda Firestore Dokumen akan Dihapus permanently. Anda Obrolan will remain visible to others in Dibaca-only mode.';

  @override
  String get profile_delete_account_confirm_action => 'Hapus Akun';

  @override
  String profile_delete_account_error(Object error) {
    return 'Couldn’t Hapus  Akun: $error';
  }

  @override
  String get chat_readonly_deleted_user =>
      'Akun Dihapus. This Obrolan adalah Dibaca-only.';

  @override
  String get blacklist_empty => 'Tidak Diblokir Pengguna';

  @override
  String get blacklist_action_unblock => 'Buka blokir';

  @override
  String get blacklist_unblock_confirm_title => 'Buka blokir?';

  @override
  String get blacklist_unblock_confirm_body =>
      'This Pengguna akan able to Pesan Anda again (if Kontak policy allows) dan see Anda Profil in Cari.';

  @override
  String get blacklist_unblock_success => 'Pengguna unblocked';

  @override
  String blacklist_unblock_error(Object error) {
    return 'Couldn’t Buka blokir: $error';
  }

  @override
  String get partner_profile_block_confirm_title => 'Blokir this Pengguna?';

  @override
  String get partner_profile_block_confirm_body =>
      'They won’t see a Obrolan with Anda, dapat’t find Anda in Cari, atau Tambah Anda to Kontak. Anda’ll disappear from their Kontak. Anda’ll keep  Obrolan history but dapat’t Pesan them while they’re Diblokir.';

  @override
  String get partner_profile_block_action => 'Blokir';

  @override
  String get partner_profile_block_success => 'Pengguna Diblokir';

  @override
  String partner_profile_block_error(Object error) {
    return 'Couldn’t Blokir: $error';
  }

  @override
  String get common_soon => 'Segera hadir';

  @override
  String common_theme_prefix(Object label) {
    return 'Tema: $label';
  }

  @override
  String common_error_cannot_save_theme(Object error) {
    return 'Couldn’t Simpan  Tema: $error';
  }

  @override
  String common_error_cannot_sign_out(Object error) {
    return 'Couldn’t Keluar: $error';
  }

  @override
  String account_error_profile(Object error) {
    return 'Profil Kesalahan: $error';
  }

  @override
  String get notifications_title => 'Notifikasi';

  @override
  String get notifications_section_main => 'Utama';

  @override
  String get notifications_mute_all_title => 'Turn off Semua';

  @override
  String get notifications_mute_all_subtitle => 'Nonaktifkan Semua Notifikasi.';

  @override
  String get notifications_sound_title => 'Suara';

  @override
  String get notifications_sound_subtitle => 'Main a sound for Baru Pesan.';

  @override
  String get notifications_preview_title => 'Pratinjau';

  @override
  String get notifications_preview_subtitle =>
      'Tampilkan Pesan text in Notifikasi.';

  @override
  String get notifications_section_quiet_hours => 'Quiet jam';

  @override
  String get notifications_quiet_hours_subtitle =>
      'Notifikasi won’t bother Anda during this time window.';

  @override
  String get notifications_quiet_hours_enable_title => 'Aktifkan quiet jam';

  @override
  String get notifications_reset_button => 'Atur ulang Pengaturan';

  @override
  String notifications_error_cannot_save(Object error) {
    return 'Couldn’t Simpan Pengaturan: $error';
  }

  @override
  String notifications_error_load(Object error) {
    return 'Couldn’t load Notifikasi: $error';
  }

  @override
  String get privacy_title => 'Obrolan Privasi';

  @override
  String privacy_error_cannot_save(Object error) {
    return 'Couldn’t Simpan Pengaturan: $error';
  }

  @override
  String privacy_error_load(Object error) {
    return 'Couldn’t load Privasi Pengaturan: $error';
  }

  @override
  String get privacy_e2ee_section => 'End‑to‑end Enkripsi';

  @override
  String get privacy_e2ee_enable_for_all_chats =>
      'Aktifkan E2EE for Semua Obrolan';

  @override
  String get privacy_e2ee_what_encrypt => 'What gets encrypted in E2EE Obrolan';

  @override
  String get privacy_e2ee_text => 'Pesan text';

  @override
  String get privacy_e2ee_media => 'Attachments (Media/Berkas)';

  @override
  String get privacy_my_devices_title => 'My Perangkat';

  @override
  String get privacy_my_devices_subtitle =>
      'Perangkat with published keys. Rename atau revoke access.';

  @override
  String get privacy_key_backup_title => 'Cadangan & key transfer';

  @override
  String get privacy_key_backup_subtitle =>
      'Buat a Kata sandi Cadangan atau transfer  key via QR.';

  @override
  String get privacy_visibility_section => 'Visibilitas';

  @override
  String get privacy_online_title => 'Daring Status';

  @override
  String get privacy_online_subtitle => 'Let others see when Anda’re Daring.';

  @override
  String get privacy_last_seen_title => 'Terakhir dilihat';

  @override
  String get privacy_last_seen_subtitle => 'Tampilkan Anda last Aktif time.';

  @override
  String get privacy_read_receipts_title => 'Dibaca receipts';

  @override
  String get privacy_read_receipts_subtitle =>
      'Let senders know Anda’ve Dibaca a Pesan.';

  @override
  String get privacy_group_invites_section => 'Grup invites';

  @override
  String get privacy_group_invites_subtitle =>
      'Who dapat Tambah Anda to Obrolan grup.';

  @override
  String get privacy_group_invites_everyone => 'Semua orang';

  @override
  String get privacy_group_invites_contacts => 'Kontak only';

  @override
  String get privacy_group_invites_nobody => 'Tidak ada';

  @override
  String get privacy_global_search_section => 'Kemampuan untuk ditemukan';

  @override
  String get privacy_global_search_subtitle =>
      'Who dapat find Anda by name among Semua Pengguna.';

  @override
  String get privacy_global_search_title => 'Global Cari';

  @override
  String get privacy_global_search_hint =>
      'If turned off, Anda won’t appear in “Semua Pengguna” when someone starts a Obrolan baru. Anda’ll still be visible to people who Ditambahkan Anda as a Kontak.';

  @override
  String get privacy_profile_for_others_section => 'Profil for others';

  @override
  String get privacy_profile_for_others_subtitle =>
      'What others dapat see in Anda Profil.';

  @override
  String get privacy_email_subtitle => 'Anda Email address in Anda Profil.';

  @override
  String get privacy_phone_title => 'Nomor telepon';

  @override
  String get privacy_phone_subtitle => 'Shown in Anda Profil dan Kontak.';

  @override
  String get privacy_birthdate_title => 'Date dari birth';

  @override
  String get privacy_birthdate_subtitle => 'Anda birthday field in Profil.';

  @override
  String get privacy_about_title => 'Tentang';

  @override
  String get privacy_about_subtitle => 'Anda Bio text in Profil.';

  @override
  String get privacy_reset_button => 'Atur ulang Pengaturan';

  @override
  String get common_cancel => 'Batal';

  @override
  String get common_create => 'Buat';

  @override
  String get common_delete => 'Hapus';

  @override
  String get common_choose => 'Pilih';

  @override
  String get common_save => 'Simpan';

  @override
  String get common_close => 'Tutup';

  @override
  String get common_nothing_found => 'Tidak ada yang ditemukan';

  @override
  String get common_retry => 'Coba lagi';

  @override
  String get auth_login_email_label => 'E-mail';

  @override
  String get auth_login_password_label => 'Kata sandi';

  @override
  String get auth_login_password_hint => 'Kata sandi';

  @override
  String get auth_login_sign_in => 'Masuk';

  @override
  String get auth_login_forgot_password => 'Lupa kata sandi?';

  @override
  String get auth_login_error_enter_email_for_reset =>
      'Masukkan Anda Email to Atur ulang Anda Kata sandi';

  @override
  String get profile_title => 'Profil';

  @override
  String get profile_edit_tooltip => 'Sunting';

  @override
  String get profile_full_name_label => 'Nama lengkap';

  @override
  String get profile_full_name_hint => 'Nama';

  @override
  String get profile_username_label => 'Nama pengguna';

  @override
  String get profile_email_label => 'E-mail';

  @override
  String get profile_phone_label => 'Telepon';

  @override
  String get profile_birthdate_label => 'Date dari birth';

  @override
  String get profile_about_label => 'Tentang';

  @override
  String get profile_about_hint => 'A short Bio';

  @override
  String get profile_password_toggle_show => 'Change Kata sandi';

  @override
  String get profile_password_toggle_hide => 'Sembunyikan Kata sandi change';

  @override
  String get profile_password_new_label => 'Baru Kata sandi';

  @override
  String get profile_password_confirm_label => 'Konfirmasi Kata sandi';

  @override
  String get profile_password_tooltip_show => 'Tampilkan Kata sandi';

  @override
  String get profile_password_tooltip_hide => 'Sembunyikan';

  @override
  String get profile_placeholder_username => 'Nama pengguna';

  @override
  String get profile_placeholder_email => 'nama@contoh.com';

  @override
  String get profile_placeholder_phone => '+7900 000-00-00';

  @override
  String get profile_placeholder_birthdate => 'DD.MM.YYYY';

  @override
  String get profile_placeholder_password_dots => '••••••••';

  @override
  String get profile_password_error_fill_both =>
      'Fill in  Baru Kata sandi dan confirmation.';

  @override
  String get settings_chats_title => 'Obrolan Pengaturan';

  @override
  String get settings_chats_preview => 'Pratinjau';

  @override
  String get settings_chats_outgoing => 'Outgoing Pesan';

  @override
  String get settings_chats_incoming => 'Incoming Pesan';

  @override
  String get settings_chats_font_size => 'Ukuran teks';

  @override
  String get settings_chats_font_small => 'Kecil';

  @override
  String get settings_chats_font_medium => 'Sedang';

  @override
  String get settings_chats_font_large => 'Besar';

  @override
  String get settings_chats_bubble_shape => 'Bentuk gelembung';

  @override
  String get settings_chats_bubble_rounded => 'Bulat';

  @override
  String get settings_chats_bubble_square => 'Persegi';

  @override
  String get settings_chats_chat_background => 'Obrolan Latar belakang';

  @override
  String get settings_chats_chat_background_pick_hint =>
      'Pilih a Foto atau fine‑tune  Latar belakang';

  @override
  String get settings_chats_advanced => 'Lanjutan';

  @override
  String get settings_chats_show_time => 'Tampilkan time';

  @override
  String get settings_chats_show_time_subtitle =>
      'Tampilkan Pesan time under bubbles';

  @override
  String get settings_chats_reset => 'Atur ulang Pengaturan';

  @override
  String settings_chats_error_cannot_save(Object error) {
    return 'Couldn’t Simpan: $error';
  }

  @override
  String settings_chats_error_wallpaper_load(Object error) {
    return 'Couldn’t load Latar belakang: $error';
  }

  @override
  String settings_chats_error_wallpaper_delete(Object error) {
    return 'Couldn’t Hapus Latar belakang: $error';
  }

  @override
  String get settings_chats_wallpaper_delete_confirm_title =>
      'Hapus Latar belakang?';

  @override
  String get settings_chats_wallpaper_delete_confirm_body =>
      'This Latar belakang akan Dihapus from Anda list.';

  @override
  String settings_chats_icon_picker_title(Object label) {
    return 'Ikon: “$label”';
  }

  @override
  String get settings_chats_icon_picker_search_hint => 'Cari by name…';

  @override
  String get settings_chats_icon_color => 'Icon Warna';

  @override
  String get settings_chats_reset_icon_size => 'Atur ulang size';

  @override
  String get settings_chats_reset_icon_stroke => 'Atur ulang stroke';

  @override
  String get settings_chats_tile_background => 'Tile Latar belakang';

  @override
  String get settings_chats_default_gradient => 'bawaan gradient';

  @override
  String get settings_chats_inherit_global => 'Use global Pengaturan';

  @override
  String get settings_chats_no_background => 'Tidak Latar belakang';

  @override
  String get settings_chats_no_background_on => 'Tidak Latar belakang (on)';

  @override
  String get chat_list_title => 'Obrolan';

  @override
  String get chat_list_search_hint => 'Cari…';

  @override
  String get chat_list_loading_connecting => 'Menghubungkan…';

  @override
  String get chat_list_loading_conversations => 'Memuat Percakapan…';

  @override
  String get chat_list_loading_list => 'Memuat Obrolan list…';

  @override
  String get chat_list_loading_sign_out => 'Keluar…';

  @override
  String get chat_list_empty_search_title => 'Tidak Obrolan found';

  @override
  String get chat_list_empty_search_body =>
      'Try a different query. Cari works by name dan Nama pengguna.';

  @override
  String get chat_list_empty_folder_title => 'This folder adalah Kosong';

  @override
  String get chat_list_empty_folder_body =>
      'Switch folders atau Mulai a Obrolan baru using  button above.';

  @override
  String get chat_list_empty_all_title => 'Tidak Obrolan yet';

  @override
  String get chat_list_empty_all_body =>
      'Mulai a Obrolan baru to begin messaging.';

  @override
  String get chat_list_action_new_folder => 'Baru folder';

  @override
  String get chat_list_action_new_chat => 'Obrolan baru';

  @override
  String get chat_list_action_create => 'Buat';

  @override
  String get chat_list_action_close => 'Tutup';

  @override
  String get chat_list_folders_title => 'Folder';

  @override
  String get chat_list_folders_subtitle => 'Pilih folders for this Obrolan.';

  @override
  String get chat_list_folders_empty => 'Tidak kustom folders yet.';

  @override
  String get chat_list_create_folder_title => 'Baru folder';

  @override
  String get chat_list_create_folder_subtitle =>
      'Buat a folder to quickly Saring Anda Obrolan.';

  @override
  String get chat_list_create_folder_name_label => 'NAMA FOLDER';

  @override
  String get chat_list_create_folder_name_hint => 'Nama folder';

  @override
  String chat_list_create_folder_chats_label(Object count) {
    return 'Obrolan ($count)';
  }

  @override
  String get chat_list_create_folder_select_all => 'Pilih Semua';

  @override
  String get chat_list_create_folder_reset => 'Atur ulang';

  @override
  String get chat_list_create_folder_search_hint => 'Cari by name…';

  @override
  String get chat_list_create_folder_no_matches => 'Tidak matching Obrolan';

  @override
  String get chat_list_folder_default_starred => 'Berbintang';

  @override
  String get chat_list_folder_default_all => 'Semua';

  @override
  String get chat_list_folder_default_new => 'Baru';

  @override
  String get chat_list_folder_default_direct => 'Langsung';

  @override
  String get chat_list_folder_default_groups => 'Grup';

  @override
  String get chat_list_yesterday => 'Kemarin';

  @override
  String get chat_list_folder_delete_action => 'Hapus';

  @override
  String get chat_list_folder_delete_title => 'Hapus folder?';

  @override
  String chat_list_folder_delete_body(Object name) {
    return 'Folder \"$name\" akan Dihapus. Obrolan will remain intact.';
  }

  @override
  String chat_list_error_open_starred(Object error) {
    return 'Couldn’t Buka Berbintang: $error';
  }

  @override
  String chat_list_error_delete_folder(Object error) {
    return 'Couldn’t Hapus folder: $error';
  }

  @override
  String get chat_list_pin_not_available =>
      'Penyematan tidak tersedia di folder ini.';

  @override
  String chat_list_pin_pinned_in_folder(Object name) {
    return 'Obrolan Disematkan in \"$name\"';
  }

  @override
  String chat_list_pin_unpinned_in_folder(Object name) {
    return 'Obrolan unpinned from \"$name\"';
  }

  @override
  String chat_list_error_toggle_pin(Object error) {
    return 'Couldn’t change Sematkan: $error';
  }

  @override
  String chat_list_error_update_folder(Object error) {
    return 'Couldn’t Perbarui folder: $error';
  }

  @override
  String get chat_list_clear_history_title => 'Hapus history?';

  @override
  String get chat_list_clear_history_body =>
      'Pesan will disappear only from Anda Obrolan view.  Lainnya participant will keep  history.';

  @override
  String get chat_list_clear_history_confirm => 'Hapus';

  @override
  String chat_list_error_clear_history(Object error) {
    return 'Couldn’t Hapus history: $error';
  }

  @override
  String chat_list_error_mark_read(Object error) {
    return 'Couldn’t mark Obrolan as Dibaca: $error';
  }

  @override
  String get chat_list_delete_chat_title => 'Hapus Obrolan?';

  @override
  String get chat_list_delete_chat_body =>
      ' Percakapan akan permanently Dihapus for Semua participants. This dapat’t be undone.';

  @override
  String get chat_list_delete_chat_confirm => 'Hapus';

  @override
  String chat_list_error_delete_chat(Object error) {
    return 'Couldn’t Hapus Obrolan: $error';
  }

  @override
  String get chat_list_context_folders => 'Folder';

  @override
  String get chat_list_context_unpin => 'Lepas sematan Obrolan';

  @override
  String get chat_list_context_pin => 'Sematkan Obrolan';

  @override
  String get chat_list_context_mark_all_read => 'Mark Semua as Dibaca';

  @override
  String get chat_list_context_clear_history => 'Hapus history';

  @override
  String get chat_list_context_delete_chat => 'Hapus Obrolan';

  @override
  String get chat_list_snackbar_history_cleared => 'Sejarah dihapus.';

  @override
  String get chat_list_snackbar_marked_read => 'Marked as Dibaca.';

  @override
  String chat_list_error_generic(Object error) {
    return 'Kesalahan: $error';
  }

  @override
  String get chat_calls_title => 'Panggilan';

  @override
  String get chat_calls_search_hint => 'Cari by name…';

  @override
  String get chat_calls_empty => 'Anda Panggilan history adalah Kosong.';

  @override
  String get chat_calls_nothing_found => 'Tidak ada yang ditemukan.';

  @override
  String chat_calls_error_load(Object error) {
    return 'Couldn’t load Panggilan:\n$error';
  }

  @override
  String get chat_reply_cancel_tooltip => 'Batal Balas';

  @override
  String get voice_preview_tooltip_cancel => 'Batal';

  @override
  String get voice_preview_tooltip_send => 'Kirim';

  @override
  String get profile_qr_title => 'My Kode QR';

  @override
  String get profile_qr_tooltip_close => 'Tutup';

  @override
  String get profile_qr_share_title => 'My LighChat Profil';

  @override
  String get profile_qr_share_subject => 'LighChat Profil';

  @override
  String chat_media_norm_pending_title(Object mediaKind) {
    return 'Memproses $mediaKind…';
  }

  @override
  String chat_media_norm_failed_title(Object mediaKind) {
    return 'Tidak dapat memproses $mediaKind';
  }

  @override
  String get chat_media_norm_pending_subtitle =>
      ' Berkas akan available after server processing.';

  @override
  String get chat_media_norm_failed_subtitle => 'Coba mulai memproses lagi.';

  @override
  String get conversation_threads_title => 'benang';

  @override
  String get conversation_threads_empty => 'Tidak threads yet';

  @override
  String get conversation_threads_root_attachment => 'Lampiran';

  @override
  String get conversation_threads_root_message => 'Pesan';

  @override
  String conversation_threads_snippet_you(Object text) {
    return 'Anda: $text';
  }

  @override
  String get conversation_threads_day_today => 'Hari ini';

  @override
  String get conversation_threads_day_yesterday => 'Kemarin';

  @override
  String conversation_threads_replies_badge(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count replies',
      one: '$count Balas',
    );
    return '$_temp0';
  }

  @override
  String get chat_meetings_title => 'Rapat';

  @override
  String get chat_meetings_subtitle =>
      'Buat conferences dan manage participant access';

  @override
  String get chat_meetings_section_new => 'Baru Pertemuan';

  @override
  String get chat_meetings_field_title_label => 'Pertemuan title';

  @override
  String get chat_meetings_field_title_hint =>
      'Misalnya, sinkronisasi logistik';

  @override
  String get chat_meetings_field_duration_label => 'Lamanya';

  @override
  String get chat_meetings_duration_unlimited => 'Tidak limit';

  @override
  String get chat_meetings_duration_15m => '15 menit';

  @override
  String get chat_meetings_duration_30m => '30 menit';

  @override
  String get chat_meetings_duration_1h => '1 jam';

  @override
  String get chat_meetings_duration_90m => '1.5 jam';

  @override
  String get chat_meetings_field_access_label => 'Mengakses';

  @override
  String get chat_meetings_access_private => 'Pribadi';

  @override
  String get chat_meetings_access_public => 'Publik';

  @override
  String get chat_meetings_waiting_room_title => 'Ruang tunggu';

  @override
  String get chat_meetings_waiting_room_desc =>
      'In waiting room mode, Anda control who joins. Until Anda tap “Admit”, guests will stay on  waiting screen.';

  @override
  String get chat_meetings_backgrounds_title => 'Latar belakang maya';

  @override
  String get chat_meetings_backgrounds_desc =>
      'Unggah backgrounds dan blur Anda Latar belakang if Anda want. Pilih an Gambar from  Galeri atau Unggah Anda own backgrounds.';

  @override
  String get chat_meetings_create_button => 'Buat Pertemuan';

  @override
  String get chat_meetings_snackbar_enter_title => 'Masukkan a Pertemuan title';

  @override
  String get chat_meetings_snackbar_auth_required =>
      'Anda need to be signed in to Buat a Pertemuan';

  @override
  String chat_meetings_error_create_failed(Object error) {
    return 'Couldn’t Buat Pertemuan: $error';
  }

  @override
  String get chat_meetings_history_title => 'Anda history';

  @override
  String get chat_meetings_history_empty => 'Pertemuan history adalah Kosong';

  @override
  String chat_meetings_history_error(Object error) {
    return 'Couldn’t load Pertemuan history: $error';
  }

  @override
  String get chat_meetings_status_live => 'hidup';

  @override
  String get chat_meetings_status_finished => 'selesai';

  @override
  String get chat_meetings_badge_private => 'pribadi';

  @override
  String get chat_contacts_search_hint => 'Cari Kontak…';

  @override
  String get chat_contacts_permission_denied =>
      'Kontak permission not granted.';

  @override
  String chat_contacts_sync_error(Object error) {
    return 'Couldn’t sync Kontak: $error';
  }

  @override
  String chat_contacts_invite_prepare_failed(Object error) {
    return 'Couldn’t prepare Undang: $error';
  }

  @override
  String get chat_contacts_matches_not_found => 'Tidak matches found.';

  @override
  String chat_contacts_added_count(Object count) {
    return 'Kontak Ditambahkan: $count.';
  }

  @override
  String get chat_contacts_invite_text =>
      'Install LighChat: https://lighchat.Daring\nI’m inviting Anda to LighChat — here’s  install Tautan.';

  @override
  String get chat_contacts_invite_subject => 'Undang to LighChat';

  @override
  String chat_contacts_error_load(Object error) {
    return 'Couldn’t load Kontak: $error';
  }

  @override
  String chat_list_item_draft_line(Object line) {
    return 'Draf · $line';
  }

  @override
  String get chat_list_item_chat_created => 'Obrolan Dibuat';

  @override
  String get chat_list_item_no_messages_yet => 'Tidak Pesan yet';

  @override
  String get chat_list_item_history_cleared => 'Sejarah dihapus';

  @override
  String get chat_list_firebase_not_configured =>
      'Firebase belum dikonfigurasi.';

  @override
  String get new_chat_title => 'Obrolan baru';

  @override
  String get new_chat_subtitle =>
      'Pilih someone to Mulai a Percakapan, atau Buat a Grup.';

  @override
  String get new_chat_search_hint => 'Name, Nama pengguna, atau @handle…';

  @override
  String get new_chat_create_group => 'Buat a Grup';

  @override
  String get new_chat_section_phone_contacts => 'PHONE Kontak';

  @override
  String get new_chat_section_contacts => 'Kontak';

  @override
  String get new_chat_section_all_users => 'Semua Pengguna';

  @override
  String get new_chat_empty_no_users =>
      'Tidak one to Mulai a Obrolan with yet.';

  @override
  String get new_chat_empty_not_found => 'Tidak matches found.';

  @override
  String new_chat_error_contacts(Object error) {
    return 'Kontak: $error';
  }

  @override
  String get new_chat_fallback_user_display_name => 'Pengguna';

  @override
  String get new_group_role_badge_admin => 'Admin';

  @override
  String get new_group_role_badge_worker => 'Anggota';

  @override
  String new_group_error_auth_session(Object error) {
    return 'Tidak dapat memverifikasi login: $error';
  }

  @override
  String get invite_subject => 'Gabung me on LighChat';

  @override
  String get invite_text =>
      'Install LighChat: https://lighchat.Daring\\nI’m inviting Anda to LighChat — here’s  install Tautan.';

  @override
  String get new_group_title => 'Buat a Grup';

  @override
  String get new_group_search_hint => 'Cari Pengguna…';

  @override
  String get new_group_pick_photo_tooltip =>
      'Tap to Pilih a Grup Foto. Long‑press to Hapus it.';

  @override
  String get new_group_name_label => 'Nama grup';

  @override
  String get new_group_name_hint => 'Nama';

  @override
  String get new_group_description_label => 'Deskripsi';

  @override
  String get new_group_description_hint => 'Opsional';

  @override
  String new_group_members_count(Object count) {
    return 'Anggota ($count)';
  }

  @override
  String get new_group_add_members_section => 'Tambah anggota';

  @override
  String get new_group_empty_no_users => 'Tidak one to Tambah yet.';

  @override
  String get new_group_empty_not_found => 'Tidak matches found.';

  @override
  String get new_group_error_name_required => 'Silakan Masukkan a Nama grup.';

  @override
  String get new_group_error_members_required => 'Tambah at least one Anggota.';

  @override
  String get new_group_action_create => 'Buat';

  @override
  String get group_members_title => 'Anggota';

  @override
  String get group_members_invite_link => 'Undang via Tautan';

  @override
  String get group_members_admin_badge => 'Admin';

  @override
  String group_members_invite_text(Object groupName, Object inviteLink) {
    return 'Gabung  Grup $groupName on LighChat: $inviteLink';
  }

  @override
  String get group_members_error_min_admin =>
      'At least one Administrator must remain in  Grup.';

  @override
  String get group_members_error_cannot_remove_creator =>
      'Anda dapat\'t Hapus Admin rights from  Grup creator.';

  @override
  String get group_members_remove_admin => 'Admin rights Dihapus';

  @override
  String get group_members_make_admin => 'Pengguna promoted to Admin';

  @override
  String get auth_brand_tagline => 'Utusan yang lebih aman';

  @override
  String get auth_firebase_not_ready =>
      'Firebase isn’t ready. Check `firebase_options.dart` dan GoogleService-Info.plist.';

  @override
  String get auth_redirecting_to_chats => 'Taking Anda to Obrolan…';

  @override
  String get auth_or => 'atau';

  @override
  String get auth_create_account => 'Buat Akun';

  @override
  String get auth_entry_sign_in => 'Masuk';

  @override
  String get auth_entry_sign_up => 'Buat Akun';

  @override
  String get auth_qr_title => 'Masuk with QR';

  @override
  String get auth_qr_hint =>
      'Buka LighChat on a Perangkat where Anda adalah already signed in → Pengaturan → Perangkat → Connect Baru Perangkat, then Pindai this code.';

  @override
  String auth_qr_refresh_in(int seconds) {
    return 'Disegarkan dalam ${seconds}dtk';
  }

  @override
  String get auth_qr_other_method => 'Masuk another way';

  @override
  String get auth_qr_approving => 'Masuk…';

  @override
  String get auth_qr_rejected => 'Permintaan ditolak';

  @override
  String get auth_qr_retry => 'Coba lagi';

  @override
  String get auth_qr_unknown_error => 'Could not generate  Kode QR.';

  @override
  String get auth_qr_use_qr_login => 'Masuk with QR';

  @override
  String get auth_privacy_policy => 'Kebijakan privasi';

  @override
  String get auth_error_open_privacy_policy =>
      'Couldn’t Buka  Kebijakan privasi';

  @override
  String get voice_transcript_show => 'Tampilkan text';

  @override
  String get voice_transcript_hide => 'Sembunyikan text';

  @override
  String get voice_transcript_copy => 'Salin';

  @override
  String get voice_transcript_loading => 'Mentranskripsikan…';

  @override
  String get voice_transcript_failed => 'Couldn’t get  text.';

  @override
  String get voice_attachment_media_kind_audio => 'Audio';

  @override
  String get voice_attachment_load_failed => 'Tidak dapat memuat';

  @override
  String get voice_attachment_title_voice_message => 'Pesan suara';

  @override
  String voice_transcript_error(Object error) {
    return 'Tidak dapat menyalin: $error';
  }

  @override
  String get voice_transcript_permission_denied =>
      'Pengenalan suara tidak diizinkan. Aktifkan di pengaturan sistem.';

  @override
  String get voice_transcript_unsupported_lang =>
      'Bahasa ini tidak didukung untuk transkripsi di perangkat.';

  @override
  String get voice_transcript_no_model =>
      'Pasang paket bahasa pengenalan suara offline di pengaturan sistem.';

  @override
  String get voice_translate_action => 'Terjemahkan';

  @override
  String get voice_translate_show_original => 'Asli';

  @override
  String get voice_translate_in_progress => 'Menerjemahkan…';

  @override
  String get voice_translate_downloading_model => 'Mengunduh model…';

  @override
  String get voice_translate_unsupported =>
      'Terjemahan tidak tersedia untuk pasangan bahasa ini.';

  @override
  String voice_translate_failed(Object error) {
    return 'Terjemahan gagal: $error';
  }

  @override
  String get chat_messages_title => 'Pesan';

  @override
  String get chat_call_decline => 'Tolak';

  @override
  String get chat_call_open => 'Buka';

  @override
  String get chat_call_accept => 'Terima';

  @override
  String video_call_error_init(Object error) {
    return 'Panggilan Video Kesalahan: $error';
  }

  @override
  String get video_call_ended => 'Panggilan ended';

  @override
  String get video_call_status_missed => 'Panggilan tak terjawab';

  @override
  String get video_call_status_cancelled => 'Panggilan cancelled';

  @override
  String get video_call_error_offer_not_ready =>
      'Offer isn’t ready yet. Coba lagi.';

  @override
  String get video_call_error_invalid_call_data => 'Invalid Panggilan Data';

  @override
  String video_call_error_accept_failed(Object error) {
    return 'Couldn’t Terima  Panggilan: $error';
  }

  @override
  String get video_call_incoming => 'Incoming Panggilan Video';

  @override
  String get video_call_connecting => 'Panggilan Video…';

  @override
  String get video_call_pip_tooltip => 'Gambar dalam gambar';

  @override
  String get video_call_mini_window_tooltip => 'jendela kecil';

  @override
  String get chat_delete_message_title_single => 'Hapus pesan?';

  @override
  String get chat_delete_message_title_multi => 'Hapus Pesan?';

  @override
  String get chat_delete_message_body_single =>
      'This Pesan akan hidden for semua orang.';

  @override
  String chat_delete_message_body_multi(Object count) {
    return 'Pesan to Hapus: $count';
  }

  @override
  String get chat_delete_file_title => 'Hapus Berkas?';

  @override
  String get chat_delete_file_body =>
      'Only this Berkas akan Dihapus from  Pesan.';

  @override
  String get forward_title => 'Teruskan';

  @override
  String get forward_empty_no_messages => 'Tidak Pesan to Teruskan';

  @override
  String get forward_error_not_authorized => 'Tidak masuk';

  @override
  String get forward_empty_no_recipients =>
      'Tidak Kontak atau Obrolan to Teruskan to';

  @override
  String get forward_search_hint => 'Cari Kontak…';

  @override
  String get forward_empty_no_available_recipients =>
      'Tidak available recipients.\nAnda dapat only Teruskan to Kontak dan Anda Aktif Obrolan.';

  @override
  String get forward_empty_not_found => 'Tidak ada yang ditemukan';

  @override
  String get forward_action_pick_recipients => 'Pilih recipients';

  @override
  String get forward_action_send => 'Kirim';

  @override
  String forward_error_generic(Object error) {
    return 'Kesalahan: $error';
  }

  @override
  String get forward_sender_fallback => 'Peserta';

  @override
  String get forward_error_profiles_load =>
      'Couldn’t load profiles to Buka Obrolan';

  @override
  String get forward_error_send_no_permissions =>
      'Couldn’t Teruskan: Anda don’t have access to one dari  Dipilih Obrolan atau  Obrolan adalah Tidak longer available.';

  @override
  String get forward_error_send_forbidden_chat =>
      'Couldn’t Teruskan: access to one dari  Obrolan adalah denied.';

  @override
  String get share_picker_title => 'Bagikan ke LighChat';

  @override
  String get share_picker_empty_payload => 'Tidak ada yang dibagikan';

  @override
  String get share_picker_summary_text_only => 'Teks';

  @override
  String share_picker_summary_files_count(int count) {
    return 'Berkas: $count';
  }

  @override
  String share_picker_summary_files_with_text(int count) {
    return 'Berkas: $count + teks';
  }

  @override
  String get devices_title => 'My Perangkat';

  @override
  String get devices_subtitle =>
      'Perangkat where Anda Enkripsi public key adalah published. Revoking creates a Baru key epoch for Semua encrypted Obrolan —  revoked Perangkat won’t be able to Dibaca Baru Pesan.';

  @override
  String get devices_empty => 'Tidak Perangkat yet.';

  @override
  String get devices_connect_new_device => 'Connect Baru Perangkat';

  @override
  String get devices_approve_title => 'Allow Perangkat ini to Masuk?';

  @override
  String get devices_approve_body_hint =>
      'Make sure this adalah Anda own Perangkat that just showed  Kode QR.';

  @override
  String get devices_approve_allow => 'Mengizinkan';

  @override
  String get devices_approve_deny => 'Membantah';

  @override
  String get devices_handover_progress_title => 'Syncing encrypted Obrolan…';

  @override
  String devices_handover_progress_body(int done, int total) {
    return 'Diperbarui $done dari $total';
  }

  @override
  String get devices_handover_progress_starting => 'Mulai…';

  @override
  String get devices_handover_success_title => 'Baru Perangkat linked';

  @override
  String devices_handover_success_body(String label) {
    return 'Perangkat $label Sekarang has access to Anda encrypted Obrolan.';
  }

  @override
  String devices_progress_rekeying(Object done, Object total) {
    return 'Updating Obrolan: $done / $total';
  }

  @override
  String get devices_chip_current => 'Perangkat ini';

  @override
  String get devices_chip_revoked => 'Dicabut';

  @override
  String devices_meta_created_activity(Object createdAt, Object lastSeenAt) {
    return 'Dibuat: $createdAt  •  Activity: $lastSeenAt';
  }

  @override
  String devices_meta_revoked_at(Object revokedAt) {
    return 'Dicabut: $revokedAt';
  }

  @override
  String get devices_action_rename => 'Ganti nama';

  @override
  String get devices_action_revoke => 'Menarik kembali';

  @override
  String get devices_dialog_rename_title => 'Rename Perangkat';

  @override
  String get devices_dialog_rename_hint => 'misalnya iPhone 15 — Safari';

  @override
  String devices_error_rename_failed(Object error) {
    return 'Tidak dapat mengganti nama: $error';
  }

  @override
  String get devices_dialog_revoke_title => 'Revoke Perangkat?';

  @override
  String get devices_dialog_revoke_body_current =>
      'Anda’re Tentang to revoke Perangkat ini. After that, Anda won’t be able to Dibaca Baru Pesan in end‑to‑end encrypted Obrolan from this client.';

  @override
  String get devices_dialog_revoke_body_other =>
      'Perangkat ini won’t be able to Dibaca Baru Pesan in end‑to‑end encrypted Obrolan. Old Pesan will remain available on it.';

  @override
  String devices_snackbar_revoked(Object rekeyed, Object suffix) {
    return 'Perangkat revoked. Obrolan Diperbarui: $rekeyed$suffix';
  }

  @override
  String devices_snackbar_failed_suffix(Object count) {
    return ', kesalahan: $count';
  }

  @override
  String devices_error_revoke_failed(Object error) {
    return 'Revoke Kesalahan: $error';
  }

  @override
  String get e2ee_recovery_title => 'E2EE — Cadangan';

  @override
  String get e2ee_password_label => 'Kata sandi';

  @override
  String get e2ee_password_confirm_label => 'Konfirmasi Kata sandi';

  @override
  String e2ee_password_min_length(Object count) {
    return 'Setidaknya $count karakter';
  }

  @override
  String get e2ee_password_mismatch => 'Kata sandi tidak cocok';

  @override
  String get e2ee_backup_create_title => 'Buat key Cadangan';

  @override
  String get e2ee_backup_restore_title => 'Pulihkan with Kata sandi';

  @override
  String get e2ee_backup_restore_action => 'Pulihkan';

  @override
  String e2ee_backup_create_error(Object error) {
    return 'Couldn’t Buat Cadangan: $error';
  }

  @override
  String e2ee_backup_restore_error(Object error) {
    return 'Couldn’t Pulihkan: $error';
  }

  @override
  String get e2ee_backup_wrong_password => 'Wrong Kata sandi';

  @override
  String get e2ee_backup_not_found => 'Cadangan Tidak ditemukan';

  @override
  String e2ee_recovery_error_generic(Object error) {
    return 'Kesalahan: $error';
  }

  @override
  String get e2ee_backup_password_card_title => 'Kata sandi Cadangan';

  @override
  String get e2ee_backup_password_card_description =>
      'Buat an encrypted Cadangan dari Anda private key. If Anda Kalah Semua Perangkat, Anda dapat Pulihkan it on a Baru one using only  Kata sandi.  Kata sandi dapat’t be recovered — store it safely.';

  @override
  String get e2ee_backup_overwrite => 'Overwrite Cadangan';

  @override
  String get e2ee_backup_create => 'Buat Cadangan';

  @override
  String get e2ee_backup_restore => 'Pulihkan from Cadangan';

  @override
  String get e2ee_backup_already_have => 'I already have a Cadangan';

  @override
  String get e2ee_qr_transfer_title => 'Transfer kunci melalui QR';

  @override
  String get e2ee_qr_transfer_description =>
      'On  Baru Perangkat Anda Tampilkan a QR, on  old one Anda Pindai it. Verify a 6‑digit code —  private key adalah transferred securely.';

  @override
  String get e2ee_qr_transfer_open => 'Buka QR pairing';

  @override
  String get media_viewer_action_reply => 'Balas';

  @override
  String get media_viewer_action_forward => 'Teruskan';

  @override
  String get media_viewer_action_send => 'Kirim';

  @override
  String get media_viewer_action_save => 'Simpan';

  @override
  String get media_viewer_action_show_in_chat => 'Tampilkan in Obrolan';

  @override
  String get media_viewer_action_delete => 'Hapus';

  @override
  String get media_viewer_error_no_gallery_access =>
      'Tidak permission to Simpan to Galeri';

  @override
  String get media_viewer_error_share_unavailable_web =>
      'Berbagi tidak tersedia di web';

  @override
  String get media_viewer_error_file_not_found => 'Berkas Tidak ditemukan';

  @override
  String get media_viewer_error_bad_media_url => 'Bad Media URL';

  @override
  String get media_viewer_error_bad_url => 'URL buruk';

  @override
  String get media_viewer_error_unsupported_media_scheme =>
      'Unsupported Media type';

  @override
  String media_viewer_error_http_status(Object status) {
    return 'Server Kesalahan (HTTP $status)';
  }

  @override
  String media_viewer_error_save_failed(Object error) {
    return 'Couldn’t Simpan: $error';
  }

  @override
  String media_viewer_error_send_failed(Object error) {
    return 'Couldn’t Kirim: $error';
  }

  @override
  String get media_viewer_video_playback_speed => 'Kecepatan pemutaran';

  @override
  String get media_viewer_video_quality => 'Kualitas';

  @override
  String get media_viewer_video_quality_auto => 'Mobil';

  @override
  String get media_viewer_error_quality_switch_failed =>
      'Tidak dapat mengubah kualitas';

  @override
  String get media_viewer_error_pip_open_failed => 'Couldn’t Buka PiP';

  @override
  String get media_viewer_pip_not_supported =>
      'Picture-in-picture isn’t supported on Perangkat ini.';

  @override
  String get media_viewer_video_processing =>
      'This Video adalah being processed on  server dan akan available soon.';

  @override
  String get media_viewer_video_playback_failed => 'Couldn’t Main  Video.';

  @override
  String get common_none => 'Tidak ada';

  @override
  String get group_member_role_admin => 'Administrator';

  @override
  String get group_member_role_worker => 'Anggota';

  @override
  String get profile_no_photo_to_view => 'Tidak Profil Foto to view.';

  @override
  String get profile_chat_id_copied_toast => 'Obrolan ID Disalin';

  @override
  String get auth_register_error_open_link => 'Couldn’t Buka  Tautan.';

  @override
  String get new_chat_error_self_profile_not_found =>
      'Anda Profil wasn’t found in  directory. Try signing out dan Kembali in.';

  @override
  String get disappearing_messages_title => 'Disappearing Pesan';

  @override
  String get disappearing_messages_intro =>
      'Baru Pesan adalah automatically Dihapus from  server after  Dipilih time (from  moment they’re Dikirim). Pesan already Dikirim adalah not changed.';

  @override
  String disappearing_messages_admin_only(Object summary) {
    return 'Only Grup admins dapat change this. Current: $summary.';
  }

  @override
  String get disappearing_messages_snackbar_off =>
      'Disappearing Pesan turned off.';

  @override
  String get disappearing_messages_snackbar_updated => 'Timer Diperbarui.';

  @override
  String get disappearing_preset_off => 'Mati';

  @override
  String get disappearing_preset_1h => '1 jam';

  @override
  String get disappearing_preset_24h => '24 jam';

  @override
  String get disappearing_preset_7d => '7 hari';

  @override
  String get disappearing_preset_30d => '30 hari';

  @override
  String get disappearing_ttl_summary_off => 'Mati';

  @override
  String disappearing_ttl_minutes(Object count) {
    return '$count mnt';
  }

  @override
  String disappearing_ttl_hours(Object count) {
    return '$count h';
  }

  @override
  String disappearing_ttl_days(Object count) {
    return '$count hari';
  }

  @override
  String disappearing_ttl_weeks(Object count) {
    return '$count minggu';
  }

  @override
  String get conversation_profile_e2ee_on => 'Pada';

  @override
  String get conversation_profile_e2ee_off => 'Mati';

  @override
  String get conversation_profile_e2ee_subtitle_on =>
      'Enkripsi ujung ke ujung adalah on. Tap for details.';

  @override
  String get conversation_profile_e2ee_subtitle_off =>
      'Enkripsi ujung ke ujung adalah off. Tap to Aktifkan.';

  @override
  String get partner_profile_title_fallback_group => 'Obrolan grup';

  @override
  String get partner_profile_title_fallback_saved => 'Disimpan Pesan';

  @override
  String get partner_profile_title_fallback_chat => 'Obrolan';

  @override
  String partner_profile_subtitle_group_member_count(Object count) {
    return '$count Anggota';
  }

  @override
  String get partner_profile_subtitle_saved_messages =>
      'Pesan dan notes for Anda only';

  @override
  String get partner_profile_error_cannot_contact_user =>
      'Anda dapat’t reach this Pengguna with  current Kontak Pengaturan.';

  @override
  String partner_profile_error_open_chat(Object error) {
    return 'Couldn’t Buka Obrolan: $error';
  }

  @override
  String get partner_profile_call_peer_fallback => 'Rekan';

  @override
  String get partner_profile_chat_not_created => ' Obrolan isn’t Dibuat yet';

  @override
  String get partner_profile_notifications_muted => 'Notifikasi Dibisukan';

  @override
  String get partner_profile_notifications_unmuted => 'Notifikasi unmuted';

  @override
  String get partner_profile_notifications_change_failed =>
      'Couldn’t Perbarui Notifikasi';

  @override
  String get partner_profile_removed_from_contacts => 'Dihapus from Kontak';

  @override
  String get partner_profile_remove_contact_failed =>
      'Couldn’t Hapus from Kontak';

  @override
  String get partner_profile_contact_sent => 'Kontak Dikirim';

  @override
  String get partner_profile_share_failed_copied =>
      'Sharing Gagal. Kontak text Disalin.';

  @override
  String get partner_profile_share_contact_header => 'Kontak on LighChat';

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
    return 'LighChat Kontak: $name';
  }

  @override
  String get partner_profile_tooltip_back => 'Kembali';

  @override
  String get partner_profile_tooltip_close => 'Tutup';

  @override
  String get partner_profile_edit_contact_short => 'Sunting';

  @override
  String get partner_profile_tooltip_copy_chat_id => 'Salin Obrolan ID';

  @override
  String get partner_profile_action_chats => 'Obrolan';

  @override
  String get partner_profile_action_voice_call => 'Panggilan';

  @override
  String get partner_profile_action_video => 'Video';

  @override
  String get partner_profile_action_share => 'Bagikan';

  @override
  String get partner_profile_action_notifications => 'Peringatan';

  @override
  String get partner_profile_menu_members => 'Anggota';

  @override
  String get partner_profile_menu_edit_group => 'Edit Grup';

  @override
  String get partner_profile_menu_media_links_files =>
      'Media, links, dan Berkas';

  @override
  String get partner_profile_menu_starred => 'Berbintang';

  @override
  String get partner_profile_menu_threads => 'benang';

  @override
  String get partner_profile_menu_games => 'Permainan';

  @override
  String get partner_profile_menu_block => 'Blokir';

  @override
  String get partner_profile_menu_unblock => 'Buka blokir';

  @override
  String get partner_profile_menu_notifications => 'Notifikasi';

  @override
  String get partner_profile_menu_chat_theme => 'Obrolan Tema';

  @override
  String get partner_profile_menu_advanced_privacy =>
      'lanjutan Obrolan Privasi';

  @override
  String get partner_profile_privacy_trailing_default => 'Bawaan';

  @override
  String get partner_profile_menu_encryption => 'Enkripsi';

  @override
  String get partner_profile_no_common_groups => 'Tidak SHARED Grup';

  @override
  String partner_profile_create_group_with(Object name) {
    return 'Buat a Grup with $name';
  }

  @override
  String get partner_profile_leave_group => 'Keluar Grup';

  @override
  String get partner_profile_contacts_and_data => 'Kontak Info';

  @override
  String get partner_profile_field_system_role => 'Sistem role';

  @override
  String get partner_profile_field_email => 'E-mail';

  @override
  String get partner_profile_field_phone => 'Telepon';

  @override
  String get partner_profile_field_birthday => 'Hari ulang tahun';

  @override
  String get partner_profile_field_bio => 'Tentang';

  @override
  String get partner_profile_add_to_contacts => 'Tambah to Kontak';

  @override
  String get partner_profile_remove_from_contacts => 'Hapus from Kontak';

  @override
  String get thread_search_hint => 'Cari in thread…';

  @override
  String get thread_search_tooltip_clear => 'Hapus';

  @override
  String get thread_search_tooltip_search => 'Cari';

  @override
  String thread_reply_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count replies',
      one: '$count Balas',
      zero: '$count replies',
    );
    return '$_temp0';
  }

  @override
  String get thread_message_not_found => 'Pesan Tidak ditemukan';

  @override
  String get thread_screen_title_fallback => 'Benang';

  @override
  String thread_load_replies_error(Object error) {
    return 'Thread Kesalahan: $error';
  }

  @override
  String get chat_message_empty_placeholder => 'Pesan';

  @override
  String get chat_sender_you => 'Anda';

  @override
  String get chat_clipboard_nothing_to_paste =>
      'Nothing to Tempel from  clipboard';

  @override
  String chat_clipboard_paste_failed(Object error) {
    return 'Couldn’t Tempel from clipboard: $error';
  }

  @override
  String chat_send_failed(Object error) {
    return 'Couldn’t Kirim: $error';
  }

  @override
  String chat_send_video_circle_failed(Object error) {
    return 'Couldn’t Kirim Video note: $error';
  }

  @override
  String get chat_service_unavailable => 'Layanan tidak tersedia';

  @override
  String get chat_repository_unavailable => 'Obrolan service unavailable';

  @override
  String get chat_still_loading => 'Obrolan adalah still Memuat';

  @override
  String get chat_no_participants => 'Tidak Obrolan participants';

  @override
  String get chat_location_ios_geolocator_missing =>
      'Lokasi isn’t linked in this iOS build. Run pod install in mobile/app/ios dan rebuild.';

  @override
  String get chat_location_services_disabled => 'Turn on Lokasi services';

  @override
  String get chat_location_permission_denied =>
      'Tidak permission to use Lokasi';

  @override
  String chat_location_send_failed(Object error) {
    return 'Couldn’t Kirim Lokasi: $error';
  }

  @override
  String get chat_poll_send_timeout => 'Poll wasn’t Dikirim: timed out';

  @override
  String chat_poll_send_firebase(Object details) {
    return 'Poll wasn’t Dikirim (Firestore): $details';
  }

  @override
  String chat_poll_send_known_error(Object details) {
    return 'Poll wasn’t Dikirim: $details';
  }

  @override
  String chat_poll_send_failed(Object error) {
    return 'Couldn’t Kirim poll: $error';
  }

  @override
  String chat_delete_action_failed(Object error) {
    return 'Couldn’t Hapus: $error';
  }

  @override
  String get chat_media_transcode_retry_started =>
      'Transcode Coba lagi started';

  @override
  String chat_media_transcode_retry_failed(Object error) {
    return 'Couldn’t Mulai transcode Coba lagi: $error';
  }

  @override
  String chat_parent_load_error(Object error) {
    return 'Kesalahan: $error';
  }

  @override
  String get chat_message_not_found_in_loaded_history =>
      'Pesan wasn’t found in  loaded history';

  @override
  String get chat_finish_editing_first =>
      'Selesaikan pengeditan terlebih dahulu';

  @override
  String chat_send_voice_failed(Object error) {
    return 'Couldn’t Kirim Pesan suara: $error';
  }

  @override
  String get chat_starred_removed => 'Dihapus from Berbintang';

  @override
  String get chat_starred_added => 'Ditambahkan to Berbintang';

  @override
  String chat_starred_toggle_failed(Object error) {
    return 'Couldn’t Perbarui Berbintang: $error';
  }

  @override
  String chat_reaction_toggle_failed(Object error) {
    return 'Couldn’t Tambah reaction: $error';
  }

  @override
  String chat_emoji_burst_sync_failed(Object error) {
    return 'Couldn’t sync Emoji effect: $error';
  }

  @override
  String get chat_pin_already_pinned => 'Pesan adalah already Disematkan';

  @override
  String chat_pin_limit_reached(int count) {
    return 'Disematkan Pesan limit ($count)';
  }

  @override
  String chat_pin_failed(Object error) {
    return 'Couldn’t Sematkan: $error';
  }

  @override
  String chat_unpin_failed(Object error) {
    return 'Couldn’t Lepas sematan: $error';
  }

  @override
  String get chat_text_copied => 'Text Disalin';

  @override
  String get chat_edit_attachments_not_allowed =>
      'Lampiran tidak tersedia saat mengedit';

  @override
  String get chat_edit_text_empty => 'Text dapat’t be Kosong';

  @override
  String chat_e2ee_unavailable(Object code) {
    return 'Enkripsi unavailable: $code';
  }

  @override
  String chat_save_failed(Object error) {
    return 'Couldn’t Simpan: $error';
  }

  @override
  String chat_load_messages_error(Object error) {
    return 'Couldn’t load Pesan: $error';
  }

  @override
  String chat_conversation_error(Object error) {
    return 'Percakapan Kesalahan: $error';
  }

  @override
  String chat_auth_error(Object error) {
    return 'Auth Kesalahan: $error';
  }

  @override
  String get chat_poll_label => 'Pemilihan';

  @override
  String get chat_location_label => 'Lokasi';

  @override
  String get chat_attachment_label => 'Lampiran';

  @override
  String chat_media_pick_failed(Object error) {
    return 'Couldn’t Pilih Media: $error';
  }

  @override
  String chat_file_pick_failed(Object error) {
    return 'Couldn’t Pilih Berkas: $error';
  }

  @override
  String get chat_call_ongoing_video => 'Panggilan Video in progress';

  @override
  String get chat_call_ongoing_audio => 'Panggilan Audio in progress';

  @override
  String get chat_call_incoming_video => 'Incoming Panggilan Video';

  @override
  String get chat_call_incoming_audio => 'Incoming Panggilan Audio';

  @override
  String get message_menu_action_reply => 'Balas';

  @override
  String get message_menu_action_thread => 'Benang';

  @override
  String get message_menu_action_copy => 'Salin';

  @override
  String get message_menu_action_translate => 'Terjemahkan';

  @override
  String get message_menu_action_show_original => 'Tampilkan asli';

  @override
  String get message_menu_action_edit => 'Sunting';

  @override
  String get message_menu_action_pin => 'Sematkan';

  @override
  String get message_menu_action_star_add => 'Tambah to Berbintang';

  @override
  String get message_menu_action_star_remove => 'Hapus from Berbintang';

  @override
  String get message_menu_action_create_sticker => 'Buat stiker';

  @override
  String get message_menu_action_save_to_my_stickers => 'Simpan ke stiker saya';

  @override
  String get message_menu_action_forward => 'Teruskan';

  @override
  String get message_menu_action_select => 'Pilih';

  @override
  String get message_menu_action_delete => 'Hapus';

  @override
  String get message_menu_initiator_deleted => 'Pesan Dihapus';

  @override
  String get message_menu_header_sent => 'Dikirim:';

  @override
  String get message_menu_header_read => 'Dibaca:';

  @override
  String get message_menu_header_expire_at => 'HILANG:';

  @override
  String get chat_header_search_hint => 'Cari Pesan…';

  @override
  String get chat_header_tooltip_threads => 'benang';

  @override
  String get chat_header_tooltip_search => 'Cari';

  @override
  String get chat_header_tooltip_video_call => 'Panggilan video';

  @override
  String get chat_header_tooltip_audio_call => 'Panggilan audio';

  @override
  String get conversation_games_title => 'Permainan';

  @override
  String get conversation_games_durak => 'Durak';

  @override
  String get conversation_games_durak_subtitle => 'Buat lobby';

  @override
  String get conversation_game_lobby_title => 'Lobi';

  @override
  String get conversation_game_lobby_not_found => 'Permainan Tidak ditemukan';

  @override
  String conversation_game_lobby_error(Object error) {
    return 'Kesalahan: $error';
  }

  @override
  String conversation_game_lobby_create_failed(Object error) {
    return 'Couldn’t Buat Permainan: $error';
  }

  @override
  String conversation_game_lobby_game_id(Object id) {
    return 'ID: $id';
  }

  @override
  String conversation_game_lobby_status(Object status) {
    return 'Status: $status';
  }

  @override
  String conversation_game_lobby_players(Object count, Object max) {
    return 'Pemain: $count/$max';
  }

  @override
  String get conversation_game_lobby_join => 'Gabung';

  @override
  String get conversation_game_lobby_start => 'Mulai';

  @override
  String conversation_game_lobby_join_failed(Object error) {
    return 'Couldn’t Gabung: $error';
  }

  @override
  String conversation_game_lobby_start_failed(Object error) {
    return 'Couldn’t Mulai  Permainan: $error';
  }

  @override
  String get conversation_game_send_test_move => 'Langkah uji';

  @override
  String conversation_game_move_failed(Object error) {
    return 'Pemindahan ditolak: $error';
  }

  @override
  String get conversation_durak_table_title => 'Meja';

  @override
  String get conversation_durak_hand_title => 'Tangan';

  @override
  String get conversation_durak_role_attacker => 'Menyerang';

  @override
  String get conversation_durak_role_defender => 'Membela';

  @override
  String get conversation_durak_role_thrower => 'Melempar ke dalam';

  @override
  String get conversation_durak_action_attack => 'Menyerang';

  @override
  String get conversation_durak_action_defend => 'Membela';

  @override
  String get conversation_durak_action_take => 'Mengambil';

  @override
  String get conversation_durak_action_beat => 'Mengalahkan';

  @override
  String get conversation_durak_action_transfer => 'Transfer';

  @override
  String get conversation_durak_action_pass => 'Lulus';

  @override
  String get conversation_durak_badge_taking => 'saya akan ambil';

  @override
  String get conversation_durak_game_finished_title => 'Permainan finished';

  @override
  String get conversation_durak_game_finished_no_loser =>
      'Tidak loser this time.';

  @override
  String conversation_durak_game_finished_loser(Object uid) {
    return 'Yang kalah: $uid';
  }

  @override
  String conversation_durak_game_finished_winners(Object uids) {
    return 'Pemenang: $uids';
  }

  @override
  String get conversation_durak_winner => 'Pemenang!';

  @override
  String get conversation_durak_play_again => 'Main again';

  @override
  String get conversation_durak_back_to_chat => 'Kembali to Obrolan';

  @override
  String get conversation_game_lobby_waiting_opponent => 'Waiting for Lawan…';

  @override
  String get conversation_durak_drop_zone => 'Drop card here to Main';

  @override
  String get durak_settings_mode => 'Mode';

  @override
  String get durak_mode_podkidnoy => 'Podkidnoy';

  @override
  String get durak_mode_perevodnoy => 'Perevodnoy';

  @override
  String get durak_settings_max_players => 'Pemain';

  @override
  String get durak_settings_deck => 'Dek';

  @override
  String get durak_deck_36 => '36 kartu';

  @override
  String get durak_deck_52 => '52 kartu';

  @override
  String get durak_settings_with_jokers => 'Pelawak';

  @override
  String get durak_settings_turn_timer => 'Putar pengatur waktu';

  @override
  String get durak_turn_timer_off => 'Mati';

  @override
  String get durak_settings_throw_in_policy => 'Who dapat throw in';

  @override
  String get durak_throw_in_policy_all => 'Semua players (except defender)';

  @override
  String get durak_throw_in_policy_neighbors => 'Hanya tetangga pembela';

  @override
  String get durak_settings_shuler => 'Modus Shuler';

  @override
  String get durak_settings_shuler_subtitle =>
      'Allows illegal moves unless someone Panggilan foul.';

  @override
  String get conversation_durak_action_foul => 'Busuk!';

  @override
  String get conversation_durak_action_resolve => 'Konfirmasi Beat';

  @override
  String get conversation_durak_foul_toast => 'Busuk! Penipu dihukum.';

  @override
  String get durak_phase_prefix => 'Fase';

  @override
  String get durak_phase_attack => 'Menyerang';

  @override
  String get durak_phase_defense => 'Pertahanan';

  @override
  String get durak_phase_throw_in => 'Lemparan ke dalam';

  @override
  String get durak_phase_resolution => 'Resolusi';

  @override
  String get durak_phase_finished => 'Selesai';

  @override
  String get durak_phase_pending_foul => 'Menunggu pelanggaran setelah Beat';

  @override
  String get durak_phase_pending_foul_hint_attacker =>
      'Wait for foul. If tidak ada Panggilan it, Konfirmasi Beat.';

  @override
  String get durak_phase_pending_foul_hint_other =>
      'Wait for foul. Panggilan Foul! if Anda spotted cheating.';

  @override
  String get durak_phase_hint_can_throw_in => 'Anda dapat throw in';

  @override
  String get durak_phase_hint_wait => 'Wait for Giliran Anda';

  @override
  String durak_now_throwing_in(Object name) {
    return 'Sekarang throwing in: $name';
  }

  @override
  String chat_selection_selected_count(int count) {
    return '$count dipilih';
  }

  @override
  String get chat_selection_tooltip_forward => 'Teruskan';

  @override
  String get chat_selection_tooltip_delete => 'Hapus';

  @override
  String get chat_composer_hint_message => 'Ketik pesan…';

  @override
  String get chat_composer_tooltip_stickers => 'Stiker';

  @override
  String get chat_composer_tooltip_attachments => 'Lampiran';

  @override
  String get chat_list_unread_separator => 'Belum dibaca Pesan';

  @override
  String get chat_e2ee_decrypt_failed_open_devices =>
      'Couldn’t decrypt. Buka Pengaturan → Perangkat';

  @override
  String get chat_e2ee_encrypted_message_placeholder => 'Encrypted Pesan';

  @override
  String chat_forwarded_from(Object name) {
    return 'Diteruskan dari $name';
  }

  @override
  String get chat_outbox_retry => 'Coba lagi';

  @override
  String get chat_outbox_remove => 'Hapus';

  @override
  String get chat_outbox_cancel => 'Batal';

  @override
  String get chat_message_edited_badge_short => 'DIEDIT';

  @override
  String get register_error_enter_name => 'Masukkan Anda name.';

  @override
  String get register_error_enter_username => 'Masukkan a Nama pengguna.';

  @override
  String get register_error_enter_phone => 'Masukkan a Nomor telepon.';

  @override
  String get register_error_invalid_phone => 'Masukkan a valid Nomor telepon.';

  @override
  String get register_error_enter_email => 'Masukkan an Email.';

  @override
  String get register_error_enter_password => 'Masukkan a Kata sandi.';

  @override
  String get register_error_repeat_password => 'Repeat  Kata sandi.';

  @override
  String get register_error_dob_format =>
      'Masukkan date dari birth in dd.mm.yyyy format';

  @override
  String get register_error_accept_privacy_policy =>
      'Silakan Konfirmasi Anda Terima  Kebijakan privasi';

  @override
  String get register_privacy_required =>
      'Kebijakan privasi acceptance adalah wajib';

  @override
  String get register_label_name => 'Nama';

  @override
  String get register_hint_name => 'Masukkan Anda name';

  @override
  String get register_label_username => 'Nama pengguna';

  @override
  String get register_hint_username => 'Masukkan a Nama pengguna';

  @override
  String get register_label_phone => 'Telepon';

  @override
  String get register_hint_choose_country => 'Pilih a country';

  @override
  String get register_label_email => 'E-mail';

  @override
  String get register_hint_email => 'Masukkan Anda Email';

  @override
  String get register_label_password => 'Kata sandi';

  @override
  String get register_hint_password => 'Masukkan Anda Kata sandi';

  @override
  String get register_label_confirm_password => 'Konfirmasi Kata sandi';

  @override
  String get register_hint_confirm_password => 'Repeat Anda Kata sandi';

  @override
  String get register_label_dob => 'Date dari birth';

  @override
  String get register_hint_dob => 'hh.mm.yyyy';

  @override
  String get register_label_bio => 'Tentang';

  @override
  String get register_hint_bio => 'Tell us Tentang yourself…';

  @override
  String get register_privacy_prefix => 'I Terima ';

  @override
  String get register_privacy_link_text => 'Personal Data processing consent';

  @override
  String get register_privacy_and => ' dan ';

  @override
  String get register_terms_link_text => 'Kebijakan privasi Pengguna agreement';

  @override
  String get register_button_create_account => 'Buat Akun';

  @override
  String get register_country_search_hint => 'Cari by country atau code';

  @override
  String get register_date_picker_help => 'Date dari birth';

  @override
  String get register_date_picker_cancel => 'Batal';

  @override
  String get register_date_picker_confirm => 'Pilih';

  @override
  String get register_pick_avatar_title => 'Pilih avatar';

  @override
  String get edit_group_title => 'Edit Grup';

  @override
  String get edit_group_save => 'Simpan';

  @override
  String get edit_group_cancel => 'Batal';

  @override
  String get edit_group_name_label => 'Nama grup';

  @override
  String get edit_group_name_hint => 'Nama';

  @override
  String get edit_group_description_label => 'Deskripsi';

  @override
  String get edit_group_description_hint => 'Opsional';

  @override
  String get edit_group_pick_photo_tooltip =>
      'Tap to Pilih a Grup Foto. Long-press to Hapus it.';

  @override
  String get edit_group_error_name_required => 'Silakan Masukkan a Nama grup.';

  @override
  String get edit_group_error_save_failed => 'Gagal to Simpan Grup.';

  @override
  String get edit_group_error_not_found => 'Grup Tidak ditemukan.';

  @override
  String get edit_group_error_permission_denied =>
      'Anda don\'t have permission to Edit this Grup.';

  @override
  String get edit_group_success => 'Grup Diperbarui.';

  @override
  String get edit_group_privacy_section => 'Privasi';

  @override
  String get edit_group_privacy_forwarding => 'Pesan forwarding';

  @override
  String get edit_group_privacy_forwarding_desc =>
      'Allow Anggota to Teruskan Pesan from this Grup.';

  @override
  String get edit_group_privacy_screenshots => 'Tangkapan layar';

  @override
  String get edit_group_privacy_screenshots_desc =>
      'Allow screenshots in this Grup (platform-dependent).';

  @override
  String get edit_group_privacy_copy => 'Penyalinan teks';

  @override
  String get edit_group_privacy_copy_desc => 'Allow copying Pesan text.';

  @override
  String get edit_group_privacy_save_media => 'Simpan Media';

  @override
  String get edit_group_privacy_save_media_desc =>
      'Allow saving Foto dan Video to  Perangkat.';

  @override
  String get edit_group_privacy_share_media => 'Bagikan Media';

  @override
  String get edit_group_privacy_share_media_desc =>
      'Allow sharing Media Berkas outside  app.';

  @override
  String get schedule_message_sheet_title => 'Schedule Pesan';

  @override
  String get schedule_message_long_press_hint => 'Schedule Kirim';

  @override
  String schedule_message_preset_today_at(String time) {
    return 'Hari ini at $time';
  }

  @override
  String schedule_message_preset_tomorrow_at(String time) {
    return 'Besok at $time';
  }

  @override
  String schedule_message_will_send_at(String datetime) {
    return 'akan Dikirim: $datetime';
  }

  @override
  String get schedule_message_must_be_in_future =>
      'Time must be in  future (at least one menit from Sekarang).';

  @override
  String get schedule_message_e2ee_warning =>
      'This adalah an E2EE Obrolan.  scheduled Pesan akan stored on  server in plaintext dan published without Enkripsi.';

  @override
  String get schedule_message_cancel => 'Batal';

  @override
  String get schedule_message_confirm => 'Jadwal';

  @override
  String get schedule_message_save => 'Simpan';

  @override
  String get schedule_message_text_required => 'Ketik pesan first';

  @override
  String get schedule_message_attachments_unsupported_mobile =>
      'Scheduling attachments adalah currently supported only on web';

  @override
  String schedule_message_scheduled_toast(String datetime) {
    return 'Dijadwalkan: $datetime';
  }

  @override
  String schedule_message_failed_toast(String error) {
    return 'Gagal to schedule: $error';
  }

  @override
  String get scheduled_messages_screen_title => 'Scheduled Pesan';

  @override
  String get scheduled_messages_empty_title => 'Tidak scheduled Pesan';

  @override
  String get scheduled_messages_empty_hint =>
      'Hold  Kirim button to schedule a Pesan.';

  @override
  String scheduled_messages_load_failed(String error) {
    return 'Gagal to load: $error';
  }

  @override
  String get scheduled_messages_e2ee_notice =>
      'In an E2EE Obrolan, scheduled Pesan adalah stored dan published in plaintext.';

  @override
  String get scheduled_messages_cancel_dialog_title => 'Batal scheduled Kirim?';

  @override
  String get scheduled_messages_cancel_dialog_body =>
      ' scheduled Pesan akan Dihapus.';

  @override
  String get scheduled_messages_cancel_dialog_keep => 'Menyimpan';

  @override
  String get scheduled_messages_cancel_dialog_confirm => 'Batal';

  @override
  String get scheduled_messages_canceled_toast => 'Dibatalkan';

  @override
  String scheduled_messages_time_changed_toast(String datetime) {
    return 'Waktu berubah: $datetime';
  }

  @override
  String scheduled_messages_action_failed_toast(String error) {
    return 'Kesalahan: $error';
  }

  @override
  String get scheduled_messages_tile_edit_tooltip => 'Ubah waktu';

  @override
  String get scheduled_messages_tile_cancel_tooltip => 'Batal';

  @override
  String scheduled_messages_preview_poll(String question) {
    return 'Jajak pendapat: $question';
  }

  @override
  String get scheduled_messages_preview_location => 'Lokasi';

  @override
  String get scheduled_messages_preview_attachment => 'Lampiran';

  @override
  String scheduled_messages_preview_attachment_count(int count) {
    return 'Lampiran (×$count)';
  }

  @override
  String get scheduled_messages_preview_message => 'Pesan';

  @override
  String get chat_header_tooltip_scheduled => 'Scheduled Pesan';

  @override
  String get schedule_date_label => 'Tanggal';

  @override
  String get schedule_time_label => 'Waktu';

  @override
  String get common_done => 'Selesai';

  @override
  String get common_send => 'Kirim';

  @override
  String get common_open => 'Buka';

  @override
  String get common_add => 'Tambah';

  @override
  String get common_search => 'Cari';

  @override
  String get common_edit => 'Sunting';

  @override
  String get common_next => 'Berikutnya';

  @override
  String get common_ok => 'OKE';

  @override
  String get common_confirm => 'Konfirmasi';

  @override
  String get common_ready => 'Siap';

  @override
  String get common_error => 'Kesalahan';

  @override
  String get common_yes => 'Ya';

  @override
  String get common_no => 'Tidak';

  @override
  String get common_back => 'Kembali';

  @override
  String get common_continue => 'Lanjutkan';

  @override
  String get common_loading => 'Memuat…';

  @override
  String get common_copy => 'Salin';

  @override
  String get common_share => 'Bagikan';

  @override
  String get common_settings => 'Pengaturan';

  @override
  String get common_today => 'Hari ini';

  @override
  String get common_yesterday => 'Kemarin';

  @override
  String get e2ee_qr_title => 'pasangan kunci QR';

  @override
  String get e2ee_qr_uid_error => 'Gagal to get Pengguna uid.';

  @override
  String get e2ee_qr_session_ended_error =>
      'Session ended before  detik Perangkat responded.';

  @override
  String get e2ee_qr_no_data_error => 'Tidak ada Data to Terapkan  key.';

  @override
  String get e2ee_qr_key_transferred_toast =>
      'Key transferred. Re-Masukkan Obrolan to Segarkan sessions.';

  @override
  String get e2ee_qr_wrong_account_error =>
      'QR adalah generated for a different Akun.';

  @override
  String get e2ee_qr_explainer_title => 'What adalah this';

  @override
  String get e2ee_qr_explainer_text =>
      'Transfer a private key from one dari Anda Perangkat to another via ECDH + QR. Both sides see a 6-digit code for manual Verifikasi.';

  @override
  String get e2ee_qr_show_qr_label => 'I\'m on  Baru Perangkat — Tampilkan QR';

  @override
  String get e2ee_qr_scan_qr_label => 'I already have a key — Pindai QR';

  @override
  String get e2ee_qr_scan_hint =>
      'Pindai  QR on  old Perangkat that already has  key.';

  @override
  String get e2ee_qr_verify_code_label =>
      'Verify  6-digit code with  old Perangkat:';

  @override
  String e2ee_qr_transfer_from_device_label(String label) {
    return 'Transfer from Perangkat: $label';
  }

  @override
  String get e2ee_qr_code_match_apply_label => 'Code matches — Terapkan';

  @override
  String get e2ee_qr_key_success_label =>
      'Key successfully transferred to Perangkat ini. Re-Masukkan Obrolan.';

  @override
  String get e2ee_qr_unknown_error => 'Unknown Kesalahan';

  @override
  String get e2ee_qr_back_to_pick_label => 'Kembali to selection';

  @override
  String get e2ee_qr_donor_scan_hint =>
      'Point  Kamera at  QR shown on  Baru Perangkat.';

  @override
  String get e2ee_qr_donor_verify_code_label =>
      'Verify  code with  Baru Perangkat:';

  @override
  String get e2ee_qr_donor_verify_hint =>
      'If  code matches — Konfirmasi on  Baru Perangkat. If not, press Batal immediately.';

  @override
  String get e2ee_encrypt_title => 'Enkripsi';

  @override
  String get e2ee_encrypt_enable_dialog_title => 'Aktifkan Enkripsi?';

  @override
  String get e2ee_encrypt_enable_dialog_body =>
      'Baru Pesan will only be available on Anda Perangkat dan Anda Kontak\'s. Old Pesan will remain as they adalah.';

  @override
  String get e2ee_encrypt_enable_label => 'Aktifkan';

  @override
  String get e2ee_encrypt_disable_dialog_title => 'Nonaktifkan Enkripsi?';

  @override
  String get e2ee_encrypt_disable_dialog_body =>
      'Baru Pesan akan Dikirim without Enkripsi ujung ke ujung. Previously Dikirim encrypted Pesan will remain in  feed.';

  @override
  String get e2ee_encrypt_disable_label => 'Nonaktifkan';

  @override
  String get e2ee_encrypt_status_on =>
      'Enkripsi ujung ke ujung adalah enabled for this Obrolan.';

  @override
  String get e2ee_encrypt_status_off =>
      'Enkripsi ujung ke ujung adalah disabled.';

  @override
  String get e2ee_encrypt_description =>
      'When Enkripsi adalah enabled, Pesan baru content adalah only available to Obrolan participants on their Perangkat. Disabling only affects Baru Pesan.';

  @override
  String get e2ee_encrypt_switch_title => 'Aktifkan Enkripsi';

  @override
  String e2ee_encrypt_switch_on(int epoch) {
    return 'Diaktifkan (masa kunci: $epoch)';
  }

  @override
  String get e2ee_encrypt_switch_off => 'Dengan disabilitas';

  @override
  String get e2ee_encrypt_already_on_toast =>
      'Enkripsi adalah already enabled atau key creation Gagal. Check  Jaringan dan Anda Kontak\'s keys.';

  @override
  String get e2ee_encrypt_no_device_toast =>
      'Could not Aktifkan:  Kontak has Tidak Aktif Perangkat with a key.';

  @override
  String e2ee_encrypt_enable_failed_toast(String error) {
    return 'Gagal to Aktifkan Enkripsi: $error';
  }

  @override
  String e2ee_encrypt_disable_failed_toast(String error) {
    return 'Gagal to Nonaktifkan: $error';
  }

  @override
  String get e2ee_encrypt_data_types_title => 'Tipe data';

  @override
  String get e2ee_encrypt_data_types_description =>
      'This setting does not change  protocol. It controls which Data types adalah Dikirim encrypted.';

  @override
  String get e2ee_encrypt_override_title =>
      'Enkripsi Pengaturan for this Obrolan';

  @override
  String get e2ee_encrypt_override_on =>
      'Obrolan-level Pengaturan adalah used.';

  @override
  String get e2ee_encrypt_override_off => 'Global Pengaturan adalah inherited.';

  @override
  String get e2ee_encrypt_text_title => 'Pesan text';

  @override
  String get e2ee_encrypt_media_title => 'Attachments (Media/Berkas)';

  @override
  String get e2ee_encrypt_override_hint =>
      'To change for this Obrolan — Aktifkan  override.';

  @override
  String get sticker_default_pack_name => 'Paket saya';

  @override
  String get sticker_new_pack_dialog_title => 'Baru Stiker pack';

  @override
  String get sticker_pack_name_hint => 'Nama';

  @override
  String get sticker_save_to_pack => 'Simpan to Stiker pack';

  @override
  String get sticker_no_packs_hint => 'Tidak packs. Buat one on  Stiker tab.';

  @override
  String get sticker_new_pack_option => 'Baru pack…';

  @override
  String get sticker_pick_image_or_gif => 'Pilih an Gambar atau GIF';

  @override
  String sticker_send_failed(String error) {
    return 'Gagal to Kirim: $error';
  }

  @override
  String get sticker_saved_to_pack => 'Disimpan to Stiker pack';

  @override
  String get sticker_save_gif_failed => 'Could not Unduh atau Simpan GIF';

  @override
  String get sticker_delete_pack_title => 'Hapus pack?';

  @override
  String sticker_delete_pack_body(String name) {
    return '\"$name\" dan Semua Stiker inside akan Dihapus.';
  }

  @override
  String get sticker_pack_deleted => 'Pack Dihapus';

  @override
  String get sticker_pack_delete_failed => 'Gagal to Hapus pack';

  @override
  String get sticker_tab_emoji => 'Emoji';

  @override
  String get sticker_tab_stickers => 'Stiker';

  @override
  String get sticker_tab_gif => 'GIF';

  @override
  String get sticker_scope_my => '-ku';

  @override
  String get sticker_scope_public => 'Publik';

  @override
  String get sticker_new_pack_tooltip => 'Baru pack';

  @override
  String get sticker_pack_created => 'Stiker pack Dibuat';

  @override
  String get sticker_no_packs_create => 'Tidak Stiker packs. Buat one.';

  @override
  String get sticker_public_packs_empty => 'Tidak public packs configured';

  @override
  String get sticker_section_recent => 'TERKINI';

  @override
  String get sticker_pack_empty_hint =>
      'Pack adalah Kosong. Tambah from Perangkat (GIF tab — \"To my pack\").';

  @override
  String get sticker_delete_sticker_title => 'Hapus Stiker?';

  @override
  String get sticker_deleted => 'Dihapus';

  @override
  String get sticker_gallery => 'Galeri';

  @override
  String get sticker_gallery_subtitle =>
      'Foto, PNG, GIF from Perangkat — straight to Obrolan';

  @override
  String get gif_search_hint => 'Cari GIF…';

  @override
  String gif_translated_hint(String query) {
    return 'Ditelusuri: $query';
  }

  @override
  String get gif_search_unavailable =>
      'GIF Cari adalah temporarily unavailable.';

  @override
  String get gif_filter_all => 'Semua';

  @override
  String get sticker_section_animated => 'ANIMASI';

  @override
  String get sticker_emoji_unavailable =>
      'Emoji-to-text adalah not available for this window.';

  @override
  String get sticker_create_pack_hint => 'Buat a pack with  + button';

  @override
  String get sticker_public_packs_unavailable => 'Paket publik belum tersedia';

  @override
  String get composer_link_title => 'Tautan';

  @override
  String get composer_link_apply => 'Terapkan';

  @override
  String get composer_attach_title => 'Menempel';

  @override
  String get composer_attach_photo_video => 'Foto/Video';

  @override
  String get composer_attach_files => 'Berkas';

  @override
  String get composer_attach_video_circle => 'Lingkaran video';

  @override
  String get composer_attach_location => 'Lokasi';

  @override
  String get composer_attach_poll => 'Pemilihan';

  @override
  String get composer_attach_stickers => 'Stiker';

  @override
  String get composer_attach_clipboard => 'papan klip';

  @override
  String get composer_attach_text => 'Teks';

  @override
  String get meeting_create_poll => 'Buat poll';

  @override
  String get meeting_min_two_options => 'At least 2 Jawab options wajib';

  @override
  String meeting_error_with_details(String details) {
    return 'Kesalahan: $details';
  }

  @override
  String meeting_polls_load_error(String details) {
    return 'Gagal to load polls: $details';
  }

  @override
  String get meeting_no_polls_yet => 'Tidak polls yet';

  @override
  String get meeting_question_label => 'Pertanyaan';

  @override
  String get meeting_options_label => 'Pilihan';

  @override
  String meeting_option_hint(int index) {
    return 'Opsi $index';
  }

  @override
  String get meeting_add_option => 'Tambah option';

  @override
  String get meeting_anonymous => 'Anonim';

  @override
  String get meeting_anonymous_subtitle => 'Who dapat see others\' choices';

  @override
  String get meeting_save_as_draft => 'Simpan as draft';

  @override
  String get meeting_publish => 'Menerbitkan';

  @override
  String get meeting_action_start => 'Mulai';

  @override
  String get meeting_action_change_vote => 'Ubah suara';

  @override
  String get meeting_action_restart => 'Mulai ulang';

  @override
  String get meeting_action_stop => 'Berhenti';

  @override
  String meeting_vote_failed(String details) {
    return 'Suara tidak dihitung: $details';
  }

  @override
  String get meeting_status_ended => 'Berakhir';

  @override
  String get meeting_status_draft => 'Draf';

  @override
  String get meeting_status_active => 'Aktif';

  @override
  String get meeting_status_public => 'Publik';

  @override
  String meeting_votes_count(int count) {
    return '$count suara';
  }

  @override
  String meeting_goal_count(int count) {
    return 'Sasaran: $count';
  }

  @override
  String get meeting_hide => 'Sembunyikan';

  @override
  String get meeting_who_voted => 'Siapa yang memilih';

  @override
  String meeting_participants_tab(int count) {
    return 'Anggota ($count)';
  }

  @override
  String meeting_polls_tab_active(int count) {
    return 'Jajak Pendapat ($count)';
  }

  @override
  String get meeting_polls_tab => 'Jajak pendapat';

  @override
  String meeting_chat_tab_unread(int count) {
    return 'Obrolan ($count)';
  }

  @override
  String get meeting_chat_tab => 'Obrolan';

  @override
  String meeting_requests_tab(int count) {
    return 'Permintaan ($count)';
  }

  @override
  String meeting_you_suffix(String name) {
    return '$name (Anda)';
  }

  @override
  String get meeting_host_label => 'Tuan rumah';

  @override
  String get meeting_force_mute_mic => 'Bisukan Mikrofon';

  @override
  String get meeting_force_mute_camera => 'Turn off Kamera';

  @override
  String get meeting_kick_from_room => 'Hapus from room';

  @override
  String meeting_chat_load_error(Object error) {
    return 'Couldn\'t load Obrolan: $error';
  }

  @override
  String get meeting_no_requests => 'Tidak Baru requests';

  @override
  String get meeting_no_messages_yet => 'Tidak Pesan yet';

  @override
  String meeting_file_too_large(String name) {
    return 'Berkas too large: $name';
  }

  @override
  String meeting_send_failed(String details) {
    return 'Gagal to Kirim: $details';
  }

  @override
  String get meeting_edit_message_title => 'Edit pesan';

  @override
  String meeting_save_failed(String details) {
    return 'Gagal to Simpan: $details';
  }

  @override
  String get meeting_delete_message_title => 'Hapus pesan?';

  @override
  String get meeting_delete_message_body =>
      'Anggota will see \"Pesan Dihapus\".';

  @override
  String meeting_delete_failed(String details) {
    return 'Gagal to Hapus: $details';
  }

  @override
  String get meeting_message_hint => 'Pesan…';

  @override
  String get meeting_message_deleted => 'Pesan Dihapus';

  @override
  String get meeting_message_edited => '• diedit';

  @override
  String get meeting_copy_action => 'Salin';

  @override
  String get meeting_edit_action => 'Sunting';

  @override
  String get meeting_join_title => 'Gabung';

  @override
  String meeting_loading_error(String details) {
    return 'Kesalahan Memuat Pertemuan: $details';
  }

  @override
  String get meeting_not_found => 'Pertemuan Tidak ditemukan atau closed';

  @override
  String get meeting_private_description =>
      'Private Pertemuan:  host will decide whether to let Anda in after Anda request.';

  @override
  String get meeting_public_description =>
      'Buka Pertemuan: Gabung via Tautan without waiting.';

  @override
  String get meeting_your_name_label => 'Anda name';

  @override
  String get meeting_enter_name_error => 'Masukkan Anda name';

  @override
  String get meeting_guest_name => 'Tamu';

  @override
  String get meeting_enter_room => 'Masukkan room';

  @override
  String get meeting_request_join => 'Request to Gabung';

  @override
  String get meeting_approved_title => 'Disetujui';

  @override
  String get meeting_approved_subtitle => 'Mengarahkan ke kamar…';

  @override
  String get meeting_denied_title => 'Ditolak';

  @override
  String get meeting_denied_subtitle => ' host denied Anda request.';

  @override
  String get meeting_pending_title => 'Menunggu persetujuan';

  @override
  String get meeting_pending_subtitle =>
      ' host will see Anda request dan decide when to let Anda in.';

  @override
  String meeting_load_error(String details) {
    return 'Gagal to load Pertemuan: $details';
  }

  @override
  String meeting_init_error(Object error) {
    return 'Initialization Kesalahan: $error';
  }

  @override
  String meeting_participants_error(Object error) {
    return 'Anggota: $error';
  }

  @override
  String meeting_bg_unavailable(Object error) {
    return 'Latar belakang unavailable: $error';
  }

  @override
  String get meeting_leave => 'Keluar';

  @override
  String get meeting_screen_share_ios =>
      'Screen sharing on iOS requires Broadcast Extension (coming in  Berikutnya release)';

  @override
  String meeting_screen_share_failed(String details) {
    return 'Gagal to Mulai screen sharing: $details';
  }

  @override
  String get meeting_tooltip_speaker_mode => 'Pengeras suara mode';

  @override
  String get meeting_tooltip_grid_mode => 'Modus jaringan';

  @override
  String get meeting_tooltip_copy_link => 'Salin Tautan (browser Gabung)';

  @override
  String get meeting_mic_on => 'Bunyikan';

  @override
  String get meeting_mic_off => 'Bisukan';

  @override
  String get meeting_camera_on => 'Kamera on';

  @override
  String get meeting_camera_off => 'Kamera off';

  @override
  String get meeting_switch_camera => 'Mengalihkan';

  @override
  String get meeting_hand_lower => 'Lebih rendah';

  @override
  String get meeting_hand_raise => 'Tangan';

  @override
  String get meeting_reaction => 'Reaksi';

  @override
  String get meeting_screen_stop => 'Berhenti';

  @override
  String get meeting_screen_label => 'Layar';

  @override
  String get meeting_bg_off => 'BG';

  @override
  String get meeting_bg_blur => 'Mengaburkan';

  @override
  String get meeting_bg_image => 'Gambar';

  @override
  String get meeting_participants_button => 'Anggota';

  @override
  String get meeting_notifications_button => 'Aktivitas';

  @override
  String get meeting_pip_button => 'Minimalkan';

  @override
  String get settings_chats_bottom_nav_icons_title => 'Ikon navigasi bawah';

  @override
  String get settings_chats_bottom_nav_icons_subtitle =>
      'Pilih icons dan visual style Suka on  web.';

  @override
  String get settings_chats_nav_colorful => 'Berwarna-warni';

  @override
  String get settings_chats_nav_minimal => 'Minimal';

  @override
  String get settings_chats_nav_global_title => 'For Semua icons';

  @override
  String get settings_chats_nav_global_subtitle =>
      'Global layer: Warna, size, stroke width, dan tile Latar belakang.';

  @override
  String get settings_chats_reset_tooltip => 'Atur ulang';

  @override
  String get settings_chats_collapse => 'Ciutkan';

  @override
  String get settings_chats_customize => 'Sesuaikan';

  @override
  String get settings_chats_reset_item_tooltip => 'Atur ulang';

  @override
  String get settings_chats_style_tooltip => 'Gaya';

  @override
  String get settings_chats_icon_size => 'Ukuran ikon';

  @override
  String get settings_chats_stroke_width => 'Lebar goresan';

  @override
  String get settings_chats_default => 'Bawaan';

  @override
  String get settings_chats_icon_search_hint_en => 'Cari by name...';

  @override
  String get settings_chats_emoji_effects => 'Efek emoji';

  @override
  String get settings_chats_emoji_effects_subtitle =>
      'Animation Profil for fullscreen Emoji when tapping a single Emoji in Obrolan.';

  @override
  String get settings_chats_emoji_lite_desc =>
      'Lite: minimum load dan maksimum smoothness on low-end Perangkat.';

  @override
  String get settings_chats_emoji_balanced_desc =>
      'Balanced: automatic compromise between performance dan expressiveness.';

  @override
  String get settings_chats_emoji_cinematic_desc =>
      'Cinematic: maksimum particles dan depth for wow-effect.';

  @override
  String get settings_chats_preview_incoming_msg => 'Hey! How adalah Anda?';

  @override
  String get settings_chats_preview_outgoing_msg => 'Bagus, terima kasih!';

  @override
  String get settings_chats_preview_hello => 'Halo';

  @override
  String get chat_theme_title => 'Obrolan Tema';

  @override
  String chat_theme_error_save(String error) {
    return 'Gagal to Simpan Latar belakang: $error';
  }

  @override
  String chat_theme_error_upload(String error) {
    return 'Latar belakang Unggah Kesalahan: $error';
  }

  @override
  String get chat_theme_delete_title => 'Hapus Latar belakang from Galeri?';

  @override
  String get chat_theme_delete_body =>
      ' Gambar akan Dihapus from Anda backgrounds list. Anda dapat Pilih another one for this Obrolan.';

  @override
  String chat_theme_error_delete(String error) {
    return 'Hapus Kesalahan: $error';
  }

  @override
  String get chat_theme_banner =>
      ' Latar belakang dari this Obrolan adalah only for Anda. Global Obrolan Pengaturan in \"Obrolan Pengaturan\" remain unchanged.';

  @override
  String get chat_theme_current_bg => 'Current Latar belakang';

  @override
  String get chat_theme_default_global => 'bawaan (global Pengaturan)';

  @override
  String get chat_theme_presets => 'Preset';

  @override
  String get chat_theme_global_tile => 'Global';

  @override
  String get chat_theme_pick_hint => 'Pilih a preset atau Foto from Galeri';

  @override
  String get contacts_title => 'Kontak';

  @override
  String get contacts_add_phone_prompt =>
      'Tambah a Nomor telepon in Anda Profil to Cari Kontak by number.';

  @override
  String get contacts_fallback_profile => 'Profil';

  @override
  String get contacts_fallback_user => 'Pengguna';

  @override
  String get contacts_status_online => 'Daring';

  @override
  String get contacts_status_recently => 'Terakhir dilihat recently';

  @override
  String contacts_status_today_at(String time) {
    return 'Terakhir dilihat at $time';
  }

  @override
  String get contacts_status_yesterday => 'Terakhir dilihat Kemarin';

  @override
  String get contacts_status_year_ago => 'Terakhir dilihat a tahun yang lalu';

  @override
  String contacts_status_years_ago(String years) {
    return 'Terakhir dilihat $years yang lalu';
  }

  @override
  String contacts_status_date(String date) {
    return 'Terakhir dilihat $date';
  }

  @override
  String get contacts_empty_state =>
      'Tidak Kontak found.\nTap  button on  right to sync Anda phone book.';

  @override
  String get add_contact_title => 'Baru Kontak';

  @override
  String get add_contact_sync_off => 'Sync adalah off in  app.';

  @override
  String get add_contact_enable_system_access =>
      'Aktifkan Kontak access for LighChat in Sistem Pengaturan.';

  @override
  String get add_contact_sync_on => 'Sync adalah on';

  @override
  String get add_contact_sync_failed => 'Couldn\'t Aktifkan Kontak sync';

  @override
  String get add_contact_invalid_phone => 'Masukkan a valid Nomor telepon';

  @override
  String get add_contact_not_found_by_phone =>
      'Tidak Kontak found for this number';

  @override
  String get add_contact_found => 'Kontak found';

  @override
  String add_contact_search_error(String error) {
    return 'Cari Gagal: $error';
  }

  @override
  String get add_contact_qr_no_profile =>
      'Kode QR doesn\'t contain a LighChat Profil';

  @override
  String get add_contact_qr_own_profile => 'This adalah Anda own Profil';

  @override
  String get add_contact_qr_profile_not_found =>
      'Profil from Kode QR Tidak ditemukan';

  @override
  String get add_contact_qr_found => 'Kontak found via Kode QR';

  @override
  String add_contact_qr_read_error(String error) {
    return 'Couldn\'t Dibaca Kode QR: $error';
  }

  @override
  String get add_contact_cannot_add_user => 'tidak dapat Tambah this Pengguna';

  @override
  String add_contact_add_error(String error) {
    return 'Couldn\'t Tambah Kontak: $error';
  }

  @override
  String get add_contact_country_search_hint => 'Cari country atau code';

  @override
  String get add_contact_sync_with_phone => 'Sinkronkan dengan telepon';

  @override
  String get add_contact_add_by_qr => 'Tambah by Kode QR';

  @override
  String get add_contact_results_unavailable => 'Hasil belum tersedia';

  @override
  String add_contact_profile_load_error(String error) {
    return 'Couldn\'t load Kontak: $error';
  }

  @override
  String get add_contact_profile_not_found => 'Profil Tidak ditemukan';

  @override
  String get add_contact_badge_already_added => 'Already Ditambahkan';

  @override
  String get add_contact_badge_new => 'Baru Kontak';

  @override
  String get add_contact_badge_unavailable => 'Tidak tersedia';

  @override
  String get add_contact_open_contact => 'Buka Kontak';

  @override
  String get add_contact_add_to_contacts => 'Tambah to Kontak';

  @override
  String get add_contact_add_unavailable => 'Menambahkan tidak tersedia';

  @override
  String get add_contact_searching => 'Searching for Kontak...';

  @override
  String get add_contact_scan_qr_title => 'Pindai kode QR';

  @override
  String get add_contact_flash_tooltip => 'Kilatan';

  @override
  String get add_contact_scan_qr_hint =>
      'Point Anda Kamera at a LighChat Profil Kode QR';

  @override
  String get contacts_edit_enter_name => 'Masukkan  Kontak name.';

  @override
  String contacts_edit_save_error(String error) {
    return 'Couldn\'t Simpan Kontak: $error';
  }

  @override
  String get contacts_edit_first_name_hint => 'Nama depan';

  @override
  String get contacts_edit_last_name_hint => 'Nama belakang';

  @override
  String get contacts_edit_name_disclaimer =>
      'This name adalah visible only to Anda: in Obrolan, Cari, dan  Kontak list.';

  @override
  String contacts_edit_error(String error) {
    return 'Kesalahan: $error';
  }

  @override
  String get chat_settings_color_default => 'Bawaan';

  @override
  String get chat_settings_color_lilac => 'Ungu';

  @override
  String get chat_settings_color_pink => 'Berwarna merah muda';

  @override
  String get chat_settings_color_green => 'Hijau';

  @override
  String get chat_settings_color_coral => 'Karang';

  @override
  String get chat_settings_color_mint => 'daun mint';

  @override
  String get chat_settings_color_sky => 'Langit';

  @override
  String get chat_settings_color_purple => 'Ungu';

  @override
  String get chat_settings_color_crimson => 'Merah tua';

  @override
  String get chat_settings_color_tiffany => 'Tiffany';

  @override
  String get chat_settings_color_yellow => 'Kuning';

  @override
  String get chat_settings_color_powder => 'Bubuk';

  @override
  String get chat_settings_color_turquoise => 'Pirus';

  @override
  String get chat_settings_color_blue => 'Biru';

  @override
  String get chat_settings_color_sunset => 'Matahari terbenam';

  @override
  String get chat_settings_color_tender => 'Lembut';

  @override
  String get chat_settings_color_lime => 'Kapur';

  @override
  String get chat_settings_color_graphite => 'Grafit';

  @override
  String get chat_settings_color_no_bg => 'Tidak Latar belakang';

  @override
  String get chat_settings_icon_color => 'Icon Warna';

  @override
  String get chat_settings_icon_size => 'Ukuran ikon';

  @override
  String get chat_settings_stroke_width => 'Lebar goresan';

  @override
  String get chat_settings_tile_background => 'Tile Latar belakang';

  @override
  String get chat_settings_bottom_nav_icons => 'Ikon navigasi bawah';

  @override
  String get chat_settings_bottom_nav_description =>
      'Pilih icons dan visual style Suka on  web.';

  @override
  String get chat_settings_bottom_nav_global_description =>
      'Shared layer: Warna, size, stroke dan tile Latar belakang.';

  @override
  String get chat_settings_colorful => 'Berwarna-warni';

  @override
  String get chat_settings_minimalism => 'Minimal';

  @override
  String get chat_settings_for_all_icons => 'For Semua icons';

  @override
  String get chat_settings_customize => 'Sesuaikan';

  @override
  String get chat_settings_hide => 'Sembunyikan';

  @override
  String get chat_settings_reset => 'Atur ulang';

  @override
  String get chat_settings_reset_item => 'Atur ulang';

  @override
  String get chat_settings_style => 'Gaya';

  @override
  String get chat_settings_select => 'Pilih';

  @override
  String get chat_settings_reset_size => 'Atur ulang size';

  @override
  String get chat_settings_reset_stroke => 'Atur ulang stroke';

  @override
  String get chat_settings_default_gradient => 'bawaan gradient';

  @override
  String get chat_settings_inherit_global => 'Mewarisi dari global';

  @override
  String get chat_settings_no_bg_on => 'Tidak Latar belakang (on)';

  @override
  String get chat_settings_no_bg => 'Tidak Latar belakang';

  @override
  String get chat_settings_outgoing_messages => 'Outgoing Pesan';

  @override
  String get chat_settings_incoming_messages => 'Incoming Pesan';

  @override
  String get chat_settings_font_size => 'Ukuran font';

  @override
  String get chat_settings_font_small => 'Kecil';

  @override
  String get chat_settings_font_medium => 'Sedang';

  @override
  String get chat_settings_font_large => 'Besar';

  @override
  String get chat_settings_bubble_shape => 'Bentuk gelembung';

  @override
  String get chat_settings_bubble_rounded => 'Bulat';

  @override
  String get chat_settings_bubble_square => 'Persegi';

  @override
  String get chat_settings_chat_background => 'Obrolan Latar belakang';

  @override
  String get chat_settings_background_hint =>
      'Pilih a Foto from Galeri atau customize';

  @override
  String get chat_settings_builtin_wallpapers_heading => 'Wallpaper bermerek';

  @override
  String get chat_settings_emoji_effects => 'Efek emoji';

  @override
  String get chat_settings_emoji_description =>
      'Animation Profil for fullscreen Emoji burst on tap in Obrolan.';

  @override
  String get chat_settings_emoji_lite =>
      'Lite: minimal load, smoothest on low-end Perangkat.';

  @override
  String get chat_settings_emoji_cinematic =>
      'Cinematic: maksimum particles dan depth for a wow effect.';

  @override
  String get chat_settings_emoji_balanced =>
      'Balanced: automatic compromise between performance dan expressiveness.';

  @override
  String get chat_settings_additional => 'Tambahan';

  @override
  String get chat_settings_show_time => 'Tampilkan time';

  @override
  String get chat_settings_show_time_hint => 'Dikirim time under Pesan';

  @override
  String get chat_settings_reset_all => 'Atur ulang Pengaturan';

  @override
  String get chat_settings_preview_incoming => 'Hi! How adalah Anda?';

  @override
  String get chat_settings_preview_outgoing => 'Bagus, terima kasih!';

  @override
  String get chat_settings_preview_hello => 'Halo';

  @override
  String chat_settings_icon_picker_title(String label) {
    return 'Ikon: \"$label\"';
  }

  @override
  String get chat_settings_search_hint => 'Cari by name (eng.)...';

  @override
  String meeting_tab_participants(Object count) {
    return 'Anggota ($count)';
  }

  @override
  String get meeting_tab_polls => 'Jajak pendapat';

  @override
  String meeting_tab_polls_count(Object count) {
    return 'Jajak Pendapat ($count)';
  }

  @override
  String get meeting_tab_chat => 'Obrolan';

  @override
  String meeting_tab_chat_count(Object count) {
    return 'Obrolan ($count)';
  }

  @override
  String meeting_tab_requests(Object count) {
    return 'Permintaan ($count)';
  }

  @override
  String get meeting_kick => 'Hapus from room';

  @override
  String meeting_file_too_big(Object name) {
    return 'Berkas too big: $name';
  }

  @override
  String meeting_send_error(Object error) {
    return 'Couldn\'t Kirim: $error';
  }

  @override
  String meeting_save_error(Object error) {
    return 'Couldn\'t Simpan: $error';
  }

  @override
  String meeting_delete_error(Object error) {
    return 'Couldn\'t Hapus: $error';
  }

  @override
  String get meeting_no_messages => 'Tidak Pesan yet';

  @override
  String get meeting_join_enter_name => 'Masukkan Anda name';

  @override
  String get meeting_join_guest => 'Tamu';

  @override
  String get meeting_join_as_label => 'Anda akan bergabung sebagai';

  @override
  String get meeting_lobby_camera_blocked =>
      'Izin kamera ditolak. Anda akan bergabung dengan kamera mati.';

  @override
  String get meeting_join_button => 'Gabung';

  @override
  String meeting_join_load_error(Object error) {
    return 'Pertemuan load Kesalahan: $error';
  }

  @override
  String get meeting_private_hint =>
      'Private Pertemuan:  host will decide whether to let Anda in after Anda request.';

  @override
  String get meeting_public_hint =>
      'Buka Pertemuan: Gabung via Tautan without waiting.';

  @override
  String get meeting_name_label => 'Anda name';

  @override
  String get meeting_waiting_title => 'Menunggu persetujuan';

  @override
  String get meeting_waiting_subtitle =>
      ' host will see Anda request dan decide when to let Anda in.';

  @override
  String get meeting_screen_share_ios_hint =>
      'Berbagi layar di iOS memerlukan Ekstensi Siaran (dalam pengembangan).';

  @override
  String meeting_screen_share_error(Object error) {
    return 'Couldn\'t Mulai screen sharing: $error';
  }

  @override
  String get meeting_speaker_mode => 'Pengeras suara mode';

  @override
  String get meeting_grid_mode => 'Modus jaringan';

  @override
  String get meeting_copy_link_tooltip => 'Salin Tautan (browser entry)';

  @override
  String get group_members_subtitle_creator => 'Grup creator';

  @override
  String get group_members_subtitle_admin => 'Administrator';

  @override
  String get group_members_subtitle_member => 'Anggota';

  @override
  String group_members_total_count(int count) {
    return 'Jumlah: $count';
  }

  @override
  String get group_members_copy_invite_tooltip => 'Salin Tautan undangan';

  @override
  String get group_members_add_member_tooltip => 'Tambah Anggota';

  @override
  String get group_members_invite_copied => 'Tautan undangan Disalin';

  @override
  String group_members_copy_link_error(String error) {
    return 'Gagal to Salin Tautan: $error';
  }

  @override
  String get group_members_added => 'Anggota Ditambahkan';

  @override
  String get group_members_revoke_admin_title => 'Revoke Admin privileges?';

  @override
  String group_members_revoke_admin_body(String name) {
    return '$name will Kalah Admin privileges. They will remain in  Grup as a regular Anggota.';
  }

  @override
  String get group_members_grant_admin_title => 'Grant Admin privileges?';

  @override
  String group_members_grant_admin_body(String name) {
    return '$name will receive Admin privileges: dapat Edit  Grup, Hapus Anggota, dan manage Pesan.';
  }

  @override
  String get group_members_revoke_admin_action => 'Menarik kembali';

  @override
  String get group_members_grant_admin_action => 'Menganugerahkan';

  @override
  String get group_members_remove_title => 'Hapus anggota?';

  @override
  String group_members_remove_body(String name) {
    return '$name akan Dihapus from  Grup. Anda dapat Urungkan this by adding  Anggota again.';
  }

  @override
  String get group_members_remove_action => 'Hapus';

  @override
  String get group_members_removed => 'Anggota Dihapus';

  @override
  String get group_members_menu_revoke_admin => 'Hapus Admin';

  @override
  String get group_members_menu_grant_admin => 'Make Admin';

  @override
  String get group_members_menu_remove => 'Hapus from Grup';

  @override
  String get group_members_creator_badge => 'PENCIPTA';

  @override
  String get group_members_add_title => 'Tambah anggota';

  @override
  String get group_members_search_contacts => 'Cari Kontak';

  @override
  String get group_members_all_in_group =>
      'Semua Anda Kontak adalah already in  Grup.';

  @override
  String get group_members_nobody_found => 'tidak ada found.';

  @override
  String get group_members_user_fallback => 'Pengguna';

  @override
  String get group_members_select_members => 'Pilih Anggota';

  @override
  String group_members_add_count(int count) {
    return 'Tambah ($count)';
  }

  @override
  String group_members_contacts_load_error(String error) {
    return 'Gagal to load Kontak: $error';
  }

  @override
  String group_members_auth_error(String error) {
    return 'Authorization Kesalahan: $error';
  }

  @override
  String group_members_add_failed(String error) {
    return 'Gagal to Tambah anggota: $error';
  }

  @override
  String get group_not_found => 'Grup Tidak ditemukan.';

  @override
  String get group_not_member => 'Anda adalah not a Anggota dari this Grup.';

  @override
  String get poll_create_title => 'Obrolan poll';

  @override
  String get poll_question_label => 'Pertanyaan';

  @override
  String get poll_question_hint => 'Misalnya: Jam berapa kita akan bertemu?';

  @override
  String get poll_description_label => 'Deskripsi (opsional)';

  @override
  String get poll_options_title => 'Pilihan';

  @override
  String poll_option_hint(int index) {
    return 'Opsi $index';
  }

  @override
  String get poll_add_option => 'Tambah option';

  @override
  String get poll_switch_anonymous => 'Pemungutan suara anonim';

  @override
  String get poll_switch_anonymous_sub => 'Do not Tampilkan who voted for what';

  @override
  String get poll_switch_multi => 'Banyak jawaban';

  @override
  String get poll_switch_multi_sub => 'Multiple options dapat be Dipilih';

  @override
  String get poll_switch_add_options => 'Tambah options';

  @override
  String get poll_switch_add_options_sub =>
      'Participants dapat suggest their own options';

  @override
  String get poll_switch_revote => 'dapat change vote';

  @override
  String get poll_switch_revote_sub =>
      'Pemungutan suara ulang diperbolehkan sampai pemungutan suara ditutup';

  @override
  String get poll_switch_shuffle => 'Opsi acak';

  @override
  String get poll_switch_shuffle_sub => 'Urutan berbeda untuk setiap peserta';

  @override
  String get poll_switch_quiz => 'Modus kuis';

  @override
  String get poll_switch_quiz_sub => 'One correct Jawab';

  @override
  String get poll_correct_option_label => 'Pilihan yang benar';

  @override
  String get poll_quiz_explanation_label => 'Explanation (opsional)';

  @override
  String get poll_close_by_time => 'Tutup by time';

  @override
  String get poll_close_not_set => 'Tidak disetel';

  @override
  String get poll_close_reset => 'Atur ulang deadline';

  @override
  String get poll_publish => 'Menerbitkan';

  @override
  String get poll_error_empty_question => 'Masukkan a question';

  @override
  String get poll_error_min_options => 'At least 2 options adalah wajib';

  @override
  String get poll_error_select_correct => 'Pilih  correct option';

  @override
  String get poll_error_future_time => 'Closing time must be in  future';

  @override
  String get poll_unavailable => 'Jajak pendapat tidak tersedia';

  @override
  String get poll_loading => 'Memuat poll…';

  @override
  String get poll_not_found => 'Poll Tidak ditemukan';

  @override
  String get poll_status_cancelled => 'Dibatalkan';

  @override
  String get poll_status_ended => 'Berakhir';

  @override
  String get poll_status_draft => 'Draf';

  @override
  String get poll_status_active => 'Aktif';

  @override
  String get poll_badge_public => 'Publik';

  @override
  String get poll_badge_multi => 'Banyak jawaban';

  @override
  String get poll_badge_quiz => 'Kuis';

  @override
  String get poll_menu_restart => 'Mulai ulang';

  @override
  String get poll_menu_end => 'Akhir';

  @override
  String get poll_menu_delete => 'Hapus';

  @override
  String get poll_submit_vote => 'Kirim vote';

  @override
  String get poll_suggest_option_hint => 'Sarankan sebuah opsi';

  @override
  String get poll_revote => 'Ubah suara';

  @override
  String poll_votes_count(int count) {
    return '$count suara';
  }

  @override
  String get poll_show_voters => 'Siapa yang memilih';

  @override
  String get poll_hide_voters => 'Sembunyikan';

  @override
  String get poll_vote_error => 'Kesalahan while voting';

  @override
  String get poll_add_option_error => 'Gagal to Tambah option';

  @override
  String get poll_error_generic => 'Kesalahan';

  @override
  String get durak_your_turn => 'Giliran Anda';

  @override
  String get durak_winner_label => 'Pemenang';

  @override
  String get durak_rematch => 'Main again';

  @override
  String get durak_surrender_tooltip => 'End Permainan';

  @override
  String get durak_close_tooltip => 'Tutup';

  @override
  String get durak_fx_took => 'Telah mengambil';

  @override
  String get durak_fx_beat => 'Dipukuli';

  @override
  String get durak_opponent_role_defend => 'DEF';

  @override
  String get durak_opponent_role_attack => 'serangan';

  @override
  String get durak_opponent_role_throwin => 'THR';

  @override
  String get durak_foul_banner_title => 'Penipu! Dirindukan:';

  @override
  String get durak_pending_resolution_attacker =>
      'Waiting for foul check… Press \"Konfirmasi Beaten\" if semua orang agrees.';

  @override
  String get durak_pending_resolution_other =>
      'Waiting for foul check… Anda dapat press \"Foul!\" if Anda noticed cheating.';

  @override
  String durak_tournament_played(int finished, int total) {
    return 'Played $finished dari $total';
  }

  @override
  String get durak_tournament_finished => 'Turnamen selesai';

  @override
  String get durak_tournament_next => 'Berikutnya tournament Permainan';

  @override
  String get durak_single_game => 'Single Permainan';

  @override
  String get durak_tournament_total_games_title =>
      'How many Permainan in  tournament?';

  @override
  String get durak_finish_game_tooltip => 'End Permainan';

  @override
  String get durak_lobby_game_unavailable =>
      'Permainan adalah unavailable atau telah Dihapus';

  @override
  String get durak_lobby_back_tooltip => 'Kembali';

  @override
  String get durak_lobby_waiting => 'Waiting for Lawan…';

  @override
  String get durak_lobby_start => 'Mulai Permainan';

  @override
  String get durak_lobby_waiting_short => 'Menunggu…';

  @override
  String get durak_lobby_ready => 'Siap';

  @override
  String get durak_lobby_empty_slot => 'Menunggu…';

  @override
  String get durak_settings_timer_subtitle => '15 detik by bawaan';

  @override
  String get durak_dm_game_active => 'Durak Permainan in progress';

  @override
  String get durak_dm_game_created => 'Durak Permainan Dibuat';

  @override
  String get game_durak_subtitle => 'Single Permainan atau tournament';

  @override
  String get group_member_write_dm => 'Kirim direct Pesan';

  @override
  String get group_member_open_dm_hint => 'Buka direct Obrolan with Anggota';

  @override
  String get group_member_profile_not_loaded =>
      'Anggota Profil not loaded yet.';

  @override
  String group_member_open_dm_error(String error) {
    return 'Gagal to Buka direct Obrolan: $error';
  }

  @override
  String get group_avatar_photo_title => 'Grup Foto';

  @override
  String get group_avatar_add_photo => 'Tambah Foto';

  @override
  String get group_avatar_change => 'Ubah avatar';

  @override
  String get group_avatar_remove => 'Hapus avatar';

  @override
  String group_avatar_process_error(String error) {
    return 'Gagal to process Foto: $error';
  }

  @override
  String get group_mention_no_matches => 'Tidak matches';

  @override
  String get durak_error_defense_does_not_beat =>
      'This card does not beat  attacking card';

  @override
  String get durak_error_only_attacker_first => 'Penyerang pergi duluan';

  @override
  String get durak_error_defender_cannot_attack =>
      'Defender tidak dapat throw in right Sekarang';

  @override
  String get durak_error_not_allowed_throwin =>
      'Anda tidak dapat throw in this round';

  @override
  String get durak_error_throwin_not_your_turn =>
      'Another player adalah throwing in Sekarang';

  @override
  String get durak_error_rank_not_allowed =>
      'Anda dapat only throw in cards dari  same rank';

  @override
  String get durak_error_cannot_throw_in =>
      'tidak dapat throw in Lainnya cards';

  @override
  String get durak_error_card_not_in_hand =>
      'This card adalah Tidak longer in Anda hand';

  @override
  String get durak_error_already_defended =>
      'This card adalah already defended';

  @override
  String get durak_error_bad_attack_index =>
      'Pilih an attacking card to defend against';

  @override
  String get durak_error_only_defender =>
      'Another player adalah defending Sekarang';

  @override
  String get durak_error_defender_already_taking =>
      'Defender adalah already taking cards';

  @override
  String get durak_error_game_not_active =>
      'Permainan adalah Tidak longer Aktif';

  @override
  String get durak_error_not_in_lobby => 'Lobi sudah dimulai';

  @override
  String get durak_error_game_already_active => 'Permainan has already started';

  @override
  String get durak_error_active_game_exists =>
      'There adalah already an Aktif Permainan in this Obrolan';

  @override
  String get durak_error_resolution_pending => 'Finish  disputed move first';

  @override
  String get durak_error_rematch_failed =>
      'Gagal to prepare rematch. Silakan Coba lagi';

  @override
  String get durak_error_unauthenticated => 'Anda need to Masuk';

  @override
  String get durak_error_permission_denied =>
      'This action adalah not available to Anda';

  @override
  String get durak_error_invalid_argument => 'Langkah tidak valid';

  @override
  String get durak_error_failed_precondition =>
      'Move adalah not available right Sekarang';

  @override
  String get durak_error_server => 'Gagal to execute move. Silakan Coba lagi';

  @override
  String pinned_count(int count) {
    return 'Disematkan: $count';
  }

  @override
  String get pinned_single => 'Disematkan';

  @override
  String get pinned_unpin_tooltip => 'Lepas sematan';

  @override
  String get pinned_type_image => 'Gambar';

  @override
  String get pinned_type_video => 'Video';

  @override
  String get pinned_type_video_circle => 'Lingkaran video';

  @override
  String get pinned_type_voice => 'Pesan suara';

  @override
  String get pinned_type_poll => 'Pemilihan';

  @override
  String get pinned_type_link => 'Tautan';

  @override
  String get pinned_type_location => 'Lokasi';

  @override
  String get pinned_type_sticker => 'Stiker';

  @override
  String get pinned_type_file => 'Berkas';

  @override
  String get call_entry_login_required_title => 'Login wajib';

  @override
  String get call_entry_login_required_subtitle =>
      'Buka  app dan Masuk to Anda Akun.';

  @override
  String get call_entry_not_found_title => 'Panggilan Tidak ditemukan';

  @override
  String get call_entry_not_found_subtitle =>
      ' Panggilan has already ended atau been Dihapus. Returning to Panggilan…';

  @override
  String get call_entry_to_calls => 'To Panggilan';

  @override
  String get call_entry_ended_title => 'Panggilan ended';

  @override
  String get call_entry_ended_subtitle =>
      'This Panggilan adalah Tidak longer available. Returning to Panggilan…';

  @override
  String get call_entry_caller_fallback => 'Penelepon';

  @override
  String get call_entry_opening_title => 'Opening Panggilan…';

  @override
  String get call_entry_connecting_video => 'Connecting to Panggilan Video';

  @override
  String get call_entry_connecting_audio => 'Connecting to Panggilan Audio';

  @override
  String get call_entry_loading_subtitle => 'Memuat Panggilan Data';

  @override
  String get call_entry_error_title => 'Kesalahan opening Panggilan';

  @override
  String chat_theme_save_error(Object error) {
    return 'Gagal to Simpan Latar belakang: $error';
  }

  @override
  String chat_theme_load_error(Object error) {
    return 'Kesalahan Memuat Latar belakang: $error';
  }

  @override
  String chat_theme_delete_error(Object error) {
    return 'Deletion Kesalahan: $error';
  }

  @override
  String get chat_theme_description =>
      ' Latar belakang dari this Percakapan adalah only visible to Anda. Global Obrolan Pengaturan in  Obrolan Pengaturan section adalah not affected.';

  @override
  String get chat_theme_default_bg => 'bawaan (global Pengaturan)';

  @override
  String get chat_theme_global_label => 'Global';

  @override
  String get chat_theme_hint => 'Pilih a preset atau Foto from Galeri';

  @override
  String get date_today => 'Hari ini';

  @override
  String get date_yesterday => 'Kemarin';

  @override
  String get date_month_1 => 'Januari';

  @override
  String get date_month_2 => 'Februari';

  @override
  String get date_month_3 => 'Maret';

  @override
  String get date_month_4 => 'April';

  @override
  String get date_month_5 => 'Mei';

  @override
  String get date_month_6 => 'Juni';

  @override
  String get date_month_7 => 'Juli';

  @override
  String get date_month_8 => 'Agustus';

  @override
  String get date_month_9 => 'September';

  @override
  String get date_month_10 => 'Oktober';

  @override
  String get date_month_11 => 'November';

  @override
  String get date_month_12 => 'Desember';

  @override
  String get video_circle_camera_unavailable => 'Kamera unavailable';

  @override
  String video_circle_camera_error(Object error) {
    return 'Gagal to Buka Kamera: $error';
  }

  @override
  String video_circle_record_error(Object error) {
    return 'Merekam Kesalahan: $error';
  }

  @override
  String get video_circle_file_not_found => 'Merekam Berkas Tidak ditemukan';

  @override
  String get video_circle_play_error => 'Gagal to Main Merekam';

  @override
  String video_circle_send_error(Object error) {
    return 'Gagal to Kirim: $error';
  }

  @override
  String video_circle_switch_error(Object error) {
    return 'Gagal to switch Kamera: $error';
  }

  @override
  String video_circle_pause_error_detail(Object description, Object code) {
    return 'Jeda unavailable: $description ($code)';
  }

  @override
  String video_circle_pause_error(Object error) {
    return 'Jeda Merekam: $error';
  }

  @override
  String get video_circle_camera_fallback_error => 'Kamera Kesalahan';

  @override
  String get video_circle_retry => 'Coba lagi';

  @override
  String get video_circle_sending => 'Mengirim...';

  @override
  String get video_circle_recorded => 'Lingkaran direkam';

  @override
  String get video_circle_swipe_cancel => 'Swipe left to Batal';

  @override
  String media_screen_error(Object error) {
    return 'Kesalahan Memuat Media: $error';
  }

  @override
  String get media_screen_title => 'Media, links dan Berkas';

  @override
  String get media_tab_media => 'Media';

  @override
  String get media_tab_circles => 'lingkaran';

  @override
  String get media_tab_files => 'Berkas';

  @override
  String get media_tab_links => 'Tautan';

  @override
  String get media_tab_audio => 'Audio';

  @override
  String get media_empty_files => 'Tidak Berkas';

  @override
  String get media_empty_media => 'Tidak Media';

  @override
  String get media_attachment_fallback => 'Lampiran';

  @override
  String get media_empty_circles => 'Tidak circles';

  @override
  String get media_empty_links => 'Tidak links';

  @override
  String get media_empty_audio => 'Tidak ada pesan suara';

  @override
  String get media_sender_you => 'Anda';

  @override
  String get media_sender_fallback => 'Peserta';

  @override
  String get call_detail_login_required => 'Login wajib.';

  @override
  String get call_detail_not_found =>
      'Panggilan Tidak ditemukan atau Tidak access.';

  @override
  String get call_detail_unknown => 'Tidak dikenal';

  @override
  String get call_detail_title => 'Panggilan details';

  @override
  String get call_detail_video => 'Panggilan video';

  @override
  String get call_detail_audio => 'Panggilan audio';

  @override
  String get call_detail_outgoing => 'Keluar';

  @override
  String get call_detail_incoming => 'Masuk';

  @override
  String get call_detail_date_label => 'Tanggal:';

  @override
  String get call_detail_duration_label => 'Lamanya:';

  @override
  String get call_detail_call_button => 'Panggilan';

  @override
  String get call_detail_video_button => 'Video';

  @override
  String call_detail_error(Object error) {
    return 'Kesalahan: $error';
  }

  @override
  String get durak_took => 'Telah mengambil';

  @override
  String get durak_beaten => 'Dipukuli';

  @override
  String get durak_end_game_tooltip => 'End Permainan';

  @override
  String get durak_role_beats => 'DEF';

  @override
  String get durak_role_move => 'BERGERAK';

  @override
  String get durak_role_throw => 'THR';

  @override
  String get durak_cheater_label => 'Penipu! Dirindukan:';

  @override
  String get durak_waiting_foll_confirm =>
      'Waiting for foul Panggilan… Press \"Konfirmasi Beaten\" if semua orang agrees.';

  @override
  String get durak_waiting_foll_call =>
      'Waiting for foul Panggilan… Anda dapat Sekarang press \"Foul!\" if Anda noticed cheating.';

  @override
  String get durak_winner => 'Pemenang';

  @override
  String get durak_play_again => 'Main again';

  @override
  String durak_games_progress(Object finished, Object total) {
    return 'Played $finished dari $total';
  }

  @override
  String get durak_next_round => 'Berikutnya tournament round';

  @override
  String audio_call_error(Object error) {
    return 'Panggilan Kesalahan: $error';
  }

  @override
  String get audio_call_ended => 'Panggilan ended';

  @override
  String get audio_call_missed => 'Panggilan tak terjawab';

  @override
  String get audio_call_cancelled => 'Panggilan cancelled';

  @override
  String get audio_call_offer_not_ready => 'Offer not ready yet, Coba lagi';

  @override
  String get audio_call_invalid_data => 'Invalid Panggilan Data';

  @override
  String audio_call_accept_error(Object error) {
    return 'Gagal to Terima Panggilan: $error';
  }

  @override
  String get audio_call_incoming => 'Incoming Panggilan Audio';

  @override
  String get audio_call_calling => 'Panggilan Audio…';

  @override
  String privacy_save_error(Object error) {
    return 'Gagal to Simpan Pengaturan: $error';
  }

  @override
  String privacy_load_error(Object error) {
    return 'Kesalahan Memuat Privasi: $error';
  }

  @override
  String get privacy_visibility => 'Visibilitas';

  @override
  String get privacy_online_status => 'Daring Status';

  @override
  String get privacy_last_visit => 'Terakhir dilihat';

  @override
  String get privacy_read_receipts => 'Dibaca receipts';

  @override
  String get privacy_profile_info => 'Profil Info';

  @override
  String get privacy_phone_number => 'Nomor telepon';

  @override
  String get privacy_birthday => 'Hari ulang tahun';

  @override
  String get privacy_about => 'Tentang';

  @override
  String starred_load_error(Object error) {
    return 'Kesalahan Memuat Berbintang: $error';
  }

  @override
  String get starred_title => 'Berbintang';

  @override
  String get starred_empty => 'Tidak Berbintang Pesan in this Obrolan';

  @override
  String get starred_message_fallback => 'Pesan';

  @override
  String get starred_sender_you => 'Anda';

  @override
  String get starred_sender_fallback => 'Peserta';

  @override
  String get starred_type_poll => 'Pemilihan';

  @override
  String get starred_type_location => 'Lokasi';

  @override
  String get starred_type_attachment => 'Lampiran';

  @override
  String starred_today_prefix(Object time) {
    return 'Hari ini, $time';
  }

  @override
  String get contact_edit_name_required => 'Masukkan Kontak name.';

  @override
  String contact_edit_save_error(Object error) {
    return 'Gagal to Simpan Kontak: $error';
  }

  @override
  String get contact_edit_user_fallback => 'Pengguna';

  @override
  String get contact_edit_first_name_hint => 'Nama depan';

  @override
  String get contact_edit_last_name_hint => 'Nama belakang';

  @override
  String get contact_edit_description =>
      'This name adalah only visible to Anda: in Obrolan, Cari dan Kontak list.';

  @override
  String contact_edit_error(Object error) {
    return 'Kesalahan: $error';
  }

  @override
  String get voice_no_mic_access => 'Tidak Mikrofon access';

  @override
  String get voice_start_error => 'Gagal to Mulai Merekam';

  @override
  String get voice_file_not_received => 'Merekam Berkas not received';

  @override
  String get voice_stop_error => 'Gagal to Berhenti Merekam';

  @override
  String get voice_title => 'Pesan suara';

  @override
  String get voice_recording => 'Merekam';

  @override
  String get voice_ready => 'Merekam ready';

  @override
  String get voice_stop_button => 'Berhenti';

  @override
  String get voice_record_again => 'Rekam again';

  @override
  String get attach_photo_video => 'Foto/Video';

  @override
  String get attach_files => 'Berkas';

  @override
  String get attach_circle => 'Lingkaran';

  @override
  String get attach_location => 'Lokasi';

  @override
  String get attach_poll => 'Pemilihan';

  @override
  String get attach_stickers => 'Stiker';

  @override
  String get attach_clipboard => 'papan klip';

  @override
  String get attach_text => 'Teks';

  @override
  String get attach_title => 'Menempel';

  @override
  String notif_save_error(Object error) {
    return 'Gagal to Simpan: $error';
  }

  @override
  String get notif_title => 'Notifikasi in this Obrolan';

  @override
  String get notif_description =>
      'Pengaturan below Terapkan only to this Percakapan dan do not change global app Notifikasi.';

  @override
  String get notif_this_chat => 'This Obrolan';

  @override
  String get notif_mute_title => 'Bisukan dan Sembunyikan Notifikasi';

  @override
  String get notif_mute_subtitle =>
      'Do not disturb for this Obrolan on Perangkat ini.';

  @override
  String get notif_preview_title => 'Tampilkan text preview';

  @override
  String get notif_preview_subtitle =>
      'When off — Notifikasi title without Pesan snippet (where supported).';

  @override
  String get poll_create_enter_question => 'Masukkan a question';

  @override
  String get poll_create_min_options => 'At least 2 options wajib';

  @override
  String get poll_create_select_correct => 'Pilih  correct option';

  @override
  String get poll_create_future_time => 'Tutup time must be in  future';

  @override
  String get poll_create_question_label => 'Pertanyaan';

  @override
  String get poll_create_question_hint =>
      'For example: What time adalah we Pertemuan?';

  @override
  String get poll_create_explanation_label => 'Explanation (opsional)';

  @override
  String get poll_create_options_title => 'Pilihan';

  @override
  String poll_create_option_hint(Object index) {
    return 'Opsi $index';
  }

  @override
  String get poll_create_add_option => 'Tambah option';

  @override
  String get poll_create_anonymous_title => 'Pemungutan suara anonim';

  @override
  String get poll_create_anonymous_subtitle =>
      'Don\'t Tampilkan who voted for what';

  @override
  String get poll_create_multi_title => 'Banyak jawaban';

  @override
  String get poll_create_multi_subtitle => 'dapat Pilih multiple options';

  @override
  String get poll_create_user_options_title => 'Pengguna-submitted options';

  @override
  String get poll_create_user_options_subtitle =>
      'Participants dapat suggest their own option';

  @override
  String get poll_create_revote_title => 'Izinkan pemungutan suara ulang';

  @override
  String get poll_create_revote_subtitle =>
      'dapat change vote until poll closes';

  @override
  String get poll_create_shuffle_title => 'Opsi acak';

  @override
  String get poll_create_shuffle_subtitle =>
      'Setiap peserta melihat urutan yang berbeda';

  @override
  String get poll_create_quiz_title => 'Modus kuis';

  @override
  String get poll_create_quiz_subtitle => 'One correct Jawab';

  @override
  String get poll_create_correct_option_label => 'Pilihan yang benar';

  @override
  String get poll_create_close_by_time => 'Tutup by time';

  @override
  String get poll_create_not_set => 'Tidak disetel';

  @override
  String get poll_create_reset_deadline => 'Atur ulang deadline';

  @override
  String get poll_create_publish => 'Menerbitkan';

  @override
  String get poll_error => 'Kesalahan';

  @override
  String get poll_status_finished => 'Selesai';

  @override
  String get poll_restart => 'Mulai ulang';

  @override
  String get poll_finish => 'Menyelesaikan';

  @override
  String get poll_suggest_hint => 'Sarankan sebuah opsi';

  @override
  String get poll_voters_toggle_hide => 'Sembunyikan';

  @override
  String get poll_voters_toggle_show => 'Siapa yang memilih';

  @override
  String get e2ee_disable_title => 'Nonaktifkan Enkripsi?';

  @override
  String get e2ee_disable_body =>
      'Baru Pesan akan Dikirim without Enkripsi ujung ke ujung. Previously Dikirim encrypted Pesan will remain in  feed.';

  @override
  String get e2ee_disable_button => 'Nonaktifkan';

  @override
  String e2ee_disable_error(Object error) {
    return 'Gagal to Nonaktifkan: $error';
  }

  @override
  String get e2ee_screen_title => 'Enkripsi';

  @override
  String get e2ee_enabled_description =>
      'Enkripsi ujung ke ujung adalah enabled for this Obrolan.';

  @override
  String get e2ee_disabled_description =>
      'Enkripsi ujung ke ujung adalah disabled.';

  @override
  String get e2ee_info_text =>
      'When Enkripsi adalah enabled,  content dari Baru Pesan adalah only available to Obrolan participants on their Perangkat. Disabling only affects Baru Pesan.';

  @override
  String get e2ee_enable_title => 'Aktifkan Enkripsi';

  @override
  String e2ee_status_enabled(Object epoch) {
    return 'Diaktifkan (masa kunci: $epoch)';
  }

  @override
  String get e2ee_status_disabled => 'Dengan disabilitas';

  @override
  String get e2ee_data_types_title => 'Tipe data';

  @override
  String get e2ee_data_types_info =>
      'This setting does not change  protocol. It controls which Data types to Kirim encrypted.';

  @override
  String get e2ee_chat_settings_title => 'Enkripsi Pengaturan for this Obrolan';

  @override
  String get e2ee_chat_settings_override =>
      'Using Obrolan-specific Pengaturan.';

  @override
  String get e2ee_chat_settings_global => 'Inheriting global Pengaturan.';

  @override
  String get e2ee_text_messages => 'Text Pesan';

  @override
  String get e2ee_attachments => 'Attachments (Media/Berkas)';

  @override
  String get e2ee_override_hint =>
      'To change for this Obrolan — Aktifkan \"Override\".';

  @override
  String get group_member_fallback => 'Peserta';

  @override
  String get group_role_creator => 'Grup creator';

  @override
  String get group_role_admin => 'Administrator';

  @override
  String group_total_count(Object count) {
    return 'Jumlah: $count';
  }

  @override
  String get group_copy_invite_tooltip => 'Salin Tautan undangan';

  @override
  String get group_add_member_tooltip => 'Tambah Anggota';

  @override
  String get group_invite_copied => 'Tautan undangan Disalin';

  @override
  String group_copy_invite_error(Object error) {
    return 'Gagal to Salin Tautan: $error';
  }

  @override
  String get group_demote_confirm => 'Hapus Admin rights?';

  @override
  String get group_promote_confirm => 'Make Administrator?';

  @override
  String group_demote_body(Object name) {
    return '$name will have their Admin rights Dihapus.  Anggota will remain in  Grup as a regular Anggota.';
  }

  @override
  String get group_demote_button => 'Hapus rights';

  @override
  String get group_promote_button => 'Mendorong';

  @override
  String get group_kick_confirm => 'Hapus anggota?';

  @override
  String get group_kick_button => 'Hapus';

  @override
  String get group_member_kicked => 'Anggota Dihapus';

  @override
  String get group_badge_creator => 'PENCIPTA';

  @override
  String get group_demote_action => 'Hapus Admin';

  @override
  String get group_promote_action => 'Make Admin';

  @override
  String get group_kick_action => 'Hapus from Grup';

  @override
  String group_contacts_load_error(Object error) {
    return 'Gagal to load Kontak: $error';
  }

  @override
  String get group_add_members_title => 'Tambah anggota';

  @override
  String get group_search_contacts_hint => 'Cari Kontak';

  @override
  String get group_all_contacts_in_group =>
      'Semua Anda Kontak adalah already in  Grup.';

  @override
  String get group_nobody_found => 'tidak ada found.';

  @override
  String get group_user_fallback => 'Pengguna';

  @override
  String get group_select_members => 'Pilih Anggota';

  @override
  String group_add_count(Object count) {
    return 'Tambah ($count)';
  }

  @override
  String group_auth_error(Object error) {
    return 'Authorization Kesalahan: $error';
  }

  @override
  String group_add_error(Object error) {
    return 'Gagal to Tambah anggota: $error';
  }

  @override
  String get add_contact_own_profile => 'This adalah Anda own Profil';

  @override
  String get add_contact_qr_not_found => 'Profil from Kode QR Tidak ditemukan';

  @override
  String add_contact_qr_error(Object error) {
    return 'Gagal to Dibaca Kode QR: $error';
  }

  @override
  String get add_contact_not_allowed => 'tidak dapat Tambah this Pengguna';

  @override
  String add_contact_save_error(Object error) {
    return 'Gagal to Tambah Kontak: $error';
  }

  @override
  String get add_contact_country_search => 'Cari country atau code';

  @override
  String get add_contact_sync_phone => 'Sinkronkan dengan telepon';

  @override
  String get add_contact_qr_button => 'Tambah by Kode QR';

  @override
  String add_contact_load_error(Object error) {
    return 'Kesalahan Memuat Kontak: $error';
  }

  @override
  String get add_contact_user_fallback => 'Pengguna';

  @override
  String get add_contact_already_in_contacts => 'Already in Kontak';

  @override
  String get add_contact_new => 'Baru Kontak';

  @override
  String get add_contact_unavailable => 'Tidak tersedia';

  @override
  String get add_contact_scan_qr => 'Pindai kode QR';

  @override
  String get add_contact_scan_hint => 'Point Kamera at LighChat Profil Kode QR';

  @override
  String get auth_validate_name_min_length => 'Nama minimal harus 2 karakter';

  @override
  String get auth_validate_username_min_length =>
      'Nama pengguna must be at least 3 characters';

  @override
  String get auth_validate_username_max_length =>
      'Nama pengguna must not exceed 30 characters';

  @override
  String get auth_validate_username_format =>
      'Nama pengguna contains invalid characters';

  @override
  String get auth_validate_phone_11_digits =>
      'Nomor telepon must contain 11 digits';

  @override
  String get auth_validate_email_format => 'Masukkan a valid Email';

  @override
  String get auth_validate_dob_invalid => 'Invalid date dari birth';

  @override
  String get auth_validate_bio_max_length =>
      'Bio tidak boleh melebihi 200 karakter';

  @override
  String get auth_validate_password_min_length =>
      'Kata sandi must be at least 6 characters';

  @override
  String get auth_validate_passwords_mismatch => 'Kata sandi tidak cocok';

  @override
  String get sticker_new_pack => 'Baru pack…';

  @override
  String get sticker_select_image_or_gif => 'Pilih an Gambar atau GIF';

  @override
  String sticker_send_error(Object error) {
    return 'Gagal to Kirim: $error';
  }

  @override
  String get sticker_saved => 'Disimpan to Stiker pack';

  @override
  String get sticker_save_failed => 'Gagal to Unduh atau Simpan GIF';

  @override
  String get sticker_tab_my => '-ku';

  @override
  String get sticker_tab_shared => 'Dibagikan';

  @override
  String get sticker_no_packs => 'Tidak Stiker packs. Buat a Baru one.';

  @override
  String get sticker_shared_not_configured =>
      'Paket bersama tidak dikonfigurasi';

  @override
  String get sticker_recent => 'TERKINI';

  @override
  String get sticker_gallery_description =>
      'Foto, PNG, GIF from Perangkat — straight to Obrolan';

  @override
  String get sticker_shared_unavailable => 'Paket bersama belum tersedia';

  @override
  String get sticker_gif_search_hint => 'Cari GIF…';

  @override
  String sticker_gif_searched(Object query) {
    return 'Ditelusuri: $query';
  }

  @override
  String get sticker_gif_search_unavailable =>
      'GIF Cari temporarily unavailable.';

  @override
  String get sticker_gif_nothing_found => 'Tidak ada yang ditemukan';

  @override
  String get sticker_gif_all => 'Semua';

  @override
  String get sticker_gif_animated => 'ANIMASI';

  @override
  String get sticker_emoji_text_unavailable =>
      'Text Emoji not available for this window.';

  @override
  String get wallpaper_sender => 'Kontak';

  @override
  String get wallpaper_incoming => 'This adalah an incoming Pesan.';

  @override
  String get wallpaper_outgoing => 'This adalah an outgoing Pesan.';

  @override
  String get wallpaper_incoming_time => '11:40';

  @override
  String get wallpaper_outgoing_time => '11:41';

  @override
  String get wallpaper_system => 'Anda changed Obrolan Wallpaper';

  @override
  String get wallpaper_you => 'Anda';

  @override
  String get wallpaper_today => 'Hari ini';

  @override
  String system_event_e2ee_enabled(Object epoch) {
    return 'Enkripsi ujung ke ujung enabled (key epoch: $epoch)';
  }

  @override
  String get system_event_e2ee_disabled => 'Enkripsi ujung ke ujung disabled';

  @override
  String get system_event_unknown => 'Sistem event';

  @override
  String get system_event_group_created => 'Grup Dibuat';

  @override
  String system_event_member_added(Object name) {
    return '$name adalah Ditambahkan';
  }

  @override
  String system_event_member_removed(Object name) {
    return '$name adalah Dihapus';
  }

  @override
  String system_event_member_left(Object name) {
    return '$name left  Grup';
  }

  @override
  String system_event_name_changed(Object name) {
    return 'Nama diubah menjadi \"$name\"';
  }

  @override
  String get image_editor_title => 'Editor';

  @override
  String get image_editor_undo => 'Urungkan';

  @override
  String get image_editor_clear => 'Hapus';

  @override
  String get image_editor_pen => 'Sikat';

  @override
  String get image_editor_text => 'Teks';

  @override
  String get image_editor_crop => 'Tanaman';

  @override
  String get image_editor_rotate => 'Memutar';

  @override
  String get location_title => 'Kirim Lokasi';

  @override
  String get location_loading => 'Memuat map…';

  @override
  String get location_send_button => 'Kirim';

  @override
  String get location_live_label => 'Hidup';

  @override
  String get location_error => 'Gagal to load map';

  @override
  String get location_no_permission => 'Tidak Lokasi access';

  @override
  String get group_member_admin => 'Admin';

  @override
  String get group_member_creator => 'Pencipta';

  @override
  String get group_member_member => 'Anggota';

  @override
  String get group_member_open_chat => 'Pesan';

  @override
  String get group_member_open_profile => 'Profil';

  @override
  String get group_member_remove => 'Hapus';

  @override
  String get durak_lobby_title => 'Durak';

  @override
  String get durak_lobby_new_game => 'Baru Permainan';

  @override
  String get durak_lobby_decline => 'Tolak';

  @override
  String get durak_lobby_accept => 'Terima';

  @override
  String get durak_lobby_invite_sent => 'Invitation Dikirim';

  @override
  String get voice_preview_cancel => 'Batal';

  @override
  String get voice_preview_send => 'Kirim';

  @override
  String get voice_preview_recorded => 'Tercatat';

  @override
  String get voice_preview_playing => 'Bermain…';

  @override
  String get voice_preview_paused => 'Dijeda';

  @override
  String get group_avatar_camera => 'Kamera';

  @override
  String get group_avatar_gallery => 'Galeri';

  @override
  String get group_avatar_upload_error => 'Unggah Kesalahan';

  @override
  String get avatar_picker_title => 'Avatar';

  @override
  String get avatar_picker_camera => 'Kamera';

  @override
  String get avatar_picker_gallery => 'Galeri';

  @override
  String get avatar_picker_crop => 'Tanaman';

  @override
  String get avatar_picker_save => 'Simpan';

  @override
  String get avatar_picker_remove => 'Hapus avatar';

  @override
  String get avatar_picker_error => 'Gagal to load avatar';

  @override
  String get avatar_picker_crop_error => 'Crop Kesalahan';

  @override
  String get webview_telegram_title => 'Masuk with Telegram';

  @override
  String get webview_telegram_loading => 'Memuat…';

  @override
  String get webview_telegram_error => 'Gagal to load page';

  @override
  String get webview_telegram_back => 'Kembali';

  @override
  String get webview_telegram_retry => 'Coba lagi';

  @override
  String get webview_telegram_close => 'Tutup';

  @override
  String get webview_telegram_no_url => 'Tidak authorization URL provided';

  @override
  String get webview_yandex_title => 'Masuk with Yandex';

  @override
  String get webview_yandex_loading => 'Memuat…';

  @override
  String get webview_yandex_error => 'Gagal to load page';

  @override
  String get webview_yandex_back => 'Kembali';

  @override
  String get webview_yandex_retry => 'Coba lagi';

  @override
  String get webview_yandex_close => 'Tutup';

  @override
  String get webview_yandex_no_url => 'Tidak authorization URL provided';

  @override
  String get google_profile_title => 'Complete Anda Profil';

  @override
  String get google_profile_name => 'Nama';

  @override
  String get google_profile_username => 'Nama pengguna';

  @override
  String get google_profile_phone => 'Telepon';

  @override
  String get google_profile_email => 'E-mail';

  @override
  String get google_profile_dob => 'Date dari birth';

  @override
  String get google_profile_bio => 'Tentang';

  @override
  String get google_profile_save => 'Simpan';

  @override
  String get google_profile_error => 'Gagal to Simpan Profil';

  @override
  String get system_event_e2ee_epoch_rotated => 'Enkripsi key rotated';

  @override
  String system_event_e2ee_device_added(String actor, String device) {
    return '$actor Ditambahkan Perangkat \"$device\"';
  }

  @override
  String system_event_e2ee_device_revoked(String actor, String device) {
    return '$actor revoked Perangkat \"$device\"';
  }

  @override
  String system_event_e2ee_fingerprint_changed(String actor) {
    return 'Keamanan Sidik jari for $actor changed';
  }

  @override
  String get system_event_game_lobby_created => 'Permainan lobby Dibuat';

  @override
  String get system_event_game_started => 'Permainan started';

  @override
  String get system_event_call_missed => 'Panggilan terlewat';

  @override
  String get system_event_call_cancelled => 'Panggilan ditolak';

  @override
  String get system_event_default_actor => 'Pengguna';

  @override
  String get system_event_default_device => 'Perangkat';

  @override
  String get image_editor_add_caption => 'Tambah caption...';

  @override
  String get image_editor_crop_failed => 'Gagal to crop Gambar';

  @override
  String get image_editor_draw_hint => 'Drawing mode: swipe across  Gambar';

  @override
  String get image_editor_crop_title => 'Tanaman';

  @override
  String get location_preview_title => 'Lokasi';

  @override
  String get location_preview_accuracy_unknown => 'Akurasi: —';

  @override
  String location_preview_accuracy_meters(String meters) {
    return 'Akurasi: ~$meters m';
  }

  @override
  String location_preview_accuracy_km(String km) {
    return 'Akurasi: ~$km km';
  }

  @override
  String get group_member_profile_default_name => 'Anggota';

  @override
  String get group_member_profile_dm => 'Kirim direct Pesan';

  @override
  String get group_member_profile_dm_hint =>
      'Buka a direct Obrolan with this Anggota';

  @override
  String group_member_profile_dm_failed(Object error) {
    return 'Gagal to Buka direct Obrolan: $error';
  }

  @override
  String get conversation_game_lobby_unavailable =>
      'Permainan unavailable atau adalah Dihapus';

  @override
  String get conversation_game_lobby_back => 'Kembali';

  @override
  String get conversation_game_lobby_waiting => 'Waiting for Lawan to Gabung…';

  @override
  String get conversation_game_lobby_start_game => 'Mulai Permainan';

  @override
  String get conversation_game_lobby_waiting_short => 'Menunggu…';

  @override
  String get conversation_game_lobby_ready => 'Siap';

  @override
  String get voice_preview_trim_confirm_title => 'Keep only  Dipilih fragment?';

  @override
  String get voice_preview_trim_confirm_body =>
      'Everything except  Dipilih fragment akan Dihapus. Merekam will Lanjutkan immediately after pressing  button.';

  @override
  String get voice_preview_continue => 'Lanjutkan';

  @override
  String get voice_preview_continue_recording => 'Lanjutkan Merekam';

  @override
  String get group_avatar_change_short => 'Mengubah';

  @override
  String get avatar_picker_cancel => 'Batal';

  @override
  String get avatar_picker_choose => 'Pilih avatar';

  @override
  String get avatar_picker_delete_photo => 'Hapus Foto';

  @override
  String get avatar_picker_loading => 'Memuat…';

  @override
  String get avatar_picker_choose_avatar => 'Pilih avatar';

  @override
  String get avatar_picker_change_avatar => 'Ubah avatar';

  @override
  String get avatar_picker_remove_tooltip => 'Hapus';

  @override
  String get telegram_sign_in_title => 'Masuk via Telegram';

  @override
  String get telegram_sign_in_open_in_browser => 'Buka in browser';

  @override
  String get telegram_sign_in_open_telegram_failed =>
      'Gagal to Buka Telegram. Silakan install  Telegram app.';

  @override
  String get telegram_sign_in_page_load_error => 'Page load Kesalahan';

  @override
  String get telegram_sign_in_login_error => 'Telegram sign-in Kesalahan.';

  @override
  String get telegram_sign_in_firebase_not_ready => 'Firebase belum siap.';

  @override
  String get telegram_sign_in_browser_failed => 'Gagal to Buka browser.';

  @override
  String telegram_sign_in_login_failed(Object error) {
    return 'Sign-in Gagal: $error';
  }

  @override
  String get yandex_sign_in_title => 'Masuk via Yandex';

  @override
  String get yandex_sign_in_open_in_browser => 'Buka in browser';

  @override
  String get yandex_sign_in_page_load_error => 'Page load Kesalahan';

  @override
  String get yandex_sign_in_login_error => 'Yandex sign-in Kesalahan.';

  @override
  String get yandex_sign_in_firebase_not_ready => 'Firebase belum siap.';

  @override
  String get yandex_sign_in_browser_failed => 'Gagal to Buka browser.';

  @override
  String yandex_sign_in_login_failed(Object error) {
    return 'Sign-in Gagal: $error';
  }

  @override
  String get google_complete_title => 'Pendaftaran lengkap';

  @override
  String get google_complete_subtitle =>
      'After signing in with Google, Silakan fill in Anda Profil as on  web Versi.';

  @override
  String get google_complete_name_label => 'Nama';

  @override
  String get google_complete_username_label => 'Nama pengguna (@Nama pengguna)';

  @override
  String get google_complete_phone_label => 'Telepon (11 digit)';

  @override
  String get google_complete_email_label => 'E-mail';

  @override
  String get google_complete_email_hint => 'Anda@example.com';

  @override
  String get google_complete_dob_label =>
      'Date dari birth (YYYY-MM-DD, opsional)';

  @override
  String get google_complete_bio_label =>
      'Tentang (up to 200 characters, opsional)';

  @override
  String get google_complete_save => 'Simpan dan Lanjutkan';

  @override
  String get google_complete_back => 'Kembali to Masuk';

  @override
  String get game_error_defense_not_beat =>
      'This card doesn\'t beat  attacking card';

  @override
  String get game_error_attacker_first => ' attacker moves first';

  @override
  String get game_error_defender_no_attack =>
      ' defender dapat\'t attack right Sekarang';

  @override
  String get game_error_not_allowed_throwin =>
      'Anda dapat\'t throw in this round';

  @override
  String get game_error_throwin_not_turn =>
      'Another player adalah throwing in Sekarang';

  @override
  String get game_error_rank_not_allowed =>
      'Anda dapat only throw in a card dari  same rank';

  @override
  String get game_error_cannot_throw_in =>
      'Tidak Lainnya cards dapat be thrown in';

  @override
  String get game_error_card_not_in_hand =>
      'This card adalah Tidak longer in Anda hand';

  @override
  String get game_error_already_defended => 'This card adalah already defended';

  @override
  String get game_error_bad_attack_index =>
      'Pilih an attacking card to defend against';

  @override
  String get game_error_only_defender =>
      'Another player adalah defending Sekarang';

  @override
  String get game_error_defender_taking =>
      ' defender adalah already taking cards';

  @override
  String get game_error_game_not_active =>
      ' Permainan adalah Tidak longer Aktif';

  @override
  String get game_error_not_in_lobby => ' lobby has already started';

  @override
  String get game_error_game_already_active => ' Permainan has already started';

  @override
  String get game_error_active_exists =>
      'There adalah already an Aktif Permainan in this Obrolan';

  @override
  String get game_error_round_pending => 'Finish  contested move first';

  @override
  String get game_error_rematch_failed => 'Gagal to prepare rematch. Coba lagi';

  @override
  String get game_error_unauthenticated => 'Anda need to Masuk';

  @override
  String get game_error_permission_denied =>
      'This action adalah not available to Anda';

  @override
  String get game_error_invalid_argument => 'Langkah tidak valid';

  @override
  String get game_error_precondition =>
      'Move adalah not available right Sekarang';

  @override
  String get game_error_server => 'Gagal to make move. Coba lagi';

  @override
  String get reply_sticker => 'Stiker';

  @override
  String get reply_gif => 'GIF';

  @override
  String get reply_video_circle => 'Lingkaran video';

  @override
  String get reply_voice_message => 'Pesan suara';

  @override
  String get reply_video => 'Video';

  @override
  String get reply_photo => 'Foto';

  @override
  String get reply_file => 'Berkas';

  @override
  String get reply_location => 'Lokasi';

  @override
  String get reply_poll => 'Pemilihan';

  @override
  String get reply_link => 'Tautan';

  @override
  String get reply_message => 'Pesan';

  @override
  String get reply_sender_you => 'Anda';

  @override
  String get reply_sender_member => 'Anggota';

  @override
  String get call_format_today => 'Hari ini';

  @override
  String get call_format_yesterday => 'Kemarin';

  @override
  String get call_format_second_short => 'S';

  @override
  String get call_format_minute_short => 'M';

  @override
  String get call_format_hour_short => 'H';

  @override
  String get call_format_day_short => 'D';

  @override
  String get call_month_january => 'Januari';

  @override
  String get call_month_february => 'Februari';

  @override
  String get call_month_march => 'Maret';

  @override
  String get call_month_april => 'April';

  @override
  String get call_month_may => 'Mei';

  @override
  String get call_month_june => 'Juni';

  @override
  String get call_month_july => 'Juli';

  @override
  String get call_month_august => 'Agustus';

  @override
  String get call_month_september => 'September';

  @override
  String get call_month_october => 'Oktober';

  @override
  String get call_month_november => 'November';

  @override
  String get call_month_december => 'Desember';

  @override
  String get push_incoming_call => 'Panggilan masuk';

  @override
  String get push_incoming_video_call => 'Incoming Panggilan Video';

  @override
  String get push_new_message => 'Pesan baru';

  @override
  String get push_channel_calls => 'Panggilan';

  @override
  String get push_channel_messages => 'Pesan';

  @override
  String contacts_years_one(Object count) {
    return '$count tahun';
  }

  @override
  String contacts_years_few(Object count) {
    return '$count tahun';
  }

  @override
  String contacts_years_many(Object count) {
    return '$count tahun';
  }

  @override
  String contacts_years_other(Object count) {
    return '$count tahun';
  }

  @override
  String get durak_entry_single_game => 'Single Permainan';

  @override
  String get durak_entry_finish_game_tooltip => 'Finish Permainan';

  @override
  String get durak_entry_tournament_games_dialog_title =>
      'How many Permainan in tournament?';

  @override
  String get durak_entry_cancel => 'Batal';

  @override
  String get durak_entry_create => 'Buat';

  @override
  String video_editor_load_failed(Object error) {
    return 'Gagal to load Video: $error';
  }

  @override
  String video_editor_process_failed(Object error) {
    return 'Gagal to process Video: $error';
  }

  @override
  String video_editor_duration(Object duration) {
    return 'Durasi: $duration';
  }

  @override
  String get video_editor_brush => 'Sikat';

  @override
  String get video_editor_caption_hint => 'Tambah caption...';

  @override
  String get video_effects_speed => 'Kecepatan';

  @override
  String get video_filter_none => 'Asli';

  @override
  String get video_filter_enhance => 'Tingkatkan';

  @override
  String get share_location_title => 'Bagikan Lokasi';

  @override
  String get share_location_how => 'Metode berbagi';

  @override
  String get share_location_cancel => 'Batal';

  @override
  String get share_location_send => 'Kirim';

  @override
  String get photo_source_gallery => 'Galeri';

  @override
  String get photo_source_take_photo => 'Ambil foto';

  @override
  String get photo_source_record_video => 'Rekam video';

  @override
  String get video_attachment_media_kind => 'Video';

  @override
  String get video_attachment_title => 'Video';

  @override
  String get video_attachment_playback_error =>
      'Unable to Main Video. Check  Tautan dan Jaringan connection.';

  @override
  String get location_card_broadcast_ended_mine =>
      'Lokasi broadcast ended.  Lainnya person dapat Tidak longer see Anda current Lokasi.';

  @override
  String get location_card_broadcast_ended_other =>
      'This Kontak\'s Lokasi broadcast has ended. Current position adalah unavailable.';

  @override
  String get location_card_title => 'Lokasi';

  @override
  String location_card_accuracy(Object meters) {
    return '±$meters m';
  }

  @override
  String get link_webview_copy_tooltip => 'Salin Tautan';

  @override
  String get link_webview_copied_snackbar => 'Tautan Disalin';

  @override
  String get link_webview_open_browser_tooltip => 'Buka in browser';

  @override
  String get hold_record_pause => 'Dijeda';

  @override
  String get hold_record_release_cancel => 'Release to Batal';

  @override
  String get hold_record_slide_hints => 'Slide left — Batal · Up — Jeda';

  @override
  String get e2ee_badge_loading => 'Memuat Sidik jari…';

  @override
  String e2ee_badge_error(Object error) {
    return 'Gagal to get Sidik jari: $error';
  }

  @override
  String get e2ee_badge_label => 'E2EE Sidik jari';

  @override
  String e2ee_badge_label_with_user(Object user) {
    return 'E2EE Sidik jari • $user';
  }

  @override
  String e2ee_badge_devices(Object count) {
    return '$count pengembang.';
  }

  @override
  String get composer_link_cancel => 'Batal';

  @override
  String message_search_results_count(Object count) {
    return 'Cari RESULTS: $count';
  }

  @override
  String get message_search_not_found => 'TIDAK ADA YANG DITEMUKAN';

  @override
  String get message_search_participant_fallback => 'Peserta';

  @override
  String get wallpaper_purple => 'Ungu';

  @override
  String get wallpaper_pink => 'Berwarna merah muda';

  @override
  String get wallpaper_blue => 'Biru';

  @override
  String get wallpaper_green => 'Hijau';

  @override
  String get wallpaper_sunset => 'Matahari terbenam';

  @override
  String get wallpaper_tender => 'Lembut';

  @override
  String get wallpaper_lime => 'Kapur';

  @override
  String get wallpaper_graphite => 'Grafit';

  @override
  String get avatar_crop_title => 'Sesuaikan avatar';

  @override
  String get avatar_crop_hint =>
      'Drag dan zoom —  circle will appear in lists dan Pesan;  full frame stays for  Profil.';

  @override
  String get avatar_crop_cancel => 'Batal';

  @override
  String get avatar_crop_reset => 'Atur ulang';

  @override
  String get avatar_crop_save => 'Simpan';

  @override
  String get meeting_entry_connecting => 'Connecting to Pertemuan…';

  @override
  String meeting_entry_auth_failed(Object error) {
    return 'Gagal to Masuk: $error';
  }

  @override
  String get meeting_entry_participant_fallback => 'Peserta';

  @override
  String get meeting_entry_back => 'Kembali';

  @override
  String get meeting_chat_copy => 'Salin';

  @override
  String get meeting_chat_edit => 'Sunting';

  @override
  String get meeting_chat_delete => 'Hapus';

  @override
  String get meeting_chat_deleted => 'Pesan Dihapus';

  @override
  String get meeting_chat_edited_mark => '• diedit';

  @override
  String get meeting_chat_reply => 'Balas';

  @override
  String get meeting_chat_react => 'Reaksi';

  @override
  String get meeting_chat_copied => 'Disalin';

  @override
  String get meeting_chat_editing => 'Mengedit';

  @override
  String meeting_chat_reply_to(Object name) {
    return 'Balas ke $name';
  }

  @override
  String get meeting_chat_attachment_placeholder => 'Lampiran';

  @override
  String meeting_timer_remaining(Object time) {
    return 'Sisa $time';
  }

  @override
  String meeting_timer_elapsed(Object time) {
    return '$time';
  }

  @override
  String get meeting_back_to_chats => 'Kembali ke chat';

  @override
  String get meeting_open_chats => 'Buka chat';

  @override
  String get meeting_in_call_chat => 'Chat saat panggilan';

  @override
  String get meeting_lobby_open_settings => 'Buka pengaturan';

  @override
  String get meeting_lobby_retry => 'Coba lagi';

  @override
  String get meeting_minimized_resume => 'Ketuk untuk kembali ke panggilan';

  @override
  String get e2ee_decrypt_image_failed => 'Gagal to decrypt Gambar';

  @override
  String get e2ee_decrypt_video_failed => 'Gagal to decrypt Video';

  @override
  String get e2ee_decrypt_audio_failed => 'Gagal to decrypt Audio';

  @override
  String get e2ee_decrypt_attachment_failed => 'Gagal to decrypt attachment';

  @override
  String get search_preview_attachment => 'Lampiran';

  @override
  String get search_preview_location => 'Lokasi';

  @override
  String get search_preview_message => 'Pesan';

  @override
  String get outbox_attachment_singular => 'Lampiran';

  @override
  String outbox_attachments_count(int count) {
    return 'Lampiran ($count)';
  }

  @override
  String get outbox_chat_unavailable => 'Obrolan service unavailable';

  @override
  String outbox_encryption_error(String code) {
    return 'Enkripsi: $code';
  }

  @override
  String get nav_chats => 'Obrolan';

  @override
  String get nav_contacts => 'Kontak';

  @override
  String get nav_meetings => 'Rapat';

  @override
  String get nav_calls => 'Panggilan';

  @override
  String get e2ee_media_decrypt_failed_image => 'Gagal to decrypt Gambar';

  @override
  String get e2ee_media_decrypt_failed_video => 'Gagal to decrypt Video';

  @override
  String get e2ee_media_decrypt_failed_audio => 'Gagal to decrypt Audio';

  @override
  String get e2ee_media_decrypt_failed_attachment =>
      'Gagal to decrypt attachment';

  @override
  String get chat_search_snippet_attachment => 'Lampiran';

  @override
  String get chat_search_snippet_location => 'Lokasi';

  @override
  String get chat_search_snippet_message => 'Pesan';

  @override
  String get bottom_nav_chats => 'Obrolan';

  @override
  String get bottom_nav_contacts => 'Kontak';

  @override
  String get bottom_nav_meetings => 'Rapat';

  @override
  String get bottom_nav_calls => 'Panggilan';

  @override
  String get chat_list_swipe_folders => 'FOLDER';

  @override
  String get chat_list_swipe_clear => 'Hapus';

  @override
  String get chat_list_swipe_delete => 'Hapus';

  @override
  String get composer_editing_title => 'EDITING Pesan';

  @override
  String get composer_editing_cancel_tooltip => 'Batal editing';

  @override
  String get composer_formatting_title => 'MEMFORMAT';

  @override
  String get composer_link_preview_loading => 'Memuat preview…';

  @override
  String get composer_link_preview_hide_tooltip => 'Sembunyikan preview';

  @override
  String get chat_invite_button => 'Undang';

  @override
  String get forward_preview_unknown_sender => 'Tidak dikenal';

  @override
  String get forward_preview_attachment => 'Lampiran';

  @override
  String get forward_preview_message => 'Pesan';

  @override
  String get chat_mention_no_matches => 'Tidak matches';

  @override
  String get live_location_sharing => 'Anda adalah sharing Anda Lokasi';

  @override
  String get live_location_stop => 'Berhenti';

  @override
  String get chat_message_deleted => 'Pesan Dihapus';

  @override
  String get profile_qr_share => 'Bagikan';

  @override
  String get shared_location_open_browser_tooltip => 'Buka in browser';

  @override
  String get reply_preview_message_fallback => 'Pesan';

  @override
  String get video_circle_media_kind => 'Video';

  @override
  String reactions_rated_count(int count) {
    return 'Bereaksi: $count';
  }

  @override
  String reactions_today_time(String time) {
    return 'Hari ini, $time';
  }

  @override
  String get durak_create_timer_subtitle => 'bawaan 15 detik';

  @override
  String get dm_game_banner_active => 'Durak Permainan in progress';

  @override
  String get dm_game_banner_created => 'Durak Permainan Dibuat';

  @override
  String get chat_folder_favorites => 'Favorit';

  @override
  String get chat_folder_new => 'Baru';

  @override
  String get contact_profile_user_fallback => 'Pengguna';

  @override
  String contact_profile_error(String error) {
    return 'Kesalahan: $error';
  }

  @override
  String get conversation_threads_loading_title => 'benang';

  @override
  String get theme_label_light => 'Terang';

  @override
  String get theme_label_dark => 'Gelap';

  @override
  String get theme_label_auto => 'Mobil';

  @override
  String get chat_draft_reply_fallback => 'Balas';

  @override
  String get mention_default_label => 'Anggota';

  @override
  String get contacts_fallback_name => 'Kontak';

  @override
  String get sticker_pack_default_name => 'Paket saya';

  @override
  String get profile_error_phone_taken =>
      'This Nomor telepon adalah already registered. Silakan use a different number.';

  @override
  String get profile_error_email_taken =>
      'This Email adalah already taken. Silakan use a different address.';

  @override
  String get profile_error_username_taken =>
      'This Nama pengguna adalah already taken. Silakan Pilih another.';

  @override
  String get e2ee_banner_default_context => 'Pesan';

  @override
  String e2ee_banner_encrypted_chat_web_only(String prefix) {
    return '$prefix to an encrypted Obrolan dapat only be Dikirim from  web client for Sekarang.';
  }

  @override
  String get chat_attachment_decrypt_error => 'Gagal to decrypt attachment';

  @override
  String get mention_fallback_label => 'Anggota';

  @override
  String get mention_fallback_label_capitalized => 'Anggota';

  @override
  String get meeting_speaking_label => 'Berbicara';

  @override
  String meeting_local_you_suffix(String name) {
    return '$name (Anda)';
  }

  @override
  String get video_crop_title => 'Tanaman';

  @override
  String video_crop_load_error(String error) {
    return 'Gagal to load Video: $error';
  }

  @override
  String get gif_section_recent => 'TERKINI';

  @override
  String get gif_section_trending => 'TREN';

  @override
  String get auth_create_account_title => 'Buat Akun';

  @override
  String yandex_sign_in_yandex_error(String error) {
    return 'Yandex: $error';
  }

  @override
  String get call_status_missed => 'Dirindukan';

  @override
  String get call_status_cancelled => 'Dibatalkan';

  @override
  String get call_status_ended => 'Berakhir';

  @override
  String get presence_offline => 'Luring';

  @override
  String get presence_online => 'Daring';

  @override
  String get dm_title_fallback => 'Obrolan';

  @override
  String get dm_title_partner_fallback => 'Kontak';

  @override
  String get group_title_fallback => 'Obrolan grup';

  @override
  String get block_call_viewer_blocked =>
      'Anda Diblokir this Pengguna. Panggilan unavailable — Buka blokir in Profil → Diblokir.';

  @override
  String get block_call_partner_blocked =>
      'This Pengguna restricted communication with Anda. Panggilan unavailable.';

  @override
  String get block_call_unavailable => 'Panggilan unavailable.';

  @override
  String get block_composer_viewer_blocked =>
      'Anda Diblokir this Pengguna. Sending unavailable — Buka blokir in Profil → Diblokir.';

  @override
  String get block_composer_partner_blocked =>
      'This Pengguna restricted communication with Anda. Sending unavailable.';

  @override
  String get forward_group_fallback => 'Grup';

  @override
  String get forward_unknown_user => 'Tidak dikenal';

  @override
  String get live_location_once => 'One-time (this Pesan only)';

  @override
  String get live_location_5min => '5 menit';

  @override
  String get live_location_15min => '15 menit';

  @override
  String get live_location_30min => '30 menit';

  @override
  String get live_location_1hour => '1 jam';

  @override
  String get live_location_2hours => '2 jam';

  @override
  String get live_location_6hours => '6 jam';

  @override
  String get live_location_1day => '1 hari';

  @override
  String get live_location_forever => 'Selamanya (sampai saya mematikannya)';

  @override
  String get e2ee_send_too_many_files =>
      'Too many attachments for encrypted Kirim: maksimum 5 Berkas per Pesan.';

  @override
  String get e2ee_send_too_large =>
      'Total attachment size too large: maksimum 96 MB for one encrypted Pesan.';

  @override
  String get presence_last_seen_prefix => 'Terakhir dilihat ';

  @override
  String get presence_less_than_minute_ago =>
      'Lebih sedikit than a menit yang lalu';

  @override
  String get presence_yesterday => 'Kemarin';

  @override
  String get dm_fallback_title => 'Obrolan';

  @override
  String get dm_fallback_partner => 'Kontak';

  @override
  String get group_fallback_title => 'Obrolan grup';

  @override
  String get block_send_viewer_blocked =>
      'Anda Diblokir this Pengguna. Sending unavailable — Buka blokir in Profil → Diblokir.';

  @override
  String get block_send_partner_blocked =>
      'This Pengguna restricted communication with Anda. Sending unavailable.';

  @override
  String get mention_fallback_name => 'Anggota';

  @override
  String get profile_conflict_phone =>
      'This Nomor telepon adalah already registered. Silakan use a different number.';

  @override
  String get profile_conflict_email =>
      'This Email adalah already taken. Silakan use a different address.';

  @override
  String get profile_conflict_username =>
      'This Nama pengguna adalah already taken. Silakan Pilih a different one.';

  @override
  String get mention_fallback_participant => 'Peserta';

  @override
  String get sticker_gif_recent => 'TERKINI';

  @override
  String get meeting_screen_sharing => 'Layar';

  @override
  String get meeting_speaking => 'Berbicara';

  @override
  String auth_sign_in_failed(Object error) {
    return 'Sign-in Gagal: $error';
  }

  @override
  String yandex_error_prefix(Object error) {
    return 'Yandex: $error';
  }

  @override
  String auth_error_prefix(Object error) {
    return 'Auth Kesalahan: $error';
  }

  @override
  String presence_minutes_ago(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count menit yang lalu',
      one: 'a minute ago',
    );
    return '$_temp0';
  }

  @override
  String presence_hours_ago(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jam yang lalu',
      one: 'an hour ago',
    );
    return '$_temp0';
  }

  @override
  String presence_days_ago(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hari yang lalu',
      one: 'a day ago',
    );
    return '$_temp0';
  }

  @override
  String presence_months_ago(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bulan yang lalu',
      one: 'a month ago',
    );
    return '$_temp0';
  }

  @override
  String presence_years_months_ago(int years, int months) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years tahun',
      one: '1 year',
    );
    String _temp1 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$months bulan yang lalu',
      one: '1 month ago',
    );
    return '$_temp0 $_temp1';
  }

  @override
  String presence_years_ago(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tahun yang lalu',
      one: 'a year ago',
    );
    return '$_temp0';
  }

  @override
  String get wallpaper_gradient_purple => 'Ungu';

  @override
  String get wallpaper_gradient_pink => 'Berwarna merah muda';

  @override
  String get wallpaper_gradient_blue => 'Biru';

  @override
  String get wallpaper_gradient_green => 'Hijau';

  @override
  String get wallpaper_gradient_sunset => 'Matahari terbenam';

  @override
  String get wallpaper_gradient_gentle => 'Lembut';

  @override
  String get wallpaper_gradient_lime => 'Kapur';

  @override
  String get wallpaper_gradient_graphite => 'Grafit';

  @override
  String get sticker_tab_recent => 'TERKINI';

  @override
  String get block_call_you_blocked =>
      'Anda Diblokir this Pengguna. Panggilan unavailable — Buka blokir in Profil → Diblokir.';

  @override
  String get block_call_they_blocked =>
      'This Pengguna restricted communication with Anda. Panggilan unavailable.';

  @override
  String get block_call_generic => 'Panggilan unavailable.';

  @override
  String get block_send_you_blocked =>
      'Anda Diblokir this Pengguna. Sending unavailable — Buka blokir in Profil → Diblokir.';

  @override
  String get block_send_they_blocked =>
      'This Pengguna restricted communication with Anda. Sending unavailable.';

  @override
  String get forward_unknown_fallback => 'Tidak dikenal';

  @override
  String get dm_title_chat => 'Obrolan';

  @override
  String get dm_title_partner => 'Mitra';

  @override
  String get dm_title_group => 'Obrolan grup';

  @override
  String get e2ee_too_many_attachments =>
      'Too many attachments for encrypted sending: maksimum 5 Berkas per Pesan.';

  @override
  String get e2ee_total_size_exceeded =>
      'Total attachment size too large: maksimum 96 MB per encrypted Pesan.';

  @override
  String composer_limit_too_many_files(int current, int max, int diff) {
    return 'Terlalu banyak lampiran: $current/$max. Hapus $diff untuk mengirim.';
  }

  @override
  String composer_limit_total_size_exceeded(String currentMb, String maxMb) {
    return 'Lampiran terlalu besar: $currentMb MB / $maxMb MB. Hapus sebagian untuk mengirim.';
  }

  @override
  String get composer_limit_blocking_send => 'Batas lampiran terlampaui';

  @override
  String yandex_sign_in_error_prefix(String error) {
    return 'Yandex: $error';
  }

  @override
  String get meeting_participant_screen => 'Layar';

  @override
  String get meeting_participant_speaking => 'Berbicara';

  @override
  String get nav_error_title => 'Navigation Kesalahan';

  @override
  String get nav_error_invalid_secret_compose =>
      'Navigasi penulisan rahasia tidak valid';

  @override
  String get sign_in_title => 'Masuk';

  @override
  String get sign_in_firebase_ready =>
      'Firebase initialized. Anda dapat Masuk.';

  @override
  String get sign_in_firebase_not_ready =>
      'Firebase adalah not ready. Check logs dan firebase_options.dart.';

  @override
  String get sign_in_continue => 'Lanjutkan';

  @override
  String get sign_in_anonymously => 'Masuk anonymously';

  @override
  String sign_in_auth_error(String error) {
    return 'Auth Kesalahan: $error';
  }

  @override
  String generic_error(String error) {
    return 'Kesalahan: $error';
  }

  @override
  String get storage_label_video => 'Video';

  @override
  String get storage_label_photo => 'Foto';

  @override
  String get storage_label_audio => 'Audio';

  @override
  String get storage_label_files => 'Berkas';

  @override
  String get storage_label_other => 'Lainnya';

  @override
  String get storage_label_recent_stickers => 'Stiker terbaru';

  @override
  String get storage_label_giphy_search => 'GIPHY · cache pencarian';

  @override
  String get storage_label_giphy_recent => 'GIPHY · GIF terbaru';

  @override
  String get storage_chat_unattributed => 'Tidak terkait dengan chat';

  @override
  String storage_label_draft(String key) {
    return 'Draf · $key';
  }

  @override
  String get storage_label_offline_snapshot => 'Luring Obrolan list snapshot';

  @override
  String storage_label_profile_cache(String name) {
    return 'Profil cache · $name';
  }

  @override
  String get call_mini_end => 'Akhiri panggilan';

  @override
  String get animation_quality_lite => 'ringan';

  @override
  String get animation_quality_balanced => 'Seimbang';

  @override
  String get animation_quality_cinematic => 'Sinematik';

  @override
  String get crop_aspect_original => 'Asli';

  @override
  String get crop_aspect_square => 'Persegi';

  @override
  String get push_notification_title => 'Allow Notifikasi';

  @override
  String get push_notification_rationale =>
      ' app needs Notifikasi for incoming Panggilan.';

  @override
  String get push_notification_required =>
      'Aktifkan Notifikasi to display incoming Panggilan.';

  @override
  String get push_notification_grant => 'Mengizinkan';

  @override
  String get push_call_accept => 'Terima';

  @override
  String get push_call_decline => 'Tolak';

  @override
  String get push_channel_incoming_calls => 'Incoming Panggilan';

  @override
  String get push_channel_missed_calls => 'Missed Panggilan';

  @override
  String get push_channel_messages_desc => 'Baru Pesan in Obrolan';

  @override
  String get push_channel_silent => 'Silent Pesan';

  @override
  String get push_channel_silent_desc => 'Dorong tanpa suara';

  @override
  String get push_caller_unknown => 'Seseorang';

  @override
  String get outbox_attachment_single => 'Lampiran';

  @override
  String outbox_attachment_count(int count) {
    return 'Lampiran ($count)';
  }

  @override
  String get bottom_nav_label_chats => 'Obrolan';

  @override
  String get bottom_nav_label_contacts => 'Kontak';

  @override
  String get bottom_nav_label_conferences => 'Konferensi';

  @override
  String get bottom_nav_label_calls => 'Panggilan';

  @override
  String get welcomeBubbleTitle => 'Selamat datang di LighChat';

  @override
  String get welcomeBubbleSubtitle => ' lighthouse adalah lit';

  @override
  String get welcomeSkip => 'Lewati';

  @override
  String get welcomeReplayDebugTile =>
      'Putar ulang animasi selamat datang (debug)';

  @override
  String get sticker_scope_library => 'Perpustakaan';

  @override
  String get sticker_library_search_hint => 'Cari Stiker...';

  @override
  String get account_menu_energy_saving => 'Hemat daya';

  @override
  String get energy_saving_title => 'Hemat daya';

  @override
  String get energy_saving_section_mode => 'Modus hemat daya';

  @override
  String get energy_saving_section_resource_heavy =>
      'Proses yang membutuhkan banyak sumber daya';

  @override
  String get energy_saving_threshold_off => 'Mati';

  @override
  String get energy_saving_threshold_always => 'Pada';

  @override
  String get energy_saving_threshold_off_full => 'Tidak pernah';

  @override
  String get energy_saving_threshold_always_full => 'Selalu';

  @override
  String energy_saving_threshold_at(int percent) {
    return 'When battery adalah below $percent%';
  }

  @override
  String get energy_saving_hint_off =>
      'Resource-heavy effects adalah tidak pernah auto-disabled.';

  @override
  String get energy_saving_hint_always =>
      'Resource-heavy effects adalah selalu disabled regardless dari battery level.';

  @override
  String energy_saving_hint_threshold(int percent) {
    return 'Automatically Nonaktifkan Semua resource-heavy processes when battery drops below $percent%.';
  }

  @override
  String energy_saving_current_battery(int percent) {
    return 'Baterai saat ini: $percent%';
  }

  @override
  String get energy_saving_active_now => 'mode adalah Aktif';

  @override
  String get energy_saving_active_threshold =>
      'Battery has reached  threshold — every effect below adalah temporarily disabled.';

  @override
  String get energy_saving_active_system =>
      'Sistem power saving adalah on — every effect below adalah temporarily disabled.';

  @override
  String get energy_saving_autoplay_video_title => 'Autoplay Video';

  @override
  String get energy_saving_autoplay_video_subtitle =>
      'Autoplay dan loop Video Pesan dan Video in Obrolan.';

  @override
  String get energy_saving_autoplay_gif_title => 'Putar otomatis GIF';

  @override
  String get energy_saving_autoplay_gif_subtitle =>
      'Autoplay dan loop GIFs in Obrolan dan on  keyboard.';

  @override
  String get energy_saving_animated_stickers_title => 'Animated Stiker';

  @override
  String get energy_saving_animated_stickers_subtitle =>
      'Looped Stiker animations dan full-screen Premium Stiker effects.';

  @override
  String get energy_saving_animated_emoji_title => 'Animated Emoji';

  @override
  String get energy_saving_animated_emoji_subtitle =>
      'Looped Emoji animation in Pesan, reactions dan statuses.';

  @override
  String get energy_saving_interface_animations_title => 'Animasi antarmuka';

  @override
  String get energy_saving_interface_animations_subtitle =>
      'Effects dan animations that make LighChat smoother dan Lainnya expressive.';

  @override
  String get energy_saving_media_preload_title => 'Pramuat media';

  @override
  String get energy_saving_media_preload_subtitle =>
      'Mulai downloading Media Berkas when opening  Obrolan list.';

  @override
  String get energy_saving_background_update_title => 'Latar belakang Perbarui';

  @override
  String get energy_saving_background_update_subtitle =>
      'Quick Obrolan updates when switching between apps.';

  @override
  String get legal_index_title => 'Dokumen hukum';

  @override
  String get legal_index_subtitle =>
      'Kebijakan privasi, syarat layanan, dan dokumen hukum lain yang mengatur penggunaan LighChat.';

  @override
  String get legal_settings_section_title => 'Informasi hukum';

  @override
  String get legal_settings_section_subtitle =>
      'Kebijakan privasi, syarat layanan, EULA, dan lainnya.';

  @override
  String get legal_not_found => 'Dokumen tidak ditemukan';

  @override
  String get legal_title_privacy_policy => 'Kebijakan Privasi';

  @override
  String get legal_title_terms_of_service => 'Ketentuan Layanan';

  @override
  String get legal_title_cookie_policy => 'Kebijakan Cookie';

  @override
  String get legal_title_eula => 'Perjanjian Lisensi Pengguna Akhir';

  @override
  String get legal_title_dpa => 'Perjanjian Pemrosesan Data';

  @override
  String get legal_title_children => 'Kebijakan Anak';

  @override
  String get legal_title_moderation => 'Kebijakan Moderasi Konten';

  @override
  String get legal_title_aup => 'Kebijakan Penggunaan yang Dapat Diterima';

  @override
  String get chat_list_item_sender_you => 'Anda';

  @override
  String get chat_preview_message => 'Pesan';

  @override
  String get chat_preview_sticker => 'Stiker';

  @override
  String get chat_preview_attachment => 'Lampiran';

  @override
  String get contacts_disclosure_title => 'Temukan teman di LighChat';

  @override
  String get contacts_disclosure_body =>
      'LighChat membaca nomor telepon dan alamat email dari buku alamat Anda, mem-hash-nya, dan memeriksanya dengan server kami untuk menampilkan kontak mana yang sudah menggunakan aplikasi ini. Kontak Anda tidak pernah disimpan di server kami.';

  @override
  String get contacts_disclosure_allow => 'Izinkan';

  @override
  String get contacts_disclosure_deny => 'Tidak sekarang';

  @override
  String get report_title => 'Laporkan';

  @override
  String get report_subtitle_message => 'Laporkan pesan';

  @override
  String get report_subtitle_user => 'Laporkan pengguna';

  @override
  String get report_reason_spam => 'Spam';

  @override
  String get report_reason_offensive => 'Konten menyinggung';

  @override
  String get report_reason_violence => 'Kekerasan atau ancaman';

  @override
  String get report_reason_fraud => 'Penipuan';

  @override
  String get report_reason_other => 'Lainnya';

  @override
  String get report_comment_hint => 'Detail tambahan (opsional)';

  @override
  String get report_submit => 'Kirim';

  @override
  String get report_success => 'Laporan terkirim. Terima kasih!';

  @override
  String get report_error => 'Gagal mengirim laporan';

  @override
  String get message_menu_action_report => 'Laporkan';

  @override
  String get partner_profile_menu_report => 'Laporkan pengguna';

  @override
  String get call_bubble_voice_call => 'Panggilan suara';

  @override
  String get call_bubble_video_call => 'Panggilan video';

  @override
  String get chat_preview_poll => 'Jajak pendapat';

  @override
  String get chat_preview_forwarded => 'Pesan diteruskan';

  @override
  String get birthday_banner_celebrates => 'sedang berulang tahun!';

  @override
  String get birthday_banner_action => 'Ucapkan →';

  @override
  String get birthday_screen_title_today => 'Ulang tahun hari ini';

  @override
  String birthday_screen_age(int age) {
    return 'Berusia $age';
  }

  @override
  String get birthday_section_actions => 'UCAPKAN';

  @override
  String get birthday_action_template => 'Pesan cepat';

  @override
  String get birthday_action_cake => 'Tiup lilin';

  @override
  String get birthday_action_confetti => 'Konfeti';

  @override
  String get birthday_action_serpentine => 'Serpentin';

  @override
  String get birthday_action_voice => 'Rekam ucapan suara';

  @override
  String get birthday_action_remind_next_year => 'Ingatkan saya tahun depan';

  @override
  String get birthday_action_open_chat => 'Tulis ucapanmu sendiri';

  @override
  String get birthday_cake_prompt => 'Ketuk lilin untuk meniupnya';

  @override
  String birthday_cake_wish_placeholder(Object name) {
    return 'Apa harapanmu untuk $name?';
  }

  @override
  String get birthday_cake_wish_hint => 'Misal: semoga semua impian tercapai…';

  @override
  String get birthday_cake_send => 'Kirim';

  @override
  String birthday_cake_message(Object name, Object wish) {
    return '🎂 Selamat ulang tahun, $name! Harapanku: «$wish»';
  }

  @override
  String birthday_confetti_message(Object name) {
    return '🎉 Selamat ulang tahun, $name! 🎉';
  }

  @override
  String birthday_template_1(Object name) {
    return 'Selamat ulang tahun, $name! Semoga tahun ini yang terbaik!';
  }

  @override
  String birthday_template_2(Object name) {
    return '$name, selamat! Semoga kebahagiaan dan harapanmu terwujud 🎉';
  }

  @override
  String birthday_template_3(Object name) {
    return 'Selamat ulang tahun, $name! Sehat, beruntung dan banyak momen bahagia 🎂';
  }

  @override
  String birthday_template_4(Object name) {
    return '$name, selamat ulang tahun! Semoga semua rencanamu lancar ✨';
  }

  @override
  String birthday_template_5(Object name) {
    return 'Selamat, $name! Terima kasih sudah ada. Selamat ulang tahun! 🎁';
  }

  @override
  String get birthday_toast_sent => 'Ucapan terkirim';

  @override
  String birthday_reminder_set(Object name) {
    return 'Kami akan mengingatkan sehari sebelum ulang tahun $name';
  }

  @override
  String get birthday_reminder_notif_title => 'Besok ulang tahun 🎂';

  @override
  String birthday_reminder_notif_body(Object name) {
    return 'Jangan lupa beri selamat ke $name besok';
  }

  @override
  String get birthday_empty => 'Tidak ada ulang tahun kontak hari ini';

  @override
  String get birthday_error_self => 'Tidak bisa memuat profilmu';

  @override
  String get birthday_error_send => 'Gagal mengirim ucapan. Coba lagi.';

  @override
  String get birthday_error_reminder => 'Gagal mengatur pengingat';

  @override
  String get chat_empty_title => 'Belum ada pesan';

  @override
  String get chat_empty_subtitle =>
      'Sapa dulu — penjaga mercusuar sudah melambai';

  @override
  String get chat_empty_quick_greet => 'Sapa 👋';
}
