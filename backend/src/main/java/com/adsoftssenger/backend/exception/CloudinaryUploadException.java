package com.adsoftssenger.backend.exception;

public class CloudinaryUploadException extends RuntimeException {

    private final String detail;

    public CloudinaryUploadException(String message) {
        super(message);
        this.detail = null;
    }

    public CloudinaryUploadException(String message, String detail) {
        super(message);
        this.detail = detail;
    }

    public CloudinaryUploadException(String message, Throwable cause) {
        super(message, cause);
        this.detail = cause == null ? null : cause.getMessage();
    }

    public String getDetail() {
        return detail;
    }
}
