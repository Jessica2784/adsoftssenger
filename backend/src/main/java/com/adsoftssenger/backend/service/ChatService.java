package com.adsoftssenger.backend.service;

import com.adsoftssenger.backend.dto.ChatRequest;
import com.adsoftssenger.backend.dto.ChatResponse;
import com.adsoftssenger.backend.model.AppUser;
import com.adsoftssenger.backend.model.Chat;
import com.adsoftssenger.backend.model.ChatType;
import com.adsoftssenger.backend.repository.AppUserRepository;
import com.adsoftssenger.backend.repository.ChatRepository;
import jakarta.persistence.EntityNotFoundException;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Transactional
public class ChatService {

    private final ChatRepository chatRepository;
    private final AppUserRepository appUserRepository;
    private final AppUserService appUserService;

    @Transactional(readOnly = true)
    public List<ChatResponse> findAll() {
        return chatRepository.findAll(Sort.by(Sort.Direction.DESC, "createdAt"))
                .stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public ChatResponse findById(Long id) {
        return toResponse(getEntity(id));
    }

    public ChatResponse create(ChatRequest request) {
        Chat chat = Chat.builder()
                .name(request.getName())
                .type(resolveType(request.getType()))
                .participants(resolveParticipants(request.getParticipantIds()))
                .build();

        return toResponse(chatRepository.save(chat));
    }

    public ChatResponse update(Long id, ChatRequest request) {
        Chat chat = getEntity(id);

        chat.setName(request.getName());
        chat.setType(resolveType(request.getType()));
        chat.setParticipants(resolveParticipants(request.getParticipantIds()));

        return toResponse(chatRepository.save(chat));
    }

    public void delete(Long id) {
        Chat chat = getEntity(id);
        chatRepository.delete(chat);
    }

    @Transactional(readOnly = true)
    public Chat getEntity(Long id) {
        return chatRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Chat no encontrado con id " + id));
    }

    private ChatResponse toResponse(Chat chat) {
        return ChatResponse.builder()
                .id(chat.getId())
                .name(chat.getName())
                .type(chat.getType())
                .participants(chat.getParticipants()
                        .stream()
                        .map(appUserService::toResponse)
                        .toList())
                .createdAt(chat.getCreatedAt())
                .build();
    }

    private ChatType resolveType(ChatType type) {
        return type == null ? ChatType.DIRECT : type;
    }

    private Set<AppUser> resolveParticipants(Set<Long> participantIds) {
        if (participantIds == null || participantIds.isEmpty()) {
            return new LinkedHashSet<>();
        }

        Set<Long> requestedIds = new LinkedHashSet<>(participantIds);
        List<AppUser> participants = appUserRepository.findAllById(requestedIds);
        Set<Long> foundIds = participants.stream()
                .map(AppUser::getId)
                .collect(Collectors.toSet());

        requestedIds.removeAll(foundIds);
        if (!requestedIds.isEmpty()) {
            throw new EntityNotFoundException("Usuarios no encontrados con ids " + requestedIds);
        }

        return new LinkedHashSet<>(participants);
    }
}
