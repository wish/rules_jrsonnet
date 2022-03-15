package(default_visibility = ["//visibility:public"])

exports_files(["jsonnet.bzl"])

py_binary(
    name = "stamper",
    srcs = ["stamper.py"],
    main = "stamper.py",
    visibility = ["//visibility:public"],
)

config_setting(
    name = "docker",
    define_values = {
        "platform": "docker",
    },
)

config_setting(
    name = "port_rust",
    define_values = {
        "jsonnet_port": "rust",
    },
)

alias(
    name = "jsonnet_tool",
    actual = select({
        "//jsonnet:docker": "@jsonnet_docker//file",
        "//conditions:default": "@jrsonnet_macos//file"
    }),
)