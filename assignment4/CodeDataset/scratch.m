
fin_img = im2bw(rgb2gray(test), graythresh(rgb2gray(test)));
fin_img = ~fin_img;
imwrite(fin_img,'digit_train/stardust/0001.png');
%----------------------------------------------------------

% Read ground truthed template images into a structure.
dir_path = './digit_train/';
dir_fold = dir(dir_path);
dir_num = length(dir_fold);

char_templates = struct();

for i = 1:dir_num
    if strcmp(dir_fold(i).name,'.') || strcmp(dir_fold(i).name,'..')
        continue;
    end
    
    img_path = [dir_path,dir_fold(i).name];
    img_dir = dir(img_path);
    img_num = length(img_dir);
    
    curr_loc = 0;
    for j = 1:img_num
        if strcmp(img_dir(j).name,'.') || strcmp(img_dir(j).name,'..')
            continue;
        end
        
        curr_loc = curr_loc + 1;
        img = imread([img_path,'/',img_dir(j).name]);
        

        
        char_templates.(dir_fold(i).name){curr_loc} = img;

    end
end
%-------------------------------------------------------------