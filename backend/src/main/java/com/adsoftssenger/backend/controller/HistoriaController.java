package com.adsoftssenger.backend.controller;

import com.adsoftssenger.backend.dto.HistoriaDTO;
import com.adsoftssenger.backend.service.HistoriaService;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/historias")
@RequiredArgsConstructor
public class HistoriaController {

    private final HistoriaService historiaService;

    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<HistoriaDTO> crearHistoria(
            @RequestParam Long usuarioId,
            @RequestPart("imagen") MultipartFile imagen
    ) {
        return ResponseEntity.ok(historiaService.crearHistoria(usuarioId, imagen));
    }

    @GetMapping
    public ResponseEntity<List<HistoriaDTO>> listarHistorias(@RequestParam Long usuarioActualId) {
        return ResponseEntity.ok(historiaService.listarHistorias(usuarioActualId));
    }

    @GetMapping("/{historiaId}/imagen")
    public ResponseEntity<byte[]> obtenerImagen(@PathVariable Long historiaId) {
        HistoriaService.ImagenData imagen = historiaService.obtenerImagen(historiaId);
        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(imagen.tipoContenido()))
                .body(imagen.contenido());
    }

    @PostMapping("/{historiaId}/vistas/{usuarioId}")
    public ResponseEntity<HistoriaDTO> marcarVista(
            @PathVariable Long historiaId,
            @PathVariable Long usuarioId
    ) {
        return ResponseEntity.ok(historiaService.marcarVista(historiaId, usuarioId));
    }

    @DeleteMapping("/{historiaId}")
    public ResponseEntity<Void> eliminarHistoria(
            @PathVariable Long historiaId,
            @RequestParam Long usuarioId
    ) {
        historiaService.eliminarHistoria(historiaId, usuarioId);
        return ResponseEntity.noContent().build();
    }
}
