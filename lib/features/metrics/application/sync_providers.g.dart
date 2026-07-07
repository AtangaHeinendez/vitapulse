// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(healthSource)
final healthSourceProvider = HealthSourceProvider._();

final class HealthSourceProvider
    extends $FunctionalProvider<HealthSource, HealthSource, HealthSource>
    with $Provider<HealthSource> {
  HealthSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'healthSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$healthSourceHash();

  @$internal
  @override
  $ProviderElement<HealthSource> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  HealthSource create(Ref ref) {
    return healthSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HealthSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HealthSource>(value),
    );
  }
}

String _$healthSourceHash() => r'5dd458998a5d8ba318c1d0a15e459401c5fd5aa6';

@ProviderFor(metricsRepository)
final metricsRepositoryProvider = MetricsRepositoryProvider._();

final class MetricsRepositoryProvider
    extends
        $FunctionalProvider<
          MetricsRepository,
          MetricsRepository,
          MetricsRepository
        >
    with $Provider<MetricsRepository> {
  MetricsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'metricsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$metricsRepositoryHash();

  @$internal
  @override
  $ProviderElement<MetricsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MetricsRepository create(Ref ref) {
    return metricsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MetricsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MetricsRepository>(value),
    );
  }
}

String _$metricsRepositoryHash() => r'533c24762f23899d3ed5eeeb70fcf197c85afcbc';

/// Latest stored value of each metric (refreshes after every sync).

@ProviderFor(latestMetrics)
final latestMetricsProvider = LatestMetricsProvider._();

/// Latest stored value of each metric (refreshes after every sync).

final class LatestMetricsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MetricSample>>,
          List<MetricSample>,
          FutureOr<List<MetricSample>>
        >
    with
        $FutureModifier<List<MetricSample>>,
        $FutureProvider<List<MetricSample>> {
  /// Latest stored value of each metric (refreshes after every sync).
  LatestMetricsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'latestMetricsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$latestMetricsHash();

  @$internal
  @override
  $FutureProviderElement<List<MetricSample>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<MetricSample>> create(Ref ref) {
    return latestMetrics(ref);
  }
}

String _$latestMetricsHash() => r'1cef664406bd4ae218faaf54ff750186e484d977';

/// Orchestrates: Health Connect -> health_metrics -> daily_summaries.
/// No-ops on web, where the dashboard only reads what the phone synced.

@ProviderFor(SyncController)
final syncControllerProvider = SyncControllerProvider._();

/// Orchestrates: Health Connect -> health_metrics -> daily_summaries.
/// No-ops on web, where the dashboard only reads what the phone synced.
final class SyncControllerProvider
    extends $AsyncNotifierProvider<SyncController, SyncState> {
  /// Orchestrates: Health Connect -> health_metrics -> daily_summaries.
  /// No-ops on web, where the dashboard only reads what the phone synced.
  SyncControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncControllerHash();

  @$internal
  @override
  SyncController create() => SyncController();
}

String _$syncControllerHash() => r'0bf538df70089caa304d07b6666f7fabf7c71538';

/// Orchestrates: Health Connect -> health_metrics -> daily_summaries.
/// No-ops on web, where the dashboard only reads what the phone synced.

abstract class _$SyncController extends $AsyncNotifier<SyncState> {
  FutureOr<SyncState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<SyncState>, SyncState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<SyncState>, SyncState>,
              AsyncValue<SyncState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
