# Release Process

## Files to update

1. `pubspec.yaml` - update `version` field

## Alpha release

1. Set version to `x.y.z-alpha.N` (e.g. `1.0.0-alpha.1`) in `pubspec.yaml`
2. Create a GitHub release tagged `x.y.z-alpha.N`, **check "Set as pre-release"**
3. GitHub Actions runs the `publish-alpha` job and pushes to pub.dev
4. Install with `dart pub add apialerts:1.0.0-alpha.1` - not picked up by default version resolution

## Full release

1. Set version to `x.y.z` in `pubspec.yaml`
2. Create a GitHub release tagged `x.y.z`, **uncheck "Set as pre-release"**
3. GitHub Actions runs the `publish-release` job and pushes to pub.dev
4. Becomes the new stable release - `dart pub add apialerts` picks it up

## pub.dev trusted publishing

OIDC trusted publishing must be configured on pub.dev for this package. No API key secret is required.
