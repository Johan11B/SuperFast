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
      // Obtener estadísticas de todos los buckets
      final productImages = await _supabase.storage.from('product_images').list();
      final userImages = await _supabase.storage.from('user_images').list();
      final businessImages = await _supabase.storage.from('business_images').list();

      int totalFiles = productImages.length + userImages.length + businessImages.length;

      // Estimación conservadora: 500 KB por imagen
      double estimatedSizeMB = totalFiles * 0.5;

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

  // 🔹 Subir imagen de perfil de usuario
  Future<String?> uploadProfileImage(File imageFile, String userId) async {
    try {
      print('🔄 Iniciando subida de imagen de perfil...');

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

      // 🔹 VALIDACIÓN 3: UserId válido
      if (userId.isEmpty) {
        throw Exception('UserId no válido para subir imagen.');
      }

      print('📋 Validaciones pasadas:');
      print('   - Tamaño archivo: ${fileSizeMB.toStringAsFixed(2)} MB');
      print('   - UserId: $userId');

      // Generar nombre único para la imagen
      String fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      String storagePath = 'users/$userId/profile/$fileName';

      print('🔄 Subiendo imagen a: $storagePath');

      // Subir el archivo a Supabase
      await _supabase.storage
          .from('user_images')
          .upload(storagePath, imageFile);

      // Obtener URL pública de la imagen
      final String publicUrl = _supabase.storage
          .from('user_images')
          .getPublicUrl(storagePath);

      // Actualizar estadísticas de uso
      final usage = await _getStorageUsage();
      print('📊 Estado almacenamiento:');
      print('   - Archivos: ${usage['totalFiles']}');
      print('   - Espacio usado: ${usage['estimatedSizeMB']?.toStringAsFixed(2)} MB');
      print('   - Porcentaje: ${usage['usagePercentage']?.toStringAsFixed(1)}%');
      print('   - Espacio libre: ${usage['remainingMB']?.toStringAsFixed(2)} MB');

      print('✅ Imagen de perfil subida exitosamente: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('❌ Error subiendo imagen de perfil a Supabase: $e');

      // Manejar errores específicos
      final errorMessage = e.toString();
      if (errorMessage.contains('Límite de almacenamiento')) {
        throw Exception(errorMessage); // Propagar el error original
      } else if (errorMessage.contains('demasiado grande')) {
        throw Exception(errorMessage); // Propagar el error original
      } else if (errorMessage.contains('UserId no válido')) {
        throw Exception(errorMessage); // Propagar el error original
      } else if (errorMessage.contains('JWT')) {
        throw Exception('Error de autenticación. Por favor, cierra sesión y vuelve a iniciar.');
      } else if (errorMessage.contains('network') || errorMessage.contains('Socket')) {
        throw Exception('Error de conexión. Verifica tu internet e intenta nuevamente.');
      } else {
        throw Exception('Error al subir imagen de perfil: $errorMessage');
      }
    }
  }

  // 🔹 Subir logo de empresa
  Future<String?> uploadBusinessLogo(File imageFile, String businessId) async {
    try {
      print('🔄 Iniciando subida de logo de empresa...');

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

      // 🔹 VALIDACIÓN 3: BusinessId válido
      if (businessId.isEmpty) {
        throw Exception('BusinessId no válido para subir logo.');
      }

      print('📋 Validaciones pasadas:');
      print('   - Tamaño archivo: ${fileSizeMB.toStringAsFixed(2)} MB');
      print('   - BusinessId: $businessId');

      // Generar nombre único para la imagen
      String fileName = 'logo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      String storagePath = 'businesses/$businessId/logo/$fileName';

      print('🔄 Subiendo logo a: $storagePath');

      // Subir el archivo a Supabase
      await _supabase.storage
          .from('business_images')
          .upload(storagePath, imageFile);

      // Obtener URL pública de la imagen
      final String publicUrl = _supabase.storage
          .from('business_images')
          .getPublicUrl(storagePath);

      // Actualizar estadísticas de uso
      final usage = await _getStorageUsage();
      print('📊 Estado almacenamiento:');
      print('   - Archivos: ${usage['totalFiles']}');
      print('   - Espacio usado: ${usage['estimatedSizeMB']?.toStringAsFixed(2)} MB');
      print('   - Porcentaje: ${usage['usagePercentage']?.toStringAsFixed(1)}%');
      print('   - Espacio libre: ${usage['remainingMB']?.toStringAsFixed(2)} MB');

      print('✅ Logo de empresa subido exitosamente: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('❌ Error subiendo logo de empresa a Supabase: $e');

      // Manejar errores específicos
      final errorMessage = e.toString();
      if (errorMessage.contains('Límite de almacenamiento')) {
        throw Exception(errorMessage); // Propagar el error original
      } else if (errorMessage.contains('demasiado grande')) {
        throw Exception(errorMessage); // Propagar el error original
      } else if (errorMessage.contains('BusinessId no válido')) {
        throw Exception(errorMessage); // Propagar el error original
      } else if (errorMessage.contains('JWT')) {
        throw Exception('Error de autenticación. Por favor, cierra sesión y vuelve a iniciar.');
      } else if (errorMessage.contains('network') || errorMessage.contains('Socket')) {
        throw Exception('Error de conexión. Verifica tu internet e intenta nuevamente.');
      } else {
        throw Exception('Error al subir logo de empresa: $errorMessage');
      }
    }
  }

  // 🔹 Subir imagen de producto a Supabase Storage CON VALIDACIONES
  Future<String?> uploadProductImage(File imageFile, String businessId, String productId) async {
    try {
      print('🔄 Iniciando subida de imagen de producto...');

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

      print('✅ Imagen de producto subida exitosamente: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('❌ Error subiendo imagen de producto a Supabase: $e');

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
        throw Exception('Error al subir imagen de producto: $errorMessage');
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

      // Determinar el bucket basado en la URL
      String bucketName = '';
      if (imageUrl.contains('product_images')) {
        bucketName = 'product_images';
      } else if (imageUrl.contains('user_images')) {
        bucketName = 'user_images';
      } else if (imageUrl.contains('business_images')) {
        bucketName = 'business_images';
      } else {
        print('⚠️ No se pudo determinar el bucket de la imagen: $imageUrl');
        return;
      }

      // En Supabase, el path completo está después del bucket name
      final bucketIndex = pathSegments.indexOf(bucketName);
      if (bucketIndex != -1 && bucketIndex + 1 < pathSegments.length) {
        final filePath = pathSegments.sublist(bucketIndex + 1).join('/');

        await _supabase.storage
            .from(bucketName)
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

      // Agrupar por bucket
      final Map<String, List<String>> bucketPaths = {
        'product_images': [],
        'user_images': [],
        'business_images': [],
      };

      for (var imageUrl in imageUrls) {
        if (imageUrl.isEmpty) continue;

        final uri = Uri.parse(imageUrl);
        final pathSegments = uri.pathSegments;

        // Determinar bucket y extraer path
        for (final bucketName in bucketPaths.keys) {
          if (imageUrl.contains(bucketName)) {
            final bucketIndex = pathSegments.indexOf(bucketName);
            if (bucketIndex != -1 && bucketIndex + 1 < pathSegments.length) {
              final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
              bucketPaths[bucketName]!.add(filePath);
            }
            break;
          }
        }
      }

      // Eliminar archivos por bucket
      for (final bucketName in bucketPaths.keys) {
        final paths = bucketPaths[bucketName]!;
        if (paths.isNotEmpty) {
          await _supabase.storage
              .from(bucketName)
              .remove(paths);

          print('✅ ${paths.length} imágenes eliminadas del bucket $bucketName');
        }
      }

      // Actualizar estadísticas
      final usage = await _getStorageUsage();
      print('📊 Almacenamiento después de eliminar: ${usage['estimatedSizeMB']?.toStringAsFixed(2)} MB usado');
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

      // Determinar el bucket basado en la URL
      String bucketName = '';
      if (imageUrl.contains('product_images')) {
        bucketName = 'product_images';
      } else if (imageUrl.contains('user_images')) {
        bucketName = 'user_images';
      } else if (imageUrl.contains('business_images')) {
        bucketName = 'business_images';
      } else {
        return false;
      }

      final response = await _supabase.storage
          .from(bucketName)
          .list();

      for (var file in response) {
        final fileUrl = _supabase.storage
            .from(bucketName)
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

  // 🔹 CREAR BUCKETS SI NO EXISTEN (método de inicialización)
  Future<void> initializeBuckets() async {
    try {
      print('🔄 Verificando buckets de almacenamiento...');

      // Los buckets se crean automáticamente al subir la primera imagen
      // Este método es solo para verificación
      final buckets = await _supabase.storage.listBuckets();
      print('✅ Buckets disponibles: ${buckets.map((b) => b.name).toList()}');

    } catch (e) {
      print('❌ Error verificando buckets: $e');
    }
  }
}