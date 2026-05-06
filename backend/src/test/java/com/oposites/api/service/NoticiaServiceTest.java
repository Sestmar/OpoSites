package com.oposites.api.service;

import com.oposites.api.model.entity.NoticiaConvocatoria;
import com.oposites.api.model.entity.Usuario;
import com.oposites.api.model.enums.EstadoEditorialNoticia;
import com.oposites.api.model.enums.TipoNoticia;
import com.oposites.api.repository.NoticiaConvocatoriaRepository;
import com.oposites.api.repository.NoticiaLeidaRepository;
import com.oposites.api.repository.RamaOposicionRepository;
import com.oposites.api.repository.UsuarioRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.Set;

import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class NoticiaServiceTest {

    @Mock
    private NoticiaConvocatoriaRepository noticiaRepository;
    @Mock
    private NoticiaLeidaRepository noticiaLeidaRepository;
    @Mock
    private UsuarioRepository usuarioRepository;
    @Mock
    private RamaOposicionRepository ramaRepository;

    private NoticiaService service;

    @BeforeEach
    void setUp() {
        service = new NoticiaService(
                noticiaRepository,
                noticiaLeidaRepository,
                usuarioRepository,
                ramaRepository
        );
    }

    @Test
    void listarNoticiasUsaRamaPrincipalSiNoSePasaRamaId() {
        Usuario user = Usuario.builder()
                .id(1L)
                .email("user@oposites.com")
                .ramaPrincipalId(7L)
                .build();

        PageRequest pageable = PageRequest.of(0, 20);
        Page<NoticiaConvocatoria> page = new PageImpl<>(List.of(
                NoticiaConvocatoria.builder()
                        .id(10L)
                        .titulo("N")
                        .contenido("C")
                        .tipo(TipoNoticia.NOTICIA)
                        .fechaPublicacion(LocalDateTime.now())
                        .estadoEditorial(EstadoEditorialNoticia.PUBLICADA)
                        .build()
        ));

        when(usuarioRepository.findByEmail("user@oposites.com")).thenReturn(Optional.of(user));
        when(noticiaLeidaRepository.findNoticiaIdsByUsuarioId(1L)).thenReturn(Set.of());
        when(noticiaRepository.findFiltered(
                eq(7L),
                eq(TipoNoticia.CAMBIO),
                eq(EstadoEditorialNoticia.PUBLICADA),
                eq(pageable)
        )).thenReturn(page);

        service.listarNoticias("user@oposites.com", null, TipoNoticia.CAMBIO, pageable);

        verify(noticiaRepository).findFiltered(
                7L,
                TipoNoticia.CAMBIO,
                EstadoEditorialNoticia.PUBLICADA,
                pageable
        );
    }

    @Test
    void listarNoticiasUsaGlobalSiUsuarioNoTieneRama() {
        Usuario user = Usuario.builder()
                .id(1L)
                .email("user@oposites.com")
                .ramaPrincipalId(null)
                .build();

        PageRequest pageable = PageRequest.of(1, 10);
        when(usuarioRepository.findByEmail("user@oposites.com")).thenReturn(Optional.of(user));
        when(noticiaLeidaRepository.findNoticiaIdsByUsuarioId(1L)).thenReturn(Set.of());
        when(noticiaRepository.findGlobalFiltered(
                eq(TipoNoticia.NOTICIA),
                eq(EstadoEditorialNoticia.PUBLICADA),
                eq(pageable)
        )).thenReturn(Page.empty());

        service.listarNoticias("user@oposites.com", null, TipoNoticia.NOTICIA, pageable);

        verify(noticiaRepository).findGlobalFiltered(
                TipoNoticia.NOTICIA,
                EstadoEditorialNoticia.PUBLICADA,
                pageable
        );
    }

    @Test
    void listarNoticiasBorradoresUsaEstadoEditorialBorrador() {
        PageRequest pageable = PageRequest.of(0, 20);
        when(noticiaRepository.findByEstadoEditorialOrderByFechaPublicacionDesc(
                eq(EstadoEditorialNoticia.BORRADOR),
                eq(pageable)
        )).thenReturn(Page.empty());

        service.listarBorradores(pageable);

        verify(noticiaRepository).findByEstadoEditorialOrderByFechaPublicacionDesc(
                EstadoEditorialNoticia.BORRADOR,
                pageable
        );
    }
}
