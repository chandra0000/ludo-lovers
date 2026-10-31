import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import 'ludo_dimensions.dart';

/// Product controls and turn feedback layered over the fixed 576 × 1024 canvas.
/// All positions are expressed in logical canvas coordinates; the parent
/// projects this layer uniformly to preserve the reference artwork's geometry.
class LudoBoardOverlay extends StatefulWidget {
  const LudoBoardOverlay({
    super.key,
    required this.onHelp,
    required this.onChat,
    required this.playerName,
    this.isLocalTurn = true,
    this.isRolling = false,
    this.isOpponentTurn = false,
    this.colorName,
    this.isCompleted = false,
    this.winnerName,
  });

  final VoidCallback onHelp;
  final VoidCallback onChat;
  final String playerName;
  final bool isLocalTurn;
  final bool isRolling;
  final bool isOpponentTurn;
  final String? colorName;
  final bool isCompleted;
  final String? winnerName;

  @override
  State<LudoBoardOverlay> createState() => _LudoBoardOverlayState();
}

class _LudoBoardOverlayState extends State<LudoBoardOverlay>
    with SingleTickerProviderStateMixin {
  static const List<String> _reactions = <String>[
    '😂', '🔥', '👍', '😢', '🎯', '👑',
  ];
  static const List<Offset> _reactionArc = <Offset>[
    Offset(8, 24),
    Offset(48, 7),
    Offset(88, 0),
    Offset(128, 0),
    Offset(168, 7),
    Offset(208, 24),
  ];

  bool _dockOpen = false;
  String? _floatingReaction;
  late final AnimationController _reactionAnimation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  late final Animation<double> _reactionFade = CurvedAnimation(
    parent: _reactionAnimation,
    curve: Curves.easeOut,
  );
  late final Animation<Offset> _reactionRise = Tween<Offset>(
    begin: Offset.zero,
    end: const Offset(0, -1.0),
  ).animate(CurvedAnimation(
    parent: _reactionAnimation,
    curve: Curves.easeOutCubic,
  ));

  @override
  void dispose() {
    _reactionAnimation.dispose();
    super.dispose();
  }

  void _showReaction(String emoji) {
    setState(() {
      _dockOpen = false;
      _floatingReaction = emoji;
    });
    _reactionAnimation.forward(from: 0).whenCompleteOrCancel(() {
      if (mounted) setState(() => _floatingReaction = null);
    });
  }

  String get _statusText {
    if (widget.isCompleted) return '${widget.winnerName ?? widget.playerName} · WINNER';
    if (widget.isRolling) return 'Rolling...';
    if (widget.isOpponentTurn) return "${widget.playerName}'s Turn";
    if (widget.isLocalTurn && widget.colorName != null) {
      return widget.colorName!.toUpperCase();
    }
    return 'Your Turn';
  }

  @override
  Widget build(BuildContext context) => Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned(
            left: LudoDimensions.helpCenter.dx - 22,
            top: LudoDimensions.helpCenter.dy - 22,
            width: 44,
            height: 44,
            child: _glassButton(
              key: const ValueKey('game_help_button'),
              tooltip: 'How to play',
              icon: Icons.help_outline_rounded,
              onTap: widget.onHelp,
            ),
          ),
          Positioned(
            left: LudoDimensions.chatCenter.dx - 28,
            top: LudoDimensions.chatCenter.dy - 28,
            width: 56,
            height: 56,
            child: _glassButton(
              key: const ValueKey('open_match_chat_button'),
              tooltip: 'Chat unavailable offline',
              icon: Icons.chat_bubble_outline_rounded,
              onTap: widget.onChat,
            ),
          ),
          Positioned(
            left: LudoDimensions.reactionCenter.dx - 28,
            top: LudoDimensions.reactionCenter.dy - 28,
            width: 56,
            height: 56,
            child: _glassButton(
              key: const ValueKey('open_reaction_dock_button'),
              tooltip: 'Reactions',
              icon: Icons.emoji_emotions_outlined,
              onTap: () => setState(() => _dockOpen = !_dockOpen),
            ),
          ),
          if (_dockOpen)
            Positioned(
              left: 286,
              top: 820,
              width: 244,
              height: 64,
              child: Material(
                color: AppTheme.panel.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(34),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    for (var index = 0; index < _reactions.length; index++)
                      Positioned(
                        left: _reactionArc[index].dx,
                        top: _reactionArc[index].dy,
                        width: 38,
                        height: 38,
                        child: Semantics(
                          button: true,
                          label: 'Send ${_reactions[index]} reaction',
                          child: Material(
                            color: AppTheme.black.withValues(alpha: 0.86),
                            shape: const CircleBorder(
                              side: BorderSide(color: AppTheme.gold, width: 0.8),
                            ),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => _showReaction(_reactions[index]),
                              child: Center(
                                child: Text(
                                  _reactions[index],
                                  style: const TextStyle(fontSize: 21),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          if (_floatingReaction != null)
            Positioned(
              left: 456,
              top: 790,
              child: IgnorePointer(
                child: FadeTransition(
                  opacity: ReverseAnimation(_reactionFade),
                  child: SlideTransition(
                    position: _reactionRise,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.8, end: 1.2).animate(
                        CurvedAnimation(
                          parent: _reactionAnimation,
                          curve: Curves.easeOutBack,
                        ),
                      ),
                      child: Text(
                        _floatingReaction!,
                        style: const TextStyle(fontSize: 36),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Positioned.fromRect(
            key: const ValueKey('turn_status_banner'),
            rect: LudoDimensions.turnBanner,
            child: IgnorePointer(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _statusText,
                    key: const ValueKey('portrait_turn_indicator'),
                    maxLines: 1,
                    style: TextStyle(
                      color: AppTheme.cream,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                      shadows: <Shadow>[
                        const Shadow(color: AppTheme.black, blurRadius: 6),
                        if (widget.isLocalTurn && !widget.isRolling)
                          Shadow(
                            color: AppTheme.gold.withValues(alpha: 0.8),
                            blurRadius: 12,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );

  Widget _glassButton({
    required Key key,
    required String tooltip,
    required IconData icon,
    required VoidCallback onTap,
  }) =>
      Semantics(
        button: true,
        label: tooltip,
        child: Material(
          key: key,
          color: AppTheme.panel.withValues(alpha: 0.72),
          shape: const CircleBorder(
            side: BorderSide(color: AppTheme.gold, width: 1),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox.expand(
              child: Center(
                child: Icon(icon, color: AppTheme.gold, size: 23),
              ),
            ),
          ),
        ),
      );
}
