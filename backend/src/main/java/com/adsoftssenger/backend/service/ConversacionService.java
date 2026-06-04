package com.adsoftssenger.backend.service;

import com.adsoftssenger.backend.dto.ConversacionDTO;
import com.adsoftssenger.backend.dto.CrearConversacionRequest;
import com.adsoftssenger.backend.model.Conversacion;
import com.adsoftssenger.backend.model.Mensaje;
import com.adsoftssenger.backend.model.Usuario;
import com.adsoftssenger.backend.repository.ConversacionRepository;
import com.adsoftssenger.backend.repository.UsuarioRepository;
import jakarta.persistence.EntityNotFoundException;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Transactional
public class ConversacionService {

    private final ConversacionRepository conversacionRepository;
    private final UsuarioRepository usuarioRepository;

    public ConversacionDTO crearConversacion(CrearConversacionRequest request) {
        validarCrearConversacion(request);

        Usuario usuario1 = obtenerUsuario(request.getUsuario1Id());
        Usuario usuario2 = obtenerUsuario(request.getUsuario2Id());

        Conversacion conversacionExistente = buscarConversacionIndividual(usuario1, usuario2);
        if (conversacionExistente != null) {
            return toDTO(conversacionExistente, usuario1.getId());
        }

        Conversacion conversacion = Conversacion.builder()
                .esGrupal(false)
                .participantes(new ArrayList<>(List.of(usuario1, usuario2)))
                .build();

        return toDTO(conversacionRepository.save(conversacion), usuario1.getId());
    }

    @Transactional(readOnly = true)
    public List<ConversacionDTO> listarConversacionesPorUsuario(Long usuarioId) {
        obtenerUsuario(usuarioId);

        return conversacionRepository.findByParticipantesId(usuarioId)
                .stream()
                .map(conversacion -> toDTO(conversacion, usuarioId))
                .toList();
    }

    @Transactional(readOnly = true)
    public Conversacion obtenerEntidadPorId(Long id) {
        return conversacionRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Conversacion no encontrada con id " + id));
    }

    public ConversacionDTO toDTO(Conversacion conversacion, Long usuarioActualId) {
        Usuario contacto = obtenerContacto(conversacion, usuarioActualId);
        Mensaje ultimoMensaje = obtenerUltimoMensaje(conversacion);

        return ConversacionDTO.builder()
                .id(conversacion.getId())
                .nombreContacto(resolveNombreContacto(conversacion, contacto))
                .fotoContactoUrl(contacto != null ? contacto.getFotoPerfilUrl() : null)
                .ultimoMensaje(ultimoMensaje != null ? ultimoMensaje.getContenido() : null)
                .fechaUltimoMensaje(ultimoMensaje != null ? ultimoMensaje.getFechaEnvio() : null)
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

    private Mensaje obtenerUltimoMensaje(Conversacion conversacion) {
        return conversacion.getMensajes()
                .stream()
                .max(Comparator.comparing(Mensaje::getFechaEnvio, Comparator.nullsLast(Comparator.naturalOrder())))
                .orElse(null);
    }

    private String resolveNombreContacto(Conversacion conversacion, Usuario contacto) {
        if (conversacion.isEsGrupal()) {
            return conversacion.getNombreGrupo();
        }

        return contacto != null ? contacto.getNombreMostrar() : null;
    }
}
