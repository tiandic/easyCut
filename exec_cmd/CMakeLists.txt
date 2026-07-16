add_executable(exec_cmd
    exec_cmd.cpp
)

install(TARGETS exec_cmd
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
