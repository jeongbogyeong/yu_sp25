import 'package:flutter/material.dart';
import 'db.dart';
import 'models.dart';
import 'seeds.dart';

void main() async {
  await DB.init();

  if(DB.transactions.isEmpty){
    await seedSampleData(months: 3, perMonth: 120);
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override Widget build(BuildContext context) {
    return MaterialApp(
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('가계부')),
      body: Center(
        child: FilledButton(
          onPressed: () async {
            final now = DateTime.now();
            final tx = MoneyTx(
              id: '${now.millisecondsSinceEpoch}',
              categoryId: 'exp:food',
              amount: 12000,
              memo: '테스트 점심',
              occurredAt: now,
              createdAt: now,
              accountId: 'cash',
            );
            await DB.transactions.put(tx.id, tx);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('저장 완료')),
              );
            }
          },
          child: const Text('거래 1건 저장'),
        ),
      ),
    );
  }
}

