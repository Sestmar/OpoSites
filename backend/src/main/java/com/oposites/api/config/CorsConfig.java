package com.oposites.api.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.Arrays;
import java.util.List;

@Configuration
public class CorsConfig {

    // Separados por coma: "http://localhost:3000,http://localhost:4200"
    @Value("${app.cors.allowed-origins:http://localhost:3000}")
    private String allowedOriginsRaw;

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration config = new CorsConfiguration();

        config.setAllowedOrigins(Arrays.asList(allowedOriginsRaw.split(",")));

        // Métodos necesarios para la API REST; PATCH incluido para actualizaciones parciales futuras
        config.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));

        // Headers explícitos — no usar "*" con allowCredentials=true (algunos proxies lo rechazan)
        config.setAllowedHeaders(List.of("Authorization", "Content-Type", "X-Requested-With"));

        // Exponer Authorization para que clientes JS/Flutter puedan leerlo si es necesario
        config.setExposedHeaders(List.of("Authorization"));

        // Credenciales necesarias para enviar el header Authorization desde JS
        config.setAllowCredentials(true);

        // Cache del preflight en el browser durante 1 hora — evita un OPTIONS por cada request
        config.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
    }
}
