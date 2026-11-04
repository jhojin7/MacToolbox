# Upstream verification skills

`create-verification-skill` and `maintain-verification-skill` are vendored from
[Lauren Tan (poteto)'s pstack](https://github.com/cursor/plugins/tree/4dd1d05818d19792e7cd6e818f1667f95f7e1dbe/pstack/skills),
commit `4dd1d05818d19792e7cd6e818f1667f95f7e1dbe` (MIT; see [POTETO-LICENSE](POTETO-LICENSE)).

Codex adaptations: `.cursor/skills/` paths become `.agents/skills/`; the
Cursor-specific `disable-model-invocation` frontmatter is omitted. Workflow
content and bundled feature-map examples are otherwise retained.

`verify-mac-toolbox` is the project-specific output of that creation workflow.
It uses native macOS Accessibility APIs and a non-mutating menu harness. These
skills do not authorize display changes, permission changes, commits, or PRs.
