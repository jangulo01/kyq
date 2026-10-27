// Genera el estilo MapLibre del mapa base de Protomaps (tema claro, etiquetas en español).
// Uso: TILES_BASE_URL=http://host:8081 node style.mjs > style.json
import { layers, namedFlavor } from "@protomaps/basemaps";

const base = process.env.TILES_BASE_URL;
if (!base) throw new Error("Falta TILES_BASE_URL");

const style = {
  version: 8,
  name: "kyq-light",
  glyphs: `${base}/fonts/{fontstack}/{range}.pbf`,
  sprite: `${base}/sprites/v4/light`,
  sources: {
    protomaps: {
      type: "vector",
      url: `pmtiles://${base}/city.pmtiles`,
      attribution:
        '<a href="https://protomaps.com">Protomaps</a> © <a href="https://openstreetmap.org/copyright">OpenStreetMap</a>',
    },
  },
  layers: layers("protomaps", namedFlavor("light"), { lang: "es" }),
};

process.stdout.write(JSON.stringify(style));
