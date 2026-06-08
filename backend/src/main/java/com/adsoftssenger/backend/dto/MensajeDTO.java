package com.adsoftssenger.backend.dto;

import com.adsoftssenger.backend.model.Estado;
import com.adsoftssenger.backend.model.TipoMensaje;
import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MensajeDTO {

    private Long id;
    private String contenido;
    private TipoMensaje tipoMensaje;
    private LocalDateTime fechaEnvio;
    private Long remitenteId;
    private String remitenteNombre;
    private Long conversacionId;
    private String urlAdjunto;
    private Estado estado;
}
