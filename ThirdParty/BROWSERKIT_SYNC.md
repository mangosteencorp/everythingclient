# BrowserKit (vendored from Firefox for iOS) — sync notes for LLMs

`ThirdParty/BrowserKit` is a **trimmed copy** of the `BrowserKit/` folder of
<https://github.com/mozilla-mobile/firefox-ios>, plus the repo's `LICENSE` (MPL-2.0).
Only the `Redux` product is kept, together with `Common` — Redux imports it for
`Logger`/`DefaultLogger` and `WindowUUID`. Everything else upstream is dropped.

Kept paths: `Sources/Redux`, `Sources/Common`, `Tests/ReduxTests`, the `Common`/`Redux` schemes under `.swiftpm`, `LICENSE`,
`README.md`, and a trimmed `Package.swift` (see "Local patches").

| | |
| --- | --- |
| Upstream repo | `mozilla-mobile/firefox-ios` |
| Upstream path | `BrowserKit/` |
| Pinned commit | `b9f06bda55dc68011a794e75a53294532bc6db01` (2026-09-11) |
| License | MPL-2.0 — keep file headers and `LICENSE` intact |

## Why a copy and not a dependency

- `BrowserKit/Package.swift` lives in a subfolder of a ~1 GB repo; SwiftPM can only
  depend on a package whose manifest is at the repository root.
- Every BrowserKit target uses `.unsafeFlags(["-enable-testing"])`. SwiftPM rejects
  unsafe flags in remote (`.package(url:)`) dependencies; they are allowed only for
  local `.package(path:)` packages.

So it is consumed as a local package. It is **not** in the root `Package.swift` graph
yet; to use it, add it there:

```swift
.package(path: "ThirdParty/BrowserKit"),
// in a target:
.product(name: "Redux", package: "BrowserKit"),
```

Heads-up before wiring it in: `Common` pulls in `sentry-cocoa`, `Dip` and `SwiftyBeaver`.

## Rules

1. **Do not edit files under `ThirdParty/BrowserKit`** (other than the trimmed
   `Package.swift`). If a change is unavoidable, list it under "Local patches" below
   so the next sync re-applies it.
2. Sync `Sources/Redux`, `Sources/Common` and `Tests/ReduxTests` as whole folders.
   If upstream `Redux` gains a dependency on another target, bring that target along
   too and add it to the trimmed `Package.swift`.
3. After syncing, update the pinned commit in the table above.

## How to sync to upstream

```bash
ref=main   # or a tag / commit SHA, e.g. a release branch like release/v150
tmp=$(mktemp -d)
git clone --depth 1 --branch "$ref" --filter=blob:none --sparse \
  https://github.com/mozilla-mobile/firefox-ios.git "$tmp"   # for a SHA: clone main, then `git -C "$tmp" fetch --depth 1 origin <sha> && git -C "$tmp" checkout <sha>`
git -C "$tmp" sparse-checkout set BrowserKit
git -C "$tmp" rev-parse HEAD            # → new pinned commit
for d in Sources/Redux Sources/Common Tests/ReduxTests; do
  rsync -a --delete --exclude '.DS_Store' "$tmp/BrowserKit/$d/" "ThirdParty/BrowserKit/$d/"
done
cp "$tmp/BrowserKit/README.md" ThirdParty/BrowserKit/README.md
cp "$tmp/LICENSE" ThirdParty/BrowserKit/LICENSE
cp "$tmp/BrowserKit/Package.swift" "$TMPDIR/BrowserKit-upstream-Package.swift"   # compare by hand, see step 1
rm -rf "$tmp"
```

Then:

1. Compare `$TMPDIR/BrowserKit-upstream-Package.swift` with the trimmed one: port any change to the `Common`/`Redux` target
   definitions, `swift-tools-version`, platforms, or the `Dip`/`SwiftyBeaver`/`sentry-cocoa`
   versions into the trimmed `Package.swift` by hand. Build with
   `xcodebuild build -scheme Redux -destination 'generic/platform=iOS Simulator'`
   from `ThirdParty/BrowserKit`.
2. If any product is wired into the root `Package.swift`, build with
   `scheme=EverythingClient bash .github/scripts/build.sh` and fix call sites.
3. Update the pinned commit above and commit the sync on its own
   (e.g. `Sync BrowserKit to firefox-ios@<short-sha>`).

## Local patches

- `Package.swift` is trimmed to the `Common` and `Redux` products, the `ReduxTests` test
  target, and the three packages `Common` needs (`Dip`, `SwiftyBeaver`, `sentry-cocoa`).
  `Package.resolved` is not kept.
