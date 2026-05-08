import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';

import '../features/boats/enums/user_type.enum.dart';
import '../features/user/bloc/all_users.cubit.dart';
import '../features/user/models/user.model.dart';
import '../utils/styling/spacing_widgets.dart';
import 'app_button.dart';

enum SelectionMode { single, multiple }

class UserSelectionModal extends StatefulWidget {
  final List<User> selectedUsers;
  final List<int> dsdInstructors;
  final UserType? userType;
  final SelectionMode selectionMode;

  const UserSelectionModal({
    super.key,
    required this.selectedUsers,
    this.userType,
    this.selectionMode = SelectionMode.multiple,
    required this.dsdInstructors,
  });

  static Future<List<User>?> selectMultiple(
    BuildContext context, {
    required List<User> selectedUsers,
    UserType? userType,
  }) {
    return showModalBottomSheet<List<User>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => UserSelectionModal(
            selectedUsers: selectedUsers,
            userType: userType,
            dsdInstructors: [],
            selectionMode: SelectionMode.multiple,
          ),
    );
  }

  static Future<User?> selectSingle(
    BuildContext context, {
    User? selectedUser,
    UserType? userType,
    List<int>? dsdInstructors,
  }) async {
    final result = await showModalBottomSheet<List<User>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => UserSelectionModal(
            selectedUsers: selectedUser != null ? [selectedUser] : [],
            dsdInstructors: dsdInstructors ?? [],
            userType: userType,
            selectionMode: SelectionMode.single,
          ),
    );
    return result?.isNotEmpty == true ? result!.first : null;
  }

  @override
  State<UserSelectionModal> createState() => _UserSelectionModalState();
}

class _UserSelectionModalState extends State<UserSelectionModal> {
  late List<User> _tempSelectedUsers;

  @override
  void initState() {
    super.initState();
    _tempSelectedUsers = List.from(widget.selectedUsers);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AllUsersCubit>().fetchAllUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.selectionMode == SelectionMode.single ? 'Select User' : 'Select Users',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          Spacing.h20,

          // User List
          Expanded(
            child: BlocBuilder<AllUsersCubit, AllUsersState>(
              builder: (context, state) {
                return state.status.when(
                  initial: () => const SizedBox.shrink(),
                  loading: () => CircularProgressIndicator().center,
                  error: (message) => Text('Error: $message', style: TextStyle(color: Colors.red)).center,
                  loaded: () {
                    List<User> dsdInstructors = [];
                    List<User> others = [];

                    for (var user in state.users) {
                      if (widget.dsdInstructors.contains(user.id)) {
                        dsdInstructors.add(user);
                      } else {
                        others.add(user);
                      }
                    }

                    final users = [...dsdInstructors, ...others];

                    return ListView.builder(
                      itemCount: users.length,
                      padding: const EdgeInsets.only(bottom: 16),
                      itemBuilder: (context, index) {
                        final user = users[index];
                        final isSelected = _tempSelectedUsers.contains(user);
                        final Widget listTile = CheckboxListTile(
                          title: Text(user.fullName),
                          value: isSelected,
                          dense: true,
                          onChanged: (selected) {
                            setState(() {
                              if (widget.selectionMode == SelectionMode.single) {
                                // Single selection mode
                                if (selected == true) {
                                  _tempSelectedUsers = [user];
                                  // Auto-close bottom sheet after selection
                                  Navigator.pop(context, _tempSelectedUsers);
                                } else {
                                  _tempSelectedUsers.remove(user);
                                  Navigator.pop(context, null);
                                }
                              } else {
                                // Multiple selection mode
                                if (selected == true) {
                                  if (!isSelected) {
                                    //  multiple selection
                                    _tempSelectedUsers.add(user);
                                  }
                                } else {
                                  _tempSelectedUsers.remove(user);
                                }
                              }
                            });
                          },
                        );

                        // Show title
                        if (dsdInstructors.isNotEmpty && index == 0) {
                          return Column(
                            children: [
                              Text(
                                'DSD Instructors',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ).paddingOnly(left: 13).left,
                              listTile,
                            ],
                          );
                        }
                        // Show title
                        if (dsdInstructors.isNotEmpty && index == dsdInstructors.length) {
                          return Column(
                            children: [
                              Divider(
                                height: 5,
                              ).paddingOnly(left: 13, right: 30),
                              listTile,
                            ],
                          );
                        }

                        return listTile;
                      },
                    );
                  },
                );
              },
            ),
          ),

          Spacing.h20,
          Row(
            children: [
              Expanded(child: AppButton.flat(text: 'Cancel', onTap: () => Navigator.pop(context))),
              const SizedBox(width: 16),
              Expanded(child: AppButton.flat(text: 'Select', onTap: () => Navigator.pop(context, _tempSelectedUsers))),
            ],
          ),
        ],
      ),
    );
  }
}
