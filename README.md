# placeholder-dds

Public CompKiller runtime used by nznt's bundled Roblox scripts.

Files:

- `source.luau`: CompKiller runtime with the `NZNT_COMPKILLER` bundle hook.
- `starlight_compat.luau`: compatibility surface for existing Starlight-style modules.
- `compkiller_arcane_compat.luau`: compatibility surface for existing DDS/CDID Arcane-style modules.
- `maclib_compat.luau`: compatibility surface for the legacy DDS free loader.

The Roblox bundle builder embeds these files into each game entrypoint, so the game script does not need to fetch a UI library from `scripts.nznt.store`.
