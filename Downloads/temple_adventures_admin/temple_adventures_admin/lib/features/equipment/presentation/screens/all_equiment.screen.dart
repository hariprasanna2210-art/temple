import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:temple_adventures_admin/features/equipment/presentation/screens/add_edit_equipment_item.screen.dart';
import 'package:temple_adventures_admin/features/equipment/presentation/screens/equipment_summary.screen.dart';
import 'package:temple_adventures_admin/features/equipment/presentation/screens/generate_otp.screen.dart';
import 'package:temple_adventures_admin/features/equipment/widgets/banner_container.dart';
import 'package:temple_adventures_admin/theme.dart';
import 'package:temple_adventures_admin/utils/extensions/build_context.extensions.dart';
import 'package:temple_adventures_admin/utils/styling/alignment_extensions.dart';
import 'package:temple_adventures_admin/utils/styling/padding_extensions.dart';
import 'package:temple_adventures_admin/widgets/app_button.dart';
import 'package:temple_adventures_admin/widgets/custom_app_bar.dart';
import 'package:temple_adventures_admin/widgets/loading_overlay.dart';

import '../../../../utils/constants.dart';
import '../../../../utils/styling/app_measurements.dart';
import '../../../../utils/styling/spacing_widgets.dart';
import '../../../../widgets/empty_state_message.dart';
import '../../bloc/all_equipment.cubit.dart';
import '../../bloc/otp.cubit.dart';
import '../../model/equipment_category.model.dart';
import '../../model/equipment_item.model.dart';

class AllEquipmentScreen extends StatefulWidget {
  const AllEquipmentScreen({super.key});

  static MaterialPageRoute<dynamic> route() => MaterialPageRoute(
    builder: (_) => const AllEquipmentScreen(),
    settings: const RouteSettings(name: 'AllEquipmentScreen'),
  );

  @override
  State<AllEquipmentScreen> createState() => _AllEquipmentScreenState();
}

class _AllEquipmentScreenState extends State<AllEquipmentScreen> {
  @override
  void initState() {
    super.initState();
    final cubit = context.read<AllEquipmentCubit>();
    final otpCubit = context.read<OtpCubit>();
    otpCubit.clearFirebaseTrackingId();
    cubit.resetEquipmentItemSelection();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.wait([
        cubit.fetchCategories(),
        cubit.fetchEquipmentItems(),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'All Equipment',
        description: 'All the available equipment for renting',
        action: IconButton(
          onPressed: () {
            final categoriesList = context.read<AllEquipmentCubit>().state.categories;
            Navigator.push(
              context,
              AddEditEquipmentItemScreen.route(
                categories: categoriesList,
              ),
            );
          },
          icon: const Icon(Icons.add_circle_outline_outlined),
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<AllEquipmentCubit, AllEquipmentState>(
          listener: (context, state) {
            if (state.status is AllEquipmentError) {
              final error = (state.status as AllEquipmentError).message;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(error), backgroundColor: Colors.red),
              );
            }
          },
          builder: (context, state) {
            if (state.status is AllEquipmentInitial || state.status is AllEquipmentLoading) {
              return LoadingOverlay();
            }

            if (state.status is AllEquipmentError) {
              final message = (state.status as AllEquipmentError).message;
              return EmptyStateMessage(
                message: 'Failed to load equipment\n$message',
                onRetry: () {
                  final cubit = context.read<AllEquipmentCubit>();
                  cubit.fetchCategories();
                  cubit.fetchEquipmentItems();
                },
              );
            }

            if (state.status is AllEquipmentLoaded || state.status is AllEquipmentSuccess) {
              final categoriesList = state.categories;
              if (categoriesList.isEmpty) {
                return EmptyStateMessage(message: 'No categories available');
              }

              return Column(
                children: [
                  _GenerateOTPBanner(),
                  Spacing.h16,
                  ...categoriesList.map((category) {
                    final equipmentItemList = state.equipmentItems.where((e) => e.category.id == category.id).toList();

                    return _EquipmentCategoryCard(
                      category: category,
                      equipmentItems: equipmentItemList,
                      selectedItems: state.selectedItems,
                    );
                  }),
                  Spacing.h50,
                ],
              ).paddingAll(16).scrollable;
            }

            return const EmptyStateMessage(message: 'Something went wrong');
          },
        ),
      ),
      bottomNavigationBar: _RentNowBanner(),
    );
  }
}

class _GenerateOTPBanner extends StatelessWidget {
  const _GenerateOTPBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Screen.width,
      decoration: BoxDecoration(
        color: skyBlueColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Spacing.w8,
          Flexible(
            child: Column(
              children: [
                Spacing.h16,
                const Text(
                  'Generate OTP',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ).left,
                Spacing.h8,
                RichText(
                  text: const TextSpan(
                    text: 'Share',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      color: Colors.black,
                    ),
                    children: <TextSpan>[
                      TextSpan(text: ' OTP ', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: 'with your dive buddy for equipment '),
                      TextSpan(text: 'verification.', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Spacing.h16,
              ],
            ).paddingSymmetric(horizontal: 16),
          ),
          AppButton.miniFlat(
            text: 'Generate',
            buttonColor: skyBlueColor,
            onTap: () => Navigator.push(context, GenerateOtpScreen.route()),
          ),
          Spacing.w8,
        ],
      ),
    );
  }
}

