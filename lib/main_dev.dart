import 'main.dart';

void main() {
  final config = AppConfig(
    environment: Environment.dev,
    apiBaseUrl: 'https://dev-api.example.com',
    appTitle: 'Anti Dev',
  );
  mainCommon(config);
}
