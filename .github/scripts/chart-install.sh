#!/bin/sh
# Installs the chart into the current kube context the recommended way (the UI
# JWT secret in a Secret), waits for GenieACS and MongoDB, checks the secret
# reached the container and the UI answers, then proves an upgrade that drops
# the secret is refused before it touches the release. Extra arguments go to
# `helm install`. Needs helm, kubectl, curl and openssl.
set -eu

NS=${NS:-genieacs-ci}
REL=${REL:-genieacs}
CHART=charts/genieacs
SECRET=$(openssl rand -hex 32)

dump() {
  echo "::group::cluster state"
  kubectl --namespace "$NS" get all,pvc,secret || true
  kubectl --namespace "$NS" describe pods || true
  kubectl --namespace "$NS" logs --all-containers --prefix --selector app.kubernetes.io/instance="$REL" --tail=200 || true
  echo "::endgroup::"
}
pf=
cleanup() {
  rc=$?
  [ -n "$pf" ] && kill "$pf" 2>/dev/null
  [ "$rc" -ne 0 ] && dump
  rm -f upgrade.err
  exit "$rc"
}
trap cleanup EXIT

kubectl create namespace "$NS"
kubectl --namespace "$NS" create secret generic "$REL-ui-jwt" \
  --from-literal=GENIEACS_UI_JWT_SECRET="$SECRET"

helm install "$REL" "$CHART" --namespace "$NS" \
  --set uiJwtSecret.existingSecret="$REL-ui-jwt" \
  --wait --timeout 10m "$@"

kubectl --namespace "$NS" rollout status "deployment/$REL" --timeout 5m
kubectl --namespace "$NS" wait pod --for=condition=Ready --all --timeout 5m

# The container must hold the Secret's value, not a default.
got=$(kubectl --namespace "$NS" exec "deployment/$REL" -- printenv GENIEACS_UI_JWT_SECRET)
if [ "$got" != "$SECRET" ]; then
  echo "GENIEACS_UI_JWT_SECRET in the container does not match the Secret"
  exit 1
fi
echo "ok    the container holds the Secret's GENIEACS_UI_JWT_SECRET"

# The UI answers through its Service.
kubectl --namespace "$NS" port-forward "svc/$REL-http" 13000:3000 >/dev/null 2>&1 &
pf=$!
for i in $(seq 1 30); do
  if code=$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:13000/) && [ "$code" = 200 ]; then
    break
  fi
  if [ "$i" -eq 30 ]; then
    echo "UI did not answer 200 (last: ${code:-none})"
    exit 1
  fi
  sleep 2
done
echo "ok    the UI answers 200 on /"

helm test "$REL" --namespace "$NS" --timeout 3m
echo "ok    helm test passed"

# An upgrade that drops the secret must stop before the cluster changes.
before=$(helm history "$REL" --namespace "$NS" --max 1 -o json | jq '.[0].revision')
case $before in
  '' | *[!0-9]*) echo "could not read the release revision (got '$before')"; exit 1 ;;
esac
if helm upgrade "$REL" "$CHART" --namespace "$NS" --reuse-values \
    --set uiJwtSecret.existingSecret= "$@" 2>upgrade.err; then
  echo "an upgrade without GENIEACS_UI_JWT_SECRET was accepted"
  exit 1
fi
grep -q "GENIEACS_UI_JWT_SECRET is not set" upgrade.err
after=$(helm history "$REL" --namespace "$NS" --max 1 -o json | jq '.[0].revision')
rm -f upgrade.err
if [ "$before" != "$after" ]; then
  echo "the refused upgrade still created revision $after"
  exit 1
fi
echo "ok    an upgrade without the secret is refused and the release stays at revision $before"
