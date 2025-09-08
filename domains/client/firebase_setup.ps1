npm install -g firebase-tools
npm i -g firebase
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
$env:NODE_TLS_REJECT_UNAUTHORIZED=0
$env:Path += ';C:\Users\$user\AppData\Local\Pub\Cache\bin\'
dart pub global activate firebase
firebase login --reauth
dart pub global activate flutterfire_cli
flutterfire configure --project=$project_id
flutter pub add firebase_core