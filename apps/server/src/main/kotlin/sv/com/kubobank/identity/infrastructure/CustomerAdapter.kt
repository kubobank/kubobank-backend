package sv.com.kubobank.identity.infrastructure

import org.springframework.stereotype.Repository
import sv.com.kubobank.identity.application.CustomerRepository
import sv.com.kubobank.identity.domain.Customer
import sv.com.kubobank.identity.infrastructure.persistence.CustomerMapper

@Repository
class CustomerAdapter(
    private val customerMapper: CustomerMapper,
) : CustomerRepository {
    override fun save(customer: Customer): Customer {
        val rowsAffected = customerMapper.insert(customer)
        if (rowsAffected == 0) {
            throw IllegalArgumentException("Failed to insert customer with ID: ${customer.customerId}")
        }
        return customer
    }
}