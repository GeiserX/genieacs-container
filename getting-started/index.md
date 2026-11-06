# Getting started

Three ways to run it: Docker Compose (GenieACS plus MongoDB on one host), `docker run` against a MongoDB you already have, or the Helm chart on Kubernetes. The image is `drumsergio/genieacs` on Docker Hub, for amd64 and arm64.

## Docker Compose

The repository's `docker-compose.yml` runs GenieACS and MongoDB together. Fetch it and start the stack:

```
curl -fsSLO https://raw.githubusercontent.com/GeiserX/genieacs-container/main/docker-compose.yml
echo "GENIEACS_UI_JWT_SECRET=$(openssl rand -hex 32)" >> .env
docker compose up -d
```

This starts GenieACS (ports 7547, 7557, 7567 and 3000) and MongoDB (port 27017, inside the Compose network only). GenieACS waits for MongoDB to report healthy, so the UI takes about 30 seconds to come up. What working looks like: http://localhost:3000 opens the GenieACS UI, and `docker compose ps` shows `genieacs` as `healthy`. The first visit shows the initialization wizard; accept its defaults, log in as `admin` / `admin` and change the password. Then [point a device at it](<https://geiserx.github.io/genieacs-container/first-device/index.md>).

The `echo` line writes a random `GENIEACS_UI_JWT_SECRET`, which signs the UI login tokens, to `.env`. The compose file has no default for it: without one, `docker compose up` stops with `required variable GENIEACS_UI_JWT_SECRET is missing a value`. Before you expose it, turn on MongoDB authentication; the commented lines in the file show how.

```
# View logs
docker compose logs -f genieacs

# Stop all services
docker compose down

# Stop and remove volumes
docker compose down -v
```

Two optional services sit behind profiles:

- `genieacs-sim`: a simulated CPE for testing, `docker compose --profile testing up -d`
- `genieacs-mcp`: the MCP server, `docker compose --profile mcp up -d`

### Upgrading from `mongo:8.0`

