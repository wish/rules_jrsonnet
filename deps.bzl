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

    http_file(
        name = "jsonnetfmt_macos",
        sha256 = "c0433d613314834822f534c76e8b3d09e9373e4a49ce445f1c1f19c99b47f918",
        urls = ["https://github.com/wish/rules_jrsonnet/releases/download/v0.5.0/jsonnetfmt_darwin_x86"],
        executable = True
    )

    http_file(
        name = "jsonnetfmt_linux_x86",
        sha256 = "16cc4bd674329c5b6bcce41dbc7df2864021071353c0bfaf7dc8fa1da8e437f8",
        urls = ["https://github.com/wish/rules_jrsonnet/releases/download/v0.5.0/jsonnetfmt_linux_x86"],
        executable = True
    )
    
    http_file(
        name = "jsonnetfmt_linux_arm64",
        sha256 = "3d25cafa90b66c0350208bbc6a131cb387675ef7108a777f18b31be45cc2b52d",
        urls = ["https://github.com/wish/rules_jrsonnet/releases/download/v0.5.0/jsonnetfmt_linux_arm64"],
        executable = True
    )
    