import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:temple_adventures_admin/utils/extensions/date_time.extensions.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/spacing_widgets.dart';
import 'package:temple_adventures_admin/widgets/app_button.dart';
import 'package:temple_adventures_admin/widgets/app_text_field.dart';
import 'package:temple_adventures_admin/widgets/custom_date_range_picker.dart';
import 'package:temple_adventures_admin/widgets/tag_chip.dart';

import '../../../../theme.dart';
import '../../../../utils/mixins/status_bar_handler_mixin.dart';
import '../../../../widgets/user_selection.modal.dart';
import '../../../activities/bloc/all_activities.cubit.dart';
import '../../../activities/models/activity.model.dart';
import '../../../user/models/user.model.dart';
import '../../models/all_bookings_filter.model.dart';
import 'all_bookings.screen.dart';

class AllBookingsFiltersScreen extends StatefulWidget {
  const AllBookingsFiltersScreen({super.key});

  static MaterialPageRoute<dynamic> route() => MaterialPageRoute(builder: (_) => const AllBookingsFiltersScreen());

  @override
  State<AllBookingsFiltersScreen> createState() => _AllBookingsFiltersScreenState();
}

class _AllBookingsFiltersScreenState extends State<AllBookingsFiltersScreen>
    with RouteAware, StatusBarHandlerMixin<AllBookingsFiltersScreen> {
  final TextEditingController _searchTED = TextEditingController();
  final TextEditingController _noOfPaxTED = TextEditingController();

  // Filter state
  String? _searchQuery;
  List<User> _selectedUsers = [];
  DateTimeRange? _dateRange;
  List<Activity> _selectedActivities = [];
  int? _noOfPax;

  bool isQuickBookingOnly = false;

  @override
  void dispose() {
    _searchTED.dispose();
    _noOfPaxTED.dispose();
    super.dispose();
  }

  void _clearAllFilters() {
    setState(() {
      _searchQuery = null;
      _selectedUsers = [];
      _dateRange = null;
      _selectedActivities = [];
      _noOfPax = null;
      isQuickBookingOnly = false;
    });
    _searchTED.clear();
    _noOfPaxTED.clear();
  }

  void _submitFilters() {
    final filters = AllBookingsFilters(
      searchQuery: _searchQuery,
      createdBy: _selectedUsers,
      activities: _selectedActivities,
      dateRange: _dateRange != null ? [_dateRange!.start, _dateRange!.end] : null,
      isQuickBooking: isQuickBookingOnly,
      noOfPax: _noOfPax,
    );

    Navigator.push(context, AllBookingsScreen.route(filters));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ColoredBox(
          color: Colors.white,
          child:
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Spacing.h100,
                  Text('Query Bookings', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)).center,
                  Text(
                    'Apply filters to find specific bookings',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  ).center,
                  Spacing.h50,
                  // Search Query Filter
                  AppTextField(
                    controller: _searchTED,
                    labelText: 'Search by Booking ID',
                    hintText: 'Search',
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.isEmpty ? null : value;
                      });
                    },
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                    ),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                    isStrictNumber: true,
                  ),
                  Spacing.h30,
                  buildSelectedUsers(),
                  buildSelectedActivities(),
                  buildDateRange(),
                  Spacing.h8,
                  Row(
                    children: [
                      Text('Show quick bookings only'),
                      const Spacer(),
                      SizedBox(
                        width: 70,
                        child: Switch(
                          activeThumbColor: skyBlueColor,
                          inactiveThumbColor: Colors.grey,
                          value: isQuickBookingOnly,
                          onChanged: (value) {
                            setState(() {
                              isQuickBookingOnly = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  Spacing.h8,
                  Row(
                    children: [
                      Text('No of persons'),
                      const Spacer(),
                      AppTextField(
                        controller: _noOfPaxTED,
                        isStrictNumber: true,
                        width: 100,
                        onChanged: (value) {
                          setState(() {
                            _noOfPax = int.tryParse(value);
                          });
                        },
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                        ),
                      ),
                    ],
                  ),
                  Spacing.h32,
                  Row(
                    children: [
                      Expanded(child: AppButton.flat(text: 'Clear All', onTap: _clearAllFilters)),
                      const SizedBox(width: 16),
                      Expanded(child: AppButton.flat(text: 'Apply Filters', onTap: _submitFilters)),
                    ],
                  ),
                  Spacing.h32,
                ],
              ).paddingHorizontal(16).scrollable,
        ),
      ),
    );
  }

  Widget buildSelectedUsers() {
    return Column(
      children: [
        Row(
          children: [
            const Text('Created By'),
            const Spacer(),
            AppButton.miniFlat(
              text: 'Select',
              onTap: () async {
                final selected = await UserSelectionModal.selectMultiple(context, selectedUsers: _selectedUsers);

                if (selected != null) {
                  setState(() {
                    _selectedUsers = selected;
                  });
                }
              },
            ),
          ],
        ),
        Spacing.h20,
        Wrap(
          spacing: 10,
          alignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.start,
          children:
              _selectedUsers.map((user) {
                return TagChip(
                  title: user.fullName,
                  onTap: () {
                    setState(() {
                      _selectedUsers.remove(user);
                    });
                  },
                ).paddingOnly(bottom: 10);
              }).toList(),
        ).left,
      ],
    );
  }

  Widget buildSelectedActivities() {
    return Column(
      children: [
        Row(
          children: [
            const Text('Activities'),
            const Spacer(),
            AppButton.miniFlat(
              text: 'Select',
              onTap: () async {
                final result = await _ActivitySelectionModal.show(
                  context,
                  selectedActivities: _selectedActivities,
                );

                if (result != null) {
                  setState(() {
                    _selectedActivities = result;
                  });
                }
              },
            ),
          ],
        ),
        Spacing.h20,
        Wrap(
          spacing: 10,
          alignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.start,
          children:
              _selectedActivities.map((activity) {
                return TagChip(
                  title: activity.name,
                  onTap: () {
                    setState(() {
                      _selectedActivities.remove(activity);
                    });
                  },
                ).paddingOnly(bottom: 10);
              }).toList(),
        ).left,
      ],
    );
  }

  Widget buildDateRange() {
    return Column(
      children: [
        Row(
          children: [
            const Text('Date'),
            const Spacer(),
            AppButton.miniFlat(
              text: _dateRange != null ? 'Change' : 'Select',
              onTap: () async {
                final selectedRange = await DateRangePickerHelper.pickDateRange(context);
                if (selectedRange != null) {
                  setState(() {
                    _dateRange = selectedRange;
                  });
                }
              },
            ),
          ],
        ),
        if (_dateRange != null)
          TagChip(
            title: '${_dateRange!.start.formatDDMMYYYY} - ${_dateRange!.end.formatDDMMYYYY}',
            onTap: () {
              setState(() {
                _dateRange = null;
              });
            },
          ).paddingOnly(bottom: 10, top: 20).left,
      ],
    );
  }
}

