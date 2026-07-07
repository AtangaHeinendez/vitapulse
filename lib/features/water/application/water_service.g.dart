// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'water_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Writes manual entries (water, weight, blood pressure) to Supabase,
/// mirrors water to Health Connect, and refreshes the affected days.

@ProviderFor(manualEntryService)
final manualEntryServiceProvider = ManualEntryServiceProvider._();

/// Writes manual entries (water, weight, blood pressure) to Supabase,
/// mirrors water to Health Connect, and refreshes the affected days.

final class ManualEntryServiceProvider
    extends
        $FunctionalProvider<
          ManualEntryService,
          ManualEntryService,
          ManualEntryService
        >
    with $Provider<ManualEntryService> {
  /// Writes manual entries (water, weight, blood pressure) to Supabase,
  /// mirrors water to Health Connect, and refreshes the affected days.
  ManualEntryServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'manualEntryServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$manualEntryServiceHash();

  @$internal
  @override
  $ProviderElement<ManualEntryService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ManualEntryService create(Ref ref) {
    return manualEntryService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ManualEntryService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ManualEntryService>(value),
    );
  }
}

String _$manualEntryServiceHash() =>
    r'af1555fe13ac0206c0713205f1f8020a956f7b62';
