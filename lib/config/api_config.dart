class ApiConfig {
  // Android emulator's special alias for your PC's localhost
  static const String _emulatorBaseUrl = 'http://10.0.2.2:3000';

  // Your PC's actual Wi-Fi IP — used when testing on a physical phone
  static const String _physicalDeviceBaseUrl = 'http://192.168.8.190:3000';

  // Flip this manually depending on what you're testing on right now
  static const bool useEmulator = true;

  static String get baseUrl =>
      useEmulator ? _emulatorBaseUrl : _physicalDeviceBaseUrl;
}