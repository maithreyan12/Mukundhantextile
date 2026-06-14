allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir = layout.buildDirectory.dir("../../build").get().asFile
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir = rootProject.layout.buildDirectory.dir(project.name).get().asFile
    project.layout.buildDirectory.set(newSubprojectBuildDir)
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

