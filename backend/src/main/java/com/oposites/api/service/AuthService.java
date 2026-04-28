package com.oposites.api.service;

import com.oposites.api.exception.AppException;
import com.oposites.api.model.dto.request.GoogleAuthRequest;
import com.oposites.api.model.dto.request.LoginRequest;
import com.oposites.api.model.dto.request.RefreshTokenRequest;
import com.oposites.api.model.dto.request.RegisterRequest;
import com.oposites.api.model.dto.response.AuthResponse;
import com.oposites.api.model.dto.response.UsuarioResponse;
import com.oposites.api.model.entity.RefreshToken;
import com.oposites.api.model.entity.Usuario;
import com.oposites.api.model.enums.Role;
import com.oposites.api.repository.RefreshTokenRepository;
import com.oposites.api.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestClient;

import java.time.LocalDateTime;
import java.util.Map;

@Service
@RequiredArgsConstructor
@Slf4j
public class AuthService {

    private final UsuarioRepository usuarioRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final PasswordEncoder passwordEncoder;
    private final TokenService tokenService;
    private final AuthenticationManager authenticationManager;

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        if (usuarioRepository.existsByEmail(request.getEmail())) {
            throw new AppException("El email ya está registrado", HttpStatus.CONFLICT);
        }

        Usuario usuario = Usuario.builder()
                .email(request.getEmail())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .nombre(request.getNombre())
                .ciudad(request.getCiudad())
                .role(Role.USER)
                .build();

        usuarioRepository.save(usuario);
        return buildAuthResponse(usuario);
    }

    @Transactional
    public AuthResponse login(LoginRequest request) {
        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.getEmail(), request.getPassword())
        );

        Usuario usuario = usuarioRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new AppException("Usuario no encontrado", HttpStatus.NOT_FOUND));

        return buildAuthResponse(usuario);
    }

    /**
     * Flujo móvil: Flutter usa google_sign_in para obtener un idToken y
     * lo envía aquí. El backend verifica el token con Google y crea/recupera el usuario.
     */
    @Transactional
    public AuthResponse loginWithGoogle(GoogleAuthRequest request) {
        Map<String, Object> googleInfo = verifyGoogleIdToken(request.getIdToken());

        String email    = (String) googleInfo.get("email");
        String nombre   = (String) googleInfo.get("name");
        String googleId = (String) googleInfo.get("sub");

        if (email == null) {
            throw new AppException("Token de Google inválido: no contiene email", HttpStatus.UNAUTHORIZED);
        }

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

        return buildAuthResponse(usuario);
    }

    /**
     * Refresca el par de tokens.
     * Valida firma y claim del JWT, verifica que el token existe en BD y no está revocado,
     * lo revoca (rotación) y emite un nuevo par.
     */
    @Transactional
    public AuthResponse refresh(RefreshTokenRequest request) {
        String token = request.getRefreshToken();

        if (!tokenService.isTokenValid(token) || !tokenService.isRefreshToken(token)) {
            throw new AppException("Refresh token inválido o expirado", HttpStatus.UNAUTHORIZED);
        }

        String hash = tokenService.hashToken(token);
        RefreshToken stored = refreshTokenRepository.findByTokenHash(hash)
                .orElseThrow(() -> new AppException("Refresh token no reconocido", HttpStatus.UNAUTHORIZED));

        if (stored.isRevocado()) {
            // Posible reutilización de token robado: revocar todos los tokens del usuario
            log.warn("Intento de uso de refresh token revocado para usuario id={}", stored.getUsuario().getId());
            throw new AppException("Refresh token revocado", HttpStatus.UNAUTHORIZED);
        }

        // Rotación: revocar el token actual antes de emitir uno nuevo
        stored.setRevocado(true);
        refreshTokenRepository.save(stored);

        String email = tokenService.extractEmail(token);
        Usuario usuario = usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new AppException("Usuario no encontrado", HttpStatus.NOT_FOUND));

        return buildAuthResponse(usuario);
    }

    /**
     * Revoca el refresh token enviado por el cliente.
     * Idempotente: si el token no existe o ya está revocado, devuelve 204 igualmente.
     */
    @Transactional
    public void logout(RefreshTokenRequest request) {
        if (request.getRefreshToken() == null || request.getRefreshToken().isBlank()) {
            return;
        }
        String hash = tokenService.hashToken(request.getRefreshToken());
        refreshTokenRepository.findByTokenHash(hash).ifPresent(t -> {
            t.setRevocado(true);
            refreshTokenRepository.save(t);
        });
    }

    /**
     * Revoca todos los refresh tokens activos de un usuario.
     * Usar en: cambio de contraseña, cuenta comprometida, eliminación de cuenta.
     */
    @Transactional
    public void revocarTodosLosTokens(Long usuarioId) {
        refreshTokenRepository.revocarTodosDeUsuario(usuarioId);
        log.info("Todos los refresh tokens revocados para usuario id={}", usuarioId);
    }

    /**
     * Limpieza nocturna de tokens expirados para evitar crecimiento indefinido de la tabla.
     */
    @Scheduled(cron = "0 0 3 * * *")
    @Transactional
    public void limpiarTokensExpirados() {
        refreshTokenRepository.deleteByExpiresAtBefore(LocalDateTime.now());
        log.info("Limpieza de refresh tokens expirados completada");
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Helpers privados
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Genera el par access+refresh, persiste el hash del refresh token y devuelve la respuesta.
     * Punto central de emisión de tokens: cualquier flujo de auth pasa por aquí.
     */
    private AuthResponse buildAuthResponse(Usuario usuario) {
        String accessToken  = tokenService.generateAccessToken(usuario);
        String refreshToken = tokenService.generateRefreshToken(usuario);

        refreshTokenRepository.save(RefreshToken.builder()
                .tokenHash(tokenService.hashToken(refreshToken))
                .usuario(usuario)
                .expiresAt(tokenService.extractExpiration(refreshToken))
                .build());

        return AuthResponse.builder()
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .usuario(toResponse(usuario))
                .build();
    }

    @SuppressWarnings("unchecked")
    private Map<String, Object> verifyGoogleIdToken(String idToken) {
        try {
            return RestClient.create()
                    .get()
                    .uri("https://oauth2.googleapis.com/tokeninfo?id_token={token}", idToken)
                    .retrieve()
                    .body(Map.class);
        } catch (Exception e) {
            log.error("Error verificando token de Google: {}", e.getMessage());
            throw new AppException("Token de Google inválido", HttpStatus.UNAUTHORIZED);
        }
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
