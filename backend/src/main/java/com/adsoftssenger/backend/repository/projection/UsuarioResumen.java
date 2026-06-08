package com.adsoftssenger.backend.repository.projection;

public interface UsuarioResumen {

    Long getId();

    String getNombreUsuario();

    String getNombreMostrar();

    String getCorreo();

    String getFotoPerfilUrl();

    Boolean getTieneFotoPerfil();

    Boolean getEstadoActivo();
}
