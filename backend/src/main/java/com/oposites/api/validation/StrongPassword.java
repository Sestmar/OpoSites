package com.oposites.api.validation;

import jakarta.validation.Constraint;
import jakarta.validation.Payload;

import java.lang.annotation.*;

/**
 * Valida que una contraseña cumpla la política de seguridad de opoSites:
 *
 *  - Mínimo 8 caracteres
 *  - Máximo 72 caracteres (límite interno de BCrypt)
 *  - Al menos 1 letra mayúscula  [A-Z]
 *  - Al menos 1 letra minúscula  [a-z]
 *  - Al menos 1 dígito           [0-9]
 *  - Al menos 1 carácter especial: ! @ # $ % ^ & * ( ) _ + - = [ ] { } ; ' : " \ | , . < > / ?
 */
@Target(ElementType.FIELD)
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Constraint(validatedBy = StrongPasswordValidator.class)
public @interface StrongPassword {

    String message() default "La contraseña debe tener entre 8 y 72 caracteres, "
            + "incluyendo mayúscula, minúscula, número y carácter especial";

    Class<?>[] groups() default {};

    Class<? extends Payload>[] payload() default {};
}
