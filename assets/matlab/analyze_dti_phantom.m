%  analyze_dti_phantom(dwi, fa, bval, output, nyqopt)
%
%  'dwi':    4D diffusion weighted image
%  'fa':     FA map from DTIfit
%  'bval':   B value files from dcm2nii
%  'output': full path to output prefix
%  'accel': ('y', 'n') 'n' to measure nyquist ghost on non-accelerated data.

function analyze_dti_phantomSC(dwi, fa, bval, output_prefix, accel)
try
    %% Part 1: load data
    disp('loading data');
    bval = dlmread(bval);
    dwi = load_nifti(dwi);
    fa = load_nifti(fa);

    if accel=='y'
        PAR='PAR';
    elseif accel=='n'
        PAR='NPAR';
    else
        disp('problem with accel value')
        exit(1)
    end

    % calculate number of directions / b0 volumes
    ndir = length(find(bval>0));
    nb0 = length(find(bval==0));
    bvalueall=bval(find(bval>0));
    bvalue=bvalueall(1);
    
    % load DWI, averaging over 3 central slices. dim1,2=AXIAL, dim3=all directions)
    dims = size(dwi.vol);
    central_slice = ceil(dims(3)/2);
    DWI = mean(dwi.vol(:,:, central_slice-1:central_slice+1, :), 3);
    
    DWIrot=imrotate(DWI,90); % get PE along vertical direction
    clear DWI
    DWI=DWIrot;
    
    [Nx, Ny, numimgs] = size(DWI);

    % load FA, taking central slice only
    FA = fa.vol(:,:,central_slice);

    clear fa dwi

    %% 2.3.1 SNR Measurements
    [AVEsnr0, CVsnr0, AVEsnrDWI, CVsnrDWI] = getSNR(DWI, nb0, PAR);

    R = AVEsnrDWI/AVEsnr0;
    ADC = (log(R)/bvalue)*1000; % in units of 10^-3 s/mm^2

    DIRfig=output_prefix;
    fig1name=strcat(DIRfig,'DiffImgs-',PAR);
    print('-f1',fig1name,'-djpeg');

    fig2name=strcat(DIRfig,'StdPlotsHist-',PAR);
    print('-f2',fig2name,'-djpeg');

    fig3name=strcat(DIRfig,'SNRImgs-',PAR);
    print('-f3',fig3name,'-djpeg');

    fig4name=strcat(DIRfig,'SNRplots-',PAR);
    print('-f4',fig4name,'-djpeg');

    disp('done 2.3.1')
    pause(0.5)

    %% 2.3.2 B0 inhomogeneity
    [RatioB0, diax, diay] = getB0Distortion(DWI, nb0, PAR);

    fig1name=strcat(DIRfig,'B0Distortion-',PAR)
    print('-f1',fig1name,'-djpeg')

    disp('done 2.3.2')
    pause(0.5)

    %% 2.3.3 Eddy Current Distortions & 2.3.4 Nyquist Ratio
    [avevoxsh, errvoxsh, NyqRatio]=getEddyCurrentDistortion_and_NyquistRatio(DWI, nb0, PAR);

    fig1name = strcat(DIRfig, 'CentralSlice-', PAR);
    print('-f1', fig1name, '-djpeg')

    fig2name = strcat(DIRfig, 'MaskCentralSlice-', PAR);
    print('-f2', fig2name, '-djpeg')

    fig3name = strcat(DIRfig, 'DiffMasks-', PAR);
    print('-f3', fig3name, '-djpeg')

    fig4name = strcat(DIRfig, 'Plot-EddyCurrentDist-', PAR);
    print('-f4', fig4name, '-djpeg')

    fig5name = strcat(DIRfig, 'NyquistRatio-', PAR);
    print('-f5', fig5name, '-djpeg')

    disp('done 2.3.3 and 2.3.4')
    pause(0.5)

    %% 2.3.5 FA
    close all

    fav = FA(find(FA));
    aveFA = mean(fav);
    stdFA = std(fav);

    h1 = figure(1)
    set(h1, 'Visible', 'off');
    set(h1, 'Units', 'inches');
    h1.Position=[10 7 15 10];

    subplot(2,2,1)
    imagesc(FA, [0 0.1]);
    set(gca,'DataAspectRatio',[1 1 1]); colorbar;
    title('FA map');

    subplot(2,2,2)
    plot(fav);
    title('FA values');

    subplot(2,2,3)
    [n,x] = hist(fav,30); plot(x, n, 'k-');
    title(['FA mean(std)=', num2str(aveFA, '%5.3f'), '(', num2str(stdFA, '%5.3f'), ')']);

    %% Write values into struct --> encode as json --> write to single output file
    j.avg_SNR_B0 = AVEsnr0;
    j.cov_SNR_B0 = CVsnr0;
    j.avg_SNR_DWI = AVEsnrDWI;
    j.vox_SNR_DWI = CVsnrDWI;
    j.adc = ADC;
    j.b0_distortion_ratio = RatioB0;
    j.avg_voxel_shift = avevoxsh;
    j.percent_error_voxel_shift = errvoxsh;
    j.avg_FA = aveFA;
    j.std_FA = stdFA;
    j.nyq_ratio = NyqRatio; 
    j.pipeline = 'qa dti';
    encoded_j = savejson('',j); 
    output = strcat(output_prefix, '_qa_dti.json');
    fid = fopen(output, 'w');
    fprintf(fid,encoded_j); 
    fclose(fid); 
                   
    close all
    exit
catch
    exit(1)
end
end
