cmake_minimum_required(VERSION 2.8.6)

project(brieflz C)

include(CheckCCompilerFlag)
include(CTest)

# If we are being built as part of another project, we don't want to
# build shared libraries, install headers, etc.  We'll use a variable
# to indicate whether or not we are in bundled mode, so projects which
# use CMake >= 2.8.11 and bundle this project can simply do something
# like:
#
#   set(BRIEFLZ_BUNDLED_MODE ON)
#   add_subdirectory(brieflz)
#
#   ...
#
#   target_link_libraries(your_target brieflz)
#
# And everything should simply work, including adding any relevant
# compiler/linker flags.
#
# If you would like to have CTest run BriefLZ's unit tests, just add
# the following line before calling add_subdirectory():
#
#   set(BRIEFLZ_TEST_ENABLE TRUE)
#
# You can also optionally provide a prefix for the test name(s) if you wish:
#
#   set(BRIEFLZ_TEST_PREFIX "/3rd-party/brieflz/")
#
# If you're stuck with CMake < 2.8.11, you'll need to add the relevant
# compiler flags manually:
#
#   include_directories(${BRIEFLZ_INCLUDE_DIRS})
#   add_definitions(${BRIEFLZ_DEFINITIONS})
mark_as_advanced(
  BRIEFLZ_BUNDLED_MODE
  BRIEFLZ_TEST_ENABLE
  BRIEFLZ_TEST_PREFIX
)

# Library version
#
# This should be incremented with every release.  See semver.org.
set(BRIEFLZ_VERSION_MAJOR    1)
set(BRIEFLZ_VERSION_MINOR    1)
set(BRIEFLZ_VERSION_REVISION 0)

# ABI version
#
# Rules from § 11.4: Library Versioning of the autobook
# https://www.sourceware.org/autobook/autobook/autobook_61.html
#
# 1) If you have changed any of the sources for this library, the
#    revision number must be incremented. This is a new revision of
#    the current interface.
# 2) If the interface has changed, then current must be incremented,
#    and revision reset to ‘0’. This is the first revision of a new
#    interface.
# 3) If the new interface is a superset of the previous interface
#    (that is, if the previous interface has not been broken by the
#    changes in this new release), then age must be incremented. This
#    release is backwards compatible with the previous release.
# 4) If the new interface has removed elements with respect to the
#    previous interface, then you have broken backward compatibility
#    and age must be reset to ‘0’. This release has a new, but
#    backwards incompatible interface.
#
# Conveniently, this also matches semantic versioning for the most
# part (API changes are a bit more complicated since we should change
# the library and pkg-config names and *can* reset these to whatever
# we want, but we don't *have* to).
set(BRIEFLZ_SOVERSION_CURRENT  ${BRIEFLZ_VERSION_MAJOR})
set(BRIEFLZ_SOVERSION_REVISION ${BRIEFLZ_VERSION_MINOR})
set(BRIEFLZ_SOVERSION_AGE      ${BRIEFLZ_VERSION_REVISION})

mark_as_advanced(
  BRIEFLZ_VERSION_MAJOR BRIEFLZ_VERSION_MINOR BRIEFLZ_VERSION_REVISION
  BRIEFLZ_SOVERSION_CURRENT BRIEFLZ_SOVERSION_REVISION BRIEFLZ_SOVERSION_AGE
)

# Add flags that compiler accepts to var
function(_add_c_compiler_flags var)
  foreach(flag ${ARGN})
    string(REGEX REPLACE "[^a-zA-Z0-9]+" "_" flag_var "CFLAG_${flag}")
    check_c_compiler_flag("${flag}" ${flag_var})
    if(${flag_var})
      set(${var} "${${var}} ${flag}")
    endif()
  endforeach()
  set(${var} "${${var}}" PARENT_SCOPE)
endfunction()

