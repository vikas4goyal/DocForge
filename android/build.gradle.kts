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
// Pin every plugin subproject to a compileSdk that actually exists locally.
//
// Some plugins (receive_sharing_intent among them) hardcode `compileSdk 37`,
// but the Android SDK now installs that platform as `android-37.0`, so Gradle
// fails with "Failed to find target with hash string 'android-37'". Overriding
// here stops a single plugin from dictating the whole build's SDK, and applies
// identically on a developer machine and in CI.
//
// This must be registered BEFORE the evaluationDependsOn block below: that call
// forces subproject evaluation, after which afterEvaluate can no longer be
// added and Gradle fails with "project is already evaluated".
subprojects {
    afterEvaluate {
        extensions.findByName("android")?.let { androidExtension ->
            (androidExtension as com.android.build.gradle.BaseExtension)
                .compileSdkVersion(36)
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
