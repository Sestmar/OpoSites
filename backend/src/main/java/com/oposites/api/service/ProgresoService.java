package com.oposites.api.service;

import com.oposites.api.model.dto.response.*;
import com.oposites.api.model.entity.Tema;
import com.oposites.api.repository.ProgresoUsuarioRepository;
import com.oposites.api.repository.TemaRepository;
import com.oposites.api.repository.TestSessionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.sql.Date;
import java.sql.Timestamp;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.IsoFields;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ProgresoService {

    private final ProgresoUsuarioRepository progresoRepository;
    private final TestSessionRepository testSessionRepository;
    private final TemaRepository temaRepository;
    private final TestService testService;

    public ProgresoResumenResponse resumen(String email, Long ramaId) {
        Long usuarioId = testService.findUsuario(email).getId();

        long totalRespondidas = progresoRepository.countByUsuarioId(usuarioId);
        long totalCorrectas = progresoRepository.countByUsuarioIdAndCorrectoTrue(usuarioId);
        double pctGlobal = totalRespondidas == 0 ? 0.0
                : Math.round((double) totalCorrectas / totalRespondidas * 100.0) / 1.0;

        int rachaActual = calcularRachaActual(testSessionRepository.findDiasEstudiados(usuarioId));

        List<TemaDebilDto> temasDebiles = calcularTemasDebiles(usuarioId, ramaId);

        return ProgresoResumenResponse.builder()
                .totalRespondidas(totalRespondidas)
                .totalCorrectas(totalCorrectas)
                .porcentajeAciertosGlobal(pctGlobal)
                .rachaActual(rachaActual)
                .temasDebiles(temasDebiles)
                .build();
    }

    public List<ProgresoTemaResponse> estadisticasPorTema(String email, Long ramaId) {
        Long usuarioId = testService.findUsuario(email).getId();

        List<Object[]> filas = progresoRepository.findEstadisticasPorTema(usuarioId, ramaId);
        if (filas.isEmpty()) return List.of();

        List<Long> temaIds = filas.stream().map(f -> (Long) f[0]).toList();
        Map<Long, String> nombresPorId = temaRepository.findAllById(temaIds).stream()
                .collect(Collectors.toMap(Tema::getId, Tema::getNombre));

        return filas.stream()
                .map(f -> {
                    Long temaId = (Long) f[0];
                    long total = (Long) f[1];
                    long correctas = ((Number) f[2]).longValue();
                    double pct = total == 0 ? 0.0 : Math.round((double) correctas / total * 100.0) / 1.0;
                    return ProgresoTemaResponse.builder()
                            .temaId(temaId)
                            .nombre(nombresPorId.getOrDefault(temaId, "Tema " + temaId))
                            .totalRespondidas(total)
                            .correctas(correctas)
                            .porcentajeAcierto(pct)
                            .build();
                })
                .toList();
    }

    public List<EvolucionSemanalDto> evolucion(String email, int semanas) {
        Long usuarioId = testService.findUsuario(email).getId();
        LocalDateTime desde = LocalDateTime.now().minusWeeks(semanas);

        return testSessionRepository.findEvolucionSemanal(usuarioId, desde)
                .stream()
                .map(f -> {
                    LocalDate semanaDate = ((Timestamp) f[0]).toLocalDateTime().toLocalDate();
                    int year = semanaDate.get(IsoFields.WEEK_BASED_YEAR);
                    int week = semanaDate.get(IsoFields.WEEK_OF_WEEK_BASED_YEAR);
                    String semanaStr = String.format("%d-W%02d", year, week);
                    double notaMedia = Math.round(((Number) f[1]).doubleValue() * 10.0) / 10.0;
                    long tests = ((Number) f[2]).longValue();
                    return EvolucionSemanalDto.builder()
                            .semana(semanaStr)
                            .notaMedia(notaMedia)
                            .testsCompletados(tests)
                            .build();
                })
                .toList();
    }

    public List<EvolucionTemaSemanalDto> evolucionPorTema(String email, Long temaId, int semanas) {
        Long usuarioId = testService.findUsuario(email).getId();
        LocalDateTime desde = LocalDateTime.now().minusWeeks(semanas);

        return progresoRepository.findEvolucionSemanalByTema(usuarioId, temaId, desde)
                .stream()
                .map(f -> {
                    java.sql.Timestamp ts = (java.sql.Timestamp) f[0];
                    LocalDate semanaDate = ts.toLocalDateTime().toLocalDate();
                    int year = semanaDate.get(IsoFields.WEEK_BASED_YEAR);
                    int week = semanaDate.get(IsoFields.WEEK_OF_WEEK_BASED_YEAR);
                    String semanaStr = String.format("%d-W%02d", year, week);

                    long total = ((Number) f[1]).longValue();
                    long correctas = ((Number) f[2]).longValue();
                    double pct = total == 0 ? 0.0
                            : Math.round((double) correctas / total * 100.0 * 10.0) / 10.0;

                    return EvolucionTemaSemanalDto.builder()
                            .semana(semanaStr)
                            .porcentajeAcierto(pct)
                            .totalRespondidas(total)
                            .build();
                })
                .toList();
    }

    public RachaResponse racha(String email) {
        Long usuarioId = testService.findUsuario(email).getId();
        List<Date> dias = testSessionRepository.findDiasEstudiados(usuarioId);

        int rachaActual = calcularRachaActual(dias);
        int mejorRacha = calcularMejorRacha(dias);
        LocalDate ultimoEstudio = dias.isEmpty() ? null : dias.get(0).toLocalDate();

        return RachaResponse.builder()
                .rachaActual(rachaActual)
                .mejorRacha(mejorRacha)
                .ultimoEstudio(ultimoEstudio)
                .build();
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

    private List<TemaDebilDto> calcularTemasDebiles(Long usuarioId, Long ramaId) {
        List<Object[]> filas = progresoRepository.findEstadisticasPorTema(usuarioId, ramaId);
        if (filas.isEmpty()) return List.of();

        List<Long> temaIds = filas.stream().map(f -> (Long) f[0]).toList();
        Map<Long, String> nombresPorId = temaRepository.findAllById(temaIds).stream()
                .collect(Collectors.toMap(Tema::getId, Tema::getNombre));

        return filas.stream()
                .map(f -> {
                    Long temaId = (Long) f[0];
                    long total = (Long) f[1];
                    long correctas = ((Number) f[2]).longValue();
                    double pct = total == 0 ? 0.0 : Math.round((double) correctas / total * 100.0) / 1.0;
                    return TemaDebilDto.builder()
                            .temaId(temaId)
                            .nombre(nombresPorId.getOrDefault(temaId, "Tema " + temaId))
                            .porcentajeAcierto(pct)
                            .totalRespondidas(total)
                            .build();
                })
                .sorted(Comparator.comparingDouble(TemaDebilDto::getPorcentajeAcierto))
                .limit(3)
                .toList();
    }

    /**
     * Racha desde hoy hacia atrás: cuenta días consecutivos
     * si el día más reciente es hoy o ayer.
     */
    private int calcularRachaActual(List<Date> diasDesc) {
        if (diasDesc.isEmpty()) return 0;

        LocalDate hoy = LocalDate.now();
        LocalDate primero = diasDesc.get(0).toLocalDate();

        if (!primero.equals(hoy) && !primero.equals(hoy.minusDays(1))) return 0;

        int racha = 1;
        for (int i = 1; i < diasDesc.size(); i++) {
            LocalDate anterior = diasDesc.get(i - 1).toLocalDate();
            LocalDate actual = diasDesc.get(i).toLocalDate();
            if (anterior.minusDays(1).equals(actual)) {
                racha++;
            } else {
                break;
            }
        }
        return racha;
    }

    /**
     * Mejor racha histórica: máxima secuencia de días consecutivos.
     */
    private int calcularMejorRacha(List<Date> diasDesc) {
        if (diasDesc.isEmpty()) return 0;

        int mejor = 1;
        int actual = 1;
        for (int i = 1; i < diasDesc.size(); i++) {
            LocalDate anterior = diasDesc.get(i - 1).toLocalDate();
            LocalDate curr = diasDesc.get(i).toLocalDate();
            if (anterior.minusDays(1).equals(curr)) {
                actual++;
                mejor = Math.max(mejor, actual);
            } else {
                actual = 1;
            }
        }
        return mejor;
    }
}
