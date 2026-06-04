package com.adsoftssenger.backend.service;

import com.adsoftssenger.backend.dto.LoginRequest;
import com.adsoftssenger.backend.dto.RegistroRequest;
import com.adsoftssenger.backend.dto.UsuarioDTO;
import com.adsoftssenger.backend.model.Usuario;
import com.adsoftssenger.backend.repository.UsuarioRepository;
import jakarta.persistence.EntityNotFoundException;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Sort;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

@Service
@RequiredArgsConstructor
@Transactional
public class UsuarioService {

    private final UsuarioRepository usuarioRepository;
    private final PasswordEncoder passwordEncoder;

    public UsuarioDTO registrarUsuario(RegistroRequest request) {
        validarRegistro(request);

        usuarioRepository.findByCorreo(request.getCorreo())
                .ifPresent(usuario -> {
                    throw new IllegalArgumentException("El correo ya esta registrado");
                });

        usuarioRepository.findByNombreUsuario(request.getNombreUsuario())
                .ifPresent(usuario -> {
                    throw new IllegalArgumentException("El nombre de usuario ya esta registrado");
                });

        Usuario usuario = Usuario.builder()
                .nombreUsuario(request.getNombreUsuario())
                .nombreMostrar(request.getNombreMostrar())
                .correo(request.getCorreo())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .estadoActivo(true)
                .build();

        return toDTO(usuarioRepository.save(usuario));
    }

    @Transactional(readOnly = true)
    public UsuarioDTO login(LoginRequest request) {
        if (request == null || !StringUtils.hasText(request.getCorreo()) || !StringUtils.hasText(request.getPassword())) {
            throw new IllegalArgumentException("Correo y password son obligatorios");
        }

        Usuario usuario = usuarioRepository.findByCorreo(request.getCorreo())
                .orElseThrow(() -> new IllegalArgumentException("Credenciales invalidas"));

        if (!passwordEncoder.matches(request.getPassword(), usuario.getPasswordHash())) {
            throw new IllegalArgumentException("Credenciales invalidas");
        }

        return toDTO(usuario);
    }

    @Transactional(readOnly = true)
    public List<UsuarioDTO> listarUsuarios() {
        return usuarioRepository.findAll(Sort.by("nombreMostrar"))
                .stream()
                .map(this::toDTO)
                .toList();
    }

    @Transactional(readOnly = true)
    public UsuarioDTO obtenerUsuarioPorId(Long id) {
        return toDTO(obtenerEntidadPorId(id));
    }

    @Transactional(readOnly = true)
    public Usuario obtenerEntidadPorId(Long id) {
        return usuarioRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Usuario no encontrado con id " + id));
    }

    public UsuarioDTO toDTO(Usuario usuario) {
        return UsuarioDTO.builder()
                .id(usuario.getId())
                .nombreUsuario(usuario.getNombreUsuario())
                .nombreMostrar(usuario.getNombreMostrar())
                .correo(usuario.getCorreo())
                .fotoPerfilUrl(usuario.getFotoPerfilUrl())
                .estadoActivo(usuario.isEstadoActivo())
                .build();
    }

    private void validarRegistro(RegistroRequest request) {
        if (request == null) {
            throw new IllegalArgumentException("Los datos de registro son obligatorios");
        }
        if (!StringUtils.hasText(request.getNombreUsuario())) {
            throw new IllegalArgumentException("El nombre de usuario es obligatorio");
        }
        if (!StringUtils.hasText(request.getNombreMostrar())) {
            throw new IllegalArgumentException("El nombre para mostrar es obligatorio");
        }
        if (!StringUtils.hasText(request.getCorreo())) {
            throw new IllegalArgumentException("El correo es obligatorio");
        }
        if (!StringUtils.hasText(request.getPassword())) {
            throw new IllegalArgumentException("El password es obligatorio");
        }
    }
}
