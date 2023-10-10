part of 'container_bloc.dart';

abstract class ContainerState {}

class ContainerInitial extends ContainerState {}

class TabSelectedState extends ContainerState {
  int currentTabIndex;
  Widget currentWidget;
  DrawerSelection drawerSelection;
  String appBarTitle;

  TabSelectedState({
    required this.currentTabIndex,
    required this.currentWidget,
    required this.drawerSelection,
    required this.appBarTitle,
  });
}
