This code is to render a Mesh given a 3x4 camera matrix with an image resolution widthxheight. The rendering result is an ID map for facets, edges and vertices. This can usually used for occlusion testing in texture mapping a model from an image, such as the texture mapping in the following two papers.

--Jianxiong Xiao http://mit.edu/jxiao/

Citation:

[1] J. Xiao, T. Fang, P. Zhao, M. Lhuillier, and L. Quan
Image-based Street-side City Modeling
ACM Transaction on Graphics (TOG), Volume 28, Number 5
Proceedings of ACM SIGGRAPH Asia 2009

[2] J. Xiao, T. Fang, P. Tan, P. Zhao, E. Ofek, and L. Quan
Image-based Facade Modeling
ACM Transaction on Graphics (TOG), Volume 27, Number 5
Proceedings of ACM SIGGRAPH Asia 2008

Example Usage:

Step 1: Compile by "make" in commend line.
Step 2: Run in commend line:
./RenderMe data/hall.ply data/hall.cam > data/hall_out.m
Step 3: Visualize in Matlab by running data/hall_out.m, and you should get an example output same with data/example_output.png

Matlab Mex interface:

In the folder Matlab, there is a mex implementation. Open demo.m for a very intuitive example.

Library:

We use the Off-screen Rendering library from Mesa3D:
http://www.mesa3d.org/osmesa.html
You will need to have libosmesa6-dev or newer version of osmesa installed.

Coordinate System:

For the image coordinate system, the origin (0,0) lies in the center of the pixel at the top-left corner of an image. The x-axis points to the right and the y-axis points to the bottom. The 2D image coordinate of the top left pixel is (0, 0), and the 2D image coordinate of the bottom right pixel is (w, h), where w and h are the image width and height, respectively.

Acknowledgement:

I would like to thank Yasutaka Furukawa for teaching me how to use osmesa and provide some very good examples and data from PMVS.

