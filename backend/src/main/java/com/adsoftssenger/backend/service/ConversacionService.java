package com.adsoftssenger.backend.service;

import com.adsoftssenger.backend.dto.ConversacionDTO;
import com.adsoftssenger.backend.dto.CrearConversacionRequest;
import com.adsoftssenger.backend.model.Conversacion;
import com.adsoftssenger.backend.model.Estado;
import com.adsoftssenger.backend.model.EstadoMensaje;
import com.adsoftssenger.backend.model.Usuario;
import com.adsoftssenger.backend.repository.ConversacionRepository;
import com.adsoftssenger.backend.repository.EstadoMensajeRepository;
import com.adsoftssenger.backend.repository.MensajeRepository;
import com.adsoftssenger.backend.repository.UsuarioRepository;
import com.adsoftssenger.backend.repository.projection.UltimoMensajeResumen;
import jakarta.persistence.EntityNotFoundException;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Transactional
public class ConversacionService {

    private static final Logger log = LoggerFactory.getLogger(ConversacionService.class);

    private final ConversacionRepository conversacionRepository;
    private final UsuarioRepository usuarioRepository;
    private final MensajeRepository mensajeRepository;
    private final EstadoMensajeRepository estadoMensajeRepository;
    private final UsuarioService usuarioService;

    public ConversacionDTO crearConversacion(CrearConversacionRequest request) {
        validarCrearConversacion(request);
        Conversacion conversacion = obtenerOCrearConversacionIndividual(
                request.getUsuario1Id(),
                request.getUsuario2Id()
        );
        return toDTO(conversacion, request.getUsuario1Id());
    }

    public Conversacion obtenerOCrearConversacionIndividual(Long usuario1Id, Long usuario2Id) {
        if (usuario1Id == null || usuario2Id == null) {
            throw new IllegalArgumentException("Los ids de usuarios son obligatorios");
        }
        if (usuario1Id.equals(usuario2Id)) {
            throw new IllegalArgumentException("La conversacion requiere dos usuarios diferentes");
        }

        Usuario usuario1 = obtenerUsuario(usuario1Id);
        Usuario usuario2 = obtenerUsuario(usuario2Id);

        Conversacion conversacionExistente = buscarConversacionIndividual(usuario1, usuario2);
        if (conversacionExistente != null) {
            log.debug("Conversacion existente {} para usuarios {} y {}", conversacionExistente.getId(), usuario1Id, usuario2Id);
            return conversacionExistente;
        }

        Conversacion conversacion = Conversacion.builder()
                .esGrupal(false)
                .participantes(new ArrayList<>(List.of(usuario1, usuario2)))
                .build();
        Conversacion guardada = conversacionRepository.save(conversacion);
        log.info("Conversacion creada {} para usuarios {} y {}", guardada.getId(), usuario1Id, usuario2Id);
        return guardada;
    }

    @Transactional(readOnly = true)
    public List<ConversacionDTO> listarConversacionesPorUsuario(Long usuarioId) {
        obtenerUsuario(usuarioId);

        List<ConversacionDTO> conversaciones = conversacionRepository.findByParticipantesId(usuarioId)
                .stream()
                .map(conversacion -> toDTO(conversacion, usuarioId))
                .sorted(Comparator
                        .comparing(
                                ConversacionDTO::getFechaUltimoMensaje,
                                Comparator.nullsLast(Comparator.reverseOrder())
                        )
                        .thenComparing(ConversacionDTO::getId, Comparator.reverseOrder()))
                .toList();
        log.debug("Conversaciones listadas para usuario {}: {}", usuarioId, conversaciones.size());
        return conversaciones;
    }

    public void marcarConversacionComoLeida(Long conversacionId, Long usuarioId) {
        Conversacion conversacion = obtenerEntidadPorId(conversacionId);
        Usuario usuario = obtenerUsuario(usuarioId);
        validarUsuarioEnConversacion(conversacion, usuario);

        List<EstadoMensaje> noLeidos = estadoMensajeRepository
                .findByMensajeConversacionIdAndDestinatarioIdAndEstadoNot(
                        conversacionId,
                        usuarioId,
                        Estado.LEIDO
                );

        LocalDateTime now = LocalDateTime.now();
        noLeidos.forEach(estadoMensaje -> {
            estadoMensaje.setEstado(Estado.LEIDO);
            estadoMensaje.setFechaActualizacion(now);
        });
        estadoMensajeRepository.saveAll(noLeidos);
        log.info("Conversacion {} marcada como leida para usuario {}. Mensajes actualizados: {}", conversacionId, usuarioId, noLeidos.size());
    }

