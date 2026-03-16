plugins {
    alias(libs.plugins.kotlin.jvm)
    alias(libs.plugins.spring.dependency) // To use Spring versions
    // DO NOT include the Spring Boot "executable" plugin here.
}

group = "sv.com.kubobank"
version = "0.0.1-SNAPSHOT"

dependencies {
    testImplementation(kotlin("test"))
}

kotlin {
    jvmToolchain(21)
}

tasks.test {
    useJUnitPlatform()
}

dependencies {
    // Database & Persistence
/*    implementation("org.springframework.boot:spring-boot-starter-liquibase")
    implementation("org.mybatis.spring.boot:mybatis-spring-boot-starter:4.0.1")
    runtimeOnly("org.postgresql:postgresql")

    // Testing for DB
    testImplementation("org.springframework.boot:spring-boot-starter-test")
    testImplementation("org.mybatis.spring.boot:mybatis-spring-boot-starter-test:4.0.1")*/
}
