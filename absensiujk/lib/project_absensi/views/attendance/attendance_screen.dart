import 'package:flutter/material.dart';

import 'package:geocoding/geocoding.dart';

import 'package:geolocator/geolocator.dart';

import '../../services/api_services.dart';

import '../../services/storage_services.dart';

import '../maps_screen.dart';

class AttendanceScreen extends StatefulWidget {

  const AttendanceScreen({super.key});

  @override

  State<AttendanceScreen> createState() => _AttendanceScreenState();

}

class _AttendanceScreenState extends State<AttendanceScreen> {

  static const Color bgColor = Color(0xFFFFF7FA);

  static const Color cardColor = Color(0xFFFFEAF1);

  static const Color accentColor = Color(0xFFE89AB7);

  static const Color accentLight = Color(0xFFD96F96);

  Position? currentPosition;

  bool isLoading = false;

  bool isCheckInLoading = false;

  bool isCheckOutLoading = false;

  bool isIzinLoading = false;

  String locationAddress = 'Mendeteksi lokasi...';

  final Geocoding geocoding = Geocoding(locale: const Locale('id', 'ID'));

  @override

  void initState() {

    super.initState();

    getCurrentLocation();

  }

  Future<void> getCurrentLocation() async {

    if (!mounted) return;

    setState(() {

      isLoading = true;

      locationAddress = 'Mendeteksi lokasi...';

    });

    try {

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {

        if (!mounted) return;

        setState(() {

          locationAddress = 'GPS belum aktif';

          isLoading = false;

        });

        return;

      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {

        permission = await Geolocator.requestPermission();

      }

      if (permission == LocationPermission.denied) {

        if (!mounted) return;

        setState(() {

          locationAddress = 'Izin lokasi ditolak';

          isLoading = false;

        });

        return;

      }

      if (permission == LocationPermission.deniedForever) {

        if (!mounted) return;

        setState(() {

          locationAddress = 'Izin lokasi ditolak permanen';

          isLoading = false;

        });

        return;

      }

      final position = await Geolocator.getCurrentPosition();

      String addressText = 'Lokasi PPKD JU';

      try {

        final placemarks = await geocoding.placemarkFromCoordinates(

          position.latitude,

          position.longitude,

        );

        if (placemarks.isNotEmpty) {

          final place = placemarks.first;

          final parts = [

            place.street,

            place.subLocality,

            place.locality,

            place.subAdministrativeArea,

          ].whereType<String>().toList();

          if (parts.isNotEmpty) {

            addressText = parts.join(', ');

          }

        }

      } catch (_) {

        addressText = 'Lokasi PPKD JU';

      }

      if (!mounted) return;

      setState(() {

        currentPosition = position;

        locationAddress = addressText;

        isLoading = false;

      });

    } catch (error) {

      if (!mounted) return;

      setState(() {

        locationAddress = 'Gagal mendapatkan lokasi';

        isLoading = false;

      });

    }

  }

  Future<void> checkIn() async {

    if (currentPosition == null) {

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(content: Text('Lokasi GPS belum tersedia')),

      );

      return;

    }

    setState(() {

      isCheckInLoading = true;

    });

    try {

      final token = await StorageServices.getToken();

      if (token == null || token.isEmpty) {

        ScaffoldMessenger.of(context).showSnackBar(

          const SnackBar(content: Text('Token login tidak ditemukan')),

        );

        return;

      }

      final response = await ApiServices().checkIn(

        token: token,

        latitude: currentPosition!.latitude,

        longitude: currentPosition!.longitude,

        address: locationAddress,

      );

      if (!mounted) return;

      if (response.statusCode == 200) {

        ScaffoldMessenger.of(context)

            .showSnackBar(const SnackBar(content: Text('Check In berhasil')));

        Navigator.pop(context);

      }

    } catch (error) {

      if (!mounted) return;

      String message = 'Check In gagal';

      if (error.toString().contains('409')) {

        message = 'Anda sudah melakukan absensi hari ini';

      }

      ScaffoldMessenger.of(context)

          .showSnackBar(SnackBar(content: Text(message)));

    } finally {

      if (mounted) {

        setState(() {

          isCheckInLoading = false;

        });

      }

    }

  }

