# Stowed in this order on a fresh install; any subset works, e.g.
#   make stow PACKAGES="nvim"
PACKAGES := git bash readline ripgrep nvim tmux

.PHONY: check doctor lint test stow

check: doctor lint test

doctor:
	@scripts/doctor.sh $(PACKAGES)

lint:
	@scripts/lint.sh

test:
	@scripts/test.sh

stow:
	stow $(PACKAGES)
