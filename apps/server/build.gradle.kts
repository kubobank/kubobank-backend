plugins {
	alias(libs.plugins.kotlin.jvm)
	alias(libs.plugins.kotlin.spring)
	alias(libs.plugins.spring.boot)
	alias(libs.plugins.spring.dependency)
}

group = "sv.com.kubobank"
version = "0.0.1-SNAPSHOT"
description = "Demo project for Spring Boot"

java {
	toolchain {
		languageVersion = JavaLanguageVersion.of(21)
	}
}

dependencies {
/*	implementation("org.springframework.boot:spring-boot-starter-liquibase")
	//implementation("org.springframework.boot:spring-boot-starter-validation")
	//implementation("org.springframework.boot:spring-boot-starter-webmvc")
	//implementation("org.jetbrains.kotlin:kotlin-reflect")
	//implementation("org.mybatis.spring.boot:mybatis-spring-boot-starter:4.0.1")
	//implementation("tools.jackson.module:jackson-module-kotlin")
	//runtimeOnly("org.postgresql:postgresql")
	//testImplementation("org.springframework.boot:spring-boot-starter-liquibase-test")
	//testImplementation("org.springframework.boot:spring-boot-starter-validation-test")
	//testImplementation("org.springframework.boot:spring-boot-starter-webmvc-test")
	//testImplementation("org.jetbrains.kotlin:kotlin-test-junit5")
	//testImplementation("org.mybatis.spring.boot:mybatis-spring-boot-starter-test:4.0.1")
	//testRuntimeOnly("org.junit.platform:junit-platform-launcher")*/

	// This tells Gradle: "Include the code and resources from libs/core"

	//implementation(project(":libs:core")) // This brings in Mybatis/DB logic
	implementation("org.springframework.boot:spring-boot-starter-web")
	implementation("org.springframework.boot:spring-boot-starter-validation")
	implementation("org.jetbrains.kotlin:kotlin-reflect")
	implementation("com.fasterxml.jackson.module:jackson-module-kotlin")
	implementation("com.fasterxml.jackson.datatype:jackson-datatype-jsr310")
	implementation("org.springframework.boot:spring-boot-starter-json") // Usually includes the above
	testImplementation("org.springframework.boot:spring-boot-starter-test")
	// 1. Import the BOM first to align versions
	implementation(platform(libs.spring.modulith.bom))

	// 2. Add the starters
	implementation(libs.spring.modulith.starter.core)
	implementation(libs.spring.modulith.starter.jdbc) // For the Postgres Event Registry
	implementation(libs.spring.modulith.events.jackson)

	// 3. Testing modularity
	testImplementation(libs.spring.modulith.test)
	implementation("org.springframework.boot:spring-boot-starter-liquibase")
	// 1. Database Core (This fixes your DataSource error)
	implementation("org.mybatis.spring.boot:mybatis-spring-boot-starter:3.0.3")
	// This ensures Instant, LocalDateTime, etc., map correctly to Postgres Timestamps
	implementation("org.mybatis:mybatis-typehandlers-jsr310:1.0.2")
	implementation("org.springframework.boot:spring-boot-starter-jdbc")
	runtimeOnly("org.postgresql:postgresql")

	// 2. MyBatis (Spring Boot Starter)
	//implementation("org.mybatis.spring.boot:mybatis-spring-boot-starter:3.0.3")

	// 3. Spring Modulith (which needs the DataSource above)
	//implementation(libs.spring.modulith.starter.jdbc)
	implementation(project(":libs:shared"))
	// Your domain projects
	implementation(project(":libs:domains:identity"))
}

kotlin {
	compilerOptions {
		freeCompilerArgs.addAll("-Xjsr305=strict", "-Xannotation-default-target=param-property")
	}
}

tasks.withType<Test> {
	useJUnitPlatform()
}
