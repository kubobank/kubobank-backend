package sv.com.kubobank.identity.infrastructure

import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.transaction.annotation.Transactional
import sv.com.kubobank.shared.DomainEventPublisher
import sv.com.kubobank.identity.application.CustomerRepository
import sv.com.kubobank.identity.application.RegisterCustomerHandler

@Configuration
class IdentityConfig {

    @Bean
    @Transactional // 🔥 Vital para que Spring Modulith guarde los eventos
    fun registerCustomerHandler(
        customerRepository: CustomerRepository,
        domainEventPublisher: DomainEventPublisher,
    ): RegisterCustomerHandler {
        return RegisterCustomerHandler(domainEventPublisher, customerRepository)
    }
}