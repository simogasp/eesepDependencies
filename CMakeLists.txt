cmake_minimum_required(VERSION 3.7)
project(eesep_dependencies LANGUAGES C CXX)

option(EESEP_BUILD_CUDA "Install CUDA" OFF)
option(EESEP_BUILD_ZLIB "Build zlib (required by Boost)" OFF)
option(EESEP_BUILD_OPENCV "Build OpenCV" OFF)
option(EESEP_BUILD_SVD3 "Build SVD3" ON)
option(EESEP_BUILD_EIGEN "Build Eigen3" ON)
option(EESEP_BUILD_BOOST "Build Boost" ON)
option(EESEP_BUILD_GEOGRAM "Build Geogram" ON)
option(EESEP_BUILD_ASSIMP "Build Assimp" ON)
option(EESEP_BUILD_BATCHCUDASOLVER "Build BatchCudaSolver" ON)
option(EESEP_BUILD_CGAL "Build CGAL" ON)
option(EESEP_BUILD_DECKLINK "Build Blackmagic Decklink" ON)
option(EESEP_BUILD_POPSIFT "Build PopSift" ON)
option(EESEP_BUILD_ALICEVISION "Build AliceVision" ON)

if(EESEP_BUILD_ALICEVISION AND NOT EESEP_BUILD_GEOGRAM)
    message(WARNING "AliceVision requires Geogram, so it is switched on")
    set(EESEP_BUILD_GEOGRAM ON)
endif()

set(EESEP_QT5_PATH "" CACHE PATH "The path where cmake can find Qt, eg /opt/Qt/5.12.4/gcc_64/")
if(NOT EESEP_QT5_PATH)
    message(WARNING "The path to Qt5 is needed to build qmlAlembic")
endif()

# Set a default build type if none was specified
set(default_build_type "Release")

if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    message(STATUS "Setting build type to '${default_build_type}' as none was specified.")
    set(CMAKE_BUILD_TYPE "${default_build_type}" CACHE  STRING "Choose the type of build." FORCE)
    # Set the possible values of build type for cmake-gui
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS  "Debug" "Release" "MinSizeRel" "RelWithDebInfo")
endif()

string(TOLOWER ${CMAKE_BUILD_TYPE} CMAKE_BUILD_TYPE_LOWERCASE)

set(EESEP_CUDA_ARCHITECTURE "" CACHE STRING "The CUDA architecture to build the target for: eg. Turing, Volta, Pascal, Maxwell")
if(NOT EESEP_CUDA_ARCHITECTURE)
    message(STATUS "Setting the cuda architecture to Auto as none was specified.")
    set(EESEP_CUDA_ARCHITECTURE "Auto" CACHE  STRING "The Cuda architecture to build the target for." FORCE)
endif()

# ==============================================================================
# GNUInstallDirs CMake module
# - Define GNU standard installation directories
# - Provides install directory variables as defined by the GNU Coding Standards.
# ==============================================================================
include(GNUInstallDirs)

if(CMAKE_BUILD_TYPE MATCHES Release)
    message(STATUS "Force CMAKE_INSTALL_DO_STRIP in Release")
    set(CMAKE_INSTALL_DO_STRIP TRUE)
endif()

message(STATUS "----------------------------------------")
message(STATUS "CMAKE_BUILD_TYPE: ${CMAKE_BUILD_TYPE}")
message(STATUS "BUILD_CUDA: ${EESEP_BUILD_CUDA}")
message(STATUS "BUILD_ZLIB: ${EESEP_BUILD_ZLIB}")
message(STATUS "BUILD_OPENCV: ${EESEP_BUILD_OPENCV}")
message(STATUS "BUILD_SVD3: ${EESEP_BUILD_SVD3}")
message(STATUS "BUILD_EIGEN: ${EESEP_BUILD_EIGEN}")
message(STATUS "BUILD_BOOST: ${EESEP_BUILD_BOOST}")
message(STATUS "BUILD_GEOGRAM: ${EESEP_BUILD_GEOGRAM}")
message(STATUS "BUILD_ASSIMP: ${EESEP_BUILD_ASSIMP}")
message(STATUS "BUILD_BATCHCUDASOLVER: ${EESEP_BUILD_BATCHCUDASOLVER}")
message(STATUS "BUILD_CGAL: ${EESEP_BUILD_CGAL}")
message(STATUS "BUILD_DECKLINK: ${EESEP_BUILD_DECKLINK}")
message(STATUS "BUILD_POPSIFT: ${EESEP_BUILD_POPSIFT}")
message(STATUS "BUILD_ALICEVISION: ${EESEP_BUILD_ALICEVISION}")
message(STATUS "QT5_PATH: ${EESEP_QT5_PATH}")

message(STATUS "CMAKE_BUILD_TYPE: ${CMAKE_BUILD_TYPE}")
message(STATUS "CUDA_ARCHITECTURE: ${EESEP_CUDA_ARCHITECTURE}")
message(STATUS "CMAKE_INSTALL_LIBDIR: ${CMAKE_INSTALL_LIBDIR}")
message(STATUS "CMAKE_INSTALL_PREFIX: ${CMAKE_INSTALL_PREFIX}")
message(STATUS "CMAKE_INSTALL_RPATH: ${CMAKE_INSTALL_RPATH}")
message(STATUS "CMAKE_INSTALL_DO_STRIP: ${CMAKE_INSTALL_DO_STRIP}")
message(STATUS "----------------------------------------")


if(WIN32)
    set(SCRIPT_EXTENSION bat)
else()
    set(SCRIPT_EXTENSION sh)
endif()

# ==============================================================================
# Use CMake ExternalProject to build all dependencies
# ==============================================================================
include(ExternalProject)

set(BUILD_DIR "${CMAKE_CURRENT_BINARY_DIR}/external")

set(CMAKE_CORE_BUILD_FLAGS -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DBUILD_SHARED_LIBS:BOOL=ON -DCMAKE_INSTALL_DO_STRIP=${CMAKE_INSTALL_DO_STRIP})
set(CMAKE_CORE_BUILD_FLAGS_NOSHARED -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DCMAKE_INSTALL_DO_STRIP=${CMAKE_INSTALL_DO_STRIP})

