package com.synapse.llm.api;

import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.Map;

@RestControllerAdvice
@Slf4j
public class GlobalExceptionHandler {

    @ExceptionHandler(Exception.class)
    public ResponseEntity<?> handleException(Exception e) {
        log.error("🔴 EXCEPTION: {}", e.getClass().getName());
        log.error("Message: {}", e.getMessage());
        log.error("Cause: {}", e.getCause());
        e.printStackTrace();

        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of(
            "error", e.getMessage(),
            "type", e.getClass().getSimpleName()
        ));
    }
}
