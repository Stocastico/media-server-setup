# Shopping list and costs

Prices below are for Spain, September 2026, VAT included, and move fast —
SSD/RAM prices were rising sharply through 2025–26 due to a NAND/DRAM
shortage. Always check current prices on idealo.es before buying; treat the
numbers here as a starting budget, not a quote.

## What to buy

| Item | Needed? | Est. price | Notes |
|---|---|---|---|
| Mini PC: Intel N150 or N100, 16 GB RAM, ≥500 GB NVMe | Yes | €175–250 | Must be 12th-gen+ Intel N-series (Alder Lake-N or newer). Avoid older Celeron J/N (11th gen or earlier) — no modern Quick Sync. Prefer a model with 2.5 GbE. Examples: Beelink Mini S13, GMKtec G3-class, Blackview MP60. |
| 2× 2 TB portable USB SSD (bus-powered) | Yes | €440–560 | E.g. Samsung T7, Crucial X9. USB 3.2 Gen 2 (10 Gbps). One is the live library, one is the nightly backup. |
| *Alternative:* 2× 2 TB portable USB HDD | Instead of SSDs, to save money | €200–220 | Slower, faintly audible, roughly half the price. Fine for a mostly-read media library. |
| Cat 6 Ethernet cable | Yes | €5–10 | Wi-Fi and powerline are explicitly **not** recommended for the server — use wired Ethernet. |
| TV streaming box (Google TV Streamer / Apple TV 4K / Nvidia Shield) | Only if your TV's built-in browser/app is poor | ~€90–120 | See [12-tv-and-device-clients.md](12-tv-and-device-clients.md). |
| Small UPS (with USB data port) | Optional | €85–110 | Protects disks and the Postgres/SQLite databases from power cuts; lets the server shut down cleanly. |
| Software | — | €0 | Debian, Jellyfin, Immich, qBittorrent are all free/open source. Optional paid extras: Infuse Pro (Apple TV client), a commercial VPN if you want qBittorrent behind one. |

## Estimated builds

| Build | Includes | Total |
|---|---|---|
| Budget | Mini PC + 2× 2 TB portable HDD + cable | ≈ €380–480 |
| Recommended | Mini PC + 2× 2 TB portable SSD + cable | ≈ €620–820 |
| Recommended, complete | + TV box + UPS | ≈ €800–1,050 |

Running cost: roughly 10–15 W average for the mini PC + two SSDs, ≈ 90–130
kWh/year, a few tens of euros a year at typical residential electricity
rates.

## Saving money

- 2.5" portable **hard drives** cost roughly half as much per TB as portable
  SSDs and are fine for a media library, which is mostly sequential reads.
- A **used** N100/N150 mini PC works just as well as new.
- An internal NVMe in the mini PC's second M.2 slot (many N150 boxes have
  one free) can later replace one of the USB SSDs for more speed/headroom.

## Buying tips

- Compare prices across at least two sites before buying; SSD/mini-PC prices
  move week to week right now.
- Buy from a shop with a warranty you can actually use (a local retailer,
  or a well-known online store) rather than the cheapest possible listing —
  RMA/returns friction matters more than a few euros when the item is a
  server you'll rely on daily.
- You'll wipe whatever OS the mini PC ships with (usually Windows) to
  install Debian — don't pay extra for a Windows license you won't use.
- Prefer **16 GB RAM** even if soldered/non-upgradable: Jellyfin, Immich
  (which includes a Postgres database and a machine-learning service for
  face/smart search) and a handful of *arr containers add up.
- Pick **USB 3.2 Gen 2 (10 Gbps)** SSDs and plug them into the mini PC's
  fastest ports directly — not through a USB hub, which can bottleneck
  throughput and cause drives to drop under load.

## Where to buy in Spain

Compare on idealo.es, then buy from a shop with Spanish warranty and easy
returns (PcComponentes, MediaMarkt, Amazon.es); AliExpress "envío desde
España" listings are cheaper for mini PCs but warranty claims are slower.
Prices below were seen in 2026 listings and change often — treat them as a
starting point, not current fact.

| Item | Where to buy | Tip |
|---|---|---|
| Mini PC N150, 16 GB | idealo.es — N150 mini PCs · PcComponentes — Blackview MP60 N150/16 GB/512 GB · Amazon.es — Beelink Mini S13 N150 · Chollometro — mini PC deals · AliExpress N150 from ~€174 (androidpc.es) | Prefer 16 GB and 2.5 GbE. The Blackview MP60 has soldered RAM (fine at 16 GB). You'll wipe Windows anyway, so don't pay extra for it. |
| Portable USB SSD 2 TB | idealo.es — Crucial X9 Portable · idealo.es — Samsung T7 · PcComponentes — Crucial X9 Pro 2 TB · MediaMarkt — Crucial X9 2 TB · Samsung España — T7 2 TB | Pick USB 3.2 Gen 2 (10 Gbps) models. Prices swing a lot in the NAND shortage: set an idealo price alert. |
| Portable USB HDD 2 TB (cheaper alternative) | idealo.es — 2 TB external drives · PcComponentes — WD Elements 2 TB | Bus-powered 2.5" drives: slower and faintly audible, but half the price of SSDs. |
| Cat 6 Ethernet cable | Any shop (PcComponentes, Amazon.es, MediaMarkt) | A few euros; buy the length you need. |
| Google TV Streamer | Amazon.es — Google TV Streamer · Google Store, MediaMarkt | List price €119 in Spain, regularly on promo at €89 (tuapppara.com). |
| UPS (SAI) | PcComponentes — APC Easy UPS 700VA (~€86) · PcComponentes — all APC UPS | For automatic clean shutdown, pick a model whose listing mentions a USB data port and configure NUT on the server. |

Next: [02-assembly-and-first-boot.md](02-assembly-and-first-boot.md)
