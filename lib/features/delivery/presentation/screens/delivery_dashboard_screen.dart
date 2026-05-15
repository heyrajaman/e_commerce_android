import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/mesh_gradient_background.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../data/models/delivery_task_model.dart';
import '../bloc/delivery_bloc.dart';
import '../bloc/delivery_event.dart';
import '../bloc/delivery_state.dart';

class DeliveryDashboardScreen extends StatefulWidget {
  const DeliveryDashboardScreen({super.key});

  @override
  State<DeliveryDashboardScreen> createState() =>
      _DeliveryDashboardScreenState();
}

class _DeliveryDashboardScreenState extends State<DeliveryDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // PROD MEMORY FIX: Added const constructor
    context.read<DeliveryBloc>().add(const FetchDeliveryTasks());
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: MeshGradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Partner Dashboard'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.black87),
                onPressed: () {
                  // PROD MEMORY FIX: Added const constructor
                  context.read<DeliveryBloc>().add(const FetchDeliveryTasks());
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.account_circle_outlined,
                  color: Colors.black87,
                  size: 26,
                ),
                onPressed: () {
                  // PROD ROUTING FIX: Use named routes
                  context.pushNamed('delivery_profile');
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.black87),
                onPressed: () {
                  context.read<AuthBloc>().add(const AuthLogoutRequested());
                },
              ),
            ],
            bottom: const TabBar(
              labelColor: Colors.deepOrangeAccent,
              unselectedLabelColor: Colors.black54,
              indicatorColor: Colors.deepOrangeAccent,
              tabs: [
                Tab(text: 'Active Tasks'),
                Tab(text: 'History'),
              ],
            ),
          ),
          body: BlocBuilder<DeliveryBloc, DeliveryState>(
            builder: (context, state) {
              if (state is DeliveryLoading || state is DeliveryInitial) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Colors.deepOrangeAccent,
                  ),
                );
              }

              if (state is DeliveryError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        state.message,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.read<DeliveryBloc>().add(
                          const FetchDeliveryTasks(),
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (state is DeliveryLoaded) {
                return TabBarView(
                  children: [
                    _buildTaskList(
                      state.filteredActiveTasks,
                      isActive: true,
                      activeFilter: state.activeFilter,
                    ),
                    _buildTaskList(state.historyTasks, isActive: false),
                  ],
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTaskList(
    List<DeliveryTask> tasks, {
    required bool isActive,
    String activeFilter = 'All',
  }) {
    return Column(
      children: [
        if (isActive)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: ['All', 'Assigned', 'Picked', 'Out for Delivery'].map((
                filter,
              ) {
                final isSelected = activeFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        // PROD COMPILE FIX: Switched to named parameters
                        context.read<DeliveryBloc>().add(
                          FilterActiveTasks(filter: filter),
                        );
                      }
                    },
                    selectedColor: Colors.deepOrangeAccent.withValues(
                      alpha: 0.2,
                    ),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? Colors.deepOrangeAccent
                            : Colors.grey.shade300,
                      ),
                    ),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.deepOrangeAccent
                          : Colors.black87,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

        Expanded(
          child: tasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isActive ? Icons.inbox_outlined : Icons.history,
                        size: 64,
                        color: Colors.black26,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isActive
                            ? 'No Tasks in "$activeFilter"'
                            : 'No History Yet',
                        style: const TextStyle(
                          color: Colors.black45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              // PROD UX FIX: Added Pull-to-refresh capability
              : RefreshIndicator(
                  color: Colors.deepOrangeAccent,
                  onRefresh: () async {
                    context.read<DeliveryBloc>().add(
                      const FetchDeliveryTasks(),
                    );
                    // Wait briefly to show the spinner gracefully
                    await Future.delayed(const Duration(seconds: 1));
                  },
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    // Ensures scrolling works even if list is short
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return _TaskCard(task: task);
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _TaskCard extends StatelessWidget {
  final DeliveryTask task;

  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.deepOrangeAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    task.status,
                    style: const TextStyle(
                      color: Colors.deepOrangeAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  task.type,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 20,
                  color: Colors.black54,
                ),
                const SizedBox(width: 8),
                Text(
                  task.customerName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                const Icon(
                  Icons.phone_outlined,
                  size: 20,
                  color: Colors.black54,
                ),
                const SizedBox(width: 8),
                Text(task.phone, style: const TextStyle(fontSize: 14)),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 20,
                  color: Colors.black54,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    task.address?.formattedAddress ?? 'No address provided',
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'To Collect',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      '₹${task.cashToCollect}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    // PROD ROUTING FIX: Safe named routing
                    context.pushNamed('delivery_task_details', extra: task);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('View Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
