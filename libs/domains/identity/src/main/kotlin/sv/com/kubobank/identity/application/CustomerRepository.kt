package sv.com.kubobank.identity.application

import sv.com.kubobank.identity.domain.Customer

interface CustomerRepository {
    fun save(customer: Customer): Customer
}