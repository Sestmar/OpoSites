package com.oposites.api.service;

import com.oposites.api.exception.AppException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.UUID;

@Service
public class FileStorageService {

    @Value("${app.uploads.path}")
    private String uploadsPath;

    /**
     * Guarda el archivo en {@code <uploadsPath>/<subdir>/} y devuelve el nombre generado.
     */
    public String store(MultipartFile file, String subdir) {
        if (file == null || file.isEmpty()) {
            throw new AppException("El archivo no puede estar vacío", HttpStatus.BAD_REQUEST);
        }

        String contentType = file.getContentType();
        if (contentType == null || !contentType.startsWith("image/")) {
            throw new AppException("Solo se permiten archivos de imagen", HttpStatus.BAD_REQUEST);
        }

        String originalFilename = file.getOriginalFilename();
        String extension = "";
        if (originalFilename != null && originalFilename.contains(".")) {
            extension = "." + originalFilename.substring(originalFilename.lastIndexOf('.') + 1).toLowerCase();
        }

        String filename = UUID.randomUUID() + extension;

        try {
            Path targetDir = Paths.get(uploadsPath, subdir);
            Files.createDirectories(targetDir);
            Path targetPath = targetDir.resolve(filename);
            Files.copy(file.getInputStream(), targetPath, StandardCopyOption.REPLACE_EXISTING);
        } catch (IOException e) {
            throw new AppException("Error al guardar el archivo: " + e.getMessage(), HttpStatus.INTERNAL_SERVER_ERROR);
        }

        return filename;
    }

    /**
     * Borra el archivo {@code <uploadsPath>/<subdir>/<filename>} si existe.
     */
    public void delete(String filename, String subdir) {
        if (filename == null || filename.isBlank()) {
            return;
        }
        try {
            Path filePath = Paths.get(uploadsPath, subdir, filename);
            Files.deleteIfExists(filePath);
        } catch (IOException e) {
            // Log y continúa — no es un error crítico
        }
    }

    public Path resolve(String subdir, String filename) {
        return Paths.get(uploadsPath, subdir, filename);
    }
}
