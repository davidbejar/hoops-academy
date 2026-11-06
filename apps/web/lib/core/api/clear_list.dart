import 'package:built_collection/built_collection.dart';

/// The `clear` list of an `Update*Request` (ADR-0032): the generated clients omit null fields, so an edit form
/// names every optional field it leaves empty. [formValues] maps each clearable field to the form's value; the
/// result is null when no field is empty, so no `clear` member is sent.
SetBuilder<E>? clearList<E>(Map<E, Object?> formValues) {
  final empty = [
    for (final entry in formValues.entries)
      if (entry.value == null) entry.key,
  ];
  return empty.isEmpty ? null : SetBuilder<E>(empty);
}
