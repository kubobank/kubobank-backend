package sv.com.kubobank.shared

data class Jurisdiction(
    val countryCode: String,
    val name: String,
    val allowedCurrencies: List<Currency>,
)
