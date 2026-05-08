import 'package:flutter/material.dart';
import 'package:temple_adventures_admin/features/bookings/models/customer.model.dart';
import 'package:temple_adventures_admin/features/bookings/presentation/widgets/custom_title.dart';
import 'package:temple_adventures_admin/features/bookings/repository/bookings.repository.dart';
import 'package:temple_adventures_admin/theme.dart';
import 'package:temple_adventures_admin/utils/extensions/build_context.extensions.dart';
import 'package:temple_adventures_admin/utils/locator.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';
import 'package:temple_adventures_admin/widgets/app_button.dart';

import '../../../../utils/styling/app_measurements.dart';
import '../../../../utils/styling/spacing_widgets.dart';
import '../../../../widgets/custom_alert_dialog.dart';
import '../../../../widgets/modal_wrapper.dart';
import '../../models/booking.model.dart';
import '../screens/add_customer_details.screen.dart';

class ManagePaxModal extends StatefulWidget {
  const ManagePaxModal({
    super.key,
    required this.booking,
  });

  final Booking booking;

  static Future<List<Customer>?> show(BuildContext context, {required Booking booking, x}) async {
    return await showModalBottomSheet<List<Customer>>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) {
        return ManagePaxModal(
          booking: booking,
        );
      },
    );
  }

  @override
  State<ManagePaxModal> createState() => _ManagePaxModalState();
}

class _ManagePaxModalState extends State<ManagePaxModal> {
  List<Customer> allCustomers = [];
  Set<int> deletingCustomerIds = {};

  @override
  void initState() {
    super.initState();
    allCustomers = widget.booking.pax ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return ModalWrapper(
      child: SafeArea(
        child: Container(
          width: Screen.width,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(16),
              topLeft: Radius.circular(16),
            ),
            color: lightBlueColor,
          ),
          child:
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildHeader(),
                  Spacing.h30,
                  ...allCustomers.map((customer) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                customer.email ?? '',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                            (customer.id == widget.booking.primaryCustomer.id)
                                ? SizedBox()
                                : IconButton(
                                  onPressed: () async {
                                    final shouldDelete = await CustomAlertDialog.show(
                                      context,
                                      title: 'Are you sure',
                                      content: 'Customer will be removed from this booking',
                                    );

                                    if (shouldDelete == true && context.mounted) {
                                      setState(() {
                                        deletingCustomerIds.add(customer.id!);
                                      });

                                      try {
                                        // Get repository directly from locator
                                        final repository = locator<BookingsRepository>();

                                        // Call delete function
                                        await repository.deleteCustomer(widget.booking.id!, customer.id!);

                                        // Update local state
                                        setState(() {
                                          allCustomers.remove(customer);
                                          deletingCustomerIds.remove(customer.id!);
                                        });

                                        // Show success message
                                        if (context.mounted) {
                                          context.showSnackBar('Customer removed successfully');
                                        }
                                      } catch (e) {
                                        setState(() {
                                          deletingCustomerIds.remove(customer.id!);
                                        });

                                        // Show error message
                                        if (context.mounted) {
                                          context.showSnackBar('Failed to remove customer: $e');
                                        }
                                      }
                                    }
                                  },
                                  icon:
                                      (deletingCustomerIds.contains(customer.id))
                                          ? CircularProgressIndicator(
                                            color: Colors.black,
                                            strokeWidth: 2,
                                          ).size(20, 20)
                                          : Icon(Icons.delete, size: 20, color: Colors.black),
                                ).right,
                          ],
                        ),
                        if ((customer.paperWorkPdfPath ?? '').isNotEmpty)
                          CustomTitle(
                            title: 'Paperwork completed',
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ).paddingOnly(top: 5),
                      ],
                    );
                  }),
                  Spacing.h30,
                  if (allCustomers.length < widget.booking.noOfPersons)
                    AppButton.miniFlat(
                      text: 'Add Customer',
                      onTap: () async {
                        // Get existing customer emails
                        final existingEmails =
                            allCustomers
                                .map((customer) => customer.email?.toLowerCase() ?? '')
                                .where((email) => email.isNotEmpty)
                                .toList();

                        final Customer? newCustomer = await Navigator.push<Customer>(
                          context,
                          AddCustomerDetailsScreen.addNewPaxRoute(
                            widget.booking.id!,
                            existingEmails: existingEmails,
                          ),
                        );
                        if (newCustomer != null) {
                          setState(() {
                            allCustomers.add(newCustomer);
                          });
                        }
                      },
                    ),
                ],
              ).paddingSymmetric(horizontal: 20).scrollable,
        ).paddingOnly(bottom: MediaQuery.of(context).viewInsets.bottom),
      ),
    );
  }

  Widget buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const Text(
          'Manage Pax',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ).paddingOnly(top: 8),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () async {
            Navigator.pop(context, allCustomers);
          },
        ),
      ],
    );
  }
}
