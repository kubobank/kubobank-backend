package sv.com.kubobank.domain

data class Jurisdiction(
    val countryCode: String,
    val name: String,
    val allowedCurrencies: List<Currency>,
)
