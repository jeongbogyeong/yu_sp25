import 'package:flutter/material.dart';

class TransactionDetailScreen extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;

  const TransactionDetailScreen({
    super.key,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("최근 거래 내역")),
      body: ListView.separated(
        itemCount: transactions.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final tx = transactions[index];
          final isExpense = tx['amount'] < 0;

          return ListTile(
            leading: Icon(tx['icon'], color: tx['color']),
            title: Text(tx['title']),
            subtitle: Text(tx['date']),
            trailing: Text(
              "${tx['amount'] > 0 ? '+' : ''}${tx['amount']}원",
              style: TextStyle(
                color: isExpense ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),
    );
  }
}
