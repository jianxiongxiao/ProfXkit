%{

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

%}

clear
clc

syms P00 P01 P02 P03 P10 P11 P12 P13 P20 P21 P22 P23
syms m_far m_near m_width m_height scale

projection = [P00 P01 P02 P03; P10 P11 P12 P13; P20 P21 P22 P23; 0 0 0 1];

% handle the near and far clip plane in OpenGL
protr = [1.0, 0.0, 0.0, 0.0;
    0.0, 1.0, 0.0, 0.0;
    0.0, 0.0, m_far / (m_far - m_near), - m_near * m_far /(m_far - m_near);
    0.0, 0.0, 1.0, 0.0];

% handle half pixel inconsistency
offset = [1.0, 0.0, 0.5, 0.0;
    0.0, 1.0, 0.5, 0.0;
    0.0, 0.0, 1.0, 0.0;
    0.0, 0.0, 0.0, 1.0];

% undo image aspect ratio and size
m0 = [m_width / 2, 0.0,         0.0, 0 + m_width / 2.0;
    0.0,        m_height / 2, 0.0, 0 + m_height / 2.0;
    0.0,        0.0,         0.5, 0.5;
    0.0,        0.0,         0.0, 1.0];


% handle scaling
m1=[1 / scale,   0.0,         0.0,                0.0;
    0.0,        1 / scale,    0.0,                0.0;
    0.0,        0.0,         1.0,                0.0;
    0.0,        0.0,         0.0,                1.0];

% handle upside down in vertical direction in image
m2=[1,           0.0,         0.0,                0.0;
    0.0,        -1.0,        m_height,            0.0;
    0.0,        0.0,         1.0,                0.0;
    0.0,        0.0,         0.0,                1.0];

M = (m0 \ protr * m2 * m1 * offset * projection);

M =
 
[     P20*(1/(m_width*scale) - 1) + (2*P00)/(m_width*scale),     P21*(1/(m_width*scale) - 1) + (2*P01)/(m_width*scale),     P22*(1/(m_width*scale) - 1) + (2*P02)/(m_width*scale),                       P23*(1/(m_width*scale) - 1) + (2*P03)/(m_width*scale)]
[ - P20*(1/(m_height*scale) - 1) - (2*P10)/(m_height*scale), - P21*(1/(m_height*scale) - 1) - (2*P11)/(m_height*scale), - P22*(1/(m_height*scale) - 1) - (2*P12)/(m_height*scale),                   - P23*(1/(m_height*scale) - 1) - (2*P13)/(m_height*scale)]
[                   (P20*(m_far + m_near))/(m_far - m_near),                   (P21*(m_far + m_near))/(m_far - m_near),                   (P22*(m_far + m_near))/(m_far - m_near), (P23*(m_far + m_near))/(m_far - m_near) - (2*m_far*m_near)/(m_far - m_near)]
[                                                       P20,                                                       P21,                                                       P22,                                                                         P23]


inv_width_scale  = 1/(m_width*scale);
inv_height_scale = 1/(m_height*scale);
inv_width_scale_1 =inv_width_scale - 1;
inv_height_scale_1_s = -(inv_height_scale - 1);
inv_width_scale_2 = inv_width_scale*2;
inv_height_scale_2_s = -inv_height_scale*2;
m_far_a_m_near = m_far + m_near;
m_far_s_m_near = m_far - m_near;
m_far_d_m_near = m_far_a_m_near/m_far_s_m_near;

M =
[     P20*(inv_width_scale - 1) + (2*P00)*inv_width_scale,   P21*(inv_width_scale - 1) + (2*P01)*inv_width_scale  , P22*(inv_width_scale - 1) + (2*P02)*inv_width_scale    ,                       P23*(inv_width_scale - 1) + (2*P03)*inv_width_scale]
[ - P20*(inv_height_scale - 1) - (2*P10)*inv_height_scale, - P21*(inv_height_scale - 1) - (2*P11)*inv_height_scale, - P22*(inv_height_scale - 1) - (2*P12)*inv_height_scale,                   - P23*(inv_height_scale - 1) - (2*P13)*inv_height_scale]
[                   (P20*m_far_a_m_near)/m_far_s_m_near,                   (P21*m_far_a_m_near)/m_far_s_m_near,                   (P22*m_far_a_m_near)/m_far_s_m_near, (P23*m_far_a_m_near)/m_far_s_m_near - (2*m_far*m_near)/m_far_s_m_near]
[                                                       P20,                                                       P21,                                                       P22,                                                                         P23]



% final OpenGL matrix = M'
% column 1
P20*inv_width_scale_1 + P00*inv_width_scale_2,
P21*inv_width_scale_1 + P01*inv_width_scale_2,
P22*inv_width_scale_1 + P02*inv_width_scale_2,
P23*inv_width_scale_1 + P03*inv_width_scale_2,

% column 2
P20*inv_height_scale_1_s + P10*inv_height_scale_2_s,
P21*inv_height_scale_1_s + P11*inv_height_scale_2_s,
P22*inv_height_scale_1_s + P12*inv_height_scale_2_s,
P23*inv_height_scale_1_s + P13*inv_height_scale_2_s,

% column 3
P20*m_far_d_m_near,
P21*m_far_d_m_near,
P22*m_far_d_m_near,
P23*m_far_d_m_near - (2*m_far*m_near)/m_far_s_m_near,
% column 4
 P20
 P21
 P22
 P23
 
% final matrix to opengl

P20*inv_width_scale_1 + P00*inv_width_scale_2,  P20*inv_height_scale_1_s + P10*inv_height_scale_2_s,    P20*m_far_d_m_near,     P20,
P21*inv_width_scale_1 + P01*inv_width_scale_2,  P21*inv_height_scale_1_s + P11*inv_height_scale_2_s,    P21*m_far_d_m_near,     P21,
P22*inv_width_scale_1 + P02*inv_width_scale_2,  P22*inv_height_scale_1_s + P12*inv_height_scale_2_s,    P22*m_far_d_m_near,     P22,
P23*inv_width_scale_1 + P03*inv_width_scale_2,  P23*inv_height_scale_1_s + P13*inv_height_scale_2_s,    P23*m_far_d_m_near - (2*m_far*m_near)/m_far_s_m_near,   P23


inv_width_scale  = 1/(m_width*scale);
inv_height_scale = 1/(m_height*scale);
inv_width_scale_1 =inv_width_scale - 1;
inv_height_scale_1_s = -(inv_height_scale - 1);
inv_width_scale_2 = inv_width_scale*2;
inv_height_scale_2_s = -inv_height_scale*2;
m_far_a_m_near = m_far + m_near;
m_far_s_m_near = m_far - m_near;
m_far_d_m_near = m_far_a_m_near/m_far_s_m_near;
 


