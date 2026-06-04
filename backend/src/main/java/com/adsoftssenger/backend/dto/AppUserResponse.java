package com.adsoftssenger.backend.dto;

import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AppUserResponse {

    private Long id;
    private String username;
    private String displayName;
    private String email;
    private String avatarUrl;
    private LocalDateTime createdAt;
}
