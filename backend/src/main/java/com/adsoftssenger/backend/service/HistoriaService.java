package com.adsoftssenger.backend.service;

import com.adsoftssenger.backend.dto.EnviarMensajeRequest;
import com.adsoftssenger.backend.dto.HistoriaDTO;
import com.adsoftssenger.backend.dto.MensajeDTO;
import com.adsoftssenger.backend.dto.ResponderHistoriaRequest;
import com.adsoftssenger.backend.model.Historia;
import com.adsoftssenger.backend.model.Conversacion;
import com.adsoftssenger.backend.model.HistoriaVista;
import com.adsoftssenger.backend.model.TipoMensaje;
import com.adsoftssenger.backend.model.Usuario;
import com.adsoftssenger.backend.repository.HistoriaRepository;
import com.adsoftssenger.backend.repository.HistoriaVistaRepository;
import com.adsoftssenger.backend.repository.projection.HistoriaResumen;
import jakarta.persistence.EntityNotFoundException;
import java.io.IOException;
import java.time.LocalDateTime;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

@Service
@RequiredArgsConstructor
@Transactional
public class HistoriaService {

    private static final long MAX_IMAGE_SIZE = 6L * 1024L * 1024L;

    private final HistoriaRepository historiaRepository;
    private final HistoriaVistaRepository historiaVistaRepository;
    private final UsuarioService usuarioService;
    private final ConversacionService conversacionService;
    private final MensajeService mensajeService;

    public HistoriaDTO crearHistoria(Long usuarioId, MultipartFile imagen) {
        Usuario usuario = usuarioService.obtenerEntidadPorId(usuarioId);
        validarImagen(imagen);

        try {
            Historia historia = historiaRepository.save(Historia.builder()
                    .usuario(usuario)
                    .imagen(imagen.getBytes())
                    .tipoContenido(resolveContentType(imagen))
                    .activa(true)
                    .build());
            return toDTO(historia, usuarioId);
        } catch (IOException exception) {
            throw new IllegalArgumentException("No se pudo leer la imagen seleccionada");
        }
    }

    public HistoriaDTO crearHistoriaCloudinary(Usuario usuario, String imagenUrl, String tipoContenido) {
        if (usuario == null || usuario.getId() == null) {
            throw new EntityNotFoundException("Usuario no encontrado");
        }
        if (!StringUtils.hasText(imagenUrl)) {
            throw new IllegalArgumentException("La URL de la historia es obligatoria");
        }

        Historia historia = historiaRepository.save(Historia.builder()
                .usuario(usuario)
                .imagen(new byte[0])
                .tipoContenido(resolveContentType(tipoContenido))
                .imagenUrl(imagenUrl)
                .activa(true)
                .build());
        return toDTO(historia, usuario.getId());
    }

    @Transactional(readOnly = true)
    public List<HistoriaDTO> listarHistorias(Long usuarioActualId) {
        usuarioService.obtenerUsuarioPorId(usuarioActualId);
        return historiaRepository.listarHistoriasActivas(LocalDateTime.now())
                .stream()
                .map(historia -> toDTO(historia, usuarioActualId))
                .toList();
    }

    @Transactional(readOnly = true)
    public List<HistoriaDTO> listarHistoriasActivas() {
        return historiaRepository.listarHistoriasActivas(LocalDateTime.now())
                .stream()
                .map(historia -> toDTO(historia, null))
                .toList();
    }

    @Transactional(readOnly = true)
    public List<HistoriaDTO> listarHistoriasActivasPorUsuario(Long usuarioId) {
        usuarioService.obtenerUsuarioPorId(usuarioId);
        return historiaRepository.listarHistoriasActivasPorUsuario(usuarioId, LocalDateTime.now())
                .stream()
                .map(historia -> toDTO(historia, usuarioId))
                .toList();
    }

    public HistoriaDTO marcarVista(Long historiaId, Long usuarioId) {
        Historia historia = obtenerEntidadPorId(historiaId);
        Usuario usuario = usuarioService.obtenerEntidadPorId(usuarioId);

        if (!historia.getUsuario().getId().equals(usuarioId)
                && historiaVistaRepository.findByHistoriaIdAndUsuarioId(historiaId, usuarioId).isEmpty()) {
            historiaVistaRepository.save(HistoriaVista.builder()
                    .historia(historia)
                    .usuario(usuario)
                    .build());
        }

        return toDTO(historia, usuarioId);
    }

    public void eliminarHistoria(Long historiaId, Long usuarioId) {
        Historia historia = obtenerEntidadPorId(historiaId);
        if (!historia.getUsuario().getId().equals(usuarioId)) {
            throw new IllegalArgumentException("Solo puedes eliminar tus propias historias");
        }
        historiaVistaRepository.deleteByHistoriaId(historiaId);
        historiaRepository.delete(historia);
    }


    public MensajeDTO responderHistoria(Long historiaId, ResponderHistoriaRequest request) {
        if (request == null || request.getUsuarioId() == null) {
            throw new IllegalArgumentException("El usuario que responde es obligatorio");
        }
        if (!StringUtils.hasText(request.getRespuesta())) {
            throw new IllegalArgumentException("Escribe una respuesta para enviar");
        }

        Historia historia = obtenerEntidadPorId(historiaId);
        Long duenioId = historia.getUsuario().getId();
        Long usuarioId = request.getUsuarioId();
        if (duenioId.equals(usuarioId)) {
            throw new IllegalArgumentException("No puedes responder tu propia historia");
        }

        String respuesta = request.getRespuesta().trim();
        Conversacion conversacion = conversacionService.obtenerOCrearConversacionIndividual(usuarioId, duenioId);
        EnviarMensajeRequest mensajeRequest = EnviarMensajeRequest.builder()
                .conversacionId(conversacion.getId())
                .remitenteId(usuarioId)
                .contenido("Respondió a tu estado: " + respuesta)
                .tipoMensaje(TipoMensaje.TEXTO)
                .build();
        return mensajeService.enviarMensaje(mensajeRequest);
    }

