project (distribute-slave-resources)
set(CMAKE_EXE_LINKER_FLAGS "-static")
add_executable(container/distribute-slave-resources distribute-slave-resources.cpp)
