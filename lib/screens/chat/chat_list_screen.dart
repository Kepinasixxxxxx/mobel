import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/conversation_model.dart';
import '../../state/chat_provider.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ChatProvider>().fetchConversations());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final list = provider.conversations.where((c) => c.customerName.toLowerCase().contains(_query.toLowerCase())).toList()
      ..sort((a, b) => (b.lastMessageAt ?? DateTime(2000)).compareTo(a.lastMessageAt ?? DateTime(2000)));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Chat')),
      body: RefreshIndicator(
        onRefresh: provider.fetchConversations,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(hintText: 'Cari nama pelanggan...', prefixIcon: Icon(Icons.search, size: 20)),
              ),
            ),
            Expanded(
              child: provider.isLoadingList
                  ? const Center(child: CircularProgressIndicator())
                  : list.isEmpty
                      ? const Center(child: Text('Belum ada percakapan', style: TextStyle(color: AppColors.textSecondary)))
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: list.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) => _ConversationTile(
                            conversation: list[index],
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatDetailScreen(conversation: list[index]))),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;

  const _ConversationTile({required this.conversation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 6),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        backgroundImage: conversation.customerPhoto != null ? NetworkImage(conversation.customerPhoto!) : null,
        child: conversation.customerPhoto == null ? Text(conversation.customerName.isNotEmpty ? conversation.customerName[0].toUpperCase() : '?', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)) : null,
      ),
      title: Text(conversation.customerName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      subtitle: Text(conversation.lastMessageText ?? 'Belum ada pesan', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
      trailing: conversation.lastMessageAt != null
          ? Text('${conversation.lastMessageAt!.hour.toString().padLeft(2, '0')}:${conversation.lastMessageAt!.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))
          : null,
    );
  }
}
