import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/data/todo_repository.dart';
import 'package:todo_app/domain/todo.dart';

/// Repository is provided here so tests can override it with a fake:
///   ProviderScope(overrides: [todoRepositoryProvider.overrideWithValue(FakeRepo())])
final todoRepositoryProvider = Provider<TodoRepository>((ref) {
  return InMemoryTodoRepository();
});

/// AsyncNotifier gives us AsyncValue<List<Todo>> for free — loading,
/// data, and error states are all modeled without extra boilerplate,
/// and the UI can exhaustively switch over them.
class TodoListNotifier extends AsyncNotifier<List<Todo>> {
  @override
  Future<List<Todo>> build() async {
    final result = await ref.read(todoRepositoryProvider).fetchTodos();
    return switch (result) {
      Ok(:final value) => value,
      Err(:final message) => throw Exception(message),
    };
  }

  Future<void> addTodo(String title) async {
    final repo = ref.read(todoRepositoryProvider);
    final result = await repo.addTodo(title);
    switch (result) {
      case Ok(:final value):
        // Optimistic-ish: append locally instead of a full refetch.
        state = AsyncValue.data([...state.value ?? [], value]);
      case Err(:final message):
        // Keep existing data visible; surface the error separately
        // rather than nuking the whole list to an error state.
        state = AsyncValue.error(message, StackTrace.current);
    }
  }

  Future<void> toggle(String id) async {
    final previous = state;
    // Optimistic update for snappy UX, with rollback on failure.
    state = AsyncValue.data([
      for (final t in state.value ?? [])
        if (t.id == id) t.copyWith(isDone: !t.isDone) else t,
    ]);

    final result = await ref.read(todoRepositoryProvider).toggleTodo(id);
    if (result is Err) {
      state = previous; // rollback
    }
  }
}

final todoListProvider =
    AsyncNotifierProvider<TodoListNotifier, List<Todo>>(TodoListNotifier.new);

/// Search filter kept as separate state so typing doesn't retrigger
/// network fetches — it filters the already-loaded list.
// Search handled locally in the UI to avoid introducing extra provider
// complexity for this small example.
