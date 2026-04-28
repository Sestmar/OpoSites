package com.oposites.api.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.oposites.api.model.dto.response.AuthResponse;
import com.oposites.api.model.dto.response.UsuarioResponse;
import com.oposites.api.model.entity.Usuario;
import com.oposites.api.model.enums.Role;
import com.oposites.api.repository.UsuarioRepository;
import com.oposites.api.service.TokenService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.oauth2.core.user.OAuth2User;
import org.springframework.security.web.authentication.SimpleUrlAuthenticationSuccessHandler;
import org.springframework.stereotype.Component;

import java.io.IOException;

/**
 * Manejador del flujo OAuth2 web (para el panel admin Angular).
 * El flujo móvil de Flutter usa POST /api/v1/auth/google con el idToken de Google.
 */
@Component
@RequiredArgsConstructor
public class OAuth2SuccessHandler extends SimpleUrlAuthenticationSuccessHandler {

    private final TokenService tokenService;
    private final UsuarioRepository usuarioRepository;
    private final ObjectMapper objectMapper;

    @Override
    public void onAuthenticationSuccess(HttpServletRequest request,
                                        HttpServletResponse response,
                                        Authentication authentication) throws IOException {
        OAuth2User oauth2User = (OAuth2User) authentication.getPrincipal();

        String email    = oauth2User.getAttribute("email");
        String nombre   = oauth2User.getAttribute("name");
        String googleId = oauth2User.getAttribute("sub");

        Usuario usuario = usuarioRepository.findByEmail(email)
                .orElseGet(() -> usuarioRepository.save(
                        Usuario.builder()
                                .email(email)
                                .nombre(nombre != null ? nombre : email)
                                .googleId(googleId)
                                .role(Role.USER)
                                .build()
                ));

        if (usuario.getGoogleId() == null) {
            usuario.setGoogleId(googleId);
            usuarioRepository.save(usuario);
        }

        AuthResponse authResponse = AuthResponse.builder()
                .accessToken(tokenService.generateAccessToken(usuario))
                .refreshToken(tokenService.generateRefreshToken(usuario))
                .usuario(toResponse(usuario))
                .build();

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        objectMapper.writeValue(response.getWriter(), authResponse);
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
