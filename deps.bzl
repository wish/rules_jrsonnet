load("@rules_jrsonnet//jrsonnet_toolchain:jrsonnet_toolchain.bzl",register_jrsonnet = "register_toolchain")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_file", "http_archive")

def register_all_toolchains():
    register_jrsonnet()    

def import_dependencies():
    http_file(
        name = "jrsonnet_mac",
        sha256= "9624407b7cc50dd306c1fa5ffb194c5b6ff8be5ed6ed563dd3decefafcba8fa7",
        urls = ["https://github.com/CertainLach/jrsonnet/releases/download/v0.4.2/jrsonnet-darwin-amd64"],
        executable = True
    )

    http_file(
        name = "jrsonnet_linux_amd",
        sha256 = "9650474ca38e53468ccad2cae9e72f2d5752cad800e87bfc45eb51dbc83726c2",
        urls = ["https://github.com/CertainLach/jrsonnet/releases/download/v0.4.2/jrsonnet-linux-gnu-amd64"],
        executable = True
    )

    http_file(
        name = "jrsonnet_linux_arm",
        sha256 = "37fbde607ebf5cf0a354fad5d7d76b9acd519e1a2d235ffe121dd07b683d1412",
        urls = ["https://github.com/CertainLach/jrsonnet/releases/download/v0.4.2/jrsonnet-linux-gnu-aarch64"],
        executable = True
    )

    http_archive(
        name = "jsonnetfmt",
        sha256 = "40347c519fd2cfe26547141776230af9be7ba6c47d15940419b771dc394765dd",
        urls = ["https://github.com/google/go-jsonnet/archive/refs/tags/v0.18.0.zip"],
        strip_prefix = "go-jsonnet-0.18.0"
    )
    