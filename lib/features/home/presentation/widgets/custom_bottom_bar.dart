import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'number_keyboard_bottom_sheet.dart';

class CustomBottomBar extends StatelessWidget {
  const CustomBottomBar({super.key});

  void _showNumberKeyboard(BuildContext context) {
    showNumberKeyboardBottomSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();

    Color getColor(String route) {
      return location == route ? Colors.black : Colors.grey[400]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.transparent)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              Icons.home_filled,
              size: 30,
              color: getColor('/dashboard'),
            ),
            onPressed: () => context.go('/dashboard'),
          ),
          Icon(Icons.access_time_filled, size: 30, color: Colors.grey[400]),
          IconButton(
            icon: Icon(Icons.settings, size: 30, color: getColor('/settings')),
            onPressed: () => context.go('/settings'),
          ),
          GestureDetector(
            onTap: () => _showNumberKeyboard(context),
            child: Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 30),
            ),
          ),
        ],
      ),
    );
  }
}
