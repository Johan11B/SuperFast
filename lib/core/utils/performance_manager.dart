import 'dart:developer';
import 'package:flutter/foundation.dart';

class PerformanceManager {
  static final PerformanceManager _instance = PerformanceManager._internal();
  factory PerformanceManager() => _instance;
  PerformanceManager._internal();

  final Map<String, PerformanceMetric> _metrics = {};
  final List<PerformanceResult> _results = [];

  // Método para medir operaciones síncronas y asíncronas
  static Future<T> measure<T>(
      String operationName,
      Future<T> Function() operation, {
        bool logToConsole = true,
      }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await operation();
      stopwatch.stop();

      final metric = PerformanceMetric(
        name: operationName,
        duration: stopwatch.elapsedMilliseconds,
        timestamp: DateTime.now(),
        type: _getOperationType(operationName),
      );

      _instance._metrics[operationName] = metric;
      _instance._results.add(PerformanceResult(
        metric: metric,
        success: true,
        additionalInfo: 'Operación completada exitosamente',
      ));

      if (logToConsole && kDebugMode) {
        print('⏱️ PERFORMANCE: $operationName - ${metric.duration}ms');
      }

      return result;
    } catch (e) {
      stopwatch.stop();
      _instance._results.add(PerformanceResult(
        metric: PerformanceMetric(
          name: operationName,
          duration: stopwatch.elapsedMilliseconds,
          timestamp: DateTime.now(),
          type: _getOperationType(operationName),
        ),
        success: false,
        additionalInfo: 'Error: $e',
      ));
      rethrow;
    }
  }

  // Método para operaciones síncronas
  static T measureSync<T>(
      String operationName,
      T Function() operation, {
        bool logToConsole = true,
      }) {
    final stopwatch = Stopwatch()..start();
    try {
      final result = operation();
      stopwatch.stop();

      final metric = PerformanceMetric(
        name: operationName,
        duration: stopwatch.elapsedMilliseconds,
        timestamp: DateTime.now(),
        type: _getOperationType(operationName),
      );

      _instance._metrics[operationName] = metric;
      _instance._results.add(PerformanceResult(
        metric: metric,
        success: true,
        additionalInfo: 'Operación completada exitosamente',
      ));

      if (logToConsole && kDebugMode) {
        print('⏱️ PERFORMANCE: $operationName - ${metric.duration}ms');
      }

      return result;
    } catch (e) {
      stopwatch.stop();
      _instance._results.add(PerformanceResult(
        metric: PerformanceMetric(
          name: operationName,
          duration: stopwatch.elapsedMilliseconds,
          timestamp: DateTime.now(),
          type: _getOperationType(operationName),
        ),
        success: false,
        additionalInfo: 'Error: $e',
      ));
      rethrow;
    }
  }

  static PerformanceType _getOperationType(String operationName) {
    if (operationName.toLowerCase().contains('login')) return PerformanceType.auth;
    if (operationName.toLowerCase().contains('navigate')) return PerformanceType.navigation;
    if (operationName.toLowerCase().contains('load')) return PerformanceType.data;
    if (operationName.toLowerCase().contains('build')) return PerformanceType.ui;
    return PerformanceType.other;
  }

  // Obtener métricas para mostrar
  static List<PerformanceMetric> get metrics => _instance._metrics.values.toList();
  static List<PerformanceResult> get results => _instance._results;

  // Estadísticas
  static PerformanceStats get stats {
    final metrics = _instance._metrics.values.toList();
    if (metrics.isEmpty) return PerformanceStats.empty();

    final durations = metrics.map((m) => m.duration).toList();
    final total = durations.reduce((a, b) => a + b);
    final average = total / durations.length;
    final max = durations.reduce((a, b) => a > b ? a : b);
    final min = durations.reduce((a, b) => a < b ? a : b);

    return PerformanceStats(
      totalOperations: metrics.length,
      totalTime: total,
      averageTime: average.round(),
      maxTime: max,
      minTime: min,
      successfulOperations: _instance._results.where((r) => r.success).length,
      failedOperations: _instance._results.where((r) => !r.success).length,
    );
  }

  // Limpiar métricas
  static void clear() {
    _instance._metrics.clear();
    _instance._results.clear();
  }
}

// Enums y modelos de datos
enum PerformanceType { auth, navigation, data, ui, other }

class PerformanceMetric {
  final String name;
  final int duration; // en milisegundos
  final DateTime timestamp;
  final PerformanceType type;

  PerformanceMetric({
    required this.name,
    required this.duration,
    required this.timestamp,
    required this.type,
  });

  String get formattedDuration => '${duration}ms';
  String get typeName => _getTypeName(type);

  String _getTypeName(PerformanceType type) {
    switch (type) {
      case PerformanceType.auth: return 'Autenticación';
      case PerformanceType.navigation: return 'Navegación';
      case PerformanceType.data: return 'Datos';
      case PerformanceType.ui: return 'Interfaz';
      case PerformanceType.other: return 'Otro';
    }
  }
}

class PerformanceResult {
  final PerformanceMetric metric;
  final bool success;
  final String additionalInfo;

  PerformanceResult({
    required this.metric,
    required this.success,
    this.additionalInfo = '',
  });
}

class PerformanceStats {
  final int totalOperations;
  final int totalTime;
  final int averageTime;
  final int maxTime;
  final int minTime;
  final int successfulOperations;
  final int failedOperations;

  const PerformanceStats({
    required this.totalOperations,
    required this.totalTime,
    required this.averageTime,
    required this.maxTime,
    required this.minTime,
    required this.successfulOperations,
    required this.failedOperations,
  });

  factory PerformanceStats.empty() {
    return PerformanceStats(
      totalOperations: 0,
      totalTime: 0,
      averageTime: 0,
      maxTime: 0,
      minTime: 0,
      successfulOperations: 0,
      failedOperations: 0,
    );
  }

  double get successRate => totalOperations == 0 ? 0 : (successfulOperations / totalOperations * 100);
}