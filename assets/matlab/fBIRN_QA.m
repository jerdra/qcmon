function fBIRN_QA(nii,dcm,json,output)
%FBIRN_QA - 
%{
Usage:
    nii:            NIfti file
    dcm:            Sample dcm file (header pulling)
    json:           BIDS json sidecar file
    output:         Folder to output
%}

%================Check inputs===========% 
tic

if nargin <2
    fprintf('Requires input and output directory. Exiting...\n');
    return;
end

%================Read dicom files====================%

meta = get_meta_data(dcm,json);

%=====================Read nifti file========================%

[vol,fwhm] = preprocess_nii_phantom(nii,output);


%==============Calls fBIRN QA routine=================%

if meta.TR == 800
    MB_fBIRN_phantom_ABCD(vol, meta, output, fwhm); 
elseif meta.TR == 2000
    fBIRN_phantom_ABCD(vol, meta, output, fwhm); 
else
    exit
end

%====================================


fprintf('Finished\n');
toc

exit
end

