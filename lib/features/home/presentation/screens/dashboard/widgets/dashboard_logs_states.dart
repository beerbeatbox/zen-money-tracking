import 'package:flutter/material.dart';

class DashboardEmptyLogs extends StatelessWidget {
  const DashboardEmptyLogs({super.key, required this.monthYearLabel});

  final String monthYearLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Text(
          'Add your first log for $monthYearLabel.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }
}

class DashboardLogsLoading extends StatelessWidget {
  const DashboardLogsLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black),
      ),
    );
  }
}

class DashboardLogsError extends StatelessWidget {
  const DashboardLogsError({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Let\'s try that again.',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: onRetry,
          child: const Text(
            'Reload logs',
            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black),
          ),
        ),
      ],
    );
  }
}


