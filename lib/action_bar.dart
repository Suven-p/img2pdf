import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

class ActionBar extends StatelessWidget {
  const ActionBar({Key? key, required this.setImages, required this.getImages})
      : super(key: key);
  final Function(List<XFile>, {bool append}) setImages;
  final List<XFile> Function() getImages;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 10),
//       constraints: BoxConstraints.expand(),
      child: Column(children: [
        Row(
          children: [_options()],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _clearAll(context),
            AddImages(this.setImages),
            GeneratePDF(),
          ],
        )
      ]),
    );
  }

  Widget _options() {
    return DropdownButton(
        items: [DropdownMenuItem(value: "Option 1", child: Text("Option 1"))],
        onChanged: (value) {
          if (value == 'Option 1') {
            print("Option 1 selected");
          }
        });
  }

  Widget _clearAll(BuildContext context) {
    return Container(
        margin: EdgeInsets.only(left: 15),
        child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.all(20),
            ),
            onPressed: () => setImages([], append: false),
            icon: Icon(Icons.clear_all),
            label: Text("Clear all")));
  }
}

class GeneratePDF extends StatelessWidget {
  const GeneratePDF({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: EdgeInsets.only(left: 15),
        child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.all(20),
            ),
            onPressed: () async {},
            icon: Icon(Icons.picture_as_pdf),
            label: Text("Generate PDF")));
  }
}

class AddImages extends StatelessWidget {
  final Function(List<XFile>) setImageCallback;
  final List<String> _allowedExtensions = ['jpg', 'JPG', 'JPEG', 'PNG'];

  AddImages(
    this.setImageCallback,
  );

  Function _openImageFile() {
    if (kIsWeb) {
      return _openImageFileDesktop;
    } else if (Platform.isAndroid || Platform.isIOS) {
      return _openImageFileMobile;
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return _openImageFileDesktop;
    } else {
      throw Exception("Unsupported platform ${Platform.operatingSystem}");
    }
  }

  void _openImageFileMobile(BuildContext context) async {
    assert(!kIsWeb, "This method cannot be used for the Web.");
    List<XFile> files = [];
    List<PlatformFile>? _paths = (await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _allowedExtensions,
      allowMultiple: true,
    ))
        ?.files;
    if (_paths == null) {
      return;
    }
    _paths.forEach((element) {
      if (element.path == null) {
        print("Path is empty for ${element.name}");
        return;
      }
      files.add(XFile(element.path!));
    });
    this.setImageCallback(files);
  }

  Future<void> _openImageFileDesktop(BuildContext context) async {
    final XTypeGroup customTypeGroup =
        XTypeGroup(label: 'Image Files', extensions: _allowedExtensions);
    final XTypeGroup allTypeGroup = XTypeGroup(
      label: 'All',
      extensions: [],
      webWildCards: ['image/'],
    );
    final List<XFile> files = await openFiles(acceptedTypeGroups: <XTypeGroup>[
      customTypeGroup,
      allTypeGroup,
    ]);
    if (files.isEmpty) {
      print("No files selected!");
      // Operation was canceled by the user.
      return;
    }
    this.setImageCallback(files);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: EdgeInsets.only(left: 15),
        child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.all(20),
            ),
            onPressed: () => _openImageFile()(context),
            icon: Icon(Icons.add_a_photo),
            label: Text("Add files")));
  }
}
