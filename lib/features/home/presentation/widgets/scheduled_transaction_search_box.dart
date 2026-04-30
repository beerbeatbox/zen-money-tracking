import 'package:baht/core/constants/app_sizes.dart';
import 'package:baht/core/extensions/widget_extension.dart';
import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';

class ScheduledTransactionSearchBox extends StatelessWidget {
  const ScheduledTransactionSearchBox({
    super.key,
    this.controller,
    this.onTap,
    this.autofocus = false,
  }) : assert(
         (controller != null && onTap == null) ||
             (controller == null && onTap != null),
         'Either controller or onTap must be provided, but not both',
       );

  final TextEditingController? controller;
  final VoidCallback? onTap;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final container = Container(
      height: Sizes.kSearchBoxHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const HeroIcon(
            HeroIcons.magnifyingGlass,
            style: HeroIconStyle.outline,
            color: Colors.black,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                controller != null
                    ? TextField(
                      controller: controller,
                      autofocus: autofocus,
                      textAlignVertical: TextAlignVertical.center,
                      decoration: const InputDecoration(
                        hintText: 'Search by name or amount',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        hintStyle: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    )
                    : Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Search by name or amount',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
          ),
        ],
      ),
    );

    return onTap != null ? container.onTap(onTap: onTap) : container;
  }
}
