package(default_visibility = ["//visibility:public"])

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_file", "http_archive")

exports_files(["jsonnet.bzl"])

py_binary(
    name = "stamper",
    srcs = ["stamper.py"],
    main = "stamper.py",
    visibility = ["//visibility:public"],
)


platform(
    name = "mac_os",
    constraint_values=[
        "@platforms//os:macos",
    ]
)
