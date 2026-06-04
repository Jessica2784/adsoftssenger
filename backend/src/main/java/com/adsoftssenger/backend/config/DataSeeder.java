package com.adsoftssenger.backend.config;

import com.adsoftssenger.backend.model.Conversacion;
import com.adsoftssenger.backend.model.Estado;
import com.adsoftssenger.backend.model.EstadoMensaje;
import com.adsoftssenger.backend.model.Mensaje;
import com.adsoftssenger.backend.model.TipoMensaje;
import com.adsoftssenger.backend.model.Usuario;
import com.adsoftssenger.backend.repository.ConversacionRepository;
import com.adsoftssenger.backend.repository.EstadoMensajeRepository;
import com.adsoftssenger.backend.repository.MensajeRepository;
import com.adsoftssenger.backend.repository.UsuarioRepository;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

@Component
@RequiredArgsConstructor
public class DataSeeder implements CommandLineRunner {

    private static final String DEFAULT_PASSWORD_HASH = "1234";

    private final UsuarioRepository usuarioRepository;
    private final ConversacionRepository conversacionRepository;
    private final MensajeRepository mensajeRepository;
    private final EstadoMensajeRepository estadoMensajeRepository;

    @Override
    @Transactional
    public void run(String... args) {
        Usuario jessica = obtenerOCrearUsuario(new SeedUser("jessica", "Jessica", "jessica@test.com"));

        crearChatPredeterminado(
                jessica,
                new SeedUser("adolfo", "Adolfo", "adolfo@test.com"),
                "Jessica, recuerda revisar el avance del proyecto."
        );
        crearChatPredeterminado(
                jessica,
                new SeedUser("carlos", "Carlos", "carlos@test.com"),
                "¿Ya terminaste la parte de Flutter?"
        );
        crearChatPredeterminado(
                jessica,
                new SeedUser("maria", "María", "maria@test.com"),
                "Estoy estudiando para el examen."
        );
        crearChatPredeterminado(
                jessica,
                new SeedUser("lucia", "Lucía", "lucia@test.com"),
                "Nos vemos en clase."
        );
        crearChatPredeterminado(
                jessica,
                new SeedUser("luis", "Luis García", "luis@test.com"),
                "Ya quedó la conexión con Spring Boot."
        );
        crearChatPredeterminado(
                jessica,
                new SeedUser("mateo", "Mateo Fernández", "mateo@test.com"),
                "Te mandé los datos de prueba."
        );
        crearChatPredeterminado(
                jessica,
                new SeedUser("elena", "Elena Rodríguez", "elena@test.com"),
                "Revisa el apartado de personas."
        );
    }

    private Usuario obtenerOCrearUsuario(SeedUser seedUser) {
        return usuarioRepository.findByNombreUsuario(seedUser.nombreUsuario())
                .or(() -> usuarioRepository.findByCorreo(seedUser.correo()))
                .orElseGet(() -> usuarioRepository.save(Usuario.builder()
                        .nombreUsuario(seedUser.nombreUsuario())
                        .nombreMostrar(seedUser.nombreMostrar())
                        .correo(seedUser.correo())
                        .passwordHash(DEFAULT_PASSWORD_HASH)
                        .fotoPerfilUrl(null)
                        .estadoActivo(true)
                        .build()));
    }

    private void crearChatPredeterminado(Usuario jessica, SeedUser contactoSeed, String mensajePredeterminado) {
        Usuario contacto = obtenerOCrearUsuario(contactoSeed);
        Conversacion conversacion = buscarConversacionIndividual(jessica, contacto)
                .orElseGet(() -> conversacionRepository.save(Conversacion.builder()
                        .esGrupal(false)
                        .participantes(new ArrayList<>(List.of(jessica, contacto)))
                        .build()));

        if (!mensajeRepository.findByConversacionIdOrderByFechaEnvioAsc(conversacion.getId()).isEmpty()) {
            return;
        }

        guardarMensaje(conversacion, contacto, mensajePredeterminado);
    }

    private Optional<Conversacion> buscarConversacionIndividual(Usuario usuario1, Usuario usuario2) {
        return conversacionRepository.findByParticipantesId(usuario1.getId())
                .stream()
                .filter(conversacion -> !conversacion.isEsGrupal())
                .filter(conversacion -> conversacion.getParticipantes().size() == 2)
                .filter(conversacion -> contieneParticipante(conversacion, usuario1)
                        && contieneParticipante(conversacion, usuario2))
                .findFirst();
    }

    private boolean contieneParticipante(Conversacion conversacion, Usuario usuario) {
        return conversacion.getParticipantes()
                .stream()
                .anyMatch(participante -> participante.getId().equals(usuario.getId()));
    }

    private void guardarMensaje(Conversacion conversacion, Usuario remitente, String contenido) {
        Mensaje mensaje = mensajeRepository.save(Mensaje.builder()
                .conversacion(conversacion)
                .remitente(remitente)
                .contenido(contenido)
                .tipoMensaje(TipoMensaje.TEXTO)
                .build());

        conversacion.getParticipantes()
                .stream()
                .filter(destinatario -> !destinatario.getId().equals(remitente.getId()))
                .map(destinatario -> EstadoMensaje.builder()
                        .mensaje(mensaje)
                        .destinatario(destinatario)
                        .estado(Estado.ENVIADO)
                        .build())
                .forEach(estadoMensajeRepository::save);
    }

    private record SeedUser(String nombreUsuario, String nombreMostrar, String correo) {
    }
}
