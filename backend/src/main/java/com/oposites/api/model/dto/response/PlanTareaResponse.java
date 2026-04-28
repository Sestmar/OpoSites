package com.oposites.api.model.dto.response;

import com.oposites.api.model.enums.TipoPlanTarea;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDate;

@Data
@Builder
public class PlanTareaResponse {

    private Long id;
    private TipoPlanTarea tipo;
    private Long temaId;
    private String nombreTema;
    private Long simulacroId;
    private String nombreSimulacro;
    private LocalDate fecha;
    private boolean completada;
    private String descripcion; // generada en el mapping, no persistida
}
