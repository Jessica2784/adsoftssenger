package com.adsoftssenger.backend.service;

import com.adsoftssenger.backend.dto.EnviarMensajeRequest;
import com.adsoftssenger.backend.dto.MensajeDTO;
import com.adsoftssenger.backend.model.Conversacion;
import com.adsoftssenger.backend.model.Estado;
import com.adsoftssenger.backend.model.EstadoMensaje;
import com.adsoftssenger.backend.model.Mensaje;
import com.adsoftssenger.backend.model.TipoMensaje;
import com.adsoftssenger.backend.model.Usuario;
import com.adsoftssenger.backend.repository.ConversacionRepository;
import com.adsoftssenger.backend.repository.EstadoMensajeRepository;
import com.adsoftssenger.backend.repository.MensajeRepository;
import com.adsoftssenger.backend.repository.UsuarioRepository;
import jakarta.persistence.EntityNotFoundException;
import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

@Service
@RequiredArgsConstructor
@Transactional
public class MensajeService {

    private final MensajeRepository mensajeRepository;
    private final ConversacionRepository conversacionRepository;
    private final UsuarioRepository usuarioRepository;
    private final EstadoMensajeRepository estadoMensajeRepository;

    public MensajeDTO enviarMensaje(EnviarMensajeRequest request) {
        validarEnviarMensaje(request);

        Conversacion conversacion = obtenerConversacion(request.getConversacionId());
        Usuario remitente = obtenerUsuario(request.getRemitenteId());
        validarRemitenteEnConversacion(conversacion, remitente);

        TipoMensaje tipoMensaje = request.getTipoMensaje() == null ? TipoMensaje.TEXTO : request.getTipoMensaje();
        LocalDateTime fechaEnvio = LocalDateTime.now();

        Mensaje mensaje = Mensaje.builder()
                .conversacion(conversacion)
                .remitente(remitente)
                .contenido(request.getContenido())
                .tipoMensaje(tipoMensaje)
                .urlAdjunto(request.getUrlAdjunto())
                .duracionAudioSeg(request.getDuracionAudioSeg())
                .fechaEnvio(fechaEnvio)
                .build();

        Mensaje mensajeGuardado = mensajeRepository.save(mensaje);
        crearEstadosIniciales(mensajeGuardado, conversacion, remitente, fechaEnvio);

        return toDTO(mensajeGuardado, Estado.ENVIADO);
    }

    @Transactional(readOnly = true)
    public List<MensajeDTO> listarMensajesPorConversacion(Long conversacionId) {
        obtenerConversacion(conversacionId);

        return mensajeRepository.findByConversacionIdOrderByFechaEnvioAsc(conversacionId)
                .stream()
                .map(mensaje -> toDTO(mensaje, resolveEstado(mensaje)))
                .toList();
    }

    private void validarEnviarMensaje(EnviarMensajeRequest request) {
        if (request == null) {
            throw new IllegalArgumentException("Los datos del mensaje son obligatorios");
        }
        if (request.getConversacionId() == null) {
            throw new IllegalArgumentException("La conversacion es obligatoria");
        }
        if (request.getRemitenteId() == null) {
            throw new IllegalArgumentException("El remitente es obligatorio");
        }

        TipoMensaje tipoMensaje = request.getTipoMensaje() == null ? TipoMensaje.TEXTO : request.getTipoMensaje();
        if (tipoMensaje == TipoMensaje.TEXTO && !StringUtils.hasText(request.getContenido())) {
            throw new IllegalArgumentException("No se puede enviar un mensaje de texto vacio");
        }
    }

    private Conversacion obtenerConversacion(Long id) {
        return conversacionRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Conversacion no encontrada con id " + id));
    }

    private Usuario obtenerUsuario(Long id) {
        return usuarioRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Usuario no encontrado con id " + id));
    }

    private void validarRemitenteEnConversacion(Conversacion conversacion, Usuario remitente) {
        boolean pertenece = conversacion.getParticipantes()
                .stream()
                .anyMatch(usuario -> usuario.getId().equals(remitente.getId()));

        if (!pertenece) {
            throw new IllegalArgumentException("El remitente no pertenece a la conversacion");
        }
    }

    private void crearEstadosIniciales(Mensaje mensaje, Conversacion conversacion, Usuario remitente, LocalDateTime fechaEnvio) {
        List<EstadoMensaje> estados = conversacion.getParticipantes()
                .stream()
                .filter(usuario -> !usuario.getId().equals(remitente.getId()))
                .map(destinatario -> EstadoMensaje.builder()
                        .mensaje(mensaje)
                        .destinatario(destinatario)
                        .estado(Estado.ENVIADO)
                        .fechaActualizacion(fechaEnvio)
                        .build())
                .toList();

        estadoMensajeRepository.saveAll(estados);
    }

    private Estado resolveEstado(Mensaje mensaje) {
        return estadoMensajeRepository.findByMensajeId(mensaje.getId())
                .stream()
                .map(EstadoMensaje::getEstado)
                .max(Comparator.comparingInt(Enum::ordinal))
                .orElse(Estado.ENVIADO);
    }

    private MensajeDTO toDTO(Mensaje mensaje, Estado estado) {
        return MensajeDTO.builder()
                .id(mensaje.getId())
                .contenido(mensaje.getContenido())
                .tipoMensaje(mensaje.getTipoMensaje())
                .fechaEnvio(mensaje.getFechaEnvio())
                .remitenteId(mensaje.getRemitente().getId())
                .remitenteNombre(mensaje.getRemitente().getNombreMostrar())
                .conversacionId(mensaje.getConversacion().getId())
                .estado(estado)
                .build();
    }
}
