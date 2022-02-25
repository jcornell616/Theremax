%% FPGA Log %%
%
% Jackson Cornell
%

% key = 12log2(fs) - 12log2(440*period) + 69
fs = 12000;
period = 0:255;
key = 12*log2(fs) - 12*log2(440*period) + 69
key = round(key)
key(1) = 0;

% write to mif file
fid = fopen('midi_keys.mif','w');

fprintf(fid,'-- 256x8 Pitch to MIDI LUT\n\n');
fprintf(fid,'WIDTH = 8;\n');
fprintf(fid,'DEPTH = 256;\n\n');
fprintf(fid,'ADDRESS_RADIX = UNS;\n');
fprintf(fid,'DATA_RADIX = UNS;\n\n');
fprintf(fid,'CONTENT BEGIN\n');

for i=1:256
    data = key(i);
    fprintf(fid,'%4u : %4u;\n',i-1, data);
end

fprintf(fid,'END;');
fclose(fid);


