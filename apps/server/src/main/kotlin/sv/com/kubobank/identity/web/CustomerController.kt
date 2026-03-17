package sv.com.kubobank.identity.web

import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController
import sv.com.kubobank.identity.application.RegisterCustomerCommand
import sv.com.kubobank.identity.application.RegisterCustomerHandler
import java.util.UUID

@RestController
@RequestMapping("/api/v1/customer")
class CustomerController(
    private val registerHandler: RegisterCustomerHandler,
) {
    @PostMapping
    fun register(@RequestBody command: RegisterCustomerCommand): ResponseEntity<UUID> {
        val customerId = registerHandler.handle(command)
        return ResponseEntity.status(HttpStatus.CREATED).body(customerId)
    }
}