cmake_minimum_required(VERSION 3.5)
project (SUPL)

find_package(FLEX)
find_package(BISON)

flex_target(suLexer src/lexer.l
    ${CMAKE_CURRENT_BINARY_DIR}/lexer.cpp
    COMPILE_FLAGS --header-file="${CMAKE_CURRENT_BINARY_DIR}/lexer.hpp")

# bison_target(suParser src/parser.y ${CMAKE_CURRENT_BINARY_DIR}/parser.cpp)
# add_flex_bison_dependency(suLexer suParser)

set(SRCS
    src/main.cpp)

include_directories(${CMAKE_CURRENT_BINARY_DIR})
add_executable(suplc
    ${SRCS}
    ${FLEX_suLexer_OUTPUTS}
    # ${BISON_suParser_OUTPUTS}
)