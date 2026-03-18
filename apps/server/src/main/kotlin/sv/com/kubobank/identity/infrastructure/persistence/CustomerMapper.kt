package sv.com.kubobank.identity.infrastructure.persistence

import org.apache.ibatis.annotations.Mapper
import sv.com.kubobank.identity.domain.Customer

@Mapper
interface CustomerMapper {
    fun insert(customer: Customer): Int
}