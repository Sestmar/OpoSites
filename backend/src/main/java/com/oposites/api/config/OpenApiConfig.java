package com.oposites.api.config;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Configura la spec OpenAPI 3 de la API.
 *
 * El botón "Authorize" del Swagger UI acepta un Bearer JWT —
 * al pegarlo se añade automáticamente el header Authorization: Bearer <token>
 * en todas las llamadas desde la UI.
 *
 * Swagger UI y /v3/api-docs solo están disponibles en dev.
 * En prod se desactivan vía application-prod.yml:
 *   springdoc.swagger-ui.enabled=false
 *   springdoc.api-docs.enabled=false
 */
@Configuration
public class OpenApiConfig {

    private static final String BEARER_AUTH = "bearerAuth";

    @Bean
    public OpenAPI openAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title("opoSites API")
                        .version("1.0.0")
                        .description("""
                                API REST de opoSites — copiloto de oposiciones tipo Duolingo.

                                **Autenticación**: la mayoría de endpoints requieren un JWT en el header
                                `Authorization: Bearer <token>`. Obtené el token en `POST /api/v1/auth/login`
                                o `POST /api/v1/auth/register` y pegalo en el botón **Authorize**.

                                **Admin**: los endpoints bajo `/api/v1/admin/**` requieren rol `ADMIN`.
                                """))
                // Esquema de seguridad global: todos los endpoints muestran el candado
                .addSecurityItem(new SecurityRequirement().addList(BEARER_AUTH))
                .components(new Components()
                        .addSecuritySchemes(BEARER_AUTH, new SecurityScheme()
                                .name(BEARER_AUTH)
                                .type(SecurityScheme.Type.HTTP)
                                .scheme("bearer")
                                .bearerFormat("JWT")
                                .description("JWT obtenido desde /api/v1/auth/login o /register")));
    }
}
