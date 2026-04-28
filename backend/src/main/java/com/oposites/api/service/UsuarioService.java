package com.oposites.api.service;

import com.oposites.api.exception.AppException;
import com.oposites.api.model.dto.request.UpdatePerfilRequest;
import com.oposites.api.model.dto.response.UsuarioResponse;
import com.oposites.api.model.entity.Usuario;
import com.oposites.api.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class UsuarioService {

    private final UsuarioRepository usuarioRepository;

    public UsuarioResponse getPerfil(String email) {
        return toResponse(findByEmail(email));
    }

    @Transactional
    public UsuarioResponse updatePerfil(String email, UpdatePerfilRequest request) {
        Usuario usuario = findByEmail(email);

        if (request.getNombre() != null) usuario.setNombre(request.getNombre());
        if (request.getCiudad() != null) usuario.setCiudad(request.getCiudad());
        if (request.getFechaExamenObjetivo() != null) usuario.setFechaExamenObjetivo(request.getFechaExamenObjetivo());

        return toResponse(usuarioRepository.save(usuario));
    }

    @Transactional
    public UsuarioResponse updateRama(String email, Long ramaId) {
        Usuario usuario = findByEmail(email);
        // En Fase 2 se validará que ramaId exista en ramas_oposiciones
        usuario.setRamaPrincipalId(ramaId);
        return toResponse(usuarioRepository.save(usuario));
    }

    @Transactional
    public void deleteAccount(String email) {
        usuarioRepository.delete(findByEmail(email));
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Helpers privados
    // ─────────────────────────────────────────────────────────────────────────

    private Usuario findByEmail(String email) {
        return usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new AppException("Usuario no encontrado", HttpStatus.NOT_FOUND));
    }

    private UsuarioResponse toResponse(Usuario u) {
        return UsuarioResponse.builder()
                .id(u.getId())
                .email(u.getEmail())
                .nombre(u.getNombre())
                .ciudad(u.getCiudad())
                .ramaPrincipalId(u.getRamaPrincipalId())
                .fechaExamenObjetivo(u.getFechaExamenObjetivo())
                .enabledChatPrivate(u.isEnabledChatPrivate())
                .role(u.getRole())
                .fechaRegistro(u.getFechaRegistro())
                .build();
    }
}
