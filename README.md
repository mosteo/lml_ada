[![Build](https://github.com/mosteo/lml_ada/workflows/build/badge.svg)](https://github.com/mosteo/lml_ada/actions)
[![Alire](https://img.shields.io/endpoint?url=https://alire.ada.dev/badges/lml.json)](https://alire.ada.dev/crates/lml.html)
[![MIT licensed](https://img.shields.io/badge/license-MIT-blue.svg)](./LICENSE)

## Human-readable Data-serialization Language Conversions

A preelaborable library to convert between common human-readable data-serialization languages (JSON, TOML, YAML).

Supported conversions (from text input to text output):

| In↓ / Out→ | JSON | TOML | YAML |
|:----------:|:----:|:----:|:----:|
| **JSON**   |   ✓  |   ✓  |   ✓  |
| **TOML**   |   ✓  |   ✓  |   ✓  |

Supported typed conversions (types from libraries listed below):

| In↓ / Out→ | TOML | Yeison |
|:----------:|:----:|:------:|
| **JSON**   |   ✓  |   ✓    |
| **TOML**   |   ✓  |   ✓    |
| **Yeison** |   ✓  |   ✓    |

- JSON: https://github.com/onox/json-ada
- TOML: https://github.com/pmderodat/ada-toml
- Yeison: https://github.com/mosteo/yeison
