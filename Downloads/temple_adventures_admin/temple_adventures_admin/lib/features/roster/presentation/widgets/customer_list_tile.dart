import 'package:flutter/material.dart';
import 'package:temple_adventures_admin/features/roster/models/customer_feedback.model.dart';
import 'package:temple_adventures_admin/features/roster/models/dsd_customer.model.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';

import '../../../../theme.dart';
import '../../../../utils/styling/spacing_widgets.dart';
import '../../models/roster.model.dart';
import 'customer_feedback.modal.dart';

class CustomerListTile extends StatelessWidget {
  final DSDCustomer customer;
  final VoidCallback onTap;

  const CustomerListTile({super.key, required this.customer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 50,
                width: 50,
                decoration: const BoxDecoration(
                  color: skyBlueColor,
                  shape: BoxShape.circle,
                ),
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Text(
                    '${customer.bookingId}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ).center.paddingAll(10),
                ),
              ),
              Spacing.w20,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.fullName,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),

                  if (customer.roster?.instructor?.firstName != null)
                    Text(
                      customer.roster?.instructor?.fullName ?? customer.roster?.instructor?.firstName ?? '-',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: disabledGrey,
                      ),
                    ).paddingOnly(top: 5),
                ],
              ),
              const Spacer(),

              if (customer.roster != null) _Icon(roster: customer.roster, customerFeedback: customer.customerFeedback),

              if (customer.customerFeedback == null)
                IconButton(
                  onPressed: () async {
                    await CustomerFeedbackModal.show(
                      context,
                      customerFeedback: customer.customerFeedback,
                      bookingId: customer.bookingId!,
                      customerId: customer.customerId!,
                    );
                  },
                  icon: const Icon(Icons.assignment),
                ),
            ],
          ),
          const Divider(),
        ],
      ),
    ).paddingOnly(bottom: 10);
  }
}

class _Icon extends StatelessWidget {
  final Roster? roster;
  final CustomerFeedback? customerFeedback;

  const _Icon({this.roster, this.customerFeedback});

  @override
  Widget build(BuildContext context) {
    if (roster == null) return const SizedBox();

    if (roster?.instructor != null && roster?.timeIn != null && roster?.timeOut != null && customerFeedback != null) {
      return const Icon(
        Icons.check_circle,
        color: Colors.green,
        size: 20,
      );
    }

    if (roster?.timeIn != null && roster?.timeOut != null) {
      return const Icon(
        Icons.directions_boat,
        color: skyBlueColor,
        size: 20,
      );
    }

    if (roster?.timeIn != null) {
      return const Icon(
        Icons.scuba_diving_rounded,
        color: Colors.orange,
        size: 20,
      );
    }

    return const SizedBox();
  }
}
