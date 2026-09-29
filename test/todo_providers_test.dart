import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/data/todo_repository.dart';
import 'package:todo_app/domain/todo.dart';
import 'package:todo_app/state/todo_providers.dart';

/// Fake repository — this is the payoff of coding to an interface.
/// No mocking framework needed, no real latency, fully deterministic.
class FakeTodoRepository implements TodoRepository {
  final List<Todo> seed;
  bool failNextToggle = false;
  FakeTodoRepository(this.seed);

  @override
  Future<Result<List<Todo>>> fetchTodos() async => Ok(seed);

  @override
  Future<Result<Todo>> addTodo(String title) async {
    if (title.trim().isEmpty) return const Err('Title cannot be empty.');
    final todo = Todo(id: 'x', title: title, isDone: false, createdAt: DateTime.now());
    seed.add(todo);
    return Ok(todo);
  }

  @override
  Future<Result<void>> toggleTodo(String id) async {
    if (failNextToggle) return const Err('boom');
    final i = seed.indexWhere((t) => t.id == id);
    seed[i] = seed[i].copyWith(isDone: !seed[i].isDone);
    return const Ok(null);
  }
}

void main() {
  test('toggle rolls back state on repository failure', () async {
    final fake = FakeTodoRepository([
      Todo(id: '1', title: 'A', isDone: false, createdAt: DateTime.now()),
    ]);
    fake.failNextToggle = true;

    final container = ProviderContainer(overrides: [
      todoRepositoryProvider.overrideWithValue(fake),
    ]);
    addTearDown(container.dispose);

    // Prime the list.
    await container.read(todoListProvider.future);

    await container.read(todoListProvider.notifier).toggle('1');

    final result = container.read(todoListProvider).value!;
    expect(result.first.isDone, isFalse); // rolled back, not toggled
  });

  test('addTodo rejects empty title without touching state', () async {
    final fake = FakeTodoRepository([]);
    final container = ProviderContainer(overrides: [
      todoRepositoryProvider.overrideWithValue(fake),
    ]);
    addTearDown(container.dispose);

    await container.read(todoListProvider.future);
    await container.read(todoListProvider.notifier).addTodo('   ');

    expect(container.read(todoListProvider).hasError, isTrue);
  });
}