    @Transactional(readOnly = true)
    public ImagenData obtenerImagen(Long historiaId) {
        Historia historia = obtenerEntidadPorId(historiaId);
        byte[] contenido = historia.getImagen();
        if ((contenido == null || contenido.length == 0) && StringUtils.hasText(historia.getImagenUrl())) {
            throw new EntityNotFoundException("La imagen de esta historia esta disponible en Cloudinary");
        }
        return new ImagenData(contenido, historia.getTipoContenido());
    }

    @Transactional(readOnly = true)
    public Historia obtenerEntidadPorId(Long id) {
        return historiaRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Historia no encontrada con id " + id));
    }

    private HistoriaDTO toDTO(Historia historia, Long usuarioActualId) {
        Usuario autor = historia.getUsuario();
        boolean propia = usuarioActualId != null && autor.getId().equals(usuarioActualId);
        boolean vista = usuarioActualId != null
                && (propia || historiaVistaRepository.existsByHistoriaIdAndUsuarioId(historia.getId(), usuarioActualId));
        LocalDateTime fechaCreacion = resolveFechaCreacion(historia.getFechaCreacion(), historia.getFechaPublicacion());

        return HistoriaDTO.builder()
                .id(historia.getId())
                .usuarioId(autor.getId())
                .nombreMostrar(autor.getNombreMostrar())
                .usuarioNombre(autor.getNombreMostrar())
                .fotoPerfilUrl(usuarioService.resolveFotoPerfilUrl(autor))
                .imagenUrl(resolveImagenUrl(historia.getId(), historia.getImagenUrl()))
                .fechaPublicacion(resolveFechaPublicacion(historia.getFechaPublicacion(), fechaCreacion))
                .fechaCreacion(fechaCreacion)
                .fechaExpiracion(historia.getFechaExpiracion())
                .activa(resolveActiva(historia.getActiva()))
                .vista(vista)
                .propia(propia)
                .build();
    }

    private HistoriaDTO toDTO(HistoriaResumen historia, Long usuarioActualId) {
        boolean propia = usuarioActualId != null && historia.getUsuarioId().equals(usuarioActualId);
        boolean vista = usuarioActualId != null && (propia || historiaVistaRepository
                .existsByHistoriaIdAndUsuarioId(historia.getId(), usuarioActualId));
        LocalDateTime fechaCreacion = resolveFechaCreacion(historia.getFechaCreacion(), historia.getFechaPublicacion());

        return HistoriaDTO.builder()
                .id(historia.getId())
                .usuarioId(historia.getUsuarioId())
                .nombreMostrar(historia.getNombreMostrar())
                .usuarioNombre(historia.getNombreMostrar())
                .fotoPerfilUrl(usuarioService.resolveFotoPerfilUrl(
                        historia.getUsuarioId(),
                        historia.getFotoPerfilUrl(),
                        Boolean.TRUE.equals(historia.getTieneFotoPerfil())
                ))
                .imagenUrl(resolveImagenUrl(historia.getId(), historia.getImagenUrl()))
                .fechaPublicacion(resolveFechaPublicacion(historia.getFechaPublicacion(), fechaCreacion))
                .fechaCreacion(fechaCreacion)
                .fechaExpiracion(historia.getFechaExpiracion())
                .activa(resolveActiva(historia.getActiva()))
                .vista(vista)
                .propia(propia)
                .build();
    }

    private void validarImagen(MultipartFile imagen) {
        if (imagen == null || imagen.isEmpty()) {
            throw new IllegalArgumentException("Debes seleccionar una imagen");
        }
        if (imagen.getSize() > MAX_IMAGE_SIZE) {
            throw new IllegalArgumentException("La imagen no puede superar 6 MB");
        }
        String contentType = imagen.getContentType();
        if (contentType == null || !contentType.startsWith("image/")) {
            throw new IllegalArgumentException("El archivo seleccionado debe ser una imagen");
        }
    }

    private String resolveContentType(MultipartFile imagen) {
        return imagen.getContentType() == null ? "image/jpeg" : imagen.getContentType();
    }

    private String resolveContentType(String contentType) {
        return StringUtils.hasText(contentType) ? contentType : "image/jpeg";
    }

    private String resolveImagenUrl(Long historiaId, String imagenUrl) {
        return StringUtils.hasText(imagenUrl) ? imagenUrl : "/api/historias/" + historiaId + "/imagen";
    }

    private LocalDateTime resolveFechaCreacion(LocalDateTime fechaCreacion, LocalDateTime fechaPublicacion) {
        return fechaCreacion == null ? fechaPublicacion : fechaCreacion;
    }

    private LocalDateTime resolveFechaPublicacion(LocalDateTime fechaPublicacion, LocalDateTime fechaCreacion) {
        return fechaPublicacion == null ? fechaCreacion : fechaPublicacion;
    }

    private boolean resolveActiva(Boolean activa) {
        return activa == null || activa;
    }

    public record ImagenData(byte[] contenido, String tipoContenido) {
    }
}
