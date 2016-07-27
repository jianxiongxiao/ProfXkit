vertex = ...
[0  0    267.9  267.9
 0  74.3 74.3   0
 0  0    0      0];

face = ...
[ 0
  1
  2
  3
];

textureUV(:,:,1) = ...
[ 0
  0
  1
  1
];

textureUV(:,:,2) = ...
[ 0
  1
  1
  0
];


texturedVRML2('demo.wrl',vertex, face, textureUV, 'PrincetonVisionGroup_logo.png');