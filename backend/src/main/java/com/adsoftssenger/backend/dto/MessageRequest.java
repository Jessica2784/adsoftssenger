package com.adsoftssenger.backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class MessageRequest {

    @NotNull
    private Long chatId;

    @NotNull
    private Long senderId;

    @NotBlank
    @Size(max = 4000)
    private String content;
}
