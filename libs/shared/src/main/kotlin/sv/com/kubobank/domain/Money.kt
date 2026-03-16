package sv.com.kubobank.domain

import java.math.BigDecimal
import java.math.RoundingMode

data class Money(
    val currency: Currency,
    val amount: BigDecimal,
){

     operator fun plus(other: Money): Money {
        checkCurrency(other)
        return Money(currency, this.amount.add(other.amount))
    }

    operator fun minus(other: Money): Money {
        checkCurrency(other)
        return Money(currency, this.amount.subtract(other.amount))
    }



    fun format() : String {
        val decimals = if (isCrypto()) 8 else 2
        val formattedAmount = amount.setScale(decimals, RoundingMode.HALF_UP).toPlainString()
        return "$formattedAmount ${currency.code}"
    }


    private fun checkCurrency(other: Money) {
        if(this.currency.code != other.currency.code) {
            throw IllegalArgumentException("Currency mismatch: ${this.currency.code}")
        }
    }

    private fun isCrypto(): Boolean = currency.type == CurrencyType.CRYPTO
}
