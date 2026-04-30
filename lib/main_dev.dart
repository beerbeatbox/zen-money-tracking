import 'main.dart';

void main() {
  final config = AppConfig(
    environment: Environment.dev,
    apiBaseUrl: 'https://dev-api.example.com',
    appTitle: 'Baht Dev',
  );
  mainCommon(config);
}
