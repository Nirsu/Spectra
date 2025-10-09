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
          _buildHeader(context, discordState, ref),
          const SizedBox(height: 32),

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
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getStatusColor(state.connectionState),
            ),
          ),
          const SizedBox(width: 12),

          // Status info - pas Expanded pour garder sa taille naturelle
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
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
                  'Connected as ${state.currentUser!.username} BOT',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                ),
            ],
          ),

          // Server selector (only when connected)
          if (state.connectionState == DiscordConnectionState.connected &&
              state.guilds.isNotEmpty) ...[
            const SizedBox(width: 16),
            Container(height: 48, width: 1, color: Colors.grey.shade700),
            const SizedBox(width: 16),
            _buildServerSelector(state, ref),
          ],

          const Spacer(),

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

  Widget _buildServerSelector(DiscordState state, WidgetRef ref) {
    return SizedBox(
      height: 48,
      width: 300,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: state.guilds.length,
        itemBuilder: (context, index) {
          final guild = state.guilds[index];
          final isSelected = guild.id == state.selectedGuildId;

          return Tooltip(
            message: guild.name,
            child: GestureDetector(
              onTap: () {
                ref.read(discordProvider.notifier).selectGuild(guild.id);
              },
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.blue.shade700
                      : Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? Colors.blue.shade500
                        : Colors.grey.shade700,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: guild.iconUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
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
                      : Icon(Icons.discord, color: Colors.white, size: 24),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChannelDropdown(DiscordState state, WidgetRef ref) {
    // Use a special value for "all channels" instead of null
    const allChannelsValue = '__all__';
    final currentValue = state.selectedChannelId ?? allChannelsValue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade700,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade600),
      ),
      child: DropdownButton<String>(
        value: currentValue,
        isExpanded: false,
        underline: const SizedBox(),
        dropdownColor: Colors.grey.shade800,
        icon: Icon(Icons.arrow_drop_down, color: Colors.grey.shade300),
        items: [
          // Option "All channels"
          const DropdownMenuItem<String>(
            value: allChannelsValue,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.tag, size: 16, color: Colors.grey),
                SizedBox(width: 8),
                Text('All channels', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          // Liste des channels
          ...state.channels.map((channel) {
            return DropdownMenuItem<String>(
              value: channel.id,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tag, size: 16, color: Colors.grey.shade300),
                  const SizedBox(width: 8),
                  Text(
                    channel.name,
                    style: TextStyle(color: Colors.grey.shade300),
                  ),
                ],
              ),
            );
          }),
        ],
        onChanged: (channelId) {
          // Convert '__all__' back to null
          final selectedId = channelId == allChannelsValue ? null : channelId;
          ref.read(discordProvider.notifier).selectChannel(selectedId);
          print('🔄 Channel changed to: ${channelId ?? "All channels"}');
        },
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade600,
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
                const SizedBox(width: 8),
                // Message count badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${state.messages.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Channel filter dropdown
                if (state.channels.isNotEmpty) ...[
                  _buildChannelDropdown(state, ref),
                ] else if (state.selectedGuildId != null) ...[
                  // Show loading indicator if guild is selected but no channels yet
                  Text(
                    'Loading channels...',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  ),
                ],
                const Spacer(),
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

          // Content
          Expanded(
            child: () {
              // Filter messages by selected channel
              final filteredMessages = state.selectedChannelId == null
                  ? state.messages
                  : state.messages
                        .where(
                          (msg) => msg.channelId == state.selectedChannelId,
                        )
                        .toList();

              return filteredMessages.isEmpty
                  ? _buildNoMessagesView()
                  : _buildMessagesList(filteredMessages);
            }(),
          ),
        ],
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

  Widget _buildMessagesList(List<DiscordMessageData> messages) {
    return ListView.builder(
      reverse: false,
      padding: const EdgeInsets.all(8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return _buildMessageCard(message);
      },
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
            Row(
              children: [
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

                Text(
                  message.authorName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(width: 8),

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

                Text(
                  _formatTimestamp(message.timestamp),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),

            const SizedBox(height: 8),

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
