function y = rgb_2_g(img, met)
    method = met;

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
            tmpA = uint16(rPlane) + uint16(bPlane);
            tmpB = bitshift(uint16(gPlane), 1);
            tmpC = tmpA + tmpB;
            y =  uint8(bitshift(tmpC, -2));
    end
end 