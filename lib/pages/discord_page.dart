import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/discord_service.dart';

class DiscordPage extends ConsumerWidget {
  const DiscordPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discordState = ref.watch(discordProvider);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // En-tête avec statut de connexion
          _buildHeader(context, discordState, ref),
          const SizedBox(height: 32),

          // Zone de contenu principale
          Expanded(child: _buildMainContent(context, discordState, ref)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, DiscordState state, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Row(
        children: [
          // Icône de statut
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getStatusColor(state.connectionState),
            ),
          ),
          const SizedBox(width: 12),

          // Informations de connexion
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStatusText(state.connectionState),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (state.currentUser != null)
                  Text(
                    'Connected as ${state.currentUser!.username}',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                  ),
              ],
            ),
          ),

          // Bouton de connexion/déconnexion
          ElevatedButton.icon(
            onPressed:
                state.connectionState == DiscordConnectionState.connecting
                ? null
                : () {
                    if (state.connectionState ==
                        DiscordConnectionState.connected) {
                      ref.read(discordProvider.notifier).disconnect();
                    } else {
                      ref.read(discordProvider.notifier).connect();
                    }
                  },
            icon: Icon(
              state.connectionState == DiscordConnectionState.connected
                  ? Icons.logout
                  : Icons.login,
            ),
            label: Text(
              state.connectionState == DiscordConnectionState.connected
                  ? 'Disconnect'
                  : 'Connect',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  state.connectionState == DiscordConnectionState.connected
                  ? Colors.red.shade700
                  : Colors.blue.shade700,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(
    BuildContext context,
    DiscordState state,
    WidgetRef ref,
  ) {
    switch (state.connectionState) {
      case DiscordConnectionState.disconnected:
        return _buildDisconnectedView();
      case DiscordConnectionState.connecting:
        return _buildConnectingView();
      case DiscordConnectionState.connected:
        return _buildConnectedView(state, ref);
      case DiscordConnectionState.error:
        return _buildErrorView(state);
    }
  }

  Widget _buildDisconnectedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey.shade600,
          ),
          const SizedBox(height: 24),
          Text(
            'Not connected to Discord',
            style: TextStyle(fontSize: 24, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 12),
          Text(
            'Click "Connect" to connect',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.blue),
          SizedBox(height: 24),
          Text('Connecting to Discord...', style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildConnectedView(DiscordState state, WidgetRef ref) {
    return Column(
      children: [
        // Sélection de serveur
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade800),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.dns, color: Colors.blue.shade400, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Available Servers',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade900.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade700),
                    ),
                    child: Text(
                      '${state.guilds.length} server(s)',
                      style: TextStyle(
                        color: Colors.blue.shade400,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (state.guilds.isEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'No servers found',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                ),
              ] else ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: state.guilds.length,
                    itemBuilder: (context, index) {
                      final guild = state.guilds[index];
                      final isSelected = state.selectedGuildId == guild.id;
                      return _buildGuildCard(guild, isSelected, ref);
                    },
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Liste des messages
        Expanded(
          child: state.messages.isEmpty
              ? _buildNoMessagesView()
              : _buildMessagesList(state.messages, ref),
        ),
      ],
    );
  }

  Widget _buildGuildCard(
    DiscordGuildData guild,
    bool isSelected,
    WidgetRef ref,
  ) {
    return GestureDetector(
      onTap: () {
        ref
            .read(discordProvider.notifier)
            .selectGuild(isSelected ? null : guild.id);
      },
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue.shade900.withOpacity(0.3)
              : Colors.grey.shade800,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue.shade600 : Colors.grey.shade700,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Icône du serveur
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.blue.shade700,
                borderRadius: BorderRadius.circular(8),
              ),
              child: guild.iconUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        guild.iconUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.discord,
                            color: Colors.white,
                            size: 24,
                          );
                        },
                      ),
                    )
                  : const Icon(Icons.discord, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            // Nom du serveur
            Expanded(
              child: Text(
                guild.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.blue.shade300 : Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoMessagesView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey.shade600,
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 8),
          Text(
            'Received messages will appear here',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(List<DiscordMessageData> messages, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Column(
        children: [
          // En-tête de la liste
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  'Received Messages',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                // Bouton pour effacer les messages
                TextButton.icon(
                  onPressed: () {
                    ref.read(discordProvider.notifier).clearMessages();
                  },
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('Clear'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),

          // Liste scrollable
          Expanded(
            child: ListView.builder(
              reverse: false,
              padding: const EdgeInsets.all(8),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return _buildMessageCard(message);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard(DiscordMessageData message) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      color: Colors.grey.shade800,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête du message
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.blue.shade700,
                  child: Text(
                    message.authorName[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Nom de l'auteur
                Text(
                  message.authorName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(width: 8),

                // Nom du canal
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade700,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    message.channelName,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  ),
                ),

                const Spacer(),

                // Horodatage
                Text(
                  _formatTimestamp(message.timestamp),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Contenu du message
            Text(message.content, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  Widget _buildErrorView(DiscordState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red.shade400),
          const SizedBox(height: 24),
          Text(
            'Connection Error',
            style: TextStyle(fontSize: 24, color: Colors.red.shade400),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              color: Colors.red.shade900.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade800),
            ),
            child: Text(
              state.errorMessage ?? 'Unknown error',
              style: TextStyle(fontSize: 14, color: Colors.red.shade300),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(DiscordConnectionState state) {
    switch (state) {
      case DiscordConnectionState.disconnected:
        return Colors.grey;
      case DiscordConnectionState.connecting:
        return Colors.orange;
      case DiscordConnectionState.connected:
        return Colors.green;
      case DiscordConnectionState.error:
        return Colors.red;
    }
  }

  String _getStatusText(DiscordConnectionState state) {
    switch (state) {
      case DiscordConnectionState.disconnected:
        return 'Disconnected';
      case DiscordConnectionState.connecting:
        return 'Connecting...';
      case DiscordConnectionState.connected:
        return 'Connected';
      case DiscordConnectionState.error:
        return 'Error';
    }
  }
}
