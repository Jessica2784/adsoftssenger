package com.adsoftssenger.backend.repository;

import com.adsoftssenger.backend.model.Historia;
import com.adsoftssenger.backend.repository.projection.HistoriaResumen;
import java.time.LocalDateTime;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface HistoriaRepository extends JpaRepository<Historia, Long> {

    List<Historia> findByActivaTrueOrderByFechaCreacionDesc();

    List<Historia> findByUsuarioIdAndActivaTrueOrderByFechaCreacionDesc(Long usuarioId);

    @Query("""
            select h.id as id,
                   h.usuario.id as usuarioId,
                   h.usuario.nombreMostrar as nombreMostrar,
                   h.usuario.fotoPerfilUrl as fotoPerfilUrl,
                   case when h.usuario.fotoPerfil is not null then true else false end as tieneFotoPerfil,
                   h.imagenUrl as imagenUrl,
                   h.fechaPublicacion as fechaPublicacion,
                   h.fechaCreacion as fechaCreacion,
                   h.fechaExpiracion as fechaExpiracion,
                   h.activa as activa
            from Historia h
            where (h.activa = true or h.activa is null)
              and (h.fechaExpiracion is null or h.fechaExpiracion > :fecha)
            order by coalesce(h.fechaCreacion, h.fechaPublicacion) desc
            """)
    List<HistoriaResumen> listarHistoriasActivas(@Param("fecha") LocalDateTime fecha);

    @Query("""
            select h
            from Historia h
            where h.usuario.id = :usuarioId
              and (h.activa = true or h.activa is null)
              and (h.fechaExpiracion is null or h.fechaExpiracion > :fecha)
            order by coalesce(h.fechaCreacion, h.fechaPublicacion) desc
            """)
    List<Historia> listarHistoriasActivasPorUsuario(
            @Param("usuarioId") Long usuarioId,
            @Param("fecha") LocalDateTime fecha
    );
}
