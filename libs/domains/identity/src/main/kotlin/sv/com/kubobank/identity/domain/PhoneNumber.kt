package sv.com.kubobank.identity.domain

import org.jmolecules.ddd.annotation.ValueObject

@ValueObject
data class PhoneNumber(
    val number: String,
    val countryCode: String = "+503",
){
    fun asString() = "$countryCode$number"
}