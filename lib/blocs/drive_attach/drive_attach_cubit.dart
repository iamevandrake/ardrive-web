import 'package:ardrive/blocs/blocs.dart';
import 'package:ardrive/models/models.dart';
import 'package:ardrive/services/services.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:reactive_forms/reactive_forms.dart';

part 'drive_attach_state.dart';

class DriveAttachCubit extends Cubit<DriveAttachState> {
  final form = FormGroup({
    'driveId': FormControl(validators: [Validators.required]),
    'name': FormControl(validators: [Validators.required]),
  });

  final ArweaveService _arweave;
  final DrivesDao _drivesDao;
  final SyncBloc _syncBloc;
  final DrivesCubit _drivesBloc;

  DriveAttachCubit({
    @required ArweaveService arweave,
    @required DrivesDao drivesDao,
    @required SyncBloc syncBloc,
    @required DrivesCubit drivesBloc,
  })  : _arweave = arweave,
        _drivesDao = drivesDao,
        _syncBloc = syncBloc,
        _drivesBloc = drivesBloc,
        super(DriveAttachInitial());

  void submit() async {
    if (form.invalid) {
      return;
    }

    emit(DriveAttachInProgress());

    final String driveId = form.control('driveId').value;
    final String driveName = form.control('name').value;

    final driveEntity = await _arweave.tryGetFirstDriveEntityWithId(driveId);

    if (driveEntity == null) {
      form.control('driveId').setErrors({'drive-not-found': true});
      emit(DriveAttachInitial());
      return;
    }

    await _drivesDao.attachDrive(name: driveName, entity: driveEntity);

    _syncBloc.add(SyncWithNetwork());
    _drivesBloc.selectDrive(driveId);

    emit(DriveAttachSuccess());
  }
}