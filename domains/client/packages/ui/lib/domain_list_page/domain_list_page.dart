import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:state/state.dart';
import 'package:repository/repository.dart';
import 'package:ui/ui.dart';



class DomainListPage extends StatelessWidget {
  const DomainListPage(
    this.repository,
    {
      super.key,
      this.title,
    }
  );
  final String? title;
  final Repository repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DomainListBloc(repository: repository),
      child: const DomainListView(),
    );
  }
}

class DomainListView extends StatelessWidget {
  const DomainListView({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final n = Navigator.of(context);
    final t = Theme.of(context);
    final b = BlocProvider.of<DomainListBloc>(context);
    // final repo = context.read(Repository);
    return BlocProvider<DomainListBloc>(
      create: (context) => context.read<DomainListBloc>()
      ..add(const DomainListStateInitRequested()),
      child: BlocBuilder<DomainListBloc, DomainListState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: t.colorScheme.inversePrimary,
              title: Text(l.domainListPageName),
            ),
            body: ListView(
              children: [
                // ignore: unused_local_variable
                for (final (index, domain) in state.domains.values.indexed)
                  ListTile(
                    title: Text(domain.title),
                    onTap: () => n.pushNamed('${DomainContentPage.routeName}/${domain.id}', arguments: {#id: domain.id}),
                  ),
                  // Row(
                  //   children: [
                  //     Text(domain.title),
                  //     IconButton(
                  //       onPressed: () {
                  //         b.add(
                  //           DomainChangingRequested(domain: domain)
                  //         );
                  //       },
                  //       icon: const Icon(Icons.create)
                  //     ),
                  //     IconButton(
                  //       onPressed: () {
                  //         b.add(
                  //           DomainDeletionRequested(domain: domain)
                  //         );
                  //       },
                  //       icon: const Icon(Icons.delete)
                  //     ),
                  //     domain.sync == SyncStatus.no ?
                  //       const Icon(Icons.sd_storage) :
                  //       const Icon(Icons.cloud_done_outlined)
                  //   ],
                  // ),
                IconButton(
                  onPressed: () {
                    b.add(
                      const DomainCreationRequested('New domain')
                    );
                  },
                  icon: const Icon(Icons.add_circle)
                ),
              ]
            ),
            // floatingActionButton: FloatingActionButton(
            //   onPressed: () {
            //     BlocProvider.of<TaskListBloc>(context).add(
            //       const TaskAddRequested()
            //     );
            //   },
            //   tooltip: l.addTaskHint,
            //   child: const Icon(Icons.add_task),
            // ), // This trailing comma makes auto-formatting nicer for build methods.
          );
      })
    );
  }
}
