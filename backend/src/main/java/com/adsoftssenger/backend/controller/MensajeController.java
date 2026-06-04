package com.adsoftssenger.backend.controller;

import com.adsoftssenger.backend.dto.EnviarMensajeRequest;
import com.adsoftssenger.backend.service.MensajeService;
import jakarta.persistence.EntityNotFoundException;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

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
