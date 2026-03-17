package sv.com.kubobank.shared.infrastructure

import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.module.kotlin.KotlinModule
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.context.annotation.Primary

@Configuration
class JacksonConfig {
/*    @Bean
    @Primary
    fun objectMapper(): ObjectMapper {
        return ObjectMapper()
            .findAndRegisterModules() // This finds the JSR310 (Instant) module
            .registerKotlinModule()    // This fixes the "no Creators" error
    }*/
    @Bean
    @Primary
    fun objectMapper(): ObjectMapper {
        return ObjectMapper()
            .registerModule(KotlinModule.Builder().build()) // Esto habilita el soporte para Data Classes
            .findAndRegisterModules() // Esto habilita soporte para Java 8 dates (Instant, LocalDateTime)
    }

}