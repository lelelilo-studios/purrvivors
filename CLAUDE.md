# Purrvivors — Project Guide

Purrvivors is a cross-platform (web + mobile + desktop) top-down survivor-like built in **Godot 4.x / GDScript**, with all pixel art generated via the **PixelLab MCP**. The full build spec is **SPEC.md** — it is the source of truth. Follow it exactly and re-read the relevant section before starting each phase.

## Prime directive
Build the game to SPEC.md. If this file and SPEC.md ever conflict on a detail, SPEC.md wins — this file just keeps the non-negotiables front-of-mind.

## Non-negotiables (never drift from these)
- **No AI slop.** The game must feel intentional and hand-crafted. Curate AI art — **regenerate anything off-model, muddy, or generic**; never accept the first output as-is. One locked palette, one pixel density, nearest-neighbor + integer scaling.
- **Personality everywhere.** Charming names + flavor text for every weapon, passive, enemy, cat, and menu. Never "Enemy" / "Upgrade 1" / "Play".
- **Game feel first.** Hit-stop, knockback, screen shake, particles, easing, idle animations. Nothing floaty or abrupt.
- **Polished UI from day one.** One global Theme + a pixel font + 9-slice panels. Zero default-gray Controls, ever.
- **Everything tunable.** All balance numbers centralized in data (a `Balance.gd` config / `.tres` resources), never hardcoded. Weapons in one DPS band — no dominant/dead weapon; threat-proportional rewards; escalating economy.
- **Cross-platform + responsive.** Web (HTML5), mobile (touch joystick), desktop (keyboard); Control-container layouts; safe areas. Mobile = touch verified via phone browser / emulated viewport; configure Android/iOS presets but do NOT build/sign native binaries.
- **Horde performance.** Object pooling everywhere; swarm enemies use lightweight manual movement (NOT per-enemy `CharacterBody2D` — physics bodies for player + bosses only). Profile 300+ enemies on the web build early.
- **Tiered wins + difficulty gate.** 3 bosses at 5/10/15 min; a run is a win if you beat >=1 boss (1-3 paws); bosses persist until killed and only kills count. A fresh cat must NOT be able to full-clear run 1 — meta-progression across runs is the point.
- **License-clean assets only.** SFX/music from CC0 sources (Kenney, freesound CC0, or procedural sfxr-style), one cohesive family; fonts free-licensed; everything credited in `CREDITS.md`. This repo is public — no unlicensed rips.

## How to work
- Proceed **one build-order phase at a time**; commit after each; pause for my review.
- Before any asset batch, run the PixelLab `get_balance` tool; spend <=75% of the pool, keep ~25% for regenerations.
- **Never commit secrets** (PixelLab token, keys, tokens of any kind).
- Publish target: source -> `github.com/lelelilo-studios/purrvivors`; web build -> GitHub Pages (serve from a `docs/` folder; export with **threads OFF** to avoid the COOP/COEP header issue).
