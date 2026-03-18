package sv.com.kubobank.identity.domain

import org.jmolecules.ddd.annotation.AggregateRoot
import java.time.Instant
import java.time.LocalDateTime
import java.util.UUID

@AggregateRoot
class Customer(
    val customerId: UUID = UUID.randomUUID(),
    val fullName: String,
    val email: String,
    val phoneNumber: PhoneNumber,
    val status: CustomerStatus = CustomerStatus.PENDING,
    val createdAt: Instant = Instant.now(),
    val updatedAt: Instant = Instant.now(),
) {
    // Business logic example
    fun activate() {
        // status = CustomerStatus.ACTIVE
        // updatedAt = Instant.now()
    }
}