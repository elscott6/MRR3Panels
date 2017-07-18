function MRR_Add_Storms_nohtml_redo4movies( MRR_struct, date_range, radar_time, settings, a, timeslist )
%MRR_ADD_STORMS Add recognized storms from MRR to webpage.
%   
%   SUMMARY: This function takes in the date_range returned from running
%   the MRR_Storm_Detection function on the MRR_struct. Generates a picture
%   for the website and inserts the storm into the table on the webpage,
%   with the link pointing to a page that displays the image. This function
%   can be built upon over time.
%
%   FUNCTIONS:
%       LCH_Spiral.m
%       makeColorMap.m
%       
%
%   INPUTS:
%       MRR_struct: The MRR structure obtained from running one of the
%                   simp2matrix functions on MRR simp data.
%       date_range: Includes serial dates of the beginning and end of
%                   storms, as well as the row locations in the MRR_struct
%                   of the beginning and end of storms.
%       radar_time: Time at which a line should be drawn to show progress
%                   of radar display. 
%       settings: * If processing for Alta with combined MRRs, make sure
%                     that MRR2 field still exists in settings.
%
%                   List of settable fields and what they do (* are
%                   required fields, - are optional)
%                   - ext = The file extension of the MRR image files. This
%                     may be set to any of Matlab's acceptable file types.
%                     The most common file types are 'png' and 'eps'. Eps
%                     file type is generally for high quality images. When
%                     setting this, make sure to not include a period in
%                     your extension, like so (e.g. settings.ext = 'png';).
%
%                   * is_alta = The perusal pages made for Alta, UT have
%                     some special conditions that must be taken into
%                     account. When processing perusal pages for Alta, this
%                     MUST be set, otherwise the perusal pages will not
%                     come out correctly.
%       a:          Number of the iteration
%       timeslist:  List of all times for which an image will be created
%
%   OUTPUTS:
%       None
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This code is part of a suite of software developed under the guidance of
% Dr. Sandra Yuter and the Cloud Precipitation Processes and Patterns Group
% at North Carolina State University. It has been modified from original
% code by Spencer Rhodes.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Initialize constants:
TITLE_FONT = {'FontSize' 18};
AXES_FONT = {'FontSize' 14};
MAX_COLORS = 64;

%%% SET THE VALUES FOR STORMDATA %%%
%This step initializes several time variables for the plots
stormData = struct([]);
stormData(1).year = datestr(date_range.start, 'yyyy');
stormData(1).month = datestr(date_range.start, 'mm');
stormData(1).day = datestr(date_range.start, 'dd');
stormData(1).start = datestr(date_range.start, 'HH:MM');
difvector = datevec(date_range.end - date_range.start);
stormData(1).duration = round(10 * (24 * difvector(3) + difvector(4) + difvector(5) / 60)) / 10;
%Set the graphics string, used to call individual parts of the image and
%save the plot 
stormData(1).graphstr = datestr(date_range.start, 'yyyymmdd_HHMM');

% If extension was specified in settings (using field 'ext') then extension
% variable will be set. Otherwise, default to PNG file type.
if isfield(settings, 'ext'), ext = settings.ext;
else ext = 'png'; end

% Set the range of values to use for reflectivity and
% doppler velocity in the images (colors).
dbz_range = [-6 35];
vel_range = [-4 6];

% Generate colormaps.
%Create reflectivity and spectral width colormap
def_cmap = LCH_Spiral(MAX_COLORS,1,180,1);
def_cmap(1,:) = [0.6 0.6 0.6];
%Create velocity color map
if vel_range(1) < 0
    cmap1 = makeColorMap([0 1 0],[.95 .95 .95],[1 0 0],(vel_range(2) * 4 + 2));
    cmap2 = makeColorMap([0 1 0],[.95 .95 .95],[1 0 0],(abs(vel_range(1)) * 4 + 2));
    vel_cmap = [[0.6 0.6 0.6];[0.6 0.6 0.6];[0 0 0.8];[0 0 0.8];...
        cmap2(1:(length(cmap2)/2),:);...
        cmap1((length(cmap1)/2+1):end,:)];
else
    vel_cmap = def_cmap;
end
clear cmap1 cmap2

% Get the heights of the images. Depends on if spectral width field exists
% in the MRR_struct.
if isfield(MRR_struct, 'SW')
    im_heights = 2.6666;
    sw_im_height = 2.6667;
else
    im_heights = 3.7500;
end

num_gates = numel(MRR_struct.Z) / length(MRR_struct.Z);

