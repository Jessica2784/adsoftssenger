package com.adsoftssenger.backend.controller;

import com.adsoftssenger.backend.dto.HistoriaDTO;
import com.adsoftssenger.backend.dto.MediaProfilePhotoResponse;
import com.adsoftssenger.backend.dto.MediaStoryResponse;
import com.adsoftssenger.backend.model.Usuario;
import com.adsoftssenger.backend.service.CloudinaryService;
import com.adsoftssenger.backend.service.HistoriaService;
import com.adsoftssenger.backend.service.UsuarioService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/media")
@RequiredArgsConstructor
public class MediaController {

    private final CloudinaryService cloudinaryService;
    private final HistoriaService historiaService;
    private final UsuarioService usuarioService;

    @PostMapping(path = "/profile-photo/{usuarioId}", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<MediaProfilePhotoResponse> uploadProfilePhoto(
            @PathVariable Long usuarioId,
            @RequestPart("file") MultipartFile file
    ) {
        Usuario usuario = usuarioService.obtenerEntidadPorId(usuarioId);
        String fotoPerfilUrl = cloudinaryService.uploadProfilePhoto(file, usuario.getId());
        Usuario usuarioActualizado = usuarioService.guardarFotoPerfilUrl(usuario, fotoPerfilUrl);

        return ResponseEntity.ok(MediaProfilePhotoResponse.builder()
                .usuarioId(usuarioActualizado.getId())
                .fotoPerfilUrl(usuarioActualizado.getFotoPerfilUrl())
                .message("Foto de perfil subida correctamente")
                .build());
    }

    @PostMapping(path = "/stories/{usuarioId}", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<MediaStoryResponse> uploadStoryImage(
            @PathVariable Long usuarioId,
            @RequestPart("file") MultipartFile file
    ) {
        Usuario usuario = usuarioService.obtenerEntidadPorId(usuarioId);
        String imagenUrl = cloudinaryService.uploadStoryImage(file, usuario.getId());
        HistoriaDTO historia = historiaService.crearHistoriaCloudinary(usuario, imagenUrl, file.getContentType());

        return ResponseEntity.ok(MediaStoryResponse.builder()
                .id(historia.getId())
                .usuarioId(historia.getUsuarioId())
                .usuarioNombre(historia.getUsuarioNombre())
                .imagenUrl(historia.getImagenUrl())
                .fechaCreacion(historia.getFechaCreacion())
                .message("Historia subida correctamente")
                .build());
    }
}
