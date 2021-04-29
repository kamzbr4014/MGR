clear all;
close all;

imgRaw = imread("data/test_plane.jpg");
img = rgb2gray(imgRaw);
imgMatlabRef = img;
imgModelRef = rgb_2_g(imgRaw, 2);
[imRow, imCol] = size(img);

resFilePath = "../tb/res/test_pattern_1_res.txt";
formatSpec = '%x';
fileID = fopen(resFilePath, 'r');
resDataRaw = uint8(fscanf(fileID, formatSpec));

resData = (reshape(resDataRaw, imCol, []))';

subplot(221); imshow(imgRaw); title("Orginal");
subplot(222); imshow(imgMatlabRef); title("Matlab rgb2gray");
subplot(223); imshow(imgModelRef); title("Model reference");
subplot(224); imshow(resData); title("resData");