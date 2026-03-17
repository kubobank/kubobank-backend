package sv.com.kubobank.identity.domain

import sv.com.kubobank.shared.DomainEvent
import java.time.Instant
import java.util.UUID

data class CustomerRegistered(
    val customerId: UUID,
    override val eventId: UUID = UUID.randomUUID(),
    override val occurredAt: Instant = Instant.now(),
) : DomainEvent
