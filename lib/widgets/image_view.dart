import 'dart:io' show File;
import 'package:drag_and_drop_gridview/devdrag.dart';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ImageView extends StatelessWidget {
  ImageView({Key? key, required this.images, required this.reorderHandler})
      : super(key: key);

  final List<XFile> images;
  final Function(int, int) reorderHandler;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.5,
          maxHeight: MediaQuery.of(context).size.height * 0.7),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: SingleChildScrollView(
          child: DragAndDropGridView(
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 300.0,
          crossAxisSpacing: 10.0,
          mainAxisSpacing: 0.0,
        ),
        itemCount: images.length,
        itemBuilder: (context, index) {
          XFile image = images[index];
          return _ImageTile(
            imageName: image.name,
            imagePath: image.path,
          );
        },
        onWillAccept: (oldIndex, newIndex) {
          return true;
        },
        onReorder: reorderHandler,
      )),
    );
  }
}

class _ImageTile extends StatelessWidget {
  const _ImageTile({Key? key, required this.imageName, required this.imagePath})
      : super(key: key);

  final String imageName;
  final String imagePath;

  @override
  Widget build(BuildContext context) {
    final _provider = kIsWeb
        ? NetworkImage(imagePath)
        : FileImage(File(imagePath)) as ImageProvider<Object>;
    return Container(
        constraints: BoxConstraints(
          minWidth: 100,
          minHeight: 100,
        ),
        child: GridTile(
          child: Container(
            padding: EdgeInsets.only(bottom: 30),
            child: Image(
              image: _provider,
              fit: BoxFit.fill,
              loadingBuilder: _loaderBuilder,
            ),
          ),
          footer: Container(
              margin: EdgeInsets.only(bottom: 10),
              child: Text(
                imageName,
                textAlign: TextAlign.center,
              )),
        ));
  }

  Widget _loaderBuilder(
      BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
    if (loadingProgress == null) return child;
    return Center(
      child: CircularProgressIndicator(
        value: loadingProgress.expectedTotalBytes != null
            ? loadingProgress.cumulativeBytesLoaded /
                loadingProgress.expectedTotalBytes!
            : null,
      ),
    );
  }
}
