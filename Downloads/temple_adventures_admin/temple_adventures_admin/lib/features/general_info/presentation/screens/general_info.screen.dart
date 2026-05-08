import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:temple_adventures_admin/features/boats/presentation/widgets/counter_widget.dart';
import 'package:temple_adventures_admin/features/boats/repository/boats.repository.dart';
import 'package:temple_adventures_admin/features/bookings/presentation/widgets/custom_title.dart';
import 'package:temple_adventures_admin/features/general_info/enums/weights.enum.dart';
import 'package:temple_adventures_admin/utils/extensions/build_context.extensions.dart';
import 'package:temple_adventures_admin/utils/extensions/date_time.extensions.dart';
import 'package:temple_adventures_admin/utils/locator.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/spacing_widgets.dart';
import 'package:temple_adventures_admin/widgets/app_text_field.dart';
import 'package:temple_adventures_admin/widgets/custom_app_bar.dart';
import 'package:temple_adventures_admin/widgets/date_selector.dart';
import '../../../../utils/styling/app_measurements.dart';
import '../../../../widgets/app_button.dart';
import '../../../../widgets/custom_time_picker.dart';
import '../../../../widgets/key_value_pair.dart';
import '../../../../widgets/user_selection_tile.dart';
import '../../../boats/enums/user_type.enum.dart';
import '../../../boats/models/boat_info.model.dart';
import '../../../../widgets/loading_overlay.dart';
import '../../bloc/general_info.cubit.dart';
import '../../enums/bcd.enum.dart';
import '../../models/general_info.model.dart';

class GeneralInfoScreen extends StatefulWidget {
  const GeneralInfoScreen({super.key});

  static Route route() {
    return MaterialPageRoute<void>(builder: (_) => const GeneralInfoScreen());
  }

  @override
  State<GeneralInfoScreen> createState() => _GeneralInfoScreenState();
}

class _GeneralInfoScreenState extends State<GeneralInfoScreen> {
  DateTime _selectedDate = DateTime.now();

  // Equipment counts
  late Map<Bcd, int> _selectedBcd;
  late Map<Weights, int> _selectedWeights;
  late int _regulatorCount;
  late int _maskCount;
  late int _powerMaskCount;
  late int _finsCount;

  // Employees
  late List<TankInfo> _dsdPool;
  late List<TankInfo> _dsdOceanLeader;
  late List<TankInfo> _dsdCenterStaff;
  late List<TankInfo> _harbourStaff;
  late List<TankInfo> _dayOffs;
  late List<TankInfo> _leaves;

  // Notes
  late TextEditingController _powerNotesTED;
  late TextEditingController _notesTED;
  late TextEditingController _wavesTED;
  late TextEditingController _windsTED;
  late DateTime _lowTide;
  late DateTime _highTide;

  @override
  void initState() {
    super.initState();
    _defaultInitialization();
  }

  @override
  void dispose() {
    _powerNotesTED.dispose();
    _notesTED.dispose();
    _wavesTED.dispose();
    _windsTED.dispose();
    super.dispose();
  }

  void _defaultInitialization() {
    _selectedBcd = {for (var bcd in Bcd.values) bcd: 0};
    _selectedWeights = {for (var weight in Weights.values) weight: 0};
    _regulatorCount = 0;
    _maskCount = 0;
    _powerMaskCount = 0;
    _finsCount = 0;

    _dsdPool = [];
    _dsdOceanLeader = [];
    _dsdCenterStaff = [];
    _harbourStaff = [];
    _dayOffs = [];
    _leaves = [];

    _powerNotesTED = TextEditingController();
    _notesTED = TextEditingController();
    _wavesTED = TextEditingController();
    _windsTED = TextEditingController();
    _lowTide = DateTime.now();
    _highTide = DateTime.now();
  }

