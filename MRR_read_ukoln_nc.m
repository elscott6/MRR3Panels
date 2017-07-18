function [ MRR_struct ] = MRR_read_ukoln_nc( file_name )
%MRR_READ_UKOLN_NC Summary of this function goes here
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


[dims, data] = gen_readnetcdf2array_v3(file_name,'time','range', 'height',...
                                                 'GLBL.source', 'GLBL.properties',...
                                                 'Ze', 'W', 'spectralWidth');

fclose('all');
                                             
sec_coords = double(data(1).data);
sec_coords = sec_coords - median(diff(sec_coords));
base_date = repmat([1970 1 1 0 0],length(sec_coords),1);
date_number = datenum([base_date sec_coords]);

gate_heights = double(data(3).data');


reflectivity = double(data(6).data');
reflectivity(reflectivity == -9999) = nan;

velocity = double(data(7).data');
velocity(velocity == -9999) = nan;

spectral_width = double(data(8).data');
spectral_width(spectral_width == -9999) = nan;

MRR_struct.dates = date_number;
MRR_struct.Z = reflectivity;
MRR_struct.W = velocity;
MRR_struct.SW = spectral_width;

MRR_struct.header.numgates = size(gate_heights,2);
MRR_struct.header.firstgate = nanmedian(gate_heights(:,1));
MRR_struct.header.gatedist = nanmedian(nanmedian(diff(gate_heights')));

properties = data(5).data;
instrument_height = regexprep(properties, '^[\S\s]*''InstrumentHeight'': (\d+)[\S\s]*$','$1');
if strcmp(instrument_height, properties)
    MRR_struct.header.height = 0;
else
    MRR_struct.header.height = str2num(instrument_height);
end

[dir, name, suffix] = fileparts(file_name);
MRR_struct.rawHeaderLines{1,1}{1,1} = '; Version: 2.0';
MRR_struct.rawHeaderLines{1,1}{2,1} = ['; Original Source Filename: ', [name suffix]];
MRR_struct.rawHeaderLines{1,1}{3,1} = ['; Original Source Path: ', dir];

end

