package com.adsoftssenger.backend.controller;

import com.adsoftssenger.backend.dto.EnviarMensajeRequest;
import com.adsoftssenger.backend.service.MensajeService;
import jakarta.persistence.EntityNotFoundException;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/mensajes")
@RequiredArgsConstructor
public class MensajeController {

    private final MensajeService mensajeService;

    @PostMapping
    public ResponseEntity<?> enviarMensaje(@RequestBody EnviarMensajeRequest request) {
        try {
            return ResponseEntity.status(HttpStatus.CREATED).body(mensajeService.enviarMensaje(request));
        } catch (EntityNotFoundException exception) {
            return notFound(exception.getMessage());
        } catch (IllegalArgumentException exception) {
            return badRequest(exception.getMessage());
        } catch (Exception exception) {
            return serverError("No se pudo enviar el mensaje");
        }
    }

    @PostMapping(path = "/imagen", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<?> enviarImagen(
            @RequestParam Long conversacionId,
            @RequestParam Long remitenteId,
            @RequestPart("imagen") MultipartFile imagen
    ) {
        try {
            return ResponseEntity.status(HttpStatus.CREATED)
                    .body(mensajeService.enviarImagen(conversacionId, remitenteId, imagen));
        } catch (EntityNotFoundException exception) {
            return notFound(exception.getMessage());
        } catch (IllegalArgumentException exception) {
            return badRequest(exception.getMessage());
        } catch (Exception exception) {
            return serverError("No se pudo enviar la imagen");
        }
    }

    @DeleteMapping("/{mensajeId}")
    public ResponseEntity<?> eliminarMensaje(@PathVariable Long mensajeId) {
        try {
            mensajeService.eliminarMensaje(mensajeId);
            return ResponseEntity.ok(Map.of("mensaje", "Mensaje eliminado"));
        } catch (EntityNotFoundException exception) {
            return notFound(exception.getMessage());
        } catch (Exception exception) {
            return serverError("No se pudo eliminar el mensaje");
        }
    }

    @GetMapping("/{mensajeId}/imagen")
    public ResponseEntity<byte[]> obtenerImagen(@PathVariable Long mensajeId) {
        MensajeService.ImagenData imagen = mensajeService.obtenerImagen(mensajeId);
        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(imagen.tipoContenido()))
                .body(imagen.contenido());
    }

    @GetMapping("/conversacion/{conversacionId}")
    public ResponseEntity<?> listarMensajesPorConversacion(@PathVariable Long conversacionId) {
        try {
            return ResponseEntity.ok(mensajeService.listarMensajesPorConversacion(conversacionId));
        } catch (EntityNotFoundException exception) {
            return notFound(exception.getMessage());
        } catch (Exception exception) {
            return serverError("No se pudieron listar los mensajes");
        }
    }

    private ResponseEntity<Map<String, String>> badRequest(String message) {
        return ResponseEntity.badRequest().body(error(message));
    }

    private ResponseEntity<Map<String, String>> notFound(String message) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error(message));
    }

    private ResponseEntity<Map<String, String>> serverError(String message) {
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error(message));
    }

    private Map<String, String> error(String message) {
        return Map.of("mensaje", message);
    }
}
