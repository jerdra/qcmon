function [vol4D, fwhm] = preprocess_nii_phantom(input, output)
%PHANTOM_FMRI Summary of this function goes here
%
%   Reads Phantom Nii files and preprocesses it for ABCD-QA-Pipeline

[vol4D, fwhm] = getFWHM(input,output);
end    

function [vol4D, fwhm] = getFWHM(fname, output)
nifti_image = load_nii(fname);
vol4D = rot90(flip(double(nifti_image.img),1),3);

cmd = sprintf('mkdir %s/AFNI', output);
unix(cmd);
cmd = sprintf('3dcopy %s %s/AFNI/dset+orig', fname, output);
unix(cmd)

afni_output = [output, '/AFNI'];
cmd = sprintf('3dvolreg -prefix %s/volreg %s/dset+orig',afni_output, afni_output);
unix(cmd);
cmd = sprintf('3dDetrend -polort 2 -prefix %s/voldetrend %s/volreg+orig', afni_output, afni_output);
unix(cmd);
cmd = sprintf('3dTstat -mean -prefix %s/volmean %s/volreg+orig', afni_output, afni_output);
unix(cmd);
cmd = sprintf('3dAutomask -q -prefix %s/volmask %s/volmean+orig', afni_output, afni_output);
unix(cmd);
cmd = sprintf('3dFWHMx -dset %s/voldetrend+orig -mask %s/volmask+orig -out %s/FWHMVALS', afni_output, afni_output, afni_output);
unix(cmd);

fname = fullfile(afni_output,'FWHMVALS');
fileID = fopen(fname,'r');
formatSpec = '%f';
sizeA = [3 size(vol4D,4)];
A = fscanf(fileID,formatSpec,sizeA);
fclose(fileID);

fwhm_x = A(1,:);
fwhm_x(fwhm_x==-1)=0;
fwhm(1)=mean(nonzeros(fwhm_x));

fwhm_y = A(2,:);
fwhm_y(fwhm_y==-1)=0;
fwhm(2)=mean(nonzeros(fwhm_y));

fwhm_z = A(3,:);
fwhm_z(fwhm_z==-1)=0;
fwhm(3)=mean(nonzeros(fwhm_z));

end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function isdicom=file_is_dicom(filename)
isdicom=false;
try
    fid = fopen(filename, 'r');
    status=fseek(fid,128,-1);  
    if(status==0)
        tag = fread(fid, 4, 'uint8=>char')';
        isdicom=strcmpi(tag,'DICM');
    end
    fclose(fid);
catch me
end

end

