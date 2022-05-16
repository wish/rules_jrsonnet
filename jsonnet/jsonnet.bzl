# Copyright 2015 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive", "http_file")

"""Jsonnet Rules

These are build rules for working with [Jsonnet][jsonnet] files with Bazel.

[jsonnet]: http://google.github.io/jsonnet/doc/

## Setup

To use the Jsonnet rules, add the following to your `WORKSPACE` file to add the
external repositories for Jsonnet:


"""

_JSONNET_FILETYPE = [
    ".jsonnet",
    ".libsonnet",
    ".json",
]

_STRING_STYLE = [
    "d",
    "s",
    "l"
]

def _add_prefix_to_imports(label, imports):
    imports_prefix = ""
    if label.workspace_root:
        imports_prefix += label.workspace_root + "/"
    if label.package:
        imports_prefix += label.package + "/"
    return [imports_prefix + im for im in imports]

def _setup_deps(deps):
    """Collects source files and import flags of transitive dependencies.

    Args:
      deps: List of deps labels from ctx.attr.deps.

    Returns:
      Returns a struct containing the following fields:
        transitive_sources: List of Files containing sources of transitive
            dependencies
        imports: List of Strings containing import flags set by transitive
            dependency targets.
    """
    transitive_sources = []
    imports = []
    for dep in deps:
        transitive_sources.append(dep.transitive_jsonnet_files)
        imports.append(dep.imports)

    return struct(
        imports = depset(transitive = imports),
        transitive_sources = depset(transitive = transitive_sources, order = "postorder"),
    )

def _jsonnet_library_impl(ctx):
    """Implementation of the jsonnet_library rule."""
    depinfo = _setup_deps(ctx.attr.deps)
    sources = depset(ctx.files.srcs, transitive = [depinfo.transitive_sources])
    imports = depset(_add_prefix_to_imports(ctx.label, ctx.attr.imports), transitive = [depinfo.imports])
    transitive_data = depset(
        transitive = [dep.data_runfiles.files for dep in ctx.attr.deps],
    )

    return struct(
        files = depset(),
        imports = imports,
        runfiles = ctx.runfiles(
            transitive_files = transitive_data,
            collect_data = True,
        ),
        transitive_jsonnet_files = sources,
    )

def _quote(s):
    return '"' + s.replace('"', '\\"') + '"'

def _stamp_resolve(ctx, string, output):
    stamps = [ctx.info_file, ctx.version_file]
    stamp_args = [
        "--stamp-info-file=%s" % sf.path
        for sf in stamps
    ]
    ctx.actions.run(
        executable = ctx.executable._stamper,
        arguments = [
            "--format=%s" % string,
            "--output=%s" % output.path,
        ] + stamp_args,
        inputs = stamps,
        tools = [ctx.executable._stamper],
        outputs = [output],
        mnemonic = "Stamp",
    )

def _make_resolve(ctx, val):
    if val[0:2] == "$(" and val[-1] == ")":
        return ctx.var[val[2:-1]]
    else:
        return val

def _make_stamp_resolve(ext_vars, ctx, relative = True):
    results = {}
    stamp_inputs = []
    for key, val in ext_vars.items():
        # Check for make variables
        val = _make_resolve(ctx, val)

        # Check for stamp variables
        if ctx.attr.stamp_keys:
            if key in ctx.attr.stamp_keys:
                stamp_file = ctx.actions.declare_file(ctx.label.name + ".jsonnet_" + key)
                _stamp_resolve(ctx, val, stamp_file)
                if relative:
                    val = "$(cat %s)" % stamp_file.short_path
                else:
                    val = "$(cat %s)" % stamp_file.path
                stamp_inputs += [stamp_file]

        results[key] = val

    return results, stamp_inputs

