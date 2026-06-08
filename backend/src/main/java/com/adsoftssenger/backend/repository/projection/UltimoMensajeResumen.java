package com.adsoftssenger.backend.repository.projection;

import com.adsoftssenger.backend.model.TipoMensaje;
import java.time.LocalDateTime;

public interface UltimoMensajeResumen {

    String getContenido();

    TipoMensaje getTipoMensaje();

    LocalDateTime getFechaEnvio();
}
