import org.gradle.api.plugins.JavaPlugin
// Root build.gradle.kts
plugins {
    alias(libs.plugins.kotlin.jvm) apply false
    alias(libs.plugins.kotlin.spring) apply false
    alias(libs.plugins.spring.boot) apply false
    alias(libs.plugins.spring.dependency) apply false
    kotlin("plugin.noarg") version "2.0.0" apply false
}

subprojects {

    if (project.path.startsWith(":libs:domains")) {
        //apply(plugin = "kotlin-noarg")
        apply(plugin = "org.jetbrains.kotlin.plugin.noarg")
        configure<org.jetbrains.kotlin.noarg.gradle.NoArgExtension> {
            annotation("sv.com.kubobank.shared.annotations.NoArg")
        }
 /*       noArg {
            // This will target any class annotated with jMolecules or DDD annotations
            annotation("org.jmolecules.ddd.annotation.AggregateRoot")
            annotation("org.jmolecules.ddd.annotation.Entity")
            // Or create a dummy annotation for your Commands
        }*/

        apply(plugin = "java")
        apply(plugin = "org.jetbrains.kotlin.jvm")

        // Access the version catalog via rootProject
        val libs = rootProject.extensions.getByType<VersionCatalogsExtension>().named("libs")

        dependencies {
            // 2. Use findLibrary with type-safe configuration name
            libs.findLibrary("jmolecules-ddd").ifPresent {
                add("implementation", it)
            }
            libs.findLibrary("jmolecules-events").ifPresent {
                add("implementation", it)
            }
        }
    }
}
