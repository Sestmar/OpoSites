package com.oposites.api.service;

import com.oposites.api.exception.AppException;
import com.oposites.api.model.dto.request.GoogleAuthRequest;
import com.oposites.api.model.dto.request.LoginRequest;
import com.oposites.api.model.dto.request.RefreshTokenRequest;
import com.oposites.api.model.dto.request.RegisterRequest;
import com.oposites.api.model.dto.response.AuthResponse;
import com.oposites.api.model.dto.response.UsuarioResponse;
import com.oposites.api.model.entity.Usuario;
import com.oposites.api.model.enums.Role;
import com.oposites.api.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestClient;

import java.util.Map;

@Service
@RequiredArgsConstructor
@Slf4j
public class AuthService {

    private final UsuarioRepository usuarioRepository;
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

    public AuthResponse login(LoginRequest request) {
        // Lanza BadCredentialsException si las credenciales son incorrectas;
        // GlobalExceptionHandler lo convierte en 401.
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

        // Si el usuario existía por email/contraseña y ahora añade Google
        if (usuario.getGoogleId() == null) {
            usuario.setGoogleId(googleId);
            usuarioRepository.save(usuario);
        }

        return buildAuthResponse(usuario);
    }

    public AuthResponse refresh(RefreshTokenRequest request) {
        String token = request.getRefreshToken();

        if (!tokenService.isTokenValid(token) || !tokenService.isRefreshToken(token)) {
            throw new AppException("Refresh token inválido o expirado", HttpStatus.UNAUTHORIZED);
        }

        String email = tokenService.extractEmail(token);
        Usuario usuario = usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new AppException("Usuario no encontrado", HttpStatus.NOT_FOUND));

        return buildAuthResponse(usuario);
    }

    /**
     * Con JWT stateless el logout es responsabilidad del cliente (descarta los tokens).
     * Aquí se podría añadir una blacklist de tokens si fuera necesario en el futuro.
     */
    public void logout() {
        // No-op en Fase 1
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Helpers privados
    // ─────────────────────────────────────────────────────────────────────────

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

    private AuthResponse buildAuthResponse(Usuario usuario) {
        return AuthResponse.builder()
                .accessToken(tokenService.generateAccessToken(usuario))
                .refreshToken(tokenService.generateRefreshToken(usuario))
                .usuario(toResponse(usuario))
                .build();
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
