function neurofeedback_city_game()
% NEUROFEEDBACK CITY WALKING GAME
% Character walks through a city only when target brainwave frequency is active.
% Default: targets alpha band (8-12 Hz). 
% SIMULATED: Add EEG Info to EEG INPUT SECTION

%% ---- SETTINGS -------------------------------------------------------
TARGET_FREQ_LOW  = 8;    % Hz - lower bound of target band
TARGET_FREQ_HIGH = 12;   % Hz - upper bound (alpha default)
THRESHOLD        = 0.5;  % 0 to 1 - how much of band must be active to walk
SAMPLE_RATE      = 256;  % Hz - your EEG sample rate
WINDOW_SIZE      = 256;  % samples per analysis window (1 second at 256 Hz)
CITY_WIDTH       = 2000; % pixels - total city scroll distance (goal)
%% ---------------------------------------------------------------------

%% --- Figure Setup ---
fig = figure('Name','Neurofeedback City Walk','NumberTitle','off',...
    'Position',[100 100 900 400],'Color',[0.53 0.81 0.98],...
    'KeyPressFcn',@keyPress,'CloseRequestFcn',@closeFig);

ax = axes('Parent',fig,'Position',[0 0 1 1],'XLim',[0 900],...
    'YLim',[0 400],'Visible','off');
axis off; hold on;

%% --- Draw Static Sky ---
fill([0 900 900 0],[0 0 400 400],[0.53 0.81 0.98],'EdgeColor','none');

%% --- State Variables ---
state.running     = true;
state.camOffset   = 0;      % how far camera has scrolled
state.charX       = 150;    % character screen X (fixed)
state.charY       = 110;    % character ground Y
state.frame       = 1;      % walk animation frame
state.walking     = false;
state.score       = 0;      % distance walked
state.simPhase    = 0;      % for simulated EEG
state.eegBuffer   = zeros(1, WINDOW_SIZE);
state.frameTimer  = 0;

%% --- Build City Scene ---
city = buildCity(CITY_WIDTH);

%% --- Graphics Handles ---
gfx.buildings = drawBuildings(ax, city, 0);
gfx.ground    = fill([0 900 900 0],[0 0 110 110],[0.3 0.25 0.2],'EdgeColor','none');
gfx.road      = fill([0 900 900 0],[0 0 70 70],[0.4 0.4 0.4],'EdgeColor','none');
gfx.roadLine  = plot([0 900],[35 35],'--','Color',[1 1 0.6],'LineWidth',1.5);
gfx.clouds    = drawClouds(ax);
gfx.char      = drawCharacter(ax, state.charX, state.charY, 1);
gfx.powerBar  = drawPowerBar(ax, 0);
gfx.scoreTxt  = text(450, 380, 'Distance: 0 / 2000 m',...
    'Color','w','FontSize',13,'FontWeight','bold',...
    'HorizontalAlignment','center','Parent',ax);
gfx.statusTxt = text(450, 355, 'RELAX & FOCUS',...
    'Color',[1 1 0.3],'FontSize',11,'FontWeight','bold',...
    'HorizontalAlignment','center','Parent',ax);
gfx.freqTxt   = text(10, 390, sprintf('Target: %d-%d Hz',TARGET_FREQ_LOW,TARGET_FREQ_HIGH),...
    'Color','w','FontSize',9,'Parent',ax);

%% --- Main Loop ---
dt = 0.05; % seconds per frame (~20 fps)
while state.running && ishandle(fig) && state.camOffset < CITY_WIDTH

    tic;

    %% ==== EEG INPUT SECTION ====
    % SIMULATED: Replace this block with real EEG acquisition
    % For real EEG, acquire WINDOW_SIZE samples from your device here.
    % Example with Psychtoolbox + BrainProducts:
    %   [data, ~] = io64read(eegPort, WINDOW_SIZE);
    %   eegSample = data(CHANNEL, :);
    state.simPhase = state.simPhase + dt;
    % Simulate alpha bursting on a ~6-second cycle
    alphaActive = 0.5 + 0.5*sin(state.simPhase * 0.9);
    noise       = 0.15 * randn(1, WINDOW_SIZE);
    t_vec       = (0:WINDOW_SIZE-1)/SAMPLE_RATE;
    alphaWave   = alphaActive * sin(2*pi*10*t_vec); % 10 Hz alpha
    eegSample   = alphaWave + noise;
    %% ==== END EEG INPUT SECTION ====

    %% --- Compute Band Power ---
    power = bandpower(eegSample, SAMPLE_RATE, [TARGET_FREQ_LOW TARGET_FREQ_HIGH]);
    totalP = bandpower(eegSample, SAMPLE_RATE, [1 40]);
    if totalP > 0
        ratio = min(power / totalP / 0.5, 1); % normalize to 0-1
    else
        ratio = 0;
    end

    state.walking = ratio >= THRESHOLD;

    %% --- Update Position ---
    if state.walking
        speed = 3 + 4 * ratio; % faster with stronger signal
        state.camOffset = state.camOffset + speed;
        state.score = round(state.camOffset);
        state.frameTimer = state.frameTimer + speed;
        if state.frameTimer > 18
            state.frame = mod(state.frame, 4) + 1;
            state.frameTimer = 0;
        end
    end

    %% --- Update Graphics ---
    % Scroll buildings
    updateBuildings(gfx.buildings, city, state.camOffset);

    % Scroll road line
    lineOffset = mod(state.camOffset, 120);
    xs = -lineOffset : 120 : 900;
    set(gfx.roadLine, 'XData', repmat(xs,2,1), ...
        'YData', repmat([28;42], 1, length(xs)));

    % Scroll clouds (parallax)
    for c = 1:length(gfx.clouds)
        cx = get(gfx.clouds(c),'XData');
        cx = cx - 0.3 * state.walking;
        if max(cx) < 0; cx = cx + 1000; end
        set(gfx.clouds(c),'XData',cx);
    end

    % Redraw character
    delete(gfx.char);
    gfx.char = drawCharacter(ax, state.charX, state.charY, state.frame);

    % Power bar
    updatePowerBar(gfx.powerBar, ratio);

    % Text
    set(gfx.scoreTxt,'String', sprintf('Distance: %d / %d m', state.score, CITY_WIDTH));
    if state.walking
        set(gfx.statusTxt,'String','WALKING  >>','Color',[0.3 1 0.3]);
    else
        set(gfx.statusTxt,'String','WAITING...','Color',[1 1 0.3]);
    end

    drawnow limitrate;

    elapsed = toc;
    pauseTime = max(0, dt - elapsed);
    pause(pauseTime);
