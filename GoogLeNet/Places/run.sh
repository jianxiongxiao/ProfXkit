#!/usr/bin/env sh
./build/tools/caffe test \
--model train_val_googlenet.prototxt \
--gpu=0 \
--weights placenet_googlenet.caffemodel \
--iterations=800 \
#--snapshot ./models/positive_noise/caffenet_train_pn_iter_4000.solverstate \
#--weights /home/yindazhang/Desktop/caffe_ionic/models/bvlc_reference_caffenet/bvlc_reference_caffenet.caffemodel \
