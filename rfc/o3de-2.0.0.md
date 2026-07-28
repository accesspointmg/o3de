# RFC: O3DE 2.0.0 — The Object Model

- **Status:** Draft / working implementation
- **Authors:** Colin Byrne (byrcolin), Access Point Media Group
- **Implementation:**
  [accesspointmg/org.o3de.repo.o3de](https://github.com/accesspointmg/org.o3de.repo.o3de)
  (the engine object's family repo, formerly `accesspointmg/o3de`),
  [accesspointmg/o3de-cli](https://github.com/accesspointmg/o3de-cli),
  [accesspointmg/o3de-pilot](https://github.com/accesspointmg/o3de-pilot),
  [accesspointmg/canonical.o3de.org](https://github.com/accesspointmg/canonical.o3de.org),
  [accesspointmg/o3de-extras](https://github.com/accesspointmg/o3de-extras),
  plus 116 further `org.o3de.repo.*` object family repos extracted from the
  first two.

## Summary

O3DE 2.0.0 recasts everything in the O3DE ecosystem — engines, gems, projects,
templates, repos, overlays — as **versioned, canonically named objects** with a
uniform metadata schema, a uniform release model, and a real dependency solver.
The engine stops being a special place where gems live and becomes just another
object you can resolve, download, build, package, and pin — exactly like a gem.

The proposal is not a design document in search of an implementation. Everything
described here exists and runs today in the repositories listed above: the
solver, the release channels, binary and source packaging, overlay composition,
workspace composition, the manifest-driven CMake build, and a GUI. The engine
branch is current with upstream `o3de/development` (merged through tag `2510.2`)
and builds the full Editor.

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
5. **Platform payloads are structural, not composable.** PAL directories bind
   platform support into the object's tree, so a platform cannot be added,
   withheld, or replaced without editing the object itself.

## Design

### 1. Canonical objects

Every object has a canonical name and a semantic version:

```
org.o3de.engine.o3de        4.2.0
org.o3de.gem.atom_rpi       1.0.0
org.o3de.gem.physx          5.0.0
org.o3de.project.automatedtesting
org.o3de.template.defaultproject
org.o3de.overlay.physx.windows
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
schema-2 consumers simultaneously. A file already at 2.0.0 under the
unversioned name is edited in place; sidecars exist only where an upgrade
actually happened.

### 2. One release model, three channels

Every object's metadata carries a `releases[]` array. A release for a given
version can offer any combination of three artifact channels:

```jsonc
{
  "version": "5.0.0",
  "source_controls": [   // channel 1: git refs
    { "uri": "https://github.com/accesspointmg/org.o3de.repo.physx.git", "tag": "physx/5.0.0" }
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
manifest (`~/.o3de/o3de_manifest.json`, or the `o3de_manifest.2-0-0.json`
sidecar where one was produced by an upgrade), registered local objects, and
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

### 4. Overlays: platform and variant composition

An overlay is an object like any other — canonically named, versioned,
releasable — whose purpose is to layer files onto another object:

```jsonc
{
  "$schemaVersion": "2.0.0",
  "overlay": { "name": "org.o3de.overlay.physx.windows", "version": "5.0.0" },
  "extends": "org.o3de.gem.physx>=5.0.0",   // required: the object layered onto
  "precedence": 10,                          // required: apply order, higher wins
  "platforms": ["windows"],                  // selection criteria
  "dependent": { "overlays": ["org.o3de.overlay.physx.common>=5.0.0"] }
}
```

The object root holds only metadata — `overlay.json`, licenses, icon — which is
never composed. The payload lives in an `Overlay/` subfolder whose contents map
onto the extended object's root at the same relative paths. This mirrors the
Template convention, and keeps "what describes the overlay" strictly separate
from "what the overlay delivers".

Selection is criteria-driven at compose time. `--platforms` and `--tags`
combine as OR: an overlay is auto-selected if it delivers any requested
platform or carries any requested tag. Overlays with no `platforms` are
platform-agnostic and apply universally — unless they are the target of another
overlay's `dependent.overlays`, in which case they are family/common payloads
pulled in transitively rather than matched directly. Explicit
`--include-overlay` / `--exclude-overlay` override the criteria, and
`--overlay-order` overrides authored precedence per base object.

Because a platform is now a separate object, platform support can be shipped,
withheld, versioned, and replaced independently of the object it extends — and
a third party can add a platform to an object they do not own.

Overlays are produced mechanically from existing PAL layouts:

```
o3de object split-platforms <object> -o <dir>   # PAL dirs -> overlay objects
```

### 5. Producing releases

```
o3de object build <gem>                # configure + build from source
o3de object install <gem>             # install layout + <name>Config.cmake
o3de object package <gem>             # -> <name>-<version>-<OS>.<ARCH>.zip  (binary channel)
o3de object package <gem> --code      # -> <name>-<version>-Source.zip|tar.gz (download channel)
o3de object package ... --update-manifest   # records the artifact in releases[]
o3de object hoist <object>            # project an object into its own family repo
o3de object split-platforms <object>  # extract PAL dirs into overlay objects
```

Packaging computes hashes, records platform/ABI tokens, and dedupes release
entries. Local binary installs land in `~/.o3de/BuiltPackages/<name>-<version>/`
and are discovered by scanning the filesystem — no registration required.

### 6. One owner for object management

- **o3de-cli** owns registration, properties, repos, downloads, templates,
  schema upgrades, packaging, publishing, resolution, overlays, and workspaces.
- **The engine** keeps only what its build needs: `resolve`, plus
  engine-specific tooling (`android-configure`/`android-generate`,
  `export-project`). ~19k lines of duplicated object-management Python were
  removed from `scripts/o3de`.
- **o3de-pilot** (Qt GUI) replaces Project Manager, driving the same o3de-cli
  code paths instead of a parallel C++ reimplementation. Project Manager is no
  longer built.

### 7. The registry

canonical.o3de.org hosts the schemas, the version-mapping files, and repo
indexes in two tiers — **curated** (vetted) and **uncurated** — with optional
per-country index roots. A repo index is itself an object (`repo.json`), so
third parties host their own registries with the same format the canonical one
uses.

### 8. Repository layout and branch policy

Each object family lives in its own repository advertising its children through
`repo.json`. All family repos follow one branch model, so a contributor learns
it once:

- **`main`** is the latest release. Protected; never committed to directly, and
  merged into only from a release branch. Tagged per release; consumers resolve
  metadata from here.
- **`development`** is branched from `main` and is the bleeding edge. Protected;
  nobody works *in* it. Linear history is required, so changes arrive squashed
  or rebased.
- **Contributors** branch from `development`, make their changes, and open a
  pull request back into `development`. Automated review gates the merge.
- **Releases** branch `development` as `release-x.y.z`, stabilize there, bump
  object versions according to what changed since the last release, then merge
  into `main`, tag, and publish binaries.

GitHub branch protection can require a pull request but cannot restrict which
branch that pull request comes from, so the source-branch rule is enforced by a
`branch-guard` check that fails a pull request into `main` from anything other
than `release-*`, and a pull request into `development` from `main`.

## The endgame: from monorepo to distribution

With engines resolved like any other object, the monorepo stops being the unit
of distribution:

- **Phase A (done):** objects, releases, solver, workspaces, binary
  consumption, tooling split — on top of the existing repo layout, current
  with upstream.
- **Phase D (done, ahead of B and C):** object families extracted into their
  own repositories with `git filter-repo`, preserving history — 117
  `org.o3de.repo.*` repos to date, covering the gems, projects, templates and
  overlays previously carried by the engine and extras repos. Platform payloads
  are split into overlay objects within the same history rewrite, so an
  extracted family arrives already decomposed. Gem fixes ship on the gem's
  cadence; the distribution pins what it has tested.
- **Phase B:** restructure the remaining engine repo as a workspace:
  `repo.json` at the root, one folder per object type; the engine object becomes
  a sibling of the objects it ships with.
- **Phase C:** the `o3de` repo becomes a **distribution**: a `repo.json` and
  `releases/<version>.lock.json` files — a pinned, tested closure of object
  releases. "O3DE 25.10" is a lockfile, not a 10 GB clone.

Extraction ran ahead of the in-place restructure because it is the step that
proves the object model: an object that cannot leave the monorepo and still
resolve, build and release was never really an object.

## Compatibility

- Schema upgrades are mechanical and reversible (mapping files + sidecars);
  legacy `gem.json` continues to load.
- Legacy CMake names are shimmed (`ly_*` wrappers, version-agnostic
  `Gem::PhysX` aliases); projects reference `Gem::<name>` targets unchanged.
- Legacy bare-OS platform tokens in existing release metadata still match.
- The sidecar strategy means a single tree serves old and new tooling during
  the transition.
- Overlays are additive: an object whose platform payloads have been split out
  still resolves and builds for a consumer that composes the matching
  overlays, and the composed tree is layout-identical to the pre-split object.

## Status

| Piece | State |
|---|---|
| Solver, manifests, workspaces, overrides | Working (o3de-cli, 1055 tests passing) |
| Release channels: source_controls / downloads / binaries | Working, incl. platform + glibc ABI selection |
| Binary gem consumption in CMake | Working (`artifact` → imported package config) |
| Manifest-driven engine build | Working; cold configure + full Editor build on Windows |
| Engine/CLI/GUI tooling split | Done (engine scripts retired, Project Manager removed) |
| Canonical schemas + mappings + indexes | Published (canonical.o3de.org, `main`) |
| Overlay composition (platform/variant layering) | Working — schema published, criteria selection and precedence apply at compose time |
| Object family extraction (Phase D) | Done — 117 `org.o3de.repo.*` repos, history preserved, platforms split |
| Uniform branch policy across object repos | Applied to 119 repos (protection + `branch-guard` check) |
| Current with upstream | Merged `o3de/development` through `2510.2` |
| Engine-as-binary-object | In progress |
| Repo restructure (Phase B) / distribution lockfiles (Phase C) | Planned |
| Upstream update path for extracted families | Open — see question 5 |

## Open questions

1. **Governance of the curated index** — who vets entries, and what are the
   acceptance criteria?
2. **Binary ABI policy beyond glibc** — MSVC toolset floors, macOS deployment
   targets, and how much to encode in the platform token vs. `abi{}`.
3. **Distribution cadence** — how lockfile releases relate to the existing
   o3de release process and SIG structure.
4. **Extraction order and repo ownership** — which object families leave the
   monorepo first, and under which SIGs.
5. **Upstream update path for extracted families.** `git filter-repo` rewrites
   commit identities, so an extracted family shares no ancestry with upstream
   and cannot simply `fetch` and `merge` from it. Replaying the *identical*
   filter against a newer upstream is deterministic and would merge cleanly,
   but the argument list — the kept paths and the platform renames — is
   computed from the working tree at hoist time and is not recorded in the
   family repo. Making families updatable needs that provenance persisted
   (filter arguments, source commit, `git-filter-repo` version) and a replay
   command that lands the result on `development` for review. The alternative,
   regenerating and applying the content delta as an ordinary commit, is
   simpler but discards upstream commit granularity.
