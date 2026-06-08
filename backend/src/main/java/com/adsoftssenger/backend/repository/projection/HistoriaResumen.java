package com.adsoftssenger.backend.repository.projection;

import java.time.LocalDateTime;

public interface HistoriaResumen {

    Long getId();

    Long getUsuarioId();

    String getNombreMostrar();

    String getFotoPerfilUrl();

    Boolean getTieneFotoPerfil();

    String getImagenUrl();

    LocalDateTime getFechaPublicacion();

    LocalDateTime getFechaCreacion();

    LocalDateTime getFechaExpiracion();

    Boolean getActiva();
}
