/// Plantilla de ejemplo para fcm_credentials.dart.
/// Copia este archivo como `lib/config/fcm_credentials.dart` y reemplaza los valores
/// con el JSON de tu Cuenta de Servicio descargado desde la consola de Firebase.
const Map<String, dynamic> fcmServiceAccountCredentials = {
  "type": "service_account",
  "project_id": "eventobq-3a405",
  "private_key_id": "YOUR_PRIVATE_KEY_ID",
  "private_key": "-----BEGIN PRIVATE KEY-----\nYOUR_KEY\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk@eventobq-3a405.iam.gserviceaccount.com",
  "client_id": "YOUR_CLIENT_ID",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk",
  "universe_domain": "googleapis.com"
};
