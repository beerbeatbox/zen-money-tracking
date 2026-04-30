import 'main.dart';

void main() {
  final config = AppConfig(
    environment: Environment.prod,
    apiBaseUrl: 'https://api.example.com',
    appTitle: 'Baht',
  );
  mainCommon(config);
}
