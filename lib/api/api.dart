class API{
  static const hostConnect ="http://192.168.0.133/api_users"; //내 ip주소
  static const hostConnectUser = "$hostConnect/users";


  static const signup = "$hostConnectUser/signup.php";
  static const fetchUser = "$hostConnectUser/fetch_user.php";
  static const login = "$hostConnectUser/login.php";
  static const getSpending = "$hostConnectUser/get_spending.php";
  static const fetchSpending = "$hostConnectUser/fetch_spending.php";
}