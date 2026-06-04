package com.adsoftssenger.backend.controller;

import com.adsoftssenger.backend.dto.ChatRequest;
import com.adsoftssenger.backend.dto.ChatResponse;
import com.adsoftssenger.backend.dto.MessageResponse;
import com.adsoftssenger.backend.service.ChatService;
import com.adsoftssenger.backend.service.MessageService;
import jakarta.validation.Valid;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/chats")
@RequiredArgsConstructor
public class ChatController {

    private final ChatService chatService;
    private final MessageService messageService;

    @GetMapping
    public List<ChatResponse> findAll() {
        return chatService.findAll();
    }

    @GetMapping("/{id}")
    public ChatResponse findById(@PathVariable Long id) {
        return chatService.findById(id);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ChatResponse create(@Valid @RequestBody ChatRequest request) {
        return chatService.create(request);
    }

    @PutMapping("/{id}")
    public ChatResponse update(@PathVariable Long id, @Valid @RequestBody ChatRequest request) {
        return chatService.update(id, request);
    }

    @GetMapping("/{chatId}/messages")
    public List<MessageResponse> findMessages(@PathVariable Long chatId) {
        return messageService.findByChatId(chatId);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        chatService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
