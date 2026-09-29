# Development

## Building the image

To build the Docker image locally:

```bash
docker build -t drumsergio/genieacs:1.2.16.0 .
```

For multi-architecture builds:

```bash
docker buildx build --platform linux/amd64,linux/arm64 \
  -t drumsergio/genieacs:1.2.16.0 \
  -t drumsergio/genieacs:latest \
  --push .
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

GenieACS-Container follows the [Contributor Covenant](http://contributor-covenant.org/version/2/1/) Code of Conduct.

## Maintainers

[@GeiserX](https://github.com/GeiserX)
