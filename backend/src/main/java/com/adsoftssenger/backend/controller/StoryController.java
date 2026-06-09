package com.adsoftssenger.backend.controller;

import com.adsoftssenger.backend.dto.HistoriaDTO;
import com.adsoftssenger.backend.dto.ResponderHistoriaRequest;
import com.adsoftssenger.backend.service.HistoriaService;
import jakarta.persistence.EntityNotFoundException;
import java.util.List;
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
@RequestMapping("/api/stories")
@RequiredArgsConstructor
public class StoryController {

    private final HistoriaService historiaService;

    @GetMapping
    public ResponseEntity<List<HistoriaDTO>> listarHistorias() {
        return ResponseEntity.ok(historiaService.listarHistoriasActivas());
    }

    @GetMapping("/usuario/{usuarioId}")
    public ResponseEntity<List<HistoriaDTO>> listarHistoriasPorUsuario(@PathVariable Long usuarioId) {
        return ResponseEntity.ok(historiaService.listarHistoriasActivasPorUsuario(usuarioId));
    }

    @PostMapping("/{storyId}/responder")
    public ResponseEntity<?> responderHistoria(
            @PathVariable Long storyId,
            @RequestBody ResponderHistoriaRequest request
    ) {
        try {
            return ResponseEntity.status(HttpStatus.CREATED).body(historiaService.responderHistoria(storyId, request));
        } catch (EntityNotFoundException exception) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error(exception.getMessage()));
        } catch (IllegalArgumentException exception) {
            return ResponseEntity.badRequest().body(error(exception.getMessage()));
        } catch (Exception exception) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error("No se pudo responder la historia"));
        }
    }

    private Map<String, String> error(String message) {
        return Map.of("mensaje", message);
    }
}
