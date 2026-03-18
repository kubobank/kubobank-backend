package sv.com.kubobank.shared.infrastructure

import com.fasterxml.jackson.module.kotlin.KotlinInvalidNullException
import org.springframework.http.ResponseEntity
import org.springframework.http.converter.HttpMessageNotReadableException
import org.springframework.web.bind.MethodArgumentNotValidException
import org.springframework.web.bind.annotation.ExceptionHandler
import org.springframework.web.bind.annotation.RestControllerAdvice
import org.springframework.dao.DataIntegrityViolationException
import org.springframework.http.HttpStatus

@RestControllerAdvice
class GlobalExceptionHandler {

    @ExceptionHandler(MethodArgumentNotValidException::class)
    fun handleValidationErrors(ex: MethodArgumentNotValidException): ResponseEntity<Map<String, Any>> {
        // Extract only the field name and the error message
        val errors = ex.bindingResult.fieldErrors.associate {
            it.field to (it.defaultMessage ?: "Invalid value")
        }

        val body = mapOf(
            "status" to 400,
            "error" to "Validation Failed",
            "messages" to errors
        )

        return ResponseEntity.badRequest().body(body)
    }

    @ExceptionHandler(HttpMessageNotReadableException::class)
    fun handleJsonErrors(ex: HttpMessageNotReadableException): ResponseEntity<Map<String, Any>> {
        val cause = ex.cause

        // Check if it's a missing Kotlin parameter (Null safety violation)
        if (cause is KotlinInvalidNullException) {
            val fieldName = cause.path.joinToString(".") { it.fieldName }
            return ResponseEntity.badRequest().body(mapOf(
                "status" to 400,
                "error" to "Missing Required Field",
                "messages" to mapOf(fieldName to "This field is mandatory")
            ))
        }

        return ResponseEntity.badRequest().body(mapOf(
            "status" to 400,
            "error" to "Malformed JSON",
            "message" to "The request body is invalid or empty"
        ))
    }

    @ExceptionHandler(DataIntegrityViolationException::class)
    fun handleDatabaseConflicts(ex: DataIntegrityViolationException): ResponseEntity<Map<String, Any>> {
        val message = ex.mostSpecificCause.message ?: ""

        // Check if it's the email constraint we defined in SQL
        if (message.contains("uq_customers_email")) {
            return ResponseEntity.status(HttpStatus.CONFLICT).body(mapOf(
                "status" to 409,
                "error" to "Conflict",
                "message" to "This email is already registered"
            ))
        }

        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(mapOf(
            "status" to 500,
            "error" to "Database Error",
            "message" to "An unexpected data error occurred"
        ))
    }
}