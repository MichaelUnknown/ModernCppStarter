cmake_minimum_required(VERSION 3.21...3.27)

project(
  GreeterStandalone
  DESCRIPTION "A standalone minimal webapi application using the Crow framework"
  LANGUAGES CXX
)

if(PROJECT_IS_TOP_LEVEL AND CMAKE_BUILD_TYPE STREQUAL "Release")
  set(CMAKE_SKIP_INSTALL_RULES
      NO
      CACHE BOOL "Forced generation of installation rules" FORCE
  )
endif()

option(OPTION_ENABLE_UNITY "Enable Unity builds of project" ON)

# --- Import tools ----

include(../cmake/tools.cmake)

# ---- Dependencies ----

include(../cmake/CPM.cmake)

#TODO(CK): add_compile_definitions(BOOST_ASIO_NO_DEPRECATED)

# Crow needs Boost 1.72 and does not provide CPM.cmake integration itself, so we have to get Boost
# first
find_package(Boost 1.72 QUIET)
if(NOT Boost_FOUND)
  # Use CPM.cmake to get Boost from the official repo if not provided as system lib
  message(STATUS "GreeterStandalone: Boost system lib NOT found")
  CPMAddPackage(
    NAME Boost
    GITHUB_REPOSITORY boostorg/boost
    GIT_TAG boost-1.78.0
    VERSION 1.78.0
  )
  # Ugly workaround: Boost cmake support is still experimental, the Boost::boost target is not
  # provided if downloaded via FetchContent_declare / CPM.cmake. Crow uses it for asio, so we fake
  # the Boost:boost target as asio
  if(NOT TARGET Boost::boost)
    add_library(Boost::boost INTERFACE IMPORTED)
    target_link_libraries(Boost::boost INTERFACE Boost::asio)
  endif()
else()
  message(STATUS "GreeterStandalone: Boost system lib found")
endif()
# add Crow
CPMAddPackage(
  NAME Crow
  GITHUB_REPOSITORY CrowCpp/Crow
  GIT_TAG v1.0+5
  VERSION 1.0.0
  OPTIONS "CROW_INSTALL OFF"
)

CPMAddPackage(
  GITHUB_REPOSITORY jarro2783/cxxopts
  VERSION 3.1.1
  SYSTEM ON # used in case of cmake v3.25
  OPTIONS "CXXOPTS_BUILD_EXAMPLES NO" "CXXOPTS_BUILD_TESTS NO" "CXXOPTS_ENABLE_INSTALL YES"
)

# get the Greeter lib
CPMAddPackage(
  NAME Greeter
  SOURCE_DIR ${CMAKE_CURRENT_LIST_DIR}/..
  FORCE ON
)

# ---- Create standalone executable ----

file(GLOB sources CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/source/*.cpp)

add_executable(${PROJECT_NAME} ${sources})
if(CMAKE_DEBUG_POSTFIX)
  set_property(TARGET ${PROJECT_NAME} PROPERTY DEBUG_POSTFIX ${CMAKE_DEBUG_POSTFIX})
endif()
target_compile_features(${PROJECT_NAME} PRIVATE cxx_std_17)
target_link_libraries(${PROJECT_NAME} Greeter::Greeter cxxopts::cxxopts Crow::Crow)
set_target_properties(${PROJECT_NAME} PROPERTIES UNITY_BUILD ${OPTION_ENABLE_UNITY})

# --- Test it ---

enable_testing()
add_test(NAME ${PROJECT_NAME} COMMAND ${PROJECT_NAME} --help)

# --- Install it ---

install(TARGETS ${PROJECT_NAME} RUNTIME)

include(CPack)
