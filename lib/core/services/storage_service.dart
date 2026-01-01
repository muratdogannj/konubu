import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter/material.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  /// Pick image from gallery
  Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      print('Error picking image from gallery: $e');
      return null;
    }
  }

  /// Pick image from camera
  Future<XFile?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      print('Error picking image from camera: $e');
      return null;
    }
  }

  /// Crop image
  Future<CroppedFile?> cropImage({
    required XFile imageFile,
    required BuildContext context,
  }) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Fotoğrafı Kırp',
            toolbarColor: const Color(0xFF192A56),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: false,
            // UI Controls localization can be tricky on Android as it uses icons mostly
            // but we set the title.
          ),
          IOSUiSettings(
            title: 'Fotoğrafı Kırp',
            doneButtonTitle: 'Kırp',
            cancelButtonTitle: 'İptal',
          ),
          WebUiSettings(
            context: context,
          ),
        ],
      );
      return croppedFile;
    } catch (e) {
      print('Error cropping image: $e');
      return null;
    }
  }

  /// Upload image to Firebase Storage
  /// Returns the download URL
  Future<String?> uploadMessageImage({
    required String conversationId,
    required String messageId,
    required XFile imageFile,
  }) async {
    try {
      final ref = _storage.ref().child('private_messages/$conversationId/$messageId.jpg');
      return await _uploadFile(ref, imageFile);
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  /// Upload profile image to Firebase Storage
  /// Returns the download URL
  Future<String?> uploadProfileImage({
    required String userId,
    required XFile imageFile,
  }) async {
    try {
      final ref = _storage.ref().child('profile_images/$userId.jpg');
      return await _uploadFile(ref, imageFile);
    } catch (e) {
      print('Error uploading profile image: $e');
      return null;
    }
  }

  /// Helper method to upload file (Web & Mobile compatible)
  Future<String> _uploadFile(Reference ref, XFile file) async {
    // Read bytes for both platforms to ensure consistent behavior
    // and avoid potential path access issues on Android
    final data = await file.readAsBytes();
    final metadata = SettableMetadata(contentType: 'image/jpeg');
    
    // Use putData for both
    final snapshot = await ref.putData(data, metadata);
    return await snapshot.ref.getDownloadURL();
  }

  /// Delete image from Firebase Storage
  Future<bool> deleteMessageImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      return true;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }
}
