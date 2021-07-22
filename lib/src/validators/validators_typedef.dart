import 'package:reactive_forms/src/models/abstract_control.dart';

/// Signature of a function that receives a control and synchronously
/// returns a map of validation errors if present, otherwise null.
typedef ValidatorFunction = Map<String, dynamic>? Function(
    AbstractControl<dynamic> control);

/// Signature of a function that receives a control and returns a Future
/// that emits validation errors if present, otherwise null.
typedef AsyncValidatorFunction = Future<Map<String, dynamic>?> Function(
    AbstractControl<dynamic> control);
