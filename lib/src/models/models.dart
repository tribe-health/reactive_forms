// Copyright 2020 Joan Pablo Jimenez Milian. All rights reserved.
// Use of this source code is governed by the MIT license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// Tracks the value and validation status of an individual form control.
class FormControl<T> extends AbstractControl<T> {
  final _focusChanges = StreamController<bool>.broadcast();
  FocusController? _focusController;
  bool _hasFocus = false;

  /// Creates a new FormControl instance.
  ///
  /// The control can optionally be initialized with a [value].
  ///
  /// The control can optionally have [validators] that validates
  /// the control each time the value changes.
  ///
  /// The control can optionally have [asyncValidators] that validates
  /// asynchronously the control each time the value changes. Asynchronous
  /// validation executes after the synchronous validation, and is performed
  /// only if the synchronous validation is successful. This check allows
  /// forms to avoid potentially expensive async validation processes
  /// (such as an HTTP request) if the more basic validation methods have
  /// already found invalid input.
  ///
  /// You can set an [asyncValidatorsDebounceTime] in millisecond to set
  /// a delay time before trigger async validators. This is useful for
  /// minimizing request to a server. The default value is 250 milliseconds.
  ///
  /// You can set [touched] as true to force the validation messages
  /// to show up at the very first time the widget that is bound to this
  /// control builds in the UI.
  ///
  /// If [disabled] is true then the control is disabled by default.
  ///
  /// ### Example:
  /// ```dart
  /// final priceControl = FormControl<double>(defaultValue: 0.0);
  /// ```
  ///
  FormControl({
    T? value,
    List<ValidatorFunction> validators = const [],
    List<AsyncValidatorFunction> asyncValidators = const [],
    int asyncValidatorsDebounceTime = 250,
    bool touched = false,
    bool disabled = false,
  }) : super(
          validators: validators,
          asyncValidators: asyncValidators,
          asyncValidatorsDebounceTime: asyncValidatorsDebounceTime,
          disabled: disabled,
          touched: touched,
        ) {
    if (value != null) {
      this.value = value;
    } else {
      updateValueAndValidity();
    }
  }

  /// True if the control is marked as focused.
  bool get hasFocus => _hasFocus;

  /// Gets the focus controller registered with in this control.
  ///
  /// Don't use [focusController] to add/remove focus to a control,
  /// use instead **control.focus()** and **control.unfocus()**.
  ///
  /// Don't use [focusController] to know if the control has focus, use instead
  /// **control.hasFocus**.
  ///
  /// Use only [focusController] if you want to access the inner UI [FocusNode]
  /// of the control.
  ///
  /// ## Example
  /// Access the inner UI [FocusNode] of the control
  /// ```dart
  /// FormControl control = this.form.control('email');
  ///
  /// final focusNode =  control.focusController.focusNode;
  /// ```
  /// See also [focus()].
  ///
  /// See also [unfocus()].
  ///
  /// See also [hasFocus].
  FocusController? get focusController => _focusController;

  /// Disposes the control
  @override
  void dispose() {
    _focusChanges.close();
    super.dispose();
  }

  /// A [ChangeNotifier] that emits an event every time the focus status of
  /// the control changes.
  Stream<bool> get focusChanges => _focusChanges.stream;

  /// Remove focus on a ReactiveFormField widget without the interaction
  /// of the user.
  ///
  /// ### Example:
  ///
  /// ```dart
  /// final formControl = form.formControl('name');
  ///
  /// // UI text field lose focus
  /// formControl.unfocus();
  ///```
  @override
  void unfocus({bool touched = true}) {
    if (hasFocus) {
      _updateFocusState(false);
    }

    if (touched == false) {
      markAsUntouched();
    }
  }

  /// Sets focus on a ReactiveFormField widget without the interaction
  /// of the user.
  ///
  /// ### Example:
  ///
  /// ```dart
  /// final formControl = form.formControl('name');
  ///
  /// // UI text field get focus and the device keyboard pop up
  /// formControl.focus();
  ///```
  ///
  @override
  void focus() {
    if (!hasFocus) {
      _updateFocusState(true);
    }
  }

  // TODO: there is something wrong with this method, it need an evaluation
  /// Removes the provided [focusController] from the control.
  void unregisterFocusController(FocusController focusController) {
    if (_focusController != null && _focusController == focusController) {
      _focusController!.removeListener(_onFocusControllerChanged);
      _focusController = null;
    }
  }

  /// Registers a focus controller.
  ///
  /// The [focusController] represents the focus controller of this control.
  void registerFocusController(FocusController focusController) {
    if (_focusController == focusController) {
      return;
    }

    if (_focusController != null) {
      unregisterFocusController(_focusController!);
    }

    _focusController = focusController;
    _focusController!.addListener(_onFocusControllerChanged);
  }

  void _onFocusControllerChanged() {
    _updateFocusState(
      _focusController!.hasFocus,
      notifyFocusController: false,
    );

    if (_focusController!.hasFocus == false) {
      markAsTouched();
    }
  }

