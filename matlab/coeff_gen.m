clear all;
close all;

W = 5;
fractLen = 8;
sigma = 1;
coeffs = fspecial('gaussian', [W W], sigma);
coeffsFI = ufi(coeffs, 8, fractLen);

fName = 'gen/filter_coeffs.txt';
fNameDat = 'gen/filter_coeffs.dat';
fileID = fopen(fName, 'w');
fileDatID = fopen(fNameDat, 'w');

dlmwrite(fNameDat, coeffs);
for i = 1 : W
    for j = 1 : W
        dataToSend = hex(coeffsFI(i,j));
        fprintf(fileID, '%s\n', dataToSend);
    end
end
fclose(fileID);
fclose(fileDatID);
disp("---------- File saved ----------")