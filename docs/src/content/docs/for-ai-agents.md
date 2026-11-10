---
title: For AI agents
description: How coding agents can find and fetch components from the catalog.
---

The catalog is generated from the metadata of each component, so these files
always describe the same components.

| File | What it has |
|---|---|
| [`catalog.json`](/AwesomeSwiftUI/catalog.json) | Every component: keywords, minimum iOS, APIs, origin, a `rawURL` and, with a Metal shader, a `shaderRawURL` |
| [`llms.txt`](/AwesomeSwiftUI/llms.txt) | A short index with a link to each component |
| [`llms-full.txt`](/AwesomeSwiftUI/llms-full.txt) | Every component with its full source |

## Find and add a component

1. Search `keywords.en` and `keywords.es` in `catalog.json`.
2. Compare its `minIOS` with the deployment target of the project.
3. Download its `rawURL` into a new Swift file in the project, keeping the
   header.
4. If it has a `shaderRawURL`, download that too, into a `.metal` file in the
   same target. The component draws nothing without it.

## Contribute

[AGENTS.md](https://github.com/magnoscg/AwesomeSwiftUI/blob/HEAD/AGENTS.md) maps
the repository and lists the rules a change has to keep.
