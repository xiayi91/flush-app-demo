import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_google_places_hoc081098/flutter_google_places_hoc081098.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:instaflutter/constants.dart';
import 'package:instaflutter/core/ui/fullScreenImageViewer/full_screen_image_viewer.dart';
import 'package:instaflutter/core/ui/loading/loading_cubit.dart';
import 'package:instaflutter/core/utils/helper.dart';
import 'package:instaflutter/listings/listings_app_config.dart';
import 'package:instaflutter/listings/model/categories_model.dart';
import 'package:instaflutter/listings/model/listings_user.dart';
import 'package:instaflutter/listings/ui/listings/addListing/add_listing_bloc.dart';
import 'package:instaflutter/listings/ui/listings/api/listings_api_manager.dart';
import 'package:instaflutter/listings/ui/listings/filtersScreen/filters_screen.dart';

class AddListingWrappingWidget extends StatelessWidget {
  final ListingsUser currentUser;

  const AddListingWrappingWidget({Key? key, required this.currentUser})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AddListingBloc(
        currentUser: currentUser,
        listingsRepository: listingApiManager,
      ),
      child: AddListingScreen(currentUser: currentUser),
    );
  }
}

class AddListingScreen extends StatefulWidget {
  final ListingsUser currentUser;

  const AddListingScreen({Key? key, required this.currentUser})
      : super(key: key);

