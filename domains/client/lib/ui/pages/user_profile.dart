import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:closers/state/state.dart';
import 'package:closers/state/user_profile/user_profile.dart';
import '../widgets/profile_item_tile.dart.dart';
import '../../l10n/app_localizations.dart';
import 'package:closers/repository/repository.dart';


class UserProfilePage extends StatelessWidget {
  static const routeName = '/user_profile';

  const UserProfilePage(this.repository, {super.key, this.id});
  final Repository repository;
  final String? id;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TaskListBloc(
        repository: repository,
        parentId: id ?? repository.myId ?? '',
      )..add(const TaskListStateInitRequested()),
      child: const UserProfileView(),
    );
  }
}

class UserProfileView extends StatelessWidget {
  const UserProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context);
    final b = BlocProvider.of<TaskListBloc>(context);
    // final repo = context.read(Repository);
    return BlocBuilder<TaskListBloc, TaskListState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: t.colorScheme.inversePrimary,
            title: Text(l.taskListPageName),
          ),
          body: ListView(
            children: [
              for (final (index, task) in state.tasks.values.indexed)
                TaskListTile(
                  title: task.title,
                  value: task.isCompleted,
                  backgroundColor: index.isEven
                      ? t.colorScheme.surface
                      : Color.lerp(
                          t.colorScheme.surface,
                          t.colorScheme.primary,
                          0.07,
                        ),
                  onValueChanged: (bool? isComplited) {
                    b.add(
                      TaskCompletionRequested(
                        task: task,
                        isComplited: isComplited ?? false,
                      ),
                    );
                  },
                  onTitleSubmitted: (submittedText) {
                    b.add(
                      TaskSubmitionRequested(
                        task: task,
                        submittedText: submittedText,
                      ),
                    );
                  },
                  onTitleChanged: (changedText) {
                    context.read<TaskListBloc>().add(
                      TaskChangingRequested(
                        task: task,
                        changedText: changedText,
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
