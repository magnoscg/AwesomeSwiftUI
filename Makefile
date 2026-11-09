.PHONY: catalog check test

# Rewrites the files generated from the component metadata.
catalog:
	node scripts/catalog.mjs generate

# Fails if a component breaks a rule or a generated file is out of date.
check:
	node scripts/catalog.mjs check

test:
	node --test scripts/catalog.test.mjs
