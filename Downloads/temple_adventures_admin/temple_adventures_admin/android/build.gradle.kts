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

// Force NDK version for all subprojects to avoid version conflicts
// This ensures all Flutter plugins (including jni from sentry_flutter) use the same NDK version
subprojects {
    // Set early via project properties (before evaluation)
    project.ext.set("android.ndkVersion", "29.0.13599879")
    
    // Also set after evaluation to override any plugin settings
    afterEvaluate {
        // Try multiple approaches to set NDK version
        try {
            val android = project.extensions.findByName("android")
            if (android != null) {
                // Method 1: Direct property access via reflection
                try {
                    val ndkVersionField = android::class.java.getDeclaredField("ndkVersion")
                    ndkVersionField.isAccessible = true
                    ndkVersionField.set(android, "29.0.13599879")
                } catch (e: Exception) {
                    // Method 2: Use setter method
                    try {
                        val setNdkVersion = android::class.java.getMethod("setNdkVersion", String::class.java)
                        setNdkVersion.invoke(android, "29.0.13599879")
                    } catch (e2: Exception) {
                        // Method 3: Use extension property if available
                        try {
                            if (android is com.android.build.gradle.BaseExtension) {
                                android.ndkVersion = "29.0.13599879"
                            }
                        } catch (e3: Exception) {
                            // If all methods fail, try setting via project properties
                            project.ext.set("android.ndkVersion", "29.0.13599879")
                        }
                    }
                }
            }
        } catch (e: Exception) {
            // Some projects might not have android extension
            // This is expected for non-Android projects
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
