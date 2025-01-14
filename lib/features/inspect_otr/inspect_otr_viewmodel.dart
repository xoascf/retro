import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_storm/bridge/errors.dart';
import 'package:flutter_storm/bridge/flags.dart';
import 'package:flutter_storm/flutter_storm.dart';
import 'package:retro/utils/log.dart';

class InspectOTRViewModel extends ChangeNotifier {
  String? selectedOTRPath;
  List<String> filesInOTR = [];
  bool isProcessing = false;

  reset() {
    selectedOTRPath = null;
    filesInOTR = [];
    isProcessing = false;
  }

  onSelectOTR() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true, type: FileType.custom, allowedExtensions: ['otr']);
    if (result != null && result.files.isNotEmpty) {
      selectedOTRPath = result.paths.first;
      if (selectedOTRPath == null) {
        // TODO: Handle this error
        return;
      }

      listOTRItems();
      notifyListeners();
    }
  }

  listOTRItems() async {
    if (selectedOTRPath == null) {
      // TODO: Handle this error
      return;
    }

    try {
      bool fileFound = false;
      List<String> files = [];
      isProcessing = true;
      notifyListeners();

      String? otrHandle = await SFileOpenArchive(selectedOTRPath!, MPQ_OPEN_READ_ONLY);
      String? findData = await SFileFindCreateDataPointer();
      String? hFind = await SFileFindFirstFile(otrHandle!, "*", findData!);

      String? fileName = await SFileFindGetDataForDataPointer(findData);
      if (fileName != null && fileName != "(signature)" && fileName != "(listfile)" && fileName != "(attributes)") {
        files.add(fileName);
      }

      do {
        try {
          await SFileFindNextFile(hFind!, findData);
          fileFound = true;
          String? fileName = await SFileFindGetDataForDataPointer(findData);
          log("File name: $fileName");
          if (fileName != null && fileName != "(signature)" && fileName != "(listfile)" && fileName != "(attributes)") {
            files.add(fileName);
          }
        } on StormException catch (e) {
          log("Failed to find next file: ${e.message}");
          fileFound = false;
        }
      } while (fileFound);

      SFileFindClose(hFind!);
      filesInOTR = files;
      isProcessing = false;
      notifyListeners();
    } on StormException catch (e) {
      log("Failed to set locale: ${e.message}");
      return;
    }
  }
}
