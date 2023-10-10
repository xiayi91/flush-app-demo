part of 'container_bloc.dart';

abstract class ContainerEvent {}

class TabSelectedEvent extends ContainerEvent {
  int currentTabIndex;
  Widget currentWidget;
  DrawerSelection drawerSelection;
  String appBarTitle;

  TabSelectedEvent({
    required this.currentTabIndex,
    required this.currentWidget,
    required this.drawerSelection,
    required this.appBarTitle,
  });
}
