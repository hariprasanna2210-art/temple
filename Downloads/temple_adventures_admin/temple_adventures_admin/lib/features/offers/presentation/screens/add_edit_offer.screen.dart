import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:temple_adventures_admin/features/offers/bloc/add_edit_offer.cubit.dart';
import 'package:temple_adventures_admin/features/offers/models/offer.model.dart';
import 'package:temple_adventures_admin/features/user/bloc/user.cubit.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/spacing_widgets.dart';
import '../../../../widgets/app_button.dart';
import '../../../../widgets/app_text_field.dart';
import '../../../../widgets/custom_alert_dialog.dart';
import '../../../../widgets/custom_app_bar.dart';
import '../../bloc/all_offers.cubit.dart';
import '../../../../widgets/date_range_form_field.dart';
import '../widgets/photo_picker_form_field.dart';

class AddEditOfferScreen extends StatefulWidget {
  const AddEditOfferScreen({super.key, required this.offer});

  final Offer? offer;

  static MaterialPageRoute<dynamic> route({Offer? offer}) =>
      MaterialPageRoute(builder: (_) => AddEditOfferScreen(offer: offer));

  @override
  State<AddEditOfferScreen> createState() => _AddEditOfferScreenState();
}

class _AddEditOfferScreenState extends State<AddEditOfferScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameTED;
  late final TextEditingController _descriptionTED;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedImage;

  Offer? get offer => widget.offer;
  bool get editMode => offer != null;

  @override
  void initState() {
    super.initState();
    _nameTED = TextEditingController(text: offer?.name ?? '');
    _descriptionTED = TextEditingController(text: offer?.description ?? '');
    _selectedImage = offer?.photo;
    _startDate = offer?.startDate;
    _endDate = offer?.endDate;
  }

  @override
  void dispose() {
    _nameTED.dispose();
    _descriptionTED.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: editMode ? 'Edit Offer' : 'Add Offer',
        description: editMode ? 'Update the offer details' : 'Add a new offer',
        action: editMode ? buildDeleteActionButton() : SizedBox(),
      ),
      bottomNavigationBar: buildActionButton().paddingAll(20),
      body: SafeArea(
        child: BlocConsumer<AddEditOfferCubit, AddEditOfferState>(
          listener: (context, state) {
            if (state.status is AddEditOfferSuccess && (state.status as AddEditOfferSuccess).shouldPop) {
              context.read<AllOffersCubit>().fetchOffers();
              Navigator.pop(context);
            }
          },
          builder: (context, state) {
            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  AppTextField(
                    controller: _nameTED,
                    labelText: 'Name *',
                    validator: (value) => value == null || value.trim().isEmpty ? 'required' : null,
                  ),
                  Spacing.h16,
                  DateRangeFormField(
                    title: 'Valid Dates *',
                    startDate: _startDate,
                    endDate: _endDate,
                    onDateSelected: (picked) {
                      setState(() {
                        _startDate = picked.start;
                        _endDate = picked.end;
                      });
                    },
                  ),
                  Spacing.h16,
                  AppTextField(
                    controller: _descriptionTED,
                    labelText: 'Description',
                    maxLines: 3,
                  ),
                  Spacing.h20,
                  PhotoPickerFormField(
                    imagePath: _selectedImage,
                    onChanged: (path) => setState(() => _selectedImage = path),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget buildActionButton() {
    return BlocSelector<AddEditOfferCubit, AddEditOfferState, bool>(
      selector: (state) => state.status is AddEditOfferSubmitLoading || state.status is AddEditOfferUploadLoading,
      builder: (context, isLoading) {
        return AppButton.flat(
          text: (editMode) ? 'Update' : 'Submit',
          showLoading: isLoading,
          onTap: () async {
            String? photoUrl;
            if (!_formKey.currentState!.validate()) return;

            photoUrl = offer?.photo;
            if (photoUrl != _selectedImage) {
              photoUrl = await context.read<AddEditOfferCubit>().uploadImage(
                File(_selectedImage!),
              );
            }

            if (photoUrl != null && context.mounted) {
              final updatedOffer = Offer(
                id: offer?.id,
                name: _nameTED.text.trim(),
                description: _descriptionTED.text.trim(),
                photo: photoUrl,
                createdBy: context.read<UserCubit>().state.currentUser!,
                startDate: _startDate!,
                endDate: _endDate!,
              );
              await context.read<AddEditOfferCubit>().onSubmit(offer: updatedOffer);
            }
          },
        );
      },
    );
  }

  Widget buildDeleteActionButton() {
    return BlocSelector<AddEditOfferCubit, AddEditOfferState, bool>(
      selector: (state) => state.status is AddEditOfferDeleteLoading,
      builder: (context, isLoading) {
        return IconButton(
          onPressed: () async {
            final shouldDelete = await CustomAlertDialog.show(
              context,
              title: 'Are you sure?',
              content: 'This offer will be deleted completely.',
            );
            if (shouldDelete == true && context.mounted) {
              await context.read<AddEditOfferCubit>().deleteOffer(offer!.id!);
            }
          },
          icon:
              isLoading
                  ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2).size(20, 20)
                  : Icon(Icons.delete, size: 20, color: Colors.white),
        ).paddingOnly(right: 10);
      },
    );
  }
}
