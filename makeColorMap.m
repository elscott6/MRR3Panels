function [ cmap ] = makeColorMap( varargin )
%MAKECOLORMAP Summary of this function goes here
%This function is used to produce linearly interpolated colormaps that go
%through more than one color.  For example, go from red to black to green
%with black in the middle.  Used in making simulated red-grey-green
%velocity fields.
%
%You may call the function with 1 of four syntaxes
%-2 input color vectors (3 element RGB color vectors)
% --this will produce a single transition from color1 to color2 with the
% default number of colors (32)
%-3 input color vectors
% --produce a 3 color cmap from color1 to color2 to color3 with the default
% number of colors (32)
%-2 input colors followed by a single number
% --produce a 2 color cmap from color1 to color2 with argin3 number of
% colors
%-3 input colors followed by a single number
% --produce a 3 color cmap from color1 to color2 to color3 with argin4
% number of colors
%
%NOTE: The order matters... the "bottom" color of the colormap should be
%the first color introduce and the "top" color the last number.  And if a
%specific number of colors is desired it should always be the last input.
%
%This is a general use function created by Andrew Hall on or around May
%2011
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This code is part of a suite of software developed under the guidance of
% Dr. Sandra Yuter and the Cloud Precipitation Processes and Patterns Group
% at North Carolina State University.
% Copyright (C) 2013 Andrew Hall and Spencer Rhodes
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

NUM_COLORS = 32;


%Sort inputs and assign to variables
if nargin == 2
    color.start = varargin{1};
    color.middle = [];
    color.end = varargin{2};
    color.num = NUM_COLORS;
elseif nargin == 4
    color.start = varargin{1};
    color.middle = varargin{2};
    color.end = varargin{3};
    color.num = varargin{4};
elseif nargin == 3
    if numel(varargin{3}) == 1
        color.start = varargin{1};
        color.middle = [];
        color.end = varargin{2};
        color.num = varargin{3};
    elseif numel(varargin{3}) == 3;
        color.start = varargin{1};
        color.middle = varargin{2};
        color.end = varargin{3};
        color.num = NUM_COLORS;
    end
end

%Linear interpolation
if isempty(color.middle)
    for i = 1:3
        cmap(:,i) = interp1([1,color.num],...
            [color.start(i),color.end(i)],...
            [1:color.num]);
    end
else
    for i = 1:3
        cmap(:,i) = interp1([1,color.num/2,color.num],...
            [color.start(i),color.middle(i),color.end(i)],...
            [1:color.num]);
    end
end


end

