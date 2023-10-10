part of 'filters_bloc.dart';

abstract class FiltersState {}

class FiltersInitial extends FiltersState {}

class FiltersReadyState extends FiltersState {
  List<FilterModel> filters;

  FiltersReadyState({required this.filters});
}
