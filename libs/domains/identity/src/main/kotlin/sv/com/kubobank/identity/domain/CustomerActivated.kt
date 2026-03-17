package sv.com.kubobank.identity.domain

import org.jmolecules.event.annotation.DomainEvent
import java.util.UUID

@DomainEvent
data class CustomerActivated(
    val customerId: UUID,
)
