package com.adsoftssenger.backend.repository;

import com.adsoftssenger.backend.model.EstadoMensaje;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface EstadoMensajeRepository extends JpaRepository<EstadoMensaje, Long> {

    List<EstadoMensaje> findByMensajeId(Long mensajeId);
}
