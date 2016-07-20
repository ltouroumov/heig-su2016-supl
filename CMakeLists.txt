cmake_minimum_required(VERSION 3.5)
project (SUPL)

find_package(FLEX)
find_package(BISON)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")

flex_target(suLexer src/lexer.l
    ${CMAKE_CURRENT_BINARY_DIR}/lexer.cpp
    COMPILE_FLAGS --header-file="${CMAKE_CURRENT_BINARY_DIR}/lexer.hpp")

bison_target(suParser src/parser.y
    ${CMAKE_CURRENT_BINARY_DIR}/parser.cpp)

add_flex_bison_dependency(suLexer suParser)

configure_file(src/supllib.hpp supllib.hpp COPYONLY)

set(Compiler_SRCS
    src/main.cpp
    src/supllib.cpp)

set(VM_SRCS
    src/suvm.cpp
    src/supllib.cpp)

include_directories(${CMAKE_CURRENT_BINARY_DIR})
add_executable(suplc
    ${Compiler_SRCS}
    ${FLEX_suLexer_OUTPUTS}
    ${BISON_suParser_OUTPUTS}
)
# target_link_libraries(suplc fl)

add_executable(suvm
    ${VM_SRCS}
)
target_link_libraries(suvm m)