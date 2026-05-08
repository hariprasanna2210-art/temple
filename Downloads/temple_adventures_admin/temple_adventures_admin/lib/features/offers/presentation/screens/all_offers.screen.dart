import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:temple_adventures_admin/features/offers/bloc/all_offers.cubit.dart';
import 'package:temple_adventures_admin/features/offers/models/offer.model.dart';
import 'package:temple_adventures_admin/features/offers/presentation/widgets/offer_filter_toggle.dart';
import 'package:temple_adventures_admin/features/offers/presentation/widgets/offer_list_view.dart';
import 'package:temple_adventures_admin/utils/extensions/build_context.extensions.dart';
import 'package:temple_adventures_admin/utils/styling/spacing_widgets.dart';
import 'package:temple_adventures_admin/widgets/custom_app_bar.dart';
import 'package:temple_adventures_admin/widgets/custom_floating_action_button.dart';
import 'package:temple_adventures_admin/widgets/loading_overlay.dart';
import 'package:temple_adventures_admin/widgets/empty_state_message.dart';

import 'add_edit_offer.screen.dart';

class AllOfferScreen extends StatefulWidget {
  const AllOfferScreen({super.key});

  static MaterialPageRoute<dynamic> route() => MaterialPageRoute(builder: (_) => const AllOfferScreen());

  @override
  State<AllOfferScreen> createState() => _AllOfferScreenState();
}

class _AllOfferScreenState extends State<AllOfferScreen> {
  bool _showOnlyValidOffers = false;

  @override
  void initState() {
    super.initState();
    context.read<AllOffersCubit>().fetchOffers();
  }

  List<Offer> _filterOffers(List<Offer> offers) {
    if (!_showOnlyValidOffers) return offers;

    final now = DateTime.now();
    return offers.where((offer) {
      return (now.isAfter(offer.startDate) && now.isBefore(offer.endDate)) || now.isBefore(offer.startDate);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Offers', description: 'All offers'),
      floatingActionButton: CustomFloatingActionButton(
        onTap: () async {
          await Navigator.push(context, AddEditOfferScreen.route());
        },
      ),
      body: SafeArea(
        child: BlocConsumer<AllOffersCubit, AllOffersState>(
          listener: (context, state) {
            if (state.status is AllOffersError) {
              final error = (state.status as AllOffersError).message;
              context.showSnackBar(error, backgroundColor: Colors.red);
            }
          },
          builder: (context, state) {
            if (state.status is AllOffersLoading) return LoadingOverlay();

            if (state.status is AllOffersError) {
              final message = (state.status as AllOffersError).message;
              return EmptyStateMessage(
                message: 'Failed to load offers\n$message',
                onRetry: () => context.read<AllOffersCubit>().fetchOffers(),
              );
            }

            if (state.status is AllOffersSuccess) {
              final offers = (state.status as AllOffersSuccess).offers;
              final filtered = _filterOffers(offers);

              return Column(
                children: [
                  OfferFilterToggle(
                    showOnlyValidOffers: _showOnlyValidOffers,
                    onChanged: (value) => setState(() => _showOnlyValidOffers = value),
                  ),
                  Expanded(
                    child: OfferListView(
                      offers: filtered,
                      showOnlyValidOffers: _showOnlyValidOffers,
                    ),
                  ),
                  Spacing.h50,
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
