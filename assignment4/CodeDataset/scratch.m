fin_img = im2bw(rgb2gray(x001), graythresh(rgb2gray(x001)));
fin_img = ~fin_img;
imwrite(fin_img,'digit_train/slash/0001.png');