if(EESEP_BUILD_CUDA)
    set(CUDA_TARGET cuda)
    ExternalProject_Add(${CUDA_TARGET}
            URL https://developer.nvidia.com/compute/cuda/8.0/Prod2/local_installers/cuda_8.0.61_375.26_linux-run
            # URL https://developer.nvidia.com/compute/cuda/9.2/Prod/local_installers/cuda_9.2.88_396.26_linux
            DOWNLOAD_NO_EXTRACT 1
            PREFIX ${BUILD_DIR}
            BUILD_IN_SOURCE 0
            BUILD_ALWAYS 0
            SOURCE_DIR ${CMAKE_CURRENT_BINARY_DIR}/cuda
            BINARY_DIR ${BUILD_DIR}/cuda_build
            INSTALL_DIR ${CMAKE_INSTALL_PREFIX}
            CONFIGURE_COMMAND ""
            BUILD_COMMAND ""
            INSTALL_COMMAND sh ${BUILD_DIR}/src/cuda_8.0.61_375.26_linux-run --silent --no-opengl-libs --toolkit --toolkitpath=<INSTALL_DIR>
            )
    set(CUDA_CUDART_LIBRARY "")
    set(CUDA_CMAKE_FLAGS -DCUDA_TOOLKIT_ROOT_DIR=${BUILD_DIR}/cuda_build)
else()
    if(CUDA_TOOLKIT_ROOT_DIR)
        set(CUDA_CMAKE_FLAGS -DCUDA_TOOLKIT_ROOT_DIR=${CUDA_TOOLKIT_ROOT_DIR})
    endif()
endif()

# Add zlib
if(EESEP_BUILD_ZLIB)
    set(ZLIB_TARGET zlib)
    ExternalProject_Add(${ZLIB_TARGET}
            URL http://www.zlib.net/zlib-1.2.11.tar.gz
            PREFIX ${BUILD_DIR}
            BUILD_IN_SOURCE 0
            BUILD_ALWAYS 0
            SOURCE_DIR ${CMAKE_CURRENT_BINARY_DIR}/zlib
            BINARY_DIR ${BUILD_DIR}/zlib_build
            INSTALL_DIR ${CMAKE_INSTALL_PREFIX}
            CONFIGURE_COMMAND ${CMAKE_COMMAND} ${CMAKE_CORE_BUILD_FLAGS} -DCMAKE_INSTALL_PREFIX:PATH=<INSTALL_DIR> <SOURCE_DIR>
            )
    set(ZLIB_CMAKE_FLAGS -DZLIB_ROOT=${CMAKE_INSTALL_PREFIX})
endif()

if(EESEP_BUILD_EIGEN)
    # Add Eigen
    set(EIGEN_TARGET eigen)
    set(EIGEN_FILENAME 3.3.4.tar.gz)
    ExternalProject_Add(${EIGEN_TARGET}
            URL https://github.com/eigenteam/eigen-git-mirror/archive/${EIGEN_FILENAME}
            DOWNLOAD_NAME eigen-${EIGEN_FILENAME}
            PREFIX ${BUILD_DIR}
            BUILD_IN_SOURCE 0
            BUILD_ALWAYS 0
            SOURCE_DIR ${CMAKE_CURRENT_BINARY_DIR}/eigen
            BINARY_DIR ${BUILD_DIR}/eigen_build
            INSTALL_DIR ${CMAKE_INSTALL_PREFIX}
            CONFIGURE_COMMAND ${CMAKE_COMMAND} ${CMAKE_CORE_BUILD_FLAGS} -DCMAKE_INSTALL_PREFIX:PATH=<INSTALL_DIR> <SOURCE_DIR>
            )
    set(EIGEN_CMAKE_FLAGS -DEigen3_DIR:PATH=${CMAKE_INSTALL_PREFIX}/share/eigen3/cmake -DEIGEN3_INCLUDE_DIR=${BUILD_DIR}/eigen_build/include/eigen3 -DEIGEN_INCLUDE_DIR=${CMAKE_INSTALL_PREFIX}/include/eigen3)
endif()

if(EESEP_BUILD_BOOST)
    # Add Boost
    set(BOOST_TARGET boost)
    ExternalProject_Add(${BOOST_TARGET}
            URL http://sourceforge.net/projects/boost/files/boost/1.66.0/boost_1_66_0.tar.bz2
	    # https://github.com/alicevision/AliceVisionDependencies/releases/download/boost-src.1.61.0/boost_1_61_0.tar.gz
            #    http://sourceforge.net/projects/boost/files/boost/1.61.0/boost_1_61_0.tar.bz2
            #    https://dl.bintray.com/boostorg/release/1.61.0/source/boost_1_61_0.tar.gz
            # GIT_REPOSITORY https://github.com/boostorg/boost.git
            # GIT_TAG boost-1.61.0
            PREFIX ${BUILD_DIR}
            BUILD_IN_SOURCE 0
            BUILD_ALWAYS 0
            SOURCE_DIR ${CMAKE_CURRENT_BINARY_DIR}/boost
            BINARY_DIR ${BUILD_DIR}/boost_build
            INSTALL_DIR ${CMAKE_INSTALL_PREFIX}
            CONFIGURE_COMMAND cd <SOURCE_DIR> && ./bootstrap.${SCRIPT_EXTENSION} --prefix=<INSTALL_DIR> --with-libraries=atomic,container,date_time,exception,filesystem,graph,iostreams,log,math,program_options,regex,serialization,system,test,thread
            BUILD_COMMAND cd <SOURCE_DIR> && ./b2 --prefix=<INSTALL_DIR> variant=${CMAKE_BUILD_TYPE_LOWERCASE} link=shared threading=multi
            INSTALL_COMMAND cd <SOURCE_DIR> && ./b2 variant=${CMAKE_BUILD_TYPE_LOWERCASE} link=shared threading=multi install
            DEPENDS ${ZLIB_TARGET}
            )
    set(BOOST_CMAKE_FLAGS -DBOOST_ROOT=${CMAKE_INSTALL_PREFIX})
