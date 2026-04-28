package com.oposites.api.exception;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class ApiError {

    private int status;
    private String error;
    private String message;
    private LocalDateTime timestamp;
    private String path;
}
