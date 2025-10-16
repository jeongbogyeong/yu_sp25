abstract class UserDataSource {
  Future<bool> registerUserToMySQL(Map<String, dynamic> userData);
  Future<Map<String, dynamic>?> fetchUserFromMySQL(String uid);
  Future<Map<String, dynamic>?> loginUserToMySQL(String email, String password);
  Future<List<Map<String, dynamic>>?> getSpendingFromMySQL(int uid);
  Future<bool> fetchSpendingFromMySQL(Map<String, dynamic> userData);
}