endif()

if(EESEP_BUILD_GEOGRAM)
    # Add Geogram
    if(WIN32)
        set(VORPALINE_PLATFORM Win-vs-dynamic-generic)
    elseif(APPLE)
        set(VORPALINE_PLATFORM Darwin-clang-dynamic)
    elseif(UNIX)
        set(VORPALINE_PLATFORM Linux64-gcc-dynamic)
    endif()
    set(GEOGRAM_TARGET geogram)
    set(GEOGRAM_FILENAME v1.6.6.tar.gz)
    ExternalProject_Add(${GEOGRAM_TARGET}
            URL https://github.com/alicevision/geogram/archive/${GEOGRAM_FILENAME}
            DOWNLOAD_NAME geogram-${GEOGRAM_FILENAME}
            PREFIX ${BUILD_DIR}
            BUILD_IN_SOURCE 0
            BUILD_ALWAYS 0
            SOURCE_DIR ${CMAKE_CURRENT_BINARY_DIR}/geogram
            BINARY_DIR ${BUILD_DIR}/geogram_internal_build
            INSTALL_DIR ${CMAKE_INSTALL_PREFIX}
            CONFIGURE_COMMAND ${CMAKE_COMMAND} ${CMAKE_CORE_BUILD_FLAGS} -DVORPALINE_PLATFORM=${VORPALINE_PLATFORM} -DGEOGRAM_WITH_HLBFGS=OFF -DGEOGRAM_WITH_TETGEN=OFF -DGEOGRAM_WITH_GRAPHICS=OFF -DGEOGRAM_WITH_EXPLORAGRAM=OFF -DGEOGRAM_WITH_LUA=OFF -DCMAKE_INSTALL_PREFIX:PATH=<INSTALL_DIR> <SOURCE_DIR>
            DEPENDS ${ZLIB_TARGET}
            )
    set(GEOGRAM_CMAKE_FLAGS -DGEOGRAM_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX} -DGEOGRAM_INCLUDE_DIR=${CMAKE_INSTALL_PREFIX}/include/geogram1)
endif()

if(EESEP_BUILD_ASSIMP)
    # Add Assimp
    set(ASSIMP_TARGET assimp)
    set(ASSIMP_BUILD_OPTIONS -DASSIMP_BUILD_ASSIMP_TOOLS:BOOL=OFF -DASSIMP_BUILD_TESTS:BOOL=OFF)
    set(ASSIMP_FILENAME v3.3.1.tar.gz)
    ExternalProject_Add(${ASSIMP_TARGET}
            URL https://github.com/assimp/assimp/archive/${ASSIMP_FILENAME}
            DOWNLOAD_NAME assimp-${ASSIMP_FILENAME}
            PREFIX ${BUILD_DIR}
            BUILD_IN_SOURCE 0
            BUILD_ALWAYS 0
            SOURCE_DIR ${CMAKE_CURRENT_BINARY_DIR}/assimp
            BINARY_DIR ${BUILD_DIR}/assimp_build
            INSTALL_DIR ${CMAKE_INSTALL_PREFIX}
            CONFIGURE_COMMAND ${CMAKE_COMMAND} ${CMAKE_CORE_BUILD_FLAGS} ${ASSIMP_BUILD_OPTIONS} -DCMAKE_INSTALL_PREFIX:PATH=<INSTALL_DIR> <SOURCE_DIR>
            )
    set(ASSIMP_CMAKE_FLAGS -DAssimp_DIR:PATH=${CMAKE_INSTALL_PREFIX}/lib/cmake/assimp-3.3.1/)
endif()

