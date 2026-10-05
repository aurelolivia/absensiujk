import 'package:flutter/material.dart';
import '../../reusable/app_theme.dart';

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

  static Color get bgColor => AppPalette.bg;

  static Color get cardColor => AppPalette.card;

  static Color get accentColor => AppPalette.accent;

  static Color get accentLight => AppPalette.accentLight;

  Position? currentPosition;

  bool isLoading = false;

  bool isCheckInLoading = false;

  bool isCheckOutLoading = false;

  bool isIzinLoading = false;

  String locationAddress = 'Mendeteksi lokasi...';

  final Geocoding geocoding = Geocoding(locale: Locale('id', 'ID'));

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

        SnackBar(content: Text('Lokasi GPS belum tersedia')),

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

          SnackBar(content: Text('Token login tidak ditemukan')),

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

            .showSnackBar(SnackBar(content: Text('Check In berhasil')));

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

        SnackBar(content: Text('Lokasi GPS belum tersedia')),

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

          SnackBar(content: Text('Token login tidak ditemukan')),

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

            .showSnackBar(SnackBar(content: Text('Check Out berhasil')));

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

        SnackBar(content: Text('Lokasi GPS belum tersedia')),

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

          title: Text(

            'Izin Sakit',

            style: TextStyle(

              color: AppPalette.textPrimary,

              fontWeight: FontWeight.w900,

            ),

          ),

          content: Text(

            'Apakah kamu yakin ingin mengajukan '

            'izin sakit hari ini?',

            style: TextStyle(color: AppPalette.textSecondary),

          ),

          actions: [

            TextButton(

              onPressed: () {

                Navigator.pop(context, false);

              },

              child: Text(

                'Batal',

                style: TextStyle(color: AppPalette.textSecondary),

              ),

            ),

            ElevatedButton(

              onPressed: () {

                Navigator.pop(context, true);

              },

              style: ElevatedButton.styleFrom(

                backgroundColor: AppPalette.snack,

                foregroundColor: AppPalette.textPrimary,

              ),

              child: Text('Ajukan'),

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

          SnackBar(content: Text('Token login tidak ditemukan')),

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

          SnackBar(content: Text('Izin sakit berhasil diajukan')),

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

      MaterialPageRoute(builder: (_) => GoogleMapsScreenDay19()),

    );

  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeController.isDarkMode,
      builder: (context, _, __) => _buildThemed(context),
    );
  }

  Widget _buildThemed(BuildContext context) {

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

          icon: Icon(

            Icons.arrow_back_ios_new_rounded,

            color: AppPalette.textPrimary,

            size: 19,

          ),

        ),

        title: Text(

          'Kehadiran',

          style: TextStyle(

            color: AppPalette.textPrimary,

            fontSize: 20,

            fontWeight: FontWeight.w900,

          ),

        ),

      ),

      body: SingleChildScrollView(

        padding: EdgeInsets.fromLTRB(20, 10, 20, 30),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            _buildHeader(),

            SizedBox(height: 22),

            _buildLocationCard(),

            SizedBox(height: 13),

            _buildMapButton(),

            SizedBox(height: 27),

            Text(

              'Aksi Absensi',

              style: TextStyle(

                color: AppPalette.textPrimary,

                fontSize: 19,

                fontWeight: FontWeight.w900,

              ),

            ),

            SizedBox(height: 5),

            Text(

              'Pilih aktivitas yang ingin kamu lakukan',

              style: TextStyle(

                color: AppPalette.textSecondary,

                fontSize: 11,

              ),

            ),

            SizedBox(height: 14),

            Row(

              children: [

                Expanded(

                  child: _buildActionButton(

                    title: 'Check In',

                    icon: Icons.login_rounded,

                    backgroundColor: accentColor,

                    foregroundColor: AppPalette.textPrimary,

                    loading: isCheckInLoading,

                    onPressed:

                        isCheckInLoading || isCheckOutLoading || isIzinLoading

                        ? null

                        : checkIn,

                  ),

                ),

                SizedBox(width: 12),

                Expanded(

                  child: _buildActionButton(

                    title: 'Check Out',

                    icon: Icons.logout_rounded,

                    backgroundColor: AppPalette.soft,

                    foregroundColor: AppPalette.textPrimary,

                    loading: isCheckOutLoading,

                    onPressed:

                        isCheckInLoading || isCheckOutLoading || isIzinLoading

                        ? null

                        : checkOut,

                  ),

                ),

              ],

            ),

            SizedBox(height: 12),

            _buildIzinButton(),

            SizedBox(height: 20),

            _buildLocationStatus(),

          ],

        ),

      ),

    );

  }

  Widget _buildHeader() {

    final now = DateTime.now();

    final months = [

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

        Text(

          'Absensi Hari Ini',

          style: TextStyle(

            color: AppPalette.textPrimary,

            fontSize: 27,

            fontWeight: FontWeight.w900,

          ),

        ),

        SizedBox(height: 5),

        Text(

          '${now.day} ${months[now.month - 1]} ${now.year}',

          style: TextStyle(

            color: AppPalette.textSecondary,

            fontSize: 12,

          ),

        ),

      ],

    );

  }

  Widget _buildLocationCard() {

    return Container(

      width: double.infinity,

      padding: EdgeInsets.all(19),

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

            offset: Offset(0, 10),

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

                child: Icon(

                  Icons.location_on_rounded,

                  color: accentLight,

                  size: 25,

                ),

              ),

              SizedBox(width: 12),

              Expanded(

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    Text(

                      'Lokasi PPKD JU',

                      style: TextStyle(

                        color: AppPalette.textPrimary,

                        fontSize: 16,

                        fontWeight: FontWeight.w900,

                      ),

                    ),

                    SizedBox(height: 3),

                    Text(

                      'Lokasi GPS saat ini',

                      style: TextStyle(

                        color: AppPalette.textSecondary,

                        fontSize: 10,

                      ),

                    ),

                  ],

                ),

              ),

              IconButton(

                onPressed: isLoading ? null : getCurrentLocation,

                icon: isLoading

                    ? SizedBox(

                        width: 18,

                        height: 18,

                        child: CircularProgressIndicator(

                          color: accentLight,

                          strokeWidth: 2,

                        ),

                      )

                    : Icon(

                        Icons.refresh_rounded,

                        color: accentLight,

                      ),

              ),

            ],

          ),

          SizedBox(height: 17),

          Container(

            width: double.infinity,

            padding: EdgeInsets.all(15),

            decoration: BoxDecoration(

              color: AppPalette.textPrimary.withValues(alpha: 0.16),

              borderRadius: BorderRadius.circular(17),

            ),

            child: Row(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Icon(

                  Icons.place_rounded,

                  color: accentLight,

                  size: 19,

                ),

                SizedBox(width: 10),

                Expanded(

                  child: Column(

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      Text(

                        'ALAMAT TERDETEKSI',

                        style: TextStyle(

                          color: AppPalette.textSecondary,

                          fontSize: 8,

                          fontWeight: FontWeight.w700,

                        ),

                      ),

                      SizedBox(height: 5),

                      Text(

                        locationAddress,

                        maxLines: 3,

                        overflow: TextOverflow.ellipsis,

                        style: TextStyle(

                          color: AppPalette.textPrimary,

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

            SizedBox(height: 10),

            Row(

              children: [

                Expanded(

                  child: _buildCoordinate(

                    'LATITUDE',

                    currentPosition!.latitude.toStringAsFixed(6),

                  ),

                ),

                SizedBox(width: 10),

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

      padding: EdgeInsets.symmetric(

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

            style: TextStyle(

              color: AppPalette.textSecondary,

              fontSize: 8,

            ),

          ),

          SizedBox(height: 3),

          Text(

            value,

            style: TextStyle(

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

        icon: Icon(Icons.map_rounded, size: 19),

        label: Text(

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

                  SizedBox(width: 7),

                  Text(

                    title,

                    style: TextStyle(

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

            ? SizedBox(

                width: 18,

                height: 18,

                child: CircularProgressIndicator(

                  color: AppPalette.snack,

                  strokeWidth: 2,

                ),

              )

            : Icon(Icons.sick_rounded),

        label: Text(

          isIzinLoading ? 'Mengajukan Izin...' : 'Izin Sakit',

        ),

        style: OutlinedButton.styleFrom(

          foregroundColor: AppPalette.snack,

          side: BorderSide(

            color: AppPalette.snack.withValues(alpha: 0.35),

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

      padding: EdgeInsets.all(16),

      decoration: BoxDecoration(

        color: success

            ? accentColor.withValues(alpha: 0.07)

            : AppPalette.textPrimary.withValues(alpha: 0.04),

        borderRadius: BorderRadius.circular(18),

        border: Border.all(

          color: success

              ? accentColor.withValues(alpha: 0.18)

              : AppPalette.textPrimary.withValues(alpha: 0.06),

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

                  : AppPalette.textPrimary.withValues(alpha: 0.06),

            ),

            child: Icon(

              success ? Icons.check_rounded : Icons.location_searching_rounded,

              color: success ? accentLight : AppPalette.textSecondary,

            ),

          ),

          SizedBox(width: 11),

          Expanded(

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Text(

                  success ? 'Lokasi berhasil ditemukan' : 'Mencari lokasi...',

                  style: TextStyle(

                    color: AppPalette.textPrimary,

                    fontWeight: FontWeight.w800,

                    fontSize: 12,

                  ),

                ),

                SizedBox(height: 3),

                Text(

                  success

                      ? 'GPS siap digunakan untuk absensi'

                      : 'Mohon tunggu sebentar',

                  style: TextStyle(

                    color: AppPalette.textSecondary,

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