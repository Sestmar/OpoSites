package com.oposites.api.model.dto.response;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
public class ConversacionResponse {

    private Long id;
    private String nombreRama;
    private String fechaExamen;
    private List<String> temasDebiles;
    private LocalDateTime createdAt;
}
