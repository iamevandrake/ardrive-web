class EntityTag {
  static const appName = 'App-Name';
  static const appVersion = 'App-Version';
  static const contentType = 'Content-Type';
  static const unixTime = 'Unix-Time';

  static const entityType = 'Entity-Type';

  static const driveId = 'Drive-Id';
  static const folderId = 'Folder-Id';
  static const parentFolderId = 'Parent-Folder-Id';
  static const fileId = 'File-Id';

  static const drivePrivacy = 'Drive-Privacy';
  static const cipher = 'Cipher';
  static const cipherIv = 'Cipher-IV';
}

class EntityType {
  static const drive = 'drive';
  static const folder = 'folder';
  static const file = 'file';
}

class Cipher {
  static const aes256 = 'AES256-GCM';
}

class DrivePrivacy {
  static const public = 'public';
  static const private = 'private';
}
