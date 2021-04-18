clear all;

img = imread('data/test_pattern_1.jpg');

rPlane = img(:,:,1);
gPlane = img(:,:,2);
bPlane = img(:,:,3);

frameHigh = bitor(bitand(rPlane, 0b11111000), bitshift(bitand(gPlane, 0b11100000), -5));
frameLow  = bitor(bitshift(bitand(gPlane, 0b00011100), 3), bitshift(bitand(bPlane, 0b11111000), -3));

fName = 'gen/test_pattern_1_dat.txt';
fileID = fopen(fName, 'w');

[row, col] = size(frameHigh);
for n = 1 : col
    strFH = sprintf('%c', dec2bin(frameHigh(n), 8));
    strFL = sprintf('%c', dec2bin(frameLow(n), 8));
    if n == col
        fprintf(fileID, '%s %s', strFH, strFL);
    else
        fprintf(fileID, '%s %s\n', strFH, strFL);
    end
end

fclose(fileID);
disp("File saved")

% fh = bitget(frameHigh(1), 8:-1:1)
% r = bitget(rPlane(1), 8:-1:1)
% g = bitget(gPlane(1), 8:-1:1)
% b = bitget(bPlane(1), 8:-1:1)
% lh = bitget(frameLow(1), 8:-1:1)