def _jsonnet_to_json_impl(ctx):
    """Implementation of the jsonnet_to_json rule."""

    if ctx.attr.vars:
        print("'vars' attribute is deprecated, please use 'ext_strs'.")
    if ctx.attr.code_vars:
        print("'code_vars' attribute is deprecated, please use 'ext_code'.")

    depinfo = _setup_deps(ctx.attr.deps)
    path=ctx.toolchains["@rules_jrsonnet//jrsonnet_toolchain:toolchain"].path
    jsonnet_ext_strs = ctx.attr.ext_strs or ctx.attr.vars
    jsonnet_ext_str_envs = ctx.attr.ext_str_envs
    jsonnet_ext_code = ctx.attr.ext_code or ctx.attr.code_vars
    jsonnet_ext_code_envs = ctx.attr.ext_code_envs
    jsonnet_ext_str_files = ctx.files.ext_str_files
    jsonnet_ext_str_file_vars = ctx.attr.ext_str_file_vars
    jsonnet_ext_code_files = ctx.files.ext_code_files
    jsonnet_ext_code_file_vars = ctx.attr.ext_code_file_vars
    jsonnet_tla_strs = ctx.attr.tla_strs
    jsonnet_tla_str_envs = ctx.attr.tla_str_envs
    jsonnet_tla_code = ctx.attr.tla_code
    jsonnet_tla_code_envs = ctx.attr.tla_code_envs
    jsonnet_tla_str_files = ctx.attr.tla_str_files
    jsonnet_tla_code_files = ctx.attr.tla_code_files

    jsonnet_ext_strs, strs_stamp_inputs = _make_stamp_resolve(ctx.attr.ext_strs, ctx, False)
    jsonnet_ext_code, code_stamp_inputs = _make_stamp_resolve(ctx.attr.ext_code, ctx, False)
    jsonnet_tla_strs, tla_strs_stamp_inputs = _make_stamp_resolve(ctx.attr.tla_strs, ctx, False)
    jsonnet_tla_code, tla_code_stamp_inputs = _make_stamp_resolve(ctx.attr.tla_code, ctx, False)
    stamp_inputs = strs_stamp_inputs + code_stamp_inputs + tla_strs_stamp_inputs + tla_code_stamp_inputs

    if ctx.attr.stamp_keys and not stamp_inputs:
        fail("Stamping requested but found no stamp variable to resolve for.")

    other_args = ctx.attr.extra_args + (["-y"] if ctx.attr.yaml_stream else [])

    search_path = _add_prefix_to_imports(ctx.label,ctx.attr.imports) + depinfo.imports.to_list() + [ctx.genfiles_dir.path, ctx.bin_dir.path, "."]
    path_cmd_var = ":".join(search_path)
    command = (
        [
            "set -e;",
            path,
        ] + ["-J ."] + other_args +
        ["--ext-str %s=%s" %
         (_quote(key), _quote(val)) for key, val in jsonnet_ext_strs.items()] +
        ["--ext-str '%s'" %
         ext_str_env for ext_str_env in jsonnet_ext_str_envs] +
        ["--ext-code %s=%s" %
         (_quote(key), _quote(val)) for key, val in jsonnet_ext_code.items()] +
        ["--ext-code %s" %
         ext_code_env for ext_code_env in jsonnet_ext_code_envs] +
        ["--ext-str-file %s=%s" %
         (var, jfile.path) for var, jfile in zip(jsonnet_ext_str_file_vars, jsonnet_ext_str_files)] +
        ["--ext-code-file %s=%s" %
         (var, jfile.path) for var, jfile in zip(jsonnet_ext_code_file_vars, jsonnet_ext_code_files)] +
        ["--tla-str %s=%s" %
         (_quote(key), _quote(val)) for key, val in jsonnet_tla_strs.items()] +
        ["--tla-str '%s'" %
         tla_str_env for tla_str_env in jsonnet_tla_str_envs] +
        ["--tla-code %s=%s" %
         (_quote(key), _quote(val)) for key, val in jsonnet_tla_code.items()] +
        ["--tla-code %s" %
         tla_code_env for tla_code_env in jsonnet_tla_code_envs] +
        ["--tla-str-file %s=%s" %
         (var, jfile.files.to_list()[0].path) for jfile, var in jsonnet_tla_str_files.items()] +
        ["--tla-code-file %s=%s" %
         (var, jfile.files.to_list()[0].path) for jfile, var in jsonnet_tla_code_files.items()]
    )

    outputs = []

    # If multiple_outputs is set to true, then jsonnet will be invoked with the
    # -m flag for multiple outputs. Otherwise, jsonnet will write the resulting
    # JSON to stdout, which is redirected into a single JSON output file.
    if len(ctx.attr.outs) > 1 or ctx.attr.multiple_outputs:
        outputs += ctx.outputs.outs
        command += ["-m", ctx.outputs.outs[0].dirname, ctx.file.src.path]
    elif len(ctx.attr.outs) > 1:
        fail("Only one file can be specified in outs if multiple_outputs is " +
             "not set.")
    else:
        compiled_json = ctx.outputs.outs[0]
        outputs += [compiled_json]
        command += ["-o", compiled_json.path, ctx.file.src.path]

    transitive_data = depset(transitive = [dep.data_runfiles.files for dep in ctx.attr.deps] +
                                          [l.files for l in jsonnet_tla_code_files.keys()] +
                                          [l.files for l in jsonnet_tla_str_files.keys()])
    # NB(sparkprime): (1) transitive_data is never used, since runfiles is only
    # used when .files is pulled from it.  (2) This makes sense - jsonnet does
    # not need transitive dependencies to be passed on the commandline. It
    # needs the -J but that is handled separately.

    files = jsonnet_ext_str_files + jsonnet_ext_code_files

    runfiles = ctx.runfiles(
        collect_data = True,
        files = files,
        transitive_files = transitive_data,
    )

    compile_inputs = (
        [ctx.file.src] +
        runfiles.files.to_list() +
        depinfo.transitive_sources.to_list()
    )


    ctx.actions.run_shell(
        tools = [ctx.toolchains["@rules_jrsonnet//jrsonnet_toolchain:toolchain"].binary],
        inputs = compile_inputs + stamp_inputs,
        outputs = outputs,
        mnemonic = "Jsonnet",
        command = " ".join(command),
        use_default_shell_env = True,
        progress_message = "Compiling Jsonnet to JSON for " + ctx.label.name,
    )

