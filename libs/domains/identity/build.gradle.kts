import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    alias(libs.plugins.kotlin.jvm)
}

group = "sv.com.kubobank.identity"
version = "0.0.1-SNAPSHOT"

dependencies {
    // If 'identity' needs 'lib-shared'
    implementation(project(":libs:shared"))
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

tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinJvmCompile>().configureEach {
    compilerOptions {
        // This replaces javaParameters = true
        javaParameters.set(true)
        jvmTarget.set(JvmTarget.JVM_21)
    }
}


