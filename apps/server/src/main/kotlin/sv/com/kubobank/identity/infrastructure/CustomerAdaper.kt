package sv.com.kubobank.identity.infrastructure

import org.springframework.stereotype.Component
import sv.com.kubobank.identity.application.CustomerRepository
import sv.com.kubobank.identity.domain.Customer

@Component
class CustomerAdaper : CustomerRepository {
    override fun save(customer: Customer): Customer {
        //TODO("Not yet implemented")
        println("TODO")
        return customer
    }
}