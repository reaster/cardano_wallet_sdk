# Flutter SDK Notes

## BUILD RUNNER:
```
flutter packages pub run build_runner build
```

## COMMIT BUG FIX BY NUMBER:
```
git commit -m "fix #xxx"
```

## PUBLISHING STEPS:
* update pubspec.yaml <version>
* update CHANGELOG.md <version>
* flutter clean
* dart test -P itest
* dart analyze .
* dart format .
* git commit -m "<version>"
* git push
* flutter packages pub publish --dry-run

## MISC NOTES:
