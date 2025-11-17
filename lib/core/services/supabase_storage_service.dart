// lib/core/services/supabase_storage_service.dart
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class SupabaseStorageService {
  final SupabaseClient _supabase;
  final ImagePicker _imagePicker = ImagePicker();

  // Límites de almacenamiento
  static const double maxFileSizeMB = 10.0; // 10 MB máximo por archivo
  static const double maxTotalStorageMB = 500.0; // 500 MB plan Free

  SupabaseStorageService()
      : _supabase = Supabase.instance.client;

  // 🔹 Seleccionar imagen de galería
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      return image != null ? File(image.path) : null;
    } catch (e) {
      print('❌ Error seleccionando imagen: $e');
      return null;
    }
  }

  // 🔹 Tomar foto con cámara
  Future<File?> takePhotoWithCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      return image != null ? File(image.path) : null;
    } catch (e) {
      print('❌ Error tomando foto: $e');
      return null;
    }
  }

  // 🔹 VERIFICAR TAMAÑO DE ARCHIVO
  Future<void> _validateFileSize(File imageFile) async {
    final fileSize = await imageFile.length();
    final fileSizeMB = fileSize / (1024 * 1024);

    if (fileSizeMB > maxFileSizeMB) {
      throw Exception('La imagen es demasiado grande (${fileSizeMB.toStringAsFixed(1)} MB). '
          'Máximo ${maxFileSizeMB} MB por imagen.');
    }

    if (fileSizeMB > 2) {
      print('⚠️ Imagen grande detectada: ${fileSizeMB.toStringAsFixed(1)} MB');
    }
  }

  // 🔹 ESTIMAR USO ACTUAL DE STORAGE
  Future<Map<String, dynamic>> _getStorageUsage() async {
    try {
      final response = await _supabase.storage
          .from('product_images')
          .list();

      int totalFiles = response.length;
      double estimatedSizeMB = 0;

      // Estimación conservadora: 500 KB por imagen
      for (var file in response) {
        estimatedSizeMB += 0.5; // 500 KB = 0.5 MB
      }

      final usagePercentage = (estimatedSizeMB / maxTotalStorageMB) * 100;

      return {
        'totalFiles': totalFiles,
        'estimatedSizeMB': estimatedSizeMB,
        'usagePercentage': usagePercentage,
        'remainingMB': maxTotalStorageMB - estimatedSizeMB,
      };
    } catch (e) {
      print('❌ Error estimando uso de storage: $e');
      return {
        'totalFiles': 0,
        'estimatedSizeMB': 0,
        'usagePercentage': 0,
        'remainingMB': maxTotalStorageMB,
      };
    }
  }

  // 🔹 VERIFICAR ESPACIO DISPONIBLE
  Future<bool> _hasEnoughSpace(double additionalMB) async {
    final usage = await _getStorageUsage();
    final remainingMB = usage['remainingMB'] ?? maxTotalStorageMB;

    return remainingMB >= additionalMB;
  }

  // 🔹 Subir imagen a Supabase Storage CON VALIDACIONES
  Future<String?> uploadProductImage(File imageFile, String businessId, String productId) async {
    try {
      print('🔄 Iniciando subida de imagen...');

      // 🔹 VALIDACIÓN 1: Tamaño del archivo
      await _validateFileSize(imageFile);
      final fileSizeMB = (await imageFile.length()) / (1024 * 1024);

      // 🔹 VALIDACIÓN 2: Espacio disponible
      final hasSpace = await _hasEnoughSpace(fileSizeMB);
      if (!hasSpace) {
        final usage = await _getStorageUsage();
        final usagePercentage = usage['usagePercentage'] ?? 0;

        throw Exception('Límite de almacenamiento alcanzado (${usagePercentage.toStringAsFixed(1)}% usado). '
            'Por favor actualiza tu plan de Supabase o elimina algunas imágenes.');
      }

      // 🔹 VALIDACIÓN 3: BusinessId y ProductId válidos
      if (businessId.isEmpty) {
        throw Exception('BusinessId no válido para subir imagen.');
      }
      if (productId.isEmpty) {
        throw Exception('ProductId no válido para subir imagen.');
      }

      print('📋 Validaciones pasadas:');
      print('   - Tamaño archivo: ${fileSizeMB.toStringAsFixed(2)} MB');
      print('   - BusinessId: $businessId');
      print('   - ProductId: $productId');

      // Generar nombre único para la imagen
      String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      String storagePath = 'businesses/$businessId/products/$productId/$fileName';

      print('🔄 Subiendo imagen a: $storagePath');

      // Subir el archivo a Supabase
      await _supabase.storage
          .from('product_images')
          .upload(storagePath, imageFile);

      // Obtener URL pública de la imagen
      final String publicUrl = _supabase.storage
          .from('product_images')
          .getPublicUrl(storagePath);

      // Actualizar estadísticas de uso
      final usage = await _getStorageUsage();
      print('📊 Estado almacenamiento:');
      print('   - Archivos: ${usage['totalFiles']}');
      print('   - Espacio usado: ${usage['estimatedSizeMB']?.toStringAsFixed(2)} MB');
      print('   - Porcentaje: ${usage['usagePercentage']?.toStringAsFixed(1)}%');
      print('   - Espacio libre: ${usage['remainingMB']?.toStringAsFixed(2)} MB');

      print('✅ Imagen subida exitosamente: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('❌ Error subiendo imagen a Supabase: $e');

      // Manejar errores específicos
      final errorMessage = e.toString();
      if (errorMessage.contains('Límite de almacenamiento')) {
        throw Exception(errorMessage); // Propagar el error original
      } else if (errorMessage.contains('demasiado grande')) {
        throw Exception(errorMessage); // Propagar el error original
      } else if (errorMessage.contains('BusinessId no válido') ||
          errorMessage.contains('ProductId no válido')) {
        throw Exception(errorMessage); // Propagar el error original
      } else if (errorMessage.contains('JWT')) {
        throw Exception('Error de autenticación. Por favor, cierra sesión y vuelve a iniciar.');
      } else if (errorMessage.contains('network') || errorMessage.contains('Socket')) {
        throw Exception('Error de conexión. Verifica tu internet e intenta nuevamente.');
      } else {
        throw Exception('Error al subir imagen: $errorMessage');
      }
    }
  }

  // 🔹 Eliminar imagen de Supabase Storage
  Future<void> deleteImage(String imageUrl) async {
    try {
      if (imageUrl.isEmpty) {
        print('⚠️ URL de imagen vacía, no se puede eliminar');
        return;
      }

      print('🔄 Eliminando imagen: $imageUrl');

      // Extraer el path del archivo desde la URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;

      // En Supabase, el path completo está después del bucket name
      final bucketIndex = pathSegments.indexOf('product_images');
      if (bucketIndex != -1 && bucketIndex + 1 < pathSegments.length) {
        final filePath = pathSegments.sublist(bucketIndex + 1).join('/');

        await _supabase.storage
            .from('product_images')
            .remove([filePath]);

        print('✅ Imagen eliminada de Supabase: $filePath');

        // Actualizar estadísticas
        final usage = await _getStorageUsage();
        print('📊 Almacenamiento después de eliminar: ${usage['estimatedSizeMB']?.toStringAsFixed(2)} MB usado');
      } else {
        print('⚠️ No se pudo extraer el path de la imagen: $imageUrl');
      }
    } catch (e) {
      print('❌ Error eliminando imagen de Supabase: $e');
      throw Exception('Error al eliminar imagen: $e');
    }
  }

  // 🔹 Subir múltiples imágenes CON VALIDACIONES
  Future<List<String>> uploadMultipleImages(
      List<File> imageFiles,
      String businessId,
      String productId
      ) async {
    try {
      print('🔄 Subiendo ${imageFiles.length} imágenes a Supabase...');

      // Validar todas las imágenes primero
      double totalSizeMB = 0;
      for (var imageFile in imageFiles) {
        await _validateFileSize(imageFile);
        totalSizeMB += (await imageFile.length()) / (1024 * 1024);
      }

      // Verificar espacio total necesario
      final hasSpace = await _hasEnoughSpace(totalSizeMB);
      if (!hasSpace) {
        final usage = await _getStorageUsage();
        throw Exception('No hay espacio suficiente para ${imageFiles.length} imágenes (${totalSizeMB.toStringAsFixed(2)} MB). '
            'Espacio disponible: ${usage['remainingMB']?.toStringAsFixed(2)} MB');
      }

      List<String> imageUrls = [];

      for (var imageFile in imageFiles) {
        final url = await uploadProductImage(imageFile, businessId, productId);
        if (url != null) {
          imageUrls.add(url);
        } else {
          print('⚠️ Una imagen no se pudo subir correctamente');
        }
      }

      print('✅ ${imageUrls.length}/${imageFiles.length} imágenes subidas exitosamente a Supabase');
      return imageUrls;
    } catch (e) {
      print('❌ Error subiendo múltiples imágenes a Supabase: $e');
      rethrow;
    }
  }

  // 🔹 Eliminar múltiples imágenes
  Future<void> deleteMultipleImages(List<String> imageUrls) async {
    try {
      if (imageUrls.isEmpty) {
        print('⚠️ Lista de imágenes vacía, no hay nada que eliminar');
        return;
      }

      print('🔄 Eliminando ${imageUrls.length} imágenes...');

      // Extraer todos los paths primero
      List<String> filePaths = [];

      for (var imageUrl in imageUrls) {
        if (imageUrl.isEmpty) continue;

        final uri = Uri.parse(imageUrl);
        final pathSegments = uri.pathSegments;

        final bucketIndex = pathSegments.indexOf('product_images');
        if (bucketIndex != -1 && bucketIndex + 1 < pathSegments.length) {
          final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
          filePaths.add(filePath);
        }
      }

      // Eliminar todos los archivos de una vez
      if (filePaths.isNotEmpty) {
        await _supabase.storage
            .from('product_images')
            .remove(filePaths);

        print('✅ ${filePaths.length} imágenes eliminadas de Supabase');

        // Actualizar estadísticas
        final usage = await _getStorageUsage();
        print('📊 Almacenamiento después de eliminar: ${usage['estimatedSizeMB']?.toStringAsFixed(2)} MB usado');
      } else {
        print('⚠️ No se pudieron extraer paths válidos de las URLs');
      }
    } catch (e) {
      print('❌ Error eliminando múltiples imágenes de Supabase: $e');
      throw Exception('Error al eliminar imágenes: $e');
    }
  }

  // 🔹 Obtener todas las imágenes de un producto
  Future<List<String>> getProductImages(String businessId, String productId) async {
    try {
      print('🔄 Obteniendo imágenes para producto: $productId');

      final response = await _supabase.storage
          .from('product_images')
          .list(path: 'businesses/$businessId/products/$productId');

      List<String> imageUrls = [];
      for (var file in response) {
        final publicUrl = _supabase.storage
            .from('product_images')
            .getPublicUrl('businesses/$businessId/products/$productId/${file.name}');
        imageUrls.add(publicUrl);
      }

      print('✅ ${imageUrls.length} imágenes encontradas para el producto');
      return imageUrls;
    } catch (e) {
      print('❌ Error obteniendo imágenes del producto: $e');
      return [];
    }
  }

  // 🔹 OBTENER ESTADÍSTICAS DE ALMACENAMIENTO (para el widget de monitoreo)
  Future<Map<String, dynamic>> getStorageStatistics() async {
    try {
      final usage = await _getStorageUsage();

      return {
        'totalFiles': usage['totalFiles'] ?? 0,
        'usedMB': (usage['estimatedSizeMB'] ?? 0).toStringAsFixed(2),
        'usagePercentage': (usage['usagePercentage'] ?? 0).toStringAsFixed(1),
        'remainingMB': (usage['remainingMB'] ?? maxTotalStorageMB).toStringAsFixed(2),
        'maxStorageMB': maxTotalStorageMB,
        'maxFileSizeMB': maxFileSizeMB,
        'status': _getStorageStatus(usage['usagePercentage'] ?? 0),
      };
    } catch (e) {
      print('❌ Error obteniendo estadísticas de almacenamiento: $e');
      return {
        'totalFiles': 0,
        'usedMB': '0.00',
        'usagePercentage': '0.0',
        'remainingMB': maxTotalStorageMB.toStringAsFixed(2),
        'maxStorageMB': maxTotalStorageMB,
        'maxFileSizeMB': maxFileSizeMB,
        'status': 'normal',
      };
    }
  }

  // 🔹 DETERMINAR ESTADO DEL ALMACENAMIENTO
  String _getStorageStatus(double percentage) {
    if (percentage >= 95) return 'critical';
    if (percentage >= 80) return 'warning';
    if (percentage >= 60) return 'notice';
    return 'normal';
  }

  // 🔹 VERIFICAR SI UNA IMAGEN EXISTE
  Future<bool> imageExists(String imageUrl) async {
    try {
      if (imageUrl.isEmpty) return false;

      final response = await _supabase.storage
          .from('product_images')
          .list();

      for (var file in response) {
        final fileUrl = _supabase.storage
            .from('product_images')
            .getPublicUrl(file.name);
        if (fileUrl == imageUrl) {
          return true;
        }
      }
      return false;
    } catch (e) {
      print('❌ Error verificando existencia de imagen: $e');
      return false;
    }
  }
}