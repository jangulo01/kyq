"""Mide SC-002 y SC-004 contra un entorno Kyq (quickstart.md, "Medición").

- SC-004: desde que el pasajero envía POST /v1/trips hasta que el conductor recibe trip.offer.
- SC-002: desde que cambia el estado del conductor (solicitud que lo ocupa / rechazo que lo
  libera) hasta que el pasajero recibe driver.presence.

Usa cuentas de prueba con el OTP de desarrollo. El conductor debe estar ONLINE y libre, y el
pasajero tenerlo como conductor elegido. Cada muestra crea una oferta y el script la rechaza.

    KYQ_DEV_OTP_CODE=... python infra/measure/latency.py --api http://192.168.1.66:8080 \
        --ws ws://192.168.1.66:8000/connection/websocket --driver +573100000001 \
        --passenger +573200000002 --samples 20
"""

import argparse
import asyncio
import json
import os
import statistics
import time

import requests
import websockets


def login(api, phone, code):
    requests.post(f"{api}/v1/auth/otp/request", json={"phone_e164": phone}, timeout=10).raise_for_status()
    r = requests.post(f"{api}/v1/auth/otp/verify", json={"phone_e164": phone, "code": code}, timeout=10)
    r.raise_for_status()
    return r.json()["access_token"]


def post(api, path, token, body=None):
    r = requests.post(f"{api}{path}", json=body or {}, headers={"Authorization": f"Bearer {token}"}, timeout=10)
    r.raise_for_status()
    return r.json() if r.content else None


class Listener:
    """Cliente mínimo del protocolo JSON de Centrifugo: guarda (hora de llegada, evento)."""

    def __init__(self, api, ws_url, token, channels):
        self.api, self.ws_url, self.token, self.channels = api, ws_url, token, channels
        self.events = asyncio.Queue()

    async def run(self, ready):
        async with websockets.connect(self.ws_url) as ws:
            rt = post(self.api, "/v1/realtime/token", self.token)["token"]
            await ws.send(json.dumps({"id": 1, "connect": {"token": rt, "name": "kyq-measure"}}))
            for i, ch in enumerate(self.channels, start=2):
                sub = post(self.api, "/v1/realtime/subscription-token", self.token, {"channel": ch})["token"]
                await ws.send(json.dumps({"id": i, "subscribe": {"channel": ch, "token": sub}}))
            ready.set()
            async for frame in ws:
                now = time.perf_counter()
                for line in frame.splitlines():
                    msg = json.loads(line) if line.strip() else {}
                    if not msg:
                        await ws.send("{}")  # ping del servidor
                        continue
                    pub = msg.get("push", {}).get("pub")
                    if pub:
                        await self.events.put((now, pub["data"]))

    async def wait_for(self, predicate, timeout=10):
        deadline = time.perf_counter() + timeout
        while True:
            left = deadline - time.perf_counter()
            if left <= 0:
                return None
            try:
                at, ev = await asyncio.wait_for(self.events.get(), left)
            except asyncio.TimeoutError:
                return None
            if predicate(ev):
                return at


def p95(xs):
    xs = sorted(xs)
    return xs[max(0, round(0.95 * len(xs)) - 1)]


async def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--api", required=True)
    ap.add_argument("--ws", required=True)
    ap.add_argument("--driver", required=True)
    ap.add_argument("--passenger", required=True)
    ap.add_argument("--samples", type=int, default=20)
    a = ap.parse_args()
    code = os.environ["KYQ_DEV_OTP_CODE"]

    drv_tok, pax_tok = login(a.api, a.driver, code), login(a.api, a.passenger, code)
    driver_id = requests.get(f"{a.api}/v1/driver/me", headers={"Authorization": f"Bearer {drv_tok}"}, timeout=10).json()[
        "driver_id"
    ]
    me = requests.get(f"{a.api}/v1/trips/active", headers={"Authorization": f"Bearer {drv_tok}"}, timeout=10)
    if me.status_code == 200:
        raise SystemExit("el conductor tiene un viaje activo; termínalo antes de medir")

    drv = Listener(a.api, a.ws, drv_tok, [f"user:{driver_id}"])
    pax = Listener(a.api, a.ws, pax_tok, [f"driver_presence:{driver_id}"])
    ready_d, ready_p = asyncio.Event(), asyncio.Event()
    tasks = [asyncio.create_task(drv.run(ready_d)), asyncio.create_task(pax.run(ready_p))]
    await ready_d.wait()
    await ready_p.wait()
    await asyncio.sleep(1)

    route = {"pickup": {"lat": 3.41387, "lng": -76.52749}, "dropoff": {"lat": 3.41070, "lng": -76.52685}}
    offer_ms, busy_ms, free_ms = [], [], []
    for i in range(a.samples):
        t0 = time.perf_counter()
        trip = post(a.api, "/v1/trips", pax_tok, {"driver_id": driver_id, **route})
        got_offer = await drv.wait_for(lambda e: e.get("type") == "trip.offer")
        got_busy = await pax.wait_for(lambda e: e.get("type") == "driver.presence" and e["data"]["presence"] == "busy")
        t1 = time.perf_counter()
        post(a.api, f"/v1/trips/{trip['id']}/reject", drv_tok)
        got_free = await pax.wait_for(lambda e: e.get("type") == "driver.presence" and e["data"]["presence"] == "free")
        for xs, at, start in ((offer_ms, got_offer, t0), (busy_ms, got_busy, t0), (free_ms, got_free, t1)):
            if at is not None:
                xs.append((at - start) * 1000)
        print(f"muestra {i + 1}: oferta {offer_ms[-1]:.0f} ms, ocupado {busy_ms[-1]:.0f} ms, libre {free_ms[-1]:.0f} ms")
        await asyncio.sleep(0.5)

    for t in tasks:
        t.cancel()
    for name, xs, limit in (("SC-004 oferta", offer_ms, 3000), ("SC-002 ocupado", busy_ms, 5000), ("SC-002 libre", free_ms, 5000)):
        print(
            f"{name}: n={len(xs)}/{a.samples} mediana {statistics.median(xs):.0f} ms, p95 {p95(xs):.0f} ms, "
            f"máx {max(xs):.0f} ms -> {'CUMPLE' if len(xs) == a.samples and p95(xs) < limit else 'NO CUMPLE'} (< {limit} ms)"
        )


if __name__ == "__main__":
    asyncio.run(main())
