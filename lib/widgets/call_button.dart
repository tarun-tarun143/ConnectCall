import 'package:flutter/material.dart';

class CallButton extends StatelessWidget {
  const CallButton({super.key, required this.icon, required this.onPressed, this.tooltip, this.filled = false});
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return IconButton.filled(tooltip: tooltip, onPressed: onPressed, icon: Icon(icon));
    }
    return IconButton.filledTonal(tooltip: tooltip, onPressed: onPressed, icon: Icon(icon));
  }
}
