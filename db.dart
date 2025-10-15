import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models.dart';

class DB {
  static late Box<AppSettings> settings;
  static late Box<Category> categories;
  static late Box<MoneyTx> transactions;
  static late Box<Account> accounts;

  static Future<void> init() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Hive.initFlutter(); // hive_flutter 사용시 간단 초기화

    // 어댑터 등록 (models.g.dart가 생성되어 있어야 함)
    Hive
      ..registerAdapter(TxTypeAdapter())
      ..registerAdapter(CategoryAdapter())
      ..registerAdapter(AccountAdapter())
      ..registerAdapter(MoneyTxAdapter())
      ..registerAdapter(AppSettingsAdapter());

    settings     = await Hive.openBox<AppSettings>('settingsBox');
    categories   = await Hive.openBox<Category>('categoriesBox');
    transactions = await Hive.openBox<MoneyTx>('transactionsBox');
    accounts     = await Hive.openBox<Account>('accountsBox');

    // 기본 시드 (비어있을 때만)
    if (categories.isEmpty) {
      await categories.put('exp:food', Category(id:'exp:food', name:'식비', type:TxType.expense));
      await categories.put('inc:salary', Category(id:'inc:salary', name:'월급', type:TxType.income));
    }
    if (accounts.isEmpty) {
      await accounts.put('cash', Account(id:'cash', name:'현금'));
    }
    if (settings.isEmpty) {
      await settings.put('app', AppSettings());
    }
  }
}
