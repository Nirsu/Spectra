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
  final String channelId;
  final String channelName;
  final DateTime timestamp;
  final String? avatarUrl;

  const DiscordMessageData({
    required this.id,
    required this.content,
    required this.authorName,
    required this.channelId,
    required this.channelName,
    required this.timestamp,
    this.avatarUrl,
  });
}

/// Classe représentant un serveur Discord
class DiscordGuildData {
  final String id;
  final String name;
  final String? iconUrl;

  const DiscordGuildData({required this.id, required this.name, this.iconUrl});
}

/// Classe représentant un channel Discord
class DiscordChannelData {
  final String id;
  final String name;
  final String guildId;

  const DiscordChannelData({
    required this.id,
    required this.name,
    required this.guildId,
  });
}

/// Classe pour gérer l'état de Discord
class DiscordState {
  final DiscordConnectionState connectionState;
  final NyxxGateway? client;
  final String? errorMessage;
  final User? currentUser;
  final List<DiscordMessageData> messages;
  final List<DiscordGuildData> guilds;
  final String? selectedGuildId;
  final List<DiscordChannelData> channels;
  final String? selectedChannelId;

  const DiscordState({
    required this.connectionState,
    this.client,
    this.errorMessage,
    this.currentUser,
    this.messages = const [],
    this.guilds = const [],
    this.selectedGuildId,
    this.channels = const [],
    this.selectedChannelId,
  });

  DiscordState copyWith({
    DiscordConnectionState? connectionState,
    NyxxGateway? client,
    String? errorMessage,
    User? currentUser,
    List<DiscordMessageData>? messages,
    List<DiscordGuildData>? guilds,
    String? selectedGuildId,
    List<DiscordChannelData>? channels,
    Object? selectedChannelId = _undefined,
  }) {
    return DiscordState(
      connectionState: connectionState ?? this.connectionState,
      client: client ?? this.client,
      errorMessage: errorMessage ?? this.errorMessage,
      currentUser: currentUser ?? this.currentUser,
      messages: messages ?? this.messages,
      guilds: guilds ?? this.guilds,
      selectedGuildId: selectedGuildId ?? this.selectedGuildId,
      channels: channels ?? this.channels,
      selectedChannelId: selectedChannelId == _undefined
          ? this.selectedChannelId
          : selectedChannelId as String?,
    );
  }
}

// Sentinel value for undefined optional parameters
const _undefined = Object();

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

      // Récupérer la liste des serveurs (guilds)
      final guilds = <DiscordGuildData>[];
      try {
        // Utiliser l'événement onReady pour récupérer les guilds
        await for (final readyEvent in client.onReady.take(1)) {
          for (final partialGuild in readyEvent.guilds) {
            try {
              // Fetch complete guild info
              final guild = await client.guilds.fetch(partialGuild.id);
              guilds.add(
                DiscordGuildData(
                  id: guild.id.toString(),
                  name: guild.name,
                  iconUrl: guild.icon?.url.toString(),
                ),
              );
            } catch (e) {
              print('⚠️ Unable to fetch server ${partialGuild.id}: $e');
            }
          }
        }
      } catch (e) {
        print('⚠️ Unable to fetch servers: $e');
      }

      state = state.copyWith(
        connectionState: DiscordConnectionState.connected,
        client: client,
        currentUser: user,
        errorMessage: null,
        messages: [], // Réinitialiser les messages
        guilds: guilds,
        selectedGuildId: guilds.isNotEmpty ? guilds.first.id : null,
      );

      // Écouter les nouveaux messages
      _listenToMessages(client);

      print('✅ Connected to Discord as ${user.username}');
      print('📁 ${guilds.length} server(s) available');

      // Charger les channels du premier serveur automatiquement
      if (guilds.isNotEmpty) {
        await _loadChannels(guilds.first.id);
      }
    } catch (e) {
      state = state.copyWith(
        connectionState: DiscordConnectionState.error,
        errorMessage: e.toString(),
      );
      print('❌ Connection error: $e');
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
          print('⚠️ Unable to fetch channel name: $e');
        }

        // Créer l'objet message
        final messageData = DiscordMessageData(
          id: message.id.toString(),
          content: message.content,
          authorName: message.author.username,
          channelId: message.channelId.toString(),
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
          '📩 Message received from ${message.author.username} in channel ${message.channelId}: ${message.content}',
        );
        print('📊 Total messages: ${updatedMessages.length}');
      } catch (e) {
        print('❌ Error processing message: $e');
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
      print('🔌 Disconnected from Discord');
    } catch (e) {
      print('❌ Error during disconnection: $e');
    }
  }

  /// Effacer les messages
  void clearMessages() {
    state = state.copyWith(messages: []);
  }

  /// Sélectionner un serveur
  Future<void> selectGuild(String? guildId) async {
    state = state.copyWith(
      selectedGuildId: guildId,
      channels: [],
      selectedChannelId: null,
    );
    print('📁 Server selected: $guildId');

    // Charger les channels du serveur sélectionné
    if (guildId != null) {
      await _loadChannels(guildId);
    }
  }

  /// Charger les channels d'un serveur
  Future<void> _loadChannels(String guildId) async {
    try {
      final client = state.client;
      if (client == null) return;

      final guild = await client.guilds.fetch(Snowflake.parse(guildId));
      final channels = <DiscordChannelData>[];

      final guildChannels = await guild.fetchChannels();
      for (final channel in guildChannels) {
        // Ne garder que les channels textuels (pas les vocaux, catégories, etc.)
        if (channel is TextChannel) {
          print('📺 Found channel: ${channel.name} (type: ${channel.type})');
          channels.add(
            DiscordChannelData(
              id: channel.id.toString(),
              name: channel.name,
              guildId: guildId,
            ),
          );
        }
      }

      // Trier les channels par ordre alphabétique
      channels.sort((a, b) => a.name.compareTo(b.name));

      state = state.copyWith(channels: channels);
      print('📺 ${channels.length} text channel(s) loaded');
    } catch (e) {
      print('❌ Error loading channels: $e');
    }
  }

  /// Sélectionner un channel
  void selectChannel(String? channelId) {
    state = state.copyWith(selectedChannelId: channelId);
    print('📺 Channel selected: $channelId');
  }

  /// Envoyer un message dans un canal
  Future<void> sendMessage(Snowflake channelId, String content) async {
    try {
      final client = state.client;
      if (client == null) {
        throw Exception('Discord client not connected');
      }

      final channel = await client.channels.fetch(channelId);
      if (channel is! TextChannel) {
        throw Exception('Channel is not a text channel');
      }

      await channel.sendMessage(MessageBuilder(content: content));
      print('📨 Message sent: $content');
    } catch (e) {
      print('❌ Error sending message: $e');
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
