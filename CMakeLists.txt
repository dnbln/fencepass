cmake_minimum_required(VERSION 3.20)
project(fence-insertion-pass)

set(LLVM_INSTALL_DIR "" CACHE PATH "LLVM installation directory")

list(APPEND CMAKE_PREFIX_PATH "${LLVM_INSTALL_DIR}/lib/cmake/llvm/")

find_package(LLVM CONFIG)
if("${LLVM_VERSION_MAJOR}" VERSION_LESS 20)
  message(FATAL_ERROR "Found LLVM ${LLVM_VERSION_MAJOR}, but need LLVM 20 or above")
endif()

include_directories(SYSTEM ${LLVM_INCLUDE_DIRS})
set(CMAKE_CXX_STANDARD 17 CACHE STRING "")

if(NOT LLVM_ENABLE_RTTI)
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fno-rtti")
endif()

add_library(FencePass SHARED FencePass.cpp)
add_library(FencePassBaselineNaive SHARED FencePassBaselineNaive.cpp)

# Allow undefined symbols in shared objects on Darwin (this is the default
# behaviour on Linux)
target_link_libraries(FencePass
  "$<$<PLATFORM_ID:Darwin>:-undefined dynamic_lookup>")
target_link_libraries(FencePassBaselineNaive
  "$<$<PLATFORM_ID:Darwin>:-undefined dynamic_lookup>")
