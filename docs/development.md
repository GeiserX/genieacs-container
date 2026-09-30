# Development

## Building the image

To build the Docker image locally:

```bash
docker build -t genieacs:dev .
```

For a multi-architecture build:

```bash
docker buildx build --platform linux/amd64,linux/arm64 -t genieacs:dev .
```

A multi-platform build is not loaded into the local image store; it stays in the BuildKit cache unless you
add `--push` with a tag in your own registry.

Releases are not built by hand. When `Dockerfile`, `entrypoint.sh` or `config/` change on `main`, the
`CI, Release & Docker Publish` workflow builds amd64 and arm64, pushes `drumsergio/genieacs:<version>`
(the upstream version plus a build number, for example `1.2.16.6`) and creates the GitHub release. A
manual run (`workflow_dispatch`) can set `version_override`, which replaces that version.

## Contributing

Pull requests are welcome. Fork, branch, change, open a PR against `main`; CI builds and smoke-tests the
image on every PR; a chart change is released when it lands on `main`. Bugs go to the
[issue tracker](https://github.com/GeiserX/genieacs-container/issues); security problems follow the
[security policy](https://github.com/GeiserX/genieacs-container/blob/main/SECURITY.md).
