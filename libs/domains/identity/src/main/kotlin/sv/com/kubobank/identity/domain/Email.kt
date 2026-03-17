package sv.com.kubobank.identity.domain

import org.jmolecules.ddd.annotation.ValueObject

@ValueObject
data class Email(
    val address: String,
)
