# cpp-conan-release-reusable-workflow

Reusable GitHub Actions workflows for building, testing, and releasing the
dice-group/tentris C++/Conan projects.

## Releasing

Go to **Actions -> Release -> Run workflow**, pick `major`, `minor`, or
`patch`, and run it on `main`.

This computes the next version from the latest `vX.Y.Z` tag, rewrites this
repo's own `@main` action references to that tag, and pushes it as the new
release tag. Downstream repos pin to that tag, e.g.:

```yaml
uses: dice-group/cpp-conan-release-reusable-workflow/.github/workflows/publish-release.yml@v2.1.1
```
