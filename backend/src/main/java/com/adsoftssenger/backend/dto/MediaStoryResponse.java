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
public class MediaStoryResponse {

    private Long id;
    private Long usuarioId;
    private String usuarioNombre;
    private String imagenUrl;
    private LocalDateTime fechaCreacion;
    private String message;
}
