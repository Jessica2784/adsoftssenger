import 'api_service.dart';

class UsuarioService {
  final ApiService _apiService;

  UsuarioService({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  Future<Map<String, dynamic>> registrarUsuario(Map<String, dynamic> usuario) {
    return _apiService.postMap('/usuarios/registro', usuario);
  }

  Future<Map<String, dynamic>> login(Map<String, dynamic> credenciales) {
    return _apiService.postMap('/usuarios/login', credenciales);
  }

  Future<List<dynamic>> obtenerUsuarios() {
    return _apiService.getList('/usuarios');
  }

  void close() {
    _apiService.close();
  }
}
