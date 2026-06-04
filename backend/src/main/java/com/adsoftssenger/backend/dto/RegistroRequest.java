package com.adsoftssenger.backend.dto;

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
public class RegistroRequest {

    private String nombreUsuario;
    private String nombreMostrar;
    private String correo;
    private String password;
}
