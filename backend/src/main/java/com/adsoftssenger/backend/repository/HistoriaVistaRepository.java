package com.adsoftssenger.backend.repository;

import com.adsoftssenger.backend.model.HistoriaVista;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface HistoriaVistaRepository extends JpaRepository<HistoriaVista, Long> {

    boolean existsByHistoriaIdAndUsuarioId(Long historiaId, Long usuarioId);

    Optional<HistoriaVista> findByHistoriaIdAndUsuarioId(Long historiaId, Long usuarioId);

    void deleteByHistoriaId(Long historiaId);
}

