package com.adsoftssenger.backend.repository;

import com.adsoftssenger.backend.model.Usuario;
import com.adsoftssenger.backend.repository.projection.UsuarioResumen;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface UsuarioRepository extends JpaRepository<Usuario, Long> {

    Optional<Usuario> findByCorreo(String correo);

    Optional<Usuario> findByNombreUsuario(String nombreUsuario);

    @Query("""
            select u.id as id,
                   u.nombreUsuario as nombreUsuario,
                   u.nombreMostrar as nombreMostrar,
                   u.correo as correo,
                   u.fotoPerfilUrl as fotoPerfilUrl,
                   case when u.fotoPerfil is not null then true else false end as tieneFotoPerfil,
                   u.estadoActivo as estadoActivo
            from Usuario u
            order by u.nombreMostrar
            """)
    List<UsuarioResumen> listarResumenUsuarios();

    @Query("""
            select u.id as id,
                   u.nombreUsuario as nombreUsuario,
                   u.nombreMostrar as nombreMostrar,
                   u.correo as correo,
                   u.fotoPerfilUrl as fotoPerfilUrl,
                   case when u.fotoPerfil is not null then true else false end as tieneFotoPerfil,
                   u.estadoActivo as estadoActivo
            from Usuario u
            where u.id = :id
            """)
    Optional<UsuarioResumen> obtenerResumenPorId(@Param("id") Long id);
}
