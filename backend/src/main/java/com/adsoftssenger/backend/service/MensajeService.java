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
import com.adsoftssenger.backend.repository.projection.MensajeResumen;
import jakarta.persistence.EntityNotFoundException;
import java.io.IOException;
import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

@Service
@RequiredArgsConstructor
@Transactional
public class MensajeService {

    private static final Logger log = LoggerFactory.getLogger(MensajeService.class);
    private static final long MAX_IMAGE_SIZE = 6L * 1024L * 1024L;

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
        log.info("Mensaje {} enviado en conversacion {} por usuario {}", mensajeGuardado.getId(), conversacion.getId(), remitente.getId());

        return toDTO(mensajeGuardado, Estado.ENVIADO);
    }

    public MensajeDTO enviarImagen(Long conversacionId, Long remitenteId, MultipartFile imagen) {
        Conversacion conversacion = obtenerConversacion(conversacionId);
        Usuario remitente = obtenerUsuario(remitenteId);
        validarRemitenteEnConversacion(conversacion, remitente);
        validarImagen(imagen);

        try {
            LocalDateTime fechaEnvio = LocalDateTime.now();
            Mensaje mensaje = mensajeRepository.save(Mensaje.builder()
                    .conversacion(conversacion)
                    .remitente(remitente)
                    .contenido("Foto")
                    .tipoMensaje(TipoMensaje.IMAGEN_URL)
                    .adjunto(imagen.getBytes())
                    .adjuntoTipo(imagen.getContentType() == null ? "image/jpeg" : imagen.getContentType())
                    .fechaEnvio(fechaEnvio)
                    .build());
            crearEstadosIniciales(mensaje, conversacion, remitente, fechaEnvio);
            log.info("Imagen mensaje {} enviada en conversacion {} por usuario {}", mensaje.getId(), conversacionId, remitenteId);
            return toDTO(mensaje, Estado.ENVIADO);
        } catch (IOException exception) {
            throw new IllegalArgumentException("No se pudo leer la imagen seleccionada");
        }
    }

    public void eliminarMensaje(Long mensajeId) {
        Mensaje mensaje = mensajeRepository.findById(mensajeId)
                .orElseThrow(() -> new EntityNotFoundException("Mensaje no encontrado con id " + mensajeId));
        Long conversacionId = mensaje.getConversacion().getId();
        estadoMensajeRepository.deleteByMensajeId(mensajeId);
        mensajeRepository.delete(mensaje);
        log.info("Mensaje {} eliminado de conversacion {}", mensajeId, conversacionId);
    }

    @Transactional(readOnly = true)
    public ImagenData obtenerImagen(Long mensajeId) {
        Mensaje mensaje = mensajeRepository.findById(mensajeId)
                .orElseThrow(() -> new EntityNotFoundException("Mensaje no encontrado con id " + mensajeId));
        if (mensaje.getAdjunto() == null || mensaje.getAdjunto().length == 0) {
            throw new EntityNotFoundException("El mensaje no contiene una imagen");
        }
        String tipo = mensaje.getAdjuntoTipo() == null ? "image/jpeg" : mensaje.getAdjuntoTipo();
        return new ImagenData(mensaje.getAdjunto(), tipo);
    }

    @Transactional(readOnly = true)
    public List<MensajeDTO> listarMensajesPorConversacion(Long conversacionId) {
        obtenerConversacion(conversacionId);

        return mensajeRepository.listarResumenPorConversacion(conversacionId)
                .stream()
                .map(this::toDTO)
                .toList();
    }

    private String resolveUrlAdjunto(Mensaje mensaje) {
        if (mensaje.getAdjunto() != null && mensaje.getAdjunto().length > 0) {
            return "/api/mensajes/" + mensaje.getId() + "/imagen";
        }
        return mensaje.getUrlAdjunto();
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

    private Estado resolveEstado(Long mensajeId) {
        return estadoMensajeRepository.findByMensajeId(mensajeId)
                .stream()
                .map(EstadoMensaje::getEstado)
                .max(Comparator.comparingInt(Enum::ordinal))
                .orElse(Estado.ENVIADO);
    }

    public record ImagenData(byte[] contenido, String tipoContenido) {
    }

    private MensajeDTO toDTO(MensajeResumen mensaje) {
        String urlAdjunto = Boolean.TRUE.equals(mensaje.getTieneAdjunto())
                ? "/api/mensajes/" + mensaje.getId() + "/imagen"
                : mensaje.getUrlAdjunto();

        return MensajeDTO.builder()
                .id(mensaje.getId())
                .contenido(mensaje.getContenido())
                .tipoMensaje(mensaje.getTipoMensaje())
                .fechaEnvio(mensaje.getFechaEnvio())
                .remitenteId(mensaje.getRemitenteId())
                .remitenteNombre(mensaje.getRemitenteNombre())
                .conversacionId(mensaje.getConversacionId())
                .urlAdjunto(urlAdjunto)
                .estado(resolveEstado(mensaje.getId()))
                .build();
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
                .urlAdjunto(resolveUrlAdjunto(mensaje))
                .estado(estado)
                .build();
    }
}
