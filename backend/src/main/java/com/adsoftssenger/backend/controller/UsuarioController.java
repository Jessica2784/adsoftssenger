package com.adsoftssenger.backend.controller;

import com.adsoftssenger.backend.dto.LoginRequest;
import com.adsoftssenger.backend.dto.RegistroRequest;
import com.adsoftssenger.backend.service.UsuarioService;
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
@RequestMapping("/api/usuarios")
@RequiredArgsConstructor
public class UsuarioController {

    private final UsuarioService usuarioService;

    @PostMapping("/registro")
    public ResponseEntity<?> registrarUsuario(@RequestBody RegistroRequest request) {
        try {
            return ResponseEntity.status(HttpStatus.CREATED).body(usuarioService.registrarUsuario(request));
        } catch (IllegalArgumentException exception) {
            return badRequest(exception.getMessage());
        } catch (Exception exception) {
            return serverError("No se pudo registrar el usuario");
        }
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequest request) {
        try {
            return ResponseEntity.ok(usuarioService.login(request));
        } catch (IllegalArgumentException exception) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(error(exception.getMessage()));
        } catch (Exception exception) {
            return serverError("No se pudo iniciar sesion");
        }
    }

    @GetMapping
    public ResponseEntity<?> listarUsuarios() {
        try {
            return ResponseEntity.ok(usuarioService.listarUsuarios());
        } catch (Exception exception) {
            return serverError("No se pudieron listar los usuarios");
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> obtenerUsuarioPorId(@PathVariable Long id) {
        try {
            return ResponseEntity.ok(usuarioService.obtenerUsuarioPorId(id));
        } catch (EntityNotFoundException exception) {
            return notFound(exception.getMessage());
        } catch (Exception exception) {
            return serverError("No se pudo obtener el usuario");
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
