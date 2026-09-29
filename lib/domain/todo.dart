/// Domain model — pure, no dependency on data or presentation layers.
class Todo {
  final String id;
  final String title;
  final bool isDone;
  final DateTime createdAt;

  const Todo({
    required this.id,
    required this.title,
    required this.isDone,
    required this.createdAt,
  });

  Todo copyWith({String? title, bool? isDone}) {
    return Todo(
      id: id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
      createdAt: createdAt,
    );
  }
}

/// A minimal Result type so callers are forced to handle failure explicitly
/// instead of relying on try/catch leaking across layers.
sealed class Result<T> {
  const Result();
}

class Ok<T> extends Result<T> {
  final T value;
  const Ok(this.value);
}

class Err<T> extends Result<T> {
  final String message;
  const Err(this.message);
}
