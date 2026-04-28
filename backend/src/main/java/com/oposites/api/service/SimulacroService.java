package com.oposites.api.service;

import com.oposites.api.exception.AppException;
import com.oposites.api.model.dto.request.CreateSimulacroRequest;
import com.oposites.api.model.dto.request.ResponderTestRequest;
import com.oposites.api.model.dto.request.UpdateSimulacroRequest;
import com.oposites.api.model.dto.response.*;
import com.oposites.api.model.entity.*;
import com.oposites.api.model.enums.EstadoSession;
import com.oposites.api.model.enums.TipoEvento;
import com.oposites.api.model.enums.TipoSession;
import com.oposites.api.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class SimulacroService {

    private final SimulacroRepository simulacroRepository;
    private final TestSessionRepository testSessionRepository;
    private final PreguntaRepository preguntaRepository;
    private final RamaOposicionRepository ramaRepository;
    private final TestService testService;
    private final CalendarioService calendarioService;

    // ─── Consultas públicas ───────────────────────────────────────────────────

    public List<SimulacroResponse> listarPorRama(Long ramaId) {
        return simulacroRepository.findByRamaIdOrderByNombreAsc(ramaId)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    public SimulacroResponse obtenerPorId(Long id) {
        return toResponse(findSimulacro(id));
    }

    // ─── Flujo de examen ─────────────────────────────────────────────────────

    @Transactional
    public TestIniciadoResponse iniciar(String email, Long simulacroId) {
        Usuario usuario = testService.findUsuario(email);
        Simulacro simulacro = findSimulacro(simulacroId);

        List<Pregunta> preguntas = preguntaRepository.findRandomByTemaIds(
                simulacro.getTemasIncluidos(), null, simulacro.getPreguntasCount());

        if (preguntas.isEmpty()) {
            throw new AppException("No hay preguntas disponibles para este simulacro", HttpStatus.BAD_REQUEST);
        }

        List<Long> preguntaIds = preguntas.stream().map(Pregunta::getId).toList();

        TestSession session = TestSession.builder()
                .usuario(usuario)
                .simulacro(simulacro)
                .rama(simulacro.getRama())
                .tipo(TipoSession.SIMULACRO)
                .preguntaIds(preguntaIds)
                .totalPreguntas(preguntas.size())
                .fechaInicio(LocalDateTime.now())
                .build();

        testSessionRepository.save(session);

        return TestIniciadoResponse.builder()
                .sessionId(session.getId())
                .preguntas(preguntas.stream().map(this::toPreguntaResponse).toList())
                .tiempoMinutos(simulacro.getDuracionMinutos())
                .build();
    }

    @Transactional
    public ResultadoTestResponse entregar(String email, Long simulacroId, ResponderTestRequest request) {
        Usuario usuario = testService.findUsuario(email);

        TestSession session = testSessionRepository
                .findByIdAndUsuarioId(request.getSessionId(), usuario.getId())
                .orElseThrow(() -> new AppException("Sesión no encontrada", HttpStatus.NOT_FOUND));

        if (session.getSimulacro() == null || !simulacroId.equals(session.getSimulacro().getId())) {
            throw new AppException("La sesión no pertenece a este simulacro", HttpStatus.BAD_REQUEST);
        }

        if (!EstadoSession.EN_CURSO.equals(session.getEstado())) {
            throw new AppException("La sesión ya fue completada", HttpStatus.BAD_REQUEST);
        }

        ResultadoTestResponse resultado = testService.completarSesion(session, request.getRespuestas());

        // Registro automático en el calendario
        calendarioService.crearAutoGenerado(
                session.getUsuario(),
                session.getRama(),
                "Simulacro: " + session.getSimulacro().getNombre(),
                TipoEvento.SIMULACRO);

        List<AnalisisTemaDto> analisis = calcularAnalisisPorTema(session, resultado);

        return ResultadoTestResponse.builder()
                .sessionId(resultado.getSessionId())
                .nota(resultado.getNota())
                .correctas(resultado.getCorrectas())
                .total(resultado.getTotal())
                .detalle(resultado.getDetalle())
                .analisisPorTema(analisis)
                .build();
    }

    // ─── Admin CRUD ───────────────────────────────────────────────────────────

    @Transactional
    public SimulacroResponse crear(Long ramaId, CreateSimulacroRequest request) {
        RamaOposicion rama = ramaRepository.findById(ramaId)
                .orElseThrow(() -> new AppException("Oposición no encontrada", HttpStatus.NOT_FOUND));

        Simulacro simulacro = Simulacro.builder()
                .rama(rama)
                .nombre(request.getNombre())
                .duracionMinutos(request.getDuracionMinutos())
                .preguntasCount(request.getPreguntasCount())
                .temasIncluidos(request.getTemasIncluidos())
                .fechaOficial(request.getFechaOficial())
                .build();

        return toResponse(simulacroRepository.save(simulacro));
    }

    @Transactional
    public SimulacroResponse actualizar(Long id, UpdateSimulacroRequest request) {
        Simulacro simulacro = findSimulacro(id);

        if (request.getNombre() != null) simulacro.setNombre(request.getNombre());
        if (request.getDuracionMinutos() != null) simulacro.setDuracionMinutos(request.getDuracionMinutos());
        if (request.getPreguntasCount() != null) simulacro.setPreguntasCount(request.getPreguntasCount());
        if (request.getTemasIncluidos() != null) simulacro.setTemasIncluidos(request.getTemasIncluidos());
        if (request.getFechaOficial() != null) simulacro.setFechaOficial(request.getFechaOficial());

        return toResponse(simulacroRepository.save(simulacro));
    }

    @Transactional
    public void eliminar(Long id) {
        if (!simulacroRepository.existsById(id)) {
            throw new AppException("Simulacro no encontrado", HttpStatus.NOT_FOUND);
        }
        simulacroRepository.deleteById(id);
    }

    // ─── Helpers ─────────────────────────────────────────────────────────────

    private List<AnalisisTemaDto> calcularAnalisisPorTema(TestSession session, ResultadoTestResponse resultado) {
        List<Pregunta> preguntas = preguntaRepository.findAllByIdWithTema(session.getPreguntaIds());
        Map<Long, Pregunta> porId = preguntas.stream()
                .collect(Collectors.toMap(Pregunta::getId, p -> p));

        // temaId → [total, correctas]
        Map<Long, int[]> acumulador = new LinkedHashMap<>();
        Map<Long, String> nombresTema = new LinkedHashMap<>();

        for (var detalle : resultado.getDetalle()) {
            Pregunta pregunta = porId.get(detalle.getPreguntaId());
            if (pregunta == null) continue;

            Long temaId = pregunta.getTema().getId();
            acumulador.computeIfAbsent(temaId, k -> new int[2]);
            nombresTema.putIfAbsent(temaId, pregunta.getTema().getNombre());

            acumulador.get(temaId)[0]++;
            if (detalle.isCorrecto()) acumulador.get(temaId)[1]++;
        }

        return acumulador.entrySet().stream()
                .map(e -> {
                    int total = e.getValue()[0];
                    int correctas = e.getValue()[1];
                    double pct = total == 0 ? 0.0 : Math.round((double) correctas / total * 100.0) / 1.0;
                    return AnalisisTemaDto.builder()
                            .temaId(e.getKey())
                            .nombreTema(nombresTema.get(e.getKey()))
                            .total(total)
                            .correctas(correctas)
                            .porcentajeAcierto(pct)
                            .build();
                })
                .toList();
    }

    private Simulacro findSimulacro(Long id) {
        return simulacroRepository.findById(id)
                .orElseThrow(() -> new AppException("Simulacro no encontrado", HttpStatus.NOT_FOUND));
    }

    private SimulacroResponse toResponse(Simulacro s) {
        return SimulacroResponse.builder()
                .id(s.getId())
                .ramaId(s.getRama().getId())
                .nombre(s.getNombre())
                .duracionMinutos(s.getDuracionMinutos())
                .preguntasCount(s.getPreguntasCount())
                .temasIncluidos(s.getTemasIncluidos())
                .fechaOficial(s.getFechaOficial())
                .build();
    }

    private PreguntaResponse toPreguntaResponse(Pregunta p) {
        return PreguntaResponse.builder()
                .id(p.getId())
                .temaId(p.getTema().getId())
                .enunciado(p.getEnunciado())
                .tipo(p.getTipo())
                .opciones(p.getOpciones())
                .dificultad(p.getDificultad())
                .build();
    }
}
