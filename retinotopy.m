sca; clear all; close all;

try
    %% PARAMETERS ------------------------------------------------------------------
    calibration         = 0;          % if true run the calibration routine, else use predifined values
    preview             = 0;          % if preview is true, show all stimuli simultaneously don't do the experiment with repetitions
    find_layer          = 0;          % if find_layer is true, show moving dots before the experiment to get the right position in z 
    place_fish          = 0;          % show cross to put the chamber in position
    microscope          = '2P';       % '2P' or 'SPIM' : different optical corrections 
    
    repetitions         = 5;          % repetition of each stimulus
    timeBetweenStimuli  = 30;         % seconds
    dotColor            = 255;        % 0: black; 255: white
    bckgColor           = 0;          % 0: black; 255: white
    stimDuration        = 1;          % seconds
    dotSizeDeg          = [4];        % degrees of the larva's visual field (diameter of the dot)
    dotAzimuthDeg       = -45:5:45;   % degrees of the larva's visual field
    dotElevationDeg     = [0];  % degrees of the larva's visual field - is up + is down
    
    pauseBeforeSync     = 0;       % wait for the fish to settle 
    pauseBefore         = 900;        % time to wait before the first stimulation in seconds: spont before
    pauseAfter          = 900;        % time to wait after the last stimulation in seconds: spont after
    randomTimeShift     = 10;         % random +/-x seconds on timeBetweenStimuli
    if (~preview) 
        [filename pathname] = uiputfile('*.mat','Save stim file'); 
    end

    %% PREPARING PROJECTOR ---------------------------------------------------------
    projector = max(Screen('Screens'));
    monitor = 0;
    [win,dstRect] = Screen('OpenWindow',projector,bckgColor,[],[],2);
    %[win,dstRect] = Screen('OpenWindow',projector,bckgColor,[0 0 1280 720]);
    [projWidth,projHeight] = Screen('WindowSize', win);
    win2 = Screen('OpenWindow',monitor,bckgColor,[0 0 projWidth projHeight]);
    ifi = Screen('GetFlipInterval', win);
    vbl = Screen('Flip', win);

    %% PREPARE STIMULI -------------------------------------------------------------
    dotAzimuthRad = deg2rad(dotAzimuthDeg);
    dotElevationRad = deg2rad(dotElevationDeg);
    dotSizeRad = deg2rad(dotSizeDeg);
    [Sz,Az,El] = meshgrid(dotSizeRad,dotAzimuthRad,dotElevationRad);
    [SzDeg,AzDeg,ElDeg] = meshgrid(dotSizeDeg,dotAzimuthDeg,dotElevationDeg);
    nPos = length(dotSizeDeg)*length(dotAzimuthDeg)*length(dotElevationDeg);
    randomOrder = randsample(repmat(1:nPos,1,repetitions),repetitions*nPos);
    nStim = length(randomOrder);
    degreeSymbol = char(176);
    estTotalTime = nStim*(timeBetweenStimuli+stimDuration)+pauseBefore+pauseAfter;
    disp(['Est. total time:' num2str(estTotalTime) ' s']);
    timeStim = []; % store stim timing;
    [Xq,Yq] = meshgrid(1:projWidth,1:projHeight);

    %% Calibration
    switch(microscope)
        case '2P'
            if (calibration)
                disp('Calibration')
                [x_zero, y_zero, y_fish, d, cx, cy] = calibrate_2P();
                r = 25;
                disp('Done')
            else % use predifined values
                % calibration values: ensure these are correct
                d        = 280;   % distance between proj and chamber in mm
                r        = 25;    % radius of chamber in mm
                cx       = 21.43; % px/mm x
                cy       = 24; % px/mm y
                x_zero   = 640;   % zero x axis in px
                y_zero   = 771;   % zero y axis in px
                y_fish   = 398;   % fish y axis position in px
            end

            geomProj = cylinderProjection(d,r,cx,cy,x_zero,y_zero,y_fish);
            theta = geomProj.get_theta(Xq);
            phi = geomProj.get_phi(Yq,Xq);
    
            % function to synchronize stimulation and calcium imaging
            ardu = arduino('COM5');
            pin_trigger = 'D7';
            sync_on = @() ardu.writeDigitalPin(pin_trigger,1);
            sync_off = @() ardu.writeDigitalPin(pin_trigger,0);  
            sync_release = @() evalin('base','clear ardu'); 

        case 'SPIM'
            % calibration values: ensure these are correct
            if (calibration)
                disp('Calibration')
                [dw, cx, cy, x_zero, y_zero] = calibrate_SPIM();
                disp('Done')
            else % use predifined values
                dw = 30;
                cx = 20;
                cy = 20;
                x_zero = 300;
                y_zero = 400;
            end
            
            geomProj = flatProjection(dw,cx,cy,x_zero,y_zero);
            theta = geomProj.get_theta(Xq);
            phi = geomProj.get_phi(Yq);
    
            % function to synchronize stimulation and calcium imaging
            % National Instruments card
            dq = daq("ni");
            dq.Rate = 20000;
            addinput(dq, "Dev1", "ai0", "Voltage");
            t = addtrigger(d,"Digital","StartTrigger","External","Dev1/PFI13");
            sync_on = @() read(dq);
            sync_off = @() ;
            sync_release = @() evalin('base','clear dq'); 

        otherwise
            error('Correct values are SPIM or 2P')
    end
    
    % functions to convert from (theta,phi) in fish visual space to 
    % (x,y) in projector space 
   
    theta_range = geomProj.theta_range;
    phi_range = geomProj.phi_range;
    if min(dotAzimuthRad) < theta_range(1) | max(dotAzimuthRad) > theta_range(2) 
        error('Azimuth values out of range, aborting')
    end
    if min(dotElevationRad) < phi_range(1) | max(dotElevationRad) > phi_range(2) 
        error('Elevation values out of range, aborting')
    end
            

    %% Place fish
    if (place_fish)
        disp('Place the fish, press key when done')
        ind_cross = find(abs(theta(:)) <= 0.001 | abs(phi(:)) <= 0.001); 
        Cross = zeros(projHeight,projWidth);
        Cross(ind_cross) = dotColor;
        textureCross = Screen('MakeTexture',win,Cross);
        Screen('DrawTexture', win, textureCross);
        Screen('Flip', win);
        KbStrokeWait;
    end
    
    %% Create textures
    disp('Creating textures')
    Reticle = zeros(projHeight,projWidth);
    for i=1:nPos
        ind_line = [];
        if (Az(i)~=0 & El(i)~=0)
            ind_line = find(abs(theta(:) - Az(i)) <= 0.001 | abs(phi(:) - El(i)) <= 0.001); 
        end
        ind_circle = find(abs((theta(:) - Az(i)).^2 + (phi(:) - El(i)).^2 - (Sz(i)/2).^2) <=0.0001); 
        Reticle([ind_line;ind_circle]) = dotColor;
    end
    ind_cross = find(abs(theta(:)) <= 0.001 | abs(phi(:)) <= 0.001); 
    Cross = zeros(projHeight,projWidth);
    Cross = Reticle;
    Cross(ind_cross) = dotColor;
    textureReticle = Screen('MakeTexture',win2,cat(3,Cross,Reticle,Reticle));

    texture = [];
    texture2 = [];
    for i=1:nPos
        im = zeros(projHeight,projWidth);
        ind_dot = find((theta(:) - Az(i)).^2 + (phi(:) - El(i)).^2 <= (Sz(i)/2).^2); 
        im(ind_dot) = dotColor;
        texture(i) = Screen('MakeTexture',win,im);
        texture2(i) = Screen('MakeTexture',win,cat(3,im + Cross,im + Reticle,im +Reticle));
    end

    %% Find layer tectum
    if (find_layer)
        disp('Find visual layer in the tectum, preparing textures...')
        n_images = round(1/ifi * diff(theta_range)/deg2rad(45)); % 45 deg/s
        azimuth = linspace(theta_range(1),theta_range(2),n_images);
        moving_texture = [];
        moving_texture2 = [];
           for i=1:length(azimuth)   
            im = zeros(projHeight,projWidth);
            ind_dot = find((theta(:) - azimuth(i)).^2 + (phi(:)).^2 <= (deg2rad(4)/2).^2); % 4deg dots
            im(ind_dot) = dotColor;
            moving_texture(i) = Screen('MakeTexture',win,im);
            moving_texture2(i) = Screen('MakeTexture',win2,cat(3,im + Cross,im + Reticle,im +Reticle));
        end

        disp('Press space to show moving dot, press escape to finish');
        disp('Hold mouse click to show dot at the selected location');
        escapeKey = KbName('esc');
        spaceKey = KbName('space');
        cont = 1;
        while(cont)
            [mx, my, buttons] = GetMouse(win2);
            if sum(buttons)>0 % mouse clicked
                % get closest point
                t = geomProj.get_theta(mx);
                p = geomProj.get_phi(my,mx   );
                [~,ind] = min(pdist2([Az(:) El(:)],[t p]));
                Screen('DrawTexture', win, texture(ind));
                Screen('DrawTexture', win2, texture2(ind));
                Screen('Flip', win);
                Screen('Flip', win2);
            end

            [keyIsDown,secs, keyCode] = KbCheck;
            if keyCode(escapeKey)
                cont = 0;
                break;
            elseif keyCode(spaceKey)
                tic
                for i=1:n_images
                    Screen('DrawTexture', win, moving_texture(i));
                    Screen('DrawTexture', win2, moving_texture2(i));
                    Screen('Flip', win);
                    Screen('Flip', win2);
                end
                toc
                Screen('FillRect', win, bckgColor);
                vbl = Screen('Flip', win);
                Screen('DrawTexture', win2, textureReticle);
                vbl = Screen('Flip', win2);
            end

            if sum(buttons)<=0 % mouse released
                Screen('FillRect', win, bckgColor);
                vbl = Screen('Flip', win);
                Screen('DrawTexture', win2, textureReticle);
                vbl = Screen('Flip', win2);
            end
        end
    end

    %% Do the experiment
    if (~preview) % do the experiment

        disp('Press any key to sync...');
        pause
        WaitSecs(pauseBeforeSync);
        
        %% SYNC SIGNAL -----------------------------------------------------------------
        sync_on();
        tic;
        disp('Sync')

        %% STIMULATION -----------------------------------------------------------------
        t0 = Screen('Flip', win);
        WaitSecs(pauseBefore);
        for j=1:nStim
            index = randomOrder(j);
            Screen('DrawTexture', win, texture(index));
            vbl = Screen('Flip', win);
            timeStim = [timeStim toc];
            Screen('DrawTexture', win2, texture2(index));
            vbl = Screen('Flip', win2);
            WaitSecs(stimDuration);
            Screen('FillRect', win, bckgColor);
            vbl = Screen('Flip', win);
            Screen('DrawTexture', win2, textureReticle  );
            vbl = Screen('Flip', win2);

            disp(['Looming stimulus ' num2str(j) '/' num2str(nStim)...
            ' , Azimuth : ' num2str(AzDeg(index)) degreeSymbol ...
            ' , Elevation : ' num2str(ElDeg(index)) degreeSymbol ...
            ' , Size : ' num2str(SzDeg(index)) degreeSymbol]);
            shift = 2*randomTimeShift*rand()-randomTimeShift;
            WaitSecs(timeBetweenStimuli + shift);
        end
        WaitSecs(pauseAfter);

        %% CLEAN AND SAVE --------------------------------------------------------------
        sync_off();
        toc
        sync_release();

        Screen('CloseAll');
        save([pathname filename],... 
             'microscope',...                                
             'repetitions',...
             'timeBetweenStimuli',...
             'dotColor',...
             'bckgColor',...
             'stimDuration',...
             'dotSizeDeg',...
             'dotAzimuthDeg',...
             'dotElevationDeg',...
             'pauseBefore',...
             'pauseAfter',...
             'timeStim',...
             'randomOrder',...
             'AzDeg',...
             'ElDeg',...
             'SzDeg',...
             'nStim');
    end

    %% Preview the experiment
    if (preview)  % preview : show all stimuli at the same time, don't do the experiment
        warning('Preview mode, the full experiment will not be performed')

        disp('Preparing textures...')
        im_stacked = zeros(projHeight,projWidth);
        for i=1:nPos
            im = zeros(projHeight,projWidth);
            ind_dot = find((theta(:) - Az(i)).^2 + (phi(:) - El(i)).^2 <= (Sz(i)/2).^2); 
            im(ind_dot) = dotColor;
            im_stacked = im_stacked + im;
        end
        texture = Screen('MakeTexture',win,im_stacked);
        disp('...textures ready');
        Screen('DrawTexture', win, texture);
        Screen('Flip',win);
        disp('Press key when done...')
        KbStrokeWait;
        Screen('CloseAll');
    end
    
catch
    sca;
end
