// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'detail_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(metricDetail)
final metricDetailProvider = MetricDetailFamily._();

final class MetricDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<DetailData>,
          DetailData,
          FutureOr<DetailData>
        >
    with $FutureModifier<DetailData>, $FutureProvider<DetailData> {
  MetricDetailProvider._({
    required MetricDetailFamily super.from,
    required (String, ChartRange) super.argument,
  }) : super(
         retry: null,
         name: r'metricDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$metricDetailHash();

  @override
  String toString() {
    return r'metricDetailProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<DetailData> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<DetailData> create(Ref ref) {
    final argument = this.argument as (String, ChartRange);
    return metricDetail(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is MetricDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$metricDetailHash() => r'906d08557535ae4ec61aa2d82af1bc816455fe99';

final class MetricDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<DetailData>, (String, ChartRange)> {
  MetricDetailFamily._()
    : super(
        retry: null,
        name: r'metricDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MetricDetailProvider call(String metricKey, ChartRange range) =>
      MetricDetailProvider._(argument: (metricKey, range), from: this);

  @override
  String toString() => r'metricDetailProvider';
}
