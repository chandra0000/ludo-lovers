import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';

/// Reusable product controls layered above the fixed board artwork.
class LudoBoardOverlay extends StatefulWidget {
  const LudoBoardOverlay({
    super.key,
    required this.onHelp,
    required this.onChat,
    required this.playerName,
  });

  final VoidCallback onHelp;
  final VoidCallback onChat;
  final String playerName;

  @override
  State<LudoBoardOverlay> createState() => _LudoBoardOverlayState();
}

class _LudoBoardOverlayState extends State<LudoBoardOverlay>
    with SingleTickerProviderStateMixin {
  static const reactions = ['😂', '🔥', '👍', '😢', '🎯', '👑'];
  bool _dockOpen = false;
  String? _floatingReaction;
  late final AnimationController _reactionAnimation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

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

  @override
  Widget build(BuildContext context) => Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: 28,
            top: 22,
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
            left: 70,
            top: 912,
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
            left: 450,
            top: 912,
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
              left: 280,
              top: 842,
              width: 260,
              height: 62,
              child: Material(
                color: AppTheme.panel.withValues(alpha: 0.93),
                borderRadius: BorderRadius.circular(32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (final emoji in reactions)
                      IconButton(
                        tooltip: 'Send $emoji reaction',
                        onPressed: () => _showReaction(emoji),
                        icon: Text(emoji, style: const TextStyle(fontSize: 22)),
                      ),
                  ],
                ),
              ),
            ),
          if (_floatingReaction != null)
            Positioned(
              left: 462,
              top: 790,
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _reactionAnimation,
                  builder: (context, child) => Opacity(
                    opacity: 1 - _reactionAnimation.value,
                    child: Transform.translate(
                      offset: Offset(0, -100 * _reactionAnimation.value),
                      child: Transform.scale(
                        scale: 0.7 + 0.5 * _reactionAnimation.value,
                        child: child,
                      ),
                    ),
                  ),
                  child: Text(_floatingReaction!, style: const TextStyle(fontSize: 36)),
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
          color: AppTheme.panel.withValues(alpha: 0.67),
          shape: const CircleBorder(side: BorderSide(color: AppTheme.gold, width: 1)),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox.expand(
              child: Center(child: Icon(icon, color: AppTheme.gold, size: 23)),
            ),
          ),
        ),
      );
}
