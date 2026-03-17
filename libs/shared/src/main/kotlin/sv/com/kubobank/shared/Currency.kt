package sv.com.kubobank.shared

data class Currency(
    val code: String,
    val type: CurrencyType,
    val decimals: Int,
    val symbol: String,
    val active: Boolean,
)
