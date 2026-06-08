package com.adsoftssenger.backend.config;

import com.adsoftssenger.backend.dto.ApiError;
import com.adsoftssenger.backend.exception.CloudinaryUploadException;
import jakarta.persistence.EntityNotFoundException;
import java.time.LocalDateTime;
import java.util.List;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.multipart.MaxUploadSizeExceededException;
import org.springframework.web.multipart.MultipartException;
import org.springframework.web.multipart.support.MissingServletRequestPartException;

@RestControllerAdvice
public class RestExceptionHandler {

    @ExceptionHandler(EntityNotFoundException.class)
    public ResponseEntity<ApiError> handleNotFound(EntityNotFoundException exception) {
        return buildResponse(HttpStatus.NOT_FOUND, exception.getMessage(), List.of());
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<ApiError> handleBadRequest(IllegalArgumentException exception) {
        return buildResponse(HttpStatus.BAD_REQUEST, exception.getMessage(), List.of());
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiError> handleValidation(MethodArgumentNotValidException exception) {
        List<String> details = exception.getBindingResult()
                .getFieldErrors()
                .stream()
                .map(error -> error.getField() + ": " + error.getDefaultMessage())
                .toList();

        return buildResponse(HttpStatus.BAD_REQUEST, "Datos invalidos", details);
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<ApiError> handleDataIntegrity(DataIntegrityViolationException exception) {
        return buildResponse(HttpStatus.CONFLICT, "Los datos enviados generan un conflicto", List.of());
    }

    @ExceptionHandler({
            MissingServletRequestPartException.class,
            MissingServletRequestParameterException.class,
            MultipartException.class
    })
    public ResponseEntity<ApiError> handleMultipart(Exception exception) {
        return buildResponse(
                HttpStatus.BAD_REQUEST,
                "Debes enviar la imagen en multipart/form-data usando el campo file",
                exception.getMessage(),
                List.of()
        );
    }

    @ExceptionHandler(MaxUploadSizeExceededException.class)
    public ResponseEntity<ApiError> handleMaxUploadSize(MaxUploadSizeExceededException exception) {
        return buildResponse(
                HttpStatus.BAD_REQUEST,
                "La imagen supera el tamaño permitido",
                exception.getMessage(),
                List.of()
        );
    }

    @ExceptionHandler(CloudinaryUploadException.class)
    public ResponseEntity<ApiError> handleCloudinaryUpload(CloudinaryUploadException exception) {
        return buildResponse(
                HttpStatus.INTERNAL_SERVER_ERROR,
                exception.getMessage(),
                exception.getDetail(),
                List.of()
        );
    }

    private ResponseEntity<ApiError> buildResponse(HttpStatus status, String message, List<String> details) {
        return buildResponse(status, message, null, details);
    }

    private ResponseEntity<ApiError> buildResponse(
            HttpStatus status,
            String message,
            String detail,
            List<String> details
    ) {
        ApiError apiError = ApiError.builder()
                .timestamp(LocalDateTime.now())
                .status(status.value())
                .error(status.getReasonPhrase())
                .message(message)
                .detail(detail)
                .details(details)
                .build();

        return ResponseEntity.status(status).body(apiError);
    }
}
