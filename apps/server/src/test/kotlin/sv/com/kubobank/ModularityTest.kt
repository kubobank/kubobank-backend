package sv.com.kubobank

import org.junit.jupiter.api.Test
import org.springframework.modulith.core.ApplicationModules

class ModularityTest {
    @Test
    fun verifyModularity() {
        // This scans the entire classpath starting at this package
        val modules = ApplicationModules.of("sv.com.kubobank")

        println("--- Detected Modules ---")
        modules.forEach(::println)

        modules.verify()
    }
}