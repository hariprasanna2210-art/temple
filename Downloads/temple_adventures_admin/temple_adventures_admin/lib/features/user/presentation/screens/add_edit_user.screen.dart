import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:temple_adventures_admin/features/logs/repository/logs.repository.dart';
import 'package:temple_adventures_admin/features/user/enums/access_levels.enum.dart';
import 'package:temple_adventures_admin/utils/extensions/build_context.extensions.dart';
import 'package:temple_adventures_admin/utils/extensions/string.extensions.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/app_measurements.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';

import '../../../../services/logging.dart';
import '../../../../utils/locator.dart';
import '../../../../utils/styling/spacing_widgets.dart';
import '../../../../widgets/app_button.dart';
import '../../../../widgets/app_dropdown.dart';
import '../../../../widgets/app_text_field.dart';
import '../../../../widgets/custom_app_bar.dart';
import '../../../../widgets/phone_number.dart';
import '../../bloc/add_edit_user.cubit.dart';
import '../../bloc/all_users.cubit.dart';
import '../../bloc/user.cubit.dart';
import '../../enums/gender.enum.dart';
import '../../enums/roles.enum.dart';
import '../../models/user.model.dart';
import '../../repository/user.repository.dart';

class AddEditUserScreen extends StatefulWidget {
  const AddEditUserScreen({super.key, this.user});

  final User? user;

  static MaterialPageRoute<dynamic> route({User? user}) => MaterialPageRoute(
    builder: (context) {
      return BlocProvider(
        create: (context) =>
            AddEditUserCubit(repository: locator<UserRepository>(), logRepository: locator<LogsRepository>()),
        child: AddEditUserScreen(user: user),
      );
    },
  );

  @override
  State<AddEditUserScreen> createState() => _AddEditUserScreenState();
}

class _AddEditUserScreenState extends State<AddEditUserScreen> {
  late TextEditingController _firstNameTED, _nickNameTED, _lastNameTED, _phoneNumberTED, _padiNoTED;

  Roles? _selectedRole;
  Gender? _selectedGender;
  String? _countryCode;
  String? _isoCode;
  List<AccessLevels> _selectedAccessLevels = [];
  final _formKey = GlobalKey<FormState>();
  User? get user => widget.user;

  bool get editMode => user != null;

  @override
  void initState() {
    super.initState();

    _firstNameTED = TextEditingController(text: user?.firstName);
    _lastNameTED = TextEditingController(text: user?.lastName);
    _nickNameTED = TextEditingController(text: user?.nickName);
    _phoneNumberTED = TextEditingController(text: user?.phoneNumber);
    _padiNoTED = TextEditingController(text: user?.padiNo);
    _countryCode = user?.countryCode;
    _isoCode = user?.isoCode;
    _selectedRole = user?.role;
    _selectedGender = user?.gender;
    _selectedAccessLevels = user?.accessLevels ?? [];
  }

