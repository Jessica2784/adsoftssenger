package com.adsoftssenger.backend.controller;

import com.adsoftssenger.backend.dto.AppUserRequest;
import com.adsoftssenger.backend.dto.AppUserResponse;
import com.adsoftssenger.backend.service.AppUserService;
import jakarta.validation.Valid;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class AppUserController {

    private final AppUserService appUserService;

    @GetMapping
    public List<AppUserResponse> findAll() {
        return appUserService.findAll();
    }

    @GetMapping("/{id}")
    public AppUserResponse findById(@PathVariable Long id) {
        return appUserService.findById(id);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public AppUserResponse create(@Valid @RequestBody AppUserRequest request) {
        return appUserService.create(request);
    }

    @PutMapping("/{id}")
    public AppUserResponse update(@PathVariable Long id, @Valid @RequestBody AppUserRequest request) {
        return appUserService.update(id, request);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        appUserService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
