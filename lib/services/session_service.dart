import 'package:shared_preferences/shared_preferences.dart';





class SessionService {
  static const _keyIdAkun = 'session_id_akun';

  final SharedPreferences _prefs;

  SessionService(this._prefs);




  Future<void> simpan(String idAkun) async {
    await _prefs.setString(_keyIdAkun, idAkun);
  }




  String? muatIdAkun() => _prefs.getString(_keyIdAkun);




  Future<void> hapus() async {
    await _prefs.remove(_keyIdAkun);
  }
}