class _EquipmentItemTile extends StatelessWidget {
  final EquipmentItem item;
  final bool isSelected;

  const _EquipmentItemTile({
    required this.item,
    required this.isSelected,
  });

  double get size => (Screen.width / 3) - 15 * 2;

  @override
  Widget build(BuildContext context) {
    final isRented = item.currentRentedPerson != null;

    return InkWell(
      onTap: () {
        if (isRented) {
          context.showSnackBar('${item.equipmentName} is rented and not available');
          return;
        }
        context.read<AllEquipmentCubit>().toggleEquipmentItemSelection(item);
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: size,
            width: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? skyBlueColor : const Color(0xffB3B3B3),
                width: isSelected ? 2 : 0.5,
              ),
              image: DecorationImage(
                image: CachedNetworkImageProvider(item.photo ?? placeHolderImage),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Spacing.w20,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.equipmentName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              Spacing.h20,
              InkWell(
                onTap: () {
                  final categoriesList = context.read<AllEquipmentCubit>().state.categories;
                  if (isSelected) {
                    context.read<AllEquipmentCubit>().resetEquipmentItemSelection();
                  }
                  Navigator.push(
                    context,
                    AddEditEquipmentItemScreen.route(
                      equipmentItem: item,
                      categories: categoriesList,
                    ),
                  );
                },
                child: const Text(
                  'Edit',
                  style: TextStyle(
                    color: skyBlueColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: CircleAvatar(
              radius: 6,
              backgroundColor: isRented ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}

class _RentNowBanner extends StatelessWidget {
  const _RentNowBanner();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AllEquipmentCubit, AllEquipmentState>(
      buildWhen: (previous, current) => previous.selectedItems != current.selectedItems,
      builder: (context, state) {
        final selectedItems = state.selectedItems;

        if (selectedItems.isEmpty) return const SizedBox();

        return SafeArea(
          child: Container(
            height: 60,
            width: double.infinity,
            color: Colors.transparent,
            child: BannerContainer(
              height: 45,
              child: Row(
                children: [
                  RichText(
                    text: TextSpan(
                      text: '${selectedItems.length} ',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      children: const [
                        TextSpan(
                          text: ' Items selected',
                          style: TextStyle(fontWeight: FontWeight.normal),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.push(context, EquipmentSummaryScreen.route());
                    },
                    child: Text('Rent now', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                  ),
                ],
              ).paddingSymmetric(horizontal: 16),
            ).center.width(Screen.width),
          ),
        );
      },
    );
  }
}

class _EquipmentCategoryCard extends StatefulWidget {
  final EquipmentCategory category;
  final List<EquipmentItem> equipmentItems;
  final List<EquipmentItem> selectedItems;

  const _EquipmentCategoryCard({
    required this.category,
    required this.equipmentItems,
    required this.selectedItems,
  });

  @override
  State<_EquipmentCategoryCard> createState() => _EquipmentCategoryCardState();
}

class _EquipmentCategoryCardState extends State<_EquipmentCategoryCard> {
  bool _expanded = false;

  int get selectedCount => widget.selectedItems.where((item) => item.category.id == widget.category.id).length;
  bool get hasSelection => selectedCount > 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: lightBlueColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() => _expanded = !_expanded);
            },
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: skyBlueColor.withOpacity(0.1),
                  child: Text(
                    widget.equipmentItems.length.toString(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Spacing.w15,
                Expanded(
                  child: Text(
                    widget.category.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
                if (hasSelection)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$selectedCount selected',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.black,
                ),
              ],
            ).paddingSymmetric(horizontal: 15, vertical: 12),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: _expanded ? _buildExpandedContent(context) : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(BuildContext context) {
    final hasItems = widget.equipmentItems.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasItems)
          ...widget.equipmentItems.map((equip) {
            final isSelected = widget.selectedItems.contains(equip);
            return _EquipmentItemTile(
              item: equip,
              isSelected: isSelected,
            ).paddingSymmetric(vertical: 8);
          }),
        Spacing.h10,
        Align(
          alignment: (hasItems) ? Alignment.bottomLeft : Alignment.center,
          child: AppButton.miniFlat(
            text: 'Add Item',
            onTap: () {
              Navigator.push(
                context,
                AddEditEquipmentItemScreen.route(
                  categories: [],
                  category: widget.category,
                ),
              );
            },
          ),
        ),
        if (!hasItems) ...[
          Spacing.h10,
          Text(
            "No equipment in this category",
            style: TextStyle(color: Colors.black54, fontSize: 12),
          ).center,
        ],
      ],
    ).paddingAll(10);
  }
}
