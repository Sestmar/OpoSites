package com.oposites.api.security.ratelimit;

import io.github.bucket4j.Bandwidth;
import io.github.bucket4j.Bucket;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.core.annotation.Order;
import org.springframework.core.Ordered;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.time.Duration;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Filtro de rate limiting para /api/v1/auth/**.
 *
 * Algoritmo: token bucket (Bucket4j). Cada IP obtiene su propio cubo.
 * Los límites se configuran en RateLimitProperties (application.yml / application-prod.yml).
 *
 * NOTA DE PRODUCCIÓN: el ConcurrentHashMap crece con cada IP única sin limpiar.
 * Para producción real con múltiples instancias se recomienda Bucket4j + Redis
 * (bucket4j-redis) en lugar de este mapa in-memory.
 */
@Component
@Order(Ordered.HIGHEST_PRECEDENCE)  // antes de Spring Security (-100)
@RequiredArgsConstructor
public class AuthRateLimitFilter extends OncePerRequestFilter {

    private static final String AUTH_PATH_PREFIX = "/api/v1/auth/";
    private static final String TOO_MANY_REQUESTS_BODY =
            "{\"error\":\"Demasiadas peticiones. Esperá un momento antes de volver a intentarlo.\"}";

    private final RateLimitProperties props;

    // Un bucket por IP. En memoria; suficiente para una sola instancia.
    private final Map<String, Bucket> buckets = new ConcurrentHashMap<>();

    // Solo actúa sobre /api/v1/auth/**
    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        return !request.getRequestURI().startsWith(AUTH_PATH_PREFIX);
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain chain) throws ServletException, IOException {

        String ip = resolveClientIp(request);
        Bucket bucket = buckets.computeIfAbsent(ip, k -> buildBucket());

        if (bucket.tryConsume(1)) {
            chain.doFilter(request, response);
        } else {
            response.setStatus(HttpStatus.TOO_MANY_REQUESTS.value());
            response.setContentType(MediaType.APPLICATION_JSON_VALUE);
            response.getWriter().write(TOO_MANY_REQUESTS_BODY);
        }
    }

    /**
     * Crea un bucket con la configuración de RateLimitProperties.
     * refillGreedy: recarga los tokens uniformemente a lo largo del minuto.
     */
    private Bucket buildBucket() {
        Bandwidth limit = Bandwidth.builder()
                .capacity(props.getBurstCapacity())
                .refillGreedy(props.getRequestsPerMinute(), Duration.ofMinutes(1))
                .build();
        return Bucket.builder().addLimit(limit).build();
    }

    /**
     * Extrae la IP real del cliente.
     * Si hay un proxy/load balancer delante, respeta X-Forwarded-For.
     * Solo toma la primera IP de la cadena (IP original del cliente).
     */
    private String resolveClientIp(HttpServletRequest request) {
        String xForwardedFor = request.getHeader("X-Forwarded-For");
        if (xForwardedFor != null && !xForwardedFor.isBlank()) {
            return xForwardedFor.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }
}
