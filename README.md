# flint-tool

`flint`, the project tool of the [Flint](https://github.com/ToastL/flint) language: it creates
projects, downloads what they depend on, and builds, runs and tests them. The compiler, `flintc`,
lives in the language's repository; flint calls it and knows it only through its command line,
so the two are developed and built separately (like Rust's `rustc` and `cargo`).

```sh
flint init hello            # hello/flint.toml and hello/src/main.fl
cd hello
flint run -- args           # build the project and run it
flint build --release       # out/release/hello
flint test                  # every `test` block in the project
flint check                 # compile errors only
flint fetch                 # download its dependencies ahead of time
flint clean                 # remove out/
flint help build            # every command has its own help
```

## flint.toml

```toml
[package]
name = "app"
version = "0.1.0"
root = "src/main.fl"                 # the default

[dependencies]
geometry = { path = "../geometry" }
json = { url = "https://example.com/json-1.2.0.tar.gz", sha256 = "9f2c..." }

[c]                                  # C code in the package, built with the C compiler
sources = ["c/fastmath.c"]
include = ["c"]
flags = ["-Wall"]
link = ["m"]

[profile.release]                    # build settings: flint build --release
overflow = "wrap"
c-flags = ["-march=native"]
```

- **Profiles** are named build settings: `optimize` (`-O2`), `overflow` (`"trap"` or `"wrap"`)
  and `c-flags`. `debug` (the default) and `release` (optimized) exist without being written;
  `[profile.<name>]` changes one or makes a new one, and `--release` or `--profile=<name>` picks
  it. Only the profiles of the project being built count, not its dependencies'.
- **Dependencies** are a `path`, or a `url` with the `sha256` of the archive there (anything `tar`
  unpacks). It's downloaded once into `$FLINT_CACHE` (`~/.cache/flint` by default), checked
  against the hash, and found there from then on. The hash pins the dependency, so there's no
  lock file; leave it out and flint tells you the hash of what the url has now. There's no
  `flint add` yet: a dependency is added by writing it in `flint.toml`.
- **`out/`** is where a project is built: the executable is `out/<profile>/<name>`, and what it
  was made from stays in `out/<profile>/cache/`. Each step (each C source, then flintc's
  assembling and linking) is skipped when its inputs are the ones it last ran with.

## How it builds a project

flint compiles the C sources itself, then makes one `flintc` call with everything else as options
(`flint build --verbose` prints it):

```sh
flintc build -O0 --overflow=trap \
    --pkg geometry=../geometry/src/geometry.fl --dep geometry=geometry \
    --include c --object out/debug/cache/main/c/app-....o --lib m \
    --cache out/debug/cache/main -o out/debug/app src/main.fl
```

It finds the compiler as `$FLINTC`, or the `flintc` next to itself, or the one in `PATH`.

## Building flint

```sh
./build.sh                  # build/flint, with the flintc in PATH (or FLINTC=path/to/flintc)
flint build --release       # or with flint itself: out/release/flint
```

The language's repository has this repository as a git submodule (`tool/`): its `./x` builds
`flint` with the `flintc` it just built, ships both in a release, and runs the tests, including
flint's (projects, downloaded dependencies, and flint's own command line).

## Layout

- `src/main.fl` and `src/cli.fl`: the command line
- `src/project.fl`: `flint.toml` (`src/toml.fl` reads the file)
- `src/fetch.fl`: downloaded dependencies (`src/sha256.fl` checks them)
- `src/build.fl`: the C sources, then the `flintc` call
- `src/scaffold.fl`: `init`, `fetch`, `clean`
- `src/cache.fl`: `out/`, and when what's in it can be used again
- `src/base/`: memory, strings, terminal colors, command-line errors
