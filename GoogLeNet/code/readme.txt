The included is a GPU implementation of GoogLeNet model.

* Author and Bug report:
The model is implemented, trained, and tested by the following authors. Feel free to contact Zhirong Wu (xavibrowu@gmail.com) for questions or report bugs.

* Patch to Caffe:

We have a patch (caffe-change-for-googlenet.patch) to caffe to train GoogLeNet with batch size 256. To use the patched caffe:

git clone https://github.com/BVLC/caffe.git .
cd caffe
git checkout -b googlenet e8dee35
git apply path/to/the/provided/patch

