package com.adsoftssenger.backend.repository;

import com.adsoftssenger.backend.model.Usuario;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UsuarioRepository extends JpaRepository<Usuario, Long> {

    Optional<Usuario> findByCorreo(String correo);

    Optional<Usuario> findByNombreUsuario(String nombreUsuario);
}
