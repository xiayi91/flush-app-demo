import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:instaflutter/listings/listings_app_config.dart';
import 'package:instaflutter/listings/model/listing_model.dart';
import 'package:instaflutter/listings/model/listings_user.dart';
import 'package:instaflutter/listings/ads/ads_utils.dart';
import 'package:instaflutter/core/utils/helper.dart';
import 'package:instaflutter/listings/ui/listings/addListing/add_listing_screen.dart';
import 'package:instaflutter/listings/ui/listings/api/listings_api_manager.dart';
import 'package:instaflutter/listings/ui/listings/categoryListings/category_listings_bloc.dart';
import 'package:instaflutter/listings/ui/listings/filtersScreen/filters_screen.dart';
import 'package:instaflutter/listings/ui/listings/listingDetails/listing_details_screen.dart';
import 'package:instaflutter/listings/ui/listings/mapView/map_view_screen.dart';

class CategoryListingsWrapperWidget extends StatelessWidget {
  final String categoryID;
  final String categoryName;
  final ListingsUser currentUser;

  const CategoryListingsWrapperWidget({
    Key? key,
    required this.categoryID,
    required this.categoryName,
    required this.currentUser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CategoryListingsBloc(
        listingsRepository: listingApiManager,
        currentUser: currentUser,
        categoryID: categoryID,
      ),
      child: CategoryListingsScreen(
        currentUser: currentUser,
        categoryID: categoryID,
        categoryName: categoryName,
      ),
    );
  }
}

class CategoryListingsScreen extends StatefulWidget {
  final String categoryID;
  final String categoryName;
  final ListingsUser currentUser;

  const CategoryListingsScreen(
      {Key? key,
      required this.categoryID,
      required this.categoryName,
      required this.currentUser})
      : super(key: key);

  @override
  State<CategoryListingsScreen> createState() => _CategoryListingsScreenState();
}

class _CategoryListingsScreenState extends State<CategoryListingsScreen> {
  List<ListingModel> _list = [];
  Map<String, String>? _filters = {};
  late ListingsUser currentUser;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    currentUser = widget.currentUser;
    context.read<CategoryListingsBloc>().add(GetListingsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
          backgroundColor: Color(colorPrimary),
          tooltip: 'Filter'.tr(),
          onPressed: () async {
            _filters = await showModalBottomSheet(
              isScrollControlled: true,
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              builder: (context) {
                return FilterWrappingWidget(filtersValue: _filters);
              },
            );
            _filters ??= {};
          },
          child: Icon(
            Icons.filter_list,
            color: isDarkMode(context) ? Colors.black : Colors.white,
          )),
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(
              Icons.map,
            ),
            onPressed: () {
              if (_list.isNotEmpty && _list.first.categoryTitle.isEmpty) {
                _list.first.categoryTitle = widget.categoryName;
              }
              push(
                  context,
                  MapViewScreen(
                    listings: _list,
                    fromHome: false,
                    currentUser: currentUser,
                  ));
            },
          )
        ],
        title: Text(widget.categoryName),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<CategoryListingsBloc>().add(LoadingEvent());
          context.read<CategoryListingsBloc>().add(GetListingsEvent());
        },
        child: BlocConsumer<CategoryListingsBloc, CategoryListingsState>(
          listener: (context, state) {
            if (state is ListingsReadyState) {
              isLoading = false;
              _list = state.listings;
            } else if (state is LoadingState) {
              isLoading = true;
            }
          },
          builder: (context, state) {
            if (isLoading) {
              return const Center(child: CircularProgressIndicator.adaptive());
            }
            if (_list.isEmpty) {
              return Stack(
                children: [
                  ListView(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 16, 16, 120),
                    child: showEmptyState(
                      'No Listing'.tr(),
                      'Add a new listing to show up here once approved.'.tr(),
                      buttonTitle: 'Add Listing'.tr(),
                      isDarkMode: isDarkMode(context),
                      action: () => push(context,
                          AddListingWrappingWidget(currentUser: currentUser)),
                      colorPrimary: Color(colorPrimary),
                    ),
                  ),
                ],
              );
            } else {
              return SafeArea(
                minimum: const EdgeInsets.only(bottom: 50),
                child: ListView.separated(
                  separatorBuilder: (context, index) {
                    return index == 0
                        ? const SizedBox.shrink()
                        : (index + 1) % 4 == 0
                            ? AdsUtils.adsContainer()
                            : const SizedBox.shrink();
                  },
                  itemCount: _list.length,
                  itemBuilder: (context, index) => ListingRowWidget(
                    listing: _list[index],
                    currentUser: currentUser,
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 60),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

class ListingRowWidget extends StatefulWidget {
  final ListingModel listing;
  final ListingsUser currentUser;

  const ListingRowWidget(
      {Key? key, required this.listing, required this.currentUser})
      : super(key: key);

  @override
  State<ListingRowWidget> createState() => _ListingRowWidgetState();
}

class _ListingRowWidgetState extends State<ListingRowWidget> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height / 8,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () async {
            bool? isListingDeleted = await push(
                context,
                ListingDetailsWrappingWidget(
                    listing: widget.listing, currentUser: widget.currentUser));
            if (isListingDeleted != null && isListingDeleted) {
              if (!mounted) return;
              context
                  .read<CategoryListingsBloc>()
                  .add(ListingDeletedEvent(listing: widget.listing));
            }
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width / 5,
                child: displayImage(widget.listing.photo),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        widget.listing.title,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode(context)
                                ? Colors.grey[300]
                                : const Color(0xFF464646)),
                      ),
                      Text(
                        'Added on ${formatReviewTimestamp(widget.listing.createdAt)}'
                            .tr(),
                        style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Text(
                                widget.listing.place,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.grey),
                              ),
                            ),
                            Text(
                              widget.listing.price,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode(context)
                                    ? Colors.grey[300]
                                    : const Color(0xFF464646),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
