import 'dart:async';

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
import 'directions_route_service.dart';
import 'map_route_polylines.dart';
import 'places_search_service.dart';

class _BookingDraft {
  const _BookingDraft({required this.priceVnd, required this.vehicleType});
  final int priceVnd;
  final String vehicleType;
}

String _formatVnd(int v) {
  final s = v.toString();
  return s.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]}.',
  );
}

/// D4: card bottom sheet — km, giá, dropdown loại xe; chặn double-tap nút Đặt xe.
class _TripBookingBottomSheet extends StatefulWidget {
  const _TripBookingBottomSheet({required this.km, required this.laGioCaoDiem});

  final double km;
  final bool laGioCaoDiem;

  @override
  State<_TripBookingBottomSheet> createState() =>
      _TripBookingBottomSheetState();
}

class _TripBookingBottomSheetState extends State<_TripBookingBottomSheet> {
  String _vehicleType = VehicleTypes.bike;
  bool _dangXacNhan = false;

  @override
  Widget build(BuildContext context) {
    final km = widget.km;
    final peak = widget.laGioCaoDiem;
    final price = PricingEngine.calculate(
      distanceKm: km,
      vehicleType: _vehicleType,
      isPeakHour: peak,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Xác nhận đặt xe',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text('Khoảng cách (ước lượng): ${km.toStringAsFixed(2)} km'),
            Text(
              'Giờ cao điểm: ${peak ? "Có (+${((PricingEngine.heSoGioCaoDiem - 1) * 100).toInt()}%)" : "Không"}',
            ),
            const SizedBox(height: 12),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Loại xe',
                border: OutlineInputBorder(),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _vehicleType,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                      value: VehicleTypes.bike,
                      child: Text('Xe máy'),
                    ),
                    DropdownMenuItem(
                      value: VehicleTypes.car,
                      child: Text('Ô tô'),
                    ),
                  ],
                  onChanged: _dangXacNhan
                      ? null
                      : (v) {
                          if (v != null) setState(() => _vehicleType = v);
                        },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Giá ước tính: ${_formatVnd(price)} đ',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _dangXacNhan
                  ? null
                  : () {
                      setState(() => _dangXacNhan = true);
                      final finalPrice = PricingEngine.calculate(
                        distanceKm: km,
                        vehicleType: _vehicleType,
                        isPeakHour: peak,
                      );
                      Navigator.pop(
                        context,
                        _BookingDraft(
                          priceVnd: finalPrice,
                          vehicleType: _vehicleType,
                        ),
                      );
                    },
              child: _dangXacNhan
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Đặt xe'),
            ),
          ],
        ),
      ),
    );
  }
}

/// TP.HCM — vị trí mặc định khi chưa lấy được GPS.
const LatLng _fallbackCenter = LatLng(10.7769, 106.7009);

/// Khóa cho Places + Geocoding REST API:
/// `flutter run --dart-define=PLACES_API_KEY=your_key`.
const String _kPlacesApiKey = String.fromEnvironment(
  'PLACES_API_KEY',
  defaultValue: '',
);

/// C4 tuỳ chọn: `flutter run --dart-define=DIRECTIONS_API_KEY=your_key`.
/// Nếu không truyền riêng thì fallback dùng `PLACES_API_KEY`.
const String _kDirectionsApiKey = String.fromEnvironment(
  'DIRECTIONS_API_KEY',
  defaultValue: _kPlacesApiKey,
);

enum _SearchTarget { pickup, dropoff }

class _AddressSearchBottomSheet extends StatefulWidget {
  const _AddressSearchBottomSheet({
    required this.service,
    required this.target,
    required this.near,
  });

  final PlacesSearchService service;
  final _SearchTarget target;
  final LatLng? near;

  @override
  State<_AddressSearchBottomSheet> createState() =>
      _AddressSearchBottomSheetState();
}

class _AddressSearchBottomSheetState extends State<_AddressSearchBottomSheet> {
  late final TextEditingController _controller;
  List<PlaceSuggestion> _suggestions = const [];
  bool _loading = false;
  String? _error;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _lookup(String input) async {
    if (input.trim().isEmpty) {
      setState(() {
        _loading = false;
        _error = null;
        _suggestions = const [];
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final results = await widget.service.autocomplete(
      input,
      around: widget.near,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _suggestions = results;
      if (results.isEmpty) {
        _error = 'Không thấy gợi ý phù hợp.';
      }
    });
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _lookup(value);
    });
  }

  Future<void> _pickSuggestion(PlaceSuggestion suggestion) async {
    setState(() => _loading = true);
    final resolved = await widget.service.resolvePlaceId(suggestion.placeId);
    if (!mounted) return;
    if (resolved == null) {
      setState(() {
        _loading = false;
        _error = 'Không lấy được tọa độ từ gợi ý đã chọn.';
      });
      return;
    }
    Navigator.of(context).pop<AddressSearchResult>(resolved);
  }

