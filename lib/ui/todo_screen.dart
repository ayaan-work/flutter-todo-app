import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/domain/todo.dart';
import 'package:todo_app/state/todo_providers.dart';

class TodoScreen extends ConsumerStatefulWidget {
  const TodoScreen({super.key});

  @override
  ConsumerState<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends ConsumerState<TodoScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final todosAsync = ref.watch(todoListProvider);
    final filtered = todosAsync.whenData((todos) =>
        _query.isEmpty
            ? todos
            : todos.where((t) => t.title.toLowerCase().contains(_query.toLowerCase())).toList());

    return Scaffold(
      appBar: AppBar(title: const Text('Todos')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search todos',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: switch (filtered) {
              AsyncData(:final value) when value.isEmpty =>
                const _EmptyState(),
              AsyncData(:final value) => _TodoList(todos: value),
              AsyncError(:final error) => _ErrorState(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(todoListProvider),
                ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New todo'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (title != null && title.trim().isNotEmpty) {
      await ref.read(todoListProvider.notifier).addTodo(title);
    }
  }
}

class _TodoList extends ConsumerWidget {
  final List<Todo> todos;
  const _TodoList({required this.todos});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      itemCount: todos.length,
      itemBuilder: (context, index) {
        final todo = todos[index];
        return CheckboxListTile(
          key: ValueKey(todo.id),
          value: todo.isDone,
          title: Text(
            todo.title,
            style: todo.isDone
                ? const TextStyle(decoration: TextDecoration.lineThrough)
                : null,
          ),
          onChanged: (_) => ref.read(todoListProvider.notifier).toggle(todo.id),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('No todos yet — tap + to add one.'),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 40),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
