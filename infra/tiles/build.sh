#!/bin/sh
# Prepara infra/data/tiles: extracto PMTiles de las ciudades piloto, estilo, fuentes y sprites.
# Uso (desde infra/): TILES_BASE_URL=http://192.168.1.66:8081 sh tiles/build.sh [AAAAMMDD]
set -eu

BUILD="${1:-$(date -u -d '1 day ago' +%Y%m%d)}"
BASE="${TILES_BASE_URL:?Falta TILES_BASE_URL, p. ej. http://192.168.1.66:8081}"
PMTILES_IMAGE=protomaps/go-pmtiles:v1.31.2
NODE_IMAGE=node:22-alpine
BASEMAPS_VERSION=5.7.2
ASSETS_COMMIT=028c18f713baecad011301ff7a69acc39bcc2ae7

HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="$(cd "$HERE/.." && pwd)/data/tiles"
mkdir -p "$OUT"
USER_ID="$(id -u):$(id -g)"

# 1. Extracto de las regiones (regions.geojson) desde el build diario de Protomaps, zoom máx. 15.
docker run --rm -u "$USER_ID" -v "$OUT:/data" -v "$HERE/regions.geojson:/regions.geojson:ro" "$PMTILES_IMAGE" \
  extract "https://build.protomaps.com/$BUILD.pmtiles" /data/city.pmtiles.tmp --region=/regions.geojson --maxzoom=15
mv "$OUT/city.pmtiles.tmp" "$OUT/city.pmtiles"

# 2. Fuentes (OFL) y sprites del tema claro desde protomaps/basemaps-assets, versión fijada.
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
curl -fsSL "https://codeload.github.com/protomaps/basemaps-assets/tar.gz/$ASSETS_COMMIT" | tar -xz -C "$TMP"
SRC="$TMP/basemaps-assets-$ASSETS_COMMIT"
rm -rf "$OUT/fonts" "$OUT/sprites"
mkdir -p "$OUT/fonts" "$OUT/sprites/v4"
for f in "Noto Sans Regular" "Noto Sans Medium" "Noto Sans Italic"; do cp -r "$SRC/fonts/$f" "$OUT/fonts/"; done
cp "$SRC"/sprites/v4/light* "$OUT/sprites/v4/"
cp "$SRC/LICENSE"* "$OUT/" 2>/dev/null || true
[ -f "$SRC/fonts/OFL.txt" ] && cp "$SRC/fonts/OFL.txt" "$OUT/fonts/"

# 3. Estilo MapLibre generado con @protomaps/basemaps (tema claro, español).
docker run --rm -u "$USER_ID" -e TILES_BASE_URL="$BASE" -e HOME=/tmp -v "$HERE/style.mjs:/app/style.mjs:ro" -w /tmp "$NODE_IMAGE" \
  sh -c "npm install --silent --no-save @protomaps/basemaps@$BASEMAPS_VERSION >/dev/null && cp /app/style.mjs . && node style.mjs" \
  > "$OUT/style.json.tmp"
mv "$OUT/style.json.tmp" "$OUT/style.json"

ls -la "$OUT"
