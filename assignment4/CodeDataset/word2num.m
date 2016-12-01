function [ num ] = word2num( word )
%WORD2NUM Convert English word to digit string

switch word
    case 'zero'
        num = '0';
    case 'one'
        num = '1';
    case 'two'
        num = '2';
    case 'three'
        num = '3';
    case 'four'
        num = '4';
    case 'five'
        num = '5';
    case 'six'
        num = '6';
    case 'seven'
        num = '7';
    case 'eight'
        num = '8';
    case 'nine'
        num = '9';
    otherwise
        num = 'ERROR';
end
end

