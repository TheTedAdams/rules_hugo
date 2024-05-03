load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

HUGO_BUILD_FILE = """    
package(default_visibility = ["//visibility:public"])
exports_files( ["hugo"] )
"""

def _hugo_repository_impl(repository_ctx):
    hugo = "hugo"
    if repository_ctx.attr.extended:
        hugo = "hugo_extended"

    arch_extension = "linux-amd64.tar.gz"

    os_name = repository_ctx.os.name.lower()
    if os_name.startswith("mac os"):
        arch_extension  = "darwin-universal.tar.gz"
    elif os_name.find("windows") != -1:
        arch_extension = "windows-amd64.zip"

    file_name = "{hugo}_{version}_{arch_extension}".format(
        hugo = hugo,
        version = repository_ctx.attr.version,
        arch_extension = arch_extension,
    )
    
    url = "https://github.com/gohugoio/hugo/releases/download/v{version}/{file_name}".format(
        version = repository_ctx.attr.version,
        file_name = file_name,
    )

    repository_ctx.download_and_extract(
        url = url,
        sha256 = repository_ctx.attr.sha_dict.get(file_name),
    )

    repository_ctx.file("BUILD.bazel", HUGO_BUILD_FILE)

hugo_repository = repository_rule(
    _hugo_repository_impl,
    attrs = {
        "version": attr.string(
            default = "0.125.4",
            doc = "The hugo version to use",
        ),
        "extended": attr.bool(
            doc = "Use extended hugo version",
        ),
        "sha_dict": attr.string_dict(
          doc = "A dictionary where the key is a release file name and the value is that file's sha256 value.",
          mandatory = True,
          allow_empty = False,
        ),
    },
)
