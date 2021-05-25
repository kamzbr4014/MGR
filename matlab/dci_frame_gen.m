clear all;

img = imread('data/test_plane.jpg');
W = 7;
stimData = (W-1)/2;
[rImg, cImg, dImg] = size(img);
X = zeros(stimData, rImg, 3);
img = [img; X];
[rImg, cImg, dImg] = size(img);

rPlane = img(:,:,1);
gPlane = img(:,:,2);
bPlane = img(:,:,3);

rPlane565 = bitand(rPlane, 0b11111000);
gPlane565 = bitand(gPlane, 0b11111100);
bPlane565 = bitand(bPlane, 0b11111000);

frameHigh = bitor(bitand(rPlane, 0b11111000), bitshift(bitand(gPlane, 0b11100000), -5));
frameLow  = bitor(bitshift(bitand(gPlane, 0b00011100), 3), bitshift(bitand(bPlane, 0b11111000), -3));

frameData = uint8(zeros(rImg, 2 * cImg));
junctionPos = 1;
posA = junctionPos + 1:junctionPos + 1 : length(frameData);
posB = ones(1, length(frameData));
posB(posA) = 0;
frameData(:, posA) = frameLow;
frameData(:, logical(posB)) = frameHigh;

fName = 'gen/test_pattern_1_dat.txt';
fileID = fopen(fName, 'w');

[row, col] = size(frameData);
formatLineLen = col + 1;
dataCounter = false;
for m = 1 : row
   for n = 1 : formatLineLen 
       if n == 1 && m == 1
           dataToSend = MakeFrame(0,1,1,0,0);
           dataCounter = false;
       elseif n == 1
           dataToSend = MakeFrame(0,1,0,0,0);
       else
           dataToSend = MakeFrame(frameData(m, n - 1), 0, 0, dataCounter,... 
            [rPlane565(m, round((n - 1) / 2)),
             gPlane565(m, round((n - 1) / 2)),
             bPlane565(m, round((n - 1) / 2))]);
           dataCounter = not(dataCounter);
       end
       fprintf(fileID, '%s\n', dataToSend); 
    end
end
dataToSend = MakeFrame(0,1,1,0,0);
fprintf(fileID, '%s\n', dataToSend);

fclose(fileID);
disp("File saved")

% ---- display diff -----
% imgN(:,:,1) = rPlane565;
% imgN(:,:,2) = gPlane565;
% imgN(:,:,3) = bPlane565;
% 
% subplot(211)
% imshow(img);
% subplot(212)
% imshow(imgN);

function str = MakeFrame(frameData, hSync, vSync, validDataSign, dataVector)
    tmpData = dataVector;
    len = length(dataVector);
    if len < 3 
        tmpData = [0, 0, 0];
    end
    valSign = 0;
    if validDataSign 
        valSign = 1;
    end
    str = sprintf('%s %d %d %d %s %s %s',...
            dec2hex(frameData, 2),... 
            hSync,...
            vSync,...
            valSign,...
            dec2hex(tmpData(1), 2),...
            dec2hex(tmpData(2), 2),...
            dec2hex(tmpData(3), 2));
end