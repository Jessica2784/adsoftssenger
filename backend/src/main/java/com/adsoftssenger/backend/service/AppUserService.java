package com.adsoftssenger.backend.service;

import com.adsoftssenger.backend.dto.AppUserRequest;
import com.adsoftssenger.backend.dto.AppUserResponse;
import com.adsoftssenger.backend.model.AppUser;
import com.adsoftssenger.backend.repository.AppUserRepository;
import jakarta.persistence.EntityNotFoundException;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

@Service
@RequiredArgsConstructor
@Transactional
public class AppUserService {

    private final AppUserRepository appUserRepository;

    @Transactional(readOnly = true)
    public List<AppUserResponse> findAll() {
        return appUserRepository.findAll(Sort.by("displayName"))
                .stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public AppUserResponse findById(Long id) {
        return toResponse(getEntity(id));
    }

    public AppUserResponse create(AppUserRequest request) {
        validateUniqueFields(request.getUsername(), request.getEmail(), null);

        AppUser user = AppUser.builder()
                .username(request.getUsername())
                .displayName(request.getDisplayName())
                .email(request.getEmail())
                .avatarUrl(request.getAvatarUrl())
                .build();

        return toResponse(appUserRepository.save(user));
    }

    public AppUserResponse update(Long id, AppUserRequest request) {
        AppUser user = getEntity(id);
        validateUniqueFields(request.getUsername(), request.getEmail(), id);

        user.setUsername(request.getUsername());
        user.setDisplayName(request.getDisplayName());
        user.setEmail(request.getEmail());
        user.setAvatarUrl(request.getAvatarUrl());

        return toResponse(appUserRepository.save(user));
    }

    public void delete(Long id) {
        AppUser user = getEntity(id);
        appUserRepository.delete(user);
    }

    @Transactional(readOnly = true)
    public AppUser getEntity(Long id) {
        return appUserRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Usuario no encontrado con id " + id));
    }

    public AppUserResponse toResponse(AppUser user) {
        return AppUserResponse.builder()
                .id(user.getId())
                .username(user.getUsername())
                .displayName(user.getDisplayName())
                .email(user.getEmail())
                .avatarUrl(user.getAvatarUrl())
                .createdAt(user.getCreatedAt())
                .build();
    }

    private void validateUniqueFields(String username, String email, Long currentUserId) {
        appUserRepository.findByUsername(username)
                .filter(existingUser -> isDifferentUser(existingUser, currentUserId))
                .ifPresent(existingUser -> {
                    throw new IllegalArgumentException("El nombre de usuario ya existe");
                });

        if (StringUtils.hasText(email)) {
            appUserRepository.findByEmail(email)
                    .filter(existingUser -> isDifferentUser(existingUser, currentUserId))
                    .ifPresent(existingUser -> {
                        throw new IllegalArgumentException("El correo ya existe");
                    });
        }
    }

    private boolean isDifferentUser(AppUser user, Long currentUserId) {
        return currentUserId == null || !user.getId().equals(currentUserId);
    }
}
