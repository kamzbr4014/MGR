clear all;
close all;

imgRaw = imread("data/test_plane.jpg");
img = rgb2gray(imgRaw);
imgMatlabRef = img;
[imRow, imCol] = size(img);
fNameDat = 'gen/filter_coeffs.dat';
coeffs = load(fNameDat);

resFilePath = "../tb/res/test_pattern_1_res.txt";
formatSpec = '%x';
fileID = fopen(resFilePath, 'r');
resDataRaw = uint8(fscanf(fileID, formatSpec));

imgModelRef = uint8(conv2(imgMatlabRef, coeffs));
resData = (reshape(resDataRaw, imCol, []))';

subplot(221); imshow(imgRaw); title("Orginal");
subplot(222); imshow(imgMatlabRef); title("Matlab rgb2gray");
subplot(223); imshow(imgModelRef); title("Model reference");
subplot(224); imshow(resData); title("resData");