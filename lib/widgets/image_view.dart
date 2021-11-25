import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import '../utils/open_image.dart';

class ImageView extends StatelessWidget {
  ImageView(
      {Key? key,
      required this.images,
      required this.reorderHandler,
      required this.setImages})
      : super(key: key);

  final List<XFile> images;
  final Function(int, int) reorderHandler;
  final Function setImages;

  @override
  Widget build(BuildContext context) {
    TextStyle text_style = TextStyle(fontSize: 18);
    if (images.isEmpty) {
      return Container(
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black, width: 1),
            borderRadius: BorderRadius.all(Radius.circular(10))),
        constraints: BoxConstraints(minHeight: 200, minWidth: 100),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(
            'No images selected.',
            style: text_style,
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            TextButton(
              child: Text('Select images', style: text_style),
              onPressed: () async {
                List<XFile>? files = await openImageFile(context);
                if (files == null) return;
                setImages(files);
              },
            ),
            Text('or drag and drop them.', style: text_style),
          ]),
        ]),
      );
    }
    return Container(
      constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.5,
          maxHeight: MediaQuery.of(context).size.height * 0.7),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Container(
          child: ReorderableGridView.builder(
        crossAxisCount: 3,
        itemCount: images.length,
        itemBuilder: (context, index) {
          final XFile image = images[index];
          return _ImageTile(
              imageName: image.name,
              imagePath: image.path,
              key: ValueKey(index));
        },
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200.0,
          mainAxisSpacing: 1.0,
          crossAxisSpacing: 1.0,
        ),
        onReorder: reorderHandler,
        dragWidgetBuilder: (index, child) {
          final image = images[index];
          return Container(
            width: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Image.file(File(image.path), width: 200),
          );
        },
      )),
    );
  }
}

class _ImageTile extends StatelessWidget {
  _ImageTile({Key? key, required this.imageName, required this.imagePath})
      : provider = kIsWeb
            ? NetworkImage(imagePath)
            : FileImage(File(imagePath)) as ImageProvider<Object>,
        super(key: key);

  final String imageName;
  final String imagePath;
  final ImageProvider provider;

  @override
  Widget build(BuildContext context) {
    // TODO: Implement tap gesture
    return Container(
        child: GridTile(
      child: Container(
        padding: EdgeInsets.only(bottom: 30),
        child: Image(
          image: provider,
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
