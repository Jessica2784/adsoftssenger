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
public class HistoriaDTO {

    private Long id;
    private Long usuarioId;
    private String nombreMostrar;
    private String usuarioNombre;
    private String fotoPerfilUrl;
    private String imagenUrl;
    private LocalDateTime fechaPublicacion;
    private LocalDateTime fechaCreacion;
    private LocalDateTime fechaExpiracion;
    private boolean activa;
    private boolean vista;
    private boolean propia;
}
