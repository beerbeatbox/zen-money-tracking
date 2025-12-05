import 'package:flutter/material.dart';

void showNumberKeyboardBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const NumberKeyboardBottomSheet(),
  );
}

class NumberKeyboardBottomSheet extends StatefulWidget {
  const NumberKeyboardBottomSheet({super.key});

  @override
  State<NumberKeyboardBottomSheet> createState() =>
      _NumberKeyboardBottomSheetState();
}

class _NumberKeyboardBottomSheetState extends State<NumberKeyboardBottomSheet> {
  late final TextEditingController _controller;
  bool _showCategories = false;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onNumberTap(String number) {
    final currentText = _controller.text;
    _controller.text = currentText + number;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );
  }

  void _onDecimalTap() {
    final currentText = _controller.text;
    if (!currentText.contains('.')) {
      _controller.text = currentText.isEmpty ? '0.' : '$currentText.';
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    }
  }

  void _onBackspaceTap() {
    final currentText = _controller.text;
    if (currentText.isNotEmpty) {
      _controller.text = currentText.substring(0, currentText.length - 1);
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final containerPadding = 24.0;
    final gapWidth = 12.0;
    final availableWidth = screenWidth - (containerPadding * 2);
    final halfWidth = (availableWidth - gapWidth) / 2;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SizedBox(
        height: screenHeight * 0.5,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left side: Amount and Category sections
                  SizedBox(
                    width: halfWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Amount Section
                        const Text(
                          'Amount',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _controller,
                          readOnly: true,
                          enabled: !_showCategories,
                          showCursor: !_showCategories,
                          decoration: InputDecoration(
                            hintText: '0.00',
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.black,
                                width: 2,
                              ),
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                            filled: _showCategories,
                            fillColor: Colors.grey[100],
                          ),
                          style: TextStyle(
                            fontSize: 18,
                            color:
                                _showCategories
                                    ? Colors.grey[400]
                                    : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Category Section
                        const Text(
                          'Category',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final maxSize = constraints.maxWidth;
                            return SizedBox(
                              width: maxSize,
                              height: maxSize,
                              child: _CategoryBox(
                                selectedCategory: _selectedCategory,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Right side: Numpad or Categories
                  Expanded(
                    child:
                        _showCategories
                            ? _CategoriesGrid(
                              selectedCategory: _selectedCategory,
                              onCategorySelected: (category) {
                                setState(() {
                                  _selectedCategory = category;
                                });
                              },
                            )
                            : _CustomNumpad(
                              onNumberTap: _onNumberTap,
                              onDecimalTap: _onDecimalTap,
                              onBackspaceTap: _onBackspaceTap,
                            ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _showCategories
                ? Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _showCategories = false;
                              _selectedCategory = null;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black,
                            side: const BorderSide(
                              color: Colors.black,
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            'Back',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed:
                              _selectedCategory != null
                                  ? () {
                                    Navigator.pop(context);
                                    // TODO: Handle the selected category and amount
                                  }
                                  : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A202C),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey[300],
                            disabledForegroundColor: Colors.grey[500],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Done',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
                : SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _showCategories = true;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A202C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Select Category',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

// Categories data - shared across widgets
const List<Map<String, String>> _categories = [
  {'emoji': '🍔', 'name': 'Food'},
  {'emoji': '🚗', 'name': 'Transport'},
  {'emoji': '🛍️', 'name': 'Shopping'},
  {'emoji': '🏠', 'name': 'Housing'},
  {'emoji': '💊', 'name': 'Health'},
  {'emoji': '🎬', 'name': 'Entertainment'},
  {'emoji': '💳', 'name': 'Bills'},
  {'emoji': '☕', 'name': 'Drinks'},
  {'emoji': '🎓', 'name': 'Education'},
  {'emoji': '💇', 'name': 'Personal'},
  {'emoji': '🎁', 'name': 'Gifts'},
  {'emoji': '📱', 'name': 'Tech'},
];

String? _getEmojiForCategory(String? categoryName) {
  if (categoryName == null) return null;
  final category = _categories.firstWhere(
    (cat) => cat['name'] == categoryName,
    orElse: () => {'emoji': '', 'name': ''},
  );
  return category['emoji'];
}

class _CategoryBox extends StatelessWidget {
  final String? selectedCategory;

  const _CategoryBox({required this.selectedCategory});

  @override
  Widget build(BuildContext context) {
    final emoji = _getEmojiForCategory(selectedCategory);
    final hasCategory =
        selectedCategory != null && emoji != null && emoji.isNotEmpty;

    return hasCategory
        ? Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 40)),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  selectedCategory!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        )
        : CustomPaint(
          painter: _DashedBorderPainter(
            color: Colors.grey[400]!,
            strokeWidth: 2,
            dashWidth: 6,
            dashSpace: 4,
            borderRadius: 12,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.category, size: 32, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  'Category',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final double borderRadius;

  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashSpace,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke;

    final path =
        Path()..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, size.width, size.height),
            Radius.circular(borderRadius),
          ),
        );

    final dashPath = _createDashedPath(path);
    canvas.drawPath(dashPath, paint);
  }

  Path _createDashedPath(Path source) {
    final dashPath = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final length = dashWidth;
        if (distance + length > metric.length) {
          dashPath.addPath(
            metric.extractPath(distance, metric.length),
            Offset.zero,
          );
        } else {
          dashPath.addPath(
            metric.extractPath(distance, distance + length),
            Offset.zero,
          );
        }
        distance += dashWidth + dashSpace;
      }
    }
    return dashPath;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CategoriesGrid extends StatelessWidget {
  final String? selectedCategory;
  final Function(String) onCategorySelected;

  const _CategoriesGrid({
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Select Category',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = selectedCategory == category['name'];
              return _CategoryItem(
                emoji: category['emoji']!,
                name: category['name']!,
                isSelected: isSelected,
                onTap: () => onCategorySelected(category['name']!),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final String emoji;
  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryItem({
    required this.emoji,
    required this.name,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            Text(
              name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.black,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomNumpad extends StatelessWidget {
  final Function(String) onNumberTap;
  final VoidCallback onDecimalTap;
  final VoidCallback onBackspaceTap;

  const _CustomNumpad({
    required this.onNumberTap,
    required this.onDecimalTap,
    required this.onBackspaceTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enter Amount',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        // Row 1: 1, 2, 3
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _NumpadButton(label: '1', onTap: () => onNumberTap('1')),
            const SizedBox(width: 8),
            _NumpadButton(label: '2', onTap: () => onNumberTap('2')),
            const SizedBox(width: 8),
            _NumpadButton(label: '3', onTap: () => onNumberTap('3')),
          ],
        ),
        const SizedBox(height: 8),
        // Row 2: 4, 5, 6
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _NumpadButton(label: '4', onTap: () => onNumberTap('4')),
            const SizedBox(width: 8),
            _NumpadButton(label: '5', onTap: () => onNumberTap('5')),
            const SizedBox(width: 8),
            _NumpadButton(label: '6', onTap: () => onNumberTap('6')),
          ],
        ),
        const SizedBox(height: 8),
        // Row 3: 7, 8, 9
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _NumpadButton(label: '7', onTap: () => onNumberTap('7')),
            const SizedBox(width: 8),
            _NumpadButton(label: '8', onTap: () => onNumberTap('8')),
            const SizedBox(width: 8),
            _NumpadButton(label: '9', onTap: () => onNumberTap('9')),
          ],
        ),
        const SizedBox(height: 8),
        // Row 4: ., 0, backspace
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _NumpadButton(label: '.', onTap: onDecimalTap),
            const SizedBox(width: 8),
            _NumpadButton(label: '0', onTap: () => onNumberTap('0')),
            const SizedBox(width: 8),
            _NumpadButton(
              label: '',
              icon: Icons.backspace_outlined,
              onTap: onBackspaceTap,
            ),
          ],
        ),
      ],
    );
  }
}

class _NumpadButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;

  const _NumpadButton({required this.label, this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 56,
            alignment: Alignment.center,
            child:
                icon != null
                    ? Icon(icon, size: 24, color: Colors.black)
                    : Text(
                      label,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
          ),
        ),
      ),
    );
  }
}
