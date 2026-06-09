package com.adsoftssenger.backend.service;

import com.adsoftssenger.backend.config.CloudinaryConfig.CloudinaryCredentials;
import com.adsoftssenger.backend.exception.CloudinaryUploadException;
import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
import java.io.IOException;
import java.time.Instant;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

@Service
@RequiredArgsConstructor
public class CloudinaryService {

    private static final String PROFILE_PHOTOS_FOLDER = "adsoftssenger/profile_photos";
    private static final String STORIES_FOLDER = "adsoftssenger/stories";
    private static final String CLOUDINARY_UPLOAD_ERROR = "No se pudo subir la imagen a Cloudinary";
    private static final Set<String> ALLOWED_IMAGE_TYPES = Set.of(
            "image/jpeg",
            "image/jpg",
            "image/png",
            "image/webp",
            "image/heic",
            "image/heif"
    );
    private static final Set<String> ALLOWED_IMAGE_EXTENSIONS = Set.of(
            ".jpg",
            ".jpeg",
            ".png",
            ".webp",
            ".heic",
            ".heif"
    );

    private final Cloudinary cloudinary;
    private final CloudinaryCredentials credentials;

    public String uploadProfilePhoto(MultipartFile file, Long usuarioId) {
        return uploadImage(file, PROFILE_PHOTOS_FOLDER, "usuario_" + usuarioId, true);
    }

    public String uploadStoryImage(MultipartFile file, Long usuarioId) {
        String publicId = "usuario_" + usuarioId + "_" + Instant.now().toEpochMilli();
        return uploadImage(file, STORIES_FOLDER, publicId, false);
    }

    private String uploadImage(MultipartFile file, String folder, String publicId, boolean overwrite) {
        logCloudinaryConfig();
        validarImagen(file);

        try {
            validarConfiguracion();
            Map<?, ?> uploadResult = cloudinary.uploader().upload(file.getBytes(), ObjectUtils.asMap(
                    "folder", folder,
                    "public_id", publicId,
                    "resource_type", "image",
                    "overwrite", overwrite,
                    "invalidate", overwrite
            ));
            System.out.println("Cloudinary response: " + uploadResult);

            Object secureUrl = uploadResult.get("secure_url");
            System.out.println("secure_url: " + secureUrl);
            if (!(secureUrl instanceof String url) || !StringUtils.hasText(url)) {
                throw new CloudinaryUploadException(
                        CLOUDINARY_UPLOAD_ERROR,
                        "Cloudinary no devolvio secure_url"
                );
            }
            return url;
        } catch (CloudinaryUploadException exception) {
            exception.printStackTrace();
            throw exception;
        } catch (IOException | RuntimeException exception) {
            exception.printStackTrace();
            throw new CloudinaryUploadException(CLOUDINARY_UPLOAD_ERROR, exception);
        }
    }

    private void logCloudinaryConfig() {
        String cloudName = credentials.cloudName();
        String apiKey = credentials.apiKey();
        String apiSecret = credentials.apiSecret();

        System.out.println("=== ENTRANDO A CLOUDINARY SERVICE ===");
        System.out.println("cloud name configurado?: " + (cloudName != null));
        System.out.println("api key configurado?: " + (apiKey != null));
        System.out.println("api secret configurado?: " + (apiSecret != null));
    }

    private void validarConfiguracion() {
        if (!credentials.isComplete()) {
            throw new CloudinaryUploadException(
                    CLOUDINARY_UPLOAD_ERROR,
                    "Faltan variables CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY o CLOUDINARY_API_SECRET"
            );
        }
    }

    private void validarImagen(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("Debes seleccionar una imagen");
        }

        String contentType = file.getContentType();
        String originalName = file.getOriginalFilename();
        String normalizedContentType = contentType == null ? "" : contentType.toLowerCase(Locale.ROOT);
        String extension = detectExtension(originalName);
        boolean validContentType = ALLOWED_IMAGE_TYPES.contains(normalizedContentType)
                || normalizedContentType.startsWith("image/");
        boolean validExtension = ALLOWED_IMAGE_EXTENSIONS.contains(extension);

        if (!validContentType && !validExtension) {
            logInvalidImage(file, contentType, originalName, extension);
            throw new IllegalArgumentException("Formato no compatible. Usa JPG, PNG, WEBP, HEIC o HEIF.");
        }
    }

    private String detectExtension(String filename) {
        if (!StringUtils.hasText(filename)) {
            return "";
        }

        String normalizedFilename = filename.toLowerCase(Locale.ROOT).trim();
        int lastDot = normalizedFilename.lastIndexOf('.');
        if (lastDot < 0 || lastDot == normalizedFilename.length() - 1) {
            return "";
        }
        return normalizedFilename.substring(lastDot);
    }

    private void logInvalidImage(MultipartFile file, String contentType, String originalName, String extension) {
        System.out.println("=== IMAGEN RECHAZADA POR FORMATO ===");
        System.out.println("contentType recibido: " + contentType);
        System.out.println("originalName: " + originalName);
        System.out.println("size: " + file.getSize());
        System.out.println("extension detectada: " + extension);
    }
}
