package com.oposites.api.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.oposites.api.exception.AppException;
import com.oposites.api.model.dto.request.CreatePlanTareaRequest;
import com.oposites.api.model.dto.request.UpdatePlanConfiguracionRequest;
import com.oposites.api.model.dto.response.PlanConfiguracionResponse;
import com.oposites.api.model.dto.response.PlanHoyResponse;
import com.oposites.api.model.dto.response.PlanTareaResponse;
import com.oposites.api.model.entity.PlanTarea;
import com.oposites.api.model.entity.Simulacro;
import com.oposites.api.model.entity.Tema;
import com.oposites.api.model.entity.Usuario;
import com.oposites.api.model.enums.PreferenciaPlan;
import com.oposites.api.model.enums.TipoPlanTarea;
import com.oposites.api.model.plan.PlanConfiguracion;
import com.oposites.api.repository.PlanTareaRepository;
import com.oposites.api.repository.ProgresoUsuarioRepository;
import com.oposites.api.repository.SimulacroRepository;
import com.oposites.api.repository.TemaRepository;
import com.oposites.api.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class PlanService {

    private static final int DIAS_PLAN = 7;
    private static final int TEMAS_DEBILES_MAX = 5;
    private static final int DIAS_EXAMEN_INTENSIVO = 30;

    private final PlanTareaRepository planTareaRepository;
    private final UsuarioRepository usuarioRepository;
    private final TemaRepository temaRepository;
    private final SimulacroRepository simulacroRepository;
    private final ProgresoUsuarioRepository progresoRepository;
    private final ObjectMapper objectMapper;

    // ─── Endpoints USER ───────────────────────────────────────────────────────

    public PlanHoyResponse getPlanHoy(String email) {
        Usuario usuario = findUsuario(email);
        LocalDate hoy = LocalDate.now();

        if (!planTareaRepository.existsByUsuarioIdAndFecha(usuario.getId(), hoy)) {
            generarYPersistirSemana(usuario, hoy);
        }

        List<PlanTarea> tareas = planTareaRepository.findByUsuarioIdAndFechaOrderByCreatedAtAsc(usuario.getId(), hoy);
        return toPlanHoyResponse(hoy, tareas);
    }

    public PlanConfiguracionResponse getConfiguracion(String email) {
        Usuario usuario = findUsuario(email);
        PlanConfiguracion config = leerConfig(usuario);
        return toConfigResponse(usuario, config);
    }

    @Transactional
    public PlanConfiguracionResponse actualizarConfiguracion(String email, UpdatePlanConfiguracionRequest request) {
        Usuario usuario = findUsuario(email);
        PlanConfiguracion config = leerConfig(usuario);

        if (request.getHorasSemana() != null)  config.setHorasSemana(request.getHorasSemana());
        if (request.getPreferencia() != null)   config.setPreferencia(request.getPreferencia());

        usuario.setPlanManual(escribirConfig(config));

        if (request.getFechaExamenObjetivo() != null) {
            usuario.setFechaExamenObjetivo(request.getFechaExamenObjetivo());
        }

        usuarioRepository.save(usuario);
        return toConfigResponse(usuario, config);
    }

    @Transactional
    public PlanHoyResponse generarPlan(String email) {
        Usuario usuario = findUsuario(email);
        LocalDate hoy = LocalDate.now();

        // Borra tareas incompletas desde hoy y regenera los próximos 7 días
        planTareaRepository.deleteIncompletsDesde(usuario.getId(), hoy);
        generarYPersistirSemana(usuario, hoy);

        List<PlanTarea> tareas = planTareaRepository.findByUsuarioIdAndFechaOrderByCreatedAtAsc(usuario.getId(), hoy);
        return toPlanHoyResponse(hoy, tareas);
    }

    @Transactional
    public PlanTareaResponse crearTareaManual(String email, CreatePlanTareaRequest request) {
        Usuario usuario = findUsuario(email);
        LocalDate hoy = LocalDate.now();

        PlanTarea tarea = PlanTarea.builder()
                .usuario(usuario)
                .tipo(request.getTipo())
                .fecha(hoy)
                .manual(true)
                .descripcion(request.getDescripcion())
                .build();

        return toTareaResponse(planTareaRepository.save(tarea));
    }

    @Transactional
    public void eliminarTarea(Long tareaId, String email) {
        PlanTarea tarea = planTareaRepository
                .findByIdAndUsuarioId(tareaId, findUsuario(email).getId())
                .orElseThrow(() -> new AppException("Tarea no encontrada", HttpStatus.NOT_FOUND));

        if (tarea.isCompletada()) {
            throw new AppException(
                    "No se puede eliminar una tarea ya completada", HttpStatus.CONFLICT);
        }

        planTareaRepository.delete(tarea);
    }

    @Transactional
    public PlanTareaResponse completarTarea(Long tareaId, String email) {
        PlanTarea tarea = planTareaRepository.findByIdAndUsuarioId(tareaId, findUsuario(email).getId())
                .orElseThrow(() -> new AppException("Tarea no encontrada", HttpStatus.NOT_FOUND));

        tarea.setCompletada(true);
        return toTareaResponse(planTareaRepository.save(tarea));
    }

    // ─── Generación del plan ──────────────────────────────────────────────────

    private void generarYPersistirSemana(Usuario usuario, LocalDate desde) {
        List<PlanTarea> todasLasTareas = new ArrayList<>();
        for (int i = 0; i < DIAS_PLAN; i++) {
            // No sobreescribir días que ya tienen tareas (ej. días futuros ya generados)
            LocalDate dia = desde.plusDays(i);
            if (!planTareaRepository.existsByUsuarioIdAndFecha(usuario.getId(), dia)) {
                todasLasTareas.addAll(generarTareasParaDia(usuario, dia));
            }
        }
        if (!todasLasTareas.isEmpty()) {
            planTareaRepository.saveAll(todasLasTareas);
        }
    }

    private List<PlanTarea> generarTareasParaDia(Usuario usuario, LocalDate fecha) {
        PlanConfiguracion config = leerConfig(usuario);
        Long ramaId = usuario.getRamaPrincipalId();

        List<Tema> temasDebiles = resolverTemasDebiles(usuario.getId(), ramaId);
        boolean modoIntensivo = esExamenProximo(usuario);

        return construirTareas(usuario, fecha, config.getPreferencia(), temasDebiles, modoIntensivo);
    }

    /**
     * Devuelve hasta TEMAS_DEBILES_MAX temas para el usuario.
     * Si tiene datos de progreso: ordena por menor % acierto.
     * Si no tiene progreso aún: devuelve los primeros temas de la rama en orden secuencial.
     */
    private List<Tema> resolverTemasDebiles(Long usuarioId, Long ramaId) {
        if (ramaId == null) return List.of();

        Set<Long> temasPracticados = progresoRepository.findTemaIdsPracticados(usuarioId, ramaId);

        List<Long> temaIds;
        if (temasPracticados.isEmpty()) {
            // Usuario nuevo: seleccionar los primeros temas secuencialmente
            temaIds = temaRepository.findIdsByRamaId(ramaId)
                    .stream()
                    .limit(TEMAS_DEBILES_MAX)
                    .collect(Collectors.toList());
        } else {
            // Ordenar los temas practicados por debilidad (menor % acierto primero)
            temaIds = progresoRepository.findTemaIdsOrdenadosPorDebilidad(
                    usuarioId, ramaId, PageRequest.of(0, TEMAS_DEBILES_MAX));

            // Completar con temas no practicados si hay menos de TEMAS_DEBILES_MAX temas débiles
            if (temaIds.size() < TEMAS_DEBILES_MAX) {
                List<Long> noPracticados = temaRepository.findIdsByRamaId(ramaId)
                        .stream()
                        .filter(id -> !temasPracticados.contains(id))
                        .limit(TEMAS_DEBILES_MAX - temaIds.size())
                        .collect(Collectors.toList());
                temaIds = new ArrayList<>(temaIds);
                temaIds.addAll(noPracticados);
            }
        }

        return temaRepository.findAllById(temaIds);
    }

    private List<PlanTarea> construirTareas(
            Usuario usuario, LocalDate fecha,
            PreferenciaPlan preferencia,
            List<Tema> temas, boolean modoIntensivo) {

        List<PlanTarea> tareas = new ArrayList<>();

        Tema tema0 = temas.size() > 0 ? temas.get(0) : null;
        Tema tema1 = temas.size() > 1 ? temas.get(1) : null;
        Tema tema2 = temas.size() > 2 ? temas.get(2) : null;

        switch (preferencia) {
            case TEST -> {
                if (tema0 != null) tareas.add(buildTarea(usuario, fecha, TipoPlanTarea.TEST, tema0, null));
                if (tema1 != null) tareas.add(buildTarea(usuario, fecha, TipoPlanTarea.TEST, tema1, null));
                if (tema2 != null) tareas.add(buildTarea(usuario, fecha, TipoPlanTarea.REPASO, tema2, null));
            }
            case TEORIA -> {
                if (tema0 != null) tareas.add(buildTarea(usuario, fecha, TipoPlanTarea.REPASO, tema0, null));
                if (tema1 != null) tareas.add(buildTarea(usuario, fecha, TipoPlanTarea.REPASO, tema1, null));
                if (tema2 != null) tareas.add(buildTarea(usuario, fecha, TipoPlanTarea.TEST, tema2, null));
            }
            default -> { // MIXTO
                if (tema0 != null) tareas.add(buildTarea(usuario, fecha, TipoPlanTarea.TEST, tema0, null));
                if (tema1 != null) tareas.add(buildTarea(usuario, fecha, TipoPlanTarea.REPASO, tema1, null));

                if (modoIntensivo) {
                    // Modo intensivo: sustituir la 3ª tarea por un simulacro si hay disponible
                    Simulacro simulacro = resolverSimulacro(usuario.getRamaPrincipalId());
                    if (simulacro != null) {
                        tareas.add(buildTarea(usuario, fecha, TipoPlanTarea.SIMULACRO, null, simulacro));
                    } else if (tema2 != null) {
                        tareas.add(buildTarea(usuario, fecha, TipoPlanTarea.TEST, tema2, null));
                    }
                } else if (tema2 != null) {
                    tareas.add(buildTarea(usuario, fecha, TipoPlanTarea.REPASO, tema2, null));
                }
            }
        }

        return tareas;
    }

    private Simulacro resolverSimulacro(Long ramaId) {
        if (ramaId == null) return null;
        List<Simulacro> simulacros = simulacroRepository.findByRamaIdOrderByIdDesc(ramaId);
        return simulacros.isEmpty() ? null : simulacros.get(0);
    }

    private boolean esExamenProximo(Usuario usuario) {
        if (usuario.getFechaExamenObjetivo() == null) return false;
        long dias = ChronoUnit.DAYS.between(LocalDate.now(), usuario.getFechaExamenObjetivo());
        return dias >= 0 && dias <= DIAS_EXAMEN_INTENSIVO;
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

    private PlanTarea buildTarea(Usuario usuario, LocalDate fecha, TipoPlanTarea tipo, Tema tema, Simulacro simulacro) {
        return PlanTarea.builder()
                .usuario(usuario)
                .tipo(tipo)
                .tema(tema)
                .simulacro(simulacro)
                .fecha(fecha)
                .build();
    }

    private PlanConfiguracion leerConfig(Usuario usuario) {
        if (usuario.getPlanManual() == null || usuario.getPlanManual().isBlank()) {
            return PlanConfiguracion.builder().build();
        }
        try {
            return objectMapper.readValue(usuario.getPlanManual(), PlanConfiguracion.class);
        } catch (JsonProcessingException e) {
            return PlanConfiguracion.builder().build();
        }
    }

    private String escribirConfig(PlanConfiguracion config) {
        try {
            return objectMapper.writeValueAsString(config);
        } catch (JsonProcessingException e) {
            throw new AppException("Error al serializar la configuración del plan", HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    private Usuario findUsuario(String email) {
        return usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new AppException("Usuario no encontrado", HttpStatus.NOT_FOUND));
    }

    // ─── Mapping ──────────────────────────────────────────────────────────────

    private PlanHoyResponse toPlanHoyResponse(LocalDate fecha, List<PlanTarea> tareas) {
        List<PlanTareaResponse> responses = tareas.stream().map(this::toTareaResponse).toList();
        long completadas = tareas.stream().filter(PlanTarea::isCompletada).count();
        return PlanHoyResponse.builder()
                .fecha(fecha)
                .tareas(responses)
                .tareasCompletadas((int) completadas)
                .totalTareas(tareas.size())
                .build();
    }

    private PlanTareaResponse toTareaResponse(PlanTarea t) {
        return PlanTareaResponse.builder()
                .id(t.getId())
                .tipo(t.getTipo())
                .temaId(t.getTema() != null ? t.getTema().getId() : null)
                .nombreTema(t.getTema() != null ? t.getTema().getNombre() : null)
                .simulacroId(t.getSimulacro() != null ? t.getSimulacro().getId() : null)
                .nombreSimulacro(t.getSimulacro() != null ? t.getSimulacro().getNombre() : null)
                .fecha(t.getFecha())
                .completada(t.isCompletada())
                .descripcion(generarDescripcion(t))
                .manual(t.isManual())
                .build();
    }

    private String generarDescripcion(PlanTarea t) {
        // Las tareas manuales usan su descripción guardada si la tienen
        if (t.getDescripcion() != null && !t.getDescripcion().isBlank()) {
            return t.getDescripcion();
        }
        return switch (t.getTipo()) {
            case TEST -> t.getTema() != null
                    ? "Haz un test de 10 preguntas sobre " + t.getTema().getNombre()
                    : "Haz un test de repaso";
            case REPASO -> t.getTema() != null
                    ? "Repasa la teoría de " + t.getTema().getNombre()
                    : "Repasa los apuntes del día";
            case SIMULACRO -> t.getSimulacro() != null
                    ? "Completa el simulacro: " + t.getSimulacro().getNombre()
                    : "Completa un simulacro de práctica";
        };
    }

    private PlanConfiguracionResponse toConfigResponse(Usuario usuario, PlanConfiguracion config) {
        Long diasHastaExamen = usuario.getFechaExamenObjetivo() != null
                ? ChronoUnit.DAYS.between(LocalDate.now(), usuario.getFechaExamenObjetivo())
                : null;
        return PlanConfiguracionResponse.builder()
                .horasSemana(config.getHorasSemana())
                .preferencia(config.getPreferencia())
                .fechaExamenObjetivo(usuario.getFechaExamenObjetivo())
                .diasHastaExamen(diasHastaExamen)
                .build();
    }
}
