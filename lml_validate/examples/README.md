# Examples

Sample data files for `lml_validate`, all checked against the schema at
[`schemas/test-pragmas.yaml`](../../schemas/test-pragmas.yaml) (relative to
the repository root). Run from the repository root:

```bash
lml_validate lml_validate/examples/valid/full_test.yaml schemas/test-pragmas.yaml
# -> VALID            (exit status 0)

lml_validate lml_validate/examples/invalid/timeout_not_number.json schemas/test-pragmas.yaml
# -> INVALID: ...     (exit status 1)
```

The format of each file is taken from its extension, so the same schema is
exercised from both YAML and JSON inputs.

## valid/

| File                          | Why it is valid                                                  |
| ----------------------------- | ---------------------------------------------------------------- |
| `auxiliary_only.yaml`         | `Auxiliary_File: true` alone — satisfies `maxProperties: 1`.     |
| `explicit_non_auxiliary.yaml` | `Auxiliary_File: false`, so the conditional rule does not fire.  |
| `full_test.yaml`              | `Name`, `Should_Fail`, `Timeout` with correct types.            |
| `named_test.json`             | A subset of the allowed keys.                                    |
| `empty.json`                  | No pragmas at all; nothing is required at the top level.         |

## invalid/

| File                            | Why it is rejected                                              |
| ------------------------------- | -------------------------------------------------------------- |
| `auxiliary_with_extra.yaml`     | `Auxiliary_File: true` plus another key — breaks `maxProperties: 1`. |
| `should_fail_not_boolean.yaml`  | `Should_Fail` is a string, not a boolean.                      |
| `timeout_not_number.json`       | `Timeout` is a string, not a number.                           |
| `unknown_key.json`              | `Bogus` is not an allowed key (`additionalProperties: false`). |
| `unknown_pragma.yaml`           | `Build_Switches` is not an allowed top-level pragma name.      |
