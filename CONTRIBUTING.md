# Contributing

Thank you for contributing to this repository.

## Commit Message Requirement

This project requires **Conventional Commits** for all commit messages.

`commitlint` is configured at the repository root and validates commit messages through a `commit-msg` Git hook.

Use the format:

```text
type(scope): short description
```

Examples:

```text
feat(scanner): add multilingual alias matching
fix(extractor): handle xz input path detection
docs(repo): document GPLv3 licensing
refactor(database): simplify local catalog bootstrap
chore(ci): update workflow dependencies
```

## Accepted Types

- `feat`
- `fix`
- `docs`
- `refactor`
- `test`
- `chore`
- `build`
- `ci`
- `perf`
- `revert`

## Notes

- Keep the description short and imperative.
- Prefer lowercase commit subjects.
- Use a scope when it adds clarity, such as `scanner`, `extractor`, `repo`, `docs`, or `database`.
- Breaking changes should follow the Conventional Commits specification.

## Local Setup

Install the repository tooling once at the root:

```bash
npm install
```

This installs `commitlint` and configures Git to use the hooks in `.githooks/`.

You can also run the linter manually:

```bash
npx commitlint --edit .git/COMMIT_EDITMSG
```

## Repository Structure

- `app/mtg_card_scanner`: Flutter mobile app
- `tools/mtg_data_extractor`: Python data pipeline tool
- `data/`: raw and generated database inputs/outputs
- `docs/`: repository and pipeline documentation
