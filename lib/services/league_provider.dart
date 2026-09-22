import 'package:flutter/material.dart';

class Provider<T extends ChangeNotifier> extends InheritedNotifier<T> {
  const Provider({
    super.key,
    required T service,
    required super.child,
  }) : super(notifier: service);

  static T of<T extends ChangeNotifier>(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<Provider<T>>();
    assert(provider != null, 'No Provider found in context');
    return provider!.notifier!;
  }
}
