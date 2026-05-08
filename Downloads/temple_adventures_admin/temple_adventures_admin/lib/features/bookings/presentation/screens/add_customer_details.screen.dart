import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:temple_adventures_admin/features/bookings/bloc/add_customer_details.cubit.dart';
import 'package:temple_adventures_admin/features/bookings/models/customer.model.dart';
import 'package:temple_adventures_admin/features/bookings/presentation/screens/select_activity_session.screen.dart';
import 'package:temple_adventures_admin/features/bookings/repository/bookings.repository.dart';
import 'package:temple_adventures_admin/utils/extensions/build_context.extensions.dart';
import 'package:temple_adventures_admin/utils/extensions/string.extensions.dart';
import 'package:temple_adventures_admin/utils/locator.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';

import '../../../../utils/styling/spacing_widgets.dart';
import '../../../../widgets/app_button.dart';
import '../../../../widgets/app_dropdown.dart';
import '../../../../widgets/app_text_field.dart';
import '../../../../widgets/custom_app_bar.dart';
import '../../../../widgets/phone_number.dart';
import '../../../user/enums/gender.enum.dart';

class AddCustomerDetailsScreen extends StatefulWidget {
  const AddCustomerDetailsScreen({
    super.key,
    required this.shouldAddNewPax,
    this.bookingId,
    this.existingEmails,
  });

  final bool shouldAddNewPax;
  final int? bookingId;
  final List<String>? existingEmails;

  static MaterialPageRoute route() {
    return MaterialPageRoute(
      builder: (_) {
        return BlocProvider(
          create: (context) => AddCustomerDetailsCubit(repository: locator<BookingsRepository>()),
          child: AddCustomerDetailsScreen(shouldAddNewPax: false),
        );
      },
    );
  }

  static MaterialPageRoute<Customer> addNewPaxRoute(int bookingId, {List<String>? existingEmails}) {
    return MaterialPageRoute<Customer>(
      builder: (_) {
        return BlocProvider(
          create: (context) => AddCustomerDetailsCubit(repository: locator<BookingsRepository>()),
          child: AddCustomerDetailsScreen(
            shouldAddNewPax: true,
            bookingId: bookingId,
            existingEmails: existingEmails,
          ),
        );
      },
    );
  }

  @override
  State<AddCustomerDetailsScreen> createState() => _AddCustomerDetailsScreenState();
}

