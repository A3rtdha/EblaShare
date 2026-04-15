plugins {
    `java-library`
}

dependencies {
    implementation(project(":core"))
    implementation("com.github.oshi:oshi-core:6.6.0")
}
