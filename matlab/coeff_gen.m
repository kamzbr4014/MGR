clear all;
close all;

W = 5;
fractLen = 8;
sigma = 1;
coeffs = fspecial('gaussian', [W W], sigma);
coeffsFI = ufi(coeffs, 8, fractLen);

fName = 'gen/filter_coeffs.txt';
fileID = fopen(fName, 'w');

for i = 1 : W
    for j = 1 : W
        dataToSend = hex(coeffsFI(i,j));
        fprintf(fileID, '%s\n', dataToSend);
    end
end

fclose(fileID);
disp("---------- File saved ----------")