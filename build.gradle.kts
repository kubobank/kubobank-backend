import org.gradle.api.plugins.JavaPlugin
// Root build.gradle.kts
plugins {
    alias(libs.plugins.kotlin.jvm) apply false
    alias(libs.plugins.kotlin.spring) apply false
    alias(libs.plugins.spring.boot) apply false
    alias(libs.plugins.spring.dependency) apply false
}

subprojects {

    if (project.path.startsWith(":libs:domains")) {

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
