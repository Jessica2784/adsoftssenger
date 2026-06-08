package com.adsoftssenger.backend.service;

import com.adsoftssenger.backend.dto.CambiarPerfilRequest;
import com.adsoftssenger.backend.dto.LoginRequest;
import com.adsoftssenger.backend.dto.RegistroRequest;
import com.adsoftssenger.backend.dto.UsuarioDTO;
import com.adsoftssenger.backend.model.Usuario;
import com.adsoftssenger.backend.repository.UsuarioRepository;
import com.adsoftssenger.backend.repository.projection.UsuarioResumen;
import jakarta.persistence.EntityNotFoundException;
import java.io.IOException;
import java.util.List;
import java.util.Set;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

@Service
@RequiredArgsConstructor
@Transactional
public class UsuarioService {

    private static final long MAX_PROFILE_IMAGE_SIZE = 6L * 1024L * 1024L;
    private static final Set<String> USUARIOS_PREDETERMINADOS = Set.of(
            "jessica", "adolfo", "carlos", "maria", "lucia", "luis", "mateo", "elena"
    );

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
                .fotoPerfilUrl(null)
                .fotoPerfil(null)
                .fotoPerfilTipo(null)
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
    public UsuarioDTO validarCambioPerfil(Long usuarioId, CambiarPerfilRequest request) {
        Usuario usuario = obtenerEntidadPorId(usuarioId);
        if (esPredeterminado(usuario)) {
            return toDTO(usuario);
        }

        String password = request == null ? null : request.getPassword();
        if (!StringUtils.hasText(password) || !passwordEncoder.matches(password, usuario.getPasswordHash())) {
            throw new IllegalArgumentException("Contraseña incorrecta");
        }

        return toDTO(usuario);
    }

    public UsuarioDTO actualizarFotoPerfil(Long usuarioId, MultipartFile imagen) {
        Usuario usuario = obtenerEntidadPorId(usuarioId);
        validarImagen(imagen);

        try {
            usuario.setFotoPerfil(imagen.getBytes());
            usuario.setFotoPerfilTipo(imagen.getContentType() == null ? "image/jpeg" : imagen.getContentType());
            usuario.setFotoPerfilUrl(null);
            return toDTO(usuarioRepository.save(usuario));
        } catch (IOException exception) {
            throw new IllegalArgumentException("No se pudo leer la imagen seleccionada");
        }
    }

    public UsuarioDTO eliminarFotoPerfil(Long usuarioId) {
        Usuario usuario = obtenerEntidadPorId(usuarioId);
        usuario.setFotoPerfil(null);
        usuario.setFotoPerfilTipo(null);
        usuario.setFotoPerfilUrl(null);
        return toDTO(usuarioRepository.save(usuario));
    }

    public Usuario guardarFotoPerfilUrl(Usuario usuario, String fotoPerfilUrl) {
        if (usuario == null) {
            throw new EntityNotFoundException("Usuario no encontrado");
        }
        if (!StringUtils.hasText(fotoPerfilUrl)) {
            throw new IllegalArgumentException("La URL de la foto de perfil es obligatoria");
        }
        usuario.setFotoPerfilUrl(fotoPerfilUrl);
        usuario.setFotoPerfil(null);
        usuario.setFotoPerfilTipo(null);
        return usuarioRepository.save(usuario);
    }

    @Transactional(readOnly = true)
    public FotoPerfilData obtenerFotoPerfil(Long usuarioId) {
        Usuario usuario = obtenerEntidadPorId(usuarioId);
        if (usuario.getFotoPerfil() == null || usuario.getFotoPerfil().length == 0) {
            throw new EntityNotFoundException("El usuario no tiene foto de perfil");
        }
        String tipo = usuario.getFotoPerfilTipo() == null ? "image/jpeg" : usuario.getFotoPerfilTipo();
        return new FotoPerfilData(usuario.getFotoPerfil(), tipo);
    }

    @Transactional(readOnly = true)
    public List<UsuarioDTO> listarUsuarios() {
        return usuarioRepository.listarResumenUsuarios()
                .stream()
                .map(this::toDTO)
                .toList();
    }

    @Transactional(readOnly = true)
    public UsuarioDTO obtenerUsuarioPorId(Long id) {
        UsuarioResumen usuario = usuarioRepository.obtenerResumenPorId(id)
                .orElseThrow(() -> new EntityNotFoundException("Usuario no encontrado con id " + id));
        return toDTO(usuario);
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
                .fotoPerfilUrl(resolveFotoPerfilUrl(usuario))
                .estadoActivo(usuario.isEstadoActivo())
                .predeterminado(esPredeterminado(usuario))
                .build();
    }

    private UsuarioDTO toDTO(UsuarioResumen usuario) {
        return UsuarioDTO.builder()
                .id(usuario.getId())
                .nombreUsuario(usuario.getNombreUsuario())
                .nombreMostrar(usuario.getNombreMostrar())
                .correo(usuario.getCorreo())
                .fotoPerfilUrl(resolveFotoPerfilUrl(
                        usuario.getId(),
                        usuario.getFotoPerfilUrl(),
                        Boolean.TRUE.equals(usuario.getTieneFotoPerfil())
                ))
                .estadoActivo(Boolean.TRUE.equals(usuario.getEstadoActivo()))
                .predeterminado(esPredeterminado(usuario.getNombreUsuario()))
                .build();
    }

    public String resolveFotoPerfilUrl(Long usuarioId, String fotoPerfilUrl, boolean tieneFotoPerfil) {
        return tieneFotoPerfil ? "/api/usuarios/" + usuarioId + "/foto" : fotoPerfilUrl;
    }

    public String resolveFotoPerfilUrl(Usuario usuario) {
        if (usuario.getFotoPerfil() != null && usuario.getFotoPerfil().length > 0) {
            return "/api/usuarios/" + usuario.getId() + "/foto";
        }
        return usuario.getFotoPerfilUrl();
    }

    public boolean esPredeterminado(Usuario usuario) {
        return usuario != null && esPredeterminado(usuario.getNombreUsuario());
    }

    private boolean esPredeterminado(String nombreUsuario) {
        return nombreUsuario != null
                && USUARIOS_PREDETERMINADOS.contains(nombreUsuario.trim().toLowerCase());
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

    private void validarImagen(MultipartFile imagen) {
        if (imagen == null || imagen.isEmpty()) {
            throw new IllegalArgumentException("Debes seleccionar una imagen");
        }
        if (imagen.getSize() > MAX_PROFILE_IMAGE_SIZE) {
            throw new IllegalArgumentException("La imagen no puede superar 6 MB");
        }
        String contentType = imagen.getContentType();
        if (contentType == null || !contentType.startsWith("image/")) {
            throw new IllegalArgumentException("El archivo seleccionado debe ser una imagen");
        }
    }

    public record FotoPerfilData(byte[] contenido, String tipoContenido) {
    }
}
