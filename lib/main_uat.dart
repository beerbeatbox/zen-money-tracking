import 'main.dart';

void main() {
  final config = AppConfig(
    environment: Environment.uat,
    apiBaseUrl: 'https://uat-api.example.com',
    appTitle: 'Baht UAT',
  );
  mainCommon(config);
}
