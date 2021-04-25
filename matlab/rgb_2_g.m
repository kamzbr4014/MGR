clear all;

img = imread('data/test_plane.jpg');
ym = rgb2gray(img);

method = 1;

rPlane = img(:,:,1);
gPlane = img(:,:,2);
bPlane = img(:,:,3);

switch method
    case 1
        % assuming 18 bit multiplayer
        % simple bitshift left (multiply 2^17)
        yrConst = sfi(0.299, 32, 5);
        ygConst = sfi(0.587, 32, 5); 
        ybConst = sfi(0.114, 32, 5); 
        yrConstT = uint32(bitshift(yrConst, 17));     
        ygConstT = uint32(bitshift(ygConst, 17));
        ybConstT = uint32(bitshift(ybConst, 17));
        % shift right (multiply 2^-17)
        yrBuff = uint8(bitshift((uint32(rPlane) * yrConstT), -17));
        ygBuff = uint8(bitshift((uint32(gPlane) * ygConstT), -17));
        ybBuff = uint8(bitshift((uint32(bPlane) * ybConstT), -17));

        y = yrBuff + ygBuff + ybBuff;
    otherwise
        yTmp = uint8((uint16(rPlane) + 2 * uint16(gPlane) + uint16(bPlane)) / 4);
        y = round(yTmp);
end

subplot(131)
imshow(img)
subplot(132)
imshow(y)
subplot(133)
imshow(ym)