package com.adsoftssenger.backend.dto;

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
public class ConversacionDTO {

    private Long id;
    private String nombreContacto;
    private String fotoContactoUrl;
    private String ultimoMensaje;
    private LocalDateTime fechaUltimoMensaje;
}
