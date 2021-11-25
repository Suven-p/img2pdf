import 'dart:io' show Platform;
import 'package:desktop_window/desktop_window.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'widgets/action_bar.dart';
import 'widgets/image_view.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pdf Generator',
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // TODO: Replace image with image class to avoid generating at reorder callback
  List<XFile> images = [];
  ImageProvider? displayedImage;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) return;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      setupWindow();
    }
  }

  Future setupWindow() async {
    if (kIsWeb) return;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await DesktopWindow.setWindowSize(Size(600, 600));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Pdf Generator'),
        ),
        body: Stack(children: [
          Container(
              padding: EdgeInsets.all(10),
              child: SingleChildScrollView(
                  child: Column(children: [
                ImageView(
                  images: images,
                  reorderHandler: reorderHandler,
                  setImages: setImage,
                  tapHandler: enlargeImage,
                ),
                ActionBar(setImages: setImage, getImages: () => images),
              ]))),
          (displayedImage != null)
              ? image_overlay(displayedImage!)
              : SizedBox.shrink(),
        ]));
  }

  Widget image_overlay(ImageProvider image) {
    return GestureDetector(
        onTap: () {
          setState(() {
            displayedImage = null;
          });
        },
        child: Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: Image(
                image: image,
              ),
            )));
  }

  void enlargeImage(ImageProvider provider) {
    setState(() {
      displayedImage = provider;
    });
  }

  void reorderHandler(oldIndex, newIndex) {
    setState(() {
      images.insert(newIndex, images.removeAt(oldIndex));
    });
  }

  void setImage(List<XFile> newImages, {bool append = true}) {
    setState(() {
      if (append) {
        images.addAll(newImages);
      } else {
        images = newImages;
      }
      print("Loaded ${newImages.length} images.");
    });
  }
}
