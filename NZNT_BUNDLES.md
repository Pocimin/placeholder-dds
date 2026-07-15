# nznt's hub UI fork

`source.luau` is the vendored CompKiller runtime used by the game bundles.
The library stays internally named `Compkiller`; visible product branding is
applied by each bundle when it creates its window and loader.

The bundle build must keep the game script, this source, and monitoring code in
one Luau chunk. Runtime game loaders must not fetch UI code from
`scripts.nznt.store`.
