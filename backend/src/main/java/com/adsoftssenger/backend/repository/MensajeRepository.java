package com.adsoftssenger.backend.repository;

import com.adsoftssenger.backend.model.Mensaje;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface MensajeRepository extends JpaRepository<Mensaje, Long> {

    List<Mensaje> findByConversacionIdOrderByFechaEnvioAsc(Long conversacionId);
}
