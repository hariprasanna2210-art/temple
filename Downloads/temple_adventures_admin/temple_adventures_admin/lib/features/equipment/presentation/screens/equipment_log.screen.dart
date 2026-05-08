import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:temple_adventures_admin/features/equipment/bloc/equipment_log.cubit.dart';
import 'package:temple_adventures_admin/features/equipment/model/enriched_equipment_logs.model.dart';
import 'package:temple_adventures_admin/features/equipment/presentation/screens/equipment_log_details.screen.dart';
import 'package:temple_adventures_admin/features/user/bloc/all_users.cubit.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';
import 'package:temple_adventures_admin/widgets/custom_app_bar.dart';
import 'package:temple_adventures_admin/widgets/empty_state_message.dart';
import 'package:temple_adventures_admin/widgets/loading_overlay.dart';

import '../../../../utils/styling/app_measurements.dart';
import '../../../../utils/styling/spacing_widgets.dart';

class EquipmentLogScreen extends StatefulWidget {
  const EquipmentLogScreen({super.key});

  static MaterialPageRoute<dynamic> route() => MaterialPageRoute(builder: (_) => const EquipmentLogScreen());

  @override
  State<EquipmentLogScreen> createState() => _EquipmentLogScreenState();
}

class _EquipmentLogScreenState extends State<EquipmentLogScreen> {
  late final TextEditingController _searchController;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    context.read<EquipmentLogCubit>().fetchEquipmentLogs();
  }

  @override
  void dispose() {
    timer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Equipment Logs',
        description: 'All equipment rental logs done by our team',
      ),
      body: BlocBuilder<EquipmentLogCubit, EquipmentLogState>(
        builder: (context, state) {
          if (state.status is EquipmentLogLoading) {
            return const LoadingOverlay();
          }

          if (state.status is EquipmentLogError) {
            return EmptyStateMessage(message: (state.status as EquipmentLogError).message).center;
          }
          final filteredLogs =
              state.logs.where((log) {
                final query = _searchController.text.toLowerCase();
                return query.isEmpty || log.renterName.toString().toLowerCase().contains(query);
              }).toList();
          if (filteredLogs.isEmpty) {
            return EmptyStateMessage(message: 'No logs found');
          }
          return Column(
            children: [
              Spacing.h24,
              _buildSearchBar(),
              Spacing.h24,
              Expanded(
                child:
                    filteredLogs.isEmpty
                        ? const Center(child: Text('No logs found.'))
                        : ListView.builder(
                          itemCount: filteredLogs.length,
                          itemBuilder: (context, index) {
                            final log = filteredLogs[index];
                            return _EquipmentLog(log: log);
                          },
                        ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      width: 328,
      height: 47,
      decoration: BoxDecoration(
        color: const Color(0xffEFFDFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xff7D7D7D)),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 15),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  hintText: 'Search',
                  hintStyle: TextStyle(
                    height: 1,
                    color: Color(0xff7D7D7D),
                  ),
                ),
                onChanged: (_) {
                  timer?.cancel();
                  timer = Timer(const Duration(milliseconds: 250), () {
                    setState(() {}); // refresh filtering
                  });
                },
              ),
            ),
            const Icon(Icons.search, color: Color(0xff7D7D7D)),
          ],
        ),
      ),
    );
  }
}

class _EquipmentLog extends StatelessWidget {
  final EnrichedEquipmentLogs log;

  const _EquipmentLog({required this.log});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AllUsersCubit, AllUsersState>(
      builder: (context, usersState) {
        bool delayedReturn = false;
        int dueDays = 0;

        if (log.collectorPersonId == null) {
          final takeTime = log.rentedTime;
          final diff = DateTime.now().difference(takeTime);
          if (diff.inDays > 1) {
            delayedReturn = true;
            dueDays = diff.inDays;
          }
        }

        return InkWell(
          onTap: () => Navigator.push(context, EquipmentLogDetailsScreen.route(log)),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    height: 50,
                    width: 61,
                    decoration: BoxDecoration(
                      color:
                          log.collectorPersonId != null
                              ? Colors.green.withOpacity(0.34)
                              : const Color(0xffD1F8FF).withOpacity(0.34),
                      borderRadius: BorderRadius.circular(16),
                      border: delayedReturn ? Border.all(color: Colors.red.shade700, width: 3) : null,
                    ),
                    child:
                        Text(
                          log.logId.toString(),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ).center,
                  ),
                  Spacing.w16,
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            text: log.renterName,
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              fontSize: 16,
                            ),
                            children: <TextSpan>[
                              const TextSpan(text: ' rented ', style: TextStyle(fontWeight: FontWeight.normal)),
                              TextSpan(text: log.equipmentItems.length.toString()),
                              TextSpan(
                                text: ' item${log.equipmentItems.length == 1 ? '' : 's'}',
                                style: const TextStyle(fontWeight: FontWeight.normal),
                              ),
                            ],
                          ),
                        ),
                        Spacing.h4,
                        RichText(
                          text: TextSpan(
                            text: log.approverName,
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.bold,
                              color: Color(0xff7D7D7D),
                              fontSize: 12,
                            ),
                            children: <TextSpan>[
                              const TextSpan(text: ' approved on ', style: TextStyle(fontWeight: FontWeight.normal)),
                              TextSpan(
                                text: DateFormat('MMM dd, yyyy hh:mm a').format(log.rentedTime),
                              ),
                            ],
                          ),
                        ),
                        if (delayedReturn)
                          Text(
                            'Not returned for $dueDays days',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              color: Colors.red.shade700,
                              fontSize: 14,
                            ),
                          ),
                        if (log.collectorPersonId != null) ...[
                          Spacing.h4,
                          RichText(
                            text: TextSpan(
                              text: '${log.collectorName}',
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.bold,
                                color: Color(0xff7D7D7D),
                                fontSize: 12,
                              ),
                              children: <TextSpan>[
                                const TextSpan(
                                  text: ' verified return on ',
                                  style: TextStyle(fontWeight: FontWeight.normal),
                                ),
                                TextSpan(text: DateFormat('MMM dd, yyyy hh:mm a').format(log.collectedTime!)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ).width(Screen.width),
                  ),
                ],
              ).paddingSymmetric(horizontal: 26, vertical: 8),
              const Divider().paddingHorizontal(30),
            ],
          ),
        );
      },
    );
  }
}