if(EESEP_BUILD_OPENCV)
    set(OCV_CONTRIB_TARGET opencv_contrib)
    set(OCV_CONTRIB_FILENAME 3.4.3.tar.gz)
    ExternalProject_Add(${OCV_CONTRIB_TARGET}
            URL https://github.com/opencv/opencv_contrib/archive/${OCV_CONTRIB_FILENAME}
            DOWNLOAD_NAME contrib-${OCV_CONTRIB_FILENAME}
            PREFIX ${BUILD_DIR}
            BUILD_IN_SOURCE 0
            BUILD_ALWAYS 0
            CONFIGURE_COMMAND ""
            BUILD_COMMAND ""
            INSTALL_COMMAND ""
            )

    # using openmp instead of tbb beacuse of https://github.com/opencv/opencv/issues/11759
    set(OPENCV_TARGET opencv)
    set(OPENCV_FILENAME 3.4.3.tar.gz)
    set(OPENCV_DO_NOT_BUILD_MODULES -DBUILD_opencv_apps:BOOL=OFF -DBUILD_opencv_bgsegm:BOOL=OFF -DBUILD_opencv_bioinspired:BOOL=OFF -DBUILD_opencv_ccalib:BOOL=OFF -DBUILD_opencv_datasets:BOOL=OFF -DBUILD_opencv_dnn:BOOL=OFF -DBUILD_opencv_dnn_objdetect:BOOL=OFF -DBUILD_opencv_dpm:BOOL=OFF -DBUILD_opencv_face:BOOL=OFF -DBUILD_opencv_fuzzy:BOOL=OFF -DBUILD_opencv_hdf:BOOL=OFF -DBUILD_opencv_hfs:BOOL=OFF -DBUILD_opencv_java_bindings_gen:BOOL=OFF -DBUILD_opencv_js:BOOL=OFF -DBUILD_opencv_line_descriptor:BOOL=OFF -DBUILD_opencv_matlab:BOOL=OFF -DBUILD_opencv_ml:BOOL=OFF -DBUILD_opencv_objdetect:BOOL=OFF -DBUILD_opencv_phase_unwrapping:BOOL=OFF -DBUILD_opencv_photo:BOOL=OFF -DBUILD_opencv_python2:BOOL=OFF -DBUILD_opencv_python3:BOOL=OFF -DBUILD_opencv_python_bindings_g:BOOL=OFF -DBUILD_opencv_reg:BOOL=OFF -DBUILD_opencv_rgbd:BOOL=OFF -DBUILD_opencv_saliency:BOOL=OFF -DBUILD_opencv_sfm:BOOL=OFF -DBUILD_opencv_shape:BOOL=OFF -DBUILD_opencv_stitching:BOOL=OFF -DBUILD_opencv_structured_light:BOOL=OFF -DBUILD_opencv_superres:BOOL=OFF -DBUILD_opencv_surface_matching:BOOL=OFF -DBUILD_opencv_text:BOOL=OFF -DBUILD_opencv_videostab:BOOL=OFF -DBUILD_opencv_viz:BOOL=OFF -DBUILD_opencv_world:BOOL=OFF -DBUILD_opencv_xobjdetect:BOOL=OFF -DBUILD_opencv_xphoto:BOOL=OFF)
    ExternalProject_Add(${OPENCV_TARGET}
            URL https://github.com/opencv/opencv/archive/${OPENCV_FILENAME}
            DOWNLOAD_NAME opencv-${OPENCV_FILENAME}
            PREFIX ${BUILD_DIR}
            BUILD_IN_SOURCE 0
            BUILD_ALWAYS 0
            SOURCE_DIR ${CMAKE_CURRENT_BINARY_DIR}/opencv
            BINARY_DIR ${BUILD_DIR}/opencv_build
            INSTALL_DIR ${CMAKE_INSTALL_PREFIX}
            CONFIGURE_COMMAND ${CMAKE_COMMAND} ${CMAKE_CORE_BUILD_FLAGS} ${EIGEN_CMAKE_FLAGS} -DWITH_EIGEN:BOOL=ON -DWITH_OPENMP:BOOL=ON -DWITH_CUDA:BOOL=ON -DWITH_CUBLAS:BOOL=ON -DWITH_CUFFT:BOOL=ON -DBUILD_CUDA_STUBS:BOOL=OFF -DCUDA_GENERATION:STRING=${EESEP_CUDA_ARCHITECTURE} -DWITH_OPENCL:BOOL=OFF -DWITH_IPP:BOOL=ON -DWITH_IPP_A:BOOL=OFF -DBUILD_DOCS:BOOL=OFF ${OPENCV_DO_NOT_BUILD_MODULES} -DBUILD_EXAMPLES:BOOL=OFF -DBUILD_PERF_TESTS:BOOL=OFF -DWITH_PTHREADS_PF:BOOL=OFF -DWITH_TBB:BOOL=OFF -DWITH_V4L:BOOL=ON -DINSTALL_C_EXAMPLES:BOOL=OFF -DBUILD_TESTS:BOOL=OFF -DINSTALL_TESTS:BOOL=OFF -DWITH_OPENEXR:BOOL=ON -DWITH_GTK_2_X:BOOL=ON -DWITH_OPENGL:BOOL=ON -DWITH_PVAPI:BOOL=ON -DBUILD_OPENEXR:BOOL=ON -DBUILD_SHARED_LIBS:BOOL=ON -DOPENCV_EXTRA_MODULES_PATH=${BUILD_DIR}/src/opencv_contrib/modules/ -DOPENCV_ENABLE_NONFREE:BOOL=TRUE -DCMAKE_INSTALL_PREFIX:PATH=<INSTALL_DIR> <SOURCE_DIR>
            DEPENDS ${ZLIB_TARGET} ${OCV_CONTRIB_TARGET} ${EIGEN_TARGET}
            )
    set(OPENCV_CMAKE_FLAGS -DOpenCV_DIR=${CMAKE_INSTALL_PREFIX})

endif()

if(EESEP_BUILD_SVD3)
    set(SVD3_TARGET svd3)
    set(SVD3_FILENAME develop.zip)
    ExternalProject_Add(${SVD3_TARGET}
            URL https://github.com/EncovGroup/svd3/archive/${SVD3_FILENAME}
            DOWNLOAD_NAME svd3-${SVD3_FILENAME}
            PREFIX ${BUILD_DIR}
            BUILD_IN_SOURCE 0
            BUILD_ALWAYS 0
            SOURCE_DIR ${CMAKE_CURRENT_BINARY_DIR}/svd3
            BINARY_DIR ${BUILD_DIR}/svd3_build
            INSTALL_DIR ${CMAKE_INSTALL_PREFIX}
            CONFIGURE_COMMAND ${CMAKE_COMMAND} ${CMAKE_CORE_BUILD_FLAGS} -DCMAKE_INSTALL_PREFIX:PATH=<INSTALL_DIR> <SOURCE_DIR>
            )
endif()

if(EESEP_BUILD_BATCHCUDASOLVER)
    set(BATCHCUDASOLVER_TARGET CudaBatchedSolver)
    set(BATCHCUDASOLVER_FILENAME develop.zip)
    ExternalProject_Add(${BATCHCUDASOLVER_TARGET}
            URL https://github.com/EncovGroup/CudaBatchedSolver/archive/${BATCHCUDASOLVER_FILENAME}
            DOWNLOAD_NAME CudaBatchedSolver-${BATCHCUDASOLVER_FILENAME}
            PREFIX ${BUILD_DIR}
            BUILD_IN_SOURCE 0
            BUILD_ALWAYS 0
            SOURCE_DIR ${CMAKE_CURRENT_BINARY_DIR}/CudaBatchedSolver
            BINARY_DIR ${BUILD_DIR}/CudaBatchedSolver_build
            INSTALL_DIR ${CMAKE_INSTALL_PREFIX}
            CONFIGURE_COMMAND ${CMAKE_COMMAND} ${CMAKE_CORE_BUILD_FLAGS} -DCMAKE_INSTALL_PREFIX:PATH=<INSTALL_DIR> <SOURCE_DIR>
            )
endif()

