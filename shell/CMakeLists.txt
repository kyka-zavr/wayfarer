cmake_minimum_required(VERSION 3.21)

project(wayfarer-shell
    VERSION 0.1.0
    DESCRIPTION "Wayfarer desktop shell frontend"
    LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

find_package(Qt6 6.5 REQUIRED COMPONENTS Core Gui Quick Qml)

# ---------------------------------------------------------------------------
# Rust core (wf-core) -> wf_core.dll
#
# Cargo is driven directly instead of via Corrosion: one less dependency, and
# `cargo build -p wf-core` works standalone for people who only touch the core.
# ---------------------------------------------------------------------------
set(WF_ROOT     "${CMAKE_CURRENT_SOURCE_DIR}/..")
set(WF_CORE_DIR "${WF_ROOT}/crates/wf-core")
set(WF_CARGO_TARGET_DIR "${CMAKE_BINARY_DIR}/rust")
set(WF_CORE_DLL "${WF_CARGO_TARGET_DIR}/release/wf_core.dll")
set(WF_CORE_IMPLIB "${WF_CARGO_TARGET_DIR}/release/wf_core.dll.lib")

file(GLOB_RECURSE WF_RUST_SOURCES CONFIGURE_DEPENDS
    "${WF_CORE_DIR}/src/*.rs"
    "${WF_CORE_DIR}/Cargo.toml")
list(APPEND WF_RUST_SOURCES "${WF_ROOT}/Cargo.toml")

add_custom_command(
    OUTPUT "${WF_CORE_DLL}"
    COMMAND ${CMAKE_COMMAND} -E env "CARGO_TARGET_DIR=${WF_CARGO_TARGET_DIR}"
            cargo build --release --manifest-path "${WF_ROOT}/Cargo.toml" -p wf-core
    DEPENDS ${WF_RUST_SOURCES}
    COMMENT "cargo build: wf-core (release)"
    VERBATIM)

add_custom_target(wf-core ALL DEPENDS "${WF_CORE_DLL}")

add_library(wf_core SHARED IMPORTED GLOBAL)
set_target_properties(wf_core PROPERTIES
    IMPORTED_LOCATION "${WF_CORE_DLL}"
    IMPORTED_IMPLIB "${WF_CORE_IMPLIB}"
    INTERFACE_INCLUDE_DIRECTORIES "${WF_CORE_DIR}/include")

# ---------------------------------------------------------------------------
# Frontend
# ---------------------------------------------------------------------------
qt_add_executable(wayfarer-shell
    src/main.cpp
    src/engine.cpp
    src/engine.h
    src/overlay_window.cpp
    src/overlay_window.h
    qml.qrc)

target_compile_definitions(wayfarer-shell PRIVATE
    WF_VERSION_STRING="${PROJECT_VERSION}")

target_link_libraries(wayfarer-shell PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Quick
    Qt6::Qml
    wf_core)

add_dependencies(wayfarer-shell wf-core)

set_target_properties(wayfarer-shell PROPERTIES
    WIN32_EXECUTABLE TRUE
    OUTPUT_NAME "wayfarer-shell")

# The DLL must sit next to the binary at runtime.
add_custom_command(TARGET wayfarer-shell POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${WF_CORE_DLL}" "$<TARGET_FILE_DIR:wayfarer-shell>"
    COMMENT "copy wf_core.dll next to wayfarer-shell"
    VERBATIM)
