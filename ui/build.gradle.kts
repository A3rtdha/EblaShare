plugins {
    `java-library`
    application
}

val fatJar by tasks.registering(Jar::class) {
    group = LifecycleBasePlugin.BUILD_GROUP
    description = "Assembles a runnable fat jar for EblaShare UI."
    archiveClassifier.set("all")

    manifest {
        attributes["Main-Class"] = "ebla.ui.TrayApp"
    }

    duplicatesStrategy = DuplicatesStrategy.EXCLUDE

    from(sourceSets.main.get().output)
    dependsOn(configurations.runtimeClasspath)

    from({
        configurations.runtimeClasspath.get()
            .filter { it.name.endsWith(".jar") }
            .map { zipTree(it) }
    })
}

dependencies {
    implementation(project(":core"))
    implementation(project(":filesync"))
    implementation(project(":monitor"))
    implementation(project(":apm"))
    implementation("org.openjfx:javafx-controls:21")
}

application {
    mainClass.set("ebla.ui.TrayApp")
}

tasks.assemble {
    dependsOn(fatJar)
}
