part of 'folder_bloc.dart';

@immutable
abstract class FolderState {}

class FolderLoadInProgress extends FolderState {}

class FolderLoadSuccess extends FolderState {
  final List<Folder> subfolders;
  final List<File> files;

  FolderLoadSuccess(this.subfolders, this.files);
}
