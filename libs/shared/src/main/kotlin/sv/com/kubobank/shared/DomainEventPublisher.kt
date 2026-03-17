package sv.com.kubobank.shared

interface DomainEventPublisher {
    fun publish(event: DomainEvent)
}