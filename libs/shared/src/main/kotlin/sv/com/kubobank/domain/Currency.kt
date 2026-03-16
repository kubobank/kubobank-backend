package sv.com.kubobank.domain

data class Currency(
    val code: String,
    val type: CurrencyType,
    val decimals: Int,
    val symbol: String,
    val active: Boolean,
)