  void _populateFromGeneralInfo(GeneralInfo? generalInfo) {
    if (generalInfo == null) {
      _defaultInitialization();
      return;
    }

    setState(() {
      _dsdPool = generalInfo.dsdPool ?? [];
      _dsdOceanLeader = generalInfo.dsdOceanLeader ?? [];
      _dsdCenterStaff = generalInfo.dsdCenterStaff ?? [];
      _harbourStaff = generalInfo.harbourStaff ?? [];
      _dayOffs = generalInfo.dayOffs ?? [];
      _leaves = generalInfo.leaves ?? [];
      _selectedBcd = generalInfo.bcd ?? {};
      _selectedWeights = generalInfo.weights ?? {};

      _regulatorCount = generalInfo.regulator ?? 0;
      _maskCount = generalInfo.mask ?? 0;
      _powerMaskCount = generalInfo.powerMask ?? 0;
      _finsCount = generalInfo.fins ?? 0;

      _powerNotesTED.text = generalInfo.powerNotes ?? '';
      _notesTED.text = generalInfo.notes ?? '';
      _wavesTED.text = generalInfo.waves ?? '';
      _windsTED.text = generalInfo.winds ?? '';
      _lowTide = generalInfo.lowTide ?? DateTime.now();
      _highTide = generalInfo.highTide ?? DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (context) => GeneralInfoCubit(repository: locator<BoatsRepository>())..fetchGeneralInfoByDate(_selectedDate),
      child: BlocConsumer<GeneralInfoCubit, GeneralInfoState>(
        listener: (context, state) {
          final status = state.status;
          if (status is GeneralInfoSuccess) {
            context.showSnackBar('General Info Updated Successfully');
            Navigator.pop(context);
          }
          if (status is GeneralInfoLoaded) {
            _populateFromGeneralInfo(status.generalInfo);
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: const CustomAppBar(title: 'General Info', description: 'All Boats general info'),
            body: SafeArea(
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Spacing.h10,
                      DateSelector(
                        selectedDate: _selectedDate,
                        onDateChange: (newDate) {
                          setState(() {
                            _selectedDate = newDate;
                            context.read<GeneralInfoCubit>().fetchGeneralInfoByDate(_selectedDate);
                          });
                        },
                      ).paddingOnly(right: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CustomTitle(title: 'BCD :', fontSize: 14, fontWeight: FontWeight.w600),
                          Spacing.h5,
                          ...Bcd.values.map((item) {
                            return _EquipmentCounterRow(
                              label: item.label,
                              initialValue: _selectedBcd[item] ?? 0,
                              onChanged: (value) {
                                setState(() {
                                  _selectedBcd[item] = value; // store updated count
                                });
                              },
                            );
                          }),
                          Spacing.h25,
                          const CustomTitle(title: 'Regulator :', fontSize: 14, fontWeight: FontWeight.w600),
                          Spacing.h10,
                          CounterWidget(
                            initialValue: _regulatorCount,
                            onChanged: (newValue) {
                              setState(() {
                                _regulatorCount = newValue;
                              });
                            },
                          ),
                          Spacing.h25,
                          const CustomTitle(title: 'Mask :', fontSize: 14, fontWeight: FontWeight.w600),
                          Spacing.h10,
                          CounterWidget(
                            initialValue: _maskCount,
                            onChanged: (newValue) {
                              setState(() {
                                _maskCount = newValue;
                              });
                            },
                          ),
                          Spacing.h25,
                          const CustomTitle(title: 'Power Mask :', fontSize: 14, fontWeight: FontWeight.w600),
                          Spacing.h10,
                          Row(
                            children: [
                              Expanded(
                                child: CounterWidget(
                                  initialValue: _powerMaskCount,
                                  onChanged: (newValue) {
                                    setState(() {
                                      _powerMaskCount = newValue;
                                    });
                                  },
                                ),
                              ),
                              Spacing.w20,
                              Expanded(child: AppTextField(controller: _powerNotesTED, labelText: 'Power Notes')),
                            ],
                          ),
                          Spacing.h25,
                          const CustomTitle(title: 'Fins :', fontSize: 14, fontWeight: FontWeight.w600),
                          Spacing.h10,
                          CounterWidget(
                            initialValue: _finsCount,
                            onChanged: (newValue) {
                              setState(() {
                                _finsCount = newValue;
                              });
                            },
                          ),
                          Spacing.h25,
                          const CustomTitle(title: 'Weights :', fontSize: 14, fontWeight: FontWeight.w600),
                          Spacing.h5,
                          ...Weights.values.map((item) {
                            return _EquipmentCounterRow(
                              label: item.label,
                              initialValue: _selectedWeights[item] ?? 0,
                              onChanged: (value) {
                                setState(() {
                                  _selectedWeights[item] = value;
                                });
                              },
                            );
                          }),
                          Spacing.h25,
                          ..._buildEmployeeButtons(),
                          AppTextField(controller: _notesTED, labelText: 'General Notes'),
                          Spacing.h25,
                          const CustomTitle(title: 'Weather :', fontSize: 14, fontWeight: FontWeight.w600),
                          Spacing.h25,
                          _buildTideTimePicker(title: 'Low Tide', time: _lowTide, onTap: () => _pickTideTime(true)),
                          Spacing.h25,
                          _buildTideTimePicker(title: 'High Tide', time: _highTide, onTap: () => _pickTideTime(false)),
                          Spacing.h25,
                          AppTextField(
                            controller: _wavesTED,
                            labelText: 'Waves',
                            suffixText: 'm',
                            keyboardType: TextInputType.numberWithOptions(signed: true),
                          ),
                          Spacing.h25,
                          AppTextField(
                            controller: _windsTED,
                            labelText: 'Winds',
                            suffixText: 'km/hr',
                            keyboardType: TextInputType.numberWithOptions(signed: true),
                          ),
                          Spacing.h50,
                          AppButton.flat(
                            width: Screen.width,
                            text:
                                ((state.status is GeneralInfoLoaded) &&
                                        (state.status as GeneralInfoLoaded).generalInfo?.id != null)
                                    ? 'Update'
                                    : 'Submit',
                            showLoading: state.status is GeneralInfoLoading,
                            onTap: () {
                              final generalInfo = GeneralInfo(
                                id:
                                    state.status is GeneralInfoLoaded
                                        ? (state.status as GeneralInfoLoaded).generalInfo?.id
                                        : null,
                                bcd: _selectedBcd,
                                date: _selectedDate.formatDDMMYYYY,
                                regulator: _regulatorCount,
                                mask: _maskCount,
                                powerMask: _powerMaskCount,
                                powerNotes: _powerNotesTED.text,
                                fins: _finsCount,
                                weights: _selectedWeights,
                                dsdPool: _dsdPool.map((tank) => tank.copyWith(role: Role.dsdPool)).toList(),
                                dsdOceanLeader:
                                    _dsdOceanLeader.map((tank) => tank.copyWith(role: Role.dsdOceanLeader)).toList(),
                                dsdCenterStaff:
                                    _dsdCenterStaff.map((tank) => tank.copyWith(role: Role.dsdCenterStaff)).toList(),
                                harbourStaff:
                                    _harbourStaff.map((tank) => tank.copyWith(role: Role.harbourStaff)).toList(),
                                dayOffs: _dayOffs.map((tank) => tank.copyWith(role: Role.dayOffs)).toList(),
                                leaves: _leaves.map((tank) => tank.copyWith(role: Role.leaves)).toList(),
                                notes: _notesTED.text,
                                lowTide: _lowTide,
                                highTide: _highTide,
                                waves: _wavesTED.text,
                                winds: _windsTED.text,
                              );

                              context.read<GeneralInfoCubit>().onSubmit(generalInfo);
                            },
                          ),
                        ],
                      ).paddingAll(20),
                    ],
                  ).scrollable,
                  if (state.status is GeneralInfoLoading) const LoadingOverlay(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildEmployeeButtons() {
    return [
      const CustomTitle(title: 'Employees :', fontSize: 14, fontWeight: FontWeight.w600),
      Spacing.h25,
      UserSelectorTile(
        title: 'DSD Pool',
        selectedUsers: _dsdPool,
        tanksRequired: false,
        userType: UserType.showAllUsers,
        onUsersSelected: (users) => setState(() => _dsdPool = users),
      ),
      UserSelectorTile(
        title: 'DSD Ocean Leader',
        selectedUsers: _dsdOceanLeader,
        tanksRequired: false,
        userType: UserType.showAllUsers,
        onUsersSelected: (users) => setState(() => _dsdOceanLeader = users),
      ),
      UserSelectorTile(
        title: 'DSD Center Staff',
        selectedUsers: _dsdCenterStaff,
        tanksRequired: false,
        userType: UserType.showAllUsers,
        onUsersSelected: (users) => setState(() => _dsdCenterStaff = users),
      ),
      UserSelectorTile(
        title: 'Harbour Staff',
        selectedUsers: _harbourStaff,
        tanksRequired: false,
        userType: UserType.showAllUsers,
        onUsersSelected: (users) => setState(() => _harbourStaff = users),
      ),
      UserSelectorTile(
        title: 'Day Offs',
        selectedUsers: _dayOffs,
        tanksRequired: false,
        userType: UserType.showAllUsers,
        onUsersSelected: (users) => setState(() => _dayOffs = users),
      ),
      UserSelectorTile(
        title: 'Leaves',
        selectedUsers: _leaves,
        tanksRequired: false,
        userType: UserType.showAllUsers,
        onUsersSelected: (users) => setState(() => _leaves = users),
      ),
    ];
  }

  Widget _buildTideTimePicker({required String title, required DateTime time, required VoidCallback onTap}) {
    return KeyValuePair(
      title: title,
      titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      widget: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 30,
          width: 100,
          decoration: BoxDecoration(border: Border.all(color: Colors.black), borderRadius: BorderRadius.circular(5)),
          child: Text(time.formatHHMM, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)).center,
        ),
      ),
    );
  }

  void _pickTideTime(bool isLowTide) async {
    final picked = await TimePicker.show(context, initialTime: isLowTide ? _lowTide : _highTide);
    if (picked != null) {
      setState(() {
        if (isLowTide) {
          _lowTide = picked;
        } else {
          _highTide = picked;
        }
      });
    }
  }
}

class _EquipmentCounterRow extends StatelessWidget {
  final String label;
  final int initialValue;
  final ValueChanged<int>? onChanged;

  const _EquipmentCounterRow({required this.label, required this.initialValue, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Spacing.w10,
        SizedBox(
          width: 30,
          child: CustomTitle(title: label, fontSize: 14, fontWeight: FontWeight.w600),
        ).paddingOnly(top: 15),
        Spacing.w20,
        CounterWidget(
          initialValue: initialValue,
          onChanged: (value) {
            if (onChanged != null) {
              onChanged!(value);
            }
          },
        ),
      ],
    );
  }
}
