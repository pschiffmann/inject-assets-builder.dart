inject assets builder
=====================

[![Build Status](https://travis-ci.com/pschiffmann/inject-assets-builder.dart.svg?branch=master)](https://travis-ci.com/pschiffmann/inject-assets-builder.dart)

This package contains a [builder][build] that makes it possible for a package to access files from packages depending on it.

_The build package uses the syntax `pkg|lib/foo.txt` to refer to the file `foo.txt` in the `lib/` directory of package `pkg`. In this document, I'll use the same syntax for all references to files to avoid ambiguity._

# Example use case

_I'll use this example to illustrate how the builder works, but the injection mechanism is not limited to SASS files, as explained below. In this document, I'll refer to a package that is used as a dependency as `dep`, and to a package consuming `dep` and injecting assets into it as `app`._

I work on a package that contains Angular components, and a couple of web apps that use these components. Each app has a different design, so I need to set some CSS properties of the components from within the app packages. The component styles are compiled from SASS, so the most convenient solution (for a consumer of `dep`) would be if `dep` read these values from a file in `app`. I want that file to be `app|lib/_variables.scss`.

`dep` can't simply import a file from `app`, because SASS import paths must be statically known, and `dep` could be used by multiple apps. That's where this builder comes into play.

This package contains a builder `inject_scss_files` that looks for a provisional `dep|lib/_variables.default.scss` file and creates the final `dep|lib/_variables.scss` file. The contents of `dep|lib/_variables.scss` are copied from `app|lib/_variables.scss`, but the source file is configurable in the build configuration. This way, a package `app2` could set `app2|lib/_variables.scss` as the source.

Now, components in `dep` can use the statically known import path `dep|lib/_variables.scss`, but will access the file contents from `app` at build time.

# Injecting SASS files

These are all the required steps to implement this use case.
In `dep`, add this package to the dependencies. Also add a dependency on [build_config][build config] to ensure compatibility with consumers of your package.
Then, create a `dep|build.yaml` file with the following content:

```yaml
targets:
  # When a package depending on `dep` is built, this build target is
  # automatically built too.
  $default:
    builders:
      inject_assets_builder|inject_scss_files:
        enabled: true
```

In `app|build.yaml`, specify which assets should be injected for the `.default` assets:

```yaml
global_options:
  inject_assets_builder|inject_scss_files:
    options:
      asset_overrides:
        'dep|lib/_variables.default.scss': 'app|lib/_variables.scss'
```

If you don't specify a source for a `.default` asset, the asset itself will be used as the final file. This means that a consumer doesn't have to configure anything if they are satisfied with the default contents.

_Side note on SASS files:  `app|lib/_variables.scss` can import the default file with `@import 'package:dep/variables.default';`. Then, you only need to assign those variables you actually want to change._

# Injecting assets with other extensions

The Dart build system requires that builders statically declare all the file extensions they run on. This makes it impossible to process all `.default.*` files in a single builder. If you need to inject assets that don't end in `.scss` or `.sass`, you need to declare your own builder. You can use `inject_asset_builder|build.yaml` as a template; you should only need to change the `build_extensions` and `file_extensions` configuration and the builder name. Then reference it with `$yourPackage|$builderName` in `builders` and `global_options`.

[build]: https://pub.dartlang.org/packages/build
[build config]: https://pub.dartlang.org/packages/build_config
