package com.oposites.api.service;

import com.oposites.api.model.entity.FuenteNoticia;
import com.oposites.api.model.entity.NoticiaConvocatoria;
import com.oposites.api.model.enums.EstadoEditorialNoticia;
import com.oposites.api.model.enums.TipoFuenteNoticia;
import com.oposites.api.model.enums.TipoNoticia;
import com.oposites.api.repository.FuenteNoticiaRepository;
import com.oposites.api.repository.NoticiaConvocatoriaRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class NoticiaIngestionServiceTest {

    @Mock
    private FuenteNoticiaRepository fuenteRepository;
    @Mock
    private NoticiaConvocatoriaRepository noticiaRepository;
    @Mock
    private org.springframework.web.client.RestClient restClient;

    private NoticiaIngestionService service;

    @BeforeEach
    void setUp() {
        service = new NoticiaIngestionService(fuenteRepository, noticiaRepository, restClient);
        when(noticiaRepository.save(any(NoticiaConvocatoria.class)))
                .thenAnswer(inv -> inv.getArgument(0));
    }

    @Test
    void ejecutarIngestaDeduplicaPorUrlYFechaEnMismoLote() {
        FuenteNoticia f1 = FuenteNoticia.builder()
                .id(1L)
                .nombre("Fuente A")
                .url("https://dummy.oposites.local/general")
                .tipoFuente(TipoFuenteNoticia.DUMMY)
                .activa(true)
                .build();
        FuenteNoticia f2 = FuenteNoticia.builder()
                .id(2L)
                .nombre("Fuente B")
                .url("https://dummy.oposites.local/general")
                .tipoFuente(TipoFuenteNoticia.DUMMY)
                .activa(true)
                .build();

        when(fuenteRepository.findByActivaTrueOrderByIdAsc()).thenReturn(List.of(f1, f2));
        when(noticiaRepository.existsByUrlAndFechaPublicacion(any(), any(LocalDateTime.class))).thenReturn(false);
        when(noticiaRepository.existsByTituloAndFechaPublicacion(any(), any(LocalDateTime.class))).thenReturn(false);

        NoticiaIngestionService.IngestionResult result = service.ejecutarIngesta();

        assertEquals(4, result.itemsLeidos());
        assertEquals(2, result.itemsCreados());
        assertEquals(2, result.itemsDuplicados());
        verify(noticiaRepository, org.mockito.Mockito.times(2)).save(any(NoticiaConvocatoria.class));
    }

    @Test
    void ejecutarIngestaClasificaTipoPorPalabrasClaveYGuardaComoBorrador() {
        FuenteNoticia fuente = FuenteNoticia.builder()
                .id(1L)
                .nombre("Fuente Dummy")
                .url("https://dummy.oposites.local/general")
                .tipoFuente(TipoFuenteNoticia.DUMMY)
                .activa(true)
                .build();

        when(fuenteRepository.findByActivaTrueOrderByIdAsc()).thenReturn(List.of(fuente));
        when(noticiaRepository.existsByUrlAndFechaPublicacion(any(), any(LocalDateTime.class))).thenReturn(false);
        when(noticiaRepository.existsByTituloAndFechaPublicacion(any(), any(LocalDateTime.class))).thenReturn(false);

        service.ejecutarIngesta();

        ArgumentCaptor<NoticiaConvocatoria> captor = ArgumentCaptor.forClass(NoticiaConvocatoria.class);
        verify(noticiaRepository, org.mockito.Mockito.times(2)).save(captor.capture());

        List<NoticiaConvocatoria> saved = captor.getAllValues();
        assertTrue(saved.stream().allMatch(n -> n.getEstadoEditorial() == EstadoEditorialNoticia.BORRADOR));
        assertTrue(saved.stream().anyMatch(n -> n.getTipo() == TipoNoticia.CONVOCATORIA));
        assertTrue(saved.stream().anyMatch(n -> n.getTipo() == TipoNoticia.CAMBIO));
    }

    @Test
    void ejecutarIngestaNoGuardaSiYaExisteDuplicadoEnBaseDeDatos() {
        FuenteNoticia fuente = FuenteNoticia.builder()
                .id(1L)
                .nombre("Fuente Dummy")
                .url("https://dummy.oposites.local/general")
                .tipoFuente(TipoFuenteNoticia.DUMMY)
                .activa(true)
                .build();

        when(fuenteRepository.findByActivaTrueOrderByIdAsc()).thenReturn(List.of(fuente));
        when(noticiaRepository.existsByUrlAndFechaPublicacion(any(), any(LocalDateTime.class))).thenReturn(true);

        NoticiaIngestionService.IngestionResult result = service.ejecutarIngesta();

        assertEquals(0, result.itemsCreados());
        assertEquals(2, result.itemsDuplicados());
        verify(noticiaRepository, never()).save(any(NoticiaConvocatoria.class));
    }
}
