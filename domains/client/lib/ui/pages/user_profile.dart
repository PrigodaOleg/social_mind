import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:closers/state/state.dart';
import 'package:closers/state/user_profile/user_profile.dart';
import '../widgets/profile_item_tile.dart';
import '../l10n/app_localizations.dart';
import 'package:closers/repository/repository.dart';

class UserProfilePage extends StatelessWidget {
  static const routeName = '/user_profile';

  const UserProfilePage(this.repository, {super.key, this.id});
  final Repository repository;
  final String? id;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProfilePageBloc(
        repository: repository,
        userId: id ?? repository.myId ?? '',
      )..add(const ProfilePageStateInitRequested()),
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
    return BlocBuilder<ProfilePageBloc, ProfilePageState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: t.colorScheme.inversePrimary,
            title: Text(l.userProfilePageName),
          ),
          body: ListView(

            children: [

              // AvatarSection(image: 
              // state.userProfileRecords.firstWhere((record)=>record.containsKey('avatarUrl'))['avatarUrl']),
              for (final (index, record) in state.userProfileRecords.indexed)

                    ProfileItemTile(
                        title: record['value'],
                        labelText: record['propId'],
                        isEditable: record['isEditable'],
                        backgroundColor: index.isEven
                            ? t.colorScheme.surface
                            : Color.lerp(
                                t.colorScheme.surface,
                                t.colorScheme.primary,
                                0.07,
                              ),
                        onTitleSubmitted: (submittedText) {
                          context.read<ProfilePageBloc>().add(
                                ProfileRecordSubmitRequested(
                                    recordIndex: index,
                                    changedText: submittedText),
                              );
                        },
                        onTitleChanged: (changedText) {
                          context.read<ProfilePageBloc>().add(
                                ProfileRecordChangingRequested(
                                  recordIndex: index,
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

class AvatarSection extends StatelessWidget {
  const AvatarSection({super.key, required this.image});

  final String image;

  @override
  Widget build(BuildContext context) {
    // return Image.asset(image, width: 600, height: 240, fit: BoxFit.cover);
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: CircleAvatar(backgroundImage: AssetImage(image)),
    );
  }
}
