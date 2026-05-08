import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:temple_adventures_admin/features/boats/models/boat_info.model.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';

import '../features/boats/enums/user_type.enum.dart';
import '../features/boats/presentation/widgets/counter_widget.dart';
import '../features/user/bloc/all_users.cubit.dart';
import '../features/user/enums/roles.enum.dart';
import '../features/user/models/user.model.dart';
import '../utils/debouncer.dart';
import '../utils/styling/spacing_widgets.dart';
import 'app_button.dart';
import 'app_text_field.dart';

enum SelectionMode { single, multiple }

class UserTankSelectionModal extends StatefulWidget {
  final List<TankInfo> initialTankInfos;
  final UserType? userType;
  final bool tanksRequired;
  final SelectionMode selectionMode;

  const UserTankSelectionModal({
    super.key,
    required this.initialTankInfos,
    this.userType,
    this.tanksRequired = true,
    this.selectionMode = SelectionMode.multiple,
  });

  static Future<List<TankInfo>?> selectMultiple(
    BuildContext context, {
    required List<TankInfo> initialTankInfos,
    UserType? userType,
    bool tanksRequired = true,
  }) {
    return showModalBottomSheet<List<TankInfo>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => UserTankSelectionModal(
            initialTankInfos: initialTankInfos,
            userType: userType,
            tanksRequired: tanksRequired,
            selectionMode: SelectionMode.multiple,
          ),
    );
  }

  static Future<TankInfo?> selectSingle(
    BuildContext context, {
    TankInfo? selectedTankInfo,
    UserType? userType,
    bool tanksRequired = true,
  }) async {
    final result = await showModalBottomSheet<List<TankInfo>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => UserTankSelectionModal(
            initialTankInfos: selectedTankInfo != null ? [selectedTankInfo] : [],
            userType: userType,
            tanksRequired: tanksRequired,
            selectionMode: SelectionMode.single,
          ),
    );
    return result?.isNotEmpty == true ? result!.first : null;
  }

  @override
  State<UserTankSelectionModal> createState() => _UserTankSelectionModalState();
}

class _UserTankSelectionModalState extends State<UserTankSelectionModal> {
  late List<TankInfo> _tempSelectedTankInfos;
  late final TextEditingController _searchTED;
  late final Debouncer _searchUpdateDebouncer;