if(NOT BRIEFLZ_BUNDLED_MODE)
  option(BUILD_SHARED_LIBS "Build shared libraries" OFF)
  option(BUILD_COVERAGE "Code coverage" OFF)

  if(BUILD_SHARED_LIBS)
    set(BRIEFLZ_LIBRARY_TYPE SHARED)
  else()
    set(BRIEFLZ_LIBRARY_TYPE STATIC)
  endif()

  enable_testing()
  set(BRIEFLZ_TEST_ENABLE TRUE)

  set(BRIEFLZ_INSTALL TRUE)

  if(BUILD_COVERAGE)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -g -O0 --coverage")
  elseif(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
  endif()
  message(STATUS "CMAKE_BUILD_TYPE: ${CMAKE_BUILD_TYPE}")
else()
  set(BRIEFLZ_LIBRARY_TYPE STATIC)
  set(BRIEFLZ_INSTALL FALSE)
endif()

mark_as_advanced(BRIEFLZ_LIBRARY_TYPE BRIEFLZ_TEST_ENABLE)

# Set BRIEFLZ_INCLUDE_DIRS and BRIEFLZ_DEFINITIONS in the parent
# scope.  This makes it a bit easier to use BriefLZ in bundled mode
# with CMake < 2.8.11.  For CMake >= 2.8.11, you can just add the
# brieflz target and be done with it.
set(BRIEFLZ_INCLUDE_DIRS "${CMAKE_CURRENT_SOURCE_DIR}")
if(BRIEFLZ_LIBRARY_TYPE STREQUAL "SHARED")
  set(BRIEFLZ_DEFINITIONS "BLZ_DLL")
else()
  set(BRIEFLZ_DEFINITIONS "")
endif()
get_directory_property(BRIEFLZ_PARENT_DIRECTORY PARENT_DIRECTORY)
if(BRIEFLZ_PARENT_DIRECTORY)
  set(BRIEFLZ_INCLUDE_DIRS "${BRIEFLZ_INCLUDE_DIRS}" PARENT_SCOPE)
  set(BRIEFLZ_DEFINITIONS "${BRIEFLZ_DEFINITIONS}" PARENT_SCOPE)
endif()
unset(BRIEFLZ_PARENT_DIRECTORY)
mark_as_advanced(BRIEFLZ_INCLUDE_DIRS BRIEFLZ_DEFINITIONS)

add_library(brieflz ${BRIEFLZ_LIBRARY_TYPE} brieflz.c depack.c depacks.c brieflz.h)
set_property(TARGET brieflz APPEND PROPERTY INCLUDE_DIRECTORIES "${BRIEFLZ_INCLUDE_DIRS}")
set_property(TARGET brieflz APPEND PROPERTY INTERFACE_INCLUDE_DIRECTORIES "${BRIEFLZ_INCLUDE_DIRS}")
set_target_properties(brieflz PROPERTIES
  VERSION ${BRIEFLZ_VERSION_MAJOR}.${BRIEFLZ_VERSION_MINOR}.${BRIEFLZ_VERSION_REVISION}
  SOVERSION "${BRIEFLZ_SOVERSION_CURRENT}.${BRIEFLZ_SOVERSION_REVISION}.${BRIEFLZ_SOVERSION_AGE}"
  POSITION_INDEPENDENT_CODE TRUE
)
if(BRIEFLZ_LIBRARY_TYPE STREQUAL "SHARED")
  set_property(TARGET brieflz APPEND PROPERTY COMPILE_DEFINITIONS BLZ_DLL BLZ_DLL_EXPORTS)
  set_property(TARGET brieflz APPEND PROPERTY INTERFACE_COMPILE_DEFINITIONS BLZ_DLL)
  set_target_properties(brieflz PROPERTIES C_VISIBILITY_PRESET hidden)
endif()

set(BRIEFLZ_COMPILE_FLAGS)
mark_as_advanced(BRIEFLZ_COMPILE_FLAGS)
if(MSVC)
  _add_c_compiler_flags(BRIEFLZ_COMPILE_FLAGS "/analyze")
elseif(CMAKE_COMPILER_IS_GNUCC)
  _add_c_compiler_flags(BRIEFLZ_COMPILE_FLAGS
    -Wall
    -Wextra
    -pedantic
    -Wshadow
    -Wpointer-arith
    -Wcast-qual
    -Wcast-align
    -Wstrict-prototypes
    -Wmissing-prototypes
  )
elseif(CMAKE_C_COMPILER_ID MATCHES "Clang")
  _add_c_compiler_flags(BRIEFLZ_COMPILE_FLAGS "-Weverything;-pedantic")
endif()
set_property(TARGET brieflz APPEND_STRING PROPERTY COMPILE_FLAGS "${BRIEFLZ_COMPILE_FLAGS}")

add_executable(blzpack example/blzpack.c example/parg.c)
target_link_libraries(blzpack brieflz)
if(MSVC)
  set_property(TARGET blzpack APPEND PROPERTY COMPILE_DEFINITIONS _CRT_SECURE_NO_WARNINGS)
endif()

add_executable(test_brieflz test/test_brieflz.c)
target_link_libraries(test_brieflz brieflz)

if(CMAKE_VERSION VERSION_LESS 2.8.11)
  include_directories("${BRIEFLZ_INCLUDE_DIRS}")
  foreach(target blzpack test_brieflz)
    set_property(TARGET ${target} APPEND PROPERTY COMPILE_DEFINITIONS "${BRIEFLZ_DEFINITIONS}")
  endforeach()
endif()

if(BRIEFLZ_TEST_ENABLE)
  add_test("${BRIEFLZ_TEST_PREFIX}brieflz" test_brieflz)
endif()

if(BRIEFLZ_INSTALL)
  include(GNUInstallDirs)

  install(TARGETS brieflz blzpack
    RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}"
    LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}"
    ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
  )
  install(FILES brieflz.h DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}")

  if(BRIEFLZ_TEST_ENABLE)
    install(TARGETS test_brieflz
      RUNTIME DESTINATION "${CMAKE_INSTALL_LIBEXECDIR}/installed-tests/brieflz"
    )
  endif()
endif()
