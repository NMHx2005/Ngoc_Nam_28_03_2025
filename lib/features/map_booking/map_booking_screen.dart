import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/geo/distance.dart';
import '../../core/pricing/pricing_engine.dart';
import '../../data/repositories/trip_repository.dart';
import '../../models/trip.dart';
import '../trip_detail/trip_detail_screen.dart';

class _BookingDraft {
  const _BookingDraft({required this.priceVnd, required this.vehicleType});
  final int priceVnd;
  final String vehicleType;
}

/// TP.HCM — vị trí mặc định khi chưa lấy được GPS.
const LatLng _fallbackCenter = LatLng(10.7769, 106.7009);

class MapBookingScreen extends StatefulWidget {
  const MapBookingScreen({super.key});

  @override
  State<MapBookingScreen> createState() => _MapBookingScreenState();
}

class _MapBookingScreenState extends State<MapBookingScreen> {
  GoogleMapController? _mapController;
  LatLng? _pickup;
  LatLng? _dropoff;
  bool _selectingDropoff = false;
  bool _locLoading = true;
  String? _locError;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    setState(() {
      _locLoading = true;
      _locError = null;
    });
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        setState(() {
          _locError =
              'Quyền vị trí bị từ chối. Bật quyền trong Cài đặt hoặc chọn điểm trên bản đồ.';
          _locLoading = false;
        });
        return;
      }
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        setState(() {
          _locError = 'Hãy bật dịch vụ định vị (GPS) trên thiết bị.';
          _locLoading = false;
        });
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      final here = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() {
        _pickup = here;
        _locLoading = false;
      });
      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(here, 14),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _locError = 'Không lấy được vị trí: $e';
          _locLoading = false;
        });
      }
    }
  }

  Set<Marker> get _markers {
    final s = <Marker>{};
    if (_pickup != null) {
      s.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: _pickup!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Điểm đón'),
        ),
      );
    }
    if (_dropoff != null) {
      s.add(
        Marker(
          markerId: const MarkerId('dropoff'),
          position: _dropoff!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Điểm đến'),
        ),
      );
    }
    return s;
  }

  Set<Polyline> get _polylines {
    if (_pickup == null || _dropoff == null) return {};
    return {
      Polyline(
        polylineId: const PolylineId('straight'),
        color: Colors.blue.shade700,
        width: 4,
        points: [_pickup!, _dropoff!],
      ),
    };
  }

  Future<void> _openBookingSheet() async {
    final pickup = _pickup;
    final dropoff = _dropoff;
    if (pickup == null || dropoff == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chọn đủ điểm đón và điểm đến.')),
      );
      return;
    }
    final km = distanceKm(pickup, dropoff);
    var vehicle = VehicleTypes.bike;
    final peak = PricingEngine.isPeakHour(DateTime.now());

    final draft = await showModalBottomSheet<_BookingDraft>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              final p = PricingEngine.calculate(
                distanceKm: km,
                vehicleType: vehicle,
                isPeakHour: peak,
              );
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Xác nhận đặt xe',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Khoảng cách (ước lượng): ${km.toStringAsFixed(2)} km',
                  ),
                  Text(
                    'Giờ cao điểm: ${peak ? "Có (+${((PricingEngine.peakMultiplier - 1) * 100).toInt()}%)" : "Không"}',
                  ),
                  const SizedBox(height: 8),
                  const Text('Loại xe'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Xe máy'),
                        selected: vehicle == VehicleTypes.bike,
                        onSelected: (_) =>
                            setModalState(() => vehicle = VehicleTypes.bike),
                      ),
                      ChoiceChip(
                        label: const Text('Ô tô'),
                        selected: vehicle == VehicleTypes.car,
                        onSelected: (_) =>
                            setModalState(() => vehicle = VehicleTypes.car),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Giá ước tính: ${_formatVnd(p)} đ',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _submitting
                        ? null
                        : () {
                            final finalPrice = PricingEngine.calculate(
                              distanceKm: km,
                              vehicleType: vehicle,
                              isPeakHour: peak,
                            );
                            Navigator.pop(
                              ctx,
                              _BookingDraft(
                                priceVnd: finalPrice,
                                vehicleType: vehicle,
                              ),
                            );
                          },
                    child: const Text('Đặt xe'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    if (draft == null || !mounted) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _submitting = true);
    try {
      final trip = Trip(
        userId: uid,
        pickupLat: pickup.latitude,
        pickupLng: pickup.longitude,
        dropoffLat: dropoff.latitude,
        dropoffLng: dropoff.longitude,
        distanceKm: km,
        priceVnd: draft.priceVnd,
        vehicleType: draft.vehicleType,
        status: TripStatuses.findingDriver,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final id =
          await context.read<TripRepository>().createTrip(trip);
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => TripDetailScreen(tripId: id),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không tạo được chuyến: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  static String _formatVnd(int v) {
    final s = v.toString();
    return s.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: _fallbackCenter,
            zoom: 12,
          ),
          markers: _markers,
          polylines: _polylines,
          myLocationButtonEnabled: true,
          myLocationEnabled: true,
          onMapCreated: (c) => _mapController = c,
          onTap: (pos) {
            setState(() {
              if (_selectingDropoff) {
                _dropoff = pos;
              } else {
                _pickup = pos;
              }
            });
          },
        ),
        Positioned(
          left: 12,
          right: 12,
          top: 12,
          child: Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_locLoading)
                    const LinearProgressIndicator(),
                  if (_locError != null)
                    Text(
                      _locError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 13,
                      ),
                    ),
                  Text(
                    _selectingDropoff
                        ? 'Chế độ: chọn điểm đến (chạm bản đồ)'
                        : 'Chế độ: chọn điểm đón (chạm bản đồ)',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() => _selectingDropoff = true);
                          },
                          child: const Text('Chọn điểm đến'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _pickup = null;
                              _dropoff = null;
                              _selectingDropoff = false;
                            });
                          },
                          child: const Text('Xóa lựa chọn'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _submitting ? null : _openBookingSheet,
                    icon: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.local_taxi),
                    label: const Text('Đặt xe & tính giá'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
