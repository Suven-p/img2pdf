import 'dart:io' show Platform, File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

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
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Column(children: [
            Row(
              children: [_options()],
            ),
            MainActionBar(
              buttons: [
                ActionButton(
                    icon: Icon(Icons.clear_all),
                    label: Text("Clear all"),
                    onPressed: () => setImages([], append: false)),
                ActionButton(
                    onPressed: () async {
                      await _generatePdf(getImages());
                    },
                    icon: Icon(Icons.picture_as_pdf),
                    label: Text("Generate PDF")),
                AddImages(setImages),
              ],
            )
          ]),
        ));
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

  Future<void> _generatePdf(List<XFile> images) async {
    final doc = pw.Document();
    for (var image in images) {
      doc.addPage(pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(
                child: pw.Image(
              pw.MemoryImage(File(image.path).readAsBytesSync()),
              fit: pw.BoxFit.fitWidth,
            ));
          }));
    }
    final fileData = await doc.save();
    String? filePath;
    if (kIsWeb) {
      filePath = await _getSavePath();
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      filePath = await _getSavePath();
    } else if (Platform.isAndroid || Platform.isIOS) {
      filePath = await _getSavePathMobile();
    } else {
      throw Exception("Unsupported platform ${Platform.operatingSystem}");
    }
    if (filePath == null) return;
    final file = File(filePath);
    await file.writeAsBytes(fileData);
  }

  Future<String?> _getSavePath() async {
    final List<XTypeGroup> acceptedGroups = [
      XTypeGroup(mimeTypes: ["application/pdf"], webWildCards: ["pdf"]),
      XTypeGroup(mimeTypes: ["*"], webWildCards: ["*"]),
    ];
    return await getSavePath(
      acceptedTypeGroups: acceptedGroups,
    );
  }

  Future<String?> _getSavePathMobile() async {
    // storage permission ask
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
    String fileName = "Output_file.pdf";
    // the downloads folder path
    if (Platform.isAndroid) {
      final path = await getExternalStorageDirectory();
      if (path == null) return null;
      return path.path + "/" + fileName;
    } else if (Platform.isIOS) {
      final path = await getApplicationSupportDirectory();
      return path.path + "/" + fileName;
    }
  }
}

class ActionButton extends StatelessWidget {
  const ActionButton(
      {Key? key,
      required this.icon,
      required this.label,
      required this.onPressed})
      : super(key: key);

  final VoidCallback onPressed;
  final Icon icon;
  final Widget label;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.all(15),
        ),
        onPressed: this.onPressed,
        icon: this.icon,
        label: this.label);
  }
}

class MainActionBar extends StatelessWidget {
  const MainActionBar({Key? key, required this.buttons}) : super(key: key);

  final List<Widget> buttons;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final bool isScreenWide = size.width > 600;
    final Axis direction = isScreenWide ? Axis.horizontal : Axis.vertical;
    final double maxWidth =
        isScreenWide ? size.width / buttons.length : size.width;
    final double? width = isScreenWide ? null : size.width;
    return Flex(
      mainAxisAlignment: MainAxisAlignment.end,
      direction: direction,
      children: buttons.map((button) {
        return Container(
            margin: EdgeInsets.only(left: 5, bottom: 10),
            width: width,
            constraints: BoxConstraints(
              maxWidth: maxWidth,
            ),
            child: button);
      }).toList(),
    );
  }
}

class AddImages extends StatelessWidget {
  final Function(List<XFile>) setImageCallback;
  final List<String> _allowedExtensions = ['jpg', 'JPG', 'JPEG', 'PNG'];

  AddImages(
    this.setImageCallback,
  );

  @override
  Widget build(BuildContext context) {
    return ActionButton(
        onPressed: () => _openImageFile()(context),
        icon: Icon(Icons.add_a_photo),
        label: Text("Add files"));
  }

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
}
