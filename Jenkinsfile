// Reconstructed from the console log of build #150 (2025-08-27, Finished: SUCCESS),
// the last known end-to-end green run -- it produced tag 1.1.9(29271790).
//
// Jenkins runs an inline "Pipeline script" (CpsFlowDefinition) from the job
// config, NOT this file. Paste this script into the job config, or switch the job
// to "Pipeline script from SCM" so this file becomes the source of truth.
//
// Requires these credential IDs to exist in Jenkins -- an undefined ID aborts the
// pipeline before any stage runs:
//   MAC_NODE_PASSWORD, MATCH_PASSWORD, FIREBASE_CLI_TOKEN,
//   FIREBASE_DISTRIBUTION_SERVICE_ACCOUNT, APPSTORE_API_KEY_ID,
//   APPSTORE_ISSUER_ID, APPSTORE_API_KEY_PATH, GOOGLE_SERVICE_ACCOUNT_JSON_KEY_PATH,
//   ANDROID_SIGNING_STORE_FILE, ANDROID_SIGNING_STORE_PASSWORD,
//   ANDROID_SIGNING_KEY_ALIAS, ANDROID_SIGNING_KEY_PASSWORD
pipeline {
  agent any
  parameters {
    choice(name: 'DEPLOYMENT_ENV', choices: ['development', 'staging', 'production'], description: 'Whats your deployment environment')
    string(name: 'GIT_BRANCH', defaultValue: 'main', description: 'enter branch name to run')
  }
  options {
    timeout(time: 30, unit: 'MINUTES')
  }
  environment {
    // Used to unlock the login keychain so codesigning can read the certs.
    MAC_NODE_PASSWORD = credentials('MAC_NODE_PASSWORD')
    MATCH_PASSWORD = credentials('MATCH_PASSWORD')
    FIREBASE_CLI_TOKEN = credentials('FIREBASE_CLI_TOKEN')
    // Preferred over FIREBASE_CLI_TOKEN, which is tied to a personal Google account
    // and already died once with "invalid_grant". Uncomment once a Secret file
    // credential with this exact ID exists in Jenkins -- referencing a missing
    // credential ID aborts the pipeline before stage one. release_firebase picks it
    // up automatically and ignores the token when it is set.
    FIREBASE_DISTRIBUTION_SERVICE_ACCOUNT = credentials('FIREBASE_DISTRIBUTION_SERVICE_ACCOUNT')
    APPSTORE_API_KEY_ID = credentials('APPSTORE_API_KEY_ID')
    APPSTORE_ISSUER_ID = credentials('APPSTORE_ISSUER_ID')
    APPSTORE_API_KEY_PATH = credentials('APPSTORE_API_KEY_PATH')

    GOOGLE_SERVICE_ACCOUNT_JSON_KEY_PATH = credentials('GOOGLE_SERVICE_ACCOUNT_JSON_KEY_PATH')
    ANDROID_SIGNING_STORE_FILE = credentials('ANDROID_SIGNING_STORE_FILE')
    ANDROID_SIGNING_STORE_PASSWORD = credentials('ANDROID_SIGNING_STORE_PASSWORD')
    ANDROID_SIGNING_KEY_ALIAS = credentials('ANDROID_SIGNING_KEY_ALIAS')
    ANDROID_SIGNING_KEY_PASSWORD = credentials('ANDROID_SIGNING_KEY_PASSWORD')

    // ExportOptions plists, checked into the repo. Build #150 bound these from
    // Jenkins credentials, but the masking log only reveals the variable names,
    // not the credential IDs -- and guessing an ID aborts the whole pipeline
    // before stage one. The repo copies hold the same method / provisioning
    // profile / teamID, so use them directly and drop the lookup.
    EXPORT_OPTION_AD_HOC = "${WORKSPACE}/Jenkins/ios/export-options/ad-hoc.plist"
    EXPORT_OPTION_APP_STORE = "${WORKSPACE}/Jenkins/ios/export-options/app-store.plist"

    // These values are compiled into the Flutter binary and attached to every
    // Crashlytics event. Keep distribution channels explicit: Firebase Ad Hoc
    // is staging, while TestFlight/App Store is production.
    AD_HOC_APP_ENV = 'staging'
    APP_STORE_APP_ENV = 'production'
  }
  stages {
    stage('Prepare Agent') {
      steps {
        // Ruby's rbconfig invokes gmkdir (Homebrew coreutils) during `make
        // install` for gems with native extensions, and links against gmp.
        // Without them `bundle update fastlane` fails on every native gem.
        // Idempotent: a no-op once the agent has them.
        sh '''
            for pkg in coreutils gmp; do
              brew list --formula "$pkg" >/dev/null 2>&1 || brew install "$pkg"
            done
        '''
        // A Kotlin compile daemon left over from an older Kotlin version rejects
        // every request over RMI (serialVersionUID mismatch), so Gradle falls
        // back to slow in-process compilation and floods the log with traces.
        sh 'pkill -f KotlinCompileDaemon || true'
      }
    }

    stage('Flutter Doctor') {
      steps {
        sh 'flutter doctor -v'
        sh 'security unlock-keychain -p "$MAC_NODE_PASSWORD" ~/Library/Keychains/login.keychain-db'
        // Unlocking is not enough for a freshly imported signing key: its ACL
        // still has no partition list, so codesign fails with
        // errSecInternalComponent from this non-GUI session. match sets this at
        // import time, but repair any key already imported without it.
        sh '''
            security set-key-partition-list \
              -S apple-tool:,apple:,codesign: \
              -s -k "$MAC_NODE_PASSWORD" \
              ~/Library/Keychains/login.keychain-db >/dev/null 2>&1 || true
        '''
      }
    }

    stage('Git Checkout') {
      steps {
        cleanWs()
        git branch: GIT_BRANCH, url: 'git@github.com:vikas4goyal/DocForge.git'
      }
    }

    stage('Flutter Clean Build') {
      steps {
        sh 'flutter clean'
        // CocoaPods is no longer used; iOS dependencies are resolved with SPM.
        // sh 'rm -rf ios/pods'
        // sh 'rm -rf ios/podfile.lock'
        sh 'flutter pub get'
        // dir(path: 'ios') {
        //   sh 'pod install --repo-update'
        // }
        sh 'flutter build ios --release --no-codesign'
        sh 'flutter build appbundle --debug'
      }
    }

    stage('Update Build Number') {
      when {
        expression {
          if (params.DEPLOYMENT_ENV == 'production') {
            return GIT_BRANCH == 'main' || GIT_BRANCH == 'master'
          } else if (params.DEPLOYMENT_ENV == 'staging') {
            return (GIT_BRANCH == 'main' || GIT_BRANCH == 'master')
          }
          return false
        }
      }
      steps {
        script {
          // Assigned without `def` so they stay visible to later stages.
          BUILD_VERSION = sh(script: 'cat Jenkins/build_version', returnStdout: true).trim()
          BUILD_NUMBER = sh(script: 'echo $(($(date +%s)/60))', returnStdout: true).trim()
          env.IMAGE_TAG = "${BUILD_VERSION} (${BUILD_NUMBER})"
          currentBuild.description = "${env.IMAGE_TAG}"
          echo "BUILD_VERSION: ${BUILD_VERSION}"
          echo "BUILD_NUMBER: ${BUILD_NUMBER}"
          echo "BUILD_DESCRIPTION: ${currentBuild.description}"
          sh "echo ${BUILD_NUMBER} > Jenkins/build_number"
          sh "git tag \"${BUILD_VERSION}(${BUILD_NUMBER})\""
          sh "git push origin \"${BUILD_VERSION}(${BUILD_NUMBER})\""
          sh 'flutter clean'
          sh 'rm -rf build'
          sh 'flutter pub get'
        }
      }
    }

    stage('Release Firebase') {
      when {
        expression {
          if (params.DEPLOYMENT_ENV == 'production') {
            return GIT_BRANCH == 'main' || GIT_BRANCH == 'master'
          } else if (params.DEPLOYMENT_ENV == 'staging') {
            return (GIT_BRANCH == 'main' || GIT_BRANCH == 'master')
          }
          return false
        }
      }
      parallel {
        stage('IOS') {
          steps {
            dir(path: 'ios') {
              sh 'bundle install'
              sh 'bundle update fastlane'
              sh 'bundle exec fastlane update_plugins'
              sh 'bundle exec fastlane ios update_build_number --verbose'
              sh 'bundle exec fastlane ios fetch_adhoc_certificate --verbose'
              // sh 'pod install --repo-update'
            }
            sh 'test "$AD_HOC_APP_ENV" = staging && echo "Building iOS Ad Hoc environment: $AD_HOC_APP_ENV"'
            sh "flutter build ipa --dart-define=\"ENVIRONMENT=\$AD_HOC_APP_ENV\" --build-name=${BUILD_VERSION} --build-number=${BUILD_NUMBER} --release --export-options-plist=\"\$EXPORT_OPTION_AD_HOC\" --verbose"
            // `flutter build ipa` exits 0 even when xcodebuild prints
            // "** EXPORT FAILED **", so an export error would otherwise surface much
            // later as a confusing "couldn't find ipa" from the upload lane.
            sh 'ls build/ios/ipa/*.ipa >/dev/null 2>&1 || { echo "No IPA produced - look for \'** EXPORT FAILED **\' above"; exit 1; }'
            dir(path: 'ios') {
              sh 'bundle exec fastlane ios release_firebase --verbose'
            }
          }
        }
        stage('Android') {
          steps {
            dir(path: 'android') {
              sh 'bundle install'
              sh 'bundle update fastlane'
              sh 'bundle exec fastlane update_plugins'
              sh 'bundle exec fastlane android update_build_number --verbose'
              // app/build.gradle reads this for the release signing config. It is
              // gitignored and cleanWs() wipes the workspace, so it must be written
              // on every run -- without it :app:signReleaseBundle throws a bare
              // NullPointerException under AGP 8.13+.
              sh '''
                  printf '%s\\n' \
                    "storePassword=$ANDROID_SIGNING_STORE_PASSWORD" \
                    "keyPassword=$ANDROID_SIGNING_KEY_PASSWORD" \
                    "keyAlias=$ANDROID_SIGNING_KEY_ALIAS" \
                    "storeFile=$ANDROID_SIGNING_STORE_FILE" \
                    > key.properties
              '''
            }
            sh 'test "$AD_HOC_APP_ENV" = staging && echo "Building Android Firebase environment: $AD_HOC_APP_ENV"'
            sh "flutter build apk --dart-define=\"ENVIRONMENT=\$AD_HOC_APP_ENV\" --build-name=${BUILD_VERSION} --build-number=${BUILD_NUMBER} --release --verbose"
            dir(path: 'android') {
              sh 'bundle exec fastlane android release_firebase --verbose'
            }
          }
        }
      }
    }

    stage('Clean') {
      steps {
        sh 'rm -rf build'
        sh 'flutter clean'
        sh 'flutter pub get'
      }
    }

    stage('Release PlayStore/AppStore') {
      when {
        expression {
          if (params.DEPLOYMENT_ENV == 'production') {
            return GIT_BRANCH == 'main' || GIT_BRANCH == 'master'
          }
          return false
        }
      }
      parallel {
        stage('Release IOS') {
          steps {
            dir(path: 'ios') {
              sh 'bundle exec fastlane ios fetch_appstore_certificate --verbose'
              // sh 'pod install --repo-update'
            }
            sh 'test "$APP_STORE_APP_ENV" = production && echo "Building iOS App Store environment: $APP_STORE_APP_ENV"'
            sh "flutter build ipa --dart-define=\"ENVIRONMENT=\$APP_STORE_APP_ENV\" --build-name=${BUILD_VERSION} --build-number=${BUILD_NUMBER} --release --export-options-plist=\"\$EXPORT_OPTION_APP_STORE\" --verbose"
            sh 'ls build/ios/ipa/*.ipa >/dev/null 2>&1 || { echo "No IPA produced - look for \'** EXPORT FAILED **\' above"; exit 1; }'
            dir(path: 'ios') {
              sh 'bundle exec fastlane ios release_appstore --verbose'
            }
          }
        }
        stage('Release Android') {
          steps {
            // Regenerate release signing input here as well so restarting the
            // pipeline from this production stage cannot reuse a debug-signed
            // or unsigned bundle.
            dir(path: 'android') {
              sh '''
                   printf '%s\\n' \\
                    "storePassword=$ANDROID_SIGNING_STORE_PASSWORD" \\
                    "keyPassword=$ANDROID_SIGNING_KEY_PASSWORD" \\
                    "keyAlias=$ANDROID_SIGNING_KEY_ALIAS" \\
                    "storeFile=$ANDROID_SIGNING_STORE_FILE" \\
                    > key.properties
              '''
            }
            sh 'test "$APP_STORE_APP_ENV" = production && echo "Building Android Play Store environment: $APP_STORE_APP_ENV"'
            sh "flutter build aab --dart-define=\"ENVIRONMENT=\$APP_STORE_APP_ENV\" --build-name=${BUILD_VERSION} --build-number=${BUILD_NUMBER} --release --verbose"
            dir(path: 'android') {
              sh 'bundle exec fastlane android send_to_play_store --verbose'
            }
          }
        }
      }
    }
  }
}
