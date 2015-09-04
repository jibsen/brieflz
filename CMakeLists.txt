cmake_minimum_required(VERSION 2.8)

project(brieflz C)

option(BUILD_SHARED_LIBS "Build BriefLZ with shared libraries" OFF)

if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release)
endif()

message(STATUS "CMAKE_BUILD_TYPE: ${CMAKE_BUILD_TYPE}")

if(MSVC)
  add_definitions(/D_CRT_SECURE_NO_WARNINGS)
else()
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall -Wextra -ansi -pedantic")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra -ansi -pedantic")
endif()

include_directories(${PROJECT_SOURCE_DIR})

add_library(brieflz brieflz.c depack.c depacks.c brieflz.h)
set_target_properties(brieflz PROPERTIES
  VERSION 1.1.0
  SOVERSION 1
  C_VISIBILITY_PRESET hidden
)

target_compile_definitions(brieflz
  PRIVATE $<$<STREQUAL:$<TARGET_PROPERTY:brieflz,TYPE>,SHARED_LIBRARY>:BLZ_DLL_EXPORTS>
  PUBLIC $<$<STREQUAL:$<TARGET_PROPERTY:brieflz,TYPE>,SHARED_LIBRARY>:BLZ_DLL>
)

add_executable(blzpack example/blzpack.c example/parg.c example/parg.h)
target_link_libraries(blzpack brieflz)

install(TARGETS brieflz blzpack
  RUNTIME DESTINATION bin
  LIBRARY DESTINATION lib
  ARCHIVE DESTINATION lib
)
install(FILES brieflz.h
  DESTINATION include
)
