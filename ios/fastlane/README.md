fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios release_firebase

```sh
[bundle exec] fastlane ios release_firebase
```

Upload app to Firebase

### ios fetch_dev_certificate

```sh
[bundle exec] fastlane ios fetch_dev_certificate
```

fetch adhoc certificate

### ios fetch_adhoc_certificate

```sh
[bundle exec] fastlane ios fetch_adhoc_certificate
```

fetch adhoc certificate

### ios fetch_appstore_certificate

```sh
[bundle exec] fastlane ios fetch_appstore_certificate
```

fetch appstore certificate

### ios release_appstore

```sh
[bundle exec] fastlane ios release_appstore
```

Upload app to appstore

### ios fetch_certificates

```sh
[bundle exec] fastlane ios fetch_certificates
```

Fetches the certificates and provisioning profiles to run the project on real devices

### ios update_certificates

```sh
[bundle exec] fastlane ios update_certificates
```

Updates the certificates and provisioning profiles

### ios update_adhoc_certificate

```sh
[bundle exec] fastlane ios update_adhoc_certificate
```

update adhoc certificate

### ios update_appstore_certificate

```sh
[bundle exec] fastlane ios update_appstore_certificate
```

update appstore certificate

### ios nuke_certificates

```sh
[bundle exec] fastlane ios nuke_certificates
```

Revoke and clear certificates of a given type, then regenerate

### ios update_dev_certificate

```sh
[bundle exec] fastlane ios update_dev_certificate
```

update dev certificate

### ios update_build_number

```sh
[bundle exec] fastlane ios update_build_number
```



----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
