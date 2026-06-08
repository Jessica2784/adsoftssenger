package com.adsoftssenger.backend.repository.projection;

import com.adsoftssenger.backend.model.TipoMensaje;
import java.time.LocalDateTime;

public interface MensajeResumen {

    Long getId();

    String getContenido();

    TipoMensaje getTipoMensaje();

    LocalDateTime getFechaEnvio();

    Long getRemitenteId();

    String getRemitenteNombre();

    Long getConversacionId();

    String getUrlAdjunto();

    Boolean getTieneAdjunto();
}
