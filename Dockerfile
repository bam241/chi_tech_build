FROM --platform=linux/x86-64 ubuntu:20.04
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y build-essential gfortran cmake python3 python-is-python3 git zlib1g-dev libx11-dev unzip mpich tar wget
ENV CC=mpicc
ENV CXX=mpicxx
ENV FC=mpifort
ENV INSTALL_DIR=/root/.local
RUN mkdir ${INSTALL_DIR}
WORKDIR /root
RUN wget https://ftp.mcs.anl.gov/pub/petsc/release-snapshots/petsc-3.17.0.tar.gz;\
    tar -zxf petsc-3.17.0.tar.gz;\
    cd petsc-3.17.0;\
    ./configure  --prefix=$INSTALL_DIR  \
        --download-hypre=1  --with-ssl=0  --with-debugging=0  \
        --with-pic=1  --with-shared-libraries=1  --download-fblaslapack=1  \
        --download-metis=1  --download-parmetis=1  --download-superlu_dist=1  \
        --with-cxx-dialect=C++11  --with-64-bit-indices CC=$CC CXX=$CXX FC=$FC \
        CFLAGS='-fPIC -fopenmp'  CXXFLAGS='-fPIC -fopenmp'  \
        FFLAGS='-fPIC -fopenmp'  FCFLAGS='-fPIC -fopenmp'  \
        F90FLAGS='-fPIC -fopenmp'  F77FLAGS='-fPIC -fopenmp'  \
        COPTFLAGS='-O3 -march=native -mtune=native'  \
        CXXOPTFLAGS='-O3 -march=native -mtune=native'  \
        FOPTFLAGS='-O3 -march=native -mtune=native'  PETSC_DIR=$PWD  \
        --download-cmake
RUN  cd petsc-3.17.0; make -j8 && make install
ENV PETSC_ROOT=$INSTALL_DIR
RUN mkdir VTK;\
    cd VTK;\
    wget https://www.vtk.org/files/release/9.1/VTK-9.1.0.tar.gz;\
    tar -zxf VTK-9.1.0.tar.gz;\
    cd VTK-9.1.0;\
    mkdir build;\
    cd build;\
    cmake -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR \
          -DBUILD_SHARED_LIBS:BOOL=ON \
          -DVTK_Group_MPI:BOOL=ON \
          -DVTK_GROUP_ENABLE_Qt=NO  \
          -DVTK_GROUP_ENABLE_Rendering=NO  \
          -DVTK_GROUP_ENABLE_Imaging=NO  \
          -DVTK_GROUP_ENABLE_StandAlone=WANT \
          -DVTK_GROUP_ENABLE_Web=NO \
          -DVTK_BUILD_TESTING:BOOL=OFF \
          -DCMAKE_BUILD_TYPE=Release \
          -DCMAKE_CXX_FLAGS=-std=c++11 \
          ../ &&\
    make -j8 && make install
ENV VTK_DIR=$INSTALL_DIR
RUN wget https://invisible-mirror.net/archives/ncurses/ncurses-6.1.tar.gz; \
    tar -zxf ncurses-6.1.tar.gz; \
    cd ncurses-6.1; \
    ./configure --prefix=$INSTALL_DIR; \
    make -j8 && make install
RUN wget ftp://ftp.gnu.org/gnu/readline/readline-8.0.tar.gz;\
    tar -zxf readline-8.0.tar.gz;\
    cd readline-8.0;\
    ./configure --prefix=$PWD/chi_build;\
    make -j8 && make install
ENV CPATH=/${INSTALL_DIR}:$CPATH
ENV LIBRARY_PATH=${INSTALL_DIR}/lib/:/root/ncurses-6.1/chi_build/lib/:$LIBRARY_PATH
RUN apt-get install -y lua5.3 liblua5.3-dev
# RUN wget https://www.lua.org/ftp/lua-5.4.6.tar.gz; \
#     tar -xvf lua-5.4.6.tar.gz; \
#     cd lua-5.4.6; \
#     make linux && make local
ENV LUA_ROOT="/usr/include/lua5.3"
RUN git clone https://github.com/bam241/chi-tech; \
    cd chi-tech; \
    ./configure.sh; \
    make -j4
ENV LD_LIBRARY_PATH=${INSTALL_DIR}/lib/:/root/ncurses-6.1/chi_build/lib/:$LIBRARY_PATH
