import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';
import 'package:temple_adventures_admin/widgets/custom_app_bar.dart';

import '../../../../widgets/app_button.dart';
import '../../../../widgets/app_text_field.dart';
import '../../../../widgets/basic_snack_bar.dart';
import '../../../../widgets/custom_alert_dialog.dart';
import '../../bloc/add_edit_dive_site.cubit.dart';
import '../../bloc/dive_sites.cubit.dart';
import '../../model/dive_site.model.dart';

class AddEditDiveSiteScreen extends StatefulWidget {
  const AddEditDiveSiteScreen({super.key, this.diveSiteModel});

  final DiveSite? diveSiteModel;

  static MaterialPageRoute<dynamic> route(DiveSite? diveSite) => MaterialPageRoute(
    builder: (_) => AddEditDiveSiteScreen(diveSiteModel: diveSite),
  );

  @override
  State<AddEditDiveSiteScreen> createState() => _AddEditDiveSiteScreenState();
}

class _AddEditDiveSiteScreenState extends State<AddEditDiveSiteScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _diveSiteTED;
  late TextEditingController _latitudeTED;
  late TextEditingController _longitudeTED;

  bool get editMode => widget.diveSiteModel != null;

  DiveSite? get diveSite => widget.diveSiteModel;

  @override
  void initState() {
    super.initState();
    _diveSiteTED = TextEditingController(text: diveSite?.siteName);
    _latitudeTED = TextEditingController(text: diveSite?.latitude.toString());
    _longitudeTED = TextEditingController(text: diveSite?.longitude.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: editMode ? 'Edit Dive Site' : 'Add Dive Site',
        description: editMode ? 'Update ${diveSite?.siteName}' : 'Add New Dive Site',
        action: editMode ? buildDeleteActionButton() : SizedBox.shrink(),
      ),
      body: SafeArea(
        child: BlocConsumer<AddEditDiveSiteCubit, AddEditDiveSiteState>(
          listener: (context, state) {
            if (state.status is AddEditDiveSiteSuccess && (state.status as AddEditDiveSiteSuccess).shouldPop) {
              context.read<DiveSiteCubit>().fetchDiveSites();
              Navigator.pop(context);
            }
            if (state.status is DiveSiteError) {
              BasicSnackBar.show(
                context,
                message: 'Error: ${(state.status as DiveSiteError).message}',
              );
            }
          },
          builder: (context, state) {
            return Form(
              key: _formKey,
              child: Column(
                children: [
                  AppTextField(
                    controller: _diveSiteTED,
                    labelText: 'Dive site name',
                    validator: (val) => val == null || val.isEmpty ? 'required' : null,
                  ),
                  AppTextField(
                    controller: _latitudeTED,
                    labelText: 'Latitude',
                    keyboardType: TextInputType.number,
                    validator: (val) => val == null || val.isEmpty ? 'required' : null,
                  ),
                  AppTextField(
                    controller: _longitudeTED,
                    labelText: 'Longitude',
                    keyboardType: TextInputType.number,
                    validator: (val) => val == null || val.isEmpty ? 'required' : null,
                  ),
                  const Spacer(),
                  buildActionButton(),
                  const Spacer(),
                ],
              ),
            );
          },
        ).paddingAll(20),
      ),
    );
  }

  Widget buildDeleteActionButton() {
    return BlocSelector<AddEditDiveSiteCubit, AddEditDiveSiteState, bool>(
      selector: (state) => state.status is AddEditDiveSiteLoading,
      builder: (context, isLoading) {
        return IconButton(
          onPressed: () async {
            final shouldDelete = await CustomAlertDialog.show(
              context,
              title: 'Are you sure?',
              content: 'This equipment item will be deleted completely.',
            );
            if (shouldDelete == true && context.mounted) {
              await context.read<AddEditDiveSiteCubit>().deleteDiveSite(
                context,
                diveSite!.id!,
              );
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

  Widget buildActionButton() {
    return BlocSelector<AddEditDiveSiteCubit, AddEditDiveSiteState, bool>(
      selector: (state) => state.status is AddEditDiveSiteLoading,
      builder:
          (context, isLoading) => AppButton.flat(
            text: editMode ? 'Update' : 'Submit',
            showLoading: isLoading,
            onTap: () async {
              if (!_formKey.currentState!.validate()) return;

              final lat = double.tryParse(_latitudeTED.text);
              final lng = double.tryParse(_longitudeTED.text);

              final newDiveSite = DiveSite(
                id: diveSite?.id,
                siteName: _diveSiteTED.text.trim(),
                latitude: lat!,
                longitude: lng!,
              );
              if (!context.mounted) return;
              context.read<AddEditDiveSiteCubit>().onDiveSiteSubmit(context, newDiveSite);
            },
          ),
    );
  }
}
