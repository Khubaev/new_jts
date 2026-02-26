import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../models/user.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/requests_provider.dart';
import '../widgets/request_card.dart';
import 'create_request_screen.dart';
import 'request_detail_screen.dart';

class RequestsListScreen extends StatefulWidget {
  const RequestsListScreen({super.key});

  @override
  State<RequestsListScreen> createState() => _RequestsListScreenState();
}

class _RequestsListScreenState extends State<RequestsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final auth = context.read<AuthProvider>();
    final requests = context.read<RequestsProvider>();
    if (auth.isAuthenticated && auth.token != null) {
      requests.setToken(auth.token);
      await requests.loadRequests();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: Icon(
              context.watch<RequestsProvider>().showCompleted
                  ? Icons.visibility_off
                  : Icons.visibility,
            ),
            onPressed: () {
              context.read<RequestsProvider>().toggleShowCompleted();
            },
            tooltip: context.watch<RequestsProvider>().showCompleted
                ? 'Скрыть выполненные'
                : 'Показать выполненные',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<RequestsProvider>().loadRequests(),
            tooltip: 'Обновить',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().logout(),
            tooltip: 'Выйти',
          ),
        ],
      ),
      body: Consumer<RequestsProvider>(
        builder: (context, provider, _) {
          if (provider.loading && provider.getFilteredRequests(user).isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null && provider.getFilteredRequests(user).isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      provider.error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => provider.loadRequests(),
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              ),
            );
          }

          final requests = provider.getFilteredRequests(user);

          if (requests.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 80,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Нет заявок',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user.role.canSeeAllRequests
                          ? 'Нажмите + чтобы создать первую заявку'
                          : 'У вас нет заявок, где вы указаны ответственным',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: RequestCard(
                  request: request,
                  requestorName: request.requestorName ?? auth.getUserById(request.requestorUserId ?? '')?.name,
                  responsibleName: request.responsibleName ?? auth.getUserById(request.responsibleUserId ?? '')?.name,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RequestDetailScreen(requestId: request.id),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const CreateRequestScreen(),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Новая заявка'),
      ),
    );
  }
}
