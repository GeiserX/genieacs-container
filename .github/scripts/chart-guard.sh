#!/usr/bin/env bash
# Proves the chart's GENIEACS_UI_JWT_SECRET guard both ways: every unsafe input
# must stop the render with the expected message, every supported input must
# render and pass kubeconform. Run from the repo root after
# `helm dependency build charts/genieacs`. Needs helm and kubeconform on PATH.
set -uo pipefail

CHART=charts/genieacs
OUT=$(mktemp -d)
trap 'rm -rf "$OUT"' EXIT
SECRET=$(openssl rand -hex 32)
fails=0

# expect_fail <case> <message fragment> <helm template args...>
expect_fail() {
  local name=$1 want=$2; shift 2
  if helm template t "$CHART" "$@" >"$OUT/$name.yaml" 2>"$OUT/$name.err"; then
    echo "FAIL  $name: rendered, but it must be refused"
    fails=$((fails + 1))
  elif ! grep -q -- "$want" "$OUT/$name.err"; then
    echo "FAIL  $name: refused, but without \"$want\":"
    sed 's/^/      /' "$OUT/$name.err"
    fails=$((fails + 1))
  else
    echo "ok    $name: refused"
  fi
}

# expect_pass <case> <string the manifest must contain> <helm template args...>
expect_pass() {
  local name=$1 want=$2; shift 2
  if ! helm template t "$CHART" "$@" >"$OUT/$name.yaml" 2>"$OUT/$name.err"; then
    echo "FAIL  $name: refused, but it must render:"
    sed 's/^/      /' "$OUT/$name.err"
    fails=$((fails + 1))
  elif ! grep -q -- "$want" "$OUT/$name.yaml"; then
    echo "FAIL  $name: rendered without \"$want\""
    fails=$((fails + 1))
  elif ! kubeconform -strict -summary "$OUT/$name.yaml" >"$OUT/$name.kc" 2>&1; then
    echo "FAIL  $name: kubeconform rejected the manifests:"
    sed 's/^/      /' "$OUT/$name.kc"
    fails=$((fails + 1))
  else
    echo "ok    $name: rendered, $(tail -n 1 "$OUT/$name.kc")"
  fi
}

# Unsafe inputs. The schema refuses some of them before the template runs, so
# the shared fragment is the variable name.
expect_fail defaults          "GENIEACS_UI_JWT_SECRET is not set"
expect_fail changeme          "GENIEACS_UI_JWT_SECRET" --set env.GENIEACS_UI_JWT_SECRET=changeme
expect_fail changeme-mixed    "placeholder"            --set env.GENIEACS_UI_JWT_SECRET=ChangeMe
expect_fail empty             "GENIEACS_UI_JWT_SECRET" --set env.GENIEACS_UI_JWT_SECRET=
expect_fail docs-placeholder  "GENIEACS_UI_JWT_SECRET" --set env.GENIEACS_UI_JWT_SECRET=your-secret-here
expect_fail extra-placeholder "placeholder" \
  --set 'extraEnvVars[0].name=GENIEACS_UI_JWT_SECRET' --set 'extraEnvVars[0].value=changeme'
expect_fail set-twice         "more than one place" \
  --set env.GENIEACS_UI_JWT_SECRET="$SECRET" --set uiJwtSecret.existingSecret=genieacs-ui-jwt
expect_fail bad-secret-name   "existingSecret" --set uiJwtSecret.existingSecret=Not_A_Name

# Supported inputs.
expect_pass value          "$SECRET" --set env.GENIEACS_UI_JWT_SECRET="$SECRET"
expect_pass existingSecret "name: \"genieacs-ui-jwt\"" --set uiJwtSecret.existingSecret=genieacs-ui-jwt
expect_pass extraEnvVars   "name: jwt-from-elsewhere" \
  --set 'extraEnvVars[0].name=GENIEACS_UI_JWT_SECRET' \
  --set 'extraEnvVars[0].valueFrom.secretKeyRef.name=jwt-from-elsewhere' \
  --set 'extraEnvVars[0].valueFrom.secretKeyRef.key=jwt'
expect_pass external-mongo "secretKeyRef" --set uiJwtSecret.existingSecret=genieacs-ui-jwt \
  --set mongodb.enabled=false --set externalMongodb.existingSecret=genieacs-mongodb

if ! grep -q "secretKeyRef" "$OUT/existingSecret.yaml" || grep -q "$SECRET" "$OUT/existingSecret.yaml"; then
  echo "FAIL  existingSecret: the value must come from the Secret, not the manifest"
  fails=$((fails + 1))
fi

# The image the chart deploys is the appVersion it advertises, never a moving tag.
app=$(sed -n 's/^appVersion: *"\{0,1\}\([^"]*\)"\{0,1\} *$/\1/p' "$CHART/Chart.yaml")
img=$(sed -n 's/^ *image: "drumsergio\/genieacs:\([^"]*\)"$/\1/p' "$OUT/value.yaml")
if [ -z "$app" ] || [ "$img" != "$app" ] || [ "$app" = latest ]; then
  echo "FAIL  image: the chart deploys drumsergio/genieacs:${img:-?} but appVersion is ${app:-unset}"
  fails=$((fails + 1))
else
  echo "ok    image: drumsergio/genieacs:$img matches appVersion"
fi

echo
if [ "$fails" -ne 0 ]; then
  echo "$fails case(s) failed"
  exit 1
fi
echo "all cases passed"
