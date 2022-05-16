

def _jrsonnet_toolchain_impl(ctx):

    _jrsonnet_binary=ctx.executable.jrsonnet

    return [platform_common.ToolchainInfo(
        binary = _jrsonnet_binary,
        path = _jrsonnet_binary.path
    )]

jrsonnet_toolchain = rule(
    _jrsonnet_toolchain_impl,
    attrs = {
        "jrsonnet":attr.label(
            doc = "jrsonnet binary",
            executable = True,
            mandatory = True,
            allow_single_file = True,
            cfg = "exec"
        )
    }
)


def define_toolchains():
    jrsonnet_toolchain(
        name = "jrsonnet_mac",
        jrsonnet = "@jrsonnet_mac//file",
        visibility = ["//visibility:public"]
    )
    native.toolchain(
        name = "jrsonnet_mac_toolchain",
        target_compatible_with = [
            "@platforms//os:macos"
        ],
        toolchain = ":jrsonnet_mac",
        toolchain_type = "@rules_jrsonnet//jrsonnet_toolchain:toolchain",
        visibility = ["//visibility:public"]
    )

    jrsonnet_toolchain(
        name = "jrsonnet_linux_amd",
        jrsonnet = "@jrsonnet_linux_amd//file",
        visibility = ["//visibility:public"]
    )
    native.toolchain(
        name = "jrsonnet_linux_amd_toolchain",
        target_compatible_with = [
            "@platforms//os:linux",
            "@platforms//cpu:x86_64"
        ],
        toolchain = ":jrsonnet_linux_amd",
        toolchain_type = "@rules_jrsonnet//jrsonnet_toolchain:toolchain",
        visibility = ["//visibility:public"]
    )

    jrsonnet_toolchain(
        name = "jrsonnet_linux_arm64",
        jrsonnet = "@jrsonnet_linux_arm//file",
        visibility = ["//visibility:public"]
    )

    native.toolchain(
        name = "jrsonnet_linux_arm_toolchain",
        exec_compatible_with = [
            "@platforms//os:linux",
            "@platforms//cpu:arm64"
        ],
        toolchain = ":jrsonnet_linux_arm",
        toolchain_type = "@rules_jrsonnet//jrsonnet_toolchain:toolchain",
        visibility = ["//visibility:public"]
    )

def register_toolchain():
    native.register_toolchains("@rules_jrsonnet//jrsonnet_toolchain:jrsonnet_mac_toolchain")
    native.register_toolchains("@rules_jrsonnet//jrsonnet_toolchain:jrsonnet_linux_amd_toolchain")
    native.register_toolchains("@rules_jrsonnet//jrsonnet_toolchain:jrsonnet_linux_arm_toolchain")