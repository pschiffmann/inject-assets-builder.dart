# usage

_dep_, awaiting a file `lib/asset.txt`:

```yaml
targets:
  $default:
    builders:
      reverse_asset_import:
        options:
          file_extensions: [".txt"]
```

_app_:

```yaml
targets:
  dep|dep:
    builders:
      reverse_asset_import:
        options:
          substitutions:
            "dep|asset.default.txt": "app|asset.css"
```
