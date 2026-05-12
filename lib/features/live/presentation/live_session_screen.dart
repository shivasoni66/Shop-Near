import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_near/shared/providers/repository_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/live_badge.dart';
import '../../../shared/models/live_session.dart';
import '../../../core/constants/agora_config.dart';
import '../../../features/auth/providers/auth_notifier.dart';
import '../../../features/auth/providers/auth_providers.dart';

class LiveSessionScreen extends ConsumerStatefulWidget {
  final LiveSession? session;
  const LiveSessionScreen({super.key, this.session});

  @override
  ConsumerState<LiveSessionScreen> createState() => _LiveSessionScreenState();
}

class _LiveSessionScreenState extends ConsumerState<LiveSessionScreen> with TickerProviderStateMixin {
  late RtcEngine _engine;
  bool _localUserJoined = false;
  bool _isJoined = false;
  int? _remoteUid;
  final List<Widget> _floatingHearts = [];
  final math.Random _random = math.Random();
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _chatMessages = [
    {'user': 'Anjali', 'msg': 'Love this collection! 😍'},
    {'user': 'Rohit K', 'msg': 'What\'s the price for blue one?'},
    {'user': 'Priya', 'msg': '₹1,299 only! Limited stock!', 'isSeller': true},
    {'user': 'Meena', 'msg': 'Can I get COD option? 🙏'},
  ];
  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    // retrieve permissions
    await [Permission.microphone, Permission.camera].request();

    //create the engine
    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(
      appId: AgoraConfig.appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("local user ${connection.localUid} joined");
          setState(() {
            _localUserJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("remote user $remoteUid joined");
          setState(() {
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          debugPrint("remote user $remoteUid left channel");
          setState(() {
            _remoteUid = null;
          });
        },
        onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
          debugPrint('[onTokenPrivilegeWillExpire] connection: ${connection.toJson()}, token: $token');
        },
      ),
    );

    final user = ref.read(authControllerProvider).user;
    final isBroadcaster = user?.role == 'seller';

    await _engine.setClientRole(
      role: isBroadcaster ? ClientRoleType.clientRoleBroadcaster : ClientRoleType.clientRoleAudience,
    );
    await _engine.enableVideo();
    await _engine.startPreview();

    await _engine.joinChannel(
      token: AgoraConfig.token,
      channelId: widget.session?.id ?? 'demo_channel',
      uid: 0,
      options: const ChannelMediaOptions(),
    );
    setState(() => _isJoined = true);

    // Socket Interactions
    _setupSocket();
  }

