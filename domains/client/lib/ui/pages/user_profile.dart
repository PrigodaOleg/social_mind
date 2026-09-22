import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:closers/state/state.dart';
import 'package:closers/state/user_profile/user_profile.dart';
import '../widgets/profile_item_tile.dart';
import '../l10n/app_localizations.dart';
import 'package:closers/repository/repository.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

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
        return LayoutBuilder(builder: (context, constraints) {
          //logic
          const double avatarRadius = 60.0;
          const double wideScreenMinWidth = 600;
          final screenWidth = MediaQuery.of(context).size.width;
          Alignment adaptiveAlignment =
              screenWidth > 600 ? Alignment.topLeft : Alignment.topCenter;
          const String? imageUrl = null;
          final qrCode = QrCode(4, QrErrorCorrectLevel.L)
            ..addData('Hello, world in QR form!');
          final qrImage = QrImage(qrCode);
          return Scaffold(
            appBar: AppBar(
              backgroundColor: t.colorScheme.inversePrimary,
              title: Text(l.userProfilePageName),
            ),
            body: Column(
              children: [
                Center(
                  child: SizedBox(
                    width: (avatarRadius * 2) + 20,
                    height: (avatarRadius * 2) + 20,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // 1. The Main Circular Profile Image
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(25),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: avatarRadius,
                            backgroundColor: Colors.blue.shade100,
                            backgroundImage: imageUrl != null
                                ? NetworkImage(imageUrl!)
                                : null,
                            child: imageUrl == null
                                ? const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ),

                        // 2. Choose Image Button (Bottom Right)
                        Positioned(
                          bottom: 5,
                          right: 5,
                          child: _buildCircularButton(
                            icon: Icons.camera_alt,
                            backgroundColor: Colors.blue,
                            iconColor: Colors.white,
                            onPressed: () async {
                              updateAvatar();
                            }, //need an bloc event here
                          ),
                        ),
                        // 3. Show QR Code Button (Top Right / Alternative Side)
                        Positioned(
                          top: 5,
                          right: 5,
                          child: _buildCircularButton(
                            icon: Icons.qr_code_2,
                            backgroundColor: Colors.white,
                            iconColor: Colors.black87,
                            onPressed: () async {
                              bool? isPerformed = await showModalBottomSheet(
                                context: context,
                                builder: (BuildContext context) {
                                  return qrview(qrImage: qrImage);
                                },
                              );
                            }, //need an bloc event here
                            hasShadow: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                    child: Align(
                  alignment: adaptiveAlignment,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: wideScreenMinWidth),
                    child: ListView.builder(
                        padding: EdgeInsets.only(top: 10, left: 10, right: 10),
                        itemCount: state.userProfileRecords
                            .where(
                                (property) => property['propId'] != 'avatarUrl')
                            .toList()
                            .length,
                        itemBuilder: (context, index) {
                          final visibleListElements = state.userProfileRecords
                              .where((property) =>
                                  property['propId'] != 'avatarUrl')
                              .toList();
                          final record = visibleListElements[index];
                          return ProfileItemTile(
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
                          );
                        }),
                  ),
                )),
              ],
            ),
          );
        });
      },
    );
  }

  Future<void> updateAvatar() async {
    XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image == null) return;

    // final Directory appDocDir = await getApplicationDocumentsDirectory();
    final Directory appSupportDir = await getApplicationSupportDirectory();

    final String extension = path.extension(image.path);
    final String newFileName = 'avatar$extension';
    final String permanentPath = path.join(appSupportDir.path, newFileName);
    print(permanentPath);

    final File tempFile = File(image.path);
    await tempFile.copy(permanentPath);
  }

  Widget qrview({required QrImage qrImage}) {
    return PrettyQrView(
      qrImage: qrImage,
      decoration: const PrettyQrDecoration(),
    );
  }

  Widget _buildCircularButton({
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
    required VoidCallback onPressed,
    bool hasShadow = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: hasShadow
            ? [
                BoxShadow(
                  color: Colors.black.withAlpha(40),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: backgroundColor,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: IconButton(
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          padding: EdgeInsets.zero,
          icon: Icon(icon, size: 20, color: iconColor),
          onPressed: onPressed,
        ),
      ),
    );
  }
}

class AvatarSection extends StatelessWidget {
  const AvatarSection({super.key, required this.image});

  static String defaultImage = 'defaultAvatar.bmp';
  final String image;

  @override
  Widget build(BuildContext context) {
    final avatar = image.trim().isNotEmpty ? image : defaultImage;
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: CircleAvatar(
        backgroundImage: AssetImage(avatar),
        minRadius: 50,
      ),
    );
  }
}
