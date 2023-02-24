"""This module contains unit tests for rust_proto_library and its aspect."""

load("@bazel_skylib//lib:unittest.bzl", "analysistest")
load(":defs.bzl", "ActionsInfo", "attach_aspect")

def _find_action_with_mnemonic(actions, mnemonic):
    action = [a for a in actions if a.mnemonic == mnemonic]
    if not action:
        fail("Couldn't find action with mnemonic {} among {}".format(mnemonic, actions))
    return action[0]

def _find_rust_lib_input(inputs, target_name):
    inputs = inputs.to_list()
    input = [i for i in inputs if i.basename.startswith("lib" + target_name) and
                                  (i.basename.endswith(".rlib") or i.basename.endswith(".rmeta"))]
    if not input:
        fail("Couldn't find lib{}-<hash>.rlib or lib{}-<hash>.rmeta among {}".format(
            target_name,
            target_name,
            [i.basename for i in inputs],
        ))
    return input[0]

def _rust_compilation_action_has_runtime_as_input_test_impl(ctx):
    env = analysistest.begin(ctx)
    target_under_test = analysistest.target_under_test(env)
    actions = target_under_test[ActionsInfo].actions
    rustc_action = _find_action_with_mnemonic(actions, "Rustc")
    _find_rust_lib_input(rustc_action.inputs, "protobuf")

    return analysistest.end(env)

rust_compilation_action_has_runtime_as_input_test = analysistest.make(
    _rust_compilation_action_has_runtime_as_input_test_impl,
)

def _test_rust_compilation_action_has_runtime_as_input():
    native.proto_library(name = "some_proto", srcs = ["some_proto.proto"])
    attach_aspect(name = "some_proto_with_aspect", dep = ":some_proto")

    rust_compilation_action_has_runtime_as_input_test(
        name = "rust_compilation_action_has_runtime_as_input_test",
        target_under_test = ":some_proto_with_aspect",
        # TODO(b/270274576): Enable testing on arm once we have a Rust Arm toolchain.
        tags = ["not_build:arm"],
    )

def rust_proto_library_unit_test(name):
    """Sets up rust_proto_library_unit_test test suite.

    Args:
      name: name of the test suite"""
    _test_rust_compilation_action_has_runtime_as_input()

    native.test_suite(
        name = name,
        tests = [
            ":rust_compilation_action_has_runtime_as_input_test",
        ],
    )
