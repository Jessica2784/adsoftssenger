package com.adsoftssenger.backend.controller;

import com.adsoftssenger.backend.dto.NotaRequest;
import com.adsoftssenger.backend.service.NotaService;
import jakarta.persistence.EntityNotFoundException;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/notas")
@RequiredArgsConstructor
public class NotaController {

    private final NotaService notaService;

    @PostMapping("/{usuarioId}")
    public ResponseEntity<?> crearNota(@PathVariable Long usuarioId, @RequestBody NotaRequest request) {
        try {
            return ResponseEntity.status(HttpStatus.CREATED).body(notaService.crearNota(usuarioId, request));
        } catch (EntityNotFoundException exception) {
            return notFound(exception.getMessage());
        } catch (IllegalArgumentException exception) {
            return badRequest(exception.getMessage());
        } catch (Exception exception) {
            return serverError("No se pudo crear la nota");
        }
    }

    @GetMapping("/activas")
    public ResponseEntity<?> listarNotasActivas() {
        try {
            return ResponseEntity.ok(notaService.listarNotasActivas());
        } catch (Exception exception) {
            return serverError("No se pudieron cargar las notas");
        }
    }

    @GetMapping("/usuario/{usuarioId}")
    public ResponseEntity<?> listarNotasPorUsuario(@PathVariable Long usuarioId) {
        try {
            return ResponseEntity.ok(notaService.listarNotasPorUsuario(usuarioId));
        } catch (EntityNotFoundException exception) {
            return notFound(exception.getMessage());
        } catch (Exception exception) {
            return serverError("No se pudieron cargar las notas del usuario");
        }
    }

    @PutMapping("/{notaId}/desactivar")
    public ResponseEntity<?> desactivarNota(@PathVariable Long notaId) {
        try {
            return ResponseEntity.ok(notaService.desactivarNota(notaId));
        } catch (EntityNotFoundException exception) {
            return notFound(exception.getMessage());
        } catch (Exception exception) {
            return serverError("No se pudo desactivar la nota");
        }
    }

    @DeleteMapping("/{notaId}")
    public ResponseEntity<?> eliminarNota(@PathVariable Long notaId) {
        try {
            notaService.eliminarNota(notaId);
            return ResponseEntity.ok(Map.of("mensaje", "Nota eliminada"));
        } catch (EntityNotFoundException exception) {
            return notFound(exception.getMessage());
        } catch (Exception exception) {
            return serverError("No se pudo eliminar la nota");
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
