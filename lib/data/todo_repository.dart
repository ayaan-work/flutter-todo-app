import 'dart:async';
import 'dart:math';
import 'package:todo_app/domain/todo.dart';

/// Abstract contract — the UI/state layer depends on this, not on the
/// concrete implementation. Makes swapping in a real API or DB trivial,
/// and makes the provider testable with a fake.
abstract class TodoRepository {
  Future<Result<List<Todo>>> fetchTodos();
  Future<Result<Todo>> addTodo(String title);
  Future<Result<void>> toggleTodo(String id);
}

/// In-memory implementation standing in for a REST/DB call.
/// Simulates latency and occasional failure so the UI layer has to
/// actually handle loading/error states, not just the happy path.
class InMemoryTodoRepository implements TodoRepository {
  final _rand = Random();
  final List<Todo> _store = [
    Todo(id: '1', title: 'Review PR #482', isDone: false, createdAt: DateTime.now()),
    Todo(id: '2', title: 'Write architecture doc', isDone: true, createdAt: DateTime.now()),
  ];

  Future<void> _latency() =>
      Future.delayed(Duration(milliseconds: 300 + _rand.nextInt(400)));

  @override
  Future<Result<List<Todo>>> fetchTodos() async {
    await _latency();
    if (_rand.nextDouble() < 0.1) {
      return const Err('Failed to load todos. Check your connection.');
    }
    return Ok(List.unmodifiable(_store));
  }

  @override
  Future<Result<Todo>> addTodo(String title) async {
    await _latency();
    if (title.trim().isEmpty) {
      return const Err('Title cannot be empty.');
    }
    final todo = Todo(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title.trim(),
      isDone: false,
      createdAt: DateTime.now(),
    );
    _store.add(todo);
    return Ok(todo);
  }

  @override
  Future<Result<void>> toggleTodo(String id) async {
    await _latency();
    final index = _store.indexWhere((t) => t.id == id);
    if (index == -1) return const Err('Todo not found.');
    _store[index] = _store[index].copyWith(isDone: !_store[index].isDone);
    return const Ok(null);
  }
}