  Future<void> _geocodeTypedAddress() async {
    final raw = _controller.text.trim();
    if (raw.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final resolved = await widget.service.geocodeText(raw);
    if (!mounted) return;
    if (resolved == null) {
      setState(() {
        _loading = false;
        _error = 'Không geocode được địa chỉ này.';
      });
      return;
    }
    Navigator.of(context).pop<AddressSearchResult>(resolved);
  }

  @override
  Widget build(BuildContext context) {
    final targetLabel = widget.target == _SearchTarget.pickup
        ? 'điểm đón'
        : 'điểm đến';
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SizedBox(
          height: 460,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tìm $targetLabel',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: _onChanged,
                onSubmitted: (_) => _geocodeTypedAddress(),
                decoration: InputDecoration(
                  hintText: 'Nhập địa chỉ, tên địa điểm...',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: _geocodeTypedAddress,
                    icon: const Icon(Icons.search),
                    tooltip: 'Tìm theo địa chỉ nhập',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              FilledButton.tonalIcon(
                onPressed: _loading ? null : _geocodeTypedAddress,
                icon: const Icon(Icons.pin_drop_outlined),
                label: const Text('Dùng đúng địa chỉ vừa nhập'),
              ),
              const SizedBox(height: 10),
              if (_loading) const LinearProgressIndicator(),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Expanded(
                child: _suggestions.isEmpty
                    ? const Center(
                        child: Text('Gõ vài ký tự để xem gợi ý địa điểm.'),
                      )
                    : ListView.separated(
                        itemCount: _suggestions.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = _suggestions[index];
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.location_on_outlined),
                            title: Text(
                              item.mainText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              item.secondaryText.isNotEmpty
                                  ? item.secondaryText
                                  : item.fullText,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => _pickSuggestion(item),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MapBookingScreen extends StatefulWidget {
  const MapBookingScreen({super.key});

  @override
  State<MapBookingScreen> createState() => _MapBookingScreenState();
}

class _MapBookingScreenState extends State<MapBookingScreen> {
  final PlacesSearchService _placesService = PlacesSearchService(
    _kPlacesApiKey,
  );
  GoogleMapController? _mapController;

  /// GPS lần đọc gần nhất — không đổi khi user chạm map (đáp ứng C2: marker “vị trí hiện tại”).
  LatLng? _deviceLocation;
  // C3: tọa độ đặt xe — StatefulWidget (không dùng Provider cho map state).
  LatLng? _pickup;
  LatLng? _dropoff;
  String? _pickupLabel;
  String? _dropoffLabel;

  /// `false` = chạm map đặt điểm đón (xanh); `true` = chạm map đặt điểm đến (đỏ).
  bool _selectingDropoff = false;
  bool _locLoading = true;
  String? _locError;
  bool _submitting = false;

  /// C4: điểm polyline từ Directions API; `null` = chỉ dùng đường thẳng.
  List<LatLng>? _directionsPoints;
  bool _directionsLoading = false;

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
        if (mounted) {
          setState(() {
            _locError =
                'Quyền vị trí bị từ chối. Có thể bật trong Cài đặt hoặc chọn điểm trên bản đồ.';
            _locLoading = false;
          });
          await _showLocationHelpDialog(
            title: 'Cần quyền vị trí',
            message:
                'Ứng dụng cần quyền vị trí để đưa bản đồ về chỗ bạn đang đứng. '
                'Bạn vẫn có thể chọn điểm đón bằng cách chạm bản đồ.',
            openSettings: Geolocator.openAppSettings,
          );
        }
        return;
      }
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        if (mounted) {
          setState(() {
            _locError = 'Hãy bật GPS / định vị trên thiết bị.';
            _locLoading = false;
          });
          await _showLocationHelpDialog(
            title: 'GPS đang tắt',
            message:
                'Bật dịch vụ định vị trong Cài đặt hệ thống để xem vị trí hiện tại.',
            openSettings: Geolocator.openLocationSettings,
          );
        }
        return;
      }
      // Độ chính xác vừa phải, nhanh hơn cho màn đặt xe.
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final here = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() {
        _deviceLocation = here;
        _pickup ??= here; // Gợi ý điểm đón = chỗ đang đứng
        _locLoading = false;
      });
      await _mapController?.animateCamera(CameraUpdate.newLatLngZoom(here, 14));
      _afterStopsUpdated();
    } catch (e) {
      if (mounted) {
        setState(() {
          _locError = 'Không lấy được vị trí: $e';
          _locLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Vị trí: $e')));
      }
    }
  }

  Future<void> _showLocationHelpDialog({
    required String title,
    required String message,
    required Future<void> Function() openSettings,
  }) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await openSettings();
            },
            child: const Text('Mở cài đặt'),
          ),
        ],
      ),
    );
  }

  /// C4: đường thẳng luôn dùng được; nếu có `DIRECTIONS_API_KEY` thì thử vẽ theo đường bộ.
  void _afterStopsUpdated() {
    final a = _pickup;
    final b = _dropoff;
    if (a == null || b == null) {
      if (_directionsPoints != null || _directionsLoading) {
        setState(() {
          _directionsPoints = null;
          _directionsLoading = false;
        });
      }
      return;
    }

    if (_kDirectionsApiKey.isEmpty) {
      if (_directionsPoints != null || _directionsLoading) {
        setState(() {
          _directionsPoints = null;
          _directionsLoading = false;
        });
      }
      return;
    }

    setState(() {
      _directionsPoints = null;
      _directionsLoading = true;
    });

    final origin = a;
    final dest = b;
    DirectionsRouteService(
      _kDirectionsApiKey,
    ).fetchRoutePoints(origin, dest).then((pts) {
      if (!mounted) return;
      if (_pickup != origin || _dropoff != dest) return;
      setState(() {
        _directionsLoading = false;
        _directionsPoints = (pts != null && pts.length >= 2) ? pts : null;
      });
    });
  }

  Future<void> _openAddressSearch(_SearchTarget target) async {
    if (_kPlacesApiKey.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Thiếu PLACES_API_KEY. Chạy lại app với --dart-define=PLACES_API_KEY=...',
          ),
        ),
      );
      return;
    }

    final picked = await showModalBottomSheet<AddressSearchResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddressSearchBottomSheet(
        service: _placesService,
        target: target,
        near: _pickup ?? _deviceLocation,
      ),
    );
    if (picked == null || !mounted) return;

    setState(() {
      if (target == _SearchTarget.pickup) {
        _pickup = picked.position;
        _pickupLabel = picked.label;
      } else {
        _dropoff = picked.position;
        _dropoffLabel = picked.label;
      }
    });
    await _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(picked.position, 15),
    );
    _afterStopsUpdated();
  }

  /// Marker: Azure = GPS (C2); xanh = pickup, đỏ = dropoff (C3).
  Set<Marker> get _markers {
    final s = <Marker>{};
    if (_deviceLocation != null) {
      s.add(
        Marker(
          markerId: const MarkerId('device'),
          position: _deviceLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: const InfoWindow(title: 'Vị trí của bạn (GPS)'),
        ),
      );
    }
    if (_pickup != null) {
      s.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: _pickup!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: InfoWindow(title: 'Điểm đón', snippet: _pickupLabel),
        ),
      );
    }
    if (_dropoff != null) {
      s.add(
        Marker(
          markerId: const MarkerId('dropoff'),
          position: _dropoff!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: 'Điểm đến', snippet: _dropoffLabel),
        ),
      );
    }
    return s;
  }

  Set<Polyline> get _polylines {
    final a = _pickup;
    final b = _dropoff;
    if (a == null || b == null) return {};

    final road = _directionsPoints;
    if (road != null && road.length >= 2) {
      return {
        Polyline(
          polylineId: const PolylineId('directions'),
          color: Colors.blue.shade800,
          width: 5,
          points: road,
        ),
      };
    }
    return {buildStraightRoutePolyline(pickup: a, dropoff: b)};
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
          child: _TripBookingBottomSheet(km: km, laGioCaoDiem: peak),
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
      final id = await context.read<TripRepository>().createTrip(trip);
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => TripDetailScreen(tripId: id)),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không tạo được chuyến: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
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
          // Dấu chấm xanh của SDK + marker Azure “Vị trí của bạn” (C2).
          myLocationButtonEnabled: true,
          myLocationEnabled: true,
          onMapCreated: (c) {
            _mapController = c;
            // Tránh race: GPS về trước khi map tạo xong — camera vẫn nhảy tới đúng chỗ.
            final target = _pickup ?? _deviceLocation;
            if (target != null) {
              c.animateCamera(CameraUpdate.newLatLngZoom(target, 14));
            }
          },
          // C3: tap map — pickup (xanh) hoặc dropoff (đỏ) tùy chế độ.
          onTap: (pos) {
            setState(() {
              if (_selectingDropoff) {
                _dropoff = pos;
                _dropoffLabel = null;
              } else {
                _pickup = pos;
                _pickupLabel = null;
              }
            });
            _afterStopsUpdated();
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
                  if (_locLoading) const LinearProgressIndicator(),
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
                  if (_pickup != null &&
                      _dropoff != null &&
                      _directionsLoading) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Đang tải lộ trình đường bộ…',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                  if (_pickupLabel != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Điểm đón: $_pickupLabel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                  if (_dropoffLabel != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Điểm đến: $_dropoffLabel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() => _selectingDropoff = false);
                          },
                          child: const Text('Chọn điểm đón'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() => _selectingDropoff = true);
                          },
                          child: const Text('Chọn điểm đến'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _openAddressSearch(_SearchTarget.pickup),
                          icon: const Icon(Icons.search),
                          label: const Text('Tìm điểm đón'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _openAddressSearch(_SearchTarget.dropoff),
                          icon: const Icon(Icons.search),
                          label: const Text('Tìm điểm đến'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _pickup = null;
                        _dropoff = null;
                        _pickupLabel = null;
                        _dropoffLabel = null;
                        _selectingDropoff = false;
                        _directionsPoints = null;
                        _directionsLoading = false;
                      });
                    },
                    child: const Text('Xóa lựa chọn'),
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
