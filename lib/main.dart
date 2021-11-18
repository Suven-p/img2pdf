import 'dart:io' show Platform, File;

import 'package:desktop_window/desktop_window.dart';
import 'package:file_selector/file_selector.dart';
import 'package:drag_and_drop_gridview/devdrag.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'action_bar.dart';

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
  List<XFile> _images = [];

  @override
  void initState() {
    super.initState();
    if (kIsWeb) return;
    if (!kIsWeb && Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      setupWindow();
    }

  }

  Future setupWindow() async {
    print("This method has been called!");
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
        body: Column(
          // padding: EdgeInsets.all(10),
          children: [
            Flexible(
                child: Column(
              children: [
                Expanded(
                    flex: 8,
                    child: ImageView(images: _images, setImages: setImage)),
                Expanded(
                    flex: 2,
                    child: ActionBar(
                        setImages: setImage, getImages: () => _images)),
              ],
            ))
          ],
        ));
  }

  void setImage(List<XFile> images, {bool append = true}) {
    setState(() {
      if (append) {
        _images.addAll(images);
      } else {
        _images = images;
      }
      print("Loaded ${images.length} images.");
    });
  }
}

class ImageView extends StatefulWidget {
  ImageView({Key? key, required this.images, required this.setImages})
      : super(key: key);

  final List<XFile> images;
  final Function setImages;

  @override
  _ImageViewState createState() => _ImageViewState();
}

class _ImageViewState extends State<ImageView> {
  // const ImageView({Key? key, required this.images}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: DragAndDropGridView(
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 300.0,
          crossAxisSpacing: 10.0,
          mainAxisSpacing: 0.0,
        ),
        itemCount: widget.images.length,
        itemBuilder: (context, index) {
          return ImageTile(image: widget.images[index]);
        },
        onWillAccept: (oldIndex, newIndex) {
          return true;
        },
        onReorder: (oldIndex, newIndex) {
          XFile _temp = widget.images[oldIndex];
          widget.images[oldIndex] = widget.images[newIndex];
          widget.images[newIndex] = _temp;
          setState(() {
            // widget.setImages(widget.images);
          });
        },
      ),
    );
  }
}

class ImageTile extends StatelessWidget {
  const ImageTile({Key? key, required this.image}) : super(key: key);

  final XFile image;

  @override
  Widget build(BuildContext context) {
    return GridTile(
      child: Container(
        padding: EdgeInsets.only(bottom: 30),
        child: kIsWeb
            ? Image.network(image.path)
            : Image.file(
                File(image.path),
                fit: BoxFit.fill,
                filterQuality: FilterQuality.medium,
              ),
      ),
      footer: Container(
          margin: EdgeInsets.only(bottom: 10),
          child: Text(
            image.name,
            textAlign: TextAlign.center,
          )),
    );
  }
}
