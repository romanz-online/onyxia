mixin NarwhalEnum<T extends Enum> on Enum {
  String get value => name;
}

extension NarwhalEnumExtension<T extends Enum> on List<T> {
  T fromString(String? input) => input == null
      ? first
      : firstWhere(
          (e) => (e as NarwhalEnum).value == input,
          orElse: () => first,
        );
}
