package sv.com.kubobank.account.infrastructure

import org.springframework.modulith.events.ApplicationModuleListener
import org.springframework.stereotype.Component
import sv.com.kubobank.identity.domain.CustomerRegistered

@Component
class AccountModuleListener {
    @ApplicationModuleListener
    fun on(event: CustomerRegistered) {
        println("Received event for customer: ${event.customerId}")
    }
}