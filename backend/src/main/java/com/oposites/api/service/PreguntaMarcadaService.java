package com.oposites.api.service;

import com.oposites.api.exception.AppException;
import com.oposites.api.model.dto.response.PreguntasMarcadasConteoResponse;
import com.oposites.api.model.entity.Pregunta;
import com.oposites.api.model.entity.PreguntaMarcada;
import com.oposites.api.model.entity.PreguntaMarcadaId;
import com.oposites.api.model.entity.Usuario;
import com.oposites.api.repository.PreguntaMarcadaRepository;
import com.oposites.api.repository.PreguntaRepository;
import com.oposites.api.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class PreguntaMarcadaService {

    private final PreguntaMarcadaRepository marcadaRepository;
    private final PreguntaRepository preguntaRepository;
    private final UsuarioRepository usuarioRepository;

    /**
     * Marca la pregunta [preguntaId] para el usuario. Idempotente.
     */
    @Transactional
    public void marcar(String email, Long preguntaId) {
        Usuario usuario = findUsuario(email);
        Pregunta pregunta = preguntaRepository.findById(preguntaId)
                .orElseThrow(() -> new AppException("Pregunta no encontrada", HttpStatus.NOT_FOUND));

        PreguntaMarcadaId id = new PreguntaMarcadaId(usuario.getId(), preguntaId);
        if (!marcadaRepository.existsById(id)) {
            marcadaRepository.save(PreguntaMarcada.builder()
                    .id(id)
                    .usuario(usuario)
                    .pregunta(pregunta)
                    .build());
        }
    }

    /**
     * Desmarca la pregunta [preguntaId] para el usuario. Idempotente.
     */
    @Transactional
    public void desmarcar(String email, Long preguntaId) {
        Long usuarioId = findUsuario(email).getId();
        marcadaRepository.deleteByUsuarioIdAndPreguntaId(usuarioId, preguntaId);
    }

    /**
     * Devuelve el número de preguntas marcadas del usuario.
     * Si ramaId es null, cuenta todas las marcadas sin filtrar por rama.
     */
    public PreguntasMarcadasConteoResponse getConteo(String email, Long ramaId) {
        Long usuarioId = findUsuario(email).getId();
        long total = marcadaRepository.countByUsuarioIdAndRamaId(usuarioId, ramaId);
        return new PreguntasMarcadasConteoResponse(total);
    }

    private Usuario findUsuario(String email) {
        return usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new AppException("Usuario no encontrado", HttpStatus.NOT_FOUND));
    }
}