  void _updateFocusState(bool value, {bool notifyFocusController = true}) {
    _hasFocus = value;
    _focusChanges.add(_hasFocus);

    if (notifyFocusController) {
      _focusController?.onControlFocusChanged(_hasFocus);
    }
  }

  @override
  T? reduceValue() => value;

  /// Sets the [value] of the [FormControl].
  ///
  /// When [updateParent] is true or not supplied (the default) each change
  /// affects this control and its parent, otherwise only affects to this
  /// control.
  ///
  /// When [emitEvent] is true or not supplied (the default), both the
  /// *statusChanges* and *valueChanges* emit events with the latest status
  /// and value when the control is reset. When false, no events are emitted.
  @override
  void updateValue(
    T? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    if (val != value) {
      val = value;

      updateValueAndValidity(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    }
  }

  /// Patches the [value] of a control.
  ///
  /// This function is functionally the same as [FormControl.updateValue] at
  /// this level. It exists for symmetry with [FormGroup.patchValue] on
  /// [FormGroup] and [FormArray.patchValue] in [FormArray] where it does
  /// behave differently.
  ///
  /// When [updateParent] is true or not supplied (the default) each change
  /// affects this control and its parent, otherwise only affects to this
  /// control.
  ///
  /// When [emitEvent] is true or not supplied (the default), both the
  /// *statusChanges* and *valueChanges* emit events with the latest status
  /// and value when the control is reset. When false, no events are emitted.
  @override
  void patchValue(T? value, {bool updateParent = true, bool emitEvent = true}) {
    updateValue(value, updateParent: updateParent, emitEvent: emitEvent);
  }

  @override
  void forEachChild(void Function(AbstractControl<dynamic>) callback) =>
      <AbstractControl<dynamic>>[];

  @override
  bool anyControls(bool Function(AbstractControl<dynamic>) condition) => false;

  @override
  AbstractControl<dynamic> findControl(String path) => this;
}

/// Tracks the value and validity state of a group of FormControl instances.
///
/// A FormGroup aggregates the values of each child FormControl into one object,
/// with each control name as the key.
///
/// It calculates its status by reducing the status values of its children.
/// For example, if one of the controls in a group is invalid, the entire group
/// becomes invalid.
class FormGroup extends AbstractControl<Map<String, Object?>>
    with FormControlCollection<Object> {
  final Map<String, AbstractControl<dynamic>> _controls = {};

  /// Creates a new FormGroup instance.
  ///
  /// When instantiating a [FormGroup], pass in a [Map] of child controls
  /// as the first argument.
  ///
  /// The key for each child registers the name for the control.
  ///
  /// ### Example:
  ///
  /// ```dart
  /// final form = FromGroup({
  ///   'name': FormControl(defaultValue: 'John Doe'),
  ///   'email': FormControl(),
  /// });
  /// ```
  /// The group can optionally have [validators] that validates
  /// the group each time the value changes.
  ///
  /// The group can optionally have [asyncValidators] that validates
  /// asynchronously the group each time the value changes. Asynchronous
  /// validation executes after the synchronous validation, and is performed
  /// only if the synchronous validation is successful. This check allows
  /// forms to avoid potentially expensive async validation processes
  /// (such as an HTTP request) if the more basic validation methods have
  /// already found invalid input.
  ///
  /// You can set an [asyncValidatorsDebounceTime] in millisecond to set
  /// a delay time before trigger async validators. This is useful for
  /// minimizing request to a server. The default value is 250 milliseconds.
  ///
  /// If [disabled] is true then all children controls of the groups are
  /// disabled by default.
  ///
  /// See also [AbstractControl.validators]
  FormGroup(
    Map<String, AbstractControl<dynamic>> controls, {
    List<ValidatorFunction> validators = const [],
    List<AsyncValidatorFunction> asyncValidators = const [],
    int asyncValidatorsDebounceTime = 250,
    bool disabled = false,
  }) : super(
          validators: validators,
          asyncValidators: asyncValidators,
          asyncValidatorsDebounceTime: asyncValidatorsDebounceTime,
          disabled: disabled,
        ) {
    addAll(controls);

    if (disabled) {
      markAsDisabled(emitEvent: false);
    }
  }

  /// Gets the value of the [FormGroup], including any disabled controls.
  ///
  /// Retrieves all values regardless of disabled status.
  Map<String, Object?> get rawValue => _controls
      .map<String, Object?>((key, control) => MapEntry(key, control.value));

  @override
  bool contains(String name) {
    return _controls.containsKey(name);
  }

  /// Retrieves a child control given the control's [name] or path.
  ///
  /// The argument [name] is a dot-delimited string that define the path to the
  /// control.
  ///
  /// Throws [FormControlNotFoundException] if no control founded with
  /// the specified [name]/path.
  ///
  /// ### Example:
  ///
  /// ```dart
  /// final form = FormGroup({
  ///   'total': FormControl<int>(value: 20),
  ///   'person': FormGroup({
  ///     'name': FormControl<String>(value: 'John'),
  ///   }),
  /// });
  /// ```
  ///
  /// Retrieves a control
  /// ```dart
  /// form.control('total');
  /// ```
  ///
  /// Retrieves a nested control
  /// ```dart
  /// form.control('person.name');
  /// ```
  @override
  AbstractControl<dynamic> control(String name) {
    final namePath = name.split('.');
    if (namePath.length > 1) {
      final control = findControlInCollection(namePath);
      if (control != null) {
        return control;
      }
    } else if (contains(name)) {
      return _controls[name]!;
    }

    throw FormControlNotFoundException(controlName: name);
  }

  /// Gets the collection of child controls.
  ///
  /// The key for each child is the name under which it is registered.
  Map<String, AbstractControl<Object?>> get controls =>
      Map<String, AbstractControl<Object?>>.unmodifiable(_controls);

  /// Reduce the value of the group is a key-value pair for each control
  /// in the group.
  ///
  /// ### Example:
  ///
  ///```dart
  /// final form = FormGroup({
  ///   'name': FormControl(defaultValue: 'John Doe'),
  ///   'email': FormControl(defaultValue: 'johndoe@email.com'),
  /// });
  ///
  /// print(form.value);
  ///```
  ///
  /// ```json
  /// { "name": "John Doe", "email": "johndoe@email.com" }
  ///```
  ///
  /// This method is for internal use only.
  @override
  Map<String, Object?> reduceValue() {
    final map = <String, Object?>{};
    _controls.forEach((key, control) {
      if (control.enabled || disabled) {
        map[key] = control.value;
      }
    });

    return map;
  }

  @override
  Map<String, Object?> get value => Map.unmodifiable(val!);

  /// Set the complete value for the form group.
  ///
  /// ### Example
  ///
  /// ```dart
  /// final form = FormGroup({
  ///   'name': FormControl(),
  ///   'email': FormControl(),
  /// });
  ///
  /// form.value = { 'name': 'John Doe', 'email': 'johndoe@email.com' }
  ///
  /// print(form.value);
  /// ```
  /// ```json
  /// { "name": "John Doe", "email": "johndoe@email.com" }
  ///```
  @override
  set value(Map<String, Object?>? value) {
    updateValue(value);
  }

  /// Disables the control.
  ///
  /// This means the control is exempt from validation checks and excluded
  /// from the aggregate value of any parent. Its status is `DISABLED`.
  ///
  /// If the control has children, all children are also disabled.
  ///
  /// When [updateParent] is false, mark only this control.
  /// When true or not supplied (the default), marks all direct ancestors.
  ///
  /// When [emitEvent] is true or not supplied (the default), [valueChanges]
  /// and [statusChanged] events are emitted if value or status change.
  /// Otherwise the control update this values but none of this events are
  /// emitted.
  @override
  void markAsDisabled({bool updateParent = true, bool emitEvent = true}) {
    _controls.forEach((_, control) {
      control.markAsDisabled(updateParent: true, emitEvent: emitEvent);
    });
    super.markAsDisabled(updateParent: updateParent, emitEvent: emitEvent);
  }

  /// Enables the control.
  ///
  /// This means the control is included in validation checks and the aggregate
  /// value of its parent. Its status recalculates based on its value and its
  /// validators.
  ///
  /// When [updateParent] is false, mark only this control.
  /// When true or not supplied (the default), marks all direct ancestors.
  ///
  /// When [emitEvent] is true or not supplied (the default), [valueChanges]
  /// and [statusChanged] events are emitted if value or status change.
  /// Otherwise the control update this values but none of this events are
  /// emitted.
  @override
  void markAsEnabled({bool updateParent = true, bool emitEvent = true}) {
    _controls.forEach((_, control) {
      control.markAsEnabled(updateParent: true, emitEvent: emitEvent);
    });
    super.markAsEnabled(updateParent: updateParent, emitEvent: emitEvent);
  }

  /// Appends all [controls] to the group.
  void addAll(Map<String, AbstractControl<dynamic>> controls) {
    _controls.addAll(controls);
    controls.forEach((name, control) {
      control.parent = this;
    });
    updateValueAndValidity();
    updateTouched();
    updatePristine();
    emitsCollectionChanged(_controls.values.toList());
  }

  /// Disposes the group.
  @override
  void dispose() {
    forEachChild((control) {
      control.parent = null;
      control.dispose();
    });
    closeCollectionEvents();
    super.dispose();
  }

  /// Returns true if all children disabled, otherwise returns false.
  ///
  /// This is for internal use only.
  @override
  bool allControlsDisabled() {
    if (_controls.isEmpty) {
      return false;
    }
    return _controls.values.every((control) => control.disabled);
  }

  /// Returns true if all children has the specified [status], otherwise
  /// returns false.
  ///
  /// This is for internal use only.
  @override
  bool anyControlsHaveStatus(ControlStatus status) {
    return _controls.values.any((control) => control.status == status);
  }

  /// Gets all errors of the group.
  ///
  /// Contains all the errors of the group and the child errors.
  @override
  Map<String, Object> get errors {
    final allErrors = Map<String, Object>.of(super.errors);
    _controls.forEach((name, control) {
      if (control.enabled && control.hasErrors) {
        allErrors.update(
          name,
          (_) => control.errors,
          ifAbsent: () => control.errors,
        );
      }
    });

    return allErrors;
  }

  /// Sets the value of the [FormGroup].
  ///
  /// The [value] argument matches the structure of the group, with control
  /// names as keys.
  ///
  /// When [updateParent] is true or not supplied (the default) each change
  /// affects this control and its parent, otherwise only affects to this
  /// control.
  ///
  /// When [emitEvent] is true or not supplied (the default), both the
  /// *statusChanges* and *valueChanges* emit events with the latest status
  /// and value when the control is reset. When false, no events are emitted.
  ///
  /// ### Example:
  /// ```dart
  /// final form = FormGroup({
  ///   'first': FormControl(),
  ///   'last': FormControl(),
  /// });
  ///
  /// print(form.value); // outputs: { first: null, last: null }
  ///
  /// form.updateValue({'first': 'John', 'last': 'Doe'});
  /// print(form.value); // outputs: { first: 'John', last: 'Doe' }
  /// ```
  @override
  void updateValue(
    Map<String, Object?>? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    value ??= {};

    for (final key in _controls.keys) {
      _controls[key]!.updateValue(
        value[key],
        updateParent: false,
        emitEvent: emitEvent,
      );
    }

    updateValueAndValidity(
      updateParent: updateParent,
      emitEvent: emitEvent,
    );
  }

  /// Patches the value of the [FormGroup]. It accepts an object with control
  /// names as keys, and does its best to match the values to the correct
  /// controls in the group.
  ///
  /// It accepts both super-sets and sub-sets of the group.
  ///
  /// The [value] argument matches the structure of the group, with control
  /// names as keys.
  ///
  /// When [updateParent] is true or not supplied (the default) each change
  /// affects this control and its parent, otherwise only affects to this
  /// control.
  ///
  /// When [emitEvent] is true or not supplied (the default), both the
  /// *statusChanges* and *valueChanges* emit events with the latest status
  /// and value when the control is reset. When false, no events are emitted.
  ///
  /// ## Example
  /// ```dart
  /// final form = FormGroup({
  ///   'name': FormControl<String>(value: 'John'),
  ///   'email': FormControl<String>(value: 'john@email.com'),
  /// });
  ///
  /// print(form.value); // outputs: {name: 'John', email: 'john@email.com'}
  ///
  /// form.patchValue({'name': 'Doe'});
  ///
  /// print(form.value); // outputs: {name: 'Doe', email: 'john@email.com'}
  /// ```
  @override
  void patchValue(
    Map<String, Object?>? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    value?.forEach((name, value) {
      if (_controls.containsKey(name)) {
        _controls[name]!.patchValue(
          value,
          updateParent: false,
          emitEvent: emitEvent,
        );
      }
    });

    updateValueAndValidity(
      updateParent: updateParent,
      emitEvent: emitEvent,
    );
  }

  /// Resets the [FormGroup], marks all descendants as *untouched*, and sets
  /// the value of all descendants to null.
  ///
  /// You reset to a specific form [state] by passing in a map of states
  /// that matches the structure of your form, with control names as keys.
  /// The control state is an object with both a value and a disabled status.
  ///
  /// The argument [removeFocus] is optional and remove the UI focus from all
  /// descendants.
  ///
  /// ### Reset the form group values and disabled status
  ///
  /// ```dart
  /// final form = FormGroup({
  ///   'first': FormControl('first name'),
  ///   'last': FormControl('last name'),
  /// });
  ///
  /// form.resetState({
  ///   'first': ControlState(value: 'name', disabled: true),
  ///   'last': ControlState(value: 'last'),
  /// });
  ///
  /// print(form.value);  // output: {first: 'name', last: 'last name'}
  /// print(form.control('first').disabled);  // output: true
  /// ```
  void resetState(Map<String, ControlState<Object>> state,
      {bool removeFocus = false}) {
    if (state.isEmpty) {
      reset(removeFocus: removeFocus);
    } else {
      _controls.forEach((name, control) {
        control.reset(
          value: state[name]?.value,
          disabled: state[name]?.disabled,
          removeFocus: removeFocus,
          updateParent: false,
        );
      });
      updatePristine();
      updateValueAndValidity();
    }
  }

  /// Sets focus to a child control.
  ///
  /// The argument [name] is a dot-delimited string that define the path to the
  /// control.
  ///
  /// ### Example:
  /// Focus a child control by name.
  /// ```dart
  /// final form = fb.group({'name': ''});
  ///
  /// // UI text field get focus and the device keyboard pop up
  /// form.focus('name');
  ///```
  ///
  /// Focus a nested child control by path.
  /// ```dart
  /// final form = fb.group({
  ///   'person': fb.group({
  ///     'name': '',
  ///   })
  /// });
  ///
  /// // UI text field get focus and the device keyboard pop up
  /// form.focus('person.name');
  ///```
  @override
  void focus([String name = '']) {
    if (name.isNotEmpty) {
      final control = findControlInCollection(name.split('.'));
      if (control != null) {
        control.focus();
      }
    } else if (_controls.isNotEmpty) {
      _controls.values.first.focus();
    }
  }

  /// Remove a control from this group given the [name] of the control.
  ///
  /// When [updateParent] is true or not supplied (the default) each change
  /// affects this control and its parent, otherwise only affects to this
  /// control.
  ///
  /// When [emitEvent] is true or not supplied (the default), both the
  /// *statusChanges* and *valueChanges* emit events with the latest status
  /// and value when the control is reset. When false, no events are emitted.
  void removeControl(String name,
      {bool updateParent = true, bool emitEvent = true}) {
    if (!_controls.containsKey(name)) {
      throw FormControlNotFoundException(controlName: name);
    }

    _controls.removeWhere((key, value) => key == name);
    updateValueAndValidity(updateParent: updateParent, emitEvent: emitEvent);
  }

  @override
  void forEachChild(void Function(AbstractControl<dynamic>) callback) {
    _controls.forEach((name, control) => callback(control));
  }

  @override
  bool anyControls(bool Function(AbstractControl<dynamic>) condition) {
    return _controls.values
        .any((control) => control.enabled && condition(control));
  }

  @override
  AbstractControl<dynamic>? findControl(String path) =>
      findControlInCollection(path.split('.'));
}

/// A FormArray aggregates the values of each child FormControl into an array.
///
/// It calculates its status by reducing the status values of its children.
/// For example, if one of the controls in a FormArray is invalid, the entire
/// array becomes invalid.
///
/// FormArray is one of the three fundamental building blocks used to define
/// forms in Reactive Forms, along with [FormControl] and [FormGroup].
class FormArray<T> extends AbstractControl<List<T?>>
    with FormControlCollection<T> {
  final List<AbstractControl<T>> _controls = [];

  /// Creates a new [FormArray] instance.
  ///
  /// When instantiating a [FormGroup], pass in a collection of child controls
  /// as the first argument.
  ///
  /// ### Example:
  ///
  /// ```dart
  /// final form = FromGroup({
  ///   'name': FormControl(defaultValue: 'John Doe'),
  ///   'aliases': FormArray([
  ///     FormControl(defaultValue: 'john'),
  ///     FormControl(defaultValue: 'little john'),
  ///   ]),
  /// });
  /// ```
  /// The array can optionally have [validators] that validates
  /// the array each time the value changes.
  ///
  /// The array can optionally have [asyncValidators] that validates
  /// asynchronously the array each time the value changes. Asynchronous
  /// validation executes after the synchronous validation, and is performed
  /// only if the synchronous validation is successful. This check allows
  /// forms to avoid potentially expensive async validation processes
  /// (such as an HTTP request) if the more basic validation methods have
  /// already found invalid input.
  ///
  /// You can set an [asyncValidatorsDebounceTime] in millisecond to set
  /// a delay time before trigger async validators. This is useful for
  /// minimizing request to a server. The default value is 250 milliseconds.
  ///
  /// If [disabled] is true then all children controls of the array are
  /// disabled by default.
  ///
  /// See also [AbstractControl.validators]
  FormArray(
    List<AbstractControl<T>> controls, {
    List<ValidatorFunction> validators = const [],
    List<AsyncValidatorFunction> asyncValidators = const [],
    int asyncValidatorsDebounceTime = 250,
    bool disabled = false,
  }) : super(
          validators: validators,
          asyncValidators: asyncValidators,
          asyncValidatorsDebounceTime: asyncValidatorsDebounceTime,
          disabled: disabled,
        ) {
    addAll(controls);

    if (disabled) {
      markAsDisabled(emitEvent: false);
    }
  }

  /// Gets the list of child controls.
  List<AbstractControl<T>> get controls =>
      List<AbstractControl<T>>.unmodifiable(_controls);

  /// Gets the value of the [FormArray], including any disabled controls.
  ///
  /// Retrieves all values regardless of disabled status.
  List<T?> get rawValue =>
      _controls.map<T?>((control) => control.value).toList();

  /// Sets the value of the [FormArray].
  ///
  /// It accepts an array that matches the structure of the control.
  /// It accepts both super-sets and sub-sets of the array.
  @override
  set value(List<T?>? value) {
    updateValue(value);
  }

  /// Gets the values of controls as an [Iterable].
  ///
  /// This method is for internal use only.
  @override
  List<T?>? reduceValue() {
    return _controls
        .where((control) => control.enabled || disabled)
        .map((control) => control.value)
        .toList();
  }

  /// Disables the control.
  ///
  /// This means the control is exempt from validation checks and excluded
  /// from the aggregate value of any parent. Its status is `DISABLED`.
  ///
  /// If the control has children, all children are also disabled.
  ///
  /// When [updateParent] is true or not supplied (the default) each change
  /// affects this control and its parent, otherwise only affects to this
  /// control.
  ///
  /// When [emitEvent] is true or not supplied (the default), both the
  /// *statusChanges* and *valueChanges* emit events with the latest status
  /// and value when the control is reset. When false, no events are emitted.
  @override
  void markAsDisabled({bool updateParent = true, bool emitEvent = true}) {
    for (final control in _controls) {
      control.markAsDisabled(updateParent: true, emitEvent: emitEvent);
    }
    super.markAsDisabled(updateParent: updateParent, emitEvent: emitEvent);
  }

  /// Enables the control. This means the control is included in validation
  /// checks and the aggregate value of its parent. Its status recalculates
  /// based on its value and its validators.
  ///
  /// When [updateParent] is true or not supplied (the default) each change
  /// affects this control and its parent, otherwise only affects to this
  /// control.
  ///
  /// When [emitEvent] is true or not supplied (the default), both the
  /// *statusChanges* and *valueChanges* emit events with the latest status
  /// and value when the control is reset. When false, no events are emitted.
  @override
  void markAsEnabled({bool updateParent = true, bool emitEvent = true}) {
    forEachChild((control) {
      control.markAsEnabled(updateParent: true, emitEvent: emitEvent);
    });
    super.markAsEnabled(updateParent: updateParent, emitEvent: emitEvent);
  }

  /// Insert a [control] at the given [index] position.
  ///
  /// The argument [index] is the position starting from 0 where to insert the
  /// control.
  ///
  /// The argument [control] is the item to insert.
  ///
  /// When [updateParent] is true or not supplied (the default) each change
  /// affects this control and its parent, otherwise only affects to this
  /// control.
  ///
  /// When [emitEvent] is true or not supplied (the default), both the
  /// *statusChanges* and *valueChanges* emit events with the latest status
  /// and value when the control is reset. When false, no events are emitted.
  void insert(
    int index,
    AbstractControl<T> control, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    _controls.insert(index, control);
    control.parent = this;

    updateValueAndValidity(
      emitEvent: emitEvent,
      updateParent: updateParent,
    );

    if (emitEvent) {
      emitsCollectionChanged(_controls);
    }
  }

  /// Insert a new [control] at the end of the array.
  ///
  /// When [updateParent] is true or not supplied (the default) each change
  /// affects this control and its parent, otherwise only affects to this
  /// control.
  ///
  /// When [emitEvent] is true or not supplied (the default), both the
  /// *statusChanges* and *valueChanges* emit events with the latest status
  /// and value when the control is reset. When false, no events are emitted.
  void add(
    AbstractControl<T> control, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    addAll([control], emitEvent: emitEvent, updateParent: updateParent);
  }

  /// Appends all [controls] to the end of this array.
  ///
  /// When [updateParent] is true or not supplied (the default) each change
  /// affects this control and its parent, otherwise only affects to this
  /// control.
  ///
  /// When [emitEvent] is true or not supplied (the default), both the
  /// *statusChanges* and *valueChanges* emit events with the latest status
  /// and value when the control is reset. When false, no events are emitted.
  void addAll(
    List<AbstractControl<T>> controls, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    _controls.addAll(controls);
    for (final control in controls) {
      control.parent = this;
    }

    updateValueAndValidity(
      updateParent: updateParent,
      emitEvent: emitEvent,
    );
    emitsCollectionChanged(_controls);
  }

  /// Removes and returns the child control at the given [index].
  ///
  /// The argument [index] is the index position of the child control to remove.
  ///
  /// When [updateParent] is true or not supplied (the default) each change
  /// affects this control and its parent, otherwise only affects to this
  /// control.
  ///
  /// When [emitEvent] is true or not supplied (the default), both the
  /// *statusChanges* and *valueChanges* emit events with the latest status
  /// and value when the control is reset. When false, no events are emitted.
  AbstractControl<T> removeAt(
    int index, {
    bool emitEvent = true,
    bool updateParent = true,
  }) {
    final removedControl = _controls.removeAt(index);
    removedControl.parent = null;
    updateValueAndValidity(
      emitEvent: emitEvent,
      updateParent: updateParent,
    );

    if (emitEvent) {
      emitsCollectionChanged(_controls);
    }

    return removedControl;
  }

  /// Removes [control] from the array.
  ///
  /// The argument [control] is the child control to remove.
  ///
  /// When [updateParent] is true or not supplied (the default) each change
  /// affects this control and its parent, otherwise only affects to this
  /// control.
  ///
  /// When [emitEvent] is true or not supplied (the default), both the
  /// *statusChanges* and *valueChanges* emit events with the latest status
  /// and value when the control is reset. When false, no events are emitted.
  ///
  /// Throws [FormControlNotFoundException] if [control] is not a child control
  /// of the array.
  ///
  /// ### Example
  /// ```dart
  /// final array = FormArray<String>([
  ///   FormControl<String>(value: 'John'),
  ///   FormControl<String>(value: 'Doe'),
  /// ]);
  ///
  /// print(array.value) // outputs: ['John', 'Doe']
  /// print(array.controls.length) // outputs: 2
  ///
  /// final firstControl = array.control('0');
  ///
  /// array.remove(firstControl);
  ///
  /// print(array.value) // outputs: ['John']
  /// print(array.controls.length) // outputs: 1
  /// ```
  void remove(
    AbstractControl<T> control, {
    bool emitEvent = true,
    bool updateParent = true,
  }) {
    final index = _controls.indexOf(control);
    if (index == -1) {
      throw FormControlNotFoundException();
    }
    removeAt(index, emitEvent: emitEvent, updateParent: updateParent);
  }

  /// Removes all children controls from the array.
  ///
  /// The [value] and validity state of the array is updated and the event
  /// [collectionChanges] is triggered.
  ///
  /// When [updateParent] is true or not supplied (the default) each change
  /// affects this control and its parent, otherwise only affects to this
  /// control.
  ///
  /// When [emitEvent] is true or not supplied (the default), both the
  /// *statusChanges* and *valueChanges* emit events with the latest status
  /// and value when the control is reset. When false, no events are emitted.
  void clear({bool emitEvent = true, bool updateParent = true}) {
    forEachChild((control) => control.parent = null);
    _controls.clear();
    updateValueAndValidity(
      emitEvent: emitEvent,
      updateParent: updateParent,
    );

    if (emitEvent) {
      emitsCollectionChanged(_controls);
    }
  }

  /// Checks if array contains a control by a given [name].
  ///
  /// The name must be the string representation of the children index.
  ///
  /// Returns true if collection contains the control, otherwise returns false.
  @override
  bool contains(String name) {
    final index = int.tryParse(name);
    if (index != null && index < _controls.length) {
      return true;
    }

    return false;
  }

  /// Retrieves a child control given the control's [name] or path.
  ///
  /// The [name] is a dot-delimited string that represents the index position
  /// of the control in array or the path to the nested control.
  ///
  /// Throws [FormArrayInvalidIndexException] if [name] is not e valid [int]
  /// number.
  ///
  /// Throws [FormControlNotFoundException] if no [FormControl] founded with
  /// the specified [name].
  ///
  /// ### Example:
  ///
  /// ```dart
  /// final array = FormArray([
  ///   FormControl(defaultValue: 'hello'),
  /// ]);
  ///
  /// final control = array.formControl('0');
  ///
  /// print(control.value);
  /// ```
  ///
  /// ```shell
  /// >hello
  /// ```
  ///
  /// Retrieves a nested control
  /// ```dart
  /// final form = FormGroup({
  ///   'address': FormArray([
  ///     FormGroup({
  ///       'zipCode': FormControl<int>(value: 1000),
  ///       'city': FormControl<String>(value: 'Sofia'),
  ///     })
  ///   ]),
  /// });
  ///
  /// form.control('address.0.city');
  /// ```
  @override
  AbstractControl<dynamic> control(String name) {
    final namePath = name.split('.');
    if (namePath.length > 1) {
      final control = findControlInCollection(namePath);
      if (control != null) {
        return control;
      }
    } else {
      final index = int.tryParse(name);
      if (index == null) {
        throw FormArrayInvalidIndexException(name);
      } else if (index < _controls.length) {
        return _controls[index];
      }
    }

    throw FormControlNotFoundException(controlName: name);
  }

  /// Disposes the array.
  @override
  void dispose() {
    forEachChild((control) {
      control.parent = null;
      control.dispose();
    });
    closeCollectionEvents();
    super.dispose();
  }

  /// Returns true if all children disabled, otherwise returns false.
  ///
  /// This is for internal use only.
  @override
  bool allControlsDisabled() {
    if (_controls.isEmpty) {
      return false;
    }
    return _controls.every((control) => control.disabled);
  }

  /// Returns true if all children has the specified [status], otherwise
  /// returns false.
  ///
  /// This is for internal use only.
  @override
  bool anyControlsHaveStatus(ControlStatus status) {
    return _controls.any((control) => control.status == status);
  }

  /// Gets all errors of the array.
  ///
  /// Contains all the errors of the array and the child errors.
  @override
  Map<String, Object> get errors {
    final allErrors = Map.of(super.errors);
    _controls.asMap().entries.forEach((entry) {
      final control = entry.value;
      final name = entry.key.toString();
      if (control.enabled && control.hasErrors) {
        allErrors.update(
          name,
          (_) => control.errors,
          ifAbsent: () => control.errors,
        );
      }
    });

    return allErrors;
  }

  /// Sets the value of the [FormArray].
  ///
  /// The [value] argument is a collection that matches the structure of the
  /// control.
  ///
  /// When [updateParent] is true or not supplied (the default) each change
  /// affects this control and its parent, otherwise only affects to this
  /// control.
  ///
  /// When [emitEvent] is true or not supplied (the default), both the
  /// *statusChanges* and *valueChanges* emit events with the latest status
  /// and value when the control is reset. When false, no events are emitted.
  ///
  /// ### Example:
  /// ```dart
  /// final array = FormArray([
  ///   FormControl(),
  ///   FormControl(),
  /// ]);
  ///
  /// print(array.value); // outputs: [null, null]
  ///
  /// array.updateValue(['John', 'Doe']);
  /// print(array.value); // outputs: ['John', 'Doe']
  /// ```
  @override
  void updateValue(
    List<T?>? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    for (var i = 0; i < _controls.length; i++) {
      if (value == null || i < value.length) {
        _controls[i].updateValue(
          value?.elementAt(i),
          updateParent: false,
          emitEvent: emitEvent,
        );
      }
    }

    if (value != null && value.length > _controls.length) {
      final newControls = value
          .toList()
          .asMap()
          .entries
          .where((entry) => entry.key >= _controls.length)
          .map((entry) => FormControl<T>(value: entry.value))
          .toList();

      addAll(
        newControls,
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    } else {
      updateValueAndValidity(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    }
  }

  /// Patches the value of the `FormArray`. It accepts an array that matches the
  /// structure of the control, and does its best to match the values to the
  /// correct controls in the array.
  ///
  /// It accepts both super-sets and sub-sets of the array without throwing an
  /// error.
  ///
  /// The argument [value] is the array of latest values for the controls.
  ///
  /// When [updateParent] is true or not supplied (the default) each change
  /// affects this control and its parent, otherwise only affects to this
  /// control.
  ///
  /// When [emitEvent] is true or not supplied (the default), both the
  /// *statusChanges* and *valueChanges* emit events with the latest status
  /// and value when the control is reset. When false, no events are emitted.
  ///
  /// ## Example
  /// Patch with a sub-set array
  ///
  /// ```dart
  /// final array = FormArray<int>([
  ///   FormControl<int>(value: 1),
  ///   FormControl<int>(value: 2),
  ///   FormControl<int>(value: 3),
  /// ]);
  ///
  /// print(array.value); // outputs: [1, 2, 3]
  ///
  /// array.patchValue([4]);
  ///
  /// print(array.value); // outputs: [4, 2, 3]
  /// ```
  ///
  /// ## Example
  /// Patch with a super-set array
  ///
  /// ```dart
  /// final array = FormArray<int>([
  ///   FormControl<int>(value: 1),
  ///   FormControl<int>(value: 2),
  /// ]);
  ///
  /// print(array.value); // outputs: [1, 2]
  ///
  /// array.patchValue([3, 4, 5]);
  ///
  /// print(array.value); // outputs: [3, 4]
  /// ```
  @override
  void patchValue(
    List<T?>? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    if (value == null) {
      return;
    }

    for (var i = 0; i < value.length; i++) {
      if (i < _controls.length) {
        _controls[i].patchValue(
          value[i] as T,
          updateParent: false,
          emitEvent: emitEvent,
        );
      }
    }

    updateValueAndValidity(
      updateParent: updateParent,
      emitEvent: emitEvent,
    );
  }

  /// Resets the array, marking all controls as untouched, and setting
  /// a state for children with an initial value and disabled state.
  ///
  /// The [state] is a collection of states for children that resets each
  /// control with an initial value and disabled state.
  ///
  /// ### Reset the values in a form array and the disabled status for the
  /// first control
  /// ````dart
  /// final array = FormArray<String>([
  ///   FormControl<String>(),
  ///   FormControl<String>(),
  /// ]);
  ///
  /// array.resetState([
  ///   ControlState(value: 'name', disabled: true),
  ///   ControlState(value: 'last'),
  /// ]);
  ///
  /// console.log(array.value);  // output: ['name', 'last name']
  /// console.log(array.control('0').disabled);  // output: true
  ///
  /// ```
  void resetState(List<ControlState<T>> state) {
    if (state.isEmpty) {
      reset();
    } else {
      for (var i = 0; i < _controls.length; i++) {
        _controls[i].reset(
          value: i < state.length ? state.elementAt(i).value : null,
          disabled: i < state.length ? state.elementAt(i).disabled : null,
          updateParent: false,
        );
      }

      updatePristine();
      updateValueAndValidity();
    }
  }

  /// Sets focus to a child control.
  ///
  /// The argument [name] is a dot-delimited string that define the path to the
  /// control.
  ///
  /// ### Example:
  /// Focus a child control by name.
  /// ```dart
  /// final array = fb.array(['john', 'susan']);
  ///
  /// // UI text field get focus and the device keyboard pop up
  /// array.focus('0');
  ///```
  ///
  /// Focus a nested child control by path.
  /// ```dart
  /// final array = fb.array({
  ///   [fb.group({'name': ''})]
  /// });
  ///
  /// // UI text field get focus and the device keyboard pop up
  /// array.focus('0.name');
  ///```
  @override
  void focus([String name = '']) {
    if (name.isNotEmpty) {
      final control = findControlInCollection(name.split('.'));
      if (control != null) {
        control.focus();
      }
    } else if (_controls.isNotEmpty) {
      _controls.first.focus();
    }
  }

  @override
  void forEachChild(void Function(AbstractControl<dynamic>) callback) =>
      _controls.forEach(callback);

  @override
  bool anyControls(bool Function(AbstractControl<dynamic>) condition) {
    return _controls.any((control) => control.enabled && condition(control));
  }

  @override
  AbstractControl<dynamic>? findControl(String path) =>
      findControlInCollection(path.split('.'));
}
