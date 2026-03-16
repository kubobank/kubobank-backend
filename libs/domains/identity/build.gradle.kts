plugins {
    alias(libs.plugins.kotlin.jvm)
}

group = "sv.com.kubobank.identity"
version = "0.0.1-SNAPSHOT"

dependencies {
    // If 'identity' needs 'lib-shared'
    // implementation(project(":libs:domains:lib-shared"))
}

dependencies {
    testImplementation(kotlin("test"))
}

kotlin {
    jvmToolchain(21)
}

tasks.test {
    useJUnitPlatform()
}