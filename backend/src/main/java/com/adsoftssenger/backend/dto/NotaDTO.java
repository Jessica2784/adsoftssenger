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
public class NotaDTO {

    private Long id;
    private Long usuarioId;
    private String nombreMostrar;
    private String nombreUsuario;
    private String fotoPerfilUrl;
    private String contenido;
    private LocalDateTime fechaCreacion;
}
