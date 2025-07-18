import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class TextRecognitionService {
  final TextRecognizer _textRecognizer = TextRecognizer(); // Specify script for better accuracy

  /// Recognizes text from a given image file path.
  /// Returns the recognized text as a String.
  Future<String> recognizeTextFromImage(String imagePath) async {
    if (!File(imagePath).existsSync()) {
      throw Exception('Image file not found at path: $imagePath');
    }
    final InputImage inputImage = InputImage.fromFilePath(imagePath);
    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
    return recognizedText.text;
  }

  /// Disposes the text recognizer to free up resources.
  void dispose() {
    _textRecognizer.close();
  }
}
