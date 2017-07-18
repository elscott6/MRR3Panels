function [ MRRfinal ] = caller_MRR_read_ukoln_nc( directory, prefix, datestart, dateend, suffix, records_per_file )
%CALLER_MRR_READ_UKOLN_NC Summary of this function goes here
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This code is part of a suite of software developed under the guidance of
% Dr. Sandra Yuter and the Cloud Precipitation Processes and Patterns Group
% at North Carolina State University.
% Copyright (C) 2013 Spencer Rhodes and Andrew Hall
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


starttime = datenum(datestart, 'yyyymmdd');
endtime = datenum(dateend, 'yyyymmdd');
days = endtime - starttime + 1;

previousgates = 31; % Forced gate count if none exists.

for i = 0:(days - 1)
    datevar = datestr(starttime + i, 'yyyymmdd');
    fileloc = strcat(directory, prefix, datevar, suffix);
    if fopen(fileloc) == -1
        MRR.dates = [];
        MRR.Z = [];
        MRR.W = [];
        MRR.SW = [];
        gates = previousgates;
        fclose('all');
    else
        fclose('all');
        [MRR] = MRR_read_ukoln_nc(fileloc);
        gates = numel(MRR.Z)/length(MRR.Z);
        previousgates = gates;
        
        % Error check that start time of MRR struct is 00:00 UTC and end
        % time is 23:59 UTC.  If not, correct the size of the MRR struct so
        % it is.
        if ~strcmp(datestr(MRR.dates(1),'HH:MM'), '00:00')
            % In order to get the correct date of the MRR file, pull from
            % the middle or towards the middle of the file (in this case,
            % we're going with index 700)
            expectedstart = datenum([datestr(starttime+i, 'yyyymmdd') '_0000'],'yyyymmdd_HHMM');
            if MRR.dates(1) < expectedstart
                % Then we need to trim the beginning of MRR struct
                % Use while loop to determine how much to trim
                counter = 2;
                while MRR.dates(counter) < expectedstart
                    counter = counter + 1;
                end
                % Once loop finishes, counter will have the new start
                MRR.dates = MRR.dates(counter:end);
                MRR.Z = MRR.Z(counter:end,:);
                MRR.W = MRR.W(counter:end,:);
                if isfield(MRR,'SW')
                    MRR.SW = MRR.SW(counter:end,:);
                end
            end
        end
        % Error check for correct end time (essentially mirror of the
        % previous if-statement)
        if ~strcmp(datestr(MRR.dates(end),'HH:MM'), '23:59')
            expectedend = datenum([datestr(starttime+i, 'yyyymmdd') '_2359'],'yyyymmdd_HHMM');
            if MRR.dates(end) > expectedend
                counter = length(MRR.dates) - 1;
                while MRR.dates(counter) > expectedend
                    counter = counter - 1;
                end
                MRR.dates = MRR.dates(1:counter);
                MRR.Z = MRR.Z(1:counter,:);
                MRR.W = MRR.W(1:counter,:);
                if isfield(MRR,'SW')
                    MRR.SW = MRR.SW(1:counter,:);
                end
            end
        end
    end
    fprintf('New MRR struct created for %s...\n',fileloc)
    
    if length(MRR.Z) < records_per_file
        if length(MRR.Z) == 1440
            records_per_file = 1440;
        elseif length(MRR.Z) < 1440 && records_per_file == 2880
            records_per_file = 1440;
        end
        
        if length(MRR.Z) < 2880
            
            if isempty(MRR.dates)
                MRR.dates(1) = starttime + i;
                MRR.dates(2) = starttime + i + 1 - (1/(24*60));
                fprintf('No data on %s, inserting NaNs...\n', datestr(starttime+i));
                MRR.Z = NaN(2,31); MRR.W = NaN(2,31); MRR.SW = NaN(2,31);
            elseif length(MRR.dates) < 1440
                fprintf('Missing data on %s, inserting NaNs...\n', datestr(starttime+i));
                if isempty(strfind(datestr(MRR.dates(1),'yyyymmdd_HHMM'), ...
                                   datestr(starttime+i, 'yyyymmdd_HHMM')))
                    MRR.dates = [starttime+i; MRR.dates];
                    MRR.Z = [NaN(1,31); MRR.Z];
                    MRR.W = [NaN(1,31); MRR.W];
                    MRR.SW = [NaN(1,31); MRR.SW];
                end
                if isempty(strfind(datestr(MRR.dates(end), 'yyyymmdd_HHMM'), ...
                                   datestr(starttime+i+1-(1/(24*60)), 'yyyymmdd_HHMM')))
                    MRR.dates = [MRR.dates; starttime + i + 1 - (1/(24*60))];
                    MRR.Z = [MRR.Z; NaN(1,31)];
                    MRR.W = [MRR.W; NaN(1,31)];
                    MRR.SW = [MRR.SW; NaN(1,31)];
                end
            end
            findgaps = [];
            for j = 2:length(MRR.dates)
                if MRR.dates(j) - MRR.dates(j-1) >= 2/(24*60)
                    findgaps = [findgaps, j];
                end
            end
            j = length(findgaps);
            while j >= 1
                gaptofill = MRR.dates(findgaps(j)-1):1/(24*60):MRR.dates(findgaps(j));
                gaptofill(end) = []; gaptofill(1) = [];
                
                MRR.dates = [MRR.dates(1:findgaps(j)-1); gaptofill'; MRR.dates(findgaps(j):end)];
                MRR.Z = [MRR.Z(1:findgaps(j)-1,:); NaN(length(gaptofill),31); MRR.Z(findgaps(j):end,:)];
                MRR.W = [MRR.W(1:findgaps(j)-1,:); NaN(length(gaptofill),31); MRR.W(findgaps(j):end,:)];
                MRR.SW = [MRR.SW(1:findgaps(j)-1,:); NaN(length(gaptofill),31); MRR.SW(findgaps(j):end,:)];
                j = j-1;
            end
        end
    end
    
    if i == 0
        if ~isfield(MRR,'header')
            % Use default number of gates (31)
            MRRfinal.Z = zeros(days * records_per_file, 31);
            MRRfinal.W = zeros(days * records_per_file, 31);
            MRRfinal.SW = zeros(days * records_per_file, 31);
            MRRfinal.dates = zeros(days * records_per_file, 1);
        else
            MRRfinal.Z = zeros(days * records_per_file, MRR.header.numgates);
            MRRfinal.W = zeros(days * records_per_file, MRR.header.numgates);
            MRRfinal.SW = zeros(days * records_per_file, MRR.header.numgates);
            MRRfinal.dates = zeros(days * records_per_file, 1);
            MRRfinal.header = MRR.header;
            MRRfinal.rawHeaderLines = MRR.rawHeaderLines;
        end
    end
    
    if ~isfield(MRRfinal, 'header') && isfield(MRR, 'header')
        MRRfinal.header = MRR.header;
        MRRfinal.rawHeaderLines = MRR.rawHeaderLines;
    end
    
    MRRfinal.dates(i * records_per_file + 1:(i + 1) * length(MRR.dates)) = MRR.dates;
    MRRfinal.Z(i * records_per_file + 1:(i + 1) * length(MRR.Z), 1:gates) = MRR.Z(1:length(MRR.Z),:);
    MRRfinal.W(i * records_per_file + 1:(i + 1) * length(MRR.W), 1:gates) = MRR.W(1:length(MRR.W),:);
    MRRfinal.SW(i * records_per_file + 1:(i + 1) * length(MRR.SW), 1:gates) = MRR.SW(1:length(MRR.SW),:);
    
end

end

