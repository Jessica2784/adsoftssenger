package com.adsoftssenger.backend.dto;

import com.adsoftssenger.backend.model.ChatType;
import jakarta.validation.constraints.Size;
import java.util.Set;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ChatRequest {

    @Size(max = 120)
    private String name;

    private ChatType type;

    private Set<Long> participantIds;
}
