# Once just v1.39.0 is widely deployed, simplify with the `read` function.
NIGHTLY_VERSION := trim(shell('cat "$1"', justfile_directory() / "nightly-version"))

_default:
  @just --list

# Install rbmt (Rust Bitcoin Maintainer Tools).
@_install-rbmt:
  cargo install --quiet --git https://github.com/rust-bitcoin/rust-bitcoin-maintainer-tools.git --rev $(cat {{justfile_directory()}}/rbmt-version) cargo-rbmt
  RBMT_LOG_LEVEL=quiet cargo rbmt toolchains > /dev/null

# Cargo check everything.
check:
  cargo check --all --all-targets --all-features

# Cargo build everything.
build:
  cargo build --all --all-targets --all-features

# Test everything.
test:
  cargo test --all-targets --all-features
  just test-bitcoind

# Test bitcoind integration with a bitcoind version.
test-bitcoind version="29_0":
  cd {{justfile_directory()}}/bitcoind-tests && cargo test --features={{version}}

# Lint everything.
lint:
  cargo +{{NIGHTLY_VERSION}} clippy --all-targets --all-features -- --deny warnings

# Run cargo fmt
fmt:
  cargo +{{NIGHTLY_VERSION}} fmt --all

# Generate documentation.
docsrs *flags:
  RUSTDOCFLAGS="--cfg docsrs -D warnings -D rustdoc::broken-intra-doc-links" cargo +{{NIGHTLY_VERSION}} doc --all-features {{flags}}

# Update the recent and minimal lock files using rbmt.
[group('tools')]
@update-lock-files: _install-rbmt
  cargo rbmt lock

# Ensure the exposed API files in api/ are up-to-date.
[group('tools')]
check-api: _install-rbmt
  cargo rbmt api

# Test crate.
[group('ci')]
ci-test toolchain="stable" lock="recent": _install-rbmt
  cargo rbmt --lock-file {{lock}} test --toolchain {{toolchain}}

# Lint crate.
[group('ci')]
ci-lint: _install-rbmt
  cargo rbmt lint

# Bitcoin core integration tests.
[group('ci')]
ci-integration: _install-rbmt
  cargo rbmt integration
