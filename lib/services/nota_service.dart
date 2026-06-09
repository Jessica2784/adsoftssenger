import '../models/note_model.dart';
import 'api_service.dart';

class NotaService {
  final ApiService _apiService;

  NotaService({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  Future<List<NoteModel>> obtenerNotasActivas() async {
    final response = await _apiService.getList('/notas/activas');
    return response.map(NoteModel.fromJson).toList(growable: false);
  }

  Future<NoteModel> crearNota(Object usuarioId, String contenido) async {
    final encodedUsuarioId = Uri.encodeComponent(usuarioId.toString());
    final response = await _apiService.postMap('/notas/$encodedUsuarioId', {
      'contenido': contenido,
    });
    return NoteModel.fromJson(response);
  }

  Future<void> desactivarNota(Object notaId) async {
    final encodedNotaId = Uri.encodeComponent(notaId.toString());
    await _apiService.putMap('/notas/$encodedNotaId/desactivar', {});
  }

  Future<void> eliminarNota(Object notaId) async {
    final encodedNotaId = Uri.encodeComponent(notaId.toString());
    await _apiService.delete('/notas/$encodedNotaId');
  }

  void close() {
    _apiService.close();
  }
}
