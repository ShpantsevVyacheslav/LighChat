allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Workaround for older Flutter plugins that don't declare `android.namespace` yet.
// Gradle 8 + AGP 8+ requires `namespace` to be set for Android library modules.
subprojects {
    if (project.name != "flutter_windowmanager") return@subprojects

    // Configure as soon as the Android library plugin is applied (no afterEvaluate).
    plugins.withId("com.android.library") {
        extensions.findByName("android")?.let { androidExt ->
            try {
                val namespaceSetter = androidExt.javaClass.methods.firstOrNull { m ->
                    m.name == "setNamespace" &&
                        m.parameterTypes.size == 1 &&
                        m.parameterTypes[0] == String::class.java
                }
                namespaceSetter?.invoke(androidExt, "io.adaptant.labs.flutter_windowmanager")
            } catch (_: Throwable) {
                // Best-effort: if AGP APIs change, build will still surface a clear error.
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
