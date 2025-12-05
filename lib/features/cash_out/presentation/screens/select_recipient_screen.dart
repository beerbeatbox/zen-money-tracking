import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:anti/core/extensions/widget_extension.dart';

enum RecipientType {
  myAccount('บัญชีของฉัน'),
  bankAccount('บัญชีธนาคาร'),
  promptPay('พร้อมเพย์'),
  favorites('รายการโปรด'),
  groupTransfer('โอนเงินกลุ่ม');

  final String label;
  const RecipientType(this.label);
}

class SelectRecipientScreen extends StatefulWidget {
  const SelectRecipientScreen({super.key});

  @override
  State<SelectRecipientScreen> createState() => _SelectRecipientScreenState();
}

class _SelectRecipientScreenState extends State<SelectRecipientScreen> {
  RecipientType _selectedType = RecipientType.myAccount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'เลือกผู้รับเงิน',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.2,
            ),
            itemCount: RecipientType.values.length,
            itemBuilder: (context, index) {
              final type = RecipientType.values[index];
              return _SelectionButton(
                text: type.label,
                isSelected: _selectedType == type,
                onTap: () => setState(() => _selectedType = type),
              );
            },
          ).paddingAll(16.0),
          const Divider(height: 1),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedType) {
      case RecipientType.bankAccount:
        return ListView(
          children: const [
            _BankListItem(
              name: 'ธนาคารออมสิน',
              color: Colors.pink,
              icon: Icons.savings,
            ),
            _BankListItem(
              name: 'ธนาคารกสิกรไทย',
              color: Colors.green,
              icon: Icons.grass,
            ),
            _BankListItem(
              name: 'ธนาคารกรุงไทย',
              color: Colors.lightBlue,
              icon: Icons.water_drop,
            ),
          ],
        );
      case RecipientType.myAccount:
        return const Center(child: Text('รายการบัญชีของฉัน'));
      case RecipientType.promptPay:
        return const Center(child: Text('รายการพร้อมเพย์'));
      case RecipientType.favorites:
        return const Center(child: Text('รายการโปรด'));
      case RecipientType.groupTransfer:
        return const Center(child: Text('โอนเงินกลุ่ม'));
    }
  }
}

class _SelectionButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectionButton({
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? Colors.pink[50] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Colors.pink : Colors.grey[300]!,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isSelected ? Colors.pink : Colors.black87,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    ).onTap(onTap);
  }
}

class _BankListItem extends StatelessWidget {
  final String name;
  final Color color;
  final IconData icon;

  const _BankListItem({
    required this.name,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        name,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    );
  }
}
