import 'dart:io' show Platform, File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/open_image.dart';

class ActionBar extends StatefulWidget {
  const ActionBar({Key? key, required this.setImages, required this.getImages})
      : super(key: key);
  final Function(List<XFile>, {bool append}) setImages;
  final List<XFile> Function() getImages;

  @override
  _ActionBarState createState() => _ActionBarState();
}

class _ActionBarState extends State<ActionBar> {
  bool _isOptionsExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: EdgeInsets.only(top: 10),
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Column(children: [
            Row(
              children: [_options(context)],
            ),
            MainActionBar(
              buttons: [
                ActionButton(
                    icon: Icon(Icons.clear_all),
                    label: Text("Clear all"),
                    onPressed: () => widget.setImages([], append: false)),
                ActionButton(
                    onPressed: () async {
                      await _generatePdf(widget.getImages());
                    },
                    icon: Icon(Icons.picture_as_pdf),
                    label: Text("Generate PDF")),
                ActionButton(
                    onPressed: () async {
                      List<XFile>? files = await openImageFile(context);
                      if (files == null) return;
                      widget.setImages(files);
                    },
                    icon: Icon(Icons.add_a_photo),
                    label: Text("Add files")),
              ],
            )
          ]),
        ));
  }

  Widget _options(BuildContext context) {
    return Expanded(
        child: ExpansionPanelList(
            expansionCallback: (int index, bool isExpanded) {
              setState(() {
                _isOptionsExpanded = !_isOptionsExpanded;
              });
            },
            children: [
          ExpansionPanel(
            headerBuilder: (BuildContext context, bool isExpanded) {
              return ListTile(
                title: Text("Options"),
              );
            },
            body: ListView(
              shrinkWrap: true,
              children: [Text("Apples"), Text("Balls"), Text("Cats")],
            ),
            canTapOnHeader: true,
            isExpanded: _isOptionsExpanded,
          )
        ]));
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
    final double? width = isScreenWide ? null : size.width;
    return Flex(
      mainAxisAlignment: MainAxisAlignment.end,
      direction: direction,
      children: buttons.map((button) {
        return Container(
            margin: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
            width: width,
            child: button);
      }).toList(),
    );
  }
}
