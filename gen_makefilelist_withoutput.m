function output = gen_makefilelist_withoutput( checkdir, listdir, varargin )
%% Documentation Section
% Script:  gen_make_filelist.m
% Author:  Nicole Corbin
% Version Date:  08 Oct 2014
% Purpose:  Create .list file of all files in a given directory
% Input Arguments:  
%     (a) checkdir - directory to search for WSR-88D files
%     (b) listdir - path to which the filelist will be saved
% Varargin flags:
%     append - append a description to the name of the filelist
%     time - beginning time (string) of event in the format yyyymmddHHMMSS
%            immediately followed by an end time string the the same format.
%
% Output Arguments: full path to file list
% Functions Used: N/A
% Required Paths: N/A
%
% Example usage: filelistpath = gen_makefilelist_v2(checkdir, listdir,...
%                                   'append', 'testing',...
%                                   'time', '19920126120000', '19920126235959');
% 

% Set default variables
append = '';

% Parse varargin
for i = 1:size(varargin,2)
    switch varargin{i}
        case 'append' % one region or all regions
            append = varargin{i+1};
        case 'time'
            starttime = varargin{i+1};
            endtime = varargin{i+2};
    end
end

% Set output filename
filename = [listdir,append,'filelist.list'];

% Retrieve file information for given directory
filestr = dir(checkdir);

% Create cell array with file full path names for given directory
filelist = cell((size(filestr,1)-2),1);
for filenum = 3:size(filestr,1)
    filelist{filenum-2} = [checkdir,filestr(filenum).name];
end

tic

% If only certain times are requested, write out only those times
if exist('starttime', 'var');

        %Matt trying things
        dateTimeList = regexprep(filelist,'^\S*(\d{8}).(\d{6})\S*$','$1$2');  
        %dateTimeList = regexprep(filelist,'(\d{14})','$1');
        datenumList = datenum(dateTimeList,'yyyymmddHHMMSS');
        start_index = find(datenumList>=datenum(starttime,'yyyymmddHHMMSS'),1,'first');
        end_index = find(datenumList<=datenum(endtime,'yyyymmddHHMMSS'),1,'last');
        if end_index<start_index
            error('end index greater than start index\n')
        end
        %end matt trying things

        
        % Write out partial file list
        filelist_2 = filelist(start_index:end_index);
        
        fid = fopen(filename, 'w');
        for i = 1:size(filelist_2,1)
            fprintf(fid,'%s\n',filelist_2{i});
        end
        fclose(fid);

else
    
    % Write out complete file list
    fid = fopen(filename, 'w');
    for i = 1:size(filelist,1)
        fprintf(fid,'%s\n',filelist{i});
    end
    fclose(fid);
    
end

output{1} = filename;
output{2} = filelist_2;


end