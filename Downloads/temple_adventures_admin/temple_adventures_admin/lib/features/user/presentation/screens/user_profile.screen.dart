import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:temple_adventures_admin/features/user/enums/roles.enum.dart';
import 'package:temple_adventures_admin/utils/extensions/date_time.extensions.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';
import 'package:temple_adventures_admin/widgets/app_button.dart';
import 'package:temple_adventures_admin/widgets/custom_app_bar.dart';
import 'package:temple_adventures_admin/widgets/key_value_pair.dart';

import '../../../../theme.dart';
import '../../../../utils/locator.dart';
import '../../../../utils/styling/spacing_widgets.dart';
import '../../bloc/user.cubit.dart';
import '../../bloc/user_profile.cubit.dart';
import '../../models/user.model.dart';
import '../../repository/user.repository.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  static MaterialPageRoute<dynamic> route() => MaterialPageRoute(
    builder: (context) {
      return BlocProvider(
        create: (context) => UserProfileCubit(repository: locator<UserRepository>()),
        child: UserProfileScreen(),
      );
    },
  );

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'User Profile', description: 'User Profile Screen'),
      body: SafeArea(
        child: Column(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(
                'https://preview.keenthemes.com/metronic-v4/theme/assets/pages/media/profile/profile_user.jpg',
              ),
            ).size(100, 100).center,
            Spacing.h20,
            const Divider(),
            Spacing.h20,
            Text('User Details', style: TextStyle(fontSize: 16, color: skyBlueColor, fontWeight: FontWeight.w700)).left,
            Spacing.h20,
            _UserInfo(),
            Spacing.h20,
            _LeavesSection(),
          ],
        ).paddingAll(30),
      ),
    );
  }
}

class _LeavesSection extends StatelessWidget {
  const _LeavesSection();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<UserCubit, UserState, User?>(
      selector: (state) => state.currentUser,
      builder: (context, user) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            KeyValuePair(
              title: 'Apply Leaves',
              widget:
                  BlocSelector<UserProfileCubit, UserProfileState, bool>(
                    selector: (state) => state is UserProfileLoading,
                    builder: (context, isLoading) {
                      return AppButton.miniFlat(
                        onTap: () {
                          // User can't come this far if user from current context is null.
                          context.read<UserProfileCubit>().updateLeaves(context);
                        },
                        text: (user?.leaveStartDate == null && user?.leaveEndDate == null) ? 'Apply' : 'Change',
                        showLoading: isLoading,
                      );
                    },
                  ).center,
            ),
            Spacing.h10,
            if (user?.leaveStartDate != null && user?.leaveEndDate != null)
              Text(
                "${user!.leaveStartDate!.formatDDMMYYYY} - ${user.leaveEndDate!.formatDDMMYYYY}",
                style: const TextStyle(fontSize: 13),
              ).left,
          ],
        );
      },
    );
  }
}

class _UserInfo extends StatelessWidget {
  const _UserInfo();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<UserCubit, UserState, User?>(
      selector: (state) => state.currentUser,
      builder: (context, user) {
        return Column(
          spacing: 10,
          children: [
            KeyValuePair(
              title: 'Name',
              value:
                  '${user?.firstName} '
                  '${user?.lastName}',
            ),
            KeyValuePair(
              title: 'Phone Number',
              value:
                  '${user?.countryCode} '
                  '${user?.phoneNumber}',
            ),
            KeyValuePair(title: 'Role', value: '${user?.role.label}'),
          ],
        );
      },
    );
  }
}
