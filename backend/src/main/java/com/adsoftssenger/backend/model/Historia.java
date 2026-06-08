package com.adsoftssenger.backend.model;

import jakarta.persistence.Basic;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "historias")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Historia {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "usuario_id", nullable = false)
    private Usuario usuario;

    @Basic(fetch = FetchType.LAZY)
    @Builder.Default
    @Column(name = "imagen", nullable = false, columnDefinition = "BYTEA")
    private byte[] imagen = new byte[0];

    @Builder.Default
    @Column(name = "tipo_contenido", nullable = false, length = 100)
    private String tipoContenido = "image/jpeg";

    @Column(name = "imagen_url", length = 1000)
    private String imagenUrl;

    @Column(name = "fecha_publicacion", nullable = false, updatable = false)
    private LocalDateTime fechaPublicacion;

    @Column(name = "fecha_creacion")
    private LocalDateTime fechaCreacion;

    @Column(name = "fecha_expiracion", nullable = false)
    private LocalDateTime fechaExpiracion;

    @Builder.Default
    @Column(name = "activa")
    private Boolean activa = true;

    @PrePersist
    void prePersist() {
        LocalDateTime now = LocalDateTime.now();
        if (fechaCreacion == null && fechaPublicacion != null) {
            fechaCreacion = fechaPublicacion;
        }
        if (fechaCreacion == null) {
            fechaCreacion = now;
        }
        if (fechaPublicacion == null) {
            fechaPublicacion = fechaCreacion;
        }
        if (fechaExpiracion == null) {
            fechaExpiracion = fechaPublicacion.plusHours(24);
        }
        if (activa == null) {
            activa = true;
        }
        if (imagen == null) {
            imagen = new byte[0];
        }
        if (tipoContenido == null) {
            tipoContenido = "image/jpeg";
        }
    }
}