end

%% --- End Screen ---
if ishandle(ax)
    text(450, 200, 'YOU MADE IT! Great Session!',...
        'Color','w','FontSize',22,'FontWeight','bold',...
        'HorizontalAlignment','center','Parent',ax);
    drawnow;
end

%% ======================== NESTED FUNCTIONS ========================

    function keyPress(~,evt)
        if strcmp(evt.Key,'escape')
            state.running = false;
        end
    end

    function closeFig(~,~)
        state.running = false;
        delete(fig);
    end

end % end main function

%% ======================== HELPER FUNCTIONS ========================

function city = buildCity(totalWidth)
% Generate random city building data
rng(42);
city = struct();
n = ceil(totalWidth / 40) + 30;
city.x      = cumsum(20 + rand(1,n)*40);
city.w      = 30 + rand(1,n)*60;
city.h      = 80 + rand(1,n)*160;
city.color  = 0.25 + rand(n,3)*0.3;
city.winRows = randi([2 5], 1, n);
city.winCols = randi([1 4], 1, n);
end

function handles = drawBuildings(ax, city, camOffset)
handles = gobjects(length(city.x), 1);
for i = 1:length(city.x)
    sx = city.x(i) - camOffset;
    if sx > -city.w(i) && sx < 1000
        handles(i) = fill([sx sx+city.w(i) sx+city.w(i) sx],...
            [110 110 110+city.h(i) 110+city.h(i)],...
            city.color(i,:),'EdgeColor',[0.1 0.1 0.1],'Parent',ax);
    else
        handles(i) = patch('XData',[],'YData',[],'Parent',ax,'Visible','off');
    end
end
end

function updateBuildings(handles, city, camOffset)
for i = 1:length(city.x)
    sx = city.x(i) - camOffset;
    if sx > -city.w(i)-10 && sx < 950
        set(handles(i),'XData',[sx sx+city.w(i) sx+city.w(i) sx],...
            'YData',[110 110 110+city.h(i) 110+city.h(i)],'Visible','on');
    else
        set(handles(i),'Visible','off');
    end
end
end

function h = drawClouds(ax)
% Simple ellipse clouds
positions = [100 300 200 500 700 800; 340 360 320 350 370 330];
h = gobjects(size(positions,2),1);
for i = 1:size(positions,2)
    cx = positions(1,i); cy = positions(2,i);
    th = linspace(0,2*pi,40);
    xc = cx + 50*cos(th);
    yc = cy + 20*sin(th);
    h(i) = fill(xc,yc,[1 1 1],'EdgeColor','none','FaceAlpha',0.85,'Parent',ax);
end
end

function h = drawCharacter(ax, x, y, frame)
% Simple stick figure with walk animation
legAngle = [20 -20 10 -10];
armAngle = [-20 20 -10 10];
la = legAngle(frame); ra = -la;
aa = armAngle(frame);

h = gobjects(7,1);
% Body
h(1) = plot(ax,[x x],[y+30 y+60],'k-','LineWidth',3);
% Head
th = linspace(0,2*pi,30);
h(2) = fill(x+10*cos(th), y+70+8*sin(th),[1 0.85 0.7],'EdgeColor','k','LineWidth',1.5,'Parent',ax);
% Left leg
lx = x + 20*sind(la); ly = y + 20*cosd(la);
h(3) = plot(ax,[x lx],[y+30 ly],'k-','LineWidth',2.5);
% Right leg
rx = x + 20*sind(ra); ry = y + 20*cosd(ra);
h(4) = plot(ax,[x rx],[y+30 ry],'k-','LineWidth',2.5);
% Left arm
ax2 = x + 25*sind(aa); ay2 = y+55 + 20*cosd(aa);
h(5) = plot(ax,[x ax2],[y+55 ay2],'k-','LineWidth',2);
% Right arm
ax3 = x + 25*sind(-aa); ay3 = y+55 + 20*cosd(-aa);
h(6) = plot(ax,[x ax3],[y+55 ay3],'k-','LineWidth',2);
% Shirt color
h(7) = plot(ax,[x x],[y+38 y+58],'b-','LineWidth',4);
end

function h = drawPowerBar(ax, ratio)
% Background bar
fill([10 160 160 10],[10 10 30 30],[0.2 0.2 0.2],'EdgeColor','w','Parent',ax);
text(85,38,'Brain Power','Color','w','FontSize',8,...
    'HorizontalAlignment','center','Parent',ax);
w = max(1, ratio*150);
c = [ratio 1-ratio 0]; % red->green
h = fill([10 10+w 10+w 10],[10 10 30 30],c,'EdgeColor','none','Parent',ax);
end

function updatePowerBar(h, ratio)
w = max(1, ratio*150);
c = [ratio 1-ratio 0];
set(h,'XData',[10 10+w 10+w 10],'FaceColor',c);
end
