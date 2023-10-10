import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:instaflutter/listings/ui/container/container_screen.dart';

part 'container_event.dart';

part 'container_state.dart';

class ContainerBloc extends Bloc<ContainerEvent, ContainerState> {
  ContainerBloc() : super(ContainerInitial()) {
    on<TabSelectedEvent>((event, emit) => emit(TabSelectedState(
          currentTabIndex: event.currentTabIndex,
          currentWidget: event.currentWidget,
          drawerSelection: event.drawerSelection,
          appBarTitle: event.appBarTitle,
        )));
  }
}
