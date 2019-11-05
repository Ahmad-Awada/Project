%Simply type "deNoise()" in the command window and select your previous workspace directory. (Same folder for all steps)

function deNoise
%User selected work space and data to process
workdir = uigetdir();
basename1 = [workdir,'\Raw\'];
basename2 = [workdir, '\Denoised\'];
estname3 = [workdir, '\Denoised\Estimated Noise Levels.csv'];

stk = input('Input the number of the first stack being processed: ');
n = input('Input the number of the last stack being processed: ');
temp = dir([basename1, '\s1\*.png']);
a = length(temp);
b = zeros(stk+1-n, a);
    
o=0;


for j = stk:1:n
    %reading files and making directories through loop
    basename3 = ['s', num2str(stk+o), '\'];
    pathname = [basename2, basename3];
    mkdir(basename2, basename3);
    

    for i = 1:1:a
        newname = strcat('y_est',num2str(i));
        filename = [basename1,'s',num2str(stk+o),'\' ,num2str(i),'.png'];
        img = double(imread(filename));
        c = NoiseLevel(img);
        b(j, i) = c;
        %end
        
        %Denoise
        [PSNR, y_est] = BM3D(1, img, c, 'np', 0);
        
        %Iterate filename through loop and save
        filename2 = [pathname,num2str(i),'.png'];
        imwrite(y_est, filename2);
    end
    o=o+1
end
    csvwrite(estname3, b);
end


