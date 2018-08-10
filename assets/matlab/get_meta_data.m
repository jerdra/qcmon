function [ meta ] = get_meta_data(dcm,json)
%GET_META_DATA Given subid searches dcm archive for matching file then
%extracts meta-data for specific scanner
% pha_id - full phantom ID
% json_path - str path to JSON file, found in nii folder of datman tree

%Load file
if file_is_dicom(dcm)
    info=dicominfo(dcm);
else
    fprintf('Only dicoms should be included in this folder. Aborting...\n');
    return;
end

%From header information extract manufacturer and extract acquisition
%parameters (only do PRISMA scans for now) 
if (strfind(info.Manufacturer, 'GE'))
    [meta] = read_ge_phantom(dcm,json);
elseif  (strfind(info.Manufacturer, 'SIEMENS'))
    [meta] = read_siemens_phantom(dcm,json);
elseif (strfind(info.Manufacturer, 'Philips'))
    [meta] = read_philips_phantom(dcm,json);
else
    return;
end

end


function [meta]=read_siemens_phantom(dcm,json)
osLevel = '';
if exist(json,'file')
    json_data=loadjson(json);
    if isfield(json_data,'OSLevel'), osLevel = json_data.OSLevel; end
end

if file_is_dicom(dcm)
    info=dicominfo(dcm);
    imatrix = nonzeros(info.AcquisitionMatrix);
    nVx = double(imatrix(1));
    nVy = double(imatrix(2));
    nSlices = double(info.Private_0019_100a);
%     nFrames = length(filelist); %not used explicitly

    
    imageFreq = info.ImagingFrequency;
    transmitGain = 0;
    aRecGain = 0;
    
    sx = info.PixelSpacing(1);
    sy = info.PixelSpacing(2);
    sz = info.SliceThickness;
    
    TR = info.RepetitionTime;
    FA = info.FlipAngle;
    TE = info.EchoTime;
    
    s_date = info.StudyDate;
    s_time = info.StudyTime;
    si_UID = info.StudyInstanceUID;
    se_time = info.SeriesTime;
    se_number = info.SeriesNumber;
    manufact = info.Manufacturer;
    model = info.ManufacturerModelName;
    sDes = info.SeriesDescription;
    
    if (isfield(info,'DeviceSerialNumber')) serialNumber = info.DeviceSerialNumber; else serialNumber=''; end;
    if (isfield(info,'SoftwareVersion')) softVersion = info.SoftwareVersion; else softVersion=''; end;
    if (isfield(info,'ImageComments')) imComments = info.ImageComments; else imComments=''; end;
    
    if (isfield(info, 'Private_0051_100f'))
        coilTypes = info.Private_0051_100f;
        if any(strfind(coilTypes, 'HEA;HEP'))
            coil = '32Ch';
        elseif any(strfind(coilTypes, 'HC1-7'))
            coil = '64Ch';
        else
            coil = 'Coil Not Recognized';
        end
    else
        coil = 'Error reading coil dicom tag';
    end
else
    fprintf('Only dicoms should be included in this folder. Aborting...');
    return;
end

meta = struct('TR',TR, 'FA',FA, 'TE', TE, 'imageFreq', imageFreq, 'transmitGain', transmitGain, 'aRecGain', aRecGain, 'sx', sx, 'sy', sy, 'sz', sz,...,
    's_date', s_date, 's_time', s_time, 'si_UID', si_UID, 'se_time', se_time, 'se_number', se_number, 'manufact', manufact, 'model', model, 'sDes', sDes, 'coil', coil,...,
    'serialNumber', serialNumber, 'softVersion', softVersion, 'osLevel', osLevel, 'imComments', imComments);
end

function [meta]=read_ge_phantom(dcm,json)
osLevel = '';
if exist(json,'file')
    json_data=loadjson(json);
    if isfield(json_data,'OSLevel'), osLevel = json_data.OSLevel; end
