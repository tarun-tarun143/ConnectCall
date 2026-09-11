import 'package:connect_call/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ConnectCall uses the configured ZEGOCLOUD AppID', () {
    expect(AppConfig.zegoAppId, 503220443);
  });
}
