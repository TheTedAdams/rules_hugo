# `rules_hugo`

[![Build Status](https://api.cirrus-ci.com/github/stackb/rules_hugo.svg)](https://cirrus-ci.com/github/stackb/rules_hugo)

<table><tr>
<td><img src="https://raw.githubusercontent.com/bazelbuild/bazel-blog/master/images/bazel-icon.svg" height="120"/></td>
<td><img src="https://raw.githubusercontent.com/gohugoio/hugoDocs/master/static/img/hugo-logo.png" height="120"/></td>
</tr><tr>
<td>Rules</td>
<td>Hugo</td>
</tr></table>

[Bazel](https://bazel.build) rules for building static websites with [Hugo](https://gohugo.io).

## Repository Rules

|                                    Name | Description                         |
| --------------------------------------: | :---------------------------------- |
|     [hugo_repository](#hugo_repository) | Load hugo dependency for this repo. |
| [github_hugo_theme](#github_hugo_theme) | Load a hugo theme from github.      |

## Build Rules

|                      Name | Description           |
| ------------------------: | :-------------------- |
|   [hugo_site](#hugo_site) | Declare a hugo site.  |
| [hugo_theme](#hugo_theme) | Declare a hugo theme. |

## Usage

### Add rules_hugo to your WORKSPACE and add a theme from github

```python
# Update these to latest
RULES_HUGO_COMMIT = "..."
RULES_HUGO_SHA256 = "..."

http_archive(
    name = "build_stack_rules_hugo",
    url = "https://github.com/stackb/rules_hugo/archive/%s.zip" % RULES_HUGO_COMMIT,
    sha256 = RULES_HUGO_SHA256,
    strip_prefix = "rules_hugo-%s" % RULES_HUGO_COMMIT
)

load("@build_stack_rules_hugo//hugo:rules.bzl", "hugo_repository", "github_hugo_theme")

#
# Load hugo binary itself
#
# For whatever version you are loading, you must supply sha_dict sourced from the checksums.txt of the release.
# Optionally, load a specific version of Hugo, with the 'version' argument
hugo_repository(
    name = "hugo",
    version = "0.125.4",
    sha_dict = {
      "hugo_0.125.4_darwin-universal.tar.gz": "faa85ddc69bdfbcd41ce1f369a2ecba5caf261ad0dafa76ee3016e1a05960fab",
      "hugo_0.125.4_linux-amd64.tar.gz": "00dc0674e458560dc7ee3310d1d4adb509208be867d9498d0055fd29e406e251",
      "hugo_0.125.4_windows-amd64.zip": "39196bf2a5afa94078e197a6d97b0a2bc6b76d2ca71838090beb6f2045f17c28",
      "hugo_extended_0.125.4_darwin-universal.tar.gz": "677279b5dd9f8aaf6d010f93895ba5e1180225d9b591172548d5e8dd8c2f1c78",
      "hugo_extended_0.125.4_linux-amd64.tar.gz": "a416f563c6c9cd773dae1a8a7c70596ef4afd45e36436e9c6b7822df56dc4b65",
      "hugo_extended_0.125.4_windows-amd64.zip": "d1f6f3b6ef38bc347d4206f017cc5c7a0a268ffd4c88f57d09376eb32146378c",
    }
)

#
# This makes a filegroup target "@com_github_yihui_hugo_xmin//:files"
# available to your build files
#
github_hugo_theme(
    name = "com_github_yihui_hugo_xmin",
    owner = "yihui",
    repo = "hugo-xmin",
    commit = "c14ca049d0dd60386264ea68c91d8495809cc4c6",
)

#
# This creates a filegroup target from a released archive from GitHub
# this is useful when a theme uses compiled / aggregated sources NOT found
# in a source root.
#
http_archive(
    name = "com_github_thegeeklab_hugo_geekdoc",
    url = "https://github.com/thegeeklab/hugo-geekdoc/releases/download/v0.34.2/hugo-geekdoc.tar.gz",
    sha256 = "7fdd57f7d4450325a778629021c0fff5531dc8475de6c4ec70ab07e9484d400e",
    build_file_content="""
filegroup(
    name = "files",
    srcs = glob(["**"]),
    visibility = ["//visibility:public"]
)
    """
)
```

### Declare a hugo_site with a GitHub repository theme in your BUILD file

```python
load("@build_stack_rules_hugo//hugo:rules.bzl", "hugo_site", "hugo_theme", "hugo_serve")

# Declare a theme 'xmin'.  In this case the `name` and
# `theme_name` are identical, so the `theme_name` could be omitted in this case.
hugo_theme(
    name = "xmin",
    theme_name = "xmin",
    srcs = [
        "@com_github_yihui_hugo_xmin//:files",
    ],
)

# Declare a site. Config file is required.
my_site_name = "basic"

hugo_site(
    name = my_site_name,
    config = "config.toml",
    content = [
        "_index.md",
        "about.md",
    ],
    quiet = False,
    theme = ":xmin",
)

# Run local development server
hugo_serve(
    name = "local_%s" % my_site_name,
    dep = [":%s" % my_site_name],
)

# Tar it up
pkg_tar(
    name = "%s_tar" % my_site_name,
    srcs = [":%s" % my_site_name],
)
```

### Declare a hugo_site with a GitHub released archive theme in your BUILD file

```python
load("@build_stack_rules_hugo//hugo:rules.bzl", "hugo_site", "hugo_theme", "hugo_serve")

hugo_theme(
    name = "hugo_theme_geekdoc",
    theme_name = "hugo-geekdoc",
    srcs = [
        "@com_github_thegeeklab_hugo_geekdoc//:files",
    ],
)

# Note, here we are using the config_dir attribute to support multi-lingual configurations.
hugo_site(
    name = "site_complex",
    config_dir = glob(["config/**"]),
    content = glob(["content/**"]),
    data = glob(["data/**"]),
    quiet = False,
    theme = ":hugo_theme_geekdoc",
)

# Run local development server
hugo_serve(
    name = "serve",
    dep = [":site_complex"],
)
```

### Previewing the site

Execute the following command:

```shell
bazel run //site_complex:serve
```

Then open your browser: [here](http://localhost:1313)

### Build the site

The `hugo_site` target emits the output in the `bazel-bin` directory.

```sh
$ bazel build :basic
[...]
Target //:basic up-to-date:
  bazel-bin/basic
[...]
```

```sh
$ tree bazel-bin/basic
bazel-bin/basic
├── 404.html
├── about
│   └── index.html
[...]
```

The `pkg_tar` target emits a `%{name}_tar.tar` file containing all the Hugo output files.

```sh
$ bazel build :basic_tar
[...]
Target //:basic up-to-date:
  bazel-bin/basic_tar.tar
```

## End

See source code for details about additional rule attributes / parameters.
