# About

This repository contains source code for the Zarhus documentation webpage.

## Contribution

Please make sure to follow below steps before publishing your changes as a
merge request.

### Local build

```shell
virtualenv -p $(which python3) venv
source venv/bin/activate
pip install -r requirements.txt
mkdocs serve
```

By default, it will host a local copy of documentation at:
`http://0.0.0.0:8000/`.

If the following error occurs `OSError: [Errno 98] Address already in use`, try
using a different address by running the command `mkdocs serve -a
localhost:12345` (the number is random).

It is crucial at this point to verify that the pages you have changed
render correctly as HTML in local preview.

<!--
### Broken links checker

Currently we are using [lychee](https://github.com/lycheeverse/lychee) a fast,
async, stream-based link checker written in Rust. The automatic check is
triggered on each push to master PR.

You can also run it locally using a docker image:

```bash
$ docker run --init -it --rm -w $(pwd) -v $(pwd):$(pwd) lycheeverse/lychee
    --max-redirects 10 -a 403,429,500,502,503,999 .
```
-->

### Make sure no TBD or TODO content is displayed

Find all occurrences:

```shell
grep -E "TBD|TODO" docs/**/*.md -r
```

Iterate over all occurrences and check if:
- file, where TBD or TODO occurs, is displayed (included in nav section of
mkdocs.yml)
- TBD or TODO is visible on the website

There should be no TBD or TODO visible on the website.

### pre-commit hooks

- [Install pre-commit](https://pre-commit.com/index.html#install), if you
  followed [local build](#local-build) procedure `pre-commit` should be
  installed

- [Install go](https://go.dev/doc/install)

- Install hooks into repo:

  ```shell
  pre-commit install
  ```

- Enjoy automatic checks on each `git commit` action!

- (Optional) Run hooks on all files (for example, when adding new hooks or
  configuring existing ones):

  ```shell
  pre-commit run --all-files
  ```

#### To skip verification

In some cases, it may be needed to skip `pre-commit` tests. To do that, please
use:

```shell
git commit --no-verify
```

### Embedding videos

Embedding videos with in-line HTML `iframe` tag does not work.
[mkdocs-video](https://github.com/soulless-viewer/mkdocs-video) plugin is used
instead. To embed an video simply type the following in markdown:
`![type:video](https://www.youtube.com/embed/LXb3EKWsInQ)` (example).
