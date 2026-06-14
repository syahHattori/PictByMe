import 'dart:async';

class PinUpdateBus {
  PinUpdateBus._();
  static final PinUpdateBus _instance = PinUpdateBus._();
  static PinUpdateBus get instance => _instance;

  final StreamController<Map<String, dynamic>> _ctrl = StreamController.broadcast();

  Stream<Map<String, dynamic>> get stream => _ctrl.stream;

  void emit(Map<String, dynamic> pin) {
    if (!_ctrl.isClosed) _ctrl.add(pin);
  }

  void dispose() {
    _ctrl.close();
  }
}