  Future<void> checkOut() async {

    if (currentPosition == null) {

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(content: Text('Lokasi GPS belum tersedia')),

      );

      return;

    }

    setState(() {

      isCheckOutLoading = true;

    });

    try {

      final token = await StorageServices.getToken();

      if (token == null || token.isEmpty) {

        ScaffoldMessenger.of(context).showSnackBar(

          const SnackBar(content: Text('Token login tidak ditemukan')),

        );

        return;

      }

      final response = await ApiServices().checkOut(

        token: token,

        latitude: currentPosition!.latitude,

        longitude: currentPosition!.longitude,

        address: locationAddress,

      );

      if (!mounted) return;

      if (response.statusCode == 200) {

        ScaffoldMessenger.of(context)

            .showSnackBar(const SnackBar(content: Text('Check Out berhasil')));

        Navigator.pop(context);

      }

    } catch (error) {

      if (!mounted) return;

      ScaffoldMessenger.of(context)

          .showSnackBar(SnackBar(content: Text('Check Out gagal: $error')));

    } finally {

      if (mounted) {

        setState(() {

          isCheckOutLoading = false;

        });

      }

    }

  }

  Future<void> izinSakit() async {

    if (currentPosition == null) {

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(content: Text('Lokasi GPS belum tersedia')),

      );

      return;

    }

    final confirm = await showDialog<bool>(

      context: context,

      builder: (context) {

        return AlertDialog(

          backgroundColor: cardColor,

          shape: RoundedRectangleBorder(

            borderRadius: BorderRadius.circular(22),

          ),

          title: const Text(

            'Izin Sakit',

            style: TextStyle(

              color: Color(0xFF54283A),

              fontWeight: FontWeight.w900,

            ),

          ),

          content: const Text(

            'Apakah kamu yakin ingin mengajukan '

            'izin sakit hari ini?',

            style: TextStyle(color: Color(0xFF9E7180)),

          ),

          actions: [

            TextButton(

              onPressed: () {

                Navigator.pop(context, false);

              },

              child: const Text(

                'Batal',

                style: TextStyle(color: Color(0xFF9E7180)),

              ),

            ),

            ElevatedButton(

              onPressed: () {

                Navigator.pop(context, true);

              },

              style: ElevatedButton.styleFrom(

                backgroundColor: Color(0xFFE58BA6),

                foregroundColor: Color(0xFF54283A),

              ),

              child: const Text('Ajukan'),

            ),

          ],

        );

      },

    );

    if (confirm != true) {

      return;

    }

    setState(() {

      isIzinLoading = true;

    });

    try {

      final token = await StorageServices.getToken();

      if (token == null || token.isEmpty) {

        ScaffoldMessenger.of(context).showSnackBar(

          const SnackBar(content: Text('Token login tidak ditemukan')),

        );

        return;

      }

      final response = await ApiServices().izinSakit(

        token: token,

        latitude: currentPosition!.latitude,

        longitude: currentPosition!.longitude,

        address: locationAddress,

      );

      if (!mounted) return;

      if (response.statusCode == 200) {

        ScaffoldMessenger.of(context).showSnackBar(

          const SnackBar(content: Text('Izin sakit berhasil diajukan')),

        );

        Navigator.pop(context);

      }

    } catch (error) {

      if (!mounted) return;

      String message = 'Izin sakit gagal diajukan';

      if (error.toString().contains('409')) {

        message = 'Anda sudah melakukan absensi atau izin hari ini';

      }

      ScaffoldMessenger.of(context)

          .showSnackBar(SnackBar(content: Text(message)));

    } finally {

      if (mounted) {

        setState(() {

          isIzinLoading = false;

        });

      }

    }

  }

  void openMap() {

    Navigator.push(

      context,

      MaterialPageRoute(builder: (_) => const GoogleMapsScreenDay19()),

    );

  }

  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: bgColor,

      appBar: AppBar(

        backgroundColor: bgColor,

        elevation: 0,

        scrolledUnderElevation: 0,

        leading: IconButton(

          onPressed: () {

            Navigator.pop(context);

          },

          icon: const Icon(

            Icons.arrow_back_ios_new_rounded,

            color: Color(0xFF54283A),

            size: 19,

          ),

        ),

        title: const Text(

          'Kehadiran',

          style: TextStyle(

            color: Color(0xFF54283A),

            fontSize: 20,

            fontWeight: FontWeight.w900,

          ),

        ),

      ),

      body: SingleChildScrollView(

        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            _buildHeader(),

            const SizedBox(height: 22),

            _buildLocationCard(),

            const SizedBox(height: 13),

            _buildMapButton(),

            const SizedBox(height: 27),

            const Text(

              'Aksi Absensi',

              style: TextStyle(

                color: Color(0xFF54283A),

                fontSize: 19,

                fontWeight: FontWeight.w900,

              ),

            ),

            const SizedBox(height: 5),

            const Text(

              'Pilih aktivitas yang ingin kamu lakukan',

              style: TextStyle(

                color: Color(0xFF9E7180),

                fontSize: 11,

              ),

            ),

            const SizedBox(height: 14),

            Row(

              children: [

                Expanded(

                  child: _buildActionButton(

                    title: 'Check In',

                    icon: Icons.login_rounded,

                    backgroundColor: accentColor,

                    foregroundColor: Color(0xFF54283A),

                    loading: isCheckInLoading,

                    onPressed:

                        isCheckInLoading || isCheckOutLoading || isIzinLoading

                        ? null

                        : checkIn,

                  ),

                ),

                const SizedBox(width: 12),

                Expanded(

                  child: _buildActionButton(

                    title: 'Check Out',

                    icon: Icons.logout_rounded,

                    backgroundColor: const Color(0xFFF3A6BD),

                    foregroundColor: Color(0xFF54283A),

                    loading: isCheckOutLoading,

                    onPressed:

                        isCheckInLoading || isCheckOutLoading || isIzinLoading

                        ? null

                        : checkOut,

                  ),

                ),

              ],

            ),

            const SizedBox(height: 12),

            _buildIzinButton(),

            const SizedBox(height: 20),

            _buildLocationStatus(),

          ],

        ),

      ),

    );

  }

  Widget _buildHeader() {

    final now = DateTime.now();

    const months = [

      'Januari',

      'Februari',

      'Maret',

      'April',

      'Mei',

      'Juni',

      'Juli',

      'Agustus',

      'September',

      'Oktober',

      'November',

      'Desember',

    ];

    return Column(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        const Text(

          'Absensi Hari Ini',

          style: TextStyle(

            color: Color(0xFF54283A),

            fontSize: 27,

            fontWeight: FontWeight.w900,

          ),

        ),

        const SizedBox(height: 5),

        Text(

          '${now.day} ${months[now.month - 1]} ${now.year}',

          style: const TextStyle(

            color: Color(0xFF9E7180),

            fontSize: 12,

          ),

        ),

      ],

    );

  }

  Widget _buildLocationCard() {

    return Container(

      width: double.infinity,

      padding: const EdgeInsets.all(19),

      decoration: BoxDecoration(

        color: cardColor,

        borderRadius: BorderRadius.circular(25),

        border: Border.all(

          color: accentColor.withValues(alpha: 0.15),

        ),

        boxShadow: [

          BoxShadow(

            color: accentColor.withValues(alpha: 0.06),

            blurRadius: 25,

            offset: const Offset(0, 10),

          ),

        ],

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Row(

            children: [

              Container(

                width: 48,

                height: 48,

                decoration: BoxDecoration(

                  color: accentColor.withValues(alpha: 0.12),

                  borderRadius: BorderRadius.circular(15),

                ),

                child: const Icon(

                  Icons.location_on_rounded,

                  color: accentLight,

                  size: 25,

                ),

              ),

              const SizedBox(width: 12),

              const Expanded(

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    Text(

                      'Lokasi PPKD JU',

                      style: TextStyle(

                        color: Color(0xFF54283A),

                        fontSize: 16,

                        fontWeight: FontWeight.w900,

                      ),

                    ),

                    SizedBox(height: 3),

                    Text(

                      'Lokasi GPS saat ini',

                      style: TextStyle(

                        color: Color(0xFF9E7180),

                        fontSize: 10,

                      ),

                    ),

                  ],

                ),

              ),

              IconButton(

                onPressed: isLoading ? null : getCurrentLocation,

                icon: isLoading

                    ? const SizedBox(

                        width: 18,

                        height: 18,

                        child: CircularProgressIndicator(

                          color: accentLight,

                          strokeWidth: 2,

                        ),

                      )

                    : const Icon(

                        Icons.refresh_rounded,

                        color: accentLight,

                      ),

              ),

            ],

          ),

          const SizedBox(height: 17),

          Container(

            width: double.infinity,

            padding: const EdgeInsets.all(15),

            decoration: BoxDecoration(

              color: Color(0xFF54283A).withValues(alpha: 0.16),

              borderRadius: BorderRadius.circular(17),

            ),

            child: Row(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                const Icon(

                  Icons.place_rounded,

                  color: accentLight,

                  size: 19,

                ),

                const SizedBox(width: 10),

                Expanded(

                  child: Column(

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      const Text(

                        'ALAMAT TERDETEKSI',

                        style: TextStyle(

                          color: Color(0xFF9E7180),

                          fontSize: 8,

                          fontWeight: FontWeight.w700,

                        ),

                      ),

                      const SizedBox(height: 5),

                      Text(

                        locationAddress,

                        maxLines: 3,

                        overflow: TextOverflow.ellipsis,

                        style: const TextStyle(

                          color: Color(0xFF54283A),

                          fontSize: 12,

                          fontWeight: FontWeight.w700,

                        ),

                      ),

                    ],

                  ),

                ),

              ],

            ),

          ),

          if (currentPosition != null) ...[

            const SizedBox(height: 10),

            Row(

              children: [

                Expanded(

                  child: _buildCoordinate(

                    'LATITUDE',

                    currentPosition!.latitude.toStringAsFixed(6),

                  ),

                ),

                const SizedBox(width: 10),

                Expanded(

                  child: _buildCoordinate(

                    'LONGITUDE',

                    currentPosition!.longitude.toStringAsFixed(6),

                  ),

                ),

              ],

            ),

          ],

        ],

      ),

    );

  }

  Widget _buildCoordinate(String title, String value) {

    return Container(

      padding: const EdgeInsets.symmetric(

        horizontal: 12,

        vertical: 10,

      ),

      decoration: BoxDecoration(

        color: accentColor.withValues(alpha: 0.06),

        borderRadius: BorderRadius.circular(13),

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Text(

            title,

            style: const TextStyle(

              color: Color(0xFF9E7180),

              fontSize: 8,

            ),

          ),

          const SizedBox(height: 3),

          Text(

            value,

            style: const TextStyle(

              color: accentLight,

              fontSize: 10,

              fontWeight: FontWeight.w800,

            ),

          ),

        ],

      ),

    );

  }

  Widget _buildMapButton() {

    return SizedBox(

      width: double.infinity,

      height: 50,

      child: OutlinedButton.icon(

        onPressed: openMap,

        icon: const Icon(Icons.map_rounded, size: 19),

        label: const Text(

          'Lihat Lokasi Saya di Peta',

          style: TextStyle(fontWeight: FontWeight.w800),

        ),

        style: OutlinedButton.styleFrom(

          foregroundColor: accentLight,

          side: BorderSide(

            color: accentColor.withValues(alpha: 0.25),

          ),

          shape: RoundedRectangleBorder(

            borderRadius: BorderRadius.circular(16),

          ),

        ),

      ),

    );

  }

  Widget _buildActionButton({

    required String title,

    required IconData icon,

    required Color backgroundColor,

    required Color foregroundColor,

    required bool loading,

    required VoidCallback? onPressed,

  }) {

    return SizedBox(

      height: 58,

      child: ElevatedButton(

        onPressed: onPressed,

        style: ElevatedButton.styleFrom(

          backgroundColor: backgroundColor,

          foregroundColor: foregroundColor,

          disabledBackgroundColor: backgroundColor.withValues(alpha: 0.35),

          elevation: 0,

          shape: RoundedRectangleBorder(

            borderRadius: BorderRadius.circular(17),

          ),

        ),

        child: loading

            ? SizedBox(

                width: 21,

                height: 21,

                child: CircularProgressIndicator(

                  color: foregroundColor,

                  strokeWidth: 2,

                ),

              )

            : Row(

                mainAxisAlignment: MainAxisAlignment.center,

                children: [

                  Icon(icon, size: 20),

                  const SizedBox(width: 7),

                  Text(

                    title,

                    style: const TextStyle(

                      fontWeight: FontWeight.w900,

                    ),

                  ),

                ],

              ),

      ),

    );

  }

  Widget _buildIzinButton() {

    return SizedBox(

      width: double.infinity,

      height: 56,

      child: OutlinedButton.icon(

        onPressed: isCheckInLoading || isCheckOutLoading || isIzinLoading

            ? null

            : izinSakit,

        icon: isIzinLoading

            ? const SizedBox(

                width: 18,

                height: 18,

                child: CircularProgressIndicator(

                  color: Color(0xFFE58BA6),

                  strokeWidth: 2,

                ),

              )

            : const Icon(Icons.sick_rounded),

        label: Text(

          isIzinLoading ? 'Mengajukan Izin...' : 'Izin Sakit',

        ),

        style: OutlinedButton.styleFrom(

          foregroundColor: Color(0xFFE58BA6),

          side: BorderSide(

            color: Color(0xFFE58BA6).withValues(alpha: 0.35),

          ),

          shape: RoundedRectangleBorder(

            borderRadius: BorderRadius.circular(17),

          ),

        ),

      ),

    );

  }

  Widget _buildLocationStatus() {

    final success = currentPosition != null;

    return Container(

      width: double.infinity,

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(

        color: success

            ? accentColor.withValues(alpha: 0.07)

            : Color(0xFF54283A).withValues(alpha: 0.04),

        borderRadius: BorderRadius.circular(18),

        border: Border.all(

          color: success

              ? accentColor.withValues(alpha: 0.18)

              : Color(0xFF54283A).withValues(alpha: 0.06),

        ),

      ),

      child: Row(

        children: [

          Container(

            width: 38,

            height: 38,

            decoration: BoxDecoration(

              shape: BoxShape.circle,

              color: success

                  ? accentColor.withValues(alpha: 0.12)

                  : Color(0xFF54283A).withValues(alpha: 0.06),

            ),

            child: Icon(

              success ? Icons.check_rounded : Icons.location_searching_rounded,

              color: success ? accentLight : Color(0xFF9E7180),

            ),

          ),

          const SizedBox(width: 11),

          Expanded(

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Text(

                  success ? 'Lokasi berhasil ditemukan' : 'Mencari lokasi...',

                  style: const TextStyle(

                    color: Color(0xFF54283A),

                    fontWeight: FontWeight.w800,

                    fontSize: 12,

                  ),

                ),

                const SizedBox(height: 3),

                Text(

                  success

                      ? 'GPS siap digunakan untuk absensi'

                      : 'Mohon tunggu sebentar',

                  style: const TextStyle(

                    color: Color(0xFF9E7180),

                    fontSize: 10,

                  ),

                ),

              ],

            ),

          ),

        ],

      ),

    );

  }

}