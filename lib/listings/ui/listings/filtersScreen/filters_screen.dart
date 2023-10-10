import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:instaflutter/core/utils/helper.dart';
import 'package:instaflutter/listings/listings_app_config.dart';
import 'package:instaflutter/listings/model/filter_model.dart';
import 'package:instaflutter/listings/ui/listings/api/listings_api_manager.dart';
import 'package:instaflutter/listings/ui/listings/filtersScreen/filters_bloc.dart';

class FilterWrappingWidget extends StatelessWidget {
  final Map<String, String>? filtersValue;

  const FilterWrappingWidget({Key? key, this.filtersValue}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FiltersBloc(listingsRepository: listingApiManager),
      child: FiltersScreen(filtersValue: filtersValue),
    );
  }
}

class FiltersScreen extends StatefulWidget {
  final Map<String, String>? filtersValue;

  const FiltersScreen({Key? key, this.filtersValue}) : super(key: key);

  @override
  State<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {
  List<FilterModel> _filters = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    context.read<FiltersBloc>().add(GetFiltersEvent());
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      maxChildSize: .9,
      initialChildSize: .9,
      minChildSize: .2,
      builder: (context, scrollController) =>
          BlocConsumer<FiltersBloc, FiltersState>(
        listener: (context, state) {
          if (state is FiltersReadyState) {
            isLoading = false;
            _filters = state.filters;
          }
        },
        builder: (context, state) {
          if (isLoading) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
          if (_filters.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: showEmptyState(
                'No filters found.'.tr(),
                'All filters will show up here once added by the admin.'.tr(),
              ),
            );
          } else {
            return SingleChildScrollView(
              controller: scrollController,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _filters.length,
                      shrinkWrap: true,
                      itemBuilder: (context, index) => FilterTileWidget(
                        filter: _filters[index],
                        filtersValue: widget.filtersValue,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                        backgroundColor: Color(colorPrimary),
                        shape: const StadiumBorder(),
                      ),
                      child: Text(
                        'Save Filters'.tr(),
                        style: const TextStyle(color: Colors.white),
                      ),
                      onPressed: () {
                        Navigator.pop(context, widget.filtersValue);
                      },
                    ),
                  )
                ],
              ),
            );
          }
        },
      ),
    );
  }
}

class FilterTileWidget extends StatefulWidget {
  final FilterModel filter;
  final Map<String, String>? filtersValue;

  const FilterTileWidget({Key? key, required this.filter, this.filtersValue})
      : super(key: key);

  @override
  State<FilterTileWidget> createState() => _FilterTileWidgetState();
}

class _FilterTileWidgetState extends State<FilterTileWidget> {
  late FilterModel filter;

  @override
  void initState() {
    super.initState();
    filter = widget.filter;
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(filter.name),
      trailing: DropdownButton<String>(
        selectedItemBuilder: (BuildContext context) => filter.options
            .cast<String>()
            .map<Widget>(
              (String item) => SizedBox(
                width: MediaQuery.of(context).size.width / 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(item),
                ),
              ),
            )
            .toList(),
        hint: SizedBox(
          width: MediaQuery.of(context).size.width / 2,
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(filter.name, textAlign: TextAlign.end),
          ),
        ),
        value: widget.filtersValue?[filter.name],
        underline: const SizedBox(),
        items: filter.options
            .map<DropdownMenuItem<String>>(
              (value) => DropdownMenuItem<String>(
                value: value,
                child: Text(value, textAlign: TextAlign.end),
              ),
            )
            .toList(),
        icon: const SizedBox(),
        onChanged: (String? value) {
          setState(() {
            widget.filtersValue?[filter.name] = value ?? '';
          });
        },
      ),
    );
  }
}
