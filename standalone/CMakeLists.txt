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

# TODO(CK): add_compile_definitions(BOOST_ASIO_NO_DEPRECATED)
add_compile_definitions(BOOST_ALL_NO_LIB)
set(Boost_USE_STATIC_LIBS YES)
# XXX set(Boost_DEBUG YES)

# In the past, Crow needs Boost and does not provide CPM.cmake integration itself, so we have to get
# Boost first (installad on Ubuntu 20.04.6 LTS is v1.71)
find_package(
  Boost 1.71
  COMPONENTS system date_time
  REQUIRED # XXX for now! CK
  QUIET
)
if(NOT Boost_FOUND)
  # Use CPM.cmake to get Boost from the official repo if not found
  message(WARNING "GreeterStandalone: Boost libs NOT found!")
  option(BUILD_SHARED_LIBS "Build shared libraries" NO)
  CPMAddPackage("gh:ClausKlein/boost-cmake@1.80.0")
else()
  message(STATUS "GreeterStandalone: Boost libs found")
endif()

# add header only library Crow
CPMAddPackage(
  NAME Crow
  GITHUB_REPOSITORY CrowCpp/Crow
  GIT_TAG v1.0+5
  VERSION 1.0.0
  SYSTEM ON # used in case of cmake v3.25
  OPTIONS "CROW_INSTALL NO"
)

# build the Greeter lib
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
target_link_libraries(${PROJECT_NAME} Greeter::Greeter Crow::Crow)
set_target_properties(${PROJECT_NAME} PROPERTIES UNITY_BUILD ${OPTION_ENABLE_UNITY})

# --- Test it ---

enable_testing()
add_test(NAME ${PROJECT_NAME} COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/service_test.sh
                                      $<TARGET_FILE:${PROJECT_NAME}>
)

# --- Install it ---

install(TARGETS ${PROJECT_NAME} RUNTIME)

include(CPack)
