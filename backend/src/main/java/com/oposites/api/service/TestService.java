package com.oposites.api.service;

import com.oposites.api.exception.AppException;
import com.oposites.api.model.dto.request.GenerarTestRequest;
import com.oposites.api.model.dto.request.RespuestaDto;
import com.oposites.api.model.dto.request.ResponderTestRequest;
import com.oposites.api.model.dto.response.*;
import com.oposites.api.model.entity.*;
import com.oposites.api.model.enums.EstadoSession;
import com.oposites.api.model.enums.TipoEvento;
import com.oposites.api.model.enums.TipoSession;
import com.oposites.api.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.*;

@Service
@RequiredArgsConstructor
public class TestService {

    private final PreguntaRepository preguntaRepository;
    private final TemaRepository temaRepository;
    private final RamaOposicionRepository ramaRepository;
    private final TestSessionRepository testSessionRepository;
    private final ProgresoUsuarioRepository progresoRepository;
    private final UsuarioRepository usuarioRepository;
    private final CalendarioService calendarioService;
    private final PreguntaMarcadaRepository preguntaMarcadaRepository;

    // ─── Tests libres ─────────────────────────────────────────────────────────

    @Transactional
    public TestIniciadoResponse generar(String email, GenerarTestRequest request) {
        Usuario usuario = findUsuario(email);
        RamaOposicion rama = ramaRepository.findById(request.getRamaId())
                .orElseThrow(() -> new AppException("Oposición no encontrada", HttpStatus.NOT_FOUND));

        final List<Pregunta> preguntas;
        if (Boolean.TRUE.equals(request.getSoloMarcadas())) {
            preguntas = preguntaRepository.findRandomMarcadasByUsuario(
                    usuario.getId(), request.getRamaId());
            if (preguntas.isEmpty()) {
                throw new AppException(
                        "No tenés preguntas marcadas para esta oposición", HttpStatus.BAD_REQUEST);
            }
        } else {
            List<Long> temaIds = resolveTemaIds(request.getRamaId(), request.getTemaIds());
            preguntas = preguntaRepository.findRandomByTemaIds(
                    temaIds, request.getDificultad(), request.getCantidad());
            if (preguntas.isEmpty()) {
                throw new AppException(
                        "No hay preguntas disponibles con esos filtros", HttpStatus.BAD_REQUEST);
            }
        }

        List<Long> preguntaIds = preguntas.stream().map(Pregunta::getId).toList();

        TestSession session = TestSession.builder()
                .usuario(usuario)
                .rama(rama)
                .tipo(TipoSession.LIBRE)
                .preguntaIds(preguntaIds)
                .totalPreguntas(preguntas.size())
                .fechaInicio(LocalDateTime.now())
                .build();

        testSessionRepository.save(session);

        return TestIniciadoResponse.builder()
                .sessionId(session.getId())
                .preguntas(preguntas.stream().map(this::toPreguntaResponse).toList())
                .tiempoMinutos(request.getTiempoMinutos())
                .build();
    }

    @Transactional
    public ResultadoTestResponse responder(String email, ResponderTestRequest request) {
        TestSession session = testSessionRepository
                .findByIdAndUsuarioId(request.getSessionId(), findUsuario(email).getId())
                .orElseThrow(() -> new AppException("Sesión no encontrada", HttpStatus.NOT_FOUND));

        if (!EstadoSession.EN_CURSO.equals(session.getEstado())) {
            throw new AppException("La sesión ya fue completada", HttpStatus.BAD_REQUEST);
        }

        return completarSesion(session, request.getRespuestas());
    }

    public List<PreguntaResponse> getFallos(String email, Long ramaId, Long temaId) {
        Long usuarioId = findUsuario(email).getId();
        List<Long> ids = progresoRepository.findPreguntaIdsFalladas(
                usuarioId, ramaId, temaId, PageRequest.of(0, 50));
        return preguntaRepository.findAllById(ids).stream()
                .map(this::toPreguntaResponse)
                .toList();
    }

    // ─── Core de grading (reutilizado por SimulacroService) ───────────────────

