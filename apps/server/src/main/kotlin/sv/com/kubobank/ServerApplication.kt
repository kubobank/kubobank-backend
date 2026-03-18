package sv.com.kubobank

import org.mybatis.spring.annotation.MapperScan
import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.runApplication
import sv.com.kubobank.shared.Currency
import sv.com.kubobank.shared.CurrencyType

@SpringBootApplication(scanBasePackages = ["sv.com.kubobank"])
@MapperScan("sv.com.kubobank.identity.infrastructure.persistence")
class ServerApplication

fun main(args: Array<String>) {
	runApplication<ServerApplication>(*args)
	val usd = Currency("USD", CurrencyType.FIAT_FOREIGN, 2, "$", true)
	println(usd)
}
