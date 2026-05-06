package com.oposites.api.model.enums;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;

class TipoNoticiaTest {

    @Test
    void fromQueryParamAdmiteMayusculasYMinusculas() {
        assertEquals(TipoNoticia.CONVOCATORIA, TipoNoticia.fromQueryParam("CONVOCATORIA"));
        assertEquals(TipoNoticia.CAMBIO, TipoNoticia.fromQueryParam("cambio"));
        assertEquals(TipoNoticia.NOTICIA, TipoNoticia.fromQueryParam("Noticia"));
    }

    @Test
    void fromQueryParamPermiteNuloOVacio() {
        assertNull(TipoNoticia.fromQueryParam(null));
        assertNull(TipoNoticia.fromQueryParam(" "));
    }

    @Test
    void fromQueryParamLanzaSiValorInvalido() {
        assertThrows(IllegalArgumentException.class, () -> TipoNoticia.fromQueryParam("otro"));
    }
}
