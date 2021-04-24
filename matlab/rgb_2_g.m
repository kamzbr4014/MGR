clear all;

img = imread('data/test_plane.jpg');
ym = rgb2gray(img);

rPlane = img(:,:,1);
gPlane = img(:,:,2);
bPlane = img(:,:,3);

% assuming 18 bit multiplayer
% simple bitshift left (multiply 2^17)
yrConst = bitshift(uint32(0.299), 17);     
ygConst = bitshift(uint32(0.587), 17);
ybConst = bitshift(uint32(0.114), 17);
% shift right (multiply 2^-17)
yrBuff = uint8(bitshift((uint32(rPlane) * yrConst), -17));
ygBuff = uint8(bitshift((uint32(gPlane) * ygConst), -17));
ybBuff = uint8(bitshift((uint32(bPlane) * ybConst), -17));

y = yrBuff + ygBuff + ybBuff;

subplot(131)
imshow(img)
subplot(132)
imshow(y)
subplot(133)
imshow(ym)