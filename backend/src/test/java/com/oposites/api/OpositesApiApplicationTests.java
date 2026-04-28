package com.oposites.api;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

/**
 * Test de integración — requiere una instancia de PostgreSQL corriendo
 * con las credenciales definidas en application.yml (o variables de entorno).
 * Flyway aplica las migraciones automáticamente antes del test.
 */
@SpringBootTest
class OpositesApiApplicationTests {

    @Test
    void contextLoads() {
    }
}