if(EESEP_BUILD_CGAL)
    # it requires GMP and MPFR which are usually shipped with linux distributions
    # also MPFR depends on GMP
    set(CGAL_TARGET CGAL)
    ExternalProject_Add(${CGAL_TARGET}
            URL https://github.com/CGAL/cgal/archive/releases/CGAL-4.12.1.tar.gz
#            URL https://github.com/CGAL/cgal/archive/releases/CGAL-4.8.1.tar.gz
            PREFIX ${BUILD_DIR}
            BUILD_IN_SOURCE 0
            BUILD_ALWAYS 0
            SOURCE_DIR ${CMAKE_CURRENT_BINARY_DIR}/CGAL
            BINARY_DIR ${BUILD_DIR}/CGAL_build
            INSTALL_DIR ${CMAKE_INSTALL_PREFIX}
            CONFIGURE_COMMAND ${CMAKE_COMMAND} ${CMAKE_CORE_BUILD_FLAGS} ${ZLIB_CMAKE_FLAGS} ${EIGEN_CMAKE_FLAGS} ${BOOST_CMAKE_FLAGS} -DCMAKE_INSTALL_PREFIX:PATH=<INSTALL_DIR> <SOURCE_DIR>
            DEPENDS ${ZLIB_TARGET} ${BOOST_TARGET} ${EIGEN_TARGET}
            )
endif()

if(EESEP_BUILD_DECKLINK)
    set(DECKLINK_TARGET Decklink)
    set(DECKLINK_FILENAME v10.5.tar.gz)
    ExternalProject_Add(${DECKLINK_TARGET}
            URL https://github.com/EncovGroup/DecklinkSDK/archive/${DECKLINK_FILENAME}
            DOWNLOAD_NAME decklink-${DECKLINK_FILENAME}
            PREFIX ${BUILD_DIR}
            BUILD_IN_SOURCE 0
            BUILD_ALWAYS 0
            SOURCE_DIR ${CMAKE_CURRENT_BINARY_DIR}/Decklink
            BINARY_DIR ${BUILD_DIR}/Decklink_build
            INSTALL_DIR ${CMAKE_INSTALL_PREFIX}
            CONFIGURE_COMMAND ${CMAKE_COMMAND} ${CMAKE_CORE_BUILD_FLAGS} -DCMAKE_INSTALL_PREFIX:PATH=<INSTALL_DIR> <SOURCE_DIR>
            )
endif()

if(EESEP_BUILD_POPSIFT)
    set(POPSIFT_TARGET popsift)
    ExternalProject_Add(${POPSIFT_TARGET}
            GIT_REPOSITORY https://github.com/alicevision/popsift
            GIT_TAG develop
            PREFIX ${BUILD_DIR}
            BUILD_IN_SOURCE 0
            BUILD_ALWAYS 0
            SOURCE_DIR ${CMAKE_CURRENT_BINARY_DIR}/popsift
            BINARY_DIR ${BUILD_DIR}/popsift_build
            INSTALL_DIR ${CMAKE_INSTALL_PREFIX}
            CONFIGURE_COMMAND ${CMAKE_COMMAND} ${CMAKE_CORE_BUILD_FLAGS} ${BOOST_CMAKE_FLAGS} ${CUDA_CMAKE_FLAGS} -DPopSift_BUILD_EXAMPLES:BOOL=OFF -DCMAKE_INSTALL_PREFIX:PATH=<INSTALL_DIR> <SOURCE_DIR>
            DEPENDS ${BOOST_TARGET} ${CUDA_TARGET}
            )
    set(POPSIFT_CMAKE_FLAGS -DPopSift_DIR:PATH=${CMAKE_INSTALL_PREFIX}/lib/cmake/PopSift)
endif()

