import 'package:flutter/material.dart';

class ModeSelectorIcon extends StatelessWidget {
  final IconData icon;
  final String label; // 👈 Add label
  final String mode;
  final String selectedMode;
  final bool isPhone; // 👈 Add field
  final Function(String) onModeChanged;

  const ModeSelectorIcon({
    Key? key,
    required this.icon,
    required this.label, // 👈 Include in constructor
    required this.mode,
    required this.selectedMode,
    required this.onModeChanged,
    required this.isPhone, // 👈 Use this
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isSelected = selectedMode == mode;

    return GestureDetector(
      onTap: () => onModeChanged(mode),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue.shade50 : Colors.white,
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey.shade400,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 28,
              color: isSelected ? Colors.blue : Colors.grey,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.blue : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
