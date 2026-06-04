package com.adsoftssenger.backend.repository;

import com.adsoftssenger.backend.model.Conversacion;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ConversacionRepository extends JpaRepository<Conversacion, Long> {

    List<Conversacion> findByParticipantesId(Long usuarioId);
}