  @override
  void dispose() {
    _firstNameTED.dispose();
    _lastNameTED.dispose();
    _nickNameTED.dispose();
    _phoneNumberTED.dispose();
    _padiNoTED.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AddEditUserCubit, AddEditUserState>(
      listener: (context, state) async {
        // Handle successful user add/edit
        if (state is AddEditUserSuccess) {
          final updatedUser = state.updatedUser;
          final currentUser = context.read<UserCubit>().state.currentUser;

          // Optimization: Only refresh current user data if the edited user is the current logged-in user.
          // This prevents unnecessary API calls when editing other users.
          if (updatedUser != null && currentUser != null && updatedUser.id == currentUser.id) {
            Log.i('Edited user is current user, refreshing current user data');
            await context.read<UserCubit>().getUserData(updatedUser.id!);
          }

          // Refresh AllUsersCubit before navigating back to ensure the user list is updated.
          // This ensures that when we navigate back to AllUsersScreen, the new/edited user appears.
          if (context.mounted) {
            await context.read<AllUsersCubit>().fetchAllUsers();
          }

          // Navigate back to previous screen(s)
          if (context.mounted) {
            Navigator.pop(context);
            // If in edit mode, pop twice because we came from UserDetailsScreen → AddEditUserScreen
            // We need to go back to AllUsersScreen
            if (editMode) {
              Navigator.pop(context);
            }
          }
        }
        // Handle errors
        if (state is AddEditUserError && context.mounted) context.showSnackBar(state.message);
      },
      builder: (context, state) {
        return Scaffold(
          appBar: CustomAppBar(title: 'User', description: editMode ? 'Edit user details' : 'Add new user'),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _firstNameTED,
                          labelText: 'First Name',
                          required: true,
                          validator: (value) => (value == null || value.trim().isEmpty) ? 'required' : null,
                        ),
                      ),
                      Spacing.w10,
                      Expanded(
                        child: AppTextField(controller: _lastNameTED, labelText: 'Last Name'),
                      ),
                    ],
                  ),
                  Spacing.h10,
                  PhoneNumberInput(
                    controller: _phoneNumberTED,
                    required: true,
                    initialCountryCode: _isoCode,
                    validator: (PhoneNumber? phone) {
                      try {
                        if (phone != null && phone.number.isEmpty && phone.isValidNumber()) {
                          return null;
                        } else {
                          return 'required';
                        }
                      } catch (_) {
                        return 'Invalid Mobile Number';
                      }
                    },
                    onChanged: (phone) {
                      _countryCode = phone.countryCode;
                      _isoCode = phone.countryISOCode;
                    },
                    onCountryChanged: (country) {
                      _countryCode = country.dialCode;
                      _isoCode = country.code;
                    },
                  ),
                  AppTextField(controller: _nickNameTED, labelText: 'Nick Name'),
                  Spacing.h10,
                  AppTextField(controller: _padiNoTED, labelText: 'Padi no', isStrictNumber: true),
                  Spacing.h20,
                  AppDropdownButton<Gender>(
                    items: Gender.values,
                    initialValue: _selectedGender,
                    hintText: "Gender *",
                    validator: (value) => value == null ? 'required' : null,
                    onChanged: (gender) => _selectedGender = gender,
                    itemLabel: (gender) => gender.label,
                  ),
                  Spacing.h20,
                  AppDropdownButton<Roles>(
                    items: Roles.values,
                    initialValue: _selectedRole,
                    hintText: "Role *",
                    validator: (value) => value == null ? 'required' : null,
                    onChanged: (role) => _selectedRole = role,
                    itemLabel: (roles) => roles.label,
                  ),
                  Spacing.h30,
                  Column(
                    children: AccessLevels.values
                        .map(
                          (accessLevel) => Row(
                            children: [
                              Expanded(
                                child: Text(
                                  accessLevel.label,
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ),
                              Switch(
                                value: _selectedAccessLevels.contains(accessLevel),
                                onChanged: (value) {
                                  setState(() {
                                    if (_selectedAccessLevels.contains(accessLevel)) {
                                      _selectedAccessLevels.remove(accessLevel);
                                    } else {
                                      _selectedAccessLevels.add(accessLevel);
                                    }
                                  });
                                },
                                activeThumbColor: Colors.black,
                                inactiveThumbColor: Colors.grey,
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                  Spacing.h30,
                  AppButton.flat(
                    text: editMode ? 'Update' : 'Add',
                    width: Screen.width,
                    showLoading: state is AddEditUserLoading,
                    onTap: () {
                      final Set<FormFieldState<Object?>> invalidFields =
                          _formKey.currentState?.validateGranularly() ?? {};
                      if (invalidFields.isNotEmpty) {
                        Scrollable.ensureVisible(
                          invalidFields.first.context,
                          duration: const Duration(milliseconds: 300),
                          alignment: 0.5,
                        );
                        return;
                      }

                      final newUser = User(
                        id: user?.id,
                        gender: _selectedGender!,
                        phoneNumber: _phoneNumberTED.text,
                        countryCode: _countryCode!,
                        isoCode: _isoCode!,
                        role: _selectedRole!,
                        firstName: _firstNameTED.text.capitalizeFirst(),
                        lastName: _lastNameTED.text.capitalizeFirst(),
                        nickName: _nickNameTED.text.capitalizeFirst(),
                        padiNo: _padiNoTED.text,
                        leaveStartDate: user?.leaveStartDate,
                        leaveEndDate: user?.leaveEndDate,
                        accessLevels: _selectedAccessLevels,
                      );
                      context.read<AddEditUserCubit>().onSubmit(context, newUser);
                    },
                  ),
                  Spacing.h30,
                ],
              ).paddingAll(20).scrollable,
            ),
          ),
        );
      },
    );
  }
}
