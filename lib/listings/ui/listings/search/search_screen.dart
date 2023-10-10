import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:instaflutter/listings/model/listing_model.dart';
import 'package:instaflutter/listings/model/listings_user.dart';
import 'package:instaflutter/core/utils/helper.dart';
import 'package:instaflutter/listings/ui/listings/addListing/add_listing_screen.dart';
import 'package:instaflutter/listings/ui/listings/api/listings_api_manager.dart';
import 'package:instaflutter/listings/ui/listings/listingDetails/listing_details_screen.dart';
import 'package:instaflutter/listings/ui/listings/search/search_bloc.dart';
import 'package:instaflutter/listings/listings_app_config.dart';

class SearchWrapperWidget extends StatelessWidget {
  final ListingsUser currentUser;

  const SearchWrapperWidget({Key? key, required this.currentUser})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SearchBloc(
        currentUser: currentUser,
        listingsRepository: listingApiManager,
      ),
      child: SearchScreen(currentUser: currentUser),
    );
  }
}

class SearchScreen extends StatefulWidget {
  final ListingsUser currentUser;

  const SearchScreen({Key? key, required this.currentUser}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<ListingModel> _filteredListings = [];
  List<ListingModel> _listings = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  late ListingsUser currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = widget.currentUser;
    context.read<SearchBloc>().add(GetListingsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          _searchController.clear();
          context.read<SearchBloc>().add(LoadingEvent());
          context.read<SearchBloc>().add(GetListingsEvent());
        },
        child: BlocConsumer<SearchBloc, SearchState>(
          listener: (context, state) {
            if (state is ListingsReadyState) {
              isLoading = false;
              _listings = state.listings;
              _filteredListings = [];
            } else if (state is LoadingState) {
              isLoading = true;
            } else if (state is ListingsFilteredState) {
              _filteredListings = state.filteredListings;
            }
          },
          builder: (context, state) {
            if (isLoading) {
              return const Center(child: CircularProgressIndicator.adaptive());
            }
            if (_listings.isEmpty) {
              return Stack(
                children: [
                  ListView(),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: showEmptyState(
                      'No Listing Found'.tr(),
                      'Add a new listing to show up here once approved by admins.'
                          .tr(),
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
              return CustomScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.only(left: 8.0, right: 8, top: 8),
                    sliver: SliverToBoxAdapter(
                      child: TextField(
                        onChanged: (query) => context
                            .read<SearchBloc>()
                            .add(SearchListingsEvent(query: query)),
                        controller: _searchController,
                        textAlignVertical: TextAlignVertical.center,
                        textInputAction: TextInputAction.search,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                            contentPadding: const EdgeInsets.all(8),
                            isDense: true,
                            fillColor: isDarkMode(context)
                                ? Colors.grey.shade700
                                : Colors.grey.shade200,
                            filled: true,
                            focusedBorder: const OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(360)),
                                borderSide:
                                    BorderSide(style: BorderStyle.none)),
                            enabledBorder: const OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(360)),
                                borderSide:
                                    BorderSide(style: BorderStyle.none)),
                            hintText: 'Search for listings'.tr(),
                            suffixIcon: IconButton(
                              focusColor: isDarkMode(context)
                                  ? Colors.white
                                  : Colors.black,
                              iconSize: 20,
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                FocusScope.of(context).unfocus();
                                context
                                    .read<SearchBloc>()
                                    .add(SearchListingsEvent(query: ''));
                                _searchController.clear();
                              },
                            ),
                            prefixIcon: const Icon(Icons.search, size: 20)),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(8),
                    sliver: _searchController.text.isNotEmpty &&
                            _filteredListings.isEmpty
                        ? SliverPadding(
                            padding: const EdgeInsets.all(16.0),
                            sliver: SliverToBoxAdapter(
                              child: showEmptyState(
                                  'No Result'.tr(),
                                  'No listing matches the used keyword, Try another keyword.'
                                      .tr()),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => SearchListingsResultTile(
                                listing: _filteredListings.isEmpty
                                    ? _listings[index]
                                    : _filteredListings[index],
                                currentUser: currentUser,
                              ),
                              childCount: _filteredListings.isEmpty
                                  ? _listings.length
                                  : _filteredListings.length,
                            ),
                          ),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class SearchListingsResultTile extends StatefulWidget {
  final ListingModel listing;
  final ListingsUser currentUser;

  const SearchListingsResultTile({
    Key? key,
    required this.listing,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<SearchListingsResultTile> createState() =>
      _SearchListingsResultTileState();
}

class _SearchListingsResultTileState extends State<SearchListingsResultTile> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height / 7,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
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
                  .read<SearchBloc>()
                  .add(ListingDeletedByUserEvent(listing: widget.listing));
            }
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width / 4,
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
                        style: const TextStyle(fontSize: 17),
                      ),
                      Text(
                        'Added on ${formatReviewTimestamp(widget.listing.createdAt)}'
                            .tr(),
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade500),
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