    /**
     * Grades a session's answers, saves ProgresoUsuario rows and closes the session.
     * Called both from responder() and SimulacroService.entregar().
     */
    @Transactional
    public ResultadoTestResponse completarSesion(TestSession session, List<RespuestaDto> respuestas) {
        Set<Long> preguntasEnSession = new HashSet<>(session.getPreguntaIds());
        Map<Long, Pregunta> preguntasMap = preguntaRepository.findAllById(session.getPreguntaIds())
                .stream()
                .collect(HashMap::new, (m, p) -> m.put(p.getId(), p), HashMap::putAll);

        int totalEvaluables = (int) session.getPreguntaIds().stream()
                .map(preguntasMap::get)
                .filter(Objects::nonNull)
                .filter(p -> !p.isAnulada())
                .count();

        List<ResultadoPreguntaDto> detalle = new ArrayList<>();
        int correctas = 0;

        for (RespuestaDto r : respuestas) {
            // Ignorar preguntas que no pertenecen a esta sesión
            if (!preguntasEnSession.contains(r.getPreguntaId())) continue;

            Pregunta pregunta = Optional.ofNullable(preguntasMap.get(r.getPreguntaId()))
                    .orElseThrow(() -> new AppException("Pregunta no encontrada: " + r.getPreguntaId(), HttpStatus.NOT_FOUND));

            if (pregunta.isAnulada()) {
                detalle.add(ResultadoPreguntaDto.builder()
                        .preguntaId(pregunta.getId())
                        .correcto(true)
                        .respuestaUsuario(r.getRespuestaUsuario())
                        .respuestaCorrecta("ANULADA")
                        .explicacion(pregunta.getExplicacion())
                        .build());
                continue;
            }

            boolean correcto = esCorrecta(pregunta, r.getRespuestaUsuario());
            if (correcto) correctas++;

            progresoRepository.save(ProgresoUsuario.builder()
                    .usuario(session.getUsuario())
                    .pregunta(pregunta)
                    .testSession(session)
                    .respuestaUsuario(r.getRespuestaUsuario())
                    .correcto(correcto)
                    .fechaRespuesta(LocalDateTime.now())
                    .build());

            detalle.add(ResultadoPreguntaDto.builder()
                    .preguntaId(pregunta.getId())
                    .correcto(correcto)
                    .respuestaUsuario(r.getRespuestaUsuario())
                    .respuestaCorrecta(pregunta.getRespuestaCorrecta())
                    .explicacion(pregunta.getExplicacion())
                    .build());
        }

        session.setTotalPreguntas(totalEvaluables);

        double nota = calcularNota(correctas, totalEvaluables);
        session.setCorrectas(correctas);
        session.setNota(nota);
        session.setEstado(EstadoSession.COMPLETADO);
        session.setFechaFin(LocalDateTime.now());
        testSessionRepository.save(session);

        // Registro automático en el calendario
        calendarioService.crearAutoGenerado(
                session.getUsuario(),
                session.getRama(),
                "Test completado: " + session.getRama().getNombre(),
                TipoEvento.ESTUDIO);

        return ResultadoTestResponse.builder()
                .sessionId(session.getId())
                .nota(nota)
                .correctas(correctas)
                .total(session.getTotalPreguntas())
                .detalle(detalle)
                .build();
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

    private List<Long> resolveTemaIds(Long ramaId, List<Long> temaIds) {
        if (temaIds == null || temaIds.isEmpty()) {
            List<Long> ids = temaRepository.findIdsByRamaId(ramaId);
            if (ids.isEmpty()) {
                throw new AppException("Esta oposición no tiene temas disponibles", HttpStatus.BAD_REQUEST);
            }
            return ids;
        }
        return temaIds;
    }

    private boolean esCorrecta(Pregunta pregunta, String respuesta) {
        if (respuesta == null) return false;
        return respuesta.trim().equalsIgnoreCase(pregunta.getRespuestaCorrecta().trim());
    }

    private double calcularNota(int correctas, int total) {
        if (total == 0) return 0.0;
        return Math.round((double) correctas / total * 100.0) / 10.0;
    }

    Usuario findUsuario(String email) {
        return usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new AppException("Usuario no encontrado", HttpStatus.NOT_FOUND));
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
