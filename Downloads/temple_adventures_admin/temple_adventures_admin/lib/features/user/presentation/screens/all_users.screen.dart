import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:temple_adventures_admin/features/user/presentation/screens/user_details.screen.dart';
import 'package:temple_adventures_admin/utils/extensions/build_context.extensions.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';

import '../../../../theme.dart';
import '../../../../utils/access_levels.dart';
import '../../../../utils/debouncer.dart';
import '../../../../widgets/app_text_field.dart';
import '../../../../widgets/custom_app_bar.dart';
import '../../../../widgets/custom_floating_action_button.dart';
import '../../../../widgets/loading_overlay.dart';
import '../../bloc/all_users.cubit.dart';
import '../../enums/access_levels.enum.dart';
import '../../models/user.model.dart';
import 'add_edit_user.screen.dart';

class AllUsersScreen extends StatefulWidget {
  const AllUsersScreen({super.key});

  static MaterialPageRoute<dynamic> route() => MaterialPageRoute(builder: (_) => const AllUsersScreen());

  @override
  State<AllUsersScreen> createState() => _AllUsersScreenState();
}

class _AllUsersScreenState extends State<AllUsersScreen> {
  late final TextEditingController _searchTED;
  late final Debouncer _searchUpdateDebouncer;

  @override
  void initState() {
    super.initState();
    _searchTED = TextEditingController();
    _searchUpdateDebouncer = Debouncer();
    // Only fetch if list is empty (first load)
    final currentState = context.read<AllUsersCubit>().state;
    if (currentState.users.isEmpty) {
      context.read<AllUsersCubit>().fetchAllUsers();
    }
  }

  @override
  void dispose() {
    _searchTED.dispose();
    _searchUpdateDebouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'All Users', description: 'All Company Users'),
      floatingActionButton: AccessLevelWidget(
        accessLevel: AccessLevels.addUser,
        child: CustomFloatingActionButton(onTap: () => Navigator.push(context, AddEditUserScreen.route())),
      ),
      body: SafeArea(
        child: BlocConsumer<AllUsersCubit, AllUsersState>(
          listener: (context, state) {
            if (state.status is AllUsersStateError) {
              context.showSnackBar((state.status as AllUsersStateError).message);
            }
          },
          builder: (context, state) => state.status.when(
            initial: () => const LoadingOverlay(),
            loading: () => const LoadingOverlay(),
            loaded: () => Column(
              children: [
                AppTextField(
                  controller: _searchTED,
                  onChanged: (_) => _searchUpdateDebouncer(() => setState(() {})),
                  labelText: 'Search for number or name',
                  border: const OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                ).paddingAll(20),
                Expanded(child: _UserList(state.users, _searchTED.text.toLowerCase())),
              ],
            ),
            error: (error) => Text(error).center,
          ),
        ),
      ),
    );
  }
}

class _UserList extends StatelessWidget {
  final List<User> users;
  final String query;
  const _UserList(
    this.users,
    this.query,
  );

  @override
  Widget build(BuildContext context) {
    // Remove deleted users from the list
    List<User> filteredUsers = users.where((user) => !user.isDeleted).toList();

    // Show only users that match the search query
    if (query.isNotEmpty) {
      filteredUsers = filteredUsers.where((user) {
        final name = '${user.firstName} ${user.lastName ?? ''}'.toLowerCase();
        final phone = user.phoneNumber.toLowerCase();
        return name.contains(query) || phone.contains(query);
      }).toList();
    }

    if (filteredUsers.isEmpty) {
      return const Text('No users match your search').center;
    }

    return ListView.builder(
      itemCount: filteredUsers.length,
      physics: BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final user = filteredUsers[index];
        return _UserListTile(user);
      },
    );
  }
}

class _UserListTile extends StatelessWidget {
  final User user;
  const _UserListTile(this.user);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        context.closeKeyboard();
        Navigator.push(context, UserDetailsScreen.route(user));
      },
      child: Card(
        elevation: 0,
        color: Colors.transparent,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: user.isDeleted ? Colors.red : skyBlueColor,
            child: Text(user.firstName[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
          ),
          title: Text('${user.firstName} ${user.lastName ?? ''}', style: const TextStyle(fontSize: 14)),
          subtitle: Text(user.phoneNumber, style: const TextStyle(fontSize: 12)),
        ),
      ),
    );
  }
}
