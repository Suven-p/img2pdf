import 'package:flutter/widgets.dart';

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart';

const List<String> _allowedExtensions = ['jpg', 'JPG', 'JPEG', 'PNG'];

Future<List<XFile>?> openImageFile(BuildContext context) async {
  if (kIsWeb) {
    return _openImageFileDesktop(context);
  } else if (Platform.isAndroid || Platform.isIOS) {
    return _openImageFileMobile(context);
  } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    return _openImageFileDesktop(context);
  } else {
    throw Exception("Unsupported platform ${Platform.operatingSystem}");
  }
}

Future<List<XFile>?> _openImageFileMobile(BuildContext context) async {
  assert(!kIsWeb, "This method cannot be used for the Web.");
  List<XFile> files = [];
  List<PlatformFile>? _paths = (await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: _allowedExtensions,
    allowMultiple: true,
  ))
      ?.files;
  if (_paths == null) {
    return null;
  }
  _paths.forEach((element) {
    if (element.path == null) {
      print("Path is empty for ${element.name}");
      return null;
    }
    files.add(XFile(element.path!));
  });
  return files;
}

Future<List<XFile>?> _openImageFileDesktop(BuildContext context) async {
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
    return null;
  }
  return files;
}
