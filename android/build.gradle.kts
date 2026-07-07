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
// Pin every module (app + plugin subprojects) to an NDK that is already
// installed locally, so Gradle never tries to auto-download another one.
// Runs after each module's own script so it also wins over plugins that set
// ndkVersion themselves; must be registered before evaluationDependsOn below.
subprojects {
    fun pinNdk() {
        (extensions.findByName("android") as? com.android.build.gradle.BaseExtension)
            ?.ndkVersion = "29.0.14206865"
    }
    if (state.executed) pinNdk() else afterEvaluate { pinNdk() }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