fprintf('Generating graph %d of %d from MRR data...',a,length(timeslist))
for stormID = 1:length(date_range)
    % Initialize a value dateincr for setting the time increment on the
    % x-axis of the graphs.
    if stormData(stormID).duration <= 2
        dateincr = (1/24) * (1/60) * 15; % 15 minutes
    elseif stormData(stormID).duration <= 6
        dateincr = (1/24) * (1/60) * 30; % 30 minutes
    elseif stormData(stormID).duration <= 12
        dateincr = (1/24); % 1 hour
    elseif stormData(stormID).duration <= 36
        dateincr = (1/24) * 2; % 2 hours
    elseif stormData(stormID).duration <= 72
        dateincr = (1/24) * 3; % 3 hours
    elseif stormData(stormID).duration <= 90
        dateincr = (1/24) * 4; % 4 hours
    else
        dateincr = (1/24) * 6; % 6 hours
    end 
    
    %%%%%%%%%%%%%%%%%%% MAKE PLOT FOR DOPPLER VELOCITY %%%%%%%%%%%%%%%%%%%
    if isfield(date_range,'row_start')
        rows = date_range(stormID).row_start : date_range(stormID).row_end;
    else
        rows = find(MRR_struct.dates == date_range(stormID).start, 1, 'first') : ...
               find(MRR_struct.dates == date_range(stormID).end, 1, 'first');
    end
    
    % Initialize an array of Doppler Velocity values for the date range.
    array_of_w = MRR_struct.W(rows, :)';
    array_of_w(array_of_w < vel_range(1)) = vel_range(1) - 1;
    array_of_w(isnan(array_of_w)) = vel_range(1) - 2;
    
    % Put Doppler Velocity plot into the subplot
    figure(stormID), set(gcf, 'visible', 'off')    %create figure, keep it from popping up on the screen   
    set(gcf, 'Renderer', 'painters')                %set Renderer
    yyaxis left                                     %set image to left axis
    imagesc(MRR_struct.dates(rows), 1:1:num_gates, array_of_w);
    axis xy;                                        %values increase from bottom to top
    if dateincr < (1/24)
        datetick('x','HH:MM','keeplimits')          %set x-axis dateticks (DO NOT use 'keepticks')
    else
        datetick('x','HH','keeplimits')
    end
    % Set the ticks on the Y axis
    i = 1;
    counter = 1;
    while i < num_gates - 1
        ytick(counter) = i;
        if isfield(settings, 'MRR2')
            i = i + 12;
            if i > 30
                i = i + 6;
            end
        elseif isfield(settings, 'is_alta')
            i = i + 3;
        else
            i = i + 4;
        end
        counter = counter + 1;
    end
    set(gca, 'YTick', ytick)
    
    % Set the labels of the ticks on the Y axis
    for i = 1:length(ytick)
        % Account for the labels if combined MRRs are being used.
        if isfield(settings, 'MRR2')
            y_label(i) = MRR_struct.header.height + ytick(i) * 25;      
        else
            %set y-labels to represent height by multiplying gate number by
            %gate spacing
            y_label(i) = MRR_struct.header.height + ytick(i) * MRR_struct.header.gatedist;
        end
        
    end
    set(gca, 'YTickLabel', y_label)
    
    % Set the title of the x and y axis, along with the fonts
    xlabel('Time (hour)', AXES_FONT{:})
    ylabel('Height (m)', AXES_FONT{:})
    set(gca, AXES_FONT{:})
    
    % Set title of graph
    title('Doppler Velocity', TITLE_FONT{:})
    
    % Set the ticks on the x and y axis to point outwards
    set(gca, 'TickDir', 'out')
    
    % Set the correct color map
    colormap(vel_cmap)
    ch = colorbar();
    caxis([(vel_range(1) - 2) vel_range(2)])
    set(get(ch, 'ylabel'), 'String', 'm/s', AXES_FONT{:})
    set(gca,'YColor','k')
    
    % Set box off to lose the tick marks on the top and right axis.
    box off
    
    hold on
    yyaxis right                                    %Use right axis to draw MRR line graph.  Any axis properties set after this point only apply to the right axis. 
    %Plot the number of camera triggers in five-minute intervals
    line(MRR_struct.dates(rows),MRR_struct.count(rows),'Color','none','LineWidth',0.5)
    ylim([0 200])
    set(gca,'YColor','none')
    %ylabel('Camera Triggers')
    
    axis xy;
    if dateincr < (1/24)
        datetick('x','HH:MM','keeplimits')
    else
        datetick('x','HH','keeplimits')
    end
    
    % Set the position of the graph to be more wide than tall and center
    % the graph in the figure window
    set(gcf, 'PaperPositionMode', 'manual')
    set(gcf, 'PaperUnits', 'inches')
    set(gcf, 'PaperPosition', [0 0 11 im_heights])
    
    %Save this portion of the image to a separate file
    print(gcf, '-r100', ['-d' ext], [stormData(stormID).graphstr '_doppler.' ext]);  %'-r100' sets 100 pixels per inch.  This can be increased but is not suggested based on the storage limits of the videoWriter function.  
    %clear the figure
    clf(stormID)
    
    %%%%%%%%%%%%%%%%%%%%% MAKE PLOT FOR REFLECTIVITY %%%%%%%%%%%%%%%%%%%%%

    % Pre initialize an array of dBZ values for the date range.
    array_of_z = MRR_struct.Z(rows, :)';
    array_of_z(isnan(array_of_z)) = dbz_range(1) - 1;
    
    % Put Reflectivity plot into the subplot
    figure(stormID+1), set(gcf, 'visible', 'off')           %turn off figure visibility
    set(gcf, 'Renderer', 'painters')
    yyaxis left
    %Plot reflectivity in the left axis
    imagesc(MRR_struct.dates(rows), 1:1:num_gates, array_of_z);
    axis xy;
    if dateincr < (1/24)
        datetick('x','HH:MM','keeplimits')          %set x-axis dateticks (DO NOT use 'keepticks')
    else
        datetick('x','HH','keeplimits')
    end
    
    % Set the ticks on the Y axis
    set(gca, 'YTick', ytick)
    
    % Set the labels of the ticks on the Y axis
    set(gca, 'YTickLabel', y_label)
    
    % Set the title of the x and y axis, along with the fonts
    xlabel('Time (hour)', AXES_FONT{:})
    ylabel('Height (m)', AXES_FONT{:})
    set(gca, AXES_FONT{:})
   
    % Set the title of the graph
    title('Reflectivity', TITLE_FONT{:})
   
    % Set the ticks on the x and y axis to point outwards
    set(gca, 'TickDir', 'out')
    
    % Set box off to lose the tick marks on the top and right axis.
    box off
    set(gca,'YColor','k')
    
     % Set the correct color map
    colormap(def_cmap)
    ch=colorbar('Ticks',[-5,5,15,25,35],'TickLabels',{'-5','5','15','25','35'});   %Specify points at which to label
    caxis([-5 35])                  %Specify color axis limits
    set(get(ch, 'ylabel'), 'String', 'dBZ', AXES_FONT{:})
    
    hold on
    yyaxis right                    %Switch to right axis
    %Plot a line graph of aggregate counts (values change every 5 minutes)
    line(MRR_struct.dates(rows),MRR_struct.aggregates(rows),'Color','none','LineWidth',0.5)
    ylim([0 40])
    %ylabel('Aggregates')
    set(gca,'YColor','none')
    axis xy;
    if dateincr < (1/24)
        datetick('x','HH:MM','keeplimits')
    else
        datetick('x','HH','keeplimits')
    end
    
    %plot a line to show the time of the other radar scan at the top of the
    %reflectivity chart
    hold on
    xcoord=[radar_time radar_time];
    ycoord=[30 40];
    line(xcoord,ycoord,'Color','r','LineWidth',1.5)
    ylim([0 40])
    
    %add textbox with time of KOKX radar scan
    %textdim sets the position of the textbox relative to the figure, where
    %the bottom left corner is 0,0 and the top right corner is 1,1
    textdim= [0.1,0.9,0.2,0.1];
    timeticker=datestr(radar_time,'HH:MM');
    annotation('textbox',textdim,'String',timeticker,'FitBoxToText','on');

    
    % Set the position of the graph to be more wide than tall and center
    % the graph in the figure window
    set(gcf, 'PaperPositionMode', 'manual')
    set(gcf, 'PaperUnits', 'inches')
    set(gcf, 'PaperPosition', [0 0 11 im_heights])
    
   
    print(gcf, '-r100', ['-d' ext], [stormData(stormID).graphstr '_reflec.' ext]);
    clf(stormID+1)
    
    if isfield(MRR_struct, 'SW')
    %%%%%%%%%%%%%%%%%%%% MAKE PLOT FOR SPECTRAL WIDTH %%%%%%%%%%%%%%%%%%%%
    
        % Add a plot for Spectral Width. 
        array_of_sw = MRR_struct.SW(rows, :)';
        array_of_sw(isnan(array_of_sw)) = 0;
        SPECTRAL_RANGE = [0 3.5];
        
        figure(stormID+2), set(gcf, 'visible', 'off')    %turn off plot visibility to keep it from popping up onscreen
        set(gcf, 'Renderer', 'painters')
        yyaxis left
        %Plot spectral width in the left axis
        imagesc(MRR_struct.dates(rows), 1:1:num_gates, array_of_sw);
        axis xy;
        if dateincr < (1/24)
            datetick('x','HH:MM','keeplimits')          %Create x-axis labels (DO NOT turn on 'keepticks')
        else
            datetick('x','HH','keeplimits')
        end

        % Set the ticks on the Y axis
        set(gca, 'YTick', ytick)

        % Set the labels of the ticks on the Y axis
        set(gca, 'YTickLabel', y_label)

        % Set the title of the x and y axis, along with the fonts
        xlabel('Time (hour)', AXES_FONT{:})
        ylabel('Height (m)', AXES_FONT{:})
        set(gca, AXES_FONT{:})
        title('Spectral Width', TITLE_FONT{:})

        % Set the ticks on the x and y axis to point outwards
        set(gca, 'TickDir', 'out')

        % Set the correct color map
        colormap(def_cmap)
        ch = colorbar();
        caxis(SPECTRAL_RANGE)
        set(get(ch, 'ylabel'), 'String', 'm/s', AXES_FONT{:})

        % Set box off to lose the tick marks on the top and right axis.
        box off
        set(gca,'YColor','k')
       
        hold on
        yyaxis right                    
        %Plot graupel in the right axis, where plotted value is the amount
        %of graupel that fell in each five-minute span
        line(MRR_struct.dates(rows),MRR_struct.graupel(rows),'Color','none','LineWidth',0.5)
        ylim([0 25])
        %ylabel('Graupel')
        set(gca,'YColor','none')
        axis xy;
        if dateincr < (1/24)
            datetick('x','HH:MM','keeplimits')
        else
            datetick('x','HH','keeplimits')
        end
       

        % Set the position of the graph to be more wide than tall and center
        % the graph in the figure window
        set(gcf, 'PaperPositionMode', 'manual')
        set(gcf, 'PaperUnits', 'inches')
        set(gcf, 'PaperPosition', [0 0 11 sw_im_height])

        print(gcf, '-r100', ['-d' ext], [stormData(stormID).graphstr '_spectral.' ext]);

        clf(stormID+2)
    end
    
    %%%%%%%%%%%%%%%%% MAKE ANNOTATION FOR FULL GRAPH %%%%%%%%%%%%%%%%%%%%%%
    
    figure(stormID+3), set(gcf, 'visible', 'off')
    set(gcf, 'Renderer', 'painters')
    
    % Make an annotation in the top right for the date of the storm
    ah = annotation('textbox', [.03 .8 .1 .1], 'String', ...
        sprintf('Date start: %s UTC\nDate end:  %s UTC',...
        datestr(date_range(stormID).start, 'dd mmm yyyy HH:MM'), ...
        datestr(date_range(stormID).end, 'dd mmm yyyy HH:MM')));
    set(ah, AXES_FONT{:})
    set(ah, 'FitBoxToText', 'on')
    set(ah, 'LineStyle', 'none')
    
    % Set the position of the annotation to be only 1 inch.
    set(gcf, 'PaperPositionMode', 'manual')
    set(gcf, 'PaperUnits', 'inches')
    set(gcf, 'PaperPosition', [0 0 11 1])
    
    print(gcf, '-r100', ['-d' ext], [stormData(stormID).graphstr '_annota.' ext]);
    
    clf(stormID+3)
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %  Print the imagesc graph to a file
        %first save radar_time as something usable for filenames
    radar_string=datestr(radar_time,'yyyymmddHHMMSS');    %Put radar time into usable format for filename
    datestring=datestr(date_range.start,'yyyymmdd');      %Save a string for the filename based on date
    
    %read in the images for each component
    ann = imread([stormData(stormID).graphstr '_annota.' ext]);
    dbz = imread([stormData(stormID).graphstr '_reflec.' ext]);
    dv = imread([stormData(stormID).graphstr '_doppler.' ext]);
    if isfield(MRR_struct, 'SW')
        sw = imread([stormData(stormID).graphstr '_spectral.' ext]);
        %append images to one variable
        combined = [ann;dbz;sw;dv];
        %Write the combined image to a new file, delete component images
        imwrite(combined, ['storms/movies/35redo/' datestring '/' stormData(stormID).graphstr '.' radar_string '.' ext]);  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%changed
        delete([stormData(stormID).graphstr '_annota.' ext], ...
            [stormData(stormID).graphstr '_reflec.' ext], ...
            [stormData(stormID).graphstr '_doppler.' ext], ...
            [stormData(stormID).graphstr '_spectral.' ext])
    else
        %append images to one variable 
        combined = [ann;dbz;dv];
        %Write the combined image to a new file, delete component images
        imwrite(combined, ['storms/movies/35redo/' datestring '/' stormData(stormID).graphstr '.' radar_string '.' ext]);   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%changed
        delete([stormData(stormID).graphstr '_annota.' ext], ...
            [stormData(stormID).graphstr '_reflec.' ext], ...
            [stormData(stormID).graphstr '_doppler.' ext])
    end
    
    %clear variables, arrays
    clear array_of_z array_of_sw dbz dv sw
    
    clear array_of_w ch x_label y_label xtick ytick
    
    %close figures
    close all
end
fprintf('complete.\n')