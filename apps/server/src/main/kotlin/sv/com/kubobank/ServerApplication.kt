package sv.com.kubobank

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.runApplication
import org.springframework.modulith.Modulithic
import sv.com.kubobank.domain.Currency
import sv.com.kubobank.domain.CurrencyType

@Modulithic(
	// Only put modules here that ARE libraries (like libs:shared)
	sharedModules = ["sv.com.kubobank.shared"],
	// This tells Modulith to look for modules in these sub-packages
	additionalPackages = ["sv.com.kubobank.identity"]
)
@SpringBootApplication(scanBasePackages = ["sv.com.kubobank"])
class ServerApplication

fun main(args: Array<String>) {
	runApplication<ServerApplication>(*args)
	val usd = Currency("USD", CurrencyType.FIAT_FOREIGN, 2, "$", true)
	println(usd)
}
