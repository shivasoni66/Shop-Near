import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/providers/product_providers.dart';
import '../../../shared/providers/dynamic_product_providers.dart';
import '../../../shared/models/chat_message.dart';
import '../../../shared/models/product.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final String name;
  final String? productId;
  const ChatDetailScreen({super.key, required this.name, this.productId});

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    // Connect socket and listen for messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final socketService = ref.read(socketServiceProvider);
      socketService.connect();
      socketService.on('message', (data) {
        if (data['sender'] == widget.name || data['receiver'] == widget.name) {
          setState(() {
            _messages.add(ChatMessage.fromMap(data));
          });
          _scrollToBottom();
        }
      });
      
      // Pre-fill message with product info but don't auto-send
      if (widget.productId != null) {
        _prefillProductMessage();
      }
    });
  }

  void _prefillProductMessage() {
    final productAsync = ref.read(dynamicProductDetailProvider(widget.productId!));
    productAsync.when(
      data: (product) {
        final inquiryMessage = """
Hi! I'm interested in your product: ${product.name}

📦 Product Details:
• Price: ₹${product.price.toInt()}
• Category: ${product.category}
• Rating: ⭐ ${product.rating} (${product.reviewsCount} reviews)

View Product: https://shopnear.com/product/${product.id}

Is this product still available? I'd like to know more about:
1. Available sizes and colors
2. Delivery time
3. Any current discounts or offers

Thank you! 🙏
        """;
        _messageController.text = inquiryMessage;
      },
      loading: () {},
      error: (err, stack) {},
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    final socketService = ref.read(socketServiceProvider);
    final messageData = {
      'receiver': widget.name,
      'text': text,
    };
    
    socketService.emit('message', messageData);
    
    // Optimistic UI update
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        sender: 'Me', // This will be replaced by actual sender from socket event
        receiver: widget.name,
        timestamp: DateTime.now(),
        isMe: true,
      ));
      _messageController.clear();
    });
    
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle, 
                gradient: LinearGradient(colors: [Color(0xFFFFECD2), Color(0xFFFCB69F)])
              ),
              alignment: Alignment.center,
              child: const Text('👗', style: TextStyle(fontSize: 14)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.name, style: AppTextStyles.labelMedium.copyWith(fontSize: 14)),
                  Text('Online', style: AppTextStyles.bodySmall.copyWith(color: AppColors.success, fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home/chat');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Video call coming soon! 🎥')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.call_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Voice call coming soon! 📞')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (widget.productId != null) _buildProductInfo(),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildChatBubble(msg.text, msg.isMe);
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isMe) {
    final hasProductLink = text.contains('https://shopnear.com/product/');
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
        ),
        child: hasProductLink ? _buildMessageWithProductLink(text, isMe) : Text(
          text,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isMe ? Colors.white : AppColors.text,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageWithProductLink(String text, bool isMe) {
    final parts = text.split('https://shopnear.com/product/');
    final productId = parts.length > 1 ? parts[1].split('\n')[0] : null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          parts[0],
          style: AppTextStyles.bodyMedium.copyWith(
            color: isMe ? Colors.white : AppColors.text,
          ),
        ),
        if (productId != null) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              // Navigate to product page
              context.push('/home/product/$productId');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMe ? Colors.white.withOpacity(0.2) : AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isMe ? Colors.white.withOpacity(0.3) : AppColors.primary.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.link,
                    color: isMe ? Colors.white : AppColors.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'View Product',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isMe ? Colors.white : AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            parts[1].contains('\n') ? parts[1].split('\n').skip(1).join('\n') : '',
            style: AppTextStyles.bodyMedium.copyWith(
              color: isMe ? Colors.white : AppColors.text,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProductInfo() {
    if (widget.productId == null) return const SizedBox.shrink();
    
    return Consumer(
      builder: (context, ref, child) {
        final productAsync = ref.watch(dynamicProductDetailProvider(widget.productId!));
        
        return productAsync.when(
          data: (product) => Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFFECD2), Color(0xFFFCB69F)],
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  alignment: Alignment.center,
                  child: Text(product.imagePlaceholder, style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: AppTextStyles.labelMedium.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${product.price.toInt()}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => context.pop(),
                  child: const Icon(
                    Icons.close,
                    color: AppColors.muted,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          loading: () => Container(
            margin: const EdgeInsets.all(16),
            height: 74,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(child: CircularProgressIndicator()),
          ),
          error: (err, stack) => const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          // Product link hint if product is available
          if (widget.productId != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Product link included in message. Seller can click to view product.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    onPressed: () {
                      setState(() {
                        _messageController.clear();
                      });
                    },
                    color: Colors.blue.shade700,
                  ),
                ],
              ),
            ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                onPressed: () {},
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: _messageController,
                    maxLines: null,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: widget.productId != null 
                          ? 'Edit your message about this product...' 
                          : 'Type a message...',
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
