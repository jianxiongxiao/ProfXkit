This is an online MATLAB implementation of structural SVM with cutting plane algorithm.
This implementation doesn't use sparse structure for the feature and w. 
But it should be straightforward to do that by making use of MATLAB's sparse() function.

Citation:
J. Xiao, K. A. Ehinger, A. Oliva and A. Torralba
Recognizing Scene Viewpoint using Panoramic Place Representation
Proceedings of 25th IEEE Conference on Computer Vision and Pattern Recognition (CVPR2012)

Usage: 

function w = trainOnlineStructSVM(size2train, w_init, find_MVC, param)

Input: 
1. need to have size2train to be the number of training examples
2. need to have w_init as initial values for w. If you have no idea, initialize w by all ones
3. need to have param
   param.C = 1.0;
   param.max_num_iterations = 500;
   param.max_num_constraints =  10000;
4. need to have a function handler @find_MVC to find the most violated constraints.
   This function should have the interface:
   [X_wo margin] = findMVC_BinaryLinearSVM(w, id)
   1st output X_wo: The constraint corresponding to that labeling = (Groud Truth Feature - Worst Offending feature)
   2nd output m   : the margin you want to enforce for this constraint.   

Output:
    w: the learned SVM weights


Example to learn how to use it:
   demo_BinaryLinearSVM.m


Jianxiong Xiao
http://mit.edu/jxiao/

It makes use of the source code written by 
[1] Chaitanya Desai: http://www.ics.uci.edu/~desaic/
[2] Vojtech Franc: http://cmp.felk.cvut.cz/~xfrancv/libqp/html/
[3] Andrea Vedaldi: http://www.vlfeat.org/~vedaldi/code/svm-struct-matlab.html
We graciously thank the authors of these code releases.

It is also inspired by 
[4] SVM^struct written by Thorsten Joachims 
[5] MITUCLA Latent Hierarchical Structural SVM written by Long Zhu

Reference:

[6] Thorsten Joachims, Thomas Finley, and Chun-Nam John Yu. 2009. 
Cutting-plane training of structural SVMs. 
Mach. Learn. 77, 1 (October 2009), 27-59. 
http://www.cs.cornell.edu/People/tj/publications/joachims_etal_07b_rev.pdf

[7] I. Tsochantaridis, T. Hofmann, T. Joachims, and Y. Altun. 
Support Vector Learning for Interdependent and Structured Output Spaces.
ICML, 2004.
http://www.cs.cornell.edu/people/tj/publications/tsochantaridis_etal_04a.pdf

[8] C. Desai, D. Ramanan, C. Fowlkes. 
Discriminative Models for Multi-Class Object Layout
International Conference on Computer Vision (ICCV) Kyoto, Japan, Sept. 2009.
http://www.ics.uci.edu/~dramanan/papers/nms.pdf