class _ActivitySelectionModal extends StatefulWidget {
  final List<Activity> selectedActivities;

  const _ActivitySelectionModal({required this.selectedActivities});

  static Future<List<Activity>?> show(BuildContext context, {required List<Activity> selectedActivities}) {
    return showModalBottomSheet<List<Activity>>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,

      backgroundColor: Colors.transparent,
      builder: (_) => _ActivitySelectionModal(selectedActivities: selectedActivities),
    );
  }

  @override
  State<_ActivitySelectionModal> createState() => _ActivitySelectionModalState();
}

class _ActivitySelectionModalState extends State<_ActivitySelectionModal> {
  late List<Activity> _tempSelectedActivities;

  @override
  void initState() {
    super.initState();
    _tempSelectedActivities = List.from(widget.selectedActivities);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AllActivitiesCubit>().fetchAllActivities();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
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
              const Text('Select Activities', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          Spacing.h20,

          // Activities list
          Expanded(
            child: BlocBuilder<AllActivitiesCubit, AllActivitiesState>(
              builder: (context, state) {
                return state.status.when(
                  initial: () => const SizedBox.shrink(),
                  loading: () => CircularProgressIndicator().center,
                  error: (message) => Text('Error: $message', style: TextStyle(color: Colors.red)).center,
                  loaded: () {
                    final activities = state.activities;
                    if (activities.isEmpty) {
                      return Text('No activities available').center;
                    }

                    return ListView.builder(
                      itemCount: activities.length,
                      padding: const EdgeInsets.only(bottom: 16),
                      itemBuilder: (context, index) {
                        final activity = activities[index];
                        final isSelected = _tempSelectedActivities.contains(activity);

                        return CheckboxListTile(
                          title: Text(activity.name),
                          subtitle: Text('₹${activity.price}'),
                          value: isSelected,
                          dense: true,
                          onChanged: (selected) {
                            setState(() {
                              if (selected == true) {
                                _tempSelectedActivities.add(activity);
                              } else {
                                _tempSelectedActivities.remove(activity);
                              }
                            });
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),

          Spacing.h20,

          // Action Buttons
          Row(
            children: [
              Expanded(child: AppButton.flat(text: 'Cancel', onTap: () => Navigator.pop(context))),
              const SizedBox(width: 16),
              Expanded(
                child: AppButton.flat(text: 'Apply', onTap: () => Navigator.pop(context, _tempSelectedActivities)),
              ),
            ],
          ),
        ],
      ).paddingAll(20),
    );
  }
}
