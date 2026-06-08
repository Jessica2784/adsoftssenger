package com.adsoftssenger.backend.controller;

import com.adsoftssenger.backend.dto.HistoriaDTO;
import com.adsoftssenger.backend.service.HistoriaService;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
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
}
