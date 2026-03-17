package sv.com.kubobank.domain

import java.util.UUID
import java.time.Instant
import org.jmolecules.event.annotation.DomainEvent

@DomainEvent
interface DomainEvent {
    val eventId: UUID
    val occurredAt: Instant
}