    @Transactional(readOnly = true)
    public Conversacion obtenerEntidadPorId(Long id) {
        return conversacionRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Conversacion no encontrada con id " + id));
    }

    public ConversacionDTO toDTO(Conversacion conversacion, Long usuarioActualId) {
        Usuario contacto = obtenerContacto(conversacion, usuarioActualId);
        UltimoMensajeResumen ultimoMensaje = obtenerUltimoMensaje(conversacion);
        int cantidadNoLeidos = usuarioActualId == null
                ? 0
                : Math.toIntExact(estadoMensajeRepository
                        .countByMensajeConversacionIdAndDestinatarioIdAndEstadoNot(
                                conversacion.getId(),
                                usuarioActualId,
                                Estado.LEIDO
                        ));

        return ConversacionDTO.builder()
                .id(conversacion.getId())
                .nombreContacto(resolveNombreContacto(conversacion, contacto))
                .fotoContactoUrl(contacto != null ? usuarioService.resolveFotoPerfilUrl(contacto) : null)
                .ultimoMensaje(ultimoMensaje != null ? resolveUltimoMensaje(ultimoMensaje) : null)
                .fechaUltimoMensaje(ultimoMensaje != null ? ultimoMensaje.getFechaEnvio() : null)
                .tieneMensajesNoLeidos(cantidadNoLeidos > 0)
                .cantidadMensajesNoLeidos(cantidadNoLeidos)
                .build();
    }

    private void validarCrearConversacion(CrearConversacionRequest request) {
        if (request == null || request.getUsuario1Id() == null || request.getUsuario2Id() == null) {
            throw new IllegalArgumentException("Los ids de usuarios son obligatorios");
        }
        if (request.getUsuario1Id().equals(request.getUsuario2Id())) {
            throw new IllegalArgumentException("La conversacion requiere dos usuarios diferentes");
        }
    }

    private Usuario obtenerUsuario(Long id) {
        return usuarioRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Usuario no encontrado con id " + id));
    }

    private Conversacion buscarConversacionIndividual(Usuario usuario1, Usuario usuario2) {
        return conversacionRepository.findByParticipantesId(usuario1.getId())
                .stream()
                .filter(conversacion -> !conversacion.isEsGrupal())
                .filter(conversacion -> conversacion.getParticipantes().size() == 2)
                .filter(conversacion -> contieneParticipante(conversacion, usuario1))
                .filter(conversacion -> contieneParticipante(conversacion, usuario2))
                .min(Comparator.comparing(Conversacion::getId))
                .orElse(null);
    }

    private boolean contieneParticipante(Conversacion conversacion, Usuario usuario) {
        return conversacion.getParticipantes()
                .stream()
                .anyMatch(participante -> participante.getId().equals(usuario.getId()));
    }

    private void validarUsuarioEnConversacion(Conversacion conversacion, Usuario usuario) {
        if (!contieneParticipante(conversacion, usuario)) {
            throw new IllegalArgumentException("El usuario no pertenece a la conversacion");
        }
    }

    private Usuario obtenerContacto(Conversacion conversacion, Long usuarioActualId) {
        if (conversacion.isEsGrupal()) {
            return null;
        }

        return conversacion.getParticipantes()
                .stream()
                .filter(usuario -> usuarioActualId == null || !usuario.getId().equals(usuarioActualId))
                .findFirst()
                .orElse(null);
    }

    private UltimoMensajeResumen obtenerUltimoMensaje(Conversacion conversacion) {
        return mensajeRepository.findFirstByConversacionIdOrderByFechaEnvioDesc(conversacion.getId())
                .orElse(null);
    }

    private String resolveUltimoMensaje(UltimoMensajeResumen mensaje) {
        if (mensaje.getTipoMensaje() == com.adsoftssenger.backend.model.TipoMensaje.IMAGEN_URL) {
            return "Foto";
        }
        return mensaje.getContenido();
    }

    private String resolveNombreContacto(Conversacion conversacion, Usuario contacto) {
        if (conversacion.isEsGrupal()) {
            return conversacion.getNombreGrupo();
        }

        return contacto != null ? contacto.getNombreMostrar() : null;
    }
}
