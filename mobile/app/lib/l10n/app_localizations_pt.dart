// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get secret_chat_title => 'Chat secreto';

  @override
  String get secret_chats_title => 'Chats secretos';

  @override
  String get secret_chat_locked_title => 'Chat secreto bloqueado';

  @override
  String get secret_chat_locked_subtitle =>
      'Digite seu PIN para desbloquear e ver as mensagens.';

  @override
  String get secret_chat_unlock_title => 'Desbloquear chat secreto';

  @override
  String get secret_chat_unlock_subtitle =>
      'É necessário um PIN para abrir este chat.';

  @override
  String get secret_chat_unlock_action => 'Desbloquear';

  @override
  String get secret_chat_set_pin_and_unlock => 'Definir PIN e desbloquear';

  @override
  String get secret_chat_pin_label => 'PIN (4 dígitos)';

  @override
  String get secret_chat_pin_invalid => 'Digite um PIN de 4 dígitos';

  @override
  String get secret_chat_already_exists =>
      'Já existe um chat secreto com este usuário.';

  @override
  String get secret_chat_exists_badge => 'Criado';

  @override
  String get secret_chat_unlock_failed =>
      'Não foi possível desbloquear. Tente novamente.';

  @override
  String get secret_chat_action_not_allowed =>
      'Esta ação não é permitida em um chat secreto';

  @override
  String get secret_chat_remember_pin => 'Lembrar PIN neste dispositivo';

  @override
  String get secret_chat_unlock_biometric => 'Desbloquear com biometria';

  @override
  String get secret_chat_biometric_reason => 'Desbloquear chat secreto';

  @override
  String get secret_chat_biometric_no_saved_pin =>
      'Digite o PIN uma vez para habilitar o desbloqueio biométrico';

  @override
  String get secret_chat_ttl_title => 'Duração do chat secreto';

  @override
  String get secret_chat_settings_title => 'Configurações do chat secreto';

  @override
  String get secret_chat_settings_subtitle => 'Duração, acesso e restrições';

  @override
  String get secret_chat_settings_not_secret =>
      'Este chat não é um chat secreto';

  @override
  String get secret_chat_settings_ttl => 'Duração';

  @override
  String secret_chat_settings_time_left(Object value) {
    return 'Tempo restante: $value';
  }

  @override
  String secret_chat_settings_expires_at(Object iso) {
    return 'Expira em: $iso';
  }

  @override
  String get secret_chat_settings_unlock_grant_ttl => 'Duração do desbloqueio';

  @override
  String get secret_chat_settings_unlock_grant_ttl_subtitle =>
      'Por quanto tempo o acesso fica ativo após o desbloqueio';

  @override
  String get secret_chat_settings_no_copy => 'Desativar cópia';

  @override
  String get secret_chat_settings_no_forward => 'Desativar encaminhamento';

  @override
  String get secret_chat_settings_no_save => 'Desativar salvar mídia';

  @override
  String get secret_chat_settings_screenshot_protection =>
      'Proteção contra capturas de tela (Android)';

  @override
  String get secret_chat_settings_media_views =>
      'Limites de visualização de mídia';

  @override
  String get secret_chat_settings_media_views_subtitle =>
      'Limites aproximados de visualizações pelo destinatário';

  @override
  String get secret_chat_media_type_image => 'Imagens';

  @override
  String get secret_chat_media_type_video => 'Vídeos';

  @override
  String get secret_chat_media_type_voice => 'Mensagens de voz';

  @override
  String get secret_chat_media_type_location => 'Localização';

  @override
  String get secret_chat_media_type_file => 'Arquivos';

  @override
  String get secret_chat_media_views_unlimited => 'Ilimitado';

  @override
  String get secret_chat_compose_create => 'Criar chat secreto';

  @override
  String get secret_chat_compose_vault_pin_subtitle =>
      'Opcional: defina um PIN do cofre de 4 dígitos usado para desbloquear a caixa de entrada secreta (armazenado neste dispositivo para biometria quando habilitado).';

  @override
  String get secret_chat_compose_require_unlock_pin =>
      'Exigir PIN para abrir este chat';

  @override
  String get secret_chat_settings_read_only_hint =>
      'Estas configurações são fixadas na criação e não podem ser alteradas.';

  @override
  String get secret_chat_settings_delete => 'Excluir chat secreto';

  @override
  String get secret_chat_settings_delete_confirm_title =>
      'Excluir este chat secreto?';

  @override
  String get secret_chat_settings_delete_confirm_body =>
      'Mensagens e mídia serão removidas para os dois participantes.';

  @override
  String get privacy_secret_vault_title => 'Cofre secreto';

  @override
  String get privacy_secret_vault_subtitle =>
      'Verificações globais de PIN e biometria para entrar nos chats secretos.';

  @override
  String get privacy_secret_vault_change_pin =>
      'Definir ou alterar PIN do cofre';

  @override
  String get privacy_secret_vault_change_pin_subtitle =>
      'Se já existe um PIN, confirme com o PIN antigo ou biometria.';

  @override
  String get privacy_secret_vault_bio_subtitle =>
      'Realizar verificação biométrica e validar o PIN local salvo.';

  @override
  String get privacy_secret_vault_bio_reason =>
      'Confirmar acesso aos chats secretos';

  @override
  String get privacy_secret_vault_current_pin => 'PIN atual';

  @override
  String get privacy_secret_vault_new_pin => 'Novo PIN';

  @override
  String get privacy_secret_vault_repeat_pin => 'Repetir novo PIN';

  @override
  String get privacy_secret_vault_pin_mismatch => 'Os PINs não coincidem';

  @override
  String get privacy_secret_vault_pin_updated => 'PIN do cofre atualizado';

  @override
  String get privacy_secret_vault_bio_unavailable =>
      'Autenticação biométrica não está disponível neste dispositivo';

  @override
  String get privacy_secret_vault_bio_verified =>
      'Verificação biométrica aprovada';

  @override
  String get privacy_secret_vault_setup_required =>
      'Configure primeiro o PIN ou o acesso biométrico em Privacidade.';

  @override
  String get privacy_secret_vault_network_timeout =>
      'Tempo limite de rede excedido. Tente novamente.';

  @override
  String privacy_secret_vault_error(Object error) {
    return 'Erro do cofre secreto: $error';
  }

  @override
  String get tournament_title => 'Torneio';

  @override
  String get tournament_subtitle => 'Classificação e séries de jogos';

  @override
  String get tournament_new_game => 'Novo jogo';

  @override
  String get tournament_standings => 'Classificação';

  @override
  String get tournament_standings_empty => 'Ainda não há resultados';

  @override
  String get tournament_games => 'Jogos';

  @override
  String get tournament_games_empty => 'Ainda não há jogos';

  @override
  String tournament_points(Object pts) {
    return '$pts pts';
  }

  @override
  String tournament_games_played(Object n) {
    return '$n jogos';
  }

  @override
  String tournament_create_failed(Object err) {
    return 'Não foi possível criar o torneio: $err';
  }

  @override
  String tournament_create_game_failed(Object err) {
    return 'Não foi possível criar o jogo: $err';
  }

  @override
  String tournament_game_players(Object names) {
    return 'Jogadores: $names';
  }

  @override
  String get tournament_game_result_draw => 'Resultado: empate';

  @override
  String tournament_game_result_loser(Object name) {
    return 'Resultado: durak — $name';
  }

  @override
  String tournament_game_place(Object place) {
    return 'Posição $place';
  }

  @override
  String get durak_dm_lobby_banner =>
      'Seu parceiro criou um lobby de Durak — entre';

  @override
  String get durak_dm_lobby_open => 'Abrir lobby';

  @override
  String get conversation_game_lobby_cancel => 'Encerrar espera';

  @override
  String conversation_game_lobby_cancel_failed(Object err) {
    return 'Não foi possível encerrar a espera: $err';
  }

  @override
  String secret_chat_media_views_count(Object count) {
    return '$count visualizações';
  }

  @override
  String secret_chat_settings_load_failed(Object error) {
    return 'Falha ao carregar: $error';
  }

  @override
  String secret_chat_settings_save_failed(Object error) {
    return 'Falha ao salvar: $error';
  }

  @override
  String get secret_chat_settings_reset_strict => 'Restaurar padrões rígidos';

  @override
  String get secret_chat_settings_reset_strict_subtitle =>
      'Habilita todas as restrições e define o limite de visualizações de mídia em 1';

  @override
  String get settings_language_title => 'Idioma';

  @override
  String get settings_language_system => 'Sistema';

  @override
  String get settings_language_ru => 'Russo';

  @override
  String get settings_language_en => 'Inglês';

  @override
  String get settings_language_hint_system =>
      'Quando “Sistema” está selecionado, o app segue as configurações de idioma do dispositivo.';

  @override
  String get account_menu_profile => 'Perfil';

  @override
  String get account_menu_features => 'Recursos';

  @override
  String get account_menu_chat_settings => 'Configurações do chat';

  @override
  String get account_menu_notifications => 'Notificações';

  @override
  String get account_menu_privacy => 'Privacidade';

  @override
  String get account_menu_devices => 'Dispositivos';

  @override
  String get account_menu_blacklist => 'Lista de bloqueados';

  @override
  String get account_menu_language => 'Idioma';

  @override
  String get account_menu_storage => 'Armazenamento';

  @override
  String get account_menu_theme => 'Tema';

  @override
  String get account_menu_sign_out => 'Sair';

  @override
  String get storage_settings_title => 'Armazenamento';

  @override
  String get storage_settings_subtitle =>
      'Controle quais dados ficam em cache neste dispositivo e limpe por chats ou arquivos.';

  @override
  String get storage_settings_total_label => 'Usado neste dispositivo';

  @override
  String storage_settings_budget_label(Object gb) {
    return 'Limite do cache: $gb GB';
  }

  @override
  String get storage_unit_gb => 'GB';

  @override
  String get storage_settings_clear_all_button => 'Limpar todo o cache';

  @override
  String get storage_settings_trim_button => 'Ajustar ao limite';

  @override
  String get storage_settings_policy_title => 'O que manter localmente';

  @override
  String get storage_settings_budget_slider_title => 'Limite do cache';

  @override
  String get storage_settings_breakdown_title => 'Por tipo de dado';

  @override
  String get storage_settings_breakdown_empty => 'Não local cached data yet.';

  @override
  String get storage_settings_chats_title => 'Por chat';

  @override
  String get storage_settings_chats_empty => 'Não chat-specific cache yet.';

  @override
  String storage_settings_chat_subtitle(Object count, Object size) {
    return '$count itens · $size';
  }

  @override
  String get storage_settings_general_title => 'Cache não atribuído';

  @override
  String get storage_settings_general_hint =>
      'Entradas que não estão vinculadas a um chat específico (cache antigo/global).';

  @override
  String get storage_settings_general_empty => 'Não shared cache entries.';

  @override
  String get storage_settings_chat_files_empty =>
      'Sem arquivos locais no cache deste chat.';

  @override
  String get storage_settings_clear_chat_action => 'Limpar cache do chat';

  @override
  String get storage_settings_clear_all_title => 'Limpar cache local?';

  @override
  String get storage_settings_clear_all_body =>
      'Isso vai remover arquivos em cache, prévias, rascunhos e snapshots offline deste dispositivo.';

  @override
  String storage_settings_clear_chat_title(Object chat) {
    return 'Limpar cache de “$chat”?';
  }

  @override
  String get storage_settings_clear_chat_body =>
      'Apenas o cache deste chat será excluído. As mensagens na nuvem permanecem intactas.';

  @override
  String get storage_settings_snackbar_cleared => 'Cache local limpo';

  @override
  String get storage_settings_snackbar_budget_already_ok =>
      'O cache já está dentro do limite definido';

  @override
  String storage_settings_snackbar_budget_trimmed(Object size) {
    return 'Liberado: $size';
  }

  @override
  String get storage_settings_error_empty =>
      'Não foi possível gerar as estatísticas de armazenamento';

  @override
  String get storage_category_e2ee_media => 'Cache de mídia E2EE';

  @override
  String get storage_category_e2ee_media_subtitle =>
      'Arquivos de mídia secretos descriptografados por chat para reabertura mais rápida.';

  @override
  String get storage_category_e2ee_text => 'Cache de texto E2EE';

  @override
  String get storage_category_e2ee_text_subtitle =>
      'Trechos de texto descriptografados por chat para renderização instantânea.';

  @override
  String get storage_category_drafts => 'Rascunhos de mensagens';

  @override
  String get storage_category_drafts_subtitle =>
      'Texto de rascunhos não enviados por chat.';

  @override
  String get storage_category_chat_list_snapshot => 'Lista de chats offline';

  @override
  String get storage_category_chat_list_snapshot_subtitle =>
      'Snapshot recente da lista de chats para iniciar rápido offline.';

  @override
  String get storage_category_profile_cards => 'Mini-cache de perfis';

  @override
  String get storage_category_profile_cards_subtitle =>
      'Nomes e avatares salvos para uma interface mais rápida.';

  @override
  String get storage_category_video_downloads => 'Cache de vídeos baixados';

  @override
  String get storage_category_video_downloads_subtitle =>
      'Vídeos baixados localmente a partir de visualizações na galeria.';

  @override
  String get storage_category_video_thumbs => 'Quadros de prévia de vídeo';

  @override
  String get storage_category_video_thumbs_subtitle =>
      'Miniaturas de primeiro quadro geradas para vídeos.';

  @override
  String get storage_category_chat_images => 'Fotos do chat';

  @override
  String get storage_category_chat_images_subtitle =>
      'Fotos e figurinhas em cache dos chats abertos.';

  @override
  String get storage_category_stickers_gifs_emoji => 'Стикеры, GIF, эмодзи';

  @override
  String get storage_category_stickers_gifs_emoji_subtitle =>
      'Кэш недавних стикеров, GIPHY (gifs/stickers/emoji) и анимированных эмодзи.';

  @override
  String get storage_category_network_images => 'Кэш сетевых картинок';

  @override
  String get storage_category_network_images_subtitle =>
      'Аватары, превью и прочие изображения, скачанные из сети (libCachedImageData).';

  @override
  String get storage_media_type_video => 'Vídeo';

  @override
  String get storage_media_type_photo => 'Fotos';

  @override
  String get storage_media_type_audio => 'Аудио';

  @override
  String get storage_media_type_files => 'Arquivos';

  @override
  String get storage_media_type_other => 'Outro';

  @override
  String storage_settings_device_usage(Object pct) {
    return 'Usa $pct% do limite de cache';
  }

  @override
  String get storage_settings_clear_all_hint =>
      'Toda a mídia continua na nuvem. Você pode baixar de novo quando quiser.';

  @override
  String get storage_settings_categories_title => 'По категориям';

  @override
  String storage_settings_clear_category_title(String category) {
    return 'Очистить «$category»?';
  }

  @override
  String storage_settings_clear_category_body(String size) {
    return 'Будет освобождено около $size. Действие нельзя отменить.';
  }

  @override
  String get storage_auto_delete_title =>
      'Excluir mídia em cache automaticamente';

  @override
  String get storage_auto_delete_personal => 'Chats pessoais';

  @override
  String get storage_auto_delete_groups => 'Grupos';

  @override
  String get storage_auto_delete_never => 'Nunca';

  @override
  String get storage_auto_delete_3_days => '3 dias';

  @override
  String get storage_auto_delete_1_week => '1 semana';

  @override
  String get storage_auto_delete_1_month => '1 mês';

  @override
  String get storage_auto_delete_3_months => '3 meses';

  @override
  String get storage_auto_delete_hint =>
      'Fotos, vídeos e arquivos que você não abriu durante esse período serão removidos do dispositivo para liberar espaço.';

  @override
  String storage_chat_detail_share(Object pct) {
    return 'Este chat usa $pct% do seu cache';
  }

  @override
  String get storage_chat_detail_media_tab => 'Mídia';

  @override
  String get storage_chat_detail_select_all => 'Selecionar tudo';

  @override
  String get storage_chat_detail_deselect_all => 'Desmarcar tudo';

  @override
  String storage_chat_detail_clear_button(Object size) {
    return 'Limpar cache $size';
  }

  @override
  String get storage_chat_detail_clear_button_empty =>
      'Selecione arquivos para excluir';

  @override
  String get storage_chat_detail_tab_empty => 'Nada nesta aba.';

  @override
  String get storage_chat_detail_delete_title => 'Excluir selected files?';

  @override
  String storage_chat_detail_delete_body(Object count, Object size) {
    return '$count arquivos ($size) serão removidos do dispositivo. As cópias na nuvem permanecem intactas.';
  }

  @override
  String get profile_delete_account => 'Excluir account';

  @override
  String get profile_delete_account_confirm_title =>
      'Excluir sua conta permanentemente?';

  @override
  String get profile_delete_account_confirm_body =>
      'Sua conta será removida do Firebase Auth e todos os seus documentos do Firestore serão excluídos permanentemente. Seus chats permanecerão visíveis para os outros em modo somente leitura.';

  @override
  String get profile_delete_account_confirm_action => 'Excluir account';

  @override
  String profile_delete_account_error(Object error) {
    return 'Não foi possível excluir a conta: $error';
  }

  @override
  String get chat_readonly_deleted_user =>
      'Conta excluída. Este chat é somente leitura.';

  @override
  String get blacklist_empty => 'Não blocked users';

  @override
  String get blacklist_action_unblock => 'Desbloquear';

  @override
  String get blacklist_unblock_confirm_title => 'Desbloquear?';

  @override
  String get blacklist_unblock_confirm_body =>
      'Este usuário poderá te enviar mensagens novamente (se a política de contatos permitir) e ver seu perfil na busca.';

  @override
  String get blacklist_unblock_success => 'Usuário desbloqueado';

  @override
  String blacklist_unblock_error(Object error) {
    return 'Não foi possível desbloquear: $error';
  }

  @override
  String get partner_profile_block_confirm_title => 'Bloquear este usuário?';

  @override
  String get partner_profile_block_confirm_body =>
      'Ele não verá um chat com você, não poderá te encontrar na busca nem te adicionar aos contatos. Você sumirá dos contatos dele. Você mantém o histórico do chat, mas não pode mandar mensagens enquanto ele estiver bloqueado.';

  @override
  String get partner_profile_block_action => 'Bloquear';

  @override
  String get partner_profile_block_success => 'Usuário bloqueado';

  @override
  String partner_profile_block_error(Object error) {
    return 'Não foi possível bloquear: $error';
  }

  @override
  String get common_soon => 'Em breve';

  @override
  String common_theme_prefix(Object label) {
    return 'Tema: $label';
  }

  @override
  String common_error_cannot_save_theme(Object error) {
    return 'Não foi possível salvar o tema: $error';
  }

  @override
  String common_error_cannot_sign_out(Object error) {
    return 'Não foi possível sair: $error';
  }

  @override
  String account_error_profile(Object error) {
    return 'Perfil error: $error';
  }

  @override
  String get notifications_title => 'Notificações';

  @override
  String get notifications_section_main => 'Principal';

  @override
  String get notifications_mute_all_title => 'Desativar tudo';

  @override
  String get notifications_mute_all_subtitle =>
      'Desativar todas as notificações.';

  @override
  String get notifications_sound_title => 'Som';

  @override
  String get notifications_sound_subtitle =>
      'Tocar um som para novas mensagens.';

  @override
  String get notifications_preview_title => 'Prévia';

  @override
  String get notifications_preview_subtitle =>
      'Mostrar o texto da mensagem nas notificações.';

  @override
  String get notifications_section_quiet_hours => 'Horário silencioso';

  @override
  String get notifications_quiet_hours_subtitle =>
      'As notificações não vão te incomodar nesse intervalo de tempo.';

  @override
  String get notifications_quiet_hours_enable_title =>
      'Ativar horário silencioso';

  @override
  String get notifications_reset_button => 'Restaurar configurações';

  @override
  String notifications_error_cannot_save(Object error) {
    return 'Não foi possível salvar settings: $error';
  }

  @override
  String notifications_error_load(Object error) {
    return 'Não foi possível carregar notifications: $error';
  }

  @override
  String get privacy_title => 'Privacidade do chat';

  @override
  String privacy_error_cannot_save(Object error) {
    return 'Não foi possível salvar settings: $error';
  }

  @override
  String privacy_error_load(Object error) {
    return 'Não foi possível carregar privacy settings: $error';
  }

  @override
  String get privacy_e2ee_section => 'Criptografia de ponta a ponta';

  @override
  String get privacy_e2ee_enable_for_all_chats =>
      'Ativar E2EE em todos os chats';

  @override
  String get privacy_e2ee_what_encrypt => 'O que é criptografado em chats E2EE';

  @override
  String get privacy_e2ee_text => 'Texto da mensagem';

  @override
  String get privacy_e2ee_media => 'Anexos (mídia/arquivos)';

  @override
  String get privacy_my_devices_title => 'Meus dispositivos';

  @override
  String get privacy_my_devices_subtitle =>
      'Dispositivos com chaves publicadas. Renomeie ou revogue acesso.';

  @override
  String get privacy_key_backup_title => 'Backup e transferência de chave';

  @override
  String get privacy_key_backup_subtitle =>
      'Crie um backup com senha ou transfira a chave por QR.';

  @override
  String get privacy_visibility_section => 'Visibilidade';

  @override
  String get privacy_online_title => 'Status online';

  @override
  String get privacy_online_subtitle =>
      'Permitir que outros vejam quando você está online.';

  @override
  String get privacy_last_seen_title => 'Visto por último';

  @override
  String get privacy_last_seen_subtitle =>
      'Mostrar quando você esteve ativo pela última vez.';

  @override
  String get privacy_read_receipts_title => 'Confirmação de leitura';

  @override
  String get privacy_read_receipts_subtitle =>
      'Permitir que remetentes vejam que você leu a mensagem.';

  @override
  String get privacy_group_invites_section => 'Convites para grupos';

  @override
  String get privacy_group_invites_subtitle =>
      'Quem pode te adicionar a chats em grupo.';

  @override
  String get privacy_group_invites_everyone => 'Todos';

  @override
  String get privacy_group_invites_contacts => 'Apenas contatos';

  @override
  String get privacy_group_invites_nobody => 'Ninguém';

  @override
  String get privacy_global_search_section => 'Descoberta';

  @override
  String get privacy_global_search_subtitle =>
      'Quem pode te encontrar pelo nome entre todos os usuários.';

  @override
  String get privacy_global_search_title => 'Busca global';

  @override
  String get privacy_global_search_hint =>
      'Se desativada, você não aparece em “Todos os usuários” quando alguém inicia um novo chat. Você ainda fica visível para quem te adicionou como contato.';

  @override
  String get privacy_profile_for_others_section => 'Perfil para outros';

  @override
  String get privacy_profile_for_others_subtitle =>
      'O que outros podem ver no seu perfil.';

  @override
  String get privacy_email_subtitle => 'Seu endereço de email no seu perfil.';

  @override
  String get privacy_phone_title => 'Número de telefone';

  @override
  String get privacy_phone_subtitle => 'Mostrado no seu perfil e nos contatos.';

  @override
  String get privacy_birthdate_title => 'Data de nascimento';

  @override
  String get privacy_birthdate_subtitle =>
      'Seu campo de aniversário no perfil.';

  @override
  String get privacy_about_title => 'Sobre';

  @override
  String get privacy_about_subtitle => 'Seu texto de bio no perfil.';

  @override
  String get privacy_reset_button => 'Restaurar configurações';

  @override
  String get common_cancel => 'Cancelar';

  @override
  String get common_create => 'Criar';

  @override
  String get common_delete => 'Excluir';

  @override
  String get common_choose => 'Escolher';

  @override
  String get common_save => 'Salvar';

  @override
  String get common_close => 'Fechar';

  @override
  String get common_nothing_found => 'Nada encontrado';

  @override
  String get common_retry => 'Tentar de novo';

  @override
  String get auth_login_email_label => 'Email';

  @override
  String get auth_login_password_label => 'Senha';

  @override
  String get auth_login_password_hint => 'Senha';

  @override
  String get auth_login_sign_in => 'Entrar';

  @override
  String get auth_login_forgot_password => 'Esqueceu a senha?';

  @override
  String get auth_login_error_enter_email_for_reset =>
      'Digite seu email para redefinir a senha';

  @override
  String get profile_title => 'Perfil';

  @override
  String get profile_edit_tooltip => 'Editar';

  @override
  String get profile_full_name_label => 'Nome completo';

  @override
  String get profile_full_name_hint => 'Nome';

  @override
  String get profile_username_label => 'Nome de usuário';

  @override
  String get profile_email_label => 'Email';

  @override
  String get profile_phone_label => 'Telefone';

  @override
  String get profile_birthdate_label => 'Data de nascimento';

  @override
  String get profile_about_label => 'Sobre';

  @override
  String get profile_about_hint => 'Uma bio curta';

  @override
  String get profile_password_toggle_show => 'Alterar senha';

  @override
  String get profile_password_toggle_hide => 'Ocultar alteração de senha';

  @override
  String get profile_password_new_label => 'Nova senha';

  @override
  String get profile_password_confirm_label => 'Confirmar senha';

  @override
  String get profile_password_tooltip_show => 'Mostrar senha';

  @override
  String get profile_password_tooltip_hide => 'Ocultar';

  @override
  String get profile_placeholder_username => 'username';

  @override
  String get profile_placeholder_email => 'nome@exemplo.com';

  @override
  String get profile_placeholder_phone => '+55 11 90000-0000';

  @override
  String get profile_placeholder_birthdate => 'DD.MM.AAAA';

  @override
  String get profile_placeholder_password_dots => '••••••••';

  @override
  String get profile_password_error_fill_both =>
      'Preencha a nova senha e a confirmação.';

  @override
  String get settings_chats_title => 'Configurações do chat';

  @override
  String get settings_chats_preview => 'Prévia';

  @override
  String get settings_chats_outgoing => 'Mensagens enviadas';

  @override
  String get settings_chats_incoming => 'Mensagens recebidas';

  @override
  String get settings_chats_font_size => 'Tamanho do texto';

  @override
  String get settings_chats_font_small => 'Pequeno';

  @override
  String get settings_chats_font_medium => 'Médio';

  @override
  String get settings_chats_font_large => 'Grande';

  @override
  String get settings_chats_bubble_shape => 'Forma do balão';

  @override
  String get settings_chats_bubble_rounded => 'Arredondado';

  @override
  String get settings_chats_bubble_square => 'Quadrado';

  @override
  String get settings_chats_chat_background => 'Plano de fundo do chat';

  @override
  String get settings_chats_chat_background_pick_hint =>
      'Escolha uma foto ou ajuste o plano de fundo';

  @override
  String get settings_chats_advanced => 'Avançado';

  @override
  String get settings_chats_show_time => 'Mostrar horário';

  @override
  String get settings_chats_show_time_subtitle =>
      'Mostrar o horário da mensagem abaixo dos balões';

  @override
  String get settings_chats_reset => 'Restaurar configurações';

  @override
  String settings_chats_error_cannot_save(Object error) {
    return 'Não foi possível salvar: $error';
  }

  @override
  String settings_chats_error_wallpaper_load(Object error) {
    return 'Não foi possível carregar o plano de fundo: $error';
  }

  @override
  String settings_chats_error_wallpaper_delete(Object error) {
    return 'Não foi possível excluir o plano de fundo: $error';
  }

  @override
  String get settings_chats_wallpaper_delete_confirm_title =>
      'Excluir plano de fundo?';

  @override
  String get settings_chats_wallpaper_delete_confirm_body =>
      'Este plano de fundo será removido da sua lista.';

  @override
  String settings_chats_icon_picker_title(Object label) {
    return 'Ícone: “$label”';
  }

  @override
  String get settings_chats_icon_picker_search_hint => 'Buscar por nome…';

  @override
  String get settings_chats_icon_color => 'Cor do ícone';

  @override
  String get settings_chats_reset_icon_size => 'Restaurar tamanho';

  @override
  String get settings_chats_reset_icon_stroke => 'Restaurar traço';

  @override
  String get settings_chats_tile_background => 'Plano de fundo do bloco';

  @override
  String get settings_chats_default_gradient => 'Gradiente padrão';

  @override
  String get settings_chats_inherit_global => 'Usar configurações globais';

  @override
  String get settings_chats_no_background => 'Sem plano de fundo';

  @override
  String get settings_chats_no_background_on => 'Sem plano de fundo (ativado)';

  @override
  String get chat_list_title => 'Chats';

  @override
  String get chat_list_search_hint => 'Buscar…';

  @override
  String get chat_list_loading_connecting => 'Conectando…';

  @override
  String get chat_list_loading_conversations => 'Carregando conversas…';

  @override
  String get chat_list_loading_list => 'Carregando lista de chats…';

  @override
  String get chat_list_loading_sign_out => 'Saindo…';

  @override
  String get chat_list_empty_search_title => 'Nenhum chat encontrado';

  @override
  String get chat_list_empty_search_body =>
      'Tente outra busca. A pesquisa funciona por nome e nome de usuário.';

  @override
  String get chat_list_empty_folder_title => 'Esta pasta está vazia';

  @override
  String get chat_list_empty_folder_body =>
      'Mude de pasta ou inicie um novo chat usando o botão acima.';

  @override
  String get chat_list_empty_all_title => 'Sem chats ainda';

  @override
  String get chat_list_empty_all_body =>
      'Inicie um novo chat para começar a conversar.';

  @override
  String get chat_list_action_new_folder => 'Nova pasta';

  @override
  String get chat_list_action_new_chat => 'Novo chat';

  @override
  String get chat_list_action_create => 'Criar';

  @override
  String get chat_list_action_close => 'Fechar';

  @override
  String get chat_list_folders_title => 'Pastas';

  @override
  String get chat_list_folders_subtitle => 'Escolha as pastas para este chat.';

  @override
  String get chat_list_folders_empty => 'Ainda não há pastas personalizadas.';

  @override
  String get chat_list_create_folder_title => 'Nova pasta';

  @override
  String get chat_list_create_folder_subtitle =>
      'Crie uma pasta para filtrar seus chats rapidamente.';

  @override
  String get chat_list_create_folder_name_label => 'NOME DA PASTA';

  @override
  String chat_list_create_folder_chats_label(Object count) {
    return 'CHATS ($count)';
  }

  @override
  String get chat_list_create_folder_select_all => 'SELECIONAR TUDO';

  @override
  String get chat_list_create_folder_reset => 'REDEFINIR';

  @override
  String get chat_list_create_folder_search_hint => 'Buscar por nome…';

  @override
  String get chat_list_create_folder_no_matches => 'Nenhum chat correspondente';

  @override
  String get chat_list_folder_default_starred => 'Favoritas';

  @override
  String get chat_list_folder_default_all => 'Todos';

  @override
  String get chat_list_folder_default_new => 'Novos';

  @override
  String get chat_list_folder_default_direct => 'Diretos';

  @override
  String get chat_list_folder_default_groups => 'Grupos';

  @override
  String get chat_list_yesterday => 'Ontem';

  @override
  String get chat_list_folder_delete_action => 'Excluir';

  @override
  String get chat_list_folder_delete_title => 'Excluir pasta?';

  @override
  String chat_list_folder_delete_body(Object name) {
    return 'A pasta \"$name\" será excluída. Os chats permanecem intactos.';
  }

  @override
  String chat_list_error_open_starred(Object error) {
    return 'Não foi possível abrir Favoritas: $error';
  }

  @override
  String chat_list_error_delete_folder(Object error) {
    return 'Não foi possível excluir a pasta: $error';
  }

  @override
  String get chat_list_pin_not_available =>
      'Fixar não está disponível nesta pasta.';

  @override
  String chat_list_pin_pinned_in_folder(Object name) {
    return 'Chat fixado em \"$name\"';
  }

  @override
  String chat_list_pin_unpinned_in_folder(Object name) {
    return 'Chat desafixado de \"$name\"';
  }

  @override
  String chat_list_error_toggle_pin(Object error) {
    return 'Não foi possível alterar a fixação: $error';
  }

  @override
  String chat_list_error_update_folder(Object error) {
    return 'Não foi possível atualizar a pasta: $error';
  }

  @override
  String get chat_list_clear_history_title => 'Limpar histórico?';

  @override
  String get chat_list_clear_history_body =>
      'As mensagens vão sumir apenas da sua visão do chat. O outro participante mantém o histórico.';

  @override
  String get chat_list_clear_history_confirm => 'Limpar';

  @override
  String chat_list_error_clear_history(Object error) {
    return 'Não foi possível limpar o histórico: $error';
  }

  @override
  String chat_list_error_mark_read(Object error) {
    return 'Não foi possível marcar o chat como lido: $error';
  }

  @override
  String get chat_list_delete_chat_title => 'Excluir chat?';

  @override
  String get chat_list_delete_chat_body =>
      'A conversa será excluída permanentemente para todos os participantes. Não dá para desfazer.';

  @override
  String get chat_list_delete_chat_confirm => 'Excluir';

  @override
  String chat_list_error_delete_chat(Object error) {
    return 'Não foi possível excluir o chat: $error';
  }

  @override
  String get chat_list_context_folders => 'Pastas';

  @override
  String get chat_list_context_unpin => 'Desafixar chat';

  @override
  String get chat_list_context_pin => 'Fixar chat';

  @override
  String get chat_list_context_mark_all_read => 'Marcar tudo como lido';

  @override
  String get chat_list_context_clear_history => 'Limpar histórico';

  @override
  String get chat_list_context_delete_chat => 'Excluir chat';

  @override
  String get chat_list_snackbar_history_cleared => 'Histórico limpo.';

  @override
  String get chat_list_snackbar_marked_read => 'Marcado como lido.';

  @override
  String chat_list_error_generic(Object error) {
    return 'Erro: $error';
  }

  @override
  String get chat_calls_title => 'Chamadas';

  @override
  String get chat_calls_search_hint => 'Buscar por nome…';

  @override
  String get chat_calls_empty => 'Seu histórico de chamadas está vazio.';

  @override
  String get chat_calls_nothing_found => 'Nada encontrado.';

  @override
  String chat_calls_error_load(Object error) {
    return 'Não foi possível carregar as chamadas:\n$error';
  }

  @override
  String get chat_reply_cancel_tooltip => 'Cancelar resposta';

  @override
  String get voice_preview_tooltip_cancel => 'Cancelar';

  @override
  String get voice_preview_tooltip_send => 'Enviar';

  @override
  String get profile_qr_title => 'Meu código QR';

  @override
  String get profile_qr_tooltip_close => 'Fechar';

  @override
  String get profile_qr_share_title => 'Meu perfil do LighChat';

  @override
  String get profile_qr_share_subject => 'Perfil do LighChat';

  @override
  String chat_media_norm_pending_title(Object mediaKind) {
    return 'Processando $mediaKind…';
  }

  @override
  String chat_media_norm_failed_title(Object mediaKind) {
    return 'Não foi possível processar $mediaKind';
  }

  @override
  String get chat_media_norm_pending_subtitle =>
      'O arquivo ficará disponível após o processamento no servidor.';

  @override
  String get chat_media_norm_failed_subtitle =>
      'Tente iniciar o processamento de novo.';

  @override
  String get conversation_threads_title => 'Tópicos';

  @override
  String get conversation_threads_empty => 'Sem tópicos ainda';

  @override
  String get conversation_threads_root_attachment => 'Anexo';

  @override
  String get conversation_threads_root_message => 'Mensagem';

  @override
  String conversation_threads_snippet_you(Object text) {
    return 'Você: $text';
  }

  @override
  String get conversation_threads_day_today => 'Hoje';

  @override
  String get conversation_threads_day_yesterday => 'Ontem';

  @override
  String conversation_threads_replies_badge(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count respostas',
      one: '$count resposta',
    );
    return '$_temp0';
  }

  @override
  String get chat_meetings_title => 'Reuniões';

  @override
  String get chat_meetings_subtitle =>
      'Crie conferências e gerencie o acesso dos participantes';

  @override
  String get chat_meetings_section_new => 'Nova reunião';

  @override
  String get chat_meetings_field_title_label => 'Título da reunião';

  @override
  String get chat_meetings_field_title_hint =>
      'Por exemplo, Sincronização de logística';

  @override
  String get chat_meetings_field_duration_label => 'Duração';

  @override
  String get chat_meetings_duration_unlimited => 'Sem limite';

  @override
  String get chat_meetings_duration_15m => '15 minutos';

  @override
  String get chat_meetings_duration_30m => '30 minutos';

  @override
  String get chat_meetings_duration_1h => '1 hora';

  @override
  String get chat_meetings_duration_90m => '1h30';

  @override
  String get chat_meetings_field_access_label => 'Acesso';

  @override
  String get chat_meetings_access_private => 'Privada';

  @override
  String get chat_meetings_access_public => 'Pública';

  @override
  String get chat_meetings_waiting_room_title => 'Sala de espera';

  @override
  String get chat_meetings_waiting_room_desc =>
      'No modo sala de espera, você controla quem entra. Até você tocar em “Admitir”, os convidados ficam na tela de espera.';

  @override
  String get chat_meetings_backgrounds_title => 'Planos de fundo virtuais';

  @override
  String get chat_meetings_backgrounds_desc =>
      'Faça upload de planos de fundo e desfoque o seu se quiser. Escolha uma imagem da galeria ou envie os seus.';

  @override
  String get chat_meetings_create_button => 'Criar reunião';

  @override
  String get chat_meetings_snackbar_enter_title =>
      'Digite um título para a reunião';

  @override
  String get chat_meetings_snackbar_auth_required =>
      'Você precisa estar conectado para criar uma reunião';

  @override
  String chat_meetings_error_create_failed(Object error) {
    return 'Não foi possível criar a reunião: $error';
  }

  @override
  String get chat_meetings_history_title => 'Seu histórico';

  @override
  String get chat_meetings_history_empty =>
      'Seu histórico de reuniões está vazio';

  @override
  String chat_meetings_history_error(Object error) {
    return 'Não foi possível carregar o histórico de reuniões: $error';
  }

  @override
  String get chat_meetings_status_live => 'ao vivo';

  @override
  String get chat_meetings_status_finished => 'finalizada';

  @override
  String get chat_meetings_badge_private => 'privada';

  @override
  String get chat_contacts_search_hint => 'Buscar contatos…';

  @override
  String get chat_contacts_permission_denied =>
      'Permissão de contatos não concedida.';

  @override
  String chat_contacts_sync_error(Object error) {
    return 'Não foi possível sincronizar os contatos: $error';
  }

  @override
  String chat_contacts_invite_prepare_failed(Object error) {
    return 'Não foi possível preparar o convite: $error';
  }

  @override
  String get chat_contacts_matches_not_found => 'Nenhum resultado encontrado.';

  @override
  String chat_contacts_added_count(Object count) {
    return 'Contatos adicionados: $count.';
  }

  @override
  String get chat_contacts_invite_text =>
      'Instale o LighChat: https://lighchat.online\nEstou te convidando para o LighChat — aqui está o link de instalação.';

  @override
  String get chat_contacts_invite_subject => 'Convite para o LighChat';

  @override
  String chat_contacts_error_load(Object error) {
    return 'Não foi possível carregar os contatos: $error';
  }

  @override
  String chat_list_item_draft_line(Object line) {
    return 'Rascunho · $line';
  }

  @override
  String get chat_list_item_chat_created => 'Chat criado';

  @override
  String get chat_list_item_no_messages_yet => 'Sem mensagens ainda';

  @override
  String get chat_list_item_history_cleared => 'Histórico limpo';

  @override
  String get chat_list_firebase_not_configured =>
      'O Firebase ainda não está configurado.';

  @override
  String get new_chat_title => 'Novo chat';

  @override
  String get new_chat_subtitle =>
      'Escolha alguém para iniciar uma conversa ou crie um grupo.';

  @override
  String get new_chat_search_hint => 'Nome, nome de usuário ou @handle…';

  @override
  String get new_chat_create_group => 'Criar um grupo';

  @override
  String get new_chat_section_phone_contacts => 'CONTATOS DO TELEFONE';

  @override
  String get new_chat_section_contacts => 'CONTATOS';

  @override
  String get new_chat_section_all_users => 'TODOS OS USUÁRIOS';

  @override
  String get new_chat_empty_no_users => 'Ninguém para iniciar um chat ainda.';

  @override
  String get new_chat_empty_not_found => 'Nenhum resultado encontrado.';

  @override
  String new_chat_error_contacts(Object error) {
    return 'Contatos: $error';
  }

  @override
  String get new_chat_fallback_user_display_name => 'Usuário';

  @override
  String get new_group_role_badge_admin => 'ADMIN';

  @override
  String get new_group_role_badge_worker => 'MEMBRO';

  @override
  String new_group_error_auth_session(Object error) {
    return 'Não foi possível verificar o login: $error';
  }

  @override
  String get invite_subject => 'Encontre-me no LighChat';

  @override
  String get invite_text =>
      'Instale o LighChat: https://lighchat.online\\nEstou te convidando para o LighChat — aqui está o link de instalação.';

  @override
  String get new_group_title => 'Criar um grupo';

  @override
  String get new_group_search_hint => 'Buscar usuários…';

  @override
  String get new_group_pick_photo_tooltip =>
      'Toque para escolher uma foto do grupo. Toque longo para remover.';

  @override
  String get new_group_name_label => 'Nome do grupo';

  @override
  String get new_group_name_hint => 'Nome';

  @override
  String get new_group_description_label => 'Descrição';

  @override
  String get new_group_description_hint => 'Opcional';

  @override
  String new_group_members_count(Object count) {
    return 'Membros ($count)';
  }

  @override
  String get new_group_add_members_section => 'ADICIONAR MEMBROS';

  @override
  String get new_group_empty_no_users => 'Ninguém para adicionar ainda.';

  @override
  String get new_group_empty_not_found => 'Nenhum resultado encontrado.';

  @override
  String get new_group_error_name_required =>
      'Por favor, digite um nome para o grupo.';

  @override
  String get new_group_error_members_required =>
      'Adicione pelo menos um membro.';

  @override
  String get new_group_action_create => 'Criar';

  @override
  String get group_members_title => 'Membros';

  @override
  String get group_members_invite_link => 'Convidar via link';

  @override
  String get group_members_admin_badge => 'ADMIN';

  @override
  String group_members_invite_text(Object groupName, Object inviteLink) {
    return 'Entre no grupo $groupName no LighChat: $inviteLink';
  }

  @override
  String get group_members_error_min_admin =>
      'É preciso manter pelo menos um administrador no grupo.';

  @override
  String get group_members_error_cannot_remove_creator =>
      'Você não pode remover os direitos de admin do criador do grupo.';

  @override
  String get group_members_remove_admin => 'Direitos de admin removidos';

  @override
  String get group_members_make_admin => 'Usuário promovido a admin';

  @override
  String get auth_brand_tagline => 'Um mensageiro mais seguro';

  @override
  String get auth_firebase_not_ready =>
      'O Firebase não está pronto. Verifique `firebase_options.dart` e GoogleService-Info.plist.';

  @override
  String get auth_redirecting_to_chats => 'Levando você aos chats…';

  @override
  String get auth_or => 'ou';

  @override
  String get auth_create_account => 'Criar conta';

  @override
  String get auth_entry_sign_in => 'Entrar';

  @override
  String get auth_entry_sign_up => 'Criar conta';

  @override
  String get auth_qr_title => 'Entrar com QR';

  @override
  String get auth_qr_hint =>
      'Abra o LighChat em um dispositivo onde você já entrou → Configurações → Dispositivos → Conectar novo dispositivo, e então escaneie este código.';

  @override
  String auth_qr_refresh_in(int seconds) {
    return 'Atualiza em ${seconds}s';
  }

  @override
  String get auth_qr_other_method => 'Entrar de outra forma';

  @override
  String get auth_qr_approving => 'Entrando…';

  @override
  String get auth_qr_rejected => 'Solicitação rejeitada';

  @override
  String get auth_qr_retry => 'Tentar de novo';

  @override
  String get auth_qr_unknown_error => 'Não foi possível gerar o código QR.';

  @override
  String get auth_qr_use_qr_login => 'Entrar com QR';

  @override
  String get auth_privacy_policy => 'Política de privacidade';

  @override
  String get auth_error_open_privacy_policy =>
      'Não foi possível abrir a política de privacidade';

  @override
  String get voice_transcript_show => 'Mostrar texto';

  @override
  String get voice_transcript_hide => 'Ocultar texto';

  @override
  String get voice_transcript_copy => 'Copiar';

  @override
  String get voice_transcript_loading => 'Transcrevendo…';

  @override
  String get voice_transcript_failed => 'Não foi possível obter o texto.';

  @override
  String get voice_attachment_media_kind_audio => 'áudio';

  @override
  String get voice_attachment_load_failed => 'Não foi possível carregar';

  @override
  String get voice_attachment_title_voice_message => 'Mensagem de voz';

  @override
  String voice_transcript_error(Object error) {
    return 'Não foi possível transcrever: $error';
  }

  @override
  String get chat_messages_title => 'Mensagens';

  @override
  String get chat_call_decline => 'Recusar';

  @override
  String get chat_call_open => 'Abrir';

  @override
  String get chat_call_accept => 'Aceitar';

  @override
  String video_call_error_init(Object error) {
    return 'Erro de chamada de vídeo: $error';
  }

  @override
  String get video_call_ended => 'Chamada encerrada';

  @override
  String get video_call_status_missed => 'Chamada perdida';

  @override
  String get video_call_status_cancelled => 'Chamada cancelada';

  @override
  String get video_call_error_offer_not_ready =>
      'A oferta ainda não está pronta. Tente novamente.';

  @override
  String get video_call_error_invalid_call_data => 'Dados de chamada inválidos';

  @override
  String video_call_error_accept_failed(Object error) {
    return 'Não foi possível aceitar a chamada: $error';
  }

  @override
  String get video_call_incoming => 'Chamada de vídeo recebida';

  @override
  String get video_call_connecting => 'Chamada de vídeo…';

  @override
  String get video_call_pip_tooltip => 'Picture in picture';

  @override
  String get video_call_mini_window_tooltip => 'Mini janela';

  @override
  String get chat_delete_message_title_single => 'Excluir mensagem?';

  @override
  String get chat_delete_message_title_multi => 'Excluir mensagens?';

  @override
  String get chat_delete_message_body_single =>
      'Esta mensagem será ocultada para todos.';

  @override
  String chat_delete_message_body_multi(Object count) {
    return 'Mensagens a excluir: $count';
  }

  @override
  String get chat_delete_file_title => 'Excluir arquivo?';

  @override
  String get chat_delete_file_body =>
      'Apenas este arquivo será removido da mensagem.';

  @override
  String get forward_title => 'Encaminhar';

  @override
  String get forward_empty_no_messages => 'Nenhuma mensagem para encaminhar';

  @override
  String get forward_error_not_authorized => 'Não conectado';

  @override
  String get forward_empty_no_recipients =>
      'Sem contatos ou chats para encaminhar';

  @override
  String get forward_search_hint => 'Buscar contatos…';

  @override
  String get forward_empty_no_available_recipients =>
      'Sem destinatários disponíveis.\nVocê só pode encaminhar para contatos e seus chats ativos.';

  @override
  String get forward_empty_not_found => 'Nada encontrado';

  @override
  String get forward_action_pick_recipients => 'Escolher destinatários';

  @override
  String get forward_action_send => 'Enviar';

  @override
  String forward_error_generic(Object error) {
    return 'Erro: $error';
  }

  @override
  String get forward_sender_fallback => 'Participante';

  @override
  String get forward_error_profiles_load =>
      'Não foi possível carregar os perfis para abrir o chat';

  @override
  String get forward_error_send_no_permissions =>
      'Não foi possível encaminhar: você não tem acesso a um dos chats selecionados ou o chat não está mais disponível.';

  @override
  String get forward_error_send_forbidden_chat =>
      'Não foi possível encaminhar: o acesso a um dos chats foi negado.';

  @override
  String get share_picker_title => 'Partilhar no LighChat';

  @override
  String get share_picker_empty_payload => 'Nada para partilhar';

  @override
  String get share_picker_summary_text_only => 'Texto';

  @override
  String share_picker_summary_files_count(int count) {
    return 'Ficheiros: $count';
  }

  @override
  String share_picker_summary_files_with_text(int count) {
    return 'Ficheiros: $count + texto';
  }

  @override
  String get devices_title => 'Meus dispositivos';

  @override
  String get devices_subtitle =>
      'Dispositivos onde sua chave pública de criptografia está publicada. Revogar cria uma nova época de chave para todos os chats criptografados — o dispositivo revogado não poderá ler novas mensagens.';

  @override
  String get devices_empty => 'Nenhum dispositivo ainda.';

  @override
  String get devices_connect_new_device => 'Conectar novo dispositivo';

  @override
  String get devices_approve_title => 'Permitir que este dispositivo entre?';

  @override
  String get devices_approve_body_hint =>
      'Confirme que este é o seu dispositivo que acabou de mostrar o código QR.';

  @override
  String get devices_approve_allow => 'Permitir';

  @override
  String get devices_approve_deny => 'Negar';

  @override
  String get devices_handover_progress_title =>
      'Sincronizando chats criptografados…';

  @override
  String devices_handover_progress_body(int done, int total) {
    return 'Atualizado $done de $total';
  }

  @override
  String get devices_handover_progress_starting => 'Iniciando…';

  @override
  String get devices_handover_success_title => 'Novo dispositivo vinculado';

  @override
  String devices_handover_success_body(String label) {
    return 'O dispositivo $label agora tem acesso aos seus chats criptografados.';
  }

  @override
  String devices_progress_rekeying(Object done, Object total) {
    return 'Atualizando chats: $done / $total';
  }

  @override
  String get devices_chip_current => 'Este dispositivo';

  @override
  String get devices_chip_revoked => 'Revogado';

  @override
  String devices_meta_created_activity(Object createdAt, Object lastSeenAt) {
    return 'Criado: $createdAt  •  Atividade: $lastSeenAt';
  }

  @override
  String devices_meta_revoked_at(Object revokedAt) {
    return 'Revogado: $revokedAt';
  }

  @override
  String get devices_action_rename => 'Renomear';

  @override
  String get devices_action_revoke => 'Revogar';

  @override
  String get devices_dialog_rename_title => 'Renomear dispositivo';

  @override
  String get devices_dialog_rename_hint => 'ex.: iPhone 15 — Safari';

  @override
  String devices_error_rename_failed(Object error) {
    return 'Não foi possível renomear: $error';
  }

  @override
  String get devices_dialog_revoke_title => 'Revogar dispositivo?';

  @override
  String get devices_dialog_revoke_body_current =>
      'Você está prestes a revogar ESTE dispositivo. Depois disso, você não poderá ler novas mensagens em chats criptografados de ponta a ponta a partir deste cliente.';

  @override
  String get devices_dialog_revoke_body_other =>
      'Este dispositivo não poderá ler novas mensagens em chats criptografados de ponta a ponta. As mensagens antigas continuarão disponíveis nele.';

  @override
  String devices_snackbar_revoked(Object rekeyed, Object suffix) {
    return 'Dispositivo revogado. Chats atualizados: $rekeyed$suffix';
  }

  @override
  String devices_snackbar_failed_suffix(Object count) {
    return ', erros: $count';
  }

  @override
  String devices_error_revoke_failed(Object error) {
    return 'Erro ao revogar: $error';
  }

  @override
  String get e2ee_recovery_title => 'E2EE — backup';

  @override
  String get e2ee_password_label => 'Senha';

  @override
  String get e2ee_password_confirm_label => 'Confirmar senha';

  @override
  String e2ee_password_min_length(Object count) {
    return 'Pelo menos $count caracteres';
  }

  @override
  String get e2ee_password_mismatch => 'As senhas não coincidem';

  @override
  String get e2ee_backup_create_title => 'Criar backup da chave';

  @override
  String get e2ee_backup_restore_title => 'Restaurar com senha';

  @override
  String get e2ee_backup_restore_action => 'Restaurar';

  @override
  String e2ee_backup_create_error(Object error) {
    return 'Não foi possível criar o backup: $error';
  }

  @override
  String e2ee_backup_restore_error(Object error) {
    return 'Não foi possível restaurar: $error';
  }

  @override
  String get e2ee_backup_wrong_password => 'Senha incorreta';

  @override
  String get e2ee_backup_not_found => 'Backup não encontrado';

  @override
  String e2ee_recovery_error_generic(Object error) {
    return 'Erro: $error';
  }

  @override
  String get e2ee_backup_password_card_title => 'Backup com senha';

  @override
  String get e2ee_backup_password_card_description =>
      'Crie um backup criptografado da sua chave privada. Se perder todos os dispositivos, dá para restaurar em um novo usando apenas a senha. A senha não pode ser recuperada — guarde com cuidado.';

  @override
  String get e2ee_backup_overwrite => 'Sobrescrever backup';

  @override
  String get e2ee_backup_create => 'Criar backup';

  @override
  String get e2ee_backup_restore => 'Restaurar do backup';

  @override
  String get e2ee_backup_already_have => 'Já tenho um backup';

  @override
  String get e2ee_qr_transfer_title => 'Transferir chave via QR';

  @override
  String get e2ee_qr_transfer_description =>
      'No novo dispositivo você mostra um QR; no antigo, você escaneia. Confirme um código de 6 dígitos — a chave privada é transferida com segurança.';

  @override
  String get e2ee_qr_transfer_open => 'Abrir pareamento por QR';

  @override
  String get media_viewer_action_reply => 'Responder';

  @override
  String get media_viewer_action_forward => 'Encaminhar';

  @override
  String get media_viewer_action_send => 'Enviar';

  @override
  String get media_viewer_action_save => 'Salvar';

  @override
  String get media_viewer_action_show_in_chat => 'Mostrar no chat';

  @override
  String get media_viewer_action_delete => 'Excluir';

  @override
  String get media_viewer_error_no_gallery_access =>
      'Sem permissão para salvar na galeria';

  @override
  String get media_viewer_error_share_unavailable_web =>
      'Compartilhamento não está disponível na web';

  @override
  String get media_viewer_error_file_not_found => 'Arquivo não encontrado';

  @override
  String get media_viewer_error_bad_media_url => 'URL de mídia inválida';

  @override
  String get media_viewer_error_bad_url => 'URL inválida';

  @override
  String get media_viewer_error_unsupported_media_scheme =>
      'Tipo de mídia não suportado';

  @override
  String media_viewer_error_http_status(Object status) {
    return 'Erro do servidor (HTTP $status)';
  }

  @override
  String media_viewer_error_save_failed(Object error) {
    return 'Não foi possível salvar: $error';
  }

  @override
  String media_viewer_error_send_failed(Object error) {
    return 'Não foi possível enviar: $error';
  }

  @override
  String get media_viewer_video_playback_speed => 'Velocidade de reprodução';

  @override
  String get media_viewer_video_quality => 'Qualidade';

  @override
  String get media_viewer_video_quality_auto => 'Automática';

  @override
  String get media_viewer_error_quality_switch_failed =>
      'Não foi possível alternar a qualidade';

  @override
  String get media_viewer_error_pip_open_failed =>
      'Não foi possível abrir o PiP';

  @override
  String get media_viewer_pip_not_supported =>
      'Picture-in-picture não é suportado neste dispositivo.';

  @override
  String get media_viewer_video_processing =>
      'Este vídeo está sendo processado no servidor e ficará disponível em breve.';

  @override
  String get media_viewer_video_playback_failed =>
      'Não foi possível reproduzir o vídeo.';

  @override
  String get common_none => 'Nenhum';

  @override
  String get group_member_role_admin => 'Administrador';

  @override
  String get group_member_role_worker => 'Membro';

  @override
  String get profile_no_photo_to_view => 'Sem foto de perfil para ver.';

  @override
  String get profile_chat_id_copied_toast => 'ID do chat copiado';

  @override
  String get auth_register_error_open_link => 'Não foi possível abrir o link.';

  @override
  String get new_chat_error_self_profile_not_found =>
      'Seu perfil não foi encontrado no diretório. Tente sair e entrar novamente.';

  @override
  String get disappearing_messages_title => 'Mensagens temporárias';

  @override
  String get disappearing_messages_intro =>
      'Novas mensagens são removidas automaticamente do servidor após o tempo selecionado (a partir do momento do envio). Mensagens já enviadas não são alteradas.';

  @override
  String disappearing_messages_admin_only(Object summary) {
    return 'Apenas admins do grupo podem alterar isso. Atual: $summary.';
  }

  @override
  String get disappearing_messages_snackbar_off =>
      'Mensagens temporárias desativadas.';

  @override
  String get disappearing_messages_snackbar_updated =>
      'Temporizador atualizado.';

  @override
  String get disappearing_preset_off => 'Desativado';

  @override
  String get disappearing_preset_1h => '1 h';

  @override
  String get disappearing_preset_24h => '24 h';

  @override
  String get disappearing_preset_7d => '7 dias';

  @override
  String get disappearing_preset_30d => '30 dias';

  @override
  String get disappearing_ttl_summary_off => 'Desativado';

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
    return '$count dias';
  }

  @override
  String disappearing_ttl_weeks(Object count) {
    return '$count sem';
  }

  @override
  String get conversation_profile_e2ee_on => 'Ativada';

  @override
  String get conversation_profile_e2ee_off => 'Desativada';

  @override
  String get conversation_profile_e2ee_subtitle_on =>
      'A criptografia de ponta a ponta está ativada. Toque para mais detalhes.';

  @override
  String get conversation_profile_e2ee_subtitle_off =>
      'A criptografia de ponta a ponta está desativada. Toque para ativar.';

  @override
  String get partner_profile_title_fallback_group => 'Chat em grupo';

  @override
  String get partner_profile_title_fallback_saved => 'Mensagens salvas';

  @override
  String get partner_profile_title_fallback_chat => 'Chat';

  @override
  String partner_profile_subtitle_group_member_count(Object count) {
    return '$count membros';
  }

  @override
  String get partner_profile_subtitle_saved_messages =>
      'Mensagens e anotações apenas para você';

  @override
  String get partner_profile_error_cannot_contact_user =>
      'Você não consegue alcançar este usuário com as configurações de contato atuais.';

  @override
  String partner_profile_error_open_chat(Object error) {
    return 'Não foi possível abrir o chat: $error';
  }

  @override
  String get partner_profile_call_peer_fallback => 'Contato';

  @override
  String get partner_profile_chat_not_created => 'O chat ainda não foi criado';

  @override
  String get partner_profile_notifications_muted => 'Notificações silenciadas';

  @override
  String get partner_profile_notifications_unmuted => 'Notificações reativadas';

  @override
  String get partner_profile_notifications_change_failed =>
      'Não foi possível atualizar as notificações';

  @override
  String get partner_profile_removed_from_contacts => 'Removido dos contatos';

  @override
  String get partner_profile_remove_contact_failed =>
      'Não foi possível remover dos contatos';

  @override
  String get partner_profile_contact_sent => 'Contato enviado';

  @override
  String get partner_profile_share_failed_copied =>
      'Falha ao compartilhar. O texto do contato foi copiado.';

  @override
  String get partner_profile_share_contact_header => 'Contato no LighChat';

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
    return 'Contato do LighChat: $name';
  }

  @override
  String get partner_profile_tooltip_back => 'Voltar';

  @override
  String get partner_profile_tooltip_close => 'Fechar';

  @override
  String get partner_profile_edit_contact_short => 'Editar';

  @override
  String get partner_profile_tooltip_copy_chat_id => 'Copiar ID do chat';

  @override
  String get partner_profile_action_chats => 'Chats';

  @override
  String get partner_profile_action_voice_call => 'Ligar';

  @override
  String get partner_profile_action_video => 'Vídeo';

  @override
  String get partner_profile_action_share => 'Compartilhar';

  @override
  String get partner_profile_action_notifications => 'Alertas';

  @override
  String get partner_profile_menu_members => 'Membros';

  @override
  String get partner_profile_menu_edit_group => 'Editar grupo';

  @override
  String get partner_profile_menu_media_links_files =>
      'Mídia, links e arquivos';

  @override
  String get partner_profile_menu_starred => 'Favoritas';

  @override
  String get partner_profile_menu_threads => 'Tópicos';

  @override
  String get partner_profile_menu_games => 'Jogos';

  @override
  String get partner_profile_menu_block => 'Bloquear';

  @override
  String get partner_profile_menu_unblock => 'Desbloquear';

  @override
  String get partner_profile_menu_notifications => 'Notificações';

  @override
  String get partner_profile_menu_chat_theme => 'Tema do chat';

  @override
  String get partner_profile_menu_advanced_privacy =>
      'Privacidade avançada do chat';

  @override
  String get partner_profile_privacy_trailing_default => 'Padrão';

  @override
  String get partner_profile_menu_encryption => 'Criptografia';

  @override
  String get partner_profile_no_common_groups => 'SEM GRUPOS EM COMUM';

  @override
  String partner_profile_create_group_with(Object name) {
    return 'Criar um grupo com $name';
  }

  @override
  String get partner_profile_leave_group => 'Sair do grupo';

  @override
  String get partner_profile_contacts_and_data => 'Informações de contato';

  @override
  String get partner_profile_field_system_role => 'Função no sistema';

  @override
  String get partner_profile_field_email => 'Email';

  @override
  String get partner_profile_field_phone => 'Telefone';

  @override
  String get partner_profile_field_birthday => 'Aniversário';

  @override
  String get partner_profile_field_bio => 'Sobre';

  @override
  String get partner_profile_add_to_contacts => 'Adicionar aos contatos';

  @override
  String get partner_profile_remove_from_contacts => 'Remover dos contatos';

  @override
  String get thread_search_hint => 'Buscar no tópico…';

  @override
  String get thread_search_tooltip_clear => 'Limpar';

  @override
  String get thread_search_tooltip_search => 'Buscar';

  @override
  String thread_reply_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count respostas',
      one: '$count resposta',
      zero: '$count respostas',
    );
    return '$_temp0';
  }

  @override
  String get thread_message_not_found => 'Mensagem não encontrada';

  @override
  String get thread_screen_title_fallback => 'Tópico';

  @override
  String thread_load_replies_error(Object error) {
    return 'Erro do tópico: $error';
  }

  @override
  String get chat_message_empty_placeholder => 'Mensagem';

  @override
  String get chat_sender_you => 'Você';

  @override
  String get chat_clipboard_nothing_to_paste =>
      'Nada para colar da área de transferência';

  @override
  String chat_clipboard_paste_failed(Object error) {
    return 'Não foi possível colar da área de transferência: $error';
  }

  @override
  String chat_send_failed(Object error) {
    return 'Não foi possível enviar: $error';
  }

  @override
  String chat_send_video_circle_failed(Object error) {
    return 'Não foi possível enviar a nota em vídeo: $error';
  }

  @override
  String get chat_service_unavailable => 'Serviço indisponível';

  @override
  String get chat_repository_unavailable => 'Serviço de chat indisponível';

  @override
  String get chat_still_loading => 'O chat ainda está carregando';

  @override
  String get chat_no_participants => 'Sem participantes no chat';

  @override
  String get chat_location_ios_geolocator_missing =>
      'A localização não está vinculada nesta build do iOS. Execute pod install em mobile/app/ios e recompile.';

  @override
  String get chat_location_services_disabled =>
      'Ative os serviços de localização';

  @override
  String get chat_location_permission_denied =>
      'Sem permissão para usar a localização';

  @override
  String chat_location_send_failed(Object error) {
    return 'Não foi possível enviar a localização: $error';
  }

  @override
  String get chat_poll_send_timeout => 'Enquete não enviada: tempo esgotado';

  @override
  String chat_poll_send_firebase(Object details) {
    return 'Enquete não enviada (Firestore): $details';
  }

  @override
  String chat_poll_send_known_error(Object details) {
    return 'Enquete não enviada: $details';
  }

  @override
  String chat_poll_send_failed(Object error) {
    return 'Não foi possível enviar a enquete: $error';
  }

  @override
  String chat_delete_action_failed(Object error) {
    return 'Não foi possível excluir: $error';
  }

  @override
  String get chat_media_transcode_retry_started =>
      'Nova tentativa de transcodificação iniciada';

  @override
  String chat_media_transcode_retry_failed(Object error) {
    return 'Não foi possível iniciar a nova tentativa de transcodificação: $error';
  }

  @override
  String chat_parent_load_error(Object error) {
    return 'Erro: $error';
  }

  @override
  String get chat_message_not_found_in_loaded_history =>
      'A mensagem não foi encontrada no histórico carregado';

  @override
  String get chat_finish_editing_first => 'Termine a edição primeiro';

  @override
  String chat_send_voice_failed(Object error) {
    return 'Não foi possível enviar a mensagem de voz: $error';
  }

  @override
  String get chat_starred_removed => 'Removida de Favoritas';

  @override
  String get chat_starred_added => 'Adicionada a Favoritas';

  @override
  String chat_starred_toggle_failed(Object error) {
    return 'Não foi possível atualizar Favoritas: $error';
  }

  @override
  String chat_reaction_toggle_failed(Object error) {
    return 'Não foi possível adicionar a reação: $error';
  }

  @override
  String chat_emoji_burst_sync_failed(Object error) {
    return 'Não foi possível sincronizar o efeito de emoji: $error';
  }

  @override
  String get chat_pin_already_pinned => 'A mensagem já está fixada';

  @override
  String chat_pin_limit_reached(int count) {
    return 'Limite de mensagens fixadas ($count)';
  }

  @override
  String chat_pin_failed(Object error) {
    return 'Não foi possível fixar: $error';
  }

  @override
  String chat_unpin_failed(Object error) {
    return 'Não foi possível desafixar: $error';
  }

  @override
  String get chat_text_copied => 'Texto copiado';

  @override
  String get chat_edit_attachments_not_allowed =>
      'Anexos não estão disponíveis durante a edição';

  @override
  String get chat_edit_text_empty => 'O texto não pode ficar vazio';

  @override
  String chat_e2ee_unavailable(Object code) {
    return 'Criptografia indisponível: $code';
  }

  @override
  String chat_save_failed(Object error) {
    return 'Não foi possível salvar: $error';
  }

  @override
  String chat_load_messages_error(Object error) {
    return 'Não foi possível carregar as mensagens: $error';
  }

  @override
  String chat_conversation_error(Object error) {
    return 'Erro da conversa: $error';
  }

  @override
  String chat_auth_error(Object error) {
    return 'Erro de autenticação: $error';
  }

  @override
  String get chat_poll_label => 'Enquete';

  @override
  String get chat_location_label => 'Localização';

  @override
  String get chat_attachment_label => 'Anexo';

  @override
  String chat_media_pick_failed(Object error) {
    return 'Não foi possível escolher mídia: $error';
  }

  @override
  String chat_file_pick_failed(Object error) {
    return 'Não foi possível escolher arquivo: $error';
  }

  @override
  String get chat_call_ongoing_video => 'Chamada de vídeo em andamento';

  @override
  String get chat_call_ongoing_audio => 'Chamada de áudio em andamento';

  @override
  String get chat_call_incoming_video => 'Chamada de vídeo recebida';

  @override
  String get chat_call_incoming_audio => 'Chamada de áudio recebida';

  @override
  String get message_menu_action_reply => 'Responder';

  @override
  String get message_menu_action_thread => 'Tópico';

  @override
  String get message_menu_action_copy => 'Copiar';

  @override
  String get message_menu_action_edit => 'Editar';

  @override
  String get message_menu_action_pin => 'Fixar';

  @override
  String get message_menu_action_star_add => 'Adicionar a Favoritas';

  @override
  String get message_menu_action_star_remove => 'Remover de Favoritas';

  @override
  String get message_menu_action_create_sticker => 'Создать стикер';

  @override
  String get message_menu_action_save_to_my_stickers =>
      'Добавить в мои стикеры';

  @override
  String get message_menu_action_forward => 'Encaminhar';

  @override
  String get message_menu_action_select => 'Selecionar';

  @override
  String get message_menu_action_delete => 'Excluir';

  @override
  String get message_menu_initiator_deleted => 'Mensagem excluída';

  @override
  String get message_menu_header_sent => 'ENVIADA:';

  @override
  String get message_menu_header_read => 'LIDA:';

  @override
  String get message_menu_header_expire_at => 'DESAPARECE:';

  @override
  String get chat_header_search_hint => 'Buscar mensagens…';

  @override
  String get chat_header_tooltip_threads => 'Tópicos';

  @override
  String get chat_header_tooltip_search => 'Buscar';

  @override
  String get chat_header_tooltip_video_call => 'Chamada de vídeo';

  @override
  String get chat_header_tooltip_audio_call => 'Chamada de áudio';

  @override
  String get conversation_games_title => 'Jogos';

  @override
  String get conversation_games_durak => 'Durak';

  @override
  String get conversation_games_durak_subtitle => 'Criar lobby';

  @override
  String get conversation_game_lobby_title => 'Lobby';

  @override
  String get conversation_game_lobby_not_found => 'Jogo não encontrado';

  @override
  String conversation_game_lobby_error(Object error) {
    return 'Erro: $error';
  }

  @override
  String conversation_game_lobby_create_failed(Object error) {
    return 'Não foi possível criar o jogo: $error';
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
    return 'Jogadores: $count/$max';
  }

  @override
  String get conversation_game_lobby_join => 'Entrar';

  @override
  String get conversation_game_lobby_start => 'Iniciar';

  @override
  String conversation_game_lobby_join_failed(Object error) {
    return 'Não foi possível entrar: $error';
  }

  @override
  String conversation_game_lobby_start_failed(Object error) {
    return 'Não foi possível iniciar o jogo: $error';
  }

  @override
  String get conversation_game_send_test_move => 'Jogada de teste';

  @override
  String conversation_game_move_failed(Object error) {
    return 'Jogada rejeitada: $error';
  }

  @override
  String get conversation_durak_table_title => 'Mesa';

  @override
  String get conversation_durak_hand_title => 'Mão';

  @override
  String get conversation_durak_role_attacker => 'Atacando';

  @override
  String get conversation_durak_role_defender => 'Defendendo';

  @override
  String get conversation_durak_role_thrower => 'Jogando extra';

  @override
  String get conversation_durak_action_attack => 'Atacar';

  @override
  String get conversation_durak_action_defend => 'Defender';

  @override
  String get conversation_durak_action_take => 'Pegar';

  @override
  String get conversation_durak_action_beat => 'Bater';

  @override
  String get conversation_durak_action_transfer => 'Passar';

  @override
  String get conversation_durak_action_pass => 'Passar';

  @override
  String get conversation_durak_badge_taking => 'Vou pegar';

  @override
  String get conversation_durak_game_finished_title => 'Jogo finalizado';

  @override
  String get conversation_durak_game_finished_no_loser =>
      'Sem perdedor desta vez.';

  @override
  String conversation_durak_game_finished_loser(Object uid) {
    return 'Perdedor: $uid';
  }

  @override
  String conversation_durak_game_finished_winners(Object uids) {
    return 'Vencedores: $uids';
  }

  @override
  String get conversation_durak_winner => 'Vencedor!';

  @override
  String get conversation_durak_play_again => 'Jogar de novo';

  @override
  String get conversation_durak_back_to_chat => 'Voltar para o chat';

  @override
  String get conversation_game_lobby_waiting_opponent => 'Aguardando oponente…';

  @override
  String get conversation_durak_drop_zone => 'Solte a carta aqui para jogar';

  @override
  String get durak_settings_mode => 'Modo';

  @override
  String get durak_mode_podkidnoy => 'Podkidnoy';

  @override
  String get durak_mode_perevodnoy => 'Perevodnoy';

  @override
  String get durak_settings_max_players => 'Jogadores';

  @override
  String get durak_settings_deck => 'Baralho';

  @override
  String get durak_deck_36 => '36 cartas';

  @override
  String get durak_deck_52 => '52 cartas';

  @override
  String get durak_settings_with_jokers => 'Curingas';

  @override
  String get durak_settings_turn_timer => 'Tempo do turno';

  @override
  String get durak_turn_timer_off => 'Desativado';

  @override
  String get durak_settings_throw_in_policy => 'Quem pode jogar extras';

  @override
  String get durak_throw_in_policy_all =>
      'Todos os jogadores (exceto o defensor)';

  @override
  String get durak_throw_in_policy_neighbors =>
      'Apenas os vizinhos do defensor';

  @override
  String get durak_settings_shuler => 'Modo Shuler';

  @override
  String get durak_settings_shuler_subtitle =>
      'Permite jogadas ilegais a menos que alguém marque falta.';

  @override
  String get conversation_durak_action_foul => 'Falta!';

  @override
  String get conversation_durak_action_resolve => 'Confirmar Bater';

  @override
  String get conversation_durak_foul_toast => 'Falta! Trapaceiro penalizado.';

  @override
  String get durak_phase_prefix => 'Fase';

  @override
  String get durak_phase_attack => 'Ataque';

  @override
  String get durak_phase_defense => 'Defesa';

  @override
  String get durak_phase_throw_in => 'Jogada extra';

  @override
  String get durak_phase_resolution => 'Resolução';

  @override
  String get durak_phase_finished => 'Finalizado';

  @override
  String get durak_phase_pending_foul => 'Falta pendente após Bater';

  @override
  String get durak_phase_pending_foul_hint_attacker =>
      'Aguarde a falta. Se ninguém marcar, confirme Bater.';

  @override
  String get durak_phase_pending_foul_hint_other =>
      'Aguarde a falta. Marque Falta! se notou trapaça.';

  @override
  String get durak_phase_hint_can_throw_in => 'Você pode jogar extras';

  @override
  String get durak_phase_hint_wait => 'Aguarde sua vez';

  @override
  String durak_now_throwing_in(Object name) {
    return 'Jogando extra agora: $name';
  }

  @override
  String chat_selection_selected_count(int count) {
    return '$count selected';
  }

  @override
  String get chat_selection_tooltip_forward => 'Encaminhar';

  @override
  String get chat_selection_tooltip_delete => 'Excluir';

  @override
  String get chat_composer_hint_message => 'Digite uma mensagem…';

  @override
  String get chat_composer_tooltip_stickers => 'Figurinhas';

  @override
  String get chat_composer_tooltip_attachments => 'Anexos';

  @override
  String get chat_list_unread_separator => 'Mensagens não lidas';

  @override
  String get chat_e2ee_decrypt_failed_open_devices =>
      'Não foi possível descriptografar. Abra Configurações → Dispositivos';

  @override
  String get chat_e2ee_encrypted_message_placeholder =>
      'Mensagem criptografada';

  @override
  String chat_forwarded_from(Object name) {
    return 'Encaminhada de $name';
  }

  @override
  String get chat_outbox_retry => 'Tentar de novo';

  @override
  String get chat_outbox_remove => 'Remover';

  @override
  String get chat_outbox_cancel => 'Cancelar';

  @override
  String get chat_message_edited_badge_short => 'EDITADA';

  @override
  String get register_error_enter_name => 'Digite seu nome.';

  @override
  String get register_error_enter_username => 'Digite um nome de usuário.';

  @override
  String get register_error_enter_phone => 'Digite um número de telefone.';

  @override
  String get register_error_invalid_phone =>
      'Digite um número de telefone válido.';

  @override
  String get register_error_enter_email => 'Digite um email.';

  @override
  String get register_error_enter_password => 'Digite uma senha.';

  @override
  String get register_error_repeat_password => 'Repita a senha.';

  @override
  String get register_error_dob_format =>
      'Digite a data de nascimento no formato dd.mm.aaaa';

  @override
  String get register_error_accept_privacy_policy =>
      'Por favor, confirme que você aceita a política de privacidade';

  @override
  String get register_privacy_required =>
      'É obrigatório aceitar a política de privacidade';

  @override
  String get register_label_name => 'Nome';

  @override
  String get register_hint_name => 'Digite seu nome';

  @override
  String get register_label_username => 'Nome de usuário';

  @override
  String get register_hint_username => 'Digite um nome de usuário';

  @override
  String get register_label_phone => 'Telefone';

  @override
  String get register_hint_choose_country => 'Escolha um país';

  @override
  String get register_label_email => 'Email';

  @override
  String get register_hint_email => 'Digite seu email';

  @override
  String get register_label_password => 'Senha';

  @override
  String get register_hint_password => 'Digite sua senha';

  @override
  String get register_label_confirm_password => 'Confirmar senha';

  @override
  String get register_hint_confirm_password => 'Repita sua senha';

  @override
  String get register_label_dob => 'Data de nascimento';

  @override
  String get register_hint_dob => 'dd.mm.aaaa';

  @override
  String get register_label_bio => 'Sobre';

  @override
  String get register_hint_bio => 'Conte um pouco sobre você…';

  @override
  String get register_privacy_prefix => 'Eu aceito o ';

  @override
  String get register_privacy_link_text =>
      'Consentimento para o tratamento de dados pessoais';

  @override
  String get register_privacy_and => ' e ';

  @override
  String get register_terms_link_text => 'Acordo de privacidade do usuário';

  @override
  String get register_button_create_account => 'Criar conta';

  @override
  String get register_country_search_hint => 'Buscar por país ou código';

  @override
  String get register_date_picker_help => 'Data de nascimento';

  @override
  String get register_date_picker_cancel => 'Cancelar';

  @override
  String get register_date_picker_confirm => 'Selecionar';

  @override
  String get register_pick_avatar_title => 'Escolher avatar';

  @override
  String get edit_group_title => 'Editar grupo';

  @override
  String get edit_group_save => 'Salvar';

  @override
  String get edit_group_cancel => 'Cancelar';

  @override
  String get edit_group_name_label => 'Nome do grupo';

  @override
  String get edit_group_name_hint => 'Nome';

  @override
  String get edit_group_description_label => 'Descrição';

  @override
  String get edit_group_description_hint => 'Opcional';

  @override
  String get edit_group_pick_photo_tooltip =>
      'Toque para escolher uma foto do grupo. Toque longo para remover.';

  @override
  String get edit_group_error_name_required =>
      'Por favor, digite um nome para o grupo.';

  @override
  String get edit_group_error_save_failed => 'Falha ao salvar o grupo.';

  @override
  String get edit_group_error_not_found => 'Grupo não encontrado.';

  @override
  String get edit_group_error_permission_denied =>
      'Você não tem permissão para editar este grupo.';

  @override
  String get edit_group_success => 'Grupo atualizado.';

  @override
  String get edit_group_privacy_section => 'PRIVACIDADE';

  @override
  String get edit_group_privacy_forwarding => 'Encaminhamento de mensagens';

  @override
  String get edit_group_privacy_forwarding_desc =>
      'Permitir que membros encaminhem mensagens deste grupo.';

  @override
  String get edit_group_privacy_screenshots => 'Capturas de tela';

  @override
  String get edit_group_privacy_screenshots_desc =>
      'Permitir capturas de tela neste grupo (depende da plataforma).';

  @override
  String get edit_group_privacy_copy => 'Cópia de texto';

  @override
  String get edit_group_privacy_copy_desc =>
      'Permitir copiar o texto das mensagens.';

  @override
  String get edit_group_privacy_save_media => 'Salvar mídia';

  @override
  String get edit_group_privacy_save_media_desc =>
      'Permitir salvar fotos e vídeos no dispositivo.';

  @override
  String get edit_group_privacy_share_media => 'Compartilhar mídia';

  @override
  String get edit_group_privacy_share_media_desc =>
      'Permitir compartilhar arquivos de mídia fora do app.';

  @override
  String get schedule_message_sheet_title => 'Agendar mensagem';

  @override
  String get schedule_message_long_press_hint => 'Agendar envio';

  @override
  String schedule_message_preset_today_at(String time) {
    return 'Hoje às $time';
  }

  @override
  String schedule_message_preset_tomorrow_at(String time) {
    return 'Amanhã às $time';
  }

  @override
  String schedule_message_will_send_at(String datetime) {
    return 'Será enviada: $datetime';
  }

  @override
  String get schedule_message_must_be_in_future =>
      'O horário precisa ser no futuro (pelo menos um minuto a partir de agora).';

  @override
  String get schedule_message_e2ee_warning =>
      'Este é um chat E2EE. A mensagem agendada será armazenada no servidor em texto plano e publicada sem criptografia.';

  @override
  String get schedule_message_cancel => 'Cancelar';

  @override
  String get schedule_message_confirm => 'Agendar';

  @override
  String get schedule_message_save => 'Salvar';

  @override
  String get schedule_message_text_required => 'Digite uma mensagem primeiro';

  @override
  String get schedule_message_attachments_unsupported_mobile =>
      'Agendar com anexos é suportado apenas na web no momento';

  @override
  String schedule_message_scheduled_toast(String datetime) {
    return 'Agendada: $datetime';
  }

  @override
  String schedule_message_failed_toast(String error) {
    return 'Falha ao agendar: $error';
  }

  @override
  String get scheduled_messages_screen_title => 'Mensagens agendadas';

  @override
  String get scheduled_messages_empty_title => 'Nenhuma mensagem agendada';

  @override
  String get scheduled_messages_empty_hint =>
      'Mantenha o botão Enviar pressionado para agendar uma mensagem.';

  @override
  String scheduled_messages_load_failed(String error) {
    return 'Falha ao carregar: $error';
  }

  @override
  String get scheduled_messages_e2ee_notice =>
      'Em um chat E2EE, as mensagens agendadas são armazenadas e publicadas em texto plano.';

  @override
  String get scheduled_messages_cancel_dialog_title =>
      'Cancelar envio agendado?';

  @override
  String get scheduled_messages_cancel_dialog_body =>
      'A mensagem agendada será excluída.';

  @override
  String get scheduled_messages_cancel_dialog_keep => 'Manter';

  @override
  String get scheduled_messages_cancel_dialog_confirm => 'Cancelar';

  @override
  String get scheduled_messages_canceled_toast => 'Cancelada';

  @override
  String scheduled_messages_time_changed_toast(String datetime) {
    return 'Horário alterado: $datetime';
  }

  @override
  String scheduled_messages_action_failed_toast(String error) {
    return 'Erro: $error';
  }

  @override
  String get scheduled_messages_tile_edit_tooltip => 'Alterar horário';

  @override
  String get scheduled_messages_tile_cancel_tooltip => 'Cancelar';

  @override
  String scheduled_messages_preview_poll(String question) {
    return 'Enquete: $question';
  }

  @override
  String get scheduled_messages_preview_location => 'Localização';

  @override
  String get scheduled_messages_preview_attachment => 'Anexo';

  @override
  String scheduled_messages_preview_attachment_count(int count) {
    return 'Anexo (×$count)';
  }

  @override
  String get scheduled_messages_preview_message => 'Mensagem';

  @override
  String get chat_header_tooltip_scheduled => 'Mensagens agendadas';

  @override
  String get schedule_date_label => 'Data';

  @override
  String get schedule_time_label => 'Horário';

  @override
  String get common_done => 'Pronto';

  @override
  String get common_send => 'Enviar';

  @override
  String get common_open => 'Abrir';

  @override
  String get common_add => 'Adicionar';

  @override
  String get common_search => 'Buscar';

  @override
  String get common_edit => 'Editar';

  @override
  String get common_next => 'Próximo';

  @override
  String get common_ok => 'OK';

  @override
  String get common_confirm => 'Confirmar';

  @override
  String get common_ready => 'Pronto';

  @override
  String get common_error => 'Erro';

  @override
  String get common_yes => 'Sim';

  @override
  String get common_no => 'Não';

  @override
  String get common_back => 'Voltar';

  @override
  String get common_continue => 'Continuar';

  @override
  String get common_loading => 'Carregando…';

  @override
  String get common_copy => 'Copiar';

  @override
  String get common_share => 'Compartilhar';

  @override
  String get common_settings => 'Configurações';

  @override
  String get common_today => 'Hoje';

  @override
  String get common_yesterday => 'Ontem';

  @override
  String get e2ee_qr_title => 'Pareamento de chaves por QR';

  @override
  String get e2ee_qr_uid_error => 'Falha ao obter o uid do usuário.';

  @override
  String get e2ee_qr_session_ended_error =>
      'A sessão terminou antes da resposta do segundo dispositivo.';

  @override
  String get e2ee_qr_no_data_error => 'Sem dados para aplicar a chave.';

  @override
  String get e2ee_qr_key_transferred_toast =>
      'Chave transferida. Reabra os chats para atualizar as sessões.';

  @override
  String get e2ee_qr_wrong_account_error =>
      'O QR foi gerado para uma conta diferente.';

  @override
  String get e2ee_qr_explainer_title => 'O que é isso';

  @override
  String get e2ee_qr_explainer_text =>
      'Transfira uma chave privada de um dos seus dispositivos para outro via ECDH + QR. Os dois lados veem um código de 6 dígitos para verificação manual.';

  @override
  String get e2ee_qr_show_qr_label => 'Estou no novo dispositivo — mostrar QR';

  @override
  String get e2ee_qr_scan_qr_label => 'Já tenho uma chave — escanear QR';

  @override
  String get e2ee_qr_scan_hint =>
      'Escaneie o QR no dispositivo antigo que já tem a chave.';

  @override
  String get e2ee_qr_verify_code_label =>
      'Confirme o código de 6 dígitos com o dispositivo antigo:';

  @override
  String e2ee_qr_transfer_from_device_label(String label) {
    return 'Transferir do dispositivo: $label';
  }

  @override
  String get e2ee_qr_code_match_apply_label => 'O código confere — aplicar';

  @override
  String get e2ee_qr_key_success_label =>
      'Chave transferida com sucesso para este dispositivo. Reabra os chats.';

  @override
  String get e2ee_qr_unknown_error => 'Erro desconhecido';

  @override
  String get e2ee_qr_back_to_pick_label => 'Voltar à seleção';

  @override
  String get e2ee_qr_donor_scan_hint =>
      'Aponte a câmera para o QR mostrado no novo dispositivo.';

  @override
  String get e2ee_qr_donor_verify_code_label =>
      'Confirme o código com o novo dispositivo:';

  @override
  String get e2ee_qr_donor_verify_hint =>
      'Se o código conferir — confirme no novo dispositivo. Se não, pressione Cancelar imediatamente.';

  @override
  String get e2ee_encrypt_title => 'Criptografia';

  @override
  String get e2ee_encrypt_enable_dialog_title => 'Ativar criptografia?';

  @override
  String get e2ee_encrypt_enable_dialog_body =>
      'Novas mensagens só ficarão disponíveis nos seus dispositivos e nos do seu contato. As mensagens antigas continuam como estão.';

  @override
  String get e2ee_encrypt_enable_label => 'Ativar';

  @override
  String get e2ee_encrypt_disable_dialog_title => 'Desativar criptografia?';

  @override
  String get e2ee_encrypt_disable_dialog_body =>
      'Novas mensagens serão enviadas sem criptografia de ponta a ponta. As mensagens criptografadas já enviadas permanecem na conversa.';

  @override
  String get e2ee_encrypt_disable_label => 'Desativar';

  @override
  String get e2ee_encrypt_status_on =>
      'A criptografia de ponta a ponta está ativada para este chat.';

  @override
  String get e2ee_encrypt_status_off =>
      'A criptografia de ponta a ponta está desativada.';

  @override
  String get e2ee_encrypt_description =>
      'Quando a criptografia está ativada, o conteúdo das novas mensagens só fica disponível para os participantes do chat nos seus dispositivos. Desativar afeta apenas as novas mensagens.';

  @override
  String get e2ee_encrypt_switch_title => 'Ativar criptografia';

  @override
  String e2ee_encrypt_switch_on(int epoch) {
    return 'Ativada (época da chave: $epoch)';
  }

  @override
  String get e2ee_encrypt_switch_off => 'Desativada';

  @override
  String get e2ee_encrypt_already_on_toast =>
      'A criptografia já está ativada ou a criação de chave falhou. Verifique a rede e as chaves do seu contato.';

  @override
  String get e2ee_encrypt_no_device_toast =>
      'Não foi possível ativar: o contato não tem dispositivo ativo com chave.';

  @override
  String e2ee_encrypt_enable_failed_toast(String error) {
    return 'Falha ao ativar a criptografia: $error';
  }

  @override
  String e2ee_encrypt_disable_failed_toast(String error) {
    return 'Falha ao desativar: $error';
  }

  @override
  String get e2ee_encrypt_data_types_title => 'Tipos de dado';

  @override
  String get e2ee_encrypt_data_types_description =>
      'Esta configuração não muda o protocolo. Ela controla quais tipos de dado são enviados criptografados.';

  @override
  String get e2ee_encrypt_override_title =>
      'Configurações de criptografia para este chat';

  @override
  String get e2ee_encrypt_override_on =>
      'As configurações específicas do chat estão em uso.';

  @override
  String get e2ee_encrypt_override_off =>
      'As configurações globais são herdadas.';

  @override
  String get e2ee_encrypt_text_title => 'Texto da mensagem';

  @override
  String get e2ee_encrypt_media_title => 'Anexos (mídia/arquivos)';

  @override
  String get e2ee_encrypt_override_hint =>
      'Para alterar para este chat — ative a sobrescrita.';

  @override
  String get sticker_default_pack_name => 'Meu pacote';

  @override
  String get sticker_new_pack_dialog_title => 'Novo pacote de figurinhas';

  @override
  String get sticker_pack_name_hint => 'Nome';

  @override
  String get sticker_save_to_pack => 'Salvar no pacote de figurinhas';

  @override
  String get sticker_no_packs_hint => 'Sem pacotes. Crie um na aba Figurinhas.';

  @override
  String get sticker_new_pack_option => 'Novo pacote…';

  @override
  String get sticker_pick_image_or_gif => 'Escolha uma imagem ou GIF';

  @override
  String sticker_send_failed(String error) {
    return 'Falha ao enviar: $error';
  }

  @override
  String get sticker_saved_to_pack => 'Salvo no pacote de figurinhas';

  @override
  String get sticker_save_gif_failed =>
      'Não foi possível baixar ou salvar o GIF';

  @override
  String get sticker_delete_pack_title => 'Excluir pacote?';

  @override
  String sticker_delete_pack_body(String name) {
    return '\"$name\" e todas as figurinhas dentro serão excluídas.';
  }

  @override
  String get sticker_pack_deleted => 'Pacote excluído';

  @override
  String get sticker_pack_delete_failed => 'Falha ao excluir o pacote';

  @override
  String get sticker_tab_emoji => 'EMOJI';

  @override
  String get sticker_tab_stickers => 'FIGURINHAS';

  @override
  String get sticker_tab_gif => 'GIF';

  @override
  String get sticker_scope_my => 'Meus';

  @override
  String get sticker_scope_public => 'Públicos';

  @override
  String get sticker_new_pack_tooltip => 'Novo pacote';

  @override
  String get sticker_pack_created => 'Pacote de figurinhas criado';

  @override
  String get sticker_no_packs_create => 'Sem pacotes de figurinhas. Crie um.';

  @override
  String get sticker_public_packs_empty => 'Nenhum pacote público configurado';

  @override
  String get sticker_section_recent => 'RECENTES';

  @override
  String get sticker_pack_empty_hint =>
      'Pacote vazio. Adicione do dispositivo (aba GIF — \"Para meu pacote\").';

  @override
  String get sticker_delete_sticker_title => 'Excluir figurinha?';

  @override
  String get sticker_deleted => 'Excluída';

  @override
  String get sticker_gallery => 'Galeria';

  @override
  String get sticker_gallery_subtitle =>
      'Fotos, PNG, GIF do dispositivo — direto no chat';

  @override
  String get gif_search_hint => 'Buscar GIF…';

  @override
  String gif_translated_hint(String query) {
    return 'Buscado: $query';
  }

  @override
  String get gif_search_unavailable =>
      'A busca de GIFs está temporariamente indisponível.';

  @override
  String get gif_filter_all => 'Todos';

  @override
  String get sticker_section_animated => 'ANIMADAS';

  @override
  String get sticker_emoji_unavailable =>
      'Conversão emoji-para-texto não está disponível para esta janela.';

  @override
  String get sticker_create_pack_hint => 'Crie um pacote com o botão +';

  @override
  String get sticker_public_packs_unavailable =>
      'Pacotes públicos ainda não estão disponíveis';

  @override
  String get composer_link_title => 'Link';

  @override
  String get composer_link_apply => 'Aplicar';

  @override
  String get composer_attach_title => 'Anexar';

  @override
  String get composer_attach_photo_video => 'Foto/Vídeo';

  @override
  String get composer_attach_files => 'Arquivos';

  @override
  String get composer_attach_video_circle => 'Nota em vídeo';

  @override
  String get composer_attach_location => 'Localização';

  @override
  String get composer_attach_poll => 'Enquete';

  @override
  String get composer_attach_stickers => 'Figurinhas';

  @override
  String get composer_attach_clipboard => 'Área de transferência';

  @override
  String get composer_attach_text => 'Texto';

  @override
  String get meeting_create_poll => 'Criar enquete';

  @override
  String get meeting_min_two_options =>
      'São necessárias pelo menos 2 opções de resposta';

  @override
  String meeting_error_with_details(String details) {
    return 'Erro: $details';
  }

  @override
  String meeting_polls_load_error(String details) {
    return 'Falha ao carregar enquetes: $details';
  }

  @override
  String get meeting_no_polls_yet => 'Sem enquetes ainda';

  @override
  String get meeting_question_label => 'Pergunta';

  @override
  String get meeting_options_label => 'Opções';

  @override
  String meeting_option_hint(int index) {
    return 'Opção $index';
  }

  @override
  String get meeting_add_option => 'Adicionar opção';

  @override
  String get meeting_anonymous => 'Anônima';

  @override
  String get meeting_anonymous_subtitle =>
      'Quem pode ver as escolhas dos outros';

  @override
  String get meeting_save_as_draft => 'Salvar como rascunho';

  @override
  String get meeting_publish => 'Publicar';

  @override
  String get meeting_action_start => 'Iniciar';

  @override
  String get meeting_action_change_vote => 'Alterar voto';

  @override
  String get meeting_action_restart => 'Reiniciar';

  @override
  String get meeting_action_stop => 'Encerrar';

  @override
  String meeting_vote_failed(String details) {
    return 'Voto não contabilizado: $details';
  }

  @override
  String get meeting_status_ended => 'Encerrada';

  @override
  String get meeting_status_draft => 'Rascunho';

  @override
  String get meeting_status_active => 'Ativa';

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
  String get meeting_who_voted => 'Quem votou';

  @override
  String meeting_participants_tab(int count) {
    return 'Membros ($count)';
  }

  @override
  String meeting_polls_tab_active(int count) {
    return 'Enquetes ($count)';
  }

  @override
  String get meeting_polls_tab => 'Enquetes';

  @override
  String meeting_chat_tab_unread(int count) {
    return 'Chat ($count)';
  }

  @override
  String get meeting_chat_tab => 'Chat';

  @override
  String meeting_requests_tab(int count) {
    return 'Solicitações ($count)';
  }

  @override
  String meeting_you_suffix(String name) {
    return '$name (Você)';
  }

  @override
  String get meeting_host_label => 'Anfitrião';

  @override
  String get meeting_force_mute_mic => 'Silenciar microfone';

  @override
  String get meeting_force_mute_camera => 'Desligar câmera';

  @override
  String get meeting_kick_from_room => 'Remover da sala';

  @override
  String meeting_chat_load_error(Object error) {
    return 'Não foi possível carregar o chat: $error';
  }

  @override
  String get meeting_no_requests => 'Sem novas solicitações';

  @override
  String get meeting_no_messages_yet => 'Sem mensagens ainda';

  @override
  String meeting_file_too_large(String name) {
    return 'Arquivo muito grande: $name';
  }

  @override
  String meeting_send_failed(String details) {
    return 'Falha ao enviar: $details';
  }

  @override
  String get meeting_edit_message_title => 'Editar mensagem';

  @override
  String meeting_save_failed(String details) {
    return 'Falha ao salvar: $details';
  }

  @override
  String get meeting_delete_message_title => 'Excluir mensagem?';

  @override
  String get meeting_delete_message_body =>
      'Os membros verão \"Mensagem excluída\".';

  @override
  String meeting_delete_failed(String details) {
    return 'Falha ao excluir: $details';
  }

  @override
  String get meeting_message_hint => 'Mensagem…';

  @override
  String get meeting_message_deleted => 'Mensagem excluída';

  @override
  String get meeting_message_edited => '• editada';

  @override
  String get meeting_copy_action => 'Copiar';

  @override
  String get meeting_edit_action => 'Editar';

  @override
  String get meeting_join_title => 'Entrar';

  @override
  String meeting_loading_error(String details) {
    return 'Erro ao carregar a reunião: $details';
  }

  @override
  String get meeting_not_found => 'Reunião não encontrada ou encerrada';

  @override
  String get meeting_private_description =>
      'Reunião privada: o anfitrião decide se deixa você entrar após sua solicitação.';

  @override
  String get meeting_public_description =>
      'Reunião aberta: entre pelo link sem esperar.';

  @override
  String get meeting_your_name_label => 'Seu nome';

  @override
  String get meeting_enter_name_error => 'Digite seu nome';

  @override
  String get meeting_guest_name => 'Convidado';

  @override
  String get meeting_enter_room => 'Entrar na sala';

  @override
  String get meeting_request_join => 'Solicitar entrada';

  @override
  String get meeting_approved_title => 'Aprovado';

  @override
  String get meeting_approved_subtitle => 'Redirecionando para a sala…';

  @override
  String get meeting_denied_title => 'Negado';

  @override
  String get meeting_denied_subtitle => 'O anfitrião negou sua solicitação.';

  @override
  String get meeting_pending_title => 'Aguardando aprovação';

  @override
  String get meeting_pending_subtitle =>
      'O anfitrião verá sua solicitação e decidirá quando deixar você entrar.';

  @override
  String meeting_load_error(String details) {
    return 'Falha ao carregar a reunião: $details';
  }

  @override
  String meeting_init_error(Object error) {
    return 'Erro de inicialização: $error';
  }

  @override
  String meeting_participants_error(Object error) {
    return 'Membros: $error';
  }

  @override
  String meeting_bg_unavailable(Object error) {
    return 'Plano de fundo indisponível: $error';
  }

  @override
  String get meeting_leave => 'Sair';

  @override
  String get meeting_screen_share_ios =>
      'Compartilhamento de tela no iOS requer Broadcast Extension (em breve)';

  @override
  String meeting_screen_share_failed(String details) {
    return 'Falha ao iniciar o compartilhamento de tela: $details';
  }

  @override
  String get meeting_tooltip_speaker_mode => 'Modo orador';

  @override
  String get meeting_tooltip_grid_mode => 'Modo grade';

  @override
  String get meeting_tooltip_copy_link => 'Copiar link (entrar pelo navegador)';

  @override
  String get meeting_mic_on => 'Ativar microfone';

  @override
  String get meeting_mic_off => 'Silenciar';

  @override
  String get meeting_camera_on => 'Ligar câmera';

  @override
  String get meeting_camera_off => 'Desligar câmera';

  @override
  String get meeting_switch_camera => 'Alternar';

  @override
  String get meeting_hand_lower => 'Abaixar';

  @override
  String get meeting_hand_raise => 'Mão';

  @override
  String get meeting_reaction => 'Reação';

  @override
  String get meeting_screen_stop => 'Parar';

  @override
  String get meeting_screen_label => 'Tela';

  @override
  String get meeting_bg_off => 'BG';

  @override
  String get meeting_bg_blur => 'Desfoque';

  @override
  String get meeting_bg_image => 'Imagem';

  @override
  String get meeting_participants_button => 'Membros';

  @override
  String get meeting_notifications_button => 'Активность';

  @override
  String get meeting_pip_button => 'Свернуть';

  @override
  String get settings_chats_bottom_nav_icons_title => 'Bottom navigation icons';

  @override
  String get settings_chats_bottom_nav_icons_subtitle =>
      'Escolha ícones e estilo visual como na web.';

  @override
  String get settings_chats_nav_colorful => 'Colorful';

  @override
  String get settings_chats_nav_minimal => 'Minimal';

  @override
  String get settings_chats_nav_global_title => 'Para todos os ícones';

  @override
  String get settings_chats_nav_global_subtitle =>
      'Global layer: color, size, stroke width, and tile background.';

  @override
  String get settings_chats_reset_tooltip => 'Restaurar';

  @override
  String get settings_chats_collapse => 'Collapse';

  @override
  String get settings_chats_customize => 'Personalizar';

  @override
  String get settings_chats_reset_item_tooltip => 'Restaurar';

  @override
  String get settings_chats_style_tooltip => 'Estilo';

  @override
  String get settings_chats_icon_size => 'Icon size';

  @override
  String get settings_chats_stroke_width => 'Stroke width';

  @override
  String get settings_chats_default => 'Padrão';

  @override
  String get settings_chats_icon_search_hint_en => 'Buscar por nome...';

  @override
  String get settings_chats_emoji_effects => 'Emoji effects';

  @override
  String get settings_chats_emoji_effects_subtitle =>
      'Perfil de animação para o efeito de emoji em tela cheia ao tocar em um único emoji no chat.';

  @override
  String get settings_chats_emoji_lite_desc =>
      'Lite: carga mínima e fluidez máxima em dispositivos modestos.';

  @override
  String get settings_chats_emoji_balanced_desc =>
      'Balanced: automatic compromise between performance and expressiveness.';

  @override
  String get settings_chats_emoji_cinematic_desc =>
      'Cinematic: máximo de partículas e profundidade para um efeito uau.';

  @override
  String get settings_chats_preview_incoming_msg => 'Oi! Tudo bem?';

  @override
  String get settings_chats_preview_outgoing_msg => 'Great, thanks!';

  @override
  String get settings_chats_preview_hello => 'Olá';

  @override
  String get chat_theme_title => 'Tema do chat';

  @override
  String chat_theme_error_save(String error) {
    return 'Falha ao salvar background: $error';
  }

  @override
  String chat_theme_error_upload(String error) {
    return 'Plano de fundo upload error: $error';
  }

  @override
  String get chat_theme_delete_title => 'Excluir plano de fundo da galeria?';

  @override
  String get chat_theme_delete_body =>
      'A imagem será removida da sua lista de planos de fundo. Você pode escolher outra para este chat.';

  @override
  String chat_theme_error_delete(String error) {
    return 'Excluir error: $error';
  }

  @override
  String get chat_theme_banner =>
      'O plano de fundo deste chat é só para você. As configurações globais em \"Configurações do chat\" permanecem inalteradas.';

  @override
  String get chat_theme_current_bg => 'Plano de fundo atual';

  @override
  String get chat_theme_default_global => 'Padrão (global settings)';

  @override
  String get chat_theme_presets => 'Pré-ajustes';

  @override
  String get chat_theme_global_tile => 'Global';

  @override
  String get chat_theme_pick_hint => 'Escolher a preset or photo from gallery';

  @override
  String get contacts_title => 'Contatos';

  @override
  String get contacts_add_phone_prompt =>
      'Adicione um número de telefone no seu perfil para buscar contatos por número.';

  @override
  String get contacts_fallback_profile => 'Perfil';

  @override
  String get contacts_fallback_user => 'Usuário';

  @override
  String get contacts_status_online => 'online';

  @override
  String get contacts_status_recently => 'Visto recentemente';

  @override
  String contacts_status_today_at(String time) {
    return 'Visto às $time';
  }

  @override
  String get contacts_status_yesterday => 'Visto ontem';

  @override
  String get contacts_status_year_ago => 'Visto há um ano';

  @override
  String contacts_status_years_ago(String years) {
    return 'Visto há $years';
  }

  @override
  String contacts_status_date(String date) {
    return 'Visto em $date';
  }

  @override
  String get contacts_empty_state =>
      'Nenhum contato encontrado.\nToque no botão à direita para sincronizar a agenda do seu telefone.';

  @override
  String get add_contact_title => 'Novo contato';

  @override
  String get add_contact_sync_off => 'A sincronização está desativada no app.';

  @override
  String get add_contact_enable_system_access =>
      'Ative o acesso aos contatos para o LighChat nas configurações do sistema.';

  @override
  String get add_contact_sync_on => 'Sincronização ativada';

  @override
  String get add_contact_sync_failed =>
      'Não foi possível ativar a sincronização de contatos';

  @override
  String get add_contact_invalid_phone => 'Digite um número de telefone válido';

  @override
  String get add_contact_not_found_by_phone =>
      'Nenhum contato encontrado para este número';

  @override
  String get add_contact_found => 'Contato encontrado';

  @override
  String add_contact_search_error(String error) {
    return 'Falha na busca: $error';
  }

  @override
  String get add_contact_qr_no_profile =>
      'O QR code não contém um perfil do LighChat';

  @override
  String get add_contact_qr_own_profile => 'Este é o seu próprio perfil';

  @override
  String get add_contact_qr_profile_not_found =>
      'Perfil do QR code não encontrado';

  @override
  String get add_contact_qr_found => 'Contato encontrado pelo QR code';

  @override
  String add_contact_qr_read_error(String error) {
    return 'Não foi possível ler o QR code: $error';
  }

  @override
  String get add_contact_cannot_add_user =>
      'Não é possível adicionar este usuário';

  @override
  String add_contact_add_error(String error) {
    return 'Não foi possível adicionar o contato: $error';
  }

  @override
  String get add_contact_country_search_hint => 'Buscar país ou código';

  @override
  String get add_contact_sync_with_phone => 'Sincronizar com o telefone';

  @override
  String get add_contact_add_by_qr => 'Adicionar por QR code';

  @override
  String get add_contact_results_unavailable =>
      'Resultados ainda não disponíveis';

  @override
  String add_contact_profile_load_error(String error) {
    return 'Não foi possível carregar o contato: $error';
  }

  @override
  String get add_contact_profile_not_found => 'Perfil não encontrado';

  @override
  String get add_contact_badge_already_added => 'Já adicionado';

  @override
  String get add_contact_badge_new => 'Novo contato';

  @override
  String get add_contact_badge_unavailable => 'Indisponível';

  @override
  String get add_contact_open_contact => 'Abrir contato';

  @override
  String get add_contact_add_to_contacts => 'Adicionar aos contatos';

  @override
  String get add_contact_add_unavailable => 'Adicionar indisponível';

  @override
  String get add_contact_searching => 'Procurando contato...';

  @override
  String get add_contact_scan_qr_title => 'Escanear QR code';

  @override
  String get add_contact_flash_tooltip => 'Flash';

  @override
  String get add_contact_scan_qr_hint =>
      'Aponte sua câmera para um QR code de perfil do LighChat';

  @override
  String get contacts_edit_enter_name => 'Digite o nome do contato.';

  @override
  String contacts_edit_save_error(String error) {
    return 'Não foi possível salvar o contato: $error';
  }

  @override
  String get contacts_edit_first_name_hint => 'Nome';

  @override
  String get contacts_edit_last_name_hint => 'Sobrenome';

  @override
  String get contacts_edit_name_disclaimer =>
      'Este nome é visível apenas para você: nos chats, na busca e na lista de contatos.';

  @override
  String contacts_edit_error(String error) {
    return 'Erro: $error';
  }

  @override
  String get chat_settings_color_default => 'Padrão';

  @override
  String get chat_settings_color_lilac => 'Lilás';

  @override
  String get chat_settings_color_pink => 'Rosa';

  @override
  String get chat_settings_color_green => 'Verde';

  @override
  String get chat_settings_color_coral => 'Coral';

  @override
  String get chat_settings_color_mint => 'Menta';

  @override
  String get chat_settings_color_sky => 'Céu';

  @override
  String get chat_settings_color_purple => 'Roxo';

  @override
  String get chat_settings_color_crimson => 'Carmesim';

  @override
  String get chat_settings_color_tiffany => 'Tiffany';

  @override
  String get chat_settings_color_yellow => 'Amarelo';

  @override
  String get chat_settings_color_powder => 'Pó';

  @override
  String get chat_settings_color_turquoise => 'Turquesa';

  @override
  String get chat_settings_color_blue => 'Azul';

  @override
  String get chat_settings_color_sunset => 'Pôr do sol';

  @override
  String get chat_settings_color_tender => 'Suave';

  @override
  String get chat_settings_color_lime => 'Lima';

  @override
  String get chat_settings_color_graphite => 'Grafite';

  @override
  String get chat_settings_color_no_bg => 'Sem plano de fundo';

  @override
  String get chat_settings_icon_color => 'Cor do ícone';

  @override
  String get chat_settings_icon_size => 'Tamanho do ícone';

  @override
  String get chat_settings_stroke_width => 'Espessura do traço';

  @override
  String get chat_settings_tile_background => 'Plano de fundo do bloco';

  @override
  String get chat_settings_bottom_nav_icons => 'Ícones da navegação inferior';

  @override
  String get chat_settings_bottom_nav_description =>
      'Escolha ícones e estilo visual como na web.';

  @override
  String get chat_settings_bottom_nav_global_description =>
      'Camada compartilhada: cor, tamanho, traço e plano de fundo do bloco.';

  @override
  String get chat_settings_colorful => 'Colorido';

  @override
  String get chat_settings_minimalism => 'Minimalista';

  @override
  String get chat_settings_for_all_icons => 'Para todos os ícones';

  @override
  String get chat_settings_customize => 'Personalizar';

  @override
  String get chat_settings_hide => 'Ocultar';

  @override
  String get chat_settings_reset => 'Restaurar';

  @override
  String get chat_settings_reset_item => 'Restaurar';

  @override
  String get chat_settings_style => 'Estilo';

  @override
  String get chat_settings_select => 'Selecionar';

  @override
  String get chat_settings_reset_size => 'Restaurar tamanho';

  @override
  String get chat_settings_reset_stroke => 'Restaurar traço';

  @override
  String get chat_settings_default_gradient => 'Gradiente padrão';

  @override
  String get chat_settings_inherit_global => 'Herdar do global';

  @override
  String get chat_settings_no_bg_on => 'Sem plano de fundo (ativado)';

  @override
  String get chat_settings_no_bg => 'Sem plano de fundo';

  @override
  String get chat_settings_outgoing_messages => 'Mensagens enviadas';

  @override
  String get chat_settings_incoming_messages => 'Mensagens recebidas';

  @override
  String get chat_settings_font_size => 'Tamanho da fonte';

  @override
  String get chat_settings_font_small => 'Pequeno';

  @override
  String get chat_settings_font_medium => 'Médio';

  @override
  String get chat_settings_font_large => 'Grande';

  @override
  String get chat_settings_bubble_shape => 'Forma do balão';

  @override
  String get chat_settings_bubble_rounded => 'Arredondado';

  @override
  String get chat_settings_bubble_square => 'Quadrado';

  @override
  String get chat_settings_chat_background => 'Plano de fundo do chat';

  @override
  String get chat_settings_background_hint =>
      'Escolha uma foto da galeria ou personalize';

  @override
  String get chat_settings_emoji_effects => 'Efeitos de emoji';

  @override
  String get chat_settings_emoji_description =>
      'Perfil de animação para emoji em tela cheia ao tocar no chat.';

  @override
  String get chat_settings_emoji_lite =>
      'Lite: carga mínima, mais fluida em dispositivos modestos.';

  @override
  String get chat_settings_emoji_cinematic =>
      'Cinematic: máximo de partículas e profundidade para um efeito uau.';

  @override
  String get chat_settings_emoji_balanced =>
      'Balanced: equilíbrio automático entre desempenho e expressividade.';

  @override
  String get chat_settings_additional => 'Adicionais';

  @override
  String get chat_settings_show_time => 'Mostrar horário';

  @override
  String get chat_settings_show_time_hint =>
      'Horário do envio abaixo das mensagens';

  @override
  String get chat_settings_reset_all => 'Restaurar configurações';

  @override
  String get chat_settings_preview_incoming => 'Oi! Tudo bem?';

  @override
  String get chat_settings_preview_outgoing => 'Tudo ótimo, obrigado!';

  @override
  String get chat_settings_preview_hello => 'Olá';

  @override
  String chat_settings_icon_picker_title(String label) {
    return 'Ícone: \"$label\"';
  }

  @override
  String get chat_settings_search_hint => 'Buscar por nome (eng.)...';

  @override
  String meeting_tab_participants(Object count) {
    return 'Membros ($count)';
  }

  @override
  String get meeting_tab_polls => 'Enquetes';

  @override
  String meeting_tab_polls_count(Object count) {
    return 'Enquetes ($count)';
  }

  @override
  String get meeting_tab_chat => 'Chat';

  @override
  String meeting_tab_chat_count(Object count) {
    return 'Chat ($count)';
  }

  @override
  String meeting_tab_requests(Object count) {
    return 'Solicitações ($count)';
  }

  @override
  String get meeting_kick => 'Remover da sala';

  @override
  String meeting_file_too_big(Object name) {
    return 'Arquivo too big: $name';
  }

  @override
  String meeting_send_error(Object error) {
    return 'Não foi possível enviar: $error';
  }

  @override
  String meeting_save_error(Object error) {
    return 'Não foi possível salvar: $error';
  }

  @override
  String meeting_delete_error(Object error) {
    return 'Não foi possível excluir: $error';
  }

  @override
  String get meeting_no_messages => 'Sem mensagens ainda';

  @override
  String get meeting_join_enter_name => 'Digite seu nome';

  @override
  String get meeting_join_guest => 'Convidado';

  @override
  String get meeting_join_as_label => 'Вы войдёте как';

  @override
  String get meeting_lobby_camera_blocked =>
      'Доступ к камере не выдан. Вы войдёте с выключенной камерой.';

  @override
  String get meeting_join_button => 'Entrar';

  @override
  String meeting_join_load_error(Object error) {
    return 'Reunião load error: $error';
  }

  @override
  String get meeting_private_hint =>
      'Reunião privada: o anfitrião decide se deixa você entrar após sua solicitação.';

  @override
  String get meeting_public_hint =>
      'Abrir meeting: join via link without waiting.';

  @override
  String get meeting_name_label => 'Seu nome';

  @override
  String get meeting_waiting_title => 'Aguardando aprovação';

  @override
  String get meeting_waiting_subtitle =>
      'O anfitrião verá sua solicitação e decidirá quando deixar você entrar.';

  @override
  String get meeting_screen_share_ios_hint =>
      'Compartilhamento de tela no iOS requer um Broadcast Extension (em desenvolvimento).';

  @override
  String meeting_screen_share_error(Object error) {
    return 'Não foi possível iniciar screen sharing: $error';
  }

  @override
  String get meeting_speaker_mode => 'Alto-falante mode';

  @override
  String get meeting_grid_mode => 'Modo grade';

  @override
  String get meeting_copy_link_tooltip => 'Copiar link (browser entry)';

  @override
  String get group_members_subtitle_creator => 'Grupo creator';

  @override
  String get group_members_subtitle_admin => 'Administrador';

  @override
  String get group_members_subtitle_member => 'Membro';

  @override
  String group_members_total_count(int count) {
    return 'Total: $count';
  }

  @override
  String get group_members_copy_invite_tooltip => 'Copiar invite link';

  @override
  String get group_members_add_member_tooltip => 'Adicionar member';

  @override
  String get group_members_invite_copied => 'Invite link copied';

  @override
  String group_members_copy_link_error(String error) {
    return 'Falha ao copiar link: $error';
  }

  @override
  String get group_members_added => 'Membros added';

  @override
  String get group_members_revoke_admin_title => 'Revoke admin privileges?';

  @override
  String group_members_revoke_admin_body(String name) {
    return '$name perderá os privilégios de admin. Continuará no grupo como membro comum.';
  }

  @override
  String get group_members_grant_admin_title => 'Grant admin privileges?';

  @override
  String group_members_grant_admin_body(String name) {
    return '$name receberá privilégios de admin: poderá editar o grupo, remover membros e gerenciar mensagens.';
  }

  @override
  String get group_members_revoke_admin_action => 'Revoke';

  @override
  String get group_members_grant_admin_action => 'Grant';

  @override
  String get group_members_remove_title => 'Remove member?';

  @override
  String group_members_remove_body(String name) {
    return '$name será removido do grupo. Você pode desfazer adicionando o membro novamente.';
  }

  @override
  String get group_members_remove_action => 'Remove';

  @override
  String get group_members_removed => 'Membro removed';

  @override
  String get group_members_menu_revoke_admin => 'Remove admin';

  @override
  String get group_members_menu_grant_admin => 'Tornar admin';

  @override
  String get group_members_menu_remove => 'Remover do grupo';

  @override
  String get group_members_creator_badge => 'CREATOR';

  @override
  String get group_members_add_title => 'Adicionar membros';

  @override
  String get group_members_search_contacts => 'Buscar contatos';

  @override
  String get group_members_all_in_group =>
      'Todos os seus contatos já estão no grupo.';

  @override
  String get group_members_nobody_found => 'Nobody found.';

  @override
  String get group_members_user_fallback => 'User';

  @override
  String get group_members_select_members => 'Selecionar members';

  @override
  String group_members_add_count(int count) {
    return 'Adicionar ($count)';
  }

  @override
  String group_members_contacts_load_error(String error) {
    return 'Falha ao carregar contacts: $error';
  }

  @override
  String group_members_auth_error(String error) {
    return 'Authorization error: $error';
  }

  @override
  String group_members_add_failed(String error) {
    return 'Falha ao adicionar members: $error';
  }

  @override
  String get group_not_found => 'Grupo not found.';

  @override
  String get group_not_member => 'Você não é membro deste grupo.';

  @override
  String get poll_create_title => 'Enquete do chat';

  @override
  String get poll_question_label => 'Question';

  @override
  String get poll_question_hint => 'E.g.: What time shall we meet?';

  @override
  String get poll_description_label => 'Descrição (optional)';

  @override
  String get poll_options_title => 'Options';

  @override
  String poll_option_hint(int index) {
    return 'Option $index';
  }

  @override
  String get poll_add_option => 'Adicionar option';

  @override
  String get poll_switch_anonymous => 'Anônimo voting';

  @override
  String get poll_switch_anonymous_sub => 'Não mostrar quem votou em quê';

  @override
  String get poll_switch_multi => 'Multiple answers';

  @override
  String get poll_switch_multi_sub => 'Várias opções podem ser selecionadas';

  @override
  String get poll_switch_add_options => 'Adicionar options';

  @override
  String get poll_switch_add_options_sub =>
      'Os participantes podem sugerir opções próprias';

  @override
  String get poll_switch_revote => 'Can change vote';

  @override
  String get poll_switch_revote_sub => 'Revote allowed until poll closes';

  @override
  String get poll_switch_shuffle => 'Shuffle options';

  @override
  String get poll_switch_shuffle_sub =>
      'Ordem diferente para cada participante';

  @override
  String get poll_switch_quiz => 'Quiz mode';

  @override
  String get poll_switch_quiz_sub => 'One correct answer';

  @override
  String get poll_correct_option_label => 'Correct option';

  @override
  String get poll_quiz_explanation_label => 'Explanation (optional)';

  @override
  String get poll_close_by_time => 'Fechar by time';

  @override
  String get poll_close_not_set => 'Not set';

  @override
  String get poll_close_reset => 'Restaurar deadline';

  @override
  String get poll_publish => 'Publish';

  @override
  String get poll_error_empty_question => 'Enter a question';

  @override
  String get poll_error_min_options => 'São necessárias pelo menos 2 opções';

  @override
  String get poll_error_select_correct => 'Selecionar the correct option';

  @override
  String get poll_error_future_time =>
      'O horário de fechamento deve ser no futuro';

  @override
  String get poll_unavailable => 'Enquete indisponível';

  @override
  String get poll_loading => 'Carregando enquete…';

  @override
  String get poll_not_found => 'Enquete não encontrada';

  @override
  String get poll_status_cancelled => 'Cancelada';

  @override
  String get poll_status_ended => 'Ended';

  @override
  String get poll_status_draft => 'Rascunho';

  @override
  String get poll_status_active => 'Ativo';

  @override
  String get poll_badge_public => 'Pública';

  @override
  String get poll_badge_multi => 'Múltiplas respostas';

  @override
  String get poll_badge_quiz => 'Quiz';

  @override
  String get poll_menu_restart => 'Restart';

  @override
  String get poll_menu_end => 'End';

  @override
  String get poll_menu_delete => 'Excluir';

  @override
  String get poll_submit_vote => 'Enviar voto';

  @override
  String get poll_suggest_option_hint => 'Suggest an option';

  @override
  String get poll_revote => 'Alterar voto';

  @override
  String poll_votes_count(int count) {
    return '$count votes';
  }

  @override
  String get poll_show_voters => 'Who voted';

  @override
  String get poll_hide_voters => 'Ocultar';

  @override
  String get poll_vote_error => 'Erro while voting';

  @override
  String get poll_add_option_error => 'Falha ao adicionar option';

  @override
  String get poll_error_generic => 'Erro';

  @override
  String get durak_your_turn => 'Sua vez';

  @override
  String get durak_winner_label => 'Vencedor';

  @override
  String get durak_rematch => 'Play again';

  @override
  String get durak_surrender_tooltip => 'End game';

  @override
  String get durak_close_tooltip => 'Fechar';

  @override
  String get durak_fx_took => 'Took';

  @override
  String get durak_fx_beat => 'Beaten';

  @override
  String get durak_opponent_role_defend => 'DEF';

  @override
  String get durak_opponent_role_attack => 'ATK';

  @override
  String get durak_opponent_role_throwin => 'THR';

  @override
  String get durak_foul_banner_title => 'Trapaceiro! Missed:';

  @override
  String get durak_pending_resolution_attacker =>
      'Waiting for foul check… Press \"Confirmar Beaten\" if everyone agrees.';

  @override
  String get durak_pending_resolution_other =>
      'Aguardando verificação de falta… Você pode pressionar \"Falta!\" se notou trapaça.';

  @override
  String durak_tournament_played(int finished, int total) {
    return 'Played $finished of $total';
  }

  @override
  String get durak_tournament_finished => 'Torneio finished';

  @override
  String get durak_tournament_next => 'Próximo tournament game';

  @override
  String get durak_single_game => 'Single game';

  @override
  String get durak_tournament_total_games_title => 'Quantos jogos no torneio?';

  @override
  String get durak_finish_game_tooltip => 'End game';

  @override
  String get durak_lobby_game_unavailable =>
      'Jogo indisponível ou foi excluído';

  @override
  String get durak_lobby_back_tooltip => 'Voltar';

  @override
  String get durak_lobby_waiting => 'Aguardando oponente…';

  @override
  String get durak_lobby_start => 'Iniciar game';

  @override
  String get durak_lobby_waiting_short => 'Waiting…';

  @override
  String get durak_lobby_ready => 'Pronto';

  @override
  String get durak_lobby_empty_slot => 'Waiting…';

  @override
  String get durak_settings_timer_subtitle => '15 segundos by default';

  @override
  String get durak_dm_game_active => 'Durak game in progress';

  @override
  String get durak_dm_game_created => 'Durak game created';

  @override
  String get game_durak_subtitle => 'Single game or tournament';

  @override
  String get group_member_write_dm => 'Enviar direct message';

  @override
  String get group_member_open_dm_hint => 'Abrir direct chat with member';

  @override
  String get group_member_profile_not_loaded =>
      'Membro profile not loaded yet.';

  @override
  String group_member_open_dm_error(String error) {
    return 'Failed to open direct chat: $error';
  }

  @override
  String get group_avatar_photo_title => 'Foto do grupo';

  @override
  String get group_avatar_add_photo => 'Adicionar photo';

  @override
  String get group_avatar_change => 'Alterar avatar';

  @override
  String get group_avatar_remove => 'Remover avatar';

  @override
  String group_avatar_process_error(String error) {
    return 'Failed to process photo: $error';
  }

  @override
  String get group_mention_no_matches => 'Não matches';

  @override
  String get durak_error_defense_does_not_beat =>
      'Esta carta não bate a carta do ataque';

  @override
  String get durak_error_only_attacker_first => 'Attacker goes first';

  @override
  String get durak_error_defender_cannot_attack =>
      'Defender cannot throw in right now';

  @override
  String get durak_error_not_allowed_throwin =>
      'Você não pode jogar extras nesta rodada';

  @override
  String get durak_error_throwin_not_your_turn =>
      'Outro jogador está jogando extras agora';

  @override
  String get durak_error_rank_not_allowed =>
      'Você só pode jogar cartas do mesmo valor';

  @override
  String get durak_error_cannot_throw_in => 'Cannot throw in more cards';

  @override
  String get durak_error_card_not_in_hand =>
      'Esta carta não está mais na sua mão';

  @override
  String get durak_error_already_defended => 'This card is already defended';

  @override
  String get durak_error_bad_attack_index =>
      'Selecionar an attacking card to defend against';

  @override
  String get durak_error_only_defender => 'Another player is defending now';

  @override
  String get durak_error_defender_already_taking =>
      'Defender is already taking cards';

  @override
  String get durak_error_game_not_active => 'Jogo is no longer active';

  @override
  String get durak_error_not_in_lobby => 'Lobby has already started';

  @override
  String get durak_error_game_already_active => 'Jogo has already started';

  @override
  String get durak_error_active_game_exists =>
      'Já existe um jogo ativo neste chat';

  @override
  String get durak_error_resolution_pending => 'Finish the disputed move first';

  @override
  String get durak_error_rematch_failed =>
      'Failed to prepare rematch. Please try again';

  @override
  String get durak_error_unauthenticated => 'Você precisa entrar';

  @override
  String get durak_error_permission_denied =>
      'Esta ação não está disponível para você';

  @override
  String get durak_error_invalid_argument => 'Invalid move';

  @override
  String get durak_error_failed_precondition =>
      'A jogada não está disponível agora';

  @override
  String get durak_error_server => 'Failed to execute move. Please try again';

  @override
  String pinned_count(int count) {
    return 'Fixadas: $count';
  }

  @override
  String get pinned_single => 'Fixada';

  @override
  String get pinned_unpin_tooltip => 'Desafixar';

  @override
  String get pinned_type_image => 'Imagem';

  @override
  String get pinned_type_video => 'Vídeo';

  @override
  String get pinned_type_video_circle => 'Vídeo circle';

  @override
  String get pinned_type_voice => 'Mensagem de voz';

  @override
  String get pinned_type_poll => 'Enquete';

  @override
  String get pinned_type_link => 'Link';

  @override
  String get pinned_type_location => 'Localização';

  @override
  String get pinned_type_sticker => 'Figurinha';

  @override
  String get pinned_type_file => 'Arquivo';

  @override
  String get call_entry_login_required_title => 'É preciso entrar';

  @override
  String get call_entry_login_required_subtitle =>
      'Abra o app e entre na sua conta.';

  @override
  String get call_entry_not_found_title => 'Chamada não encontrada';

  @override
  String get call_entry_not_found_subtitle =>
      'A chamada já terminou ou foi excluída. Voltando para chamadas…';

  @override
  String get call_entry_to_calls => 'Para chamadas';

  @override
  String get call_entry_ended_title => 'Chamada encerrada';

  @override
  String get call_entry_ended_subtitle =>
      'Esta chamada não está mais disponível. Voltando para chamadas…';

  @override
  String get call_entry_caller_fallback => 'Quem ligou';

  @override
  String get call_entry_opening_title => 'Abrindo a chamada…';

  @override
  String get call_entry_connecting_video => 'Conectando à chamada de vídeo';

  @override
  String get call_entry_connecting_audio => 'Conectando à chamada de áudio';

  @override
  String get call_entry_loading_subtitle => 'Carregando dados da chamada';

  @override
  String get call_entry_error_title => 'Erro opening call';

  @override
  String chat_theme_save_error(Object error) {
    return 'Falha ao salvar background: $error';
  }

  @override
  String chat_theme_load_error(Object error) {
    return 'Erro loading background: $error';
  }

  @override
  String chat_theme_delete_error(Object error) {
    return 'Erro ao excluir: $error';
  }

  @override
  String get chat_theme_description =>
      'O plano de fundo desta conversa é visível apenas para você. As configurações globais em Configurações do chat não são afetadas.';

  @override
  String get chat_theme_default_bg => 'Padrão (global settings)';

  @override
  String get chat_theme_global_label => 'Global';

  @override
  String get chat_theme_hint => 'Escolha um pré-ajuste ou foto da galeria';

  @override
  String get date_today => 'Hoje';

  @override
  String get date_yesterday => 'Ontem';

  @override
  String get date_month_1 => 'Janeiro';

  @override
  String get date_month_2 => 'Fevereiro';

  @override
  String get date_month_3 => 'Março';

  @override
  String get date_month_4 => 'Abril';

  @override
  String get date_month_5 => 'Maio';

  @override
  String get date_month_6 => 'Junho';

  @override
  String get date_month_7 => 'Julho';

  @override
  String get date_month_8 => 'Agosto';

  @override
  String get date_month_9 => 'Setembro';

  @override
  String get date_month_10 => 'Outubro';

  @override
  String get date_month_11 => 'Novembro';

  @override
  String get date_month_12 => 'Dezembro';

  @override
  String get video_circle_camera_unavailable => 'Câmera unavailable';

  @override
  String video_circle_camera_error(Object error) {
    return 'Falha ao abrir a câmera: $error';
  }

  @override
  String video_circle_record_error(Object error) {
    return 'Gravando error: $error';
  }

  @override
  String get video_circle_file_not_found =>
      'Arquivo de gravação não encontrado';

  @override
  String get video_circle_play_error => 'Falha ao reproduzir recording';

  @override
  String video_circle_send_error(Object error) {
    return 'Falha ao enviar: $error';
  }

  @override
  String video_circle_switch_error(Object error) {
    return 'Falha ao alternar a câmera: $error';
  }

  @override
  String video_circle_pause_error_detail(Object description, Object code) {
    return 'Pausa indisponível: $description ($code)';
  }

  @override
  String video_circle_pause_error(Object error) {
    return 'Erro ao pausar a gravação: $error';
  }

  @override
  String get video_circle_camera_fallback_error => 'Erro de câmera';

  @override
  String get video_circle_retry => 'Tentar de novo';

  @override
  String get video_circle_sending => 'Enviando...';

  @override
  String get video_circle_recorded => 'Nota em vídeo gravada';

  @override
  String get video_circle_swipe_cancel =>
      'Deslize para a esquerda para cancelar';

  @override
  String media_screen_error(Object error) {
    return 'Erro loading media: $error';
  }

  @override
  String get media_screen_title => 'Mídia, links e arquivos';

  @override
  String get media_tab_media => 'Mídia';

  @override
  String get media_tab_circles => 'Notas em vídeo';

  @override
  String get media_tab_files => 'Arquivos';

  @override
  String get media_tab_links => 'Links';

  @override
  String get media_empty_files => 'Não files';

  @override
  String get media_empty_media => 'Não media';

  @override
  String get media_attachment_fallback => 'Anexo';

  @override
  String get media_empty_circles => 'Não circles';

  @override
  String get media_empty_links => 'Não links';

  @override
  String get media_sender_you => 'Você';

  @override
  String get media_sender_fallback => 'Participante';

  @override
  String get call_detail_login_required => 'É preciso entrar.';

  @override
  String get call_detail_not_found => 'Chamada not found or no access.';

  @override
  String get call_detail_unknown => 'Desconhecido';

  @override
  String get call_detail_title => 'Chamada details';

  @override
  String get call_detail_video => 'Chamada de vídeo';

  @override
  String get call_detail_audio => 'Chamada de áudio';

  @override
  String get call_detail_outgoing => 'Realizada';

  @override
  String get call_detail_incoming => 'Recebida';

  @override
  String get call_detail_date_label => 'Data:';

  @override
  String get call_detail_duration_label => 'Duração:';

  @override
  String get call_detail_call_button => 'Chamada';

  @override
  String get call_detail_video_button => 'Vídeo';

  @override
  String call_detail_error(Object error) {
    return 'Erro: $error';
  }

  @override
  String get durak_took => 'Pegou';

  @override
  String get durak_beaten => 'Batidas';

  @override
  String get durak_end_game_tooltip => 'Encerrar jogo';

  @override
  String get durak_role_beats => 'DEF';

  @override
  String get durak_role_move => 'JOG';

  @override
  String get durak_role_throw => 'EXT';

  @override
  String get durak_cheater_label => 'Trapaceiro! Missed:';

  @override
  String get durak_waiting_foll_confirm =>
      'Aguardando marcação de falta… Pressione \"Confirmar Bater\" se todos concordarem.';

  @override
  String get durak_waiting_foll_call =>
      'Aguardando marcação de falta… Você pode pressionar \"Falta!\" se notou trapaça.';

  @override
  String get durak_winner => 'Vencedor';

  @override
  String get durak_play_again => 'Jogar de novo';

  @override
  String durak_games_progress(Object finished, Object total) {
    return 'Jogados $finished de $total';
  }

  @override
  String get durak_next_round => 'Próximo tournament round';

  @override
  String audio_call_error(Object error) {
    return 'Chamada error: $error';
  }

  @override
  String get audio_call_ended => 'Chamada encerrada';

  @override
  String get audio_call_missed => 'Chamada perdida';

  @override
  String get audio_call_cancelled => 'Chamada cancelada';

  @override
  String get audio_call_offer_not_ready =>
      'Oferta ainda não está pronta, tente novamente';

  @override
  String get audio_call_invalid_data => 'Dados de chamada inválidos';

  @override
  String audio_call_accept_error(Object error) {
    return 'Falha ao aceitar a chamada: $error';
  }

  @override
  String get audio_call_incoming => 'Chamada de áudio recebida';

  @override
  String get audio_call_calling => 'Chamada de áudio…';

  @override
  String privacy_save_error(Object error) {
    return 'Falha ao salvar settings: $error';
  }

  @override
  String privacy_load_error(Object error) {
    return 'Erro loading privacy: $error';
  }

  @override
  String get privacy_visibility => 'Visibilidade';

  @override
  String get privacy_online_status => 'Status online';

  @override
  String get privacy_last_visit => 'Visto por último';

  @override
  String get privacy_read_receipts => 'Confirmações de leitura';

  @override
  String get privacy_profile_info => 'Perfil info';

  @override
  String get privacy_phone_number => 'Número de telefone';

  @override
  String get privacy_birthday => 'Aniversário';

  @override
  String get privacy_about => 'Sobre';

  @override
  String starred_load_error(Object error) {
    return 'Erro loading starred: $error';
  }

  @override
  String get starred_title => 'Favoritas';

  @override
  String get starred_empty => 'Nenhuma mensagem em Favoritas neste chat';

  @override
  String get starred_message_fallback => 'Mensagem';

  @override
  String get starred_sender_you => 'Você';

  @override
  String get starred_sender_fallback => 'Participante';

  @override
  String get starred_type_poll => 'Enquete';

  @override
  String get starred_type_location => 'Localização';

  @override
  String get starred_type_attachment => 'Anexo';

  @override
  String starred_today_prefix(Object time) {
    return 'Hoje, $time';
  }

  @override
  String get contact_edit_name_required => 'Digite o nome do contato.';

  @override
  String contact_edit_save_error(Object error) {
    return 'Falha ao salvar contact: $error';
  }

  @override
  String get contact_edit_user_fallback => 'Usuário';

  @override
  String get contact_edit_first_name_hint => 'Nome';

  @override
  String get contact_edit_last_name_hint => 'Sobrenome';

  @override
  String get contact_edit_description =>
      'Este nome é visível apenas para você: nos chats, na busca e na lista de contatos.';

  @override
  String contact_edit_error(Object error) {
    return 'Erro: $error';
  }

  @override
  String get voice_no_mic_access => 'Não microphone access';

  @override
  String get voice_start_error => 'Falha ao iniciar recording';

  @override
  String get voice_file_not_received => 'Gravando file not received';

  @override
  String get voice_stop_error => 'Falha ao parar a gravação';

  @override
  String get voice_title => 'Mensagem de voz';

  @override
  String get voice_recording => 'Gravando';

  @override
  String get voice_ready => 'Gravando ready';

  @override
  String get voice_stop_button => 'Parar';

  @override
  String get voice_record_again => 'Gravar again';

  @override
  String get attach_photo_video => 'Foto/Vídeo';

  @override
  String get attach_files => 'Arquivos';

  @override
  String get attach_circle => 'Nota em vídeo';

  @override
  String get attach_location => 'Localização';

  @override
  String get attach_poll => 'Enquete';

  @override
  String get attach_stickers => 'Figurinhas';

  @override
  String get attach_clipboard => 'Área de transferência';

  @override
  String get attach_text => 'Texto';

  @override
  String get attach_title => 'Anexar';

  @override
  String notif_save_error(Object error) {
    return 'Falha ao salvar: $error';
  }

  @override
  String get notif_title => 'Notificações neste chat';

  @override
  String get notif_description =>
      'As configurações abaixo se aplicam apenas a esta conversa e não alteram as notificações globais do app.';

  @override
  String get notif_this_chat => 'Este chat';

  @override
  String get notif_mute_title => 'Silenciar and hide notifications';

  @override
  String get notif_mute_subtitle =>
      'Não perturbe para este chat neste dispositivo.';

  @override
  String get notif_preview_title => 'Mostrar texto preview';

  @override
  String get notif_preview_subtitle =>
      'Quando desativada — título da notificação sem trecho da mensagem (onde houver suporte).';

  @override
  String get poll_create_enter_question => 'Digite uma pergunta';

  @override
  String get poll_create_min_options => 'São necessárias pelo menos 2 opções';

  @override
  String get poll_create_select_correct => 'Selecionar the correct option';

  @override
  String get poll_create_future_time =>
      'O horário de fechamento deve ser no futuro';

  @override
  String get poll_create_question_label => 'Pergunta';

  @override
  String get poll_create_question_hint =>
      'Por exemplo: A que horas vamos nos encontrar?';

  @override
  String get poll_create_explanation_label => 'Explicação (opcional)';

  @override
  String get poll_create_options_title => 'Opções';

  @override
  String poll_create_option_hint(Object index) {
    return 'Opção $index';
  }

  @override
  String get poll_create_add_option => 'Adicionar option';

  @override
  String get poll_create_anonymous_title => 'Anônimo voting';

  @override
  String get poll_create_anonymous_subtitle => 'Não show who voted for what';

  @override
  String get poll_create_multi_title => 'Múltiplas respostas';

  @override
  String get poll_create_multi_subtitle => 'Pode selecionar várias opções';

  @override
  String get poll_create_user_options_title => 'Opções enviadas pelos usuários';

  @override
  String get poll_create_user_options_subtitle =>
      'Os participantes podem sugerir uma opção própria';

  @override
  String get poll_create_revote_title => 'Permitir alterar voto';

  @override
  String get poll_create_revote_subtitle =>
      'Pode mudar o voto até a enquete fechar';

  @override
  String get poll_create_shuffle_title => 'Embaralhar opções';

  @override
  String get poll_create_shuffle_subtitle =>
      'Cada participante vê uma ordem diferente';

  @override
  String get poll_create_quiz_title => 'Modo quiz';

  @override
  String get poll_create_quiz_subtitle => 'Uma resposta correta';

  @override
  String get poll_create_correct_option_label => 'Opção correta';

  @override
  String get poll_create_close_by_time => 'Fechar by time';

  @override
  String get poll_create_not_set => 'Não definida';

  @override
  String get poll_create_reset_deadline => 'Restaurar deadline';

  @override
  String get poll_create_publish => 'Publicar';

  @override
  String get poll_error => 'Erro';

  @override
  String get poll_status_finished => 'Finalizado';

  @override
  String get poll_restart => 'Reiniciar';

  @override
  String get poll_finish => 'Encerrar';

  @override
  String get poll_suggest_hint => 'Sugerir uma opção';

  @override
  String get poll_voters_toggle_hide => 'Ocultar';

  @override
  String get poll_voters_toggle_show => 'Quem votou';

  @override
  String get e2ee_disable_title => 'Desativar encryption?';

  @override
  String get e2ee_disable_body =>
      'Novas mensagens serão enviadas sem criptografia de ponta a ponta. As mensagens criptografadas já enviadas permanecem na conversa.';

  @override
  String get e2ee_disable_button => 'Desativar';

  @override
  String e2ee_disable_error(Object error) {
    return 'Falha ao desativar: $error';
  }

  @override
  String get e2ee_screen_title => 'Criptografia';

  @override
  String get e2ee_enabled_description =>
      'A criptografia de ponta a ponta está ativada para este chat.';

  @override
  String get e2ee_disabled_description =>
      'Criptografia de ponta a ponta is disabled.';

  @override
  String get e2ee_info_text =>
      'Quando a criptografia está ativada, o conteúdo das novas mensagens só fica disponível para os participantes do chat nos seus dispositivos. Desativar afeta apenas as novas mensagens.';

  @override
  String get e2ee_enable_title => 'Ativar encryption';

  @override
  String e2ee_status_enabled(Object epoch) {
    return 'Ativado (key epoch: $epoch)';
  }

  @override
  String get e2ee_status_disabled => 'Desativado';

  @override
  String get e2ee_data_types_title => 'Tipos de dado';

  @override
  String get e2ee_data_types_info =>
      'Esta configuração não muda o protocolo. Ela controla quais tipos de dado são enviados criptografados.';

  @override
  String get e2ee_chat_settings_title =>
      'Configurações de criptografia para este chat';

  @override
  String get e2ee_chat_settings_override =>
      'Usando configurações específicas do chat.';

  @override
  String get e2ee_chat_settings_global => 'Herdando configurações globais.';

  @override
  String get e2ee_text_messages => 'Mensagens de texto';

  @override
  String get e2ee_attachments => 'Anexos (mídia/arquivos)';

  @override
  String get e2ee_override_hint =>
      'Para alterar para este chat — ative \"Sobrescrever\".';

  @override
  String get group_member_fallback => 'Participante';

  @override
  String get group_role_creator => 'Grupo creator';

  @override
  String get group_role_admin => 'Administrador';

  @override
  String group_total_count(Object count) {
    return 'Total: $count';
  }

  @override
  String get group_copy_invite_tooltip => 'Copiar invite link';

  @override
  String get group_add_member_tooltip => 'Adicionar member';

  @override
  String get group_invite_copied => 'Link de convite copiado';

  @override
  String group_copy_invite_error(Object error) {
    return 'Falha ao copiar link: $error';
  }

  @override
  String get group_demote_confirm => 'Remover direitos de admin?';

  @override
  String get group_promote_confirm => 'Tornar administrador?';

  @override
  String group_demote_body(Object name) {
    return '$name terá os direitos de admin removidos. O membro continuará no grupo como membro comum.';
  }

  @override
  String get group_demote_button => 'Remover direitos';

  @override
  String get group_promote_button => 'Promover';

  @override
  String get group_kick_confirm => 'Remover membro?';

  @override
  String get group_kick_button => 'Remover';

  @override
  String get group_member_kicked => 'Membro removed';

  @override
  String get group_badge_creator => 'CRIADOR';

  @override
  String get group_demote_action => 'Remover admin';

  @override
  String get group_promote_action => 'Tornar admin';

  @override
  String get group_kick_action => 'Remover do grupo';

  @override
  String group_contacts_load_error(Object error) {
    return 'Falha ao carregar contacts: $error';
  }

  @override
  String get group_add_members_title => 'Adicionar membros';

  @override
  String get group_search_contacts_hint => 'Buscar contatos';

  @override
  String get group_all_contacts_in_group =>
      'Todos os seus contatos já estão no grupo.';

  @override
  String get group_nobody_found => 'Ninguém encontrado.';

  @override
  String get group_user_fallback => 'Usuário';

  @override
  String get group_select_members => 'Selecionar members';

  @override
  String group_add_count(Object count) {
    return 'Adicionar ($count)';
  }

  @override
  String group_auth_error(Object error) {
    return 'Erro de autorização: $error';
  }

  @override
  String group_add_error(Object error) {
    return 'Falha ao adicionar members: $error';
  }

  @override
  String get add_contact_own_profile => 'Este é o seu próprio perfil';

  @override
  String get add_contact_qr_not_found => 'Perfil from QR code not found';

  @override
  String add_contact_qr_error(Object error) {
    return 'Falha ao ler o QR code: $error';
  }

  @override
  String get add_contact_not_allowed => 'Não é possível adicionar este usuário';

  @override
  String add_contact_save_error(Object error) {
    return 'Falha ao adicionar contact: $error';
  }

  @override
  String get add_contact_country_search => 'Buscar country or code';

  @override
  String get add_contact_sync_phone => 'Sincronizar com o telefone';

  @override
  String get add_contact_qr_button => 'Adicionar by QR code';

  @override
  String add_contact_load_error(Object error) {
    return 'Erro loading contact: $error';
  }

  @override
  String get add_contact_user_fallback => 'Usuário';

  @override
  String get add_contact_already_in_contacts => 'Já está nos contatos';

  @override
  String get add_contact_new => 'Novo contato';

  @override
  String get add_contact_unavailable => 'Indisponível';

  @override
  String get add_contact_scan_qr => 'Escanear QR code';

  @override
  String get add_contact_scan_hint =>
      'Aponte a câmera para um QR code de perfil do LighChat';

  @override
  String get auth_validate_name_min_length =>
      'Name must be pelo menos 2 caracteres';

  @override
  String get auth_validate_username_min_length =>
      'Nome de usuário must be pelo menos 3 caracteres';

  @override
  String get auth_validate_username_max_length =>
      'Nome de usuário must not exceed 30 caracteres';

  @override
  String get auth_validate_username_format =>
      'Nome de usuário contains invalid caracteres';

  @override
  String get auth_validate_phone_11_digits =>
      'Número de telefone must contain 11 digits';

  @override
  String get auth_validate_email_format => 'Digite um email válido';

  @override
  String get auth_validate_dob_invalid => 'Data de nascimento inválida';

  @override
  String get auth_validate_bio_max_length =>
      'Bio must not exceed 200 caracteres';

  @override
  String get auth_validate_password_min_length =>
      'Senha must be pelo menos 6 caracteres';

  @override
  String get auth_validate_passwords_mismatch => 'As senhas não coincidem';

  @override
  String get sticker_new_pack => 'Novo pacote…';

  @override
  String get sticker_select_image_or_gif => 'Selecionar an image or GIF';

  @override
  String sticker_send_error(Object error) {
    return 'Falha ao enviar: $error';
  }

  @override
  String get sticker_saved => 'Salvo to sticker pack';

  @override
  String get sticker_save_failed => 'Falha ao baixar or save GIF';

  @override
  String get sticker_tab_my => 'My';

  @override
  String get sticker_tab_shared => 'Compartilhados';

  @override
  String get sticker_no_packs => 'Não sticker packs. Create a new one.';

  @override
  String get sticker_shared_not_configured =>
      'Pacotes compartilhados não configurados';

  @override
  String get sticker_recent => 'RECENTES';

  @override
  String get sticker_gallery_description =>
      'Fotos, PNG, GIF do dispositivo — direto no chat';

  @override
  String get sticker_shared_unavailable =>
      'Pacotes compartilhados ainda não disponíveis';

  @override
  String get sticker_gif_search_hint => 'Buscar GIF…';

  @override
  String sticker_gif_searched(Object query) {
    return 'Buscado: $query';
  }

  @override
  String get sticker_gif_search_unavailable =>
      'Busca de GIFs temporariamente indisponível.';

  @override
  String get sticker_gif_nothing_found => 'Nada encontrado';

  @override
  String get sticker_gif_all => 'Todos';

  @override
  String get sticker_gif_animated => 'ANIMADAS';

  @override
  String get sticker_emoji_text_unavailable =>
      'Emoji em texto não está disponível para esta janela.';

  @override
  String get wallpaper_sender => 'Contato';

  @override
  String get wallpaper_incoming => 'Esta é uma mensagem recebida.';

  @override
  String get wallpaper_outgoing => 'Esta é uma mensagem enviada.';

  @override
  String get wallpaper_incoming_time => '11:40';

  @override
  String get wallpaper_outgoing_time => '11:41';

  @override
  String get wallpaper_system => 'Você alterou o plano de fundo do chat';

  @override
  String get wallpaper_you => 'Você';

  @override
  String get wallpaper_today => 'Hoje';

  @override
  String system_event_e2ee_enabled(Object epoch) {
    return 'Criptografia de ponta a ponta ativada (época da chave: $epoch)';
  }

  @override
  String get system_event_e2ee_disabled =>
      'Criptografia de ponta a ponta desativada';

  @override
  String get system_event_unknown => 'Sistema event';

  @override
  String get system_event_group_created => 'Grupo created';

  @override
  String system_event_member_added(Object name) {
    return '$name foi adicionado(a)';
  }

  @override
  String system_event_member_removed(Object name) {
    return '$name foi removido(a)';
  }

  @override
  String system_event_member_left(Object name) {
    return '$name saiu do grupo';
  }

  @override
  String system_event_name_changed(Object name) {
    return 'Nome alterado para \"$name\"';
  }

  @override
  String get image_editor_title => 'Editor';

  @override
  String get image_editor_undo => 'Desfazer';

  @override
  String get image_editor_clear => 'Limpar';

  @override
  String get image_editor_pen => 'Pincel';

  @override
  String get image_editor_text => 'Texto';

  @override
  String get image_editor_crop => 'Recortar';

  @override
  String get image_editor_rotate => 'Girar';

  @override
  String get location_title => 'Enviar location';

  @override
  String get location_loading => 'Carregando mapa…';

  @override
  String get location_send_button => 'Enviar';

  @override
  String get location_live_label => 'Ao vivo';

  @override
  String get location_error => 'Falha ao carregar map';

  @override
  String get location_no_permission => 'Não location access';

  @override
  String get group_member_admin => 'Admin';

  @override
  String get group_member_creator => 'Criador';

  @override
  String get group_member_member => 'Membro';

  @override
  String get group_member_open_chat => 'Mensagem';

  @override
  String get group_member_open_profile => 'Perfil';

  @override
  String get group_member_remove => 'Remover';

  @override
  String get durak_lobby_title => 'Durak';

  @override
  String get durak_lobby_new_game => 'Novo jogo';

  @override
  String get durak_lobby_decline => 'Recusar';

  @override
  String get durak_lobby_accept => 'Aceitar';

  @override
  String get durak_lobby_invite_sent => 'Convite enviado';

  @override
  String get voice_preview_cancel => 'Cancelar';

  @override
  String get voice_preview_send => 'Enviar';

  @override
  String get voice_preview_recorded => 'Gravada';

  @override
  String get voice_preview_playing => 'Reproduzindo…';

  @override
  String get voice_preview_paused => 'Pausada';

  @override
  String get group_avatar_camera => 'Câmera';

  @override
  String get group_avatar_gallery => 'Galeria';

  @override
  String get group_avatar_upload_error => 'Erro de upload';

  @override
  String get avatar_picker_title => 'Avatar';

  @override
  String get avatar_picker_camera => 'Câmera';

  @override
  String get avatar_picker_gallery => 'Galeria';

  @override
  String get avatar_picker_crop => 'Recortar';

  @override
  String get avatar_picker_save => 'Salvar';

  @override
  String get avatar_picker_remove => 'Remover avatar';

  @override
  String get avatar_picker_error => 'Falha ao carregar avatar';

  @override
  String get avatar_picker_crop_error => 'Erro ao recortar';

  @override
  String get webview_telegram_title => 'Entrar with Telegram';

  @override
  String get webview_telegram_loading => 'Carregando…';

  @override
  String get webview_telegram_error => 'Falha ao carregar page';

  @override
  String get webview_telegram_back => 'Voltar';

  @override
  String get webview_telegram_retry => 'Tentar de novo';

  @override
  String get webview_telegram_close => 'Fechar';

  @override
  String get webview_telegram_no_url => 'Não authorization URL provided';

  @override
  String get webview_yandex_title => 'Entrar with Yandex';

  @override
  String get webview_yandex_loading => 'Carregando…';

  @override
  String get webview_yandex_error => 'Falha ao carregar page';

  @override
  String get webview_yandex_back => 'Voltar';

  @override
  String get webview_yandex_retry => 'Tentar de novo';

  @override
  String get webview_yandex_close => 'Fechar';

  @override
  String get webview_yandex_no_url => 'Não authorization URL provided';

  @override
  String get google_profile_title => 'Complete seu perfil';

  @override
  String get google_profile_name => 'Nome';

  @override
  String get google_profile_username => 'Nome de usuário';

  @override
  String get google_profile_phone => 'Telefone';

  @override
  String get google_profile_email => 'Email';

  @override
  String get google_profile_dob => 'Data de nascimento';

  @override
  String get google_profile_bio => 'Sobre';

  @override
  String get google_profile_save => 'Salvar e continuar';

  @override
  String get google_profile_error => 'Falha ao salvar profile';

  @override
  String get system_event_e2ee_epoch_rotated => 'Criptografia key rotated';

  @override
  String system_event_e2ee_device_added(String actor, String device) {
    return '$actor adicionou o dispositivo \"$device\"';
  }

  @override
  String system_event_e2ee_device_revoked(String actor, String device) {
    return '$actor revogou o dispositivo \"$device\"';
  }

  @override
  String system_event_e2ee_fingerprint_changed(String actor) {
    return 'A impressão de segurança de $actor mudou';
  }

  @override
  String get system_event_game_lobby_created => 'Jogo lobby created';

  @override
  String get system_event_game_started => 'Jogo started';

  @override
  String get system_event_default_actor => 'Usuário';

  @override
  String get system_event_default_device => 'dispositivo';

  @override
  String get image_editor_add_caption => 'Adicionar caption...';

  @override
  String get image_editor_crop_failed => 'Falha ao recortar a imagem';

  @override
  String get image_editor_draw_hint =>
      'Modo de desenho: arraste sobre a imagem';

  @override
  String get image_editor_crop_title => 'Recortar';

  @override
  String get location_preview_title => 'Localização';

  @override
  String get location_preview_accuracy_unknown => 'Precisão: —';

  @override
  String location_preview_accuracy_meters(String meters) {
    return 'Precisão: ~$meters m';
  }

  @override
  String location_preview_accuracy_km(String km) {
    return 'Precisão: ~$km km';
  }

  @override
  String get group_member_profile_default_name => 'Membro';

  @override
  String get group_member_profile_dm => 'Enviar direct message';

  @override
  String get group_member_profile_dm_hint =>
      'Abrir um chat direto com este membro';

  @override
  String group_member_profile_dm_failed(Object error) {
    return 'Falha ao abrir o chat direto: $error';
  }

  @override
  String get conversation_game_lobby_unavailable =>
      'Jogo unavailable or was deleted';

  @override
  String get conversation_game_lobby_back => 'Voltar';

  @override
  String get conversation_game_lobby_waiting => 'Aguardando oponente to join…';

  @override
  String get conversation_game_lobby_start_game => 'Iniciar game';

  @override
  String get conversation_game_lobby_waiting_short => 'Aguardando…';

  @override
  String get conversation_game_lobby_ready => 'Pronto';

  @override
  String get voice_preview_trim_confirm_title =>
      'Manter apenas o trecho selecionado?';

  @override
  String get voice_preview_trim_confirm_body =>
      'Tudo, exceto o trecho selecionado, será excluído. A gravação continuará logo após pressionar o botão.';

  @override
  String get voice_preview_continue => 'Continuar';

  @override
  String get voice_preview_continue_recording => 'Continuar recording';

  @override
  String get group_avatar_change_short => 'Alterar';

  @override
  String get avatar_picker_cancel => 'Cancelar';

  @override
  String get avatar_picker_choose => 'Escolher avatar';

  @override
  String get avatar_picker_delete_photo => 'Excluir photo';

  @override
  String get avatar_picker_loading => 'Carregando…';

  @override
  String get avatar_picker_choose_avatar => 'Escolher avatar';

  @override
  String get avatar_picker_change_avatar => 'Alterar avatar';

  @override
  String get avatar_picker_remove_tooltip => 'Remover';

  @override
  String get telegram_sign_in_title => 'Entrar via Telegram';

  @override
  String get telegram_sign_in_open_in_browser => 'Abrir in browser';

  @override
  String get telegram_sign_in_open_telegram_failed =>
      'Falha ao abrir o Telegram. Por favor, instale o app do Telegram.';

  @override
  String get telegram_sign_in_page_load_error => 'Erro ao carregar a página';

  @override
  String get telegram_sign_in_login_error => 'Erro ao entrar com o Telegram.';

  @override
  String get telegram_sign_in_firebase_not_ready => 'Firebase não está pronto.';

  @override
  String get telegram_sign_in_browser_failed => 'Falha ao abrir o navegador.';

  @override
  String telegram_sign_in_login_failed(Object error) {
    return 'Falha ao entrar: $error';
  }

  @override
  String get yandex_sign_in_title => 'Yandex';

  @override
  String get yandex_sign_in_open_in_browser => 'Abrir in browser';

  @override
  String get yandex_sign_in_page_load_error => 'Erro ao carregar a página';

  @override
  String get yandex_sign_in_login_error => 'Erro ao entrar com o Yandex.';

  @override
  String get yandex_sign_in_firebase_not_ready => 'Firebase não está pronto.';

  @override
  String get yandex_sign_in_browser_failed => 'Falha ao abrir o navegador.';

  @override
  String yandex_sign_in_login_failed(Object error) {
    return 'Falha ao entrar: $error';
  }

  @override
  String get google_complete_title => 'Concluir cadastro';

  @override
  String get google_complete_subtitle =>
      'Após entrar com o Google, preencha seu perfil como na versão web.';

  @override
  String get google_complete_name_label => 'Nome';

  @override
  String get google_complete_username_label => 'Nome de usuário';

  @override
  String get google_complete_phone_label => 'Telefone';

  @override
  String get google_complete_email_label => 'Email';

  @override
  String get google_complete_email_hint => 'voce@exemplo.com';

  @override
  String get google_complete_dob_label => 'Data de nascimento';

  @override
  String get google_complete_bio_label =>
      'Sobre (up to 200 caracteres, optional)';

  @override
  String get google_complete_save => 'Salvar e continuar';

  @override
  String get google_complete_back => 'Voltar para entrar';

  @override
  String get game_error_defense_not_beat =>
      'Esta carta não bate a carta do ataque';

  @override
  String get game_error_attacker_first => 'The attacker moves first';

  @override
  String get game_error_defender_no_attack =>
      'O defensor não pode atacar agora';

  @override
  String get game_error_not_allowed_throwin =>
      'Você não pode jogar extras nesta rodada';

  @override
  String get game_error_throwin_not_turn =>
      'Outro jogador está jogando extras agora';

  @override
  String get game_error_rank_not_allowed =>
      'Você só pode jogar uma carta do mesmo valor';

  @override
  String get game_error_cannot_throw_in =>
      'Não dá para jogar mais cartas extras';

  @override
  String get game_error_card_not_in_hand =>
      'Esta carta não está mais na sua mão';

  @override
  String get game_error_already_defended => 'Esta carta já foi defendida';

  @override
  String get game_error_bad_attack_index =>
      'Selecionar an attacking card to defend against';

  @override
  String get game_error_only_defender => 'Outro jogador está defendendo agora';

  @override
  String get game_error_defender_taking => 'O defensor já está pegando cartas';

  @override
  String get game_error_game_not_active => 'O jogo não está mais ativo';

  @override
  String get game_error_not_in_lobby => 'O lobby já começou';

  @override
  String get game_error_game_already_active => 'O jogo já começou';

  @override
  String get game_error_active_exists => 'Já existe um jogo ativo neste chat';

  @override
  String get game_error_round_pending => 'Finish the contested move first';

  @override
  String get game_error_rematch_failed =>
      'Failed to prepare rematch. Tente novamente';

  @override
  String get game_error_unauthenticated => 'Você precisa entrar';

  @override
  String get game_error_permission_denied =>
      'Esta ação não está disponível para você';

  @override
  String get game_error_invalid_argument => 'Invalid move';

  @override
  String get game_error_precondition => 'A jogada não está disponível agora';

  @override
  String get game_error_server => 'Failed to make move. Tente novamente';

  @override
  String get reply_sticker => 'Figurinha';

  @override
  String get reply_gif => 'GIF';

  @override
  String get reply_video_circle => 'Vídeo circle';

  @override
  String get reply_voice_message => 'Mensagem de voz';

  @override
  String get reply_video => 'Vídeo';

  @override
  String get reply_photo => 'Foto';

  @override
  String get reply_file => 'Arquivo';

  @override
  String get reply_location => 'Location';

  @override
  String get reply_poll => 'Poll';

  @override
  String get reply_link => 'Link';

  @override
  String get reply_message => 'Mensagem';

  @override
  String get reply_sender_you => 'You';

  @override
  String get reply_sender_member => 'Membro';

  @override
  String get call_format_today => 'Hoje';

  @override
  String get call_format_yesterday => 'Ontem';

  @override
  String get call_format_second_short => 's';

  @override
  String get call_format_minute_short => 'm';

  @override
  String get call_format_hour_short => 'h';

  @override
  String get call_format_day_short => 'd';

  @override
  String get call_month_january => 'January';

  @override
  String get call_month_february => 'February';

  @override
  String get call_month_march => 'March';

  @override
  String get call_month_april => 'April';

  @override
  String get call_month_may => 'May';

  @override
  String get call_month_june => 'June';

  @override
  String get call_month_july => 'July';

  @override
  String get call_month_august => 'August';

  @override
  String get call_month_september => 'September';

  @override
  String get call_month_october => 'October';

  @override
  String get call_month_november => 'November';

  @override
  String get call_month_december => 'December';

  @override
  String get push_incoming_call => 'Incoming call';

  @override
  String get push_incoming_video_call => 'Chamada de vídeo recebida';

  @override
  String get push_new_message => 'Nova mensagem';

  @override
  String get push_channel_calls => 'Chamadas';

  @override
  String get push_channel_messages => 'Mensagens';

  @override
  String contacts_years_one(Object count) {
    return '$count year';
  }

  @override
  String contacts_years_few(Object count) {
    return '$count years';
  }

  @override
  String contacts_years_many(Object count) {
    return '$count years';
  }

  @override
  String contacts_years_other(Object count) {
    return '$count years';
  }

  @override
  String get durak_entry_single_game => 'Single game';

  @override
  String get durak_entry_finish_game_tooltip => 'Finish game';

  @override
  String get durak_entry_tournament_games_dialog_title =>
      'How many games in tournament?';

  @override
  String get durak_entry_cancel => 'Cancelar';

  @override
  String get durak_entry_create => 'Create';

  @override
  String video_editor_load_failed(Object error) {
    return 'Falha ao carregar video: $error';
  }

  @override
  String video_editor_process_failed(Object error) {
    return 'Failed to process video: $error';
  }

  @override
  String video_editor_duration(Object duration) {
    return 'Duration: $duration';
  }

  @override
  String get video_editor_brush => 'Brush';

  @override
  String get video_editor_caption_hint => 'Adicionar caption...';

  @override
  String get share_location_title => 'Share location';

  @override
  String get share_location_how => 'Sharing method';

  @override
  String get share_location_cancel => 'Cancelar';

  @override
  String get share_location_send => 'Enviar';

  @override
  String get photo_source_gallery => 'Galeria';

  @override
  String get photo_source_take_photo => 'Pegar photo';

  @override
  String get photo_source_record_video => 'Gravar video';

  @override
  String get video_attachment_media_kind => 'video';

  @override
  String get video_attachment_title => 'Vídeo';

  @override
  String get video_attachment_playback_error =>
      'Não foi possível reproduzir o vídeo. Verifique o link e a conexão.';

  @override
  String get location_card_broadcast_ended_mine =>
      'Transmissão de localização encerrada. A outra pessoa não pode mais ver sua localização atual.';

  @override
  String get location_card_broadcast_ended_other =>
      'A transmissão de localização deste contato terminou. A posição atual está indisponível.';

  @override
  String get location_card_title => 'Location';

  @override
  String location_card_accuracy(Object meters) {
    return '±$meters m';
  }

  @override
  String get link_webview_copy_tooltip => 'Copiar link';

  @override
  String get link_webview_copied_snackbar => 'Link copied';

  @override
  String get link_webview_open_browser_tooltip => 'Abrir in browser';

  @override
  String get hold_record_pause => 'Paused';

  @override
  String get hold_record_release_cancel => 'Release to cancel';

  @override
  String get hold_record_slide_hints => 'Slide left — cancel · Up — pause';

  @override
  String get e2ee_badge_loading => 'Loading fingerprint…';

  @override
  String e2ee_badge_error(Object error) {
    return 'Failed to get fingerprint: $error';
  }

  @override
  String get e2ee_badge_label => 'E2EE Fingerprint';

  @override
  String e2ee_badge_label_with_user(Object user) {
    return 'E2EE Fingerprint • $user';
  }

  @override
  String e2ee_badge_devices(Object count) {
    return '$count dev.';
  }

  @override
  String get composer_link_cancel => 'Cancelar';

  @override
  String message_search_results_count(Object count) {
    return 'SEARCH RESULTS: $count';
  }

  @override
  String get message_search_not_found => 'NOTHING FOUND';

  @override
  String get message_search_participant_fallback => 'Participant';

  @override
  String get wallpaper_purple => 'Purple';

  @override
  String get wallpaper_pink => 'Pink';

  @override
  String get wallpaper_blue => 'Blue';

  @override
  String get wallpaper_green => 'Green';

  @override
  String get wallpaper_sunset => 'Sunset';

  @override
  String get wallpaper_tender => 'Tender';

  @override
  String get wallpaper_lime => 'Lime';

  @override
  String get wallpaper_graphite => 'Graphite';

  @override
  String get avatar_crop_title => 'Adjust avatar';

  @override
  String get avatar_crop_hint =>
      'Arraste e dê zoom — o círculo aparece nas listas e mensagens; o frame completo fica para o perfil.';

  @override
  String get avatar_crop_cancel => 'Cancelar';

  @override
  String get avatar_crop_reset => 'Restaurar';

  @override
  String get avatar_crop_save => 'Salvar';

  @override
  String get meeting_entry_connecting => 'Conectando to meeting…';

  @override
  String meeting_entry_auth_failed(Object error) {
    return 'Falha ao entrar: $error';
  }

  @override
  String get meeting_entry_participant_fallback => 'Participant';

  @override
  String get meeting_entry_back => 'Voltar';

  @override
  String get meeting_chat_copy => 'Copiar';

  @override
  String get meeting_chat_edit => 'Editar';

  @override
  String get meeting_chat_delete => 'Excluir';

  @override
  String get meeting_chat_deleted => 'Mensagem deleted';

  @override
  String get meeting_chat_edited_mark => '• edited';

  @override
  String get e2ee_decrypt_image_failed => 'Failed to decrypt image';

  @override
  String get e2ee_decrypt_video_failed => 'Failed to decrypt video';

  @override
  String get e2ee_decrypt_audio_failed => 'Failed to decrypt audio';

  @override
  String get e2ee_decrypt_attachment_failed => 'Failed to decrypt attachment';

  @override
  String get search_preview_attachment => 'Attachment';

  @override
  String get search_preview_location => 'Location';

  @override
  String get search_preview_message => 'Mensagem';

  @override
  String get outbox_attachment_singular => 'Attachment';

  @override
  String outbox_attachments_count(int count) {
    return 'Attachments ($count)';
  }

  @override
  String get outbox_chat_unavailable => 'Serviço de chat indisponível';

  @override
  String outbox_encryption_error(String code) {
    return 'Criptografia: $code';
  }

  @override
  String get nav_chats => 'Chats';

  @override
  String get nav_contacts => 'Contatos';

  @override
  String get nav_meetings => 'Reuniões';

  @override
  String get nav_calls => 'Chamadas';

  @override
  String get e2ee_media_decrypt_failed_image => 'Failed to decrypt image';

  @override
  String get e2ee_media_decrypt_failed_video => 'Failed to decrypt video';

  @override
  String get e2ee_media_decrypt_failed_audio => 'Failed to decrypt audio';

  @override
  String get e2ee_media_decrypt_failed_attachment =>
      'Failed to decrypt attachment';

  @override
  String get chat_search_snippet_attachment => 'Attachment';

  @override
  String get chat_search_snippet_location => 'Location';

  @override
  String get chat_search_snippet_message => 'Mensagem';

  @override
  String get bottom_nav_chats => 'Chats';

  @override
  String get bottom_nav_contacts => 'Contatos';

  @override
  String get bottom_nav_meetings => 'Reuniões';

  @override
  String get bottom_nav_calls => 'Chamadas';

  @override
  String get chat_list_swipe_folders => 'FOLDERS';

  @override
  String get chat_list_swipe_clear => 'CLEAR';

  @override
  String get chat_list_swipe_delete => 'DELETE';

  @override
  String get composer_editing_title => 'EDITING MESSAGE';

  @override
  String get composer_editing_cancel_tooltip => 'Cancelar editing';

  @override
  String get composer_formatting_title => 'FORMATTING';

  @override
  String get composer_link_preview_loading => 'Loading preview…';

  @override
  String get composer_link_preview_hide_tooltip => 'Ocultar preview';

  @override
  String get chat_invite_button => 'Invite';

  @override
  String get forward_preview_unknown_sender => 'Unknown';

  @override
  String get forward_preview_attachment => 'Attachment';

  @override
  String get forward_preview_message => 'Mensagem';

  @override
  String get chat_mention_no_matches => 'Não matches';

  @override
  String get live_location_sharing =>
      'Você está compartilhando sua localização';

  @override
  String get live_location_stop => 'Parar';

  @override
  String get chat_message_deleted => 'Mensagem deleted';

  @override
  String get profile_qr_share => 'Share';

  @override
  String get shared_location_open_browser_tooltip => 'Abrir in browser';

  @override
  String get reply_preview_message_fallback => 'Mensagem';

  @override
  String get video_circle_media_kind => 'video';

  @override
  String reactions_rated_count(int count) {
    return 'Reacted: $count';
  }

  @override
  String reactions_today_time(String time) {
    return 'Hoje, $time';
  }

  @override
  String get durak_create_timer_subtitle => 'Padrão 15 segundos';

  @override
  String get dm_game_banner_active => 'Durak game in progress';

  @override
  String get dm_game_banner_created => 'Durak game created';

  @override
  String get chat_folder_favorites => 'Favorites';

  @override
  String get chat_folder_new => 'New';

  @override
  String get contact_profile_user_fallback => 'User';

  @override
  String contact_profile_error(String error) {
    return 'Erro: $error';
  }

  @override
  String get conversation_threads_loading_title => 'Tópicos';

  @override
  String get theme_label_light => 'Light';

  @override
  String get theme_label_dark => 'Dark';

  @override
  String get theme_label_auto => 'Auto';

  @override
  String get chat_draft_reply_fallback => 'Responder';

  @override
  String get mention_default_label => 'Membro';

  @override
  String get contacts_fallback_name => 'Contato';

  @override
  String get sticker_pack_default_name => 'My pack';

  @override
  String get profile_error_phone_taken =>
      'Este número de telefone já está cadastrado. Por favor, use outro número.';

  @override
  String get profile_error_email_taken =>
      'Este email já está em uso. Por favor, use outro endereço.';

  @override
  String get profile_error_username_taken =>
      'Este nome de usuário já está em uso. Por favor, escolha outro.';

  @override
  String get e2ee_banner_default_context => 'Mensagem';

  @override
  String e2ee_banner_encrypted_chat_web_only(String prefix) {
    return '$prefix para um chat criptografado só pode ser enviado pelo cliente web por enquanto.';
  }

  @override
  String get chat_attachment_decrypt_error => 'Failed to decrypt attachment';

  @override
  String get mention_fallback_label => 'member';

  @override
  String get mention_fallback_label_capitalized => 'Membro';

  @override
  String get meeting_speaking_label => 'Speaking';

  @override
  String meeting_local_you_suffix(String name) {
    return '$name (You)';
  }

  @override
  String get video_crop_title => 'Crop';

  @override
  String video_crop_load_error(String error) {
    return 'Falha ao carregar video: $error';
  }

  @override
  String get gif_section_recent => 'RECENTES';

  @override
  String get gif_section_trending => 'TRENDING';

  @override
  String get auth_create_account_title => 'Create Account';

  @override
  String yandex_sign_in_yandex_error(String error) {
    return 'Yandex: $error';
  }

  @override
  String get call_status_missed => 'Missed';

  @override
  String get call_status_cancelled => 'Cancelled';

  @override
  String get call_status_ended => 'Ended';

  @override
  String get presence_offline => 'Offline';

  @override
  String get presence_online => 'Online';

  @override
  String get dm_title_fallback => 'Chat';

  @override
  String get dm_title_partner_fallback => 'Contato';

  @override
  String get group_title_fallback => 'Chat em grupo';

  @override
  String get block_call_viewer_blocked =>
      'Você bloqueou este usuário. Chamada indisponível — desbloqueie em Perfil → Bloqueados.';

  @override
  String get block_call_partner_blocked =>
      'Este usuário restringiu a comunicação com você. Chamada indisponível.';

  @override
  String get block_call_unavailable => 'Chamada unavailable.';

  @override
  String get block_composer_viewer_blocked =>
      'Você bloqueou este usuário. Envio indisponível — desbloqueie em Perfil → Bloqueados.';

  @override
  String get block_composer_partner_blocked =>
      'Este usuário restringiu a comunicação com você. Envio indisponível.';

  @override
  String get forward_group_fallback => 'Grupo';

  @override
  String get forward_unknown_user => 'Unknown';

  @override
  String get live_location_once => 'Apenas uma vez (somente esta mensagem)';

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
  String get live_location_1day => '1 dia';

  @override
  String get live_location_forever => 'Forever (until I turn it off)';

  @override
  String get e2ee_send_too_many_files =>
      'Too many attachments for encrypted send: maximum 5 files per message.';

  @override
  String get e2ee_send_too_large =>
      'Total attachment size too large: maximum 96 MB for one encrypted message.';

  @override
  String get presence_last_seen_prefix => 'Visto por último ';

  @override
  String get presence_less_than_minute_ago => 'less than a minuto ago';

  @override
  String get presence_yesterday => 'yesterday';

  @override
  String get dm_fallback_title => 'Chat';

  @override
  String get dm_fallback_partner => 'Contato';

  @override
  String get group_fallback_title => 'Chat em grupo';

  @override
  String get block_send_viewer_blocked =>
      'Você bloqueou este usuário. Envio indisponível — desbloqueie em Perfil → Bloqueados.';

  @override
  String get block_send_partner_blocked =>
      'Este usuário restringiu a comunicação com você. Envio indisponível.';

  @override
  String get mention_fallback_name => 'Membro';

  @override
  String get profile_conflict_phone =>
      'Este número de telefone já está cadastrado. Por favor, use outro número.';

  @override
  String get profile_conflict_email =>
      'Este email já está em uso. Por favor, use outro endereço.';

  @override
  String get profile_conflict_username =>
      'Este nome de usuário já está em uso. Por favor, escolha outro.';

  @override
  String get mention_fallback_participant => 'Participant';

  @override
  String get sticker_gif_recent => 'RECENTES';

  @override
  String get meeting_screen_sharing => 'Screen';

  @override
  String get meeting_speaking => 'Speaking';

  @override
  String auth_sign_in_failed(Object error) {
    return 'Sign-in failed: $error';
  }

  @override
  String yandex_error_prefix(Object error) {
    return 'Yandex: $error';
  }

  @override
  String auth_error_prefix(Object error) {
    return 'Auth error: $error';
  }

  @override
  String presence_minutes_ago(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutos ago',
      one: 'a minuto ago',
    );
    return '$_temp0';
  }

  @override
  String presence_hours_ago(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count horas ago',
      one: 'an hora ago',
    );
    return '$_temp0';
  }

  @override
  String presence_days_ago(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dias ago',
      one: 'a dia ago',
    );
    return '$_temp0';
  }

  @override
  String presence_months_ago(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count meses ago',
      one: 'a mês ago',
    );
    return '$_temp0';
  }

  @override
  String presence_years_months_ago(int years, int months) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years anos',
      one: '1 ano',
    );
    String _temp1 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$months meses atrás',
      one: '1 mês atrás',
    );
    return '$_temp0 $_temp1';
  }

  @override
  String presence_years_ago(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count years ago',
      one: 'a year ago',
    );
    return '$_temp0';
  }

  @override
  String get wallpaper_gradient_purple => 'Purple';

  @override
  String get wallpaper_gradient_pink => 'Pink';

  @override
  String get wallpaper_gradient_blue => 'Blue';

  @override
  String get wallpaper_gradient_green => 'Green';

  @override
  String get wallpaper_gradient_sunset => 'Sunset';

  @override
  String get wallpaper_gradient_gentle => 'Gentle';

  @override
  String get wallpaper_gradient_lime => 'Lime';

  @override
  String get wallpaper_gradient_graphite => 'Graphite';

  @override
  String get sticker_tab_recent => 'RECENTES';

  @override
  String get block_call_you_blocked =>
      'Você bloqueou este usuário. Chamada indisponível — desbloqueie em Perfil → Bloqueados.';

  @override
  String get block_call_they_blocked =>
      'Este usuário restringiu a comunicação com você. Chamada indisponível.';

  @override
  String get block_call_generic => 'Chamada unavailable.';

  @override
  String get block_send_you_blocked =>
      'Você bloqueou este usuário. Envio indisponível — desbloqueie em Perfil → Bloqueados.';

  @override
  String get block_send_they_blocked =>
      'Este usuário restringiu a comunicação com você. Envio indisponível.';

  @override
  String get forward_unknown_fallback => 'Unknown';

  @override
  String get dm_title_chat => 'Chat';

  @override
  String get dm_title_partner => 'Partner';

  @override
  String get dm_title_group => 'Chat em grupo';

  @override
  String get e2ee_too_many_attachments =>
      'Too many attachments for encrypted sending: maximum 5 files per message.';

  @override
  String get e2ee_total_size_exceeded =>
      'Total attachment size too large: maximum 96 MB per encrypted message.';

  @override
  String yandex_sign_in_error_prefix(String error) {
    return 'Yandex: $error';
  }

  @override
  String get meeting_participant_screen => 'Screen';

  @override
  String get meeting_participant_speaking => 'Speaking';

  @override
  String get nav_error_title => 'Navigation error';

  @override
  String get nav_error_invalid_secret_compose =>
      'Invalid secret compose navigation';

  @override
  String get sign_in_title => 'Entrar';

  @override
  String get sign_in_firebase_ready =>
      'Firebase inicializado. Você pode entrar.';

  @override
  String get sign_in_firebase_not_ready =>
      'O Firebase não está pronto. Verifique os logs e o firebase_options.dart.';

  @override
  String get sign_in_continue => 'Continuar';

  @override
  String get sign_in_anonymously => 'Entrar anonymously';

  @override
  String sign_in_auth_error(String error) {
    return 'Auth error: $error';
  }

  @override
  String generic_error(String error) {
    return 'Erro: $error';
  }

  @override
  String get storage_label_video => 'Vídeo';

  @override
  String get storage_label_photo => 'Foto';

  @override
  String get storage_label_audio => 'Аудио';

  @override
  String get storage_label_files => 'Arquivos';

  @override
  String get storage_label_other => 'Other';

  @override
  String get storage_label_recent_stickers => 'Недавние стикеры';

  @override
  String get storage_label_giphy_search => 'GIPHY · поисковый кэш';

  @override
  String get storage_label_giphy_recent => 'GIPHY · недавние GIF';

  @override
  String get storage_chat_unattributed => 'Без привязки к чату';

  @override
  String storage_label_draft(String key) {
    return 'Draft · $key';
  }

  @override
  String get storage_label_offline_snapshot => 'Offline chat list snapshot';

  @override
  String storage_label_profile_cache(String name) {
    return 'Perfil cache · $name';
  }

  @override
  String get call_mini_end => 'End call';

  @override
  String get animation_quality_lite => 'Lite';

  @override
  String get animation_quality_balanced => 'Balanced';

  @override
  String get animation_quality_cinematic => 'Cinematic';

  @override
  String get crop_aspect_original => 'Original';

  @override
  String get crop_aspect_square => 'Square';

  @override
  String get push_notification_title => 'Allow notifications';

  @override
  String get push_notification_rationale =>
      'O app precisa de notificações para chamadas recebidas.';

  @override
  String get push_notification_required =>
      'Ativar notifications to display incoming calls.';

  @override
  String get push_notification_grant => 'Allow';

  @override
  String get push_call_accept => 'Aceitar';

  @override
  String get push_call_decline => 'Recusar';

  @override
  String get push_channel_incoming_calls => 'Incoming calls';

  @override
  String get push_channel_missed_calls => 'Missed calls';

  @override
  String get push_channel_messages_desc => 'Novas mensagens nos chats';

  @override
  String get push_channel_silent => 'Silent messages';

  @override
  String get push_channel_silent_desc => 'Push without sound';

  @override
  String get push_caller_unknown => 'Someone';

  @override
  String get outbox_attachment_single => 'Attachment';

  @override
  String outbox_attachment_count(int count) {
    return 'Attachments ($count)';
  }

  @override
  String get bottom_nav_label_chats => 'Chats';

  @override
  String get bottom_nav_label_contacts => 'Contatos';

  @override
  String get bottom_nav_label_conferences => 'Conferências';

  @override
  String get bottom_nav_label_calls => 'Chamadas';

  @override
  String get welcomeBubbleTitle => 'Bem-vindo ao LighChat';

  @override
  String get welcomeBubbleSubtitle => 'O farol está aceso';

  @override
  String get welcomeSkip => 'Skip';

  @override
  String get welcomeReplayDebugTile => 'Replay welcome animation (debug)';

  @override
  String get sticker_scope_library => 'Library';

  @override
  String get sticker_library_search_hint => 'Buscar stickers...';

  @override
  String get account_menu_energy_saving => 'Power saving';

  @override
  String get energy_saving_title => 'Economia de energia';

  @override
  String get energy_saving_section_mode => 'Power saving mode';

  @override
  String get energy_saving_section_resource_heavy => 'Resource-heavy processes';

  @override
  String get energy_saving_threshold_off => 'Desativado';

  @override
  String get energy_saving_threshold_always => 'Ativado';

  @override
  String get energy_saving_threshold_off_full => 'Never';

  @override
  String get energy_saving_threshold_always_full => 'Always';

  @override
  String energy_saving_threshold_at(int percent) {
    return 'Quando a bateria estiver abaixo de $percent%';
  }

  @override
  String get energy_saving_hint_off =>
      'Resource-heavy effects are never auto-disabled.';

  @override
  String get energy_saving_hint_always =>
      'Os efeitos pesados ficam sempre desativados, independentemente do nível da bateria.';

  @override
  String energy_saving_hint_threshold(int percent) {
    return 'Desativar automaticamente todos os processos pesados quando a bateria cair abaixo de $percent%.';
  }

  @override
  String energy_saving_current_battery(int percent) {
    return 'Current battery: $percent%';
  }

  @override
  String get energy_saving_active_now => 'mode is active';

  @override
  String get energy_saving_active_threshold =>
      'A bateria atingiu o limite — todo efeito abaixo fica temporariamente desativado.';

  @override
  String get energy_saving_active_system =>
      'Economia de energia do sistema está ativa — todo efeito abaixo fica temporariamente desativado.';

  @override
  String get energy_saving_autoplay_video_title => 'Auto-reprodução de vídeo';

  @override
  String get energy_saving_autoplay_video_subtitle =>
      'Reproduzir e repetir automaticamente mensagens em vídeo e vídeos nos chats.';

  @override
  String get energy_saving_autoplay_gif_title => 'Auto-reprodução de GIF';

  @override
  String get energy_saving_autoplay_gif_subtitle =>
      'Reproduzir e repetir GIFs automaticamente nos chats e no teclado.';

  @override
  String get energy_saving_animated_stickers_title => 'Animadas stickers';

  @override
  String get energy_saving_animated_stickers_subtitle =>
      'Looped sticker animations and full-screen Premium sticker effects.';

  @override
  String get energy_saving_animated_emoji_title => 'Emoji animado';

  @override
  String get energy_saving_animated_emoji_subtitle =>
      'Animação de emoji em loop em mensagens, reações e status.';

  @override
  String get energy_saving_interface_animations_title =>
      'Animações da interface';

  @override
  String get energy_saving_interface_animations_subtitle =>
      'Efeitos e animações que tornam o LighChat mais fluido e expressivo.';

  @override
  String get energy_saving_media_preload_title => 'Pré-carregar mídia';

  @override
  String get energy_saving_media_preload_subtitle =>
      'Começar a baixar arquivos de mídia ao abrir a lista de chats.';

  @override
  String get energy_saving_background_update_title => 'Plano de fundo update';

  @override
  String get energy_saving_background_update_subtitle =>
      'Quick chat updates when switching between apps.';

  @override
  String get legal_index_title => 'Юридические документы';

  @override
  String get legal_index_subtitle =>
      'Политика конфиденциальности, пользовательское соглашение и другие юридические документы, регулирующие использование LighChat.';

  @override
  String get legal_settings_section_title => 'Правовая информация';

  @override
  String get legal_settings_section_subtitle =>
      'Политика конфиденциальности, пользовательское соглашение, EULA и другие документы.';

  @override
  String get legal_not_found => 'Документ не найден';

  @override
  String get legal_title_privacy_policy => 'Политика конфиденциальности';

  @override
  String get legal_title_terms_of_service => 'Пользовательское соглашение';

  @override
  String get legal_title_cookie_policy => 'Политика использования cookies';

  @override
  String get legal_title_eula => 'Лицензионное соглашение (EULA)';

  @override
  String get legal_title_dpa => 'Соглашение об обработке данных (DPA)';

  @override
  String get legal_title_children => 'Политика в отношении несовершеннолетних';

  @override
  String get legal_title_moderation => 'Политика модерации контента';

  @override
  String get legal_title_aup => 'Правила допустимого использования';

  @override
  String get chat_list_item_sender_you => 'Você';

  @override
  String get chat_preview_message => 'Mensagem';

  @override
  String get chat_preview_sticker => 'Figurinha';

  @override
  String get chat_preview_attachment => 'Anexo';
}

/// The translations for Portuguese, as used in Brazil (`pt_BR`).
class AppLocalizationsPtBr extends AppLocalizationsPt {
  AppLocalizationsPtBr() : super('pt_BR');

  @override
  String get secret_chat_title => 'Chat secreto';

  @override
  String get secret_chats_title => 'Chats secretos';

  @override
  String get secret_chat_locked_title => 'Chat secreto bloqueado';

  @override
  String get secret_chat_locked_subtitle =>
      'Digite seu PIN para desbloquear e ver as mensagens.';

  @override
  String get secret_chat_unlock_title => 'Desbloquear chat secreto';

  @override
  String get secret_chat_unlock_subtitle =>
      'É necessário um PIN para abrir este chat.';

  @override
  String get secret_chat_unlock_action => 'Desbloquear';

  @override
  String get secret_chat_set_pin_and_unlock => 'Definir PIN e desbloquear';

  @override
  String get secret_chat_pin_label => 'PIN (4 dígitos)';

  @override
  String get secret_chat_pin_invalid => 'Digite um PIN de 4 dígitos';

  @override
  String get secret_chat_already_exists =>
      'Já existe um chat secreto com este usuário.';

  @override
  String get secret_chat_exists_badge => 'Criado';

  @override
  String get secret_chat_unlock_failed =>
      'Não foi possível desbloquear. Tente novamente.';

  @override
  String get secret_chat_action_not_allowed =>
      'Esta ação não é permitida em um chat secreto';

  @override
  String get secret_chat_remember_pin => 'Lembrar PIN neste dispositivo';

  @override
  String get secret_chat_unlock_biometric => 'Desbloquear com biometria';

  @override
  String get secret_chat_biometric_reason => 'Desbloquear chat secreto';

  @override
  String get secret_chat_biometric_no_saved_pin =>
      'Digite o PIN uma vez para habilitar o desbloqueio biométrico';

  @override
  String get secret_chat_ttl_title => 'Duração do chat secreto';

  @override
  String get secret_chat_settings_title => 'Configurações do chat secreto';

  @override
  String get secret_chat_settings_subtitle => 'Duração, acesso e restrições';

  @override
  String get secret_chat_settings_not_secret =>
      'Este chat não é um chat secreto';

  @override
  String get secret_chat_settings_ttl => 'Duração';

  @override
  String secret_chat_settings_time_left(Object value) {
    return 'Tempo restante: $value';
  }

  @override
  String secret_chat_settings_expires_at(Object iso) {
    return 'Expira em: $iso';
  }

  @override
  String get secret_chat_settings_unlock_grant_ttl => 'Duração do desbloqueio';

  @override
  String get secret_chat_settings_unlock_grant_ttl_subtitle =>
      'Por quanto tempo o acesso fica ativo após o desbloqueio';

  @override
  String get secret_chat_settings_no_copy => 'Desativar cópia';

  @override
  String get secret_chat_settings_no_forward => 'Desativar encaminhamento';

  @override
  String get secret_chat_settings_no_save => 'Desativar salvar mídia';

  @override
  String get secret_chat_settings_screenshot_protection =>
      'Proteção contra capturas de tela (Android)';

  @override
  String get secret_chat_settings_media_views =>
      'Limites de visualização de mídia';

  @override
  String get secret_chat_settings_media_views_subtitle =>
      'Limites aproximados de visualizações pelo destinatário';

  @override
  String get secret_chat_media_type_image => 'Imagens';

  @override
  String get secret_chat_media_type_video => 'Vídeos';

  @override
  String get secret_chat_media_type_voice => 'Mensagens de voz';

  @override
  String get secret_chat_media_type_location => 'Localização';

  @override
  String get secret_chat_media_type_file => 'Arquivos';

  @override
  String get secret_chat_media_views_unlimited => 'Ilimitado';

  @override
  String get secret_chat_compose_create => 'Criar chat secreto';

  @override
  String get secret_chat_compose_vault_pin_subtitle =>
      'Opcional: defina um PIN do cofre de 4 dígitos usado para desbloquear a caixa de entrada secreta (armazenado neste dispositivo para biometria quando habilitado).';

  @override
  String get secret_chat_compose_require_unlock_pin =>
      'Exigir PIN para abrir este chat';

  @override
  String get secret_chat_settings_read_only_hint =>
      'Estas configurações são fixadas na criação e não podem ser alteradas.';

  @override
  String get secret_chat_settings_delete => 'Excluir chat secreto';

  @override
  String get secret_chat_settings_delete_confirm_title =>
      'Excluir este chat secreto?';

  @override
  String get secret_chat_settings_delete_confirm_body =>
      'Mensagens e mídia serão removidas para os dois participantes.';

  @override
  String get privacy_secret_vault_title => 'Cofre secreto';

  @override
  String get privacy_secret_vault_subtitle =>
      'Verificações globais de PIN e biometria para entrar nos chats secretos.';

  @override
  String get privacy_secret_vault_change_pin =>
      'Definir ou alterar PIN do cofre';

  @override
  String get privacy_secret_vault_change_pin_subtitle =>
      'Se já existe um PIN, confirme com o PIN antigo ou biometria.';

  @override
  String get privacy_secret_vault_bio_subtitle =>
      'Realizar verificação biométrica e validar o PIN local salvo.';

  @override
  String get privacy_secret_vault_bio_reason =>
      'Confirmar acesso aos chats secretos';

  @override
  String get privacy_secret_vault_current_pin => 'PIN atual';

  @override
  String get privacy_secret_vault_new_pin => 'Novo PIN';

  @override
  String get privacy_secret_vault_repeat_pin => 'Repetir novo PIN';

  @override
  String get privacy_secret_vault_pin_mismatch => 'Os PINs não coincidem';

  @override
  String get privacy_secret_vault_pin_updated => 'PIN do cofre atualizado';

  @override
  String get privacy_secret_vault_bio_unavailable =>
      'Autenticação biométrica não está disponível neste dispositivo';

  @override
  String get privacy_secret_vault_bio_verified =>
      'Verificação biométrica aprovada';

  @override
  String get privacy_secret_vault_setup_required =>
      'Configure primeiro o PIN ou o acesso biométrico em Privacidade.';

  @override
  String get privacy_secret_vault_network_timeout =>
      'Tempo limite de rede excedido. Tente novamente.';

  @override
  String privacy_secret_vault_error(Object error) {
    return 'Erro do cofre secreto: $error';
  }

  @override
  String get tournament_title => 'Torneio';

  @override
  String get tournament_subtitle => 'Classificação e séries de jogos';

  @override
  String get tournament_new_game => 'Novo jogo';

  @override
  String get tournament_standings => 'Classificação';

  @override
  String get tournament_standings_empty => 'Ainda não há resultados';

  @override
  String get tournament_games => 'Jogos';

  @override
  String get tournament_games_empty => 'Ainda não há jogos';

  @override
  String tournament_points(Object pts) {
    return '$pts pts';
  }

  @override
  String tournament_games_played(Object n) {
    return '$n jogos';
  }

  @override
  String tournament_create_failed(Object err) {
    return 'Não foi possível criar o torneio: $err';
  }

  @override
  String tournament_create_game_failed(Object err) {
    return 'Não foi possível criar o jogo: $err';
  }

  @override
  String tournament_game_players(Object names) {
    return 'Jogadores: $names';
  }

  @override
  String get tournament_game_result_draw => 'Resultado: empate';

  @override
  String tournament_game_result_loser(Object name) {
    return 'Resultado: durak — $name';
  }

  @override
  String tournament_game_place(Object place) {
    return 'Posição $place';
  }

  @override
  String get durak_dm_lobby_banner =>
      'Seu parceiro criou um lobby de Durak — entre';

  @override
  String get durak_dm_lobby_open => 'Abrir lobby';

  @override
  String get conversation_game_lobby_cancel => 'Encerrar espera';

  @override
  String conversation_game_lobby_cancel_failed(Object err) {
    return 'Não foi possível encerrar a espera: $err';
  }

  @override
  String secret_chat_media_views_count(Object count) {
    return '$count visualizações';
  }

  @override
  String secret_chat_settings_load_failed(Object error) {
    return 'Falha ao carregar: $error';
  }

  @override
  String secret_chat_settings_save_failed(Object error) {
    return 'Falha ao salvar: $error';
  }

  @override
  String get secret_chat_settings_reset_strict => 'Restaurar padrões rígidos';

  @override
  String get secret_chat_settings_reset_strict_subtitle =>
      'Habilita todas as restrições e define o limite de visualizações de mídia em 1';

  @override
  String get settings_language_title => 'Idioma';

  @override
  String get settings_language_system => 'Sistema';

  @override
  String get settings_language_ru => 'Russo';

  @override
  String get settings_language_en => 'Inglês';

  @override
  String get settings_language_hint_system =>
      'Quando “Sistema” está selecionado, o app segue as configurações de idioma do dispositivo.';

  @override
  String get account_menu_profile => 'Perfil';

  @override
  String get account_menu_features => 'Recursos';

  @override
  String get account_menu_chat_settings => 'Configurações do chat';

  @override
  String get account_menu_notifications => 'Notificações';

  @override
  String get account_menu_privacy => 'Privacidade';

  @override
  String get account_menu_devices => 'Dispositivos';

  @override
  String get account_menu_blacklist => 'Lista de bloqueados';

  @override
  String get account_menu_language => 'Idioma';

  @override
  String get account_menu_storage => 'Armazenamento';

  @override
  String get account_menu_theme => 'Tema';

  @override
  String get account_menu_sign_out => 'Sair';

  @override
  String get storage_settings_title => 'Armazenamento';

  @override
  String get storage_settings_subtitle =>
      'Controle quais dados ficam em cache neste dispositivo e limpe por chats ou arquivos.';

  @override
  String get storage_settings_total_label => 'Usado neste dispositivo';

  @override
  String storage_settings_budget_label(Object gb) {
    return 'Limite do cache: $gb GB';
  }

  @override
  String get storage_unit_gb => 'GB';

  @override
  String get storage_settings_clear_all_button => 'Limpar todo o cache';

  @override
  String get storage_settings_trim_button => 'Ajustar ao limite';

  @override
  String get storage_settings_policy_title => 'O que manter localmente';

  @override
  String get storage_settings_budget_slider_title => 'Limite do cache';

  @override
  String get storage_settings_breakdown_title => 'Por tipo de dado';

  @override
  String get storage_settings_breakdown_empty => 'Não local cached data yet.';

  @override
  String get storage_settings_chats_title => 'Por chat';

  @override
  String get storage_settings_chats_empty => 'Não chat-specific cache yet.';

  @override
  String storage_settings_chat_subtitle(Object count, Object size) {
    return '$count itens · $size';
  }

  @override
  String get storage_settings_general_title => 'Cache não atribuído';

  @override
  String get storage_settings_general_hint =>
      'Entradas que não estão vinculadas a um chat específico (cache antigo/global).';

  @override
  String get storage_settings_general_empty => 'Não shared cache entries.';

  @override
  String get storage_settings_chat_files_empty =>
      'Sem arquivos locais no cache deste chat.';

  @override
  String get storage_settings_clear_chat_action => 'Limpar cache do chat';

  @override
  String get storage_settings_clear_all_title => 'Limpar cache local?';

  @override
  String get storage_settings_clear_all_body =>
      'Isso vai remover arquivos em cache, prévias, rascunhos e snapshots offline deste dispositivo.';

  @override
  String storage_settings_clear_chat_title(Object chat) {
    return 'Limpar cache de “$chat”?';
  }

  @override
  String get storage_settings_clear_chat_body =>
      'Apenas o cache deste chat será excluído. As mensagens na nuvem permanecem intactas.';

  @override
  String get storage_settings_snackbar_cleared => 'Cache local limpo';

  @override
  String get storage_settings_snackbar_budget_already_ok =>
      'O cache já está dentro do limite definido';

  @override
  String storage_settings_snackbar_budget_trimmed(Object size) {
    return 'Liberado: $size';
  }

  @override
  String get storage_settings_error_empty =>
      'Não foi possível gerar as estatísticas de armazenamento';

  @override
  String get storage_category_e2ee_media => 'Cache de mídia E2EE';

  @override
  String get storage_category_e2ee_media_subtitle =>
      'Arquivos de mídia secretos descriptografados por chat para reabertura mais rápida.';

  @override
  String get storage_category_e2ee_text => 'Cache de texto E2EE';

  @override
  String get storage_category_e2ee_text_subtitle =>
      'Trechos de texto descriptografados por chat para renderização instantânea.';

  @override
  String get storage_category_drafts => 'Rascunhos de mensagens';

  @override
  String get storage_category_drafts_subtitle =>
      'Texto de rascunhos não enviados por chat.';

  @override
  String get storage_category_chat_list_snapshot => 'Lista de chats offline';

  @override
  String get storage_category_chat_list_snapshot_subtitle =>
      'Snapshot recente da lista de chats para iniciar rápido offline.';

  @override
  String get storage_category_profile_cards => 'Mini-cache de perfis';

  @override
  String get storage_category_profile_cards_subtitle =>
      'Nomes e avatares salvos para uma interface mais rápida.';

  @override
  String get storage_category_video_downloads => 'Cache de vídeos baixados';

  @override
  String get storage_category_video_downloads_subtitle =>
      'Vídeos baixados localmente a partir de visualizações na galeria.';

  @override
  String get storage_category_video_thumbs => 'Quadros de prévia de vídeo';

  @override
  String get storage_category_video_thumbs_subtitle =>
      'Miniaturas de primeiro quadro geradas para vídeos.';

  @override
  String get storage_category_chat_images => 'Fotos do chat';

  @override
  String get storage_category_chat_images_subtitle =>
      'Fotos e figurinhas em cache dos chats abertos.';

  @override
  String get storage_media_type_video => 'Vídeo';

  @override
  String get storage_media_type_photo => 'Fotos';

  @override
  String get storage_media_type_files => 'Arquivos';

  @override
  String get storage_media_type_other => 'Outro';

  @override
  String storage_settings_device_usage(Object pct) {
    return 'Usa $pct% do limite de cache';
  }

  @override
  String get storage_settings_clear_all_hint =>
      'Toda a mídia continua na nuvem. Você pode baixar de novo quando quiser.';

  @override
  String get storage_auto_delete_title =>
      'Excluir mídia em cache automaticamente';

  @override
  String get storage_auto_delete_personal => 'Chats pessoais';

  @override
  String get storage_auto_delete_groups => 'Grupos';

  @override
  String get storage_auto_delete_never => 'Nunca';

  @override
  String get storage_auto_delete_3_days => '3 dias';

  @override
  String get storage_auto_delete_1_week => '1 semana';

  @override
  String get storage_auto_delete_1_month => '1 mês';

  @override
  String get storage_auto_delete_3_months => '3 meses';

  @override
  String get storage_auto_delete_hint =>
      'Fotos, vídeos e arquivos que você não abriu durante esse período serão removidos do dispositivo para liberar espaço.';

  @override
  String storage_chat_detail_share(Object pct) {
    return 'Este chat usa $pct% do seu cache';
  }

  @override
  String get storage_chat_detail_media_tab => 'Mídia';

  @override
  String get storage_chat_detail_select_all => 'Selecionar tudo';

  @override
  String get storage_chat_detail_deselect_all => 'Desmarcar tudo';

  @override
  String storage_chat_detail_clear_button(Object size) {
    return 'Limpar cache $size';
  }

  @override
  String get storage_chat_detail_clear_button_empty =>
      'Selecione arquivos para excluir';

  @override
  String get storage_chat_detail_tab_empty => 'Nada nesta aba.';

  @override
  String get storage_chat_detail_delete_title => 'Excluir selected files?';

  @override
  String storage_chat_detail_delete_body(Object count, Object size) {
    return '$count arquivos ($size) serão removidos do dispositivo. As cópias na nuvem permanecem intactas.';
  }

  @override
  String get profile_delete_account => 'Excluir account';

  @override
  String get profile_delete_account_confirm_title =>
      'Excluir sua conta permanentemente?';

  @override
  String get profile_delete_account_confirm_body =>
      'Sua conta será removida do Firebase Auth e todos os seus documentos do Firestore serão excluídos permanentemente. Seus chats permanecerão visíveis para os outros em modo somente leitura.';

  @override
  String get profile_delete_account_confirm_action => 'Excluir account';

  @override
  String profile_delete_account_error(Object error) {
    return 'Não foi possível excluir a conta: $error';
  }

  @override
  String get chat_readonly_deleted_user =>
      'Conta excluída. Este chat é somente leitura.';

  @override
  String get blacklist_empty => 'Não blocked users';

  @override
  String get blacklist_action_unblock => 'Desbloquear';

  @override
  String get blacklist_unblock_confirm_title => 'Desbloquear?';

  @override
  String get blacklist_unblock_confirm_body =>
      'Este usuário poderá te enviar mensagens novamente (se a política de contatos permitir) e ver seu perfil na busca.';

  @override
  String get blacklist_unblock_success => 'Usuário desbloqueado';

  @override
  String blacklist_unblock_error(Object error) {
    return 'Não foi possível desbloquear: $error';
  }

  @override
  String get partner_profile_block_confirm_title => 'Bloquear este usuário?';

  @override
  String get partner_profile_block_confirm_body =>
      'Ele não verá um chat com você, não poderá te encontrar na busca nem te adicionar aos contatos. Você sumirá dos contatos dele. Você mantém o histórico do chat, mas não pode mandar mensagens enquanto ele estiver bloqueado.';

  @override
  String get partner_profile_block_action => 'Bloquear';

  @override
  String get partner_profile_block_success => 'Usuário bloqueado';

  @override
  String partner_profile_block_error(Object error) {
    return 'Não foi possível bloquear: $error';
  }

  @override
  String get common_soon => 'Em breve';

  @override
  String common_theme_prefix(Object label) {
    return 'Tema: $label';
  }

  @override
  String common_error_cannot_save_theme(Object error) {
    return 'Não foi possível salvar o tema: $error';
  }

  @override
  String common_error_cannot_sign_out(Object error) {
    return 'Não foi possível sair: $error';
  }

  @override
  String account_error_profile(Object error) {
    return 'Perfil error: $error';
  }

  @override
  String get notifications_title => 'Notificações';

  @override
  String get notifications_section_main => 'Principal';

  @override
  String get notifications_mute_all_title => 'Desativar tudo';

  @override
  String get notifications_mute_all_subtitle =>
      'Desativar todas as notificações.';

  @override
  String get notifications_sound_title => 'Som';

  @override
  String get notifications_sound_subtitle =>
      'Tocar um som para novas mensagens.';

  @override
  String get notifications_preview_title => 'Prévia';

  @override
  String get notifications_preview_subtitle =>
      'Mostrar o texto da mensagem nas notificações.';

  @override
  String get notifications_section_quiet_hours => 'Horário silencioso';

  @override
  String get notifications_quiet_hours_subtitle =>
      'As notificações não vão te incomodar nesse intervalo de tempo.';

  @override
  String get notifications_quiet_hours_enable_title =>
      'Ativar horário silencioso';

  @override
  String get notifications_reset_button => 'Restaurar configurações';

  @override
  String notifications_error_cannot_save(Object error) {
    return 'Não foi possível salvar settings: $error';
  }

  @override
  String notifications_error_load(Object error) {
    return 'Não foi possível carregar notifications: $error';
  }

  @override
  String get privacy_title => 'Privacidade do chat';

  @override
  String privacy_error_cannot_save(Object error) {
    return 'Não foi possível salvar settings: $error';
  }

  @override
  String privacy_error_load(Object error) {
    return 'Não foi possível carregar privacy settings: $error';
  }

  @override
  String get privacy_e2ee_section => 'Criptografia de ponta a ponta';

  @override
  String get privacy_e2ee_enable_for_all_chats =>
      'Ativar E2EE em todos os chats';

  @override
  String get privacy_e2ee_what_encrypt => 'O que é criptografado em chats E2EE';

  @override
  String get privacy_e2ee_text => 'Texto da mensagem';

  @override
  String get privacy_e2ee_media => 'Anexos (mídia/arquivos)';

  @override
  String get privacy_my_devices_title => 'Meus dispositivos';

  @override
  String get privacy_my_devices_subtitle =>
      'Dispositivos com chaves publicadas. Renomeie ou revogue acesso.';

  @override
  String get privacy_key_backup_title => 'Backup e transferência de chave';

  @override
  String get privacy_key_backup_subtitle =>
      'Crie um backup com senha ou transfira a chave por QR.';

  @override
  String get privacy_visibility_section => 'Visibilidade';

  @override
  String get privacy_online_title => 'Status online';

  @override
  String get privacy_online_subtitle =>
      'Permitir que outros vejam quando você está online.';

  @override
  String get privacy_last_seen_title => 'Visto por último';

  @override
  String get privacy_last_seen_subtitle =>
      'Mostrar quando você esteve ativo pela última vez.';

  @override
  String get privacy_read_receipts_title => 'Confirmação de leitura';

  @override
  String get privacy_read_receipts_subtitle =>
      'Permitir que remetentes vejam que você leu a mensagem.';

  @override
  String get privacy_group_invites_section => 'Convites para grupos';

  @override
  String get privacy_group_invites_subtitle =>
      'Quem pode te adicionar a chats em grupo.';

  @override
  String get privacy_group_invites_everyone => 'Todos';

  @override
  String get privacy_group_invites_contacts => 'Apenas contatos';

  @override
  String get privacy_group_invites_nobody => 'Ninguém';

  @override
  String get privacy_global_search_section => 'Descoberta';

  @override
  String get privacy_global_search_subtitle =>
      'Quem pode te encontrar pelo nome entre todos os usuários.';

  @override
  String get privacy_global_search_title => 'Busca global';

  @override
  String get privacy_global_search_hint =>
      'Se desativada, você não aparece em “Todos os usuários” quando alguém inicia um novo chat. Você ainda fica visível para quem te adicionou como contato.';

  @override
  String get privacy_profile_for_others_section => 'Perfil para outros';

  @override
  String get privacy_profile_for_others_subtitle =>
      'O que outros podem ver no seu perfil.';

  @override
  String get privacy_email_subtitle => 'Seu endereço de email no seu perfil.';

  @override
  String get privacy_phone_title => 'Número de telefone';

  @override
  String get privacy_phone_subtitle => 'Mostrado no seu perfil e nos contatos.';

  @override
  String get privacy_birthdate_title => 'Data de nascimento';

  @override
  String get privacy_birthdate_subtitle =>
      'Seu campo de aniversário no perfil.';

  @override
  String get privacy_about_title => 'Sobre';

  @override
  String get privacy_about_subtitle => 'Seu texto de bio no perfil.';

  @override
  String get privacy_reset_button => 'Restaurar configurações';

  @override
  String get common_cancel => 'Cancelar';

  @override
  String get common_create => 'Criar';

  @override
  String get common_delete => 'Excluir';

  @override
  String get common_choose => 'Escolher';

  @override
  String get common_save => 'Salvar';

  @override
  String get common_close => 'Fechar';

  @override
  String get common_nothing_found => 'Nada encontrado';

  @override
  String get common_retry => 'Tentar de novo';

  @override
  String get auth_login_email_label => 'Email';

  @override
  String get auth_login_password_label => 'Senha';

  @override
  String get auth_login_password_hint => 'Senha';

  @override
  String get auth_login_sign_in => 'Entrar';

  @override
  String get auth_login_forgot_password => 'Esqueceu a senha?';

  @override
  String get auth_login_error_enter_email_for_reset =>
      'Digite seu email para redefinir a senha';

  @override
  String get profile_title => 'Perfil';

  @override
  String get profile_edit_tooltip => 'Editar';

  @override
  String get profile_full_name_label => 'Nome completo';

  @override
  String get profile_full_name_hint => 'Nome';

  @override
  String get profile_username_label => 'Nome de usuário';

  @override
  String get profile_email_label => 'Email';

  @override
  String get profile_phone_label => 'Telefone';

  @override
  String get profile_birthdate_label => 'Data de nascimento';

  @override
  String get profile_about_label => 'Sobre';

  @override
  String get profile_about_hint => 'Uma bio curta';

  @override
  String get profile_password_toggle_show => 'Alterar senha';

  @override
  String get profile_password_toggle_hide => 'Ocultar alteração de senha';

  @override
  String get profile_password_new_label => 'Nova senha';

  @override
  String get profile_password_confirm_label => 'Confirmar senha';

  @override
  String get profile_password_tooltip_show => 'Mostrar senha';

  @override
  String get profile_password_tooltip_hide => 'Ocultar';

  @override
  String get profile_placeholder_username => 'username';

  @override
  String get profile_placeholder_email => 'nome@exemplo.com';

  @override
  String get profile_placeholder_phone => '+55 11 90000-0000';

  @override
  String get profile_placeholder_birthdate => 'DD.MM.AAAA';

  @override
  String get profile_placeholder_password_dots => '••••••••';

  @override
  String get profile_password_error_fill_both =>
      'Preencha a nova senha e a confirmação.';

  @override
  String get settings_chats_title => 'Configurações do chat';

  @override
  String get settings_chats_preview => 'Prévia';

  @override
  String get settings_chats_outgoing => 'Mensagens enviadas';

  @override
  String get settings_chats_incoming => 'Mensagens recebidas';

  @override
  String get settings_chats_font_size => 'Tamanho do texto';

  @override
  String get settings_chats_font_small => 'Pequeno';

  @override
  String get settings_chats_font_medium => 'Médio';

  @override
  String get settings_chats_font_large => 'Grande';

  @override
  String get settings_chats_bubble_shape => 'Forma do balão';

  @override
  String get settings_chats_bubble_rounded => 'Arredondado';

  @override
  String get settings_chats_bubble_square => 'Quadrado';

  @override
  String get settings_chats_chat_background => 'Plano de fundo do chat';

  @override
  String get settings_chats_chat_background_pick_hint =>
      'Escolha uma foto ou ajuste o plano de fundo';

  @override
  String get settings_chats_advanced => 'Avançado';

  @override
  String get settings_chats_show_time => 'Mostrar horário';

  @override
  String get settings_chats_show_time_subtitle =>
      'Mostrar o horário da mensagem abaixo dos balões';

  @override
  String get settings_chats_reset => 'Restaurar configurações';

  @override
  String settings_chats_error_cannot_save(Object error) {
    return 'Não foi possível salvar: $error';
  }

  @override
  String settings_chats_error_wallpaper_load(Object error) {
    return 'Não foi possível carregar o plano de fundo: $error';
  }

  @override
  String settings_chats_error_wallpaper_delete(Object error) {
    return 'Não foi possível excluir o plano de fundo: $error';
  }

  @override
  String get settings_chats_wallpaper_delete_confirm_title =>
      'Excluir plano de fundo?';

  @override
  String get settings_chats_wallpaper_delete_confirm_body =>
      'Este plano de fundo será removido da sua lista.';

  @override
  String settings_chats_icon_picker_title(Object label) {
    return 'Ícone: “$label”';
  }

  @override
  String get settings_chats_icon_picker_search_hint => 'Buscar por nome…';

  @override
  String get settings_chats_icon_color => 'Cor do ícone';

  @override
  String get settings_chats_reset_icon_size => 'Restaurar tamanho';

  @override
  String get settings_chats_reset_icon_stroke => 'Restaurar traço';

  @override
  String get settings_chats_tile_background => 'Plano de fundo do bloco';

  @override
  String get settings_chats_default_gradient => 'Gradiente padrão';

  @override
  String get settings_chats_inherit_global => 'Usar configurações globais';

  @override
  String get settings_chats_no_background => 'Sem plano de fundo';

  @override
  String get settings_chats_no_background_on => 'Sem plano de fundo (ativado)';

  @override
  String get chat_list_title => 'Chats';

  @override
  String get chat_list_search_hint => 'Buscar…';

  @override
  String get chat_list_loading_connecting => 'Conectando…';

  @override
  String get chat_list_loading_conversations => 'Carregando conversas…';

  @override
  String get chat_list_loading_list => 'Carregando lista de chats…';

  @override
  String get chat_list_loading_sign_out => 'Saindo…';

  @override
  String get chat_list_empty_search_title => 'Nenhum chat encontrado';

  @override
  String get chat_list_empty_search_body =>
      'Tente outra busca. A pesquisa funciona por nome e nome de usuário.';

  @override
  String get chat_list_empty_folder_title => 'Esta pasta está vazia';

  @override
  String get chat_list_empty_folder_body =>
      'Mude de pasta ou inicie um novo chat usando o botão acima.';

  @override
  String get chat_list_empty_all_title => 'Sem chats ainda';

  @override
  String get chat_list_empty_all_body =>
      'Inicie um novo chat para começar a conversar.';

  @override
  String get chat_list_action_new_folder => 'Nova pasta';

  @override
  String get chat_list_action_new_chat => 'Novo chat';

  @override
  String get chat_list_action_create => 'Criar';

  @override
  String get chat_list_action_close => 'Fechar';

  @override
  String get chat_list_folders_title => 'Pastas';

  @override
  String get chat_list_folders_subtitle => 'Escolha as pastas para este chat.';

  @override
  String get chat_list_folders_empty => 'Ainda não há pastas personalizadas.';

  @override
  String get chat_list_create_folder_title => 'Nova pasta';

  @override
  String get chat_list_create_folder_subtitle =>
      'Crie uma pasta para filtrar seus chats rapidamente.';

  @override
  String get chat_list_create_folder_name_label => 'NOME DA PASTA';

  @override
  String chat_list_create_folder_chats_label(Object count) {
    return 'CHATS ($count)';
  }

  @override
  String get chat_list_create_folder_select_all => 'SELECIONAR TUDO';

  @override
  String get chat_list_create_folder_reset => 'REDEFINIR';

  @override
  String get chat_list_create_folder_search_hint => 'Buscar por nome…';

  @override
  String get chat_list_create_folder_no_matches => 'Nenhum chat correspondente';

  @override
  String get chat_list_folder_default_starred => 'Favoritas';

  @override
  String get chat_list_folder_default_all => 'Todos';

  @override
  String get chat_list_folder_default_new => 'Novos';

  @override
  String get chat_list_folder_default_direct => 'Diretos';

  @override
  String get chat_list_folder_default_groups => 'Grupos';

  @override
  String get chat_list_yesterday => 'Ontem';

  @override
  String get chat_list_folder_delete_action => 'Excluir';

  @override
  String get chat_list_folder_delete_title => 'Excluir pasta?';

  @override
  String chat_list_folder_delete_body(Object name) {
    return 'A pasta \"$name\" será excluída. Os chats permanecem intactos.';
  }

  @override
  String chat_list_error_open_starred(Object error) {
    return 'Não foi possível abrir Favoritas: $error';
  }

  @override
  String chat_list_error_delete_folder(Object error) {
    return 'Não foi possível excluir a pasta: $error';
  }

  @override
  String get chat_list_pin_not_available =>
      'Fixar não está disponível nesta pasta.';

  @override
  String chat_list_pin_pinned_in_folder(Object name) {
    return 'Chat fixado em \"$name\"';
  }

  @override
  String chat_list_pin_unpinned_in_folder(Object name) {
    return 'Chat desafixado de \"$name\"';
  }

  @override
  String chat_list_error_toggle_pin(Object error) {
    return 'Não foi possível alterar a fixação: $error';
  }

  @override
  String chat_list_error_update_folder(Object error) {
    return 'Não foi possível atualizar a pasta: $error';
  }

  @override
  String get chat_list_clear_history_title => 'Limpar histórico?';

  @override
  String get chat_list_clear_history_body =>
      'As mensagens vão sumir apenas da sua visão do chat. O outro participante mantém o histórico.';

  @override
  String get chat_list_clear_history_confirm => 'Limpar';

  @override
  String chat_list_error_clear_history(Object error) {
    return 'Não foi possível limpar o histórico: $error';
  }

  @override
  String chat_list_error_mark_read(Object error) {
    return 'Não foi possível marcar o chat como lido: $error';
  }

  @override
  String get chat_list_delete_chat_title => 'Excluir chat?';

  @override
  String get chat_list_delete_chat_body =>
      'A conversa será excluída permanentemente para todos os participantes. Não dá para desfazer.';

  @override
  String get chat_list_delete_chat_confirm => 'Excluir';

  @override
  String chat_list_error_delete_chat(Object error) {
    return 'Não foi possível excluir o chat: $error';
  }

  @override
  String get chat_list_context_folders => 'Pastas';

  @override
  String get chat_list_context_unpin => 'Desafixar chat';

  @override
  String get chat_list_context_pin => 'Fixar chat';

  @override
  String get chat_list_context_mark_all_read => 'Marcar tudo como lido';

  @override
  String get chat_list_context_clear_history => 'Limpar histórico';

  @override
  String get chat_list_context_delete_chat => 'Excluir chat';

  @override
  String get chat_list_snackbar_history_cleared => 'Histórico limpo.';

  @override
  String get chat_list_snackbar_marked_read => 'Marcado como lido.';

  @override
  String chat_list_error_generic(Object error) {
    return 'Erro: $error';
  }

  @override
  String get chat_calls_title => 'Chamadas';

  @override
  String get chat_calls_search_hint => 'Buscar por nome…';

  @override
  String get chat_calls_empty => 'Seu histórico de chamadas está vazio.';

  @override
  String get chat_calls_nothing_found => 'Nada encontrado.';

  @override
  String chat_calls_error_load(Object error) {
    return 'Não foi possível carregar as chamadas:\n$error';
  }

  @override
  String get chat_reply_cancel_tooltip => 'Cancelar resposta';

  @override
  String get voice_preview_tooltip_cancel => 'Cancelar';

  @override
  String get voice_preview_tooltip_send => 'Enviar';

  @override
  String get profile_qr_title => 'Meu código QR';

  @override
  String get profile_qr_tooltip_close => 'Fechar';

  @override
  String get profile_qr_share_title => 'Meu perfil do LighChat';

  @override
  String get profile_qr_share_subject => 'Perfil do LighChat';

  @override
  String chat_media_norm_pending_title(Object mediaKind) {
    return 'Processando $mediaKind…';
  }

  @override
  String chat_media_norm_failed_title(Object mediaKind) {
    return 'Não foi possível processar $mediaKind';
  }

  @override
  String get chat_media_norm_pending_subtitle =>
      'O arquivo ficará disponível após o processamento no servidor.';

  @override
  String get chat_media_norm_failed_subtitle =>
      'Tente iniciar o processamento de novo.';

  @override
  String get conversation_threads_title => 'Tópicos';

  @override
  String get conversation_threads_empty => 'Sem tópicos ainda';

  @override
  String get conversation_threads_root_attachment => 'Anexo';

  @override
  String get conversation_threads_root_message => 'Mensagem';

  @override
  String conversation_threads_snippet_you(Object text) {
    return 'Você: $text';
  }

  @override
  String get conversation_threads_day_today => 'Hoje';

  @override
  String get conversation_threads_day_yesterday => 'Ontem';

  @override
  String conversation_threads_replies_badge(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count respostas',
      one: '$count resposta',
    );
    return '$_temp0';
  }

  @override
  String get chat_meetings_title => 'Reuniões';

  @override
  String get chat_meetings_subtitle =>
      'Crie conferências e gerencie o acesso dos participantes';

  @override
  String get chat_meetings_section_new => 'Nova reunião';

  @override
  String get chat_meetings_field_title_label => 'Título da reunião';

  @override
  String get chat_meetings_field_title_hint =>
      'Por exemplo, Sincronização de logística';

  @override
  String get chat_meetings_field_duration_label => 'Duração';

  @override
  String get chat_meetings_duration_unlimited => 'Sem limite';

  @override
  String get chat_meetings_duration_15m => '15 minutos';

  @override
  String get chat_meetings_duration_30m => '30 minutos';

  @override
  String get chat_meetings_duration_1h => '1 hora';

  @override
  String get chat_meetings_duration_90m => '1h30';

  @override
  String get chat_meetings_field_access_label => 'Acesso';

  @override
  String get chat_meetings_access_private => 'Privada';

  @override
  String get chat_meetings_access_public => 'Pública';

  @override
  String get chat_meetings_waiting_room_title => 'Sala de espera';

  @override
  String get chat_meetings_waiting_room_desc =>
      'No modo sala de espera, você controla quem entra. Até você tocar em “Admitir”, os convidados ficam na tela de espera.';

  @override
  String get chat_meetings_backgrounds_title => 'Planos de fundo virtuais';

  @override
  String get chat_meetings_backgrounds_desc =>
      'Faça upload de planos de fundo e desfoque o seu se quiser. Escolha uma imagem da galeria ou envie os seus.';

  @override
  String get chat_meetings_create_button => 'Criar reunião';

  @override
  String get chat_meetings_snackbar_enter_title =>
      'Digite um título para a reunião';

  @override
  String get chat_meetings_snackbar_auth_required =>
      'Você precisa estar conectado para criar uma reunião';

  @override
  String chat_meetings_error_create_failed(Object error) {
    return 'Não foi possível criar a reunião: $error';
  }

  @override
  String get chat_meetings_history_title => 'Seu histórico';

  @override
  String get chat_meetings_history_empty =>
      'Seu histórico de reuniões está vazio';

  @override
  String chat_meetings_history_error(Object error) {
    return 'Não foi possível carregar o histórico de reuniões: $error';
  }

  @override
  String get chat_meetings_status_live => 'ao vivo';

  @override
  String get chat_meetings_status_finished => 'finalizada';

  @override
  String get chat_meetings_badge_private => 'privada';

  @override
  String get chat_contacts_search_hint => 'Buscar contatos…';

  @override
  String get chat_contacts_permission_denied =>
      'Permissão de contatos não concedida.';

  @override
  String chat_contacts_sync_error(Object error) {
    return 'Não foi possível sincronizar os contatos: $error';
  }

  @override
  String chat_contacts_invite_prepare_failed(Object error) {
    return 'Não foi possível preparar o convite: $error';
  }

  @override
  String get chat_contacts_matches_not_found => 'Nenhum resultado encontrado.';

  @override
  String chat_contacts_added_count(Object count) {
    return 'Contatos adicionados: $count.';
  }

  @override
  String get chat_contacts_invite_text =>
      'Instale o LighChat: https://lighchat.online\nEstou te convidando para o LighChat — aqui está o link de instalação.';

  @override
  String get chat_contacts_invite_subject => 'Convite para o LighChat';

  @override
  String chat_contacts_error_load(Object error) {
    return 'Não foi possível carregar os contatos: $error';
  }

  @override
  String chat_list_item_draft_line(Object line) {
    return 'Rascunho · $line';
  }

  @override
  String get chat_list_item_chat_created => 'Chat criado';

  @override
  String get chat_list_item_no_messages_yet => 'Sem mensagens ainda';

  @override
  String get chat_list_item_history_cleared => 'Histórico limpo';

  @override
  String get chat_list_firebase_not_configured =>
      'O Firebase ainda não está configurado.';

  @override
  String get new_chat_title => 'Novo chat';

  @override
  String get new_chat_subtitle =>
      'Escolha alguém para iniciar uma conversa ou crie um grupo.';

  @override
  String get new_chat_search_hint => 'Nome, nome de usuário ou @handle…';

  @override
  String get new_chat_create_group => 'Criar um grupo';

  @override
  String get new_chat_section_phone_contacts => 'CONTATOS DO TELEFONE';

  @override
  String get new_chat_section_contacts => 'CONTATOS';

  @override
  String get new_chat_section_all_users => 'TODOS OS USUÁRIOS';

  @override
  String get new_chat_empty_no_users => 'Ninguém para iniciar um chat ainda.';

  @override
  String get new_chat_empty_not_found => 'Nenhum resultado encontrado.';

  @override
  String new_chat_error_contacts(Object error) {
    return 'Contatos: $error';
  }

  @override
  String get new_chat_fallback_user_display_name => 'Usuário';

  @override
  String get new_group_role_badge_admin => 'ADMIN';

  @override
  String get new_group_role_badge_worker => 'MEMBRO';

  @override
  String new_group_error_auth_session(Object error) {
    return 'Não foi possível verificar o login: $error';
  }

  @override
  String get invite_subject => 'Encontre-me no LighChat';

  @override
  String get invite_text =>
      'Instale o LighChat: https://lighchat.online\\nEstou te convidando para o LighChat — aqui está o link de instalação.';

  @override
  String get new_group_title => 'Criar um grupo';

  @override
  String get new_group_search_hint => 'Buscar usuários…';

  @override
  String get new_group_pick_photo_tooltip =>
      'Toque para escolher uma foto do grupo. Toque longo para remover.';

  @override
  String get new_group_name_label => 'Nome do grupo';

  @override
  String get new_group_name_hint => 'Nome';

  @override
  String get new_group_description_label => 'Descrição';

  @override
  String get new_group_description_hint => 'Opcional';

  @override
  String new_group_members_count(Object count) {
    return 'Membros ($count)';
  }

  @override
  String get new_group_add_members_section => 'ADICIONAR MEMBROS';

  @override
  String get new_group_empty_no_users => 'Ninguém para adicionar ainda.';

  @override
  String get new_group_empty_not_found => 'Nenhum resultado encontrado.';

  @override
  String get new_group_error_name_required =>
      'Por favor, digite um nome para o grupo.';

  @override
  String get new_group_error_members_required =>
      'Adicione pelo menos um membro.';

  @override
  String get new_group_action_create => 'Criar';

  @override
  String get group_members_title => 'Membros';

  @override
  String get group_members_invite_link => 'Convidar via link';

  @override
  String get group_members_admin_badge => 'ADMIN';

  @override
  String group_members_invite_text(Object groupName, Object inviteLink) {
    return 'Entre no grupo $groupName no LighChat: $inviteLink';
  }

  @override
  String get group_members_error_min_admin =>
      'É preciso manter pelo menos um administrador no grupo.';

  @override
  String get group_members_error_cannot_remove_creator =>
      'Você não pode remover os direitos de admin do criador do grupo.';

  @override
  String get group_members_remove_admin => 'Direitos de admin removidos';

  @override
  String get group_members_make_admin => 'Usuário promovido a admin';

  @override
  String get auth_brand_tagline => 'Um mensageiro mais seguro';

  @override
  String get auth_firebase_not_ready =>
      'O Firebase não está pronto. Verifique `firebase_options.dart` e GoogleService-Info.plist.';

  @override
  String get auth_redirecting_to_chats => 'Levando você aos chats…';

  @override
  String get auth_or => 'ou';

  @override
  String get auth_create_account => 'Criar conta';

  @override
  String get auth_entry_sign_in => 'Entrar';

  @override
  String get auth_entry_sign_up => 'Criar conta';

  @override
  String get auth_qr_title => 'Entrar com QR';

  @override
  String get auth_qr_hint =>
      'Abra o LighChat em um dispositivo onde você já entrou → Configurações → Dispositivos → Conectar novo dispositivo, e então escaneie este código.';

  @override
  String auth_qr_refresh_in(int seconds) {
    return 'Atualiza em ${seconds}s';
  }

  @override
  String get auth_qr_other_method => 'Entrar de outra forma';

  @override
  String get auth_qr_approving => 'Entrando…';

  @override
  String get auth_qr_rejected => 'Solicitação rejeitada';

  @override
  String get auth_qr_retry => 'Tentar de novo';

  @override
  String get auth_qr_unknown_error => 'Não foi possível gerar o código QR.';

  @override
  String get auth_qr_use_qr_login => 'Entrar com QR';

  @override
  String get auth_privacy_policy => 'Política de privacidade';

  @override
  String get auth_error_open_privacy_policy =>
      'Não foi possível abrir a política de privacidade';

  @override
  String get voice_transcript_show => 'Mostrar texto';

  @override
  String get voice_transcript_hide => 'Ocultar texto';

  @override
  String get voice_transcript_copy => 'Copiar';

  @override
  String get voice_transcript_loading => 'Transcrevendo…';

  @override
  String get voice_transcript_failed => 'Não foi possível obter o texto.';

  @override
  String get voice_attachment_media_kind_audio => 'áudio';

  @override
  String get voice_attachment_load_failed => 'Não foi possível carregar';

  @override
  String get voice_attachment_title_voice_message => 'Mensagem de voz';

  @override
  String voice_transcript_error(Object error) {
    return 'Não foi possível transcrever: $error';
  }

  @override
  String get chat_messages_title => 'Mensagens';

  @override
  String get chat_call_decline => 'Recusar';

  @override
  String get chat_call_open => 'Abrir';

  @override
  String get chat_call_accept => 'Aceitar';

  @override
  String video_call_error_init(Object error) {
    return 'Erro de chamada de vídeo: $error';
  }

  @override
  String get video_call_ended => 'Chamada encerrada';

  @override
  String get video_call_status_missed => 'Chamada perdida';

  @override
  String get video_call_status_cancelled => 'Chamada cancelada';

  @override
  String get video_call_error_offer_not_ready =>
      'A oferta ainda não está pronta. Tente novamente.';

  @override
  String get video_call_error_invalid_call_data => 'Dados de chamada inválidos';

  @override
  String video_call_error_accept_failed(Object error) {
    return 'Não foi possível aceitar a chamada: $error';
  }

  @override
  String get video_call_incoming => 'Chamada de vídeo recebida';

  @override
  String get video_call_connecting => 'Chamada de vídeo…';

  @override
  String get video_call_pip_tooltip => 'Picture in picture';

  @override
  String get video_call_mini_window_tooltip => 'Mini janela';

  @override
  String get chat_delete_message_title_single => 'Excluir mensagem?';

  @override
  String get chat_delete_message_title_multi => 'Excluir mensagens?';

  @override
  String get chat_delete_message_body_single =>
      'Esta mensagem será ocultada para todos.';

  @override
  String chat_delete_message_body_multi(Object count) {
    return 'Mensagens a excluir: $count';
  }

  @override
  String get chat_delete_file_title => 'Excluir arquivo?';

  @override
  String get chat_delete_file_body =>
      'Apenas este arquivo será removido da mensagem.';

  @override
  String get forward_title => 'Encaminhar';

  @override
  String get forward_empty_no_messages => 'Nenhuma mensagem para encaminhar';

  @override
  String get forward_error_not_authorized => 'Não conectado';

  @override
  String get forward_empty_no_recipients =>
      'Sem contatos ou chats para encaminhar';

  @override
  String get forward_search_hint => 'Buscar contatos…';

  @override
  String get forward_empty_no_available_recipients =>
      'Sem destinatários disponíveis.\nVocê só pode encaminhar para contatos e seus chats ativos.';

  @override
  String get forward_empty_not_found => 'Nada encontrado';

  @override
  String get forward_action_pick_recipients => 'Escolher destinatários';

  @override
  String get forward_action_send => 'Enviar';

  @override
  String forward_error_generic(Object error) {
    return 'Erro: $error';
  }

  @override
  String get forward_sender_fallback => 'Participante';

  @override
  String get forward_error_profiles_load =>
      'Não foi possível carregar os perfis para abrir o chat';

  @override
  String get forward_error_send_no_permissions =>
      'Não foi possível encaminhar: você não tem acesso a um dos chats selecionados ou o chat não está mais disponível.';

  @override
  String get forward_error_send_forbidden_chat =>
      'Não foi possível encaminhar: o acesso a um dos chats foi negado.';

  @override
  String get share_picker_title => 'Compartilhar com o LighChat';

  @override
  String get share_picker_empty_payload => 'Nada para compartilhar';

  @override
  String get share_picker_summary_text_only => 'Texto';

  @override
  String share_picker_summary_files_count(int count) {
    return 'Arquivos: $count';
  }

  @override
  String share_picker_summary_files_with_text(int count) {
    return 'Arquivos: $count + texto';
  }

  @override
  String get devices_title => 'Meus dispositivos';

  @override
  String get devices_subtitle =>
      'Dispositivos onde sua chave pública de criptografia está publicada. Revogar cria uma nova época de chave para todos os chats criptografados — o dispositivo revogado não poderá ler novas mensagens.';

  @override
  String get devices_empty => 'Nenhum dispositivo ainda.';

  @override
  String get devices_connect_new_device => 'Conectar novo dispositivo';

  @override
  String get devices_approve_title => 'Permitir que este dispositivo entre?';

  @override
  String get devices_approve_body_hint =>
      'Confirme que este é o seu dispositivo que acabou de mostrar o código QR.';

  @override
  String get devices_approve_allow => 'Permitir';

  @override
  String get devices_approve_deny => 'Negar';

  @override
  String get devices_handover_progress_title =>
      'Sincronizando chats criptografados…';

  @override
  String devices_handover_progress_body(int done, int total) {
    return 'Atualizado $done de $total';
  }

  @override
  String get devices_handover_progress_starting => 'Iniciando…';

  @override
  String get devices_handover_success_title => 'Novo dispositivo vinculado';

  @override
  String devices_handover_success_body(String label) {
    return 'O dispositivo $label agora tem acesso aos seus chats criptografados.';
  }

  @override
  String devices_progress_rekeying(Object done, Object total) {
    return 'Atualizando chats: $done / $total';
  }

  @override
  String get devices_chip_current => 'Este dispositivo';

  @override
  String get devices_chip_revoked => 'Revogado';

  @override
  String devices_meta_created_activity(Object createdAt, Object lastSeenAt) {
    return 'Criado: $createdAt  •  Atividade: $lastSeenAt';
  }

  @override
  String devices_meta_revoked_at(Object revokedAt) {
    return 'Revogado: $revokedAt';
  }

  @override
  String get devices_action_rename => 'Renomear';

  @override
  String get devices_action_revoke => 'Revogar';

  @override
  String get devices_dialog_rename_title => 'Renomear dispositivo';

  @override
  String get devices_dialog_rename_hint => 'ex.: iPhone 15 — Safari';

  @override
  String devices_error_rename_failed(Object error) {
    return 'Não foi possível renomear: $error';
  }

  @override
  String get devices_dialog_revoke_title => 'Revogar dispositivo?';

  @override
  String get devices_dialog_revoke_body_current =>
      'Você está prestes a revogar ESTE dispositivo. Depois disso, você não poderá ler novas mensagens em chats criptografados de ponta a ponta a partir deste cliente.';

  @override
  String get devices_dialog_revoke_body_other =>
      'Este dispositivo não poderá ler novas mensagens em chats criptografados de ponta a ponta. As mensagens antigas continuarão disponíveis nele.';

  @override
  String devices_snackbar_revoked(Object rekeyed, Object suffix) {
    return 'Dispositivo revogado. Chats atualizados: $rekeyed$suffix';
  }

  @override
  String devices_snackbar_failed_suffix(Object count) {
    return ', erros: $count';
  }

  @override
  String devices_error_revoke_failed(Object error) {
    return 'Erro ao revogar: $error';
  }

  @override
  String get e2ee_recovery_title => 'E2EE — backup';

  @override
  String get e2ee_password_label => 'Senha';

  @override
  String get e2ee_password_confirm_label => 'Confirmar senha';

  @override
  String e2ee_password_min_length(Object count) {
    return 'Pelo menos $count caracteres';
  }

  @override
  String get e2ee_password_mismatch => 'As senhas não coincidem';

  @override
  String get e2ee_backup_create_title => 'Criar backup da chave';

  @override
  String get e2ee_backup_restore_title => 'Restaurar com senha';

  @override
  String get e2ee_backup_restore_action => 'Restaurar';

  @override
  String e2ee_backup_create_error(Object error) {
    return 'Não foi possível criar o backup: $error';
  }

  @override
  String e2ee_backup_restore_error(Object error) {
    return 'Não foi possível restaurar: $error';
  }

  @override
  String get e2ee_backup_wrong_password => 'Senha incorreta';

  @override
  String get e2ee_backup_not_found => 'Backup não encontrado';

  @override
  String e2ee_recovery_error_generic(Object error) {
    return 'Erro: $error';
  }

  @override
  String get e2ee_backup_password_card_title => 'Backup com senha';

  @override
  String get e2ee_backup_password_card_description =>
      'Crie um backup criptografado da sua chave privada. Se perder todos os dispositivos, dá para restaurar em um novo usando apenas a senha. A senha não pode ser recuperada — guarde com cuidado.';

  @override
  String get e2ee_backup_overwrite => 'Sobrescrever backup';

  @override
  String get e2ee_backup_create => 'Criar backup';

  @override
  String get e2ee_backup_restore => 'Restaurar do backup';

  @override
  String get e2ee_backup_already_have => 'Já tenho um backup';

  @override
  String get e2ee_qr_transfer_title => 'Transferir chave via QR';

  @override
  String get e2ee_qr_transfer_description =>
      'No novo dispositivo você mostra um QR; no antigo, você escaneia. Confirme um código de 6 dígitos — a chave privada é transferida com segurança.';

  @override
  String get e2ee_qr_transfer_open => 'Abrir pareamento por QR';

  @override
  String get media_viewer_action_reply => 'Responder';

  @override
  String get media_viewer_action_forward => 'Encaminhar';

  @override
  String get media_viewer_action_send => 'Enviar';

  @override
  String get media_viewer_action_save => 'Salvar';

  @override
  String get media_viewer_action_show_in_chat => 'Mostrar no chat';

  @override
  String get media_viewer_action_delete => 'Excluir';

  @override
  String get media_viewer_error_no_gallery_access =>
      'Sem permissão para salvar na galeria';

  @override
  String get media_viewer_error_share_unavailable_web =>
      'Compartilhamento não está disponível na web';

  @override
  String get media_viewer_error_file_not_found => 'Arquivo não encontrado';

  @override
  String get media_viewer_error_bad_media_url => 'URL de mídia inválida';

  @override
  String get media_viewer_error_bad_url => 'URL inválida';

  @override
  String get media_viewer_error_unsupported_media_scheme =>
      'Tipo de mídia não suportado';

  @override
  String media_viewer_error_http_status(Object status) {
    return 'Erro do servidor (HTTP $status)';
  }

  @override
  String media_viewer_error_save_failed(Object error) {
    return 'Não foi possível salvar: $error';
  }

  @override
  String media_viewer_error_send_failed(Object error) {
    return 'Não foi possível enviar: $error';
  }

  @override
  String get media_viewer_video_playback_speed => 'Velocidade de reprodução';

  @override
  String get media_viewer_video_quality => 'Qualidade';

  @override
  String get media_viewer_video_quality_auto => 'Automática';

  @override
  String get media_viewer_error_quality_switch_failed =>
      'Não foi possível alternar a qualidade';

  @override
  String get media_viewer_error_pip_open_failed =>
      'Não foi possível abrir o PiP';

  @override
  String get media_viewer_pip_not_supported =>
      'Picture-in-picture não é suportado neste dispositivo.';

  @override
  String get media_viewer_video_processing =>
      'Este vídeo está sendo processado no servidor e ficará disponível em breve.';

  @override
  String get media_viewer_video_playback_failed =>
      'Não foi possível reproduzir o vídeo.';

  @override
  String get common_none => 'Nenhum';

  @override
  String get group_member_role_admin => 'Administrador';

  @override
  String get group_member_role_worker => 'Membro';

  @override
  String get profile_no_photo_to_view => 'Sem foto de perfil para ver.';

  @override
  String get profile_chat_id_copied_toast => 'ID do chat copiado';

  @override
  String get auth_register_error_open_link => 'Não foi possível abrir o link.';

  @override
  String get new_chat_error_self_profile_not_found =>
      'Seu perfil não foi encontrado no diretório. Tente sair e entrar novamente.';

  @override
  String get disappearing_messages_title => 'Mensagens temporárias';

  @override
  String get disappearing_messages_intro =>
      'Novas mensagens são removidas automaticamente do servidor após o tempo selecionado (a partir do momento do envio). Mensagens já enviadas não são alteradas.';

  @override
  String disappearing_messages_admin_only(Object summary) {
    return 'Apenas admins do grupo podem alterar isso. Atual: $summary.';
  }

  @override
  String get disappearing_messages_snackbar_off =>
      'Mensagens temporárias desativadas.';

  @override
  String get disappearing_messages_snackbar_updated =>
      'Temporizador atualizado.';

  @override
  String get disappearing_preset_off => 'Desativado';

  @override
  String get disappearing_preset_1h => '1 h';

  @override
  String get disappearing_preset_24h => '24 h';

  @override
  String get disappearing_preset_7d => '7 dias';

  @override
  String get disappearing_preset_30d => '30 dias';

  @override
  String get disappearing_ttl_summary_off => 'Desativado';

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
    return '$count dias';
  }

  @override
  String disappearing_ttl_weeks(Object count) {
    return '$count sem';
  }

  @override
  String get conversation_profile_e2ee_on => 'Ativada';

  @override
  String get conversation_profile_e2ee_off => 'Desativada';

  @override
  String get conversation_profile_e2ee_subtitle_on =>
      'A criptografia de ponta a ponta está ativada. Toque para mais detalhes.';

  @override
  String get conversation_profile_e2ee_subtitle_off =>
      'A criptografia de ponta a ponta está desativada. Toque para ativar.';

  @override
  String get partner_profile_title_fallback_group => 'Chat em grupo';

  @override
  String get partner_profile_title_fallback_saved => 'Mensagens salvas';

  @override
  String get partner_profile_title_fallback_chat => 'Chat';

  @override
  String partner_profile_subtitle_group_member_count(Object count) {
    return '$count membros';
  }

  @override
  String get partner_profile_subtitle_saved_messages =>
      'Mensagens e anotações apenas para você';

  @override
  String get partner_profile_error_cannot_contact_user =>
      'Você não consegue alcançar este usuário com as configurações de contato atuais.';

  @override
  String partner_profile_error_open_chat(Object error) {
    return 'Não foi possível abrir o chat: $error';
  }

  @override
  String get partner_profile_call_peer_fallback => 'Contato';

  @override
  String get partner_profile_chat_not_created => 'O chat ainda não foi criado';

  @override
  String get partner_profile_notifications_muted => 'Notificações silenciadas';

  @override
  String get partner_profile_notifications_unmuted => 'Notificações reativadas';

  @override
  String get partner_profile_notifications_change_failed =>
      'Não foi possível atualizar as notificações';

  @override
  String get partner_profile_removed_from_contacts => 'Removido dos contatos';

  @override
  String get partner_profile_remove_contact_failed =>
      'Não foi possível remover dos contatos';

  @override
  String get partner_profile_contact_sent => 'Contato enviado';

  @override
  String get partner_profile_share_failed_copied =>
      'Falha ao compartilhar. O texto do contato foi copiado.';

  @override
  String get partner_profile_share_contact_header => 'Contato no LighChat';

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
    return 'Contato do LighChat: $name';
  }

  @override
  String get partner_profile_tooltip_back => 'Voltar';

  @override
  String get partner_profile_tooltip_close => 'Fechar';

  @override
  String get partner_profile_edit_contact_short => 'Editar';

  @override
  String get partner_profile_tooltip_copy_chat_id => 'Copiar ID do chat';

  @override
  String get partner_profile_action_chats => 'Chats';

  @override
  String get partner_profile_action_voice_call => 'Ligar';

  @override
  String get partner_profile_action_video => 'Vídeo';

  @override
  String get partner_profile_action_share => 'Compartilhar';

  @override
  String get partner_profile_action_notifications => 'Alertas';

  @override
  String get partner_profile_menu_members => 'Membros';

  @override
  String get partner_profile_menu_edit_group => 'Editar grupo';

  @override
  String get partner_profile_menu_media_links_files =>
      'Mídia, links e arquivos';

  @override
  String get partner_profile_menu_starred => 'Favoritas';

  @override
  String get partner_profile_menu_threads => 'Tópicos';

  @override
  String get partner_profile_menu_games => 'Jogos';

  @override
  String get partner_profile_menu_block => 'Bloquear';

  @override
  String get partner_profile_menu_unblock => 'Desbloquear';

  @override
  String get partner_profile_menu_notifications => 'Notificações';

  @override
  String get partner_profile_menu_chat_theme => 'Tema do chat';

  @override
  String get partner_profile_menu_advanced_privacy =>
      'Privacidade avançada do chat';

  @override
  String get partner_profile_privacy_trailing_default => 'Padrão';

  @override
  String get partner_profile_menu_encryption => 'Criptografia';

  @override
  String get partner_profile_no_common_groups => 'SEM GRUPOS EM COMUM';

  @override
  String partner_profile_create_group_with(Object name) {
    return 'Criar um grupo com $name';
  }

  @override
  String get partner_profile_leave_group => 'Sair do grupo';

  @override
  String get partner_profile_contacts_and_data => 'Informações de contato';

  @override
  String get partner_profile_field_system_role => 'Função no sistema';

  @override
  String get partner_profile_field_email => 'Email';

  @override
  String get partner_profile_field_phone => 'Telefone';

  @override
  String get partner_profile_field_birthday => 'Aniversário';

  @override
  String get partner_profile_field_bio => 'Sobre';

  @override
  String get partner_profile_add_to_contacts => 'Adicionar aos contatos';

  @override
  String get partner_profile_remove_from_contacts => 'Remover dos contatos';

  @override
  String get thread_search_hint => 'Buscar no tópico…';

  @override
  String get thread_search_tooltip_clear => 'Limpar';

  @override
  String get thread_search_tooltip_search => 'Buscar';

  @override
  String thread_reply_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count respostas',
      one: '$count resposta',
      zero: '$count respostas',
    );
    return '$_temp0';
  }

  @override
  String get thread_message_not_found => 'Mensagem não encontrada';

  @override
  String get thread_screen_title_fallback => 'Tópico';

  @override
  String thread_load_replies_error(Object error) {
    return 'Erro do tópico: $error';
  }

  @override
  String get chat_message_empty_placeholder => 'Mensagem';

  @override
  String get chat_sender_you => 'Você';

  @override
  String get chat_clipboard_nothing_to_paste =>
      'Nada para colar da área de transferência';

  @override
  String chat_clipboard_paste_failed(Object error) {
    return 'Não foi possível colar da área de transferência: $error';
  }

  @override
  String chat_send_failed(Object error) {
    return 'Não foi possível enviar: $error';
  }

  @override
  String chat_send_video_circle_failed(Object error) {
    return 'Não foi possível enviar a nota em vídeo: $error';
  }

  @override
  String get chat_service_unavailable => 'Serviço indisponível';

  @override
  String get chat_repository_unavailable => 'Serviço de chat indisponível';

  @override
  String get chat_still_loading => 'O chat ainda está carregando';

  @override
  String get chat_no_participants => 'Sem participantes no chat';

  @override
  String get chat_location_ios_geolocator_missing =>
      'A localização não está vinculada nesta build do iOS. Execute pod install em mobile/app/ios e recompile.';

  @override
  String get chat_location_services_disabled =>
      'Ative os serviços de localização';

  @override
  String get chat_location_permission_denied =>
      'Sem permissão para usar a localização';

  @override
  String chat_location_send_failed(Object error) {
    return 'Não foi possível enviar a localização: $error';
  }

  @override
  String get chat_poll_send_timeout => 'Enquete não enviada: tempo esgotado';

  @override
  String chat_poll_send_firebase(Object details) {
    return 'Enquete não enviada (Firestore): $details';
  }

  @override
  String chat_poll_send_known_error(Object details) {
    return 'Enquete não enviada: $details';
  }

  @override
  String chat_poll_send_failed(Object error) {
    return 'Não foi possível enviar a enquete: $error';
  }

  @override
  String chat_delete_action_failed(Object error) {
    return 'Não foi possível excluir: $error';
  }

  @override
  String get chat_media_transcode_retry_started =>
      'Nova tentativa de transcodificação iniciada';

  @override
  String chat_media_transcode_retry_failed(Object error) {
    return 'Não foi possível iniciar a nova tentativa de transcodificação: $error';
  }

  @override
  String chat_parent_load_error(Object error) {
    return 'Erro: $error';
  }

  @override
  String get chat_message_not_found_in_loaded_history =>
      'A mensagem não foi encontrada no histórico carregado';

  @override
  String get chat_finish_editing_first => 'Termine a edição primeiro';

  @override
  String chat_send_voice_failed(Object error) {
    return 'Não foi possível enviar a mensagem de voz: $error';
  }

  @override
  String get chat_starred_removed => 'Removida de Favoritas';

  @override
  String get chat_starred_added => 'Adicionada a Favoritas';

  @override
  String chat_starred_toggle_failed(Object error) {
    return 'Não foi possível atualizar Favoritas: $error';
  }

  @override
  String chat_reaction_toggle_failed(Object error) {
    return 'Não foi possível adicionar a reação: $error';
  }

  @override
  String chat_emoji_burst_sync_failed(Object error) {
    return 'Não foi possível sincronizar o efeito de emoji: $error';
  }

  @override
  String get chat_pin_already_pinned => 'A mensagem já está fixada';

  @override
  String chat_pin_limit_reached(int count) {
    return 'Limite de mensagens fixadas ($count)';
  }

  @override
  String chat_pin_failed(Object error) {
    return 'Não foi possível fixar: $error';
  }

  @override
  String chat_unpin_failed(Object error) {
    return 'Não foi possível desafixar: $error';
  }

  @override
  String get chat_text_copied => 'Texto copiado';

  @override
  String get chat_edit_attachments_not_allowed =>
      'Anexos não estão disponíveis durante a edição';

  @override
  String get chat_edit_text_empty => 'O texto não pode ficar vazio';

  @override
  String chat_e2ee_unavailable(Object code) {
    return 'Criptografia indisponível: $code';
  }

  @override
  String chat_save_failed(Object error) {
    return 'Não foi possível salvar: $error';
  }

  @override
  String chat_load_messages_error(Object error) {
    return 'Não foi possível carregar as mensagens: $error';
  }

  @override
  String chat_conversation_error(Object error) {
    return 'Erro da conversa: $error';
  }

  @override
  String chat_auth_error(Object error) {
    return 'Erro de autenticação: $error';
  }

  @override
  String get chat_poll_label => 'Enquete';

  @override
  String get chat_location_label => 'Localização';

  @override
  String get chat_attachment_label => 'Anexo';

  @override
  String chat_media_pick_failed(Object error) {
    return 'Não foi possível escolher mídia: $error';
  }

  @override
  String chat_file_pick_failed(Object error) {
    return 'Não foi possível escolher arquivo: $error';
  }

  @override
  String get chat_call_ongoing_video => 'Chamada de vídeo em andamento';

  @override
  String get chat_call_ongoing_audio => 'Chamada de áudio em andamento';

  @override
  String get chat_call_incoming_video => 'Chamada de vídeo recebida';

  @override
  String get chat_call_incoming_audio => 'Chamada de áudio recebida';

  @override
  String get message_menu_action_reply => 'Responder';

  @override
  String get message_menu_action_thread => 'Tópico';

  @override
  String get message_menu_action_copy => 'Copiar';

  @override
  String get message_menu_action_edit => 'Editar';

  @override
  String get message_menu_action_pin => 'Fixar';

  @override
  String get message_menu_action_star_add => 'Adicionar a Favoritas';

  @override
  String get message_menu_action_star_remove => 'Remover de Favoritas';

  @override
  String get message_menu_action_forward => 'Encaminhar';

  @override
  String get message_menu_action_select => 'Selecionar';

  @override
  String get message_menu_action_delete => 'Excluir';

  @override
  String get message_menu_initiator_deleted => 'Mensagem excluída';

  @override
  String get message_menu_header_sent => 'ENVIADA:';

  @override
  String get message_menu_header_read => 'LIDA:';

  @override
  String get message_menu_header_expire_at => 'DESAPARECE:';

  @override
  String get chat_header_search_hint => 'Buscar mensagens…';

  @override
  String get chat_header_tooltip_threads => 'Tópicos';

  @override
  String get chat_header_tooltip_search => 'Buscar';

  @override
  String get chat_header_tooltip_video_call => 'Chamada de vídeo';

  @override
  String get chat_header_tooltip_audio_call => 'Chamada de áudio';

  @override
  String get conversation_games_title => 'Jogos';

  @override
  String get conversation_games_durak => 'Durak';

  @override
  String get conversation_games_durak_subtitle => 'Criar lobby';

  @override
  String get conversation_game_lobby_title => 'Lobby';

  @override
  String get conversation_game_lobby_not_found => 'Jogo não encontrado';

  @override
  String conversation_game_lobby_error(Object error) {
    return 'Erro: $error';
  }

  @override
  String conversation_game_lobby_create_failed(Object error) {
    return 'Não foi possível criar o jogo: $error';
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
    return 'Jogadores: $count/$max';
  }

  @override
  String get conversation_game_lobby_join => 'Entrar';

  @override
  String get conversation_game_lobby_start => 'Iniciar';

  @override
  String conversation_game_lobby_join_failed(Object error) {
    return 'Não foi possível entrar: $error';
  }

  @override
  String conversation_game_lobby_start_failed(Object error) {
    return 'Não foi possível iniciar o jogo: $error';
  }

  @override
  String get conversation_game_send_test_move => 'Jogada de teste';

  @override
  String conversation_game_move_failed(Object error) {
    return 'Jogada rejeitada: $error';
  }

  @override
  String get conversation_durak_table_title => 'Mesa';

  @override
  String get conversation_durak_hand_title => 'Mão';

  @override
  String get conversation_durak_role_attacker => 'Atacando';

  @override
  String get conversation_durak_role_defender => 'Defendendo';

  @override
  String get conversation_durak_role_thrower => 'Jogando extra';

  @override
  String get conversation_durak_action_attack => 'Atacar';

  @override
  String get conversation_durak_action_defend => 'Defender';

  @override
  String get conversation_durak_action_take => 'Pegar';

  @override
  String get conversation_durak_action_beat => 'Bater';

  @override
  String get conversation_durak_action_transfer => 'Passar';

  @override
  String get conversation_durak_action_pass => 'Passar';

  @override
  String get conversation_durak_badge_taking => 'Vou pegar';

  @override
  String get conversation_durak_game_finished_title => 'Jogo finalizado';

  @override
  String get conversation_durak_game_finished_no_loser =>
      'Sem perdedor desta vez.';

  @override
  String conversation_durak_game_finished_loser(Object uid) {
    return 'Perdedor: $uid';
  }

  @override
  String conversation_durak_game_finished_winners(Object uids) {
    return 'Vencedores: $uids';
  }

  @override
  String get conversation_durak_winner => 'Vencedor!';

  @override
  String get conversation_durak_play_again => 'Jogar de novo';

  @override
  String get conversation_durak_back_to_chat => 'Voltar para o chat';

  @override
  String get conversation_game_lobby_waiting_opponent => 'Aguardando oponente…';

  @override
  String get conversation_durak_drop_zone => 'Solte a carta aqui para jogar';

  @override
  String get durak_settings_mode => 'Modo';

  @override
  String get durak_mode_podkidnoy => 'Podkidnoy';

  @override
  String get durak_mode_perevodnoy => 'Perevodnoy';

  @override
  String get durak_settings_max_players => 'Jogadores';

  @override
  String get durak_settings_deck => 'Baralho';

  @override
  String get durak_deck_36 => '36 cartas';

  @override
  String get durak_deck_52 => '52 cartas';

  @override
  String get durak_settings_with_jokers => 'Curingas';

  @override
  String get durak_settings_turn_timer => 'Tempo do turno';

  @override
  String get durak_turn_timer_off => 'Desativado';

  @override
  String get durak_settings_throw_in_policy => 'Quem pode jogar extras';

  @override
  String get durak_throw_in_policy_all =>
      'Todos os jogadores (exceto o defensor)';

  @override
  String get durak_throw_in_policy_neighbors =>
      'Apenas os vizinhos do defensor';

  @override
  String get durak_settings_shuler => 'Modo Shuler';

  @override
  String get durak_settings_shuler_subtitle =>
      'Permite jogadas ilegais a menos que alguém marque falta.';

  @override
  String get conversation_durak_action_foul => 'Falta!';

  @override
  String get conversation_durak_action_resolve => 'Confirmar Bater';

  @override
  String get conversation_durak_foul_toast => 'Falta! Trapaceiro penalizado.';

  @override
  String get durak_phase_prefix => 'Fase';

  @override
  String get durak_phase_attack => 'Ataque';

  @override
  String get durak_phase_defense => 'Defesa';

  @override
  String get durak_phase_throw_in => 'Jogada extra';

  @override
  String get durak_phase_resolution => 'Resolução';

  @override
  String get durak_phase_finished => 'Finalizado';

  @override
  String get durak_phase_pending_foul => 'Falta pendente após Bater';

  @override
  String get durak_phase_pending_foul_hint_attacker =>
      'Aguarde a falta. Se ninguém marcar, confirme Bater.';

  @override
  String get durak_phase_pending_foul_hint_other =>
      'Aguarde a falta. Marque Falta! se notou trapaça.';

  @override
  String get durak_phase_hint_can_throw_in => 'Você pode jogar extras';

  @override
  String get durak_phase_hint_wait => 'Aguarde sua vez';

  @override
  String durak_now_throwing_in(Object name) {
    return 'Jogando extra agora: $name';
  }

  @override
  String chat_selection_selected_count(int count) {
    return '$count selected';
  }

  @override
  String get chat_selection_tooltip_forward => 'Encaminhar';

  @override
  String get chat_selection_tooltip_delete => 'Excluir';

  @override
  String get chat_composer_hint_message => 'Digite uma mensagem…';

  @override
  String get chat_composer_tooltip_stickers => 'Figurinhas';

  @override
  String get chat_composer_tooltip_attachments => 'Anexos';

  @override
  String get chat_list_unread_separator => 'Mensagens não lidas';

  @override
  String get chat_e2ee_decrypt_failed_open_devices =>
      'Não foi possível descriptografar. Abra Configurações → Dispositivos';

  @override
  String get chat_e2ee_encrypted_message_placeholder =>
      'Mensagem criptografada';

  @override
  String chat_forwarded_from(Object name) {
    return 'Encaminhada de $name';
  }

  @override
  String get chat_outbox_retry => 'Tentar de novo';

  @override
  String get chat_outbox_remove => 'Remover';

  @override
  String get chat_outbox_cancel => 'Cancelar';

  @override
  String get chat_message_edited_badge_short => 'EDITADA';

  @override
  String get register_error_enter_name => 'Digite seu nome.';

  @override
  String get register_error_enter_username => 'Digite um nome de usuário.';

  @override
  String get register_error_enter_phone => 'Digite um número de telefone.';

  @override
  String get register_error_invalid_phone =>
      'Digite um número de telefone válido.';

  @override
  String get register_error_enter_email => 'Digite um email.';

  @override
  String get register_error_enter_password => 'Digite uma senha.';

  @override
  String get register_error_repeat_password => 'Repita a senha.';

  @override
  String get register_error_dob_format =>
      'Digite a data de nascimento no formato dd.mm.aaaa';

  @override
  String get register_error_accept_privacy_policy =>
      'Por favor, confirme que você aceita a política de privacidade';

  @override
  String get register_privacy_required =>
      'É obrigatório aceitar a política de privacidade';

  @override
  String get register_label_name => 'Nome';

  @override
  String get register_hint_name => 'Digite seu nome';

  @override
  String get register_label_username => 'Nome de usuário';

  @override
  String get register_hint_username => 'Digite um nome de usuário';

  @override
  String get register_label_phone => 'Telefone';

  @override
  String get register_hint_choose_country => 'Escolha um país';

  @override
  String get register_label_email => 'Email';

  @override
  String get register_hint_email => 'Digite seu email';

  @override
  String get register_label_password => 'Senha';

  @override
  String get register_hint_password => 'Digite sua senha';

  @override
  String get register_label_confirm_password => 'Confirmar senha';

  @override
  String get register_hint_confirm_password => 'Repita sua senha';

  @override
  String get register_label_dob => 'Data de nascimento';

  @override
  String get register_hint_dob => 'dd.mm.aaaa';

  @override
  String get register_label_bio => 'Sobre';

  @override
  String get register_hint_bio => 'Conte um pouco sobre você…';

  @override
  String get register_privacy_prefix => 'Eu aceito o ';

  @override
  String get register_privacy_link_text =>
      'Consentimento para o tratamento de dados pessoais';

  @override
  String get register_privacy_and => ' e ';

  @override
  String get register_terms_link_text => 'Acordo de privacidade do usuário';

  @override
  String get register_button_create_account => 'Criar conta';

  @override
  String get register_country_search_hint => 'Buscar por país ou código';

  @override
  String get register_date_picker_help => 'Data de nascimento';

  @override
  String get register_date_picker_cancel => 'Cancelar';

  @override
  String get register_date_picker_confirm => 'Selecionar';

  @override
  String get register_pick_avatar_title => 'Escolher avatar';

  @override
  String get edit_group_title => 'Editar grupo';

  @override
  String get edit_group_save => 'Salvar';

  @override
  String get edit_group_cancel => 'Cancelar';

  @override
  String get edit_group_name_label => 'Nome do grupo';

  @override
  String get edit_group_name_hint => 'Nome';

  @override
  String get edit_group_description_label => 'Descrição';

  @override
  String get edit_group_description_hint => 'Opcional';

  @override
  String get edit_group_pick_photo_tooltip =>
      'Toque para escolher uma foto do grupo. Toque longo para remover.';

  @override
  String get edit_group_error_name_required =>
      'Por favor, digite um nome para o grupo.';

  @override
  String get edit_group_error_save_failed => 'Falha ao salvar o grupo.';

  @override
  String get edit_group_error_not_found => 'Grupo não encontrado.';

  @override
  String get edit_group_error_permission_denied =>
      'Você não tem permissão para editar este grupo.';

  @override
  String get edit_group_success => 'Grupo atualizado.';

  @override
  String get edit_group_privacy_section => 'PRIVACIDADE';

  @override
  String get edit_group_privacy_forwarding => 'Encaminhamento de mensagens';

  @override
  String get edit_group_privacy_forwarding_desc =>
      'Permitir que membros encaminhem mensagens deste grupo.';

  @override
  String get edit_group_privacy_screenshots => 'Capturas de tela';

  @override
  String get edit_group_privacy_screenshots_desc =>
      'Permitir capturas de tela neste grupo (depende da plataforma).';

  @override
  String get edit_group_privacy_copy => 'Cópia de texto';

  @override
  String get edit_group_privacy_copy_desc =>
      'Permitir copiar o texto das mensagens.';

  @override
  String get edit_group_privacy_save_media => 'Salvar mídia';

  @override
  String get edit_group_privacy_save_media_desc =>
      'Permitir salvar fotos e vídeos no dispositivo.';

  @override
  String get edit_group_privacy_share_media => 'Compartilhar mídia';

  @override
  String get edit_group_privacy_share_media_desc =>
      'Permitir compartilhar arquivos de mídia fora do app.';

  @override
  String get schedule_message_sheet_title => 'Agendar mensagem';

  @override
  String get schedule_message_long_press_hint => 'Agendar envio';

  @override
  String schedule_message_preset_today_at(String time) {
    return 'Hoje às $time';
  }

  @override
  String schedule_message_preset_tomorrow_at(String time) {
    return 'Amanhã às $time';
  }

  @override
  String schedule_message_will_send_at(String datetime) {
    return 'Será enviada: $datetime';
  }

  @override
  String get schedule_message_must_be_in_future =>
      'O horário precisa ser no futuro (pelo menos um minuto a partir de agora).';

  @override
  String get schedule_message_e2ee_warning =>
      'Este é um chat E2EE. A mensagem agendada será armazenada no servidor em texto plano e publicada sem criptografia.';

  @override
  String get schedule_message_cancel => 'Cancelar';

  @override
  String get schedule_message_confirm => 'Agendar';

  @override
  String get schedule_message_save => 'Salvar';

  @override
  String get schedule_message_text_required => 'Digite uma mensagem primeiro';

  @override
  String get schedule_message_attachments_unsupported_mobile =>
      'Agendar com anexos é suportado apenas na web no momento';

  @override
  String schedule_message_scheduled_toast(String datetime) {
    return 'Agendada: $datetime';
  }

  @override
  String schedule_message_failed_toast(String error) {
    return 'Falha ao agendar: $error';
  }

  @override
  String get scheduled_messages_screen_title => 'Mensagens agendadas';

  @override
  String get scheduled_messages_empty_title => 'Nenhuma mensagem agendada';

  @override
  String get scheduled_messages_empty_hint =>
      'Mantenha o botão Enviar pressionado para agendar uma mensagem.';

  @override
  String scheduled_messages_load_failed(String error) {
    return 'Falha ao carregar: $error';
  }

  @override
  String get scheduled_messages_e2ee_notice =>
      'Em um chat E2EE, as mensagens agendadas são armazenadas e publicadas em texto plano.';

  @override
  String get scheduled_messages_cancel_dialog_title =>
      'Cancelar envio agendado?';

  @override
  String get scheduled_messages_cancel_dialog_body =>
      'A mensagem agendada será excluída.';

  @override
  String get scheduled_messages_cancel_dialog_keep => 'Manter';

  @override
  String get scheduled_messages_cancel_dialog_confirm => 'Cancelar';

  @override
  String get scheduled_messages_canceled_toast => 'Cancelada';

  @override
  String scheduled_messages_time_changed_toast(String datetime) {
    return 'Horário alterado: $datetime';
  }

  @override
  String scheduled_messages_action_failed_toast(String error) {
    return 'Erro: $error';
  }

  @override
  String get scheduled_messages_tile_edit_tooltip => 'Alterar horário';

  @override
  String get scheduled_messages_tile_cancel_tooltip => 'Cancelar';

  @override
  String scheduled_messages_preview_poll(String question) {
    return 'Enquete: $question';
  }

  @override
  String get scheduled_messages_preview_location => 'Localização';

  @override
  String get scheduled_messages_preview_attachment => 'Anexo';

  @override
  String scheduled_messages_preview_attachment_count(int count) {
    return 'Anexo (×$count)';
  }

  @override
  String get scheduled_messages_preview_message => 'Mensagem';

  @override
  String get chat_header_tooltip_scheduled => 'Mensagens agendadas';

  @override
  String get schedule_date_label => 'Data';

  @override
  String get schedule_time_label => 'Horário';

  @override
  String get common_done => 'Pronto';

  @override
  String get common_send => 'Enviar';

  @override
  String get common_open => 'Abrir';

  @override
  String get common_add => 'Adicionar';

  @override
  String get common_search => 'Buscar';

  @override
  String get common_edit => 'Editar';

  @override
  String get common_next => 'Próximo';

  @override
  String get common_ok => 'OK';

  @override
  String get common_confirm => 'Confirmar';

  @override
  String get common_ready => 'Pronto';

  @override
  String get common_error => 'Erro';

  @override
  String get common_yes => 'Sim';

  @override
  String get common_no => 'Não';

  @override
  String get common_back => 'Voltar';

  @override
  String get common_continue => 'Continuar';

  @override
  String get common_loading => 'Carregando…';

  @override
  String get common_copy => 'Copiar';

  @override
  String get common_share => 'Compartilhar';

  @override
  String get common_settings => 'Configurações';

  @override
  String get common_today => 'Hoje';

  @override
  String get common_yesterday => 'Ontem';

  @override
  String get e2ee_qr_title => 'Pareamento de chaves por QR';

  @override
  String get e2ee_qr_uid_error => 'Falha ao obter o uid do usuário.';

  @override
  String get e2ee_qr_session_ended_error =>
      'A sessão terminou antes da resposta do segundo dispositivo.';

  @override
  String get e2ee_qr_no_data_error => 'Sem dados para aplicar a chave.';

  @override
  String get e2ee_qr_key_transferred_toast =>
      'Chave transferida. Reabra os chats para atualizar as sessões.';

  @override
  String get e2ee_qr_wrong_account_error =>
      'O QR foi gerado para uma conta diferente.';

  @override
  String get e2ee_qr_explainer_title => 'O que é isso';

  @override
  String get e2ee_qr_explainer_text =>
      'Transfira uma chave privada de um dos seus dispositivos para outro via ECDH + QR. Os dois lados veem um código de 6 dígitos para verificação manual.';

  @override
  String get e2ee_qr_show_qr_label => 'Estou no novo dispositivo — mostrar QR';

  @override
  String get e2ee_qr_scan_qr_label => 'Já tenho uma chave — escanear QR';

  @override
  String get e2ee_qr_scan_hint =>
      'Escaneie o QR no dispositivo antigo que já tem a chave.';

  @override
  String get e2ee_qr_verify_code_label =>
      'Confirme o código de 6 dígitos com o dispositivo antigo:';

  @override
  String e2ee_qr_transfer_from_device_label(String label) {
    return 'Transferir do dispositivo: $label';
  }

  @override
  String get e2ee_qr_code_match_apply_label => 'O código confere — aplicar';

  @override
  String get e2ee_qr_key_success_label =>
      'Chave transferida com sucesso para este dispositivo. Reabra os chats.';

  @override
  String get e2ee_qr_unknown_error => 'Erro desconhecido';

  @override
  String get e2ee_qr_back_to_pick_label => 'Voltar à seleção';

  @override
  String get e2ee_qr_donor_scan_hint =>
      'Aponte a câmera para o QR mostrado no novo dispositivo.';

  @override
  String get e2ee_qr_donor_verify_code_label =>
      'Confirme o código com o novo dispositivo:';

  @override
  String get e2ee_qr_donor_verify_hint =>
      'Se o código conferir — confirme no novo dispositivo. Se não, pressione Cancelar imediatamente.';

  @override
  String get e2ee_encrypt_title => 'Criptografia';

  @override
  String get e2ee_encrypt_enable_dialog_title => 'Ativar criptografia?';

  @override
  String get e2ee_encrypt_enable_dialog_body =>
      'Novas mensagens só ficarão disponíveis nos seus dispositivos e nos do seu contato. As mensagens antigas continuam como estão.';

  @override
  String get e2ee_encrypt_enable_label => 'Ativar';

  @override
  String get e2ee_encrypt_disable_dialog_title => 'Desativar criptografia?';

  @override
  String get e2ee_encrypt_disable_dialog_body =>
      'Novas mensagens serão enviadas sem criptografia de ponta a ponta. As mensagens criptografadas já enviadas permanecem na conversa.';

  @override
  String get e2ee_encrypt_disable_label => 'Desativar';

  @override
  String get e2ee_encrypt_status_on =>
      'A criptografia de ponta a ponta está ativada para este chat.';

  @override
  String get e2ee_encrypt_status_off =>
      'A criptografia de ponta a ponta está desativada.';

  @override
  String get e2ee_encrypt_description =>
      'Quando a criptografia está ativada, o conteúdo das novas mensagens só fica disponível para os participantes do chat nos seus dispositivos. Desativar afeta apenas as novas mensagens.';

  @override
  String get e2ee_encrypt_switch_title => 'Ativar criptografia';

  @override
  String e2ee_encrypt_switch_on(int epoch) {
    return 'Ativada (época da chave: $epoch)';
  }

  @override
  String get e2ee_encrypt_switch_off => 'Desativada';

  @override
  String get e2ee_encrypt_already_on_toast =>
      'A criptografia já está ativada ou a criação de chave falhou. Verifique a rede e as chaves do seu contato.';

  @override
  String get e2ee_encrypt_no_device_toast =>
      'Não foi possível ativar: o contato não tem dispositivo ativo com chave.';

  @override
  String e2ee_encrypt_enable_failed_toast(String error) {
    return 'Falha ao ativar a criptografia: $error';
  }

  @override
  String e2ee_encrypt_disable_failed_toast(String error) {
    return 'Falha ao desativar: $error';
  }

  @override
  String get e2ee_encrypt_data_types_title => 'Tipos de dado';

  @override
  String get e2ee_encrypt_data_types_description =>
      'Esta configuração não muda o protocolo. Ela controla quais tipos de dado são enviados criptografados.';

  @override
  String get e2ee_encrypt_override_title =>
      'Configurações de criptografia para este chat';

  @override
  String get e2ee_encrypt_override_on =>
      'As configurações específicas do chat estão em uso.';

  @override
  String get e2ee_encrypt_override_off =>
      'As configurações globais são herdadas.';

  @override
  String get e2ee_encrypt_text_title => 'Texto da mensagem';

  @override
  String get e2ee_encrypt_media_title => 'Anexos (mídia/arquivos)';

  @override
  String get e2ee_encrypt_override_hint =>
      'Para alterar para este chat — ative a sobrescrita.';

  @override
  String get sticker_default_pack_name => 'Meu pacote';

  @override
  String get sticker_new_pack_dialog_title => 'Novo pacote de figurinhas';

  @override
  String get sticker_pack_name_hint => 'Nome';

  @override
  String get sticker_save_to_pack => 'Salvar no pacote de figurinhas';

  @override
  String get sticker_no_packs_hint => 'Sem pacotes. Crie um na aba Figurinhas.';

  @override
  String get sticker_new_pack_option => 'Novo pacote…';

  @override
  String get sticker_pick_image_or_gif => 'Escolha uma imagem ou GIF';

  @override
  String sticker_send_failed(String error) {
    return 'Falha ao enviar: $error';
  }

  @override
  String get sticker_saved_to_pack => 'Salvo no pacote de figurinhas';

  @override
  String get sticker_save_gif_failed =>
      'Não foi possível baixar ou salvar o GIF';

  @override
  String get sticker_delete_pack_title => 'Excluir pacote?';

  @override
  String sticker_delete_pack_body(String name) {
    return '\"$name\" e todas as figurinhas dentro serão excluídas.';
  }

  @override
  String get sticker_pack_deleted => 'Pacote excluído';

  @override
  String get sticker_pack_delete_failed => 'Falha ao excluir o pacote';

  @override
  String get sticker_tab_emoji => 'EMOJI';

  @override
  String get sticker_tab_stickers => 'FIGURINHAS';

  @override
  String get sticker_tab_gif => 'GIF';

  @override
  String get sticker_scope_my => 'Meus';

  @override
  String get sticker_scope_public => 'Públicos';

  @override
  String get sticker_new_pack_tooltip => 'Novo pacote';

  @override
  String get sticker_pack_created => 'Pacote de figurinhas criado';

  @override
  String get sticker_no_packs_create => 'Sem pacotes de figurinhas. Crie um.';

  @override
  String get sticker_public_packs_empty => 'Nenhum pacote público configurado';

  @override
  String get sticker_section_recent => 'RECENTES';

  @override
  String get sticker_pack_empty_hint =>
      'Pacote vazio. Adicione do dispositivo (aba GIF — \"Para meu pacote\").';

  @override
  String get sticker_delete_sticker_title => 'Excluir figurinha?';

  @override
  String get sticker_deleted => 'Excluída';

  @override
  String get sticker_gallery => 'Galeria';

  @override
  String get sticker_gallery_subtitle =>
      'Fotos, PNG, GIF do dispositivo — direto no chat';

  @override
  String get gif_search_hint => 'Buscar GIF…';

  @override
  String gif_translated_hint(String query) {
    return 'Buscado: $query';
  }

  @override
  String get gif_search_unavailable =>
      'A busca de GIFs está temporariamente indisponível.';

  @override
  String get gif_filter_all => 'Todos';

  @override
  String get sticker_section_animated => 'ANIMADAS';

  @override
  String get sticker_emoji_unavailable =>
      'Conversão emoji-para-texto não está disponível para esta janela.';

  @override
  String get sticker_create_pack_hint => 'Crie um pacote com o botão +';

  @override
  String get sticker_public_packs_unavailable =>
      'Pacotes públicos ainda não estão disponíveis';

  @override
  String get composer_link_title => 'Link';

  @override
  String get composer_link_apply => 'Aplicar';

  @override
  String get composer_attach_title => 'Anexar';

  @override
  String get composer_attach_photo_video => 'Foto/Vídeo';

  @override
  String get composer_attach_files => 'Arquivos';

  @override
  String get composer_attach_video_circle => 'Nota em vídeo';

  @override
  String get composer_attach_location => 'Localização';

  @override
  String get composer_attach_poll => 'Enquete';

  @override
  String get composer_attach_stickers => 'Figurinhas';

  @override
  String get composer_attach_clipboard => 'Área de transferência';

  @override
  String get composer_attach_text => 'Texto';

  @override
  String get meeting_create_poll => 'Criar enquete';

  @override
  String get meeting_min_two_options =>
      'São necessárias pelo menos 2 opções de resposta';

  @override
  String meeting_error_with_details(String details) {
    return 'Erro: $details';
  }

  @override
  String meeting_polls_load_error(String details) {
    return 'Falha ao carregar enquetes: $details';
  }

  @override
  String get meeting_no_polls_yet => 'Sem enquetes ainda';

  @override
  String get meeting_question_label => 'Pergunta';

  @override
  String get meeting_options_label => 'Opções';

  @override
  String meeting_option_hint(int index) {
    return 'Opção $index';
  }

  @override
  String get meeting_add_option => 'Adicionar opção';

  @override
  String get meeting_anonymous => 'Anônima';

  @override
  String get meeting_anonymous_subtitle =>
      'Quem pode ver as escolhas dos outros';

  @override
  String get meeting_save_as_draft => 'Salvar como rascunho';

  @override
  String get meeting_publish => 'Publicar';

  @override
  String get meeting_action_start => 'Iniciar';

  @override
  String get meeting_action_change_vote => 'Alterar voto';

  @override
  String get meeting_action_restart => 'Reiniciar';

  @override
  String get meeting_action_stop => 'Encerrar';

  @override
  String meeting_vote_failed(String details) {
    return 'Voto não contabilizado: $details';
  }

  @override
  String get meeting_status_ended => 'Encerrada';

  @override
  String get meeting_status_draft => 'Rascunho';

  @override
  String get meeting_status_active => 'Ativa';

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
  String get meeting_who_voted => 'Quem votou';

  @override
  String meeting_participants_tab(int count) {
    return 'Membros ($count)';
  }

  @override
  String meeting_polls_tab_active(int count) {
    return 'Enquetes ($count)';
  }

  @override
  String get meeting_polls_tab => 'Enquetes';

  @override
  String meeting_chat_tab_unread(int count) {
    return 'Chat ($count)';
  }

  @override
  String get meeting_chat_tab => 'Chat';

  @override
  String meeting_requests_tab(int count) {
    return 'Solicitações ($count)';
  }

  @override
  String meeting_you_suffix(String name) {
    return '$name (Você)';
  }

  @override
  String get meeting_host_label => 'Anfitrião';

  @override
  String get meeting_force_mute_mic => 'Silenciar microfone';

  @override
  String get meeting_force_mute_camera => 'Desligar câmera';

  @override
  String get meeting_kick_from_room => 'Remover da sala';

  @override
  String meeting_chat_load_error(Object error) {
    return 'Não foi possível carregar o chat: $error';
  }

  @override
  String get meeting_no_requests => 'Sem novas solicitações';

  @override
  String get meeting_no_messages_yet => 'Sem mensagens ainda';

  @override
  String meeting_file_too_large(String name) {
    return 'Arquivo muito grande: $name';
  }

  @override
  String meeting_send_failed(String details) {
    return 'Falha ao enviar: $details';
  }

  @override
  String get meeting_edit_message_title => 'Editar mensagem';

  @override
  String meeting_save_failed(String details) {
    return 'Falha ao salvar: $details';
  }

  @override
  String get meeting_delete_message_title => 'Excluir mensagem?';

  @override
  String get meeting_delete_message_body =>
      'Os membros verão \"Mensagem excluída\".';

  @override
  String meeting_delete_failed(String details) {
    return 'Falha ao excluir: $details';
  }

  @override
  String get meeting_message_hint => 'Mensagem…';

  @override
  String get meeting_message_deleted => 'Mensagem excluída';

  @override
  String get meeting_message_edited => '• editada';

  @override
  String get meeting_copy_action => 'Copiar';

  @override
  String get meeting_edit_action => 'Editar';

  @override
  String get meeting_join_title => 'Entrar';

  @override
  String meeting_loading_error(String details) {
    return 'Erro ao carregar a reunião: $details';
  }

  @override
  String get meeting_not_found => 'Reunião não encontrada ou encerrada';

  @override
  String get meeting_private_description =>
      'Reunião privada: o anfitrião decide se deixa você entrar após sua solicitação.';

  @override
  String get meeting_public_description =>
      'Reunião aberta: entre pelo link sem esperar.';

  @override
  String get meeting_your_name_label => 'Seu nome';

  @override
  String get meeting_enter_name_error => 'Digite seu nome';

  @override
  String get meeting_guest_name => 'Convidado';

  @override
  String get meeting_enter_room => 'Entrar na sala';

  @override
  String get meeting_request_join => 'Solicitar entrada';

  @override
  String get meeting_approved_title => 'Aprovado';

  @override
  String get meeting_approved_subtitle => 'Redirecionando para a sala…';

  @override
  String get meeting_denied_title => 'Negado';

  @override
  String get meeting_denied_subtitle => 'O anfitrião negou sua solicitação.';

  @override
  String get meeting_pending_title => 'Aguardando aprovação';

  @override
  String get meeting_pending_subtitle =>
      'O anfitrião verá sua solicitação e decidirá quando deixar você entrar.';

  @override
  String meeting_load_error(String details) {
    return 'Falha ao carregar a reunião: $details';
  }

  @override
  String meeting_init_error(Object error) {
    return 'Erro de inicialização: $error';
  }

  @override
  String meeting_participants_error(Object error) {
    return 'Membros: $error';
  }

  @override
  String meeting_bg_unavailable(Object error) {
    return 'Plano de fundo indisponível: $error';
  }

  @override
  String get meeting_leave => 'Sair';

  @override
  String get meeting_screen_share_ios =>
      'Compartilhamento de tela no iOS requer Broadcast Extension (em breve)';

  @override
  String meeting_screen_share_failed(String details) {
    return 'Falha ao iniciar o compartilhamento de tela: $details';
  }

  @override
  String get meeting_tooltip_speaker_mode => 'Modo orador';

  @override
  String get meeting_tooltip_grid_mode => 'Modo grade';

  @override
  String get meeting_tooltip_copy_link => 'Copiar link (entrar pelo navegador)';

  @override
  String get meeting_mic_on => 'Ativar microfone';

  @override
  String get meeting_mic_off => 'Silenciar';

  @override
  String get meeting_camera_on => 'Ligar câmera';

  @override
  String get meeting_camera_off => 'Desligar câmera';

  @override
  String get meeting_switch_camera => 'Alternar';

  @override
  String get meeting_hand_lower => 'Abaixar';

  @override
  String get meeting_hand_raise => 'Mão';

  @override
  String get meeting_reaction => 'Reação';

  @override
  String get meeting_screen_stop => 'Parar';

  @override
  String get meeting_screen_label => 'Tela';

  @override
  String get meeting_bg_off => 'BG';

  @override
  String get meeting_bg_blur => 'Desfoque';

  @override
  String get meeting_bg_image => 'Imagem';

  @override
  String get meeting_participants_button => 'Membros';

  @override
  String get settings_chats_bottom_nav_icons_title => 'Bottom navigation icons';

  @override
  String get settings_chats_bottom_nav_icons_subtitle =>
      'Escolha ícones e estilo visual como na web.';

  @override
  String get settings_chats_nav_colorful => 'Colorful';

  @override
  String get settings_chats_nav_minimal => 'Minimal';

  @override
  String get settings_chats_nav_global_title => 'Para todos os ícones';

  @override
  String get settings_chats_nav_global_subtitle =>
      'Global layer: color, size, stroke width, and tile background.';

  @override
  String get settings_chats_reset_tooltip => 'Restaurar';

  @override
  String get settings_chats_collapse => 'Collapse';

  @override
  String get settings_chats_customize => 'Personalizar';

  @override
  String get settings_chats_reset_item_tooltip => 'Restaurar';

  @override
  String get settings_chats_style_tooltip => 'Estilo';

  @override
  String get settings_chats_icon_size => 'Icon size';

  @override
  String get settings_chats_stroke_width => 'Stroke width';

  @override
  String get settings_chats_default => 'Padrão';

  @override
  String get settings_chats_icon_search_hint_en => 'Buscar por nome...';

  @override
  String get settings_chats_emoji_effects => 'Emoji effects';

  @override
  String get settings_chats_emoji_effects_subtitle =>
      'Perfil de animação para o efeito de emoji em tela cheia ao tocar em um único emoji no chat.';

  @override
  String get settings_chats_emoji_lite_desc =>
      'Lite: carga mínima e fluidez máxima em dispositivos modestos.';

  @override
  String get settings_chats_emoji_balanced_desc =>
      'Balanced: automatic compromise between performance and expressiveness.';

  @override
  String get settings_chats_emoji_cinematic_desc =>
      'Cinematic: máximo de partículas e profundidade para um efeito uau.';

  @override
  String get settings_chats_preview_incoming_msg => 'Oi! Tudo bem?';

  @override
  String get settings_chats_preview_outgoing_msg => 'Great, thanks!';

  @override
  String get settings_chats_preview_hello => 'Olá';

  @override
  String get chat_theme_title => 'Tema do chat';

  @override
  String chat_theme_error_save(String error) {
    return 'Falha ao salvar background: $error';
  }

  @override
  String chat_theme_error_upload(String error) {
    return 'Plano de fundo upload error: $error';
  }

  @override
  String get chat_theme_delete_title => 'Excluir plano de fundo da galeria?';

  @override
  String get chat_theme_delete_body =>
      'A imagem será removida da sua lista de planos de fundo. Você pode escolher outra para este chat.';

  @override
  String chat_theme_error_delete(String error) {
    return 'Excluir error: $error';
  }

  @override
  String get chat_theme_banner =>
      'O plano de fundo deste chat é só para você. As configurações globais em \"Configurações do chat\" permanecem inalteradas.';

  @override
  String get chat_theme_current_bg => 'Plano de fundo atual';

  @override
  String get chat_theme_default_global => 'Padrão (global settings)';

  @override
  String get chat_theme_presets => 'Pré-ajustes';

  @override
  String get chat_theme_global_tile => 'Global';

  @override
  String get chat_theme_pick_hint => 'Escolher a preset or photo from gallery';

  @override
  String get contacts_title => 'Contatos';

  @override
  String get contacts_add_phone_prompt =>
      'Adicione um número de telefone no seu perfil para buscar contatos por número.';

  @override
  String get contacts_fallback_profile => 'Perfil';

  @override
  String get contacts_fallback_user => 'Usuário';

  @override
  String get contacts_status_online => 'online';

  @override
  String get contacts_status_recently => 'Visto recentemente';

  @override
  String contacts_status_today_at(String time) {
    return 'Visto às $time';
  }

  @override
  String get contacts_status_yesterday => 'Visto ontem';

  @override
  String get contacts_status_year_ago => 'Visto há um ano';

  @override
  String contacts_status_years_ago(String years) {
    return 'Visto há $years';
  }

  @override
  String contacts_status_date(String date) {
    return 'Visto em $date';
  }

  @override
  String get contacts_empty_state =>
      'Nenhum contato encontrado.\nToque no botão à direita para sincronizar a agenda do seu telefone.';

  @override
  String get add_contact_title => 'Novo contato';

  @override
  String get add_contact_sync_off => 'A sincronização está desativada no app.';

  @override
  String get add_contact_enable_system_access =>
      'Ative o acesso aos contatos para o LighChat nas configurações do sistema.';

  @override
  String get add_contact_sync_on => 'Sincronização ativada';

  @override
  String get add_contact_sync_failed =>
      'Não foi possível ativar a sincronização de contatos';

  @override
  String get add_contact_invalid_phone => 'Digite um número de telefone válido';

  @override
  String get add_contact_not_found_by_phone =>
      'Nenhum contato encontrado para este número';

  @override
  String get add_contact_found => 'Contato encontrado';

  @override
  String add_contact_search_error(String error) {
    return 'Falha na busca: $error';
  }

  @override
  String get add_contact_qr_no_profile =>
      'O QR code não contém um perfil do LighChat';

  @override
  String get add_contact_qr_own_profile => 'Este é o seu próprio perfil';

  @override
  String get add_contact_qr_profile_not_found =>
      'Perfil do QR code não encontrado';

  @override
  String get add_contact_qr_found => 'Contato encontrado pelo QR code';

  @override
  String add_contact_qr_read_error(String error) {
    return 'Não foi possível ler o QR code: $error';
  }

  @override
  String get add_contact_cannot_add_user =>
      'Não é possível adicionar este usuário';

  @override
  String add_contact_add_error(String error) {
    return 'Não foi possível adicionar o contato: $error';
  }

  @override
  String get add_contact_country_search_hint => 'Buscar país ou código';

  @override
  String get add_contact_sync_with_phone => 'Sincronizar com o telefone';

  @override
  String get add_contact_add_by_qr => 'Adicionar por QR code';

  @override
  String get add_contact_results_unavailable =>
      'Resultados ainda não disponíveis';

  @override
  String add_contact_profile_load_error(String error) {
    return 'Não foi possível carregar o contato: $error';
  }

  @override
  String get add_contact_profile_not_found => 'Perfil não encontrado';

  @override
  String get add_contact_badge_already_added => 'Já adicionado';

  @override
  String get add_contact_badge_new => 'Novo contato';

  @override
  String get add_contact_badge_unavailable => 'Indisponível';

  @override
  String get add_contact_open_contact => 'Abrir contato';

  @override
  String get add_contact_add_to_contacts => 'Adicionar aos contatos';

  @override
  String get add_contact_add_unavailable => 'Adicionar indisponível';

  @override
  String get add_contact_searching => 'Procurando contato...';

  @override
  String get add_contact_scan_qr_title => 'Escanear QR code';

  @override
  String get add_contact_flash_tooltip => 'Flash';

  @override
  String get add_contact_scan_qr_hint =>
      'Aponte sua câmera para um QR code de perfil do LighChat';

  @override
  String get contacts_edit_enter_name => 'Digite o nome do contato.';

  @override
  String contacts_edit_save_error(String error) {
    return 'Não foi possível salvar o contato: $error';
  }

  @override
  String get contacts_edit_first_name_hint => 'Nome';

  @override
  String get contacts_edit_last_name_hint => 'Sobrenome';

  @override
  String get contacts_edit_name_disclaimer =>
      'Este nome é visível apenas para você: nos chats, na busca e na lista de contatos.';

  @override
  String contacts_edit_error(String error) {
    return 'Erro: $error';
  }

  @override
  String get chat_settings_color_default => 'Padrão';

  @override
  String get chat_settings_color_lilac => 'Lilás';

  @override
  String get chat_settings_color_pink => 'Rosa';

  @override
  String get chat_settings_color_green => 'Verde';

  @override
  String get chat_settings_color_coral => 'Coral';

  @override
  String get chat_settings_color_mint => 'Menta';

  @override
  String get chat_settings_color_sky => 'Céu';

  @override
  String get chat_settings_color_purple => 'Roxo';

  @override
  String get chat_settings_color_crimson => 'Carmesim';

  @override
  String get chat_settings_color_tiffany => 'Tiffany';

  @override
  String get chat_settings_color_yellow => 'Amarelo';

  @override
  String get chat_settings_color_powder => 'Pó';

  @override
  String get chat_settings_color_turquoise => 'Turquesa';

  @override
  String get chat_settings_color_blue => 'Azul';

  @override
  String get chat_settings_color_sunset => 'Pôr do sol';

  @override
  String get chat_settings_color_tender => 'Suave';

  @override
  String get chat_settings_color_lime => 'Lima';

  @override
  String get chat_settings_color_graphite => 'Grafite';

  @override
  String get chat_settings_color_no_bg => 'Sem plano de fundo';

  @override
  String get chat_settings_icon_color => 'Cor do ícone';

  @override
  String get chat_settings_icon_size => 'Tamanho do ícone';

  @override
  String get chat_settings_stroke_width => 'Espessura do traço';

  @override
  String get chat_settings_tile_background => 'Plano de fundo do bloco';

  @override
  String get chat_settings_bottom_nav_icons => 'Ícones da navegação inferior';

  @override
  String get chat_settings_bottom_nav_description =>
      'Escolha ícones e estilo visual como na web.';

  @override
  String get chat_settings_bottom_nav_global_description =>
      'Camada compartilhada: cor, tamanho, traço e plano de fundo do bloco.';

  @override
  String get chat_settings_colorful => 'Colorido';

  @override
  String get chat_settings_minimalism => 'Minimalista';

  @override
  String get chat_settings_for_all_icons => 'Para todos os ícones';

  @override
  String get chat_settings_customize => 'Personalizar';

  @override
  String get chat_settings_hide => 'Ocultar';

  @override
  String get chat_settings_reset => 'Restaurar';

  @override
  String get chat_settings_reset_item => 'Restaurar';

  @override
  String get chat_settings_style => 'Estilo';

  @override
  String get chat_settings_select => 'Selecionar';

  @override
  String get chat_settings_reset_size => 'Restaurar tamanho';

  @override
  String get chat_settings_reset_stroke => 'Restaurar traço';

  @override
  String get chat_settings_default_gradient => 'Gradiente padrão';

  @override
  String get chat_settings_inherit_global => 'Herdar do global';

  @override
  String get chat_settings_no_bg_on => 'Sem plano de fundo (ativado)';

  @override
  String get chat_settings_no_bg => 'Sem plano de fundo';

  @override
  String get chat_settings_outgoing_messages => 'Mensagens enviadas';

  @override
  String get chat_settings_incoming_messages => 'Mensagens recebidas';

  @override
  String get chat_settings_font_size => 'Tamanho da fonte';

  @override
  String get chat_settings_font_small => 'Pequeno';

  @override
  String get chat_settings_font_medium => 'Médio';

  @override
  String get chat_settings_font_large => 'Grande';

  @override
  String get chat_settings_bubble_shape => 'Forma do balão';

  @override
  String get chat_settings_bubble_rounded => 'Arredondado';

  @override
  String get chat_settings_bubble_square => 'Quadrado';

  @override
  String get chat_settings_chat_background => 'Plano de fundo do chat';

  @override
  String get chat_settings_background_hint =>
      'Escolha uma foto da galeria ou personalize';

  @override
  String get chat_settings_emoji_effects => 'Efeitos de emoji';

  @override
  String get chat_settings_emoji_description =>
      'Perfil de animação para emoji em tela cheia ao tocar no chat.';

  @override
  String get chat_settings_emoji_lite =>
      'Lite: carga mínima, mais fluida em dispositivos modestos.';

  @override
  String get chat_settings_emoji_cinematic =>
      'Cinematic: máximo de partículas e profundidade para um efeito uau.';

  @override
  String get chat_settings_emoji_balanced =>
      'Balanced: equilíbrio automático entre desempenho e expressividade.';

  @override
  String get chat_settings_additional => 'Adicionais';

  @override
  String get chat_settings_show_time => 'Mostrar horário';

  @override
  String get chat_settings_show_time_hint =>
      'Horário do envio abaixo das mensagens';

  @override
  String get chat_settings_reset_all => 'Restaurar configurações';

  @override
  String get chat_settings_preview_incoming => 'Oi! Tudo bem?';

  @override
  String get chat_settings_preview_outgoing => 'Tudo ótimo, obrigado!';

  @override
  String get chat_settings_preview_hello => 'Olá';

  @override
  String chat_settings_icon_picker_title(String label) {
    return 'Ícone: \"$label\"';
  }

  @override
  String get chat_settings_search_hint => 'Buscar por nome (eng.)...';

  @override
  String meeting_tab_participants(Object count) {
    return 'Membros ($count)';
  }

  @override
  String get meeting_tab_polls => 'Enquetes';

  @override
  String meeting_tab_polls_count(Object count) {
    return 'Enquetes ($count)';
  }

  @override
  String get meeting_tab_chat => 'Chat';

  @override
  String meeting_tab_chat_count(Object count) {
    return 'Chat ($count)';
  }

  @override
  String meeting_tab_requests(Object count) {
    return 'Solicitações ($count)';
  }

  @override
  String get meeting_kick => 'Remover da sala';

  @override
  String meeting_file_too_big(Object name) {
    return 'Arquivo too big: $name';
  }

  @override
  String meeting_send_error(Object error) {
    return 'Não foi possível enviar: $error';
  }

  @override
  String meeting_save_error(Object error) {
    return 'Não foi possível salvar: $error';
  }

  @override
  String meeting_delete_error(Object error) {
    return 'Não foi possível excluir: $error';
  }

  @override
  String get meeting_no_messages => 'Sem mensagens ainda';

  @override
  String get meeting_join_enter_name => 'Digite seu nome';

  @override
  String get meeting_join_guest => 'Convidado';

  @override
  String get meeting_join_button => 'Entrar';

  @override
  String meeting_join_load_error(Object error) {
    return 'Reunião load error: $error';
  }

  @override
  String get meeting_private_hint =>
      'Reunião privada: o anfitrião decide se deixa você entrar após sua solicitação.';

  @override
  String get meeting_public_hint =>
      'Abrir meeting: join via link without waiting.';

  @override
  String get meeting_name_label => 'Seu nome';

  @override
  String get meeting_waiting_title => 'Aguardando aprovação';

  @override
  String get meeting_waiting_subtitle =>
      'O anfitrião verá sua solicitação e decidirá quando deixar você entrar.';

  @override
  String get meeting_screen_share_ios_hint =>
      'Compartilhamento de tela no iOS requer um Broadcast Extension (em desenvolvimento).';

  @override
  String meeting_screen_share_error(Object error) {
    return 'Não foi possível iniciar screen sharing: $error';
  }

  @override
  String get meeting_speaker_mode => 'Alto-falante mode';

  @override
  String get meeting_grid_mode => 'Modo grade';

  @override
  String get meeting_copy_link_tooltip => 'Copiar link (browser entry)';

  @override
  String get group_members_subtitle_creator => 'Grupo creator';

  @override
  String get group_members_subtitle_admin => 'Administrador';

  @override
  String get group_members_subtitle_member => 'Membro';

  @override
  String group_members_total_count(int count) {
    return 'Total: $count';
  }

  @override
  String get group_members_copy_invite_tooltip => 'Copiar invite link';

  @override
  String get group_members_add_member_tooltip => 'Adicionar member';

  @override
  String get group_members_invite_copied => 'Invite link copied';

  @override
  String group_members_copy_link_error(String error) {
    return 'Falha ao copiar link: $error';
  }

  @override
  String get group_members_added => 'Membros added';

  @override
  String get group_members_revoke_admin_title => 'Revoke admin privileges?';

  @override
  String group_members_revoke_admin_body(String name) {
    return '$name perderá os privilégios de admin. Continuará no grupo como membro comum.';
  }

  @override
  String get group_members_grant_admin_title => 'Grant admin privileges?';

  @override
  String group_members_grant_admin_body(String name) {
    return '$name receberá privilégios de admin: poderá editar o grupo, remover membros e gerenciar mensagens.';
  }

  @override
  String get group_members_revoke_admin_action => 'Revoke';

  @override
  String get group_members_grant_admin_action => 'Grant';

  @override
  String get group_members_remove_title => 'Remove member?';

  @override
  String group_members_remove_body(String name) {
    return '$name será removido do grupo. Você pode desfazer adicionando o membro novamente.';
  }

  @override
  String get group_members_remove_action => 'Remove';

  @override
  String get group_members_removed => 'Membro removed';

  @override
  String get group_members_menu_revoke_admin => 'Remove admin';

  @override
  String get group_members_menu_grant_admin => 'Tornar admin';

  @override
  String get group_members_menu_remove => 'Remover do grupo';

  @override
  String get group_members_creator_badge => 'CREATOR';

  @override
  String get group_members_add_title => 'Adicionar membros';

  @override
  String get group_members_search_contacts => 'Buscar contatos';

  @override
  String get group_members_all_in_group =>
      'Todos os seus contatos já estão no grupo.';

  @override
  String get group_members_nobody_found => 'Nobody found.';

  @override
  String get group_members_user_fallback => 'User';

  @override
  String get group_members_select_members => 'Selecionar members';

  @override
  String group_members_add_count(int count) {
    return 'Adicionar ($count)';
  }

  @override
  String group_members_contacts_load_error(String error) {
    return 'Falha ao carregar contacts: $error';
  }

  @override
  String group_members_auth_error(String error) {
    return 'Authorization error: $error';
  }

  @override
  String group_members_add_failed(String error) {
    return 'Falha ao adicionar members: $error';
  }

  @override
  String get group_not_found => 'Grupo not found.';

  @override
  String get group_not_member => 'Você não é membro deste grupo.';

  @override
  String get poll_create_title => 'Enquete do chat';

  @override
  String get poll_question_label => 'Question';

  @override
  String get poll_question_hint => 'E.g.: What time shall we meet?';

  @override
  String get poll_description_label => 'Descrição (optional)';

  @override
  String get poll_options_title => 'Options';

  @override
  String poll_option_hint(int index) {
    return 'Option $index';
  }

  @override
  String get poll_add_option => 'Adicionar option';

  @override
  String get poll_switch_anonymous => 'Anônimo voting';

  @override
  String get poll_switch_anonymous_sub => 'Não mostrar quem votou em quê';

  @override
  String get poll_switch_multi => 'Multiple answers';

  @override
  String get poll_switch_multi_sub => 'Várias opções podem ser selecionadas';

  @override
  String get poll_switch_add_options => 'Adicionar options';

  @override
  String get poll_switch_add_options_sub =>
      'Os participantes podem sugerir opções próprias';

  @override
  String get poll_switch_revote => 'Can change vote';

  @override
  String get poll_switch_revote_sub => 'Revote allowed until poll closes';

  @override
  String get poll_switch_shuffle => 'Shuffle options';

  @override
  String get poll_switch_shuffle_sub =>
      'Ordem diferente para cada participante';

  @override
  String get poll_switch_quiz => 'Quiz mode';

  @override
  String get poll_switch_quiz_sub => 'One correct answer';

  @override
  String get poll_correct_option_label => 'Correct option';

  @override
  String get poll_quiz_explanation_label => 'Explanation (optional)';

  @override
  String get poll_close_by_time => 'Fechar by time';

  @override
  String get poll_close_not_set => 'Not set';

  @override
  String get poll_close_reset => 'Restaurar deadline';

  @override
  String get poll_publish => 'Publish';

  @override
  String get poll_error_empty_question => 'Enter a question';

  @override
  String get poll_error_min_options => 'São necessárias pelo menos 2 opções';

  @override
  String get poll_error_select_correct => 'Selecionar the correct option';

  @override
  String get poll_error_future_time =>
      'O horário de fechamento deve ser no futuro';

  @override
  String get poll_unavailable => 'Enquete indisponível';

  @override
  String get poll_loading => 'Carregando enquete…';

  @override
  String get poll_not_found => 'Enquete não encontrada';

  @override
  String get poll_status_cancelled => 'Cancelada';

  @override
  String get poll_status_ended => 'Ended';

  @override
  String get poll_status_draft => 'Rascunho';

  @override
  String get poll_status_active => 'Ativo';

  @override
  String get poll_badge_public => 'Pública';

  @override
  String get poll_badge_multi => 'Múltiplas respostas';

  @override
  String get poll_badge_quiz => 'Quiz';

  @override
  String get poll_menu_restart => 'Restart';

  @override
  String get poll_menu_end => 'End';

  @override
  String get poll_menu_delete => 'Excluir';

  @override
  String get poll_submit_vote => 'Enviar voto';

  @override
  String get poll_suggest_option_hint => 'Suggest an option';

  @override
  String get poll_revote => 'Alterar voto';

  @override
  String poll_votes_count(int count) {
    return '$count votes';
  }

  @override
  String get poll_show_voters => 'Who voted';

  @override
  String get poll_hide_voters => 'Ocultar';

  @override
  String get poll_vote_error => 'Erro while voting';

  @override
  String get poll_add_option_error => 'Falha ao adicionar option';

  @override
  String get poll_error_generic => 'Erro';

  @override
  String get durak_your_turn => 'Sua vez';

  @override
  String get durak_winner_label => 'Vencedor';

  @override
  String get durak_rematch => 'Play again';

  @override
  String get durak_surrender_tooltip => 'End game';

  @override
  String get durak_close_tooltip => 'Fechar';

  @override
  String get durak_fx_took => 'Took';

  @override
  String get durak_fx_beat => 'Beaten';

  @override
  String get durak_opponent_role_defend => 'DEF';

  @override
  String get durak_opponent_role_attack => 'ATK';

  @override
  String get durak_opponent_role_throwin => 'THR';

  @override
  String get durak_foul_banner_title => 'Trapaceiro! Missed:';

  @override
  String get durak_pending_resolution_attacker =>
      'Waiting for foul check… Press \"Confirmar Beaten\" if everyone agrees.';

  @override
  String get durak_pending_resolution_other =>
      'Aguardando verificação de falta… Você pode pressionar \"Falta!\" se notou trapaça.';

  @override
  String durak_tournament_played(int finished, int total) {
    return 'Played $finished of $total';
  }

  @override
  String get durak_tournament_finished => 'Torneio finished';

  @override
  String get durak_tournament_next => 'Próximo tournament game';

  @override
  String get durak_single_game => 'Single game';

  @override
  String get durak_tournament_total_games_title => 'Quantos jogos no torneio?';

  @override
  String get durak_finish_game_tooltip => 'End game';

  @override
  String get durak_lobby_game_unavailable =>
      'Jogo indisponível ou foi excluído';

  @override
  String get durak_lobby_back_tooltip => 'Voltar';

  @override
  String get durak_lobby_waiting => 'Aguardando oponente…';

  @override
  String get durak_lobby_start => 'Iniciar game';

  @override
  String get durak_lobby_waiting_short => 'Waiting…';

  @override
  String get durak_lobby_ready => 'Pronto';

  @override
  String get durak_lobby_empty_slot => 'Waiting…';

  @override
  String get durak_settings_timer_subtitle => '15 segundos by default';

  @override
  String get durak_dm_game_active => 'Durak game in progress';

  @override
  String get durak_dm_game_created => 'Durak game created';

  @override
  String get game_durak_subtitle => 'Single game or tournament';

  @override
  String get group_member_write_dm => 'Enviar direct message';

  @override
  String get group_member_open_dm_hint => 'Abrir direct chat with member';

  @override
  String get group_member_profile_not_loaded =>
      'Membro profile not loaded yet.';

  @override
  String group_member_open_dm_error(String error) {
    return 'Failed to open direct chat: $error';
  }

  @override
  String get group_avatar_photo_title => 'Foto do grupo';

  @override
  String get group_avatar_add_photo => 'Adicionar photo';

  @override
  String get group_avatar_change => 'Alterar avatar';

  @override
  String get group_avatar_remove => 'Remover avatar';

  @override
  String group_avatar_process_error(String error) {
    return 'Failed to process photo: $error';
  }

  @override
  String get group_mention_no_matches => 'Não matches';

  @override
  String get durak_error_defense_does_not_beat =>
      'Esta carta não bate a carta do ataque';

  @override
  String get durak_error_only_attacker_first => 'Attacker goes first';

  @override
  String get durak_error_defender_cannot_attack =>
      'Defender cannot throw in right now';

  @override
  String get durak_error_not_allowed_throwin =>
      'Você não pode jogar extras nesta rodada';

  @override
  String get durak_error_throwin_not_your_turn =>
      'Outro jogador está jogando extras agora';

  @override
  String get durak_error_rank_not_allowed =>
      'Você só pode jogar cartas do mesmo valor';

  @override
  String get durak_error_cannot_throw_in => 'Cannot throw in more cards';

  @override
  String get durak_error_card_not_in_hand =>
      'Esta carta não está mais na sua mão';

  @override
  String get durak_error_already_defended => 'This card is already defended';

  @override
  String get durak_error_bad_attack_index =>
      'Selecionar an attacking card to defend against';

  @override
  String get durak_error_only_defender => 'Another player is defending now';

  @override
  String get durak_error_defender_already_taking =>
      'Defender is already taking cards';

  @override
  String get durak_error_game_not_active => 'Jogo is no longer active';

  @override
  String get durak_error_not_in_lobby => 'Lobby has already started';

  @override
  String get durak_error_game_already_active => 'Jogo has already started';

  @override
  String get durak_error_active_game_exists =>
      'Já existe um jogo ativo neste chat';

  @override
  String get durak_error_resolution_pending => 'Finish the disputed move first';

  @override
  String get durak_error_rematch_failed =>
      'Failed to prepare rematch. Please try again';

  @override
  String get durak_error_unauthenticated => 'Você precisa entrar';

  @override
  String get durak_error_permission_denied =>
      'Esta ação não está disponível para você';

  @override
  String get durak_error_invalid_argument => 'Invalid move';

  @override
  String get durak_error_failed_precondition =>
      'A jogada não está disponível agora';

  @override
  String get durak_error_server => 'Failed to execute move. Please try again';

  @override
  String pinned_count(int count) {
    return 'Fixadas: $count';
  }

  @override
  String get pinned_single => 'Fixada';

  @override
  String get pinned_unpin_tooltip => 'Desafixar';

  @override
  String get pinned_type_image => 'Imagem';

  @override
  String get pinned_type_video => 'Vídeo';

  @override
  String get pinned_type_video_circle => 'Vídeo circle';

  @override
  String get pinned_type_voice => 'Mensagem de voz';

  @override
  String get pinned_type_poll => 'Enquete';

  @override
  String get pinned_type_link => 'Link';

  @override
  String get pinned_type_location => 'Localização';

  @override
  String get pinned_type_sticker => 'Figurinha';

  @override
  String get pinned_type_file => 'Arquivo';

  @override
  String get call_entry_login_required_title => 'É preciso entrar';

  @override
  String get call_entry_login_required_subtitle =>
      'Abra o app e entre na sua conta.';

  @override
  String get call_entry_not_found_title => 'Chamada não encontrada';

  @override
  String get call_entry_not_found_subtitle =>
      'A chamada já terminou ou foi excluída. Voltando para chamadas…';

  @override
  String get call_entry_to_calls => 'Para chamadas';

  @override
  String get call_entry_ended_title => 'Chamada encerrada';

  @override
  String get call_entry_ended_subtitle =>
      'Esta chamada não está mais disponível. Voltando para chamadas…';

  @override
  String get call_entry_caller_fallback => 'Quem ligou';

  @override
  String get call_entry_opening_title => 'Abrindo a chamada…';

  @override
  String get call_entry_connecting_video => 'Conectando à chamada de vídeo';

  @override
  String get call_entry_connecting_audio => 'Conectando à chamada de áudio';

  @override
  String get call_entry_loading_subtitle => 'Carregando dados da chamada';

  @override
  String get call_entry_error_title => 'Erro opening call';

  @override
  String chat_theme_save_error(Object error) {
    return 'Falha ao salvar background: $error';
  }

  @override
  String chat_theme_load_error(Object error) {
    return 'Erro loading background: $error';
  }

  @override
  String chat_theme_delete_error(Object error) {
    return 'Erro ao excluir: $error';
  }

  @override
  String get chat_theme_description =>
      'O plano de fundo desta conversa é visível apenas para você. As configurações globais em Configurações do chat não são afetadas.';

  @override
  String get chat_theme_default_bg => 'Padrão (global settings)';

  @override
  String get chat_theme_global_label => 'Global';

  @override
  String get chat_theme_hint => 'Escolha um pré-ajuste ou foto da galeria';

  @override
  String get date_today => 'Hoje';

  @override
  String get date_yesterday => 'Ontem';

  @override
  String get date_month_1 => 'Janeiro';

  @override
  String get date_month_2 => 'Fevereiro';

  @override
  String get date_month_3 => 'Março';

  @override
  String get date_month_4 => 'Abril';

  @override
  String get date_month_5 => 'Maio';

  @override
  String get date_month_6 => 'Junho';

  @override
  String get date_month_7 => 'Julho';

  @override
  String get date_month_8 => 'Agosto';

  @override
  String get date_month_9 => 'Setembro';

  @override
  String get date_month_10 => 'Outubro';

  @override
  String get date_month_11 => 'Novembro';

  @override
  String get date_month_12 => 'Dezembro';

  @override
  String get video_circle_camera_unavailable => 'Câmera unavailable';

  @override
  String video_circle_camera_error(Object error) {
    return 'Falha ao abrir a câmera: $error';
  }

  @override
  String video_circle_record_error(Object error) {
    return 'Gravando error: $error';
  }

  @override
  String get video_circle_file_not_found =>
      'Arquivo de gravação não encontrado';

  @override
  String get video_circle_play_error => 'Falha ao reproduzir recording';

  @override
  String video_circle_send_error(Object error) {
    return 'Falha ao enviar: $error';
  }

  @override
  String video_circle_switch_error(Object error) {
    return 'Falha ao alternar a câmera: $error';
  }

  @override
  String video_circle_pause_error_detail(Object description, Object code) {
    return 'Pausa indisponível: $description ($code)';
  }

  @override
  String video_circle_pause_error(Object error) {
    return 'Erro ao pausar a gravação: $error';
  }

  @override
  String get video_circle_camera_fallback_error => 'Erro de câmera';

  @override
  String get video_circle_retry => 'Tentar de novo';

  @override
  String get video_circle_sending => 'Enviando...';

  @override
  String get video_circle_recorded => 'Nota em vídeo gravada';

  @override
  String get video_circle_swipe_cancel =>
      'Deslize para a esquerda para cancelar';

  @override
  String media_screen_error(Object error) {
    return 'Erro loading media: $error';
  }

  @override
  String get media_screen_title => 'Mídia, links e arquivos';

  @override
  String get media_tab_media => 'Mídia';

  @override
  String get media_tab_circles => 'Notas em vídeo';

  @override
  String get media_tab_files => 'Arquivos';

  @override
  String get media_tab_links => 'Links';

  @override
  String get media_empty_files => 'Não files';

  @override
  String get media_empty_media => 'Não media';

  @override
  String get media_attachment_fallback => 'Anexo';

  @override
  String get media_empty_circles => 'Não circles';

  @override
  String get media_empty_links => 'Não links';

  @override
  String get media_sender_you => 'Você';

  @override
  String get media_sender_fallback => 'Participante';

  @override
  String get call_detail_login_required => 'É preciso entrar.';

  @override
  String get call_detail_not_found => 'Chamada not found or no access.';

  @override
  String get call_detail_unknown => 'Desconhecido';

  @override
  String get call_detail_title => 'Chamada details';

  @override
  String get call_detail_video => 'Chamada de vídeo';

  @override
  String get call_detail_audio => 'Chamada de áudio';

  @override
  String get call_detail_outgoing => 'Realizada';

  @override
  String get call_detail_incoming => 'Recebida';

  @override
  String get call_detail_date_label => 'Data:';

  @override
  String get call_detail_duration_label => 'Duração:';

  @override
  String get call_detail_call_button => 'Chamada';

  @override
  String get call_detail_video_button => 'Vídeo';

  @override
  String call_detail_error(Object error) {
    return 'Erro: $error';
  }

  @override
  String get durak_took => 'Pegou';

  @override
  String get durak_beaten => 'Batidas';

  @override
  String get durak_end_game_tooltip => 'Encerrar jogo';

  @override
  String get durak_role_beats => 'DEF';

  @override
  String get durak_role_move => 'JOG';

  @override
  String get durak_role_throw => 'EXT';

  @override
  String get durak_cheater_label => 'Trapaceiro! Missed:';

  @override
  String get durak_waiting_foll_confirm =>
      'Aguardando marcação de falta… Pressione \"Confirmar Bater\" se todos concordarem.';

  @override
  String get durak_waiting_foll_call =>
      'Aguardando marcação de falta… Você pode pressionar \"Falta!\" se notou trapaça.';

  @override
  String get durak_winner => 'Vencedor';

  @override
  String get durak_play_again => 'Jogar de novo';

  @override
  String durak_games_progress(Object finished, Object total) {
    return 'Jogados $finished de $total';
  }

  @override
  String get durak_next_round => 'Próximo tournament round';

  @override
  String audio_call_error(Object error) {
    return 'Chamada error: $error';
  }

  @override
  String get audio_call_ended => 'Chamada encerrada';

  @override
  String get audio_call_missed => 'Chamada perdida';

  @override
  String get audio_call_cancelled => 'Chamada cancelada';

  @override
  String get audio_call_offer_not_ready =>
      'Oferta ainda não está pronta, tente novamente';

  @override
  String get audio_call_invalid_data => 'Dados de chamada inválidos';

  @override
  String audio_call_accept_error(Object error) {
    return 'Falha ao aceitar a chamada: $error';
  }

  @override
  String get audio_call_incoming => 'Chamada de áudio recebida';

  @override
  String get audio_call_calling => 'Chamada de áudio…';

  @override
  String privacy_save_error(Object error) {
    return 'Falha ao salvar settings: $error';
  }

  @override
  String privacy_load_error(Object error) {
    return 'Erro loading privacy: $error';
  }

  @override
  String get privacy_visibility => 'Visibilidade';

  @override
  String get privacy_online_status => 'Status online';

  @override
  String get privacy_last_visit => 'Visto por último';

  @override
  String get privacy_read_receipts => 'Confirmações de leitura';

  @override
  String get privacy_profile_info => 'Perfil info';

  @override
  String get privacy_phone_number => 'Número de telefone';

  @override
  String get privacy_birthday => 'Aniversário';

  @override
  String get privacy_about => 'Sobre';

  @override
  String starred_load_error(Object error) {
    return 'Erro loading starred: $error';
  }

  @override
  String get starred_title => 'Favoritas';

  @override
  String get starred_empty => 'Nenhuma mensagem em Favoritas neste chat';

  @override
  String get starred_message_fallback => 'Mensagem';

  @override
  String get starred_sender_you => 'Você';

  @override
  String get starred_sender_fallback => 'Participante';

  @override
  String get starred_type_poll => 'Enquete';

  @override
  String get starred_type_location => 'Localização';

  @override
  String get starred_type_attachment => 'Anexo';

  @override
  String starred_today_prefix(Object time) {
    return 'Hoje, $time';
  }

  @override
  String get contact_edit_name_required => 'Digite o nome do contato.';

  @override
  String contact_edit_save_error(Object error) {
    return 'Falha ao salvar contact: $error';
  }

  @override
  String get contact_edit_user_fallback => 'Usuário';

  @override
  String get contact_edit_first_name_hint => 'Nome';

  @override
  String get contact_edit_last_name_hint => 'Sobrenome';

  @override
  String get contact_edit_description =>
      'Este nome é visível apenas para você: nos chats, na busca e na lista de contatos.';

  @override
  String contact_edit_error(Object error) {
    return 'Erro: $error';
  }

  @override
  String get voice_no_mic_access => 'Não microphone access';

  @override
  String get voice_start_error => 'Falha ao iniciar recording';

  @override
  String get voice_file_not_received => 'Gravando file not received';

  @override
  String get voice_stop_error => 'Falha ao parar a gravação';

  @override
  String get voice_title => 'Mensagem de voz';

  @override
  String get voice_recording => 'Gravando';

  @override
  String get voice_ready => 'Gravando ready';

  @override
  String get voice_stop_button => 'Parar';

  @override
  String get voice_record_again => 'Gravar again';

  @override
  String get attach_photo_video => 'Foto/Vídeo';

  @override
  String get attach_files => 'Arquivos';

  @override
  String get attach_circle => 'Nota em vídeo';

  @override
  String get attach_location => 'Localização';

  @override
  String get attach_poll => 'Enquete';

  @override
  String get attach_stickers => 'Figurinhas';

  @override
  String get attach_clipboard => 'Área de transferência';

  @override
  String get attach_text => 'Texto';

  @override
  String get attach_title => 'Anexar';

  @override
  String notif_save_error(Object error) {
    return 'Falha ao salvar: $error';
  }

  @override
  String get notif_title => 'Notificações neste chat';

  @override
  String get notif_description =>
      'As configurações abaixo se aplicam apenas a esta conversa e não alteram as notificações globais do app.';

  @override
  String get notif_this_chat => 'Este chat';

  @override
  String get notif_mute_title => 'Silenciar and hide notifications';

  @override
  String get notif_mute_subtitle =>
      'Não perturbe para este chat neste dispositivo.';

  @override
  String get notif_preview_title => 'Mostrar texto preview';

  @override
  String get notif_preview_subtitle =>
      'Quando desativada — título da notificação sem trecho da mensagem (onde houver suporte).';

  @override
  String get poll_create_enter_question => 'Digite uma pergunta';

  @override
  String get poll_create_min_options => 'São necessárias pelo menos 2 opções';

  @override
  String get poll_create_select_correct => 'Selecionar the correct option';

  @override
  String get poll_create_future_time =>
      'O horário de fechamento deve ser no futuro';

  @override
  String get poll_create_question_label => 'Pergunta';

  @override
  String get poll_create_question_hint =>
      'Por exemplo: A que horas vamos nos encontrar?';

  @override
  String get poll_create_explanation_label => 'Explicação (opcional)';

  @override
  String get poll_create_options_title => 'Opções';

  @override
  String poll_create_option_hint(Object index) {
    return 'Opção $index';
  }

  @override
  String get poll_create_add_option => 'Adicionar option';

  @override
  String get poll_create_anonymous_title => 'Anônimo voting';

  @override
  String get poll_create_anonymous_subtitle => 'Não show who voted for what';

  @override
  String get poll_create_multi_title => 'Múltiplas respostas';

  @override
  String get poll_create_multi_subtitle => 'Pode selecionar várias opções';

  @override
  String get poll_create_user_options_title => 'Opções enviadas pelos usuários';

  @override
  String get poll_create_user_options_subtitle =>
      'Os participantes podem sugerir uma opção própria';

  @override
  String get poll_create_revote_title => 'Permitir alterar voto';

  @override
  String get poll_create_revote_subtitle =>
      'Pode mudar o voto até a enquete fechar';

  @override
  String get poll_create_shuffle_title => 'Embaralhar opções';

  @override
  String get poll_create_shuffle_subtitle =>
      'Cada participante vê uma ordem diferente';

  @override
  String get poll_create_quiz_title => 'Modo quiz';

  @override
  String get poll_create_quiz_subtitle => 'Uma resposta correta';

  @override
  String get poll_create_correct_option_label => 'Opção correta';

  @override
  String get poll_create_close_by_time => 'Fechar by time';

  @override
  String get poll_create_not_set => 'Não definida';

  @override
  String get poll_create_reset_deadline => 'Restaurar deadline';

  @override
  String get poll_create_publish => 'Publicar';

  @override
  String get poll_error => 'Erro';

  @override
  String get poll_status_finished => 'Finalizado';

  @override
  String get poll_restart => 'Reiniciar';

  @override
  String get poll_finish => 'Encerrar';

  @override
  String get poll_suggest_hint => 'Sugerir uma opção';

  @override
  String get poll_voters_toggle_hide => 'Ocultar';

  @override
  String get poll_voters_toggle_show => 'Quem votou';

  @override
  String get e2ee_disable_title => 'Desativar encryption?';

  @override
  String get e2ee_disable_body =>
      'Novas mensagens serão enviadas sem criptografia de ponta a ponta. As mensagens criptografadas já enviadas permanecem na conversa.';

  @override
  String get e2ee_disable_button => 'Desativar';

  @override
  String e2ee_disable_error(Object error) {
    return 'Falha ao desativar: $error';
  }

  @override
  String get e2ee_screen_title => 'Criptografia';

  @override
  String get e2ee_enabled_description =>
      'A criptografia de ponta a ponta está ativada para este chat.';

  @override
  String get e2ee_disabled_description =>
      'Criptografia de ponta a ponta is disabled.';

  @override
  String get e2ee_info_text =>
      'Quando a criptografia está ativada, o conteúdo das novas mensagens só fica disponível para os participantes do chat nos seus dispositivos. Desativar afeta apenas as novas mensagens.';

  @override
  String get e2ee_enable_title => 'Ativar encryption';

  @override
  String e2ee_status_enabled(Object epoch) {
    return 'Ativado (key epoch: $epoch)';
  }

  @override
  String get e2ee_status_disabled => 'Desativado';

  @override
  String get e2ee_data_types_title => 'Tipos de dado';

  @override
  String get e2ee_data_types_info =>
      'Esta configuração não muda o protocolo. Ela controla quais tipos de dado são enviados criptografados.';

  @override
  String get e2ee_chat_settings_title =>
      'Configurações de criptografia para este chat';

  @override
  String get e2ee_chat_settings_override =>
      'Usando configurações específicas do chat.';

  @override
  String get e2ee_chat_settings_global => 'Herdando configurações globais.';

  @override
  String get e2ee_text_messages => 'Mensagens de texto';

  @override
  String get e2ee_attachments => 'Anexos (mídia/arquivos)';

  @override
  String get e2ee_override_hint =>
      'Para alterar para este chat — ative \"Sobrescrever\".';

  @override
  String get group_member_fallback => 'Participante';

  @override
  String get group_role_creator => 'Grupo creator';

  @override
  String get group_role_admin => 'Administrador';

  @override
  String group_total_count(Object count) {
    return 'Total: $count';
  }

  @override
  String get group_copy_invite_tooltip => 'Copiar invite link';

  @override
  String get group_add_member_tooltip => 'Adicionar member';

  @override
  String get group_invite_copied => 'Link de convite copiado';

  @override
  String group_copy_invite_error(Object error) {
    return 'Falha ao copiar link: $error';
  }

  @override
  String get group_demote_confirm => 'Remover direitos de admin?';

  @override
  String get group_promote_confirm => 'Tornar administrador?';

  @override
  String group_demote_body(Object name) {
    return '$name terá os direitos de admin removidos. O membro continuará no grupo como membro comum.';
  }

  @override
  String get group_demote_button => 'Remover direitos';

  @override
  String get group_promote_button => 'Promover';

  @override
  String get group_kick_confirm => 'Remover membro?';

  @override
  String get group_kick_button => 'Remover';

  @override
  String get group_member_kicked => 'Membro removed';

  @override
  String get group_badge_creator => 'CRIADOR';

  @override
  String get group_demote_action => 'Remover admin';

  @override
  String get group_promote_action => 'Tornar admin';

  @override
  String get group_kick_action => 'Remover do grupo';

  @override
  String group_contacts_load_error(Object error) {
    return 'Falha ao carregar contacts: $error';
  }

  @override
  String get group_add_members_title => 'Adicionar membros';

  @override
  String get group_search_contacts_hint => 'Buscar contatos';

  @override
  String get group_all_contacts_in_group =>
      'Todos os seus contatos já estão no grupo.';

  @override
  String get group_nobody_found => 'Ninguém encontrado.';

  @override
  String get group_user_fallback => 'Usuário';

  @override
  String get group_select_members => 'Selecionar members';

  @override
  String group_add_count(Object count) {
    return 'Adicionar ($count)';
  }

  @override
  String group_auth_error(Object error) {
    return 'Erro de autorização: $error';
  }

  @override
  String group_add_error(Object error) {
    return 'Falha ao adicionar members: $error';
  }

  @override
  String get add_contact_own_profile => 'Este é o seu próprio perfil';

  @override
  String get add_contact_qr_not_found => 'Perfil from QR code not found';

  @override
  String add_contact_qr_error(Object error) {
    return 'Falha ao ler o QR code: $error';
  }

  @override
  String get add_contact_not_allowed => 'Não é possível adicionar este usuário';

  @override
  String add_contact_save_error(Object error) {
    return 'Falha ao adicionar contact: $error';
  }

  @override
  String get add_contact_country_search => 'Buscar country or code';

  @override
  String get add_contact_sync_phone => 'Sincronizar com o telefone';

  @override
  String get add_contact_qr_button => 'Adicionar by QR code';

  @override
  String add_contact_load_error(Object error) {
    return 'Erro loading contact: $error';
  }

  @override
  String get add_contact_user_fallback => 'Usuário';

  @override
  String get add_contact_already_in_contacts => 'Já está nos contatos';

  @override
  String get add_contact_new => 'Novo contato';

  @override
  String get add_contact_unavailable => 'Indisponível';

  @override
  String get add_contact_scan_qr => 'Escanear QR code';

  @override
  String get add_contact_scan_hint =>
      'Aponte a câmera para um QR code de perfil do LighChat';

  @override
  String get auth_validate_name_min_length =>
      'Name must be pelo menos 2 caracteres';

  @override
  String get auth_validate_username_min_length =>
      'Nome de usuário must be pelo menos 3 caracteres';

  @override
  String get auth_validate_username_max_length =>
      'Nome de usuário must not exceed 30 caracteres';

  @override
  String get auth_validate_username_format =>
      'Nome de usuário contains invalid caracteres';

  @override
  String get auth_validate_phone_11_digits =>
      'Número de telefone must contain 11 digits';

  @override
  String get auth_validate_email_format => 'Digite um email válido';

  @override
  String get auth_validate_dob_invalid => 'Data de nascimento inválida';

  @override
  String get auth_validate_bio_max_length =>
      'Bio must not exceed 200 caracteres';

  @override
  String get auth_validate_password_min_length =>
      'Senha must be pelo menos 6 caracteres';

  @override
  String get auth_validate_passwords_mismatch => 'As senhas não coincidem';

  @override
  String get sticker_new_pack => 'Novo pacote…';

  @override
  String get sticker_select_image_or_gif => 'Selecionar an image or GIF';

  @override
  String sticker_send_error(Object error) {
    return 'Falha ao enviar: $error';
  }

  @override
  String get sticker_saved => 'Salvo to sticker pack';

  @override
  String get sticker_save_failed => 'Falha ao baixar or save GIF';

  @override
  String get sticker_tab_my => 'My';

  @override
  String get sticker_tab_shared => 'Compartilhados';

  @override
  String get sticker_no_packs => 'Não sticker packs. Create a new one.';

  @override
  String get sticker_shared_not_configured =>
      'Pacotes compartilhados não configurados';

  @override
  String get sticker_recent => 'RECENTES';

  @override
  String get sticker_gallery_description =>
      'Fotos, PNG, GIF do dispositivo — direto no chat';

  @override
  String get sticker_shared_unavailable =>
      'Pacotes compartilhados ainda não disponíveis';

  @override
  String get sticker_gif_search_hint => 'Buscar GIF…';

  @override
  String sticker_gif_searched(Object query) {
    return 'Buscado: $query';
  }

  @override
  String get sticker_gif_search_unavailable =>
      'Busca de GIFs temporariamente indisponível.';

  @override
  String get sticker_gif_nothing_found => 'Nada encontrado';

  @override
  String get sticker_gif_all => 'Todos';

  @override
  String get sticker_gif_animated => 'ANIMADAS';

  @override
  String get sticker_emoji_text_unavailable =>
      'Emoji em texto não está disponível para esta janela.';

  @override
  String get wallpaper_sender => 'Contato';

  @override
  String get wallpaper_incoming => 'Esta é uma mensagem recebida.';

  @override
  String get wallpaper_outgoing => 'Esta é uma mensagem enviada.';

  @override
  String get wallpaper_incoming_time => '11:40';

  @override
  String get wallpaper_outgoing_time => '11:41';

  @override
  String get wallpaper_system => 'Você alterou o plano de fundo do chat';

  @override
  String get wallpaper_you => 'Você';

  @override
  String get wallpaper_today => 'Hoje';

  @override
  String system_event_e2ee_enabled(Object epoch) {
    return 'Criptografia de ponta a ponta ativada (época da chave: $epoch)';
  }

  @override
  String get system_event_e2ee_disabled =>
      'Criptografia de ponta a ponta desativada';

  @override
  String get system_event_unknown => 'Sistema event';

  @override
  String get system_event_group_created => 'Grupo created';

  @override
  String system_event_member_added(Object name) {
    return '$name foi adicionado(a)';
  }

  @override
  String system_event_member_removed(Object name) {
    return '$name foi removido(a)';
  }

  @override
  String system_event_member_left(Object name) {
    return '$name saiu do grupo';
  }

  @override
  String system_event_name_changed(Object name) {
    return 'Nome alterado para \"$name\"';
  }

  @override
  String get image_editor_title => 'Editor';

  @override
  String get image_editor_undo => 'Desfazer';

  @override
  String get image_editor_clear => 'Limpar';

  @override
  String get image_editor_pen => 'Pincel';

  @override
  String get image_editor_text => 'Texto';

  @override
  String get image_editor_crop => 'Recortar';

  @override
  String get image_editor_rotate => 'Girar';

  @override
  String get location_title => 'Enviar location';

  @override
  String get location_loading => 'Carregando mapa…';

  @override
  String get location_send_button => 'Enviar';

  @override
  String get location_live_label => 'Ao vivo';

  @override
  String get location_error => 'Falha ao carregar map';

  @override
  String get location_no_permission => 'Não location access';

  @override
  String get group_member_admin => 'Admin';

  @override
  String get group_member_creator => 'Criador';

  @override
  String get group_member_member => 'Membro';

  @override
  String get group_member_open_chat => 'Mensagem';

  @override
  String get group_member_open_profile => 'Perfil';

  @override
  String get group_member_remove => 'Remover';

  @override
  String get durak_lobby_title => 'Durak';

  @override
  String get durak_lobby_new_game => 'Novo jogo';

  @override
  String get durak_lobby_decline => 'Recusar';

  @override
  String get durak_lobby_accept => 'Aceitar';

  @override
  String get durak_lobby_invite_sent => 'Convite enviado';

  @override
  String get voice_preview_cancel => 'Cancelar';

  @override
  String get voice_preview_send => 'Enviar';

  @override
  String get voice_preview_recorded => 'Gravada';

  @override
  String get voice_preview_playing => 'Reproduzindo…';

  @override
  String get voice_preview_paused => 'Pausada';

  @override
  String get group_avatar_camera => 'Câmera';

  @override
  String get group_avatar_gallery => 'Galeria';

  @override
  String get group_avatar_upload_error => 'Erro de upload';

  @override
  String get avatar_picker_title => 'Avatar';

  @override
  String get avatar_picker_camera => 'Câmera';

  @override
  String get avatar_picker_gallery => 'Galeria';

  @override
  String get avatar_picker_crop => 'Recortar';

  @override
  String get avatar_picker_save => 'Salvar';

  @override
  String get avatar_picker_remove => 'Remover avatar';

  @override
  String get avatar_picker_error => 'Falha ao carregar avatar';

  @override
  String get avatar_picker_crop_error => 'Erro ao recortar';

  @override
  String get webview_telegram_title => 'Entrar with Telegram';

  @override
  String get webview_telegram_loading => 'Carregando…';

  @override
  String get webview_telegram_error => 'Falha ao carregar page';

  @override
  String get webview_telegram_back => 'Voltar';

  @override
  String get webview_telegram_retry => 'Tentar de novo';

  @override
  String get webview_telegram_close => 'Fechar';

  @override
  String get webview_telegram_no_url => 'Não authorization URL provided';

  @override
  String get webview_yandex_title => 'Entrar with Yandex';

  @override
  String get webview_yandex_loading => 'Carregando…';

  @override
  String get webview_yandex_error => 'Falha ao carregar page';

  @override
  String get webview_yandex_back => 'Voltar';

  @override
  String get webview_yandex_retry => 'Tentar de novo';

  @override
  String get webview_yandex_close => 'Fechar';

  @override
  String get webview_yandex_no_url => 'Não authorization URL provided';

  @override
  String get google_profile_title => 'Complete seu perfil';

  @override
  String get google_profile_name => 'Nome';

  @override
  String get google_profile_username => 'Nome de usuário';

  @override
  String get google_profile_phone => 'Telefone';

  @override
  String get google_profile_email => 'Email';

  @override
  String get google_profile_dob => 'Data de nascimento';

  @override
  String get google_profile_bio => 'Sobre';

  @override
  String get google_profile_save => 'Salvar e continuar';

  @override
  String get google_profile_error => 'Falha ao salvar profile';

  @override
  String get system_event_e2ee_epoch_rotated => 'Criptografia key rotated';

  @override
  String system_event_e2ee_device_added(String actor, String device) {
    return '$actor adicionou o dispositivo \"$device\"';
  }

  @override
  String system_event_e2ee_device_revoked(String actor, String device) {
    return '$actor revogou o dispositivo \"$device\"';
  }

  @override
  String system_event_e2ee_fingerprint_changed(String actor) {
    return 'A impressão de segurança de $actor mudou';
  }

  @override
  String get system_event_game_lobby_created => 'Jogo lobby created';

  @override
  String get system_event_game_started => 'Jogo started';

  @override
  String get system_event_default_actor => 'Usuário';

  @override
  String get system_event_default_device => 'dispositivo';

  @override
  String get image_editor_add_caption => 'Adicionar caption...';

  @override
  String get image_editor_crop_failed => 'Falha ao recortar a imagem';

  @override
  String get image_editor_draw_hint =>
      'Modo de desenho: arraste sobre a imagem';

  @override
  String get image_editor_crop_title => 'Recortar';

  @override
  String get location_preview_title => 'Localização';

  @override
  String get location_preview_accuracy_unknown => 'Precisão: —';

  @override
  String location_preview_accuracy_meters(String meters) {
    return 'Precisão: ~$meters m';
  }

  @override
  String location_preview_accuracy_km(String km) {
    return 'Precisão: ~$km km';
  }

  @override
  String get group_member_profile_default_name => 'Membro';

  @override
  String get group_member_profile_dm => 'Enviar direct message';

  @override
  String get group_member_profile_dm_hint =>
      'Abrir um chat direto com este membro';

  @override
  String group_member_profile_dm_failed(Object error) {
    return 'Falha ao abrir o chat direto: $error';
  }

  @override
  String get conversation_game_lobby_unavailable =>
      'Jogo unavailable or was deleted';

  @override
  String get conversation_game_lobby_back => 'Voltar';

  @override
  String get conversation_game_lobby_waiting => 'Aguardando oponente to join…';

  @override
  String get conversation_game_lobby_start_game => 'Iniciar game';

  @override
  String get conversation_game_lobby_waiting_short => 'Aguardando…';

  @override
  String get conversation_game_lobby_ready => 'Pronto';

  @override
  String get voice_preview_trim_confirm_title =>
      'Manter apenas o trecho selecionado?';

  @override
  String get voice_preview_trim_confirm_body =>
      'Tudo, exceto o trecho selecionado, será excluído. A gravação continuará logo após pressionar o botão.';

  @override
  String get voice_preview_continue => 'Continuar';

  @override
  String get voice_preview_continue_recording => 'Continuar recording';

  @override
  String get group_avatar_change_short => 'Alterar';

  @override
  String get avatar_picker_cancel => 'Cancelar';

  @override
  String get avatar_picker_choose => 'Escolher avatar';

  @override
  String get avatar_picker_delete_photo => 'Excluir photo';

  @override
  String get avatar_picker_loading => 'Carregando…';

  @override
  String get avatar_picker_choose_avatar => 'Escolher avatar';

  @override
  String get avatar_picker_change_avatar => 'Alterar avatar';

  @override
  String get avatar_picker_remove_tooltip => 'Remover';

  @override
  String get telegram_sign_in_title => 'Entrar via Telegram';

  @override
  String get telegram_sign_in_open_in_browser => 'Abrir in browser';

  @override
  String get telegram_sign_in_open_telegram_failed =>
      'Falha ao abrir o Telegram. Por favor, instale o app do Telegram.';

  @override
  String get telegram_sign_in_page_load_error => 'Erro ao carregar a página';

  @override
  String get telegram_sign_in_login_error => 'Erro ao entrar com o Telegram.';

  @override
  String get telegram_sign_in_firebase_not_ready => 'Firebase não está pronto.';

  @override
  String get telegram_sign_in_browser_failed => 'Falha ao abrir o navegador.';

  @override
  String telegram_sign_in_login_failed(Object error) {
    return 'Falha ao entrar: $error';
  }

  @override
  String get yandex_sign_in_title => 'Yandex';

  @override
  String get yandex_sign_in_open_in_browser => 'Abrir in browser';

  @override
  String get yandex_sign_in_page_load_error => 'Erro ao carregar a página';

  @override
  String get yandex_sign_in_login_error => 'Erro ao entrar com o Yandex.';

  @override
  String get yandex_sign_in_firebase_not_ready => 'Firebase não está pronto.';

  @override
  String get yandex_sign_in_browser_failed => 'Falha ao abrir o navegador.';

  @override
  String yandex_sign_in_login_failed(Object error) {
    return 'Falha ao entrar: $error';
  }

  @override
  String get google_complete_title => 'Concluir cadastro';

  @override
  String get google_complete_subtitle =>
      'Após entrar com o Google, preencha seu perfil como na versão web.';

  @override
  String get google_complete_name_label => 'Nome';

  @override
  String get google_complete_username_label => 'Nome de usuário';

  @override
  String get google_complete_phone_label => 'Telefone';

  @override
  String get google_complete_email_label => 'Email';

  @override
  String get google_complete_email_hint => 'voce@exemplo.com';

  @override
  String get google_complete_dob_label => 'Data de nascimento';

  @override
  String get google_complete_bio_label =>
      'Sobre (up to 200 caracteres, optional)';

  @override
  String get google_complete_save => 'Salvar e continuar';

  @override
  String get google_complete_back => 'Voltar para entrar';

  @override
  String get game_error_defense_not_beat =>
      'Esta carta não bate a carta do ataque';

  @override
  String get game_error_attacker_first => 'The attacker moves first';

  @override
  String get game_error_defender_no_attack =>
      'O defensor não pode atacar agora';

  @override
  String get game_error_not_allowed_throwin =>
      'Você não pode jogar extras nesta rodada';

  @override
  String get game_error_throwin_not_turn =>
      'Outro jogador está jogando extras agora';

  @override
  String get game_error_rank_not_allowed =>
      'Você só pode jogar uma carta do mesmo valor';

  @override
  String get game_error_cannot_throw_in =>
      'Não dá para jogar mais cartas extras';

  @override
  String get game_error_card_not_in_hand =>
      'Esta carta não está mais na sua mão';

  @override
  String get game_error_already_defended => 'Esta carta já foi defendida';

  @override
  String get game_error_bad_attack_index =>
      'Selecionar an attacking card to defend against';

  @override
  String get game_error_only_defender => 'Outro jogador está defendendo agora';

  @override
  String get game_error_defender_taking => 'O defensor já está pegando cartas';

  @override
  String get game_error_game_not_active => 'O jogo não está mais ativo';

  @override
  String get game_error_not_in_lobby => 'O lobby já começou';

  @override
  String get game_error_game_already_active => 'O jogo já começou';

  @override
  String get game_error_active_exists => 'Já existe um jogo ativo neste chat';

  @override
  String get game_error_round_pending => 'Finish the contested move first';

  @override
  String get game_error_rematch_failed =>
      'Failed to prepare rematch. Tente novamente';

  @override
  String get game_error_unauthenticated => 'Você precisa entrar';

  @override
  String get game_error_permission_denied =>
      'Esta ação não está disponível para você';

  @override
  String get game_error_invalid_argument => 'Invalid move';

  @override
  String get game_error_precondition => 'A jogada não está disponível agora';

  @override
  String get game_error_server => 'Failed to make move. Tente novamente';

  @override
  String get reply_sticker => 'Figurinha';

  @override
  String get reply_gif => 'GIF';

  @override
  String get reply_video_circle => 'Vídeo circle';

  @override
  String get reply_voice_message => 'Mensagem de voz';

  @override
  String get reply_video => 'Vídeo';

  @override
  String get reply_photo => 'Foto';

  @override
  String get reply_file => 'Arquivo';

  @override
  String get reply_location => 'Location';

  @override
  String get reply_poll => 'Poll';

  @override
  String get reply_link => 'Link';

  @override
  String get reply_message => 'Mensagem';

  @override
  String get reply_sender_you => 'You';

  @override
  String get reply_sender_member => 'Membro';

  @override
  String get call_format_today => 'Hoje';

  @override
  String get call_format_yesterday => 'Ontem';

  @override
  String get call_format_second_short => 's';

  @override
  String get call_format_minute_short => 'm';

  @override
  String get call_format_hour_short => 'h';

  @override
  String get call_format_day_short => 'd';

  @override
  String get call_month_january => 'January';

  @override
  String get call_month_february => 'February';

  @override
  String get call_month_march => 'March';

  @override
  String get call_month_april => 'April';

  @override
  String get call_month_may => 'May';

  @override
  String get call_month_june => 'June';

  @override
  String get call_month_july => 'July';

  @override
  String get call_month_august => 'August';

  @override
  String get call_month_september => 'September';

  @override
  String get call_month_october => 'October';

  @override
  String get call_month_november => 'November';

  @override
  String get call_month_december => 'December';

  @override
  String get push_incoming_call => 'Incoming call';

  @override
  String get push_incoming_video_call => 'Chamada de vídeo recebida';

  @override
  String get push_new_message => 'Nova mensagem';

  @override
  String get push_channel_calls => 'Chamadas';

  @override
  String get push_channel_messages => 'Mensagens';

  @override
  String contacts_years_one(Object count) {
    return '$count year';
  }

  @override
  String contacts_years_few(Object count) {
    return '$count years';
  }

  @override
  String contacts_years_many(Object count) {
    return '$count years';
  }

  @override
  String contacts_years_other(Object count) {
    return '$count years';
  }

  @override
  String get durak_entry_single_game => 'Single game';

  @override
  String get durak_entry_finish_game_tooltip => 'Finish game';

  @override
  String get durak_entry_tournament_games_dialog_title =>
      'How many games in tournament?';

  @override
  String get durak_entry_cancel => 'Cancelar';

  @override
  String get durak_entry_create => 'Create';

  @override
  String video_editor_load_failed(Object error) {
    return 'Falha ao carregar video: $error';
  }

  @override
  String video_editor_process_failed(Object error) {
    return 'Failed to process video: $error';
  }

  @override
  String video_editor_duration(Object duration) {
    return 'Duration: $duration';
  }

  @override
  String get video_editor_brush => 'Brush';

  @override
  String get video_editor_caption_hint => 'Adicionar caption...';

  @override
  String get share_location_title => 'Share location';

  @override
  String get share_location_how => 'Sharing method';

  @override
  String get share_location_cancel => 'Cancelar';

  @override
  String get share_location_send => 'Enviar';

  @override
  String get photo_source_gallery => 'Galeria';

  @override
  String get photo_source_take_photo => 'Pegar photo';

  @override
  String get photo_source_record_video => 'Gravar video';

  @override
  String get video_attachment_media_kind => 'video';

  @override
  String get video_attachment_title => 'Vídeo';

  @override
  String get video_attachment_playback_error =>
      'Não foi possível reproduzir o vídeo. Verifique o link e a conexão.';

  @override
  String get location_card_broadcast_ended_mine =>
      'Transmissão de localização encerrada. A outra pessoa não pode mais ver sua localização atual.';

  @override
  String get location_card_broadcast_ended_other =>
      'A transmissão de localização deste contato terminou. A posição atual está indisponível.';

  @override
  String get location_card_title => 'Location';

  @override
  String location_card_accuracy(Object meters) {
    return '±$meters m';
  }

  @override
  String get link_webview_copy_tooltip => 'Copiar link';

  @override
  String get link_webview_copied_snackbar => 'Link copied';

  @override
  String get link_webview_open_browser_tooltip => 'Abrir in browser';

  @override
  String get hold_record_pause => 'Paused';

  @override
  String get hold_record_release_cancel => 'Release to cancel';

  @override
  String get hold_record_slide_hints => 'Slide left — cancel · Up — pause';

  @override
  String get e2ee_badge_loading => 'Loading fingerprint…';

  @override
  String e2ee_badge_error(Object error) {
    return 'Failed to get fingerprint: $error';
  }

  @override
  String get e2ee_badge_label => 'E2EE Fingerprint';

  @override
  String e2ee_badge_label_with_user(Object user) {
    return 'E2EE Fingerprint • $user';
  }

  @override
  String e2ee_badge_devices(Object count) {
    return '$count dev.';
  }

  @override
  String get composer_link_cancel => 'Cancelar';

  @override
  String message_search_results_count(Object count) {
    return 'SEARCH RESULTS: $count';
  }

  @override
  String get message_search_not_found => 'NOTHING FOUND';

  @override
  String get message_search_participant_fallback => 'Participant';

  @override
  String get wallpaper_purple => 'Purple';

  @override
  String get wallpaper_pink => 'Pink';

  @override
  String get wallpaper_blue => 'Blue';

  @override
  String get wallpaper_green => 'Green';

  @override
  String get wallpaper_sunset => 'Sunset';

  @override
  String get wallpaper_tender => 'Tender';

  @override
  String get wallpaper_lime => 'Lime';

  @override
  String get wallpaper_graphite => 'Graphite';

  @override
  String get avatar_crop_title => 'Adjust avatar';

  @override
  String get avatar_crop_hint =>
      'Arraste e dê zoom — o círculo aparece nas listas e mensagens; o frame completo fica para o perfil.';

  @override
  String get avatar_crop_cancel => 'Cancelar';

  @override
  String get avatar_crop_reset => 'Restaurar';

  @override
  String get avatar_crop_save => 'Salvar';

  @override
  String get meeting_entry_connecting => 'Conectando to meeting…';

  @override
  String meeting_entry_auth_failed(Object error) {
    return 'Falha ao entrar: $error';
  }

  @override
  String get meeting_entry_participant_fallback => 'Participant';

  @override
  String get meeting_entry_back => 'Voltar';

  @override
  String get meeting_chat_copy => 'Copiar';

  @override
  String get meeting_chat_edit => 'Editar';

  @override
  String get meeting_chat_delete => 'Excluir';

  @override
  String get meeting_chat_deleted => 'Mensagem deleted';

  @override
  String get meeting_chat_edited_mark => '• edited';

  @override
  String get e2ee_decrypt_image_failed => 'Failed to decrypt image';

  @override
  String get e2ee_decrypt_video_failed => 'Failed to decrypt video';

  @override
  String get e2ee_decrypt_audio_failed => 'Failed to decrypt audio';

  @override
  String get e2ee_decrypt_attachment_failed => 'Failed to decrypt attachment';

  @override
  String get search_preview_attachment => 'Attachment';

  @override
  String get search_preview_location => 'Location';

  @override
  String get search_preview_message => 'Mensagem';

  @override
  String get outbox_attachment_singular => 'Attachment';

  @override
  String outbox_attachments_count(int count) {
    return 'Attachments ($count)';
  }

  @override
  String get outbox_chat_unavailable => 'Serviço de chat indisponível';

  @override
  String outbox_encryption_error(String code) {
    return 'Criptografia: $code';
  }

  @override
  String get nav_chats => 'Chats';

  @override
  String get nav_contacts => 'Contatos';

  @override
  String get nav_meetings => 'Reuniões';

  @override
  String get nav_calls => 'Chamadas';

  @override
  String get e2ee_media_decrypt_failed_image => 'Failed to decrypt image';

  @override
  String get e2ee_media_decrypt_failed_video => 'Failed to decrypt video';

  @override
  String get e2ee_media_decrypt_failed_audio => 'Failed to decrypt audio';

  @override
  String get e2ee_media_decrypt_failed_attachment =>
      'Failed to decrypt attachment';

  @override
  String get chat_search_snippet_attachment => 'Attachment';

  @override
  String get chat_search_snippet_location => 'Location';

  @override
  String get chat_search_snippet_message => 'Mensagem';

  @override
  String get bottom_nav_chats => 'Chats';

  @override
  String get bottom_nav_contacts => 'Contatos';

  @override
  String get bottom_nav_meetings => 'Reuniões';

  @override
  String get bottom_nav_calls => 'Chamadas';

  @override
  String get chat_list_swipe_folders => 'FOLDERS';

  @override
  String get chat_list_swipe_clear => 'CLEAR';

  @override
  String get chat_list_swipe_delete => 'DELETE';

  @override
  String get composer_editing_title => 'EDITING MESSAGE';

  @override
  String get composer_editing_cancel_tooltip => 'Cancelar editing';

  @override
  String get composer_formatting_title => 'FORMATTING';

  @override
  String get composer_link_preview_loading => 'Loading preview…';

  @override
  String get composer_link_preview_hide_tooltip => 'Ocultar preview';

  @override
  String get chat_invite_button => 'Invite';

  @override
  String get forward_preview_unknown_sender => 'Unknown';

  @override
  String get forward_preview_attachment => 'Attachment';

  @override
  String get forward_preview_message => 'Mensagem';

  @override
  String get chat_mention_no_matches => 'Não matches';

  @override
  String get live_location_sharing =>
      'Você está compartilhando sua localização';

  @override
  String get live_location_stop => 'Parar';

  @override
  String get chat_message_deleted => 'Mensagem deleted';

  @override
  String get profile_qr_share => 'Share';

  @override
  String get shared_location_open_browser_tooltip => 'Abrir in browser';

  @override
  String get reply_preview_message_fallback => 'Mensagem';

  @override
  String get video_circle_media_kind => 'video';

  @override
  String reactions_rated_count(int count) {
    return 'Reacted: $count';
  }

  @override
  String reactions_today_time(String time) {
    return 'Hoje, $time';
  }

  @override
  String get durak_create_timer_subtitle => 'Padrão 15 segundos';

  @override
  String get dm_game_banner_active => 'Durak game in progress';

  @override
  String get dm_game_banner_created => 'Durak game created';

  @override
  String get chat_folder_favorites => 'Favorites';

  @override
  String get chat_folder_new => 'New';

  @override
  String get contact_profile_user_fallback => 'User';

  @override
  String contact_profile_error(String error) {
    return 'Erro: $error';
  }

  @override
  String get conversation_threads_loading_title => 'Tópicos';

  @override
  String get theme_label_light => 'Light';

  @override
  String get theme_label_dark => 'Dark';

  @override
  String get theme_label_auto => 'Auto';

  @override
  String get chat_draft_reply_fallback => 'Responder';

  @override
  String get mention_default_label => 'Membro';

  @override
  String get contacts_fallback_name => 'Contato';

  @override
  String get sticker_pack_default_name => 'My pack';

  @override
  String get profile_error_phone_taken =>
      'Este número de telefone já está cadastrado. Por favor, use outro número.';

  @override
  String get profile_error_email_taken =>
      'Este email já está em uso. Por favor, use outro endereço.';

  @override
  String get profile_error_username_taken =>
      'Este nome de usuário já está em uso. Por favor, escolha outro.';

  @override
  String get e2ee_banner_default_context => 'Mensagem';

  @override
  String e2ee_banner_encrypted_chat_web_only(String prefix) {
    return '$prefix para um chat criptografado só pode ser enviado pelo cliente web por enquanto.';
  }

  @override
  String get chat_attachment_decrypt_error => 'Failed to decrypt attachment';

  @override
  String get mention_fallback_label => 'member';

  @override
  String get mention_fallback_label_capitalized => 'Membro';

  @override
  String get meeting_speaking_label => 'Speaking';

  @override
  String meeting_local_you_suffix(String name) {
    return '$name (You)';
  }

  @override
  String get video_crop_title => 'Crop';

  @override
  String video_crop_load_error(String error) {
    return 'Falha ao carregar video: $error';
  }

  @override
  String get gif_section_recent => 'RECENTES';

  @override
  String get gif_section_trending => 'TRENDING';

  @override
  String get auth_create_account_title => 'Create Account';

  @override
  String yandex_sign_in_yandex_error(String error) {
    return 'Yandex: $error';
  }

  @override
  String get call_status_missed => 'Missed';

  @override
  String get call_status_cancelled => 'Cancelled';

  @override
  String get call_status_ended => 'Ended';

  @override
  String get presence_offline => 'Offline';

  @override
  String get presence_online => 'Online';

  @override
  String get dm_title_fallback => 'Chat';

  @override
  String get dm_title_partner_fallback => 'Contato';

  @override
  String get group_title_fallback => 'Chat em grupo';

  @override
  String get block_call_viewer_blocked =>
      'Você bloqueou este usuário. Chamada indisponível — desbloqueie em Perfil → Bloqueados.';

  @override
  String get block_call_partner_blocked =>
      'Este usuário restringiu a comunicação com você. Chamada indisponível.';

  @override
  String get block_call_unavailable => 'Chamada unavailable.';

  @override
  String get block_composer_viewer_blocked =>
      'Você bloqueou este usuário. Envio indisponível — desbloqueie em Perfil → Bloqueados.';

  @override
  String get block_composer_partner_blocked =>
      'Este usuário restringiu a comunicação com você. Envio indisponível.';

  @override
  String get forward_group_fallback => 'Grupo';

  @override
  String get forward_unknown_user => 'Unknown';

  @override
  String get live_location_once => 'Apenas uma vez (somente esta mensagem)';

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
  String get live_location_1day => '1 dia';

  @override
  String get live_location_forever => 'Forever (until I turn it off)';

  @override
  String get e2ee_send_too_many_files =>
      'Too many attachments for encrypted send: maximum 5 files per message.';

  @override
  String get e2ee_send_too_large =>
      'Total attachment size too large: maximum 96 MB for one encrypted message.';

  @override
  String get presence_last_seen_prefix => 'Visto por último ';

  @override
  String get presence_less_than_minute_ago => 'less than a minuto ago';

  @override
  String get presence_yesterday => 'yesterday';

  @override
  String get dm_fallback_title => 'Chat';

  @override
  String get dm_fallback_partner => 'Contato';

  @override
  String get group_fallback_title => 'Chat em grupo';

  @override
  String get block_send_viewer_blocked =>
      'Você bloqueou este usuário. Envio indisponível — desbloqueie em Perfil → Bloqueados.';

  @override
  String get block_send_partner_blocked =>
      'Este usuário restringiu a comunicação com você. Envio indisponível.';

  @override
  String get mention_fallback_name => 'Membro';

  @override
  String get profile_conflict_phone =>
      'Este número de telefone já está cadastrado. Por favor, use outro número.';

  @override
  String get profile_conflict_email =>
      'Este email já está em uso. Por favor, use outro endereço.';

  @override
  String get profile_conflict_username =>
      'Este nome de usuário já está em uso. Por favor, escolha outro.';

  @override
  String get mention_fallback_participant => 'Participant';

  @override
  String get sticker_gif_recent => 'RECENTES';

  @override
  String get meeting_screen_sharing => 'Screen';

  @override
  String get meeting_speaking => 'Speaking';

  @override
  String auth_sign_in_failed(Object error) {
    return 'Sign-in failed: $error';
  }

  @override
  String yandex_error_prefix(Object error) {
    return 'Yandex: $error';
  }

  @override
  String auth_error_prefix(Object error) {
    return 'Auth error: $error';
  }

  @override
  String presence_minutes_ago(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutos ago',
      one: 'a minuto ago',
    );
    return '$_temp0';
  }

  @override
  String presence_hours_ago(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count horas ago',
      one: 'an hora ago',
    );
    return '$_temp0';
  }

  @override
  String presence_days_ago(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dias ago',
      one: 'a dia ago',
    );
    return '$_temp0';
  }

  @override
  String presence_months_ago(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count meses ago',
      one: 'a mês ago',
    );
    return '$_temp0';
  }

  @override
  String presence_years_months_ago(int years, int months) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years anos',
      one: '1 ano',
    );
    String _temp1 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$months meses atrás',
      one: '1 mês atrás',
    );
    return '$_temp0 $_temp1';
  }

  @override
  String presence_years_ago(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count years ago',
      one: 'a year ago',
    );
    return '$_temp0';
  }

  @override
  String get wallpaper_gradient_purple => 'Purple';

  @override
  String get wallpaper_gradient_pink => 'Pink';

  @override
  String get wallpaper_gradient_blue => 'Blue';

  @override
  String get wallpaper_gradient_green => 'Green';

  @override
  String get wallpaper_gradient_sunset => 'Sunset';

  @override
  String get wallpaper_gradient_gentle => 'Gentle';

  @override
  String get wallpaper_gradient_lime => 'Lime';

  @override
  String get wallpaper_gradient_graphite => 'Graphite';

  @override
  String get sticker_tab_recent => 'RECENTES';

  @override
  String get block_call_you_blocked =>
      'Você bloqueou este usuário. Chamada indisponível — desbloqueie em Perfil → Bloqueados.';

  @override
  String get block_call_they_blocked =>
      'Este usuário restringiu a comunicação com você. Chamada indisponível.';

  @override
  String get block_call_generic => 'Chamada unavailable.';

  @override
  String get block_send_you_blocked =>
      'Você bloqueou este usuário. Envio indisponível — desbloqueie em Perfil → Bloqueados.';

  @override
  String get block_send_they_blocked =>
      'Este usuário restringiu a comunicação com você. Envio indisponível.';

  @override
  String get forward_unknown_fallback => 'Unknown';

  @override
  String get dm_title_chat => 'Chat';

  @override
  String get dm_title_partner => 'Partner';

  @override
  String get dm_title_group => 'Chat em grupo';

  @override
  String get e2ee_too_many_attachments =>
      'Too many attachments for encrypted sending: maximum 5 files per message.';

  @override
  String get e2ee_total_size_exceeded =>
      'Total attachment size too large: maximum 96 MB per encrypted message.';

  @override
  String yandex_sign_in_error_prefix(String error) {
    return 'Yandex: $error';
  }

  @override
  String get meeting_participant_screen => 'Screen';

  @override
  String get meeting_participant_speaking => 'Speaking';

  @override
  String get nav_error_title => 'Navigation error';

  @override
  String get nav_error_invalid_secret_compose =>
      'Invalid secret compose navigation';

  @override
  String get sign_in_title => 'Entrar';

  @override
  String get sign_in_firebase_ready =>
      'Firebase inicializado. Você pode entrar.';

  @override
  String get sign_in_firebase_not_ready =>
      'O Firebase não está pronto. Verifique os logs e o firebase_options.dart.';

  @override
  String get sign_in_continue => 'Continuar';

  @override
  String get sign_in_anonymously => 'Entrar anonymously';

  @override
  String sign_in_auth_error(String error) {
    return 'Auth error: $error';
  }

  @override
  String generic_error(String error) {
    return 'Erro: $error';
  }

  @override
  String get storage_label_video => 'Vídeo';

  @override
  String get storage_label_photo => 'Foto';

  @override
  String get storage_label_files => 'Arquivos';

  @override
  String get storage_label_other => 'Other';

  @override
  String storage_label_draft(String key) {
    return 'Draft · $key';
  }

  @override
  String get storage_label_offline_snapshot => 'Offline chat list snapshot';

  @override
  String storage_label_profile_cache(String name) {
    return 'Perfil cache · $name';
  }

  @override
  String get call_mini_end => 'End call';

  @override
  String get animation_quality_lite => 'Lite';

  @override
  String get animation_quality_balanced => 'Balanced';

  @override
  String get animation_quality_cinematic => 'Cinematic';

  @override
  String get crop_aspect_original => 'Original';

  @override
  String get crop_aspect_square => 'Square';

  @override
  String get push_notification_title => 'Allow notifications';

  @override
  String get push_notification_rationale =>
      'O app precisa de notificações para chamadas recebidas.';

  @override
  String get push_notification_required =>
      'Ativar notifications to display incoming calls.';

  @override
  String get push_notification_grant => 'Allow';

  @override
  String get push_call_accept => 'Aceitar';

  @override
  String get push_call_decline => 'Recusar';

  @override
  String get push_channel_incoming_calls => 'Incoming calls';

  @override
  String get push_channel_missed_calls => 'Missed calls';

  @override
  String get push_channel_messages_desc => 'Novas mensagens nos chats';

  @override
  String get push_channel_silent => 'Silent messages';

  @override
  String get push_channel_silent_desc => 'Push without sound';

  @override
  String get push_caller_unknown => 'Someone';

  @override
  String get outbox_attachment_single => 'Attachment';

  @override
  String outbox_attachment_count(int count) {
    return 'Attachments ($count)';
  }

  @override
  String get bottom_nav_label_chats => 'Chats';

  @override
  String get bottom_nav_label_contacts => 'Contatos';

  @override
  String get bottom_nav_label_conferences => 'Conferências';

  @override
  String get bottom_nav_label_calls => 'Chamadas';

  @override
  String get welcomeBubbleTitle => 'Bem-vindo ao LighChat';

  @override
  String get welcomeBubbleSubtitle => 'O farol está aceso';

  @override
  String get welcomeSkip => 'Skip';

  @override
  String get welcomeReplayDebugTile => 'Replay welcome animation (debug)';

  @override
  String get sticker_scope_library => 'Library';

  @override
  String get sticker_library_search_hint => 'Buscar stickers...';

  @override
  String get account_menu_energy_saving => 'Power saving';

  @override
  String get energy_saving_title => 'Economia de energia';

  @override
  String get energy_saving_section_mode => 'Power saving mode';

  @override
  String get energy_saving_section_resource_heavy => 'Resource-heavy processes';

  @override
  String get energy_saving_threshold_off => 'Desativado';

  @override
  String get energy_saving_threshold_always => 'Ativado';

  @override
  String get energy_saving_threshold_off_full => 'Never';

  @override
  String get energy_saving_threshold_always_full => 'Always';

  @override
  String energy_saving_threshold_at(int percent) {
    return 'Quando a bateria estiver abaixo de $percent%';
  }

  @override
  String get energy_saving_hint_off =>
      'Resource-heavy effects are never auto-disabled.';

  @override
  String get energy_saving_hint_always =>
      'Os efeitos pesados ficam sempre desativados, independentemente do nível da bateria.';

  @override
  String energy_saving_hint_threshold(int percent) {
    return 'Desativar automaticamente todos os processos pesados quando a bateria cair abaixo de $percent%.';
  }

  @override
  String energy_saving_current_battery(int percent) {
    return 'Current battery: $percent%';
  }

  @override
  String get energy_saving_active_now => 'mode is active';

  @override
  String get energy_saving_active_threshold =>
      'A bateria atingiu o limite — todo efeito abaixo fica temporariamente desativado.';

  @override
  String get energy_saving_active_system =>
      'Economia de energia do sistema está ativa — todo efeito abaixo fica temporariamente desativado.';

  @override
  String get energy_saving_autoplay_video_title => 'Auto-reprodução de vídeo';

  @override
  String get energy_saving_autoplay_video_subtitle =>
      'Reproduzir e repetir automaticamente mensagens em vídeo e vídeos nos chats.';

  @override
  String get energy_saving_autoplay_gif_title => 'Auto-reprodução de GIF';

  @override
  String get energy_saving_autoplay_gif_subtitle =>
      'Reproduzir e repetir GIFs automaticamente nos chats e no teclado.';

  @override
  String get energy_saving_animated_stickers_title => 'Animadas stickers';

  @override
  String get energy_saving_animated_stickers_subtitle =>
      'Looped sticker animations and full-screen Premium sticker effects.';

  @override
  String get energy_saving_animated_emoji_title => 'Emoji animado';

  @override
  String get energy_saving_animated_emoji_subtitle =>
      'Animação de emoji em loop em mensagens, reações e status.';

  @override
  String get energy_saving_interface_animations_title =>
      'Animações da interface';

  @override
  String get energy_saving_interface_animations_subtitle =>
      'Efeitos e animações que tornam o LighChat mais fluido e expressivo.';

  @override
  String get energy_saving_media_preload_title => 'Pré-carregar mídia';

  @override
  String get energy_saving_media_preload_subtitle =>
      'Começar a baixar arquivos de mídia ao abrir a lista de chats.';

  @override
  String get energy_saving_background_update_title => 'Plano de fundo update';

  @override
  String get energy_saving_background_update_subtitle =>
      'Quick chat updates when switching between apps.';

  @override
  String get chat_list_item_sender_you => 'Você';

  @override
  String get chat_preview_message => 'Mensagem';

  @override
  String get chat_preview_sticker => 'Figurinha';

  @override
  String get chat_preview_attachment => 'Anexo';
}
