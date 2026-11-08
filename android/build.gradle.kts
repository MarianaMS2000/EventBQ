allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    tasks.configureEach {
        if (name.contains("compile") && name.contains("Kotlin")) {
            try {
                val kotlinOptions = this.property("kotlinOptions")
                val freeArgsMethod = kotlinOptions?.javaClass?.getMethod("getFreeCompilerArgs")
                val setArgsMethod = kotlinOptions?.javaClass?.getMethod("setFreeCompilerArgs", List::class.java)
                if (freeArgsMethod != null && setArgsMethod != null) {
                    @Suppress("UNCHECKED_CAST")
                    val list = (freeArgsMethod.invoke(kotlinOptions) as? List<String>) ?: emptyList()
                    if (!list.contains("-Xskip-metadata-version-check")) {
                        setArgsMethod.invoke(kotlinOptions, list + "-Xskip-metadata-version-check")
                    }
                }
            } catch (_: Exception) {}
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
