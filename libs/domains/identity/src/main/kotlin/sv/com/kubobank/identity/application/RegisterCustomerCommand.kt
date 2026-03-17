package sv.com.kubobank.identity.application

import sv.com.kubobank.identity.domain.PhoneNumber

data class RegisterCustomerCommand(
    val fullName: String,
    val email: String,
    val phoneNumber: PhoneNumber,
)
