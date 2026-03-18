package sv.com.kubobank.identity.domain

import jakarta.validation.constraints.NotBlank
import org.jmolecules.ddd.annotation.ValueObject

@ValueObject
data class PhoneNumber(
    @field:NotBlank
    val number: String,
    @field:NotBlank
    val countryCode: String = "+503",
){
    fun asString() = "$countryCode$number"
}