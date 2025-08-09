# COLMAP Complete Documentation

*Scraped from https://colmap.github.io/*


## Table of Contents

### Main Documentation (13 items)
### PyCOLMAP Python Bindings (4 items)

---

### Documentation: Colmap.Github.Io

## Colmap.Github.Io

COLMAP
COLMAP
Sparse model of central Rome using 21K photos produced by COLMAP’s SfM
pipeline.
Dense models of several landmarks produced by COLMAP’s MVS pipeline.
About
COLMAP is a general-purpose Structure-from-Motion (SfM) and Multi-View Stereo
(MVS) pipeline with a graphical and command-line interface. It offers a wide
range of features for reconstruction of ordered and unordered image collections.
The software is licensed under the new BSD license. If you use this project for
your research, please cite:
@inproceedings
schoenberger2016sfm
author
nberger, Johannes Lutz and Frahm, Jan-Michael},
title
Structure
from
Motion
Revisited
booktitle
Conference
Computer
Vision
Pattern
Recognition
CVPR
year
2016
@inproceedings
schoenberger2016mvs
author
nberger, Johannes Lutz and Zheng, Enliang and Pollefeys, Marc and Frahm, Jan-Michael},
title
Pixelwise
View
Selection
Unstructured
Multi
View
Stereo
booktitle
European
Conference
Computer
Vision
ECCV
year
2016
If you use the image retrieval / vocabulary tree engine, please also cite:
@inproceedings
schoenberger2016vote
author
nberger, Johannes Lutz and Price, True and Sattler, Torsten and Frahm, Jan-Michael and Pollefeys, Marc},
title
Vote
Verify
Strategy
Fast
Spatial
Verification
Image
Retrieval
booktitle
Asian
Conference
Computer
Vision
ACCV
year
2016
The latest source code is available at
GitHub
. COLMAP builds on top of existing works and
when using specific algorithms within COLMAP, please also cite the original
authors, as specified in the source code.
Download
Executables and other resources can be downloaded from
https://demuc.de/colmap/
Getting Started
Download the
pre-built binaries
or build the
library manually from
source
(see
Installation
Download one of the provided datasets (see
Datasets
or use your own images.
Use the
automatic reconstruction
to easily build models
with a single click (see
Quickstart
Support
Please, use
GitHub Discussions
for questions and the
GitHub issue tracker
for bug reports, feature requests/additions, etc.
Acknowledgments
COLMAP was originally written by
Johannes Schönberger
with
funding provided by his PhD advisors Jan-Michael Frahm and Marc Pollefeys.
The team of core project maintainers currently includes
Johannes Schönberger
Paul-Edouard Sarlin
, and
Shaohui Liu
The Python bindings in PyCOLMAP were originally added by
Mihai Dusmanu
Philipp Lindenberger
, and
Paul-Edouard Sarlin
The project has also benefitted from countless community contributions, including
bug fixes, improvements, new features, third-party tooling, and community
support (special credits to
Torsten Sattler


---

### Documentation: Install.Html

## Install.Html

Installation
Installation
You can either download one of the pre-built binaries or build the source code
manually. Pre-built binaries and other resources can be downloaded from
https://demuc.de/colmap/
An overview of system packages for Linux/Unix/BSD distributions are available at
https://repology.org/metapackage/colmap/versions
. Note that the COLMAP packages
in the default repositories for Linux/Unix/BSD do not come with CUDA support,
which requires a manual build from source, as explained further below.
For Mac users,
Homebrew
provides a formula for COLMAP with
pre-compiled binaries or the option to build from source. After installing
homebrew, installing COLMAP is as easy as running
brew
install
colmap
COLMAP can be used as an independent application through the command-line or
graphical user interface. Alternatively, COLMAP is also built as a reusable
library, i.e., you can include and link COLMAP against your own C++ source code,
as described further below. Furthermore, you can use most of COLMAP’s
functionality with
PyCOLMAP
in Python.
Pre-built Binaries
Windows
For convenience, the pre-built binaries for Windows contain both the graphical
and command-line interface executables. To start the COLMAP GUI, you can simply
double-click  the
COLMAP.bat
batch script or alternatively run it from the
Windows command shell or Powershell. The command-line interface is also
accessible through this batch script, which automatically sets the necessary
library paths. To list the available COLMAP commands, run
COLMAP.bat
the command shell
cmd.exe
or in Powershell. The first time you run COLMAP,
Windows defender may prompt you with a security warning, because the binaries
are not officially signed. The provided COLMAP binaries are automatically built
from GitHub Actions CI machines. If you do not trust them, you can build from
source as described below.
Docker
COLMAP provides a pre-built Docker image with CUDA support. For detailed
instructions on how to build and run COLMAP using Docker, please refer to the
Docker documentation
Build from Source
COLMAP builds on all major platforms (Linux, Mac, Windows) with little effort.
First, checkout the latest source code:
clone
https
github
colmap
colmap
Under Linux and Mac, it is generally recommended to follow the installation
instructions below, which use the respective system package managers to install
the required dependencies. Alternatively, the instructions for VCPKG can be used
to compile the required dependencies from scratch on more exotic systems with
limited system packages. The VCPKG approach is also the method of choice under
Windows, compute clusters, or if you do not have root access under Linux or Mac.
Debian/Ubuntu
Recommended dependencies:
CUDA (at least version 7.X)
Dependencies from the default Ubuntu repositories:
sudo
install
cmake
ninja
build
build
essential
libboost
program
options
libboost
graph
libboost
system
libeigen3
libfreeimage
libmetis
libgoogle
glog
libgtest
libgmock
libsqlite3
libglew
qtbase5
libqt5opengl5
libcgal
libceres
libcurl4
openssl
libmkl
full
To compile with
CUDA support
, also install Ubuntu’s default CUDA package:
sudo
install
nvidia
cuda
toolkit
nvidia
cuda
toolkit
Or, manually install the latest CUDA from NVIDIA’s homepage. During CMake
configuration, specify
-DCMAKE_CUDA_ARCHITECTURES=native
, if you want to run
COLMAP only on your current machine (default), “all”/”all-major” to be able to
distribute to other machines, or a specific CUDA architecture like “75”, etc.
Configure and compile COLMAP:
clone
https
github
colmap
colmap
colmap
mkdir
build
build
cmake
GNinja
DBLA_VENDOR
Intel10_64lp
ninja
sudo
ninja
install
Run COLMAP:
colmap
colmap
Under
Ubuntu 18.04
, the CMake configuration scripts of CGAL are broken and
you must also install the CGAL Qt5 package:
sudo
install
libcgal
Under
Ubuntu 22.04
, there is a problem when compiling with Ubuntu’s default
CUDA package and GCC, and you must compile against GCC 10:
sudo
install
export
export
export
CUDAHOSTCXX
# ... and then run CMake against COLMAP's sources.
Notice that the
BLA_VENDOR=Intel10_64lp
option tells CMake to find Intel’s MKL
implementation of BLAS. If you decide to compile against OpenBLAS instead of
MKL, you must install and select the OpenMP version under Debian/Ubuntu because
this issue
Dependencies from
Homebrew
brew
install
cmake
ninja
boost
eigen
freeimage
curl
libomp
metis
glog
googletest
ceres
solver
glew
cgal
sqlite3
brew
link
force
libomp
Configure and compile COLMAP:
clone
https
github
colmap
colmap
colmap
mkdir
build
build
cmake
GNinja
DQt5_DIR
"$(brew --prefix qt@5)/lib/cmake/Qt5"
ninja
sudo
ninja
install
If you have Qt 6 installed on your system as well, you might have to temporarily
link your Qt 5 installation while configuring CMake:
brew
link
cmake
from
previous
code
block
brew
unlink
Run COLMAP:
colmap
colmap
Windows
Recommended dependencies:
CUDA (at least version 7.X), Visual Studio 2019
On Windows, the recommended way is to build COLMAP using VCPKG:
clone
https
github
microsoft
vcpkg
vcpkg
bootstrap
vcpkg
vcpkg
install
colmap
cuda
tests
windows
To compile CUDA for multiple compute architectures, please use:
vcpkg
install
colmap
cuda
redist
windows
Please refer to the next section for more details.
VCPKG
COLMAP ships as part of the VCPKG distribution. This enables to conveniently
build COLMAP and all of its dependencies from scratch under different platforms.
Note that VCPKG requires you to install CUDA manually in the standard way on
your platform. To compile COLMAP using VCPKG, you run:
clone
https
github
microsoft
vcpkg
vcpkg
bootstrap
vcpkg
vcpkg
install
colmap
linux
VCPKG ships with support for various other platforms (e.g., x64-osx,
x64-windows, etc.). To compile with CUDA support and to build all tests:
vcpkg
install
colmap
cuda
tests
linux
The above commands will build the latest release version of COLMAP. To compile
the latest commit in the dev branch, you can use the following options:
vcpkg
install
colmap
linux
head
To modify the source code, you can further add
--editable
--no-downloads
Or, if you want to build from another folder and use the dependencies from
vcpkg, first run
./vcpkg
integrate
install
(under Windows use pwsh and
./scripts/shell/enter_vs_dev_shell.ps1
) and then configure COLMAP as:
path
colmap
mkdir
build
build
cmake
DCMAKE_TOOLCHAIN_FILE
path
vcpkg
scripts
buildsystems
vcpkg
cmake
DCMAKE_BUILD_TYPE
Release
cmake
build
config
release
target
colmap
parallel
Library
If you want to include and link COLMAP against your own library, the easiest way
is to use CMake as a build configuration tool. After configuring the COLMAP
build and running
ninja/make
install
, COLMAP automatically installs all
headers to
${CMAKE_INSTALL_PREFIX}/include/colmap
, all libraries to
${CMAKE_INSTALL_PREFIX}/lib/colmap
, and the CMake configuration to
${CMAKE_INSTALL_PREFIX}/share/colmap
For example, compiling your own source code against COLMAP is as simple as
using the following
CMakeLists.txt
cmake_minimum_required
VERSION
3.10
project
SampleProject
find_package
colmap
REQUIRED
# or to require a specific version: find_package(colmap 3.4 REQUIRED)
add_executable
hello_world
hello_world
target_link_libraries
hello_world
colmap
colmap
with the source code
hello_world.cc
#include <cstdlib>
#include <iostream>
#include <colmap/controllers/option_manager.h>
#include <colmap/util/string.h>
main
argc
char
argv
colmap
InitializeGlog
argv
string
message
colmap
OptionManager
options
options
AddRequiredOption
"message"
message
options
Parse
argc
argv
cout
colmap
StringPrintf
"Hello
message
c_str
());
return
EXIT_SUCCESS
Then compile and run your code as:
mkdir build
cd build
export colmap_DIR=${CMAKE_INSTALL_PREFIX}/share/colmap
cmake .. -GNinja
ninja
./hello_world --message "world"
The sources of this example are stored under
doc/sample-project
AddressSanitizer
If you want to build COLMAP with address sanitizer flags enabled, you need to
use a recent compiler with ASan support. For example, you can manually install
a recent clang version on your Ubuntu machine and invoke CMake as follows:
clang
clang
cmake
DASAN_ENABLED
DTESTS_ENABLED
DCMAKE_BUILD_TYPE
RelWithDebInfo
Note that it is generally useful to combine ASan with debug symbols to get
meaningful traces for reported issues.
Documentation
You need Python and Sphinx to build the HTML documentation:
path
colmap
sudo
install
python
install
sphinx
make
html
open
_build
html
index
html
Alternatively, you can build the documentation as PDF, EPUB, etc.:
make
latexpdf
open
_build
COLMAP


---

### Documentation: Tutorial.Html

## Tutorial.Html

Tutorial
Tutorial
This tutorial covers the topic of image-based 3D reconstruction by demonstrating
the individual processing steps in COLMAP. If you are interested in a more
general and mathematical introduction to the topic of image-based 3D
reconstruction, please also refer to the
CVPR 2017 Tutorial on Large-scale 3D
Modeling from Crowdsourced Data
[schoenberger_thesis]
Image-based 3D reconstruction from images traditionally first recovers a sparse
representation of the scene and the camera poses of the input images using
Structure-from-Motion. This output then serves as the input to Multi-View Stereo
to recover a dense representation of the scene.
Quickstart
First, start the graphical user interface of COLMAP, as described
here
. COLMAP provides an automatic reconstruction tool that simply takes
a folder of input images and produces a sparse and dense reconstruction in a
workspace folder. Click
Reconstruction
Automatic
Reconstruction
in the GUI
and specify the relevant options. The output is written to the workspace folder.
For example, if your images are located in
path/to/project/images
, you could
select
path/to/project
as a workspace folder and after running the automatic
reconstruction tool, the folder would look similar to this:
+── images
│   +── image1.jpg
│   +── image2.jpg
│   +── ...
+── sparse
│   +── 0
│   │   +── rigs.bin
│   │   +── cameras.bin
│   │   +── frames.bin
│   │   +── images.bin
│   │   +── points3D.bin
│   +── ...
+── dense
│   +── 0
│   │   +── images
│   │   +── sparse
│   │   +── stereo
│   │   +── fused.ply
│   │   +── meshed-poisson.ply
│   │   +── meshed-delaunay.ply
│   +── ...
+── database.db
Here, the
path/to/project/sparse
contains the sparse models for all
reconstructed components, while
path/to/project/dense
contains their
corresponding dense models. The dense point cloud
fused.ply
can be imported
in COLMAP using
File
Import
model
from
, while the dense mesh must be
visualized with an external viewer such as Meshlab.
The following sections give general recommendations and describe the
reconstruction process in more detail, if you need more control over the
reconstruction process/parameters or if you are interested in the underlying
technology in COLMAP.
Structure-from-Motion
COLMAP’s incremental Structure-from-Motion pipeline.
Structure-from-Motion (SfM) is the process of reconstructing 3D structure from
its projections into a series of images. The input is a set of overlapping
images of the same object, taken from different viewpoints. The output is a 3-D
reconstruction of the object, and the reconstructed intrinsic and extrinsic
camera parameters of all images. Typically, Structure-from-Motion systems divide
this process into three stages:
Feature detection and extraction
Feature matching and geometric verification
Structure and motion reconstruction
COLMAP reflects these stages in different modules, that can be combined
depending on the application. More information on Structure-from-Motion in
general and the algorithms in COLMAP can be found in
[schoenberger16sfm]
[schoenberger16mvs]
If you have control over the picture capture process, please follow these
guidelines for optimal reconstruction results:
Capture images with
good texture
. Avoid completely texture-less images
(e.g., a white wall or empty desk). If the scene does not contain enough
texture itself, you could place additional background objects, such as
posters, etc.
Capture images at
similar illumination
conditions. Avoid high dynamic
range scenes (e.g., pictures against the sun with shadows or pictures
through doors/windows). Avoid specularities on shiny surfaces.
Capture images with
high visual overlap
. Make sure that each object is
seen in at least 3 images – the more images the better.
Capture images from
different viewpoints
. Do not take images from the
same location by only rotating the camera, e.g., make a few steps after each
shot. At the same time, try to have enough images from a relatively similar
viewpoint. Note that more images is not necessarily better and might lead to a
slow reconstruction process. If you use a video as input, consider
down-sampling the frame rate.
Multi-View Stereo
Multi-View Stereo (MVS) takes the output of SfM to compute depth and/or normal
information for every pixel in an image. Fusion of the depth and normal maps of
multiple images in 3D then produces a dense point cloud of the scene. Using the
depth and normal information of the fused point cloud, algorithms such as the
(screened) Poisson surface reconstruction
[kazhdan2013]
can then recover the 3D
surface geometry of the scene. More information on Multi-View Stereo in general
and the algorithms in COLMAP can be found in
[schoenberger16mvs]
Preface
COLMAP requires only few steps to do a standard reconstruction for a general
user. For more experienced users, the program exposes many different parameters,
only some of which are intuitive to a beginner. The program should usually work
without the need to modify any parameters. The defaults are chosen as a trade-
off between reconstruction robustness/quality and speed. You can set “optimal”
options for different reconstruction scenarios by choosing
Extras
options
data
. If in doubt what settings to choose, stick to the
defaults. The source code contains more documentation about all parameters.
COLMAP is research software and in rare cases it may exit ungracefully if some
constraints are not fulfilled. In this case, the program prints a traceback to
stdout. To see this traceback or more debug information, it is recommended to
run the executables (including the GUI) from the command-line, where you can
define various levels of logging verbosity.
Terminology
The term
camera
is associated with the physical object of a camera using the
same zoom-factor and lens. A camera defines the intrinsic projection model in
COLMAP. A single camera can take multiple images with the same resolution,
intrinsic parameters, and distortion characteristics. The term
image
associated with a bitmap file, e.g., a JPEG or PNG file on disk. COLMAP detects
keypoints
in each image whose appearance is described by numerical
descriptors
. Pure appearance-based correspondences between
keypoints/descriptors are defined by
matches
, while
inlier matches
geometrically verified and used for the reconstruction procedure.
Data Structure
COLMAP assumes that all input images are in one input directory with potentially
nested sub-directories. It recursively considers all images stored in this
directory, and it supports various different image formats (see
FreeImage
). Other files are
automatically ignored. If high performance is a requirement, then you should
separate any files that are not images. Images are identified uniquely by their
relative file path. For later processing, such as image undistortion or dense
reconstruction, the relative folder structure should be preserved. COLMAP does
not modify the input images or directory and all extracted data is stored in a
single, self-contained SQLite database file (see
Database Format
The first step is to start the graphical user interface of COLMAP by running the
pre-built binaries (Windows:
COLMAP.bat
, Mac:
COLMAP.app
) or by executing
./src/colmap/exe/colmap
from the CMake build folder. Next, create a new project
by choosing
File
project
. In this dialog, you must select where to
store the database and the folder that contains the input images. For
convenience, you can save the entire project settings to a configuration file by
choosing
File
Save
project
. The project configuration stores the absolute
path information of the database and image folder in addition to any other
parameter settings. If you decide to move the database or image folder, you must
change the paths accordingly by creating a new project. Alternatively, the
resulting
.ini
configuration file can be directly modified in a text editor of
your choice. To reopen an existing project, you can simply open the
configuration file by choosing
File
Open
project
and all parameter
settings should be recovered. Note that all COLMAP executables can be started
from the command-line by either specifying individual settings as command-line
arguments or by providing the path to the project configuration file (see
Interface
An example folder structure could look like this:
/path/to/project/...
+── images
│   +── image1.jpg
│   +── image2.jpg
│   +── ...
│   +── imageN.jpg
+── database.db
+── project.ini
In this example, you would select
/path/to/project/images
as the image folder
path,
/path/to/project/database.db
as the database file path, and save the
project configuration to
/path/to/project/project.ini
Feature Detection and Extraction
In the first step, feature detection/extraction finds sparse feature points in
the image and describes their appearance using a numerical descriptor. COLMAP
imports images and performs feature detection/extraction in one step in order to
only load images from disk once.
Next, choose
Processing
Extract
features
. In this dialog, you must first
decide on the employed intrinsic camera model. You can either automatically
extract focal length information from the embedded EXIF information or manually
specify intrinsic parameters, e.g., as obtained in a lab calibration. If an
image has partial EXIF information, COLMAP tries to find the missing camera
specifications in a large database of camera models automatically. If all your
images were captured by the same physical camera with identical zoom factor, it
is recommended to share intrinsics between all images. Note that the program
will exit ungracefully if the same camera model is shared among all images but
not all images have the same size or EXIF focal length. If you have several
groups of images that share the same intrinsic camera parameters, you can easily
modify the camera models at a later point as well (see
Database Management
). If in doubt what to choose in this step, simply stick
to the default parameters.
You can either detect and extract new features from the images or import
existing features from text files. COLMAP extracts SIFT
[lowe04]
features
either on the GPU or the CPU. The GPU version requires an attached display,
while the CPU version is recommended for use on a server. In general, the GPU
version is favorable as it has a customized feature detection mode that often
produces higher quality features in the case of high contrast images. If you
import existing features, every image must have a text file next to it (e.g.,
/path/to/image1.jpg
/path/to/image1.jpg.txt
) in the following format:
NUM_FEATURES
SCALE
ORIENTATION
D_128
SCALE
ORIENTATION
D_128
where
SCALE,
ORIENTATION
are floating point numbers and
D_1...D_128
values in the range
0...255
. The file should have
NUM_FEATURES
lines with
one line per feature. For example, if an image has 4 features, then the text
file should look something like this:
Note that by convention the upper left corner of an image has coordinate
and the center of the upper left most pixel has coordinate
(0.5,
0.5)
. If
you must  import features for large image collections, it is much more efficient
to directly access the database with your favorite scripting language (see
Database Format
If you are done setting all options, choose
Extract
and wait for the
extraction to finish or cancel. If you cancel during the extraction process, the
next time you start extracting images for the same project, COLMAP automatically
continues where it left off. This also allows you to add images to an existing
project/reconstruction. In this case, be sure to verify the camera parameters
when using shared intrinsics.
All extracted data will be stored in the database file and can be
reviewed/managed in the database management tool (see
Database Management
) or, for experts, directly modified using SQLite (see
Database Format
Feature Matching and Geometric Verification
In the second step, feature matching and geometric verification finds
correspondences between the feature points in different images.
Please, choose
Processing
Feature
matching
and select one of the provided
matching modes, that are intended for different input scenarios:
Exhaustive Matching
: If the number of images in your dataset is
relatively low (up to several hundreds), this matching mode should be fast
enough and leads to the best reconstruction results. Here, every image is
matched against every other image, while the block size determines how many
images are loaded from disk into memory at the same time.
Sequential Matching
: This mode is useful if the images are acquired in
sequential order, e.g., by a video camera. In this case, consecutive frames
have visual overlap and there is no need to match all image pairs
exhaustively. Instead, consecutively captured images are matched against each
other. This matching mode has built-in loop detection based on a vocabulary
tree, where every N-th image (
loop_detection_period
) is matched against its
visually most similar images (
loop_detection_num_images
). Note that image
file names must be ordered sequentially (e.g.,
image0001.jpg
image0002.jpg
, etc.). The order in the database is not relevant, since the
images are explicitly ordered according to their file names. Note that loop
detection requires a pre-trained vocabulary tree. A default tree will be
automatically downloaded and cached. More trees are available and can be
downloaded from
https://demuc.de/colmap/
. In case rigs and frames are
configured appropriately in the database, sequential matching will
automatically match all images in consecutive frames against each other.
Vocabulary Tree Matching
: In this matching mode
[schoenberger16vote]
every image is matched against its visual nearest neighbors using a vocabulary
tree with spatial re-ranking. This is the recommended matching mode for large
image collections (several thousands). This requires a pre-trained vocabulary
tree, that can be downloaded from
https://demuc.de/colmap/
Spatial Matching
: This matching mode matches every image against its
spatial nearest neighbors. Spatial locations can be manually set in the
database management. By default, COLMAP also extracts GPS information from
EXIF and uses it for spatial nearest neighbor search. If accurate prior
location information is available, this is the recommended matching mode.
Transitive Matching
: This matching mode uses the transitive relations of
already existing feature matches to produce a more complete matching graph.
If an image A matches to an image B and B matches to C, then this matcher
attempts to match A to C directly.
Custom Matching
: This mode allows to specify individual image pairs for
matching or to import individual feature matches. To specify image pairs, you
have to provide a text file with one image pair per line:
image1
image2
image1
image3
where
image1.jpg
is the relative path in the image folder. You have two
options to import individual feature matches. Either raw feature matches,
which are not geometrically verified or already geometrically verified feature
matches. In both cases, the expected format is:
image1
image2
empty
line
image1
image3
empty
line
where
image1.jpg
is the relative path in the image folder and the pairs of
numbers are zero-based feature indices in the respective images. If you must
import many matches for large image collections, it is more efficient to
directly access the database with a scripting language of your choice.
If you are done setting all options, choose
Match
and wait for the matching
to finish or cancel in between. Note that this step can take a significant
amount of time depending on the number of images, the number of features per
image, and the chosen matching mode. Expected times for exhaustive matching are
from a few minutes for tens of images to a few hours for hundreds of images to
days or weeks for thousands of images. If you cancel the matching process or
import new images after matching, COLMAP only matches image pairs that have not
been matched previously. The overhead of skipping already matched image pairs is
low. This also enables to match additional images imported after an initial
matching and it enables to combine different matching modes for the same
dataset.
All extracted data will be stored in the database file and can be
reviewed/managed in the database management tool (see
Database Management
) or, for experts, directly modified using SQLite (see
Database Format
Note that feature matching requires a GPU and that the display performance of
your computer might degrade significantly during the matching process. If your
system has multiple CUDA-enabled GPUs, you can select specific GPUs with the
gpu_index
option.
Sparse Reconstruction
After producing the scene graph in the previous two steps, you can start the
incremental reconstruction process by choosing
Reconstruction
Start
COLMAP first loads all extracted data from the database into memory and seeds
the reconstruction from an initial image pair. Then, the scene is incrementally
extended by registering new images and triangulating new points. The results are
visualized in “real-time” during this reconstruction process. Refer to the
Graphical User Interface
section for more details about the
available controls. COLMAP attempts to reconstruct multiple models if not all
images are registered into the same model. The different models can be selected
from the drop-down menu in the toolbar. If the different models have common
registered images, you can use the
model_converter
executable to merge them
into a single reconstruction (see
for details).
Ideally, the reconstruction works fine and all images are registered. If this is
not the case, it is recommended to:
Perform additional matching. For best results, use exhaustive matching, enable
guided matching, increase the number of nearest neighbors in vocabulary tree
matching, or increase the overlap in sequential matching, etc.
Manually choose an initial image pair, if COLMAP fails to initialize. Choose
Reconstruction
Reconstruction
options
Init
and set images from the
database management tool that have enough matches from different viewpoints.
Importing and Exporting
COLMAP provides several export options for further processing. For full
flexibility, it is recommended to export the reconstruction in COLMAP’s data
format by choosing
File
Export
to export the currently viewed model or
File
Export
to export all reconstructed models. The model is exported
in the selected folder using separate text files for the reconstructed cameras,
images, and points. When exporting in COLMAP’s data format, you can re- import
the reconstruction for later visualization, image undistortion, or to continue
an existing reconstruction from where it left off (e.g., after importing and
matching new images). To import a model, choose
File
Import
and select the
export folder path. Alternatively, you can also export the model in various
other formats, such as Bundler, VisualSfM
, PLY, or VRML by choosing
File
Export
as...
. COLMAP can visualize plain PLY point cloud files with
RGB information by choosing
File
Import
From...
. Further information about
the format of the exported models can be found
here
Dense Reconstruction
After reconstructing a sparse representation of the scene and the camera poses
of the input images, MVS can now recover denser scene geometry. COLMAP has an
integrated dense reconstruction pipeline to produce depth and normal maps for
all registered images, to fuse the depth and normal maps into a dense point
cloud with normal information, and to finally estimate a dense surface from the
fused point cloud using Poisson
[kazhdan2013]
or Delaunay reconstruction.
To get started, import your sparse 3D model into COLMAP (or select the
reconstructed model after finishing the previous sparse reconstruction steps).
Then, choose
Reconstruction
Multi-view
stereo
and select an empty or
existing workspace folder, which is used for the output and of all dense
reconstruction results. The first step is to
undistort
the images, second to
compute the depth and normal maps using
stereo
, third to
fuse
the depth
and normals maps to a point cloud, followed by a final, optional point cloud
meshing
step. During the stereo reconstruction process, the display might
freeze due to heavy compute load and, if your GPU does not have enough memory,
the reconstruction process might ungracefully crash. Please, refer to the FAQ
freeze
memory
) for
information on how to avoid these problems. Note that the reconstructed normals
of the point cloud cannot be directly visualized in COLMAP, but e.g. in Meshlab
by enabling
Render
Show
Normal/Curvature
. Similarly, the reconstructed
dense surface mesh model must be visualized with external software.
In addition to the internal dense reconstruction functionality, COLMAP exports
to several other dense reconstruction libraries, such as CMVS/PMVS
[furukawa10]
or CMP-MVS
[jancosek11]
. Please choose
Extras
Undistort
images
and select
the appropriate format. The output folders contain the reconstruction and the
undistorted images. In addition, the folders contain sample shell scripts to
perform the dense reconstruction. To run PMVS2, execute the following commands:
./path/to/pmvs2 /path/to/undistortion/folder/pmvs/ option-all
where
/path/to/undistortion/folder
is the folder selected in the undistortion
dialog. Make sure not to forget the trailing slash in
/path/to/undistortion/folder/pmvs/
in the above command-line arguments.
For large datasets, you probably want to first run CMVS to cluster the scene
into more manageable parts and then run COLMAP or PMVS2. Please, refer to the
sample shell scripts in the undistortion output folder on how to run CMVS in
combination with COLMAP or PMVS2. Moreover, there are a number of external
libraries that support COLMAP’s output:
CMVS/PMVS
[furukawa10]
CMP-MVS
[jancosek11]
Line3D++
[hofer16]
Database Management
You can review and manage the imported cameras, images, and feature matches in
the database management tool. Choose
Processing
Manage
database
. In the
opening dialog, you can see the list of imported images and cameras. You can
view the features and matches for each image by clicking
Show
image
Overlapping
images
. Individual entries in the database tables can be
modified by double clicking specific cells. Note that any changes to the
database are only effective after clicking
Save
To share intrinsic camera parameters between arbitrary groups of images, select
a single or multiple images, choose
camera
and set the
camera_id
which corresponds to the unique
camera_id
column in the cameras table. You can
also add new cameras with specific parameters. By setting the
prior_focal_length
flag to 0 or 1, you can give a hint whether the
reconstruction algorithm should trust the focal length value. In case of a prior
lab calibration, you want to set this value to 1. Without prior knowledge about
the focal length, it is recommended to set this value to
1.25
max(width_in_px,
height_in_px)
The database management tool has only limited functionality and, for full
control over the data, you must directly modify the SQLite database (see
Database Format
). By accessing the database directly,
you can use COLMAP only for feature extraction and matching or you can import
your own features and matches to only use COLMAP’s incremental reconstruction
algorithm.
Graphical and Command-line Interface
Most of COLMAP’s features are accessible from both the graphical and the
command-line interface, which are both embedded in the same executable. You can
provide the options directly as command-line arguments or you can provide a
.ini
project configuration file containing the options using the
--project_path
path/to/project.ini
argument. To start the GUI application,
please execute
colmap
or directly specify a project configuration as
colmap
--project_path
path/to/project.ini
to avoid tedious selection in
the GUI. To list the different commands available from the command-line, execute
colmap
help
. For example, to run feature extraction from the command-line,
you must execute
colmap
feature_extractor
. The
graphical user
interface
command-line Interface
sections provide more
details about the available commands.
Footnotes
VisualSfM’s
[wu13]
projection model applies the distortion to the
measurements and COLMAP to the projection, hence the exported NVM file is
not fully compatible with VisualSfM.


---

### Documentation: Gui.Html

## Gui.Html

Graphical User Interface
Graphical User Interface
The graphical user interface of COLMAP provides access to most of the available
functionality and visualizes the reconstruction process in “real-time”. To start
the GUI, you can run the pre-built packages (Windows:
COLMAP.bat
, Mac:
COLMAP.app
), execute
colmap
if you installed COLMAP or execute
./src/colmap/exe/colmap
from the CMake build folder. The GUI application
requires an attached display with at least OpenGL 3.2 support. Registered images
are visualized in red and reconstructed points in their average point color
extracted from the images. The viewer can also visualize dense point clouds
produced from Multi-View Stereo.
Model Viewer Controls
Rotate model
: Left-click and drag.
Shift model
: Right-click or <CTRL>-click (<CMD>-click) and drag.
Zoom model
: Scroll.
Change point size
: <CTRL>-scroll (<CMD>-scroll).
Change camera size
: <ALT>-scroll.
Adjust clipping plane
: <SHIFT>-scroll.
Select point
: Double-left-click point (change point size if too small).
The green lines visualize the projections into the images that see the point.
The opening window shows the projected locations of the point in all images.
Select camera
: Double-left-click camera (change camera size if too small).
The purple lines visualize images that see at least one common point with the
selected image. The opening window shows a few statistics of the image.
Reset view
: To reset all viewing settings, choose
Render
Reset
view
Render Options
The model viewer allows you to render the model with different settings,
projections, colormaps, etc. Please, choose
Render
Render
options
Create Screenshots
To create screenshots of the current viewpoint (without coordinate axes), choose
Extras
Grab
image
and save the image in the format of your choice.
Create Screencast
To create a video screen capture of the reconstructed model, choose
Extras
Grab
movie
. This dialog allows you to set individual control viewpoints by
choosing
. COLMAP generates a fixed number of frames per second between
each control viewpoint by smoothly interpolating the linear trajectory, and to
interpolate the configured point and the camera sizes at the time of clicking
. To change the number of frames between two viewpoints or to reorder
individual viewpoints, modify the time of the viewpoint by double-clicking the
respective cell in the table. Note that the video capture requires to set the
perspective projection model in the render options. You can review the
trajectory in the viewer, which is rendered in light blue. Choose
Assemble
movie
, if you are done creating the trajectory. The output directory then
contains the individual frames of the video capture, which can be assembled to a
movie using
FFMPEG
with the following command:
ffmpeg
frame
scale
1680
1050
movie


---

### Documentation: Cli.Html

## Cli.Html

Command-line Interface
Command-line Interface
The command-line interface provides access to all of COLMAP’s functionality for
automated scripting. Each core functionality is implemented as a command to the
colmap
executable. Run
colmap
to list the available commands (or
COLMAP.bat
under Windows). Note that if you run COLMAP from the CMake
build folder, the executable is located at
./src/colmap/exe/colmap
. To start the
graphical user interface, run
colmap
Example
Assuming you stored the images of your project in the following structure:
/path/to/project/...
+── images
│   +── image1.jpg
│   +── image2.jpg
│   +── ...
│   +── imageN.jpg
The command for the automatic reconstruction tool would be:
# The project folder must contain a folder "images" with all the images.
$ DATASET_PATH=/path/to/project
$ colmap automatic_reconstructor \
--workspace_path $DATASET_PATH \
--image_path $DATASET_PATH/images
Note that any command lists all available options using the
-h,--help
command-line argument. In case you need more control over the individual
parameters of the reconstruction process, you can execute the following sequence
of commands as an alternative to the automatic reconstruction command:
# The project folder must contain a folder "images" with all the images.
$ DATASET_PATH=/path/to/dataset
$ colmap feature_extractor \
--database_path $DATASET_PATH/database.db \
--image_path $DATASET_PATH/images
$ colmap exhaustive_matcher \
--database_path $DATASET_PATH/database.db
$ mkdir $DATASET_PATH/sparse
$ colmap mapper \
--database_path $DATASET_PATH/database.db \
--image_path $DATASET_PATH/images \
--output_path $DATASET_PATH/sparse
$ mkdir $DATASET_PATH/dense
$ colmap image_undistorter \
--image_path $DATASET_PATH/images \
--input_path $DATASET_PATH/sparse/0 \
--output_path $DATASET_PATH/dense \
--output_type COLMAP \
--max_image_size 2000
$ colmap patch_match_stereo \
--workspace_path $DATASET_PATH/dense \
--workspace_format COLMAP \
--PatchMatchStereo.geom_consistency true
$ colmap stereo_fusion \
--workspace_path $DATASET_PATH/dense \
--workspace_format COLMAP \
--input_type geometric \
--output_path $DATASET_PATH/dense/fused.ply
$ colmap poisson_mesher \
--input_path $DATASET_PATH/dense/fused.ply \
--output_path $DATASET_PATH/dense/meshed-poisson.ply
$ colmap delaunay_mesher \
--input_path $DATASET_PATH/dense \
--output_path $DATASET_PATH/dense/meshed-delaunay.ply
If you want to run COLMAP on a computer without an attached display (e.g.,
cluster or cloud service), COLMAP automatically switches to use CUDA if
supported by your system. If no CUDA enabled device is available, you can
manually select to use CPU-based feature extraction and matching by setting the
--SiftExtraction.use_gpu
--SiftMatching.use_gpu
options.
Help
The available commands can be listed using the command:
$ colmap help
Usage:
colmap [command] [options]
Documentation:
https://colmap.github.io/
Example usage:
colmap help [ -h, --help ]
colmap gui
colmap gui -h [ --help ]
colmap automatic_reconstructor -h [ --help ]
colmap automatic_reconstructor --image_path IMAGES --workspace_path WORKSPACE
colmap feature_extractor --image_path IMAGES --database_path DATABASE
colmap exhaustive_matcher --database_path DATABASE
colmap mapper --image_path IMAGES --database_path DATABASE --output_path MODEL
Available commands:
help
automatic_reconstructor
bundle_adjuster
color_extractor
database_cleaner
database_creator
database_merger
delaunay_mesher
exhaustive_matcher
feature_extractor
feature_importer
hierarchical_mapper
image_deleter
image_filterer
image_rectifier
image_registrator
image_undistorter
image_undistorter_standalone
mapper
matches_importer
model_aligner
model_analyzer
model_comparer
model_converter
model_cropper
model_merger
model_orientation_aligner
model_splitter
model_transformer
patch_match_stereo
point_filtering
point_triangulator
pose_prior_mapper
poisson_mesher
project_generator
rig_configurator
rig_bundle_adjuster
sequential_matcher
spatial_matcher
stereo_fusion
transitive_matcher
vocab_tree_builder
vocab_tree_matcher
vocab_tree_retriever
And each command has a
-h,--help
command-line argument to show the usage and
the available options, e.g.:
$ colmap feature_extractor -h
Options can either be specified via command-line or by defining
them in a .ini project file passed to ``--project_path``.
-h [ --help ]
--project_path arg
--database_path arg
--image_path arg
--image_list_path arg
--ImageReader.camera_model arg (=SIMPLE_RADIAL)
--ImageReader.single_camera arg (=0)
--ImageReader.camera_params arg
--ImageReader.default_focal_length_factor arg (=1.2)
--SiftExtraction.num_threads arg (=-1)
--SiftExtraction.use_gpu arg (=1)
--SiftExtraction.gpu_index arg (=-1)
--SiftExtraction.max_image_size arg (=3200)
--SiftExtraction.max_num_features arg (=8192)
--SiftExtraction.first_octave arg (=-1)
--SiftExtraction.num_octaves arg (=4)
--SiftExtraction.octave_resolution arg (=3)
--SiftExtraction.peak_threshold arg (=0.0066666666666666671)
--SiftExtraction.edge_threshold arg (=10)
--SiftExtraction.estimate_affine_shape arg (=0)
--SiftExtraction.max_num_orientations arg (=2)
--SiftExtraction.upright arg (=0)
--SiftExtraction.domain_size_pooling arg (=0)
--SiftExtraction.dsp_min_scale arg (=0.16666666666666666)
--SiftExtraction.dsp_max_scale arg (=3)
--SiftExtraction.dsp_num_scales arg (=10)
The available options can either be provided directly from the command-line or
through a
.ini
file provided to
--project_path
Commands
The following list briefly documents the functionality of each command, that is
available as
colmap
[command]
: The graphical user interface, see
Graphical User Interface
for more information.
automatic_reconstructor
: Automatically reconstruct sparse and dense model
for a set of input images.
project_generator
: Generate project files at different quality settings.
feature_extractor
feature_importer
: Perform feature extraction or
import features for a set of images.
exhaustive_matcher
vocab_tree_matcher
sequential_matcher
spatial_matcher
transitive_matcher
matches_importer
Perform feature matching after performing feature extraction.
mapper
: Sparse 3D reconstruction / mapping of the dataset using SfM after
performing feature extraction and matching.
pose_prior_mapper
Sparse 3D reconstruction / mapping using pose priors.
hierarchical_mapper
: Sparse 3D reconstruction / mapping of the dataset
using hierarchical SfM after performing feature extraction and matching.
This parallelizes the reconstruction process by partitioning the scene into
overlapping submodels and then reconstructing each submodel independently.
Finally, the overlapping submodels are merged into a single reconstruction.
It is recommended to run a few rounds of point triangulation and bundle
adjustment after this step.
image_undistorter
: Undistort images and/or export them for MVS or to
external dense reconstruction software, such as CMVS/PMVS.
image_rectifier
: Stereo rectify cameras and undistort images for stereo
disparity estimation.
image_filterer
: Filter images from a sparse reconstruction.
image_deleter
: Delete specific images from a sparse reconstruction.
patch_match_stereo
: Dense 3D reconstruction / mapping using MVS after
running the
image_undistorter
to initialize the workspace.
stereo_fusion
: Fusion of
patch_match_stereo
results into to a colored
point cloud.
poisson_mesher
: Meshing of the fused point cloud using Poisson
surface reconstruction.
delaunay_mesher
: Meshing of the reconstructed sparse or dense point cloud
using a graph cut on the Delaunay triangulation and visibility voting.
image_registrator
: Register new images in the database against an existing
model, e.g., when extracting features and matching newly added images in a
database after running
mapper
. Note that no bundle adjustment or
triangulation is performed.
point_triangulator
: Triangulate all observations of registered images in
an existing model using the feature matches in a database.
point_filtering
: Filter sparse points in model by enforcing criteria,
such as minimum track length, maximum reprojection error, etc.
bundle_adjuster
: Run global bundle adjustment on a reconstructed scene,
e.g., when a refinement of the intrinsics is needed or
after running the
image_registrator
database_cleaner
: Clean specific or all database tables.
database_creator
: Create an empty COLMAP SQLite database with the
necessary database schema information.
database_merger
: Merge two databases into a new database. Note that the
cameras will not be merged and that the unique camera and image identifiers
might change during the merging process.
model_analyzer
: Print statistics about reconstructions.
model_aligner
: Align/geo-register model to coordinate system of given
camera centers.
model_orientation_aligner
: Align the coordinate axis of a model using a
Manhattan world assumption.
model_comparer
: Compare statistics of two reconstructions.
model_converter
: Convert the COLMAP export format to another format,
such as PLY or NVM.
model_cropper
: Crop model to specific bounding box described in GPS or
model coordinate system.
model_merger
: Attempt to merge two disconnected reconstructions,
if they have common registered images.
model_splitter
: Divide model in rectangular sub-models specified from
file containing bounding box coordinates, or max extent of sub-model, or
number of subdivisions in each dimension.
model_transformer
: Transform coordinate frame of a model.
color_extractor
: Extract mean colors for all 3D points of a model.
rig_configurator
: Configure rigs and frames after feature extraction.
vocab_tree_builder
: Create a vocabulary tree from a database with
extracted images. This is an offline procedure and can be run once, while the
same vocabulary tree can be reused for other datasets. Note that, as a rule of
thumb, you should use at least 10-100 times more features than visual words.
Pre-trained trees can be downloaded from
https://demuc.de/colmap/
This is useful if you want to build a custom tree with a different trade-off
in terms of precision/recall vs. speed.
vocab_tree_retriever
: Perform vocabulary tree based image retrieval.
Visualization
If you want to quickly visualize the outputs of the sparse or dense
reconstruction pipelines, COLMAP offers you the following possibilities:
The sparse point cloud obtained with the
mapper
can be visualized via the
COLMAP GUI by importing the following files: choose
File
Import
Model
and select the folder where the three files,
cameras.txt
images.txt
points3d.txt
are located.
The dense point cloud obtained with the
stereo_fusion
can be visualized
via the COLMAP GUI by importing
fused.ply
: choose
File
Import
Model
from...
and then select the file
fused.ply
The dense mesh model
meshed-*.ply
obtained with the
poisson_mesher
delaunay_mesher
can currently not be visualized with COLMAP, instead
you can use an external viewer, such as Meshlab.


---

### Documentation: Database.Html

## Database.Html

Database Format
Database Format
COLMAP stores all extracted information in a single SQLite database file. The
database can be accessed with the database management toolkit in the COLMAP GUI,
the provided C++ database API (see
src/colmap/scene/database.h
), or using
Python with pycolmap.
The database contains the following tables:
rigs
cameras
frames
images
keypoints
descriptors
matches
two_view_geometries
To initialize an empty SQLite database file with the required schema, you can
either create a new project in the GUI or execute
src/colmap/exe/database_create.cc
Rigs and Sensors
The relation between rigs and sensors (cameras, etc.) is 1-to-N with one sensor
being chosen as the reference sensor to define the origin of the rig. Each sensor
must only be part of one rig.
Rigs and Frames
The relation between rigs and frames is 1-to-N, where a frame defines a specific
instance of the rig with all or a subset of sensors exposed at the same time.
Cameras and Images
The relation between cameras and images is 1-to-N. This has important
implications for Structure-from-Motion, since one camera shares the same
intrinsic parameters (focal length, principal point, distortion, etc.), while
every image has separate extrinsic parameters (orientation and location).
The intrinsic parameters of cameras are stored as contiguous binary blobs in
float64
, ordered as specified in
src/colmap/sensor/models.h
. COLMAP only
uses cameras that are referenced by images, all other cameras are ignored.
name
column in the images table is the unique relative path in the image
folder. As such, the database file and image folder can be moved to different
locations, as long as the relative folder structure is preserved.
When manually inserting images and cameras into the database, make sure
that all identifiers are positive and non-zero, i.e.
image_id
camera_id
Keypoints and Descriptors
The detected keypoints are stored as row-major
float32
binary blobs, where the
first two columns are the X and Y locations in the image, respectively. COLMAP
uses the convention that the upper left image corner has coordinate
the center of the upper left most pixel has coordinate
(0.5,
0.5)
. If the
keypoints have 4 columns, then the feature geometry is a similarity and the
third column is the scale and the fourth column the orientation of the feature
(according to SIFT conventions). If the keypoints have 6 columns, then the
feature geometry is an affinity and the last 4 columns encode its affine shape
(see
src/feature/types.h
for details).
The extracted descriptors are stored as row-major
uint8
binary blobs, where
each row describes the feature appearance of the corresponding entry in the
keypoints table. Note that COLMAP only supports 128-D descriptors for now, i.e.
cols
column must be 128.
In both tables, the
rows
table specifies the number of detected features per
image, while
rows=0
means that an image has no features. For feature matching
and geometric verification, every image must have a corresponding keypoints and
descriptors entry. Note that only vocabulary tree matching with fast spatial
verification requires meaningful values for the local feature geometry, i.e.,
only X and Y must be provided and the other keypoint columns can be set to zero.
The rest of the reconstruction pipeline only uses the keypoint locations.
Matches and two-view geometries
Feature matching stores its output in the
matches
table and geometric
verification in the
two_view_geometries
table. COLMAP only uses the data in
two_view_geometries
for reconstruction. Every entry in the two tables stores
the feature matches between two unique images, where the
pair_id
is the
row-major, linear index in the upper-triangular match matrix, generated as
follows:
image_ids_to_pair_id
image_id1
image_id2
image_id1
image_id2
return
2147483647
image_id2
image_id1
else
return
2147483647
image_id1
image_id2
and image identifiers can be uniquely determined from the
pair_id
pair_id_to_image_ids
pair_id
image_id2
pair_id
2147483647
image_id1
pair_id
image_id2
2147483647
return
image_id1
image_id2
pair_id
enables efficient database queries, as the matches tables may
contain several hundred millions of entries. This scheme limits the maximum
number of images in a database to 2147483647 (maximum value of signed 32-bit
integers), i.e.
image_id
must be smaller than 2147483647.
The binary blobs in the matches tables are row-major
uint32
matrices, where
the left column are zero-based indices into the features of
image_id1
and the
second column into the features of
image_id2
. The column
cols
must be 2 and
rows
column specifies the number of feature matches.
The F, E, H blobs in the
two_view_geometries
table are stored as 3x3 matrices
in row-major
float64
format. The meaning of the
config
values are documented
in the
src/estimators/two_view_geometry.h
source file.


---

### Documentation: Format.Html

## Format.Html

Output Format
Output Format
Binary File Format
Note that all binary data is stored using little endian byte ordering. All x86
processors are little endian and thus no special care has to be taken when
reading COLMAP binary data on most platforms. The data can be most conveniently
parsed using the C++ reconstruction API under
src/colmap/scene/reconstruction_io.h
or using the Python API provided by pycolmap.
Indices and Identifiers
Any variable name ending with
*_idx
should be considered as an ordered,
contiguous zero-based index. In general, any variable name ending with
*_id
should be considered as an unordered, non-contiguous identifier.
For example, the unique identifiers of cameras (
CAMERA_ID
), images
IMAGE_ID
), and 3D points (
POINT3D_ID
) are unordered and are most likely not
contiguous. This also means that the maximum
POINT3D_ID
does not necessarily
correspond to the number 3D points, since some
POINT3D_ID
’s are missing due to
filtering during the reconstruction, etc.
Sparse Reconstruction
By default, COLMAP uses a binary file format (machine-readable, fast) for
storing sparse models. In addition, COLMAP provides the option to store the
sparse models as text files (human-readable, slow). In both cases, the
information is split into multiples files for the information about
rigs
cameras
frames
images
, and
points
. Any directory containing these
files constitutes a sparse model. The binary files have the file extension
.bin
and the text files the file extension
.txt
. Note that when loading a
model from a directory which contains both binary and text files, COLMAP prefers
the binary format.
Note that older versions of COLMAP had no rig support and thus the
rigs
frames
files may be missing. The reconstruction I/O routines in COLMAP are
fully backwards compatible in that models without these files can be read and
trivial rigs and frames will be automatically initialized. Furthermore, newer
output reconstructions’
cameras
images
files are fully compatible with
old outputs.
To export the currently selected model in the GUI, choose
File
Export
model
. To export all reconstructed models in the current dataset, choose
File
Export
. The selected folder then contains the three files, and
for convenience, the current project configuration for importing the model to
COLMAP. To import the exported models, e.g., for visualization or to resume the
reconstruction, choose
File
Import
model
and select the folder containing
cameras
images
, and
points3D
files.
To convert between the binary and text format in the GUI, you can load the model
using
File
Import
model
and then export the model in the desired output
format using
File
Export
model
(binary) or
File
Export
model
text
(text). In addition, you can export sparse models to other formats, such as
VisualSfM’s NVM, Bundler files, PLY, VRML, etc., using
File
Export
as...
To convert between various formats from the CLI, use the
model_converter
executable.
There are two source files to conveniently read the sparse reconstructions using
Python (
scripts/python/read_write_model.py
supporting binary and text) and Matlab
scripts/matlab/read_model.m
supporting text).
Text Format
COLMAP exports the following three text files for every reconstructed model:
rigs.txt
cameras.txt
frames.txt
images.txt
, and
points3D.txt
Comments start with a leading “#” character and are ignored. The first comment
lines briefly describe the format of the text files, as described in more
detailed on this page.
rigs.txt
This file contains the configured rigs and sensors, e.g.:
# Rig calib list with one line of data per calib:
#   RIG_ID, NUM_SENSORS, REF_SENSOR_TYPE, REF_SENSOR_ID, SENSORS[] as (SENSOR_TYPE, SENSOR_ID, HAS_POSE, [QW, QX, QY, QZ, TX, TY, TZ])
# Number of rigs: 1
CAMERA
CAMERA
0.9999701516465348
0.0011120266840749639
0.0075347911527510894
0.0012985125893421306
0.19316906391350164
0.00085222218993398979
0.0070758955539026785
CAMERA
Here, the dataset contains two rigs: the first rig has two cameras and the second
one has 1 camera.
cameras.txt
This file contains the intrinsic parameters of all reconstructed cameras in the
dataset using one line per camera, e.g.:
# Camera list with one line of data per camera:
#   CAMERA_ID, MODEL, WIDTH, HEIGHT, PARAMS[]
# Number of cameras: 3
SIMPLE_PINHOLE
3072
2304
2559.81
1536
1152
PINHOLE
3072
2304
2560.56
2560.56
1536
1152
SIMPLE_RADIAL
3072
2304
2559.69
1536
1152
0.0218531
Here, the dataset contains 3 cameras based using different distortion models
with the same sensor dimensions (width: 3072, height: 2304). The length of
parameters is variable and depends on the camera model. For the first camera,
there are 3 parameters with a single focal length of 2559.81 pixels and a
principal point at pixel location
(1536,
1152)
. The intrinsic parameters of a
camera can be shared by multiple images, which refer to cameras using the unique
identifier
CAMERA_ID
frames.txt
This file contains the frames, where a frame defines a specific
instance of a rig with all or a subset of sensors exposed at the same time, e.g.:
# Frame list with one line of data per frame:
#   FRAME_ID, RIG_ID, RIG_FROM_WORLD[QW, QX, QY, QZ, TX, TY, TZ], NUM_DATA_IDS, DATA_IDS[] as (SENSOR_TYPE, SENSOR_ID, DATA_ID)
# Number of frames: 151
0.99801363919752195
0.040985139360073107
0.041890917712361225
0.023111584553400576
5.2666546897987896
0.17120007823690631
0.12300519697527648
CAMERA
CAMERA
0.99816472047267968
0.037605501383281774
0.043101511724657163
0.019881568259519072
5.1956060695789192
0.20794508616745555
0.14967533910764824
CAMERA
Here, the dataset contains two frames, where frame 1 is an instance of rig 1 and
frame 2 an instance of rig 2.
images.txt
This file contains the pose and keypoints of all reconstructed images in the
dataset using two lines per image, e.g.:
# Image list with two lines of data per image:
#   IMAGE_ID, QW, QX, QY, QZ, TX, TY, TZ, CAMERA_ID, NAME
#   POINTS2D[] as (X, Y, POINT3D_ID)
# Number of images: 2, mean observations per image: 2
0.851773
0.0165051
0.503764
0.142941
0.737434
1.02973
3.74354
P1180141
2362.39
248.498
58396
1784.7
268.254
59027
1784.7
268.254
0.851773
0.0165051
0.503764
0.142941
0.737434
1.02973
3.74354
P1180142
1190.83
663.957
23056
1258.77
640.354
59070
Here, the first two lines define the information of the first image, and so on.
The reconstructed pose of an image is specified as the projection from world to
the camera coordinate system of an image using a quaternion
(QW,
and a translation vector
(TX,
. The quaternion is defined using the
Hamilton convention, which is, for example, also used by the Eigen library. The
coordinates of the projection/camera center are given by
-R^t
, where
is the inverse/transpose of the 3x3 rotation matrix composed from the
quaternion and
is the translation vector. The local camera coordinate
system of an image is defined in a way that the X axis points to the right, the
Y axis to the bottom, and the Z axis to the front as seen from the image.
Both images in the example above use the same camera model and share intrinsics
CAMERA_ID
). The image name is relative to the selected base image folder
of the project. The first image has 3 keypoints and the second image has 2
keypoints, while the location of the keypoints is specified in pixel
coordinates. Both images observe 2 3D points and note that the last keypoint of
the first image does not observe a 3D point in the reconstruction as the 3D
point identifier is -1.
points3D.txt
This file contains the information of all reconstructed 3D points in the
dataset using one line per point, e.g.:
# 3D point list with one line of data per point:
#   POINT3D_ID, X, Y, Z, R, G, B, ERROR, TRACK[] as (IMAGE_ID, POINT2D_IDX)
# Number of points: 3, mean track length: 3.3334
63390
1.67241
0.292931
0.609726
1.33927
6542
7345
6714
7227
63376
2.01848
0.108877
0.0260841
1.73449
6519
7322
7212
3991
63371
1.71102
0.28566
0.53475
0.612829
4140
4473
Here, there are three reconstructed 3D points, where
POINT2D_IDX
defines the
zero-based index of the keypoint in the
images.txt
file. The error is given in
pixels of reprojection error and is only updated after global bundle adjustment.
Dense Reconstruction
COLMAP uses the following workspace folder structure:
+── images
│   +── image1.jpg
│   +── image2.jpg
│   +── ...
+── sparse
│   +── cameras.txt
│   +── images.txt
│   +── points3D.txt
+── stereo
│   +── consistency_graphs
│   │   +── image1.jpg.photometric.bin
│   │   +── image2.jpg.photometric.bin
│   │   +── ...
│   +── depth_maps
│   │   +── image1.jpg.photometric.bin
│   │   +── image2.jpg.photometric.bin
│   │   +── ...
│   +── normal_maps
│   │   +── image1.jpg.photometric.bin
│   │   +── image2.jpg.photometric.bin
│   │   +── ...
│   +── patch-match.cfg
│   +── fusion.cfg
+── fused.ply
+── meshed-poisson.ply
+── meshed-delaunay.ply
+── run-colmap-geometric.sh
+── run-colmap-photometric.sh
Here, the
images
folder contains the undistorted images, the
sparse
folder
contains the sparse reconstruction with undistorted cameras, the
stereo
folder
contains the stereo reconstruction results,
point-cloud.ply
mesh.ply
the results of the fusion and meshing procedure, and
run-colmap-geometric.sh
run-colmap-photometric.sh
contain example command-line usage to perform
the dense reconstruction.
Depth and Normal Maps
The depth maps are stored as mixed text and binary files. The text header
defines the dimensions of the image in the format
with&height&channels&
followed by row-major
float32
binary data. For depth maps
channels=1
for normal maps
channels=3
. The depth and normal maps can be conveniently
read with Python using the functions in
scripts/python/read_dense.py
with Matlab using the functions in
scripts/matlab/read_depth_map.m
scripts/matlab/read_normal_map.m
Consistency Graphs
The consistency graph defines, for all pixels in an image, the source images a
pixel is consistent with. The graph is stored as a mixed text and binary file,
while the text part is equivalent to the depth and normal maps and the binary
part is a continuous list of
int32
values in the format
<row><col><N><image_idx1>...<image_idxN>
. Here,
(row,
col)
defines the
location of the pixel in the image followed by a list of
image indices.
The indices are specified w.r.t. the ordering in the
images.txt
file.


---

### Documentation: Datasets.Html

## Datasets.Html

Datasets
Datasets
A number of different datasets are available for download at:
https://demuc.de/colmap/datasets/
Gerrard Hall
: 100 high-resolution images of the “Gerrard” hall at UNC
Chapel Hill, which is the building right next to the “South” building.
The images are taken with the same camera but different focus
using a wide-angle lens.
Graham Hall
: 1273 high-resolution images of the interior and exterior of
“Graham” memorial hall at UNC Chapel Hill. The images are taken with the same
camera but different focus using a wide-angle lens.
Person Hall
: 330 high-resolution images of the “Person” hall at UNC Chapel
Hill. The images are taken with the same camera using a wide-angle lens.
South Building
: 128 images of the “South” building at UNC Chapel Hill. The
images are taken with the same camera, kindly provided by Christopher Zach.
A number of sample reconstructions produced by COLMAP can be viewed here:
Sparse reconstructions
https://youtu.be/PmXqdfBQxfQ
https://youtu.be/DIv1aGKqSIk
Dense reconstructions
https://youtu.be/11awtGWSqQU


---

### Documentation: Cameras.Html

## Cameras.Html

Camera Models
Camera Models
COLMAP implements different camera models of varying complexity. If no intrinsic
parameters are known a priori, it is generally best to use the simplest camera
model that is complex enough to model the distortion effects:
SIMPLE_PINHOLE
PINHOLE
: Use these camera models, if your images are
undistorted a priori. These use one and two focal length parameters,
respectively. Note that even in the case of undistorted images, COLMAP could
try to improve the intrinsics with a more complex camera model.
SIMPLE_RADIAL
RADIAL
: This should be the camera model of choice, if the
intrinsics are unknown and every image has a different camera calibration,
e.g., in the case of Internet photos. Both models are simplified versions of
OPENCV
model only modeling radial distortion effects with one and two
parameters, respectively.
OPENCV
FULL_OPENCV
: Use these camera models, if you know the calibration
parameters a priori. You can also try to let COLMAP estimate the parameters,
if you share the intrinsics for multiple images. Note that the automatic
estimation of parameters will most likely fail, if every image has a separate
set of intrinsic parameters.
SIMPLE_RADIAL_FISHEYE
RADIAL_FISHEYE
OPENCV_FISHEYE
THIN_PRISM_FISHEYE
RAD_TAN_THIN_PRISM_FISHEYE
: Use these camera models
for fisheye lenses and note that all other models are not really capable of
modeling the distortion effects of fisheye lenses. The
model is used by
Google Project Tango (make sure to not initialize
omega
to zero).
You can inspect the estimated intrinsic parameters by double-clicking specific
images in the model viewer or by exporting the model and opening the
cameras.txt
file.
To achieve optimal reconstruction results, you might have to try different
camera models for your problem. Generally, when the reconstruction fails and the
estimated focal length values / distortion coefficients are grossly wrong, it is
a sign of using a too complex camera model. Contrary, if COLMAP uses many
iterative local and global bundle adjustments, it is a sign of using a too
simple camera model that is not able to fully model the distortion effects.
You can also share intrinsics between multiple
images to obtain more reliable results
(see
Share intrinsic camera parameters
) or you can
fix the intrinsic parameters during the reconstruction
(see
Fix intrinsic camera parameters
Please, refer to the camera models header file for information on the parameters
of the different camera models:
https://github.com/colmap/colmap/blob/main/src/colmap/sensor/models.h


---

### Documentation: Faq.Html

## Faq.Html

Frequently Asked Questions
Frequently Asked Questions
Adjusting the options for different reconstruction scenarios and output quality
COLMAP provides many options that can be tuned for different reconstruction
scenarios and to trade off accuracy and completeness versus efficiency. The
default options are set to for medium to high quality reconstruction of
unstructured input data. There are several presets for different scenarios and
quality levels, which can be set in the GUI as
Extras
options
To use these presets from the command-line, you can save the current set of
options as
File
Save
project
after choosing the presets. The resulting
project file can be opened with a text editor to view the different options.
Alternatively, you can generate the project file also from the command-line
by running
colmap
project_generator
Extending COLMAP
If you need to simply analyze the produced sparse or dense reconstructions from
COLMAP, you can load the sparse models in Python and Matlab using the provided
scripts in
scripts/python
scripts/matlab
If you want to write a C/C++ executable that builds on top of COLMAP, there are
two possible approaches. First, the COLMAP headers and library are installed
to the
CMAKE_INSTALL_PREFIX
by default. Compiling against COLMAP as a
library is described
here
. Alternatively, you can
start from the
src/tools/example.cc
code template and implement the desired
functionality directly as a new binary within COLMAP.
Share intrinsics
COLMAP supports shared intrinsics for arbitrary groups of images and camera
models. Images share the same intrinsics, if they refer to the same camera, as
specified by the
camera_id
property in the database. You can add new cameras
and set shared intrinsics in the database management tool. Please, refer to
Database Management
for more information.
Fix intrinsics
By default, COLMAP tries to refine the intrinsic camera parameters (except
principal point) automatically during the reconstruction. Usually, if there are
enough images in the dataset and you share the intrinsics between multiple
images, the estimated intrinsic camera parameters in SfM should be better than
parameters manually obtained with a calibration pattern.
However, sometimes COLMAP’s self-calibration routine might converge in
degenerate parameters, especially in case of the more complex camera models with
many distortion parameters. If you know the calibration parameters a priori, you
can fix different parameter groups during the reconstruction. Choose
Reconstruction
Reconstruction
options
Bundle
Adj.
refine_*
and check
which parameter group to refine or to keep constant. Even if you keep the
parameters constant during the reconstruction, you can refine the parameters in
a final global bundle adjustment by setting
Reconstruction
Bundle
adj.
options
refine_*
and then running
Reconstruction
Bundle
adjustment
Principal point refinement
By default, COLMAP keeps the principal point constant during the reconstruction,
as principal point estimation is an ill-posed problem in general. Once all
images are reconstructed, the problem is most often constrained enough that you
can try to refine the principal point in global bundle adjustment, especially
when sharing intrinsic parameters between multiple images. Please, refer to
Fix intrinsics
for more information.
Increase number of matches / sparse 3D points
To increase the number of matches, you should use the more discriminative
DSP-SIFT features instead of plain SIFT and also estimate the affine feature
shape using the options:
--SiftExtraction.estimate_affine_shape=true
--SiftExtraction.domain_size_pooling=true
. In addition, you should enable
guided feature matching using:
--SiftMatching.guided_matching=true
By default, COLMAP ignores two-view feature tracks in triangulation, resulting
in fewer 3D points than possible. Triangulation of two-view tracks can in rare
cases improve the stability of sparse image collections by providing additional
constraints in bundle adjustment. To also triangulate two-view tracks, unselect
the option
Reconstruction
Reconstruction
options
Triangulation
ignore_two_view_tracks
. If your images are taken from far distance with
respect to the scene, you can try to reduce the minimum triangulation angle.
Reconstruct sparse/dense model from known camera poses
If the camera poses are known and you want to reconstruct a sparse or dense
model of the scene, you must first manually construct a sparse model by creating
cameras.txt
points3D.txt
, and
images.txt
under a new folder:
+── path/to/manually/created/sparse/model
│   +── cameras.txt
│   +── images.txt
│   +── points3D.txt
points3D.txt
file should be empty while every other line in the
images.txt
should also be empty, since the sparse features are computed, as described below. You can
refer to
this article
for more information about the structure of
a sparse model.
Example of images.txt:
0.695104
0.718385
0.024566
0.012285
0.046895
0.005253
0.199664
image0001
# Make sure every other line is left empty
0.696445
0.717090
0.023185
0.014441
0.041213
0.001928
0.134851
image0002
0.697457
0.715925
0.025383
0.018967
0.054056
0.008579
0.378221
image0003
0.698777
0.714625
0.023996
0.021129
0.048184
0.004529
0.313427
image0004
Each image above must have the same
image_id
(first column) as in the database (next step).
This database can be inspected either in the GUI (under
Database
management
Processing
or, one can create a reconstruction with colmap and later export  it as text in order to see
the images.txt file it creates.
To reconstruct a sparse map, you first have to recompute features from the
images of the known camera poses as follows:
colmap feature_extractor \
--database_path $PROJECT_PATH/database.db \
--image_path $PROJECT_PATH/images
If your known camera intrinsics have large distortion coefficients, you should
now manually copy the parameters from your
cameras.txt
to the database, such
that the matcher can leverage the intrinsics. Modifying the database is possible
in many ways, but an easy option is to use the provided
scripts/python/database.py
script. Otherwise, you can skip this step and
simply continue as follows:
colmap exhaustive_matcher \ # or alternatively any other matcher
--database_path $PROJECT_PATH/database.db
colmap point_triangulator \
--database_path $PROJECT_PATH/database.db \
--image_path $PROJECT_PATH/images
--input_path path/to/manually/created/sparse/model \
--output_path path/to/triangulated/sparse/model
Note that the sparse reconstruction step is not necessary in order to compute
a dense model from known camera poses. Assuming you computed a sparse model
from the known camera poses, you can compute a dense model as follows:
colmap image_undistorter \
--image_path $PROJECT_PATH/images \
--input_path path/to/triangulated/sparse/model \
--output_path path/to/dense/workspace
colmap patch_match_stereo \
--workspace_path path/to/dense/workspace
colmap stereo_fusion \
--workspace_path path/to/dense/workspace \
--output_path path/to/dense/workspace/fused.ply
Alternatively, you can also produce a dense model without a sparse model as:
colmap image_undistorter \
--image_path $PROJECT_PATH/images \
--input_path path/to/manually/created/sparse/model \
--output_path path/to/dense/workspace
Since the sparse point cloud is used to automatically select neighboring images
during the dense stereo stage, you have to manually specify the source images,
as described
here
. The dense stereo stage
now also requires a manual specification of the depth range:
colmap patch_match_stereo \
--workspace_path path/to/dense/workspace \
--PatchMatchStereo.depth_min $MIN_DEPTH \
--PatchMatchStereo.depth_max $MAX_DEPTH
colmap stereo_fusion \
--workspace_path path/to/dense/workspace \
--output_path path/to/dense/workspace/fused.ply
Merge disconnected models
Sometimes COLMAP fails to reconstruct all images into the same model and hence
produces multiple sub-models. If those sub-models have common registered images,
they can be merged into a single model as post-processing step:
colmap
model_merger
input_path1
path
model1
input_path2
path
model2
output_path
path
merged
model
To improve the quality of the alignment between the two sub-models, it is
recommended to run another global bundle adjustment after the merge:
colmap
bundle_adjuster
input_path
path
merged
model
output_path
path
refined
merged
model
Geo-registration
Geo-registration of models is possible by providing the 3D locations for the
camera centers of a subset or all registered images. The 3D similarity
transformation between the reconstructed model and the target coordinate frame
of the geo-registration is determined from these correspondences.
The geo-registered 3D coordinates can either be extracted from the database
(tvec_prior field) or from a user specified text file.
For text-files, the geo-registered 3D coordinates of the camera centers for
images must be specified with the following format:
image_name1
image_name2
image_name3
The coordinates can be either GPS-based (lat/lon/alt) or cartesian-based (x/y/z).
In case of GPS coordinates, a conversion will be performed to turn those into
cartesian coordinates.  The conversion can be done from GPS to ECEF
(Earth-Centered-Earth-Fixed) or to ENU (East-North-Up) coordinates. If ENU coordinates
are used, the first image GPS coordinates will define the origin of the ENU frame.
It is also possible to use ECEF coordinates for alignment and then rotate the aligned
reconstruction into the ENU plane.
Note that at least 3 images must be specified to estimate a 3D similarity
transformation. Then, the model can be geo-registered using:
colmap
model_aligner
input_path
path
model
output_path
path
registered
model
ref_images_path
path
text
file
database_path
path
database
ref_is_gps
alignment_type
ecef
alignment_max_error
where
error
threshold
used
RANSAC
A 3D similarity transformation will be estimated with a RANSAC estimator to be robust to potential outliers
in the data. It is required to provide the error threshold to be used in the RANSAC estimator.
Manhattan world alignment
COLMAP has functionality to align the coordinate axes of a reconstruction using
a Manhattan world assumption, i.e. COLMAP can automatically determine the
gravity axis and the major horizontal axis of the Manhattan world through
vanishing point detection in the images. Please, refer to the
model_orientation_aligner
for more details.
Mask image regions
COLMAP supports masking of keypoints during feature extraction two different ways:
1. Passing
mask_path
to a folder with image masks. For a given image, the corresponding
mask must have the same sub-path below this root as the image has below
image_path
. The filename must be equal, aside from the added extension
.png
. For example, for an image
image_path/abc/012.jpg
, the mask would
mask_path/abc/012.jpg.png
Passing
camera_mask_path
to a single mask image. This single mask is applied to all images.
In both cases no features will be extracted in regions,
where the mask image is black (pixel intensity value 0 in grayscale).
Register/localize new images into an existing reconstruction
If you have an existing reconstruction of images and want to register/localize
new images within this reconstruction, you can follow these steps:
colmap feature_extractor \
--database_path $PROJECT_PATH/database.db \
--image_path $PROJECT_PATH/images \
--image_list_path /path/to/image-list.txt
colmap vocab_tree_matcher \
--database_path $PROJECT_PATH/database.db \
--VocabTreeMatching.match_list_path /path/to/image-list.txt
colmap image_registrator \
--database_path $PROJECT_PATH/database.db \
--input_path /path/to/existing-model \
--output_path /path/to/model-with-new-images
colmap bundle_adjuster \
--input_path /path/to/model-with-new-images \
--output_path /path/to/model-with-new-images
Note that this first extracts features for the new images, then matches them to
the existing images in the database, and finally registers them into the model.
The image list text file contains a list of images to extract and match,
specified as one image file name per line. The bundle adjustment is optional.
If you need a more accurate image registration with triangulation, then you
should restart or continue the reconstruction process rather than just
registering the images to the model. Instead of running the
image_registrator
, you should run the
mapper
to continue the
reconstruction process from the existing model:
colmap mapper \
--database_path $PROJECT_PATH/database.db \
--image_path $PROJECT_PATH/images \
--input_path /path/to/existing-model \
--output_path /path/to/model-with-new-images
Or, alternatively, you can start the reconstruction from scratch:
colmap mapper \
--database_path $PROJECT_PATH/database.db \
--image_path $PROJECT_PATH/images \
--output_path /path/to/model-with-new-images
Note that dense reconstruction must be re-run from scratch after running the
mapper
or the
bundle_adjuster
, as the coordinate frame of the model can
change during these steps.
Available functionality without GPU/CUDA
If you do not have a CUDA-enabled GPU but some other GPU, you can use all COLMAP
functionality except the dense reconstruction part. However, you can use
external dense reconstruction software as an alternative, as described in the
Tutorial
. If you have a GPU with low compute power
or you want to execute COLMAP on a machine without an attached display and
without CUDA support, you can run all steps on the CPU by specifying the
appropriate options (e.g.,
--SiftExtraction.use_gpu=false
for the feature
extraction step). But note that this might result in a significant slow-down of
the reconstruction pipeline. Please, also note that feature extraction on the
CPU can consume excessive RAM for large images in the default settings, which
might require manually reducing the maximum image size using
--SiftExtraction.max_image_size
and/or setting
--SiftExtraction.first_octave
or by manually limiting the number of
threads using
--SiftExtraction.num_threads
Multi-GPU support in feature extraction/matching
You can run feature extraction/matching on multiple GPUs by specifying multiple
indices for CUDA-enabled GPUs, e.g.,
--SiftExtraction.gpu_index=0,1,2,3
--SiftMatching.gpu_index=0,1,2,3
runs the feature extraction/matching on 4
GPUs in parallel. Note that you can only run one thread per GPU and this
typically also gives the best performance. By default, COLMAP runs one feature
extraction/matching thread per CUDA-enabled GPU and this usually gives the best
performance as compared to running multiple threads on the same GPU.
Feature matching fails due to illegal memory access
If you encounter the following error message:
MultiplyDescriptor
illegal
memory
access
encountered
or the following:
ERROR: Feature matching failed. This probably caused by insufficient GPU
memory. Consider reducing the maximum number of features.
during feature matching, your GPU runs out of memory. Try decreasing the option
--SiftMatching.max_num_matches
until the error disappears. Note that this
might lead to inferior feature matching results, since the lower-scale input
features will be clamped in order to fit them into GPU memory. Alternatively,
you could change to CPU-based feature matching, but this can become very slow,
or better you buy a GPU with more memory.
The maximum required GPU memory can be approximately estimated using the
following formula:
num_matches
num_matches
num_matches
For example, if you set
--SiftMatching.max_num_matches
10000
, the maximum
required GPU memory will be around 400MB, which are only allocated if one of
your images actually has that many features.
Trading off completeness and accuracy in dense reconstruction
If the dense point cloud contains too many outliers and too much noise, try to
increase the value of option
--StereoFusion.min_num_pixels
If the reconstructed dense surface mesh model using Poisson reconstruction
contains no surface or there are too many outlier surfaces, you should reduce
the value of option
--PoissonMeshing.trim
to decrease the surface are and
vice versa to increase it. Also consider to try the reduce the outliers or
increase the completeness in the fusion stage, as described above.
If the reconstructed dense surface mesh model using Delaunay reconstruction
contains too noisy or incomplete surfaces, you should increase the
--DenaunayMeshing.quality_regularization
parameter to obtain a smoother
surface. If the resolution of the mesh is too coarse, you should reduce the
--DelaunayMeshing.max_proj_dist
option to a lower value.
Improving dense reconstruction results for weakly textured surfaces
For scenes with weakly textured surfaces it can help to have a high resolution
of the input images (
--PatchMatchStereo.max_image_size
) and a large patch window
radius (
--PatchMatchStereo.window_radius
). You may also want to reduce the
filtering threshold for the photometric consistency cost
--PatchMatchStereo.filter_min_ncc
Surface mesh reconstruction
COLMAP supports two types of surface reconstruction algorithms. Poisson surface
reconstruction
[kazhdan2013]
and graph-cut based surface extraction from a
Delaunay triangulation. Poisson surface reconstruction typically requires an
almost outlier-free input point cloud and it often produces bad surfaces in the
presence of outliers or large holes in the input data. The Delaunay
triangulation based meshing algorithm is more robust to outliers and in general
more scalable to large datasets than the Poisson algorithm, but it usually
produces less smooth surfaces. Furthermore, the Delaunay based meshing can be
applied to sparse and dense reconstruction results. To increase the smoothness
of the surface as a post-processing step, you could use Laplacian smoothing, as
e.g. implemented in Meshlab.
Note that the two algorithms can also be combined by first running the Delaunay
meshing to robustly filter outliers from the sparse or dense point cloud and
then, in the second step, performing Poisson surface reconstruction to obtain a
smooth surface.
Speedup dense reconstruction
The dense reconstruction can be speeded up in multiple ways:
Put more GPUs in your system as the dense reconstruction can make use of
multiple GPUs during the stereo reconstruction step. Put more RAM into your
system and increase the
--PatchMatchStereo.cache_size
--StereoFusion.cache_size
to the largest possible value in order to
speed up the dense fusion step.
Do not perform geometric dense stereo reconstruction
--PatchMatchStereo.geom_consistency
false
. Make sure to also enable
--PatchMatchStereo.filter
true
in this case.
Reduce the
--PatchMatchStereo.max_image_size
--StereoFusion.max_image_size
values to perform dense reconstruction on a maximum image resolution.
Reduce the number of source images per reference image to be considered, as
described
here
Increase the patch windows step
--PatchMatchStereo.window_step
to 2.
Reduce the patch window radius
--PatchMatchStereo.window_radius
Reduce the number of patch match iterations
--PatchMatchStereo.num_iterations
Reduce the number of sampled views
--PatchMatchStereo.num_samples
To speedup the dense stereo and fusion step for very large reconstructions,
you can use CMVS to partition your scene into multiple clusters and to prune
redundant images, as described
here
Note that apart from upgrading your hardware, the proposed changes might degrade
the quality of the dense reconstruction results. When canceling the stereo
reconstruction process and restarting it later, the previous progress is not
lost and any already processed views will be skipped.
Reduce memory usage during dense reconstruction
If you run out of GPU memory during patch match stereo, you can either reduce
the maximum image size by setting the option
--PatchMatchStereo.max_image_size
reduce the number of source images in the
stereo/patch-match.cfg
file from
e.g.
__auto__,
__auto__,
. Note that enabling the
geom_consistency
option increases the required GPU memory.
If you run out of CPU memory during stereo or fusion, you can reduce the
--PatchMatchStereo.cache_size
--StereoFusion.cache_size
specified in
gigabytes or you can reduce
--PatchMatchStereo.max_image_size
--StereoFusion.max_image_size
. Note that a too low value might lead to very
slow processing and heavy load on the hard disk.
For large-scale reconstructions of several thousands of images, you should
consider splitting your sparse reconstruction into more manageable clusters of
images using e.g. CMVS
[furukawa10]
. In addition, CMVS allows to prune
redundant images observing the same scene elements. Note that, for this use
case, COLMAP’s dense reconstruction pipeline also supports the PMVS/CMVS folder
structure when executed from the command-line. Please, refer to the workspace
folder for example shell scripts. Note that the example shell scripts for
PMVS/CMVS are only generated, if the output type is set to PMVS. Since CMVS
produces highly overlapping clusters, it is recommended to increase the default
value of 100 images per cluster to as high as possible according to your
available system resources and speed requirements. To change the number of
images using CMVS, you must modify the shell scripts accordingly. For example,
cmvs
pmvs/
to limit each cluster to 500 images. If you want to use CMVS
to prune redundant images but not to cluster the scene, you can simply set this
number to a very large value.
Manual specification of source images during dense reconstruction
You can change the number of source images in the
stereo/patch-match.cfg
file from e.g.
__auto__,
__auto__,
. This selects the images
with the most visual overlap automatically as source images. You can also use
all other images as source images, by specifying
__all__
. Alternatively, you
can manually specify images with their name, for example:
image1
image2
image3
image2
image1
image3
image3
image1
image2
Here,
image2.jpg
image3.jpg
are used as source images for
image1.jpg
, etc.
Multi-GPU support in dense reconstruction
You can run dense reconstruction on multiple GPUs by specifying multiple indices
for CUDA-enabled GPUs, e.g.,
--PatchMatchStereo.gpu_index=0,1,2,3
runs the dense
reconstruction on 4 GPUs in parallel. You can also run multiple dense
reconstruction threads on the same GPU by specifying the same GPU index twice,
e.g.,
--PatchMatchStereo.gpu_index=0,0,1,1,2,3
. By default, COLMAP runs one
dense reconstruction thread per CUDA-enabled GPU.
Fix GPU freezes and timeouts during dense reconstruction
The stereo reconstruction pipeline runs on the GPU using CUDA and puts the GPU
under heavy load. You might experience a display freeze or even a program crash
during the reconstruction. As a solution to this problem, you could use a
secondary GPU in your system, that is not connected to your display by setting
the GPU indices explicitly (usually index 0 corresponds to the card that the
display is attached to). Alternatively, you can increase the GPU timeouts of
your system, as detailed in the following.
By default, the Windows operating system detects response problems from the GPU,
and recovers to a functional desktop by resetting the card and aborting the
stereo reconstruction process. The solution is to increase the so-called
“Timeout Detection & Recovery” (TDR) delay to a larger value. Please, refer to
NVIDIA Nsight documentation
or to the
Microsoft
documentation
on how to increase the delay time under Windows. You can increase the delay
using the following Windows Registry entries:
HKEY_LOCAL_MACHINE
SYSTEM
CurrentControlSet
Control
GraphicsDrivers
"TdrLevel"
dword
00000001
"TdrDelay"
dword
00000120
To set the registry entries, execute the following commands using administrator
privileges (e.g., in
cmd.exe
powershell.exe
HKEY_LOCAL_MACHINE
SYSTEM
CurrentControlSet
Control
GraphicsDrivers
TdrLevel
REG_DWORD
00000001
HKEY_LOCAL_MACHINE
SYSTEM
CurrentControlSet
Control
GraphicsDrivers
TdrDelay
REG_DWORD
00000120
and restart your machine afterwards to make the changes effective.
The X window system under Linux/Unix has a similar feature and detects response
problems of the GPU. The easiest solution to avoid timeout problems under the X
window system is to shut it down and run the stereo reconstruction from the
command-line. Under Ubuntu, you could first stop X using:
sudo
service
lightdm
stop
And then run the dense reconstruction code from the command-line:
colmap
patch_match_stereo
Finally, you can restart your desktop environment with the following command:
sudo
service
lightdm
start
If the dense reconstruction still crashes after these changes, the reason is
probably insufficient GPU memory, as discussed in a separate item in this list.


---

### Documentation: Bibliography.Html

## Bibliography.Html

Bibliography
Bibliography
schoenberger_thesis
Johannes L. Schönberger. “Robust Methods for Accurate
and Efficient 3D Modeling from Unstructured Imagery.” ETH Zürich, 2018.
furukawa10
Furukawa, Yasutaka, and Jean Ponce.
“Accurate, dense, and robust multiview stereopsis.”
Transactions on Pattern Analysis and Machine Intelligence, 2010.
hofer16
Hofer, M., Maurer, M., and Bischof, H.
Efficient 3D Scene Abstraction Using Line Segments,
Computer Vision and Image Understanding, 2016.
jancosek11
Jancosek, Michal, and Tomás Pajdla.
“Multi-view reconstruction preserving weakly-supported surfaces.”
Conference on Computer Vision and Pattern Recognition, 2011.
kazhdan2013
Kazhdan, Michael and Hoppe, Hugues
“Screened poisson surface reconstruction.”
ACM Transactions on Graphics (TOG), 2013.
schoenberger16sfm
Schönberger, Johannes Lutz and Frahm, Jan-Michael.
“Structure-from-Motion Revisited.” Conference on Computer Vision and
Pattern Recognition, 2016.
schoenberger16mvs
Schönberger, Johannes Lutz and Zheng, Enliang and
Pollefeys, Marc and Frahm, Jan-Michael.
“Pixelwise View Selection for Unstructured Multi-View Stereo.”
European Conference on Computer Vision, 2016.
schoenberger16vote
Schönberger, Johannes Lutz and Price, True and
Sattler, Torsten and Frahm, Jan-Michael and Pollefeys, Marc
“A Vote­-and­-Verify Strategy for Fast Spatial Verification in Image
Retrieval.” Asian Conference on Computer Vision, 2016.
lowe04
Lowe, David G. “Distinctive image features from scale-invariant
keypoints”. International journal of computer vision 60.2 (2004): 91-110.
wu13
Wu, Changchang. “Towards linear-time incremental structure from
motion.” International Conference 3D Vision, 2013.


---

### Documentation: License.Html

## License.Html

License
License
The COLMAP library is licensed under the new BSD license. Note that this text
refers only to the license for COLMAP itself, independent of its thirdparty
dependencies, which are separately licensed. Building COLMAP with these
dependencies may affect the resulting COLMAP license.
Copyright (c), ETH Zurich and UNC Chapel Hill.
All rights reserved.
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
* Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.
* Neither the name of ETH Zurich and UNC Chapel Hill nor the names of
its contributors may be used to endorse or promote products derived
from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.


---

### Documentation: Contribution.Html

## Contribution.Html

Contribution
Contribution
Contributions (bug reports, bug fixes, improvements, etc.) are very welcome and
should be submitted in the form of new issues and/or pull requests on GitHub.
Please, adhere to the Google coding style guide:
https
google
github
styleguide
cppguide
html
by using the provided “.clang-format” file.
Document functions, methods, classes, etc. with inline documentation strings
describing the API, using the following format:
Short
description
Longer
description
with
sentences
multiple
lines
@param
parameter1
Description
parameter
@param
parameter2
Description
parameter
@return
Description
optional
return
value
Add unit tests for all newly added code and make sure that algorithmic
“improvements” generalize and actually improve the results of the pipeline on a
variety of datasets.


---

### PyCOLMAP: Index.Html

## Index.Html

PyCOLMAP
PyCOLMAP
PyCOLMAP exposes to Python most capabilities of COLMAP.
Installation
Pre-built wheels for Linux, macOS, and Windows can be installed using pip:
install
pycolmap
The wheels are automatically built and pushed to
PyPI
at each release. They are currently not
built with CUDA support, which requires building from source. To build PyCOLMAP
from source, follow these steps:
Install COLMAP from source following
Installation
Build PyCOLMAP:
On Linux and macOS:
python
install
On Windows, after installing COLMAP via VCPKG, run in powershell:
python -m pip install . `
--cmake.define.CMAKE_TOOLCHAIN_FILE="$VCPKG_INSTALLATION_ROOT/scripts/buildsystems/vcpkg.cmake" `
--cmake.define.VCPKG_TARGET_TRIPLET="x64-windows"
Some features, such as cost functions, require that
PyCeres
is installed in the same manner as PyCOLMAP,
so either from PyPI or from source.
pycolmap
Device
SensorType
sensor_t
data_t
logging
Timer
Rotation3d
AlignedBox3d
Rigid3d
get_covariance_for_inverse()
get_covariance_for_composed_rigid3d()
get_covariance_for_relative_rigid3d()
average_quaternions()
interpolate_camera_poses()
Sim3d
PosePriorCoordinateSystem
PosePrior
GPSTransfromEllipsoid
GPSTransform
pose_from_homography_matrix()
homography_decomposition()
essential_matrix_from_pose()
triangulate_point()
calculate_triangulation_angle()
TriangulatePoint()
CalculateTriangulationAngle()
triangulate_mid_point()
RANSACOptions
Bitmap
RigMap
KeysView
ValuesView
ItemsView
Point2D
Point2DList
CameraModelId
Camera
CameraMap
Frame
FrameMap
Image
ImageMap
TrackElement
Track
Point3D
Point3DMap
Correspondence
CorrespondenceGraph
Reconstruction
ReconstructionManager
TwoViewGeometryConfiguration
TwoViewGeometry
Database
DatabaseTransaction
RigConfigCamera
RigConfig
read_rig_config()
apply_rig_config()
DatabaseCache
SyntheticDatasetMatchConfig
SyntheticDatasetOptions
synthesize_dataset()
UndistortCameraOptions
undistort_camera()
undistort_image()
AbsolutePoseEstimationOptions
AbsolutePoseRefinementOptions
estimate_absolute_pose()
refine_absolute_pose()
estimate_and_refine_absolute_pose()
absolute_pose_estimation()
estimate_relative_pose()
refine_relative_pose()
estimate_affine2d()
estimate_affine2d_robust()
ImageAlignmentError
align_reconstructions_via_reprojections()
align_reconstructions_via_proj_centers()
align_reconstructions_via_points()
align_reconstruction_to_locations()
compare_reconstructions()
BundleAdjustmentGauge
BundleAdjustmentConfig
LossFunctionType
BundleAdjustmentOptions
PosePriorBundleAdjustmentOptions
BundleAdjuster
create_default_bundle_adjuster()
create_pose_prior_bundle_adjuster()
BACovarianceOptionsParams
ExperimentalPoseParam
BACovarianceOptions
BACovariance
estimate_ba_covariance_from_problem()
estimate_ba_covariance()
estimate_essential_matrix()
essential_matrix_estimation()
estimate_fundamental_matrix()
fundamental_matrix_estimation()
estimate_generalized_absolute_pose()
refine_generalized_absolute_pose()
estimate_and_refine_generalized_absolute_pose()
rig_absolute_pose_estimation()
estimate_generalized_relative_pose()
estimate_homography_matrix()
homography_matrix_estimation()
estimate_rigid3d()
estimate_rigid3d_robust()
estimate_sim3d()
estimate_sim3d_robust()
TriangulationResidualType
EstimateTriangulationOptions
estimate_triangulation()
TwoViewGeometryOptions
estimate_calibrated_two_view_geometry()
estimate_two_view_geometry()
estimate_two_view_geometry_pose()
compute_squared_sampson_error()
squared_sampson_error()
FeatureKeypoint
FeatureKeypoints
FeatureMatch
FeatureMatches
Normalization
SiftExtractionOptions
Sift
SiftMatchingOptions
ImageScore
VisualIndex
ImagePairStat
ObservationManager
IncrementalTriangulatorOptions
IncrementalTriangulator
ImageSelectionMethod
IncrementalMapperOptions
LocalBundleAdjustmentReport
IncrementalMapper
IncrementalPipelineOptions
IncrementalMapperCallback
IncrementalMapperStatus
IncrementalPipeline
CameraMode
ImageReaderOptions
CopyType
import_images()
infer_camera_from_image()
undistort_images()
extract_features()
ExhaustiveMatchingOptions
SpatialMatchingOptions
VocabTreeMatchingOptions
SequentialMatchingOptions
ImagePairsMatchingOptions
match_exhaustive()
match_spatial()
match_vocabtree()
match_sequential()
verify_matches()
PairGenerator
ExhaustivePairGenerator
VocabTreePairGenerator
SequentialPairGenerator
SpatialPairGenerator
ImportedPairGenerator
triangulate_points()
incremental_mapping()
bundle_adjustment()
PatchMatchOptions
patch_match_stereo()
StereoFusionOptions
stereo_fusion()
PoissonMeshingOptions
DelaunayMeshingOptions
poisson_meshing()
sparse_delaunay_meshing()
dense_delaunay_meshing()
set_random_seed()
ostream
Cost Functions
ReprojErrorCost()
RigReprojErrorCost()
SampsonErrorCost()
AbsolutePosePriorCost()
AbsolutePosePositionPriorCost()
RelativePosePriorCost()
Point3DAlignmentCost()


---

## Installation.Html

*Failed to load content from https://colmap.github.io/pycolmap/installation.html*

---

## Tutorial.Html

*Failed to load content from https://colmap.github.io/pycolmap/tutorial.html*

---

## Api.Html

*Failed to load content from https://colmap.github.io/pycolmap/api.html*

---
