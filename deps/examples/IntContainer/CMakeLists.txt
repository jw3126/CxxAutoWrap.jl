cmake_minimum_required(VERSION 3.6)
project(IntContainer)

set(CMAKE_CXX_STANDARD 11)

set(SOURCE_FILES library.cpp library.h)
add_library(IntContainer SHARED ${SOURCE_FILES})