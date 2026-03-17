package sv.com.kubobank.shared.infrastructure

import org.springframework.context.ApplicationEventPublisher
import org.springframework.stereotype.Component
import sv.com.kubobank.domain.DomainEvent
import sv.com.kubobank.domain.DomainEventPublisher

@Component
class SpringEventPublisher(
    private val springPublisher: ApplicationEventPublisher,
) : DomainEventPublisher {

    override fun publish(event: DomainEvent) {
        springPublisher.publishEvent(event)
    }
}