Until November 2026 the compose file ran `mongo:8.0`. MongoDB from 8.0 on crashes on Linux kernels 6.19 through 7.0.13, so it stops at startup on them ([SERVER-121912](<https://jira.mongodb.org/browse/SERVER-121912>)). The 8.0 and 8.3 releases out today (8.0.34, 8.3.13) also stop on kernels that already carry the fix but still report `7.0.0`, such as Ubuntu's ([SERVER-136848](<https://jira.mongodb.org/browse/SERVER-136848>)); 9.0.4 recognizes those and starts. So the compose file now runs `mongo:9.0.4`. A kernel that really is between 6.19 and 7.0.13 has to be upgraded to 7.0.14 or newer: no MongoDB from 8.0 on runs there.

MongoDB supports going from 8.0 straight to 9.0, and your existing volume keeps working. Going back to 7.0 does not: it refuses data written by 8.0. With MongoDB authentication on, add `-u root -p <password> --authenticationDatabase admin` to the `mongodump` and `mongosh` commands below.

1. If `mongo:8.0` still starts on your host, back up and check the data's feature compatibility version (FCV):

```
docker compose exec -T mongo mongodump --archive --db genieacs > genieacs-backup.archive
docker compose exec mongo mongosh --quiet --eval \
  'db.adminCommand({getParameter: 1, featureCompatibilityVersion: 1})'
```

It must say `8.0`. If it says `7.0` (a volume first created by `mongo:7.0`), raise it first: `db.adminCommand({setFeatureCompatibilityVersion: "8.0", confirm: true})`. 2. Change the `mongo` image to `mongo:9.0.4` (or fetch the new `docker-compose.yml`), then `docker compose up -d`. MongoDB 9.0 opens the data at FCV 8.0. Check that the console shows your devices and that they still inform before the next step. 3. Finish the upgrade. After this step, going back to `mongo:8.0` needs the backup.

```
docker compose exec mongo mongosh --quiet --eval \
  'db.adminCommand({setFeatureCompatibilityVersion: "9.0", confirm: true})'
```

If `mongo:9.0.4` exits with `Wrong mongod version`, the data is still at FCV 7.0. Start that volume once with `mongo:8.0` on a host whose kernel is older than 6.19 or 7.0.14 or newer, run step 1, then switch.

## Docker run

With a MongoDB you already run:

```
docker run -d \
  --name genieacs \
  -p 7547:7547 \
  -p 7557:7557 \
  -p 7567:7567 \
  -p 3000:3000 \
  -e GENIEACS_MONGODB_CONNECTION_URL=mongodb://your-mongo-host/genieacs \
  -e GENIEACS_UI_JWT_SECRET="$(openssl rand -hex 32)" \
  drumsergio/genieacs:1.2.16.6
```

## Kubernetes with Helm

### Install from the chart repository

Add the chart repository:

```
helm repo add genieacs https://geiserx.github.io/genieacs-container
helm repo update
```

Install GenieACS:

```
helm install genieacs genieacs/genieacs \
  --namespace genieacs \
  --create-namespace \
  --set env.GENIEACS_UI_JWT_SECRET=$(openssl rand -hex 32)
```

The chart has no default `GENIEACS_UI_JWT_SECRET`: without one, `helm install` and `helm upgrade` stop before touching the cluster with `GENIEACS_UI_JWT_SECRET is not set` and the commands to make one. The `--set` line above passes a random one. To keep it out of values files and the Deployment spec, put it in a Secret and name that Secret instead:

```
kubectl create namespace genieacs
kubectl create secret generic genieacs-ui-jwt --namespace genieacs \
  --from-literal=GENIEACS_UI_JWT_SECRET="$(openssl rand -hex 32)"

helm install genieacs genieacs/genieacs \
  --namespace genieacs \
  --set uiJwtSecret.existingSecret=genieacs-ui-jwt
```

What working looks like: `kubectl -n genieacs get pods` shows a `genieacs-...` pod and a `genieacs-mongodb-...` pod, both `Running` and `1/1` within about two minutes (the readiness probe waits 30 s). Port-forward the console with `kubectl -n genieacs port-forward svc/genieacs-http 3000:3000` (the chart's notes print the same command with local port 8080), then open http://localhost:3000 and run the wizard. Devices reach the ACS through the `genieacs-cwmp` Service; expose it with a LoadBalancer or a TCP route before a real CPE can inform.

This deploys GenieACS with a MongoDB instance included by default (no auth). For production with MongoDB auth:

```
helm install genieacs genieacs/genieacs \
  --namespace genieacs \
  --create-namespace \
  --set mongodb.auth.enabled=true \
  --set mongodb.auth.rootPassword=$(openssl rand -base64 24) \
  --set env.GENIEACS_UI_JWT_SECRET=$(openssl rand -hex 32)
```

To use an external MongoDB (connection string inline):

```
helm install genieacs genieacs/genieacs \
  --namespace genieacs \
  --create-namespace \
  --set mongodb.enabled=false \
  --set externalMongodb.url=mongodb://your-mongo-host/genieacs \
  --set env.GENIEACS_UI_JWT_SECRET=$(openssl rand -hex 32)
```

To use an external MongoDB with the connection string sourced from a Kubernetes Secret (recommended for production: keeps credentials out of values files and out of the pod spec):

```
kubectl create namespace genieacs
kubectl create secret generic genieacs-mongodb \
  --namespace genieacs \
  --from-literal=connectionString="mongodb+srv://user:pass@cluster.example.net/genieacs?retryWrites=true"
kubectl create secret generic genieacs-ui-jwt \
  --namespace genieacs \
  --from-literal=GENIEACS_UI_JWT_SECRET="$(openssl rand -hex 32)"

helm install genieacs genieacs/genieacs \
  --namespace genieacs \
  --set mongodb.enabled=false \
  --set externalMongodb.existingSecret=genieacs-mongodb \
  --set uiJwtSecret.existingSecret=genieacs-ui-jwt
```

This pattern integrates with External Secrets Operator, Sealed Secrets, Vault, and operators that write connection details to a Kubernetes Secret (MongoDB Atlas Operator, MongoDB Controllers for Kubernetes (MCK), the Percona Operator).

> **Production note:** The bundled Bitnami MongoDB subchart is intended for development and evaluation only. For production deployments, run MongoDB separately — managed (MongoDB Atlas), operator-managed ([MCK](<https://github.com/mongodb/mongodb-kubernetes>), [Percona Operator for MongoDB](<https://github.com/percona/percona-server-mongodb-operator>)), or self-hosted — and point the chart at it using `externalMongodb.existingSecret`.

### Helmfile

See the [examples directory](<https://github.com/GeiserX/genieacs-container/tree/main/examples>) for a complete Helmfile deployment example:

```
helmfile -f examples/helmfile.yaml apply
```

### Chart values

The chart values that matter are on [Configuration](<https://geiserx.github.io/genieacs-container/configuration/#helm-chart-values>); the full file is [values.yaml](<https://github.com/GeiserX/genieacs-container/blob/main/charts/genieacs/values.yaml>).
