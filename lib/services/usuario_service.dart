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

  Future<Map<String, dynamic>> validarCambioPerfil(
    Object usuarioId,
    String password,
  ) {
    return _apiService.postMap('/usuarios/$usuarioId/validar-acceso', {
      'password': password,
    });
  }

  Future<List<dynamic>> obtenerUsuarios() {
    return _apiService.getList('/usuarios');
  }

  Future<Map<String, dynamic>> obtenerUsuario(Object usuarioId) {
    return _apiService.getMap('/usuarios/$usuarioId');
  }

  void close() => _apiService.close();
}
