import 'package:meta/meta.dart';

/// Base class for project-level attribute definitions (tags, releases, statuses…).
///
/// Provides [id]/[name] and value-equality by [id] within the same concrete type.
/// Subclasses inherit [==] and [hashCode] — no need to override them.
abstract class AttributeDefinition {
  const AttributeDefinition({required this.id, required this.name});
  final String id;
  final String name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is AttributeDefinition && runtimeType == other.runtimeType && id == other.id);

  /// NOTE: runtimeType intentionally excluded to satisfy the cross-type equality
  /// contract with [AttributeReference] (a == b → a.hashCode == b.hashCode).
  @override
  int get hashCode => id.hashCode;
}

/// Global registry for [AttributeDefinition] objects, populated by definition
/// notifiers on every state change.
///
/// This lets [AttributeReference.name] and [AttributeReference.definition]
/// resolve without `ref` or any knowledge of Riverpod. Each notifier calls
/// [register] when its state changes and [clear] when it disposes.
class AttributeDefinitionRegistry {
  AttributeDefinitionRegistry._();

  static final Map<Type, Map<String, AttributeDefinition>> _definitions = {};

  /// Registers all definitions of type [D].
  /// Call this from your notifier's stream listener on every update.
  static void register<D extends AttributeDefinition>(List<D> definitions) {
    _definitions[D] = {for (final d in definitions) d.id: d};
  }

  /// Clears all cached definitions for type [D].
  /// Call this from your notifier's [dispose] to prevent stale data across project changes.
  static void clear<D extends AttributeDefinition>() => _definitions.remove(D);

  /// Returns the display name for [id] of definition type [type].
  /// Returns [id] itself as a fallback if the registry hasn't been populated yet.
  static String resolveName(Type type, String id) => _definitions[type]?[id]?.name ?? id;

  /// Returns the full definition for [id] of definition type [type].
  /// Returns null if the registry hasn't been populated yet.
  static AttributeDefinition? resolveDefinition(Type type, String id) => _definitions[type]?[id];
}

/// Base class for per-item references to an [AttributeDefinition].
///
/// Enables cross-type equality so that standard [List.contains] works across
/// definition and reference types without custom extension methods:
///
/// ```dart
/// item.tags.contains(tagDefinition)  // works ✓
/// definitions.where((d) => item.tags.contains(d))  // works ✓
/// ```
///
/// Also provides [name] and [definition] resolution via [AttributeDefinitionRegistry],
/// so both work anywhere without needing `ref`:
///
/// ```dart
/// tag.name        // display name, no ref needed ✓
/// tag.definition  // full TagDefinition object, no ref needed ✓
/// ```
///
/// To create a new attribute type:
/// 1. Extend [AttributeDefinition] with your definition class.
/// 2. Extend [AttributeReference] with your reference class:
///    - Declare `final String definitionId;`
///    - Override `Type get definitionType => MyDefinition;`
///    - Implement [matchesDefinition]: `other is MyDefinition && definitionId == other.id`
///    - Override `definition` to return the concrete type: `MyDefinition? get definition => super.definition as MyDefinition?;`
/// 3. In your notifier's stream listener: `AttributeDefinitionRegistry.register<MyDefinition>(defs);`
/// 4. In your notifier's dispose: `AttributeDefinitionRegistry.clear<MyDefinition>();`
///
/// That's it — [==], [hashCode], cross-type comparison, [name], and [definition] are all inherited.
abstract class AttributeReference {
  const AttributeReference();

  /// The [AttributeDefinition.id] this reference points to.
  /// Concrete subclasses should expose this as a plain `final String definitionId` field.
  String get definitionId;

  /// The concrete [AttributeDefinition] subtype this reference targets.
  /// Used by [name] and [definition] to look up data in [AttributeDefinitionRegistry].
  ///
  /// Implement as:
  /// ```dart
  /// @override
  /// Type get definitionType => MyDefinition;
  /// ```
  Type get definitionType;

  /// Display name of the referenced definition, resolved via [AttributeDefinitionRegistry].
  ///
  /// Returns [definitionId] as a fallback if the registry hasn't been populated yet
  /// (e.g., before the first Firestore stream event on app start).
  String get name => AttributeDefinitionRegistry.resolveName(definitionType, definitionId);

  /// The full [AttributeDefinition] for this reference, resolved via [AttributeDefinitionRegistry].
  ///
  /// Returns null if the registry hasn't been populated yet.
  /// Concrete subclasses should override this to return their specific definition type:
  /// ```dart
  /// @override
  /// MyDefinition? get definition => super.definition as MyDefinition?;
  /// ```
  AttributeDefinition? get definition => AttributeDefinitionRegistry.resolveDefinition(definitionType, definitionId);

  /// Returns true when [other] is the specific definition type for this
  /// reference and its id matches [definitionId].
  ///
  /// Canonical implementation:
  /// ```dart
  /// @override
  /// bool matchesDefinition(Object other) =>
  ///     other is MyDefinition && definitionId == other.id;
  /// ```
  @protected
  bool matchesDefinition(Object other);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is AttributeReference) {
      return runtimeType == other.runtimeType && definitionId == other.definitionId;
    }
    return matchesDefinition(other);
  }

  /// hashCode is based only on [definitionId] (not runtimeType) to satisfy the
  /// contract `a == b → a.hashCode == b.hashCode` for cross-type comparisons.
  @override
  int get hashCode => definitionId.hashCode;
}