_EXIT_CODE_COMPARE_COMMAND = """
EXIT_CODE=$?
EXPECTED_EXIT_CODE=%d
if [ $EXIT_CODE -ne $EXPECTED_EXIT_CODE ] ; then
  echo "FAIL (exit code): %s"
  echo "Expected: $EXPECTED_EXIT_CODE"
  echo "Actual: $EXIT_CODE"
  if [ %s = true ]; then
    echo "Output: $OUTPUT"
  fi
  exit 1
fi
"""

_DIFF_COMMAND = """
GOLDEN=$(%s %s)
if [ "$OUTPUT" != "$GOLDEN" ]; then
  echo "FAIL (output mismatch): %s"
  echo "Diff:"
  diff <(echo "$GOLDEN") <(echo "$OUTPUT")
  if [ %s = true ]; then
    echo "Expected: $GOLDEN"
    echo "Actual: $OUTPUT"
  fi
  exit 1
fi
"""

_REGEX_DIFF_COMMAND = """
GOLDEN_REGEX=$(%s %s)
if [[ ! "$OUTPUT" =~ $GOLDEN_REGEX ]]; then
  echo "FAIL (regex mismatch): %s"
  if [ %s = true ]; then
    echo "Output: $OUTPUT"
  fi
  exit 1
fi
"""

_jsonnet_common_attrs = {
    "data": attr.label_list(
        allow_files = True,
    ),
    "imports": attr.string_list(),
    "deps": attr.label_list(
        providers = ["transitive_jsonnet_files"],
        allow_files = False,
    ),
}

_jsonnet_library_attrs = {
    "srcs": attr.label_list(allow_files = _JSONNET_FILETYPE),
}

jsonnet_library = rule(
    _jsonnet_library_impl,
    attrs = dict(_jsonnet_library_attrs.items() +
                 _jsonnet_common_attrs.items()),
)