if(EESEP_BUILD_ALICEVISION)

    set(TBB_TARGET tbb)
    ExternalProject_Add(${TBB_TARGET}
            URL https://github.com/01org/tbb/archive/2018_U5.tar.gz
            PREFIX ${BUILD_DIR}
            BUILD_IN_SOURCE 0
            BUILD_ALWAYS 0
            SOURCE_DIR ${CMAKE_CURRENT_BINARY_DIR}/tbb
            BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR}/tbb
            INSTALL_DIR ${CMAKE_INSTALL_PREFIX}
            CONFIGURE_COMMAND ""
            BUILD_COMMAND PREFIX=<INSTALL_DIR> make PREFIX=<INSTALL_DIR>
            INSTALL_COMMAND mkdir -p <INSTALL_DIR>/${CMAKE_INSTALL_LIBDIR} && echo "cp <BINARY_DIR>/build/linux_*_release/*.so <INSTALL_DIR>/${CMAKE_INSTALL_LIBDIR}" > tbb_so_files.sh && sh tbb_so_files.sh && cp -r "<BINARY_DIR>/include" "<INSTALL_DIR>"
            )

    set(LAPACK_TARGET lapack)
    ExternalProject_Add(${LAPACK_TARGET}
            URL http://www.netlib.org/lapack/lapack-3.8.0.tar.gz
            PREFIX ${BUILD_DIR}
            BUILD_IN_SOURCE 0
            BUILD_ALWAYS 0
            UPDATE_COMMAND ""
            SOURCE_DIR ${CMAKE_CURRENT_BINARY_DIR}/lapack
            BINARY_DIR ${BUILD_DIR}/lapack_build
            INSTALL_DIR ${CMAKE_INSTALL_PREFIX}
            CONFIGURE_COMMAND ${CMAKE_COMMAND} ${CMAKE_CORE_BUILD_FLAGS} -DCMAKE_INSTALL_PREFIX:PATH=<INSTALL_DIR> <SOURCE_DIR>
            DEPENDS ${TBB_TARGET}
            )
    set(BLAS_LIBRARIES ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR}/libblas.so)
    set(LAPACK_LIBRARIES ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR}/liblapack.so)
    set(LAPACK_CMAKE_FLAGS -DBLAS_LIBRARIES=${BLAS_LIBRARIES} -DLAPACK_LIBRARIES=${LAPACK_LIBRARIES})


    set(SUITESPARSE_TARGET suitesparse)
    set(SUITESPARSE_FILENAME v4.5.6.tar.gz)
    set(SUITESPARSE_INTERNAL_MAKE_CMD LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR} make BLAS="${BLAS_LIBRARIES}" LAPACK="${LAPACK_LIBRARIES}")
    ExternalProject_Add(${SUITESPARSE_TARGET}
            URL https://github.com/jluttine/suitesparse/archive/${SUITESPARSE_FILENAME}
            # URL http://faculty.cse.tamu.edu/davis/SuiteSparse/SuiteSparse-5.4.0.tar.gz  # requires gxx >= 4.9, centos 7 use gxx-4.8.5
            DOWNLOAD_NAME SuiteSparse-${SUITESPARSE_FILENAME}
            PREFIX ${BUILD_DIR}
            BUILD_IN_SOURCE 0
            BUILD_ALWAYS 0
            SOURCE_DIR ${CMAKE_CURRENT_BINARY_DIR}/suitesparse
            BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR}/suitesparse
            INSTALL_DIR ${CMAKE_INSTALL_PREFIX}
            CONFIGURE_COMMAND ""
            BUILD_COMMAND  ""
            INSTALL_COMMAND cd <BINARY_DIR> && ${SUITESPARSE_INTERNAL_MAKE_CMD} install INSTALL=<INSTALL_DIR>
            DEPENDS ${LAPACK_TARGET}
            )
    set(SUITESPARSE_CMAKE_FLAGS ${LAPACK_CMAKE_FLAGS} -DSUITESPARSE_INCLUDE_DIR_HINTS=${CMAKE_INSTALL_PREFIX}/include -DSUITESPARSE_LIBRARY_DIR_HINTS=${CMAKE_INSTALL_PREFIX}/lib)

    # Add ceres-solver: A Nonlinear Least Squares Minimizer
    set(CERES_TARGET ceres)
    set(CERES_FILENAME 1.14.0.tar.gz)
    ExternalProject_Add(${CERES_TARGET}
            URL https://github.com/ceres-solver/ceres-solver/archive/${CERES_FILENAME}
            DOWNLOAD_NAME ceres-${CERES_FILENAME}
            PREFIX ${BUILD_DIR}
            BUILD_IN_SOURCE 0
            BUILD_ALWAYS 0
            UPDATE_COMMAND ""
            SOURCE_DIR ${CMAKE_CURRENT_BINARY_DIR}/ceres-solver
            BINARY_DIR ${BUILD_DIR}/ceres_build
            INSTALL_DIR ${CMAKE_INSTALL_PREFIX}
            CONFIGURE_COMMAND ${CMAKE_COMMAND} ${CMAKE_CORE_BUILD_FLAGS} ${SUITESPARSE_CMAKE_FLAGS} -DSUITESPARSE:BOOL=ON -DLAPACK:BOOL=ON ${EIGEN_CMAKE_FLAGS} -DMINIGLOG=ON -DBUILD_TESTING:BOOL=OFF -DBUILD_EXAMPLES:BOOL=OFF -DBUILD_EXAMPLES:BOOL=OFF -DCMAKE_INSTALL_PREFIX:PATH=<INSTALL_DIR> <SOURCE_DIR>
            DEPENDS ${EIGEN_TARGET} ${SUITESPARSE_TARGET}
            )
    set(CERES_CMAKE_FLAGS ${SUITESPARSE_CMAKE_FLAGS} -DCeres_DIR=${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR}/cmake/Ceres)


    set(OPENEXR_TARGET openexr)
    set(OPENEXR_VERSION 2.3)
    set(OPENEXR_FILENAME v${OPENEXR_VERSION}.0.tar.gz)
    ExternalProject_Add(${OPENEXR_TARGET}
            URL https://github.com/openexr/openexr/archive/${OPENEXR_FILENAME}
            DOWNLOAD_NAME openexr-${OPENEXR_FILENAME}
            PREFIX ${BUILD_DIR}
            BUILD_IN_SOURCE 0
            BUILD_ALWAYS 0
            UPDATE_COMMAND ""
            SOURCE_DIR ${CMAKE_CURRENT_BINARY_DIR}/openexr
            BINARY_DIR ${BUILD_DIR}/openexr_build
            INSTALL_DIR ${CMAKE_INSTALL_PREFIX}
            CONFIGURE_COMMAND ${CMAKE_COMMAND} ${CMAKE_CORE_BUILD_FLAGS} -DOPENEXR_BUILD_PYTHON_LIBS:BOOL=OFF -DENABLE_TESTS:BOOL=OFF ${ZLIB_CMAKE_FLAGS} -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR> <SOURCE_DIR>
            DEPENDS ${ZLIB_TARGET}
            )
    set(ILMBASE_CMAKE_FLAGS -DILMBASE_ROOT_DIR=${CMAKE_INSTALL_PREFIX} -DILMBASE_ROOT=${CMAKE_INSTALL_PREFIX} -DILMBASE_INCLUDE_PATH=${CMAKE_INSTALL_PREFIX}/include)
    set(OPENEXR_CMAKE_FLAGS ${ILMBASE_CMAKE_FLAGS} -DOPENEXR_ROOT_DIR=${CMAKE_INSTALL_PREFIX} -DOPENEXR_ROOT=${CMAKE_INSTALL_PREFIX} -DOPENEXR_INCLUDE_PATH=${CMAKE_INSTALL_PREFIX}/include)


    set(TIFF_TARGET tiff)
    ExternalProject_Add(${TIFF_TARGET}
            URL http://download.osgeo.org/libtiff/tiff-4.0.10.tar.gz
            PREFIX ${BUILD_DIR}
            BUILD_IN_SOURCE 0
            BUILD_ALWAYS 0
            UPDATE_COMMAND ""
            SOURCE_DIR ${CMAKE_CURRENT_BINARY_DIR}/tiff
            BINARY_DIR ${BUILD_DIR}/tiff_build
            INSTALL_DIR ${CMAKE_INSTALL_PREFIX}
            CONFIGURE_COMMAND <SOURCE_DIR>/configure --prefix=<INSTALL_DIR>
            DEPENDS ${ZLIB_TARGET}
            )
    SET(TIFF_CMAKE_FLAGS -DTIFF_LIBRARY=${CMAKE_INSTALL_PREFIX}/lib/libtiff.so -DTIFF_INCLUDE_DIR=${CMAKE_INSTALL_PREFIX}/include)

    set(PNG_TARGET png)
    ExternalProject_Add(${PNG_TARGET}
            URL http://github.com/glennrp/libpng-releases/raw/master/libpng-1.6.34.tar.gz
            #    http://prdownloads.sourceforge.net/libpng/libpng-1.6.34.tar.gz
            #    https://sourceforge.net/projects/libpng/files/libpng16/1.6.34/libpng-1.6.34.tar.gz
            PREFIX ${BUILD_DIR}
            BUILD_IN_SOURCE 0
            BUILD_ALWAYS 0
            UPDATE_COMMAND ""
            SOURCE_DIR ${CMAKE_CURRENT_BINARY_DIR}/png
            BINARY_DIR ${BUILD_DIR}/png_build
            INSTALL_DIR ${CMAKE_INSTALL_PREFIX}
            # CONFIGURE_COMMAND <SOURCE_DIR>/configure --prefix=<INSTALL_DIR>
            CONFIGURE_COMMAND ${CMAKE_COMMAND} ${CMAKE_CORE_BUILD_FLAGS} ${ZLIB_CMAKE_FLAGS} -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR> <SOURCE_DIR>
            DEPENDS ${ZLIB_TARGET}
            )
    SET(PNG_CMAKE_FLAGS -DPNG_LIBRARY=${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR}/libpng.so -DPNG_PNG_INCLUDE_DIR=${CMAKE_INSTALL_PREFIX}/include)


    set(JPEG_TARGET turbojpeg)
    set(JPEG_FILENAME 1.5.3.tar.gz)
    # Add turbojpeg
    ExternalProject_Add(${JPEG_TARGET}
            URL https://github.com/libjpeg-turbo/libjpeg-turbo/archive/${JPEG_FILENAME}
            DOWNLOAD_NAME turbojpeg-${JPEG_FILENAME}
            PREFIX ${BUILD_DIR}
            BUILD_IN_SOURCE 0
            BUILD_ALWAYS 0
            UPDATE_COMMAND ""
            SOURCE_DIR ${CMAKE_CURRENT_BINARY_DIR}/turbojpeg
            BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR}/turbojpeg
            INSTALL_DIR ${CMAKE_INSTALL_PREFIX}
            CONFIGURE_COMMAND cd <BINARY_DIR> && autoreconf -fiv && ./configure --prefix=<INSTALL_DIR>
            DEPENDS ${ZLIB_TARGET}
            )
    SET(JPEG_CMAKE_FLAGS -DJPEG_LIBRARY=${CMAKE_INSTALL_PREFIX}/lib/libjpeg.so -DJPEG_INCLUDE_DIR=${CMAKE_INSTALL_PREFIX}/include)

    # Add OpenImageIO
    set(OPENIMAGEIO_TARGET openimageio)
    set(OPENIMAGEIO_FILENAME Release-2.0.3.tar.gz)
    ExternalProject_Add(${OPENIMAGEIO_TARGET}
            URL https://github.com/OpenImageIO/oiio/archive/${OPENIMAGEIO_FILENAME}
            DOWNLOAD_NAME oiio-${OPENIMAGEIO_FILENAME}
            PREFIX ${BUILD_DIR}
            BUILD_IN_SOURCE 0
            BUILD_ALWAYS 0
            UPDATE_COMMAND ""
            SOURCE_DIR ${CMAKE_CURRENT_BINARY_DIR}/openimageio
            BINARY_DIR ${BUILD_DIR}/openimageio_build
            INSTALL_DIR ${CMAKE_INSTALL_PREFIX}
            CONFIGURE_COMMAND ${CMAKE_COMMAND} -DCMAKE_CXX_FLAGS="-Wno-deprecated-declarations" ${CMAKE_CORE_BUILD_FLAGS} -D_OPENEXR_VERSION:STRING=${OPENEXR_VERSION} -DCMAKE_PREFIX_PATH="${CMAKE_INSTALL_PREFIX}" -DBOOST_ROOT=${CMAKE_INSTALL_PREFIX} -DOIIO_BUILD_TESTS:BOOL=OFF -DILMBASE_HOME=${CMAKE_INSTALL_PREFIX} -DOPENEXR_HOME=${CMAKE_INSTALL_PREFIX} ${TIFF_CMAKE_FLAGS} ${ZLIB_CMAKE_FLAGS} ${PNG_CMAKE_FLAGS} ${JPEG_CMAKE_FLAGS} ${LIBRAW_CMAKE_FLAGS} ${OPENEXR_CMAKE_FLAGS} -DCMAKE_INSTALL_PREFIX:PATH=<INSTALL_DIR> <SOURCE_DIR> -DUSE_PYTHON=OFF -DUSE_OPENCV=OFF -DUSE_OPENGL=OFF
            DEPENDS ${BOOST_TARGET} ${OPENEXR_TARGET} ${TIFF_TARGET} ${PNG_TARGET} ${JPEG_TARGET} ${LIBRAW_TARGET} ${ZLIB_TARGET}
            )
    # TODO: openjpeg
    # -DOPENJPEG_INCLUDE_DIR=$OPENJPEG_INCLUDE_DIR/openjpeg-2.0 -DOPENJPEG_OPENJP2_LIBRARIES=$OPENJPEG_OPENJP2_LIBRARIES
    set(OPENIMAGEIO_CMAKE_FLAGS -DOPENIMAGEIO_INCLUDE_DIR_HINTS=${CMAKE_INSTALL_PREFIX} -DOPENIMAGEIO_INCLUDE_DIR_HINTS=${CMAKE_INSTALL_PREFIX})

    # Add Alembic: I/O for Point Cloud and Cameras
    set(ALEMBIC_TARGET alembic)
    set(ALEMBIC_FILENAME 1.7.10.tar.gz)
    ExternalProject_Add(${ALEMBIC_TARGET}
            URL https://github.com/alembic/alembic/archive/${ALEMBIC_FILENAME}
            DOWNLOAD_NAME alembic-${ALEMBIC_FILENAME}
            PREFIX ${BUILD_DIR}
            BUILD_IN_SOURCE 0
            BUILD_ALWAYS 0
            UPDATE_COMMAND ""
            SOURCE_DIR ${CMAKE_CURRENT_BINARY_DIR}/alembic
            BINARY_DIR ${BUILD_DIR}/alembic_build
            INSTALL_DIR ${CMAKE_INSTALL_PREFIX}
            CONFIGURE_COMMAND ${CMAKE_COMMAND} ${CMAKE_CORE_BUILD_FLAGS} ${ZLIB_CMAKE_FLAGS} ${ILMBASE_CMAKE_FLAGS} -DUSE_TESTS:BOOL=OFF -DCMAKE_INSTALL_PREFIX:PATH=<INSTALL_DIR> <SOURCE_DIR>
            DEPENDS ${BOOST_TARGET} ${OPENEXR_TARGET} ${ZLIB_TARGET}
            )
    set(ALEMBIC_CMAKE_FLAGS -DAlembic_DIR:PATH=${CMAKE_INSTALL_PREFIX}/lib/cmake/Alembic)

    # this is only needed by meshroom
