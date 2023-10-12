import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share/share.dart';
import 'package:url_launcher/url_launcher.dart';
import 'menu.dart';

/// Aplikasi Flutter untuk melacak dan membagikan lokasi pengguna.
///
/// Aplikasi ini memanfaatkan pustaka-pustaka seperti Google Maps, Geolocator,
/// Share, dan Url Launcher untuk melacak lokasi pengguna, menampilkan
/// informasi tentang lokasi tersebut, dan memungkinkan pengguna untuk membagikan
/// lokasi mereka melalui aplikasi sosial media.
void main() => runApp(MyApp());

/// Kelas MyApp adalah entry point dari aplikasi.
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aku Dimana?',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Home(),
    );
  }
}

/// Kelas Home adalah kelas utama yang berisi peta Google Maps dan fungsi-fungsi
/// terkait lokasi.
class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

/// Kelas _HomeState adalah kelas state dari Home yang berisi logika untuk
/// melacak lokasi pengguna dan menampilkan informasi lokasi.
class _HomeState extends State<Home> {
  GoogleMapController _controller;
  Geolocator _geolocator;
  LatLng _currentPosition;
  double _currentZoom;
  String _textToDisplay;
  StreamSubscription<Position> _positionStream;
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  bool _shouldRecenterMap = true;
  Timer _mapDragTimer;

  @override
  void initState() {
    super.initState();

    _textToDisplay = "Sedang melacak posisi kamu..";
    _currentPosition = LatLng(3.5913479, 98.6754698);
    _currentZoom = 17.5;

    _initLocationService();
  }

  /// Inisialisasi layanan lokasi menggunakan Geolocator.
  Future<void> _initLocationService() async {
    _geolocator = Geolocator();

    var locationOptions = LocationOptions(accuracy: LocationAccuracy.best);

    try {
      _positionStream =
          _geolocator.getPositionStream(locationOptions).listen((position) {
        if (position != null) {
          _updateCurrentPosition(position);
        }
      });
    } on PlatformException catch (_) {
      print("Permission denied");
    }
  }

  @override
  void dispose() {
    _positionStream.cancel();
    super.dispose();
  }

  /// Memperbarui lokasi pengguna saat ada perubahan posisi.
  void _updateCurrentPosition(Position position) {
    _currentPosition = LatLng(position.latitude, position.longitude);

    _moveMarker(position);
    _refreshCameraPosition();
    _geocodeCurrentPosition();
  }

  /// Memindahkan marker ke lokasi pengguna saat ini pada peta.
  void _moveMarker(Position position) {
    var markerId = MarkerId("currentPos");
    setState(() {
      markers[markerId] =
          Marker(markerId: markerId, position: _currentPosition);
    });
  }

  /// Memperbarui tampilan peta saat ada perubahan posisi pengguna.
  void _refreshCameraPosition() {
    if (_controller != null && _shouldRecenterMap) {
      _controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: _currentPosition, zoom: _currentZoom),
      ));
    }
  }

  /// Mendapatkan informasi alamat berdasarkan koordinat lokasi pengguna.
  void _geocodeCurrentPosition() async {
    var resultList = await _geolocator.placemarkFromCoordinates(
        _currentPosition.latitude, _currentPosition.longitude,
        localeIdentifier: "id-ID");

    if (resultList.length > 0) {
      Placemark firstResult = resultList[0];

      String textResult = firstResult.thoroughfare +
          " " +
          firstResult.subThoroughfare +
          ", " +
          firstResult.locality;

      setState(() {
        _textToDisplay = textResult;
      });
    }
  }

  /// Berbagi lokasi pengguna melalui aplikasi sosial media.
  void _shareCurrentLocation() {
    String stringToShare = '';

    stringToShare += 'Saya sedang berada di "' + _textToDisplay + '"';

    stringToShare += "\n\n";

    stringToShare += "http://www.google.com/maps/place/" +
        _currentPosition.latitude.toString() +
        "," +
        _currentPosition.longitude.toString();

    Share.share(stringToShare);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          GoogleMap(
            initialCameraPosition:
                CameraPosition(target: _currentPosition, zoom: _currentZoom),
            mapType: MapType.normal,
            onMapCreated: (controller) {
              _controller = controller;
            },
            onCameraMove: (cameraPosition) {
              _currentZoom = cameraPosition.zoom;

              // Menonaktifkan recenter, mengaktifkannya kembali setelah 3 detik
              _shouldRecenterMap = false;
              if (_mapDragTimer != null && _mapDragTimer.isActive) {
                _mapDragTimer.cancel();
              }
              _mapDragTimer = Timer(Duration(seconds: 3), () {
                _shouldRecenterMap = true;
              });
            },
            markers: Set<Marker>.of(markers.values),
          ),
          SafeArea(
            child: Container(
              padding: EdgeInsets.all(8.0),
              width: double.infinity,
              child: Card(
                child: Container(
                  height: 60.0,
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(_textToDisplay),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: MenuButton(
        onTapShare: () {
          _shareCurrentLocation();
        },
        onTapHelp: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: Text("Aplikasi Apa Ini?"),
                  content: Text(
                      "Sesuai dengan namanya, aplikasi ini hanya mendeteksi Anda sedang berada di mana. Aplikasi ini juga dapat mengirimkan posisi anda ke teman-teman anda via aplikasi sosial media yang Anda gunakan.\n\nSelain itu, tidak ada lagi yang bisa dilakukan aplikasi ini :("),
                  actions: <Widget>[
                    FlatButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text("Okelah"),
                    ),
                  ],
                ),
          );
        },
        onTapInfo: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: Text("Info Aplikasi"),
                  content: Text(
                      "Aplikasi ini adalah aplikasi iseng dalam rangka mempelajari Flutter.\n\nSilakan kunjungi repository project ini untuk melihat source codenya."),
                  actions: <Widget>[
                    FlatButton(
                      child: Text("Buka Repository"),
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await launch(
                            "https://github.com/charzone95/flutter_aku_dimana");
                      },
                    ),
                    FlatButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text("OK"),
                    ),
                  ],
                ),
          );
        },
      ),
    );
  }
}
