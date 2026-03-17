package sv.com.kubobank.domain

interface DomainEventPublisher {
    fun publish(event: DomainEvent)
}