import 'metric_type.dart';

/// One measurement destined for (or read from) the `health_metrics` table.
class MetricSample {
  const MetricSample({
    required this.type,
    required this.value,
    required this.recordedAt,
    this.source = 'health_connect',
  });

  final MetricType type;
  final double value;
  final DateTime recordedAt;
  final String source;

  Map<String, dynamic> toRow(String userId) => {
        'user_id': userId,
        'metric_type': type.dbName,
        'value': value,
        'unit': type.unit,
        'recorded_at': recordedAt.toUtc().toIso8601String(),
        'source': source,
      };

  factory MetricSample.fromRow(Map<String, dynamic> row) => MetricSample(
        type: MetricType.fromDbName(row['metric_type'] as String),
        value: (row['value'] as num).toDouble(),
        recordedAt: DateTime.parse(row['recorded_at'] as String).toLocal(),
        source: row['source'] as String? ?? 'health_connect',
      );
}
