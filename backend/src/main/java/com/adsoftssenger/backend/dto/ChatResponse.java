package com.adsoftssenger.backend.dto;

import com.adsoftssenger.backend.model.ChatType;
import java.time.LocalDateTime;
import java.util.List;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ChatResponse {

    private Long id;
    private String name;
    private ChatType type;
    private List<AppUserResponse> participants;
    private LocalDateTime createdAt;
}
