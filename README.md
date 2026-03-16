mkdir -p libs/domains/identity/src/main/kotlin
touch libs/domains/identity/build.gradle.kts

// settings.gradle.kts (at the root)
include(":libs:domains:identity")

// build.gradle.kts (lib)
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

// usar en server
implementation(project(":libs:shared"))