  @override
  State<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends State<AddListingScreen> {
  CategoriesModel? _categoryValue;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  Map<String, String>? _filters = {};
  PlaceDetails? _placeDetail;
  List<File?> _images = [null];
  List<CategoriesModel> _categories = [];
  late ListingsUser currentUser;
  bool isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    currentUser = widget.currentUser;
    context.read<AddListingBloc>().add(GetCategoriesEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddListingBloc, AddListingState>(
      listener: (listenerContext, state) async {
        if (state is AddListingErrorState) {
          await context.read<LoadingCubit>().hideLoading();
          if (!mounted) return;
          showAlertDialog(
              listenerContext, state.errorTitle, state.errorMessage);
        } else if (state is ListingPublishedState) {
          context.read<LoadingCubit>().hideLoading();
          Navigator.pop(context);
          showAlertDialog(context, 'Listing Added'.tr(),
              'Your listing has been added successfully'.tr());
        }
      },
      listenWhen: (old, current) =>
          old != current &&
          (current is AddListingErrorState || current is ListingPublishedState),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text('Add Listing'.tr()),
        ),
        body: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Material(
                color: isDarkMode(context) ? Colors.black12 : Colors.white,
                type: MaterialType.canvas,
                elevation: 2,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          'Title'.tr(),
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: TextField(
                        controller: _titleController,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          hintText: 'Start typing'.tr(),
                          isDense: true,
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Material(
                  color: isDarkMode(context) ? Colors.black12 : Colors.white,
                  elevation: 2,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            'Description'.tr(),
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: TextField(
                          keyboardType: TextInputType.multiline,
                          controller: _descController,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Start typing'.tr(),
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Material(
                color: isDarkMode(context) ? Colors.black12 : Colors.white,
                elevation: 2,
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      dense: true,
                      title: Text(
                        'Price'.tr(),
                        style: const TextStyle(fontSize: 20),
                      ),
                      trailing: SizedBox(
                        width: MediaQuery.of(context).size.width / 3,
                        child: TextField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.end,
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: '1000\$'.tr(),
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                    ListTile(
                      dense: true,
                      title: Text(
                        'Category'.tr(),
                        style: const TextStyle(fontSize: 20),
                      ),
                      trailing: SizedBox(
                        width: MediaQuery.of(context).size.width / 2,
                        child: BlocBuilder<AddListingBloc, AddListingState>(
                          buildWhen: (old, current) =>
                              old != current &&
                              (current is CategoriesFetchedState ||
                                  current is CategorySelectedState),
                          builder: (context, state) {
                            if (state is CategoriesFetchedState) {
                              isLoadingCategories = false;
                              _categories = state.categories;
                            } else if (state is CategorySelectedState) {
                              _categoryValue = state.category;
                            }
                            if (isLoadingCategories) {
                              return const Align(
                                alignment: Alignment.centerRight,
                                child: CircularProgressIndicator.adaptive(),
                              );
                            }
                            if (_categories.isEmpty) {
                              return Align(
                                alignment: Alignment.centerRight,
                                child: Text('No Categories Found'.tr()),
                              );
                            } else {
                              return DropdownButton<CategoriesModel>(
                                alignment: Alignment.centerRight,
                                isDense: true,
                                isExpanded: true,
                                selectedItemBuilder: (BuildContext context) =>
                                    _categories
                                        .map<Widget>((CategoriesModel item) =>
                                            Text(item.title))
                                        .toList(),
                                hint: Text('Choose Category'.tr()),
                                value: _categoryValue,
                                underline: const SizedBox(),
                                items: _categories
                                    .map<DropdownMenuItem<CategoriesModel>>(
                                      (category) =>
                                          DropdownMenuItem<CategoriesModel>(
                                        value: category,
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          category.title,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                icon: const SizedBox(),
                                onChanged: (CategoriesModel? model) => context
                                    .read<AddListingBloc>()
                                    .add(CategorySelectedEvent(
                                        categoriesModel: model)),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                    ListTile(
                      dense: true,
                      title: Text(
                        'Filters'.tr(),
                        style: const TextStyle(fontSize: 20),
                      ),
                      trailing: BlocBuilder<AddListingBloc, AddListingState>(
                        buildWhen: (old, current) =>
                            old != current && current is SetFiltersState,
                        builder: (context, state) {
                          if (state is SetFiltersState) {
                            _filters = state.filters ?? {};
                          }
                          return Text(_filters?.isEmpty ?? true
                              ? 'Set Filters'.tr()
                              : 'Edit Filters'.tr());
                        },
                      ),
                      onTap: () async {
                        Map<String, String>? filters =
                            await showModalBottomSheet(
                          isScrollControlled: true,
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          builder: (context) => FilterWrappingWidget(
                              filtersValue: _filters ?? {}),
                        );
                        if (filters != null) {
                          if (!mounted) return;
                          context
                              .read<AddListingBloc>()
                              .add(SetFiltersEvent(filters: filters));
                        }
                      },
                    ),
                    ListTile(
                      dense: true,
                      title: Text(
                        'Location'.tr(),
                        style: const TextStyle(fontSize: 20),
                      ),
                      trailing: SizedBox(
                        width: MediaQuery.of(context).size.width / 2,
                        child: BlocBuilder<AddListingBloc, AddListingState>(
                          buildWhen: (old, current) =>
                              old != current && current is PlaceDetailsState,
                          builder: (context, state) {
                            if (state is PlaceDetailsState) {
                              _placeDetail = state.placeDetails;
                            }
                            return Text(
                              _placeDetail != null
                                  ? '${_placeDetail!.formattedAddress}'.tr()
                                  : 'Select Place'.tr(),
                              textAlign: TextAlign.end,
                            );
                          },
                        ),
                      ),
                      onTap: () async {
                        Prediction? prediction = await PlacesAutocomplete.show(
                          context: context,
                          apiKey: googleApiKey,
                          mode: Mode.fullscreen,
                          language: 'en',
                        );
                        if (prediction != null) {
                          if (!mounted) return;
                          context.read<AddListingBloc>().add(
                              GetPlaceDetailsEvent(prediction: prediction));
                        }
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16.0),
                      child: Text(
                        'Add Photos'.tr(),
                        style: const TextStyle(fontSize: 25),
                      ),
                    ),
                    BlocBuilder<AddListingBloc, AddListingState>(
                      buildWhen: (old, current) =>
                          old != current &&
                          current is ListingImagesUpdatedState,
                      builder: (context, state) {
                        if (state is ListingImagesUpdatedState) {
                          _images = [...state.images, null];
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: SizedBox(
                            height: 100,
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _images.length,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              scrollDirection: Axis.horizontal,
                              itemBuilder: (context, index) =>
                                  ListingImageWidget(imageFile: _images[index]),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24),
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 24),
                      backgroundColor: Color(colorPrimary),
                      shape: RoundedRectangleBorder(
                        side: BorderSide.none,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      'Post Listing'.tr(),
                      style: TextStyle(
                          color:
                              isDarkMode(context) ? Colors.black : Colors.white,
                          fontSize: 20),
                    ),
                    onPressed: () => _postListing()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  _postListing() async {
    await context.read<LoadingCubit>().showLoading(
          context,
          'Loading...'.tr(),
          false,
          Color(colorPrimary),
        );
    if (!mounted) return;
    context.read<AddListingBloc>().add(ValidateListingInputEvent(
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          price: _priceController.text.trim(),
          category: _categoryValue,
          filters: _filters,
          placeDetails: _placeDetail,
        ));
  }
}

class ListingImageWidget extends StatefulWidget {
  final File? imageFile;

  const ListingImageWidget({Key? key, required this.imageFile})
      : super(key: key);

  @override
  State<ListingImageWidget> createState() => _ListingImageWidgetState();
}

class _ListingImageWidgetState extends State<ListingImageWidget> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.imageFile == null
            ? _pickImage(context)
            : _viewOrDeleteImage(widget.imageFile!, context);
      },
      child: SizedBox(
        width: 100,
        child: Card(
          shape: RoundedRectangleBorder(
            side: BorderSide.none,
            borderRadius: BorderRadius.circular(12),
          ),
          color: Color(colorPrimary),
          child: widget.imageFile == null
              ? Icon(
                  Icons.camera_alt,
                  size: 40,
                  color: isDarkMode(context) ? Colors.black : Colors.white,
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    widget.imageFile!,
                    fit: BoxFit.cover,
                  ),
                ),
        ),
      ),
    );
  }

  _viewOrDeleteImage(File imageFile, BuildContext blocContext) =>
      showCupertinoModalPopup(
        context: context,
        builder: (context) => CupertinoActionSheet(
          actions: [
            CupertinoActionSheetAction(
              onPressed: () async {
                Navigator.pop(context);
                blocContext
                    .read<AddListingBloc>()
                    .add(RemoveListingImageEvent(image: imageFile));
              },
              isDestructiveAction: true,
              child: Text('Remove Picture'.tr()),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                push(
                    context,
                    FullScreenImageViewer(
                        imageUrl: 'preview', imageFile: imageFile));
              },
              isDefaultAction: true,
              child: Text('View Picture'.tr()),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            child: Text('Cancel'.tr()),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      );

  _pickImage(BuildContext blocContext) => showCupertinoModalPopup(
        context: context,
        builder: (context) => CupertinoActionSheet(
          message: Text(
            'Add picture'.tr(),
            style: const TextStyle(fontSize: 15.0),
          ),
          actions: [
            CupertinoActionSheetAction(
              isDefaultAction: false,
              onPressed: () {
                Navigator.pop(context);
                blocContext
                    .read<AddListingBloc>()
                    .add(AddImageToListingEvent(fromGallery: true));
              },
              child: Text('Choose from gallery'.tr()),
            ),
            CupertinoActionSheetAction(
              isDestructiveAction: false,
              onPressed: () {
                Navigator.pop(context);
                blocContext
                    .read<AddListingBloc>()
                    .add(AddImageToListingEvent(fromGallery: false));
              },
              child: Text('Take a picture'.tr()),
            )
          ],
          cancelButton: CupertinoActionSheetAction(
            child: Text('Cancel'.tr()),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      );
}
