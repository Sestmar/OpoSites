package com.oposites.api.security;

import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration
@EnableWebSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtFilter jwtFilter;
    private final OAuth2SuccessHandler oAuth2SuccessHandler;

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        return http
                .csrf(AbstractHttpConfigurer::disable)
                // CORS usa el bean CorsConfigurationSource definido en CorsConfig
                .cors(cors -> {})
                .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(auth -> auth
                        // Endpoints públicos (sin token)
                        .requestMatchers(
                                "/api/v1/auth/**",
                                "/actuator/health",
                                "/login/oauth2/**",
                                "/oauth2/**",
                                // Swagger UI — solo activo en dev (desactivado en prod vía yml)
                                "/v3/api-docs/**",
                                "/swagger-ui/**",
                                "/swagger-ui.html"
                        ).permitAll()
                        // Fotos de perfil — acceso público (Flutter las usa sin token en listas)
                        .requestMatchers(HttpMethod.GET, "/api/v1/usuarios/fotos/**").permitAll()
                        // Lectura pública de oposiciones y temas (Fase 2)
                        // '*' en Spring Security AntMatcher coincide con UN solo segmento de ruta,
                        // por lo que /api/v1/temas/* matchea /temas/{id} pero NO /temas/{id}/preguntas
                        .requestMatchers(HttpMethod.GET,
                                "/api/v1/oposiciones",
                                "/api/v1/oposiciones/*",
                                "/api/v1/oposiciones/*/temas",
                                "/api/v1/temas/*"
                        ).permitAll()
                        // Solo ADMIN puede acceder a rutas /admin/**
                        .requestMatchers("/api/v1/admin/**").hasRole("ADMIN")
                        // El resto requiere autenticación
                        .anyRequest().authenticated()
                )
                // Flujo OAuth2 web para el panel admin Angular.
                // El flujo móvil (Flutter) usa POST /api/v1/auth/google.
                .oauth2Login(oauth2 -> oauth2
                        .successHandler(oAuth2SuccessHandler)
                )
                // JwtFilter se ejecuta antes del filtro de autenticación por usuario/contraseña
                .addFilterBefore(jwtFilter, UsernamePasswordAuthenticationFilter.class)
                .build();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }
}
