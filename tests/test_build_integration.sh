#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

fail() { echo "FAIL: $1" >&2; exit 1; }

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/repo"

cat >"$tmp/bin/docker" <<'EOF'
#!/bin/bash
printf '%s\n' "$@" >>"$MOCK_LOG"
ctx="${!#}"
if [ -f "$ctx/tmp/services" ]; then
  printf 'SERVICES_CONTENT\n' >>"$MOCK_LOG"
  cat "$ctx/tmp/services" >>"$MOCK_LOG"
fi
if [ -f "$ctx/tmp/bundled_scripts.sh" ]; then
  printf 'USER_BUNDLE\n' >>"$MOCK_LOG"
  cat "$ctx/tmp/bundled_scripts.sh" >>"$MOCK_LOG"
fi
if [ -f "$ctx/tmp/bundled_root_scripts.sh" ]; then
  printf 'ROOT_BUNDLE\n' >>"$MOCK_LOG"
  cat "$ctx/tmp/bundled_root_scripts.sh" >>"$MOCK_LOG"
fi
exit 0
EOF
chmod +x "$tmp/bin/docker"

# Committed tree, with the working-tree files under test overlaid
git archive HEAD | tar -x -C "$tmp/repo"
cp build.sh "$tmp/repo/build.sh"
cp Dockerfile "$tmp/repo/Dockerfile"
mkdir -p "$tmp/repo/tmp"

cat >"$tmp/repo/cfg/env" <<'EOF'
USER_NAME=tester
USER_ID=1000
USER_GROUP=1000
MISE_DATA_DIR=/mise
MISE_CONFIG_DIR=/mise
MISE_CACHE_DIR=/mise/cache
MISE_INSTALL_PATH=/usr/local/bin/mise
IMAGE_NAME=test_img
EOF
echo "GLOBAL_ONLY=1" >"$tmp/repo/cfg/services.cfg"

export MOCK_LOG="$tmp/mock.log"

out=$(cd "$tmp/repo" && PATH="$tmp/bin:$PATH" bash build.sh 2>&1) ||
  fail "global-only build failed: $out"
grep -q "Using services from .*cfg/services.cfg" <<<"$out" ||
  fail "expected global services message, got: $out"
grep -q '^GLOBAL_ONLY=1$' "$MOCK_LOG" || fail "global services not baked into build context"
grep -q '^\. \./env$' "$MOCK_LOG" || fail "bundles must source env"
grep -q '^\. \./services$' "$MOCK_LOG" || fail "bundles must source services"
grep -Fqx 'COPY tmp/env tmp/services tmp/bundled_root_scripts.sh .' "$tmp/repo/Dockerfile" ||
  fail "root Dockerfile COPY must include tmp/services"
grep -Fqx 'COPY --chown=${USER_NAME} tmp/env tmp/services tmp/bundled_scripts.sh .' "$tmp/repo/Dockerfile" ||
  fail "user Dockerfile COPY must include tmp/services"
grep -Fq 'rm -f env services bundled_root_scripts.sh' "$tmp/repo/Dockerfile" ||
  fail "root Dockerfile must delete services after use"
grep -Fq 'rm -f env services bundled_scripts.sh' "$tmp/repo/Dockerfile" ||
  fail "user Dockerfile must delete services after use"
grep -Fq 'RUN mkdir -p $HOME/.local/bin' "$tmp/repo/Dockerfile" ||
  fail "Dockerfile must create ~/.local/bin"
grep -Fq 'PATH=\$PATH:$HOME/.local/bin' "$tmp/repo/Dockerfile" ||
  fail "Dockerfile must add ~/.local/bin to PATH"

mkdir -p "$tmp/repo/profiles/bp"
echo "PROFILE_ONLY=1" >"$tmp/repo/profiles/bp/services.cfg"
: >"$MOCK_LOG"
out=$(cd "$tmp/repo" && PATH="$tmp/bin:$PATH" bash build.sh --profile bp 2>&1) ||
  fail "profile build failed: $out"
grep -q "Using services from .*profiles/bp/services.cfg" <<<"$out" ||
  fail "expected profile services message, got: $out"
grep -q '^PROFILE_ONLY=1$' "$MOCK_LOG" || fail "profile services not baked into build context"
grep -q '^GLOBAL_ONLY' "$MOCK_LOG" && fail "global services leaked into profile build"
grep -qx -- '--build-arg' "$MOCK_LOG" || fail "build args missing"
grep -qx 'USER_NAME=tester' "$MOCK_LOG" || fail "USER_NAME build arg missing"

# No services file anywhere: hard error, no docker build.
mkdir -p "$tmp/repo/profiles/bp2"
rm "$tmp/repo/cfg/services.cfg"
: >"$MOCK_LOG"
out=$(cd "$tmp/repo" && PATH="$tmp/bin:$PATH" bash build.sh --profile bp2 2>&1) &&
  fail "build.sh must fail when no services.cfg exists"
grep -q 'services.cfg not found' <<<"$out" || fail "missing-file error hint absent: $out"
grep -q 'cfg/services.cfg.sample' <<<"$out" || fail "error must name the sample file"
[ ! -s "$MOCK_LOG" ] || fail "docker build must not run when services.cfg is missing"

echo "test_build_integration: all passed"
