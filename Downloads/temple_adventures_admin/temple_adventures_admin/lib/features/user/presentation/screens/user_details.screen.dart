import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:temple_adventures_admin/features/logs/repository/logs.repository.dart';
import 'package:temple_adventures_admin/features/user/enums/gender.enum.dart';
import 'package:temple_adventures_admin/features/user/enums/roles.enum.dart';
import 'package:temple_adventures_admin/utils/extensions/build_context.extensions.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';

import '../../../../theme.dart';
import '../../../../utils/access_levels.dart';
import '../../../../utils/locator.dart';
import '../../../../utils/phone_utils.dart';
import '../../../../utils/styling/spacing_widgets.dart';
import '../../../../widgets/custom_alert_dialog.dart';
import '../../../../widgets/custom_app_bar.dart';
import '../../../../widgets/key_value_pair.dart';
import '../../bloc/user_details.cubit.dart';
import '../../models/user.model.dart';
import '../../repository/user.repository.dart';
import 'add_edit_user.screen.dart';

class UserDetailsScreen extends StatefulWidget {
  const UserDetailsScreen({super.key, required this.user});

  final User user;

  static MaterialPageRoute<dynamic> route(User user) {
    return MaterialPageRoute(
      builder: (context) {
        return UserDetailsScreen(user: user);
      },
    );
  }

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  late UserDetailsCubit _userDetailsCubit;

  @override
  void initState() {
    super.initState();
    _userDetailsCubit = UserDetailsCubit(
      repository: locator<UserRepository>(),
      logRepository: locator<LogsRepository>(),
    );
  }

  User get user => widget.user;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _userDetailsCubit,
      child: BlocConsumer<UserDetailsCubit, UserDetailsState>(
        listener: (context, state) {
          if (state is UserDetailsSuccess) {
            Navigator.pop(context);
          }
          if (state is UserDetailsError) context.showSnackBar(state.message);
        },
        builder: (context, state) {
          return Scaffold(
            appBar: CustomAppBar(title: 'User Details', description: 'User Information'),
            body: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Spacing.h40,
                  _buildUserAvtar,
                  Spacing.h20,
                  Text(
                    '${user.firstName} ${user.lastName}',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  Spacing.h20,
                  _buildUserActionButtons(context),
                  Spacing.h20,
                  const Divider(),
                  Spacing.h20,
                  _UserDetails(userModel: user).paddingHorizontal(30),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget get _buildUserAvtar {
    return SizedBox(
      height: 100,
      width: 100,
      child: CircleAvatar(
        backgroundImage: NetworkImage(
          'https://preview.keenthemes.com/metronic-v4/theme/assets/pages/media/profile/profile_user.jpg',
        ),
      ),
    );
  }

  Widget _buildUserActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _ActionButton(
          icon: Icons.phone,
          onTap: () {
            PhoneUtils.makingPhoneCall(phoneNumber: user.phoneNumber, code: user.countryCode);
          },
        ),
        _ActionButton(
          icon: Icons.edit,
          onTap: () {
            if (AccessLevelChecker.canEditUsers(context)) {
              Navigator.push(context, AddEditUserScreen.route(user: user));
            } else {
              // Show message that user doesn't have permission
              context.showSnackBar('You don\'t have permission to edit users');
            }
          },
        ),
        _ActionButton(
          icon: Icons.delete,
          onTap: () async {
            final shouldDeleteUser = await CustomAlertDialog.show(
              context,
              title: 'Are you sure?',
              content: 'User will be permanently deleted',
            );
            if (shouldDeleteUser == true && context.mounted) {
              await _userDetailsCubit.deleteUser(context, user);
            }
          },
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;

  const _ActionButton({required this.onTap, required this.icon});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: CircleAvatar(
        backgroundColor: lightSkyBlue,
        child: Icon(icon, size: 20, color: Colors.black).center,
      ),
    );
  }
}

class _UserDetails extends StatelessWidget {
  final User userModel;

  const _UserDetails({required this.userModel});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'User Details',
          style: TextStyle(color: skyBlueColor, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        Spacing.h20,
        Column(
          spacing: 10,
          children: [
            KeyValuePair(title: 'Phone Number', value: '${userModel.countryCode} ${userModel.phoneNumber}'),
            KeyValuePair(title: 'Gender', value: userModel.gender.label),
            KeyValuePair(title: 'Role', value: userModel.role.label),
            KeyValuePair(title: 'Padi No', value: userModel.padiNo ?? '-'),
          ],
        ),
      ],
    );
  }
}
