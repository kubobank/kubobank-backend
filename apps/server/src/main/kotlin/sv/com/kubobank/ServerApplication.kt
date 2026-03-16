package sv.com.kubobank

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.runApplication
import sv.com.kubobank.domain.Currency
import sv.com.kubobank.domain.CurrencyType

@SpringBootApplication
class ServerApplication

fun main(args: Array<String>) {
	runApplication<ServerApplication>(*args)
	val usd = Currency("USD", CurrencyType.FIAT_FOREIGN, 2, "$", true)
	println(usd)
}
