package com.oposites.api.service;

import com.oposites.api.exception.AppException;
import com.oposites.api.model.dto.request.CreateEventoRequest;
import com.oposites.api.model.dto.request.UpdateEventoRequest;
import com.oposites.api.model.dto.response.EventoResponse;
import com.oposites.api.model.entity.CalendarioEvento;
import com.oposites.api.model.entity.RamaOposicion;
import com.oposites.api.model.entity.Usuario;
import com.oposites.api.model.enums.TipoEvento;
import com.oposites.api.repository.CalendarioEventoRepository;
import com.oposites.api.repository.RamaOposicionRepository;
import com.oposites.api.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class CalendarioService {

    private final CalendarioEventoRepository calendarioRepository;
    private final UsuarioRepository usuarioRepository;
    private final RamaOposicionRepository ramaRepository;

    // ─── Endpoints USER ────────────────────────────────────────────────────────

    public List<EventoResponse> listarEventos(String email, LocalDateTime desde, LocalDateTime hasta, TipoEvento tipo) {
        Usuario usuario = findUsuario(email);

        // Por defecto: mes actual
        LocalDateTime efectivoDesde = desde != null ? desde
                : LocalDateTime.now().withDayOfMonth(1).withHour(0).withMinute(0).withSecond(0).withNano(0);
        LocalDateTime efectivoHasta = hasta != null ? hasta
                : efectivoDesde.plusMonths(1).minusSeconds(1);

        return calendarioRepository.findFiltered(usuario.getId(), efectivoDesde, efectivoHasta, tipo)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    public EventoResponse getEvento(Long id, String email) {
        Usuario usuario = findUsuario(email);
        return toResponse(findByIdAndOwner(id, usuario.getId()));
    }

    @Transactional
    public EventoResponse crearManual(String email, CreateEventoRequest request) {
        Usuario usuario = findUsuario(email);
        RamaOposicion rama = resolveRama(request.getRamaId());

        CalendarioEvento evento = CalendarioEvento.builder()
                .usuario(usuario)
                .rama(rama)
                .titulo(request.getTitulo())
                .descripcion(request.getDescripcion())
                .fechaInicio(request.getFechaInicio())
                .fechaFin(request.getFechaFin())
                .tipo(request.getTipo())
                .autoGenerado(false)
                .build();

        return toResponse(calendarioRepository.save(evento));
    }

    @Transactional
    public EventoResponse editarManual(Long id, String email, UpdateEventoRequest request) {
        Usuario usuario = findUsuario(email);
        CalendarioEvento evento = findByIdAndOwner(id, usuario.getId());

        if (evento.isAutoGenerado()) {
            throw new AppException("No se puede editar un evento generado automáticamente", HttpStatus.BAD_REQUEST);
        }

        if (request.getTitulo() != null)      evento.setTitulo(request.getTitulo());
        if (request.getDescripcion() != null) evento.setDescripcion(request.getDescripcion());
        if (request.getFechaInicio() != null) evento.setFechaInicio(request.getFechaInicio());
        if (request.getFechaFin() != null)    evento.setFechaFin(request.getFechaFin());

        return toResponse(calendarioRepository.save(evento));
    }

    @Transactional
    public void eliminarManual(Long id, String email) {
        Usuario usuario = findUsuario(email);
        CalendarioEvento evento = findByIdAndOwner(id, usuario.getId());

        if (evento.isAutoGenerado()) {
            throw new AppException("No se puede eliminar un evento generado automáticamente", HttpStatus.BAD_REQUEST);
        }

        calendarioRepository.delete(evento);
    }

    // ─── Llamado interno desde TestService y SimulacroService ─────────────────

    /**
     * Crea un evento de calendario automáticamente al completar un test o simulacro.
     * Recibe entidades ya cargadas para evitar consultas adicionales a la BD.
     */
    @Transactional
    public void crearAutoGenerado(Usuario usuario, RamaOposicion rama, String titulo, TipoEvento tipo) {
        CalendarioEvento evento = CalendarioEvento.builder()
                .usuario(usuario)
                .rama(rama)
                .titulo(titulo)
                .tipo(tipo)
                .fechaInicio(LocalDateTime.now())
                .autoGenerado(true)
                .build();
        calendarioRepository.save(evento);
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

    private CalendarioEvento findByIdAndOwner(Long id, Long usuarioId) {
        return calendarioRepository.findByIdAndUsuarioId(id, usuarioId)
                .orElseThrow(() -> new AppException("Evento no encontrado", HttpStatus.NOT_FOUND));
    }

    private RamaOposicion resolveRama(Long ramaId) {
        if (ramaId == null) return null;
        return ramaRepository.findById(ramaId)
                .orElseThrow(() -> new AppException("Oposición no encontrada", HttpStatus.NOT_FOUND));
    }

    private Usuario findUsuario(String email) {
        return usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new AppException("Usuario no encontrado", HttpStatus.NOT_FOUND));
    }

    // ─── Mapping ──────────────────────────────────────────────────────────────

    private EventoResponse toResponse(CalendarioEvento e) {
        return EventoResponse.builder()
                .id(e.getId())
                .titulo(e.getTitulo())
                .descripcion(e.getDescripcion())
                .fechaInicio(e.getFechaInicio())
                .fechaFin(e.getFechaFin())
                .tipo(e.getTipo())
                .ramaId(e.getRama() != null ? e.getRama().getId() : null)
                .nombreRama(e.getRama() != null ? e.getRama().getNombre() : null)
                .autoGenerado(e.isAutoGenerado())
                .build();
    }
}
