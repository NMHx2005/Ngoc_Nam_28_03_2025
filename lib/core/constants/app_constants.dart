/// Trạng thái chuyến (demo — không có app tài xế thật).
abstract class TripStatuses {
  static const findingDriver = 'finding_driver';
  static const accepted = 'accepted';
  /// Demo: tài xế đã nhận và đang tới điểm đón.
  static const driverArriving = 'driver_arriving';
  static const inProgress = 'in_progress';
  static const completed = 'completed';
  static const cancelled = 'cancelled';
}

abstract class VehicleTypes {
  static const bike = 'bike';
  static const car = 'car';
}