  @override
  void initState() {
    super.initState();
    _tempSelectedTankInfos = List.from(widget.initialTankInfos);
    _searchTED = TextEditingController();
    _searchUpdateDebouncer = Debouncer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AllUsersCubit>().fetchAllUsers();
    });
  }

  @override
  void dispose() {
    _searchTED.dispose();
    _searchUpdateDebouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header - fixed
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.selectionMode == SelectionMode.single ? 'Select User' : 'Select Users',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Spacing.h20,

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    children: [
                      // Selected Tanks
                      if (_tempSelectedTankInfos.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(
                            _tempSelectedTankInfos.length,
                            (index) => _buildTankCounter(index),
                          ),
                        ).paddingOnly(bottom: 20),

                      // Search field
                      AppTextField(
                        controller: _searchTED,
                        onChanged: (_) => _searchUpdateDebouncer(() => setState(() {})),
                        labelText: 'Search by name',
                        border: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                      ).paddingOnly(bottom: 20),

                      // User list
                      BlocBuilder<AllUsersCubit, AllUsersState>(
                        builder: (context, state) {
                          return state.status.when(
                            initial: () => const SizedBox.shrink(),
                            loading: () => CircularProgressIndicator().center,
                            error:
                                (message) =>
                                    Text(
                                      'Error: $message',
                                      style: const TextStyle(color: Colors.red),
                                    ).center,
                            loaded: () {
                              List<User> filteredUsers =
                                  state.users.where((user) {
                                    final type = widget.userType;
                                    if (type == null) return true;
                                    switch (type) {
                                      case UserType.showAllUsers:
                                        return true;
                                      case UserType.showCaptains:
                                        return user.role == Roles.captainTeam;
                                      case UserType.showFreelancersDivers:
                                        return user.role == Roles.diveTeam || user.role == Roles.freelanceTeam;
                                      case UserType.showDiveTeam:
                                        return user.role == Roles.diveTeam ||
                                            user.role == Roles.freelanceTeam ||
                                            user.role == Roles.intern;
                                      case UserType.showInterns:
                                        return user.role == Roles.intern;
                                    }
                                  }).toList();

                              final query = _searchTED.text.toLowerCase();
                              filteredUsers =
                                  filteredUsers.where((user) => user.fullName.toLowerCase().contains(query)).toList();

                              if (filteredUsers.isEmpty) {
                                return const Text('No users available').center;
                              }

                              return ListView.builder(
                                controller: scrollController,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: filteredUsers.length,
                                padding: const EdgeInsets.only(bottom: 16),
                                itemBuilder: (context, index) {
                                  final user = filteredUsers[index];
                                  final isSelected = _tempSelectedTankInfos.any(
                                    (tankInfo) => tankInfo.userId == user.id,
                                  );
                                  bool isSelectedInstructor = _tempSelectedTankInfos
                                      .map((e) => e.userId)
                                      .contains(user.id);

                                  return InkWell(
                                    onTap: () {
                                      setState(() {
                                        if (widget.selectionMode == SelectionMode.single) {
                                          if (!isSelected) {
                                            _tempSelectedTankInfos = [
                                              TankInfo(
                                                userId: user.id!,
                                                userFirstName: user.firstName,
                                                userLastName: user.lastName,
                                                nitrox: 0,
                                                air: 0,
                                                role: null,
                                              ),
                                            ];
                                          } else {
                                            _tempSelectedTankInfos.clear();
                                          }
                                        } else {
                                          if (isSelected) {
                                            _tempSelectedTankInfos.removeWhere(
                                              (tankInfo) => tankInfo.userId == user.id,
                                            );
                                          } else {
                                            _tempSelectedTankInfos.add(
                                              TankInfo(
                                                userId: user.id!,
                                                userFirstName: user.firstName,
                                                userLastName: user.lastName,
                                                nitrox: 0,
                                                air: 0,
                                                role: null,
                                              ),
                                            );
                                          }
                                        }
                                      });
                                    },
                                    child: Container(
                                      decoration:
                                          isSelectedInstructor
                                              ? BoxDecoration(
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: Colors.black,
                                                ),
                                              )
                                              : null,
                                      child: Row(
                                        children: [
                                          Text(
                                            user.fullName,
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                          const Spacer(),
                                          if (isSelectedInstructor)
                                            buildStatusTab('Selected', Colors.black, Colors.white),
                                        ],
                                      ).paddingAll(10),
                                    ).paddingOnly(bottom: 10),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              Spacing.h20,

              // Bottom buttons
              Row(
                children: [
                  Expanded(
                    child: AppButton.flat(text: 'Cancel', onTap: () => Navigator.pop(context)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppButton.flat(text: 'Select', onTap: () => Navigator.pop(context, _tempSelectedTankInfos)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Container _buildTankCounter(int index) {
    final bool tanksRequired = widget.tanksRequired;
    final TankInfo user = _tempSelectedTankInfos[index];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                user.name,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              (tanksRequired) ? Spacer() : Spacing.w5,
              (tanksRequired)
                  ? AppButton.miniFlat(
                    text: 'Remove',
                    onTap: () {
                      setState(() {
                        _tempSelectedTankInfos.remove(user);
                      });
                    },
                  )
                  : InkWell(
                    onTap: () {
                      setState(() {
                        _tempSelectedTankInfos.remove(user);
                      });
                    },
                    child: Icon(
                      Icons.close,
                      size: 16,
                    ),
                  ),
            ],
          ),
          if (tanksRequired)
            Row(
              children: [
                CounterWidget(
                  label: 'Nitrox',
                  onChanged: (int nitrox) {
                    setState(() {
                      _tempSelectedTankInfos[index] = user.copyWith(nitrox: nitrox);
                    });
                  },
                  initialValue: user.nitrox ?? 0,
                ),
                Spacer(),
                CounterWidget(
                  label: 'Air',
                  onChanged: (int air) {
                    setState(() {
                      _tempSelectedTankInfos[index] = user.copyWith(air: air);
                    });
                  },
                  initialValue: user.air ?? 0,
                ),
              ],
            ).paddingOnly(top: 10),
        ],
      ).paddingAll(15),
    );
  }

  Widget buildStatusTab(String text, Color color, [Color? textColor]) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
      height: 20,
      width: 70,
      child:
          Text(
            text,
            style: TextStyle(fontSize: 10, color: textColor),
            textAlign: TextAlign.center,
          ).center,
    );
  }
}
