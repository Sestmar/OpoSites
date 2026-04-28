package com.oposites.api.security.ratelimit;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

/**
 * Configuración de rate limiting para /api/v1/auth/**.
 *
 * Dev  (application.yml)       → valores laxos para no molestar en local.
 * Prod (application-prod.yml)  → valores estrictos para proteger en producción.
 *
 * Ajuste recomendado:
 *   - requestsPerMinute: peticiones totales permitidas por IP por minuto.
 *   - burstCapacity:     pico instantáneo permitido antes de refill (útil para
 *                        clientes móviles con reintentos automáticos legítimos).
 */
@Data
@Component
@ConfigurationProperties(prefix = "app.rate-limit.auth")
public class RateLimitProperties {

    /** Peticiones permitidas por IP por minuto. Dev: 20 | Prod: 5 */
    private int requestsPerMinute = 20;

    /**
     * Capacidad máxima del "cubo". Permite absorber ráfagas breves sin rechazar.
     * Normalmente igual a requestsPerMinute o un poco mayor.
     * Dev: 20 | Prod: 5
     */
    private int burstCapacity = 20;
}
