package sv.com.kubobank.identity.application

import jakarta.validation.Valid
import jakarta.validation.constraints.Email
import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.NotNull
import sv.com.kubobank.identity.domain.PhoneNumber

data class RegisterCustomerCommand(
    @field:NotBlank(message = "Full name is required")
    val fullName: String,
    @field:Email(message = "Invalid email format")
    @field:NotBlank(message = "Email is required")
    val email: String,
    @field:NotNull(message = "Phone number is required")
    @field:Valid // This tells Spring to also validate the fields inside PhoneNumber
    val phoneNumber: PhoneNumber,
)
