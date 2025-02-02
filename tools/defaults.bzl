"""Re-export of some bazel rules with repository-wide defaults."""

load("@npm//@angular/bazel:index.bzl", _ng_module = "ng_module", _ng_package = "ng_package")
load("@build_bazel_rules_nodejs//:index.bzl", _pkg_npm = "pkg_npm")
load("@npm//@bazel/jasmine:index.bzl", _jasmine_node_test = "jasmine_node_test")
load(
    "@npm//@bazel/typescript:index.bzl",
    _ts_library = "ts_library",
)

DEFAULT_TSCONFIG_BUILD = "//modules:bazel-tsconfig-build.json"
DEFAULT_TSCONFIG_TEST = "//modules:bazel-tsconfig-test"
DEFAULT_TS_TYPINGS = "@npm//typescript:typescript__typings"

def _getDefaultTsConfig(testonly):
    if testonly:
        return DEFAULT_TSCONFIG_TEST
    else:
        return DEFAULT_TSCONFIG_BUILD

def ts_library(tsconfig = None, deps = [], testonly = False, **kwargs):
    local_deps = ["@npm//tslib", "@npm//@types/node", DEFAULT_TS_TYPINGS] + deps
    if not tsconfig:
        tsconfig = _getDefaultTsConfig(testonly)

    _ts_library(
        tsconfig = tsconfig,
        testonly = testonly,
        deps = local_deps,
        **kwargs
    )

NG_VERSION = "^12.0.0-rc.1"
RXJS_VERSION = "^6.5.5"
HAPI_VERSION = "^18.4.0"
EXPRESS_VERSION = "^4.15.2"
EXPRESS_TYPES_VERSION = "^4.17.0"
DEVKIT_CORE_VERSION = "^12.0.0-rc.1"
DEVKIT_ARCHITECT_VERSION = "^0.1200.0-rc.1"
DEVKIT_BUILD_ANGULAR_VERSION = "^12.0.0-rc.1"
TSLIB_VERSION = "^2.1.0"

NGUNIVERSAL_SCOPED_PACKAGES = ["@nguniversal/%s" % p for p in [
    "aspnetcore-engine",
    "builders",
    "common",
    "express-engine",
    "hapi-engine",
]]

PKG_GROUP_REPLACEMENTS = {
    "\"NG_UPDATE_PACKAGE_GROUP\"": """[
      %s
    ]""" % ",\n      ".join(["\"%s\"" % s for s in NGUNIVERSAL_SCOPED_PACKAGES]),
    "EXPRESS_VERSION": EXPRESS_VERSION,
    "EXPRESS_TYPES_VERSION": EXPRESS_TYPES_VERSION,
    "HAPI_VERSION": HAPI_VERSION,
    "NG_VERSION": NG_VERSION,
    "RXJS_VERSION": RXJS_VERSION,
    "DEVKIT_CORE_VERSION": DEVKIT_CORE_VERSION,
    "DEVKIT_ARCHITECT_VERSION": DEVKIT_ARCHITECT_VERSION,
    "DEVKIT_BUILD_ANGULAR_VERSION": DEVKIT_BUILD_ANGULAR_VERSION,
    "TSLIB_VERSION": TSLIB_VERSION,
}

GLOBALS = {
    "@angular/animations": "ng.animations",
    "@angular/common": "ng.common",
    "@angular/common/http": "ng.common.http",
    "@angular/compiler": "ng.compiler",
    "@angular/core": "ng.core",
    "@angular/http": "ng.http",
    "@angular/platform-browser": "ng.platformBrowser",
    "@angular/platform-browser-dynamic": "ng.platformBrowserDynamic",
    "@angular/platform-server": "ng.platformServer",
    "@nguniversal/common": "nguniversal.common",
    "@nguniversal/common/engine": "nguniversal.common.engine",
    "@nguniversal/common/clover": "nguniversal.common.domRenderer",
    "@nguniversal/common/clover/server": "nguniversal.common.domRenderer.server",
    "@nguniversal/aspnetcore-engine/tokens": "nguniversal.aspnetcoreEngine.tokens",
    "@nguniversal/express-engine/tokens": "nguniversal.expressEngine.tokens",
    "@nguniversal/hapi-engine/tokens": "nguniversal.hapiEngine.tokens",
    "express": "express",
    "fs": "fs",
    "domino": "domino",
    "jsdom": "jsdom",
    "url": "url",
    "net": "net",
    "@hapi/hapi": "hapi.hapi",
    "rxjs": "rxjs",
    "rxjs/operators": "rxjs.operators",
}

def ng_module(name, tsconfig = None, testonly = False, deps = [], bundle_dts = True, **kwargs):
    deps = deps + ["@npm//tslib", "@npm//@types/node", DEFAULT_TS_TYPINGS]
    if not tsconfig:
        tsconfig = _getDefaultTsConfig(testonly)
    _ng_module(
        name = name,
        flat_module_out_file = name,
        bundle_dts = bundle_dts,
        tsconfig = tsconfig,
        testonly = testonly,
        deps = deps,
        **kwargs
    )

def jasmine_node_test(deps = [], **kwargs):
    local_deps = [
        "@npm//source-map-support",
    ] + deps

    _jasmine_node_test(
        deps = local_deps,
        templated_args = ["--bazel_patch_module_resolver"],
        configuration_env_vars = ["compile"],
        **kwargs
    )

def ng_test_library(deps = [], tsconfig = None, **kwargs):
    local_deps = [
        # We declare "@angular/core" as default dependencies because
        # all Angular component unit tests use the `TestBed` and `Component` exports.
        "@npm//@angular/core",
        "@npm//@types/jasmine",
    ] + deps

    if not tsconfig:
        tsconfig = _getDefaultTsConfig(1)

    ts_library(
        testonly = 1,
        tsconfig = tsconfig,
        deps = local_deps,
        **kwargs
    )

def ng_package(globals = {}, deps = [], **kwargs):
    globals = dict(globals, **GLOBALS)
    deps = deps + [
        "@npm//tslib",
    ]

    common_substitutions = dict(kwargs.pop("substitutions", {}), **PKG_GROUP_REPLACEMENTS)
    substitutions = dict(common_substitutions, **{
        "0.0.0-PLACEHOLDER": "0.0.0",
    })
    stamped_substitutions = dict(common_substitutions, **{
        "0.0.0-PLACEHOLDER": "{BUILD_SCM_VERSION}",
    })

    _ng_package(
        globals = globals,
        deps = deps,
        substitutions = select({
            "//:stamp": stamped_substitutions,
            "//conditions:default": substitutions,
        }),
        **kwargs
    )

def pkg_npm(name, **kwargs):
    common_substitutions = dict(kwargs.pop("substitutions", {}), **PKG_GROUP_REPLACEMENTS)
    substitutions = dict(common_substitutions, **{
        "0.0.0-PLACEHOLDER": "0.0.0",
    })
    stamped_substitutions = dict(common_substitutions, **{
        "0.0.0-PLACEHOLDER": "{BUILD_SCM_VERSION}",
    })

    _pkg_npm(
        name = name,
        substitutions = select({
            "//:stamp": stamped_substitutions,
            "//conditions:default": substitutions,
        }),
        **kwargs
    )
