// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminders_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(notificationsService)
final notificationsServiceProvider = NotificationsServiceProvider._();

final class NotificationsServiceProvider
    extends
        $FunctionalProvider<
          NotificationsService,
          NotificationsService,
          NotificationsService
        >
    with $Provider<NotificationsService> {
  NotificationsServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationsServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationsServiceHash();

  @$internal
  @override
  $ProviderElement<NotificationsService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NotificationsService create(Ref ref) {
    return notificationsService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotificationsService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotificationsService>(value),
    );
  }
}

String _$notificationsServiceHash() =>
    r'47e53fe1e4db300ac765e5659f411b13566b9628';

@ProviderFor(Reminders)
final remindersProvider = RemindersProvider._();

final class RemindersProvider
    extends $NotifierProvider<Reminders, ReminderSettings> {
  RemindersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'remindersProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$remindersHash();

  @$internal
  @override
  Reminders create() => Reminders();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReminderSettings value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReminderSettings>(value),
    );
  }
}

String _$remindersHash() => r'be289c3490334ed79ef41ff8b31f74b288936719';

abstract class _$Reminders extends $Notifier<ReminderSettings> {
  ReminderSettings build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ReminderSettings, ReminderSettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ReminderSettings, ReminderSettings>,
              ReminderSettings,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
