import 'dart:async';
import 'package:nyxx/nyxx.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../env/env.dart';

/// État de la connexion Discord
enum DiscordConnectionState { disconnected, connecting, connected, error }

/// Classe représentant un message Discord reçu
class DiscordMessageData {
  final String id;
  final String content;
  final String authorName;
  final String channelName;
  final DateTime timestamp;
  final String? avatarUrl;

  const DiscordMessageData({
    required this.id,
    required this.content,
    required this.authorName,
    required this.channelName,
    required this.timestamp,
    this.avatarUrl,
  });
}

/// Classe pour gérer l'état de Discord
class DiscordState {
  final DiscordConnectionState connectionState;
  final NyxxGateway? client;
  final String? errorMessage;
  final User? currentUser;
  final List<DiscordMessageData> messages;

  const DiscordState({
    required this.connectionState,
    this.client,
    this.errorMessage,
    this.currentUser,
    this.messages = const [],
  });

  DiscordState copyWith({
    DiscordConnectionState? connectionState,
    NyxxGateway? client,
    String? errorMessage,
    User? currentUser,
    List<DiscordMessageData>? messages,
  }) {
    return DiscordState(
      connectionState: connectionState ?? this.connectionState,
      client: client ?? this.client,
      errorMessage: errorMessage ?? this.errorMessage,
      currentUser: currentUser ?? this.currentUser,
      messages: messages ?? this.messages,
    );
  }
}

/// Notifier pour gérer le client Discord
class DiscordNotifier extends StateNotifier<DiscordState> {
  StreamSubscription<MessageCreateEvent>? _messageSubscription;

  DiscordNotifier()
    : super(
        const DiscordState(
          connectionState: DiscordConnectionState.disconnected,
        ),
      );

  /// Connexion à Discord
  Future<void> connect() async {
    try {
      state = state.copyWith(
        connectionState: DiscordConnectionState.connecting,
        errorMessage: null,
      );

      final client = await Nyxx.connectGateway(
        Env.discordBotToken,
        GatewayIntents.allUnprivileged | GatewayIntents.messageContent,
        options: GatewayClientOptions(plugins: [logging, cliIntegration]),
      );

      // Récupérer les informations de l'utilisateur actuel
      final user = await client.users.fetchCurrentUser();

      state = state.copyWith(
        connectionState: DiscordConnectionState.connected,
        client: client,
        currentUser: user,
        errorMessage: null,
        messages: [], // Réinitialiser les messages
      );

      // Écouter les nouveaux messages
      _listenToMessages(client);

      print('✅ Connecté à Discord en tant que ${user.username}');
    } catch (e) {
      state = state.copyWith(
        connectionState: DiscordConnectionState.error,
        errorMessage: e.toString(),
      );
      print('❌ Erreur de connexion: $e');
    }
  }

  /// Écouter les messages Discord
  void _listenToMessages(NyxxGateway client) {
    _messageSubscription?.cancel();
    _messageSubscription = client.onMessageCreate.listen((event) async {
      try {
        final message = event.message;

        // Ne pas afficher les messages du bot lui-même
        if (message.author.id == state.currentUser?.id) {
          return;
        }

        // Récupérer le nom du canal
        String channelName = 'Canal inconnu';
        try {
          final channel = await client.channels.fetch(message.channelId);
          if (channel is GuildChannel) {
            channelName = '#${channel.name}';
          } else if (channel is DmChannel) {
            channelName = 'DM';
          }
        } catch (e) {
          print('⚠️ Impossible de récupérer le nom du canal: $e');
        }

        // Créer l'objet message
        final messageData = DiscordMessageData(
          id: message.id.toString(),
          content: message.content,
          authorName: message.author.username,
          channelName: channelName,
          timestamp: message.timestamp,
          avatarUrl: message.author.avatar?.url.toString(),
        );

        // Ajouter le message à la liste (max 100 messages)
        final updatedMessages = [messageData, ...state.messages];
        if (updatedMessages.length > 100) {
          updatedMessages.removeLast();
        }

        state = state.copyWith(messages: updatedMessages);

        print(
          '📩 Message reçu de ${message.author.username}: ${message.content}',
        );
      } catch (e) {
        print('❌ Erreur lors du traitement du message: $e');
      }
    });
  }

  /// Déconnexion de Discord
  Future<void> disconnect() async {
    try {
      _messageSubscription?.cancel();
      await state.client?.close();
      state = const DiscordState(
        connectionState: DiscordConnectionState.disconnected,
      );
      print('🔌 Déconnecté de Discord');
    } catch (e) {
      print('❌ Erreur lors de la déconnexion: $e');
    }
  }

  /// Effacer les messages
  void clearMessages() {
    state = state.copyWith(messages: []);
  }

  /// Envoyer un message dans un canal
  Future<void> sendMessage(Snowflake channelId, String content) async {
    try {
      final client = state.client;
      if (client == null) {
        throw Exception('Client Discord non connecté');
      }

      final channel = await client.channels.fetch(channelId);
      if (channel is! TextChannel) {
        throw Exception('Le canal n\'est pas un canal textuel');
      }

      await channel.sendMessage(MessageBuilder(content: content));
      print('📨 Message envoyé: $content');
    } catch (e) {
      print('❌ Erreur lors de l\'envoi du message: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    state.client?.close();
    super.dispose();
  }
}

/// Provider pour le service Discord
final discordProvider = StateNotifierProvider<DiscordNotifier, DiscordState>((
  ref,
) {
  return DiscordNotifier();
});
