function [x_zero, y_zero, y_fish, d, cx, cy] = calibrate_2P()

    screenid = max(Screen('Screens'));
    [win,dstRect] = Screen('OpenWindow', screenid, 0);
    %[win,dstRect] = Screen('OpenWindow',0,0,[0 0 1280 720]); % for testing 
    [projWidth,projHeight] = Screen('WindowSize', win);
    [Xq,Yq] = meshgrid(1:projWidth,1:projHeight);
    
    escapeKey = KbName('esc');
    spaceKey = KbName('space');
    plusKey = KbName('+');
    minusKey = KbName('-');
    upArrowKey = KbName('up');
    downArrowKey = KbName('down');
    leftArrowKey = KbName('left');
    rightArrowKey = KbName('right');
    enterKey = KbName('return');
    wKey = KbName('w');
    aKey = KbName('a');
    sKey = KbName('s');
    dKey = KbName('d');
    
    %% step 0: initial guess ----------------------------------------------
    r        = 25;    % radius of chamber in mm 
    d        = 280;   % distance between proj and chamber in mm
    cx       = 21.43; % px/mm x
    cy       = 24; % px/mm y
    x_zero   = 640;   % zero x axis in px
    y_zero   = 771;   % zero y axis in px
    y_fish   = 398;   % fish y axis position in px
       
    %% step 1: get the position of horizontal and vertical lines ----------
    disp(' ')
    disp(['Step 1: -----------------------------------------------------'])
    disp(['Press arrows to change the position of the zero lines'])
    disp(['Press +/- to change position of the fish line'])
    disp(['Press space to continue'])
    disp(['Press escape to quit'])
    
    keepgoing = 1;
    while(keepgoing)
        [~,~,keyCode] = KbCheck;
        if keyCode(escapeKey)
            keepgoing = 0;
            Screen('Close',win);
            return;
        elseif keyCode(spaceKey)
            keepgoing = 0;
        elseif keyCode(plusKey)
            y_fish = y_fish + 1; 
        elseif keyCode(minusKey)
            y_fish = y_fish - 1;
        elseif keyCode(upArrowKey)
            y_zero = y_zero + 1;
        elseif keyCode(downArrowKey)
            y_zero = y_zero - 1;
        elseif keyCode(leftArrowKey)
            x_zero = x_zero - 1;
        elseif keyCode(rightArrowKey)
            x_zero = x_zero + 1;
        end
        
        xy = [1 projWidth 1 projWidth x_zero x_zero;
            y_zero y_zero y_fish y_fish 1 projHeight];
        Screen('DrawLines', win, xy, 2);
        Screen('Flip',win);
    end
    KbReleaseWait;
    
    %% step 2 : project a 1cm grid on the screen and adjust the distance --
    %% between proj and screen
    
    disp(' ')
    disp(['Step 2: -----------------------------------------------------'])
    disp(['Press + or - to change proj distance'])
    disp(['Press up/down arrows to change cy'])
    disp(['Press left/right arrows to change cx'])
    disp(['Press w/a/s/d to shift the grid'])
    disp(['Press space to continue'])
    disp(['Press escape to quit'])
    
    stepd = 10;
    stepc = 0.1;
    stepg = 0.01;
    gx = 0;
    gy = 0;
    keepgoing = 1;
    while(keepgoing)
        [~,~,keyCode] = KbCheck;
        if keyCode(escapeKey)
            keepgoing = 0;
            Screen('Close',win);
            return;
        elseif keyCode(spaceKey)
            Screen('Close',win);
            keepgoing = 0;
            break;
        elseif keyCode(plusKey)
            d = d + stepd;
        elseif keyCode(minusKey)
            if (d - stepd)>0
                d = d - stepd;
            end
        elseif keyCode(upArrowKey)
            cy = cy + stepc;
        elseif keyCode(downArrowKey)
            cy = cy - stepc;
        elseif keyCode(leftArrowKey)
            cx = cx - stepc;
        elseif keyCode(rightArrowKey)
            cx = cx + stepc;
        elseif keyCode(wKey)
            gy = gy + stepg;
        elseif keyCode(sKey)
            gy = gy - stepg;
        elseif keyCode(aKey)
            gx = gx - stepg;
        elseif keyCode(dKey)
            gx = gx + stepg;
        end
        
        cp = cylinderProjection(d,r,cx,cy,x_zero,y_zero,y_fish);
        theta = cp.get_theta(Xq);
        phi = cp.get_phi(Yq,Xq);
        
        im_grid = zeros(projHeight,projWidth);
        ind = find(abs(mod(theta+gx,10/r)) < 0.01 | abs(mod(tan(phi)+gy,10/r)) < 0.01);
        im_grid(ind) = 255;
        
        texture = Screen('MakeTexture',win,im_grid);
        Screen('DrawTexture', win, texture);
        Screen('Flip', win);
    end
    KbReleaseWait;
    
end
