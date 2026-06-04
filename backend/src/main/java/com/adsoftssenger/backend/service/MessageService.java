package com.adsoftssenger.backend.service;

import com.adsoftssenger.backend.dto.MessageRequest;
import com.adsoftssenger.backend.dto.MessageResponse;
import com.adsoftssenger.backend.model.AppUser;
import com.adsoftssenger.backend.model.Chat;
import com.adsoftssenger.backend.model.Message;
import com.adsoftssenger.backend.repository.MessageRepository;
import jakarta.persistence.EntityNotFoundException;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Transactional
public class MessageService {

    private final MessageRepository messageRepository;
    private final ChatService chatService;
    private final AppUserService appUserService;

    @Transactional(readOnly = true)
    public List<MessageResponse> findAll() {
        return messageRepository.findAll(Sort.by(Sort.Direction.DESC, "sentAt"))
                .stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<MessageResponse> findByChatId(Long chatId) {
        chatService.getEntity(chatId);

        return messageRepository.findByChatIdOrderBySentAtAsc(chatId)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public MessageResponse findById(Long id) {
        return toResponse(getEntity(id));
    }

    public MessageResponse create(MessageRequest request) {
        Chat chat = chatService.getEntity(request.getChatId());
        AppUser sender = appUserService.getEntity(request.getSenderId());

        Message message = Message.builder()
                .chat(chat)
                .sender(sender)
                .content(request.getContent())
                .build();

        return toResponse(messageRepository.save(message));
    }

    public void delete(Long id) {
        Message message = getEntity(id);
        messageRepository.delete(message);
    }

    private Message getEntity(Long id) {
        return messageRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Mensaje no encontrado con id " + id));
    }

    private MessageResponse toResponse(Message message) {
        return MessageResponse.builder()
                .id(message.getId())
                .chatId(message.getChat().getId())
                .sender(appUserService.toResponse(message.getSender()))
                .content(message.getContent())
                .sentAt(message.getSentAt())
                .build();
    }
}
