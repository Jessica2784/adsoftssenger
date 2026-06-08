package com.adsoftssenger.backend.repository;

import com.adsoftssenger.backend.model.Mensaje;
import com.adsoftssenger.backend.repository.projection.MensajeResumen;
import com.adsoftssenger.backend.repository.projection.UltimoMensajeResumen;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface MensajeRepository extends JpaRepository<Mensaje, Long> {

    List<Mensaje> findByConversacionIdOrderByFechaEnvioAsc(Long conversacionId);

    @Query("""
            select m.id as id,
                   m.contenido as contenido,
                   m.tipoMensaje as tipoMensaje,
                   m.fechaEnvio as fechaEnvio,
                   m.remitente.id as remitenteId,
                   m.remitente.nombreMostrar as remitenteNombre,
                   m.conversacion.id as conversacionId,
                   m.urlAdjunto as urlAdjunto,
                   case when m.adjunto is not null then true else false end as tieneAdjunto
            from Mensaje m
            where m.conversacion.id = :conversacionId
            order by m.fechaEnvio asc
            """)
    List<MensajeResumen> listarResumenPorConversacion(@Param("conversacionId") Long conversacionId);

    Optional<UltimoMensajeResumen> findFirstByConversacionIdOrderByFechaEnvioDesc(Long conversacionId);
}
