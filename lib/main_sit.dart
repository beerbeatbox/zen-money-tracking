import 'main.dart';

void main() {
  final config = AppConfig(
    environment: Environment.sit,
    apiBaseUrl: 'https://sit-api.example.com',
    appTitle: 'Baht SIT',
  );
  mainCommon(config);
}
