import 'dart:async';

import 'package:reactive_forms/src/validators/validators_typedef.dart';

import 'control_status.dart';

/// This is the base class for [FormGroup], [FormArray] and [FormControl].
///
/// It provides some of the shared behavior that all controls and groups have,
/// like running validators, calculating status, and resetting state.
///
/// It also defines the properties that are shared between all sub-classes,
/// like value and valid.
///
/// It shouldn't be instantiated directly.
abstract class AbstractControl<T> {
  final _statusChanges = StreamController<ControlStatus>.broadcast();
  final _valueChanges = StreamController<T?>.broadcast();
  final _touchChanges = StreamController<bool>.broadcast();
  final List<ValidatorFunction> _validators = <ValidatorFunction>[];
  final List<AsyncValidatorFunction> _asyncValidators =
      <AsyncValidatorFunction>[];

  StreamSubscription<Map<String, dynamic>?>? _asyncValidationSubscription;
  Map<String, dynamic> _errors = <String, dynamic>{};
  bool _pristine = true;

  T? val;

  ControlStatus _status;

  /// The parent control.
  AbstractControl<Object>? parent;

  /// Async validators debounce timer.
  Timer? _debounceTimer;

  /// Async validators debounce time in milliseconds.
  final int _asyncValidatorsDebounceTime;

  bool _touched;

  /// Constructor of the [AbstractControl].
  AbstractControl({
    List<ValidatorFunction> validators = const [],
    List<AsyncValidatorFunction> asyncValidators = const [],
    int asyncValidatorsDebounceTime = 250,
    bool disabled = false,
    bool touched = false,
  })  : assert(asyncValidatorsDebounceTime >= 0),
        _asyncValidatorsDebounceTime = asyncValidatorsDebounceTime,
        _touched = touched,
        _status = disabled ? ControlStatus.disabled : ControlStatus.valid {
    setValidators(validators);
    setAsyncValidators(asyncValidators);
  }

  /// A control is `dirty` if the user has changed the value in the UI.
  ///
  /// Gets true if the user has changed the value of this control in the UI.
  ///
  /// Programmatic changes to a control's value do not mark it dirty.
  ///
  /// See also [pristine].
  bool get dirty => !pristine;

  /// A control is `pristine` if the user has not yet changed the value
  /// in the UI.
  ///
  /// Gets true if the user has not yet changed the value in the UI.
  /// Programmatic changes to a control's value do not mark it dirty.
  ///
  /// See also [dirty].
  bool get pristine => _pristine;

  /// Gets if the control is touched or not.
  ///
  /// A control is touched when the user taps on the ReactiveFormField widget
  /// and then remove focus or completes the text edition. Validation messages
  /// will begin to show up when the FormControl is touched.
  bool get touched => _touched;

  /// The list of functions that determines the validity of this control.
  ///
  /// In [FormGroup] these come in handy when you want to perform validation
  /// that considers the value of more than one child control.
  List<ValidatorFunction> get validators =>
      List<ValidatorFunction>.unmodifiable(_validators);

