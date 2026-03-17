plugins {
    alias(libs.plugins.kotlin.jvm)
    alias(libs.plugins.spring.dependency) // To use Spring versions
    // DO NOT include the Spring Boot "executable" plugin here.
}

group = "sv.com.kubobank.shared"
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
    implementation(libs.jmolecules.events)
    implementation(libs.jmolecules.ddd)
}
