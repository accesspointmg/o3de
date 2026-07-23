# RFC: O3DE 2.0.0 — The Object Model

- **Status:** Draft / working implementation
- **Authors:** Colin Byrne (byrcolin), Access Point Media Group
- **Implementation:** [accesspointmg/o3de](https://github.com/accesspointmg/o3de) (`2.0.0`),
  [accesspointmg/o3de-cli](https://github.com/accesspointmg/o3de-cli),
  [accesspointmg/o3de-pilot](https://github.com/accesspointmg/o3de-pilot),
  [accesspointmg/canonical.o3de.org](https://github.com/accesspointmg/canonical.o3de.org),
  [accesspointmg/o3de-extras](https://github.com/accesspointmg/o3de-extras)

## Summary

O3DE 2.0.0 recasts everything in the O3DE ecosystem — engines, gems, projects,
templates, repos, overlays — as **versioned, canonically named objects** with a
uniform metadata schema, a uniform release model, and a real dependency solver.
The engine stops being a special place where gems live and becomes just another
object you can resolve, download, build, package, and pin — exactly like a gem.

The proposal is not a design document in search of an implementation. Everything
described here exists and runs today in the repositories listed above: the
solver, the release channels, binary and source packaging, workspace
composition, the manifest-driven CMake build, and a GUI. The `2.0.0` branch is
current with upstream `o3de/development` (merged through tag `2510.2`) and
builds the full Editor.

## Motivation

O3DE's core strengths are undermined by how it is distributed and assembled:

1. **No versioned dependency resolution.** `gem_names` arrays with ad-hoc
   version fields, resolved by convention. Two versions of a gem cannot
   coexist meaningfully; upgrades are all-or-nothing.
2. **The engine is a monolith.** Gems live *inside* the engine repo, so
   shipping a gem fix means shipping the engine. The repo is LFS-heavy and
   slow to clone, and the boundary between "engine" and "content that happens
   to be in the engine repo" is invisible.
3. **Source-only assembly.** There is no first-class notion of consuming a
   prebuilt gem or a prebuilt engine. Everyone compiles everything, always.
4. **Fragmented tooling.** Object management logic is duplicated across
   `scripts/o3de`, Project Manager C++ bindings, and CMake, with no single
   owner and no consistent behavior.

## Design

### 1. Canonical objects

Every object has a canonical name and a semantic version:

```
org.o3de.engine.o3de        4.2.0
org.o3de.gem.atom_rpi       1.0.0
org.o3de.gem.physx          5.0.0
org.o3de.project.automatedtesting
org.o3de.template.defaultproject
```

Object metadata is JSON with `$schema`/`$schemaVersion` headers. Schema 2.0.0
documents live at canonical.o3de.org, together with machine-readable mapping
files that upgrade legacy metadata mechanically:

```
o3de-gem-2.0.0.json                     # the schema
o3de-gem-0.0.0-to-1.0.0-mapping.json    # legacy -> 1.0.0
o3de-gem-1.0.0-to-2.0.0-mapping.json    # 1.0.0 -> 2.0.0
```

During migration, upgraded metadata is written to a sidecar
(`gem.2-0-0.json`) next to the legacy file, so a tree can serve schema-1 and
schema-2 consumers simultaneously.

### 2. One release model, three channels

Every object's metadata carries a `releases[]` array. A release for a given
version can offer any combination of three artifact channels:

```jsonc
{
  "version": "5.0.0",
  "source_controls": [   // channel 1: git refs
    { "uri": "https://github.com/accesspointmg/o3de.git", "tag": "physx/5.0.0" }
  ],
  "downloads": [         // channel 2: code archives
    { "source": ".../physx-5.0.0-Source.zip", "source_sha256": "..." }
  ],
  "binaries": [          // channel 3: prebuilt, per platform
    { "platform": "Windows.AMD64", "binary": ".../physx-5.0.0-Windows.AMD64.zip", "sha256": "..." },
    { "platform": "Linux.AMD64",   "binary": "...", "sha256": "...", "abi": { "glibc": "2.28" } }
  ]
}
```

Platform tokens are `<OS>.<ARCH>` (`Windows.AMD64`, `Linux.ARM64`,
`Darwin.ARM64`). Legacy bare-OS tokens still match for compatibility. Linux
binaries may advertise an ABI floor (`glibc`); the resolver selects the highest
floor compatible with the host. Binary archives are install layouts containing
a `<canonical-name>Config.cmake`, consumable directly by `find_package`.

### 3. Resolution and the manifest-driven build

`o3de-cli` embeds a PubGrub-style solver (resolvelib). Inputs are the user
manifest (`~/.o3de/o3de_manifest.2-0-0.json`), registered local objects, and
remote repo indexes. Output is a **resolved manifest** — a complete pinned
closure with absolute paths.

The CMake build consumes only the resolved manifest. At configure time the
engine runs `o3de resolve`, then:

- every resolved object directory joins `CMAKE_PREFIX_PATH`, so
  `find_package(org.o3de.gem.camera 0.1.0)` works uniformly;
- gem subdirectories are added from the manifest index
  (`o3de_add_manifest_gem_subdirectories`), not from directory scanning;
- an object whose resolved artifact form is a **binary** is not compiled: its
  package config is imported instead (`artifact` / `binary_config_path` fields
  in the resolved manifest).

Workspaces are composed from resolved closures using hardlinks and carry a
workspace-scoped resolved manifest — a lockfile. Per-object **overrides** pin a
version and an artifact form (`source`, `local-binary`, `remote-binary`,
`remote-source`) and trigger a full re-solve, with conflicts reported, never
silently ignored.

### 4. Producing releases

```
o3de object build <gem>                # configure + build from source
o3de object install <gem>             # install layout + <name>Config.cmake
o3de object package <gem>             # -> <name>-<version>-<OS>.<ARCH>.zip  (binary channel)
o3de object package <gem> --code      # -> <name>-<version>-Source.zip|tar.gz (download channel)
o3de object package ... --update-manifest   # records the artifact in releases[]
```

Packaging computes hashes, records platform/ABI tokens, and dedupes release
entries. Local binary installs land in `~/.o3de/BuiltPackages/<name>-<version>/`
and are discovered by scanning the filesystem — no registration required.

### 5. One owner for object management

- **o3de-cli** owns registration, properties, repos, downloads, templates,
  schema upgrades, packaging, publishing, resolution, and workspaces.
- **The engine** keeps only what its build needs: `resolve`, plus
  engine-specific tooling (`android-configure`/`android-generate`,
  `export-project`). ~19k lines of duplicated object-management Python were
  removed from `scripts/o3de`.
- **o3de-pilot** (Qt GUI) replaces Project Manager, driving the same o3de-cli
  code paths instead of a parallel C++ reimplementation. Project Manager is no
  longer built.

### 6. The registry

canonical.o3de.org hosts the schemas, the version-mapping files, and repo
indexes in two tiers — **curated** (vetted) and **uncurated** — with optional
per-country index roots. A repo index is itself an object (`repo.json`), so
third parties host their own registries with the same format the canonical one
uses.

## The endgame: from monorepo to distribution

With engines resolved like any other object, the monorepo stops being the unit
of distribution:

- **Phase A (done):** objects, releases, solver, workspaces, binary
  consumption, tooling split — on top of the existing repo layout, current
  with upstream.
- **Phase B:** restructure the repo as a workspace: `repo.json` at the root,
  one folder per object type; the engine object becomes a sibling of the gems
  it ships with.
- **Phase C:** the `o3de` repo becomes a **distribution**: a `repo.json` and
  `releases/<version>.lock.json` files — a pinned, tested closure of object
  releases. "O3DE 25.10" is a lockfile, not a 10 GB clone.
- **Phase D:** extract object families (Atom, PhysX, ScriptCanvas, ...) into
  their own repositories with `git filter-repo`, preserving history. Gem fixes
  ship on the gem's cadence; the distribution pins what it has tested.

## Compatibility

- Schema upgrades are mechanical and reversible (mapping files + sidecars);
  legacy `gem.json` continues to load.
- Legacy CMake names are shimmed (`ly_*` wrappers, version-agnostic
  `Gem::PhysX` aliases); projects reference `Gem::<name>` targets unchanged.
- Legacy bare-OS platform tokens in existing release metadata still match.
- The sidecar strategy means a single tree serves old and new tooling during
  the transition.

## Status

| Piece | State |
|---|---|
| Solver, manifests, workspaces, overrides | Working (o3de-cli, ~1000 tests passing) |
| Release channels: source_controls / downloads / binaries | Working, incl. platform + glibc ABI selection |
| Binary gem consumption in CMake | Working (`artifact` → imported package config) |
| Manifest-driven engine build | Working; cold configure + full Editor build on Windows |
| Engine/CLI/GUI tooling split | Done (engine scripts retired, Project Manager removed) |
| Canonical schemas + mappings + indexes | Published (canonical.o3de.org, 2.0.0 branch) |
| Current with upstream | Merged `o3de/development` through `2510.2` |
| Engine-as-binary-object | In progress |
| Repo restructure / distribution / extraction | Planned (Phases B–D) |

## Open questions

1. **Governance of the curated index** — who vets entries, and what are the
   acceptance criteria?
2. **Binary ABI policy beyond glibc** — MSVC toolset floors, macOS deployment
   targets, and how much to encode in the platform token vs. `abi{}`.
3. **Distribution cadence** — how lockfile releases relate to the existing
   o3de release process and SIG structure.
4. **Extraction order and repo ownership** — which object families leave the
   monorepo first, and under which SIGs.
