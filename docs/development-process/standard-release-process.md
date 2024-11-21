# Standard Release Process

The following document is a description of the standard release process of
Zarhus-related images. Precise steps and differences from the standard
process will be described in layer-specific documentation.

## Process steps

1. Make sure that everything that should go into the given release is merged
   into `develop`.
2. Bump `DISTRO_VERSION` in the `conf/distro/<distro-name>.conf` file.
3. Fill up the `CHANGELOG.md` file with latest changes.
    - Run `generate-changelog.sh` to generate the change notes for your release.
    - Use the `generate-changed-recipes` script to print the list of changes in
      recipe versions. The script uses build manifests - lists of recipes
      contained in the image along with their versions. You must provide your
      manifest and the current release's manifest as arguments to the script.
      The latter can be found in the latest release's section in the GitHub
      release pages. The current manifest can be found under the Yocto working
      directory in
      `build/tmp/deploy/images/{machine-name}/{image-name}.manifest`.
    - Paste the script output into your release's section in `CHANGELOG.md`.
      Additionally, you must explain why those changes were made and what they
      introduce (unless the commit messages listed by `generate-changelog.sh`
      already explain that).
    - Describe any additional changes.
4. Commit and push the changelog.
5. Merge the changes from `develop` into `main`.
6. Create and push a tag to `main` that matches the newly bumped version, with
   `v` added at the beginning (e.g. `v2.0.1-rc.1`).
7. Publish the release on GitHub. The release description should be the same as
   the release notes for that version. The following artifacts should be
   uploaded: The image (usually as `wic.gz` and `wic.bmap`), the manifest and
   `sha256` sum of each of those files. Additionally, if possible, upload the
   signatures of files (`*.sha256.sig`). In case of a `release candidate`, you
   should publish it as a pre-release.

## Versioning scheme

`Zarhus`-related layers are versioned using the
[semantic versioning](https://semver.org) scheme with the following
clarifications and additions:

- `PATCH` version is incremented with each released `HOTFIX`
- `PATCH` version is zeroed with the increment of `MINOR` or `MAJOR` versions
- `MINOR` version is incremented with every `FEATURE` release (may include more
  than one feature) unless `MAJOR` version is incremented
- `MINOR` version is zeroed with the increment of `MAJOR` version
- `MAJOR` version is incremented according to the project road map. Project road
  map should define at which point in time or with which feature set next
  `MAJOR` release is ready.

### Release candidate

Depending on the need of a particular software project, a `pre-release`
(`release candidate`) version may be released. The version format must follow
the [pre-release semver versioning scheme](https://semver.org/#spec-item-9).
Generally, we shall use the following scheme for `release candidates`:

```text
MAJOR.MINOR.PATCH-rc.RC_ID
```

where the `RC_ID` starts with 1.
