# Troubleshooting

## Check Container Logs

```bash
docker compose logs genieacs
```

## Verify MongoDB Connection

```bash
docker compose exec genieacs ping mongo
```

## Access Container Shell

```bash
docker compose exec genieacs /bin/bash
```