  void _setupSocket() {
    final socketService = ref.read(socketServiceProvider);
    final roomId = widget.session?.id ?? 'demo_channel';

    socketService.emit('join_room', roomId);

    socketService.on('receive_live_chat', (data) {
      if (mounted) {
        setState(() {
          _chatMessages.add({
            'user': data['user'],
            'msg': data['msg'],
            'isSeller': data['isSeller'] ?? false,
          });
        });
        _scrollToBottom();
      }
    });

    socketService.on('receive_live_reaction', (data) {
      if (mounted && data['user'] != 'You') {
        _showHeartAnimation(data['emoji']);
      }
    });
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

  void _addHeart(String emoji) {
    _showHeartAnimation(emoji);
    
    // Broadcast reaction
    final socketService = ref.read(socketServiceProvider);
    socketService.emit('live_reaction', {
      'roomId': widget.session?.id ?? 'demo_channel',
      'user': 'Someone',
      'emoji': emoji,
    });
  }

  void _showHeartAnimation(String emoji) {
    setState(() {
      _floatingHearts.add(
        _FloatingHeart(
          key: UniqueKey(),
          emoji: emoji,
          onComplete: (key) {
            setState(() {
              _floatingHearts.removeWhere((element) => element.key == key);
            });
          },
        ),
      );
    });
  }

  void _sendChatMessage() {
    if (_chatController.text.trim().isEmpty) return;
    
    final user = ref.read(authControllerProvider).user;
    final msg = _chatController.text.trim();
    final isSeller = user?.role == 'seller';

    // Broadcast message
    final socketService = ref.read(socketServiceProvider);
    socketService.emit('live_chat', {
      'roomId': widget.session?.id ?? 'demo_channel',
      'user': user?.name ?? 'User',
      'msg': msg,
      'isSeller': isSeller,
    });

    setState(() {
      _chatMessages.add({
        'user': 'You',
        'msg': msg,
        'isSeller': isSeller,
      });
      _chatController.clear();
    });
    _scrollToBottom();
  }

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  Widget _videoView() {
    final user = ref.read(authControllerProvider).user;
    final isBroadcaster = user?.role == 'seller';

    if (isBroadcaster) {
      return AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: _engine,
          canvas: const VideoCanvas(uid: 0),
        ),
      );
    }

    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: widget.session?.id ?? 'demo_channel'),
        ),
      );
    } else {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2B1B54), Color(0xFFEE7B9D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('⌛', style: TextStyle(fontSize: 60)),
              SizedBox(height: 10),
              Text('Waiting for seller to start...', style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Real Video background
          Positioned.fill(
            child: _videoView(),
          ),

          // Floating Hearts Layer
          ..._floatingHearts,
          
          // Header
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(20)),
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(30)),
                  child: Row(
                    children: [
                      const CircleAvatar(radius: 16, backgroundColor: Colors.white, child: Text('👗')),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Priya Fashion', style: AppTextStyles.labelMedium.copyWith(color: Colors.white)),
                          Text('1.2k viewers', style: AppTextStyles.labelSmall.copyWith(color: Colors.white70)),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(16)),
                        child: Text('Follow', style: AppTextStyles.labelSmall.copyWith(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const LiveBadge(pulse: true),
              ],
            ),
          ),
          
          // Reactions Side
          Positioned(
            right: 14,
            bottom: 250,
            child: Column(
              children: [
                _buildReactBtn('❤️'),
                const SizedBox(height: 10),
                _buildReactBtn('🔥'),
                const SizedBox(height: 10),
                _buildReactBtn('👏'),
                const SizedBox(height: 10),
                _buildReactBtn('😍'),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => context.push('/home/cart'),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      border: Border.all(color: Colors.white.withOpacity(0.25)),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
          
          // Chat Area
          Positioned(
            bottom: 210,
            left: 14,
            right: 70,
            height: 160,
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _chatMessages.length,
              padding: EdgeInsets.zero,
              itemBuilder: (context, index) {
                final chat = _chatMessages[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _buildChatBubble(chat['user'], chat['msg'], isSeller: chat['isSeller'] ?? false),
                );
              },
            ),
          ),
          
          // Live Product Bar
          Positioned(
            bottom: 136,
            left: 14,
            right: 70,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: const LinearGradient(colors: [Color(0xFFFFECD2), Color(0xFFFCB69F)]),
                    ),
                    alignment: Alignment.center,
                    child: const Text('👗', style: TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Silk Saree — Royal Blue', style: AppTextStyles.labelMedium.copyWith(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                        Text('₹1,299', style: AppTextStyles.labelMedium.copyWith(color: AppColors.accent, fontSize: 14, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => context.push('/home/cart'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      minimumSize: Size.zero,
                    ),
                    child: Text('Buy Now', style: AppTextStyles.labelSmall.copyWith(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
          ),
          
          // Live Input Area
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 28),
              color: Colors.black.withOpacity(0.65),
              child: Row(
                children: [
                  const Text('🎁', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _chatController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Say something...',
                          hintStyle: AppTextStyles.bodyMedium.copyWith(color: Colors.white.withOpacity(0.45), fontSize: 13),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _sendChatMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendChatMessage,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.send, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactBtn(String emoji) {
    return GestureDetector(
      onTap: () => _addHeart(emoji),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(emoji, style: const TextStyle(fontSize: 20)),
      ),
    );
  }

  Widget _buildChatBubble(String user, String msg, {bool isSeller = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(10),
      ),
      child: RichText(
        text: TextSpan(
          text: '$user: ',
          style: AppTextStyles.labelMedium.copyWith(color: isSeller ? AppColors.accent : Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
          children: [
            TextSpan(text: msg, style: AppTextStyles.bodySmall.copyWith(color: Colors.white, fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}

class _FloatingHeart extends StatefulWidget {
  final String emoji;
  final Function(Key?) onComplete;

  const _FloatingHeart({super.key, required this.emoji, required this.onComplete});

  @override
  State<_FloatingHeart> createState() => _FloatingHeartState();
}

class _FloatingHeartState extends State<_FloatingHeart> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late double _left;
  late double _size;

  @override
  void initState() {
    super.initState();
    _left = 150 + math.Random().nextDouble() * 200;
    _size = 20 + math.Random().nextDouble() * 15;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..forward().then((_) => widget.onComplete(widget.key));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double progress = _controller.value;
        final double y = 400 * progress;
        final double x = 50 * math.sin(progress * 2 * math.pi);
        final double opacity = 1 - progress;

        return Positioned(
          bottom: 100 + y,
          left: _left + x,
          child: Opacity(
            opacity: opacity,
            child: Text(widget.emoji, style: TextStyle(fontSize: _size)),
          ),
        );
      },
    );
  }
}