"""Creates a logical set of Jsonnet files.

Args:
    name: A unique name for this rule.
    srcs: List of `.jsonnet` files that comprises this Jsonnet library.
    deps: List of targets that are required by the `srcs` Jsonnet files.
    imports: List of import `-J` flags to be passed to the `jsonnet` compiler.

Example:
  Suppose you have the following directory structure:

  ```
  [workspace]/
      WORKSPACE
      configs/
          BUILD
          backend.jsonnet
          frontend.jsonnet
  ```

  You can use the `jsonnet_library` rule to build a collection of `.jsonnet`
  files that can be imported by other `.jsonnet` files as dependencies:

  `configs/BUILD`:

  ```python
  load("@io_bazel_rules_jsonnet//jsonnet:jsonnet.bzl", "jsonnet_library")

  jsonnet_library(
      name = "configs",
      srcs = [
          "backend.jsonnet",
          "frontend.jsonnet",
      ],
  )
  ```
"""

_jsonnet_compile_attrs = {
    "src": attr.label(allow_single_file = _JSONNET_FILETYPE),
    "code_vars": attr.string_dict(),  # Deprecated (use 'ext_code').
    "ext_code": attr.string_dict(),
    "ext_code_envs": attr.string_list(),
    "ext_code_file_vars": attr.string_list(),
    "ext_code_files": attr.label_list(
        allow_files = True,
    ),
    "ext_str_envs": attr.string_list(),
    "ext_str_file_vars": attr.string_list(),
    "ext_str_files": attr.label_list(
        allow_files = True,
    ),
    "ext_strs": attr.string_dict(),
    "tla_code": attr.string_dict(),
    "tla_code_envs": attr.string_list(),
    "tla_strs": attr.string_dict(),
    "tla_str_envs": attr.string_list(),
    "tla_str_files": attr.label_keyed_string_dict(allow_files = True),
    "tla_code_files": attr.label_keyed_string_dict(allow_files = True),
    "stamp_keys": attr.string_list(
        default = [],
        mandatory = False,
    ),
    "yaml_stream": attr.bool(
        default = False,
        mandatory = False,
    ),
    "extra_args": attr.string_list(),
    "vars": attr.string_dict(),  # Deprecated (use 'ext_strs').
    "_stamper": attr.label(
        default = Label("//jsonnet:stamper"),
        cfg = "host",
        executable = True,
        allow_files = True,
    ),
}

_jsonnet_to_json_attrs = {
    "outs": attr.output_list(mandatory = True),
    "multiple_outputs": attr.bool(),
}

jsonnet_to_json = rule(
    _jsonnet_to_json_impl,
    attrs = dict(_jsonnet_compile_attrs.items() +
                 _jsonnet_to_json_attrs.items() +
                 _jsonnet_common_attrs.items()),
    toolchains = ["@rules_jrsonnet//jrsonnet_toolchain:toolchain"]
)


_jsonnetfmt_attrs = {
    "jsonnetfmt": attr.label(
        doc = "jsonnetfmt binary",
        cfg = "exec",
        executable = True,
        allow_single_file = True,
        default = Label("@jsonnetfmt//cmd/jsonnetfmt")
    ),
}

JSONNET_FMT_CODE = '''
cd $BUILD_WORKSPACE_DIRECTORY
find . -name '*.jsonnet' | xargs {path} --string-style l -i
find . ! -path './lib/images/*' -name '*.libsonnet' | xargs {path} --string-style l -i
find . -name '_namespace.jsonnet' | xargs {path} -i
'''

# Bazel does not allow modify files in place when executing bazel build, but allows it during bazel run, so this is a workaround hack.
# this rule generates a bash script with the jsonnetfmt code and the path of the jsonnetfmt binary which is compiled by bazel (without needing user install)
# the bash script can then be executed using bazel run to format in place.
def _jsonnetfmt_impl(ctx):
    jsonnetfmt_path = ctx.executable.jsonnetfmt.path

    content = JSONNET_FMT_CODE.format(path = jsonnetfmt_path)
    out = ctx.actions.declare_file("format.sh")
    ctx.actions.write(out,content,is_executable=True)
    return [DefaultInfo(files=depset([out]))]

jsonnetfmt = rule(
    _jsonnetfmt_impl,
    attrs = _jsonnetfmt_attrs
)