import 'dart:convert';

import 'package:ardrive/blocs/blocs.dart';
import 'package:ardrive/entities/entities.dart';
import 'package:ardrive/entities/profileTypes.dart';
import 'package:ardrive/l11n/validation_messages.dart';
import 'package:ardrive/models/models.dart';
import 'package:ardrive/services/arconnect/arconnect.dart' as arconnect;
import 'package:ardrive/services/pendo/pendo.dart' as pendo;
import 'package:ardrive/services/services.dart';
import 'package:arweave/arweave.dart';
import 'package:bloc/bloc.dart';
import 'package:crypto/crypto.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:reactive_forms/reactive_forms.dart';

part 'profile_add_state.dart';

class ProfileAddCubit extends Cubit<ProfileAddState> {
  FormGroup form;

  Wallet _wallet;
  ProfileType _profileType;
  String _lastKnownWalletAddress;
  List<TransactionCommonMixin> _driveTxs;

  final ProfileCubit _profileCubit;
  final ProfileDao _profileDao;
  final ArweaveService _arweave;
  ProfileAddCubit({
    @required ProfileCubit profileCubit,
    @required ProfileDao profileDao,
    @required ArweaveService arweave,
    @required BuildContext context,
  })  : _profileCubit = profileCubit,
        _profileDao = profileDao,
        _arweave = arweave,
        super(ProfileAddPromptWallet());

  bool isArconnectInstalled() {
    return arconnect.isExtensionPresent();
  }

  ProfileType getProfileType() => _profileType;

  Future<void> promptForWallet() async {
    if (isArconnectInstalled()) {
      await arconnect.disconnect();
    }
    emit(ProfileAddPromptWallet());
  }

  Future<void> pickWallet(String walletJson) async {
    emit(ProfileAddUserStateLoadInProgress());

    _wallet = Wallet.fromJwk(json.decode(walletJson));
    _driveTxs =
        await _arweave.getUniqueUserDriveEntityTxs(await _wallet.getAddress());

    if (_driveTxs.isEmpty) {
      emit(ProfileAddOnboardingNewUser());
    } else {
      emit(ProfileAddPromptDetails(isExistingUser: true));
      setupForm(withPasswordConfirmation: false);
    }
  }

  Future<void> pickWalletFromArconnect() async {
    try {
      emit(ProfileAddUserStateLoadInProgress());
      _profileType = ProfileType.ArConnect;

      await arconnect.connect();
      if (!(await arconnect.checkPermissions())) {
        emit(ProfileAddFailiure());
        return;
      }

      _lastKnownWalletAddress = await arconnect.getWalletAddress();

      _driveTxs =
          await _arweave.getUniqueUserDriveEntityTxs(_lastKnownWalletAddress);

      if (_driveTxs.isEmpty) {
        emit(ProfileAddOnboardingNewUser());
      } else {
        emit(ProfileAddPromptDetails(isExistingUser: true));
        setupForm(withPasswordConfirmation: false);
      }
    } catch (e) {
      emit(ProfileAddFailiure());
    }
  }

  Future<void> completeOnboarding() async {
    emit(ProfileAddPromptDetails(isExistingUser: false));
    setupForm(withPasswordConfirmation: true);
  }

  void setupForm({bool withPasswordConfirmation}) {
    form = FormGroup(
      {
        'username': FormControl(validators: [Validators.required]),
        'password': FormControl(validators: [Validators.required]),
        if (withPasswordConfirmation) 'passwordConfirmation': FormControl(),
        'agreementConsent':
            FormControl<bool>(validators: [Validators.requiredTrue]),
      },
      validators: [
        if (withPasswordConfirmation)
          _mustMatch('password', 'passwordConfirmation'),
      ],
    );
  }

  Future<void> submit() async {
    try {
      form.markAllAsTouched();

      if (form.invalid) {
        return;
      }
      if (_profileType == ProfileType.ArConnect &&
          (_lastKnownWalletAddress != await arconnect.getWalletAddress() ||
              !(await arconnect.checkPermissions()))) {
        //Wallet was switched or deleted before login from another tab

        emit(ProfileAddFailiure());
        return;
      }
      final previousState = state;
      emit(ProfileAddInProgress());

      final username = form.control('username').value.toString().trim();
      final String password = form.control('password').value;

      final privateDriveTxs = _driveTxs.where(
          (tx) => tx.getTag(EntityTag.drivePrivacy) == DrivePrivacy.private);

      // Try and decrypt one of the user's private drive entities to check if they are entering the
      // right password.
      if (privateDriveTxs.isNotEmpty) {
        final checkDriveId = privateDriveTxs.first.getTag(EntityTag.driveId);
        final signature =
            _wallet != null ? _wallet.sign : arconnect.getSignature;

        final checkDriveKey = await deriveDriveKey(
          signature,
          checkDriveId,
          password,
        );

        final privateDrive = await _arweave.getLatestDriveEntityWithId(
          checkDriveId,
          checkDriveKey,
        );

        // If the private drive could not be decoded, the password is incorrect.
        if (privateDrive == null) {
          form
              .control('password')
              .setErrors({AppValidationMessage.passwordIncorrect: true});

          // Reemit the previous state so form errors can be shown again.
          emit(previousState);

          return;
        }
      }
      var walletAddress;
      if (_wallet != null) {
        walletAddress = await _wallet.getAddress();
        await _profileDao.addProfile(username, password, _wallet);
      } else {
        walletAddress = await arconnect.getWalletAddress();
        final walletPublicKey = await arconnect.getPublicKey();
        await _profileDao.addProfileArconnect(
          username,
          password,
          walletAddress,
          walletPublicKey,
        );
      }

      // Initialize Pendo
      final publicKeyMD5Hash =
          md5.convert(utf8.encode(walletAddress)).toString();
      pendo.initializePendo(publicKeyMD5Hash);
      await _profileCubit.unlockDefaultProfile(password, _profileType);
      await _profileCubit.unlockDefaultProfile(password, _profileType);
    } catch (e) {
      await _profileCubit.logoutProfile();
    }
  }

  ValidatorFunction _mustMatch(String controlName, String matchingControlName) {
    return (AbstractControl control) {
      final form = control as FormGroup;

      final formControl = form.control(controlName);
      final matchingFormControl = form.control(matchingControlName);

      if (formControl.value != matchingFormControl.value) {
        matchingFormControl.setErrors({'mustMatch': true});

        // Do not mark the matching form control as touched like the default `mustMatch` validator does.
        // matchingFormControl.markAsTouched();
      } else {
        matchingFormControl.setErrors({});
      }

      return null;
    };
  }
}
