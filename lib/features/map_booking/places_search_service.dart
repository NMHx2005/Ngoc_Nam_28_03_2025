import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class PlaceSuggestion {
  const PlaceSuggestion({
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
    required this.fullText,
  });

  final String placeId;
  final String mainText;
  final String secondaryText;
  final String fullText;
}

class AddressSearchResult {
  const AddressSearchResult({required this.position, required this.label});

  final LatLng position;
  final String label;
}

/// Tìm địa chỉ qua Places Autocomplete + resolve lat/lng bằng Place Details.
///
/// Nếu user nhập địa chỉ tự do (không chọn suggestion), dùng Geocoding API.
class PlacesSearchService {
  PlacesSearchService(this._apiKey);

  final String _apiKey;

  bool get enabled => _apiKey.isNotEmpty;

  Future<List<PlaceSuggestion>> autocomplete(
    String input, {
    LatLng? around,
  }) async {
    if (!enabled || input.trim().isEmpty) return const [];
    final query = <String, String>{
      'input': input.trim(),
      'key': _apiKey,
      'language': 'vi',
      'components': 'country:vn',
    };
    if (around != null) {
      query['location'] = '${around.latitude},${around.longitude}';
      query['radius'] = '20000';
    }
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/autocomplete/json',
      query,
    );
    try {
      final res = await http.get(uri);
      if (res.statusCode != 200) return const [];
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final status = data['status'] as String?;
      if (status != 'OK' && status != 'ZERO_RESULTS') return const [];
      final predictions = data['predictions'] as List<dynamic>? ?? const [];
      return predictions
          .map((raw) => _toSuggestion(raw as Map<String, dynamic>))
          .whereType<PlaceSuggestion>()
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<AddressSearchResult?> resolvePlaceId(String placeId) async {
    if (!enabled || placeId.trim().isEmpty) return null;
    final uri =
        Uri.https('maps.googleapis.com', '/maps/api/place/details/json', {
          'place_id': placeId,
          'fields': 'formatted_address,geometry/location,name',
          'language': 'vi',
          'key': _apiKey,
        });
    try {
      final res = await http.get(uri);
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['status'] != 'OK') return null;
      final result = data['result'] as Map<String, dynamic>?;
      final geometry = result?['geometry'] as Map<String, dynamic>?;
      final location = geometry?['location'] as Map<String, dynamic>?;
      final lat = (location?['lat'] as num?)?.toDouble();
      final lng = (location?['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) return null;
      final label =
          (result?['formatted_address'] as String?) ??
          (result?['name'] as String?) ??
          '$lat,$lng';
      return AddressSearchResult(position: LatLng(lat, lng), label: label);
    } catch (_) {
      return null;
    }
  }

  Future<AddressSearchResult?> geocodeText(String address) async {
    if (!enabled || address.trim().isEmpty) return null;
    final uri = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
      'address': address.trim(),
      'language': 'vi',
      'region': 'vn',
      'key': _apiKey,
    });
    try {
      final res = await http.get(uri);
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final status = data['status'] as String?;
      if (status != 'OK') return null;
      final results = data['results'] as List<dynamic>? ?? const [];
      if (results.isEmpty) return null;
      final first = results.first as Map<String, dynamic>;
      final geometry = first['geometry'] as Map<String, dynamic>?;
      final location = geometry?['location'] as Map<String, dynamic>?;
      final lat = (location?['lat'] as num?)?.toDouble();
      final lng = (location?['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) return null;
      final label = (first['formatted_address'] as String?) ?? address.trim();
      return AddressSearchResult(position: LatLng(lat, lng), label: label);
    } catch (_) {
      return null;
    }
  }

  PlaceSuggestion? _toSuggestion(Map<String, dynamic> raw) {
    final placeId = raw['place_id'] as String?;
    final structured = raw['structured_formatting'] as Map<String, dynamic>?;
    final mainText = structured?['main_text'] as String?;
    final secondaryText = structured?['secondary_text'] as String?;
    final fullText = raw['description'] as String?;
    if (placeId == null || fullText == null) return null;
    return PlaceSuggestion(
      placeId: placeId,
      mainText: mainText ?? fullText,
      secondaryText: secondaryText ?? '',
      fullText: fullText,
    );
  }
}
