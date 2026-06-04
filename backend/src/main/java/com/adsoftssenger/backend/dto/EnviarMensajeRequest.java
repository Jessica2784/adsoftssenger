package com.adsoftssenger.backend.dto;

import com.adsoftssenger.backend.model.TipoMensaje;
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
public class EnviarMensajeRequest {

    private Long conversacionId;
    private Long remitenteId;
    private String contenido;
    private TipoMensaje tipoMensaje;
    private String urlAdjunto;
    private Integer duracionAudioSeg;
}
