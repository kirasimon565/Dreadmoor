import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/state/messenger_state.dart';
import 'package:intl/intl.dart';

class MessengerListScreen extends ConsumerWidget {
  const MessengerListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threadsAsync = ref.watch(threadsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
             Image.asset('assets/ui/messenger_weapon_logo.png', width: 24, height: 24, errorBuilder: (c,o,s) => const Icon(Icons.message, color: Colors.white)),
             const SizedBox(width: 8),
             const Text('MESSENGER', style: TextStyle(fontFamily: 'Cinzel', letterSpacing: 1.5)),
          ],
        ),
        backgroundColor: Colors.grey[900],
        elevation: 0,
      ),
      body: threadsAsync.when(
        data: (threads) {
          if (threads.isEmpty) {
            return const Center(child: Text('No messages yet', style: TextStyle(color: Colors.grey)));
          }
          return ListView.separated(
            itemCount: threads.length,
            separatorBuilder: (context, index) => Divider(color: Colors.grey[800], height: 1),
            itemBuilder: (context, index) {
              final item = threads[index];
              return ThreadItem(item: item);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error loading threads: $e')),
      ),
    );
  }
}

class ThreadItem extends StatelessWidget {
  final ThreadWithLastMessage item;
  const ThreadItem({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final lastMsg = item.lastMessage;
    final timeStr = lastMsg != null ? DateFormat('HH:mm').format(lastMsg.timestamp) : '';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.purple.withOpacity(0.2),
        backgroundImage: AssetImage('assets/characters/${item.thread.title.toLowerCase()}.png'), // Placeholder logic
        onBackgroundImageError: (e, s) {}, // Handle missing image
        child: Text(item.thread.title.substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white)),
      ),
      title: Text(
        item.thread.title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      subtitle: Row(
        children: [
          if (item.thread.isTyping)
             const Text('Typing...', style: TextStyle(color: Colors.purple, fontStyle: FontStyle.italic))
          else
             Expanded(
               child: Text(
                 lastMsg?.content ?? 'No messages',
                 style: TextStyle(color: Colors.grey[400], overflow: TextOverflow.ellipsis),
                 maxLines: 1,
               ),
             ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(timeStr, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          if (item.thread.unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(color: Colors.purple, shape: BoxShape.circle),
              child: Text('${item.thread.unreadCount}', style: const TextStyle(color: Colors.white, fontSize: 10)),
            ),
        ],
      ),
      onTap: () {
        context.push('/messenger/chat/${item.thread.id}');
      },
    );
  }
}
