# Troubleshooting

## Check Container Logs

```bash
docker compose logs genieacs
```

That shows supervisord only. Each service's errors are in its own file under `/var/log/genieacs/`; see
[Usage](usage.md#logs).

## Verify MongoDB Connection

```bash
docker compose exec genieacs ping mongo
```

## Access Container Shell

```bash
docker compose exec genieacs /bin/bash
```

## Reporting a bug

Open an issue at https://github.com/GeiserX/genieacs-container/issues with:

- the image tag, for example `drumsergio/genieacs:1.2.16.6`, and the chart version if you use Helm
- how you run it: Compose, `docker run` or Helm, and on which architecture
- the service logs: `docker compose exec genieacs tail -n 100 /var/log/genieacs/genieacs-cwmp.log` and the
  same for `nbi`, `fs` and `ui`, or `kubectl exec` into the pod for the same files
- your MongoDB connection string with the credentials removed
