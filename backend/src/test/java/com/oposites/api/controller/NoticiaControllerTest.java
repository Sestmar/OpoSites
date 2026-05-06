package com.oposites.api.controller;

import com.oposites.api.exception.AppException;
import com.oposites.api.model.dto.response.NoticiaResumenResponse;
import com.oposites.api.model.enums.TipoNoticia;
import com.oposites.api.service.NoticiaService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.security.core.userdetails.UserDetails;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class NoticiaControllerTest {

    @Mock
    private NoticiaService noticiaService;

    @Mock
    private UserDetails userDetails;

    private NoticiaController controller;

    @BeforeEach
    void setUp() {
        controller = new NoticiaController(noticiaService);
        when(userDetails.getUsername()).thenReturn("user@oposites.com");
    }

    @Test
    void listarAceptaTipoCaseInsensitiveYPaginacion() {
        Page<NoticiaResumenResponse> page = new PageImpl<>(List.of());
        when(noticiaService.listarNoticias(
                eq("user@oposites.com"),
                eq(5L),
                eq(TipoNoticia.CAMBIO),
                isNull(),
                eq(PageRequest.of(2, 15))
        )).thenReturn(page);

        var response = controller.listar(userDetails, "CaMbIo", 5L, null, 2, 15);

        assertEquals(200, response.getStatusCode().value());
        verify(noticiaService).listarNoticias(
                "user@oposites.com",
                5L,
                TipoNoticia.CAMBIO,
                null,
                PageRequest.of(2, 15)
        );
    }

    @Test
    void listarLanzaBadRequestSiTipoInvalido() {
        assertThrows(AppException.class, () ->
                controller.listar(userDetails, "invalido", null, null, 0, 20)
        );
        verifyNoInteractions(noticiaService);
    }

    @Test
    void listarSinTipoPasaNullAlService() {
        Page<NoticiaResumenResponse> page = new PageImpl<>(List.of());
        when(noticiaService.listarNoticias(
                eq("user@oposites.com"),
                isNull(),
                isNull(),
                isNull(),
                eq(PageRequest.of(0, 20))
        )).thenReturn(page);

        var response = controller.listar(userDetails, null, null, null, 0, 20);

        assertEquals(200, response.getStatusCode().value());
        verify(noticiaService).listarNoticias(
                "user@oposites.com",
                null,
                null,
                null,
                PageRequest.of(0, 20)
        );
    }
}