  /// Sets the synchronous [validators] that are active on this control. Calling
  /// this overwrites any existing sync validators.
  ///
  /// If [autoValidate] is `true` then the status of the control is recalculated
  /// after setting the new [validators]. If [autoValidate] is `false` (default)
  /// you must call **updateValueAndValidity()**, or assign a new value to the
  /// control for the new validation to take effect.
  ///
  /// When [updateParent] is `true` or not supplied (the default) each change
  /// affects this control and its parent, otherwise only affects to this
  /// control. This argument is only taking into account if [autoValidate] is
  /// equals to `true`.
  ///
  /// When [emitEvent] is true or not supplied (the default), both the
  /// *statusChanges* and *valueChanges* emit events with the latest status
  /// and value when the control is reset. When false, no events are emitted.
  /// This argument is only taking into account if [autoValidate] is equals to
  /// `true`.
  void setValidators(
    List<ValidatorFunction> validators, {
    bool autoValidate = false,
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    clearValidators();
    _validators.addAll(validators);

    if (autoValidate) {
      updateValueAndValidity(updateParent: updateParent, emitEvent: emitEvent);
    }
  }

  /// Empties out the sync validator list.
  ///
  /// When you add or remove a validator at run time, you must call
  /// **updateValueAndValidity()**, or assign a new value to the control for
  /// the new validation to take effect.
  void clearValidators() {
    _validators.clear();
  }

  /// The list of async functions that determines the validity of this control.
  ///
  /// In [FormGroup] these come in handy when you want to perform validation
  /// that considers the value of more than one child control.
  List<AsyncValidatorFunction> get asyncValidators =>
      List<AsyncValidatorFunction>.unmodifiable(_asyncValidators);

  /// Sets the async [validators] that are active on this control. Calling this
  /// overwrites any existing async validators.
  ///
  /// If [autoValidate] is `true` then the status of the control is recalculated
  /// after setting the new [validators]. If [autoValidate] is `false` (default)
  /// you must call **updateValueAndValidity()**, or assign a new value to the
  /// control for the new validation to take effect.
  ///
  /// When [updateParent] is `true` or not supplied (the default) each change
  /// affects this control and its parent, otherwise only affects to this
  /// control. This argument is only taking into account if [autoValidate] is
  /// equals to `true`.
  ///
  /// When [emitEvent] is true or not supplied (the default), both the
  /// *statusChanges* and *valueChanges* emit events with the latest status
  /// and value when the control is reset. When false, no events are emitted.
  /// This argument is only taking into account if [autoValidate] is equals to
  /// `true`.
  void setAsyncValidators(
    List<AsyncValidatorFunction> validators, {
    bool autoValidate = false,
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    clearAsyncValidators();
    _asyncValidators.addAll(validators);

    if (autoValidate) {
      updateValueAndValidity(updateParent: updateParent, emitEvent: emitEvent);
    }
  }

  /// Empties out the async validator list.
  ///
  /// When you add or remove a validator at run time, you must call
  /// **updateValueAndValidity()**, or assign a new value to the control for
  /// the new validation to take effect.
  void clearAsyncValidators() {
    _asyncValidators.clear();
  }

  /// The current value of the control.
  T? get value => val;

  /// Sets the value to the control
  set value(T? value) {
    updateValue(value);
  }

  /// An object containing any errors generated by failing validation,
  /// or empty [Map] if there are no errors.
  Map<String, Object> get errors => Map<String, Object>.unmodifiable(_errors);

  /// A [Stream] that emits the status every time it changes.
  Stream<ControlStatus> get statusChanged => _statusChanges.stream;

  /// A [Stream] that emits the value of the control every time it changes.
  Stream<T?> get valueChanges => _valueChanges.stream;

  /// A [Stream] that emits an event every time the control
  /// is touched or untouched.
  Stream<bool> get touchChanges => _touchChanges.stream;

  /// A control is valid when its [status] is ControlStatus.valid.
  bool get valid => status == ControlStatus.valid;

  /// A control is invalid when its [status] is ControlStatus.invalid.
  bool get invalid => status == ControlStatus.invalid;

  /// A control is pending when its [status] is ControlStatus.pending.
  bool get pending => status == ControlStatus.pending;

  /// A control is disabled when its [status] is ControlStatus.disabled.
  bool get disabled => status == ControlStatus.disabled;

  /// A control is enabled as long as its [status] is
  /// not ControlStatus.disabled.
  bool get enabled => !disabled;

  /// True whether the control has validation errors.
  bool get hasErrors => errors.isNotEmpty;

  /// The validation status of the control.
  ///
  /// There are four possible validation status values:
  /// * VALID: This control has passed all validation checks.
  /// * INVALID: This control has failed at least one validation check.
  /// * PENDING: This control is in the midst of conducting a validation check.
  ///
  /// These status values are mutually exclusive, so a control cannot be both
  /// valid AND invalid or invalid AND pending.
  ControlStatus get status => _status;

  /// Reports whether the control with the given [path] has the specified
  /// [errorCode].
  ///
  /// If no [path] is given, this method checks for the error on the current
  /// control.
  ///
  /// ### Example:
  /// ```dart
  /// final form = FormGroup({
  ///   'address': FormGroup({
  ///     'street': FormControl<String>(validators: [Validators.required]),
  ///   }),
  /// });
  ///
  /// final hasError = form.hasError(ValidationMessages.required, 'address.street');
  /// print(hasError); // outputs: true
  /// ```
  bool hasError(String errorCode, [String? path]) {
    return getError(errorCode, path) != null;
  }

  /// Returns the error data for the control with the given [errorCode] in the
  /// given [path].
  ///
  /// If no [path] is given, this method checks for the error on the current
  /// control.
  ///
  /// ### Example:
  /// ```dart
  /// final form = FormGroup({
  ///   'payment': FormGroup({
  ///     'amount': FormControl<double>(
  ///       value: 5.0,
  ///       validators: [Validators.min(10.0)]
  ///      ),
  ///   }),
  /// });
  ///
  /// final error = form.getError(ValidationMessages.min, 'payment.amount');
  /// print(error); // outputs: { min: 10.0, actual: 5.0 }
  /// ```
  Object? getError(String errorCode, [String? path]) {
    final control = path != null ? findControl(path) : this;
    return control!.errors[errorCode];
  }

  /// Marks the control as `dirty`.
  ///
  /// A control becomes dirty when the control's value is changed through
  /// the UI.
  ///
  /// When [updateParent] is false, mark only this control. When true or not
  /// supplied, marks all direct ancestors. Default is true.
  ///
  /// When [emitEvent] is true or not supplied (the default), the
  /// *statusChanges* emit event with the latest status when the control is
  /// mark dirty. When false, no events are emitted.
  void markAsDirty({bool updateParent = true, bool emitEvent = true}) {
    _pristine = false;

    if (emitEvent) {
      _statusChanges.add(_status);
    }

    if (updateParent) {
      parent?.markAsDirty(updateParent: updateParent, emitEvent: emitEvent);
    }
  }

  /// Marks the control as `pristine`.
  ///
  /// If the control has any children, marks all children as `pristine`, and
  /// recalculates the `pristine` status of all parent controls.
  ///
  /// When [updateParent] is false, mark only this control. When true or not
  /// supplied, marks all direct ancestors. Default is true.
  void markAsPristine({bool updateParent = true}) {
    _pristine = true;

    forEachChild((control) => control.markAsPristine(updateParent: false));

    if (updateParent) {
      parent?.updatePristine(updateParent: updateParent);
    }
  }

  /// Marks the control as touched.
  ///
  /// When [updateParent] is false, mark only this control. When true or not
  /// supplied, marks all direct ancestors. Default is true.
  ///
  /// When [emitEvent] is true or not supplied (the default), an
  /// event is emitted.
  void markAsTouched({bool updateParent = true, bool emitEvent = true}) {
    if (!_touched) {
      _touched = true;

      if (emitEvent) {
        _touchChanges.add(_touched);
      }

      if (updateParent) {
        parent?.markAsTouched(updateParent: updateParent, emitEvent: false);
      }
    }
  }

  /// Marks the control and all its descendant controls as touched.
  ///
  /// When [updateParent] is false, mark only this control and descendants.
  /// When true or not supplied, marks also all direct ancestors.
  /// Default is true.
  ///
  /// When [emitEvent] is true or not supplied (the default), a notification
  /// event is emitted.
  void markAllAsTouched({bool updateParent = true, bool emitEvent = true}) {
    markAsTouched(updateParent: updateParent, emitEvent: emitEvent);
    forEachChild((control) => control.markAllAsTouched(updateParent: false));
  }

  /// Marks the control as untouched.
  ///
  /// When [updateParent] is false, mark only this control. When true or not
  /// supplied, marks all direct ancestors. Default is true.
  ///
  /// When [emitEvent] is true or not supplied (the default), a notification
  /// event is emitted.
  void markAsUntouched({bool updateParent = true, bool emitEvent = true}) {
    if (_touched) {
      _touched = false;
      forEachChild((control) => control.markAsUntouched(updateParent: false));

      if (emitEvent) {
        _touchChanges.add(_touched);
      }

      if (updateParent) {
        parent?.updateTouched(updateParent: updateParent);
      }
    }
  }

  /// Enables the control. This means the control is included in validation
  /// checks and the aggregate value of its parent. Its status recalculates
  /// based on its value and its validators.
  ///
  /// When [updateParent] is false, mark only this control. When true or not
  /// supplied, marks all direct ancestors. Default is true.
  ///
  /// When [emitEvent] is true or not supplied (the default), [valueChanges]
  /// and [statusChanged] events are emitted if value or status change.
  /// Otherwise the control update this values but none of this events are
  /// emitted.
  void markAsEnabled({bool updateParent = true, bool emitEvent = true}) {
    if (enabled) {
      return;
    }
    _status = ControlStatus.valid;
    updateValueAndValidity(updateParent: true, emitEvent: emitEvent);
    _updateAncestors(updateParent);
  }

  /// Disables the control.
  ///
  /// This means the control is exempt from validation checks and excluded
  /// from the aggregate value of any parent. Its status is `DISABLED`.
  ///
  /// If the control has children, all children are also disabled.
  ///
  /// When [updateParent] is false, mark only this control. When true or not
  /// supplied, marks all direct ancestors. Default is true.
  ///
  /// When [emitEvent] is true or not supplied (the default), a [statusChanged]
  /// event is emitted.
  void markAsDisabled({bool updateParent = true, bool emitEvent = true}) {
    if (disabled) {
      return;
    }

    _errors.clear();
    _status = ControlStatus.disabled;
    if (emitEvent) {
      _statusChanges.add(_status);
    }
    _updateAncestors(updateParent);
  }

  /// Disposes the control
  void dispose() {
    _statusChanges.close();
    _valueChanges.close();
    _asyncValidationSubscription?.cancel();
  }

  /// Sets the value of the control.
  ///
  /// When [updateParent] is true or not supplied (the default) each change
  /// affects this control and its parent, otherwise only affects to this
  /// control.
  ///
  /// When [emitEvent] is true or not supplied (the default), both the
  /// *statusChanges* and *valueChanges* emit events with the latest status
  /// and value when the control is reset. When false, no events are emitted.
  void updateValue(T? value, {bool updateParent = true, bool emitEvent = true});

  /// Patches the value of the control.
  ///
  /// When [updateParent] is true or not supplied (the default) each change
  /// affects this control and its parent, otherwise only affects to this
  /// control.
  ///
  /// When [emitEvent] is true or not supplied (the default), both the
  /// *statusChanges* and *valueChanges* emit events with the latest status
  /// and value when the control is reset. When false, no events are emitted.
  void patchValue(T? value, {bool updateParent = true, bool emitEvent = true});

  /// Resets the control, marking it as untouched, pristine and setting the
  /// value to null.
  ///
  /// In case of [FormGroup] or [FormArray] all descendants are marked pristine
  /// and untouched, and the value of all descendants are set to null.
  ///
  /// The argument [value] is optional and resets the control with an initial
  /// value.
  ///
  /// The argument [disabled] is optional and resets the disabled status of the
  /// control. If value is `true` then if will disable the control, if value is
  /// `false` then if will enable the control, and if the value is `null` or
  /// not set (the default) then the control will state in the same state that
  /// it previously has.
  ///
  /// The argument [removeFocus] is optional and remove the UI focus from the
  /// control. In case of [FormGroup] or [FormArray] remove the focus from all
  /// descendants.
  ///
  /// When [updateParent] is true or not supplied (the default) each change
  /// affects this control and its parent, otherwise only affects to this
  /// control.
  ///
  /// When [emitEvent] is true or not supplied (the default), both the
  /// *statusChanges* and *valueChanges* events notify listeners with the
  /// latest status and value when the control is reset. When false, no events
  /// are emitted.
  ///
  /// ### FormControl example
  /// ```dart
  /// final control = FormControl<String>();
  ///
  /// control.reset(value: 'John Doe');
  ///
  /// print(control.value); // output: 'John Doe'
  ///
  /// ```
  ///
  /// ### FormGroup example
  /// ```dart
  /// final form = FormGroup({
  ///   'first': FormControl(value: 'first name'),
  ///   'last': FormControl(value: 'last name'),
  /// });
  ///
  /// print(form.value);   // output: {first: 'first name', last: 'last name'}
  ///
  /// form.reset(value: { 'first': 'John', 'last': 'last name' });
  ///
  /// print(form.value); // output: {first: 'John', last: 'last name'}
  ///
  /// ```
  ///
  /// ### FormArray example
  /// ````dart
  /// final array = FormArray<String>([
  ///   FormControl<String>(),
  ///   FormControl<String>(),
  /// ]);
  ///
  /// array.reset(value: ['name', 'last name']);
  ///
  /// print(array.value); // output: ['name', 'last name']
  ///
  /// ```
  void reset({
    T? value,
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) {
    markAsPristine(updateParent: updateParent);
    markAsUntouched(updateParent: updateParent);

    updateValue(value, updateParent: updateParent, emitEvent: emitEvent);

    if (disabled != null) {
      disabled
          ? markAsDisabled(updateParent: true, emitEvent: false)
          : markAsEnabled(updateParent: true, emitEvent: false);
    }

    if (removeFocus) {
      unfocus(touched: false);
    }
  }

  /// Sets errors on a form control when running validations manually,
  /// rather than automatically.
  ///
  /// If [markAsDirty] is true or not set (default) then the control is marked
  /// as dirty.
  ///
  /// See [dirty].
  void setErrors(Map<String, dynamic> errors, {bool markAsDirty = true}) {
    _errors.clear();
    _errors.addAll(errors);

    _updateControlsErrors();

    if (markAsDirty) {
      this.markAsDirty(emitEvent: false);
    }
  }

  /// Removes an error given the error [key].
  ///
  /// If [markAsDirty] is true then the control is marked as dirty.
  ///
  /// See [dirty].
  void removeError(String key, {bool markAsDirty = false}) {
    _errors.removeWhere((errorKey, dynamic value) => errorKey == key);
    _updateControlsErrors();

    if (markAsDirty) {
      this.markAsDirty(emitEvent: false);
    }
  }

  /// Returns true if all children disabled, otherwise returns false.
  bool allControlsDisabled() => disabled;

  /// Returns true if all children has the specified [status], otherwise
  /// returns false.
  bool anyControlsHaveStatus(ControlStatus status) => false;

  ControlStatus _calculateStatus() {
    if (allControlsDisabled()) {
      return ControlStatus.disabled;
    } else if (hasErrors) {
      return ControlStatus.invalid;
    } else if (anyControlsHaveStatus(ControlStatus.pending)) {
      return ControlStatus.pending;
    } else if (anyControlsHaveStatus(ControlStatus.invalid)) {
      return ControlStatus.invalid;
    }

    return ControlStatus.valid;
  }

  void _updateControlsErrors() {
    _status = _calculateStatus();
    _statusChanges.add(_status);

    parent?._updateControlsErrors();
  }

  Map<String, dynamic> _runValidators() {
    final errors = <String, dynamic>{};
    for (final validator in validators) {
      final error = validator(this);
      if (error != null) {
        errors.addAll(error);
      }
    }

    return errors;
  }

  void _setInitialStatus() {
    _status =
        allControlsDisabled() ? ControlStatus.disabled : ControlStatus.valid;
  }

  void _updateAncestors(bool updateParent) {
    if (updateParent) {
      parent?.updateValueAndValidity(updateParent: updateParent);
    }
  }

  void _updateValue() {
    val = reduceValue();
  }

  /// Recalculates the value and validation status of the control.
  ///
  /// When [updateParent] is true or not supplied (the default) each change
  /// affects this control and its parent, otherwise only affects to this
  /// control.
  ///
  /// When [emitEvent] is true or not supplied (the default), both the
  /// *statusChanges* and *valueChanges* emit events with the latest status
  /// and value when the control is reset. When false, no events are emitted.
  void updateValueAndValidity({
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    _setInitialStatus();
    _updateValue();
    if (enabled) {
      _cancelExistingSubscription();
      _errors = _runValidators();
      _status = _calculateStatus();
      if (_status == ControlStatus.valid || _status == ControlStatus.pending) {
        _runAsyncValidators();
      }
    }

    if (emitEvent) {
      _valueChanges.add(value);
      _statusChanges.add(_status);
    }

    _updateAncestors(updateParent);
  }

  Future<void> _cancelExistingSubscription() async {
    await _asyncValidationSubscription?.cancel();
    _asyncValidationSubscription = null;
  }

  /// runs async validators to validate the value of current control
  Future<void> _runAsyncValidators() async {
    if (_asyncValidators.isEmpty) {
      return;
    }

    _status = ControlStatus.pending;

    _debounceTimer?.cancel();

    _debounceTimer = Timer(
      Duration(milliseconds: _asyncValidatorsDebounceTime),
      () {
        final validatorsStream = Stream.fromFutures(
            asyncValidators.map((validator) => validator(this)).toList());

        final errors = <String, dynamic>{};
        _asyncValidationSubscription = validatorsStream.listen(
          (Map<String, dynamic>? error) {
            if (error != null) {
              errors.addAll(error);
            }
          },
          onDone: () {
            setErrors(errors, markAsDirty: false);
          },
        );
      },
    );
  }

  /// Remove the focus from the UI widget without the interaction of the user.
  ///
  /// The [touched] argument can be optionally provided. If [touched] is false
  /// then the control is marked as untouched and validations messages don't
  /// show up. If [touched] is true (default) the control is marked as touched
  /// and validation error messages comes visible in the UI.
  ///
  /// ### Example:
  /// Removes focus from a control
  /// ```dart
  /// final formControl = form.formControl('name');
  ///
  /// // UI text field lose focus
  /// formControl.unfocus();
  ///```
  ///
  /// Removes focus to all children controls in a form
  /// ```dart
  /// form.unfocus();
  ///```
  ///
  /// Removes focus to all children controls in an array
  /// ```dart
  /// array.unfocus();
  ///```
  void unfocus({bool touched = true}) {
    if (!touched) {
      markAsUntouched(emitEvent: false);
    }

    forEachChild((control) {
      control.unfocus(touched: touched);
    });
  }

  void focus();

  void updateTouched({bool updateParent = true}) {
    _touched = _anyControlsTouched();

    if (updateParent) {
      parent?.updateTouched(updateParent: updateParent);
    }
  }

  void updatePristine({bool updateParent = true}) {
    _pristine = !_anyControlsDirty();

    if (updateParent) {
      parent?.updatePristine(updateParent: updateParent);
    }
  }

  bool _anyControlsTouched() => anyControls((control) => control.touched);

  bool _anyControlsDirty() => anyControls((control) => control.dirty);

  bool anyControls(bool Function(AbstractControl<dynamic>) condition);

  T? reduceValue();

  void forEachChild(void Function(AbstractControl<dynamic>) callback);

  AbstractControl<dynamic>? findControl(String path);
}
