package sv.com.kubobank.identity.application

import sv.com.kubobank.domain.DomainEventPublisher
import sv.com.kubobank.identity.domain.Customer
import sv.com.kubobank.identity.domain.CustomerRegistered
import java.util.UUID

class RegisterCustomerHandler(
    private val eventPublisher: DomainEventPublisher,
    private val repository: CustomerRepository,
) {

    fun handle(command: RegisterCustomerCommand): UUID {

        val customer = Customer(
            fullName = command.fullName,
            email = command.email,
            phoneNumber = command.phoneNumber.asString()
        )

        val savedCustomer = repository.save(customer)
        val event = CustomerRegistered(savedCustomer.customerId)
        eventPublisher.publish(event)

        return customer.customerId
    }
}