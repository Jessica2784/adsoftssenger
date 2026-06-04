package com.adsoftssenger.backend.controller;

import com.adsoftssenger.backend.dto.CrearConversacionRequest;
import com.adsoftssenger.backend.service.ConversacionService;
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
@RequestMapping("/api/conversaciones")
@RequiredArgsConstructor
public class ConversacionController {

    private final ConversacionService conversacionService;

    @PostMapping
    public ResponseEntity<?> crearConversacion(@RequestBody CrearConversacionRequest request) {
        try {
            return ResponseEntity.status(HttpStatus.CREATED).body(conversacionService.crearConversacion(request));
        } catch (EntityNotFoundException exception) {
            return notFound(exception.getMessage());
        } catch (IllegalArgumentException exception) {
            return badRequest(exception.getMessage());
        } catch (Exception exception) {
            return serverError("No se pudo crear la conversacion");
        }
    }

    @GetMapping("/usuario/{usuarioId}")
    public ResponseEntity<?> listarConversacionesPorUsuario(@PathVariable Long usuarioId) {
        try {
            return ResponseEntity.ok(conversacionService.listarConversacionesPorUsuario(usuarioId));
        } catch (EntityNotFoundException exception) {
            return notFound(exception.getMessage());
        } catch (Exception exception) {
            return serverError("No se pudieron listar las conversaciones");
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
