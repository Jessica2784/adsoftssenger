package com.adsoftssenger.backend.service;

import com.adsoftssenger.backend.dto.NotaDTO;
import com.adsoftssenger.backend.dto.NotaRequest;
import com.adsoftssenger.backend.model.UserNote;
import com.adsoftssenger.backend.model.Usuario;
import com.adsoftssenger.backend.repository.UserNoteRepository;
import jakarta.persistence.EntityNotFoundException;
import java.time.LocalDateTime;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

@Service
@RequiredArgsConstructor
@Transactional
public class NotaService {

    private static final Logger log = LoggerFactory.getLogger(NotaService.class);
    private static final int MAX_LENGTH = 60;

    private final UserNoteRepository userNoteRepository;
    private final UsuarioService usuarioService;

    public NotaDTO crearNota(Long usuarioId, NotaRequest request) {
        Usuario usuario = usuarioService.obtenerEntidadPorId(usuarioId);
        String contenido = validarContenido(request);

        desactivarNotasActivas(usuarioId);
        UserNote nota = userNoteRepository.save(UserNote.builder()
                .usuario(usuario)
                .contenido(contenido)
                .activa(true)
                .build());
        log.info("Nota {} creada para usuario {}", nota.getId(), usuarioId);
        return toDTO(nota);
    }

    public List<NotaDTO> listarNotasActivas() {
        LocalDateTime fechaMinima = LocalDateTime.now().minusHours(24);
        desactivarNotasExpiradas(fechaMinima);
        return userNoteRepository.findByActivaTrueAndFechaCreacionAfterOrderByFechaCreacionDesc(fechaMinima)
                .stream()
                .map(this::toDTO)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<NotaDTO> listarNotasPorUsuario(Long usuarioId) {
        usuarioService.obtenerUsuarioPorId(usuarioId);
        return userNoteRepository.findByUsuarioIdOrderByFechaCreacionDesc(usuarioId)
                .stream()
                .map(this::toDTO)
                .toList();
    }

    public NotaDTO desactivarNota(Long notaId) {
        UserNote nota = obtenerNota(notaId);
        nota.setActiva(false);
        log.info("Nota {} desactivada", notaId);
        return toDTO(nota);
    }

    public void eliminarNota(Long notaId) {
        UserNote nota = obtenerNota(notaId);
        nota.setActiva(false);
        log.info("Nota {} eliminada logicamente", notaId);
    }

    private void desactivarNotasActivas(Long usuarioId) {
        List<UserNote> activas = userNoteRepository.findByUsuarioIdAndActivaTrue(usuarioId);
        activas.forEach(nota -> nota.setActiva(false));
        userNoteRepository.saveAll(activas);
    }

    private void desactivarNotasExpiradas(LocalDateTime fechaMinima) {
        List<UserNote> expiradas = userNoteRepository.findAll()
                .stream()
                .filter(UserNote::isActiva)
                .filter(nota -> nota.getFechaCreacion() != null && nota.getFechaCreacion().isBefore(fechaMinima))
                .toList();
        expiradas.forEach(nota -> nota.setActiva(false));
        userNoteRepository.saveAll(expiradas);
    }

    private UserNote obtenerNota(Long notaId) {
        return userNoteRepository.findById(notaId)
                .orElseThrow(() -> new EntityNotFoundException("Nota no encontrada con id " + notaId));
    }

    private String validarContenido(NotaRequest request) {
        if (request == null || !StringUtils.hasText(request.getContenido())) {
            throw new IllegalArgumentException("El contenido de la nota es obligatorio");
        }
        String contenido = request.getContenido().trim();
        if (contenido.length() > MAX_LENGTH) {
            throw new IllegalArgumentException("La nota no puede superar 60 caracteres");
        }
        return contenido;
    }

    private NotaDTO toDTO(UserNote nota) {
        Usuario usuario = nota.getUsuario();
        return NotaDTO.builder()
                .id(nota.getId())
                .usuarioId(usuario.getId())
                .nombreMostrar(usuario.getNombreMostrar())
                .nombreUsuario(usuario.getNombreUsuario())
                .fotoPerfilUrl(usuarioService.resolveFotoPerfilUrl(usuario))
                .contenido(nota.getContenido())
                .fechaCreacion(nota.getFechaCreacion())
                .build();
    }
}
