# Troubleshooting

## The console does not open

Port 3000 answers nothing for the first 30 to 60 seconds while GenieACS waits for MongoDB;
`docker compose ps` shows `genieacs` as `starting`, then `healthy`. If it stays unhealthy,
`docker compose logs genieacs` shows supervisord, and
`docker compose exec genieacs tail -n 50 /var/log/genieacs/genieacs-ui.log` shows the reason, most often
the MongoDB URL. Each service's errors are in its own file under `/var/log/genieacs/`; see
[Usage](usage.md#logs).

## A device never appears

The ACS URL must reach port 7547 of the host, not `localhost` on the device. Check with
`curl -i http://<host>:7547/` from the device's network: GenieACS answers `405 Method Not Allowed` to a
bare GET, which is the right answer. Then run
`docker compose exec genieacs tail -f /var/log/genieacs/genieacs-cwmp-access.log` while the device
reboots. No line means the inform never arrived (network, ACS URL, a firewall); a line means the device is
in MongoDB and the console's filter or a fault is hiding it.

## MongoDB connection

`docker compose exec genieacs ping -c 1 mongo` checks the network, then `genieacs-cwmp.log` shows any
`MongoServerError`. With authentication on, the URL must carry `?authSource=admin`.

## MongoDB exits at startup

`docker compose logs mongo` saying `Linux kernel versions 6.19 and newer has a known incompatibility`
means the compose file still runs `mongo:8.0` on a kernel between 6.19 and 7.0.13. Move to `mongo:9.0.4`
as described in [Upgrading from `mongo:8.0`](getting-started.md#upgrading-from-mongo80).
`Wrong mongod version` means the data's feature compatibility version is too old for that MongoDB; the
same section shows how to raise it.

## A shell in the container

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
