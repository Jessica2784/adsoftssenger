package com.adsoftssenger.backend.repository;

import com.adsoftssenger.backend.model.Chat;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ChatRepository extends JpaRepository<Chat, Long> {
}