#    set(QMLALEMBIC_CONFIG_COMMAND ${CMAKE_COMMAND} -DCMAKE_PREFIX_PATH:PATH=${CMAKE_INSTALL_PREFIX}$<SEMICOLON>${EESEP_QT5_PATH})
    ExternalProject_Add(qmlAlembic
            GIT_REPOSITORY https://github.com/alicevision/qmlAlembic.git
            GIT_TAG develop
            PREFIX ${BUILD_DIR}
            BUILD_IN_SOURCE 0
            BUILD_ALWAYS 0
            SOURCE_DIR ${CMAKE_CURRENT_BINARY_DIR}/qmlAlembic
            BINARY_DIR ${BUILD_DIR}/qmlAlembic_build
            INSTALL_DIR ${CMAKE_INSTALL_PREFIX}
            CONFIGURE_COMMAND ${CMAKE_COMMAND} -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DCMAKE_PREFIX_PATH:PATH=${CMAKE_INSTALL_PREFIX}$<SEMICOLON>${EESEP_QT5_PATH} -DBUILD_SHARED_LIBS:BOOL=ON ${ALEMBIC_CMAKE_FLAGS} -DCMAKE_INSTALL_PREFIX:PATH=<INSTALL_DIR> <SOURCE_DIR>
#            CONFIGURE_COMMAND ${QMLALEMBIC_CONFIG_COMMAND} -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DBUILD_SHARED_LIBS:BOOL=ON ${ALEMBIC_CMAKE_FLAGS} -DCMAKE_INSTALL_PREFIX:PATH=<INSTALL_DIR> <SOURCE_DIR>
            DEPENDS ${ALEMBIC_TARGET}
            )

    set(AV_DEPS
            ${ZLIB_TARGET}
            ${GEOGRAM_TARGET}
            ${CUDA_TARGET}
            ${TBB_TARGET}
            ${EIGEN_TARGET}
            ${OPENGV_TARGET}
            ${LAPACK_TARGET}
            ${SUITESPARSE_TARGET}
            ${CERES_TARGET}
            ${OPENEXR_TARGET}
            ${TIFF_TARGET}
            ${PNG_TARGET}
            ${JPEG_TARGET}
            ${LIBRAW_TARGET}
            ${BOOST_TARGET}
            ${OPENIMAGEIO_TARGET}
            ${ALEMBIC_TARGET}
            ${POPSIFT_TARGET}
            )

    ExternalProject_Add(aliceVision
            GIT_REPOSITORY https://github.com/alicevision/AliceVision
            GIT_TAG develop
            PREFIX ${BUILD_DIR}
            BUILD_IN_SOURCE 0
            BUILD_ALWAYS 0
            SOURCE_DIR ${CMAKE_CURRENT_BINARY_DIR}/aliceVision
            BINARY_DIR ${BUILD_DIR}/aliceVision_build
            INSTALL_DIR ${CMAKE_INSTALL_PREFIX}
            CONFIGURE_COMMAND ${CMAKE_COMMAND} -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DCMAKE_PREFIX_PATH=${CMAKE_INSTALL_PREFIX} -DBUILD_SHARED_LIBS:BOOL=ON -DTARGET_ARCHITECTURE=core -DALICEVISION_ROOT=${ALICEVISION_ROOT} -DALICEVISION_USE_ALEMBIC=ON -DMINIGLOG=ON -DALICEVISION_USE_OPENCV=OFF -DALICEVISION_USE_OPENGV=OFF -DALICEVISION_USE_POPSIFT=ON -DALICEVISION_USE_CUDA=ON -DALICEVISION_BUILD_DOC=OFF -DALICEVISION_BUILD_EXAMPLES=OFF ${ZLIB_CMAKE_FLAGS} ${EIGEN_CMAKE_FLAGS} ${OPENIMAGEIO_CMAKE_FLAGS} ${OPENEXR_CMAKE_FLAGS} ${BOOST_CMAKE_FLAGS} ${ALEMBIC_CMAKE_FLAGS} ${GEOGRAM_CMAKE_FLAGS} ${LAPACK_CMAKE_FLAGS} ${CERES_CMAKE_FLAGS} ${CUDA_CMAKE_FLAGS} ${POPSIFT_CMAKE_FLAGS} ${OPENGV_CMAKE_FLAGS} -DALICEVISION_BUILD_SHARED=ON -DCMAKE_INSTALL_PREFIX:PATH=<INSTALL_DIR> <SOURCE_DIR>
            DEPENDS ${AV_DEPS}
            )
endif()