# Contributing

Thank you for helping. Components, fixes and ideas are all welcome.
[AGENTS.md](AGENTS.md) maps the repository and lists the rules every change
keeps; read it first, whether you are a person or a coding agent.

## Before you start

- **A bug**: open an issue with the bug form. Say which component, which iOS
  version and how to see it.
- **A new component**: open an issue with the component form first, so the idea
  can be shaped before the code is written.
- **A vulnerability**: never in a public issue. See [SECURITY.md](SECURITY.md).

Everyone involved follows the [code of conduct](CODE_OF_CONDUCT.md).

## Where code may come from

Every line in this repository has to be redistributable under its license.

- **Original work** is always welcome.
- **Code under a compatible license** (MIT, BSD, Apache 2.0) may be adapted.
  Keep its license and copyright notice next to it, and record the source in
  the component's metadata.
- **Everything else stays out**: paid courses and tutorials, code with no
  license, and anything else without permission to redistribute. An idea can
  inspire a new implementation written from scratch, and should be credited,
  but do not copy or closely translate its code.

## Branches

The repository follows Gitflow.

| Branch | Purpose | Branches from | Merges into |
|---|---|---|---|
| `main` | What has been released | | |
| `develop` | Integration | `main` | |
| `feature/*` | New work | `develop` | `develop`, through a pull request |
| `release/X.Y.Z` | Preparing a release | `develop` | `main` and `develop` |
| `hotfix/*` | Urgent fixes to a release | `main` | `main` and `develop` |

Pull requests target `develop`, except releases and hotfixes.

## Making a change

1. Branch from `develop`: `git switch -c feature/short-name develop`.
2. Write the change, and tests for any logic it adds.
3. If users will notice it, add a line under "Unreleased" in
   [CHANGELOG.md](CHANGELOG.md).
4. Commit with [Conventional Commits](https://www.conventionalcommits.org/), in
   English: `feat(buttons): add pressable scale style`.
5. Open a pull request against `develop` and fill in the template.

Keep pull requests to one topic. Match the style of the code around you, and
let comments say why rather than what.

Every component needs an animated preview, as
[AGENTS.md](AGENTS.md#recording-a-preview) explains. After changing a
component, run `make catalog` and commit the generated files.
Then check the change with `make verify`, which needs Node 24 or later and
Xcode 27.2 or later with its Metal toolchain.
[AGENTS.md](AGENTS.md#commands) lists every command.

## Releasing

For maintainers. Versions follow [Semantic Versioning](https://semver.org/),
and tags are `X.Y.Z` without a `v`.

1. `git switch -c release/X.Y.Z develop`
2. Give the unreleased notes in [CHANGELOG.md](CHANGELOG.md) a dated heading,
   commit it as `chore(release): X.Y.Z` and push the branch.
3. Merge it into `main` without fast-forward, tag `main` with an annotated
   `X.Y.Z` tag and push both. The push to `main` publishes the site.
4. Merge `main` back into `develop`.
