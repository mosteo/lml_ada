[![Build](https://github.com/mosteo/lml_ada/workflows/build/badge.svg)](https://github.com/mosteo/lml_ada/actions)
[![Alire](https://img.shields.io/endpoint?url=https://alire.ada.dev/badges/lml.json)](https://alire.ada.dev/crates/lml.html)
[![MIT licensed](https://img.shields.io/badge/license-MIT-blue.svg)](./LICENSE)

## Human-readable Data-serialization Language Conversions

A preelaborable library to convert between common human-readable
data-serialization languages (JSON, TOML, YAML).

Yeison is a format-agnostic data type that can be used as an intermediate
representation or convenient in-memory data structure for manipulation. It has
no human-readable representation, but is show in these tables for completeness.

Supported conversions (from text input to text output):

| In↓ / Out→ | JSON | TOML | YAML |
|:----------:|:----:|:----:|:----:|
| **Ada**    |   ✓  |   ✓  |   ✓  |
| **JSON**   |   ✓  |   ✓  |   ✓  |
| **TOML**   |   ✓  |   ✓  |   ✓  |
| **YAML** † |   ✓  |   ✓  |   ✓  |

Supported typed conversions (types from the libraries listed below):

| In↓ / Out→ | TOML | Yeison |
|:----------:|:----:|:------:|
| **JSON**   |   ✓  |   ✓    |
| **TOML**   |   ✓  |   ✓    |
| **Yeison** |   ✓  |   ✓    |

- JSON: https://github.com/onox/json-ada
- TOML: https://github.com/pmderodat/ada-toml
- YAML: https://github.com/yaml/AdaYaml
- Yeison: https://github.com/mosteo/yeison

† YAML **input** relies on AdaYaml, which is not preelaborable. To keep `LML`
itself preelaborable the client must initialize the YAML parser by calling
once at startup before parsing any YAML:

```ada
LML.Input.YAML.Initialization.Initialize;
```

Anchors and aliases are not yet supported and raise `LML.Unsupported_Error`.
