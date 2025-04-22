allprojects {
    repositories {
        google()
        mavenCentral()
    }

    // Add configurations to handle missing plugins
    configurations.all {
        resolutionStrategy {
            force("com.aboutyou.dart_packages:sign_in_with_apple:0.0.0")
        }
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
