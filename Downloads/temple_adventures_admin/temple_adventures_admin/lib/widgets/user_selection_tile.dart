import 'package:flutter/material.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';
import 'package:temple_adventures_admin/widgets/user_tank_selection.modal.dart';

import '../features/boats/enums/user_type.enum.dart';
import '../features/boats/models/boat_info.model.dart';
import '../features/bookings/presentation/widgets/custom_title.dart';

class UserSelectorTile extends StatelessWidget {
  final String title;
  final List<TankInfo> selectedUsers;
  final UserType userType;
  final void Function(List<TankInfo>) onUsersSelected;
  final bool tanksRequired;

  const UserSelectorTile({
    super.key,
    required this.title,
    required this.selectedUsers,
    required this.userType,
    required this.onUsersSelected,
    this.tanksRequired = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.only(right: 10),
      title: CustomTitle(
        title: (tanksRequired) ? '$title (N-A)' : title,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selectedUsers.isNotEmpty)
            ...selectedUsers.map(
              (user) => Text(
                user.formatedTankInfo(tanksRequired),
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ).paddingOnly(top: 5),
            ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        final users = await UserTankSelectionModal.selectMultiple(
          context,
          initialTankInfos: selectedUsers,
          tanksRequired: tanksRequired,
          userType: userType,
        );

        if (users != null) {
          onUsersSelected(users);
        }
      },
    );
  }
}
