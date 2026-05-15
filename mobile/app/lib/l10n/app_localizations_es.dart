// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get secret_chat_title => 'Chat secreto';

  @override
  String get secret_chats_title => 'Chats secretos';

  @override
  String get secret_chat_locked_title => 'El chat secreto está bloqueado';

  @override
  String get secret_chat_locked_subtitle =>
      'Ingresa tu PIN para desbloquear y ver los mensajes.';

  @override
  String get secret_chat_unlock_title => 'Desbloquear chat secreto';

  @override
  String get secret_chat_unlock_subtitle =>
      'Se requiere PIN para abrir este chat.';

  @override
  String get secret_chat_unlock_action => 'Desbloquear';

  @override
  String get secret_chat_set_pin_and_unlock => 'Establecer PIN y desbloquear';

  @override
  String get secret_chat_pin_label => 'PIN (4 dígitos)';

  @override
  String get secret_chat_pin_invalid => 'Ingresa un PIN de 4 dígitos';

  @override
  String get secret_chat_already_exists =>
      'Ya existe un chat secreto con este usuario.';

  @override
  String get secret_chat_exists_badge => 'Creado';

  @override
  String get secret_chat_unlock_failed =>
      'No se pudo desbloquear. Intenta de nuevo.';

  @override
  String get secret_chat_action_not_allowed =>
      'Esta acción no está permitida en un chat secreto';

  @override
  String get secret_chat_remember_pin => 'Recordar PIN en este dispositivo';

  @override
  String get secret_chat_unlock_biometric => 'Desbloquear con biometría';

  @override
  String get secret_chat_biometric_reason => 'Desbloquear chat secreto';

  @override
  String get secret_chat_biometric_no_saved_pin =>
      'Ingresa el PIN una vez para habilitar el desbloqueo biométrico';

  @override
  String get secret_chat_ttl_title => 'Duración del chat secreto';

  @override
  String get secret_chat_settings_title => 'Configuración del chat secreto';

  @override
  String get secret_chat_settings_subtitle =>
      'Duración, acceso y restricciones';

  @override
  String get secret_chat_settings_not_secret =>
      'Este chat no es un chat secreto';

  @override
  String get secret_chat_settings_ttl => 'Duración';

  @override
  String secret_chat_settings_time_left(Object value) {
    return 'Tiempo restante: $value';
  }

  @override
  String secret_chat_settings_expires_at(Object iso) {
    return 'Expira el: $iso';
  }

  @override
  String get secret_chat_settings_unlock_grant_ttl => 'Duración del desbloqueo';

  @override
  String get secret_chat_settings_unlock_grant_ttl_subtitle =>
      'Cuánto tiempo permanece activo el acceso después de desbloquear';

  @override
  String get secret_chat_settings_no_copy => 'Desactivar copiado';

  @override
  String get secret_chat_settings_no_forward => 'Desactivar reenvío';

  @override
  String get secret_chat_settings_no_save =>
      'Desactivar guardado de multimedia';

  @override
  String get secret_chat_settings_screenshot_protection =>
      'Protección contra capturas de pantalla (Android)';

  @override
  String get secret_chat_settings_media_views =>
      'Límites de visualización de multimedia';

  @override
  String get secret_chat_settings_media_views_subtitle =>
      'Límites aproximados de visualizaciones del destinatario';

  @override
  String get secret_chat_media_type_image => 'Imágenes';

  @override
  String get secret_chat_media_type_video => 'Vídeos';

  @override
  String get secret_chat_media_type_voice => 'Mensajes de voz';

  @override
  String get secret_chat_media_type_location => 'Ubicación';

  @override
  String get secret_chat_media_type_file => 'Archivos';

  @override
  String get secret_chat_media_views_unlimited => 'Ilimitado';

  @override
  String get secret_chat_compose_create => 'Crear chat secreto';

  @override
  String get secret_chat_compose_vault_pin_subtitle =>
      'Opcional: establece un PIN de 4 dígitos para desbloquear la bandeja secreta (almacenado en este dispositivo para biometría cuando está habilitado).';

  @override
  String get secret_chat_compose_require_unlock_pin =>
      'Requerir PIN para abrir este chat';

  @override
  String get secret_chat_settings_read_only_hint =>
      'Estos ajustes se fijan al crear y no se pueden cambiar.';

  @override
  String get secret_chat_settings_delete => 'Eliminar chat secreto';

  @override
  String get secret_chat_settings_delete_confirm_title =>
      '¿Eliminar este chat secreto?';

  @override
  String get secret_chat_settings_delete_confirm_body =>
      'Los mensajes y multimedia se eliminarán para ambos participantes.';

  @override
  String get privacy_secret_vault_title => 'Bóveda secreta';

  @override
  String get privacy_secret_vault_subtitle =>
      'PIN global y verificación biométrica para acceder a los chats secretos.';

  @override
  String get privacy_secret_vault_change_pin =>
      'Establecer o cambiar PIN de bóveda';

  @override
  String get privacy_secret_vault_change_pin_subtitle =>
      'Si ya existe un PIN, confírmalo usando el PIN anterior o biometría.';

  @override
  String get privacy_secret_vault_bio_subtitle =>
      'Ejecutar verificación biométrica y validar el PIN local guardado.';

  @override
  String get privacy_secret_vault_bio_reason =>
      'Confirmar acceso a los chats secretos';

  @override
  String get privacy_secret_vault_current_pin => 'PIN actual';

  @override
  String get privacy_secret_vault_new_pin => 'Nuevo PIN';

  @override
  String get privacy_secret_vault_repeat_pin => 'Repetir nuevo PIN';

  @override
  String get privacy_secret_vault_pin_mismatch => 'Los PINs no coinciden';

  @override
  String get privacy_secret_vault_pin_updated => 'PIN de bóveda actualizado';

  @override
  String get privacy_secret_vault_bio_unavailable =>
      'La autenticación biométrica no está disponible en este dispositivo';

  @override
  String get privacy_secret_vault_bio_verified =>
      'Verificación biométrica exitosa';

  @override
  String get privacy_secret_vault_setup_required =>
      'Configura primero el PIN o el acceso biométrico en Privacidad.';

  @override
  String get privacy_secret_vault_network_timeout =>
      'Tiempo de espera agotado. Intenta de nuevo.';

  @override
  String privacy_secret_vault_error(Object error) {
    return 'Error de bóveda secreta: $error';
  }

  @override
  String get tournament_title => 'Torneo';

  @override
  String get tournament_subtitle => 'Clasificación y series de juegos';

  @override
  String get tournament_new_game => 'Nuevo juego';

  @override
  String get tournament_standings => 'Clasificación';

  @override
  String get tournament_standings_empty => 'Sin resultados aún';

  @override
  String get tournament_games => 'Juegos';

  @override
  String get tournament_games_empty => 'Sin juegos aún';

  @override
  String tournament_points(Object pts) {
    return '$pts puntos';
  }

  @override
  String tournament_games_played(Object n) {
    return '$n juegos';
  }

  @override
  String tournament_create_failed(Object err) {
    return 'No se pudo crear el torneo: $err';
  }

  @override
  String tournament_create_game_failed(Object err) {
    return 'No se pudo crear el juego: $err';
  }

  @override
  String tournament_game_players(Object names) {
    return 'Jugadores: $names';
  }

  @override
  String get tournament_game_result_draw => 'Resultado: empate';

  @override
  String tournament_game_result_loser(Object name) {
    return 'Resultado: durak — $name';
  }

  @override
  String tournament_game_place(Object place) {
    return 'Lugar $place';
  }

  @override
  String get durak_dm_lobby_banner =>
      'Tu compañero creó una sala de Durak — únete';

  @override
  String get durak_dm_lobby_open => 'Abrir sala';

  @override
  String get conversation_game_lobby_cancel => 'Terminar espera';

  @override
  String conversation_game_lobby_cancel_failed(Object err) {
    return 'No se pudo terminar la espera: $err';
  }

  @override
  String secret_chat_media_views_count(Object count) {
    return '$count visualizaciones';
  }

  @override
  String secret_chat_settings_load_failed(Object error) {
    return 'Error al cargar: $error';
  }

  @override
  String secret_chat_settings_save_failed(Object error) {
    return 'Error al guardar: $error';
  }

  @override
  String get secret_chat_settings_reset_strict =>
      'Restablecer valores estrictos predeterminados';

  @override
  String get secret_chat_settings_reset_strict_subtitle =>
      'Activa todas las restricciones y establece el límite de visualización a 1';

  @override
  String get settings_language_title => 'Idioma';

  @override
  String get settings_language_system => 'Sistema';

  @override
  String get settings_language_ru => 'Ruso';

  @override
  String get settings_language_en => 'Inglés';

  @override
  String get settings_language_hint_system =>
      'Cuando se selecciona “Sistema”, la app sigue la configuración de idioma de tu dispositivo.';

  @override
  String get account_menu_profile => 'Perfil';

  @override
  String get account_menu_features => 'Funciones';

  @override
  String get account_menu_chat_settings => 'Configuración del chat';

  @override
  String get account_menu_notifications => 'Notificaciones';

  @override
  String get account_menu_privacy => 'Privacidad';

  @override
  String get account_menu_devices => 'Dispositivos';

  @override
  String get account_menu_blacklist => 'Lista de bloqueados';

  @override
  String get account_menu_language => 'Idioma';

  @override
  String get account_menu_storage => 'Almacenamiento';

  @override
  String get account_menu_theme => 'Tema';

  @override
  String get account_menu_sign_out => 'Cerrar sesión';

  @override
  String get storage_settings_title => 'Almacenamiento';

  @override
  String get storage_settings_subtitle =>
      'Controla qué datos se almacenan en caché en este dispositivo y limpia por chats o archivos.';

  @override
  String get storage_settings_total_label => 'Usado en este dispositivo';

  @override
  String storage_settings_budget_label(Object gb) {
    return 'Límite de caché: $gb GB';
  }

  @override
  String get storage_unit_gb => 'ES';

  @override
  String get storage_settings_clear_all_button => 'Borrar toda la caché';

  @override
  String get storage_settings_trim_button => 'Ajustar al límite';

  @override
  String get storage_settings_policy_title => 'Qué mantener localmente';

  @override
  String get storage_settings_budget_slider_title => 'Presupuesto de caché';

  @override
  String get storage_settings_breakdown_title => 'Por tipo de datos';

  @override
  String get storage_settings_breakdown_empty =>
      'No hay datos en caché local aún.';

  @override
  String get storage_settings_chats_title => 'Por chats';

  @override
  String get storage_settings_chats_empty =>
      'No hay caché específica de chat aún.';

  @override
  String storage_settings_chat_subtitle(Object count, Object size) {
    return '$count elementos · $size';
  }

  @override
  String get storage_settings_general_title => 'Caché no asignada';

  @override
  String get storage_settings_general_hint =>
      'Entradas no vinculadas a un chat específico (caché global/heredada).';

  @override
  String get storage_settings_general_empty =>
      'No hay entradas de caché compartidas.';

  @override
  String get storage_settings_chat_files_empty =>
      'No hay archivos locales en la caché de este chat.';

  @override
  String get storage_settings_clear_chat_action => 'Borrar caché del chat';

  @override
  String get storage_settings_clear_all_title => '¿Borrar caché local?';

  @override
  String get storage_settings_clear_all_body =>
      'Esto eliminará archivos en caché, vistas previas, borradores y copias sin conexión de este dispositivo.';

  @override
  String storage_settings_clear_chat_title(Object chat) {
    return 'Borrar caché de “$chat”?';
  }

  @override
  String get storage_settings_clear_chat_body =>
      'Solo se eliminará la caché de este chat. Los mensajes en la nube permanecen intactos.';

  @override
  String get storage_settings_snackbar_cleared => 'Caché local borrada';

  @override
  String get storage_settings_snackbar_budget_already_ok =>
      'La caché ya cumple con el presupuesto objetivo';

  @override
  String storage_settings_snackbar_budget_trimmed(Object size) {
    return 'Liberado: $size';
  }

  @override
  String get storage_settings_error_empty =>
      'No se pudieron generar las estadísticas de almacenamiento';

  @override
  String get storage_category_e2ee_media => 'Caché de multimedia E2EE';

  @override
  String get storage_category_e2ee_media_subtitle =>
      'Archivos multimedia secretos descifrados por chat para una reapertura más rápida.';

  @override
  String get storage_category_e2ee_text => 'Caché de texto E2EE';

  @override
  String get storage_category_e2ee_text_subtitle =>
      'Fragmentos de texto descifrados por chat para renderizado instantáneo.';

  @override
  String get storage_category_drafts => 'Borradores de mensajes';

  @override
  String get storage_category_drafts_subtitle =>
      'Texto de borradores no enviados por chat.';

  @override
  String get storage_category_chat_list_snapshot =>
      'Lista de chats sin conexión';

  @override
  String get storage_category_chat_list_snapshot_subtitle =>
      'Captura reciente de la lista de chats para inicio rápido sin conexión.';

  @override
  String get storage_category_profile_cards => 'Mini-caché de perfil';

  @override
  String get storage_category_profile_cards_subtitle =>
      'Nombres y avatares guardados para una interfaz más rápida.';

  @override
  String get storage_category_video_downloads => 'Caché de videos descargados';

  @override
  String get storage_category_video_downloads_subtitle =>
      'Videos descargados localmente desde vistas de galería.';

  @override
  String get storage_category_video_thumbs =>
      'Fotogramas de vista previa de video';

  @override
  String get storage_category_video_thumbs_subtitle =>
      'Miniaturas del primer fotograma generadas para videos.';

  @override
  String get storage_category_chat_images => 'Fotos del chat';

  @override
  String get storage_category_chat_images_subtitle =>
      'Fotos y stickers en caché de chats abiertos.';

  @override
  String get storage_category_stickers_gifs_emoji => 'Stickers, GIF y emoji';

  @override
  String get storage_category_stickers_gifs_emoji_subtitle =>
      'Caché de stickers recientes y de GIPHY (gif/stickers/emoji animados).';

  @override
  String get storage_category_network_images => 'Caché de imágenes de red';

  @override
  String get storage_category_network_images_subtitle =>
      'Avatares, vistas previas y otras imágenes obtenidas por red (libCachedImageData).';

  @override
  String get storage_media_type_video => 'Video';

  @override
  String get storage_media_type_photo => 'Fotos';

  @override
  String get storage_media_type_audio => 'Audio';

  @override
  String get storage_media_type_files => 'Archivos';

  @override
  String get storage_media_type_other => 'Otros';

  @override
  String storage_settings_device_usage(Object pct) {
    return 'Usa $pct% del presupuesto de caché';
  }

  @override
  String get storage_settings_clear_all_hint =>
      'Toda la multimedia permanece en la nube. Puedes volver a descargarla en cualquier momento.';

  @override
  String get storage_settings_categories_title => 'Por categoría';

  @override
  String storage_settings_clear_category_title(String category) {
    return '¿Borrar \"$category\"?';
  }

  @override
  String storage_settings_clear_category_body(String size) {
    return 'Se liberarán aproximadamente $size. Esta acción no se puede deshacer.';
  }

  @override
  String get storage_auto_delete_title =>
      'Eliminar automáticamente multimedia en caché';

  @override
  String get storage_auto_delete_personal => 'Chats personales';

  @override
  String get storage_auto_delete_groups => 'Grupos';

  @override
  String get storage_auto_delete_never => 'Nunca';

  @override
  String get storage_auto_delete_3_days => '3 días';

  @override
  String get storage_auto_delete_1_week => '1 semana';

  @override
  String get storage_auto_delete_1_month => '1 mes';

  @override
  String get storage_auto_delete_3_months => '3 meses';

  @override
  String get storage_auto_delete_hint =>
      'Las fotos, videos y archivos que no hayas abierto durante este período se eliminarán del dispositivo para ahorrar espacio.';

  @override
  String storage_chat_detail_share(Object pct) {
    return 'Este chat usa $pct% de tu caché';
  }

  @override
  String get storage_chat_detail_media_tab => 'Multimedia';

  @override
  String get storage_chat_detail_select_all => 'Seleccionar todo';

  @override
  String get storage_chat_detail_deselect_all => 'Deseleccionar todo';

  @override
  String storage_chat_detail_clear_button(Object size) {
    return 'Borrar caché $size';
  }

  @override
  String get storage_chat_detail_clear_button_empty =>
      'Seleccionar archivos para eliminar';

  @override
  String get storage_chat_detail_tab_empty => 'Nada en esta pestaña.';

  @override
  String get storage_chat_detail_delete_title =>
      '¿Eliminar archivos seleccionados?';

  @override
  String storage_chat_detail_delete_body(Object count, Object size) {
    return '$count archivos ($size) se eliminarán del dispositivo. Las copias en la nube permanecen intactas.';
  }

  @override
  String get profile_delete_account => 'Eliminar cuenta';

  @override
  String get profile_delete_account_confirm_title =>
      '¿Eliminar tu cuenta permanentemente?';

  @override
  String get profile_delete_account_confirm_body =>
      'Tu cuenta se eliminará de Firebase Auth y todos tus documentos de Firestore se borrarán permanentemente. Tus chats seguirán visibles para otros en modo de solo lectura.';

  @override
  String get profile_delete_account_confirm_action => 'Eliminar cuenta';

  @override
  String profile_delete_account_error(Object error) {
    return 'No se pudo eliminar la cuenta: $error';
  }

  @override
  String get chat_readonly_deleted_user =>
      'Cuenta eliminada. Este chat es de solo lectura.';

  @override
  String get blacklist_empty => 'No hay usuarios bloqueados';

  @override
  String get blacklist_action_unblock => 'Desbloquear';

  @override
  String get blacklist_unblock_confirm_title => '¿Desbloquear?';

  @override
  String get blacklist_unblock_confirm_body =>
      'Este usuario podrá enviarte mensajes de nuevo (si la política de contacto lo permite) y ver tu perfil en búsqueda.';

  @override
  String get blacklist_unblock_success => 'Usuario desbloqueado';

  @override
  String blacklist_unblock_error(Object error) {
    return 'No se pudo desbloquear: $error';
  }

  @override
  String get partner_profile_block_confirm_title => '¿Bloquear a este usuario?';

  @override
  String get partner_profile_block_confirm_body =>
      'No verán un chat contigo, no podrán encontrarte en búsqueda ni agregarte a contactos. Desaparecerás de sus contactos. Conservarás el historial del chat, pero no podrás enviarles mensajes mientras estén bloqueados.';

  @override
  String get partner_profile_block_action => 'Bloquear';

  @override
  String get partner_profile_block_success => 'Usuario bloqueado';

  @override
  String partner_profile_block_error(Object error) {
    return 'No se pudo bloquear: $error';
  }

  @override
  String get common_soon => 'Próximamente';

  @override
  String common_theme_prefix(Object label) {
    return 'Tema: $label';
  }

  @override
  String common_error_cannot_save_theme(Object error) {
    return 'No se pudo guardar el tema: $error';
  }

  @override
  String common_error_cannot_sign_out(Object error) {
    return 'No se pudo cerrar sesión: $error';
  }

  @override
  String account_error_profile(Object error) {
    return 'Error de perfil: $error';
  }

  @override
  String get notifications_title => 'Notificaciones';

  @override
  String get notifications_section_main => 'Principal';

  @override
  String get notifications_mute_all_title => 'Desactivar todo';

  @override
  String get notifications_mute_all_subtitle =>
      'Desactivar todas las notificaciones.';

  @override
  String get notifications_sound_title => 'Sonido';

  @override
  String get notifications_sound_subtitle =>
      'Reproducir un sonido para nuevos mensajes.';

  @override
  String get notifications_preview_title => 'Vista previa';

  @override
  String get notifications_preview_subtitle =>
      'Mostrar texto del mensaje en las notificaciones.';

  @override
  String get notifications_message_ringtone_label => 'Tono de mensajes';

  @override
  String get notifications_call_ringtone_label => 'Tono de llamadas';

  @override
  String get notifications_meeting_hand_raise_title =>
      'Sonido de mano levantada';

  @override
  String get notifications_meeting_hand_raise_subtitle =>
      'Señal suave cuando un participante levanta la mano.';

  @override
  String get ringtone_default => 'Predeterminado';

  @override
  String get ringtone_classic_chime => 'Carillón clásico';

  @override
  String get ringtone_gentle_bells => 'Campanas suaves';

  @override
  String get ringtone_marimba_tap => 'Marimba';

  @override
  String get ringtone_soft_pulse => 'Pulso suave';

  @override
  String get ringtone_ascending_chord => 'Acorde ascendente';

  @override
  String get ringtone_storage_original => 'Original (Storage)';

  @override
  String get ringtone_preview_play => 'Escuchar';

  @override
  String get ringtone_picker_messages_title => 'Tono de mensajes';

  @override
  String get ringtone_picker_calls_title => 'Tono de llamadas';

  @override
  String get notifications_section_quiet_hours => 'Horas de silencio';

  @override
  String get notifications_quiet_hours_subtitle =>
      'Las notificaciones no te molestarán durante este período.';

  @override
  String get notifications_quiet_hours_enable_title =>
      'Activar horas de silencio';

  @override
  String get notifications_reset_button => 'Restablecer configuración';

  @override
  String notifications_error_cannot_save(Object error) {
    return 'No se pudo guardar la configuración: $error';
  }

  @override
  String notifications_error_load(Object error) {
    return 'No se pudieron cargar las notificaciones: $error';
  }

  @override
  String get privacy_title => 'Privacidad del chat';

  @override
  String privacy_error_cannot_save(Object error) {
    return 'No se pudo guardar la configuración: $error';
  }

  @override
  String privacy_error_load(Object error) {
    return 'No se pudo cargar la configuración de privacidad: $error';
  }

  @override
  String get privacy_e2ee_section => 'Cifrado de extremo a extremo';

  @override
  String get privacy_e2ee_enable_for_all_chats =>
      'Activar E2EE para todos los chats';

  @override
  String get privacy_e2ee_what_encrypt => 'Qué se cifra en los chats E2EE';

  @override
  String get privacy_e2ee_text => 'Texto del mensaje';

  @override
  String get privacy_e2ee_media => 'Adjuntos (multimedia/archivos)';

  @override
  String get privacy_my_devices_title => 'Mis dispositivos';

  @override
  String get privacy_my_devices_subtitle =>
      'Dispositivos con claves publicadas. Renombra o revoca el acceso.';

  @override
  String get privacy_key_backup_title => 'Respaldo y transferencia de claves';

  @override
  String get privacy_key_backup_subtitle =>
      'Crea un respaldo con contraseña o transfiere la clave por QR.';

  @override
  String get privacy_visibility_section => 'Visibilidad';

  @override
  String get privacy_online_title => 'Estado en línea';

  @override
  String get privacy_online_subtitle =>
      'Permitir que otros vean cuando estás en línea.';

  @override
  String get privacy_last_seen_title => 'Última vez';

  @override
  String get privacy_last_seen_subtitle =>
      'Mostrar tu última hora de actividad.';

  @override
  String get privacy_read_receipts_title => 'Confirmaciones de lectura';

  @override
  String get privacy_read_receipts_subtitle =>
      'Permitir que los remitentes sepan que leíste un mensaje.';

  @override
  String get privacy_group_invites_section => 'Invitaciones a grupos';

  @override
  String get privacy_group_invites_subtitle =>
      'Quién puede agregarte a chats grupales.';

  @override
  String get privacy_group_invites_everyone => 'Todos';

  @override
  String get privacy_group_invites_contacts => 'Solo contactos';

  @override
  String get privacy_group_invites_nobody => 'Nadie';

  @override
  String get privacy_global_search_section => 'Visibilidad en búsqueda';

  @override
  String get privacy_global_search_subtitle =>
      'Quién puede encontrarte por nombre entre todos los usuarios.';

  @override
  String get privacy_global_search_title => 'Búsqueda global';

  @override
  String get privacy_global_search_hint =>
      'Si se desactiva, no aparecerás en “Todos los usuarios” cuando alguien inicie un nuevo chat. Seguirás siendo visible para quienes te agregaron como contacto.';

  @override
  String get privacy_profile_for_others_section => 'Perfil para otros';

  @override
  String get privacy_profile_for_others_subtitle =>
      'Lo que otros pueden ver en tu perfil.';

  @override
  String get privacy_email_subtitle => 'Tu correo electrónico en tu perfil.';

  @override
  String get privacy_phone_title => 'Número de teléfono';

  @override
  String get privacy_phone_subtitle => 'Visible en tu perfil y contactos.';

  @override
  String get privacy_birthdate_title => 'Fecha de nacimiento';

  @override
  String get privacy_birthdate_subtitle =>
      'Tu campo de cumpleaños en el perfil.';

  @override
  String get privacy_about_title => 'Acerca de';

  @override
  String get privacy_about_subtitle => 'Tu texto de biografía en el perfil.';

  @override
  String get privacy_reset_button => 'Restablecer configuración';

  @override
  String get common_cancel => 'Cancelar';

  @override
  String get common_create => 'Crear';

  @override
  String get common_delete => 'Eliminar';

  @override
  String get common_choose => 'Elegir';

  @override
  String get common_save => 'Guardar';

  @override
  String get common_close => 'Cerrar';

  @override
  String get common_nothing_found => 'No se encontró nada';

  @override
  String get common_retry => 'Reintentar';

  @override
  String get auth_login_email_label => 'Correo electrónico';

  @override
  String get auth_login_password_label => 'Contraseña';

  @override
  String get auth_login_password_hint => 'Contraseña';

  @override
  String get auth_login_sign_in => 'Iniciar sesión';

  @override
  String get auth_login_forgot_password => '¿Olvidaste tu contraseña?';

  @override
  String get auth_login_error_enter_email_for_reset =>
      'Ingresa tu correo para restablecer tu contraseña';

  @override
  String get profile_title => 'Perfil';

  @override
  String get profile_edit_tooltip => 'Editar';

  @override
  String get profile_full_name_label => 'Nombre completo';

  @override
  String get profile_full_name_hint => 'Nombre';

  @override
  String get profile_username_label => 'Nombre de usuario';

  @override
  String get profile_email_label => 'Correo electrónico';

  @override
  String get profile_phone_label => 'Teléfono';

  @override
  String get profile_birthdate_label => 'Fecha de nacimiento';

  @override
  String get profile_about_label => 'Acerca de';

  @override
  String get profile_about_hint => 'Una breve biografía';

  @override
  String get profile_password_toggle_show => 'Cambiar contraseña';

  @override
  String get profile_password_toggle_hide => 'Ocultar cambio de contraseña';

  @override
  String get profile_password_new_label => 'Nueva contraseña';

  @override
  String get profile_password_confirm_label => 'Confirmar contraseña';

  @override
  String get profile_password_tooltip_show => 'Mostrar contraseña';

  @override
  String get profile_password_tooltip_hide => 'Ocultar';

  @override
  String get profile_placeholder_username => 'nombre_de_usuario';

  @override
  String get profile_placeholder_email => 'nombre@ejemplo.com';

  @override
  String get profile_placeholder_phone => '+52 55 0000-0000';

  @override
  String get profile_placeholder_birthdate => 'DD.MM.AAAA';

  @override
  String get profile_placeholder_password_dots => '••••••••';

  @override
  String get profile_password_error_fill_both =>
      'Completa la nueva contraseña y la confirmación.';

  @override
  String get settings_chats_title => 'Configuración del chat';

  @override
  String get settings_chats_preview => 'Vista previa';

  @override
  String get settings_chats_outgoing => 'Mensajes enviados';

  @override
  String get settings_chats_incoming => 'Mensajes recibidos';

  @override
  String get settings_chats_font_size => 'Tamaño de texto';

  @override
  String get settings_chats_font_small => 'Pequeño';

  @override
  String get settings_chats_font_medium => 'Mediano';

  @override
  String get settings_chats_font_large => 'Grande';

  @override
  String get settings_chats_bubble_shape => 'Forma de burbuja';

  @override
  String get settings_chats_bubble_rounded => 'Redondeada';

  @override
  String get settings_chats_bubble_square => 'Cuadrada';

  @override
  String get settings_chats_chat_background => 'Fondo del chat';

  @override
  String get settings_chats_chat_background_pick_hint =>
      'Elige una foto o ajusta el fondo';

  @override
  String get settings_chats_advanced => 'Avanzado';

  @override
  String get settings_chats_show_time => 'Mostrar hora';

  @override
  String get settings_chats_show_time_subtitle =>
      'Mostrar hora del mensaje debajo de las burbujas';

  @override
  String get settings_chats_reset => 'Restablecer configuración';

  @override
  String settings_chats_error_cannot_save(Object error) {
    return 'No se pudo guardar: $error';
  }

  @override
  String settings_chats_error_wallpaper_load(Object error) {
    return 'No se pudo cargar el fondo: $error';
  }

  @override
  String settings_chats_error_wallpaper_delete(Object error) {
    return 'No se pudo eliminar el fondo: $error';
  }

  @override
  String get settings_chats_wallpaper_delete_confirm_title =>
      '¿Eliminar fondo?';

  @override
  String get settings_chats_wallpaper_delete_confirm_body =>
      'Este fondo se eliminará de tu lista.';

  @override
  String settings_chats_icon_picker_title(Object label) {
    return 'Icono: “$label”';
  }

  @override
  String get settings_chats_icon_picker_search_hint => 'Buscar por nombre…';

  @override
  String get settings_chats_icon_color => 'Color del icono';

  @override
  String get settings_chats_reset_icon_size => 'Restablecer tamaño';

  @override
  String get settings_chats_reset_icon_stroke => 'Restablecer trazo';

  @override
  String get settings_chats_tile_background => 'Mosaico de fondo';

  @override
  String get settings_chats_default_gradient => 'Degradado predeterminado';

  @override
  String get settings_chats_inherit_global => 'Usar configuración global';

  @override
  String get settings_chats_no_background => 'Sin fondo';

  @override
  String get settings_chats_no_background_on => 'Sin fondo (activado)';

  @override
  String get chat_list_title => 'Charlas';

  @override
  String get chat_list_search_hint => 'Buscar…';

  @override
  String get chat_list_loading_connecting => 'Conectando…';

  @override
  String get chat_list_loading_conversations => 'Cargando conversaciones…';

  @override
  String get chat_list_loading_list => 'Cargando lista de chats…';

  @override
  String get chat_list_loading_sign_out => 'Cerrando sesión…';

  @override
  String get chat_list_empty_search_title => 'No se encontraron chats';

  @override
  String get chat_list_empty_search_body =>
      'Intenta otra búsqueda. Funciona por nombre y nombre de usuario.';

  @override
  String get chat_list_empty_folder_title => 'Esta carpeta está vacía';

  @override
  String get chat_list_empty_folder_body =>
      'Cambia de carpeta o inicia un nuevo chat con el botón de arriba.';

  @override
  String get chat_list_empty_all_title => 'Aún no hay chats';

  @override
  String get chat_list_empty_all_body =>
      'Inicia un nuevo chat para empezar a enviar mensajes.';

  @override
  String get chat_list_action_new_folder => 'Nueva carpeta';

  @override
  String get chat_list_action_new_chat => 'Nuevo chat';

  @override
  String get chat_list_action_create => 'Crear';

  @override
  String get chat_list_action_close => 'Cerrar';

  @override
  String get chat_list_folders_title => 'Carpetas';

  @override
  String get chat_list_folders_subtitle => 'Elige carpetas para este chat.';

  @override
  String get chat_list_folders_empty => 'Aún no hay carpetas personalizadas.';

  @override
  String get chat_list_create_folder_title => 'Nueva carpeta';

  @override
  String get chat_list_create_folder_subtitle =>
      'Crea una carpeta para filtrar rápidamente tus chats.';

  @override
  String get chat_list_create_folder_name_label => 'NOMBRE DE CARPETA';

  @override
  String get chat_list_create_folder_name_hint => 'Nombre de carpeta';

  @override
  String chat_list_create_folder_chats_label(Object count) {
    return 'CHATS ($count)';
  }

  @override
  String get chat_list_create_folder_select_all => 'SELECCIONAR TODO';

  @override
  String get chat_list_create_folder_reset => 'RESTABLECER';

  @override
  String get chat_list_create_folder_search_hint => 'Buscar por nombre…';

  @override
  String get chat_list_create_folder_no_matches => 'No hay chats que coincidan';

  @override
  String get chat_list_folder_default_starred => 'Destacados';

  @override
  String get chat_list_folder_default_all => 'Todos';

  @override
  String get chat_list_folder_default_new => 'Nuevos';

  @override
  String get chat_list_folder_default_direct => 'Directos';

  @override
  String get chat_list_folder_default_groups => 'Grupos';

  @override
  String get chat_list_yesterday => 'Ayer';

  @override
  String get chat_list_folder_delete_action => 'Eliminar';

  @override
  String get chat_list_folder_delete_title => '¿Eliminar carpeta?';

  @override
  String chat_list_folder_delete_body(Object name) {
    return 'La carpeta \"$name\" se eliminará. Los chats permanecerán intactos.';
  }

  @override
  String chat_list_error_open_starred(Object error) {
    return 'No se pudo abrir Destacados: $error';
  }

  @override
  String chat_list_error_delete_folder(Object error) {
    return 'No se pudo eliminar la carpeta: $error';
  }

  @override
  String get chat_list_pin_not_available =>
      'Fijar no está disponible en esta carpeta.';

  @override
  String chat_list_pin_pinned_in_folder(Object name) {
    return 'Chat fijado en \"$name\"';
  }

  @override
  String chat_list_pin_unpinned_in_folder(Object name) {
    return 'Chat desfijado de \"$name\"';
  }

  @override
  String chat_list_error_toggle_pin(Object error) {
    return 'No se pudo cambiar el fijado: $error';
  }

  @override
  String chat_list_error_update_folder(Object error) {
    return 'No se pudo actualizar la carpeta: $error';
  }

  @override
  String get chat_list_clear_history_title => '¿Borrar historial?';

  @override
  String get chat_list_clear_history_body =>
      'Los mensajes desaparecerán solo de tu vista del chat. El otro participante conservará el historial.';

  @override
  String get chat_list_clear_history_confirm => 'Borrar';

  @override
  String chat_list_error_clear_history(Object error) {
    return 'No se pudo borrar el historial: $error';
  }

  @override
  String chat_list_error_mark_read(Object error) {
    return 'No se pudo marcar el chat como leído: $error';
  }

  @override
  String get chat_list_delete_chat_title => '¿Eliminar chat?';

  @override
  String get chat_list_delete_chat_body =>
      'La conversación se eliminará permanentemente para todos los participantes. Esto no se puede deshacer.';

  @override
  String get chat_list_delete_chat_confirm => 'Eliminar';

  @override
  String chat_list_error_delete_chat(Object error) {
    return 'No se pudo eliminar el chat: $error';
  }

  @override
  String get chat_list_context_folders => 'Carpetas';

  @override
  String get chat_list_context_unpin => 'Desfijar chat';

  @override
  String get chat_list_context_pin => 'Fijar chat';

  @override
  String get chat_list_context_mark_all_read => 'Marcar todo como leído';

  @override
  String get chat_list_context_clear_history => 'Borrar historial';

  @override
  String get chat_list_context_delete_chat => 'Eliminar chat';

  @override
  String get chat_list_snackbar_history_cleared => 'Historial borrado.';

  @override
  String get chat_list_snackbar_marked_read => 'Marcado como leído.';

  @override
  String chat_list_error_generic(Object error) {
    return 'Error: $error';
  }

  @override
  String get chat_calls_title => 'Llamadas';

  @override
  String get chat_calls_search_hint => 'Buscar por nombre…';

  @override
  String get chat_calls_empty => 'Tu historial de llamadas está vacío.';

  @override
  String get chat_calls_nothing_found => 'No se encontró nada.';

  @override
  String chat_calls_error_load(Object error) {
    return 'No se pudieron cargar las llamadas:\n$error';
  }

  @override
  String get chat_reply_cancel_tooltip => 'Cancelar respuesta';

  @override
  String get voice_preview_tooltip_cancel => 'Cancelar';

  @override
  String get voice_preview_tooltip_send => 'Enviar';

  @override
  String get profile_qr_title => 'Mi código QR';

  @override
  String get profile_qr_tooltip_close => 'Cerrar';

  @override
  String get profile_qr_share_title => 'Mi perfil de LighChat';

  @override
  String get profile_qr_share_subject => 'Perfil de LighChat';

  @override
  String chat_media_norm_pending_title(Object mediaKind) {
    return 'Procesando $mediaKind…';
  }

  @override
  String chat_media_norm_failed_title(Object mediaKind) {
    return 'No se pudo procesar $mediaKind';
  }

  @override
  String get chat_media_norm_pending_subtitle =>
      'El archivo estará disponible después del procesamiento del servidor.';

  @override
  String get chat_media_norm_failed_subtitle =>
      'Intenta iniciar el procesamiento de nuevo.';

  @override
  String get conversation_threads_title => 'Hilos';

  @override
  String get conversation_threads_empty => 'Aún no hay hilos';

  @override
  String get conversation_threads_root_attachment => 'Adjunto';

  @override
  String get conversation_threads_root_message => 'Mensaje';

  @override
  String conversation_threads_snippet_you(Object text) {
    return 'Tú: $text';
  }

  @override
  String get conversation_threads_day_today => 'Hoy';

  @override
  String get conversation_threads_day_yesterday => 'Ayer';

  @override
  String conversation_threads_replies_badge(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count respuestas',
      one: '$count respuesta',
    );
    return '$_temp0';
  }

  @override
  String get chat_meetings_title => 'Reuniones';

  @override
  String get chat_meetings_subtitle =>
      'Crea conferencias y administra el acceso de participantes';

  @override
  String get chat_meetings_section_new => 'Nueva reunión';

  @override
  String get chat_meetings_field_title_label => 'Título de la reunión';

  @override
  String get chat_meetings_field_title_hint =>
      'Ej., Sincronización de logística';

  @override
  String get chat_meetings_field_duration_label => 'Duración';

  @override
  String get chat_meetings_duration_unlimited => 'Sin límite';

  @override
  String get chat_meetings_duration_15m => '15 minutos';

  @override
  String get chat_meetings_duration_30m => '30 minutos';

  @override
  String get chat_meetings_duration_1h => '1 hora';

  @override
  String get chat_meetings_duration_90m => '1.5 horas';

  @override
  String get chat_meetings_field_access_label => 'Acceso';

  @override
  String get chat_meetings_access_private => 'Privada';

  @override
  String get chat_meetings_access_public => 'Pública';

  @override
  String get chat_meetings_waiting_room_title => 'Sala de espera';

  @override
  String get chat_meetings_waiting_room_desc =>
      'En modo de sala de espera, tú controlas quién se une. Hasta que toques “Admitir”, los invitados permanecerán en la pantalla de espera.';

  @override
  String get chat_meetings_backgrounds_title => 'Fondos virtuales';

  @override
  String get chat_meetings_backgrounds_desc =>
      'Sube fondos y difumina tu fondo si quieres. Elige una imagen de la galería o sube tus propios fondos.';

  @override
  String get chat_meetings_create_button => 'Crear reunión';

  @override
  String get chat_meetings_snackbar_enter_title =>
      'Ingresa un título para la reunión';

  @override
  String get chat_meetings_snackbar_auth_required =>
      'Necesitas iniciar sesión para crear una reunión';

  @override
  String chat_meetings_error_create_failed(Object error) {
    return 'No se pudo crear la reunión: $error';
  }

  @override
  String get chat_meetings_history_title => 'Tu historial';

  @override
  String get chat_meetings_history_empty =>
      'El historial de reuniones está vacío';

  @override
  String chat_meetings_history_error(Object error) {
    return 'No se pudo cargar el historial de reuniones: $error';
  }

  @override
  String get chat_meetings_status_live => 'en vivo';

  @override
  String get chat_meetings_status_finished => 'finalizada';

  @override
  String get chat_meetings_badge_private => 'privada';

  @override
  String get chat_contacts_search_hint => 'Buscar contactos…';

  @override
  String get chat_contacts_permission_denied =>
      'Permiso de contactos no otorgado.';

  @override
  String chat_contacts_sync_error(Object error) {
    return 'No se pudieron sincronizar los contactos: $error';
  }

  @override
  String chat_contacts_invite_prepare_failed(Object error) {
    return 'No se pudo preparar la invitación: $error';
  }

  @override
  String get chat_contacts_matches_not_found =>
      'No se encontraron coincidencias.';

  @override
  String chat_contacts_added_count(Object count) {
    return 'Contactos agregados: $count.';
  }

  @override
  String get chat_contacts_invite_text =>
      'Instala LighChat: https://lighchat.online\nTe invito a LighChat — aquí está el enlace de instalación.';

  @override
  String get chat_contacts_invite_subject => 'Invitación a LighChat';

  @override
  String chat_contacts_error_load(Object error) {
    return 'No se pudieron cargar los contactos: $error';
  }

  @override
  String chat_list_item_draft_line(Object line) {
    return 'Borrador · $line';
  }

  @override
  String get chat_list_item_chat_created => 'Chat creado';

  @override
  String get chat_list_item_no_messages_yet => 'Aún no hay mensajes';

  @override
  String get chat_list_item_history_cleared => 'Historial borrado';

  @override
  String get chat_list_firebase_not_configured =>
      'Firebase aún no está configurado.';

  @override
  String get new_chat_title => 'Nuevo chat';

  @override
  String get new_chat_subtitle =>
      'Elige a alguien para iniciar una conversación o crea un grupo.';

  @override
  String get new_chat_search_hint => 'Nombre, usuario o @identificador…';

  @override
  String get new_chat_create_group => 'Crear un grupo';

  @override
  String get new_chat_section_phone_contacts => 'CONTACTOS DEL TELÉFONO';

  @override
  String get new_chat_section_contacts => 'CONTACTOS';

  @override
  String get new_chat_section_all_users => 'TODOS LOS USUARIOS';

  @override
  String get new_chat_empty_no_users => 'Aún no hay nadie con quien chatear.';

  @override
  String get new_chat_empty_not_found => 'No se encontraron coincidencias.';

  @override
  String new_chat_error_contacts(Object error) {
    return 'Contactos: $error';
  }

  @override
  String get new_chat_fallback_user_display_name => 'Usuario';

  @override
  String get new_group_role_badge_admin => 'ADMINISTRACIÓN';

  @override
  String get new_group_role_badge_worker => 'MIEMBRO';

  @override
  String new_group_error_auth_session(Object error) {
    return 'No se pudo verificar el inicio de sesión: $error';
  }

  @override
  String get invite_subject => 'Únete a mí en LighChat';

  @override
  String get invite_text =>
      'Instala LighChat: https://lighchat.online\\nTe invito a LighChat — aquí está el enlace de instalación.';

  @override
  String get new_group_title => 'Crear un grupo';

  @override
  String get new_group_search_hint => 'Buscar usuarios…';

  @override
  String get new_group_pick_photo_tooltip =>
      'Toca para elegir una foto de grupo. Mantén presionado para eliminarla.';

  @override
  String get new_group_name_label => 'Nombre del grupo';

  @override
  String get new_group_name_hint => 'Nombre';

  @override
  String get new_group_description_label => 'Descripción';

  @override
  String get new_group_description_hint => 'Opcional';

  @override
  String new_group_members_count(Object count) {
    return 'Miembros ($count)';
  }

  @override
  String get new_group_add_members_section => 'AGREGAR MIEMBROS';

  @override
  String get new_group_empty_no_users => 'Aún no hay nadie para agregar.';

  @override
  String get new_group_empty_not_found => 'No se encontraron coincidencias.';

  @override
  String get new_group_error_name_required =>
      'Por favor, ingresa un nombre de grupo.';

  @override
  String get new_group_error_members_required => 'Agrega al menos un miembro.';

  @override
  String get new_group_action_create => 'Crear';

  @override
  String get group_members_title => 'Miembros';

  @override
  String get group_members_invite_link => 'Invitar por enlace';

  @override
  String get group_members_admin_badge => 'ADMINISTRACIÓN';

  @override
  String group_members_invite_text(Object groupName, Object inviteLink) {
    return 'Únete al grupo $groupName en LighChat: $inviteLink';
  }

  @override
  String get group_members_error_min_admin =>
      'Al menos un administrador debe permanecer en el grupo.';

  @override
  String get group_members_error_cannot_remove_creator =>
      'No puedes quitar los derechos de administrador al creador del grupo.';

  @override
  String get group_members_remove_admin =>
      'Derechos de administrador eliminados';

  @override
  String get group_members_make_admin => 'Usuario promovido a administrador';

  @override
  String get auth_brand_tagline => 'Un mensajero más seguro';

  @override
  String get auth_firebase_not_ready =>
      'Firebase no está listo. Verifica `firebase_options.dart` y GoogleService-Info.plist.';

  @override
  String get auth_redirecting_to_chats => 'Llevándote a los chats…';

  @override
  String get auth_or => 'o';

  @override
  String get auth_create_account => 'Crear cuenta';

  @override
  String get auth_entry_sign_in => 'Iniciar sesión';

  @override
  String get auth_entry_sign_up => 'Crear cuenta';

  @override
  String get auth_qr_title => 'Iniciar sesión con QR';

  @override
  String get auth_qr_hint =>
      'Abre LighChat en un dispositivo donde ya hayas iniciado sesión → Configuración → Dispositivos → Conectar nuevo dispositivo, luego escanea este código.';

  @override
  String auth_qr_refresh_in(int seconds) {
    return 'Se actualiza en ${seconds}s';
  }

  @override
  String get auth_qr_other_method => 'Iniciar sesión de otra forma';

  @override
  String get auth_qr_approving => 'Iniciando sesión…';

  @override
  String get auth_qr_rejected => 'Solicitud rechazada';

  @override
  String get auth_qr_retry => 'Reintentar';

  @override
  String get auth_qr_unknown_error => 'No se pudo generar el código QR.';

  @override
  String get auth_qr_use_qr_login => 'Iniciar sesión con QR';

  @override
  String get auth_privacy_policy => 'Política de privacidad';

  @override
  String get auth_error_open_privacy_policy =>
      'No se pudo abrir la política de privacidad';

  @override
  String get voice_transcript_show => 'Mostrar texto';

  @override
  String get voice_transcript_hide => 'Ocultar texto';

  @override
  String get voice_transcript_copy => 'Copiar';

  @override
  String get voice_transcript_retry => 'Reintentar transcripción';

  @override
  String get voice_transcript_summary_show => 'Mostrar resumen';

  @override
  String get voice_transcript_summary_hide => 'Mostrar texto completo';

  @override
  String voice_transcript_stats(int words, int wpm) {
    return '$words palabras · $wpm ppm';
  }

  @override
  String get voice_attachment_skip_silence => 'Saltar silencios';

  @override
  String get voice_karaoke_title => 'Karaoke';

  @override
  String get voice_karaoke_prompt_title => 'Modo karaoke';

  @override
  String get voice_karaoke_prompt_body =>
      '¿Abrir el mensaje de voz en pantalla completa con letras?';

  @override
  String get voice_karaoke_prompt_open => 'Abrir';

  @override
  String get voice_transcript_loading => 'Transcribiendo…';

  @override
  String get voice_transcript_failed => 'No se pudo obtener el texto.';

  @override
  String get voice_attachment_media_kind_audio => 'audio';

  @override
  String get voice_attachment_load_failed => 'No se pudo cargar';

  @override
  String get voice_attachment_title_voice_message => 'Mensaje de voz';

  @override
  String voice_transcript_error(Object error) {
    return 'No se pudo transcribir: $error';
  }

  @override
  String get voice_transcript_permission_denied =>
      'El reconocimiento de voz no está permitido. Habilítalo en los ajustes del sistema.';

  @override
  String get voice_transcript_unsupported_lang =>
      'Este idioma no es compatible con la transcripción en el dispositivo.';

  @override
  String get voice_transcript_no_model =>
      'Instala un paquete de reconocimiento de voz sin conexión en los ajustes del sistema.';

  @override
  String get ai_action_summarize => 'Resumir';

  @override
  String get ai_action_rewrite => 'Reescribir con IA';

  @override
  String get ai_action_apply => 'Aplicar';

  @override
  String get ai_action_thinking => 'Escribiendo…';

  @override
  String get ai_action_failed =>
      'No se pudo procesar este texto. Es posible que el idioma aún no esté soportado por la IA en el dispositivo.';

  @override
  String get ai_status_model_not_ready =>
      'La modelo de Apple Intelligence aún se descarga. Inténtalo en un minuto.';

  @override
  String get ai_status_not_enabled =>
      'Apple Intelligence no está activado en Ajustes.';

  @override
  String get ai_status_device_not_eligible =>
      'Este dispositivo no admite Apple Intelligence.';

  @override
  String get ai_status_unsupported_os =>
      'Apple Intelligence requiere iOS 26 o más reciente.';

  @override
  String get ai_status_unknown =>
      'Apple Intelligence no está disponible ahora.';

  @override
  String get navigator_picker_title => 'Abrir en';

  @override
  String get calendar_picker_title => 'Agregar al calendario';

  @override
  String get calendar_picker_native_subtitle =>
      'Calendario del sistema con todas tus cuentas';

  @override
  String get calendar_picker_web_subtitle =>
      'Abre la app si está instalada, si no — el navegador';

  @override
  String get ai_style_friendly => 'Más amigable';

  @override
  String get ai_style_formal => 'Formal';

  @override
  String get ai_style_shorter => 'Más corto';

  @override
  String get ai_style_longer => 'Más largo';

  @override
  String get ai_style_proofread => 'Corregir';

  @override
  String get ai_style_youth => 'Juvenil';

  @override
  String get ai_style_strict => 'Estricto';

  @override
  String get ai_style_blatnoy => 'Callejero';

  @override
  String get ai_style_funny => 'Divertido';

  @override
  String get ai_style_romantic => 'Romántico';

  @override
  String get ai_style_sarcastic => 'Sarcástico';

  @override
  String get ai_rewrite_picker_title => 'Estilo de reescritura';

  @override
  String get voice_translate_action => 'Traducir';

  @override
  String get voice_translate_show_original => 'Original';

  @override
  String get voice_translate_in_progress => 'Traduciendo…';

  @override
  String get voice_translate_downloading_model => 'Descargando modelo…';

  @override
  String get voice_translate_unsupported =>
      'La traducción no está disponible para este par de idiomas.';

  @override
  String voice_translate_failed(Object error) {
    return 'No se pudo traducir: $error';
  }

  @override
  String get chat_messages_title => 'Mensajes';

  @override
  String get chat_call_decline => 'Rechazar';

  @override
  String get chat_call_open => 'Abrir';

  @override
  String get chat_call_accept => 'Aceptar';

  @override
  String video_call_error_init(Object error) {
    return 'Error de videollamada: $error';
  }

  @override
  String get video_call_ended => 'Llamada finalizada';

  @override
  String get video_call_status_missed => 'Llamada perdida';

  @override
  String get video_call_status_cancelled => 'Llamada cancelada';

  @override
  String get video_call_error_offer_not_ready =>
      'La oferta aún no está lista. Intenta de nuevo.';

  @override
  String get video_call_error_invalid_call_data =>
      'Datos de llamada no válidos';

  @override
  String video_call_error_accept_failed(Object error) {
    return 'No se pudo aceptar la llamada: $error';
  }

  @override
  String get video_call_incoming => 'Videollamada entrante';

  @override
  String get video_call_connecting => 'Videollamada…';

  @override
  String get video_call_pip_tooltip => 'Imagen en imagen';

  @override
  String get video_call_mini_window_tooltip => 'Mini ventana';

  @override
  String get chat_delete_message_title_single => '¿Eliminar mensaje?';

  @override
  String get chat_delete_message_title_multi => '¿Eliminar mensajes?';

  @override
  String get chat_delete_message_body_single =>
      'Este mensaje se ocultará para todos.';

  @override
  String chat_delete_message_body_multi(Object count) {
    return 'Mensajes a eliminar: $count';
  }

  @override
  String get chat_delete_file_title => '¿Eliminar archivo?';

  @override
  String get chat_delete_file_body =>
      'Solo este archivo se eliminará del mensaje.';

  @override
  String get forward_title => 'Reenviar';

  @override
  String get forward_empty_no_messages => 'No hay mensajes para reenviar';

  @override
  String get forward_error_not_authorized => 'No ha iniciado sesión';

  @override
  String get forward_empty_no_recipients =>
      'No hay contactos o chats a los que reenviar';

  @override
  String get forward_search_hint => 'Buscar contactos…';

  @override
  String get forward_empty_no_available_recipients =>
      'No hay destinatarios disponibles.\nSolo puedes reenviar a contactos y tus chats activos.';

  @override
  String get forward_empty_not_found => 'No se encontró nada';

  @override
  String get forward_action_pick_recipients => 'Elegir destinatarios';

  @override
  String get forward_action_send => 'Enviar';

  @override
  String forward_error_generic(Object error) {
    return 'Error: $error';
  }

  @override
  String get forward_sender_fallback => 'Participante';

  @override
  String get forward_error_profiles_load =>
      'No se pudieron cargar los perfiles para abrir el chat';

  @override
  String get forward_error_send_no_permissions =>
      'No se pudo reenviar: no tienes acceso a uno de los chats seleccionados o el chat ya no está disponible.';

  @override
  String get forward_error_send_forbidden_chat =>
      'No se pudo reenviar: acceso denegado a uno de los chats.';

  @override
  String get share_picker_title => 'Compartir con LighChat';

  @override
  String get share_picker_empty_payload => 'Nada que compartir';

  @override
  String get share_picker_summary_text_only => 'Texto';

  @override
  String share_picker_summary_files_count(int count) {
    return 'Archivos: $count';
  }

  @override
  String share_picker_summary_files_with_text(int count) {
    return 'Archivos: $count + texto';
  }

  @override
  String get devices_title => 'Mis dispositivos';

  @override
  String get devices_subtitle =>
      'Dispositivos donde se publica tu clave pública de cifrado. Revocar crea una nueva época de clave para todos los chats cifrados — el dispositivo revocado no podrá leer nuevos mensajes.';

  @override
  String get devices_empty => 'Aún no hay dispositivos.';

  @override
  String get devices_connect_new_device => 'Conectar nuevo dispositivo';

  @override
  String get devices_approve_title =>
      '¿Permitir que este dispositivo inicie sesión?';

  @override
  String get devices_approve_body_hint =>
      'Asegúrate de que este es tu propio dispositivo que acaba de mostrar el código QR.';

  @override
  String get devices_approve_allow => 'Permitir';

  @override
  String get devices_approve_deny => 'Denegar';

  @override
  String get devices_handover_progress_title => 'Sincronizando chats cifrados…';

  @override
  String devices_handover_progress_body(int done, int total) {
    return 'Actualizados $done de $total';
  }

  @override
  String get devices_handover_progress_starting => 'Iniciando…';

  @override
  String get devices_handover_success_title => 'Nuevo dispositivo vinculado';

  @override
  String devices_handover_success_body(String label) {
    return 'El dispositivo $label ahora tiene acceso a tus chats cifrados.';
  }

  @override
  String devices_progress_rekeying(Object done, Object total) {
    return 'Actualizando chats: $done / $total';
  }

  @override
  String get devices_chip_current => 'Este dispositivo';

  @override
  String get devices_chip_revoked => 'Revocado';

  @override
  String devices_meta_created_activity(Object createdAt, Object lastSeenAt) {
    return 'Creado: $createdAt  •  Actividad: $lastSeenAt';
  }

  @override
  String devices_meta_revoked_at(Object revokedAt) {
    return 'Revocado: $revokedAt';
  }

  @override
  String get devices_action_rename => 'Renombrar';

  @override
  String get devices_action_revoke => 'Revocar';

  @override
  String get devices_dialog_rename_title => 'Renombrar dispositivo';

  @override
  String get devices_dialog_rename_hint => 'ej. iPhone 15 — Safari';

  @override
  String devices_error_rename_failed(Object error) {
    return 'No se pudo renombrar: $error';
  }

  @override
  String get devices_dialog_revoke_title => '¿Revocar dispositivo?';

  @override
  String get devices_dialog_revoke_body_current =>
      'Estás a punto de revocar ESTE dispositivo. Después de eso, no podrás leer nuevos mensajes en chats cifrados de extremo a extremo desde este cliente.';

  @override
  String get devices_dialog_revoke_body_other =>
      'Este dispositivo no podrá leer nuevos mensajes en chats cifrados de extremo a extremo. Los mensajes antiguos seguirán disponibles.';

  @override
  String devices_snackbar_revoked(Object rekeyed, Object suffix) {
    return 'Dispositivo revocado. Chats actualizados: $rekeyed$suffix';
  }

  @override
  String devices_snackbar_failed_suffix(Object count) {
    return ', errores: $count';
  }

  @override
  String devices_error_revoke_failed(Object error) {
    return 'Error al revocar: $error';
  }

  @override
  String get e2ee_recovery_title => 'E2EE — respaldo';

  @override
  String get e2ee_password_label => 'Contraseña';

  @override
  String get e2ee_password_confirm_label => 'Confirmar contraseña';

  @override
  String e2ee_password_min_length(Object count) {
    return 'Al menos $count caracteres';
  }

  @override
  String get e2ee_password_mismatch => 'Las contraseñas no coinciden';

  @override
  String get e2ee_backup_create_title => 'Crear respaldo de clave';

  @override
  String get e2ee_backup_restore_title => 'Restaurar con contraseña';

  @override
  String get e2ee_backup_restore_action => 'Restaurar';

  @override
  String e2ee_backup_create_error(Object error) {
    return 'No se pudo crear el respaldo: $error';
  }

  @override
  String e2ee_backup_restore_error(Object error) {
    return 'No se pudo restaurar: $error';
  }

  @override
  String get e2ee_backup_wrong_password => 'Contraseña incorrecta';

  @override
  String get e2ee_backup_not_found => 'Respaldo no encontrado';

  @override
  String e2ee_recovery_error_generic(Object error) {
    return 'Error: $error';
  }

  @override
  String get e2ee_backup_password_card_title => 'Respaldo con contraseña';

  @override
  String get e2ee_backup_password_card_description =>
      'Crea un respaldo cifrado de tu clave privada. Si pierdes todos tus dispositivos, puedes restaurarla en uno nuevo usando solo la contraseña. La contraseña no se puede recuperar — guárdala de forma segura.';

  @override
  String get e2ee_backup_overwrite => 'Sobrescribir respaldo';

  @override
  String get e2ee_backup_create => 'Crear respaldo';

  @override
  String get e2ee_backup_restore => 'Restaurar desde respaldo';

  @override
  String get e2ee_backup_already_have => 'Ya tengo un respaldo';

  @override
  String get e2ee_qr_transfer_title => 'Transferir clave por QR';

  @override
  String get e2ee_qr_transfer_description =>
      'En el nuevo dispositivo muestras un QR, en el anterior lo escaneas. Verifica un código de 6 dígitos — la clave privada se transfiere de forma segura.';

  @override
  String get e2ee_qr_transfer_open => 'Abrir emparejamiento QR';

  @override
  String get media_viewer_action_reply => 'Responder';

  @override
  String get media_viewer_action_forward => 'Reenviar';

  @override
  String get media_viewer_action_send => 'Enviar';

  @override
  String get media_viewer_action_save => 'Guardar';

  @override
  String get media_viewer_action_live_text => 'Live Text';

  @override
  String get media_viewer_action_subject_lift => 'Aislar objeto';

  @override
  String get media_viewer_action_subject_send => 'Enviar a este chat';

  @override
  String get media_viewer_action_subject_save => 'Guardar en Fotos';

  @override
  String get media_viewer_action_subject_share => 'Compartir';

  @override
  String get media_viewer_subject_saved => 'Guardado en Fotos';

  @override
  String get media_viewer_action_show_in_chat => 'Mostrar en el chat';

  @override
  String get media_viewer_action_delete => 'Eliminar';

  @override
  String get media_viewer_error_no_gallery_access =>
      'Sin permiso para guardar en la galería';

  @override
  String get media_viewer_error_share_unavailable_web =>
      'Compartir no está disponible en web';

  @override
  String get media_viewer_error_file_not_found => 'Archivo no encontrado';

  @override
  String get media_viewer_error_bad_media_url => 'URL de multimedia incorrecta';

  @override
  String get media_viewer_error_bad_url => 'URL incorrecta';

  @override
  String get media_viewer_error_unsupported_media_scheme =>
      'Tipo de multimedia no soportado';

  @override
  String media_viewer_error_http_status(Object status) {
    return 'Error del servidor (HTTP $status)';
  }

  @override
  String media_viewer_error_save_failed(Object error) {
    return 'No se pudo guardar: $error';
  }

  @override
  String media_viewer_error_send_failed(Object error) {
    return 'No se pudo enviar: $error';
  }

  @override
  String get media_viewer_video_playback_speed => 'Velocidad de reproducción';

  @override
  String get media_viewer_video_quality => 'Calidad';

  @override
  String get media_viewer_video_quality_auto => 'Automática';

  @override
  String get media_viewer_error_quality_switch_failed =>
      'No se pudo cambiar la calidad';

  @override
  String get media_viewer_error_pip_open_failed => 'No se pudo abrir PiP';

  @override
  String get media_viewer_pip_not_supported =>
      'Imagen en imagen no es compatible con este dispositivo.';

  @override
  String get media_viewer_video_processing =>
      'Este video se está procesando en el servidor y estará disponible pronto.';

  @override
  String get media_viewer_video_playback_failed =>
      'No se pudo reproducir el video.';

  @override
  String get common_none => 'Ninguno';

  @override
  String get group_member_role_admin => 'Administrador';

  @override
  String get group_member_role_worker => 'Miembro';

  @override
  String get profile_no_photo_to_view => 'No hay foto de perfil para ver.';

  @override
  String get profile_chat_id_copied_toast => 'ID del chat copiado';

  @override
  String get auth_register_error_open_link => 'No se pudo abrir el enlace.';

  @override
  String get new_chat_error_self_profile_not_found =>
      'Tu perfil no se encontró en el directorio. Intenta cerrar sesión e iniciar de nuevo.';

  @override
  String get disappearing_messages_title => 'Mensajes que desaparecen';

  @override
  String get disappearing_messages_intro =>
      'Los nuevos mensajes se eliminan automáticamente del servidor después del tiempo seleccionado (desde el momento en que se envían). Los mensajes ya enviados no se modifican.';

  @override
  String disappearing_messages_admin_only(Object summary) {
    return 'Solo los administradores del grupo pueden cambiar esto. Actual: $summary.';
  }

  @override
  String get disappearing_messages_snackbar_off =>
      'Mensajes que desaparecen desactivados.';

  @override
  String get disappearing_messages_snackbar_updated =>
      'Temporizador actualizado.';

  @override
  String get disappearing_preset_off => 'Desactivado';

  @override
  String get disappearing_preset_1h => '1 hora';

  @override
  String get disappearing_preset_24h => '24 horas';

  @override
  String get disappearing_preset_7d => '7 días';

  @override
  String get disappearing_preset_30d => '30 días';

  @override
  String get disappearing_ttl_summary_off => 'Desactivado';

  @override
  String disappearing_ttl_minutes(Object count) {
    return '$count min';
  }

  @override
  String disappearing_ttl_hours(Object count) {
    return '$count h';
  }

  @override
  String disappearing_ttl_days(Object count) {
    return '$count días';
  }

  @override
  String disappearing_ttl_weeks(Object count) {
    return '$count sem';
  }

  @override
  String get conversation_profile_e2ee_on => 'Activado';

  @override
  String get conversation_profile_e2ee_off => 'Desactivado';

  @override
  String get conversation_profile_e2ee_subtitle_on =>
      'El cifrado de extremo a extremo está activado. Toca para más detalles.';

  @override
  String get conversation_profile_e2ee_subtitle_off =>
      'El cifrado de extremo a extremo está desactivado. Toca para activar.';

  @override
  String get partner_profile_title_fallback_group => 'Chat grupal';

  @override
  String get partner_profile_title_fallback_saved => 'Mensajes guardados';

  @override
  String get partner_profile_title_fallback_chat => 'Charlar';

  @override
  String partner_profile_subtitle_group_member_count(Object count) {
    return '$count miembros';
  }

  @override
  String get partner_profile_subtitle_saved_messages =>
      'Mensajes y notas solo para ti';

  @override
  String get partner_profile_error_cannot_contact_user =>
      'No puedes contactar a este usuario con la configuración de contacto actual.';

  @override
  String partner_profile_error_open_chat(Object error) {
    return 'No se pudo abrir el chat: $error';
  }

  @override
  String get partner_profile_call_peer_fallback => 'Contacto';

  @override
  String get partner_profile_chat_not_created => 'El chat aún no se ha creado';

  @override
  String get partner_profile_notifications_muted =>
      'Notificaciones silenciadas';

  @override
  String get partner_profile_notifications_unmuted =>
      'Notificaciones activadas';

  @override
  String get partner_profile_notifications_change_failed =>
      'No se pudieron actualizar las notificaciones';

  @override
  String get partner_profile_removed_from_contacts => 'Eliminado de contactos';

  @override
  String get partner_profile_remove_contact_failed =>
      'No se pudo eliminar de contactos';

  @override
  String get partner_profile_contact_sent => 'Contacto enviado';

  @override
  String get partner_profile_share_failed_copied =>
      'Error al compartir. Texto del contacto copiado.';

  @override
  String get partner_profile_share_contact_header => 'Contacto en LighChat';

  @override
  String partner_profile_share_avatar_line(Object url) {
    return 'Avatar: $url';
  }

  @override
  String partner_profile_share_profile_line(Object url) {
    return 'Perfil: $url';
  }

  @override
  String partner_profile_share_contact_subject(Object name) {
    return 'Contacto de LighChat: $name';
  }

  @override
  String get partner_profile_tooltip_back => 'Atrás';

  @override
  String get partner_profile_tooltip_close => 'Cerrar';

  @override
  String get partner_profile_edit_contact_short => 'Editar';

  @override
  String get partner_profile_tooltip_copy_chat_id => 'Copiar ID del chat';

  @override
  String get partner_profile_action_chats => 'Charlas';

  @override
  String get partner_profile_action_voice_call => 'Llamar';

  @override
  String get partner_profile_action_video => 'Video';

  @override
  String get partner_profile_action_share => 'Compartir';

  @override
  String get partner_profile_action_notifications => 'Alertas';

  @override
  String get partner_profile_menu_members => 'Miembros';

  @override
  String get partner_profile_menu_edit_group => 'Editar grupo';

  @override
  String get partner_profile_menu_media_links_files =>
      'Multimedia, enlaces y archivos';

  @override
  String get partner_profile_menu_starred => 'Destacados';

  @override
  String get partner_profile_menu_threads => 'Hilos';

  @override
  String get partner_profile_menu_games => 'Juegos';

  @override
  String get partner_profile_menu_block => 'Bloquear';

  @override
  String get partner_profile_menu_unblock => 'Desbloquear';

  @override
  String get partner_profile_menu_notifications => 'Notificaciones';

  @override
  String get partner_profile_menu_chat_theme => 'Tema del chat';

  @override
  String get partner_profile_menu_advanced_privacy =>
      'Privacidad avanzada del chat';

  @override
  String get partner_profile_privacy_trailing_default => 'Predeterminado';

  @override
  String get partner_profile_menu_encryption => 'Cifrado';

  @override
  String get partner_profile_no_common_groups => 'SIN GRUPOS EN COMÚN';

  @override
  String partner_profile_create_group_with(Object name) {
    return 'Crear un grupo con $name';
  }

  @override
  String get partner_profile_leave_group => 'Salir del grupo';

  @override
  String get partner_profile_contacts_and_data => 'Información de contacto';

  @override
  String get partner_profile_field_system_role => 'Rol del sistema';

  @override
  String get partner_profile_field_email => 'Correo electrónico';

  @override
  String get partner_profile_field_phone => 'Teléfono';

  @override
  String get partner_profile_field_birthday => 'Cumpleaños';

  @override
  String get partner_profile_field_bio => 'Acerca de';

  @override
  String get partner_profile_add_to_contacts => 'Agregar a contactos';

  @override
  String get partner_profile_remove_from_contacts => 'Eliminar de contactos';

  @override
  String get thread_search_hint => 'Buscar en el hilo…';

  @override
  String get thread_search_tooltip_clear => 'Borrar';

  @override
  String get thread_search_tooltip_search => 'Buscar';

  @override
  String thread_reply_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count respuestas',
      one: '$count respuesta',
      zero: '$count respuestas',
    );
    return '$_temp0';
  }

  @override
  String get thread_message_not_found => 'Mensaje no encontrado';

  @override
  String get thread_screen_title_fallback => 'Hilo';

  @override
  String thread_load_replies_error(Object error) {
    return 'Error del hilo: $error';
  }

  @override
  String get chat_message_empty_placeholder => 'Mensaje';

  @override
  String get chat_sender_you => 'Tú';

  @override
  String get chat_clipboard_nothing_to_paste =>
      'Nada que pegar del portapapeles';

  @override
  String chat_clipboard_paste_failed(Object error) {
    return 'No se pudo pegar del portapapeles: $error';
  }

  @override
  String chat_send_failed(Object error) {
    return 'No se pudo enviar: $error';
  }

  @override
  String chat_send_video_circle_failed(Object error) {
    return 'No se pudo enviar la nota de video: $error';
  }

  @override
  String get chat_service_unavailable => 'Servicio no disponible';

  @override
  String get chat_repository_unavailable => 'Servicio de chat no disponible';

  @override
  String get chat_still_loading => 'El chat aún se está cargando';

  @override
  String get chat_no_participants => 'Sin participantes en el chat';

  @override
  String get chat_location_ios_geolocator_missing =>
      'La ubicación no está vinculada en esta compilación de iOS. Ejecuta pod install en mobile/app/ios y recompila.';

  @override
  String get chat_location_services_disabled =>
      'Activa los servicios de ubicación';

  @override
  String get chat_location_permission_denied =>
      'Sin permiso para usar la ubicación';

  @override
  String chat_location_send_failed(Object error) {
    return 'No se pudo enviar la ubicación: $error';
  }

  @override
  String get chat_poll_send_timeout =>
      'La encuesta no se envió: tiempo agotado';

  @override
  String chat_poll_send_firebase(Object details) {
    return 'La encuesta no se envió (Firestore): $details';
  }

  @override
  String chat_poll_send_known_error(Object details) {
    return 'La encuesta no se envió: $details';
  }

  @override
  String chat_poll_send_failed(Object error) {
    return 'No se pudo enviar la encuesta: $error';
  }

  @override
  String chat_delete_action_failed(Object error) {
    return 'No se pudo eliminar: $error';
  }

  @override
  String get chat_media_transcode_retry_started =>
      'Reintento de transcodificación iniciado';

  @override
  String chat_media_transcode_retry_failed(Object error) {
    return 'No se pudo iniciar el reintento de transcodificación: $error';
  }

  @override
  String chat_parent_load_error(Object error) {
    return 'Error: $error';
  }

  @override
  String get chat_message_not_found_in_loaded_history =>
      'El mensaje no se encontró en el historial cargado';

  @override
  String get chat_finish_editing_first => 'Termina de editar primero';

  @override
  String chat_send_voice_failed(Object error) {
    return 'No se pudo enviar el mensaje de voz: $error';
  }

  @override
  String get chat_starred_removed => 'Eliminado de Destacados';

  @override
  String get chat_starred_added => 'Agregado a Destacados';

  @override
  String chat_starred_toggle_failed(Object error) {
    return 'No se pudo actualizar Destacados: $error';
  }

  @override
  String chat_reaction_toggle_failed(Object error) {
    return 'No se pudo agregar la reacción: $error';
  }

  @override
  String chat_emoji_burst_sync_failed(Object error) {
    return 'No se pudo sincronizar el efecto de emoji: $error';
  }

  @override
  String get chat_pin_already_pinned => 'El mensaje ya está fijado';

  @override
  String chat_pin_limit_reached(int count) {
    return 'Límite de mensajes fijados ($count)';
  }

  @override
  String chat_pin_failed(Object error) {
    return 'No se pudo fijar: $error';
  }

  @override
  String chat_unpin_failed(Object error) {
    return 'No se pudo desfijar: $error';
  }

  @override
  String get chat_text_copied => 'Texto copiado';

  @override
  String get chat_edit_attachments_not_allowed =>
      'Los adjuntos no están disponibles mientras editas';

  @override
  String get chat_edit_text_empty => 'El texto no puede estar vacío';

  @override
  String chat_e2ee_unavailable(Object code) {
    return 'Cifrado no disponible: $code';
  }

  @override
  String chat_save_failed(Object error) {
    return 'No se pudo guardar: $error';
  }

  @override
  String chat_load_messages_error(Object error) {
    return 'No se pudieron cargar los mensajes: $error';
  }

  @override
  String chat_conversation_error(Object error) {
    return 'Error de conversación: $error';
  }

  @override
  String chat_auth_error(Object error) {
    return 'Error de autenticación: $error';
  }

  @override
  String get chat_poll_label => 'Encuesta';

  @override
  String get chat_location_label => 'Ubicación';

  @override
  String get chat_attachment_label => 'Adjunto';

  @override
  String chat_media_pick_failed(Object error) {
    return 'No se pudo seleccionar multimedia: $error';
  }

  @override
  String chat_file_pick_failed(Object error) {
    return 'No se pudo seleccionar archivo: $error';
  }

  @override
  String get chat_call_ongoing_video => 'Videollamada en progreso';

  @override
  String get chat_call_ongoing_audio => 'Llamada de audio en progreso';

  @override
  String get chat_call_incoming_video => 'Videollamada entrante';

  @override
  String get chat_call_incoming_audio => 'Llamada de audio entrante';

  @override
  String get message_menu_action_reply => 'Responder';

  @override
  String get message_menu_action_thread => 'Hilo';

  @override
  String get message_menu_action_copy => 'Copiar';

  @override
  String get message_menu_action_translate => 'Traducir';

  @override
  String get message_menu_action_show_original => 'Mostrar original';

  @override
  String get message_menu_action_read_aloud => 'Leer en voz alta';

  @override
  String get tts_quality_hint =>
      '¿Voz robótica? Instala voces Enhanced en Ajustes → Accesibilidad → Contenido leído → Voces.';

  @override
  String get tts_quality_hint_cta => 'Ajustes';

  @override
  String get message_menu_action_edit => 'Editar';

  @override
  String get message_menu_action_pin => 'Fijar';

  @override
  String get message_menu_action_star_add => 'Agregar a Destacados';

  @override
  String get message_menu_action_star_remove => 'Eliminar de Destacados';

  @override
  String get message_menu_action_create_sticker => 'Crear sticker';

  @override
  String get message_menu_action_save_to_my_stickers =>
      'Guardar en mis stickers';

  @override
  String get message_menu_action_forward => 'Reenviar';

  @override
  String get message_menu_action_select => 'Seleccionar';

  @override
  String get message_menu_action_delete => 'Eliminar';

  @override
  String get message_menu_initiator_deleted => 'Mensaje eliminado';

  @override
  String get message_menu_header_sent => 'ENVIADO:';

  @override
  String get message_menu_header_read => 'LEÍDO:';

  @override
  String get message_menu_header_expire_at => 'DESAPARECE:';

  @override
  String get chat_header_search_hint => 'Buscar mensajes…';

  @override
  String get chat_header_tooltip_threads => 'Hilos';

  @override
  String get chat_header_tooltip_search => 'Buscar';

  @override
  String get chat_header_tooltip_video_call => 'Videollamada';

  @override
  String get chat_header_tooltip_audio_call => 'Llamada de audio';

  @override
  String get conversation_games_title => 'Juegos';

  @override
  String get conversation_games_durak => 'Durak';

  @override
  String get conversation_games_durak_subtitle => 'Crear sala';

  @override
  String get conversation_game_lobby_title => 'Sala';

  @override
  String get conversation_game_lobby_not_found => 'Juego no encontrado';

  @override
  String conversation_game_lobby_error(Object error) {
    return 'Error: $error';
  }

  @override
  String conversation_game_lobby_create_failed(Object error) {
    return 'No se pudo crear el juego: $error';
  }

  @override
  String conversation_game_lobby_game_id(Object id) {
    return 'ID: $id';
  }

  @override
  String conversation_game_lobby_status(Object status) {
    return 'Estado: $status';
  }

  @override
  String conversation_game_lobby_players(Object count, Object max) {
    return 'Jugadores: $count/$max';
  }

  @override
  String get conversation_game_lobby_join => 'Unirse';

  @override
  String get conversation_game_lobby_start => 'Iniciar';

  @override
  String conversation_game_lobby_join_failed(Object error) {
    return 'No se pudo unir: $error';
  }

  @override
  String conversation_game_lobby_start_failed(Object error) {
    return 'No se pudo iniciar el juego: $error';
  }

  @override
  String get conversation_game_send_test_move => 'Movimiento de prueba';

  @override
  String conversation_game_move_failed(Object error) {
    return 'Movimiento rechazado: $error';
  }

  @override
  String get conversation_durak_table_title => 'Mesa';

  @override
  String get conversation_durak_hand_title => 'Mano';

  @override
  String get conversation_durak_role_attacker => 'Atacando';

  @override
  String get conversation_durak_role_defender => 'Defendiendo';

  @override
  String get conversation_durak_role_thrower => 'Lanzando';

  @override
  String get conversation_durak_action_attack => 'Atacar';

  @override
  String get conversation_durak_action_defend => 'Defender';

  @override
  String get conversation_durak_action_take => 'Tomar';

  @override
  String get conversation_durak_action_beat => 'Ganar';

  @override
  String get conversation_durak_action_transfer => 'Transferir';

  @override
  String get conversation_durak_action_pass => 'Pasar';

  @override
  String get conversation_durak_badge_taking => 'Tomo';

  @override
  String get conversation_durak_game_finished_title => 'Juego terminado';

  @override
  String get conversation_durak_game_finished_no_loser =>
      'No hay perdedor esta vez.';

  @override
  String conversation_durak_game_finished_loser(Object uid) {
    return 'Perdedor: $uid';
  }

  @override
  String conversation_durak_game_finished_winners(Object uids) {
    return 'Ganadores: $uids';
  }

  @override
  String get conversation_durak_winner => '¡Ganador!';

  @override
  String get conversation_durak_play_again => 'Jugar de nuevo';

  @override
  String get conversation_durak_back_to_chat => 'Volver al chat';

  @override
  String get conversation_game_lobby_waiting_opponent =>
      'Esperando al oponente…';

  @override
  String get conversation_durak_drop_zone => 'Suelta la carta aquí para jugar';

  @override
  String get durak_settings_mode => 'Modo';

  @override
  String get durak_mode_podkidnoy => 'Podkidnoy';

  @override
  String get durak_mode_perevodnoy => 'Perevodnoy';

  @override
  String get durak_settings_max_players => 'Jugadores';

  @override
  String get durak_settings_deck => 'Baraja';

  @override
  String get durak_deck_36 => '36 cartas';

  @override
  String get durak_deck_52 => '52 cartas';

  @override
  String get durak_settings_with_jokers => 'Comodines';

  @override
  String get durak_settings_turn_timer => 'Temporizador de turno';

  @override
  String get durak_turn_timer_off => 'Desactivado';

  @override
  String get durak_settings_throw_in_policy => 'Quién puede lanzar';

  @override
  String get durak_throw_in_policy_all =>
      'Todos los jugadores (excepto el defensor)';

  @override
  String get durak_throw_in_policy_neighbors => 'Solo los vecinos del defensor';

  @override
  String get durak_settings_shuler => 'Modo tramposo';

  @override
  String get durak_settings_shuler_subtitle =>
      'Permite movimientos ilegales a menos que alguien cante falta.';

  @override
  String get conversation_durak_action_foul => '¡Falta!';

  @override
  String get conversation_durak_action_resolve => 'Confirmar victoria';

  @override
  String get conversation_durak_foul_toast => '¡Falta! Tramposo penalizado.';

  @override
  String get durak_phase_prefix => 'Fase';

  @override
  String get durak_phase_attack => 'Atacar';

  @override
  String get durak_phase_defense => 'Defensa';

  @override
  String get durak_phase_throw_in => 'Lanzamiento';

  @override
  String get durak_phase_resolution => 'Resolución';

  @override
  String get durak_phase_finished => 'Terminado';

  @override
  String get durak_phase_pending_foul => 'Falta pendiente después de ganar';

  @override
  String get durak_phase_pending_foul_hint_attacker =>
      'Espera la falta. Si nadie la canta, confirma la victoria.';

  @override
  String get durak_phase_pending_foul_hint_other =>
      'Espera la falta. ¡Canta Falta! si viste trampa.';

  @override
  String get durak_phase_hint_can_throw_in => 'Puedes lanzar';

  @override
  String get durak_phase_hint_wait => 'Espera tu turno';

  @override
  String durak_now_throwing_in(Object name) {
    return 'Ahora lanza: $name';
  }

  @override
  String chat_selection_selected_count(int count) {
    return '$count seleccionados';
  }

  @override
  String get chat_selection_tooltip_forward => 'Reenviar';

  @override
  String get chat_selection_tooltip_delete => 'Eliminar';

  @override
  String get chat_composer_hint_message => 'Escribe un mensaje…';

  @override
  String get chat_composer_tooltip_stickers => 'Pegatinas';

  @override
  String get chat_composer_tooltip_attachments => 'Adjuntos';

  @override
  String get chat_list_unread_separator => 'Mensajes no leídos';

  @override
  String get chat_e2ee_decrypt_failed_open_devices =>
      'No se pudo descifrar. Abre Configuración → Dispositivos';

  @override
  String get chat_e2ee_encrypted_message_placeholder => 'Mensaje cifrado';

  @override
  String chat_forwarded_from(Object name) {
    return 'Reenviado de $name';
  }

  @override
  String get chat_outbox_retry => 'Reintentar';

  @override
  String get chat_outbox_remove => 'Eliminar';

  @override
  String get chat_outbox_cancel => 'Cancelar';

  @override
  String get chat_message_edited_badge_short => 'EDITADO';

  @override
  String get register_error_enter_name => 'Ingresa tu nombre.';

  @override
  String get register_error_enter_username => 'Ingresa un nombre de usuario.';

  @override
  String get register_error_enter_phone => 'Ingresa un número de teléfono.';

  @override
  String get register_error_invalid_phone =>
      'Ingresa un número de teléfono válido.';

  @override
  String get register_error_enter_email => 'Ingresa un correo electrónico.';

  @override
  String get register_error_enter_password => 'Ingresa una contraseña.';

  @override
  String get register_error_repeat_password => 'Repite la contraseña.';

  @override
  String get register_error_dob_format =>
      'Ingresa la fecha de nacimiento en formato dd.mm.aaaa';

  @override
  String get register_error_accept_privacy_policy =>
      'Por favor confirma que aceptas la política de privacidad';

  @override
  String get register_privacy_required =>
      'Es necesario aceptar la política de privacidad';

  @override
  String get register_label_name => 'Nombre';

  @override
  String get register_hint_name => 'Ingresa tu nombre';

  @override
  String get register_label_username => 'Nombre de usuario';

  @override
  String get register_hint_username => 'Ingresa un nombre de usuario';

  @override
  String get register_label_phone => 'Teléfono';

  @override
  String get register_hint_choose_country => 'Elige un país';

  @override
  String get register_label_email => 'Correo electrónico';

  @override
  String get register_hint_email => 'Ingresa tu correo electrónico';

  @override
  String get register_label_password => 'Contraseña';

  @override
  String get register_hint_password => 'Ingresa tu contraseña';

  @override
  String get register_label_confirm_password => 'Confirmar contraseña';

  @override
  String get register_hint_confirm_password => 'Repite tu contraseña';

  @override
  String get register_label_dob => 'Fecha de nacimiento';

  @override
  String get register_hint_dob => 'dd.mm.aaaa';

  @override
  String get register_label_bio => 'Acerca de';

  @override
  String get register_hint_bio => 'Cuéntanos sobre ti…';

  @override
  String get register_privacy_prefix => 'Acepto ';

  @override
  String get register_privacy_link_text =>
      'Consentimiento para el tratamiento de datos personales';

  @override
  String get register_privacy_and => ' y ';

  @override
  String get register_terms_link_text =>
      'Acuerdo de usuario y política de privacidad';

  @override
  String get register_button_create_account => 'Crear cuenta';

  @override
  String get register_country_search_hint => 'Buscar por país o código';

  @override
  String get register_date_picker_help => 'Fecha de nacimiento';

  @override
  String get register_date_picker_cancel => 'Cancelar';

  @override
  String get register_date_picker_confirm => 'Seleccionar';

  @override
  String get register_pick_avatar_title => 'Elegir avatar';

  @override
  String get edit_group_title => 'Editar grupo';

  @override
  String get edit_group_save => 'Guardar';

  @override
  String get edit_group_cancel => 'Cancelar';

  @override
  String get edit_group_name_label => 'Nombre del grupo';

  @override
  String get edit_group_name_hint => 'Nombre';

  @override
  String get edit_group_description_label => 'Descripción';

  @override
  String get edit_group_description_hint => 'Opcional';

  @override
  String get edit_group_pick_photo_tooltip =>
      'Toca para elegir una foto de grupo. Mantén presionado para eliminarla.';

  @override
  String get edit_group_error_name_required =>
      'Por favor, ingresa un nombre de grupo.';

  @override
  String get edit_group_error_save_failed => 'Error al guardar el grupo.';

  @override
  String get edit_group_error_not_found => 'Grupo no encontrado.';

  @override
  String get edit_group_error_permission_denied =>
      'No tienes permiso para editar este grupo.';

  @override
  String get edit_group_success => 'Grupo actualizado.';

  @override
  String get edit_group_privacy_section => 'PRIVACIDAD';

  @override
  String get edit_group_privacy_forwarding => 'Reenvío de mensajes';

  @override
  String get edit_group_privacy_forwarding_desc =>
      'Permitir a los miembros reenviar mensajes de este grupo.';

  @override
  String get edit_group_privacy_screenshots => 'Capturas de pantalla';

  @override
  String get edit_group_privacy_screenshots_desc =>
      'Permitir capturas de pantalla en este grupo (depende de la plataforma).';

  @override
  String get edit_group_privacy_copy => 'Copiar texto';

  @override
  String get edit_group_privacy_copy_desc =>
      'Permitir copiar texto de mensajes.';

  @override
  String get edit_group_privacy_save_media => 'Guardar multimedia';

  @override
  String get edit_group_privacy_save_media_desc =>
      'Permitir guardar fotos y videos en el dispositivo.';

  @override
  String get edit_group_privacy_share_media => 'Compartir multimedia';

  @override
  String get edit_group_privacy_share_media_desc =>
      'Permitir compartir archivos multimedia fuera de la app.';

  @override
  String get schedule_message_sheet_title => 'Programar mensaje';

  @override
  String get schedule_message_long_press_hint => 'Envío programado';

  @override
  String schedule_message_preset_today_at(String time) {
    return 'Hoy a las $time';
  }

  @override
  String schedule_message_preset_tomorrow_at(String time) {
    return 'Mañana a las $time';
  }

  @override
  String schedule_message_will_send_at(String datetime) {
    return 'Se enviará: $datetime';
  }

  @override
  String get schedule_message_must_be_in_future =>
      'La hora debe ser futura (al menos un minuto a partir de ahora).';

  @override
  String get schedule_message_e2ee_warning =>
      'Este es un chat E2EE. El mensaje programado se almacenará en el servidor en texto plano y se publicará sin cifrado.';

  @override
  String get schedule_message_cancel => 'Cancelar';

  @override
  String get schedule_message_confirm => 'Programar';

  @override
  String get schedule_message_save => 'Guardar';

  @override
  String get schedule_message_text_required => 'Escribe un mensaje primero';

  @override
  String get schedule_message_attachments_unsupported_mobile =>
      'La programación de adjuntos actualmente solo es compatible con la web';

  @override
  String schedule_message_scheduled_toast(String datetime) {
    return 'Programado: $datetime';
  }

  @override
  String schedule_message_failed_toast(String error) {
    return 'Error al programar: $error';
  }

  @override
  String get scheduled_messages_screen_title => 'Mensajes programados';

  @override
  String get scheduled_messages_empty_title => 'No hay mensajes programados';

  @override
  String get scheduled_messages_empty_hint =>
      'Mantén presionado el botón Enviar para programar un mensaje.';

  @override
  String scheduled_messages_load_failed(String error) {
    return 'Error al cargar: $error';
  }

  @override
  String get scheduled_messages_e2ee_notice =>
      'En un chat E2EE, los mensajes programados se almacenan y publican en texto plano.';

  @override
  String get scheduled_messages_cancel_dialog_title =>
      '¿Cancelar envío programado?';

  @override
  String get scheduled_messages_cancel_dialog_body =>
      'El mensaje programado se eliminará.';

  @override
  String get scheduled_messages_cancel_dialog_keep => 'Mantener';

  @override
  String get scheduled_messages_cancel_dialog_confirm => 'Cancelar';

  @override
  String get scheduled_messages_canceled_toast => 'Cancelado';

  @override
  String scheduled_messages_time_changed_toast(String datetime) {
    return 'Hora cambiada: $datetime';
  }

  @override
  String scheduled_messages_action_failed_toast(String error) {
    return 'Error: $error';
  }

  @override
  String get scheduled_messages_tile_edit_tooltip => 'Cambiar hora';

  @override
  String get scheduled_messages_tile_cancel_tooltip => 'Cancelar';

  @override
  String scheduled_messages_preview_poll(String question) {
    return 'Encuesta: $question';
  }

  @override
  String get scheduled_messages_preview_location => 'Ubicación';

  @override
  String get scheduled_messages_preview_attachment => 'Adjunto';

  @override
  String scheduled_messages_preview_attachment_count(int count) {
    return 'Adjunto (×$count)';
  }

  @override
  String get scheduled_messages_preview_message => 'Mensaje';

  @override
  String get chat_header_tooltip_scheduled => 'Mensajes programados';

  @override
  String get schedule_date_label => 'Fecha';

  @override
  String get schedule_time_label => 'Hora';

  @override
  String get common_done => 'Listo';

  @override
  String get common_send => 'Enviar';

  @override
  String get common_open => 'Abrir';

  @override
  String get common_add => 'Agregar';

  @override
  String get common_search => 'Buscar';

  @override
  String get common_edit => 'Editar';

  @override
  String get common_next => 'Siguiente';

  @override
  String get common_ok => 'Aceptar';

  @override
  String get common_confirm => 'Confirmar';

  @override
  String get common_ready => 'Listo';

  @override
  String get common_error => 'Error';

  @override
  String get common_yes => 'Sí';

  @override
  String get common_no => 'No';

  @override
  String get common_back => 'Atrás';

  @override
  String get common_continue => 'Continuar';

  @override
  String get common_loading => 'Cargando…';

  @override
  String get common_copy => 'Copiar';

  @override
  String get common_share => 'Compartir';

  @override
  String get common_settings => 'Configuración';

  @override
  String get common_today => 'Hoy';

  @override
  String get common_yesterday => 'Ayer';

  @override
  String get e2ee_qr_title => 'Emparejamiento de clave QR';

  @override
  String get e2ee_qr_uid_error => 'Error al obtener el uid del usuario.';

  @override
  String get e2ee_qr_session_ended_error =>
      'La sesión finalizó antes de que el segundo dispositivo respondiera.';

  @override
  String get e2ee_qr_no_data_error => 'No hay datos para aplicar la clave.';

  @override
  String get e2ee_qr_key_transferred_toast =>
      'Clave transferida. Vuelve a entrar a los chats para actualizar las sesiones.';

  @override
  String get e2ee_qr_wrong_account_error =>
      'El QR fue generado para una cuenta diferente.';

  @override
  String get e2ee_qr_explainer_title => 'Qué es esto';

  @override
  String get e2ee_qr_explainer_text =>
      'Transfiere una clave privada de uno de tus dispositivos a otro vía ECDH + QR. Ambos lados ven un código de 6 dígitos para verificación manual.';

  @override
  String get e2ee_qr_show_qr_label =>
      'Estoy en el nuevo dispositivo — mostrar QR';

  @override
  String get e2ee_qr_scan_qr_label => 'Ya tengo una clave — escanear QR';

  @override
  String get e2ee_qr_scan_hint =>
      'Escanea el QR en el dispositivo anterior que ya tiene la clave.';

  @override
  String get e2ee_qr_verify_code_label =>
      'Verifica el código de 6 dígitos con el dispositivo anterior:';

  @override
  String e2ee_qr_transfer_from_device_label(String label) {
    return 'Transferir del dispositivo: $label';
  }

  @override
  String get e2ee_qr_code_match_apply_label => 'El código coincide — aplicar';

  @override
  String get e2ee_qr_key_success_label =>
      'Clave transferida exitosamente a este dispositivo. Vuelve a entrar a los chats.';

  @override
  String get e2ee_qr_unknown_error => 'Error desconocido';

  @override
  String get e2ee_qr_back_to_pick_label => 'Volver a la selección';

  @override
  String get e2ee_qr_donor_scan_hint =>
      'Apunta la cámara al QR que se muestra en el nuevo dispositivo.';

  @override
  String get e2ee_qr_donor_verify_code_label =>
      'Verifica el código con el nuevo dispositivo:';

  @override
  String get e2ee_qr_donor_verify_hint =>
      'Si el código coincide — confirma en el nuevo dispositivo. Si no, presiona Cancelar inmediatamente.';

  @override
  String get e2ee_encrypt_title => 'Cifrado';

  @override
  String get e2ee_encrypt_enable_dialog_title => '¿Activar cifrado?';

  @override
  String get e2ee_encrypt_enable_dialog_body =>
      'Los nuevos mensajes solo estarán disponibles en tus dispositivos y los de tu contacto. Los mensajes anteriores permanecerán como están.';

  @override
  String get e2ee_encrypt_enable_label => 'Activar';

  @override
  String get e2ee_encrypt_disable_dialog_title => '¿Desactivar cifrado?';

  @override
  String get e2ee_encrypt_disable_dialog_body =>
      'Los nuevos mensajes se enviarán sin cifrado de extremo a extremo. Los mensajes cifrados enviados anteriormente permanecerán en el historial.';

  @override
  String get e2ee_encrypt_disable_label => 'Desactivar';

  @override
  String get e2ee_encrypt_status_on =>
      'El cifrado de extremo a extremo está activado para este chat.';

  @override
  String get e2ee_encrypt_status_off =>
      'El cifrado de extremo a extremo está desactivado.';

  @override
  String get e2ee_encrypt_description =>
      'Cuando el cifrado está activado, el contenido de los nuevos mensajes solo está disponible para los participantes del chat en sus dispositivos. Desactivar solo afecta a los nuevos mensajes.';

  @override
  String get e2ee_encrypt_switch_title => 'Activar cifrado';

  @override
  String e2ee_encrypt_switch_on(int epoch) {
    return 'Activado (época de clave: $epoch)';
  }

  @override
  String get e2ee_encrypt_switch_off => 'Desactivado';

  @override
  String get e2ee_encrypt_already_on_toast =>
      'El cifrado ya está activado o la creación de clave falló. Verifica la red y las claves de tu contacto.';

  @override
  String get e2ee_encrypt_no_device_toast =>
      'No se pudo activar: el contacto no tiene un dispositivo activo con clave.';

  @override
  String e2ee_encrypt_enable_failed_toast(String error) {
    return 'Error al activar el cifrado: $error';
  }

  @override
  String e2ee_encrypt_disable_failed_toast(String error) {
    return 'Error al desactivar: $error';
  }

  @override
  String get e2ee_encrypt_data_types_title => 'Tipos de datos';

  @override
  String get e2ee_encrypt_data_types_description =>
      'Esta configuración no cambia el protocolo. Controla qué tipos de datos se envían cifrados.';

  @override
  String get e2ee_encrypt_override_title =>
      'Configuración de cifrado para este chat';

  @override
  String get e2ee_encrypt_override_on => 'Se usa la configuración del chat.';

  @override
  String get e2ee_encrypt_override_off => 'Se hereda la configuración global.';

  @override
  String get e2ee_encrypt_text_title => 'Texto del mensaje';

  @override
  String get e2ee_encrypt_media_title => 'Adjuntos (multimedia/archivos)';

  @override
  String get e2ee_encrypt_override_hint =>
      'Para cambiar en este chat — activa la anulación.';

  @override
  String get sticker_default_pack_name => 'Mi paquete';

  @override
  String get sticker_new_pack_dialog_title => 'Nuevo paquete de stickers';

  @override
  String get sticker_pack_name_hint => 'Nombre';

  @override
  String get sticker_save_to_pack => 'Guardar en paquete de stickers';

  @override
  String get sticker_no_packs_hint =>
      'Sin paquetes. Crea uno en la pestaña Stickers.';

  @override
  String get sticker_new_pack_option => 'Nuevo paquete…';

  @override
  String get sticker_pick_image_or_gif => 'Elige una imagen o GIF';

  @override
  String sticker_send_failed(String error) {
    return 'Error al enviar: $error';
  }

  @override
  String get sticker_saved_to_pack => 'Guardado en paquete de stickers';

  @override
  String get sticker_save_gif_failed => 'No se pudo descargar o guardar el GIF';

  @override
  String get sticker_delete_pack_title => '¿Eliminar paquete?';

  @override
  String sticker_delete_pack_body(String name) {
    return '\"$name\" y todos los stickers dentro se eliminarán.';
  }

  @override
  String get sticker_pack_deleted => 'Paquete eliminado';

  @override
  String get sticker_pack_delete_failed => 'Error al eliminar el paquete';

  @override
  String get sticker_tab_emoji => 'emojis';

  @override
  String get sticker_tab_stickers => 'PEGATINAS';

  @override
  String get sticker_tab_gif => 'GIF';

  @override
  String get sticker_scope_my => 'Mío';

  @override
  String get sticker_scope_public => 'Pública';

  @override
  String get sticker_new_pack_tooltip => 'Nuevo paquete';

  @override
  String get sticker_pack_created => 'Paquete de stickers creado';

  @override
  String get sticker_no_packs_create => 'Sin paquetes de stickers. Crea uno.';

  @override
  String get sticker_public_packs_empty =>
      'No hay paquetes públicos configurados';

  @override
  String get sticker_section_recent => 'RECIENTES';

  @override
  String get sticker_pack_empty_hint =>
      'El paquete está vacío. Agrega desde el dispositivo (pestaña GIF — \"A mi paquete\").';

  @override
  String get sticker_delete_sticker_title => '¿Eliminar sticker?';

  @override
  String get sticker_deleted => 'Eliminado';

  @override
  String get sticker_gallery => 'Galería';

  @override
  String get sticker_gallery_subtitle =>
      'Fotos, PNG, GIF del dispositivo — directo al chat';

  @override
  String get gif_search_hint => 'Buscar GIF…';

  @override
  String gif_translated_hint(String query) {
    return 'Buscado: $query';
  }

  @override
  String get gif_search_unavailable =>
      'La búsqueda de GIF no está disponible temporalmente.';

  @override
  String get gif_filter_all => 'Todos';

  @override
  String get sticker_section_animated => 'ANIMADOS';

  @override
  String get sticker_emoji_unavailable =>
      'Emoji a texto no está disponible para esta ventana.';

  @override
  String get sticker_create_pack_hint => 'Crea un paquete con el botón +';

  @override
  String get sticker_public_packs_unavailable =>
      'Paquetes públicos aún no disponibles';

  @override
  String get composer_link_title => 'Enlace';

  @override
  String get composer_link_apply => 'Aplicar';

  @override
  String get composer_attach_title => 'Adjuntar';

  @override
  String get composer_attach_photo_video => 'Foto/Video';

  @override
  String get composer_attach_files => 'Archivos';

  @override
  String get composer_attach_video_circle => 'Video circular';

  @override
  String get composer_attach_location => 'Ubicación';

  @override
  String get composer_attach_poll => 'Encuesta';

  @override
  String get composer_attach_stickers => 'Pegatinas';

  @override
  String get composer_attach_clipboard => 'Portapapeles';

  @override
  String get composer_attach_text => 'Texto';

  @override
  String get meeting_create_poll => 'Crear encuesta';

  @override
  String get meeting_min_two_options =>
      'Se requieren al menos 2 opciones de respuesta';

  @override
  String meeting_error_with_details(String details) {
    return 'Error: $details';
  }

  @override
  String meeting_polls_load_error(String details) {
    return 'Error al cargar encuestas: $details';
  }

  @override
  String get meeting_no_polls_yet => 'Aún no hay encuestas';

  @override
  String get meeting_question_label => 'Pregunta';

  @override
  String get meeting_options_label => 'Opciones';

  @override
  String meeting_option_hint(int index) {
    return 'Opción $index';
  }

  @override
  String get meeting_add_option => 'Agregar opción';

  @override
  String get meeting_anonymous => 'Anónima';

  @override
  String get meeting_anonymous_subtitle =>
      'Quién puede ver las elecciones de otros';

  @override
  String get meeting_save_as_draft => 'Guardar como borrador';

  @override
  String get meeting_publish => 'Publicar';

  @override
  String get meeting_action_start => 'Iniciar';

  @override
  String get meeting_action_change_vote => 'Cambiar voto';

  @override
  String get meeting_action_restart => 'Reiniciar';

  @override
  String get meeting_action_stop => 'Detener';

  @override
  String meeting_vote_failed(String details) {
    return 'Voto no contado: $details';
  }

  @override
  String get meeting_status_ended => 'Finalizada';

  @override
  String get meeting_status_draft => 'Borrador';

  @override
  String get meeting_status_active => 'Activa';

  @override
  String get meeting_status_public => 'Pública';

  @override
  String meeting_votes_count(int count) {
    return '$count votos';
  }

  @override
  String meeting_goal_count(int count) {
    return 'Meta: $count';
  }

  @override
  String get meeting_hide => 'Ocultar';

  @override
  String get meeting_who_voted => 'Quién votó';

  @override
  String meeting_participants_tab(int count) {
    return 'Miembros ($count)';
  }

  @override
  String meeting_polls_tab_active(int count) {
    return 'Encuestas ($count)';
  }

  @override
  String get meeting_polls_tab => 'Encuestas';

  @override
  String meeting_chat_tab_unread(int count) {
    return 'Chat ($count)';
  }

  @override
  String get meeting_chat_tab => 'Charlar';

  @override
  String meeting_requests_tab(int count) {
    return 'Solicitudes ($count)';
  }

  @override
  String meeting_you_suffix(String name) {
    return '$name (Tú)';
  }

  @override
  String get meeting_host_label => 'Anfitrión';

  @override
  String get meeting_force_mute_mic => 'Silenciar micrófono';

  @override
  String get meeting_force_mute_camera => 'Apagar cámara';

  @override
  String get meeting_kick_from_room => 'Eliminar de la sala';

  @override
  String meeting_chat_load_error(Object error) {
    return 'No se pudo cargar el chat: $error';
  }

  @override
  String get meeting_no_requests => 'No hay nuevas solicitudes';

  @override
  String get meeting_no_messages_yet => 'Aún no hay mensajes';

  @override
  String meeting_file_too_large(String name) {
    return 'Archivo demasiado grande: $name';
  }

  @override
  String meeting_send_failed(String details) {
    return 'Error al enviar: $details';
  }

  @override
  String get meeting_edit_message_title => 'Editar mensaje';

  @override
  String meeting_save_failed(String details) {
    return 'Error al guardar: $details';
  }

  @override
  String get meeting_delete_message_title => '¿Eliminar mensaje?';

  @override
  String get meeting_delete_message_body =>
      'Los miembros verán \"Mensaje eliminado\".';

  @override
  String meeting_delete_failed(String details) {
    return 'Error al eliminar: $details';
  }

  @override
  String get meeting_message_hint => 'Mensaje…';

  @override
  String get meeting_message_deleted => 'Mensaje eliminado';

  @override
  String get meeting_message_edited => '• editado';

  @override
  String get meeting_copy_action => 'Copiar';

  @override
  String get meeting_edit_action => 'Editar';

  @override
  String get meeting_join_title => 'Unirse';

  @override
  String meeting_loading_error(String details) {
    return 'Error al cargar la reunión: $details';
  }

  @override
  String get meeting_not_found => 'Reunión no encontrada o cerrada';

  @override
  String get meeting_private_description =>
      'Reunión privada: el anfitrión decidirá si te permite entrar después de tu solicitud.';

  @override
  String get meeting_public_description =>
      'Reunión abierta: únete por enlace sin esperar.';

  @override
  String get meeting_your_name_label => 'Tu nombre';

  @override
  String get meeting_enter_name_error => 'Ingresa tu nombre';

  @override
  String get meeting_guest_name => 'Invitado';

  @override
  String get meeting_enter_room => 'Entrar a la sala';

  @override
  String get meeting_request_join => 'Solicitar unirse';

  @override
  String get meeting_approved_title => 'Aprobado';

  @override
  String get meeting_approved_subtitle => 'Redirigiendo a la sala…';

  @override
  String get meeting_denied_title => 'Denegado';

  @override
  String get meeting_denied_subtitle => 'El anfitrión denegó tu solicitud.';

  @override
  String get meeting_pending_title => 'Esperando aprobación';

  @override
  String get meeting_pending_subtitle =>
      'El anfitrión verá tu solicitud y decidirá cuándo dejarte entrar.';

  @override
  String meeting_load_error(String details) {
    return 'Error al cargar la reunión: $details';
  }

  @override
  String meeting_init_error(Object error) {
    return 'Error de inicialización: $error';
  }

  @override
  String meeting_participants_error(Object error) {
    return 'Miembros: $error';
  }

  @override
  String meeting_bg_unavailable(Object error) {
    return 'Fondo no disponible: $error';
  }

  @override
  String get meeting_leave => 'Salir';

  @override
  String get meeting_screen_share_ios =>
      'Compartir pantalla en iOS requiere Broadcast Extension (próximamente)';

  @override
  String meeting_screen_share_failed(String details) {
    return 'Error al iniciar compartir pantalla: $details';
  }

  @override
  String get meeting_tooltip_speaker_mode => 'Modo orador';

  @override
  String get meeting_tooltip_grid_mode => 'Modo cuadrícula';

  @override
  String get meeting_tooltip_copy_link =>
      'Copiar enlace (acceso por navegador)';

  @override
  String get meeting_mic_on => 'Activar micrófono';

  @override
  String get meeting_mic_off => 'Silenciar';

  @override
  String get meeting_camera_on => 'Cámara encendida';

  @override
  String get meeting_camera_off => 'Cámara apagada';

  @override
  String get meeting_switch_camera => 'Cambiar';

  @override
  String get meeting_hand_lower => 'Bajar';

  @override
  String get meeting_hand_raise => 'Mano';

  @override
  String get meeting_reaction => 'Reacción';

  @override
  String get meeting_screen_stop => 'Detener';

  @override
  String get meeting_screen_label => 'Pantalla';

  @override
  String get meeting_bg_off => 'Fondo';

  @override
  String get meeting_bg_blur => 'Difuminar';

  @override
  String get meeting_bg_image => 'Imagen';

  @override
  String get meeting_participants_button => 'Miembros';

  @override
  String get meeting_notifications_button => 'Actividad';

  @override
  String get meeting_pip_button => 'Minimizar';

  @override
  String get settings_chats_bottom_nav_icons_title =>
      'Iconos de navegación inferior';

  @override
  String get settings_chats_bottom_nav_icons_subtitle =>
      'Elige iconos y estilo visual como en la web.';

  @override
  String get settings_chats_nav_colorful => 'Colorido';

  @override
  String get settings_chats_nav_minimal => 'Minimalista';

  @override
  String get settings_chats_nav_global_title => 'Para todos los iconos';

  @override
  String get settings_chats_nav_global_subtitle =>
      'Capa global: color, tamaño, ancho de trazo y mosaico de fondo.';

  @override
  String get settings_chats_reset_tooltip => 'Restablecer';

  @override
  String get settings_chats_collapse => 'Colapsar';

  @override
  String get settings_chats_customize => 'Personalizar';

  @override
  String get settings_chats_reset_item_tooltip => 'Restablecer';

  @override
  String get settings_chats_style_tooltip => 'Estilo';

  @override
  String get settings_chats_icon_size => 'Tamaño del icono';

  @override
  String get settings_chats_stroke_width => 'Ancho del trazo';

  @override
  String get settings_chats_default => 'Predeterminado';

  @override
  String get settings_chats_icon_search_hint_en => 'Buscar por nombre...';

  @override
  String get settings_chats_emoji_effects => 'Efectos de emoji';

  @override
  String get settings_chats_emoji_effects_subtitle =>
      'Perfil de animación para emoji a pantalla completa al tocar un solo emoji en el chat.';

  @override
  String get settings_chats_emoji_lite_desc =>
      'Lite: carga mínima y máxima fluidez en dispositivos de gama baja.';

  @override
  String get settings_chats_emoji_balanced_desc =>
      'Equilibrado: compromiso automático entre rendimiento y expresividad.';

  @override
  String get settings_chats_emoji_cinematic_desc =>
      'Cinemático: máximo de partículas y profundidad para efecto impactante.';

  @override
  String get settings_chats_preview_incoming_msg => '¡Oye! ¿Cómo estás?';

  @override
  String get settings_chats_preview_outgoing_msg => '¡Bien, gracias!';

  @override
  String get settings_chats_preview_hello => 'Hola';

  @override
  String get chat_theme_title => 'Tema del chat';

  @override
  String chat_theme_error_save(String error) {
    return 'Error al guardar el fondo: $error';
  }

  @override
  String chat_theme_error_upload(String error) {
    return 'Error al subir el fondo: $error';
  }

  @override
  String get chat_theme_delete_title => '¿Eliminar fondo de la galería?';

  @override
  String get chat_theme_delete_body =>
      'La imagen se eliminará de tu lista de fondos. Puedes elegir otro para este chat.';

  @override
  String chat_theme_error_delete(String error) {
    return 'Error al eliminar: $error';
  }

  @override
  String get chat_theme_banner =>
      'El fondo de este chat es solo para ti. La configuración global del chat en \"Configuración del chat\" permanece sin cambios.';

  @override
  String get chat_theme_current_bg => 'Fondo actual';

  @override
  String get chat_theme_default_global =>
      'Predeterminado (configuración global)';

  @override
  String get chat_theme_presets => 'Preajustes';

  @override
  String get chat_theme_global_tile => 'Global';

  @override
  String get chat_theme_pick_hint => 'Elige un preset o foto de la galería';

  @override
  String get contacts_title => 'Contactos';

  @override
  String get contacts_add_phone_prompt =>
      'Agrega un número de teléfono en tu perfil para buscar contactos por número.';

  @override
  String get contacts_fallback_profile => 'Perfil';

  @override
  String get contacts_fallback_user => 'Usuario';

  @override
  String get contacts_status_online => 'en línea';

  @override
  String get contacts_status_recently => 'Visto recientemente';

  @override
  String contacts_status_today_at(String time) {
    return 'Visto a las $time';
  }

  @override
  String get contacts_status_yesterday => 'Visto ayer';

  @override
  String get contacts_status_year_ago => 'Visto hace un año';

  @override
  String contacts_status_years_ago(String years) {
    return 'Visto hace $years';
  }

  @override
  String contacts_status_date(String date) {
    return 'Visto el $date';
  }

  @override
  String get contacts_empty_state =>
      'No se encontraron contactos.\nToca el botón de la derecha para sincronizar tu agenda.';

  @override
  String get add_contact_title => 'Nuevo contacto';

  @override
  String get add_contact_sync_off =>
      'La sincronización está desactivada en la app.';

  @override
  String get add_contact_enable_system_access =>
      'Activa el acceso a contactos de LighChat en la configuración del sistema.';

  @override
  String get add_contact_sync_on => 'Sincronización activada';

  @override
  String get add_contact_sync_failed =>
      'No se pudo activar la sincronización de contactos';

  @override
  String get add_contact_invalid_phone =>
      'Ingresa un número de teléfono válido';

  @override
  String get add_contact_not_found_by_phone =>
      'No se encontró contacto para este número';

  @override
  String get add_contact_found => 'Contacto encontrado';

  @override
  String add_contact_search_error(String error) {
    return 'Error en la búsqueda: $error';
  }

  @override
  String get add_contact_qr_no_profile =>
      'El código QR no contiene un perfil de LighChat';

  @override
  String get add_contact_qr_own_profile => 'Este es tu propio perfil';

  @override
  String get add_contact_qr_profile_not_found =>
      'Perfil del código QR no encontrado';

  @override
  String get add_contact_qr_found => 'Contacto encontrado por código QR';

  @override
  String add_contact_qr_read_error(String error) {
    return 'No se pudo leer el código QR: $error';
  }

  @override
  String get add_contact_cannot_add_user =>
      'No se puede agregar a este usuario';

  @override
  String add_contact_add_error(String error) {
    return 'No se pudo agregar el contacto: $error';
  }

  @override
  String get add_contact_country_search_hint => 'Buscar por país o código';

  @override
  String get add_contact_sync_with_phone => 'Sincronizar con teléfono';

  @override
  String get add_contact_add_by_qr => 'Agregar por código QR';

  @override
  String get add_contact_results_unavailable => 'Resultados aún no disponibles';

  @override
  String add_contact_profile_load_error(String error) {
    return 'No se pudo cargar el contacto: $error';
  }

  @override
  String get add_contact_profile_not_found => 'Perfil no encontrado';

  @override
  String get add_contact_badge_already_added => 'Ya agregado';

  @override
  String get add_contact_badge_new => 'Nuevo contacto';

  @override
  String get add_contact_badge_unavailable => 'No disponible';

  @override
  String get add_contact_open_contact => 'Abrir contacto';

  @override
  String get add_contact_add_to_contacts => 'Agregar a contactos';

  @override
  String get add_contact_add_unavailable => 'No se puede agregar';

  @override
  String get add_contact_searching => 'Buscando contacto...';

  @override
  String get add_contact_scan_qr_title => 'Escanear código QR';

  @override
  String get add_contact_flash_tooltip => 'Destello';

  @override
  String get add_contact_scan_qr_hint =>
      'Apunta tu cámara al código QR de un perfil de LighChat';

  @override
  String get contacts_edit_enter_name => 'Ingresa el nombre del contacto.';

  @override
  String contacts_edit_save_error(String error) {
    return 'No se pudo guardar el contacto: $error';
  }

  @override
  String get contacts_edit_first_name_hint => 'Nombre';

  @override
  String get contacts_edit_last_name_hint => 'Apellido';

  @override
  String get contacts_edit_name_disclaimer =>
      'Este nombre solo es visible para ti: en chats, búsqueda y la lista de contactos.';

  @override
  String contacts_edit_error(String error) {
    return 'Error: $error';
  }

  @override
  String get chat_settings_color_default => 'Predeterminado';

  @override
  String get chat_settings_color_lilac => 'Lila';

  @override
  String get chat_settings_color_pink => 'Rosa';

  @override
  String get chat_settings_color_green => 'Verde';

  @override
  String get chat_settings_color_coral => 'Coral';

  @override
  String get chat_settings_color_mint => 'Menta';

  @override
  String get chat_settings_color_sky => 'Cielo';

  @override
  String get chat_settings_color_purple => 'Púrpura';

  @override
  String get chat_settings_color_crimson => 'Carmesí';

  @override
  String get chat_settings_color_tiffany => 'tiffany';

  @override
  String get chat_settings_color_yellow => 'Amarillo';

  @override
  String get chat_settings_color_powder => 'Polvos';

  @override
  String get chat_settings_color_turquoise => 'Turquesa';

  @override
  String get chat_settings_color_blue => 'Azul';

  @override
  String get chat_settings_color_sunset => 'Atardecer';

  @override
  String get chat_settings_color_tender => 'Suave';

  @override
  String get chat_settings_color_lime => 'Lima';

  @override
  String get chat_settings_color_graphite => 'Grafito';

  @override
  String get chat_settings_color_no_bg => 'Sin fondo';

  @override
  String get chat_settings_icon_color => 'Color del icono';

  @override
  String get chat_settings_icon_size => 'Tamaño del icono';

  @override
  String get chat_settings_stroke_width => 'Ancho del trazo';

  @override
  String get chat_settings_tile_background => 'Mosaico de fondo';

  @override
  String get chat_settings_bottom_nav_icons => 'Iconos de navegación inferior';

  @override
  String get chat_settings_bottom_nav_description =>
      'Elige iconos y estilo visual como en la web.';

  @override
  String get chat_settings_bottom_nav_global_description =>
      'Capa compartida: color, tamaño, trazo y mosaico de fondo.';

  @override
  String get chat_settings_colorful => 'Colorido';

  @override
  String get chat_settings_minimalism => 'Minimalista';

  @override
  String get chat_settings_for_all_icons => 'Para todos los iconos';

  @override
  String get chat_settings_customize => 'Personalizar';

  @override
  String get chat_settings_hide => 'Ocultar';

  @override
  String get chat_settings_reset => 'Restablecer';

  @override
  String get chat_settings_reset_item => 'Restablecer';

  @override
  String get chat_settings_style => 'Estilo';

  @override
  String get chat_settings_select => 'Seleccionar';

  @override
  String get chat_settings_reset_size => 'Restablecer tamaño';

  @override
  String get chat_settings_reset_stroke => 'Restablecer trazo';

  @override
  String get chat_settings_default_gradient => 'Degradado predeterminado';

  @override
  String get chat_settings_inherit_global => 'Heredar de global';

  @override
  String get chat_settings_no_bg_on => 'Sin fondo (activado)';

  @override
  String get chat_settings_no_bg => 'Sin fondo';

  @override
  String get chat_settings_outgoing_messages => 'Mensajes enviados';

  @override
  String get chat_settings_incoming_messages => 'Mensajes recibidos';

  @override
  String get chat_settings_font_size => 'Tamaño de fuente';

  @override
  String get chat_settings_font_small => 'Pequeño';

  @override
  String get chat_settings_font_medium => 'Mediano';

  @override
  String get chat_settings_font_large => 'Grande';

  @override
  String get chat_settings_bubble_shape => 'Forma de burbuja';

  @override
  String get chat_settings_bubble_rounded => 'Redondeada';

  @override
  String get chat_settings_bubble_square => 'Cuadrada';

  @override
  String get chat_settings_chat_background => 'Fondo del chat';

  @override
  String get chat_settings_background_hint =>
      'Elige una foto de la galería o personaliza';

  @override
  String get chat_settings_builtin_wallpapers_heading => 'Fondos de marca';

  @override
  String get chat_settings_show_all_wallpapers => 'Ver todos los fondos';

  @override
  String get chat_settings_animated_wallpapers_heading => 'Fondos animados';

  @override
  String get chat_settings_animated_wallpapers_hint =>
      'Se reproduce una vez al abrir el chat';

  @override
  String get chat_settings_emoji_effects => 'Efectos de emoji';

  @override
  String get chat_settings_emoji_description =>
      'Perfil de animación para explosión de emoji a pantalla completa al tocar en el chat.';

  @override
  String get chat_settings_emoji_lite =>
      'Lite: carga mínima, más fluido en dispositivos de gama baja.';

  @override
  String get chat_settings_emoji_cinematic =>
      'Cinemático: máximo de partículas y profundidad para un efecto impactante.';

  @override
  String get chat_settings_emoji_balanced =>
      'Equilibrado: compromiso automático entre rendimiento y expresividad.';

  @override
  String get chat_settings_additional => 'Adicional';

  @override
  String get chat_settings_show_time => 'Mostrar hora';

  @override
  String get chat_settings_show_time_hint =>
      'Hora de envío debajo de los mensajes';

  @override
  String get chat_settings_auto_translate => 'Auto-traducir entrantes';

  @override
  String get chat_settings_auto_translate_hint =>
      'Mensajes en otros idiomas se traducen en el dispositivo a tu idioma';

  @override
  String get message_auto_translated_label => 'Traducido';

  @override
  String get message_show_original => 'Mostrar original';

  @override
  String get message_show_translation => 'Mostrar traducción';

  @override
  String get chat_settings_reset_all => 'Restablecer configuración';

  @override
  String get chat_settings_preview_incoming => '¡Hola! ¿Cómo estás?';

  @override
  String get chat_settings_preview_outgoing => '¡Bien, gracias!';

  @override
  String get chat_settings_preview_hello => 'Hola';

  @override
  String chat_settings_icon_picker_title(String label) {
    return 'Icono: \"$label\"';
  }

  @override
  String get chat_settings_search_hint => 'Buscar por nombre (ing.)...';

  @override
  String meeting_tab_participants(Object count) {
    return 'Miembros ($count)';
  }

  @override
  String get meeting_tab_polls => 'Encuestas';

  @override
  String meeting_tab_polls_count(Object count) {
    return 'Encuestas ($count)';
  }

  @override
  String get meeting_tab_chat => 'Charlar';

  @override
  String meeting_tab_chat_count(Object count) {
    return 'Chat ($count)';
  }

  @override
  String meeting_tab_requests(Object count) {
    return 'Solicitudes ($count)';
  }

  @override
  String get meeting_kick => 'Eliminar de la sala';

  @override
  String meeting_file_too_big(Object name) {
    return 'Archivo muy grande: $name';
  }

  @override
  String meeting_send_error(Object error) {
    return 'No se pudo enviar: $error';
  }

  @override
  String meeting_save_error(Object error) {
    return 'No se pudo guardar: $error';
  }

  @override
  String meeting_delete_error(Object error) {
    return 'No se pudo eliminar: $error';
  }

  @override
  String get meeting_no_messages => 'Aún no hay mensajes';

  @override
  String get meeting_join_enter_name => 'Ingresa tu nombre';

  @override
  String get meeting_join_guest => 'Invitado';

  @override
  String get meeting_join_as_label => 'Te unirás como';

  @override
  String get meeting_lobby_camera_blocked =>
      'El permiso de la cámara está denegado. Te unirás con la cámara apagada.';

  @override
  String get meeting_join_button => 'Unirse';

  @override
  String meeting_join_load_error(Object error) {
    return 'Error al cargar la reunión: $error';
  }

  @override
  String get meeting_private_hint =>
      'Reunión privada: el anfitrión decidirá si te permite entrar después de tu solicitud.';

  @override
  String get meeting_public_hint =>
      'Reunión abierta: únete por enlace sin esperar.';

  @override
  String get meeting_name_label => 'Tu nombre';

  @override
  String get meeting_waiting_title => 'Esperando aprobación';

  @override
  String get meeting_waiting_subtitle =>
      'El anfitrión verá tu solicitud y decidirá cuándo dejarte entrar.';

  @override
  String get meeting_screen_share_ios_hint =>
      'Compartir pantalla en iOS requiere una Broadcast Extension (en desarrollo).';

  @override
  String meeting_screen_share_error(Object error) {
    return 'No se pudo iniciar compartir pantalla: $error';
  }

  @override
  String get meeting_speaker_mode => 'Modo orador';

  @override
  String get meeting_grid_mode => 'Modo cuadrícula';

  @override
  String get meeting_copy_link_tooltip =>
      'Copiar enlace (acceso por navegador)';

  @override
  String get group_members_subtitle_creator => 'Creador del grupo';

  @override
  String get group_members_subtitle_admin => 'Administrador';

  @override
  String get group_members_subtitle_member => 'Miembro';

  @override
  String group_members_total_count(int count) {
    return 'Total: $count';
  }

  @override
  String get group_members_copy_invite_tooltip => 'Copiar enlace de invitación';

  @override
  String get group_members_add_member_tooltip => 'Agregar miembro';

  @override
  String get group_members_invite_copied => 'Enlace de invitación copiado';

  @override
  String group_members_copy_link_error(String error) {
    return 'Error al copiar el enlace: $error';
  }

  @override
  String get group_members_added => 'Miembros agregados';

  @override
  String get group_members_revoke_admin_title =>
      '¿Revocar privilegios de administrador?';

  @override
  String group_members_revoke_admin_body(String name) {
    return '$name perderá privilegios de administrador. Permanecerá en el grupo como miembro regular.';
  }

  @override
  String get group_members_grant_admin_title =>
      '¿Otorgar privilegios de administrador?';

  @override
  String group_members_grant_admin_body(String name) {
    return '$name recibirá privilegios de administrador: podrá editar el grupo, eliminar miembros y gestionar mensajes.';
  }

  @override
  String get group_members_revoke_admin_action => 'Revocar';

  @override
  String get group_members_grant_admin_action => 'Otorgar';

  @override
  String get group_members_remove_title => '¿Eliminar miembro?';

  @override
  String group_members_remove_body(String name) {
    return '$name será eliminado del grupo. Puedes deshacer esto agregando al miembro de nuevo.';
  }

  @override
  String get group_members_remove_action => 'Eliminar';

  @override
  String get group_members_removed => 'Miembro eliminado';

  @override
  String get group_members_menu_revoke_admin => 'Quitar administrador';

  @override
  String get group_members_menu_grant_admin => 'Hacer administrador';

  @override
  String get group_members_menu_remove => 'Eliminar del grupo';

  @override
  String get group_members_creator_badge => 'CREADOR';

  @override
  String get group_members_add_title => 'Agregar miembros';

  @override
  String get group_members_search_contacts => 'Buscar contactos';

  @override
  String get group_members_all_in_group =>
      'Todos tus contactos ya están en el grupo.';

  @override
  String get group_members_nobody_found => 'No se encontró a nadie.';

  @override
  String get group_members_user_fallback => 'Usuario';

  @override
  String get group_members_select_members => 'Seleccionar miembros';

  @override
  String group_members_add_count(int count) {
    return 'Agregar ($count)';
  }

  @override
  String group_members_contacts_load_error(String error) {
    return 'Error al cargar contactos: $error';
  }

  @override
  String group_members_auth_error(String error) {
    return 'Error de autorización: $error';
  }

  @override
  String group_members_add_failed(String error) {
    return 'Error al agregar miembros: $error';
  }

  @override
  String get group_not_found => 'Grupo no encontrado.';

  @override
  String get group_not_member => 'No eres miembro de este grupo.';

  @override
  String get poll_create_title => 'Encuesta del chat';

  @override
  String get poll_question_label => 'Pregunta';

  @override
  String get poll_question_hint => 'Ej.: ¿A qué hora nos vemos?';

  @override
  String get poll_description_label => 'Descripción (opcional)';

  @override
  String get poll_options_title => 'Opciones';

  @override
  String poll_option_hint(int index) {
    return 'Opción $index';
  }

  @override
  String get poll_add_option => 'Agregar opción';

  @override
  String get poll_switch_anonymous => 'Votación anónima';

  @override
  String get poll_switch_anonymous_sub => 'No mostrar quién votó por qué';

  @override
  String get poll_switch_multi => 'Respuestas múltiples';

  @override
  String get poll_switch_multi_sub => 'Se pueden seleccionar varias opciones';

  @override
  String get poll_switch_add_options => 'Agregar opciones';

  @override
  String get poll_switch_add_options_sub =>
      'Los participantes pueden sugerir sus propias opciones';

  @override
  String get poll_switch_revote => 'Puede cambiar voto';

  @override
  String get poll_switch_revote_sub =>
      'Se permite cambiar el voto hasta que cierre la encuesta';

  @override
  String get poll_switch_shuffle => 'Mezclar opciones';

  @override
  String get poll_switch_shuffle_sub =>
      'Orden diferente para cada participante';

  @override
  String get poll_switch_quiz => 'Modo quiz';

  @override
  String get poll_switch_quiz_sub => 'Una respuesta correcta';

  @override
  String get poll_correct_option_label => 'Opción correcta';

  @override
  String get poll_quiz_explanation_label => 'Explicación (opcional)';

  @override
  String get poll_close_by_time => 'Cerrar por tiempo';

  @override
  String get poll_close_not_set => 'No establecido';

  @override
  String get poll_close_reset => 'Restablecer fecha límite';

  @override
  String get poll_publish => 'Publicar';

  @override
  String get poll_error_empty_question => 'Ingresa una pregunta';

  @override
  String get poll_error_min_options => 'Se requieren al menos 2 opciones';

  @override
  String get poll_error_select_correct => 'Selecciona la opción correcta';

  @override
  String get poll_error_future_time => 'La hora de cierre debe ser futura';

  @override
  String get poll_unavailable => 'Encuesta no disponible';

  @override
  String get poll_loading => 'Cargando encuesta…';

  @override
  String get poll_not_found => 'Encuesta no encontrada';

  @override
  String get poll_status_cancelled => 'Cancelada';

  @override
  String get poll_status_ended => 'Finalizada';

  @override
  String get poll_status_draft => 'Borrador';

  @override
  String get poll_status_active => 'Activa';

  @override
  String get poll_badge_public => 'Pública';

  @override
  String get poll_badge_multi => 'Respuestas múltiples';

  @override
  String get poll_badge_quiz => 'Prueba';

  @override
  String get poll_menu_restart => 'Reiniciar';

  @override
  String get poll_menu_end => 'Finalizar';

  @override
  String get poll_menu_delete => 'Eliminar';

  @override
  String get poll_submit_vote => 'Enviar voto';

  @override
  String get poll_suggest_option_hint => 'Sugerir una opción';

  @override
  String get poll_revote => 'Cambiar voto';

  @override
  String poll_votes_count(int count) {
    return '$count votos';
  }

  @override
  String get poll_show_voters => 'Quién votó';

  @override
  String get poll_hide_voters => 'Ocultar';

  @override
  String get poll_vote_error => 'Error al votar';

  @override
  String get poll_add_option_error => 'Error al agregar opción';

  @override
  String get poll_error_generic => 'Error';

  @override
  String get durak_your_turn => 'Tu turno';

  @override
  String get durak_winner_label => 'Ganador';

  @override
  String get durak_rematch => 'Jugar de nuevo';

  @override
  String get durak_surrender_tooltip => 'Terminar juego';

  @override
  String get durak_close_tooltip => 'Cerrar';

  @override
  String get durak_fx_took => 'Tomó';

  @override
  String get durak_fx_beat => 'Ganado';

  @override
  String get durak_opponent_role_defend => 'DEF';

  @override
  String get durak_opponent_role_attack => 'ATK';

  @override
  String get durak_opponent_role_throwin => 'LAN';

  @override
  String get durak_foul_banner_title => '¡Tramposo! Perdido:';

  @override
  String get durak_pending_resolution_attacker =>
      'Esperando verificación de falta… Presiona \"Confirmar ganado\" si todos están de acuerdo.';

  @override
  String get durak_pending_resolution_other =>
      'Esperando verificación de falta… Puedes presionar \"¡Falta!\" si notaste trampa.';

  @override
  String durak_tournament_played(int finished, int total) {
    return 'Jugados $finished de $total';
  }

  @override
  String get durak_tournament_finished => 'Torneo terminado';

  @override
  String get durak_tournament_next => 'Siguiente juego del torneo';

  @override
  String get durak_single_game => 'Juego individual';

  @override
  String get durak_tournament_total_games_title =>
      '¿Cuántos juegos en el torneo?';

  @override
  String get durak_finish_game_tooltip => 'Terminar juego';

  @override
  String get durak_lobby_game_unavailable =>
      'El juego no está disponible o fue eliminado';

  @override
  String get durak_lobby_back_tooltip => 'Atrás';

  @override
  String get durak_lobby_waiting => 'Esperando al oponente…';

  @override
  String get durak_lobby_start => 'Iniciar juego';

  @override
  String get durak_lobby_waiting_short => 'Esperando…';

  @override
  String get durak_lobby_ready => 'Listo';

  @override
  String get durak_lobby_empty_slot => 'Esperando…';

  @override
  String get durak_settings_timer_subtitle => '15 segundos por defecto';

  @override
  String get durak_dm_game_active => 'Juego de Durak en progreso';

  @override
  String get durak_dm_game_created => 'Juego de Durak creado';

  @override
  String get game_durak_subtitle => 'Juego individual o torneo';

  @override
  String get group_member_write_dm => 'Enviar mensaje directo';

  @override
  String get group_member_open_dm_hint => 'Abrir chat directo con miembro';

  @override
  String get group_member_profile_not_loaded =>
      'Perfil del miembro aún no cargado.';

  @override
  String group_member_open_dm_error(String error) {
    return 'Error al abrir el chat directo: $error';
  }

  @override
  String get group_avatar_photo_title => 'Foto del grupo';

  @override
  String get group_avatar_add_photo => 'Agregar foto';

  @override
  String get group_avatar_change => 'Cambiar avatar';

  @override
  String get group_avatar_remove => 'Eliminar avatar';

  @override
  String group_avatar_process_error(String error) {
    return 'Error al procesar la foto: $error';
  }

  @override
  String get group_mention_no_matches => 'Sin coincidencias';

  @override
  String get durak_error_defense_does_not_beat =>
      'Esta carta no gana a la carta de ataque';

  @override
  String get durak_error_only_attacker_first => 'El atacante va primero';

  @override
  String get durak_error_defender_cannot_attack =>
      'El defensor no puede lanzar ahora';

  @override
  String get durak_error_not_allowed_throwin =>
      'No puedes lanzar en esta ronda';

  @override
  String get durak_error_throwin_not_your_turn =>
      'Otro jugador está lanzando ahora';

  @override
  String get durak_error_rank_not_allowed =>
      'Solo puedes lanzar cartas del mismo rango';

  @override
  String get durak_error_cannot_throw_in => 'No se pueden lanzar más cartas';

  @override
  String get durak_error_card_not_in_hand => 'Esta carta ya no está en tu mano';

  @override
  String get durak_error_already_defended => 'Esta carta ya está defendida';

  @override
  String get durak_error_bad_attack_index =>
      'Selecciona una carta de ataque para defender';

  @override
  String get durak_error_only_defender => 'Otro jugador está defendiendo ahora';

  @override
  String get durak_error_defender_already_taking =>
      'El defensor ya está tomando cartas';

  @override
  String get durak_error_game_not_active => 'El juego ya no está activo';

  @override
  String get durak_error_not_in_lobby => 'La sala ya ha iniciado';

  @override
  String get durak_error_game_already_active => 'El juego ya ha iniciado';

  @override
  String get durak_error_active_game_exists =>
      'Ya hay un juego activo en este chat';

  @override
  String get durak_error_resolution_pending =>
      'Termina primero el movimiento disputado';

  @override
  String get durak_error_rematch_failed =>
      'Error al preparar la revancha. Por favor intenta de nuevo';

  @override
  String get durak_error_unauthenticated => 'Necesitas iniciar sesión';

  @override
  String get durak_error_permission_denied =>
      'Esta acción no está disponible para ti';

  @override
  String get durak_error_invalid_argument => 'Movimiento no válido';

  @override
  String get durak_error_failed_precondition =>
      'El movimiento no está disponible en este momento';

  @override
  String get durak_error_server =>
      'Error al ejecutar el movimiento. Por favor intenta de nuevo';

  @override
  String pinned_count(int count) {
    return 'Fijados: $count';
  }

  @override
  String get pinned_single => 'Fijado';

  @override
  String get pinned_unpin_tooltip => 'Desfijar';

  @override
  String get pinned_type_image => 'Imagen';

  @override
  String get pinned_type_video => 'Video';

  @override
  String get pinned_type_video_circle => 'Video circular';

  @override
  String get pinned_type_voice => 'Mensaje de voz';

  @override
  String get pinned_type_poll => 'Encuesta';

  @override
  String get pinned_type_link => 'Enlace';

  @override
  String get pinned_type_location => 'Ubicación';

  @override
  String get pinned_type_sticker => 'Etiqueta engomada';

  @override
  String get pinned_type_file => 'Archivo';

  @override
  String get call_entry_login_required_title => 'Se requiere iniciar sesión';

  @override
  String get call_entry_login_required_subtitle =>
      'Abre la app e inicia sesión en tu cuenta.';

  @override
  String get call_entry_not_found_title => 'Llamada no encontrada';

  @override
  String get call_entry_not_found_subtitle =>
      'La llamada ya finalizó o fue eliminada. Regresando a llamadas…';

  @override
  String get call_entry_to_calls => 'Ir a llamadas';

  @override
  String get call_entry_ended_title => 'Llamada finalizada';

  @override
  String get call_entry_ended_subtitle =>
      'Esta llamada ya no está disponible. Regresando a llamadas…';

  @override
  String get call_entry_caller_fallback => 'Llamante';

  @override
  String get call_entry_opening_title => 'Abriendo llamada…';

  @override
  String get call_entry_connecting_video => 'Conectando a videollamada';

  @override
  String get call_entry_connecting_audio => 'Conectando a llamada de audio';

  @override
  String get call_entry_loading_subtitle => 'Cargando datos de la llamada';

  @override
  String get call_entry_error_title => 'Error al abrir la llamada';

  @override
  String chat_theme_save_error(Object error) {
    return 'Error al guardar el fondo: $error';
  }

  @override
  String chat_theme_load_error(Object error) {
    return 'Error al cargar el fondo: $error';
  }

  @override
  String chat_theme_delete_error(Object error) {
    return 'Error al eliminar: $error';
  }

  @override
  String get chat_theme_description =>
      'El fondo de esta conversación solo es visible para ti. La configuración global del chat en la sección de Configuración del chat no se ve afectada.';

  @override
  String get chat_theme_default_bg => 'Predeterminado (configuración global)';

  @override
  String get chat_theme_global_label => 'Global';

  @override
  String get chat_theme_hint => 'Elige un preset o foto de la galería';

  @override
  String get date_today => 'Hoy';

  @override
  String get date_yesterday => 'Ayer';

  @override
  String get date_month_1 => 'Enero';

  @override
  String get date_month_2 => 'Febrero';

  @override
  String get date_month_3 => 'Marzo';

  @override
  String get date_month_4 => 'Abril';

  @override
  String get date_month_5 => 'Mayo';

  @override
  String get date_month_6 => 'Junio';

  @override
  String get date_month_7 => 'Julio';

  @override
  String get date_month_8 => 'Agosto';

  @override
  String get date_month_9 => 'Septiembre';

  @override
  String get date_month_10 => 'Octubre';

  @override
  String get date_month_11 => 'Noviembre';

  @override
  String get date_month_12 => 'Diciembre';

  @override
  String get video_circle_camera_unavailable => 'Cámara no disponible';

  @override
  String video_circle_camera_error(Object error) {
    return 'Error al abrir la cámara: $error';
  }

  @override
  String video_circle_record_error(Object error) {
    return 'Error de grabación: $error';
  }

  @override
  String get video_circle_file_not_found =>
      'Archivo de grabación no encontrado';

  @override
  String get video_circle_play_error => 'Error al reproducir la grabación';

  @override
  String video_circle_send_error(Object error) {
    return 'Error al enviar: $error';
  }

  @override
  String video_circle_switch_error(Object error) {
    return 'Error al cambiar de cámara: $error';
  }

  @override
  String video_circle_pause_error_detail(Object description, Object code) {
    return 'Pausa no disponible: $description ($code)';
  }

  @override
  String video_circle_pause_error(Object error) {
    return 'Pausar grabación: $error';
  }

  @override
  String get video_circle_camera_fallback_error => 'Error de cámara';

  @override
  String get video_circle_retry => 'Reintentar';

  @override
  String get video_circle_sending => 'Enviando...';

  @override
  String get video_circle_recorded => 'Video circular grabado';

  @override
  String get video_circle_swipe_cancel =>
      'Desliza a la izquierda para cancelar';

  @override
  String media_screen_error(Object error) {
    return 'Error al cargar multimedia: $error';
  }

  @override
  String get media_screen_title => 'Multimedia, enlaces y archivos';

  @override
  String get media_tab_media => 'Multimedia';

  @override
  String get media_tab_circles => 'Círculos';

  @override
  String get media_tab_files => 'Archivos';

  @override
  String get media_tab_links => 'Enlaces';

  @override
  String get media_tab_audio => 'Audio';

  @override
  String get media_empty_files => 'Sin archivos';

  @override
  String get media_empty_media => 'Sin multimedia';

  @override
  String get media_attachment_fallback => 'Adjunto';

  @override
  String get media_empty_circles => 'Sin videos circulares';

  @override
  String get media_empty_links => 'Sin enlaces';

  @override
  String get media_empty_audio => 'Sin mensajes de voz';

  @override
  String get media_sender_you => 'Tú';

  @override
  String get media_sender_fallback => 'Participante';

  @override
  String get call_detail_login_required => 'Se requiere iniciar sesión.';

  @override
  String get call_detail_not_found => 'Llamada no encontrada o sin acceso.';

  @override
  String get call_detail_unknown => 'Desconocido';

  @override
  String get call_detail_title => 'Detalles de la llamada';

  @override
  String get call_detail_video => 'Videollamada';

  @override
  String get call_detail_audio => 'Llamada de audio';

  @override
  String get call_detail_outgoing => 'Saliente';

  @override
  String get call_detail_incoming => 'Entrante';

  @override
  String get call_detail_date_label => 'Fecha:';

  @override
  String get call_detail_duration_label => 'Duración:';

  @override
  String get call_detail_call_button => 'Llamar';

  @override
  String get call_detail_video_button => 'Video';

  @override
  String call_detail_error(Object error) {
    return 'Error: $error';
  }

  @override
  String get durak_took => 'Tomó';

  @override
  String get durak_beaten => 'Ganado';

  @override
  String get durak_end_game_tooltip => 'Terminar juego';

  @override
  String get durak_role_beats => 'DEF';

  @override
  String get durak_role_move => 'MOV';

  @override
  String get durak_role_throw => 'LAN';

  @override
  String get durak_cheater_label => '¡Tramposo! Perdido:';

  @override
  String get durak_waiting_foll_confirm =>
      'Esperando que canten falta… Presiona \"Confirmar ganado\" si todos están de acuerdo.';

  @override
  String get durak_waiting_foll_call =>
      'Esperando que canten falta… Ahora puedes presionar \"¡Falta!\" si viste trampa.';

  @override
  String get durak_winner => 'Ganador';

  @override
  String get durak_play_again => 'Jugar de nuevo';

  @override
  String durak_games_progress(Object finished, Object total) {
    return 'Jugados $finished de $total';
  }

  @override
  String get durak_next_round => 'Siguiente ronda del torneo';

  @override
  String audio_call_error(Object error) {
    return 'Error de llamada: $error';
  }

  @override
  String get audio_call_ended => 'Llamada finalizada';

  @override
  String get audio_call_missed => 'Llamada perdida';

  @override
  String get audio_call_cancelled => 'Llamada cancelada';

  @override
  String get audio_call_offer_not_ready =>
      'Oferta aún no lista, intenta de nuevo';

  @override
  String get audio_call_invalid_data => 'Datos de llamada no válidos';

  @override
  String audio_call_accept_error(Object error) {
    return 'Error al aceptar la llamada: $error';
  }

  @override
  String get audio_call_incoming => 'Llamada de audio entrante';

  @override
  String get audio_call_calling => 'Llamada de audio…';

  @override
  String privacy_save_error(Object error) {
    return 'Error al guardar la configuración: $error';
  }

  @override
  String privacy_load_error(Object error) {
    return 'Error al cargar privacidad: $error';
  }

  @override
  String get privacy_visibility => 'Visibilidad';

  @override
  String get privacy_online_status => 'Estado en línea';

  @override
  String get privacy_last_visit => 'Última vez';

  @override
  String get privacy_read_receipts => 'Confirmaciones de lectura';

  @override
  String get privacy_profile_info => 'Información del perfil';

  @override
  String get privacy_phone_number => 'Número de teléfono';

  @override
  String get privacy_birthday => 'Cumpleaños';

  @override
  String get privacy_about => 'Acerca de';

  @override
  String starred_load_error(Object error) {
    return 'Error al cargar destacados: $error';
  }

  @override
  String get starred_title => 'Destacados';

  @override
  String get starred_empty => 'No hay mensajes destacados en este chat';

  @override
  String get starred_message_fallback => 'Mensaje';

  @override
  String get starred_sender_you => 'Tú';

  @override
  String get starred_sender_fallback => 'Participante';

  @override
  String get starred_type_poll => 'Encuesta';

  @override
  String get starred_type_location => 'Ubicación';

  @override
  String get starred_type_attachment => 'Adjunto';

  @override
  String starred_today_prefix(Object time) {
    return 'Hoy, $time';
  }

  @override
  String get contact_edit_name_required => 'Ingresa el nombre del contacto.';

  @override
  String contact_edit_save_error(Object error) {
    return 'Error al guardar contacto: $error';
  }

  @override
  String get contact_edit_user_fallback => 'Usuario';

  @override
  String get contact_edit_first_name_hint => 'Nombre';

  @override
  String get contact_edit_last_name_hint => 'Apellido';

  @override
  String get contact_edit_description =>
      'Este nombre solo es visible para ti: en chats, búsqueda y lista de contactos.';

  @override
  String contact_edit_error(Object error) {
    return 'Error: $error';
  }

  @override
  String get voice_no_mic_access => 'Sin acceso al micrófono';

  @override
  String get voice_start_error => 'Error al iniciar la grabación';

  @override
  String get voice_file_not_received => 'Archivo de grabación no recibido';

  @override
  String get voice_stop_error => 'Error al detener la grabación';

  @override
  String get voice_title => 'Mensaje de voz';

  @override
  String get voice_recording => 'Grabando';

  @override
  String get voice_ready => 'Grabación lista';

  @override
  String get voice_stop_button => 'Detener';

  @override
  String get voice_record_again => 'Grabar de nuevo';

  @override
  String get attach_photo_video => 'Foto/Video';

  @override
  String get attach_files => 'Archivos';

  @override
  String get attach_scan => 'Escanear';

  @override
  String scanner_preview_title(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count páginas',
      one: '$count página',
    );
    return '$_temp0';
  }

  @override
  String scanner_preview_send(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Enviar $count páginas',
      one: 'Enviar página',
    );
    return '$_temp0';
  }

  @override
  String get scanner_preview_add => 'Escanear otra página';

  @override
  String get scanner_preview_retake => 'Volver a escanear';

  @override
  String get scanner_preview_delete => 'Eliminar página';

  @override
  String get scanner_preview_empty =>
      'Todas las páginas eliminadas. Toca + para escanear otra.';

  @override
  String get attach_circle => 'Circular';

  @override
  String get attach_location => 'Ubicación';

  @override
  String get attach_poll => 'Encuesta';

  @override
  String get attach_stickers => 'Pegatinas';

  @override
  String get attach_clipboard => 'Portapapeles';

  @override
  String get attach_text => 'Texto';

  @override
  String get attach_title => 'Adjuntar';

  @override
  String notif_save_error(Object error) {
    return 'Error al guardar: $error';
  }

  @override
  String get notif_title => 'Notificaciones en este chat';

  @override
  String get notif_description =>
      'Los ajustes a continuación aplican solo a esta conversación y no cambian las notificaciones globales de la app.';

  @override
  String get notif_this_chat => 'Este chat';

  @override
  String get notif_mute_title => 'Silenciar y ocultar notificaciones';

  @override
  String get notif_mute_subtitle =>
      'No molestar para este chat en este dispositivo.';

  @override
  String get notif_preview_title => 'Mostrar vista previa del texto';

  @override
  String get notif_preview_subtitle =>
      'Si se desactiva — título de la notificación sin fragmento del mensaje (donde se admita).';

  @override
  String get poll_create_enter_question => 'Ingresa una pregunta';

  @override
  String get poll_create_min_options => 'Se requieren al menos 2 opciones';

  @override
  String get poll_create_select_correct => 'Selecciona la opción correcta';

  @override
  String get poll_create_future_time => 'La hora de cierre debe ser futura';

  @override
  String get poll_create_question_label => 'Pregunta';

  @override
  String get poll_create_question_hint => 'Por ejemplo: ¿A qué hora nos vemos?';

  @override
  String get poll_create_explanation_label => 'Explicación (opcional)';

  @override
  String get poll_create_options_title => 'Opciones';

  @override
  String poll_create_option_hint(Object index) {
    return 'Opción $index';
  }

  @override
  String get poll_create_add_option => 'Agregar opción';

  @override
  String get poll_create_anonymous_title => 'Votación anónima';

  @override
  String get poll_create_anonymous_subtitle => 'No mostrar quién votó por qué';

  @override
  String get poll_create_multi_title => 'Respuestas múltiples';

  @override
  String get poll_create_multi_subtitle =>
      'Se pueden seleccionar varias opciones';

  @override
  String get poll_create_user_options_title => 'Opciones enviadas por usuarios';

  @override
  String get poll_create_user_options_subtitle =>
      'Los participantes pueden sugerir su propia opción';

  @override
  String get poll_create_revote_title => 'Permitir cambio de voto';

  @override
  String get poll_create_revote_subtitle =>
      'Se puede cambiar el voto hasta que cierre la encuesta';

  @override
  String get poll_create_shuffle_title => 'Mezclar opciones';

  @override
  String get poll_create_shuffle_subtitle =>
      'Cada participante ve un orden diferente';

  @override
  String get poll_create_quiz_title => 'Modo quiz';

  @override
  String get poll_create_quiz_subtitle => 'Una respuesta correcta';

  @override
  String get poll_create_correct_option_label => 'Opción correcta';

  @override
  String get poll_create_close_by_time => 'Cerrar por tiempo';

  @override
  String get poll_create_not_set => 'No establecido';

  @override
  String get poll_create_reset_deadline => 'Restablecer fecha límite';

  @override
  String get poll_create_publish => 'Publicar';

  @override
  String get poll_error => 'Error';

  @override
  String get poll_status_finished => 'Terminado';

  @override
  String get poll_restart => 'Reiniciar';

  @override
  String get poll_finish => 'Finalizar';

  @override
  String get poll_suggest_hint => 'Sugerir una opción';

  @override
  String get poll_voters_toggle_hide => 'Ocultar';

  @override
  String get poll_voters_toggle_show => 'Quién votó';

  @override
  String get e2ee_disable_title => '¿Desactivar cifrado?';

  @override
  String get e2ee_disable_body =>
      'Los nuevos mensajes se enviarán sin cifrado de extremo a extremo. Los mensajes cifrados enviados anteriormente permanecerán en el historial.';

  @override
  String get e2ee_disable_button => 'Desactivar';

  @override
  String e2ee_disable_error(Object error) {
    return 'Error al desactivar: $error';
  }

  @override
  String get e2ee_screen_title => 'Cifrado';

  @override
  String get e2ee_enabled_description =>
      'El cifrado de extremo a extremo está activado para este chat.';

  @override
  String get e2ee_disabled_description =>
      'El cifrado de extremo a extremo está desactivado.';

  @override
  String get e2ee_info_text =>
      'Cuando el cifrado está activado, el contenido de los nuevos mensajes solo está disponible para los participantes del chat en sus dispositivos. Desactivar solo afecta a los nuevos mensajes.';

  @override
  String get e2ee_enable_title => 'Activar cifrado';

  @override
  String e2ee_status_enabled(Object epoch) {
    return 'Activado (época de clave: $epoch)';
  }

  @override
  String get e2ee_status_disabled => 'Desactivado';

  @override
  String get e2ee_data_types_title => 'Tipos de datos';

  @override
  String get e2ee_data_types_info =>
      'Esta configuración no cambia el protocolo. Controla qué tipos de datos se envían cifrados.';

  @override
  String get e2ee_chat_settings_title =>
      'Configuración de cifrado para este chat';

  @override
  String get e2ee_chat_settings_override =>
      'Usando configuración específica del chat.';

  @override
  String get e2ee_chat_settings_global => 'Heredando configuración global.';

  @override
  String get e2ee_text_messages => 'Mensajes de texto';

  @override
  String get e2ee_attachments => 'Adjuntos (multimedia/archivos)';

  @override
  String get e2ee_override_hint =>
      'Para cambiar en este chat — activa \"Anular\".';

  @override
  String get group_member_fallback => 'Participante';

  @override
  String get group_role_creator => 'Creador del grupo';

  @override
  String get group_role_admin => 'Administrador';

  @override
  String group_total_count(Object count) {
    return 'Total: $count';
  }

  @override
  String get group_copy_invite_tooltip => 'Copiar enlace de invitación';

  @override
  String get group_add_member_tooltip => 'Agregar miembro';

  @override
  String get group_invite_copied => 'Enlace de invitación copiado';

  @override
  String group_copy_invite_error(Object error) {
    return 'Error al copiar el enlace: $error';
  }

  @override
  String get group_demote_confirm => '¿Quitar derechos de administrador?';

  @override
  String get group_promote_confirm => '¿Hacer administrador?';

  @override
  String group_demote_body(Object name) {
    return '$name perderá sus derechos de administrador. El miembro permanecerá en el grupo como miembro regular.';
  }

  @override
  String get group_demote_button => 'Quitar derechos';

  @override
  String get group_promote_button => 'Promover';

  @override
  String get group_kick_confirm => '¿Eliminar miembro?';

  @override
  String get group_kick_button => 'Eliminar';

  @override
  String get group_member_kicked => 'Miembro eliminado';

  @override
  String get group_badge_creator => 'CREADOR';

  @override
  String get group_demote_action => 'Quitar administrador';

  @override
  String get group_promote_action => 'Hacer administrador';

  @override
  String get group_kick_action => 'Eliminar del grupo';

  @override
  String group_contacts_load_error(Object error) {
    return 'Error al cargar contactos: $error';
  }

  @override
  String get group_add_members_title => 'Agregar miembros';

  @override
  String get group_search_contacts_hint => 'Buscar contactos';

  @override
  String get group_all_contacts_in_group =>
      'Todos tus contactos ya están en el grupo.';

  @override
  String get group_nobody_found => 'No se encontró a nadie.';

  @override
  String get group_user_fallback => 'Usuario';

  @override
  String get group_select_members => 'Seleccionar miembros';

  @override
  String group_add_count(Object count) {
    return 'Agregar ($count)';
  }

  @override
  String group_auth_error(Object error) {
    return 'Error de autorización: $error';
  }

  @override
  String group_add_error(Object error) {
    return 'Error al agregar miembros: $error';
  }

  @override
  String get add_contact_own_profile => 'Este es tu propio perfil';

  @override
  String get add_contact_qr_not_found => 'Perfil del código QR no encontrado';

  @override
  String add_contact_qr_error(Object error) {
    return 'Error al leer el código QR: $error';
  }

  @override
  String get add_contact_not_allowed => 'No se puede agregar a este usuario';

  @override
  String add_contact_save_error(Object error) {
    return 'Error al agregar contacto: $error';
  }

  @override
  String get add_contact_country_search => 'Buscar por país o código';

  @override
  String get add_contact_sync_phone => 'Sincronizar con teléfono';

  @override
  String get add_contact_qr_button => 'Agregar por código QR';

  @override
  String add_contact_load_error(Object error) {
    return 'Error al cargar contacto: $error';
  }

  @override
  String get add_contact_user_fallback => 'Usuario';

  @override
  String get add_contact_already_in_contacts => 'Ya está en contactos';

  @override
  String get add_contact_new => 'Nuevo contacto';

  @override
  String get add_contact_unavailable => 'No disponible';

  @override
  String get add_contact_scan_qr => 'Escanear código QR';

  @override
  String get add_contact_scan_hint =>
      'Apunta la cámara al código QR de perfil de LighChat';

  @override
  String get auth_validate_name_min_length =>
      'El nombre debe tener al menos 2 caracteres';

  @override
  String get auth_validate_username_min_length =>
      'El nombre de usuario debe tener al menos 3 caracteres';

  @override
  String get auth_validate_username_max_length =>
      'El nombre de usuario no debe exceder 30 caracteres';

  @override
  String get auth_validate_username_format =>
      'El nombre de usuario contiene caracteres no válidos';

  @override
  String get auth_validate_phone_11_digits =>
      'El número de teléfono debe contener 11 dígitos';

  @override
  String get auth_validate_email_format =>
      'Ingresa un correo electrónico válido';

  @override
  String get auth_validate_dob_invalid => 'Fecha de nacimiento no válida';

  @override
  String get auth_validate_bio_max_length =>
      'La biografía no debe exceder 200 caracteres';

  @override
  String get auth_validate_password_min_length =>
      'La contraseña debe tener al menos 6 caracteres';

  @override
  String get auth_validate_passwords_mismatch => 'Las contraseñas no coinciden';

  @override
  String get sticker_new_pack => 'Nuevo paquete…';

  @override
  String get sticker_select_image_or_gif => 'Selecciona una imagen o GIF';

  @override
  String sticker_send_error(Object error) {
    return 'Error al enviar: $error';
  }

  @override
  String get sticker_saved => 'Guardado en paquete de stickers';

  @override
  String get sticker_save_failed => 'Error al descargar o guardar el GIF';

  @override
  String get sticker_tab_my => 'Mío';

  @override
  String get sticker_tab_shared => 'Compartidos';

  @override
  String get sticker_no_packs => 'Sin paquetes de stickers. Crea uno nuevo.';

  @override
  String get sticker_shared_not_configured =>
      'Paquetes compartidos no configurados';

  @override
  String get sticker_recent => 'RECIENTES';

  @override
  String get sticker_gallery_description =>
      'Fotos, PNG, GIF del dispositivo — directo al chat';

  @override
  String get sticker_shared_unavailable =>
      'Paquetes compartidos aún no disponibles';

  @override
  String get sticker_gif_search_hint => 'Buscar GIF…';

  @override
  String sticker_gif_searched(Object query) {
    return 'Buscado: $query';
  }

  @override
  String get sticker_gif_search_unavailable =>
      'Búsqueda de GIF temporalmente no disponible.';

  @override
  String get sticker_gif_nothing_found => 'No se encontró nada';

  @override
  String get sticker_gif_all => 'Todos';

  @override
  String get sticker_gif_animated => 'ANIMADOS';

  @override
  String get sticker_emoji_text_unavailable =>
      'Emoji de texto no disponible para esta ventana.';

  @override
  String get wallpaper_sender => 'Contacto';

  @override
  String get wallpaper_incoming => 'Este es un mensaje entrante.';

  @override
  String get wallpaper_outgoing => 'Este es un mensaje saliente.';

  @override
  String get wallpaper_incoming_time => '11:40';

  @override
  String get wallpaper_outgoing_time => '11:41';

  @override
  String get wallpaper_system => 'Cambiaste el fondo del chat';

  @override
  String get wallpaper_you => 'Tú';

  @override
  String get wallpaper_today => 'Hoy';

  @override
  String system_event_e2ee_enabled(Object epoch) {
    return 'Cifrado de extremo a extremo activado (época de clave: $epoch)';
  }

  @override
  String get system_event_e2ee_disabled =>
      'Cifrado de extremo a extremo desactivado';

  @override
  String get system_event_unknown => 'Evento del sistema';

  @override
  String get system_event_group_created => 'Grupo creado';

  @override
  String system_event_member_added(Object name) {
    return '$name fue agregado';
  }

  @override
  String system_event_member_removed(Object name) {
    return '$name fue eliminado';
  }

  @override
  String system_event_member_left(Object name) {
    return '$name dejó el grupo';
  }

  @override
  String system_event_name_changed(Object name) {
    return 'Nombre cambiado a \"$name\"';
  }

  @override
  String get image_editor_title => 'Editor';

  @override
  String get image_editor_undo => 'Deshacer';

  @override
  String get image_editor_clear => 'Borrar';

  @override
  String get image_editor_pen => 'Pincel';

  @override
  String get image_editor_text => 'Texto';

  @override
  String get image_editor_crop => 'Recortar';

  @override
  String get image_editor_rotate => 'Rotar';

  @override
  String get location_title => 'Enviar ubicación';

  @override
  String get location_loading => 'Cargando mapa…';

  @override
  String get location_send_button => 'Enviar';

  @override
  String get location_live_label => 'En vivo';

  @override
  String get location_error => 'Error al cargar el mapa';

  @override
  String get location_no_permission => 'Sin acceso a la ubicación';

  @override
  String get group_member_admin => 'Administración';

  @override
  String get group_member_creator => 'Creador';

  @override
  String get group_member_member => 'Miembro';

  @override
  String get group_member_open_chat => 'Mensaje';

  @override
  String get group_member_open_profile => 'Perfil';

  @override
  String get group_member_remove => 'Eliminar';

  @override
  String get durak_lobby_title => 'Durak';

  @override
  String get durak_lobby_new_game => 'Nuevo juego';

  @override
  String get durak_lobby_decline => 'Rechazar';

  @override
  String get durak_lobby_accept => 'Aceptar';

  @override
  String get durak_lobby_invite_sent => 'Invitación enviada';

  @override
  String get voice_preview_cancel => 'Cancelar';

  @override
  String get voice_preview_send => 'Enviar';

  @override
  String get voice_preview_recorded => 'Grabado';

  @override
  String get voice_preview_playing => 'Reproduciendo…';

  @override
  String get voice_preview_paused => 'Pausado';

  @override
  String get group_avatar_camera => 'Cámara';

  @override
  String get group_avatar_gallery => 'Galería';

  @override
  String get group_avatar_upload_error => 'Error al subir';

  @override
  String get avatar_picker_title => 'Avatar';

  @override
  String get avatar_picker_camera => 'Cámara';

  @override
  String get avatar_picker_gallery => 'Galería';

  @override
  String get avatar_picker_crop => 'Recortar';

  @override
  String get avatar_picker_save => 'Guardar';

  @override
  String get avatar_picker_remove => 'Eliminar avatar';

  @override
  String get avatar_picker_error => 'Error al cargar el avatar';

  @override
  String get avatar_picker_crop_error => 'Error al recortar';

  @override
  String get webview_telegram_title => 'Iniciar sesión con Telegram';

  @override
  String get webview_telegram_loading => 'Cargando…';

  @override
  String get webview_telegram_error => 'Error al cargar la página';

  @override
  String get webview_telegram_back => 'Atrás';

  @override
  String get webview_telegram_retry => 'Reintentar';

  @override
  String get webview_telegram_close => 'Cerrar';

  @override
  String get webview_telegram_no_url => 'No se proporcionó URL de autorización';

  @override
  String get webview_yandex_title => 'Iniciar sesión con Yandex';

  @override
  String get webview_yandex_loading => 'Cargando…';

  @override
  String get webview_yandex_error => 'Error al cargar la página';

  @override
  String get webview_yandex_back => 'Atrás';

  @override
  String get webview_yandex_retry => 'Reintentar';

  @override
  String get webview_yandex_close => 'Cerrar';

  @override
  String get webview_yandex_no_url => 'No se proporcionó URL de autorización';

  @override
  String get google_profile_title => 'Completa tu perfil';

  @override
  String get google_profile_name => 'Nombre';

  @override
  String get google_profile_username => 'Nombre de usuario';

  @override
  String get google_profile_phone => 'Teléfono';

  @override
  String get google_profile_email => 'Correo electrónico';

  @override
  String get google_profile_dob => 'Fecha de nacimiento';

  @override
  String get google_profile_bio => 'Acerca de';

  @override
  String get google_profile_save => 'Guardar';

  @override
  String get google_profile_error => 'Error al guardar el perfil';

  @override
  String get system_event_e2ee_epoch_rotated => 'Clave de cifrado rotada';

  @override
  String system_event_e2ee_device_added(String actor, String device) {
    return '$actor agregó el dispositivo \"$device\"';
  }

  @override
  String system_event_e2ee_device_revoked(String actor, String device) {
    return '$actor revocó el dispositivo \"$device\"';
  }

  @override
  String system_event_e2ee_fingerprint_changed(String actor) {
    return 'La huella de seguridad de $actor cambió';
  }

  @override
  String get system_event_game_lobby_created => 'Sala de juego creada';

  @override
  String get system_event_game_started => 'Juego iniciado';

  @override
  String get system_event_call_missed => 'Llamada perdida';

  @override
  String get system_event_call_cancelled => 'Llamada rechazada';

  @override
  String get system_event_default_actor => 'Usuario';

  @override
  String get system_event_default_device => 'dispositivo';

  @override
  String get image_editor_add_caption => 'Agregar descripción...';

  @override
  String get image_editor_crop_failed => 'Error al recortar la imagen';

  @override
  String get image_editor_draw_hint =>
      'Modo de dibujo: desliza sobre la imagen';

  @override
  String get image_editor_crop_title => 'Recortar';

  @override
  String get location_preview_title => 'Ubicación';

  @override
  String get location_preview_accuracy_unknown => 'Precisión: —';

  @override
  String location_preview_accuracy_meters(String meters) {
    return 'Precisión: ~$meters m';
  }

  @override
  String location_preview_accuracy_km(String km) {
    return 'Precisión: ~$km km';
  }

  @override
  String get group_member_profile_default_name => 'Miembro';

  @override
  String get group_member_profile_dm => 'Enviar mensaje directo';

  @override
  String get group_member_profile_dm_hint =>
      'Abrir un chat directo con este miembro';

  @override
  String group_member_profile_dm_failed(Object error) {
    return 'Error al abrir el chat directo: $error';
  }

  @override
  String get conversation_game_lobby_unavailable =>
      'Juego no disponible o eliminado';

  @override
  String get conversation_game_lobby_back => 'Atrás';

  @override
  String get conversation_game_lobby_waiting =>
      'Esperando a que el oponente se una…';

  @override
  String get conversation_game_lobby_start_game => 'Iniciar juego';

  @override
  String get conversation_game_lobby_waiting_short => 'Esperando…';

  @override
  String get conversation_game_lobby_ready => 'Listo';

  @override
  String get voice_preview_trim_confirm_title =>
      '¿Mantener solo el fragmento seleccionado?';

  @override
  String get voice_preview_trim_confirm_body =>
      'Todo excepto el fragmento seleccionado se eliminará. La grabación continuará inmediatamente después de presionar el botón.';

  @override
  String get voice_preview_continue => 'Continuar';

  @override
  String get voice_preview_continue_recording => 'Continuar grabando';

  @override
  String get group_avatar_change_short => 'Cambiar';

  @override
  String get avatar_picker_cancel => 'Cancelar';

  @override
  String get avatar_picker_choose => 'Elegir avatar';

  @override
  String get avatar_picker_delete_photo => 'Eliminar foto';

  @override
  String get avatar_picker_loading => 'Cargando…';

  @override
  String get avatar_picker_choose_avatar => 'Elegir avatar';

  @override
  String get avatar_picker_change_avatar => 'Cambiar avatar';

  @override
  String get avatar_picker_remove_tooltip => 'Eliminar';

  @override
  String get telegram_sign_in_title => 'Iniciar sesión con Telegram';

  @override
  String get telegram_sign_in_open_in_browser => 'Abrir en navegador';

  @override
  String get telegram_sign_in_open_telegram_failed =>
      'Error al abrir Telegram. Por favor instala la app de Telegram.';

  @override
  String get telegram_sign_in_page_load_error => 'Error al cargar la página';

  @override
  String get telegram_sign_in_login_error =>
      'Error de inicio de sesión con Telegram.';

  @override
  String get telegram_sign_in_firebase_not_ready => 'Firebase no está listo.';

  @override
  String get telegram_sign_in_browser_failed => 'Error al abrir el navegador.';

  @override
  String telegram_sign_in_login_failed(Object error) {
    return 'Error al iniciar sesión: $error';
  }

  @override
  String get yandex_sign_in_title => 'Iniciar sesión con Yandex';

  @override
  String get yandex_sign_in_open_in_browser => 'Abrir en navegador';

  @override
  String get yandex_sign_in_page_load_error => 'Error al cargar la página';

  @override
  String get yandex_sign_in_login_error =>
      'Error de inicio de sesión con Yandex.';

  @override
  String get yandex_sign_in_firebase_not_ready => 'Firebase no está listo.';

  @override
  String get yandex_sign_in_browser_failed => 'Error al abrir el navegador.';

  @override
  String yandex_sign_in_login_failed(Object error) {
    return 'Error al iniciar sesión: $error';
  }

  @override
  String get google_complete_title => 'Completar registro';

  @override
  String get google_complete_subtitle =>
      'Después de iniciar sesión con Google, completa tu perfil como en la versión web.';

  @override
  String get google_complete_name_label => 'Nombre';

  @override
  String get google_complete_username_label => 'Nombre de usuario (@usuario)';

  @override
  String get google_complete_phone_label => 'Teléfono (11 dígitos)';

  @override
  String get google_complete_email_label => 'Correo electrónico';

  @override
  String get google_complete_email_hint => 'tu@ejemplo.com';

  @override
  String get google_complete_dob_label =>
      'Fecha de nacimiento (AAAA-MM-DD, opcional)';

  @override
  String get google_complete_bio_label =>
      'Acerca de (hasta 200 caracteres, opcional)';

  @override
  String get google_complete_save => 'Guardar y continuar';

  @override
  String get google_complete_back => 'Volver a iniciar sesión';

  @override
  String get game_error_defense_not_beat =>
      'Esta carta no gana a la carta de ataque';

  @override
  String get game_error_attacker_first => 'El atacante mueve primero';

  @override
  String get game_error_defender_no_attack =>
      'El defensor no puede atacar ahora';

  @override
  String get game_error_not_allowed_throwin => 'No puedes lanzar en esta ronda';

  @override
  String get game_error_throwin_not_turn => 'Otro jugador está lanzando ahora';

  @override
  String get game_error_rank_not_allowed =>
      'Solo puedes lanzar una carta del mismo rango';

  @override
  String get game_error_cannot_throw_in => 'No se pueden lanzar más cartas';

  @override
  String get game_error_card_not_in_hand => 'Esta carta ya no está en tu mano';

  @override
  String get game_error_already_defended => 'Esta carta ya está defendida';

  @override
  String get game_error_bad_attack_index =>
      'Selecciona una carta de ataque para defender';

  @override
  String get game_error_only_defender => 'Otro jugador está defendiendo ahora';

  @override
  String get game_error_defender_taking => 'El defensor ya está tomando cartas';

  @override
  String get game_error_game_not_active => 'El juego ya no está activo';

  @override
  String get game_error_not_in_lobby => 'La sala ya ha iniciado';

  @override
  String get game_error_game_already_active => 'El juego ya ha iniciado';

  @override
  String get game_error_active_exists => 'Ya hay un juego activo en este chat';

  @override
  String get game_error_round_pending =>
      'Termina primero el movimiento disputado';

  @override
  String get game_error_rematch_failed =>
      'Error al preparar la revancha. Intenta de nuevo';

  @override
  String get game_error_unauthenticated => 'Necesitas iniciar sesión';

  @override
  String get game_error_permission_denied =>
      'Esta acción no está disponible para ti';

  @override
  String get game_error_invalid_argument => 'Movimiento no válido';

  @override
  String get game_error_precondition =>
      'El movimiento no está disponible en este momento';

  @override
  String get game_error_server =>
      'Error al hacer el movimiento. Intenta de nuevo';

  @override
  String get reply_sticker => 'Etiqueta engomada';

  @override
  String get reply_gif => 'GIF';

  @override
  String get reply_video_circle => 'Video circular';

  @override
  String get reply_voice_message => 'Mensaje de voz';

  @override
  String get reply_video => 'Video';

  @override
  String get reply_photo => 'Foto';

  @override
  String get reply_file => 'Archivo';

  @override
  String get reply_location => 'Ubicación';

  @override
  String get reply_poll => 'Encuesta';

  @override
  String get reply_link => 'Enlace';

  @override
  String get reply_message => 'Mensaje';

  @override
  String get reply_sender_you => 'Tú';

  @override
  String get reply_sender_member => 'Miembro';

  @override
  String get call_format_today => 'Hoy';

  @override
  String get call_format_yesterday => 'Ayer';

  @override
  String get call_format_second_short => 's';

  @override
  String get call_format_minute_short => 'metro';

  @override
  String get call_format_hour_short => 'h';

  @override
  String get call_format_day_short => 'd';

  @override
  String get call_month_january => 'Enero';

  @override
  String get call_month_february => 'Febrero';

  @override
  String get call_month_march => 'Marzo';

  @override
  String get call_month_april => 'Abril';

  @override
  String get call_month_may => 'Mayo';

  @override
  String get call_month_june => 'Junio';

  @override
  String get call_month_july => 'Julio';

  @override
  String get call_month_august => 'Agosto';

  @override
  String get call_month_september => 'Septiembre';

  @override
  String get call_month_october => 'Octubre';

  @override
  String get call_month_november => 'Noviembre';

  @override
  String get call_month_december => 'Diciembre';

  @override
  String get push_incoming_call => 'Llamada entrante';

  @override
  String get push_incoming_video_call => 'Videollamada entrante';

  @override
  String get push_new_message => 'Nuevo mensaje';

  @override
  String get push_channel_calls => 'Llamadas';

  @override
  String get push_channel_messages => 'Mensajes';

  @override
  String contacts_years_one(Object count) {
    return '$count año';
  }

  @override
  String contacts_years_few(Object count) {
    return '$count años';
  }

  @override
  String contacts_years_many(Object count) {
    return '$count años';
  }

  @override
  String contacts_years_other(Object count) {
    return '$count años';
  }

  @override
  String get durak_entry_single_game => 'Juego individual';

  @override
  String get durak_entry_finish_game_tooltip => 'Terminar juego';

  @override
  String get durak_entry_tournament_games_dialog_title =>
      '¿Cuántos juegos en el torneo?';

  @override
  String get durak_entry_cancel => 'Cancelar';

  @override
  String get durak_entry_create => 'Crear';

  @override
  String video_editor_load_failed(Object error) {
    return 'Error al cargar el video: $error';
  }

  @override
  String video_editor_process_failed(Object error) {
    return 'Error al procesar el video: $error';
  }

  @override
  String video_editor_duration(Object duration) {
    return 'Duración: $duration';
  }

  @override
  String get video_editor_brush => 'Pincel';

  @override
  String get video_editor_caption_hint => 'Agregar descripción...';

  @override
  String get video_effects_speed => 'Velocidad';

  @override
  String get video_filter_none => 'Original';

  @override
  String get video_filter_enhance => 'Realzar';

  @override
  String get share_location_title => 'Compartir ubicación';

  @override
  String get share_location_how => 'Método de compartir';

  @override
  String get share_location_cancel => 'Cancelar';

  @override
  String get share_location_send => 'Enviar';

  @override
  String get photo_source_gallery => 'Galería';

  @override
  String get photo_source_take_photo => 'Tomar foto';

  @override
  String get photo_source_record_video => 'Grabar video';

  @override
  String get video_attachment_media_kind => 'video';

  @override
  String get video_attachment_title => 'Video';

  @override
  String get video_attachment_playback_error =>
      'No se puede reproducir el video. Verifica el enlace y la conexión de red.';

  @override
  String get location_card_broadcast_ended_mine =>
      'La transmisión de ubicación finalizó. La otra persona ya no puede ver tu ubicación actual.';

  @override
  String get location_card_broadcast_ended_other =>
      'La transmisión de ubicación de este contacto ha finalizado. La posición actual no está disponible.';

  @override
  String get location_card_title => 'Ubicación';

  @override
  String location_card_accuracy(Object meters) {
    return '±$meters m';
  }

  @override
  String get link_webview_copy_tooltip => 'Copiar enlace';

  @override
  String get link_webview_copied_snackbar => 'Enlace copiado';

  @override
  String get link_webview_open_browser_tooltip => 'Abrir en navegador';

  @override
  String get hold_record_pause => 'Pausado';

  @override
  String get hold_record_release_cancel => 'Suelta para cancelar';

  @override
  String get hold_record_slide_hints =>
      'Desliza izquierda — cancelar · Arriba — pausar';

  @override
  String get e2ee_badge_loading => 'Cargando huella digital…';

  @override
  String e2ee_badge_error(Object error) {
    return 'Error al obtener la huella digital: $error';
  }

  @override
  String get e2ee_badge_label => 'Huella digital E2EE';

  @override
  String e2ee_badge_label_with_user(Object user) {
    return 'Huella digital E2EE • $user';
  }

  @override
  String e2ee_badge_devices(Object count) {
    return '$count disp.';
  }

  @override
  String get composer_link_cancel => 'Cancelar';

  @override
  String message_search_results_count(Object count) {
    return 'RESULTADOS DE BÚSQUEDA: $count';
  }

  @override
  String get message_search_not_found => 'NADA ENCONTRADO';

  @override
  String get message_search_participant_fallback => 'Participante';

  @override
  String get wallpaper_purple => 'Púrpura';

  @override
  String get wallpaper_pink => 'Rosa';

  @override
  String get wallpaper_blue => 'Azul';

  @override
  String get wallpaper_green => 'Verde';

  @override
  String get wallpaper_sunset => 'Atardecer';

  @override
  String get wallpaper_tender => 'Suave';

  @override
  String get wallpaper_lime => 'Lima';

  @override
  String get wallpaper_graphite => 'Grafito';

  @override
  String get avatar_crop_title => 'Ajustar avatar';

  @override
  String get avatar_crop_hint =>
      'Arrastra y haz zoom — el círculo aparecerá en listas y mensajes; el marco completo se queda para el perfil.';

  @override
  String get avatar_crop_cancel => 'Cancelar';

  @override
  String get avatar_crop_reset => 'Restablecer';

  @override
  String get avatar_crop_save => 'Guardar';

  @override
  String get meeting_entry_connecting => 'Conectando a la reunión…';

  @override
  String meeting_entry_auth_failed(Object error) {
    return 'Error al iniciar sesión: $error';
  }

  @override
  String get meeting_entry_participant_fallback => 'Participante';

  @override
  String get meeting_entry_back => 'Atrás';

  @override
  String get meeting_chat_copy => 'Copiar';

  @override
  String get meeting_chat_edit => 'Editar';

  @override
  String get meeting_chat_delete => 'Eliminar';

  @override
  String get meeting_chat_deleted => 'Mensaje eliminado';

  @override
  String get meeting_chat_edited_mark => '• editado';

  @override
  String get meeting_chat_reply => 'Responder';

  @override
  String get meeting_chat_react => 'Reaccionar';

  @override
  String get meeting_chat_copied => 'Copiado';

  @override
  String get meeting_chat_editing => 'Editando';

  @override
  String meeting_chat_reply_to(Object name) {
    return 'Responder a $name';
  }

  @override
  String get meeting_chat_attachment_placeholder => 'Archivo adjunto';

  @override
  String meeting_timer_remaining(Object time) {
    return 'Quedan $time';
  }

  @override
  String meeting_timer_elapsed(Object time) {
    return '$time';
  }

  @override
  String get meeting_back_to_chats => 'Volver a los chats';

  @override
  String get meeting_open_chats => 'Abrir chats';

  @override
  String get meeting_in_call_chat => 'Chat en la llamada';

  @override
  String get meeting_lobby_open_settings => 'Abrir ajustes';

  @override
  String get meeting_lobby_retry => 'Reintentar';

  @override
  String get meeting_minimized_resume => 'Toca para volver a la llamada';

  @override
  String get e2ee_decrypt_image_failed => 'Error al descifrar imagen';

  @override
  String get e2ee_decrypt_video_failed => 'Error al descifrar video';

  @override
  String get e2ee_decrypt_audio_failed => 'Error al descifrar audio';

  @override
  String get e2ee_decrypt_attachment_failed => 'Error al descifrar adjunto';

  @override
  String get search_preview_attachment => 'Adjunto';

  @override
  String get search_preview_location => 'Ubicación';

  @override
  String get search_preview_message => 'Mensaje';

  @override
  String get outbox_attachment_singular => 'Adjunto';

  @override
  String outbox_attachments_count(int count) {
    return 'Adjuntos ($count)';
  }

  @override
  String get outbox_chat_unavailable => 'Servicio de chat no disponible';

  @override
  String outbox_encryption_error(String code) {
    return 'Cifrado: $code';
  }

  @override
  String get nav_chats => 'Charlas';

  @override
  String get nav_contacts => 'Contactos';

  @override
  String get nav_meetings => 'Reuniones';

  @override
  String get nav_calls => 'Llamadas';

  @override
  String get e2ee_media_decrypt_failed_image => 'Error al descifrar imagen';

  @override
  String get e2ee_media_decrypt_failed_video => 'Error al descifrar video';

  @override
  String get e2ee_media_decrypt_failed_audio => 'Error al descifrar audio';

  @override
  String get e2ee_media_decrypt_failed_attachment =>
      'Error al descifrar adjunto';

  @override
  String get chat_search_snippet_attachment => 'Adjunto';

  @override
  String get chat_search_snippet_location => 'Ubicación';

  @override
  String get chat_search_snippet_message => 'Mensaje';

  @override
  String get bottom_nav_chats => 'Charlas';

  @override
  String get bottom_nav_contacts => 'Contactos';

  @override
  String get bottom_nav_meetings => 'Reuniones';

  @override
  String get bottom_nav_calls => 'Llamadas';

  @override
  String get chat_list_swipe_folders => 'CARPETAS';

  @override
  String get chat_list_swipe_clear => 'BORRAR';

  @override
  String get chat_list_swipe_delete => 'ELIMINAR';

  @override
  String get composer_editing_title => 'EDITANDO MENSAJE';

  @override
  String get composer_editing_cancel_tooltip => 'Cancelar edición';

  @override
  String get composer_formatting_title => 'FORMATO';

  @override
  String get composer_link_preview_loading => 'Cargando vista previa…';

  @override
  String get composer_link_preview_hide_tooltip => 'Ocultar vista previa';

  @override
  String get chat_invite_button => 'Invitar';

  @override
  String get forward_preview_unknown_sender => 'Desconocido';

  @override
  String get forward_preview_attachment => 'Adjunto';

  @override
  String get forward_preview_message => 'Mensaje';

  @override
  String get chat_mention_no_matches => 'Sin coincidencias';

  @override
  String get live_location_sharing => 'Estás compartiendo tu ubicación';

  @override
  String get live_location_stop => 'Detener';

  @override
  String get chat_message_deleted => 'Mensaje eliminado';

  @override
  String get profile_qr_share => 'Compartir';

  @override
  String get shared_location_open_browser_tooltip => 'Abrir en navegador';

  @override
  String get reply_preview_message_fallback => 'Mensaje';

  @override
  String get video_circle_media_kind => 'video';

  @override
  String reactions_rated_count(int count) {
    return 'Reaccionaron: $count';
  }

  @override
  String reactions_today_time(String time) {
    return 'Hoy, $time';
  }

  @override
  String get durak_create_timer_subtitle => '15 segundos por defecto';

  @override
  String get dm_game_banner_active => 'Juego de Durak en progreso';

  @override
  String get dm_game_banner_created => 'Juego de Durak creado';

  @override
  String get chat_folder_favorites => 'Favoritos';

  @override
  String get chat_folder_new => 'Nuevos';

  @override
  String get contact_profile_user_fallback => 'Usuario';

  @override
  String contact_profile_error(String error) {
    return 'Error: $error';
  }

  @override
  String get conversation_threads_loading_title => 'Hilos';

  @override
  String get theme_label_light => 'Claro';

  @override
  String get theme_label_dark => 'Oscuro';

  @override
  String get theme_label_auto => 'Auto';

  @override
  String get chat_draft_reply_fallback => 'Responder';

  @override
  String get mention_default_label => 'Miembro';

  @override
  String get contacts_fallback_name => 'Contacto';

  @override
  String get sticker_pack_default_name => 'Mi paquete';

  @override
  String get profile_error_phone_taken =>
      'Este número de teléfono ya está registrado. Por favor usa un número diferente.';

  @override
  String get profile_error_email_taken =>
      'Este correo ya está en uso. Por favor usa una dirección diferente.';

  @override
  String get profile_error_username_taken =>
      'Este nombre de usuario ya está en uso. Por favor elige otro.';

  @override
  String get e2ee_banner_default_context => 'Mensaje';

  @override
  String e2ee_banner_encrypted_chat_web_only(String prefix) {
    return '$prefix a un chat cifrado solo se puede enviar desde el cliente web por ahora.';
  }

  @override
  String get chat_attachment_decrypt_error => 'Error al descifrar adjunto';

  @override
  String get mention_fallback_label => 'miembro';

  @override
  String get mention_fallback_label_capitalized => 'Miembro';

  @override
  String get meeting_speaking_label => 'Hablando';

  @override
  String meeting_local_you_suffix(String name) {
    return '$name (Tú)';
  }

  @override
  String get video_crop_title => 'Recortar';

  @override
  String video_crop_load_error(String error) {
    return 'Error al cargar el video: $error';
  }

  @override
  String get gif_section_recent => 'RECIENTES';

  @override
  String get gif_section_trending => 'TENDENCIAS';

  @override
  String get auth_create_account_title => 'Crear cuenta';

  @override
  String yandex_sign_in_yandex_error(String error) {
    return 'Yandex: $error';
  }

  @override
  String get call_status_missed => 'Perdida';

  @override
  String get call_status_cancelled => 'Cancelada';

  @override
  String get call_status_ended => 'Finalizada';

  @override
  String get presence_offline => 'Sin conexión';

  @override
  String get presence_online => 'En línea';

  @override
  String get dm_title_fallback => 'Charlar';

  @override
  String get dm_title_partner_fallback => 'Contacto';

  @override
  String get group_title_fallback => 'Chat grupal';

  @override
  String get block_call_viewer_blocked =>
      'Bloqueaste a este usuario. Llamada no disponible — desbloquea en Perfil → Bloqueados.';

  @override
  String get block_call_partner_blocked =>
      'Este usuario restringió la comunicación contigo. Llamada no disponible.';

  @override
  String get block_call_unavailable => 'Llamada no disponible.';

  @override
  String get block_composer_viewer_blocked =>
      'Bloqueaste a este usuario. Envío no disponible — desbloquea en Perfil → Bloqueados.';

  @override
  String get block_composer_partner_blocked =>
      'Este usuario restringió la comunicación contigo. Envío no disponible.';

  @override
  String get forward_group_fallback => 'Grupo';

  @override
  String get forward_unknown_user => 'Desconocido';

  @override
  String get live_location_once => 'Una vez (solo este mensaje)';

  @override
  String get live_location_5min => '5 minutos';

  @override
  String get live_location_15min => '15 minutos';

  @override
  String get live_location_30min => '30 minutos';

  @override
  String get live_location_1hour => '1 hora';

  @override
  String get live_location_2hours => '2 horas';

  @override
  String get live_location_6hours => '6 horas';

  @override
  String get live_location_1day => '1 día';

  @override
  String get live_location_forever => 'Para siempre (hasta que lo desactive)';

  @override
  String get e2ee_send_too_many_files =>
      'Demasiados adjuntos para envío cifrado: máximo 5 archivos por mensaje.';

  @override
  String get e2ee_send_too_large =>
      'Tamaño total de adjuntos demasiado grande: máximo 96 MB por mensaje cifrado.';

  @override
  String get presence_last_seen_prefix => 'Visto por última vez ';

  @override
  String get presence_less_than_minute_ago => 'hace menos de un minuto';

  @override
  String get presence_yesterday => 'ayer';

  @override
  String get dm_fallback_title => 'Charlar';

  @override
  String get dm_fallback_partner => 'Contacto';

  @override
  String get group_fallback_title => 'Chat grupal';

  @override
  String get block_send_viewer_blocked =>
      'Bloqueaste a este usuario. Envío no disponible — desbloquea en Perfil → Bloqueados.';

  @override
  String get block_send_partner_blocked =>
      'Este usuario restringió la comunicación contigo. Envío no disponible.';

  @override
  String get mention_fallback_name => 'Miembro';

  @override
  String get profile_conflict_phone =>
      'Este número de teléfono ya está registrado. Por favor usa un número diferente.';

  @override
  String get profile_conflict_email =>
      'Este correo ya está en uso. Por favor usa una dirección diferente.';

  @override
  String get profile_conflict_username =>
      'Este nombre de usuario ya está en uso. Por favor elige uno diferente.';

  @override
  String get mention_fallback_participant => 'Participante';

  @override
  String get sticker_gif_recent => 'RECIENTES';

  @override
  String get meeting_screen_sharing => 'Pantalla';

  @override
  String get meeting_speaking => 'Hablando';

  @override
  String auth_sign_in_failed(Object error) {
    return 'Error al iniciar sesión: $error';
  }

  @override
  String yandex_error_prefix(Object error) {
    return 'Yandex: $error';
  }

  @override
  String auth_error_prefix(Object error) {
    return 'Error de autenticación: $error';
  }

  @override
  String presence_minutes_ago(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace $count minutos',
      one: 'hace un minuto',
    );
    return '$_temp0';
  }

  @override
  String presence_hours_ago(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace $count horas',
      one: 'hace una hora',
    );
    return '$_temp0';
  }

  @override
  String presence_days_ago(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace $count días',
      one: 'hace un día',
    );
    return '$_temp0';
  }

  @override
  String presence_months_ago(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace $count meses',
      one: 'hace un mes',
    );
    return '$_temp0';
  }

  @override
  String presence_years_months_ago(int years, int months) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years años',
      one: '1 año',
    );
    String _temp1 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: 'hace $months meses',
      one: 'hace 1 mes',
    );
    return '$_temp0 $_temp1';
  }

  @override
  String presence_years_ago(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace $count años',
      one: 'hace un año',
    );
    return '$_temp0';
  }

  @override
  String get wallpaper_gradient_purple => 'Púrpura';

  @override
  String get wallpaper_gradient_pink => 'Rosa';

  @override
  String get wallpaper_gradient_blue => 'Azul';

  @override
  String get wallpaper_gradient_green => 'Verde';

  @override
  String get wallpaper_gradient_sunset => 'Atardecer';

  @override
  String get wallpaper_gradient_gentle => 'Suave';

  @override
  String get wallpaper_gradient_lime => 'Lima';

  @override
  String get wallpaper_gradient_graphite => 'Grafito';

  @override
  String get sticker_tab_recent => 'RECIENTES';

  @override
  String get block_call_you_blocked =>
      'Bloqueaste a este usuario. Llamada no disponible — desbloquea en Perfil → Bloqueados.';

  @override
  String get block_call_they_blocked =>
      'Este usuario restringió la comunicación contigo. Llamada no disponible.';

  @override
  String get block_call_generic => 'Llamada no disponible.';

  @override
  String get block_send_you_blocked =>
      'Bloqueaste a este usuario. Envío no disponible — desbloquea en Perfil → Bloqueados.';

  @override
  String get block_send_they_blocked =>
      'Este usuario restringió la comunicación contigo. Envío no disponible.';

  @override
  String get forward_unknown_fallback => 'Desconocido';

  @override
  String get dm_title_chat => 'Charlar';

  @override
  String get dm_title_partner => 'Compañero';

  @override
  String get dm_title_group => 'Chat grupal';

  @override
  String get e2ee_too_many_attachments =>
      'Demasiados adjuntos para envío cifrado: máximo 5 archivos por mensaje.';

  @override
  String get e2ee_total_size_exceeded =>
      'Tamaño total de adjuntos demasiado grande: máximo 96 MB por mensaje cifrado.';

  @override
  String composer_limit_too_many_files(int current, int max, int diff) {
    return 'Demasiados adjuntos: $current/$max. Elimina $diff para enviar.';
  }

  @override
  String composer_limit_total_size_exceeded(String currentMb, String maxMb) {
    return 'Adjuntos demasiado grandes: $currentMb MB / $maxMb MB. Elimina algunos para enviar.';
  }

  @override
  String get composer_limit_blocking_send => 'Límite de adjuntos superado';

  @override
  String yandex_sign_in_error_prefix(String error) {
    return 'Yandex: $error';
  }

  @override
  String get meeting_participant_screen => 'Pantalla';

  @override
  String get meeting_participant_speaking => 'Hablando';

  @override
  String get nav_error_title => 'Error de navegación';

  @override
  String get nav_error_invalid_secret_compose =>
      'Navegación de composición secreta no válida';

  @override
  String get sign_in_title => 'Iniciar sesión';

  @override
  String get sign_in_firebase_ready =>
      'Firebase inicializado. Puedes iniciar sesión.';

  @override
  String get sign_in_firebase_not_ready =>
      'Firebase no está listo. Verifica los registros y firebase_options.dart.';

  @override
  String get sign_in_continue => 'Continuar';

  @override
  String get sign_in_anonymously => 'Iniciar sesión anónimamente';

  @override
  String sign_in_auth_error(String error) {
    return 'Error de autenticación: $error';
  }

  @override
  String generic_error(String error) {
    return 'Error: $error';
  }

  @override
  String get storage_label_video => 'Video';

  @override
  String get storage_label_photo => 'Foto';

  @override
  String get storage_label_audio => 'Audio';

  @override
  String get storage_label_files => 'Archivos';

  @override
  String get storage_label_other => 'Otros';

  @override
  String get storage_label_recent_stickers => 'Stickers recientes';

  @override
  String get storage_label_giphy_search => 'GIPHY · caché de búsqueda';

  @override
  String get storage_label_giphy_recent => 'GIPHY · GIF recientes';

  @override
  String get storage_chat_unattributed => 'No atribuido a un chat';

  @override
  String storage_label_draft(String key) {
    return 'Borrador · $key';
  }

  @override
  String get storage_label_offline_snapshot =>
      'Captura de lista de chats sin conexión';

  @override
  String storage_label_profile_cache(String name) {
    return 'Caché de perfil · $name';
  }

  @override
  String get call_mini_end => 'Finalizar llamada';

  @override
  String get animation_quality_lite => 'ligero';

  @override
  String get animation_quality_balanced => 'Balance';

  @override
  String get animation_quality_cinematic => 'Cine';

  @override
  String get crop_aspect_original => 'Original';

  @override
  String get crop_aspect_square => 'Cuadrada';

  @override
  String get push_notification_title => 'Permitir notificaciones';

  @override
  String get push_notification_rationale =>
      'La app necesita notificaciones para llamadas entrantes.';

  @override
  String get push_notification_required =>
      'Activa las notificaciones para mostrar las llamadas entrantes.';

  @override
  String get push_notification_grant => 'Permitir';

  @override
  String get push_call_accept => 'Aceptar';

  @override
  String get push_call_decline => 'Rechazar';

  @override
  String get push_channel_incoming_calls => 'Llamadas entrantes';

  @override
  String get push_channel_missed_calls => 'Llamadas perdidas';

  @override
  String get push_channel_messages_desc => 'Nuevos mensajes en chats';

  @override
  String get push_channel_silent => 'Mensajes silenciosos';

  @override
  String get push_channel_silent_desc => 'Push sin sonido';

  @override
  String get push_caller_unknown => 'Alguien';

  @override
  String get outbox_attachment_single => 'Adjunto';

  @override
  String outbox_attachment_count(int count) {
    return 'Adjuntos ($count)';
  }

  @override
  String get bottom_nav_label_chats => 'Charlas';

  @override
  String get bottom_nav_label_contacts => 'Contactos';

  @override
  String get bottom_nav_label_conferences => 'Conferencias';

  @override
  String get bottom_nav_label_calls => 'Llamadas';

  @override
  String get welcomeBubbleTitle => 'Bienvenido a LighChat';

  @override
  String get welcomeBubbleSubtitle => 'El faro está encendido';

  @override
  String get welcomeSkip => 'Omitir';

  @override
  String get welcomeReplayDebugTile =>
      'Repetir animación de bienvenida (debug)';

  @override
  String get sticker_scope_library => 'Biblioteca';

  @override
  String get sticker_library_search_hint => 'Buscar stickers...';

  @override
  String get account_menu_energy_saving => 'Ahorro de energía';

  @override
  String get energy_saving_title => 'Ahorro de energía';

  @override
  String get energy_saving_section_mode => 'Modo de ahorro de energía';

  @override
  String get energy_saving_section_resource_heavy => 'Procesos de alto consumo';

  @override
  String get energy_saving_threshold_off => 'Desactivado';

  @override
  String get energy_saving_threshold_always => 'Activado';

  @override
  String get energy_saving_threshold_off_full => 'Nunca';

  @override
  String get energy_saving_threshold_always_full => 'Siempre';

  @override
  String energy_saving_threshold_at(int percent) {
    return 'Cuando la batería esté por debajo del $percent%';
  }

  @override
  String get energy_saving_hint_off =>
      'Los efectos de alto consumo nunca se desactivan automáticamente.';

  @override
  String get energy_saving_hint_always =>
      'Los efectos de alto consumo siempre están desactivados sin importar el nivel de batería.';

  @override
  String energy_saving_hint_threshold(int percent) {
    return 'Desactivar automáticamente todos los procesos de alto consumo cuando la batería baje del $percent%.';
  }

  @override
  String energy_saving_current_battery(int percent) {
    return 'Batería actual: $percent%';
  }

  @override
  String get energy_saving_active_now => 'modo activo';

  @override
  String get energy_saving_active_threshold =>
      'La batería alcanzó el umbral — todos los efectos a continuación están temporalmente desactivados.';

  @override
  String get energy_saving_active_system =>
      'El ahorro de energía del sistema está activado — todos los efectos a continuación están temporalmente desactivados.';

  @override
  String get energy_saving_autoplay_video_title =>
      'Reproducción automática de videos';

  @override
  String get energy_saving_autoplay_video_subtitle =>
      'Reproducir automáticamente y repetir mensajes de video y videos en chats.';

  @override
  String get energy_saving_autoplay_gif_title =>
      'Reproducción automática de GIFs';

  @override
  String get energy_saving_autoplay_gif_subtitle =>
      'Reproducir automáticamente y repetir GIFs en chats y en el teclado.';

  @override
  String get energy_saving_animated_stickers_title => 'Stickers animados';

  @override
  String get energy_saving_animated_stickers_subtitle =>
      'Animaciones en bucle de stickers y efectos de stickers Premium a pantalla completa.';

  @override
  String get energy_saving_animated_emoji_title => 'Emoji animados';

  @override
  String get energy_saving_animated_emoji_subtitle =>
      'Animación en bucle de emoji en mensajes, reacciones y estados.';

  @override
  String get energy_saving_interface_animations_title =>
      'Animaciones de interfaz';

  @override
  String get energy_saving_interface_animations_subtitle =>
      'Efectos y animaciones que hacen a LighChat más fluido y expresivo.';

  @override
  String get energy_saving_media_preload_title => 'Precarga de multimedia';

  @override
  String get energy_saving_media_preload_subtitle =>
      'Comenzar a descargar archivos multimedia al abrir la lista de chats.';

  @override
  String get energy_saving_background_update_title =>
      'Actualización en segundo plano';

  @override
  String get energy_saving_background_update_subtitle =>
      'Actualizaciones rápidas del chat al cambiar entre apps.';

  @override
  String get legal_index_title => 'Documentos legales';

  @override
  String get legal_index_subtitle =>
      'Política de privacidad, términos de servicio y otros documentos legales que regulan el uso de LighChat.';

  @override
  String get legal_settings_section_title => 'Información legal';

  @override
  String get legal_settings_section_subtitle =>
      'Política de privacidad, términos de servicio, EULA y más.';

  @override
  String get legal_not_found => 'Documento no encontrado';

  @override
  String get legal_title_privacy_policy => 'Política de Privacidad';

  @override
  String get legal_title_terms_of_service => 'Términos de Servicio';

  @override
  String get legal_title_cookie_policy => 'Política de Cookies';

  @override
  String get legal_title_eula => 'Acuerdo de Licencia de Usuario Final';

  @override
  String get legal_title_dpa => 'Acuerdo de Procesamiento de Datos';

  @override
  String get legal_title_children => 'Política para Niños';

  @override
  String get legal_title_moderation => 'Política de Moderación de Contenido';

  @override
  String get legal_title_aup => 'Política de Uso Aceptable';

  @override
  String get chat_list_item_sender_you => 'Tú';

  @override
  String get chat_preview_message => 'Mensaje';

  @override
  String get chat_preview_sticker => 'Etiqueta engomada';

  @override
  String get chat_preview_attachment => 'Adjunto';

  @override
  String get contacts_disclosure_title => 'Encontrar amigos en LighChat';

  @override
  String get contacts_disclosure_body =>
      'LighChat lee los números de teléfono y las direcciones de correo electrónico de tu libreta de contactos, los hashea y los compara con nuestro servidor para mostrar cuáles de tus contactos ya usan la aplicación. Tus contactos nunca se almacenan en nuestros servidores.';

  @override
  String get contacts_disclosure_allow => 'Permitir';

  @override
  String get contacts_disclosure_deny => 'Ahora no';

  @override
  String get report_title => 'Denunciar';

  @override
  String get report_subtitle_message => 'Denunciar mensaje';

  @override
  String get report_subtitle_user => 'Denunciar usuario';

  @override
  String get report_reason_spam => 'Spam';

  @override
  String get report_reason_offensive => 'Contenido ofensivo';

  @override
  String get report_reason_violence => 'Violencia o amenazas';

  @override
  String get report_reason_fraud => 'Fraude o estafa';

  @override
  String get report_reason_other => 'Otro';

  @override
  String get report_comment_hint => 'Detalles adicionales (opcional)';

  @override
  String get report_submit => 'Enviar';

  @override
  String get report_success => 'Denuncia enviada. ¡Gracias!';

  @override
  String get report_error => 'Error al enviar la denuncia';

  @override
  String get message_menu_action_report => 'Denunciar';

  @override
  String get partner_profile_menu_report => 'Denunciar usuario';

  @override
  String get call_bubble_voice_call => 'Llamada de voz';

  @override
  String get call_bubble_video_call => 'Videollamada';

  @override
  String get chat_preview_poll => 'Encuesta';

  @override
  String get chat_preview_forwarded => 'Mensaje reenviado';

  @override
  String get birthday_banner_celebrates => 'está de cumpleaños!';

  @override
  String get birthday_banner_action => 'Felicitar →';

  @override
  String get birthday_screen_title_today => 'Cumpleaños hoy';

  @override
  String birthday_screen_age(int age) {
    return 'Cumple $age';
  }

  @override
  String get birthday_section_actions => 'FELICITAR';

  @override
  String get birthday_action_template => 'Mensaje rápido';

  @override
  String get birthday_action_cake => 'Soplar la vela';

  @override
  String get birthday_action_confetti => 'Confeti';

  @override
  String get birthday_action_serpentine => 'Serpentinas';

  @override
  String get birthday_action_voice => 'Grabar saludo de voz';

  @override
  String get birthday_action_remind_next_year => 'Recordarme el año que viene';

  @override
  String get birthday_action_open_chat => 'Escribir tu propio mensaje';

  @override
  String get birthday_cake_prompt => 'Toca la vela para apagarla';

  @override
  String birthday_cake_wish_placeholder(Object name) {
    return '¿Qué deseas para $name?';
  }

  @override
  String get birthday_cake_wish_hint =>
      'Por ejemplo: que se cumplan todos tus sueños…';

  @override
  String get birthday_cake_send => 'Enviar';

  @override
  String birthday_cake_message(Object name, Object wish) {
    return '🎂 ¡Feliz cumpleaños, $name! Mi deseo para ti: «$wish»';
  }

  @override
  String birthday_confetti_message(Object name) {
    return '🎉 ¡Feliz cumpleaños, $name! 🎉';
  }

  @override
  String birthday_template_1(Object name) {
    return '¡Feliz cumpleaños, $name! ¡Que este año sea el mejor!';
  }

  @override
  String birthday_template_2(Object name) {
    return '$name, ¡felicidades! Te deseo alegría, cariño y que se cumplan tus sueños 🎉';
  }

  @override
  String birthday_template_3(Object name) {
    return '¡Feliz día, $name! Salud, suerte y muchos momentos felices 🎂';
  }

  @override
  String birthday_template_4(Object name) {
    return '$name, ¡feliz cumple! Que todos tus planes se cumplan fácilmente ✨';
  }

  @override
  String birthday_template_5(Object name) {
    return '¡Felicidades, $name! Gracias por existir. ¡Feliz cumpleaños! 🎁';
  }

  @override
  String get birthday_toast_sent => 'Felicitación enviada';

  @override
  String birthday_reminder_set(Object name) {
    return 'Te recordaremos un día antes del cumpleaños de $name';
  }

  @override
  String get birthday_reminder_notif_title => 'Mañana es cumpleaños 🎂';

  @override
  String birthday_reminder_notif_body(Object name) {
    return 'No olvides felicitar a $name mañana';
  }

  @override
  String get birthday_empty => 'Hoy no hay cumpleaños entre tus contactos';

  @override
  String get birthday_error_self => 'No se pudo cargar tu perfil';

  @override
  String get birthday_error_send =>
      'No se pudo enviar el mensaje. Inténtalo de nuevo.';

  @override
  String get birthday_error_reminder => 'No se pudo configurar el recordatorio';

  @override
  String get chat_empty_title => 'Aún no hay mensajes';

  @override
  String get chat_empty_subtitle =>
      'Saluda — el farero ya te está saludando con la mano';

  @override
  String get chat_empty_quick_greet => 'Saludar 👋';
}

/// The translations for Spanish Castilian, as used in Mexico (`es_MX`).
class AppLocalizationsEsMx extends AppLocalizationsEs {
  AppLocalizationsEsMx() : super('es_MX');

  @override
  String get secret_chat_title => 'Chat secreto';

  @override
  String get secret_chats_title => 'Chats secretos';

  @override
  String get secret_chat_locked_title => 'El chat secreto está bloqueado';

  @override
  String get secret_chat_locked_subtitle =>
      'Ingresa tu PIN para desbloquear y ver los mensajes.';

  @override
  String get secret_chat_unlock_title => 'Desbloquear chat secreto';

  @override
  String get secret_chat_unlock_subtitle =>
      'Se requiere PIN para abrir este chat.';

  @override
  String get secret_chat_unlock_action => 'Desbloquear';

  @override
  String get secret_chat_set_pin_and_unlock => 'Establecer PIN y desbloquear';

  @override
  String get secret_chat_pin_label => 'PIN (4 dígitos)';

  @override
  String get secret_chat_pin_invalid => 'Ingresa un PIN de 4 dígitos';

  @override
  String get secret_chat_already_exists =>
      'Ya existe un chat secreto con este usuario.';

  @override
  String get secret_chat_exists_badge => 'Creado';

  @override
  String get secret_chat_unlock_failed =>
      'No se pudo desbloquear. Intenta de nuevo.';

  @override
  String get secret_chat_action_not_allowed =>
      'Esta acción no está permitida en un chat secreto';

  @override
  String get secret_chat_remember_pin => 'Recordar PIN en este dispositivo';

  @override
  String get secret_chat_unlock_biometric => 'Desbloquear con biometría';

  @override
  String get secret_chat_biometric_reason => 'Desbloquear chat secreto';

  @override
  String get secret_chat_biometric_no_saved_pin =>
      'Ingresa el PIN una vez para habilitar el desbloqueo biométrico';

  @override
  String get secret_chat_ttl_title => 'Duración del chat secreto';

  @override
  String get secret_chat_settings_title => 'Configuración del chat secreto';

  @override
  String get secret_chat_settings_subtitle =>
      'Duración, acceso y restricciones';

  @override
  String get secret_chat_settings_not_secret =>
      'Este chat no es un chat secreto';

  @override
  String get secret_chat_settings_ttl => 'Duración';

  @override
  String secret_chat_settings_time_left(Object value) {
    return 'Tiempo restante: $value';
  }

  @override
  String secret_chat_settings_expires_at(Object iso) {
    return 'Expira el: $iso';
  }

  @override
  String get secret_chat_settings_unlock_grant_ttl => 'Duración del desbloqueo';

  @override
  String get secret_chat_settings_unlock_grant_ttl_subtitle =>
      'Cuánto tiempo permanece activo el acceso después de desbloquear';

  @override
  String get secret_chat_settings_no_copy => 'Desactivar copiado';

  @override
  String get secret_chat_settings_no_forward => 'Desactivar reenvío';

  @override
  String get secret_chat_settings_no_save =>
      'Desactivar guardado de multimedia';

  @override
  String get secret_chat_settings_screenshot_protection =>
      'Protección contra capturas de pantalla (Android)';

  @override
  String get secret_chat_settings_media_views =>
      'Límites de visualización de multimedia';

  @override
  String get secret_chat_settings_media_views_subtitle =>
      'Límites aproximados de visualizaciones del destinatario';

  @override
  String get secret_chat_media_type_image => 'Imágenes';

  @override
  String get secret_chat_media_type_video => 'Vídeos';

  @override
  String get secret_chat_media_type_voice => 'Mensajes de voz';

  @override
  String get secret_chat_media_type_location => 'Ubicación';

  @override
  String get secret_chat_media_type_file => 'Archivos';

  @override
  String get secret_chat_media_views_unlimited => 'Ilimitado';

  @override
  String get secret_chat_compose_create => 'Crear chat secreto';

  @override
  String get secret_chat_compose_vault_pin_subtitle =>
      'Opcional: establece un PIN de 4 dígitos para desbloquear la bandeja secreta (almacenado en este dispositivo para biometría cuando está habilitado).';

  @override
  String get secret_chat_compose_require_unlock_pin =>
      'Requerir PIN para abrir este chat';

  @override
  String get secret_chat_settings_read_only_hint =>
      'Estos ajustes se fijan al crear y no se pueden cambiar.';

  @override
  String get secret_chat_settings_delete => 'Eliminar chat secreto';

  @override
  String get secret_chat_settings_delete_confirm_title =>
      '¿Eliminar este chat secreto?';

  @override
  String get secret_chat_settings_delete_confirm_body =>
      'Los mensajes y multimedia se eliminarán para ambos participantes.';

  @override
  String get privacy_secret_vault_title => 'Bóveda secreta';

  @override
  String get privacy_secret_vault_subtitle =>
      'PIN global y verificación biométrica para acceder a los chats secretos.';

  @override
  String get privacy_secret_vault_change_pin =>
      'Establecer o cambiar PIN de bóveda';

  @override
  String get privacy_secret_vault_change_pin_subtitle =>
      'Si ya existe un PIN, confírmalo usando el PIN anterior o biometría.';

  @override
  String get privacy_secret_vault_bio_subtitle =>
      'Ejecutar verificación biométrica y validar el PIN local guardado.';

  @override
  String get privacy_secret_vault_bio_reason =>
      'Confirmar acceso a los chats secretos';

  @override
  String get privacy_secret_vault_current_pin => 'PIN actual';

  @override
  String get privacy_secret_vault_new_pin => 'Nuevo PIN';

  @override
  String get privacy_secret_vault_repeat_pin => 'Repetir nuevo PIN';

  @override
  String get privacy_secret_vault_pin_mismatch => 'Los PINs no coinciden';

  @override
  String get privacy_secret_vault_pin_updated => 'PIN de bóveda actualizado';

  @override
  String get privacy_secret_vault_bio_unavailable =>
      'La autenticación biométrica no está disponible en este dispositivo';

  @override
  String get privacy_secret_vault_bio_verified =>
      'Verificación biométrica exitosa';

  @override
  String get privacy_secret_vault_setup_required =>
      'Configura primero el PIN o el acceso biométrico en Privacidad.';

  @override
  String get privacy_secret_vault_network_timeout =>
      'Tiempo de espera agotado. Intenta de nuevo.';

  @override
  String privacy_secret_vault_error(Object error) {
    return 'Error de bóveda secreta: $error';
  }

  @override
  String get tournament_title => 'Torneo';

  @override
  String get tournament_subtitle => 'Clasificación y series de juegos';

  @override
  String get tournament_new_game => 'Nuevo juego';

  @override
  String get tournament_standings => 'Clasificación';

  @override
  String get tournament_standings_empty => 'Sin resultados aún';

  @override
  String get tournament_games => 'Juegos';

  @override
  String get tournament_games_empty => 'Sin juegos aún';

  @override
  String tournament_points(Object pts) {
    return '$pts puntos';
  }

  @override
  String tournament_games_played(Object n) {
    return '$n juegos';
  }

  @override
  String tournament_create_failed(Object err) {
    return 'No se pudo crear el torneo: $err';
  }

  @override
  String tournament_create_game_failed(Object err) {
    return 'No se pudo crear el juego: $err';
  }

  @override
  String tournament_game_players(Object names) {
    return 'Jugadores: $names';
  }

  @override
  String get tournament_game_result_draw => 'Resultado: empate';

  @override
  String tournament_game_result_loser(Object name) {
    return 'Resultado: durak — $name';
  }

  @override
  String tournament_game_place(Object place) {
    return 'Lugar $place';
  }

  @override
  String get durak_dm_lobby_banner =>
      'Tu compañero creó una sala de Durak — únete';

  @override
  String get durak_dm_lobby_open => 'Abrir sala';

  @override
  String get conversation_game_lobby_cancel => 'Terminar espera';

  @override
  String conversation_game_lobby_cancel_failed(Object err) {
    return 'No se pudo terminar la espera: $err';
  }

  @override
  String secret_chat_media_views_count(Object count) {
    return '$count visualizaciones';
  }

  @override
  String secret_chat_settings_load_failed(Object error) {
    return 'Error al cargar: $error';
  }

  @override
  String secret_chat_settings_save_failed(Object error) {
    return 'Error al guardar: $error';
  }

  @override
  String get secret_chat_settings_reset_strict =>
      'Restablecer valores estrictos predeterminados';

  @override
  String get secret_chat_settings_reset_strict_subtitle =>
      'Activa todas las restricciones y establece el límite de visualización a 1';

  @override
  String get settings_language_title => 'Idioma';

  @override
  String get settings_language_system => 'Sistema';

  @override
  String get settings_language_ru => 'Ruso';

  @override
  String get settings_language_en => 'Inglés';

  @override
  String get settings_language_hint_system =>
      'Cuando se selecciona “Sistema”, la app sigue la configuración de idioma de tu dispositivo.';

  @override
  String get account_menu_profile => 'Perfil';

  @override
  String get account_menu_features => 'Funciones';

  @override
  String get account_menu_chat_settings => 'Configuración del chat';

  @override
  String get account_menu_notifications => 'Notificaciones';

  @override
  String get account_menu_privacy => 'Privacidad';

  @override
  String get account_menu_devices => 'Dispositivos';

  @override
  String get account_menu_blacklist => 'Lista de bloqueados';

  @override
  String get account_menu_language => 'Idioma';

  @override
  String get account_menu_storage => 'Almacenamiento';

  @override
  String get account_menu_theme => 'Tema';

  @override
  String get account_menu_sign_out => 'Cerrar sesión';

  @override
  String get storage_settings_title => 'Almacenamiento';

  @override
  String get storage_settings_subtitle =>
      'Controla qué datos se almacenan en caché en este dispositivo y limpia por chats o archivos.';

  @override
  String get storage_settings_total_label => 'Usado en este dispositivo';

  @override
  String storage_settings_budget_label(Object gb) {
    return 'Límite de caché: $gb GB';
  }

  @override
  String get storage_unit_gb => 'ES';

  @override
  String get storage_settings_clear_all_button => 'Borrar toda la caché';

  @override
  String get storage_settings_trim_button => 'Ajustar al límite';

  @override
  String get storage_settings_policy_title => 'Qué mantener localmente';

  @override
  String get storage_settings_budget_slider_title => 'Presupuesto de caché';

  @override
  String get storage_settings_breakdown_title => 'Por tipo de datos';

  @override
  String get storage_settings_breakdown_empty =>
      'No hay datos en caché local aún.';

  @override
  String get storage_settings_chats_title => 'Por chats';

  @override
  String get storage_settings_chats_empty =>
      'No hay caché específica de chat aún.';

  @override
  String storage_settings_chat_subtitle(Object count, Object size) {
    return '$count elementos · $size';
  }

  @override
  String get storage_settings_general_title => 'Caché no asignada';

  @override
  String get storage_settings_general_hint =>
      'Entradas no vinculadas a un chat específico (caché global/heredada).';

  @override
  String get storage_settings_general_empty =>
      'No hay entradas de caché compartidas.';

  @override
  String get storage_settings_chat_files_empty =>
      'No hay archivos locales en la caché de este chat.';

  @override
  String get storage_settings_clear_chat_action => 'Borrar caché del chat';

  @override
  String get storage_settings_clear_all_title => '¿Borrar caché local?';

  @override
  String get storage_settings_clear_all_body =>
      'Esto eliminará archivos en caché, vistas previas, borradores y copias sin conexión de este dispositivo.';

  @override
  String storage_settings_clear_chat_title(Object chat) {
    return 'Borrar caché de “$chat”?';
  }

  @override
  String get storage_settings_clear_chat_body =>
      'Solo se eliminará la caché de este chat. Los mensajes en la nube permanecen intactos.';

  @override
  String get storage_settings_snackbar_cleared => 'Caché local borrada';

  @override
  String get storage_settings_snackbar_budget_already_ok =>
      'La caché ya cumple con el presupuesto objetivo';

  @override
  String storage_settings_snackbar_budget_trimmed(Object size) {
    return 'Liberado: $size';
  }

  @override
  String get storage_settings_error_empty =>
      'No se pudieron generar las estadísticas de almacenamiento';

  @override
  String get storage_category_e2ee_media => 'Caché de multimedia E2EE';

  @override
  String get storage_category_e2ee_media_subtitle =>
      'Archivos multimedia secretos descifrados por chat para una reapertura más rápida.';

  @override
  String get storage_category_e2ee_text => 'Caché de texto E2EE';

  @override
  String get storage_category_e2ee_text_subtitle =>
      'Fragmentos de texto descifrados por chat para renderizado instantáneo.';

  @override
  String get storage_category_drafts => 'Borradores de mensajes';

  @override
  String get storage_category_drafts_subtitle =>
      'Texto de borradores no enviados por chat.';

  @override
  String get storage_category_chat_list_snapshot =>
      'Lista de chats sin conexión';

  @override
  String get storage_category_chat_list_snapshot_subtitle =>
      'Captura reciente de la lista de chats para inicio rápido sin conexión.';

  @override
  String get storage_category_profile_cards => 'Mini-caché de perfil';

  @override
  String get storage_category_profile_cards_subtitle =>
      'Nombres y avatares guardados para una interfaz más rápida.';

  @override
  String get storage_category_video_downloads => 'Caché de videos descargados';

  @override
  String get storage_category_video_downloads_subtitle =>
      'Videos descargados localmente desde vistas de galería.';

  @override
  String get storage_category_video_thumbs =>
      'Fotogramas de vista previa de video';

  @override
  String get storage_category_video_thumbs_subtitle =>
      'Miniaturas del primer fotograma generadas para videos.';

  @override
  String get storage_category_chat_images => 'Fotos del chat';

  @override
  String get storage_category_chat_images_subtitle =>
      'Fotos y stickers en caché de chats abiertos.';

  @override
  String get storage_category_stickers_gifs_emoji => 'Stickers, GIF y emoji';

  @override
  String get storage_category_stickers_gifs_emoji_subtitle =>
      'Caché de stickers recientes y de GIPHY (gif/stickers/emoji animados).';

  @override
  String get storage_category_network_images => 'Caché de imágenes de red';

  @override
  String get storage_category_network_images_subtitle =>
      'Avatares, vistas previas y otras imágenes obtenidas por red (libCachedImageData).';

  @override
  String get storage_media_type_video => 'Video';

  @override
  String get storage_media_type_photo => 'Fotos';

  @override
  String get storage_media_type_audio => 'Audio';

  @override
  String get storage_media_type_files => 'Archivos';

  @override
  String get storage_media_type_other => 'Otros';

  @override
  String storage_settings_device_usage(Object pct) {
    return 'Usa $pct% del presupuesto de caché';
  }

  @override
  String get storage_settings_clear_all_hint =>
      'Toda la multimedia permanece en la nube. Puedes volver a descargarla en cualquier momento.';

  @override
  String get storage_settings_categories_title => 'Por categoría';

  @override
  String storage_settings_clear_category_title(String category) {
    return '¿Borrar \"$category\"?';
  }

  @override
  String storage_settings_clear_category_body(String size) {
    return 'Se liberarán aproximadamente $size. Esta acción no se puede deshacer.';
  }

  @override
  String get storage_auto_delete_title =>
      'Eliminar automáticamente multimedia en caché';

  @override
  String get storage_auto_delete_personal => 'Chats personales';

  @override
  String get storage_auto_delete_groups => 'Grupos';

  @override
  String get storage_auto_delete_never => 'Nunca';

  @override
  String get storage_auto_delete_3_days => '3 días';

  @override
  String get storage_auto_delete_1_week => '1 semana';

  @override
  String get storage_auto_delete_1_month => '1 mes';

  @override
  String get storage_auto_delete_3_months => '3 meses';

  @override
  String get storage_auto_delete_hint =>
      'Las fotos, videos y archivos que no hayas abierto durante este período se eliminarán del dispositivo para ahorrar espacio.';

  @override
  String storage_chat_detail_share(Object pct) {
    return 'Este chat usa $pct% de tu caché';
  }

  @override
  String get storage_chat_detail_media_tab => 'Multimedia';

  @override
  String get storage_chat_detail_select_all => 'Seleccionar todo';

  @override
  String get storage_chat_detail_deselect_all => 'Deseleccionar todo';

  @override
  String storage_chat_detail_clear_button(Object size) {
    return 'Borrar caché $size';
  }

  @override
  String get storage_chat_detail_clear_button_empty =>
      'Seleccionar archivos para eliminar';

  @override
  String get storage_chat_detail_tab_empty => 'Nada en esta pestaña.';

  @override
  String get storage_chat_detail_delete_title =>
      '¿Eliminar archivos seleccionados?';

  @override
  String storage_chat_detail_delete_body(Object count, Object size) {
    return '$count archivos ($size) se eliminarán del dispositivo. Las copias en la nube permanecen intactas.';
  }

  @override
  String get profile_delete_account => 'Eliminar cuenta';

  @override
  String get profile_delete_account_confirm_title =>
      '¿Eliminar tu cuenta permanentemente?';

  @override
  String get profile_delete_account_confirm_body =>
      'Tu cuenta se eliminará de Firebase Auth y todos tus documentos de Firestore se borrarán permanentemente. Tus chats seguirán visibles para otros en modo de solo lectura.';

  @override
  String get profile_delete_account_confirm_action => 'Eliminar cuenta';

  @override
  String profile_delete_account_error(Object error) {
    return 'No se pudo eliminar la cuenta: $error';
  }

  @override
  String get chat_readonly_deleted_user =>
      'Cuenta eliminada. Este chat es de solo lectura.';

  @override
  String get blacklist_empty => 'No hay usuarios bloqueados';

  @override
  String get blacklist_action_unblock => 'Desbloquear';

  @override
  String get blacklist_unblock_confirm_title => '¿Desbloquear?';

  @override
  String get blacklist_unblock_confirm_body =>
      'Este usuario podrá enviarte mensajes de nuevo (si la política de contacto lo permite) y ver tu perfil en búsqueda.';

  @override
  String get blacklist_unblock_success => 'Usuario desbloqueado';

  @override
  String blacklist_unblock_error(Object error) {
    return 'No se pudo desbloquear: $error';
  }

  @override
  String get partner_profile_block_confirm_title => '¿Bloquear a este usuario?';

  @override
  String get partner_profile_block_confirm_body =>
      'No verán un chat contigo, no podrán encontrarte en búsqueda ni agregarte a contactos. Desaparecerás de sus contactos. Conservarás el historial del chat, pero no podrás enviarles mensajes mientras estén bloqueados.';

  @override
  String get partner_profile_block_action => 'Bloquear';

  @override
  String get partner_profile_block_success => 'Usuario bloqueado';

  @override
  String partner_profile_block_error(Object error) {
    return 'No se pudo bloquear: $error';
  }

  @override
  String get common_soon => 'Próximamente';

  @override
  String common_theme_prefix(Object label) {
    return 'Tema: $label';
  }

  @override
  String common_error_cannot_save_theme(Object error) {
    return 'No se pudo guardar el tema: $error';
  }

  @override
  String common_error_cannot_sign_out(Object error) {
    return 'No se pudo cerrar sesión: $error';
  }

  @override
  String account_error_profile(Object error) {
    return 'Error de perfil: $error';
  }

  @override
  String get notifications_title => 'Notificaciones';

  @override
  String get notifications_section_main => 'Principal';

  @override
  String get notifications_mute_all_title => 'Desactivar todo';

  @override
  String get notifications_mute_all_subtitle =>
      'Desactivar todas las notificaciones.';

  @override
  String get notifications_sound_title => 'Sonido';

  @override
  String get notifications_sound_subtitle =>
      'Reproducir un sonido para nuevos mensajes.';

  @override
  String get notifications_preview_title => 'Vista previa';

  @override
  String get notifications_preview_subtitle =>
      'Mostrar texto del mensaje en las notificaciones.';

  @override
  String get notifications_message_ringtone_label => 'Tono de mensajes';

  @override
  String get notifications_call_ringtone_label => 'Tono de llamadas';

  @override
  String get notifications_meeting_hand_raise_title =>
      'Sonido de mano levantada';

  @override
  String get notifications_meeting_hand_raise_subtitle =>
      'Señal suave cuando un participante levanta la mano.';

  @override
  String get ringtone_default => 'Predeterminado';

  @override
  String get ringtone_classic_chime => 'Carillón clásico';

  @override
  String get ringtone_gentle_bells => 'Campanas suaves';

  @override
  String get ringtone_marimba_tap => 'Marimba';

  @override
  String get ringtone_soft_pulse => 'Pulso suave';

  @override
  String get ringtone_ascending_chord => 'Acorde ascendente';

  @override
  String get ringtone_storage_original => 'Original (Storage)';

  @override
  String get ringtone_preview_play => 'Escuchar';

  @override
  String get ringtone_picker_messages_title => 'Tono de mensajes';

  @override
  String get ringtone_picker_calls_title => 'Tono de llamadas';

  @override
  String get notifications_section_quiet_hours => 'Horas de silencio';

  @override
  String get notifications_quiet_hours_subtitle =>
      'Las notificaciones no te molestarán durante este período.';

  @override
  String get notifications_quiet_hours_enable_title =>
      'Activar horas de silencio';

  @override
  String get notifications_reset_button => 'Restablecer configuración';

  @override
  String notifications_error_cannot_save(Object error) {
    return 'No se pudo guardar la configuración: $error';
  }

  @override
  String notifications_error_load(Object error) {
    return 'No se pudieron cargar las notificaciones: $error';
  }

  @override
  String get privacy_title => 'Privacidad del chat';

  @override
  String privacy_error_cannot_save(Object error) {
    return 'No se pudo guardar la configuración: $error';
  }

  @override
  String privacy_error_load(Object error) {
    return 'No se pudo cargar la configuración de privacidad: $error';
  }

  @override
  String get privacy_e2ee_section => 'Cifrado de extremo a extremo';

  @override
  String get privacy_e2ee_enable_for_all_chats =>
      'Activar E2EE para todos los chats';

  @override
  String get privacy_e2ee_what_encrypt => 'Qué se cifra en los chats E2EE';

  @override
  String get privacy_e2ee_text => 'Texto del mensaje';

  @override
  String get privacy_e2ee_media => 'Adjuntos (multimedia/archivos)';

  @override
  String get privacy_my_devices_title => 'Mis dispositivos';

  @override
  String get privacy_my_devices_subtitle =>
      'Dispositivos con claves publicadas. Renombra o revoca el acceso.';

  @override
  String get privacy_key_backup_title => 'Respaldo y transferencia de claves';

  @override
  String get privacy_key_backup_subtitle =>
      'Crea un respaldo con contraseña o transfiere la clave por QR.';

  @override
  String get privacy_visibility_section => 'Visibilidad';

  @override
  String get privacy_online_title => 'Estado en línea';

  @override
  String get privacy_online_subtitle =>
      'Permitir que otros vean cuando estás en línea.';

  @override
  String get privacy_last_seen_title => 'Última vez';

  @override
  String get privacy_last_seen_subtitle =>
      'Mostrar tu última hora de actividad.';

  @override
  String get privacy_read_receipts_title => 'Confirmaciones de lectura';

  @override
  String get privacy_read_receipts_subtitle =>
      'Permitir que los remitentes sepan que leíste un mensaje.';

  @override
  String get privacy_group_invites_section => 'Invitaciones a grupos';

  @override
  String get privacy_group_invites_subtitle =>
      'Quién puede agregarte a chats grupales.';

  @override
  String get privacy_group_invites_everyone => 'Todos';

  @override
  String get privacy_group_invites_contacts => 'Solo contactos';

  @override
  String get privacy_group_invites_nobody => 'Nadie';

  @override
  String get privacy_global_search_section => 'Visibilidad en búsqueda';

  @override
  String get privacy_global_search_subtitle =>
      'Quién puede encontrarte por nombre entre todos los usuarios.';

  @override
  String get privacy_global_search_title => 'Búsqueda global';

  @override
  String get privacy_global_search_hint =>
      'Si se desactiva, no aparecerás en “Todos los usuarios” cuando alguien inicie un nuevo chat. Seguirás siendo visible para quienes te agregaron como contacto.';

  @override
  String get privacy_profile_for_others_section => 'Perfil para otros';

  @override
  String get privacy_profile_for_others_subtitle =>
      'Lo que otros pueden ver en tu perfil.';

  @override
  String get privacy_email_subtitle => 'Tu correo electrónico en tu perfil.';

  @override
  String get privacy_phone_title => 'Número de teléfono';

  @override
  String get privacy_phone_subtitle => 'Visible en tu perfil y contactos.';

  @override
  String get privacy_birthdate_title => 'Fecha de nacimiento';

  @override
  String get privacy_birthdate_subtitle =>
      'Tu campo de cumpleaños en el perfil.';

  @override
  String get privacy_about_title => 'Acerca de';

  @override
  String get privacy_about_subtitle => 'Tu texto de biografía en el perfil.';

  @override
  String get privacy_reset_button => 'Restablecer configuración';

  @override
  String get common_cancel => 'Cancelar';

  @override
  String get common_create => 'Crear';

  @override
  String get common_delete => 'Eliminar';

  @override
  String get common_choose => 'Elegir';

  @override
  String get common_save => 'Guardar';

  @override
  String get common_close => 'Cerrar';

  @override
  String get common_nothing_found => 'No se encontró nada';

  @override
  String get common_retry => 'Reintentar';

  @override
  String get auth_login_email_label => 'Correo electrónico';

  @override
  String get auth_login_password_label => 'Contraseña';

  @override
  String get auth_login_password_hint => 'Contraseña';

  @override
  String get auth_login_sign_in => 'Iniciar sesión';

  @override
  String get auth_login_forgot_password => '¿Olvidaste tu contraseña?';

  @override
  String get auth_login_error_enter_email_for_reset =>
      'Ingresa tu correo para restablecer tu contraseña';

  @override
  String get profile_title => 'Perfil';

  @override
  String get profile_edit_tooltip => 'Editar';

  @override
  String get profile_full_name_label => 'Nombre completo';

  @override
  String get profile_full_name_hint => 'Nombre';

  @override
  String get profile_username_label => 'Nombre de usuario';

  @override
  String get profile_email_label => 'Correo electrónico';

  @override
  String get profile_phone_label => 'Teléfono';

  @override
  String get profile_birthdate_label => 'Fecha de nacimiento';

  @override
  String get profile_about_label => 'Acerca de';

  @override
  String get profile_about_hint => 'Una breve biografía';

  @override
  String get profile_password_toggle_show => 'Cambiar contraseña';

  @override
  String get profile_password_toggle_hide => 'Ocultar cambio de contraseña';

  @override
  String get profile_password_new_label => 'Nueva contraseña';

  @override
  String get profile_password_confirm_label => 'Confirmar contraseña';

  @override
  String get profile_password_tooltip_show => 'Mostrar contraseña';

  @override
  String get profile_password_tooltip_hide => 'Ocultar';

  @override
  String get profile_placeholder_username => 'nombre_de_usuario';

  @override
  String get profile_placeholder_email => 'nombre@ejemplo.com';

  @override
  String get profile_placeholder_phone => '+52 55 0000-0000';

  @override
  String get profile_placeholder_birthdate => 'DD.MM.AAAA';

  @override
  String get profile_placeholder_password_dots => '••••••••';

  @override
  String get profile_password_error_fill_both =>
      'Completa la nueva contraseña y la confirmación.';

  @override
  String get settings_chats_title => 'Configuración del chat';

  @override
  String get settings_chats_preview => 'Vista previa';

  @override
  String get settings_chats_outgoing => 'Mensajes enviados';

  @override
  String get settings_chats_incoming => 'Mensajes recibidos';

  @override
  String get settings_chats_font_size => 'Tamaño de texto';

  @override
  String get settings_chats_font_small => 'Pequeño';

  @override
  String get settings_chats_font_medium => 'Mediano';

  @override
  String get settings_chats_font_large => 'Grande';

  @override
  String get settings_chats_bubble_shape => 'Forma de burbuja';

  @override
  String get settings_chats_bubble_rounded => 'Redondeada';

  @override
  String get settings_chats_bubble_square => 'Cuadrada';

  @override
  String get settings_chats_chat_background => 'Fondo del chat';

  @override
  String get settings_chats_chat_background_pick_hint =>
      'Elige una foto o ajusta el fondo';

  @override
  String get settings_chats_advanced => 'Avanzado';

  @override
  String get settings_chats_show_time => 'Mostrar hora';

  @override
  String get settings_chats_show_time_subtitle =>
      'Mostrar hora del mensaje debajo de las burbujas';

  @override
  String get settings_chats_reset => 'Restablecer configuración';

  @override
  String settings_chats_error_cannot_save(Object error) {
    return 'No se pudo guardar: $error';
  }

  @override
  String settings_chats_error_wallpaper_load(Object error) {
    return 'No se pudo cargar el fondo: $error';
  }

  @override
  String settings_chats_error_wallpaper_delete(Object error) {
    return 'No se pudo eliminar el fondo: $error';
  }

  @override
  String get settings_chats_wallpaper_delete_confirm_title =>
      '¿Eliminar fondo?';

  @override
  String get settings_chats_wallpaper_delete_confirm_body =>
      'Este fondo se eliminará de tu lista.';

  @override
  String settings_chats_icon_picker_title(Object label) {
    return 'Icono: “$label”';
  }

  @override
  String get settings_chats_icon_picker_search_hint => 'Buscar por nombre…';

  @override
  String get settings_chats_icon_color => 'Color del icono';

  @override
  String get settings_chats_reset_icon_size => 'Restablecer tamaño';

  @override
  String get settings_chats_reset_icon_stroke => 'Restablecer trazo';

  @override
  String get settings_chats_tile_background => 'Mosaico de fondo';

  @override
  String get settings_chats_default_gradient => 'Degradado predeterminado';

  @override
  String get settings_chats_inherit_global => 'Usar configuración global';

  @override
  String get settings_chats_no_background => 'Sin fondo';

  @override
  String get settings_chats_no_background_on => 'Sin fondo (activado)';

  @override
  String get chat_list_title => 'Charlas';

  @override
  String get chat_list_search_hint => 'Buscar…';

  @override
  String get chat_list_loading_connecting => 'Conectando…';

  @override
  String get chat_list_loading_conversations => 'Cargando conversaciones…';

  @override
  String get chat_list_loading_list => 'Cargando lista de chats…';

  @override
  String get chat_list_loading_sign_out => 'Cerrando sesión…';

  @override
  String get chat_list_empty_search_title => 'No se encontraron chats';

  @override
  String get chat_list_empty_search_body =>
      'Intenta otra búsqueda. Funciona por nombre y nombre de usuario.';

  @override
  String get chat_list_empty_folder_title => 'Esta carpeta está vacía';

  @override
  String get chat_list_empty_folder_body =>
      'Cambia de carpeta o inicia un nuevo chat con el botón de arriba.';

  @override
  String get chat_list_empty_all_title => 'Aún no hay chats';

  @override
  String get chat_list_empty_all_body =>
      'Inicia un nuevo chat para empezar a enviar mensajes.';

  @override
  String get chat_list_action_new_folder => 'Nueva carpeta';

  @override
  String get chat_list_action_new_chat => 'Nuevo chat';

  @override
  String get chat_list_action_create => 'Crear';

  @override
  String get chat_list_action_close => 'Cerrar';

  @override
  String get chat_list_folders_title => 'Carpetas';

  @override
  String get chat_list_folders_subtitle => 'Elige carpetas para este chat.';

  @override
  String get chat_list_folders_empty => 'Aún no hay carpetas personalizadas.';

  @override
  String get chat_list_create_folder_title => 'Nueva carpeta';

  @override
  String get chat_list_create_folder_subtitle =>
      'Crea una carpeta para filtrar rápidamente tus chats.';

  @override
  String get chat_list_create_folder_name_label => 'NOMBRE DE CARPETA';

  @override
  String get chat_list_create_folder_name_hint => 'Nombre de carpeta';

  @override
  String chat_list_create_folder_chats_label(Object count) {
    return 'CHATS ($count)';
  }

  @override
  String get chat_list_create_folder_select_all => 'SELECCIONAR TODO';

  @override
  String get chat_list_create_folder_reset => 'RESTABLECER';

  @override
  String get chat_list_create_folder_search_hint => 'Buscar por nombre…';

  @override
  String get chat_list_create_folder_no_matches => 'No hay chats que coincidan';

  @override
  String get chat_list_folder_default_starred => 'Destacados';

  @override
  String get chat_list_folder_default_all => 'Todos';

  @override
  String get chat_list_folder_default_new => 'Nuevos';

  @override
  String get chat_list_folder_default_direct => 'Directos';

  @override
  String get chat_list_folder_default_groups => 'Grupos';

  @override
  String get chat_list_yesterday => 'Ayer';

  @override
  String get chat_list_folder_delete_action => 'Eliminar';

  @override
  String get chat_list_folder_delete_title => '¿Eliminar carpeta?';

  @override
  String chat_list_folder_delete_body(Object name) {
    return 'La carpeta \"$name\" se eliminará. Los chats permanecerán intactos.';
  }

  @override
  String chat_list_error_open_starred(Object error) {
    return 'No se pudo abrir Destacados: $error';
  }

  @override
  String chat_list_error_delete_folder(Object error) {
    return 'No se pudo eliminar la carpeta: $error';
  }

  @override
  String get chat_list_pin_not_available =>
      'Fijar no está disponible en esta carpeta.';

  @override
  String chat_list_pin_pinned_in_folder(Object name) {
    return 'Chat fijado en \"$name\"';
  }

  @override
  String chat_list_pin_unpinned_in_folder(Object name) {
    return 'Chat desfijado de \"$name\"';
  }

  @override
  String chat_list_error_toggle_pin(Object error) {
    return 'No se pudo cambiar el fijado: $error';
  }

  @override
  String chat_list_error_update_folder(Object error) {
    return 'No se pudo actualizar la carpeta: $error';
  }

  @override
  String get chat_list_clear_history_title => '¿Borrar historial?';

  @override
  String get chat_list_clear_history_body =>
      'Los mensajes desaparecerán solo de tu vista del chat. El otro participante conservará el historial.';

  @override
  String get chat_list_clear_history_confirm => 'Borrar';

  @override
  String chat_list_error_clear_history(Object error) {
    return 'No se pudo borrar el historial: $error';
  }

  @override
  String chat_list_error_mark_read(Object error) {
    return 'No se pudo marcar el chat como leído: $error';
  }

  @override
  String get chat_list_delete_chat_title => '¿Eliminar chat?';

  @override
  String get chat_list_delete_chat_body =>
      'La conversación se eliminará permanentemente para todos los participantes. Esto no se puede deshacer.';

  @override
  String get chat_list_delete_chat_confirm => 'Eliminar';

  @override
  String chat_list_error_delete_chat(Object error) {
    return 'No se pudo eliminar el chat: $error';
  }

  @override
  String get chat_list_context_folders => 'Carpetas';

  @override
  String get chat_list_context_unpin => 'Desfijar chat';

  @override
  String get chat_list_context_pin => 'Fijar chat';

  @override
  String get chat_list_context_mark_all_read => 'Marcar todo como leído';

  @override
  String get chat_list_context_clear_history => 'Borrar historial';

  @override
  String get chat_list_context_delete_chat => 'Eliminar chat';

  @override
  String get chat_list_snackbar_history_cleared => 'Historial borrado.';

  @override
  String get chat_list_snackbar_marked_read => 'Marcado como leído.';

  @override
  String chat_list_error_generic(Object error) {
    return 'Error: $error';
  }

  @override
  String get chat_calls_title => 'Llamadas';

  @override
  String get chat_calls_search_hint => 'Buscar por nombre…';

  @override
  String get chat_calls_empty => 'Tu historial de llamadas está vacío.';

  @override
  String get chat_calls_nothing_found => 'No se encontró nada.';

  @override
  String chat_calls_error_load(Object error) {
    return 'No se pudieron cargar las llamadas:\n$error';
  }

  @override
  String get chat_reply_cancel_tooltip => 'Cancelar respuesta';

  @override
  String get voice_preview_tooltip_cancel => 'Cancelar';

  @override
  String get voice_preview_tooltip_send => 'Enviar';

  @override
  String get profile_qr_title => 'Mi código QR';

  @override
  String get profile_qr_tooltip_close => 'Cerrar';

  @override
  String get profile_qr_share_title => 'Mi perfil de LighChat';

  @override
  String get profile_qr_share_subject => 'Perfil de LighChat';

  @override
  String chat_media_norm_pending_title(Object mediaKind) {
    return 'Procesando $mediaKind…';
  }

  @override
  String chat_media_norm_failed_title(Object mediaKind) {
    return 'No se pudo procesar $mediaKind';
  }

  @override
  String get chat_media_norm_pending_subtitle =>
      'El archivo estará disponible después del procesamiento del servidor.';

  @override
  String get chat_media_norm_failed_subtitle =>
      'Intenta iniciar el procesamiento de nuevo.';

  @override
  String get conversation_threads_title => 'Hilos';

  @override
  String get conversation_threads_empty => 'Aún no hay hilos';

  @override
  String get conversation_threads_root_attachment => 'Adjunto';

  @override
  String get conversation_threads_root_message => 'Mensaje';

  @override
  String conversation_threads_snippet_you(Object text) {
    return 'Tú: $text';
  }

  @override
  String get conversation_threads_day_today => 'Hoy';

  @override
  String get conversation_threads_day_yesterday => 'Ayer';

  @override
  String conversation_threads_replies_badge(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count respuestas',
      one: '$count respuesta',
    );
    return '$_temp0';
  }

  @override
  String get chat_meetings_title => 'Reuniones';

  @override
  String get chat_meetings_subtitle =>
      'Crea conferencias y administra el acceso de participantes';

  @override
  String get chat_meetings_section_new => 'Nueva reunión';

  @override
  String get chat_meetings_field_title_label => 'Título de la reunión';

  @override
  String get chat_meetings_field_title_hint =>
      'Ej., Sincronización de logística';

  @override
  String get chat_meetings_field_duration_label => 'Duración';

  @override
  String get chat_meetings_duration_unlimited => 'Sin límite';

  @override
  String get chat_meetings_duration_15m => '15 minutos';

  @override
  String get chat_meetings_duration_30m => '30 minutos';

  @override
  String get chat_meetings_duration_1h => '1 hora';

  @override
  String get chat_meetings_duration_90m => '1.5 horas';

  @override
  String get chat_meetings_field_access_label => 'Acceso';

  @override
  String get chat_meetings_access_private => 'Privada';

  @override
  String get chat_meetings_access_public => 'Pública';

  @override
  String get chat_meetings_waiting_room_title => 'Sala de espera';

  @override
  String get chat_meetings_waiting_room_desc =>
      'En modo de sala de espera, tú controlas quién se une. Hasta que toques “Admitir”, los invitados permanecerán en la pantalla de espera.';

  @override
  String get chat_meetings_backgrounds_title => 'Fondos virtuales';

  @override
  String get chat_meetings_backgrounds_desc =>
      'Sube fondos y difumina tu fondo si quieres. Elige una imagen de la galería o sube tus propios fondos.';

  @override
  String get chat_meetings_create_button => 'Crear reunión';

  @override
  String get chat_meetings_snackbar_enter_title =>
      'Ingresa un título para la reunión';

  @override
  String get chat_meetings_snackbar_auth_required =>
      'Necesitas iniciar sesión para crear una reunión';

  @override
  String chat_meetings_error_create_failed(Object error) {
    return 'No se pudo crear la reunión: $error';
  }

  @override
  String get chat_meetings_history_title => 'Tu historial';

  @override
  String get chat_meetings_history_empty =>
      'El historial de reuniones está vacío';

  @override
  String chat_meetings_history_error(Object error) {
    return 'No se pudo cargar el historial de reuniones: $error';
  }

  @override
  String get chat_meetings_status_live => 'en vivo';

  @override
  String get chat_meetings_status_finished => 'finalizada';

  @override
  String get chat_meetings_badge_private => 'privada';

  @override
  String get chat_contacts_search_hint => 'Buscar contactos…';

  @override
  String get chat_contacts_permission_denied =>
      'Permiso de contactos no otorgado.';

  @override
  String chat_contacts_sync_error(Object error) {
    return 'No se pudieron sincronizar los contactos: $error';
  }

  @override
  String chat_contacts_invite_prepare_failed(Object error) {
    return 'No se pudo preparar la invitación: $error';
  }

  @override
  String get chat_contacts_matches_not_found =>
      'No se encontraron coincidencias.';

  @override
  String chat_contacts_added_count(Object count) {
    return 'Contactos agregados: $count.';
  }

  @override
  String get chat_contacts_invite_text =>
      'Instala LighChat: https://lighchat.online\nTe invito a LighChat — aquí está el enlace de instalación.';

  @override
  String get chat_contacts_invite_subject => 'Invitación a LighChat';

  @override
  String chat_contacts_error_load(Object error) {
    return 'No se pudieron cargar los contactos: $error';
  }

  @override
  String chat_list_item_draft_line(Object line) {
    return 'Borrador · $line';
  }

  @override
  String get chat_list_item_chat_created => 'Chat creado';

  @override
  String get chat_list_item_no_messages_yet => 'Aún no hay mensajes';

  @override
  String get chat_list_item_history_cleared => 'Historial borrado';

  @override
  String get chat_list_firebase_not_configured =>
      'Firebase aún no está configurado.';

  @override
  String get new_chat_title => 'Nuevo chat';

  @override
  String get new_chat_subtitle =>
      'Elige a alguien para iniciar una conversación o crea un grupo.';

  @override
  String get new_chat_search_hint => 'Nombre, usuario o @identificador…';

  @override
  String get new_chat_create_group => 'Crear un grupo';

  @override
  String get new_chat_section_phone_contacts => 'CONTACTOS DEL TELÉFONO';

  @override
  String get new_chat_section_contacts => 'CONTACTOS';

  @override
  String get new_chat_section_all_users => 'TODOS LOS USUARIOS';

  @override
  String get new_chat_empty_no_users => 'Aún no hay nadie con quien chatear.';

  @override
  String get new_chat_empty_not_found => 'No se encontraron coincidencias.';

  @override
  String new_chat_error_contacts(Object error) {
    return 'Contactos: $error';
  }

  @override
  String get new_chat_fallback_user_display_name => 'Usuario';

  @override
  String get new_group_role_badge_admin => 'ADMINISTRACIÓN';

  @override
  String get new_group_role_badge_worker => 'MIEMBRO';

  @override
  String new_group_error_auth_session(Object error) {
    return 'No se pudo verificar el inicio de sesión: $error';
  }

  @override
  String get invite_subject => 'Únete a mí en LighChat';

  @override
  String get invite_text =>
      'Instala LighChat: https://lighchat.online\\nTe invito a LighChat — aquí está el enlace de instalación.';

  @override
  String get new_group_title => 'Crear un grupo';

  @override
  String get new_group_search_hint => 'Buscar usuarios…';

  @override
  String get new_group_pick_photo_tooltip =>
      'Toca para elegir una foto de grupo. Mantén presionado para eliminarla.';

  @override
  String get new_group_name_label => 'Nombre del grupo';

  @override
  String get new_group_name_hint => 'Nombre';

  @override
  String get new_group_description_label => 'Descripción';

  @override
  String get new_group_description_hint => 'Opcional';

  @override
  String new_group_members_count(Object count) {
    return 'Miembros ($count)';
  }

  @override
  String get new_group_add_members_section => 'AGREGAR MIEMBROS';

  @override
  String get new_group_empty_no_users => 'Aún no hay nadie para agregar.';

  @override
  String get new_group_empty_not_found => 'No se encontraron coincidencias.';

  @override
  String get new_group_error_name_required =>
      'Por favor, ingresa un nombre de grupo.';

  @override
  String get new_group_error_members_required => 'Agrega al menos un miembro.';

  @override
  String get new_group_action_create => 'Crear';

  @override
  String get group_members_title => 'Miembros';

  @override
  String get group_members_invite_link => 'Invitar por enlace';

  @override
  String get group_members_admin_badge => 'ADMINISTRACIÓN';

  @override
  String group_members_invite_text(Object groupName, Object inviteLink) {
    return 'Únete al grupo $groupName en LighChat: $inviteLink';
  }

  @override
  String get group_members_error_min_admin =>
      'Al menos un administrador debe permanecer en el grupo.';

  @override
  String get group_members_error_cannot_remove_creator =>
      'No puedes quitar los derechos de administrador al creador del grupo.';

  @override
  String get group_members_remove_admin =>
      'Derechos de administrador eliminados';

  @override
  String get group_members_make_admin => 'Usuario promovido a administrador';

  @override
  String get auth_brand_tagline => 'Un mensajero más seguro';

  @override
  String get auth_firebase_not_ready =>
      'Firebase no está listo. Verifica `firebase_options.dart` y GoogleService-Info.plist.';

  @override
  String get auth_redirecting_to_chats => 'Llevándote a los chats…';

  @override
  String get auth_or => 'o';

  @override
  String get auth_create_account => 'Crear cuenta';

  @override
  String get auth_entry_sign_in => 'Iniciar sesión';

  @override
  String get auth_entry_sign_up => 'Crear cuenta';

  @override
  String get auth_qr_title => 'Iniciar sesión con QR';

  @override
  String get auth_qr_hint =>
      'Abre LighChat en un dispositivo donde ya hayas iniciado sesión → Configuración → Dispositivos → Conectar nuevo dispositivo, luego escanea este código.';

  @override
  String auth_qr_refresh_in(int seconds) {
    return 'Se actualiza en ${seconds}s';
  }

  @override
  String get auth_qr_other_method => 'Iniciar sesión de otra forma';

  @override
  String get auth_qr_approving => 'Iniciando sesión…';

  @override
  String get auth_qr_rejected => 'Solicitud rechazada';

  @override
  String get auth_qr_retry => 'Reintentar';

  @override
  String get auth_qr_unknown_error => 'No se pudo generar el código QR.';

  @override
  String get auth_qr_use_qr_login => 'Iniciar sesión con QR';

  @override
  String get auth_privacy_policy => 'Política de privacidad';

  @override
  String get auth_error_open_privacy_policy =>
      'No se pudo abrir la política de privacidad';

  @override
  String get voice_transcript_show => 'Mostrar texto';

  @override
  String get voice_transcript_hide => 'Ocultar texto';

  @override
  String get voice_transcript_copy => 'Copiar';

  @override
  String get voice_transcript_retry => 'Reintentar transcripción';

  @override
  String get voice_transcript_summary_show => 'Mostrar resumen';

  @override
  String get voice_transcript_summary_hide => 'Mostrar texto completo';

  @override
  String voice_transcript_stats(int words, int wpm) {
    return '$words palabras · $wpm ppm';
  }

  @override
  String get voice_attachment_skip_silence => 'Saltar silencios';

  @override
  String get voice_karaoke_title => 'Karaoke';

  @override
  String get voice_karaoke_prompt_title => 'Modo karaoke';

  @override
  String get voice_karaoke_prompt_body =>
      '¿Abrir el mensaje de voz en pantalla completa con letras?';

  @override
  String get voice_karaoke_prompt_open => 'Abrir';

  @override
  String get voice_transcript_loading => 'Transcribiendo…';

  @override
  String get voice_transcript_failed => 'No se pudo obtener el texto.';

  @override
  String get voice_attachment_media_kind_audio => 'audio';

  @override
  String get voice_attachment_load_failed => 'No se pudo cargar';

  @override
  String get voice_attachment_title_voice_message => 'Mensaje de voz';

  @override
  String voice_transcript_error(Object error) {
    return 'No se pudo transcribir: $error';
  }

  @override
  String get voice_transcript_permission_denied =>
      'El reconocimiento de voz no está permitido. Actívalo en los ajustes del sistema.';

  @override
  String get voice_transcript_unsupported_lang =>
      'Este idioma no es compatible con la transcripción en el dispositivo.';

  @override
  String get voice_transcript_no_model =>
      'Instala un paquete de reconocimiento de voz sin conexión en los ajustes del sistema.';

  @override
  String get ai_action_summarize => 'Resumir';

  @override
  String get ai_action_rewrite => 'Reescribir con IA';

  @override
  String get ai_action_apply => 'Aplicar';

  @override
  String get ai_action_thinking => 'Escribiendo…';

  @override
  String get ai_action_failed =>
      'No se pudo procesar este texto. Es posible que el idioma aún no esté soportado por la IA en el dispositivo.';

  @override
  String get ai_status_model_not_ready =>
      'La modelo de Apple Intelligence aún se descarga. Inténtalo en un minuto.';

  @override
  String get ai_status_not_enabled =>
      'Apple Intelligence no está activado en Ajustes.';

  @override
  String get ai_status_device_not_eligible =>
      'Este dispositivo no admite Apple Intelligence.';

  @override
  String get ai_status_unsupported_os =>
      'Apple Intelligence requiere iOS 26 o más reciente.';

  @override
  String get ai_status_unknown =>
      'Apple Intelligence no está disponible ahora.';

  @override
  String get navigator_picker_title => 'Abrir en';

  @override
  String get calendar_picker_title => 'Agregar al calendario';

  @override
  String get calendar_picker_native_subtitle =>
      'Calendario del sistema con todas tus cuentas';

  @override
  String get calendar_picker_web_subtitle =>
      'Abre la app si está instalada, si no — el navegador';

  @override
  String get ai_style_friendly => 'Más amigable';

  @override
  String get ai_style_formal => 'Formal';

  @override
  String get ai_style_shorter => 'Más corto';

  @override
  String get ai_style_longer => 'Más largo';

  @override
  String get ai_style_proofread => 'Corregir';

  @override
  String get ai_style_youth => 'Juvenil';

  @override
  String get ai_style_strict => 'Estricto';

  @override
  String get ai_style_blatnoy => 'Callejero';

  @override
  String get ai_style_funny => 'Chistoso';

  @override
  String get ai_style_romantic => 'Romántico';

  @override
  String get ai_style_sarcastic => 'Sarcástico';

  @override
  String get ai_rewrite_picker_title => 'Estilo de reescritura';

  @override
  String get voice_translate_action => 'Traducir';

  @override
  String get voice_translate_show_original => 'Original';

  @override
  String get voice_translate_in_progress => 'Traduciendo…';

  @override
  String get voice_translate_downloading_model => 'Descargando modelo…';

  @override
  String get voice_translate_unsupported =>
      'La traducción no está disponible para este par de idiomas.';

  @override
  String voice_translate_failed(Object error) {
    return 'No se pudo traducir: $error';
  }

  @override
  String get chat_messages_title => 'Mensajes';

  @override
  String get chat_call_decline => 'Rechazar';

  @override
  String get chat_call_open => 'Abrir';

  @override
  String get chat_call_accept => 'Aceptar';

  @override
  String video_call_error_init(Object error) {
    return 'Error de videollamada: $error';
  }

  @override
  String get video_call_ended => 'Llamada finalizada';

  @override
  String get video_call_status_missed => 'Llamada perdida';

  @override
  String get video_call_status_cancelled => 'Llamada cancelada';

  @override
  String get video_call_error_offer_not_ready =>
      'La oferta aún no está lista. Intenta de nuevo.';

  @override
  String get video_call_error_invalid_call_data =>
      'Datos de llamada no válidos';

  @override
  String video_call_error_accept_failed(Object error) {
    return 'No se pudo aceptar la llamada: $error';
  }

  @override
  String get video_call_incoming => 'Videollamada entrante';

  @override
  String get video_call_connecting => 'Videollamada…';

  @override
  String get video_call_pip_tooltip => 'Imagen en imagen';

  @override
  String get video_call_mini_window_tooltip => 'Mini ventana';

  @override
  String get chat_delete_message_title_single => '¿Eliminar mensaje?';

  @override
  String get chat_delete_message_title_multi => '¿Eliminar mensajes?';

  @override
  String get chat_delete_message_body_single =>
      'Este mensaje se ocultará para todos.';

  @override
  String chat_delete_message_body_multi(Object count) {
    return 'Mensajes a eliminar: $count';
  }

  @override
  String get chat_delete_file_title => '¿Eliminar archivo?';

  @override
  String get chat_delete_file_body =>
      'Solo este archivo se eliminará del mensaje.';

  @override
  String get forward_title => 'Reenviar';

  @override
  String get forward_empty_no_messages => 'No hay mensajes para reenviar';

  @override
  String get forward_error_not_authorized => 'No ha iniciado sesión';

  @override
  String get forward_empty_no_recipients =>
      'No hay contactos o chats a los que reenviar';

  @override
  String get forward_search_hint => 'Buscar contactos…';

  @override
  String get forward_empty_no_available_recipients =>
      'No hay destinatarios disponibles.\nSolo puedes reenviar a contactos y tus chats activos.';

  @override
  String get forward_empty_not_found => 'No se encontró nada';

  @override
  String get forward_action_pick_recipients => 'Elegir destinatarios';

  @override
  String get forward_action_send => 'Enviar';

  @override
  String forward_error_generic(Object error) {
    return 'Error: $error';
  }

  @override
  String get forward_sender_fallback => 'Participante';

  @override
  String get forward_error_profiles_load =>
      'No se pudieron cargar los perfiles para abrir el chat';

  @override
  String get forward_error_send_no_permissions =>
      'No se pudo reenviar: no tienes acceso a uno de los chats seleccionados o el chat ya no está disponible.';

  @override
  String get forward_error_send_forbidden_chat =>
      'No se pudo reenviar: acceso denegado a uno de los chats.';

  @override
  String get share_picker_title => 'Compartir con LighChat';

  @override
  String get share_picker_empty_payload => 'Nada que compartir';

  @override
  String get share_picker_summary_text_only => 'Texto';

  @override
  String share_picker_summary_files_count(int count) {
    return 'Archivos: $count';
  }

  @override
  String share_picker_summary_files_with_text(int count) {
    return 'Archivos: $count + texto';
  }

  @override
  String get devices_title => 'Mis dispositivos';

  @override
  String get devices_subtitle =>
      'Dispositivos donde se publica tu clave pública de cifrado. Revocar crea una nueva época de clave para todos los chats cifrados — el dispositivo revocado no podrá leer nuevos mensajes.';

  @override
  String get devices_empty => 'Aún no hay dispositivos.';

  @override
  String get devices_connect_new_device => 'Conectar nuevo dispositivo';

  @override
  String get devices_approve_title =>
      '¿Permitir que este dispositivo inicie sesión?';

  @override
  String get devices_approve_body_hint =>
      'Asegúrate de que este es tu propio dispositivo que acaba de mostrar el código QR.';

  @override
  String get devices_approve_allow => 'Permitir';

  @override
  String get devices_approve_deny => 'Denegar';

  @override
  String get devices_handover_progress_title => 'Sincronizando chats cifrados…';

  @override
  String devices_handover_progress_body(int done, int total) {
    return 'Actualizados $done de $total';
  }

  @override
  String get devices_handover_progress_starting => 'Iniciando…';

  @override
  String get devices_handover_success_title => 'Nuevo dispositivo vinculado';

  @override
  String devices_handover_success_body(String label) {
    return 'El dispositivo $label ahora tiene acceso a tus chats cifrados.';
  }

  @override
  String devices_progress_rekeying(Object done, Object total) {
    return 'Actualizando chats: $done / $total';
  }

  @override
  String get devices_chip_current => 'Este dispositivo';

  @override
  String get devices_chip_revoked => 'Revocado';

  @override
  String devices_meta_created_activity(Object createdAt, Object lastSeenAt) {
    return 'Creado: $createdAt  •  Actividad: $lastSeenAt';
  }

  @override
  String devices_meta_revoked_at(Object revokedAt) {
    return 'Revocado: $revokedAt';
  }

  @override
  String get devices_action_rename => 'Renombrar';

  @override
  String get devices_action_revoke => 'Revocar';

  @override
  String get devices_dialog_rename_title => 'Renombrar dispositivo';

  @override
  String get devices_dialog_rename_hint => 'ej. iPhone 15 — Safari';

  @override
  String devices_error_rename_failed(Object error) {
    return 'No se pudo renombrar: $error';
  }

  @override
  String get devices_dialog_revoke_title => '¿Revocar dispositivo?';

  @override
  String get devices_dialog_revoke_body_current =>
      'Estás a punto de revocar ESTE dispositivo. Después de eso, no podrás leer nuevos mensajes en chats cifrados de extremo a extremo desde este cliente.';

  @override
  String get devices_dialog_revoke_body_other =>
      'Este dispositivo no podrá leer nuevos mensajes en chats cifrados de extremo a extremo. Los mensajes antiguos seguirán disponibles.';

  @override
  String devices_snackbar_revoked(Object rekeyed, Object suffix) {
    return 'Dispositivo revocado. Chats actualizados: $rekeyed$suffix';
  }

  @override
  String devices_snackbar_failed_suffix(Object count) {
    return ', errores: $count';
  }

  @override
  String devices_error_revoke_failed(Object error) {
    return 'Error al revocar: $error';
  }

  @override
  String get e2ee_recovery_title => 'E2EE — respaldo';

  @override
  String get e2ee_password_label => 'Contraseña';

  @override
  String get e2ee_password_confirm_label => 'Confirmar contraseña';

  @override
  String e2ee_password_min_length(Object count) {
    return 'Al menos $count caracteres';
  }

  @override
  String get e2ee_password_mismatch => 'Las contraseñas no coinciden';

  @override
  String get e2ee_backup_create_title => 'Crear respaldo de clave';

  @override
  String get e2ee_backup_restore_title => 'Restaurar con contraseña';

  @override
  String get e2ee_backup_restore_action => 'Restaurar';

  @override
  String e2ee_backup_create_error(Object error) {
    return 'No se pudo crear el respaldo: $error';
  }

  @override
  String e2ee_backup_restore_error(Object error) {
    return 'No se pudo restaurar: $error';
  }

  @override
  String get e2ee_backup_wrong_password => 'Contraseña incorrecta';

  @override
  String get e2ee_backup_not_found => 'Respaldo no encontrado';

  @override
  String e2ee_recovery_error_generic(Object error) {
    return 'Error: $error';
  }

  @override
  String get e2ee_backup_password_card_title => 'Respaldo con contraseña';

  @override
  String get e2ee_backup_password_card_description =>
      'Crea un respaldo cifrado de tu clave privada. Si pierdes todos tus dispositivos, puedes restaurarla en uno nuevo usando solo la contraseña. La contraseña no se puede recuperar — guárdala de forma segura.';

  @override
  String get e2ee_backup_overwrite => 'Sobrescribir respaldo';

  @override
  String get e2ee_backup_create => 'Crear respaldo';

  @override
  String get e2ee_backup_restore => 'Restaurar desde respaldo';

  @override
  String get e2ee_backup_already_have => 'Ya tengo un respaldo';

  @override
  String get e2ee_qr_transfer_title => 'Transferir clave por QR';

  @override
  String get e2ee_qr_transfer_description =>
      'En el nuevo dispositivo muestras un QR, en el anterior lo escaneas. Verifica un código de 6 dígitos — la clave privada se transfiere de forma segura.';

  @override
  String get e2ee_qr_transfer_open => 'Abrir emparejamiento QR';

  @override
  String get media_viewer_action_reply => 'Responder';

  @override
  String get media_viewer_action_forward => 'Reenviar';

  @override
  String get media_viewer_action_send => 'Enviar';

  @override
  String get media_viewer_action_save => 'Guardar';

  @override
  String get media_viewer_action_live_text => 'Live Text';

  @override
  String get media_viewer_action_subject_lift => 'Aislar objeto';

  @override
  String get media_viewer_action_subject_send => 'Enviar a este chat';

  @override
  String get media_viewer_action_subject_save => 'Guardar en Fotos';

  @override
  String get media_viewer_action_subject_share => 'Compartir';

  @override
  String get media_viewer_subject_saved => 'Guardado en Fotos';

  @override
  String get media_viewer_action_show_in_chat => 'Mostrar en el chat';

  @override
  String get media_viewer_action_delete => 'Eliminar';

  @override
  String get media_viewer_error_no_gallery_access =>
      'Sin permiso para guardar en la galería';

  @override
  String get media_viewer_error_share_unavailable_web =>
      'Compartir no está disponible en web';

  @override
  String get media_viewer_error_file_not_found => 'Archivo no encontrado';

  @override
  String get media_viewer_error_bad_media_url => 'URL de multimedia incorrecta';

  @override
  String get media_viewer_error_bad_url => 'URL incorrecta';

  @override
  String get media_viewer_error_unsupported_media_scheme =>
      'Tipo de multimedia no soportado';

  @override
  String media_viewer_error_http_status(Object status) {
    return 'Error del servidor (HTTP $status)';
  }

  @override
  String media_viewer_error_save_failed(Object error) {
    return 'No se pudo guardar: $error';
  }

  @override
  String media_viewer_error_send_failed(Object error) {
    return 'No se pudo enviar: $error';
  }

  @override
  String get media_viewer_video_playback_speed => 'Velocidad de reproducción';

  @override
  String get media_viewer_video_quality => 'Calidad';

  @override
  String get media_viewer_video_quality_auto => 'Automática';

  @override
  String get media_viewer_error_quality_switch_failed =>
      'No se pudo cambiar la calidad';

  @override
  String get media_viewer_error_pip_open_failed => 'No se pudo abrir PiP';

  @override
  String get media_viewer_pip_not_supported =>
      'Imagen en imagen no es compatible con este dispositivo.';

  @override
  String get media_viewer_video_processing =>
      'Este video se está procesando en el servidor y estará disponible pronto.';

  @override
  String get media_viewer_video_playback_failed =>
      'No se pudo reproducir el video.';

  @override
  String get common_none => 'Ninguno';

  @override
  String get group_member_role_admin => 'Administrador';

  @override
  String get group_member_role_worker => 'Miembro';

  @override
  String get profile_no_photo_to_view => 'No hay foto de perfil para ver.';

  @override
  String get profile_chat_id_copied_toast => 'ID del chat copiado';

  @override
  String get auth_register_error_open_link => 'No se pudo abrir el enlace.';

  @override
  String get new_chat_error_self_profile_not_found =>
      'Tu perfil no se encontró en el directorio. Intenta cerrar sesión e iniciar de nuevo.';

  @override
  String get disappearing_messages_title => 'Mensajes que desaparecen';

  @override
  String get disappearing_messages_intro =>
      'Los nuevos mensajes se eliminan automáticamente del servidor después del tiempo seleccionado (desde el momento en que se envían). Los mensajes ya enviados no se modifican.';

  @override
  String disappearing_messages_admin_only(Object summary) {
    return 'Solo los administradores del grupo pueden cambiar esto. Actual: $summary.';
  }

  @override
  String get disappearing_messages_snackbar_off =>
      'Mensajes que desaparecen desactivados.';

  @override
  String get disappearing_messages_snackbar_updated =>
      'Temporizador actualizado.';

  @override
  String get disappearing_preset_off => 'Desactivado';

  @override
  String get disappearing_preset_1h => '1 hora';

  @override
  String get disappearing_preset_24h => '24 horas';

  @override
  String get disappearing_preset_7d => '7 días';

  @override
  String get disappearing_preset_30d => '30 días';

  @override
  String get disappearing_ttl_summary_off => 'Desactivado';

  @override
  String disappearing_ttl_minutes(Object count) {
    return '$count min';
  }

  @override
  String disappearing_ttl_hours(Object count) {
    return '$count h';
  }

  @override
  String disappearing_ttl_days(Object count) {
    return '$count días';
  }

  @override
  String disappearing_ttl_weeks(Object count) {
    return '$count sem';
  }

  @override
  String get conversation_profile_e2ee_on => 'Activado';

  @override
  String get conversation_profile_e2ee_off => 'Desactivado';

  @override
  String get conversation_profile_e2ee_subtitle_on =>
      'El cifrado de extremo a extremo está activado. Toca para más detalles.';

  @override
  String get conversation_profile_e2ee_subtitle_off =>
      'El cifrado de extremo a extremo está desactivado. Toca para activar.';

  @override
  String get partner_profile_title_fallback_group => 'Chat grupal';

  @override
  String get partner_profile_title_fallback_saved => 'Mensajes guardados';

  @override
  String get partner_profile_title_fallback_chat => 'Charlar';

  @override
  String partner_profile_subtitle_group_member_count(Object count) {
    return '$count miembros';
  }

  @override
  String get partner_profile_subtitle_saved_messages =>
      'Mensajes y notas solo para ti';

  @override
  String get partner_profile_error_cannot_contact_user =>
      'No puedes contactar a este usuario con la configuración de contacto actual.';

  @override
  String partner_profile_error_open_chat(Object error) {
    return 'No se pudo abrir el chat: $error';
  }

  @override
  String get partner_profile_call_peer_fallback => 'Contacto';

  @override
  String get partner_profile_chat_not_created => 'El chat aún no se ha creado';

  @override
  String get partner_profile_notifications_muted =>
      'Notificaciones silenciadas';

  @override
  String get partner_profile_notifications_unmuted =>
      'Notificaciones activadas';

  @override
  String get partner_profile_notifications_change_failed =>
      'No se pudieron actualizar las notificaciones';

  @override
  String get partner_profile_removed_from_contacts => 'Eliminado de contactos';

  @override
  String get partner_profile_remove_contact_failed =>
      'No se pudo eliminar de contactos';

  @override
  String get partner_profile_contact_sent => 'Contacto enviado';

  @override
  String get partner_profile_share_failed_copied =>
      'Error al compartir. Texto del contacto copiado.';

  @override
  String get partner_profile_share_contact_header => 'Contacto en LighChat';

  @override
  String partner_profile_share_avatar_line(Object url) {
    return 'Avatar: $url';
  }

  @override
  String partner_profile_share_profile_line(Object url) {
    return 'Perfil: $url';
  }

  @override
  String partner_profile_share_contact_subject(Object name) {
    return 'Contacto de LighChat: $name';
  }

  @override
  String get partner_profile_tooltip_back => 'Atrás';

  @override
  String get partner_profile_tooltip_close => 'Cerrar';

  @override
  String get partner_profile_edit_contact_short => 'Editar';

  @override
  String get partner_profile_tooltip_copy_chat_id => 'Copiar ID del chat';

  @override
  String get partner_profile_action_chats => 'Charlas';

  @override
  String get partner_profile_action_voice_call => 'Llamar';

  @override
  String get partner_profile_action_video => 'Video';

  @override
  String get partner_profile_action_share => 'Compartir';

  @override
  String get partner_profile_action_notifications => 'Alertas';

  @override
  String get partner_profile_menu_members => 'Miembros';

  @override
  String get partner_profile_menu_edit_group => 'Editar grupo';

  @override
  String get partner_profile_menu_media_links_files =>
      'Multimedia, enlaces y archivos';

  @override
  String get partner_profile_menu_starred => 'Destacados';

  @override
  String get partner_profile_menu_threads => 'Hilos';

  @override
  String get partner_profile_menu_games => 'Juegos';

  @override
  String get partner_profile_menu_block => 'Bloquear';

  @override
  String get partner_profile_menu_unblock => 'Desbloquear';

  @override
  String get partner_profile_menu_notifications => 'Notificaciones';

  @override
  String get partner_profile_menu_chat_theme => 'Tema del chat';

  @override
  String get partner_profile_menu_advanced_privacy =>
      'Privacidad avanzada del chat';

  @override
  String get partner_profile_privacy_trailing_default => 'Predeterminado';

  @override
  String get partner_profile_menu_encryption => 'Cifrado';

  @override
  String get partner_profile_no_common_groups => 'SIN GRUPOS EN COMÚN';

  @override
  String partner_profile_create_group_with(Object name) {
    return 'Crear un grupo con $name';
  }

  @override
  String get partner_profile_leave_group => 'Salir del grupo';

  @override
  String get partner_profile_contacts_and_data => 'Información de contacto';

  @override
  String get partner_profile_field_system_role => 'Rol del sistema';

  @override
  String get partner_profile_field_email => 'Correo electrónico';

  @override
  String get partner_profile_field_phone => 'Teléfono';

  @override
  String get partner_profile_field_birthday => 'Cumpleaños';

  @override
  String get partner_profile_field_bio => 'Acerca de';

  @override
  String get partner_profile_add_to_contacts => 'Agregar a contactos';

  @override
  String get partner_profile_remove_from_contacts => 'Eliminar de contactos';

  @override
  String get thread_search_hint => 'Buscar en el hilo…';

  @override
  String get thread_search_tooltip_clear => 'Borrar';

  @override
  String get thread_search_tooltip_search => 'Buscar';

  @override
  String thread_reply_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count respuestas',
      one: '$count respuesta',
      zero: '$count respuestas',
    );
    return '$_temp0';
  }

  @override
  String get thread_message_not_found => 'Mensaje no encontrado';

  @override
  String get thread_screen_title_fallback => 'Hilo';

  @override
  String thread_load_replies_error(Object error) {
    return 'Error del hilo: $error';
  }

  @override
  String get chat_message_empty_placeholder => 'Mensaje';

  @override
  String get chat_sender_you => 'Tú';

  @override
  String get chat_clipboard_nothing_to_paste =>
      'Nada que pegar del portapapeles';

  @override
  String chat_clipboard_paste_failed(Object error) {
    return 'No se pudo pegar del portapapeles: $error';
  }

  @override
  String chat_send_failed(Object error) {
    return 'No se pudo enviar: $error';
  }

  @override
  String chat_send_video_circle_failed(Object error) {
    return 'No se pudo enviar la nota de video: $error';
  }

  @override
  String get chat_service_unavailable => 'Servicio no disponible';

  @override
  String get chat_repository_unavailable => 'Servicio de chat no disponible';

  @override
  String get chat_still_loading => 'El chat aún se está cargando';

  @override
  String get chat_no_participants => 'Sin participantes en el chat';

  @override
  String get chat_location_ios_geolocator_missing =>
      'La ubicación no está vinculada en esta compilación de iOS. Ejecuta pod install en mobile/app/ios y recompila.';

  @override
  String get chat_location_services_disabled =>
      'Activa los servicios de ubicación';

  @override
  String get chat_location_permission_denied =>
      'Sin permiso para usar la ubicación';

  @override
  String chat_location_send_failed(Object error) {
    return 'No se pudo enviar la ubicación: $error';
  }

  @override
  String get chat_poll_send_timeout =>
      'La encuesta no se envió: tiempo agotado';

  @override
  String chat_poll_send_firebase(Object details) {
    return 'La encuesta no se envió (Firestore): $details';
  }

  @override
  String chat_poll_send_known_error(Object details) {
    return 'La encuesta no se envió: $details';
  }

  @override
  String chat_poll_send_failed(Object error) {
    return 'No se pudo enviar la encuesta: $error';
  }

  @override
  String chat_delete_action_failed(Object error) {
    return 'No se pudo eliminar: $error';
  }

  @override
  String get chat_media_transcode_retry_started =>
      'Reintento de transcodificación iniciado';

  @override
  String chat_media_transcode_retry_failed(Object error) {
    return 'No se pudo iniciar el reintento de transcodificación: $error';
  }

  @override
  String chat_parent_load_error(Object error) {
    return 'Error: $error';
  }

  @override
  String get chat_message_not_found_in_loaded_history =>
      'El mensaje no se encontró en el historial cargado';

  @override
  String get chat_finish_editing_first => 'Termina de editar primero';

  @override
  String chat_send_voice_failed(Object error) {
    return 'No se pudo enviar el mensaje de voz: $error';
  }

  @override
  String get chat_starred_removed => 'Eliminado de Destacados';

  @override
  String get chat_starred_added => 'Agregado a Destacados';

  @override
  String chat_starred_toggle_failed(Object error) {
    return 'No se pudo actualizar Destacados: $error';
  }

  @override
  String chat_reaction_toggle_failed(Object error) {
    return 'No se pudo agregar la reacción: $error';
  }

  @override
  String chat_emoji_burst_sync_failed(Object error) {
    return 'No se pudo sincronizar el efecto de emoji: $error';
  }

  @override
  String get chat_pin_already_pinned => 'El mensaje ya está fijado';

  @override
  String chat_pin_limit_reached(int count) {
    return 'Límite de mensajes fijados ($count)';
  }

  @override
  String chat_pin_failed(Object error) {
    return 'No se pudo fijar: $error';
  }

  @override
  String chat_unpin_failed(Object error) {
    return 'No se pudo desfijar: $error';
  }

  @override
  String get chat_text_copied => 'Texto copiado';

  @override
  String get chat_edit_attachments_not_allowed =>
      'Los adjuntos no están disponibles mientras editas';

  @override
  String get chat_edit_text_empty => 'El texto no puede estar vacío';

  @override
  String chat_e2ee_unavailable(Object code) {
    return 'Cifrado no disponible: $code';
  }

  @override
  String chat_save_failed(Object error) {
    return 'No se pudo guardar: $error';
  }

  @override
  String chat_load_messages_error(Object error) {
    return 'No se pudieron cargar los mensajes: $error';
  }

  @override
  String chat_conversation_error(Object error) {
    return 'Error de conversación: $error';
  }

  @override
  String chat_auth_error(Object error) {
    return 'Error de autenticación: $error';
  }

  @override
  String get chat_poll_label => 'Encuesta';

  @override
  String get chat_location_label => 'Ubicación';

  @override
  String get chat_attachment_label => 'Adjunto';

  @override
  String chat_media_pick_failed(Object error) {
    return 'No se pudo seleccionar multimedia: $error';
  }

  @override
  String chat_file_pick_failed(Object error) {
    return 'No se pudo seleccionar archivo: $error';
  }

  @override
  String get chat_call_ongoing_video => 'Videollamada en progreso';

  @override
  String get chat_call_ongoing_audio => 'Llamada de audio en progreso';

  @override
  String get chat_call_incoming_video => 'Videollamada entrante';

  @override
  String get chat_call_incoming_audio => 'Llamada de audio entrante';

  @override
  String get message_menu_action_reply => 'Responder';

  @override
  String get message_menu_action_thread => 'Hilo';

  @override
  String get message_menu_action_copy => 'Copiar';

  @override
  String get message_menu_action_translate => 'Traducir';

  @override
  String get message_menu_action_show_original => 'Mostrar original';

  @override
  String get message_menu_action_read_aloud => 'Leer en voz alta';

  @override
  String get tts_quality_hint =>
      '¿Voz robótica? Instala voces Enhanced en Ajustes → Accesibilidad → Contenido leído → Voces.';

  @override
  String get tts_quality_hint_cta => 'Ajustes';

  @override
  String get message_menu_action_edit => 'Editar';

  @override
  String get message_menu_action_pin => 'Fijar';

  @override
  String get message_menu_action_star_add => 'Agregar a Destacados';

  @override
  String get message_menu_action_star_remove => 'Eliminar de Destacados';

  @override
  String get message_menu_action_create_sticker => 'Crear sticker';

  @override
  String get message_menu_action_save_to_my_stickers =>
      'Guardar en mis stickers';

  @override
  String get message_menu_action_forward => 'Reenviar';

  @override
  String get message_menu_action_select => 'Seleccionar';

  @override
  String get message_menu_action_delete => 'Eliminar';

  @override
  String get message_menu_initiator_deleted => 'Mensaje eliminado';

  @override
  String get message_menu_header_sent => 'ENVIADO:';

  @override
  String get message_menu_header_read => 'LEÍDO:';

  @override
  String get message_menu_header_expire_at => 'DESAPARECE:';

  @override
  String get chat_header_search_hint => 'Buscar mensajes…';

  @override
  String get chat_header_tooltip_threads => 'Hilos';

  @override
  String get chat_header_tooltip_search => 'Buscar';

  @override
  String get chat_header_tooltip_video_call => 'Videollamada';

  @override
  String get chat_header_tooltip_audio_call => 'Llamada de audio';

  @override
  String get conversation_games_title => 'Juegos';

  @override
  String get conversation_games_durak => 'Durak';

  @override
  String get conversation_games_durak_subtitle => 'Crear sala';

  @override
  String get conversation_game_lobby_title => 'Sala';

  @override
  String get conversation_game_lobby_not_found => 'Juego no encontrado';

  @override
  String conversation_game_lobby_error(Object error) {
    return 'Error: $error';
  }

  @override
  String conversation_game_lobby_create_failed(Object error) {
    return 'No se pudo crear el juego: $error';
  }

  @override
  String conversation_game_lobby_game_id(Object id) {
    return 'ID: $id';
  }

  @override
  String conversation_game_lobby_status(Object status) {
    return 'Estado: $status';
  }

  @override
  String conversation_game_lobby_players(Object count, Object max) {
    return 'Jugadores: $count/$max';
  }

  @override
  String get conversation_game_lobby_join => 'Unirse';

  @override
  String get conversation_game_lobby_start => 'Iniciar';

  @override
  String conversation_game_lobby_join_failed(Object error) {
    return 'No se pudo unir: $error';
  }

  @override
  String conversation_game_lobby_start_failed(Object error) {
    return 'No se pudo iniciar el juego: $error';
  }

  @override
  String get conversation_game_send_test_move => 'Movimiento de prueba';

  @override
  String conversation_game_move_failed(Object error) {
    return 'Movimiento rechazado: $error';
  }

  @override
  String get conversation_durak_table_title => 'Mesa';

  @override
  String get conversation_durak_hand_title => 'Mano';

  @override
  String get conversation_durak_role_attacker => 'Atacando';

  @override
  String get conversation_durak_role_defender => 'Defendiendo';

  @override
  String get conversation_durak_role_thrower => 'Lanzando';

  @override
  String get conversation_durak_action_attack => 'Atacar';

  @override
  String get conversation_durak_action_defend => 'Defender';

  @override
  String get conversation_durak_action_take => 'Tomar';

  @override
  String get conversation_durak_action_beat => 'Ganar';

  @override
  String get conversation_durak_action_transfer => 'Transferir';

  @override
  String get conversation_durak_action_pass => 'Pasar';

  @override
  String get conversation_durak_badge_taking => 'Tomo';

  @override
  String get conversation_durak_game_finished_title => 'Juego terminado';

  @override
  String get conversation_durak_game_finished_no_loser =>
      'No hay perdedor esta vez.';

  @override
  String conversation_durak_game_finished_loser(Object uid) {
    return 'Perdedor: $uid';
  }

  @override
  String conversation_durak_game_finished_winners(Object uids) {
    return 'Ganadores: $uids';
  }

  @override
  String get conversation_durak_winner => '¡Ganador!';

  @override
  String get conversation_durak_play_again => 'Jugar de nuevo';

  @override
  String get conversation_durak_back_to_chat => 'Volver al chat';

  @override
  String get conversation_game_lobby_waiting_opponent =>
      'Esperando al oponente…';

  @override
  String get conversation_durak_drop_zone => 'Suelta la carta aquí para jugar';

  @override
  String get durak_settings_mode => 'Modo';

  @override
  String get durak_mode_podkidnoy => 'Podkidnoy';

  @override
  String get durak_mode_perevodnoy => 'Perevodnoy';

  @override
  String get durak_settings_max_players => 'Jugadores';

  @override
  String get durak_settings_deck => 'Baraja';

  @override
  String get durak_deck_36 => '36 cartas';

  @override
  String get durak_deck_52 => '52 cartas';

  @override
  String get durak_settings_with_jokers => 'Comodines';

  @override
  String get durak_settings_turn_timer => 'Temporizador de turno';

  @override
  String get durak_turn_timer_off => 'Desactivado';

  @override
  String get durak_settings_throw_in_policy => 'Quién puede lanzar';

  @override
  String get durak_throw_in_policy_all =>
      'Todos los jugadores (excepto el defensor)';

  @override
  String get durak_throw_in_policy_neighbors => 'Solo los vecinos del defensor';

  @override
  String get durak_settings_shuler => 'Modo tramposo';

  @override
  String get durak_settings_shuler_subtitle =>
      'Permite movimientos ilegales a menos que alguien cante falta.';

  @override
  String get conversation_durak_action_foul => '¡Falta!';

  @override
  String get conversation_durak_action_resolve => 'Confirmar victoria';

  @override
  String get conversation_durak_foul_toast => '¡Falta! Tramposo penalizado.';

  @override
  String get durak_phase_prefix => 'Fase';

  @override
  String get durak_phase_attack => 'Atacar';

  @override
  String get durak_phase_defense => 'Defensa';

  @override
  String get durak_phase_throw_in => 'Lanzamiento';

  @override
  String get durak_phase_resolution => 'Resolución';

  @override
  String get durak_phase_finished => 'Terminado';

  @override
  String get durak_phase_pending_foul => 'Falta pendiente después de ganar';

  @override
  String get durak_phase_pending_foul_hint_attacker =>
      'Espera la falta. Si nadie la canta, confirma la victoria.';

  @override
  String get durak_phase_pending_foul_hint_other =>
      'Espera la falta. ¡Canta Falta! si viste trampa.';

  @override
  String get durak_phase_hint_can_throw_in => 'Puedes lanzar';

  @override
  String get durak_phase_hint_wait => 'Espera tu turno';

  @override
  String durak_now_throwing_in(Object name) {
    return 'Ahora lanza: $name';
  }

  @override
  String chat_selection_selected_count(int count) {
    return '$count seleccionados';
  }

  @override
  String get chat_selection_tooltip_forward => 'Reenviar';

  @override
  String get chat_selection_tooltip_delete => 'Eliminar';

  @override
  String get chat_composer_hint_message => 'Escribe un mensaje…';

  @override
  String get chat_composer_tooltip_stickers => 'Pegatinas';

  @override
  String get chat_composer_tooltip_attachments => 'Adjuntos';

  @override
  String get chat_list_unread_separator => 'Mensajes no leídos';

  @override
  String get chat_e2ee_decrypt_failed_open_devices =>
      'No se pudo descifrar. Abre Configuración → Dispositivos';

  @override
  String get chat_e2ee_encrypted_message_placeholder => 'Mensaje cifrado';

  @override
  String chat_forwarded_from(Object name) {
    return 'Reenviado de $name';
  }

  @override
  String get chat_outbox_retry => 'Reintentar';

  @override
  String get chat_outbox_remove => 'Eliminar';

  @override
  String get chat_outbox_cancel => 'Cancelar';

  @override
  String get chat_message_edited_badge_short => 'EDITADO';

  @override
  String get register_error_enter_name => 'Ingresa tu nombre.';

  @override
  String get register_error_enter_username => 'Ingresa un nombre de usuario.';

  @override
  String get register_error_enter_phone => 'Ingresa un número de teléfono.';

  @override
  String get register_error_invalid_phone =>
      'Ingresa un número de teléfono válido.';

  @override
  String get register_error_enter_email => 'Ingresa un correo electrónico.';

  @override
  String get register_error_enter_password => 'Ingresa una contraseña.';

  @override
  String get register_error_repeat_password => 'Repite la contraseña.';

  @override
  String get register_error_dob_format =>
      'Ingresa la fecha de nacimiento en formato dd.mm.aaaa';

  @override
  String get register_error_accept_privacy_policy =>
      'Por favor confirma que aceptas la política de privacidad';

  @override
  String get register_privacy_required =>
      'Es necesario aceptar la política de privacidad';

  @override
  String get register_label_name => 'Nombre';

  @override
  String get register_hint_name => 'Ingresa tu nombre';

  @override
  String get register_label_username => 'Nombre de usuario';

  @override
  String get register_hint_username => 'Ingresa un nombre de usuario';

  @override
  String get register_label_phone => 'Teléfono';

  @override
  String get register_hint_choose_country => 'Elige un país';

  @override
  String get register_label_email => 'Correo electrónico';

  @override
  String get register_hint_email => 'Ingresa tu correo electrónico';

  @override
  String get register_label_password => 'Contraseña';

  @override
  String get register_hint_password => 'Ingresa tu contraseña';

  @override
  String get register_label_confirm_password => 'Confirmar contraseña';

  @override
  String get register_hint_confirm_password => 'Repite tu contraseña';

  @override
  String get register_label_dob => 'Fecha de nacimiento';

  @override
  String get register_hint_dob => 'dd.mm.aaaa';

  @override
  String get register_label_bio => 'Acerca de';

  @override
  String get register_hint_bio => 'Cuéntanos sobre ti…';

  @override
  String get register_privacy_prefix => 'Acepto ';

  @override
  String get register_privacy_link_text =>
      'Consentimiento para el tratamiento de datos personales';

  @override
  String get register_privacy_and => ' y ';

  @override
  String get register_terms_link_text =>
      'Acuerdo de usuario y política de privacidad';

  @override
  String get register_button_create_account => 'Crear cuenta';

  @override
  String get register_country_search_hint => 'Buscar por país o código';

  @override
  String get register_date_picker_help => 'Fecha de nacimiento';

  @override
  String get register_date_picker_cancel => 'Cancelar';

  @override
  String get register_date_picker_confirm => 'Seleccionar';

  @override
  String get register_pick_avatar_title => 'Elegir avatar';

  @override
  String get edit_group_title => 'Editar grupo';

  @override
  String get edit_group_save => 'Guardar';

  @override
  String get edit_group_cancel => 'Cancelar';

  @override
  String get edit_group_name_label => 'Nombre del grupo';

  @override
  String get edit_group_name_hint => 'Nombre';

  @override
  String get edit_group_description_label => 'Descripción';

  @override
  String get edit_group_description_hint => 'Opcional';

  @override
  String get edit_group_pick_photo_tooltip =>
      'Toca para elegir una foto de grupo. Mantén presionado para eliminarla.';

  @override
  String get edit_group_error_name_required =>
      'Por favor, ingresa un nombre de grupo.';

  @override
  String get edit_group_error_save_failed => 'Error al guardar el grupo.';

  @override
  String get edit_group_error_not_found => 'Grupo no encontrado.';

  @override
  String get edit_group_error_permission_denied =>
      'No tienes permiso para editar este grupo.';

  @override
  String get edit_group_success => 'Grupo actualizado.';

  @override
  String get edit_group_privacy_section => 'PRIVACIDAD';

  @override
  String get edit_group_privacy_forwarding => 'Reenvío de mensajes';

  @override
  String get edit_group_privacy_forwarding_desc =>
      'Permitir a los miembros reenviar mensajes de este grupo.';

  @override
  String get edit_group_privacy_screenshots => 'Capturas de pantalla';

  @override
  String get edit_group_privacy_screenshots_desc =>
      'Permitir capturas de pantalla en este grupo (depende de la plataforma).';

  @override
  String get edit_group_privacy_copy => 'Copiar texto';

  @override
  String get edit_group_privacy_copy_desc =>
      'Permitir copiar texto de mensajes.';

  @override
  String get edit_group_privacy_save_media => 'Guardar multimedia';

  @override
  String get edit_group_privacy_save_media_desc =>
      'Permitir guardar fotos y videos en el dispositivo.';

  @override
  String get edit_group_privacy_share_media => 'Compartir multimedia';

  @override
  String get edit_group_privacy_share_media_desc =>
      'Permitir compartir archivos multimedia fuera de la app.';

  @override
  String get schedule_message_sheet_title => 'Programar mensaje';

  @override
  String get schedule_message_long_press_hint => 'Envío programado';

  @override
  String schedule_message_preset_today_at(String time) {
    return 'Hoy a las $time';
  }

  @override
  String schedule_message_preset_tomorrow_at(String time) {
    return 'Mañana a las $time';
  }

  @override
  String schedule_message_will_send_at(String datetime) {
    return 'Se enviará: $datetime';
  }

  @override
  String get schedule_message_must_be_in_future =>
      'La hora debe ser futura (al menos un minuto a partir de ahora).';

  @override
  String get schedule_message_e2ee_warning =>
      'Este es un chat E2EE. El mensaje programado se almacenará en el servidor en texto plano y se publicará sin cifrado.';

  @override
  String get schedule_message_cancel => 'Cancelar';

  @override
  String get schedule_message_confirm => 'Programar';

  @override
  String get schedule_message_save => 'Guardar';

  @override
  String get schedule_message_text_required => 'Escribe un mensaje primero';

  @override
  String get schedule_message_attachments_unsupported_mobile =>
      'La programación de adjuntos actualmente solo es compatible con la web';

  @override
  String schedule_message_scheduled_toast(String datetime) {
    return 'Programado: $datetime';
  }

  @override
  String schedule_message_failed_toast(String error) {
    return 'Error al programar: $error';
  }

  @override
  String get scheduled_messages_screen_title => 'Mensajes programados';

  @override
  String get scheduled_messages_empty_title => 'No hay mensajes programados';

  @override
  String get scheduled_messages_empty_hint =>
      'Mantén presionado el botón Enviar para programar un mensaje.';

  @override
  String scheduled_messages_load_failed(String error) {
    return 'Error al cargar: $error';
  }

  @override
  String get scheduled_messages_e2ee_notice =>
      'En un chat E2EE, los mensajes programados se almacenan y publican en texto plano.';

  @override
  String get scheduled_messages_cancel_dialog_title =>
      '¿Cancelar envío programado?';

  @override
  String get scheduled_messages_cancel_dialog_body =>
      'El mensaje programado se eliminará.';

  @override
  String get scheduled_messages_cancel_dialog_keep => 'Mantener';

  @override
  String get scheduled_messages_cancel_dialog_confirm => 'Cancelar';

  @override
  String get scheduled_messages_canceled_toast => 'Cancelado';

  @override
  String scheduled_messages_time_changed_toast(String datetime) {
    return 'Hora cambiada: $datetime';
  }

  @override
  String scheduled_messages_action_failed_toast(String error) {
    return 'Error: $error';
  }

  @override
  String get scheduled_messages_tile_edit_tooltip => 'Cambiar hora';

  @override
  String get scheduled_messages_tile_cancel_tooltip => 'Cancelar';

  @override
  String scheduled_messages_preview_poll(String question) {
    return 'Encuesta: $question';
  }

  @override
  String get scheduled_messages_preview_location => 'Ubicación';

  @override
  String get scheduled_messages_preview_attachment => 'Adjunto';

  @override
  String scheduled_messages_preview_attachment_count(int count) {
    return 'Adjunto (×$count)';
  }

  @override
  String get scheduled_messages_preview_message => 'Mensaje';

  @override
  String get chat_header_tooltip_scheduled => 'Mensajes programados';

  @override
  String get schedule_date_label => 'Fecha';

  @override
  String get schedule_time_label => 'Hora';

  @override
  String get common_done => 'Listo';

  @override
  String get common_send => 'Enviar';

  @override
  String get common_open => 'Abrir';

  @override
  String get common_add => 'Agregar';

  @override
  String get common_search => 'Buscar';

  @override
  String get common_edit => 'Editar';

  @override
  String get common_next => 'Siguiente';

  @override
  String get common_ok => 'Aceptar';

  @override
  String get common_confirm => 'Confirmar';

  @override
  String get common_ready => 'Listo';

  @override
  String get common_error => 'Error';

  @override
  String get common_yes => 'Sí';

  @override
  String get common_no => 'No';

  @override
  String get common_back => 'Atrás';

  @override
  String get common_continue => 'Continuar';

  @override
  String get common_loading => 'Cargando…';

  @override
  String get common_copy => 'Copiar';

  @override
  String get common_share => 'Compartir';

  @override
  String get common_settings => 'Configuración';

  @override
  String get common_today => 'Hoy';

  @override
  String get common_yesterday => 'Ayer';

  @override
  String get e2ee_qr_title => 'Emparejamiento de clave QR';

  @override
  String get e2ee_qr_uid_error => 'Error al obtener el uid del usuario.';

  @override
  String get e2ee_qr_session_ended_error =>
      'La sesión finalizó antes de que el segundo dispositivo respondiera.';

  @override
  String get e2ee_qr_no_data_error => 'No hay datos para aplicar la clave.';

  @override
  String get e2ee_qr_key_transferred_toast =>
      'Clave transferida. Vuelve a entrar a los chats para actualizar las sesiones.';

  @override
  String get e2ee_qr_wrong_account_error =>
      'El QR fue generado para una cuenta diferente.';

  @override
  String get e2ee_qr_explainer_title => 'Qué es esto';

  @override
  String get e2ee_qr_explainer_text =>
      'Transfiere una clave privada de uno de tus dispositivos a otro vía ECDH + QR. Ambos lados ven un código de 6 dígitos para verificación manual.';

  @override
  String get e2ee_qr_show_qr_label =>
      'Estoy en el nuevo dispositivo — mostrar QR';

  @override
  String get e2ee_qr_scan_qr_label => 'Ya tengo una clave — escanear QR';

  @override
  String get e2ee_qr_scan_hint =>
      'Escanea el QR en el dispositivo anterior que ya tiene la clave.';

  @override
  String get e2ee_qr_verify_code_label =>
      'Verifica el código de 6 dígitos con el dispositivo anterior:';

  @override
  String e2ee_qr_transfer_from_device_label(String label) {
    return 'Transferir del dispositivo: $label';
  }

  @override
  String get e2ee_qr_code_match_apply_label => 'El código coincide — aplicar';

  @override
  String get e2ee_qr_key_success_label =>
      'Clave transferida exitosamente a este dispositivo. Vuelve a entrar a los chats.';

  @override
  String get e2ee_qr_unknown_error => 'Error desconocido';

  @override
  String get e2ee_qr_back_to_pick_label => 'Volver a la selección';

  @override
  String get e2ee_qr_donor_scan_hint =>
      'Apunta la cámara al QR que se muestra en el nuevo dispositivo.';

  @override
  String get e2ee_qr_donor_verify_code_label =>
      'Verifica el código con el nuevo dispositivo:';

  @override
  String get e2ee_qr_donor_verify_hint =>
      'Si el código coincide — confirma en el nuevo dispositivo. Si no, presiona Cancelar inmediatamente.';

  @override
  String get e2ee_encrypt_title => 'Cifrado';

  @override
  String get e2ee_encrypt_enable_dialog_title => '¿Activar cifrado?';

  @override
  String get e2ee_encrypt_enable_dialog_body =>
      'Los nuevos mensajes solo estarán disponibles en tus dispositivos y los de tu contacto. Los mensajes anteriores permanecerán como están.';

  @override
  String get e2ee_encrypt_enable_label => 'Activar';

  @override
  String get e2ee_encrypt_disable_dialog_title => '¿Desactivar cifrado?';

  @override
  String get e2ee_encrypt_disable_dialog_body =>
      'Los nuevos mensajes se enviarán sin cifrado de extremo a extremo. Los mensajes cifrados enviados anteriormente permanecerán en el historial.';

  @override
  String get e2ee_encrypt_disable_label => 'Desactivar';

  @override
  String get e2ee_encrypt_status_on =>
      'El cifrado de extremo a extremo está activado para este chat.';

  @override
  String get e2ee_encrypt_status_off =>
      'El cifrado de extremo a extremo está desactivado.';

  @override
  String get e2ee_encrypt_description =>
      'Cuando el cifrado está activado, el contenido de los nuevos mensajes solo está disponible para los participantes del chat en sus dispositivos. Desactivar solo afecta a los nuevos mensajes.';

  @override
  String get e2ee_encrypt_switch_title => 'Activar cifrado';

  @override
  String e2ee_encrypt_switch_on(int epoch) {
    return 'Activado (época de clave: $epoch)';
  }

  @override
  String get e2ee_encrypt_switch_off => 'Desactivado';

  @override
  String get e2ee_encrypt_already_on_toast =>
      'El cifrado ya está activado o la creación de clave falló. Verifica la red y las claves de tu contacto.';

  @override
  String get e2ee_encrypt_no_device_toast =>
      'No se pudo activar: el contacto no tiene un dispositivo activo con clave.';

  @override
  String e2ee_encrypt_enable_failed_toast(String error) {
    return 'Error al activar el cifrado: $error';
  }

  @override
  String e2ee_encrypt_disable_failed_toast(String error) {
    return 'Error al desactivar: $error';
  }

  @override
  String get e2ee_encrypt_data_types_title => 'Tipos de datos';

  @override
  String get e2ee_encrypt_data_types_description =>
      'Esta configuración no cambia el protocolo. Controla qué tipos de datos se envían cifrados.';

  @override
  String get e2ee_encrypt_override_title =>
      'Configuración de cifrado para este chat';

  @override
  String get e2ee_encrypt_override_on => 'Se usa la configuración del chat.';

  @override
  String get e2ee_encrypt_override_off => 'Se hereda la configuración global.';

  @override
  String get e2ee_encrypt_text_title => 'Texto del mensaje';

  @override
  String get e2ee_encrypt_media_title => 'Adjuntos (multimedia/archivos)';

  @override
  String get e2ee_encrypt_override_hint =>
      'Para cambiar en este chat — activa la anulación.';

  @override
  String get sticker_default_pack_name => 'Mi paquete';

  @override
  String get sticker_new_pack_dialog_title => 'Nuevo paquete de stickers';

  @override
  String get sticker_pack_name_hint => 'Nombre';

  @override
  String get sticker_save_to_pack => 'Guardar en paquete de stickers';

  @override
  String get sticker_no_packs_hint =>
      'Sin paquetes. Crea uno en la pestaña Stickers.';

  @override
  String get sticker_new_pack_option => 'Nuevo paquete…';

  @override
  String get sticker_pick_image_or_gif => 'Elige una imagen o GIF';

  @override
  String sticker_send_failed(String error) {
    return 'Error al enviar: $error';
  }

  @override
  String get sticker_saved_to_pack => 'Guardado en paquete de stickers';

  @override
  String get sticker_save_gif_failed => 'No se pudo descargar o guardar el GIF';

  @override
  String get sticker_delete_pack_title => '¿Eliminar paquete?';

  @override
  String sticker_delete_pack_body(String name) {
    return '\"$name\" y todos los stickers dentro se eliminarán.';
  }

  @override
  String get sticker_pack_deleted => 'Paquete eliminado';

  @override
  String get sticker_pack_delete_failed => 'Error al eliminar el paquete';

  @override
  String get sticker_tab_emoji => 'emojis';

  @override
  String get sticker_tab_stickers => 'PEGATINAS';

  @override
  String get sticker_tab_gif => 'GIF';

  @override
  String get sticker_scope_my => 'Mío';

  @override
  String get sticker_scope_public => 'Pública';

  @override
  String get sticker_new_pack_tooltip => 'Nuevo paquete';

  @override
  String get sticker_pack_created => 'Paquete de stickers creado';

  @override
  String get sticker_no_packs_create => 'Sin paquetes de stickers. Crea uno.';

  @override
  String get sticker_public_packs_empty =>
      'No hay paquetes públicos configurados';

  @override
  String get sticker_section_recent => 'RECIENTES';

  @override
  String get sticker_pack_empty_hint =>
      'El paquete está vacío. Agrega desde el dispositivo (pestaña GIF — \"A mi paquete\").';

  @override
  String get sticker_delete_sticker_title => '¿Eliminar sticker?';

  @override
  String get sticker_deleted => 'Eliminado';

  @override
  String get sticker_gallery => 'Galería';

  @override
  String get sticker_gallery_subtitle =>
      'Fotos, PNG, GIF del dispositivo — directo al chat';

  @override
  String get gif_search_hint => 'Buscar GIF…';

  @override
  String gif_translated_hint(String query) {
    return 'Buscado: $query';
  }

  @override
  String get gif_search_unavailable =>
      'La búsqueda de GIF no está disponible temporalmente.';

  @override
  String get gif_filter_all => 'Todos';

  @override
  String get sticker_section_animated => 'ANIMADOS';

  @override
  String get sticker_emoji_unavailable =>
      'Emoji a texto no está disponible para esta ventana.';

  @override
  String get sticker_create_pack_hint => 'Crea un paquete con el botón +';

  @override
  String get sticker_public_packs_unavailable =>
      'Paquetes públicos aún no disponibles';

  @override
  String get composer_link_title => 'Enlace';

  @override
  String get composer_link_apply => 'Aplicar';

  @override
  String get composer_attach_title => 'Adjuntar';

  @override
  String get composer_attach_photo_video => 'Foto/Video';

  @override
  String get composer_attach_files => 'Archivos';

  @override
  String get composer_attach_video_circle => 'Video circular';

  @override
  String get composer_attach_location => 'Ubicación';

  @override
  String get composer_attach_poll => 'Encuesta';

  @override
  String get composer_attach_stickers => 'Pegatinas';

  @override
  String get composer_attach_clipboard => 'Portapapeles';

  @override
  String get composer_attach_text => 'Texto';

  @override
  String get meeting_create_poll => 'Crear encuesta';

  @override
  String get meeting_min_two_options =>
      'Se requieren al menos 2 opciones de respuesta';

  @override
  String meeting_error_with_details(String details) {
    return 'Error: $details';
  }

  @override
  String meeting_polls_load_error(String details) {
    return 'Error al cargar encuestas: $details';
  }

  @override
  String get meeting_no_polls_yet => 'Aún no hay encuestas';

  @override
  String get meeting_question_label => 'Pregunta';

  @override
  String get meeting_options_label => 'Opciones';

  @override
  String meeting_option_hint(int index) {
    return 'Opción $index';
  }

  @override
  String get meeting_add_option => 'Agregar opción';

  @override
  String get meeting_anonymous => 'Anónima';

  @override
  String get meeting_anonymous_subtitle =>
      'Quién puede ver las elecciones de otros';

  @override
  String get meeting_save_as_draft => 'Guardar como borrador';

  @override
  String get meeting_publish => 'Publicar';

  @override
  String get meeting_action_start => 'Iniciar';

  @override
  String get meeting_action_change_vote => 'Cambiar voto';

  @override
  String get meeting_action_restart => 'Reiniciar';

  @override
  String get meeting_action_stop => 'Detener';

  @override
  String meeting_vote_failed(String details) {
    return 'Voto no contado: $details';
  }

  @override
  String get meeting_status_ended => 'Finalizada';

  @override
  String get meeting_status_draft => 'Borrador';

  @override
  String get meeting_status_active => 'Activa';

  @override
  String get meeting_status_public => 'Pública';

  @override
  String meeting_votes_count(int count) {
    return '$count votos';
  }

  @override
  String meeting_goal_count(int count) {
    return 'Meta: $count';
  }

  @override
  String get meeting_hide => 'Ocultar';

  @override
  String get meeting_who_voted => 'Quién votó';

  @override
  String meeting_participants_tab(int count) {
    return 'Miembros ($count)';
  }

  @override
  String meeting_polls_tab_active(int count) {
    return 'Encuestas ($count)';
  }

  @override
  String get meeting_polls_tab => 'Encuestas';

  @override
  String meeting_chat_tab_unread(int count) {
    return 'Chat ($count)';
  }

  @override
  String get meeting_chat_tab => 'Charlar';

  @override
  String meeting_requests_tab(int count) {
    return 'Solicitudes ($count)';
  }

  @override
  String meeting_you_suffix(String name) {
    return '$name (Tú)';
  }

  @override
  String get meeting_host_label => 'Anfitrión';

  @override
  String get meeting_force_mute_mic => 'Silenciar micrófono';

  @override
  String get meeting_force_mute_camera => 'Apagar cámara';

  @override
  String get meeting_kick_from_room => 'Eliminar de la sala';

  @override
  String meeting_chat_load_error(Object error) {
    return 'No se pudo cargar el chat: $error';
  }

  @override
  String get meeting_no_requests => 'No hay nuevas solicitudes';

  @override
  String get meeting_no_messages_yet => 'Aún no hay mensajes';

  @override
  String meeting_file_too_large(String name) {
    return 'Archivo demasiado grande: $name';
  }

  @override
  String meeting_send_failed(String details) {
    return 'Error al enviar: $details';
  }

  @override
  String get meeting_edit_message_title => 'Editar mensaje';

  @override
  String meeting_save_failed(String details) {
    return 'Error al guardar: $details';
  }

  @override
  String get meeting_delete_message_title => '¿Eliminar mensaje?';

  @override
  String get meeting_delete_message_body =>
      'Los miembros verán \"Mensaje eliminado\".';

  @override
  String meeting_delete_failed(String details) {
    return 'Error al eliminar: $details';
  }

  @override
  String get meeting_message_hint => 'Mensaje…';

  @override
  String get meeting_message_deleted => 'Mensaje eliminado';

  @override
  String get meeting_message_edited => '• editado';

  @override
  String get meeting_copy_action => 'Copiar';

  @override
  String get meeting_edit_action => 'Editar';

  @override
  String get meeting_join_title => 'Unirse';

  @override
  String meeting_loading_error(String details) {
    return 'Error al cargar la reunión: $details';
  }

  @override
  String get meeting_not_found => 'Reunión no encontrada o cerrada';

  @override
  String get meeting_private_description =>
      'Reunión privada: el anfitrión decidirá si te permite entrar después de tu solicitud.';

  @override
  String get meeting_public_description =>
      'Reunión abierta: únete por enlace sin esperar.';

  @override
  String get meeting_your_name_label => 'Tu nombre';

  @override
  String get meeting_enter_name_error => 'Ingresa tu nombre';

  @override
  String get meeting_guest_name => 'Invitado';

  @override
  String get meeting_enter_room => 'Entrar a la sala';

  @override
  String get meeting_request_join => 'Solicitar unirse';

  @override
  String get meeting_approved_title => 'Aprobado';

  @override
  String get meeting_approved_subtitle => 'Redirigiendo a la sala…';

  @override
  String get meeting_denied_title => 'Denegado';

  @override
  String get meeting_denied_subtitle => 'El anfitrión denegó tu solicitud.';

  @override
  String get meeting_pending_title => 'Esperando aprobación';

  @override
  String get meeting_pending_subtitle =>
      'El anfitrión verá tu solicitud y decidirá cuándo dejarte entrar.';

  @override
  String meeting_load_error(String details) {
    return 'Error al cargar la reunión: $details';
  }

  @override
  String meeting_init_error(Object error) {
    return 'Error de inicialización: $error';
  }

  @override
  String meeting_participants_error(Object error) {
    return 'Miembros: $error';
  }

  @override
  String meeting_bg_unavailable(Object error) {
    return 'Fondo no disponible: $error';
  }

  @override
  String get meeting_leave => 'Salir';

  @override
  String get meeting_screen_share_ios =>
      'Compartir pantalla en iOS requiere Broadcast Extension (próximamente)';

  @override
  String meeting_screen_share_failed(String details) {
    return 'Error al iniciar compartir pantalla: $details';
  }

  @override
  String get meeting_tooltip_speaker_mode => 'Modo orador';

  @override
  String get meeting_tooltip_grid_mode => 'Modo cuadrícula';

  @override
  String get meeting_tooltip_copy_link =>
      'Copiar enlace (acceso por navegador)';

  @override
  String get meeting_mic_on => 'Activar micrófono';

  @override
  String get meeting_mic_off => 'Silenciar';

  @override
  String get meeting_camera_on => 'Cámara encendida';

  @override
  String get meeting_camera_off => 'Cámara apagada';

  @override
  String get meeting_switch_camera => 'Cambiar';

  @override
  String get meeting_hand_lower => 'Bajar';

  @override
  String get meeting_hand_raise => 'Mano';

  @override
  String get meeting_reaction => 'Reacción';

  @override
  String get meeting_screen_stop => 'Detener';

  @override
  String get meeting_screen_label => 'Pantalla';

  @override
  String get meeting_bg_off => 'Fondo';

  @override
  String get meeting_bg_blur => 'Difuminar';

  @override
  String get meeting_bg_image => 'Imagen';

  @override
  String get meeting_participants_button => 'Miembros';

  @override
  String get meeting_notifications_button => 'Actividad';

  @override
  String get meeting_pip_button => 'Minimizar';

  @override
  String get settings_chats_bottom_nav_icons_title =>
      'Iconos de navegación inferior';

  @override
  String get settings_chats_bottom_nav_icons_subtitle =>
      'Elige iconos y estilo visual como en la web.';

  @override
  String get settings_chats_nav_colorful => 'Colorido';

  @override
  String get settings_chats_nav_minimal => 'Minimalista';

  @override
  String get settings_chats_nav_global_title => 'Para todos los iconos';

  @override
  String get settings_chats_nav_global_subtitle =>
      'Capa global: color, tamaño, ancho de trazo y mosaico de fondo.';

  @override
  String get settings_chats_reset_tooltip => 'Restablecer';

  @override
  String get settings_chats_collapse => 'Colapsar';

  @override
  String get settings_chats_customize => 'Personalizar';

  @override
  String get settings_chats_reset_item_tooltip => 'Restablecer';

  @override
  String get settings_chats_style_tooltip => 'Estilo';

  @override
  String get settings_chats_icon_size => 'Tamaño del icono';

  @override
  String get settings_chats_stroke_width => 'Ancho del trazo';

  @override
  String get settings_chats_default => 'Predeterminado';

  @override
  String get settings_chats_icon_search_hint_en => 'Buscar por nombre...';

  @override
  String get settings_chats_emoji_effects => 'Efectos de emoji';

  @override
  String get settings_chats_emoji_effects_subtitle =>
      'Perfil de animación para emoji a pantalla completa al tocar un solo emoji en el chat.';

  @override
  String get settings_chats_emoji_lite_desc =>
      'Lite: carga mínima y máxima fluidez en dispositivos de gama baja.';

  @override
  String get settings_chats_emoji_balanced_desc =>
      'Equilibrado: compromiso automático entre rendimiento y expresividad.';

  @override
  String get settings_chats_emoji_cinematic_desc =>
      'Cinemático: máximo de partículas y profundidad para efecto impactante.';

  @override
  String get settings_chats_preview_incoming_msg => '¡Oye! ¿Cómo estás?';

  @override
  String get settings_chats_preview_outgoing_msg => '¡Bien, gracias!';

  @override
  String get settings_chats_preview_hello => 'Hola';

  @override
  String get chat_theme_title => 'Tema del chat';

  @override
  String chat_theme_error_save(String error) {
    return 'Error al guardar el fondo: $error';
  }

  @override
  String chat_theme_error_upload(String error) {
    return 'Error al subir el fondo: $error';
  }

  @override
  String get chat_theme_delete_title => '¿Eliminar fondo de la galería?';

  @override
  String get chat_theme_delete_body =>
      'La imagen se eliminará de tu lista de fondos. Puedes elegir otro para este chat.';

  @override
  String chat_theme_error_delete(String error) {
    return 'Error al eliminar: $error';
  }

  @override
  String get chat_theme_banner =>
      'El fondo de este chat es solo para ti. La configuración global del chat en \"Configuración del chat\" permanece sin cambios.';

  @override
  String get chat_theme_current_bg => 'Fondo actual';

  @override
  String get chat_theme_default_global =>
      'Predeterminado (configuración global)';

  @override
  String get chat_theme_presets => 'Preajustes';

  @override
  String get chat_theme_global_tile => 'Global';

  @override
  String get chat_theme_pick_hint => 'Elige un preset o foto de la galería';

  @override
  String get contacts_title => 'Contactos';

  @override
  String get contacts_add_phone_prompt =>
      'Agrega un número de teléfono en tu perfil para buscar contactos por número.';

  @override
  String get contacts_fallback_profile => 'Perfil';

  @override
  String get contacts_fallback_user => 'Usuario';

  @override
  String get contacts_status_online => 'en línea';

  @override
  String get contacts_status_recently => 'Visto recientemente';

  @override
  String contacts_status_today_at(String time) {
    return 'Visto a las $time';
  }

  @override
  String get contacts_status_yesterday => 'Visto ayer';

  @override
  String get contacts_status_year_ago => 'Visto hace un año';

  @override
  String contacts_status_years_ago(String years) {
    return 'Visto hace $years';
  }

  @override
  String contacts_status_date(String date) {
    return 'Visto el $date';
  }

  @override
  String get contacts_empty_state =>
      'No se encontraron contactos.\nToca el botón de la derecha para sincronizar tu agenda.';

  @override
  String get add_contact_title => 'Nuevo contacto';

  @override
  String get add_contact_sync_off =>
      'La sincronización está desactivada en la app.';

  @override
  String get add_contact_enable_system_access =>
      'Activa el acceso a contactos de LighChat en la configuración del sistema.';

  @override
  String get add_contact_sync_on => 'Sincronización activada';

  @override
  String get add_contact_sync_failed =>
      'No se pudo activar la sincronización de contactos';

  @override
  String get add_contact_invalid_phone =>
      'Ingresa un número de teléfono válido';

  @override
  String get add_contact_not_found_by_phone =>
      'No se encontró contacto para este número';

  @override
  String get add_contact_found => 'Contacto encontrado';

  @override
  String add_contact_search_error(String error) {
    return 'Error en la búsqueda: $error';
  }

  @override
  String get add_contact_qr_no_profile =>
      'El código QR no contiene un perfil de LighChat';

  @override
  String get add_contact_qr_own_profile => 'Este es tu propio perfil';

  @override
  String get add_contact_qr_profile_not_found =>
      'Perfil del código QR no encontrado';

  @override
  String get add_contact_qr_found => 'Contacto encontrado por código QR';

  @override
  String add_contact_qr_read_error(String error) {
    return 'No se pudo leer el código QR: $error';
  }

  @override
  String get add_contact_cannot_add_user =>
      'No se puede agregar a este usuario';

  @override
  String add_contact_add_error(String error) {
    return 'No se pudo agregar el contacto: $error';
  }

  @override
  String get add_contact_country_search_hint => 'Buscar por país o código';

  @override
  String get add_contact_sync_with_phone => 'Sincronizar con teléfono';

  @override
  String get add_contact_add_by_qr => 'Agregar por código QR';

  @override
  String get add_contact_results_unavailable => 'Resultados aún no disponibles';

  @override
  String add_contact_profile_load_error(String error) {
    return 'No se pudo cargar el contacto: $error';
  }

  @override
  String get add_contact_profile_not_found => 'Perfil no encontrado';

  @override
  String get add_contact_badge_already_added => 'Ya agregado';

  @override
  String get add_contact_badge_new => 'Nuevo contacto';

  @override
  String get add_contact_badge_unavailable => 'No disponible';

  @override
  String get add_contact_open_contact => 'Abrir contacto';

  @override
  String get add_contact_add_to_contacts => 'Agregar a contactos';

  @override
  String get add_contact_add_unavailable => 'No se puede agregar';

  @override
  String get add_contact_searching => 'Buscando contacto...';

  @override
  String get add_contact_scan_qr_title => 'Escanear código QR';

  @override
  String get add_contact_flash_tooltip => 'Destello';

  @override
  String get add_contact_scan_qr_hint =>
      'Apunta tu cámara al código QR de un perfil de LighChat';

  @override
  String get contacts_edit_enter_name => 'Ingresa el nombre del contacto.';

  @override
  String contacts_edit_save_error(String error) {
    return 'No se pudo guardar el contacto: $error';
  }

  @override
  String get contacts_edit_first_name_hint => 'Nombre';

  @override
  String get contacts_edit_last_name_hint => 'Apellido';

  @override
  String get contacts_edit_name_disclaimer =>
      'Este nombre solo es visible para ti: en chats, búsqueda y la lista de contactos.';

  @override
  String contacts_edit_error(String error) {
    return 'Error: $error';
  }

  @override
  String get chat_settings_color_default => 'Predeterminado';

  @override
  String get chat_settings_color_lilac => 'Lila';

  @override
  String get chat_settings_color_pink => 'Rosa';

  @override
  String get chat_settings_color_green => 'Verde';

  @override
  String get chat_settings_color_coral => 'Coral';

  @override
  String get chat_settings_color_mint => 'Menta';

  @override
  String get chat_settings_color_sky => 'Cielo';

  @override
  String get chat_settings_color_purple => 'Púrpura';

  @override
  String get chat_settings_color_crimson => 'Carmesí';

  @override
  String get chat_settings_color_tiffany => 'tiffany';

  @override
  String get chat_settings_color_yellow => 'Amarillo';

  @override
  String get chat_settings_color_powder => 'Polvos';

  @override
  String get chat_settings_color_turquoise => 'Turquesa';

  @override
  String get chat_settings_color_blue => 'Azul';

  @override
  String get chat_settings_color_sunset => 'Atardecer';

  @override
  String get chat_settings_color_tender => 'Suave';

  @override
  String get chat_settings_color_lime => 'Lima';

  @override
  String get chat_settings_color_graphite => 'Grafito';

  @override
  String get chat_settings_color_no_bg => 'Sin fondo';

  @override
  String get chat_settings_icon_color => 'Color del icono';

  @override
  String get chat_settings_icon_size => 'Tamaño del icono';

  @override
  String get chat_settings_stroke_width => 'Ancho del trazo';

  @override
  String get chat_settings_tile_background => 'Mosaico de fondo';

  @override
  String get chat_settings_bottom_nav_icons => 'Iconos de navegación inferior';

  @override
  String get chat_settings_bottom_nav_description =>
      'Elige iconos y estilo visual como en la web.';

  @override
  String get chat_settings_bottom_nav_global_description =>
      'Capa compartida: color, tamaño, trazo y mosaico de fondo.';

  @override
  String get chat_settings_colorful => 'Colorido';

  @override
  String get chat_settings_minimalism => 'Minimalista';

  @override
  String get chat_settings_for_all_icons => 'Para todos los iconos';

  @override
  String get chat_settings_customize => 'Personalizar';

  @override
  String get chat_settings_hide => 'Ocultar';

  @override
  String get chat_settings_reset => 'Restablecer';

  @override
  String get chat_settings_reset_item => 'Restablecer';

  @override
  String get chat_settings_style => 'Estilo';

  @override
  String get chat_settings_select => 'Seleccionar';

  @override
  String get chat_settings_reset_size => 'Restablecer tamaño';

  @override
  String get chat_settings_reset_stroke => 'Restablecer trazo';

  @override
  String get chat_settings_default_gradient => 'Degradado predeterminado';

  @override
  String get chat_settings_inherit_global => 'Heredar de global';

  @override
  String get chat_settings_no_bg_on => 'Sin fondo (activado)';

  @override
  String get chat_settings_no_bg => 'Sin fondo';

  @override
  String get chat_settings_outgoing_messages => 'Mensajes enviados';

  @override
  String get chat_settings_incoming_messages => 'Mensajes recibidos';

  @override
  String get chat_settings_font_size => 'Tamaño de fuente';

  @override
  String get chat_settings_font_small => 'Pequeño';

  @override
  String get chat_settings_font_medium => 'Mediano';

  @override
  String get chat_settings_font_large => 'Grande';

  @override
  String get chat_settings_bubble_shape => 'Forma de burbuja';

  @override
  String get chat_settings_bubble_rounded => 'Redondeada';

  @override
  String get chat_settings_bubble_square => 'Cuadrada';

  @override
  String get chat_settings_chat_background => 'Fondo del chat';

  @override
  String get chat_settings_background_hint =>
      'Elige una foto de la galería o personaliza';

  @override
  String get chat_settings_builtin_wallpapers_heading => 'Fondos de marca';

  @override
  String get chat_settings_show_all_wallpapers => 'Ver todos los fondos';

  @override
  String get chat_settings_animated_wallpapers_heading => 'Fondos animados';

  @override
  String get chat_settings_animated_wallpapers_hint =>
      'Se reproduce una vez al abrir el chat';

  @override
  String get chat_settings_emoji_effects => 'Efectos de emoji';

  @override
  String get chat_settings_emoji_description =>
      'Perfil de animación para explosión de emoji a pantalla completa al tocar en el chat.';

  @override
  String get chat_settings_emoji_lite =>
      'Lite: carga mínima, más fluido en dispositivos de gama baja.';

  @override
  String get chat_settings_emoji_cinematic =>
      'Cinemático: máximo de partículas y profundidad para un efecto impactante.';

  @override
  String get chat_settings_emoji_balanced =>
      'Equilibrado: compromiso automático entre rendimiento y expresividad.';

  @override
  String get chat_settings_additional => 'Adicional';

  @override
  String get chat_settings_show_time => 'Mostrar hora';

  @override
  String get chat_settings_show_time_hint =>
      'Hora de envío debajo de los mensajes';

  @override
  String get chat_settings_auto_translate => 'Auto-traducir entrantes';

  @override
  String get chat_settings_auto_translate_hint =>
      'Mensajes en otros idiomas se traducen en el dispositivo a tu idioma';

  @override
  String get message_auto_translated_label => 'Traducido';

  @override
  String get message_show_original => 'Mostrar original';

  @override
  String get message_show_translation => 'Mostrar traducción';

  @override
  String get chat_settings_reset_all => 'Restablecer configuración';

  @override
  String get chat_settings_preview_incoming => '¡Hola! ¿Cómo estás?';

  @override
  String get chat_settings_preview_outgoing => '¡Bien, gracias!';

  @override
  String get chat_settings_preview_hello => 'Hola';

  @override
  String chat_settings_icon_picker_title(String label) {
    return 'Icono: \"$label\"';
  }

  @override
  String get chat_settings_search_hint => 'Buscar por nombre (ing.)...';

  @override
  String meeting_tab_participants(Object count) {
    return 'Miembros ($count)';
  }

  @override
  String get meeting_tab_polls => 'Encuestas';

  @override
  String meeting_tab_polls_count(Object count) {
    return 'Encuestas ($count)';
  }

  @override
  String get meeting_tab_chat => 'Charlar';

  @override
  String meeting_tab_chat_count(Object count) {
    return 'Chat ($count)';
  }

  @override
  String meeting_tab_requests(Object count) {
    return 'Solicitudes ($count)';
  }

  @override
  String get meeting_kick => 'Eliminar de la sala';

  @override
  String meeting_file_too_big(Object name) {
    return 'Archivo muy grande: $name';
  }

  @override
  String meeting_send_error(Object error) {
    return 'No se pudo enviar: $error';
  }

  @override
  String meeting_save_error(Object error) {
    return 'No se pudo guardar: $error';
  }

  @override
  String meeting_delete_error(Object error) {
    return 'No se pudo eliminar: $error';
  }

  @override
  String get meeting_no_messages => 'Aún no hay mensajes';

  @override
  String get meeting_join_enter_name => 'Ingresa tu nombre';

  @override
  String get meeting_join_guest => 'Invitado';

  @override
  String get meeting_join_as_label => 'Te unirás como';

  @override
  String get meeting_lobby_camera_blocked =>
      'El permiso de la cámara está denegado. Te unirás con la cámara apagada.';

  @override
  String get meeting_join_button => 'Unirse';

  @override
  String meeting_join_load_error(Object error) {
    return 'Error al cargar la reunión: $error';
  }

  @override
  String get meeting_private_hint =>
      'Reunión privada: el anfitrión decidirá si te permite entrar después de tu solicitud.';

  @override
  String get meeting_public_hint =>
      'Reunión abierta: únete por enlace sin esperar.';

  @override
  String get meeting_name_label => 'Tu nombre';

  @override
  String get meeting_waiting_title => 'Esperando aprobación';

  @override
  String get meeting_waiting_subtitle =>
      'El anfitrión verá tu solicitud y decidirá cuándo dejarte entrar.';

  @override
  String get meeting_screen_share_ios_hint =>
      'Compartir pantalla en iOS requiere una Broadcast Extension (en desarrollo).';

  @override
  String meeting_screen_share_error(Object error) {
    return 'No se pudo iniciar compartir pantalla: $error';
  }

  @override
  String get meeting_speaker_mode => 'Modo orador';

  @override
  String get meeting_grid_mode => 'Modo cuadrícula';

  @override
  String get meeting_copy_link_tooltip =>
      'Copiar enlace (acceso por navegador)';

  @override
  String get group_members_subtitle_creator => 'Creador del grupo';

  @override
  String get group_members_subtitle_admin => 'Administrador';

  @override
  String get group_members_subtitle_member => 'Miembro';

  @override
  String group_members_total_count(int count) {
    return 'Total: $count';
  }

  @override
  String get group_members_copy_invite_tooltip => 'Copiar enlace de invitación';

  @override
  String get group_members_add_member_tooltip => 'Agregar miembro';

  @override
  String get group_members_invite_copied => 'Enlace de invitación copiado';

  @override
  String group_members_copy_link_error(String error) {
    return 'Error al copiar el enlace: $error';
  }

  @override
  String get group_members_added => 'Miembros agregados';

  @override
  String get group_members_revoke_admin_title =>
      '¿Revocar privilegios de administrador?';

  @override
  String group_members_revoke_admin_body(String name) {
    return '$name perderá privilegios de administrador. Permanecerá en el grupo como miembro regular.';
  }

  @override
  String get group_members_grant_admin_title =>
      '¿Otorgar privilegios de administrador?';

  @override
  String group_members_grant_admin_body(String name) {
    return '$name recibirá privilegios de administrador: podrá editar el grupo, eliminar miembros y gestionar mensajes.';
  }

  @override
  String get group_members_revoke_admin_action => 'Revocar';

  @override
  String get group_members_grant_admin_action => 'Otorgar';

  @override
  String get group_members_remove_title => '¿Eliminar miembro?';

  @override
  String group_members_remove_body(String name) {
    return '$name será eliminado del grupo. Puedes deshacer esto agregando al miembro de nuevo.';
  }

  @override
  String get group_members_remove_action => 'Eliminar';

  @override
  String get group_members_removed => 'Miembro eliminado';

  @override
  String get group_members_menu_revoke_admin => 'Quitar administrador';

  @override
  String get group_members_menu_grant_admin => 'Hacer administrador';

  @override
  String get group_members_menu_remove => 'Eliminar del grupo';

  @override
  String get group_members_creator_badge => 'CREADOR';

  @override
  String get group_members_add_title => 'Agregar miembros';

  @override
  String get group_members_search_contacts => 'Buscar contactos';

  @override
  String get group_members_all_in_group =>
      'Todos tus contactos ya están en el grupo.';

  @override
  String get group_members_nobody_found => 'No se encontró a nadie.';

  @override
  String get group_members_user_fallback => 'Usuario';

  @override
  String get group_members_select_members => 'Seleccionar miembros';

  @override
  String group_members_add_count(int count) {
    return 'Agregar ($count)';
  }

  @override
  String group_members_contacts_load_error(String error) {
    return 'Error al cargar contactos: $error';
  }

  @override
  String group_members_auth_error(String error) {
    return 'Error de autorización: $error';
  }

  @override
  String group_members_add_failed(String error) {
    return 'Error al agregar miembros: $error';
  }

  @override
  String get group_not_found => 'Grupo no encontrado.';

  @override
  String get group_not_member => 'No eres miembro de este grupo.';

  @override
  String get poll_create_title => 'Encuesta del chat';

  @override
  String get poll_question_label => 'Pregunta';

  @override
  String get poll_question_hint => 'Ej.: ¿A qué hora nos vemos?';

  @override
  String get poll_description_label => 'Descripción (opcional)';

  @override
  String get poll_options_title => 'Opciones';

  @override
  String poll_option_hint(int index) {
    return 'Opción $index';
  }

  @override
  String get poll_add_option => 'Agregar opción';

  @override
  String get poll_switch_anonymous => 'Votación anónima';

  @override
  String get poll_switch_anonymous_sub => 'No mostrar quién votó por qué';

  @override
  String get poll_switch_multi => 'Respuestas múltiples';

  @override
  String get poll_switch_multi_sub => 'Se pueden seleccionar varias opciones';

  @override
  String get poll_switch_add_options => 'Agregar opciones';

  @override
  String get poll_switch_add_options_sub =>
      'Los participantes pueden sugerir sus propias opciones';

  @override
  String get poll_switch_revote => 'Puede cambiar voto';

  @override
  String get poll_switch_revote_sub =>
      'Se permite cambiar el voto hasta que cierre la encuesta';

  @override
  String get poll_switch_shuffle => 'Mezclar opciones';

  @override
  String get poll_switch_shuffle_sub =>
      'Orden diferente para cada participante';

  @override
  String get poll_switch_quiz => 'Modo quiz';

  @override
  String get poll_switch_quiz_sub => 'Una respuesta correcta';

  @override
  String get poll_correct_option_label => 'Opción correcta';

  @override
  String get poll_quiz_explanation_label => 'Explicación (opcional)';

  @override
  String get poll_close_by_time => 'Cerrar por tiempo';

  @override
  String get poll_close_not_set => 'No establecido';

  @override
  String get poll_close_reset => 'Restablecer fecha límite';

  @override
  String get poll_publish => 'Publicar';

  @override
  String get poll_error_empty_question => 'Ingresa una pregunta';

  @override
  String get poll_error_min_options => 'Se requieren al menos 2 opciones';

  @override
  String get poll_error_select_correct => 'Selecciona la opción correcta';

  @override
  String get poll_error_future_time => 'La hora de cierre debe ser futura';

  @override
  String get poll_unavailable => 'Encuesta no disponible';

  @override
  String get poll_loading => 'Cargando encuesta…';

  @override
  String get poll_not_found => 'Encuesta no encontrada';

  @override
  String get poll_status_cancelled => 'Cancelada';

  @override
  String get poll_status_ended => 'Finalizada';

  @override
  String get poll_status_draft => 'Borrador';

  @override
  String get poll_status_active => 'Activa';

  @override
  String get poll_badge_public => 'Pública';

  @override
  String get poll_badge_multi => 'Respuestas múltiples';

  @override
  String get poll_badge_quiz => 'Prueba';

  @override
  String get poll_menu_restart => 'Reiniciar';

  @override
  String get poll_menu_end => 'Finalizar';

  @override
  String get poll_menu_delete => 'Eliminar';

  @override
  String get poll_submit_vote => 'Enviar voto';

  @override
  String get poll_suggest_option_hint => 'Sugerir una opción';

  @override
  String get poll_revote => 'Cambiar voto';

  @override
  String poll_votes_count(int count) {
    return '$count votos';
  }

  @override
  String get poll_show_voters => 'Quién votó';

  @override
  String get poll_hide_voters => 'Ocultar';

  @override
  String get poll_vote_error => 'Error al votar';

  @override
  String get poll_add_option_error => 'Error al agregar opción';

  @override
  String get poll_error_generic => 'Error';

  @override
  String get durak_your_turn => 'Tu turno';

  @override
  String get durak_winner_label => 'Ganador';

  @override
  String get durak_rematch => 'Jugar de nuevo';

  @override
  String get durak_surrender_tooltip => 'Terminar juego';

  @override
  String get durak_close_tooltip => 'Cerrar';

  @override
  String get durak_fx_took => 'Tomó';

  @override
  String get durak_fx_beat => 'Ganado';

  @override
  String get durak_opponent_role_defend => 'DEF';

  @override
  String get durak_opponent_role_attack => 'ATK';

  @override
  String get durak_opponent_role_throwin => 'LAN';

  @override
  String get durak_foul_banner_title => '¡Tramposo! Perdido:';

  @override
  String get durak_pending_resolution_attacker =>
      'Esperando verificación de falta… Presiona \"Confirmar ganado\" si todos están de acuerdo.';

  @override
  String get durak_pending_resolution_other =>
      'Esperando verificación de falta… Puedes presionar \"¡Falta!\" si notaste trampa.';

  @override
  String durak_tournament_played(int finished, int total) {
    return 'Jugados $finished de $total';
  }

  @override
  String get durak_tournament_finished => 'Torneo terminado';

  @override
  String get durak_tournament_next => 'Siguiente juego del torneo';

  @override
  String get durak_single_game => 'Juego individual';

  @override
  String get durak_tournament_total_games_title =>
      '¿Cuántos juegos en el torneo?';

  @override
  String get durak_finish_game_tooltip => 'Terminar juego';

  @override
  String get durak_lobby_game_unavailable =>
      'El juego no está disponible o fue eliminado';

  @override
  String get durak_lobby_back_tooltip => 'Atrás';

  @override
  String get durak_lobby_waiting => 'Esperando al oponente…';

  @override
  String get durak_lobby_start => 'Iniciar juego';

  @override
  String get durak_lobby_waiting_short => 'Esperando…';

  @override
  String get durak_lobby_ready => 'Listo';

  @override
  String get durak_lobby_empty_slot => 'Esperando…';

  @override
  String get durak_settings_timer_subtitle => '15 segundos por defecto';

  @override
  String get durak_dm_game_active => 'Juego de Durak en progreso';

  @override
  String get durak_dm_game_created => 'Juego de Durak creado';

  @override
  String get game_durak_subtitle => 'Juego individual o torneo';

  @override
  String get group_member_write_dm => 'Enviar mensaje directo';

  @override
  String get group_member_open_dm_hint => 'Abrir chat directo con miembro';

  @override
  String get group_member_profile_not_loaded =>
      'Perfil del miembro aún no cargado.';

  @override
  String group_member_open_dm_error(String error) {
    return 'Error al abrir el chat directo: $error';
  }

  @override
  String get group_avatar_photo_title => 'Foto del grupo';

  @override
  String get group_avatar_add_photo => 'Agregar foto';

  @override
  String get group_avatar_change => 'Cambiar avatar';

  @override
  String get group_avatar_remove => 'Eliminar avatar';

  @override
  String group_avatar_process_error(String error) {
    return 'Error al procesar la foto: $error';
  }

  @override
  String get group_mention_no_matches => 'Sin coincidencias';

  @override
  String get durak_error_defense_does_not_beat =>
      'Esta carta no gana a la carta de ataque';

  @override
  String get durak_error_only_attacker_first => 'El atacante va primero';

  @override
  String get durak_error_defender_cannot_attack =>
      'El defensor no puede lanzar ahora';

  @override
  String get durak_error_not_allowed_throwin =>
      'No puedes lanzar en esta ronda';

  @override
  String get durak_error_throwin_not_your_turn =>
      'Otro jugador está lanzando ahora';

  @override
  String get durak_error_rank_not_allowed =>
      'Solo puedes lanzar cartas del mismo rango';

  @override
  String get durak_error_cannot_throw_in => 'No se pueden lanzar más cartas';

  @override
  String get durak_error_card_not_in_hand => 'Esta carta ya no está en tu mano';

  @override
  String get durak_error_already_defended => 'Esta carta ya está defendida';

  @override
  String get durak_error_bad_attack_index =>
      'Selecciona una carta de ataque para defender';

  @override
  String get durak_error_only_defender => 'Otro jugador está defendiendo ahora';

  @override
  String get durak_error_defender_already_taking =>
      'El defensor ya está tomando cartas';

  @override
  String get durak_error_game_not_active => 'El juego ya no está activo';

  @override
  String get durak_error_not_in_lobby => 'La sala ya ha iniciado';

  @override
  String get durak_error_game_already_active => 'El juego ya ha iniciado';

  @override
  String get durak_error_active_game_exists =>
      'Ya hay un juego activo en este chat';

  @override
  String get durak_error_resolution_pending =>
      'Termina primero el movimiento disputado';

  @override
  String get durak_error_rematch_failed =>
      'Error al preparar la revancha. Por favor intenta de nuevo';

  @override
  String get durak_error_unauthenticated => 'Necesitas iniciar sesión';

  @override
  String get durak_error_permission_denied =>
      'Esta acción no está disponible para ti';

  @override
  String get durak_error_invalid_argument => 'Movimiento no válido';

  @override
  String get durak_error_failed_precondition =>
      'El movimiento no está disponible en este momento';

  @override
  String get durak_error_server =>
      'Error al ejecutar el movimiento. Por favor intenta de nuevo';

  @override
  String pinned_count(int count) {
    return 'Fijados: $count';
  }

  @override
  String get pinned_single => 'Fijado';

  @override
  String get pinned_unpin_tooltip => 'Desfijar';

  @override
  String get pinned_type_image => 'Imagen';

  @override
  String get pinned_type_video => 'Video';

  @override
  String get pinned_type_video_circle => 'Video circular';

  @override
  String get pinned_type_voice => 'Mensaje de voz';

  @override
  String get pinned_type_poll => 'Encuesta';

  @override
  String get pinned_type_link => 'Enlace';

  @override
  String get pinned_type_location => 'Ubicación';

  @override
  String get pinned_type_sticker => 'Etiqueta engomada';

  @override
  String get pinned_type_file => 'Archivo';

  @override
  String get call_entry_login_required_title => 'Se requiere iniciar sesión';

  @override
  String get call_entry_login_required_subtitle =>
      'Abre la app e inicia sesión en tu cuenta.';

  @override
  String get call_entry_not_found_title => 'Llamada no encontrada';

  @override
  String get call_entry_not_found_subtitle =>
      'La llamada ya finalizó o fue eliminada. Regresando a llamadas…';

  @override
  String get call_entry_to_calls => 'Ir a llamadas';

  @override
  String get call_entry_ended_title => 'Llamada finalizada';

  @override
  String get call_entry_ended_subtitle =>
      'Esta llamada ya no está disponible. Regresando a llamadas…';

  @override
  String get call_entry_caller_fallback => 'Llamante';

  @override
  String get call_entry_opening_title => 'Abriendo llamada…';

  @override
  String get call_entry_connecting_video => 'Conectando a videollamada';

  @override
  String get call_entry_connecting_audio => 'Conectando a llamada de audio';

  @override
  String get call_entry_loading_subtitle => 'Cargando datos de la llamada';

  @override
  String get call_entry_error_title => 'Error al abrir la llamada';

  @override
  String chat_theme_save_error(Object error) {
    return 'Error al guardar el fondo: $error';
  }

  @override
  String chat_theme_load_error(Object error) {
    return 'Error al cargar el fondo: $error';
  }

  @override
  String chat_theme_delete_error(Object error) {
    return 'Error al eliminar: $error';
  }

  @override
  String get chat_theme_description =>
      'El fondo de esta conversación solo es visible para ti. La configuración global del chat en la sección de Configuración del chat no se ve afectada.';

  @override
  String get chat_theme_default_bg => 'Predeterminado (configuración global)';

  @override
  String get chat_theme_global_label => 'Global';

  @override
  String get chat_theme_hint => 'Elige un preset o foto de la galería';

  @override
  String get date_today => 'Hoy';

  @override
  String get date_yesterday => 'Ayer';

  @override
  String get date_month_1 => 'Enero';

  @override
  String get date_month_2 => 'Febrero';

  @override
  String get date_month_3 => 'Marzo';

  @override
  String get date_month_4 => 'Abril';

  @override
  String get date_month_5 => 'Mayo';

  @override
  String get date_month_6 => 'Junio';

  @override
  String get date_month_7 => 'Julio';

  @override
  String get date_month_8 => 'Agosto';

  @override
  String get date_month_9 => 'Septiembre';

  @override
  String get date_month_10 => 'Octubre';

  @override
  String get date_month_11 => 'Noviembre';

  @override
  String get date_month_12 => 'Diciembre';

  @override
  String get video_circle_camera_unavailable => 'Cámara no disponible';

  @override
  String video_circle_camera_error(Object error) {
    return 'Error al abrir la cámara: $error';
  }

  @override
  String video_circle_record_error(Object error) {
    return 'Error de grabación: $error';
  }

  @override
  String get video_circle_file_not_found =>
      'Archivo de grabación no encontrado';

  @override
  String get video_circle_play_error => 'Error al reproducir la grabación';

  @override
  String video_circle_send_error(Object error) {
    return 'Error al enviar: $error';
  }

  @override
  String video_circle_switch_error(Object error) {
    return 'Error al cambiar de cámara: $error';
  }

  @override
  String video_circle_pause_error_detail(Object description, Object code) {
    return 'Pausa no disponible: $description ($code)';
  }

  @override
  String video_circle_pause_error(Object error) {
    return 'Pausar grabación: $error';
  }

  @override
  String get video_circle_camera_fallback_error => 'Error de cámara';

  @override
  String get video_circle_retry => 'Reintentar';

  @override
  String get video_circle_sending => 'Enviando...';

  @override
  String get video_circle_recorded => 'Video circular grabado';

  @override
  String get video_circle_swipe_cancel =>
      'Desliza a la izquierda para cancelar';

  @override
  String media_screen_error(Object error) {
    return 'Error al cargar multimedia: $error';
  }

  @override
  String get media_screen_title => 'Multimedia, enlaces y archivos';

  @override
  String get media_tab_media => 'Multimedia';

  @override
  String get media_tab_circles => 'Círculos';

  @override
  String get media_tab_files => 'Archivos';

  @override
  String get media_tab_links => 'Enlaces';

  @override
  String get media_tab_audio => 'Audio';

  @override
  String get media_empty_files => 'Sin archivos';

  @override
  String get media_empty_media => 'Sin multimedia';

  @override
  String get media_attachment_fallback => 'Adjunto';

  @override
  String get media_empty_circles => 'Sin videos circulares';

  @override
  String get media_empty_links => 'Sin enlaces';

  @override
  String get media_empty_audio => 'Sin mensajes de voz';

  @override
  String get media_sender_you => 'Tú';

  @override
  String get media_sender_fallback => 'Participante';

  @override
  String get call_detail_login_required => 'Se requiere iniciar sesión.';

  @override
  String get call_detail_not_found => 'Llamada no encontrada o sin acceso.';

  @override
  String get call_detail_unknown => 'Desconocido';

  @override
  String get call_detail_title => 'Detalles de la llamada';

  @override
  String get call_detail_video => 'Videollamada';

  @override
  String get call_detail_audio => 'Llamada de audio';

  @override
  String get call_detail_outgoing => 'Saliente';

  @override
  String get call_detail_incoming => 'Entrante';

  @override
  String get call_detail_date_label => 'Fecha:';

  @override
  String get call_detail_duration_label => 'Duración:';

  @override
  String get call_detail_call_button => 'Llamar';

  @override
  String get call_detail_video_button => 'Video';

  @override
  String call_detail_error(Object error) {
    return 'Error: $error';
  }

  @override
  String get durak_took => 'Tomó';

  @override
  String get durak_beaten => 'Ganado';

  @override
  String get durak_end_game_tooltip => 'Terminar juego';

  @override
  String get durak_role_beats => 'DEF';

  @override
  String get durak_role_move => 'MOV';

  @override
  String get durak_role_throw => 'LAN';

  @override
  String get durak_cheater_label => '¡Tramposo! Perdido:';

  @override
  String get durak_waiting_foll_confirm =>
      'Esperando que canten falta… Presiona \"Confirmar ganado\" si todos están de acuerdo.';

  @override
  String get durak_waiting_foll_call =>
      'Esperando que canten falta… Ahora puedes presionar \"¡Falta!\" si viste trampa.';

  @override
  String get durak_winner => 'Ganador';

  @override
  String get durak_play_again => 'Jugar de nuevo';

  @override
  String durak_games_progress(Object finished, Object total) {
    return 'Jugados $finished de $total';
  }

  @override
  String get durak_next_round => 'Siguiente ronda del torneo';

  @override
  String audio_call_error(Object error) {
    return 'Error de llamada: $error';
  }

  @override
  String get audio_call_ended => 'Llamada finalizada';

  @override
  String get audio_call_missed => 'Llamada perdida';

  @override
  String get audio_call_cancelled => 'Llamada cancelada';

  @override
  String get audio_call_offer_not_ready =>
      'Oferta aún no lista, intenta de nuevo';

  @override
  String get audio_call_invalid_data => 'Datos de llamada no válidos';

  @override
  String audio_call_accept_error(Object error) {
    return 'Error al aceptar la llamada: $error';
  }

  @override
  String get audio_call_incoming => 'Llamada de audio entrante';

  @override
  String get audio_call_calling => 'Llamada de audio…';

  @override
  String privacy_save_error(Object error) {
    return 'Error al guardar la configuración: $error';
  }

  @override
  String privacy_load_error(Object error) {
    return 'Error al cargar privacidad: $error';
  }

  @override
  String get privacy_visibility => 'Visibilidad';

  @override
  String get privacy_online_status => 'Estado en línea';

  @override
  String get privacy_last_visit => 'Última vez';

  @override
  String get privacy_read_receipts => 'Confirmaciones de lectura';

  @override
  String get privacy_profile_info => 'Información del perfil';

  @override
  String get privacy_phone_number => 'Número de teléfono';

  @override
  String get privacy_birthday => 'Cumpleaños';

  @override
  String get privacy_about => 'Acerca de';

  @override
  String starred_load_error(Object error) {
    return 'Error al cargar destacados: $error';
  }

  @override
  String get starred_title => 'Destacados';

  @override
  String get starred_empty => 'No hay mensajes destacados en este chat';

  @override
  String get starred_message_fallback => 'Mensaje';

  @override
  String get starred_sender_you => 'Tú';

  @override
  String get starred_sender_fallback => 'Participante';

  @override
  String get starred_type_poll => 'Encuesta';

  @override
  String get starred_type_location => 'Ubicación';

  @override
  String get starred_type_attachment => 'Adjunto';

  @override
  String starred_today_prefix(Object time) {
    return 'Hoy, $time';
  }

  @override
  String get contact_edit_name_required => 'Ingresa el nombre del contacto.';

  @override
  String contact_edit_save_error(Object error) {
    return 'Error al guardar contacto: $error';
  }

  @override
  String get contact_edit_user_fallback => 'Usuario';

  @override
  String get contact_edit_first_name_hint => 'Nombre';

  @override
  String get contact_edit_last_name_hint => 'Apellido';

  @override
  String get contact_edit_description =>
      'Este nombre solo es visible para ti: en chats, búsqueda y lista de contactos.';

  @override
  String contact_edit_error(Object error) {
    return 'Error: $error';
  }

  @override
  String get voice_no_mic_access => 'Sin acceso al micrófono';

  @override
  String get voice_start_error => 'Error al iniciar la grabación';

  @override
  String get voice_file_not_received => 'Archivo de grabación no recibido';

  @override
  String get voice_stop_error => 'Error al detener la grabación';

  @override
  String get voice_title => 'Mensaje de voz';

  @override
  String get voice_recording => 'Grabando';

  @override
  String get voice_ready => 'Grabación lista';

  @override
  String get voice_stop_button => 'Detener';

  @override
  String get voice_record_again => 'Grabar de nuevo';

  @override
  String get attach_photo_video => 'Foto/Video';

  @override
  String get attach_files => 'Archivos';

  @override
  String get attach_scan => 'Escanear';

  @override
  String scanner_preview_title(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count páginas',
      one: '$count página',
    );
    return '$_temp0';
  }

  @override
  String scanner_preview_send(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Enviar $count páginas',
      one: 'Enviar página',
    );
    return '$_temp0';
  }

  @override
  String get scanner_preview_add => 'Escanear otra página';

  @override
  String get scanner_preview_retake => 'Volver a escanear';

  @override
  String get scanner_preview_delete => 'Eliminar página';

  @override
  String get scanner_preview_empty =>
      'Todas las páginas eliminadas. Toca + para escanear otra.';

  @override
  String get attach_circle => 'Circular';

  @override
  String get attach_location => 'Ubicación';

  @override
  String get attach_poll => 'Encuesta';

  @override
  String get attach_stickers => 'Pegatinas';

  @override
  String get attach_clipboard => 'Portapapeles';

  @override
  String get attach_text => 'Texto';

  @override
  String get attach_title => 'Adjuntar';

  @override
  String notif_save_error(Object error) {
    return 'Error al guardar: $error';
  }

  @override
  String get notif_title => 'Notificaciones en este chat';

  @override
  String get notif_description =>
      'Los ajustes a continuación aplican solo a esta conversación y no cambian las notificaciones globales de la app.';

  @override
  String get notif_this_chat => 'Este chat';

  @override
  String get notif_mute_title => 'Silenciar y ocultar notificaciones';

  @override
  String get notif_mute_subtitle =>
      'No molestar para este chat en este dispositivo.';

  @override
  String get notif_preview_title => 'Mostrar vista previa del texto';

  @override
  String get notif_preview_subtitle =>
      'Si se desactiva — título de la notificación sin fragmento del mensaje (donde se admita).';

  @override
  String get poll_create_enter_question => 'Ingresa una pregunta';

  @override
  String get poll_create_min_options => 'Se requieren al menos 2 opciones';

  @override
  String get poll_create_select_correct => 'Selecciona la opción correcta';

  @override
  String get poll_create_future_time => 'La hora de cierre debe ser futura';

  @override
  String get poll_create_question_label => 'Pregunta';

  @override
  String get poll_create_question_hint => 'Por ejemplo: ¿A qué hora nos vemos?';

  @override
  String get poll_create_explanation_label => 'Explicación (opcional)';

  @override
  String get poll_create_options_title => 'Opciones';

  @override
  String poll_create_option_hint(Object index) {
    return 'Opción $index';
  }

  @override
  String get poll_create_add_option => 'Agregar opción';

  @override
  String get poll_create_anonymous_title => 'Votación anónima';

  @override
  String get poll_create_anonymous_subtitle => 'No mostrar quién votó por qué';

  @override
  String get poll_create_multi_title => 'Respuestas múltiples';

  @override
  String get poll_create_multi_subtitle =>
      'Se pueden seleccionar varias opciones';

  @override
  String get poll_create_user_options_title => 'Opciones enviadas por usuarios';

  @override
  String get poll_create_user_options_subtitle =>
      'Los participantes pueden sugerir su propia opción';

  @override
  String get poll_create_revote_title => 'Permitir cambio de voto';

  @override
  String get poll_create_revote_subtitle =>
      'Se puede cambiar el voto hasta que cierre la encuesta';

  @override
  String get poll_create_shuffle_title => 'Mezclar opciones';

  @override
  String get poll_create_shuffle_subtitle =>
      'Cada participante ve un orden diferente';

  @override
  String get poll_create_quiz_title => 'Modo quiz';

  @override
  String get poll_create_quiz_subtitle => 'Una respuesta correcta';

  @override
  String get poll_create_correct_option_label => 'Opción correcta';

  @override
  String get poll_create_close_by_time => 'Cerrar por tiempo';

  @override
  String get poll_create_not_set => 'No establecido';

  @override
  String get poll_create_reset_deadline => 'Restablecer fecha límite';

  @override
  String get poll_create_publish => 'Publicar';

  @override
  String get poll_error => 'Error';

  @override
  String get poll_status_finished => 'Terminado';

  @override
  String get poll_restart => 'Reiniciar';

  @override
  String get poll_finish => 'Finalizar';

  @override
  String get poll_suggest_hint => 'Sugerir una opción';

  @override
  String get poll_voters_toggle_hide => 'Ocultar';

  @override
  String get poll_voters_toggle_show => 'Quién votó';

  @override
  String get e2ee_disable_title => '¿Desactivar cifrado?';

  @override
  String get e2ee_disable_body =>
      'Los nuevos mensajes se enviarán sin cifrado de extremo a extremo. Los mensajes cifrados enviados anteriormente permanecerán en el historial.';

  @override
  String get e2ee_disable_button => 'Desactivar';

  @override
  String e2ee_disable_error(Object error) {
    return 'Error al desactivar: $error';
  }

  @override
  String get e2ee_screen_title => 'Cifrado';

  @override
  String get e2ee_enabled_description =>
      'El cifrado de extremo a extremo está activado para este chat.';

  @override
  String get e2ee_disabled_description =>
      'El cifrado de extremo a extremo está desactivado.';

  @override
  String get e2ee_info_text =>
      'Cuando el cifrado está activado, el contenido de los nuevos mensajes solo está disponible para los participantes del chat en sus dispositivos. Desactivar solo afecta a los nuevos mensajes.';

  @override
  String get e2ee_enable_title => 'Activar cifrado';

  @override
  String e2ee_status_enabled(Object epoch) {
    return 'Activado (época de clave: $epoch)';
  }

  @override
  String get e2ee_status_disabled => 'Desactivado';

  @override
  String get e2ee_data_types_title => 'Tipos de datos';

  @override
  String get e2ee_data_types_info =>
      'Esta configuración no cambia el protocolo. Controla qué tipos de datos se envían cifrados.';

  @override
  String get e2ee_chat_settings_title =>
      'Configuración de cifrado para este chat';

  @override
  String get e2ee_chat_settings_override =>
      'Usando configuración específica del chat.';

  @override
  String get e2ee_chat_settings_global => 'Heredando configuración global.';

  @override
  String get e2ee_text_messages => 'Mensajes de texto';

  @override
  String get e2ee_attachments => 'Adjuntos (multimedia/archivos)';

  @override
  String get e2ee_override_hint =>
      'Para cambiar en este chat — activa \"Anular\".';

  @override
  String get group_member_fallback => 'Participante';

  @override
  String get group_role_creator => 'Creador del grupo';

  @override
  String get group_role_admin => 'Administrador';

  @override
  String group_total_count(Object count) {
    return 'Total: $count';
  }

  @override
  String get group_copy_invite_tooltip => 'Copiar enlace de invitación';

  @override
  String get group_add_member_tooltip => 'Agregar miembro';

  @override
  String get group_invite_copied => 'Enlace de invitación copiado';

  @override
  String group_copy_invite_error(Object error) {
    return 'Error al copiar el enlace: $error';
  }

  @override
  String get group_demote_confirm => '¿Quitar derechos de administrador?';

  @override
  String get group_promote_confirm => '¿Hacer administrador?';

  @override
  String group_demote_body(Object name) {
    return '$name perderá sus derechos de administrador. El miembro permanecerá en el grupo como miembro regular.';
  }

  @override
  String get group_demote_button => 'Quitar derechos';

  @override
  String get group_promote_button => 'Promover';

  @override
  String get group_kick_confirm => '¿Eliminar miembro?';

  @override
  String get group_kick_button => 'Eliminar';

  @override
  String get group_member_kicked => 'Miembro eliminado';

  @override
  String get group_badge_creator => 'CREADOR';

  @override
  String get group_demote_action => 'Quitar administrador';

  @override
  String get group_promote_action => 'Hacer administrador';

  @override
  String get group_kick_action => 'Eliminar del grupo';

  @override
  String group_contacts_load_error(Object error) {
    return 'Error al cargar contactos: $error';
  }

  @override
  String get group_add_members_title => 'Agregar miembros';

  @override
  String get group_search_contacts_hint => 'Buscar contactos';

  @override
  String get group_all_contacts_in_group =>
      'Todos tus contactos ya están en el grupo.';

  @override
  String get group_nobody_found => 'No se encontró a nadie.';

  @override
  String get group_user_fallback => 'Usuario';

  @override
  String get group_select_members => 'Seleccionar miembros';

  @override
  String group_add_count(Object count) {
    return 'Agregar ($count)';
  }

  @override
  String group_auth_error(Object error) {
    return 'Error de autorización: $error';
  }

  @override
  String group_add_error(Object error) {
    return 'Error al agregar miembros: $error';
  }

  @override
  String get add_contact_own_profile => 'Este es tu propio perfil';

  @override
  String get add_contact_qr_not_found => 'Perfil del código QR no encontrado';

  @override
  String add_contact_qr_error(Object error) {
    return 'Error al leer el código QR: $error';
  }

  @override
  String get add_contact_not_allowed => 'No se puede agregar a este usuario';

  @override
  String add_contact_save_error(Object error) {
    return 'Error al agregar contacto: $error';
  }

  @override
  String get add_contact_country_search => 'Buscar por país o código';

  @override
  String get add_contact_sync_phone => 'Sincronizar con teléfono';

  @override
  String get add_contact_qr_button => 'Agregar por código QR';

  @override
  String add_contact_load_error(Object error) {
    return 'Error al cargar contacto: $error';
  }

  @override
  String get add_contact_user_fallback => 'Usuario';

  @override
  String get add_contact_already_in_contacts => 'Ya está en contactos';

  @override
  String get add_contact_new => 'Nuevo contacto';

  @override
  String get add_contact_unavailable => 'No disponible';

  @override
  String get add_contact_scan_qr => 'Escanear código QR';

  @override
  String get add_contact_scan_hint =>
      'Apunta la cámara al código QR de perfil de LighChat';

  @override
  String get auth_validate_name_min_length =>
      'El nombre debe tener al menos 2 caracteres';

  @override
  String get auth_validate_username_min_length =>
      'El nombre de usuario debe tener al menos 3 caracteres';

  @override
  String get auth_validate_username_max_length =>
      'El nombre de usuario no debe exceder 30 caracteres';

  @override
  String get auth_validate_username_format =>
      'El nombre de usuario contiene caracteres no válidos';

  @override
  String get auth_validate_phone_11_digits =>
      'El número de teléfono debe contener 11 dígitos';

  @override
  String get auth_validate_email_format =>
      'Ingresa un correo electrónico válido';

  @override
  String get auth_validate_dob_invalid => 'Fecha de nacimiento no válida';

  @override
  String get auth_validate_bio_max_length =>
      'La biografía no debe exceder 200 caracteres';

  @override
  String get auth_validate_password_min_length =>
      'La contraseña debe tener al menos 6 caracteres';

  @override
  String get auth_validate_passwords_mismatch => 'Las contraseñas no coinciden';

  @override
  String get sticker_new_pack => 'Nuevo paquete…';

  @override
  String get sticker_select_image_or_gif => 'Selecciona una imagen o GIF';

  @override
  String sticker_send_error(Object error) {
    return 'Error al enviar: $error';
  }

  @override
  String get sticker_saved => 'Guardado en paquete de stickers';

  @override
  String get sticker_save_failed => 'Error al descargar o guardar el GIF';

  @override
  String get sticker_tab_my => 'Mío';

  @override
  String get sticker_tab_shared => 'Compartidos';

  @override
  String get sticker_no_packs => 'Sin paquetes de stickers. Crea uno nuevo.';

  @override
  String get sticker_shared_not_configured =>
      'Paquetes compartidos no configurados';

  @override
  String get sticker_recent => 'RECIENTES';

  @override
  String get sticker_gallery_description =>
      'Fotos, PNG, GIF del dispositivo — directo al chat';

  @override
  String get sticker_shared_unavailable =>
      'Paquetes compartidos aún no disponibles';

  @override
  String get sticker_gif_search_hint => 'Buscar GIF…';

  @override
  String sticker_gif_searched(Object query) {
    return 'Buscado: $query';
  }

  @override
  String get sticker_gif_search_unavailable =>
      'Búsqueda de GIF temporalmente no disponible.';

  @override
  String get sticker_gif_nothing_found => 'No se encontró nada';

  @override
  String get sticker_gif_all => 'Todos';

  @override
  String get sticker_gif_animated => 'ANIMADOS';

  @override
  String get sticker_emoji_text_unavailable =>
      'Emoji de texto no disponible para esta ventana.';

  @override
  String get wallpaper_sender => 'Contacto';

  @override
  String get wallpaper_incoming => 'Este es un mensaje entrante.';

  @override
  String get wallpaper_outgoing => 'Este es un mensaje saliente.';

  @override
  String get wallpaper_incoming_time => '11:40';

  @override
  String get wallpaper_outgoing_time => '11:41';

  @override
  String get wallpaper_system => 'Cambiaste el fondo del chat';

  @override
  String get wallpaper_you => 'Tú';

  @override
  String get wallpaper_today => 'Hoy';

  @override
  String system_event_e2ee_enabled(Object epoch) {
    return 'Cifrado de extremo a extremo activado (época de clave: $epoch)';
  }

  @override
  String get system_event_e2ee_disabled =>
      'Cifrado de extremo a extremo desactivado';

  @override
  String get system_event_unknown => 'Evento del sistema';

  @override
  String get system_event_group_created => 'Grupo creado';

  @override
  String system_event_member_added(Object name) {
    return '$name fue agregado';
  }

  @override
  String system_event_member_removed(Object name) {
    return '$name fue eliminado';
  }

  @override
  String system_event_member_left(Object name) {
    return '$name dejó el grupo';
  }

  @override
  String system_event_name_changed(Object name) {
    return 'Nombre cambiado a \"$name\"';
  }

  @override
  String get image_editor_title => 'Editor';

  @override
  String get image_editor_undo => 'Deshacer';

  @override
  String get image_editor_clear => 'Borrar';

  @override
  String get image_editor_pen => 'Pincel';

  @override
  String get image_editor_text => 'Texto';

  @override
  String get image_editor_crop => 'Recortar';

  @override
  String get image_editor_rotate => 'Rotar';

  @override
  String get location_title => 'Enviar ubicación';

  @override
  String get location_loading => 'Cargando mapa…';

  @override
  String get location_send_button => 'Enviar';

  @override
  String get location_live_label => 'En vivo';

  @override
  String get location_error => 'Error al cargar el mapa';

  @override
  String get location_no_permission => 'Sin acceso a la ubicación';

  @override
  String get group_member_admin => 'Administración';

  @override
  String get group_member_creator => 'Creador';

  @override
  String get group_member_member => 'Miembro';

  @override
  String get group_member_open_chat => 'Mensaje';

  @override
  String get group_member_open_profile => 'Perfil';

  @override
  String get group_member_remove => 'Eliminar';

  @override
  String get durak_lobby_title => 'Durak';

  @override
  String get durak_lobby_new_game => 'Nuevo juego';

  @override
  String get durak_lobby_decline => 'Rechazar';

  @override
  String get durak_lobby_accept => 'Aceptar';

  @override
  String get durak_lobby_invite_sent => 'Invitación enviada';

  @override
  String get voice_preview_cancel => 'Cancelar';

  @override
  String get voice_preview_send => 'Enviar';

  @override
  String get voice_preview_recorded => 'Grabado';

  @override
  String get voice_preview_playing => 'Reproduciendo…';

  @override
  String get voice_preview_paused => 'Pausado';

  @override
  String get group_avatar_camera => 'Cámara';

  @override
  String get group_avatar_gallery => 'Galería';

  @override
  String get group_avatar_upload_error => 'Error al subir';

  @override
  String get avatar_picker_title => 'Avatar';

  @override
  String get avatar_picker_camera => 'Cámara';

  @override
  String get avatar_picker_gallery => 'Galería';

  @override
  String get avatar_picker_crop => 'Recortar';

  @override
  String get avatar_picker_save => 'Guardar';

  @override
  String get avatar_picker_remove => 'Eliminar avatar';

  @override
  String get avatar_picker_error => 'Error al cargar el avatar';

  @override
  String get avatar_picker_crop_error => 'Error al recortar';

  @override
  String get webview_telegram_title => 'Iniciar sesión con Telegram';

  @override
  String get webview_telegram_loading => 'Cargando…';

  @override
  String get webview_telegram_error => 'Error al cargar la página';

  @override
  String get webview_telegram_back => 'Atrás';

  @override
  String get webview_telegram_retry => 'Reintentar';

  @override
  String get webview_telegram_close => 'Cerrar';

  @override
  String get webview_telegram_no_url => 'No se proporcionó URL de autorización';

  @override
  String get webview_yandex_title => 'Iniciar sesión con Yandex';

  @override
  String get webview_yandex_loading => 'Cargando…';

  @override
  String get webview_yandex_error => 'Error al cargar la página';

  @override
  String get webview_yandex_back => 'Atrás';

  @override
  String get webview_yandex_retry => 'Reintentar';

  @override
  String get webview_yandex_close => 'Cerrar';

  @override
  String get webview_yandex_no_url => 'No se proporcionó URL de autorización';

  @override
  String get google_profile_title => 'Completa tu perfil';

  @override
  String get google_profile_name => 'Nombre';

  @override
  String get google_profile_username => 'Nombre de usuario';

  @override
  String get google_profile_phone => 'Teléfono';

  @override
  String get google_profile_email => 'Correo electrónico';

  @override
  String get google_profile_dob => 'Fecha de nacimiento';

  @override
  String get google_profile_bio => 'Acerca de';

  @override
  String get google_profile_save => 'Guardar';

  @override
  String get google_profile_error => 'Error al guardar el perfil';

  @override
  String get system_event_e2ee_epoch_rotated => 'Clave de cifrado rotada';

  @override
  String system_event_e2ee_device_added(String actor, String device) {
    return '$actor agregó el dispositivo \"$device\"';
  }

  @override
  String system_event_e2ee_device_revoked(String actor, String device) {
    return '$actor revocó el dispositivo \"$device\"';
  }

  @override
  String system_event_e2ee_fingerprint_changed(String actor) {
    return 'La huella de seguridad de $actor cambió';
  }

  @override
  String get system_event_game_lobby_created => 'Sala de juego creada';

  @override
  String get system_event_game_started => 'Juego iniciado';

  @override
  String get system_event_call_missed => 'Llamada perdida';

  @override
  String get system_event_call_cancelled => 'Llamada rechazada';

  @override
  String get system_event_default_actor => 'Usuario';

  @override
  String get system_event_default_device => 'dispositivo';

  @override
  String get image_editor_add_caption => 'Agregar descripción...';

  @override
  String get image_editor_crop_failed => 'Error al recortar la imagen';

  @override
  String get image_editor_draw_hint =>
      'Modo de dibujo: desliza sobre la imagen';

  @override
  String get image_editor_crop_title => 'Recortar';

  @override
  String get location_preview_title => 'Ubicación';

  @override
  String get location_preview_accuracy_unknown => 'Precisión: —';

  @override
  String location_preview_accuracy_meters(String meters) {
    return 'Precisión: ~$meters m';
  }

  @override
  String location_preview_accuracy_km(String km) {
    return 'Precisión: ~$km km';
  }

  @override
  String get group_member_profile_default_name => 'Miembro';

  @override
  String get group_member_profile_dm => 'Enviar mensaje directo';

  @override
  String get group_member_profile_dm_hint =>
      'Abrir un chat directo con este miembro';

  @override
  String group_member_profile_dm_failed(Object error) {
    return 'Error al abrir el chat directo: $error';
  }

  @override
  String get conversation_game_lobby_unavailable =>
      'Juego no disponible o eliminado';

  @override
  String get conversation_game_lobby_back => 'Atrás';

  @override
  String get conversation_game_lobby_waiting =>
      'Esperando a que el oponente se una…';

  @override
  String get conversation_game_lobby_start_game => 'Iniciar juego';

  @override
  String get conversation_game_lobby_waiting_short => 'Esperando…';

  @override
  String get conversation_game_lobby_ready => 'Listo';

  @override
  String get voice_preview_trim_confirm_title =>
      '¿Mantener solo el fragmento seleccionado?';

  @override
  String get voice_preview_trim_confirm_body =>
      'Todo excepto el fragmento seleccionado se eliminará. La grabación continuará inmediatamente después de presionar el botón.';

  @override
  String get voice_preview_continue => 'Continuar';

  @override
  String get voice_preview_continue_recording => 'Continuar grabando';

  @override
  String get group_avatar_change_short => 'Cambiar';

  @override
  String get avatar_picker_cancel => 'Cancelar';

  @override
  String get avatar_picker_choose => 'Elegir avatar';

  @override
  String get avatar_picker_delete_photo => 'Eliminar foto';

  @override
  String get avatar_picker_loading => 'Cargando…';

  @override
  String get avatar_picker_choose_avatar => 'Elegir avatar';

  @override
  String get avatar_picker_change_avatar => 'Cambiar avatar';

  @override
  String get avatar_picker_remove_tooltip => 'Eliminar';

  @override
  String get telegram_sign_in_title => 'Iniciar sesión con Telegram';

  @override
  String get telegram_sign_in_open_in_browser => 'Abrir en navegador';

  @override
  String get telegram_sign_in_open_telegram_failed =>
      'Error al abrir Telegram. Por favor instala la app de Telegram.';

  @override
  String get telegram_sign_in_page_load_error => 'Error al cargar la página';

  @override
  String get telegram_sign_in_login_error =>
      'Error de inicio de sesión con Telegram.';

  @override
  String get telegram_sign_in_firebase_not_ready => 'Firebase no está listo.';

  @override
  String get telegram_sign_in_browser_failed => 'Error al abrir el navegador.';

  @override
  String telegram_sign_in_login_failed(Object error) {
    return 'Error al iniciar sesión: $error';
  }

  @override
  String get yandex_sign_in_title => 'Iniciar sesión con Yandex';

  @override
  String get yandex_sign_in_open_in_browser => 'Abrir en navegador';

  @override
  String get yandex_sign_in_page_load_error => 'Error al cargar la página';

  @override
  String get yandex_sign_in_login_error =>
      'Error de inicio de sesión con Yandex.';

  @override
  String get yandex_sign_in_firebase_not_ready => 'Firebase no está listo.';

  @override
  String get yandex_sign_in_browser_failed => 'Error al abrir el navegador.';

  @override
  String yandex_sign_in_login_failed(Object error) {
    return 'Error al iniciar sesión: $error';
  }

  @override
  String get google_complete_title => 'Completar registro';

  @override
  String get google_complete_subtitle =>
      'Después de iniciar sesión con Google, completa tu perfil como en la versión web.';

  @override
  String get google_complete_name_label => 'Nombre';

  @override
  String get google_complete_username_label => 'Nombre de usuario (@usuario)';

  @override
  String get google_complete_phone_label => 'Teléfono (11 dígitos)';

  @override
  String get google_complete_email_label => 'Correo electrónico';

  @override
  String get google_complete_email_hint => 'tu@ejemplo.com';

  @override
  String get google_complete_dob_label =>
      'Fecha de nacimiento (AAAA-MM-DD, opcional)';

  @override
  String get google_complete_bio_label =>
      'Acerca de (hasta 200 caracteres, opcional)';

  @override
  String get google_complete_save => 'Guardar y continuar';

  @override
  String get google_complete_back => 'Volver a iniciar sesión';

  @override
  String get game_error_defense_not_beat =>
      'Esta carta no gana a la carta de ataque';

  @override
  String get game_error_attacker_first => 'El atacante mueve primero';

  @override
  String get game_error_defender_no_attack =>
      'El defensor no puede atacar ahora';

  @override
  String get game_error_not_allowed_throwin => 'No puedes lanzar en esta ronda';

  @override
  String get game_error_throwin_not_turn => 'Otro jugador está lanzando ahora';

  @override
  String get game_error_rank_not_allowed =>
      'Solo puedes lanzar una carta del mismo rango';

  @override
  String get game_error_cannot_throw_in => 'No se pueden lanzar más cartas';

  @override
  String get game_error_card_not_in_hand => 'Esta carta ya no está en tu mano';

  @override
  String get game_error_already_defended => 'Esta carta ya está defendida';

  @override
  String get game_error_bad_attack_index =>
      'Selecciona una carta de ataque para defender';

  @override
  String get game_error_only_defender => 'Otro jugador está defendiendo ahora';

  @override
  String get game_error_defender_taking => 'El defensor ya está tomando cartas';

  @override
  String get game_error_game_not_active => 'El juego ya no está activo';

  @override
  String get game_error_not_in_lobby => 'La sala ya ha iniciado';

  @override
  String get game_error_game_already_active => 'El juego ya ha iniciado';

  @override
  String get game_error_active_exists => 'Ya hay un juego activo en este chat';

  @override
  String get game_error_round_pending =>
      'Termina primero el movimiento disputado';

  @override
  String get game_error_rematch_failed =>
      'Error al preparar la revancha. Intenta de nuevo';

  @override
  String get game_error_unauthenticated => 'Necesitas iniciar sesión';

  @override
  String get game_error_permission_denied =>
      'Esta acción no está disponible para ti';

  @override
  String get game_error_invalid_argument => 'Movimiento no válido';

  @override
  String get game_error_precondition =>
      'El movimiento no está disponible en este momento';

  @override
  String get game_error_server =>
      'Error al hacer el movimiento. Intenta de nuevo';

  @override
  String get reply_sticker => 'Etiqueta engomada';

  @override
  String get reply_gif => 'GIF';

  @override
  String get reply_video_circle => 'Video circular';

  @override
  String get reply_voice_message => 'Mensaje de voz';

  @override
  String get reply_video => 'Video';

  @override
  String get reply_photo => 'Foto';

  @override
  String get reply_file => 'Archivo';

  @override
  String get reply_location => 'Ubicación';

  @override
  String get reply_poll => 'Encuesta';

  @override
  String get reply_link => 'Enlace';

  @override
  String get reply_message => 'Mensaje';

  @override
  String get reply_sender_you => 'Tú';

  @override
  String get reply_sender_member => 'Miembro';

  @override
  String get call_format_today => 'Hoy';

  @override
  String get call_format_yesterday => 'Ayer';

  @override
  String get call_format_second_short => 's';

  @override
  String get call_format_minute_short => 'metro';

  @override
  String get call_format_hour_short => 'h';

  @override
  String get call_format_day_short => 'd';

  @override
  String get call_month_january => 'Enero';

  @override
  String get call_month_february => 'Febrero';

  @override
  String get call_month_march => 'Marzo';

  @override
  String get call_month_april => 'Abril';

  @override
  String get call_month_may => 'Mayo';

  @override
  String get call_month_june => 'Junio';

  @override
  String get call_month_july => 'Julio';

  @override
  String get call_month_august => 'Agosto';

  @override
  String get call_month_september => 'Septiembre';

  @override
  String get call_month_october => 'Octubre';

  @override
  String get call_month_november => 'Noviembre';

  @override
  String get call_month_december => 'Diciembre';

  @override
  String get push_incoming_call => 'Llamada entrante';

  @override
  String get push_incoming_video_call => 'Videollamada entrante';

  @override
  String get push_new_message => 'Nuevo mensaje';

  @override
  String get push_channel_calls => 'Llamadas';

  @override
  String get push_channel_messages => 'Mensajes';

  @override
  String contacts_years_one(Object count) {
    return '$count año';
  }

  @override
  String contacts_years_few(Object count) {
    return '$count años';
  }

  @override
  String contacts_years_many(Object count) {
    return '$count años';
  }

  @override
  String contacts_years_other(Object count) {
    return '$count años';
  }

  @override
  String get durak_entry_single_game => 'Juego individual';

  @override
  String get durak_entry_finish_game_tooltip => 'Terminar juego';

  @override
  String get durak_entry_tournament_games_dialog_title =>
      '¿Cuántos juegos en el torneo?';

  @override
  String get durak_entry_cancel => 'Cancelar';

  @override
  String get durak_entry_create => 'Crear';

  @override
  String video_editor_load_failed(Object error) {
    return 'Error al cargar el video: $error';
  }

  @override
  String video_editor_process_failed(Object error) {
    return 'Error al procesar el video: $error';
  }

  @override
  String video_editor_duration(Object duration) {
    return 'Duración: $duration';
  }

  @override
  String get video_editor_brush => 'Pincel';

  @override
  String get video_editor_caption_hint => 'Agregar descripción...';

  @override
  String get video_effects_speed => 'Velocidad';

  @override
  String get video_filter_none => 'Original';

  @override
  String get video_filter_enhance => 'Realzar';

  @override
  String get share_location_title => 'Compartir ubicación';

  @override
  String get share_location_how => 'Método de compartir';

  @override
  String get share_location_cancel => 'Cancelar';

  @override
  String get share_location_send => 'Enviar';

  @override
  String get photo_source_gallery => 'Galería';

  @override
  String get photo_source_take_photo => 'Tomar foto';

  @override
  String get photo_source_record_video => 'Grabar video';

  @override
  String get video_attachment_media_kind => 'video';

  @override
  String get video_attachment_title => 'Video';

  @override
  String get video_attachment_playback_error =>
      'No se puede reproducir el video. Verifica el enlace y la conexión de red.';

  @override
  String get location_card_broadcast_ended_mine =>
      'La transmisión de ubicación finalizó. La otra persona ya no puede ver tu ubicación actual.';

  @override
  String get location_card_broadcast_ended_other =>
      'La transmisión de ubicación de este contacto ha finalizado. La posición actual no está disponible.';

  @override
  String get location_card_title => 'Ubicación';

  @override
  String location_card_accuracy(Object meters) {
    return '±$meters m';
  }

  @override
  String get link_webview_copy_tooltip => 'Copiar enlace';

  @override
  String get link_webview_copied_snackbar => 'Enlace copiado';

  @override
  String get link_webview_open_browser_tooltip => 'Abrir en navegador';

  @override
  String get hold_record_pause => 'Pausado';

  @override
  String get hold_record_release_cancel => 'Suelta para cancelar';

  @override
  String get hold_record_slide_hints =>
      'Desliza izquierda — cancelar · Arriba — pausar';

  @override
  String get e2ee_badge_loading => 'Cargando huella digital…';

  @override
  String e2ee_badge_error(Object error) {
    return 'Error al obtener la huella digital: $error';
  }

  @override
  String get e2ee_badge_label => 'Huella digital E2EE';

  @override
  String e2ee_badge_label_with_user(Object user) {
    return 'Huella digital E2EE • $user';
  }

  @override
  String e2ee_badge_devices(Object count) {
    return '$count disp.';
  }

  @override
  String get composer_link_cancel => 'Cancelar';

  @override
  String message_search_results_count(Object count) {
    return 'RESULTADOS DE BÚSQUEDA: $count';
  }

  @override
  String get message_search_not_found => 'NADA ENCONTRADO';

  @override
  String get message_search_participant_fallback => 'Participante';

  @override
  String get wallpaper_purple => 'Púrpura';

  @override
  String get wallpaper_pink => 'Rosa';

  @override
  String get wallpaper_blue => 'Azul';

  @override
  String get wallpaper_green => 'Verde';

  @override
  String get wallpaper_sunset => 'Atardecer';

  @override
  String get wallpaper_tender => 'Suave';

  @override
  String get wallpaper_lime => 'Lima';

  @override
  String get wallpaper_graphite => 'Grafito';

  @override
  String get avatar_crop_title => 'Ajustar avatar';

  @override
  String get avatar_crop_hint =>
      'Arrastra y haz zoom — el círculo aparecerá en listas y mensajes; el marco completo se queda para el perfil.';

  @override
  String get avatar_crop_cancel => 'Cancelar';

  @override
  String get avatar_crop_reset => 'Restablecer';

  @override
  String get avatar_crop_save => 'Guardar';

  @override
  String get meeting_entry_connecting => 'Conectando a la reunión…';

  @override
  String meeting_entry_auth_failed(Object error) {
    return 'Error al iniciar sesión: $error';
  }

  @override
  String get meeting_entry_participant_fallback => 'Participante';

  @override
  String get meeting_entry_back => 'Atrás';

  @override
  String get meeting_chat_copy => 'Copiar';

  @override
  String get meeting_chat_edit => 'Editar';

  @override
  String get meeting_chat_delete => 'Eliminar';

  @override
  String get meeting_chat_deleted => 'Mensaje eliminado';

  @override
  String get meeting_chat_edited_mark => '• editado';

  @override
  String get meeting_chat_reply => 'Responder';

  @override
  String get meeting_chat_react => 'Reaccionar';

  @override
  String get meeting_chat_copied => 'Copiado';

  @override
  String get meeting_chat_editing => 'Editando';

  @override
  String meeting_chat_reply_to(Object name) {
    return 'Responder a $name';
  }

  @override
  String get meeting_chat_attachment_placeholder => 'Adjunto';

  @override
  String meeting_timer_remaining(Object time) {
    return 'Quedan $time';
  }

  @override
  String meeting_timer_elapsed(Object time) {
    return '$time';
  }

  @override
  String get meeting_back_to_chats => 'Regresar a los chats';

  @override
  String get meeting_open_chats => 'Abrir chats';

  @override
  String get meeting_in_call_chat => 'Chat en la llamada';

  @override
  String get meeting_lobby_open_settings => 'Abrir ajustes';

  @override
  String get meeting_lobby_retry => 'Reintentar';

  @override
  String get meeting_minimized_resume => 'Toca para regresar a la llamada';

  @override
  String get e2ee_decrypt_image_failed => 'Error al descifrar imagen';

  @override
  String get e2ee_decrypt_video_failed => 'Error al descifrar video';

  @override
  String get e2ee_decrypt_audio_failed => 'Error al descifrar audio';

  @override
  String get e2ee_decrypt_attachment_failed => 'Error al descifrar adjunto';

  @override
  String get search_preview_attachment => 'Adjunto';

  @override
  String get search_preview_location => 'Ubicación';

  @override
  String get search_preview_message => 'Mensaje';

  @override
  String get outbox_attachment_singular => 'Adjunto';

  @override
  String outbox_attachments_count(int count) {
    return 'Adjuntos ($count)';
  }

  @override
  String get outbox_chat_unavailable => 'Servicio de chat no disponible';

  @override
  String outbox_encryption_error(String code) {
    return 'Cifrado: $code';
  }

  @override
  String get nav_chats => 'Charlas';

  @override
  String get nav_contacts => 'Contactos';

  @override
  String get nav_meetings => 'Reuniones';

  @override
  String get nav_calls => 'Llamadas';

  @override
  String get e2ee_media_decrypt_failed_image => 'Error al descifrar imagen';

  @override
  String get e2ee_media_decrypt_failed_video => 'Error al descifrar video';

  @override
  String get e2ee_media_decrypt_failed_audio => 'Error al descifrar audio';

  @override
  String get e2ee_media_decrypt_failed_attachment =>
      'Error al descifrar adjunto';

  @override
  String get chat_search_snippet_attachment => 'Adjunto';

  @override
  String get chat_search_snippet_location => 'Ubicación';

  @override
  String get chat_search_snippet_message => 'Mensaje';

  @override
  String get bottom_nav_chats => 'Charlas';

  @override
  String get bottom_nav_contacts => 'Contactos';

  @override
  String get bottom_nav_meetings => 'Reuniones';

  @override
  String get bottom_nav_calls => 'Llamadas';

  @override
  String get chat_list_swipe_folders => 'CARPETAS';

  @override
  String get chat_list_swipe_clear => 'BORRAR';

  @override
  String get chat_list_swipe_delete => 'ELIMINAR';

  @override
  String get composer_editing_title => 'EDITANDO MENSAJE';

  @override
  String get composer_editing_cancel_tooltip => 'Cancelar edición';

  @override
  String get composer_formatting_title => 'FORMATO';

  @override
  String get composer_link_preview_loading => 'Cargando vista previa…';

  @override
  String get composer_link_preview_hide_tooltip => 'Ocultar vista previa';

  @override
  String get chat_invite_button => 'Invitar';

  @override
  String get forward_preview_unknown_sender => 'Desconocido';

  @override
  String get forward_preview_attachment => 'Adjunto';

  @override
  String get forward_preview_message => 'Mensaje';

  @override
  String get chat_mention_no_matches => 'Sin coincidencias';

  @override
  String get live_location_sharing => 'Estás compartiendo tu ubicación';

  @override
  String get live_location_stop => 'Detener';

  @override
  String get chat_message_deleted => 'Mensaje eliminado';

  @override
  String get profile_qr_share => 'Compartir';

  @override
  String get shared_location_open_browser_tooltip => 'Abrir en navegador';

  @override
  String get reply_preview_message_fallback => 'Mensaje';

  @override
  String get video_circle_media_kind => 'video';

  @override
  String reactions_rated_count(int count) {
    return 'Reaccionaron: $count';
  }

  @override
  String reactions_today_time(String time) {
    return 'Hoy, $time';
  }

  @override
  String get durak_create_timer_subtitle => '15 segundos por defecto';

  @override
  String get dm_game_banner_active => 'Juego de Durak en progreso';

  @override
  String get dm_game_banner_created => 'Juego de Durak creado';

  @override
  String get chat_folder_favorites => 'Favoritos';

  @override
  String get chat_folder_new => 'Nuevos';

  @override
  String get contact_profile_user_fallback => 'Usuario';

  @override
  String contact_profile_error(String error) {
    return 'Error: $error';
  }

  @override
  String get conversation_threads_loading_title => 'Hilos';

  @override
  String get theme_label_light => 'Claro';

  @override
  String get theme_label_dark => 'Oscuro';

  @override
  String get theme_label_auto => 'Auto';

  @override
  String get chat_draft_reply_fallback => 'Responder';

  @override
  String get mention_default_label => 'Miembro';

  @override
  String get contacts_fallback_name => 'Contacto';

  @override
  String get sticker_pack_default_name => 'Mi paquete';

  @override
  String get profile_error_phone_taken =>
      'Este número de teléfono ya está registrado. Por favor usa un número diferente.';

  @override
  String get profile_error_email_taken =>
      'Este correo ya está en uso. Por favor usa una dirección diferente.';

  @override
  String get profile_error_username_taken =>
      'Este nombre de usuario ya está en uso. Por favor elige otro.';

  @override
  String get e2ee_banner_default_context => 'Mensaje';

  @override
  String e2ee_banner_encrypted_chat_web_only(String prefix) {
    return '$prefix a un chat cifrado solo se puede enviar desde el cliente web por ahora.';
  }

  @override
  String get chat_attachment_decrypt_error => 'Error al descifrar adjunto';

  @override
  String get mention_fallback_label => 'miembro';

  @override
  String get mention_fallback_label_capitalized => 'Miembro';

  @override
  String get meeting_speaking_label => 'Hablando';

  @override
  String meeting_local_you_suffix(String name) {
    return '$name (Tú)';
  }

  @override
  String get video_crop_title => 'Recortar';

  @override
  String video_crop_load_error(String error) {
    return 'Error al cargar el video: $error';
  }

  @override
  String get gif_section_recent => 'RECIENTES';

  @override
  String get gif_section_trending => 'TENDENCIAS';

  @override
  String get auth_create_account_title => 'Crear cuenta';

  @override
  String yandex_sign_in_yandex_error(String error) {
    return 'Yandex: $error';
  }

  @override
  String get call_status_missed => 'Perdida';

  @override
  String get call_status_cancelled => 'Cancelada';

  @override
  String get call_status_ended => 'Finalizada';

  @override
  String get presence_offline => 'Sin conexión';

  @override
  String get presence_online => 'En línea';

  @override
  String get dm_title_fallback => 'Charlar';

  @override
  String get dm_title_partner_fallback => 'Contacto';

  @override
  String get group_title_fallback => 'Chat grupal';

  @override
  String get block_call_viewer_blocked =>
      'Bloqueaste a este usuario. Llamada no disponible — desbloquea en Perfil → Bloqueados.';

  @override
  String get block_call_partner_blocked =>
      'Este usuario restringió la comunicación contigo. Llamada no disponible.';

  @override
  String get block_call_unavailable => 'Llamada no disponible.';

  @override
  String get block_composer_viewer_blocked =>
      'Bloqueaste a este usuario. Envío no disponible — desbloquea en Perfil → Bloqueados.';

  @override
  String get block_composer_partner_blocked =>
      'Este usuario restringió la comunicación contigo. Envío no disponible.';

  @override
  String get forward_group_fallback => 'Grupo';

  @override
  String get forward_unknown_user => 'Desconocido';

  @override
  String get live_location_once => 'Una vez (solo este mensaje)';

  @override
  String get live_location_5min => '5 minutos';

  @override
  String get live_location_15min => '15 minutos';

  @override
  String get live_location_30min => '30 minutos';

  @override
  String get live_location_1hour => '1 hora';

  @override
  String get live_location_2hours => '2 horas';

  @override
  String get live_location_6hours => '6 horas';

  @override
  String get live_location_1day => '1 día';

  @override
  String get live_location_forever => 'Para siempre (hasta que lo desactive)';

  @override
  String get e2ee_send_too_many_files =>
      'Demasiados adjuntos para envío cifrado: máximo 5 archivos por mensaje.';

  @override
  String get e2ee_send_too_large =>
      'Tamaño total de adjuntos demasiado grande: máximo 96 MB por mensaje cifrado.';

  @override
  String get presence_last_seen_prefix => 'Visto por última vez ';

  @override
  String get presence_less_than_minute_ago => 'hace menos de un minuto';

  @override
  String get presence_yesterday => 'ayer';

  @override
  String get dm_fallback_title => 'Charlar';

  @override
  String get dm_fallback_partner => 'Contacto';

  @override
  String get group_fallback_title => 'Chat grupal';

  @override
  String get block_send_viewer_blocked =>
      'Bloqueaste a este usuario. Envío no disponible — desbloquea en Perfil → Bloqueados.';

  @override
  String get block_send_partner_blocked =>
      'Este usuario restringió la comunicación contigo. Envío no disponible.';

  @override
  String get mention_fallback_name => 'Miembro';

  @override
  String get profile_conflict_phone =>
      'Este número de teléfono ya está registrado. Por favor usa un número diferente.';

  @override
  String get profile_conflict_email =>
      'Este correo ya está en uso. Por favor usa una dirección diferente.';

  @override
  String get profile_conflict_username =>
      'Este nombre de usuario ya está en uso. Por favor elige uno diferente.';

  @override
  String get mention_fallback_participant => 'Participante';

  @override
  String get sticker_gif_recent => 'RECIENTES';

  @override
  String get meeting_screen_sharing => 'Pantalla';

  @override
  String get meeting_speaking => 'Hablando';

  @override
  String auth_sign_in_failed(Object error) {
    return 'Error al iniciar sesión: $error';
  }

  @override
  String yandex_error_prefix(Object error) {
    return 'Yandex: $error';
  }

  @override
  String auth_error_prefix(Object error) {
    return 'Error de autenticación: $error';
  }

  @override
  String presence_minutes_ago(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace $count minutos',
      one: 'hace un minuto',
    );
    return '$_temp0';
  }

  @override
  String presence_hours_ago(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace $count horas',
      one: 'hace una hora',
    );
    return '$_temp0';
  }

  @override
  String presence_days_ago(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace $count días',
      one: 'hace un día',
    );
    return '$_temp0';
  }

  @override
  String presence_months_ago(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace $count meses',
      one: 'hace un mes',
    );
    return '$_temp0';
  }

  @override
  String presence_years_months_ago(int years, int months) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years años',
      one: '1 año',
    );
    String _temp1 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: 'hace $months meses',
      one: 'hace 1 mes',
    );
    return '$_temp0 $_temp1';
  }

  @override
  String presence_years_ago(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace $count años',
      one: 'hace un año',
    );
    return '$_temp0';
  }

  @override
  String get wallpaper_gradient_purple => 'Púrpura';

  @override
  String get wallpaper_gradient_pink => 'Rosa';

  @override
  String get wallpaper_gradient_blue => 'Azul';

  @override
  String get wallpaper_gradient_green => 'Verde';

  @override
  String get wallpaper_gradient_sunset => 'Atardecer';

  @override
  String get wallpaper_gradient_gentle => 'Suave';

  @override
  String get wallpaper_gradient_lime => 'Lima';

  @override
  String get wallpaper_gradient_graphite => 'Grafito';

  @override
  String get sticker_tab_recent => 'RECIENTES';

  @override
  String get block_call_you_blocked =>
      'Bloqueaste a este usuario. Llamada no disponible — desbloquea en Perfil → Bloqueados.';

  @override
  String get block_call_they_blocked =>
      'Este usuario restringió la comunicación contigo. Llamada no disponible.';

  @override
  String get block_call_generic => 'Llamada no disponible.';

  @override
  String get block_send_you_blocked =>
      'Bloqueaste a este usuario. Envío no disponible — desbloquea en Perfil → Bloqueados.';

  @override
  String get block_send_they_blocked =>
      'Este usuario restringió la comunicación contigo. Envío no disponible.';

  @override
  String get forward_unknown_fallback => 'Desconocido';

  @override
  String get dm_title_chat => 'Charlar';

  @override
  String get dm_title_partner => 'Compañero';

  @override
  String get dm_title_group => 'Chat grupal';

  @override
  String get e2ee_too_many_attachments =>
      'Demasiados adjuntos para envío cifrado: máximo 5 archivos por mensaje.';

  @override
  String get e2ee_total_size_exceeded =>
      'Tamaño total de adjuntos demasiado grande: máximo 96 MB por mensaje cifrado.';

  @override
  String composer_limit_too_many_files(int current, int max, int diff) {
    return 'Demasiados adjuntos: $current/$max. Elimina $diff para enviar.';
  }

  @override
  String composer_limit_total_size_exceeded(String currentMb, String maxMb) {
    return 'Adjuntos demasiado grandes: $currentMb MB / $maxMb MB. Elimina algunos para enviar.';
  }

  @override
  String get composer_limit_blocking_send => 'Límite de adjuntos superado';

  @override
  String yandex_sign_in_error_prefix(String error) {
    return 'Yandex: $error';
  }

  @override
  String get meeting_participant_screen => 'Pantalla';

  @override
  String get meeting_participant_speaking => 'Hablando';

  @override
  String get nav_error_title => 'Error de navegación';

  @override
  String get nav_error_invalid_secret_compose =>
      'Navegación de composición secreta no válida';

  @override
  String get sign_in_title => 'Iniciar sesión';

  @override
  String get sign_in_firebase_ready =>
      'Firebase inicializado. Puedes iniciar sesión.';

  @override
  String get sign_in_firebase_not_ready =>
      'Firebase no está listo. Verifica los registros y firebase_options.dart.';

  @override
  String get sign_in_continue => 'Continuar';

  @override
  String get sign_in_anonymously => 'Iniciar sesión anónimamente';

  @override
  String sign_in_auth_error(String error) {
    return 'Error de autenticación: $error';
  }

  @override
  String generic_error(String error) {
    return 'Error: $error';
  }

  @override
  String get storage_label_video => 'Video';

  @override
  String get storage_label_photo => 'Foto';

  @override
  String get storage_label_audio => 'Audio';

  @override
  String get storage_label_files => 'Archivos';

  @override
  String get storage_label_other => 'Otros';

  @override
  String get storage_label_recent_stickers => 'Stickers recientes';

  @override
  String get storage_label_giphy_search => 'GIPHY · caché de búsqueda';

  @override
  String get storage_label_giphy_recent => 'GIPHY · GIF recientes';

  @override
  String get storage_chat_unattributed => 'No atribuido a un chat';

  @override
  String storage_label_draft(String key) {
    return 'Borrador · $key';
  }

  @override
  String get storage_label_offline_snapshot =>
      'Captura de lista de chats sin conexión';

  @override
  String storage_label_profile_cache(String name) {
    return 'Caché de perfil · $name';
  }

  @override
  String get call_mini_end => 'Finalizar llamada';

  @override
  String get animation_quality_lite => 'ligero';

  @override
  String get animation_quality_balanced => 'Balance';

  @override
  String get animation_quality_cinematic => 'Cine';

  @override
  String get crop_aspect_original => 'Original';

  @override
  String get crop_aspect_square => 'Cuadrada';

  @override
  String get push_notification_title => 'Permitir notificaciones';

  @override
  String get push_notification_rationale =>
      'La app necesita notificaciones para llamadas entrantes.';

  @override
  String get push_notification_required =>
      'Activa las notificaciones para mostrar las llamadas entrantes.';

  @override
  String get push_notification_grant => 'Permitir';

  @override
  String get push_call_accept => 'Aceptar';

  @override
  String get push_call_decline => 'Rechazar';

  @override
  String get push_channel_incoming_calls => 'Llamadas entrantes';

  @override
  String get push_channel_missed_calls => 'Llamadas perdidas';

  @override
  String get push_channel_messages_desc => 'Nuevos mensajes en chats';

  @override
  String get push_channel_silent => 'Mensajes silenciosos';

  @override
  String get push_channel_silent_desc => 'Push sin sonido';

  @override
  String get push_caller_unknown => 'Alguien';

  @override
  String get outbox_attachment_single => 'Adjunto';

  @override
  String outbox_attachment_count(int count) {
    return 'Adjuntos ($count)';
  }

  @override
  String get bottom_nav_label_chats => 'Charlas';

  @override
  String get bottom_nav_label_contacts => 'Contactos';

  @override
  String get bottom_nav_label_conferences => 'Conferencias';

  @override
  String get bottom_nav_label_calls => 'Llamadas';

  @override
  String get welcomeBubbleTitle => 'Bienvenido a LighChat';

  @override
  String get welcomeBubbleSubtitle => 'El faro está encendido';

  @override
  String get welcomeSkip => 'Omitir';

  @override
  String get welcomeReplayDebugTile =>
      'Repetir animación de bienvenida (debug)';

  @override
  String get sticker_scope_library => 'Biblioteca';

  @override
  String get sticker_library_search_hint => 'Buscar stickers...';

  @override
  String get account_menu_energy_saving => 'Ahorro de energía';

  @override
  String get energy_saving_title => 'Ahorro de energía';

  @override
  String get energy_saving_section_mode => 'Modo de ahorro de energía';

  @override
  String get energy_saving_section_resource_heavy => 'Procesos de alto consumo';

  @override
  String get energy_saving_threshold_off => 'Desactivado';

  @override
  String get energy_saving_threshold_always => 'Activado';

  @override
  String get energy_saving_threshold_off_full => 'Nunca';

  @override
  String get energy_saving_threshold_always_full => 'Siempre';

  @override
  String energy_saving_threshold_at(int percent) {
    return 'Cuando la batería esté por debajo del $percent%';
  }

  @override
  String get energy_saving_hint_off =>
      'Los efectos de alto consumo nunca se desactivan automáticamente.';

  @override
  String get energy_saving_hint_always =>
      'Los efectos de alto consumo siempre están desactivados sin importar el nivel de batería.';

  @override
  String energy_saving_hint_threshold(int percent) {
    return 'Desactivar automáticamente todos los procesos de alto consumo cuando la batería baje del $percent%.';
  }

  @override
  String energy_saving_current_battery(int percent) {
    return 'Batería actual: $percent%';
  }

  @override
  String get energy_saving_active_now => 'modo activo';

  @override
  String get energy_saving_active_threshold =>
      'La batería alcanzó el umbral — todos los efectos a continuación están temporalmente desactivados.';

  @override
  String get energy_saving_active_system =>
      'El ahorro de energía del sistema está activado — todos los efectos a continuación están temporalmente desactivados.';

  @override
  String get energy_saving_autoplay_video_title =>
      'Reproducción automática de videos';

  @override
  String get energy_saving_autoplay_video_subtitle =>
      'Reproducir automáticamente y repetir mensajes de video y videos en chats.';

  @override
  String get energy_saving_autoplay_gif_title =>
      'Reproducción automática de GIFs';

  @override
  String get energy_saving_autoplay_gif_subtitle =>
      'Reproducir automáticamente y repetir GIFs en chats y en el teclado.';

  @override
  String get energy_saving_animated_stickers_title => 'Stickers animados';

  @override
  String get energy_saving_animated_stickers_subtitle =>
      'Animaciones en bucle de stickers y efectos de stickers Premium a pantalla completa.';

  @override
  String get energy_saving_animated_emoji_title => 'Emoji animados';

  @override
  String get energy_saving_animated_emoji_subtitle =>
      'Animación en bucle de emoji en mensajes, reacciones y estados.';

  @override
  String get energy_saving_interface_animations_title =>
      'Animaciones de interfaz';

  @override
  String get energy_saving_interface_animations_subtitle =>
      'Efectos y animaciones que hacen a LighChat más fluido y expresivo.';

  @override
  String get energy_saving_media_preload_title => 'Precarga de multimedia';

  @override
  String get energy_saving_media_preload_subtitle =>
      'Comenzar a descargar archivos multimedia al abrir la lista de chats.';

  @override
  String get energy_saving_background_update_title =>
      'Actualización en segundo plano';

  @override
  String get energy_saving_background_update_subtitle =>
      'Actualizaciones rápidas del chat al cambiar entre apps.';

  @override
  String get legal_index_title => 'Documentos legales';

  @override
  String get legal_index_subtitle =>
      'Política de privacidad, términos de servicio y otros documentos legales que regulan el uso de LighChat.';

  @override
  String get legal_settings_section_title => 'Información legal';

  @override
  String get legal_settings_section_subtitle =>
      'Política de privacidad, términos de servicio, EULA y más.';

  @override
  String get legal_not_found => 'Documento no encontrado';

  @override
  String get legal_title_privacy_policy => 'Política de Privacidad';

  @override
  String get legal_title_terms_of_service => 'Términos de Servicio';

  @override
  String get legal_title_cookie_policy => 'Política de Cookies';

  @override
  String get legal_title_eula => 'Acuerdo de Licencia de Usuario Final';

  @override
  String get legal_title_dpa => 'Acuerdo de Procesamiento de Datos';

  @override
  String get legal_title_children => 'Política para Niños';

  @override
  String get legal_title_moderation => 'Política de Moderación de Contenido';

  @override
  String get legal_title_aup => 'Política de Uso Aceptable';

  @override
  String get chat_list_item_sender_you => 'Tú';

  @override
  String get chat_preview_message => 'Mensaje';

  @override
  String get chat_preview_sticker => 'Etiqueta engomada';

  @override
  String get chat_preview_attachment => 'Adjunto';

  @override
  String get contacts_disclosure_title => 'Encontrar amigos en LighChat';

  @override
  String get contacts_disclosure_body =>
      'LighChat lee los números de teléfono y las direcciones de correo electrónico de tu libreta de contactos, los hashea y los compara con nuestro servidor para mostrar cuáles de tus contactos ya usan la aplicación. Tus contactos nunca se almacenan en nuestros servidores.';

  @override
  String get contacts_disclosure_allow => 'Permitir';

  @override
  String get contacts_disclosure_deny => 'Ahora no';

  @override
  String get report_title => 'Denunciar';

  @override
  String get report_subtitle_message => 'Denunciar mensaje';

  @override
  String get report_subtitle_user => 'Denunciar usuario';

  @override
  String get report_reason_spam => 'Spam';

  @override
  String get report_reason_offensive => 'Contenido ofensivo';

  @override
  String get report_reason_violence => 'Violencia o amenazas';

  @override
  String get report_reason_fraud => 'Fraude o estafa';

  @override
  String get report_reason_other => 'Otro';

  @override
  String get report_comment_hint => 'Detalles adicionales (opcional)';

  @override
  String get report_submit => 'Enviar';

  @override
  String get report_success => 'Denuncia enviada. ¡Gracias!';

  @override
  String get report_error => 'Error al enviar la denuncia';

  @override
  String get message_menu_action_report => 'Denunciar';

  @override
  String get partner_profile_menu_report => 'Denunciar usuario';

  @override
  String get call_bubble_voice_call => 'Llamada de voz';

  @override
  String get call_bubble_video_call => 'Videollamada';

  @override
  String get chat_preview_poll => 'Encuesta';

  @override
  String get chat_preview_forwarded => 'Mensaje reenviado';

  @override
  String get birthday_banner_celebrates => 'está de cumpleaños!';

  @override
  String get birthday_banner_action => 'Felicitar →';

  @override
  String get birthday_screen_title_today => 'Cumpleaños hoy';

  @override
  String birthday_screen_age(int age) {
    return 'Cumple $age';
  }

  @override
  String get birthday_section_actions => 'FELICITAR';

  @override
  String get birthday_action_template => 'Mensaje rápido';

  @override
  String get birthday_action_cake => 'Soplar la vela';

  @override
  String get birthday_action_confetti => 'Confeti';

  @override
  String get birthday_action_serpentine => 'Serpentinas';

  @override
  String get birthday_action_voice => 'Grabar saludo de voz';

  @override
  String get birthday_action_remind_next_year => 'Recordarme el año que viene';

  @override
  String get birthday_action_open_chat => 'Escribir tu propio mensaje';

  @override
  String get birthday_cake_prompt => 'Toca la vela para apagarla';

  @override
  String birthday_cake_wish_placeholder(Object name) {
    return '¿Qué deseas para $name?';
  }

  @override
  String get birthday_cake_wish_hint =>
      'Por ejemplo: que se cumplan todos tus sueños…';

  @override
  String get birthday_cake_send => 'Enviar';

  @override
  String birthday_cake_message(Object name, Object wish) {
    return '🎂 ¡Feliz cumpleaños, $name! Mi deseo para ti: «$wish»';
  }

  @override
  String birthday_confetti_message(Object name) {
    return '🎉 ¡Feliz cumpleaños, $name! 🎉';
  }

  @override
  String birthday_template_1(Object name) {
    return '¡Feliz cumpleaños, $name! ¡Que este año sea el mejor!';
  }

  @override
  String birthday_template_2(Object name) {
    return '$name, ¡felicidades! Te deseo alegría, cariño y que se cumplan tus sueños 🎉';
  }

  @override
  String birthday_template_3(Object name) {
    return '¡Feliz día, $name! Salud, suerte y muchos momentos felices 🎂';
  }

  @override
  String birthday_template_4(Object name) {
    return '$name, ¡feliz cumple! Que todos tus planes se cumplan fácilmente ✨';
  }

  @override
  String birthday_template_5(Object name) {
    return '¡Felicidades, $name! Gracias por existir. ¡Feliz cumpleaños! 🎁';
  }

  @override
  String get birthday_toast_sent => 'Felicitación enviada';

  @override
  String birthday_reminder_set(Object name) {
    return 'Te recordaremos un día antes del cumpleaños de $name';
  }

  @override
  String get birthday_reminder_notif_title => 'Mañana es cumpleaños 🎂';

  @override
  String birthday_reminder_notif_body(Object name) {
    return 'No olvides felicitar a $name mañana';
  }

  @override
  String get birthday_empty => 'Hoy no hay cumpleaños entre tus contactos';

  @override
  String get birthday_error_self => 'No se pudo cargar tu perfil';

  @override
  String get birthday_error_send =>
      'No se pudo enviar el mensaje. Inténtalo de nuevo.';

  @override
  String get birthday_error_reminder => 'No se pudo configurar el recordatorio';

  @override
  String get chat_empty_title => 'Aún no hay mensajes';

  @override
  String get chat_empty_subtitle => 'Saluda — el farero ya te está saludando';

  @override
  String get chat_empty_quick_greet => 'Saludar 👋';
}
