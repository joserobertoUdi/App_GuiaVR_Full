import 'package:flutter/material.dart';

import 'package:app_guia_ar/features/navigation/domain/models/node_model.dart';
import 'package:app_guia_ar/core/theme/app_theme.dart';

class NavigationControlsWidget extends StatelessWidget {
  final List<NodeModel> connectedNodes;
  final Function(String nodeId) onNodeTap;
  final String? highlightedNodeId;

  const NavigationControlsWidget({
    super.key,
    required this.connectedNodes,
    required this.onNodeTap,
    this.highlightedNodeId,
  });

  @override
  Widget build(BuildContext context) {
    if (connectedNodes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 100,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.navigation,
                  color: Colors.white.withValues(alpha: 0.8),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Navegar a:',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: connectedNodes.map((node) {
                final isHighlighted = node.id == highlightedNodeId;
                return ElevatedButton.icon(
                  onPressed: () => onNodeTap(node.id),
                  icon: Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: isHighlighted ? Colors.white : Colors.black87,
                  ),
                  label: Text(
                    node.name,
                    style: TextStyle(
                      color: isHighlighted ? Colors.white : Colors.black87,
                      fontSize: 12,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isHighlighted
                        ? AppTheme.warningColor
                        : Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
