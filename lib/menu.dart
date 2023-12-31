import 'dart:math';

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' show radians;

/// Kelas MenuButton adalah tombol aksi yang menampilkan menu ikon saat ditekan.
///
/// Tombol ini dapat digunakan untuk memicu tiga fungsi yang berbeda:
/// - `onTapShare`: Untuk berbagi lokasi pengguna.
/// - `onTapInfo`: Untuk menampilkan informasi tentang aplikasi.
/// - `onTapHelp`: Untuk menampilkan petunjuk penggunaan aplikasi.
class MenuButton extends StatefulWidget {
  final Function onTapShare;
  final Function onTapInfo;
  final Function onTapHelp;

  const MenuButton({Key key, this.onTapShare, this.onTapInfo, this.onTapHelp}) : super(key: key);

  @override
  _MenuButtonState createState() => _MenuButtonState();
}

/// Kelas _MenuButtonState adalah kelas state dari MenuButton yang mengatur
/// tampilan tombol dan animasi ikon menu.
class _MenuButtonState extends State<MenuButton> with SingleTickerProviderStateMixin {
  bool _isOpened = false;

  AnimationController _animationController;
  Animation<double> _animateIcon;
  Animation<double> _animateTranslation;
  Animation<double> _animateVisible;

  @override
  void initState() {
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    )..addListener(() {
        setState(() {});
      });

    _animateIcon =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);

    _animateTranslation = Tween<double>(begin: 0.0, end: 72.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animateVisible = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Mengubah status tombol (menu terbuka/tutup) dan mengendalikan animasi ikon.
  void _toggle() {
    if (!_isOpened) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }

    _isOpened = !_isOpened;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200.0,
      width: 200.0,
      child: Stack(
        alignment: AlignmentDirectional.bottomEnd,
        children: <Widget>[
          // Tombol Help
          Transform(
            transform: Matrix4.identity()
              ..translate(
                _animateTranslation.value * -1.5,
              ),
            child: Opacity(
              opacity: _animateVisible.value,
              child: FloatingActionButton(
                backgroundColor: Colors.yellow[800],
                child: Icon(Icons.help_outline),
                onPressed: () {
                  if (widget.onTapHelp != null) {
                    widget.onTapHelp();
                  }
                  _toggle();
                },
              ),
            ),
          ),
          
          // Tombol Info
          Transform(
            transform: Matrix4.identity()
              ..translate(
                _animateTranslation.value * -1,
                _animateTranslation.value * -1,
              ),
            child: Opacity(
              opacity: _animateVisible.value,
              child: FloatingActionButton(
                backgroundColor: Colors.blue[300],
                child: Icon(Icons.info_outline),
                onPressed: () {
                  if (widget.onTapInfo != null) {
                    widget.onTapInfo();
                  }
                  _toggle();
                },
              ),
            ),
          ),
          
          // Tombol Share
          Transform(
            transform: Matrix4.identity()
              ..translate(
                0.0,
                _animateTranslation.value * -1.5,
              ),
            child: Opacity(
              opacity: _animateVisible.value,
              child: FloatingActionButton(
                backgroundColor: Colors.blue[700],
                child: Icon(Icons.send),
                onPressed: () {
                  if (widget.onTapShare != null) {
                    widget.onTapShare();
                  }
                  _toggle();
                },
              ),
            ),
          ),
          
          // Tombol Menu (Tombol utama)
          FloatingActionButton(
            child: AnimatedIcon(
              icon: AnimatedIcons.menu_close,
              progress: _animateIcon,
            ),
            onPressed: () {
              _toggle();
            },
          ),
        ],
      ),
    );
  }
}
