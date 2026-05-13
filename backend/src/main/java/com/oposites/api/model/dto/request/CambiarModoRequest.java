package com.oposites.api.model.dto.request;

import com.oposites.api.model.enums.ChatModo;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CambiarModoRequest {
    @NotNull
    private ChatModo modo;
}
