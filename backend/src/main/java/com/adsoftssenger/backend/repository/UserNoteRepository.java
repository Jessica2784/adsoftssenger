package com.adsoftssenger.backend.repository;

import com.adsoftssenger.backend.model.UserNote;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserNoteRepository extends JpaRepository<UserNote, Long> {

    List<UserNote> findByActivaTrueAndFechaCreacionAfterOrderByFechaCreacionDesc(LocalDateTime fechaMinima);

    List<UserNote> findByUsuarioIdOrderByFechaCreacionDesc(Long usuarioId);

    List<UserNote> findByUsuarioIdAndActivaTrue(Long usuarioId);

    Optional<UserNote> findFirstByUsuarioIdAndActivaTrueOrderByFechaCreacionDesc(Long usuarioId);
}
