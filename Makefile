.PHONY: install check dry-run install-macos install-linux check-macos check-linux dry-run-macos dry-run-linux test prove bundle prove-bundle ci

install:
	./install.sh

check:
	./install.sh --check

dry-run:
	./install.sh --dry-run

install-macos:
	./install.sh --profile macos

install-linux:
	./install.sh --profile linux

check-macos:
	./install.sh --check --profile macos

check-linux:
	./install.sh --check --profile linux

dry-run-macos:
	./install.sh --dry-run --profile macos

dry-run-linux:
	./install.sh --dry-run --profile linux

test:
	./tests/test.sh

prove:
	./tests/prove-runtime.sh

bundle:
	./scripts/build-bundle.sh

prove-bundle:
	./tests/prove-bundle.sh

ci: test prove prove-bundle
