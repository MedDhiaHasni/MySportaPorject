// lib/Services/location_service.dart


import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

enum LocationStatus {
  granted,        // position obtained
  serviceDisabled,// device GPS switch is off
  denied,         // user tapped "Deny"
  deniedForever,  // user tapped "Never ask again"
  pluginMissing,  // MissingPluginException — needs full rebuild
  unavailable,    // any other error (timeout, no fix, …)
}

class LocationResult {
  final LocationStatus status;
  final Position? position;
  final String? errorMessage;
  const LocationResult({required this.status, this.position, this.errorMessage});
}

class LocationService {
  LocationService._();
  static final instance = LocationService._();

  /// Full flow: service check → permission → position.
  /// Never throws. Always returns a [LocationResult].
  Future<LocationResult> requestAndGet() async {
    // ── 1. Is location service enabled on the device? ───────────────────────
    bool serviceEnabled;
    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
    } on MissingPluginException catch (e) {
      return LocationResult(status: LocationStatus.pluginMissing, errorMessage: e.message);
    } catch (e) {
      return LocationResult(status: LocationStatus.unavailable, errorMessage: e.toString());
    }

    if (!serviceEnabled) {
      return const LocationResult(status: LocationStatus.serviceDisabled);
    }

    // ── 2. Check / request permission ────────────────────────────────────────
    LocationPermission permission;
    try {
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
    } on MissingPluginException catch (e) {
      return LocationResult(status: LocationStatus.pluginMissing, errorMessage: e.message);
    } catch (e) {
      return LocationResult(status: LocationStatus.unavailable, errorMessage: e.toString());
    }

    if (permission == LocationPermission.denied) {
      return const LocationResult(status: LocationStatus.denied);
    }
    if (permission == LocationPermission.deniedForever) {
      return const LocationResult(status: LocationStatus.deniedForever);
    }

    // ── 3. Get position ───────────────────────────────────────────────────────
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      return LocationResult(status: LocationStatus.granted, position: pos);
    } on MissingPluginException catch (e) {
      return LocationResult(status: LocationStatus.pluginMissing, errorMessage: e.message);
    } on LocationServiceDisabledException {
      return const LocationResult(status: LocationStatus.serviceDisabled);
    } catch (e) {
      return LocationResult(status: LocationStatus.unavailable, errorMessage: e.toString());
    }
  }

  /// Open device GPS settings (safe).
  Future<void> openLocationSettings() async {
    try { await Geolocator.openLocationSettings(); } catch (_) {}
  }

  /// Open app permission settings (safe).
  Future<void> openAppSettings() async {
    try { await Geolocator.openAppSettings(); } catch (_) {}
  }
}