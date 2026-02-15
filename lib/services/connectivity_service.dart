import 'dart:async';
import 'dart:developer' as developer;

import 'package:connectivity_plus/connectivity_plus.dart';

/// خدمة مراقبة حالة الاتصال بالإنترنت.
///
/// توفر Stream للاستماع لتغييرات الاتصال وتحديث الـ UI تلقائياً.
class ConnectivityService {
  ConnectivityService._();

  static final ConnectivityService instance = ConnectivityService._();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// Stream لحالة الاتصال (true = متصل، false = غير متصل).
  final StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();

  Stream<bool> get connectivityStream => _connectivityController.stream;

  bool _isConnected = true;

  /// الحصول على حالة الاتصال الحالية.
  bool get isConnected => _isConnected;

  /// بدء مراقبة حالة الاتصال.
  Future<void> initialize() async {
    // التحقق من الحالة الأولية
    final result = await _connectivity.checkConnectivity();
    _updateConnectionStatus(result);

    // الاستماع للتغييرات
    _subscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
      onError: (error) {
        developer.log(
          'Error in connectivity stream: $error',
          name: 'sohba.connectivity',
          level: 900,
        );
      },
    );

    developer.log(
      'ConnectivityService initialized',
      name: 'sohba.connectivity',
    );
  }

  /// تحديث حالة الاتصال بناءً على نتيجة الفحص.
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    // نعتبر المستخدم متصلاً إذا كان لديه أي نوع من الاتصال (WiFi أو Mobile)
    final hasConnection = results.any(
      (result) =>
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.ethernet,
    );

    if (_isConnected != hasConnection) {
      _isConnected = hasConnection;
      _connectivityController.add(_isConnected);

      developer.log(
        _isConnected ? 'Connected to internet' : 'Disconnected from internet',
        name: 'sohba.connectivity',
      );
    }
  }

  /// إيقاف المراقبة وتنظيف الموارد.
  void dispose() {
    _subscription?.cancel();
    _connectivityController.close();
  }
}