end
if(file_is_dicom(dcm))
    info=dicominfo(dcm);
    nVy = info.Rows;
    nVx = info.Columns;
    nImages = info.ImagesInAcquisition;
    nFrames = info.NumberOfTemporalPositions;
    
    sx = info.PixelSpacing(1);
    sy = info.PixelSpacing(2);
    sz = info.SliceThickness;
    
    imageFreq = info.Private_0019_1093;
    transmitGain = info.Private_0019_1094;
    aRecGain = info.Private_0019_1095;
    if (nImages > nFrames)
        while(mod(nImages,nFrames)~=0)
            nFrames = nFrames-1;
        end
        nSlices = nImages/nFrames;
    else
        nSlices = nImages;
    end
    TR = info.RepetitionTime;
    FA = info.FlipAngle;
    TE = info.EchoTime;
    
    s_date = info.StudyDate;
    s_time = info.StudyTime;
    si_UID = info.StudyInstanceUID;
    se_time = info.SeriesTime;
    se_number = info.SeriesNumber;
    manufact = info.Manufacturer;
    model = info.ManufacturerModelName;
    sDes = info.SeriesDescription;
    
    if (isfield(info,'DeviceSerialNumber')) serialNumber = info.DeviceSerialNumber; else serialNumber=''; end;
    if (isfield(info,'SoftwareVersion')) softVersion = info.SoftwareVersion; else softVersion=''; end;
    if (isfield(info,'ImageComments')) imComments = info.ImageComments; else imComments=''; end;
    
    if (isfield(info, 'ReceiveCoilName'))
        coil = info.ReceiveCoilName;
    else
        coil = '';
    end
    
else
    fprintf('Only dicoms should be included in this folder. Aborting...');
    return;
end

meta = struct('TR',TR, 'FA',FA, 'TE', TE, 'imageFreq', imageFreq, 'transmitGain', transmitGain, 'aRecGain', aRecGain, 'sx', sx, 'sy', sy, 'sz', sz,...,
    's_date', s_date, 's_time', s_time, 'si_UID', si_UID, 'se_time', se_time, 'se_number', se_number, 'manufact', manufact, 'model', model, 'sDes', sDes, 'coil', coil,...,
    'serialNumber', serialNumber, 'softVersion', softVersion, 'osLevel', osLevel, 'imComments', imComments);

end

function [meta]=read_philips_phantom(dcm,json)
osLevel = '';
if exist(json,'file')
    json_data=loadjson(json);
    if isfield(json_data,'OSLevel'), osLevel = json_data.OSLevel; end
end
if(file_is_dicom(dcm))
    info=dicominfo(dcm);
    nVy = info.Rows;
    nVx = info.Columns;
    nImages = length(filelist);
    nFrames = double(info.NumberOfTemporalPositions);
    
    sx = info.PixelSpacing(1);
    sy = info.PixelSpacing(2);
    sz = info.SliceThickness;
    
    imageFreq = info.ImagingFrequency;
    transmitGain = 0;
    aRecGain = 0;
    
    nSlices = nImages/nFrames;
    TR = info.RepetitionTime;
    FA = info.FlipAngle;
    TE = info.EchoTime;
    
    
    s_date = info.StudyDate;
    s_time = info.StudyTime;
    si_UID = info.StudyInstanceUID;
    se_time = info.SeriesTime;
    se_number = info.SeriesNumber;
    manufact = info.Manufacturer;
    model = info.ManufacturerModelName;
    sDes = info.SeriesDescription;
    
    if (isfield(info,'DeviceSerialNumber')) serialNumber = info.DeviceSerialNumber; else serialNumber=''; end;
    if (isfield(info,'SoftwareVersion')) softVersion = info.SoftwareVersion; else softVersion=''; end;
    if (isfield(info,'ImageComments')) imComments = info.ImageComments; else imComments=''; end;
    
    if (isfield(info, 'ReceiveCoilName'))
        coil = info.ReceiveCoilName;
    else
        coil = '';
    end
    
else
    fprintf('Only dicoms should be included in this folder. Aborting...');
    return;
end

meta = struct('TR',TR, 'FA',FA, 'TE', TE, 'imageFreq', imageFreq, 'transmitGain', transmitGain, 'aRecGain', aRecGain, 'sx', sx, 'sy', sy, 'sz', sz,...,
    's_date', s_date, 's_time', s_time, 'si_UID', si_UID, 'se_time', se_time, 'se_number', se_number, 'manufact', manufact, 'model', model, 'sDes', sDes, 'coil', coil,...,
    'serialNumber', serialNumber, 'softVersion', softVersion, 'osLevel', osLevel, 'imComments', imComments);
end

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