class _AddCustomerDetailsScreenState extends State<AddCustomerDetailsScreen> {
  late final TextEditingController _firstNameTED, _lastNameTED, _emailTED, _phoneNumberTED;
  Gender? _selectedGender;
  String? _countryCode;
  String? _isoCode;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _firstNameTED = TextEditingController();
    _lastNameTED = TextEditingController();
    _emailTED = TextEditingController();
    _phoneNumberTED = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameTED.dispose();
    _lastNameTED.dispose();
    _emailTED.dispose();
    _phoneNumberTED.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AddCustomerDetailsCubit, AddCustomerDetailsState>(
      listener: (context, state) {
        final status = state.status;
        if (status is AddCustomerDetailsSuccess && status.updateFields) {
          final existingCustomer = state.customer;

          if (existingCustomer == null) {
            context.showSnackBar('Customer does not exist');
            return;
          }

          _firstNameTED.text = existingCustomer.firstName;
          _lastNameTED.text = existingCustomer.lastName ?? '';
          _phoneNumberTED.text = existingCustomer.phoneNumber ?? '';
          _countryCode = existingCustomer.countryCode;
          _isoCode = existingCustomer.isoCode;
          _selectedGender = existingCustomer.gender;
          setState(() {});
        }

        if (status is AddCustomerDetailsError) context.showSnackBar(status.message);
      },
      builder: (context, state) {
        return Scaffold(
          bottomNavigationBar: AppButton.flat(
            text: widget.shouldAddNewPax ? 'Add Customer to PAX' : 'Continue',
            showLoading: state.status is AddCustomerDetailsLoading,
            onTap: () async {
              context.closeKeyboard();
              if (_formKey.currentState?.validate() != true) return;

              // Additional safety check for duplicate emails
              final email = _emailTED.text.trim().toLowerCase();
              if ((widget.existingEmails ?? []).contains(email)) {
                context.showSnackBar('Customer is already present in this booking');
                return;
              }

              final cubit = context.read<AddCustomerDetailsCubit>();
              Customer? existingCustomer = state.customer;

              // Fetch if customer not loaded or email was changed after last fetch
              if (existingCustomer?.email?.toLowerCase() != email) {
                existingCustomer = await cubit.fetchCustomerByEmail(
                  emailId: _emailTED.text.trim().toLowerCase(),
                  updateFields: false,
                );
              }

              if (!context.mounted) return;

              final Customer customer = Customer(
                id: existingCustomer?.id,
                email: _emailTED.text.toLowerCase(),
                firstName: _firstNameTED.text.capitalizeFirst(),
                lastName: _lastNameTED.text.capitalizeFirst(),
                gender: _selectedGender!,
                phoneNumber: _phoneNumberTED.text,
                countryCode: _countryCode,
                isoCode: _isoCode,
              );

              if (widget.shouldAddNewPax) {
                // Add customer as PAX to the booking
                if (widget.bookingId != null) {
                  final Customer? finalCustomer = await context.read<AddCustomerDetailsCubit>().addCustomerAsPax(
                    bookingId: widget.bookingId!,
                    customer: customer,
                  );

                  if (context.mounted) {
                    // Return to ManagePax with customer data
                    Navigator.pop(context, finalCustomer);
                  }
                }
              } else {
                // Continue normal booking flow
                Navigator.push(
                  context,
                  SelectActivitySessionScreen.route(customer: customer),
                );
              }
            },
          ).paddingAll(20),
          appBar: CustomAppBar(
            title: 'Customer Details',
            description: widget.shouldAddNewPax ? 'Add Customer for PAX' : 'Add Customer Details',
          ),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextField(
                    controller: _emailTED,
                    labelText: 'Customer Email Id',
                    keyboardType: TextInputType.emailAddress,
                    required: true,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'required';
                      }

                      // Check if email already exists in the booking
                      final emailToCheck = value.trim().toLowerCase();
                      if (widget.existingEmails != null && widget.existingEmails!.contains(emailToCheck)) {
                        return 'Customer is already present in this booking';
                      }

                      return null;
                    },
                  ),
                  Spacing.h10,
                  AppButton.miniFlat(
                    text: 'Get Details',
                    showLoading: state.status is AddCustomerDetailsLoading,
                    onTap: () {
                      context.closeKeyboard();
                      if (_emailTED.text.trim().isEmpty) {
                        context.showSnackBar('Please enter an email ID');
                        return;
                      }

                      // Check for duplicate email
                      final emailToCheck = _emailTED.text.trim().toLowerCase();
                      if (widget.existingEmails != null && widget.existingEmails!.contains(emailToCheck)) {
                        context.showSnackBar('Customer is already present in this booking');
                        return;
                      }

                      context.read<AddCustomerDetailsCubit>().fetchCustomerByEmail(
                        emailId: emailToCheck,
                      );
                    },
                  ).right,
                  Spacing.h10,
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
                      Expanded(child: AppTextField(controller: _lastNameTED, labelText: 'Last Name')),
                    ],
                  ),
                  Spacing.h30,
                  PhoneNumberInput(
                    controller: _phoneNumberTED,
                    required: true,
                    initialCountryCode: _isoCode,
                    validator: (PhoneNumber? phone) {
                      try {
                        if (phone != null && phone.isValidNumber()) {
                          return null;
                        }
                        return 'required';
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
                  Spacing.h30,
                  AppDropdownButton<Gender>(
                    items: Gender.values,
                    initialValue: _selectedGender,
                    hintText: "Gender *",
                    validator: (value) => value == null ? 'required' : null,
                    onChanged: (gender) {
                      _selectedGender = gender;
                      setState(() {});
                    },
                    itemLabel: (gender) => gender.label,
                  ),
                ],
              ).scrollable.paddingAll(20),
            ),
          ),
        );
      },
    );
  }
}
