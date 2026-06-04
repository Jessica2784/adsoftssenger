package com.adsoftssenger.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CrearConversacionRequest {

    private Long usuario1Id;
    private Long usuario2Id;
}
