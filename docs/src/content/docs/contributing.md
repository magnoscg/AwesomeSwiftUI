---
title: Contributing
description: How to propose a component, fix one and get the change merged.
---

Components, fixes and ideas are all welcome. This page is the short version.
[CONTRIBUTING.md](https://github.com/magnoscg/swiftui-blocks/blob/HEAD/CONTRIBUTING.md)
has the workflow in full, and
[AGENTS.md](https://github.com/magnoscg/swiftui-blocks/blob/HEAD/AGENTS.md)
maps the repository for people and coding agents alike.

## Before you start

- **A bug**: open an issue with the bug form. Say which component, which iOS
  version and how to see it.
- **A new component**: open an issue with the component form first, so the
  idea can be shaped before the code is written.
- **A vulnerability**: never in a public issue. See
  [SECURITY.md](https://github.com/magnoscg/swiftui-blocks/blob/HEAD/SECURITY.md).

## What a component is made of

```text
Components/
  <Category>/
    <Name>/
      <Name>.swift       The component, a demo and a preview, in one file
      <Name>.meta.json   Keywords, minimum iOS, APIs used, difficulty, origin
      <Name>.webp        An animated preview of what it looks like
      <Name>.metal       Its Metal shader, in the few components that have one
```

It keeps [the rules](/rules/) of the catalog.

## Make the change

1. Branch from `develop`: `git switch -c feature/short-name develop`.
2. Write the component and its metadata, and tests for any logic it adds.
3. Run `make catalog`, which rewrites the indexes, and record its preview
   with `make record COMPONENT=<Category>/<Name>`.
4. Check it with `make verify`. It needs Node 24 or later and Xcode 27.2 or
   later with its Metal toolchain.
5. Commit with [Conventional Commits](https://www.conventionalcommits.org/),
   in English, and open a pull request against `develop`.

Keep a pull request to one topic.

## Where code may come from

Every line has to be redistributable under its license.

- **Original work** is always welcome.
- **Code under a compatible license** (MIT, BSD, Apache 2.0) may be adapted.
  Keep its license and copyright notice next to it, and record the source in
  the metadata.
- **Everything else stays out**: paid courses and tutorials, code with no
  license, and anything else without permission to redistribute. An idea can
  inspire a new implementation written from scratch, credited with a link.
