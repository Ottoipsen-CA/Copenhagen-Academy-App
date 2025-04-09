import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:universal_html/html.dart' as html;

class ImagePickerHelper {
  static Future<String?> pickImage() async {
    if (kIsWeb) {
      return await _pickImageWeb();
    } else {
      return await _pickImageMobile();
    }
  }

  static Future<String?> _pickImageWeb() async {
    final html.FileUploadInputElement input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();

    await input.onChange.first;
    if (input.files?.isEmpty ?? true) return null;

    final file = input.files!.first;
    final reader = html.FileReader();
    reader.readAsDataUrl(file);
    await reader.onLoad.first;

    return reader.result as String;
  }

  static Future<String?> _pickImageMobile() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image == null) return null;
    return image.path;
  }
} 