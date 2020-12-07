classdef Minesweeper < handle
%--------------------------------------------------------------------------
% Syntax:       Minesweeper();
%               Minesweeper(level);
%               Minesweeper(nRows,nCols,nMines);
%               M = Minesweeper();
%               M = Minesweeper(level);
%               M = Minesweeper(nRows,nCols,nMines);
%               
% Inputs:       [OPTIONAL] level = {'Beginner','Intermediate','Expert'}
%               specifies the desired board level to load. The default
%               value is level = 'Intermediate'
%               
%               [OPTIONAL] (nRows,nCols) is the desired number of rows and
%               columns, respectively, on the board. The default values are
%               (nRows,nCols) = (16,16)
%               
%               [OPTIONAL] nMines is the desired number of mines on the
%               board. The default value is nMines = 40
%               
%               NOTE: The board level can be changed at any time within the
%               GUI via the GAME menu
%               
% Outputs:      M is a Minesweeper object with public methods:
%               
%                       M.Hint();               % Open safe square
%                       M.AutoSolve();          % Auto-solve puzzle
%                       M.EngineMove();         % Ask engine to make a move
%               tbv   = M.Compute3BV();         % Compute 3BV of puzzle
%                       M.LeftClick(row,col);   % Left-click given square
%                       M.RightClick(row,col);  % Right-click given square
%               board = M.GetBoardState();      % Get encoded board state
%                       M.ResetBoard();         % Start a new puzzle
%                       M.Close();              % Close the GUI
%               
% Description:  This class generates a fully-functional Minesweeper GUI
%               with beginner, intermediate, expert, and custom levels,
%               a persistent leaderboard, classical graphics, hints, and
%               an artificial intelligence (AI) auto-solution engine.
%               
% Note:         All of the necessary public properties/methods are exposed
%               for you to write your own external auto-solution engine.
%               See README.txt for more information
%               
% Author:       Brian Moore
%               brimoor@umich.edu
%               
% Date:         June 19, 2014
%--------------------------------------------------------------------------

    %
    % Private constants
    %
    properties (GetAccess = private, Constant = true)
        % Board dimensions and spacings
        SQUARE_WIDTH = 30;              % Square width, in pixels
        BORDER_WIDTH = 6;               % Border width, in pixels
        PANEL_GAP = 8;                  % Gap between panels, in pixels
        
        % Standard levels
        BEGINNER = [9 9 10];            % Beginner level
        INTERMEDIATE = [16 16 40];      % Intermediate level
        EXPERT = [16 30 99];            % Expert level
        
        % Default level
        DEFAULT_LEVEL = 'INTERMEDIATE'; % Default board level
        
        % Button "enums"
        NULL = 0;                       % No square
        SQUARE = 1;                     % Board square
        SMILEY = 2;                     % Smiley square
        
        % Square-click enums
        NULL_CLICK = 0;                 % Null-click
        LEFT_CLICK = 1;                 % Left-click
        RIGHT_CLICK = 2;                % Right-click
        
        % Colors
        LIGHT_GRAY = 0.90196 * [1 1 1]; % Light gray color
        GRAY = 0.74902 * [1 1 1];       % Gray color
        DARK_GRAY = 0.47059 * [1 1 1];  % Dark gray color
        RED = [1 0 0];                  % Red color
        BLACK = [0 0 0];                % Black color
        
        % Numbers
        NUMBERS = {'zero','one', ...    % Field names for graphics access
                   'two','three', ...
                   'four','five', ...
                   'six','seven', ...
                   'eight','nine'};
        
        % Spacings (normalized units)
        DSM = 0.130;                    % Smiley border size
        DSB = 0.150;                    % Bomb border size
        DSF = 0.225;                    % Flag border size
        DSN = 0.255;                    % Number border size
        DSX = 0.060;                    % X-ed bomb border sizes
        DSC = 0.030;                    % Clicked square bezel width
        DSU = 0.100;                    % Unclicked square bezel width
    end
    
    %
    % Public GetAccess properties
    %
    properties (GetAccess = public, SetAccess = private)
        % {'BEGINNER','INTERMEDIATE','EXPERT','CUSTOM'}
        level;                      % Board level string
        
        % Positive integers
        nRows;                      % Number of rows
        nCols;                      % Number of columns
        nSquares;                   % Number of squares
        nMines;                     % Number of mines
        clearedCount;               % Number of cleared squares
        flaggedCount;               % Number of flagged squares
        timeElapsed;                % Seconds elapsed
        
        % Logicals
        usedHint;                   % Hint flag
        isRunning;                  % Timer running status
        isGameOver;                 % Game over state
        isSolved;                   % Puzzle solved state
        
        % Miscellaneous info
        highScores;                 % High score structure
        dir;                        % Base directory path
        version;                    % Version structure
    end
    
    %
    % Private properties
    %
    properties (Access = private)
        % Game state structures
        board;                      % Board state structure
        sqs;                        % Squares structure
        
        % Game state parameters
        activeSq;                   % Active square struct
        timerobj;                   % Game timer object
        isSolving;                  % Auto-solution flag
        mlock;                      % Motion lock
        lastClick;                  % Last click type
        isMouseDown;                % Mouse down flag
        
        % Graphics data
        numbers;                    % Mine count images
        sevenSeg;                   % Seven segment display images
        sprites;                    % Misc. sprites
        patches;                    % Patch X/Y templates
        lims;                       % Image limits
        clicked;                    % Clicked square patch coordinates
        unclicked;                  % Unclicked square patch coordinates
        digits;                     % Seven-segment display parameters
        
        % Axis coordinates
        smileyCoords;               % Smiley button axis coordinates 
        borderCoords;               % Board border axis coordinates
        sqCoords;                   % Square coordinates
        
        % GUI handles
        fig;                        % Figure handle
        ax;                         % Axis handle
        ph;                         % Patch handles
        mineh;                      % Mine seven-segment display handles
        timeh;                      % Time seven-segment display handles
        smileyh;                    % Smiley image handle
        children;                   % Handles to figures spawned by GUI
    end
    
    %
    % Public methods
    %
    methods (Access = public)
        %
        % Constructor
        %
        function this = Minesweeper(varargin)
        % Type "help Minesweeper" for more information
        
            % Save base directory
            this.dir = Minesweeper.GetBaseDir();
            
            % Load graphics/version data
            dcell = load([this.dir '/data.mat']);
            this.numbers = dcell.numbers;
            this.sevenSeg = dcell.sevenSeg;
            this.sprites = dcell.sprites;
            this.patches = dcell.patches;
            this.version = dcell.version;
            
            % Load high score data
            scorepath = [this.dir '/scores.mat'];
            if (exist(scorepath,'file') == 2)
                scell = load(scorepath);
                this.highScores = scell.HIGH_SCORES;
            else
                % Start a new high score list
                this.EmptyHighScores();
            end
            
            % Generate image limits
            lims_fcn = @(ds) this.SQUARE_WIDTH * [ds (1 - ds)];
            this.lims.smiley = lims_fcn(this.DSM); % Smiley
            this.lims.bomb = lims_fcn(this.DSB);   % Bomb
            this.lims.flag = lims_fcn(this.DSF);   % Flag
            this.lims.number = lims_fcn(this.DSN); % Numbers
            this.lims.xbomb = lims_fcn(this.DSX);  % X-ed bomb
            
            % Pregenerate patch data for fast(er...) graphics
            this.clicked.X = this.patches.X(this.SQUARE_WIDTH,this.DSC);
            this.clicked.Y = this.patches.Y(this.SQUARE_WIDTH,this.DSC);
            this.clicked.C = permute([this.DARK_GRAY' ...
                                     this.GRAY' ...
                                     this.DARK_GRAY'],[3 2 1]);
            this.clicked.red = permute([this.DARK_GRAY' ...
                                        this.RED' ...
                                        this.DARK_GRAY'],[3 2 1]);
            this.unclicked.X = this.patches.X(this.SQUARE_WIDTH,this.DSU);
            this.unclicked.Y = this.patches.Y(this.SQUARE_WIDTH,this.DSU);
            this.unclicked.C = permute([this.LIGHT_GRAY' ...
                                        this.GRAY' ...
                                        this.DARK_GRAY'],[3 2 1]);
            
            % Initialize GUI based on user inputs
            if (nargin == 1)
                % Level string given
                this.level = upper(varargin{1});
                params = num2cell(this.(this.level));
                this.InitializeGUI(params{:});
            elseif (nargin == 3)
                % Custom user-specified board
                this.level = 'CUSTOM';
                this.InitializeGUI(varargin{:});
            else
                % Default board level
                this.InitializeGUI();
            end
        end
        
        %
        % Get a hint
        %
        function Hint(this)
        %------------------------------------------------------------------
        % Syntax:       M.Hint();
        %               Hint(M);
        %               
        % Inputs:       M is a Minesweeper object
        %               
        % Description:  This function opens a useful safe square on the
        %               current board
        %               
        % Note:         This function sets the usedHint flag, which
        %               disqualifies the solution time from appearing on
        %               the leaderboard
        %------------------------------------------------------------------
        
            % If the game isn't over
            if (this.isGameOver == false)               
                % Set hint flag
                this.usedHint = true;
                
                % Find a useful safe square
                ssqs = this.sqs(~[this.board.mine] & ~[this.board.open]);
                counts = arrayfun(@(sq)this.CountOpenNeighbors(sq),ssqs);
                idx = find(counts == max(counts));
                idx = idx(randi([1 length(idx)]));
                
                % Open the square
                this.CascadeOpenSquare(ssqs(idx));
            end
        end
        
        %
        % Auto-solve the puzzle
        %
        function AutoSolve(this)
        %------------------------------------------------------------------
        % Syntax:       M.AutoSolve();
        %               AutoSolve(M);
        %               
        % Inputs:       M is a Minesweeper object
        %               
        % Description:  This function repeatedly invokes EngineMove() until
        %               the puzzle is solved or a mine is revealed
        %------------------------------------------------------------------
        
            % If the game isn't over and solution isn't already in progress
            if ((this.isGameOver == false) && (this.isSolving == false))
                % Set solving flag
                this.isSolving = true;
                
                % Update smiley button
                this.UpdateSmiley();
                
                % Loop until solving flag is released
                while (this.isSolving == true)
                    % Have the engine make a move
                    this.EngineMove();
                    
                    % Flush graphics
                    drawnow;
                end
            end
        end
        
        %
        % Have the engine make a move
        %
        function EngineMove(this)
        %------------------------------------------------------------------
        % Syntax:       M.EngineMove();
        %               EngineMove(M);
        %               
        % Inputs:       M is a Minesweeper object
        %               
        % Description:  This function performs one click (opens a square,
        %               flags a square, or cascade-clicks an opened square
        %               with enough flags around it) based on an internal
        %               engine's analysis of the current board state
        %               
        % Note:         This function sets the usedHint flag, which
        %               disqualifies the solution time from appearing on
        %               the leaderboard
        %------------------------------------------------------------------
        
            % If the game isn't over
            if (this.isGameOver == false)              
                % Set hint flag
                this.usedHint = true;
                
                % Compute unknown neighbors
                unkn = arrayfun(@(sq)this.UnknownNeighbors(sq),this.sqs,...
                                                    'UniformOutput',false);
                unkncnt = cellfun(@length,unkn);
                
                % Apply flag information
                b = [this.board.num]' - ...
                    arrayfun(@(sq)this.CountFlaggedNeighbors(sq),this.sqs);
                
                % Get open squares
                osqs = ([this.board.open]' == true);
                
                % Get unknown (closed and unflagged) squares
                usqs = (~osqs & ([this.board.flagged]' == false));
                
                % Check for an obvious move
                obv = find((unkncnt > 0) & (b <= 0) & (osqs == true));
                if ~isempty(obv)
                    % Cascade region around an obvious square
                    idx = obv(randi([1 length(obv)]));
                    this.CascadeRegion(this.sqs(idx));
                    
                    % Quick return
                    return;
                end
                
                % Construct array of informative squares
                idx = find((b > 0) & (osqs == true));
                b = b(idx);
                n = length(idx);
                
                % Construct constraint matrix
                A = zeros(n,this.nSquares);
                for i = 1:n
                    A(i,unkn{idx(i)}) = 1;
                end
                
                % Add total mine constraint for the end game
                minesLeft = this.nMines - this.flaggedCount;
                if (minesLeft <= 8)
                    A = [A;zeros(1,this.nSquares)];
                    A(n + 1,usqs) = 1;
                    b(n + 1,1) = minesLeft;
                end
                
                % Restrict to nontrivial squares
                idx2 = find(sum(A,1) > 0);
                A = A(:,idx2);
                
                % If there's nothing to analyze
                if ((this.flaggedCount >= this.nMines) || isempty(A))                  
                    % Open a random unknown square
                    inds = find(usqs,randi([1 sum(usqs)]),'first');
                    this.CascadeOpenSquare(this.sqs(inds(end)));
                    
                    % Quick return
                    return;
                end
                
                % (Heuristic) AI square danger scores
                x = pinv(A) * b;
                
                % Make the most obvious move
                [ps idxs] = min(x);
                [pd idxd] = max(x);
                if ((1 - pd) <= ps)
                    % Flag the most dangerous square
                    this.FlagSquare(this.sqs(idx2(idxd)));
                else
                    % Open the safest square
                    this.CascadeOpenSquare(this.sqs(idx2(idxs)));
                end
            end
        end
        
        %
        % Compute the 3BV score of the current layout
        %
        function tbv = Compute3BV(this)
        %------------------------------------------------------------------
        % Syntax:       tbv = M.Compute3BV();
        %               tbv = Compute3BV(M);
        %               
        % Inputs:       M is a Minesweeper object
        %               
        % Outputs:      tbv is the 3BV score of the current puzzle
        %               
        % Description:  This function returns the 3BV score of the current
        %               puzzle, defined as the minimum number of left
        %               clicks required to solve the puzzle. 3BV is a
        %               quantitative measure of the difficulty of a puzzle
        %               
        % Note:         3BV cannot be computed until GenerateMines() is
        %               called, which happens *after* the first square is
        %               clicked
        %------------------------------------------------------------------
        
            % Count number of empty regions
            ner = 0;
            sqn = this.sqs(([this.board.num] == 0) & ...
                           ([this.board.mine] == false));
            for idx = 1:length(sqn)
                % Get square
                sq = sqn(idx);
                
                % If square is unqueued
                if (this.board(sq.i,sq.j).queued == false)
                    % Set queued flag
                    [this.board(sq.i,sq.j).queued] = true;
                    
                    % Increment empty region count
                    ner = ner + 1;
                    
                    % Cascade region around given square
                    this.CascadeRegion3BV(sq);
                end
            end
            
            % Count remaining non-queued and non-mine squares
            nrn = sum(([this.board.queued] == false) & ...
                      ([this.board.mine] == false));
            
            % Return 3BV count
            tbv = ner + nrn;
            
            % Release all queued flags
            [this.board.queued] = deal(false);
        end
        
        %
        % Left-click the square with the given (row,col) coordinates
        %
        function LeftClick(this,row,col)
        %------------------------------------------------------------------
        % Syntax:       M.LeftClick(row,col);
        %               LeftClick(M,row,col);
        %               
        % Inputs:       M is a Minesweeper object
        %               
        %               (row,col) are the row/column coordinates of a
        %               square to left-click
        %               
        % Description:  This function left-clicks the square with the given
        %               (row,col) coordinates
        %               
        % Note:         In combination with RightClick() and
        %               GetBoardState(), it is straightforward to implement
        %               a custom AI Minesweeper engine to solve puzzles.
        %               See README.txt for more information
        %------------------------------------------------------------------
        
            % (Re)-create square struct
            sq = struct('i',col,'j',row);
            
            % If the click is valid
            if ((this.isGameOver == false) && ...
                (this.board(sq.i,sq.j).flagged == false))
                if (this.board(sq.i,sq.j).open == false)
                    % Cascade open the square
                    this.CascadeOpenSquare(sq);
                elseif (this.CountFlaggedNeighbors(sq) >= ...
                                                 this.board(sq.i,sq.j).num)
                    % Auto-open around clicked square
                    this.CascadeRegion(sq);
                end
            end
        end
        
        %
        % Right-click the square with the given (row,col) coordinates
        %
        function RightClick(this,row,col)
        %------------------------------------------------------------------
        % Syntax:       M.RightClick(row,col);
        %               RightClick(M,row,col);
        %               
        % Inputs:       M is a Minesweeper object
        %               
        %               (row,col) are the row/column coordinates of a
        %               square to right-click
        %               
        % Description:  This function right-clicks the square with the
        %               given (row,col) coordinates
        %               
        % Note:         In combination with LeftClick() and
        %               GetBoardState(), it is straightforward to implement
        %               a custom AI Minesweeper engine to solve puzzles.
        %               See README.txt for more information
        %------------------------------------------------------------------
        
            % (Re)-create square struct
            sq = struct('i',col,'j',row);
            
            % Make sure the game isn't over
            if (this.isGameOver == false)
                if (this.board(sq.i,sq.j).flagged == true)
                    % Unflag the square
                    this.UnflagSquare(sq);
                elseif ((this.board(sq.i,sq.j).open == false) && ...
                        (this.flaggedCount < this.nMines))
                    % Flag the square
                    this.FlagSquare(sq);
                end
            end
        end
        
        %
        % Returns a matrix representing the current board state
        %
        function board = GetBoardState(this)
        %------------------------------------------------------------------
        % Syntax:       board = M.GetBoardState();
        %               board = GetBoardState(M);
        %               
        % Inputs:       M is a Minesweeper object
        %               
        % Outputs:      board is a (M.nRows x M.nCols) matrix with entries
        %               
        %                                {  NaN  , unopened square
        %               board(row,col) = {   -1  , flagged square 
        %                                { [0-8] , # adjacent mines
        %               
        % Description:  This function returns a matrix representing the
        %               current board state
        %               
        % Note:         In combination with LeftClick() and RightClick(),
        %               it is straightforward to implement a custom AI
        %               Minesweeper engine to solve puzzles. See README.txt
        %               for more information
        %------------------------------------------------------------------
        
            % Return encoded board state
            board = [this.board.num];
            board([this.board.open] == false) = nan;
            board([this.board.flagged] == true) = -1;
            board = reshape(board,[this.nCols this.nRows])';
        end
        
        %
        % Reset board
        %
        function ResetBoard(this)
        %------------------------------------------------------------------
        % Syntax:       M.ResetBoard();
        %               ResetBoard(M);
        %               
        % Inputs:       M is a Minesweeper object
        %               
        % Description:  This function resets the board and initializes the
        %               GUI with a new puzzle
        %------------------------------------------------------------------
        
            % Shuffle random stream for unique gameplay
            Minesweeper.ShuffleRandStream();
            
            % Reset game state variables
            this.isGameOver = false;
            this.isSolved = false;
            this.mlock = false;
            this.isMouseDown = false;
            this.lastClick = this.NULL_CLICK;
            this.usedHint = false;
            this.isSolving = false;
            this.UpdateSmiley();
            
            % Clear active square pointer
            this.activeSq = struct('type',this.NULL,'i',nan,'j',nan);
            
            % Clear board state
            this.ClearBoard();
            this.flaggedCount = 0;
            this.clearedCount = 0;
            
            % Reset mine display
            this.UpdateMineDisplay();
            
            % Reset game timer
            this.timeElapsed = 0;
            this.StopTimer();
            this.UpdateTimeDisplay();
        end
        
        %
        % Delete object gracefully
        %
        function Close(this)
        %------------------------------------------------------------------
        % Syntax:       M.Close();
        %               Close(M);
        %               
        % Inputs:       M is a Minesweeper object
        %               
        % Description:  This function gracefully closes the Minesweeper GUI
        %               and deletes the Minesweeper object
        %------------------------------------------------------------------
        
            try
                % Save updated high score data
                HIGH_SCORES = this.highScores; %#ok
                save([this.dir '/scores.mat'],'HIGH_SCORES');
            catch %#ok
                % Graceful exit
            end
            
            % Delete all children
            for i = 1:length(this.children)
                try
                    % If child hasn't already been deleted
                    if ishandle(this.children(i))
                        % Delete ith child
                        delete(this.children(i));
                    end
                catch %#ok
                    % Graceful exit
                end
            end
            
            % Close the GUI
            this.CloseGUI();
            
            try
                % Delete this object
                delete(this);
            catch %#ok
                % Graceful exit
            end
        end
    end
    
    %
    % Private methods
    %
    methods (Access = private)
        %
        % Locate mouse on board
        %
        function sq = LocateMouse(this)
            % Get mouse coordinates
            xy = get(this.ax,'CurrentPoint');
            x = xy(1,1);
            y = xy(1,2);
            
            % Get bounding box of game board
            x1 = this.borderCoords.x(1);
            x2 = this.borderCoords.x(2);
            y1 = this.borderCoords.y(1);
            y2 = this.borderCoords.y(2);
            
            % Locate the mouse
            if ((x > x1) && (x < x2) && (y > y1) && (y < y2))
                % Valid board square selected
                sq.type = this.SQUARE;
                sq.i = ceil((x - x1) / this.SQUARE_WIDTH);
                sq.j = this.nRows + 1 - ceil((y - y1) / this.SQUARE_WIDTH);
            elseif ((x > this.smileyCoords.x(1)) && ...
                    (x < this.smileyCoords.x(2)) && ...
                    (y > this.smileyCoords.y(1)) && ...
                    (y < this.smileyCoords.y(2)))
                % Smiley was clicked
                sq.type = this.SMILEY;
            else
                % Nothing active was clicked
                sq.type = this.NULL;
            end
        end
        
        %
        % Handle mouse click
        %
        function MouseDown(this)
            % Set mouse down flag
            this.isMouseDown = true;
            
            % Locate mouse
            sq = this.LocateMouse();
            
            % Process click
            if (sq.type == this.SMILEY)
                % Smiley was clicked
                this.activeSq.type = this.SMILEY;
            elseif ((sq.type == this.SQUARE) && (this.isGameOver == false))
                % Check if the square is clickable
                if ((this.board(sq.i,sq.j).clicked == false) && ...
                    (this.board(sq.i,sq.j).flagged == false))
                    % Click square
                    this.ClickSquare(sq);
                    
                    % Record square as active
                    this.activeSq = sq;
                end
            end
        end
        
        %
        % Handle mouse movement
        %
        function MouseMove(this)
            % Only process if the mouse is down and we aren't interrupting
            % another mouse movement callback
            if ((this.isMouseDown == true) && (this.mlock == false))
                % Set motion lock
                this.mlock = true;
                
                % Locate mouse
                sq = this.LocateMouse();
                
                % If there's an active square
                if (this.activeSq.type == this.SQUARE)
                    if (sq.type == this.SQUARE)
                        if ((sq.i ~= this.activeSq.i) || ...
                            (sq.j ~= this.activeSq.j))
                            % Release the original active square
                            this.ReleaseSquare(this.activeSq);
                            this.activeSq.type = this.NULL;
                        end
                    else
                        % Release the original active square
                        this.ReleaseSquare(this.activeSq);
                        this.activeSq.type = this.NULL;
                    end
                end
                
                % Check for new square to click
                if ((sq.type == this.SQUARE) && ...
                    (this.isGameOver == false) && ...
                    (this.board(sq.i,sq.j).clicked == false) && ...
                    (this.board(sq.i,sq.j).flagged == false))
                    % Click the current square
                    this.ClickSquare(sq);
                    
                    % Record square as active
                    this.activeSq = sq;
                end
                
                % Release motion lock
                this.mlock = false;
            end
        end
        
        %
        % Handle mouse release
        %
        function MouseUp(this)
            % Release mouse down flag
            this.isMouseDown = false;
            
            % Locate mouse
            sq = this.LocateMouse();
            
            % Check for right/cmd/ctrl-click
            modifiers = get(this.fig,'CurrentModifier');
            modifiers{end + 1} = get(this.fig,'SelectionType');
            if (any(ismember(modifiers,{'command','control','alt'})) || ...
               (any(ismember(modifiers,'open')) && ...
               (this.lastClick == this.RIGHT_CLICK)))
                % Right-click detected
                this.lastClick = this.RIGHT_CLICK;
                
                % Handle right-click
                if (sq.type == this.SQUARE)
                    % Right-click the square
                    this.RightClick(sq.j,sq.i);
                end
            else
                % Left-click detected
                this.lastClick = this.LEFT_CLICK;
                
                % Handle left-click
                if (sq.type == this.SMILEY)
                    % Process based on solving state
                    if (this.isSolving == true)
                        % Release solving flag
                        this.isSolving = false;
                        
                        % Update smiley button
                        this.UpdateSmiley();
                    else
                        % Reset board
                        this.ResetBoard();
                    end
                elseif (sq.type == this.SQUARE)
                    % Left-click the square
                    this.LeftClick(sq.j,sq.i);
                end
            end
            
            % Reset active square
            if (this.activeSq.type == this.SQUARE)
                this.ReleaseSquare(this.activeSq);
            end
            this.activeSq.type = this.NULL;
        end
        
        %
        % Open the given square + cascade connected region if necessary
        %
        function CascadeOpenSquare(this,sq)
            % Check if this is the first opened square
            if (this.isRunning == false)
                % Generate mine field
                this.GenerateMines(sq);
                
                % Start timer
                this.StartTimer();
            end
            
            % Open the square
            this.OpenSquare(sq);
            
            % Process based on neighbor mine count
            if ((this.board(sq.i,sq.j).num == 0) && ~this.isGameOver)
                % Cascasde connected region
                this.CascadeRegion(sq);
            else
                % Check for (and handle) victory
                this.CheckForVictory();
            end
        end
        
        %
        % Cascade-open connected region around given square
        %
        function CascadeRegion(this,sq)
            % Set queued flag of original square
            this.board(sq.i,sq.j).queued = true;
            
            % Create neighbor queue
            queue = this.QueueNeighbors(sq);
            
            % Loop until queue is empty
            while ~isempty(queue)
                % Process head of queue
                sq = queue(1);
                queue(1) = [];
                
                % Open square
                this.OpenSquare(sq);
                
                % Check if square has any adjacent mines
                if (this.board(sq.i,sq.j).num == 0)                    
                    % No, so add neighbors to queue
                    sqn = this.QueueNeighbors(sq);
                    nn = length(sqn);
                    if (nn > 0)
                        queue((end + 1):(end + nn)) = sqn;
                    end
                end
            end
            
            % Release all queued flags
            [this.board.queued] = deal(false);
            
            % Check for (and handle) victory
            this.CheckForVictory();
        end
        
        %
        % Queue valid (i.e., closed, unflagged, and unqueued) neighbors
        % of the given square
        %
        function sqn = QueueNeighbors(this,sq)
            % Get neighbor squares
            inds = this.GetNeighbors(sq);
            
            % Keep valid neighbors
            idx = (([this.board(inds).open] == false) & ...
                    ([this.board(inds).queued] == false) & ...
                    ([this.board(inds).flagged] == false));
            inds = inds(idx);
            
            % Set queued flags
            [this.board(inds).queued] = deal(true);
            
            % Return structure array of queued neighbors
            sqn = this.sqs(inds);
        end
        
        %
        % Return linear indices of unknown (i.e., unclicked and unflagged)
        % neighbors of the given square
        %
        function inds = UnknownNeighbors(this,sq)
            % Get neighbors
            inds = this.GetNeighbors(sq);
            
            % Keep unknown neighbors
            idx = (([this.board(inds).open] == false) & ...
                    ([this.board(inds).flagged] == false));
            inds = inds(idx);
        end
        
        %
        % Get linear indices of neighbors of the given square
        %
        function inds = GetNeighbors(this,sq)
            % Locate neighbor squares
            I = sq.i + [-1 -1 -1  0  0  1  1  1];
            J = sq.j + [-1  0  1 -1  1 -1  0  1];
            idx = ((I >= 1) & (I <= this.nCols) & ...
                   (J >= 1) & (J <= this.nRows));
            
            % Return linear indices
            inds = sub2ind([this.nCols this.nRows],I(idx),J(idx));
        end
        
        %
        % Return number of open neighboring squares
        %
        function count = CountOpenNeighbors(this,sq)
            % Get neighbors
            inds = this.GetNeighbors(sq);
            
            % Count open neighbors
            count = sum([this.board(inds).open] == true);
        end
        
        %
        % Return number of flagged neighboring squares
        %
        function count = CountFlaggedNeighbors(this,sq)
            % Get neighbors
            inds = this.GetNeighbors(sq);
            
            % Count flagged neighbors
            count = sum([this.board(inds).flagged] == true);
        end
        
        %
        % Click the given square
        %
        function ClickSquare(this,sq)
            % Set patch to clicked
            x0 = this.sqCoords.x(sq.i);
            y0 = this.sqCoords.y(sq.j);
            set(this.board(sq.i,sq.j).ph,'XData',x0 + this.clicked.X, ...
                                         'YData',y0 + this.clicked.Y, ...
                                         'CData',this.clicked.C);
            
            % Set clicked flag
            this.board(sq.i,sq.j).clicked = true;
        end
        
        %
        % Release the given square (if not opened)
        %
        function ReleaseSquare(this,sq)
            % Don't update graphics of opened squares
            if (this.board(sq.i,sq.j).open == false)
                % Set patch to unclicked
                x0 = this.sqCoords.x(sq.i);
                y0 = this.sqCoords.y(sq.j);
                set(this.board(sq.i,sq.j).ph, ...
                                         'XData',x0 + this.unclicked.X, ...
                                         'YData',y0 + this.unclicked.Y, ...
                                         'CData',this.unclicked.C);
                
                % Release clicked flag
                this.board(sq.i,sq.j).clicked = false;
            end            
        end
        
        %
        % Open the given square
        %
        function OpenSquare(this,sq)
            % Click square, if necessary
            if (this.board(sq.i,sq.j).clicked == false)
                this.ClickSquare(sq);
            end
            
            % Unflag square, if necessary
            if (this.board(sq.i,sq.j).flagged == true)
                this.UnflagSquare(sq);
            end
            
            % Set open flag
            this.board(sq.i,sq.j).open = true;
            
            % Process based on contents of square
            if (this.board(sq.i,sq.j).mine == true)
                % Found a mine...
                this.GameOver(sq);
            else
                % Increment clear square count
                this.clearedCount = this.clearedCount + 1;
                
                % Display neighboring mine count, if necessary
                if (this.board(sq.i,sq.j).num > 0)
                    x0 = this.sqCoords.x(sq.i);
                    y0 = this.sqCoords.y(sq.j);
                    num = this.NUMBERS{this.board(sq.i,sq.j).num + 1};
                    set(this.board(sq.i,sq.j).imh, ...
                                         'XData',x0 + this.lims.number, ...
                                         'YData',y0 + this.lims.number, ...
                                         'CData',this.numbers.(num), ...
                                         'Visible','on');
                end
            end
        end
        
        %
        % Close the given square
        %
        function CloseSquare(this,sq)
            % Turn off square's image
            set(this.board(sq.i,sq.j).imh,'Visible','off');
            
            % Release open flag
            this.board(sq.i,sq.j).open = false;
        end
        
        %
        % Flag the given square
        %
        function FlagSquare(this,sq)
            % Set flagged flag
            this.board(sq.i,sq.j).flagged = true;
            
            % Increment flagged square counter
            this.flaggedCount = this.flaggedCount + 1;
            
            % Update mine display
            this.UpdateMineDisplay();
            
            % Draw flag @(i,j)
            x0 = this.sqCoords.x(sq.i);
            y0 = this.sqCoords.y(sq.j);
            set(this.board(sq.i,sq.j).imh,'XData',x0 + this.lims.flag, ...
                                          'YData',y0 + this.lims.flag, ...
                                          'CData',this.sprites.flag, ...
                                          'Visible','on');
        end
        
        %
        % Unflag the given square
        %
        function UnflagSquare(this,sq)
            % Release flagged flag
            this.board(sq.i,sq.j).flagged = false;
            
            % Decrement flagged square counter
            this.flaggedCount = this.flaggedCount - 1;
            
            % Update mine display
            this.UpdateMineDisplay();
            
            % Turn off square's image
            set(this.board(sq.i,sq.j).imh,'Visible','off');
        end
        
        %
        % Check for (and handle) victory
        %
        function CheckForVictory(this)
            % Check for victory
            if (this.clearedCount >= (this.nSquares - this.nMines))
                % Player just won!
                
                % Stop game timer
                this.StopTimer();
                
                % Set gameover state
                this.isSolved = true;
                this.isGameOver = true;
                this.isSolving = false;
                
                % Update high scores (if there was no hint)
                if (this.usedHint == false)
                    this.UpdateHighScores(this.timeElapsed);
                end
                
                % Flag all mines
                this.FlagMines();
                
                % Update smiley face
                this.UpdateSmiley();
            end
        end
        
        %
        % Handle game over at the given square
        %
        function GameOver(this,sq)
            % Stop game timer
            this.StopTimer();
            
            % Set gameover state
            this.isSolved = false;
            this.isGameOver = true;
            this.isSolving = false;
            
            % Draw red mine given square
            x0 = this.sqCoords.x(sq.i);
            y0 = this.sqCoords.y(sq.j);
            set(this.board(sq.i,sq.j).ph,'CData',this.clicked.red);
            set(this.board(sq.i,sq.j).imh,'XData',x0 + this.lims.bomb, ...
                                          'YData',y0 + this.lims.bomb, ...
                                          'CData',this.sprites.redbomb, ...
                                          'Visible','on');
            
            % Reveal all (other) mines
            this.RevealMines();
            
            % Reveal incorrect flags
            this.RevealIncorrectFlags();
            
            % Update smiley face
            this.UpdateSmiley();
        end
        
        %
        % Flag all (remaining) mines
        %
        function FlagMines(this)
            % Get all mine squares
            inds = find([this.board.mine]);
            
            % Loop over mine squares
            for idx = 1:length(inds)
                % Get square
                sq = this.sqs(inds(idx));
                
                % Flag square, if necessary
                if (this.board(sq.i,sq.j).flagged == false)
                    this.FlagSquare(sq);
                end
            end
        end
        
        %
        % Reveal all mines
        %
        function RevealMines(this)
            % Get all mine squares
            inds = find([this.board.mine]);
            
            % Loop over mine squares
            for idx = 1:length(inds)
                % Create square structure
                sq = this.sqs(inds(idx));
                
                % Only display unflagged mines
                if (this.board(sq.i,sq.j).flagged == false)
                    % Click square, if necessary
                    if (this.board(sq.i,sq.j).clicked == false)
                        this.ClickSquare(sq);
                    end
                    
                    % Draw mine, if necessary
                    if (this.board(sq.i,sq.j).open == false)
                        % Draw mine at square
                        x0 = this.sqCoords.x(sq.i);
                        y0 = this.sqCoords.y(sq.j);
                        set(this.board(sq.i,sq.j).imh, ...
                                           'XData',x0 + this.lims.bomb, ...
                                           'YData',y0 + this.lims.bomb, ...
                                           'CData',this.sprites.bomb, ...
                                           'Visible','on');
                    end
                end
            end
        end
        
        %
        % Reveal incorrect flags
        %
        function RevealIncorrectFlags(this)
            % Get all incorrect flags
            inds = find([this.board.flagged] & ~[this.board.mine]);
            
            % Loop over mine squares
            for idx = 1:length(inds)
                % Create square structure
                sq = this.sqs(inds(idx));
                
                % Click square
                this.ClickSquare(sq);
                
                % Draw X-ed mine at square
                x0 = this.sqCoords.x(sq.i);
                y0 = this.sqCoords.y(sq.j);
                set(this.board(sq.i,sq.j).imh, ...
                                       'XData',x0 + this.lims.xbomb, ...
                                       'YData',y0 + this.lims.xbomb, ...
                                       'CData',this.sprites.xbomb, ...
                                       'Visible','on');
            end
        end
        
        %
        % Update mine display
        %
        function UpdateMineDisplay(this)
            % Get number of remaining mines
            mineCount = this.nMines - this.flaggedCount;
            
            % Update seven-segment display
            minestr = sprintf('%03d',mineCount);
            for i = 1:3
                % Set ith digit 
                idx = str2double(minestr(i)) + 1;
                set(this.mineh(i),'CData', ...
                    this.sevenSeg.(this.NUMBERS{idx}));
            end
        end
        
        %
        % Update time conter
        %
        function UpdateTime(this)
            % Increment time counter
            this.timeElapsed = this.timeElapsed + 1;
            
            % Update time display
            if (this.timeElapsed <= 999)
                this.UpdateTimeDisplay();
            end
        end
        
        %
        % Update time display
        %
        function UpdateTimeDisplay(this)
            % Get current time elapsed
            sec = this.timeElapsed;
            
            % Update seven-segment display
            secstr = sprintf('%03d',sec);
            for i = 1:3
                % Set ith digit 
                idx = str2double(secstr(i)) + 1;
                set(this.timeh(i), ...
                    'CData',this.sevenSeg.(this.NUMBERS{idx}));
            end
        end
        
        %
        % Update smiley button
        %
        function UpdateSmiley(this)
            % Process based on solving/gameover flags
            if (this.isSolving == true)
                % Auto-solution in progress, so display stop symbol
                set(this.smileyh,'CData',this.sprites.stop);
            elseif (this.isGameOver == false)
                % Game is in progress, so display smiley face
                set(this.smileyh,'CData',this.sprites.smileyface);
            elseif (this.isSolved == true)
                % Puzzle is solved, so display cool face!
                set(this.smileyh,'CData',this.sprites.coolface);
            else
                % Solution has failed, so display sad face...
                set(this.smileyh,'CData',this.sprites.sadface);
            end
        end
        
        %
        % Start game timer
        %
        function StartTimer(this)
            % Start timer object
            start(this.timerobj);
            
            % Set running flag
            this.isRunning = true;
        end
        
        %
        % Stop game timer
        %
        function StopTimer(this)
            % Stop timer object
            stop(this.timerobj);
            
            % Release running flag
            this.isRunning = false;
        end
        
        %
        % Generate mine locations (with no mines adjacent to given square)
        %
        function GenerateMines(this,sq)
            % Get linear indices of given square and all neighbors       
            ninds = this.GetNeighbors(sq);
            ninds(end + 1) = sub2ind([this.nCols this.nRows],sq.i,sq.j);
            
            % Assign mines randomly among valid squares
            vinds = setdiff(1:this.nSquares,ninds); % valid squares
            idxs = randperm(length(vinds)); % random subset
            [this.board(vinds(idxs(1:this.nMines))).mine] = deal(true);
            
            % Compute neighboring mines
            this.CountNeighbors();
        end
        
        %
        % Compute mine neighbor counts for a given mine field
        %
        function CountNeighbors(this)
            % Get minefield size
            m = this.nCols;
            n = this.nRows;
            
            % Zero-padded mines
            mines = zeros(m + 2,n + 2);
            mines(2:(m + 1),2:(n + 1)) = reshape([this.board.mine],m,n);
            
            % Comptue neighbor counts
            H = [1 1 1;1 0 1;1 1 1]; % Neighbor filter            
            for i = 1:m
                for j = 1:n
                    Nij = H .* mines(i:(i + 2),j:(j + 2));
                    this.board(i,j).num = sum(Nij(:));
                end
            end
        end
        
        %
        % Cascade region (for 3BV calculation) around given square
        %
        function CascadeRegion3BV(this,sq)
            % Create neighbor queue
            queue = this.QueueNeighbors3BV(sq);
            
            % Loop until queue is empty
            while ~isempty(queue)
                % Process head of queue
                sqh = queue(1);
                queue(1) = [];
                
                % If square is empty
                if (this.board(sqh.i,sqh.j).num == 0)
                    % Add neighbors to the queue
                    sqn = this.QueueNeighbors3BV(sqh);
                    nn = length(sqn);
                    if (nn > 0)
                        queue((end + 1):(end + nn)) = sqn;
                    end
                end
            end
        end
        
        %
        % Queue neighbors (for 3BV calculation) of the given square
        %
        function sqn = QueueNeighbors3BV(this,sq)
            % Get neighbors
            inds = this.GetNeighbors(sq);
            
            % Keep unqueued squares
            inds = inds([this.board(inds).queued] == false);
            
            % Set queued flags
            [this.board(inds).queued] = deal(true);
            
            % Return unqueued neighbors
            sqn = this.sqs(inds);
        end
        
        %
        % Clear all board squares
        %
        function ClearBoard(this)
            % Loop over board squares
            for idx = 1:this.nSquares
                % Get square
                sq = this.sqs(idx);
                
                % Close square
                this.CloseSquare(sq);
                
                % Set square to unclicked
                this.ReleaseSquare(sq);
                
                % Clear mine info
                this.board(sq.i,sq.j).flagged = false;
                this.board(sq.i,sq.j).queued = false;
                this.board(sq.i,sq.j).mine = false;
                this.board(sq.i,sq.j).num = 0;
            end
        end
        
        %
        % Initialize the GUI
        %
        function InitializeGUI(this,nRows,nCols,nMines,varargin)
            % Parse board dimensions
            if (nargin < 4)
                % Load default board
                this.level = this.DEFAULT_LEVEL;
                params = num2cell(this.(this.DEFAULT_LEVEL));
                [nRows nCols nMines] = deal(params{:});
            end
            
            % Make sure board parameters are valid
            [maxRows maxCols] = Minesweeper.MaxBoardSize();
            if ((nCols > maxCols) || (nRows > maxRows))
                error('Max allowed board size is %i x %i',maxRows,maxCols);
            elseif (nMines > (nCols * nRows - 9))
                error('Too many mines for those board dimensions');
            end
            
            % Save board parameters
            this.nRows = nRows;
            this.nCols = nCols;
            this.nMines = nMines;
            this.nSquares = nRows * nCols;
            
            % Initialize square structure
            [J I] = meshgrid(1:this.nRows,1:this.nCols);
            this.sqs = struct('i',num2cell(I(:)),'j',num2cell(J(:)));
            
            % Create GUI
            this.CreateGUI(varargin{:});
            
            % Reset board
            this.ResetBoard();
        end
        
        %
        % Set board dimensions
        %
        function SetBoardDims(this,lvl)
            % Parse new level
            lvl = upper(lvl);
            if strcmp(lvl,'CUSTOM')
                % Get board params from user
                def = arrayfun(@num2str,(this.(this.DEFAULT_LEVEL)),...
                               'UniformOutput',false);
                answer = inputdlg({'Rows','Columns','Mines'}, ...
                                  'Custom Board',[1 40],def);
                drawnow; % hack to avoid MATLAB freeze + crash
                params = cellfun(@str2double,answer);
                
                % Return immediately if user cancelled during creation
                if isempty(params)
                    % Quick return
                    return;
                end
            else
                % Load default parameters
                params = this.(lvl);
            end
            
            % Save new level
            this.level = lvl;
            
            % Save center coordinates of old GUI
            xyc = this.GetCenterCoordinates();
            
            % Close old GUI
            this.CloseGUI();
            
            % Initialize new GUI
            params = num2cell(params);
            this.InitializeGUI(params{:},xyc);
        end
        
        %
        % Display leaderboard
        %
        function Leaderboard(this)
            % Get handle to existing leaderboard
            tag = 'Leaderboard';
            figh = this.GetFigHandle(tag);
            
            % If no leaderboard exists
            if isempty(figh)
                % Concatenate high scores
                scr = [this.highScores.beginner;
                       this.highScores.intermediate;
                       this.highScores.expert];
                scr(isnan(scr)) = 0; % Display nans as empty strings
                
                % Leaderboard text
                txt = {'       Beginner    Intermediate    Expert', ...
              sprintf('1st:  %6.i        %6.i        %6.i  ',scr(:,1)), ...
              sprintf('2nd:  %6.i        %6.i        %6.i  ',scr(:,2)), ...
              sprintf('3rd:  %6.i        %6.i        %6.i  ',scr(:,3))};
                
                % Create leaderboard in separate window
                name = 'Leaderboard';
                this.TextWindow(name,txt,tag);
            else
                % Give focus to existing leaderboard
                figure(figh(1));
            end
        end
        
        %
        % Clear leaderboard
        %
        function ClearLeaders(this)
            % Ask user to confirm leaderboard clearing
            selection = questdlg('Really clear the leaderboard?', ...
                                  this.version.name,'Yes','No','No');
            drawnow; % hack to avoid MATLAB freeze + crash
            
            % Handle request
            if strcmp(selection,'Yes')
                % Empty high score structure
                this.EmptyHighScores();
                
                % Refresh leaderboard
                this.RefreshLeaderboard();
            end
        end
        
        %
        % Create an empty high scores structure
        %
        function EmptyHighScores(this)
            % Empty the scores structure
            this.highScores.beginner = nan(1,3);
            this.highScores.intermediate = nan(1,3);
            this.highScores.expert = nan(1,3);
        end
        
        %
        % Update high score list
        %
        function UpdateHighScores(this,score)
            % Process based on board level
            switch this.level
                case 'BEGINNER'
                    % Save beginner score
                    list = sort([this.highScores.beginner score]);
                    this.highScores.beginner = list(1:3);
                case 'INTERMEDIATE'
                    % Save intermediate score
                    list = sort([this.highScores.intermediate score]);
                    this.highScores.intermediate = list(1:3);
                case 'EXPERT'
                    % Save expert score
                    list = sort([this.highScores.expert score]);
                    this.highScores.expert = list(1:3);
            end
            
            % Refresh leaderboard
            this.RefreshLeaderboard();
        end
        
        %
        % Refresh the leaderboard
        %
        function RefreshLeaderboard(this)
            % Get handle to existing leaderboard
            figh = this.GetFigHandle('Leaderboard');
            
            % If a leaderboard exists
            if ~isempty(figh)
                % Delete old leaderboard
                delete(figh);
                
                % Display updated leaderboard
                this.Leaderboard();
            end
        end
        
        %
        % Help window
        %
        function Help(this)
            % Get handle to existing leaderboard
            tag = 'Help';
            figh = this.GetFigHandle(tag);
            
            % If no leaderboard exists
            if isempty(figh)
                % Load help text
                txt = this.version.help;
                
                % Create help window
                name = [this.version.name ' Help'];
                this.TextWindow(name,txt,tag);
            else
                % Give focus to existing help window
                figure(figh(1));
            end
        end
        
        %
        % About window
        %
        function About(this)
            % Get handle to existing leaderboard
            tag = 'About';
            figh = this.GetFigHandle(tag);
            
            % If no leaderboard exists
            if isempty(figh)
                % Load version info
                name = this.version.name;
                release = this.version.release;
                date = this.version.date;
                author = this.version.author;
                contact = this.version.contact;
                
                % About text
                txt = {[name ' v' release],'',date,'',author,contact};
                
                % Create about window
                name = 'About';
                this.TextWindow(name,txt,tag);
            else
                % Give focus to existing about window
                figure(figh(1));
            end
        end
        
        %
        % Creates a text window as a child of the GUI
        %
        function TextWindow(this,name,txt,tag)
            % Constants
            fontSize = 12; % font size, in pixels
            ds = 25; % border spacing, in pixels
            color = 0.9294 * [1 1 1]; % background color
            
            % Compute required figure dimensions
            h = 1.25 * fontSize * length(txt);
            w = 0.60 * fontSize * max(cellfun(@length,txt));
            dim = [w h] + 2 * ds;
            
            % Setup a nice figure centered on top of GUI
            xyc = this.GetCenterCoordinates();
            twfig = figure('name',name, ...
                  'tag',tag, ...
                  'MenuBar','none', ...
                  'NumberTitle','off', ...
                  'Position',[(xyc - 0.5 * dim) dim], ...
                  'Color',color, ...
                  'DockControl','off', ...
                  'WindowKeyPressFcn',@(s,e)AuxFigKeyPress(this,tag,e), ...
                  'Resize','off');
            
            % Add text
            uicontrol(twfig,'Style','text', ...
                            'Units','pixels', ...
                            'Position',[ds ds w h], ...
                            'HorizontalAlignment','center', ...
                            'BackgroundColor',color, ...
                            'FontUnits','pixels', ...
                            'FontSize',fontSize, ...
                            'FontName','Courier', ...
                            'Max',2,'Min',0, ...
                            'String',txt);
            
            % Save figure handle to children list
            this.children(end + 1) = twfig;
        end
        
        %
        % Handle key press on auxiliary figure
        %
        function AuxFigKeyPress(this,tag,event)
            % Check for ctrl + w
            key = double(event.Character);
            modifiers = event.Modifier;
            if (any(ismember(modifiers,{'command','control'})) && ...
                any(ismember(key,[23 87 119])))
                % Close figures with matching tags
                figh = this.GetFigHandle(tag);
                delete(figh);
            end
        end
        
        %
        % Get handle(s) to figure(s) with the given tag
        %
        function figh = GetFigHandle(this,tag)
            % Remove deleted children from list
            this.children(~ishandle(this.children)) = [];
            
            % Make sure children exist
            if isempty(this.children)
                % Quick return
                figh = [];
                return;
            end
            
            % Get children tags
            tags = get(this.children,'tag');
            if ischar(tags)
                tags = {tags};
            end
            
            % Return handles to matching tags
            figh = this.children(ismember(tags,tag));
        end
        
        %
        % Create GUI
        %
        function CreateGUI(this,xyc)
            % Initialize these things before WindowButtonMotionFcn to
            % avoid silly errors from premature callback...
            this.mlock = false;
            this.activeSq.type = this.NULL;
            
            % Get size constants
            gap = this.PANEL_GAP;
            bw = this.BORDER_WIDTH;
            sw = this.SQUARE_WIDTH;
            
            % Setup a nice figure
            if (nargin < 2)
                % Center of screen
                scrsz = get(0,'ScreenSize');
                xyc = 0.5 * scrsz(3:4);
            end
            dimx = 2 * gap + 2 * bw + sw * this.nCols;
            dimy = 3 * gap + 6 * bw + sw * (this.nRows + 1);
            dim = [dimx dimy];
            this.fig = figure('MenuBar','None', ...
                         'NumberTitle','off', ...
                         'name',this.version.name, ...
                         'tag','Minesweeper', ...
                         'Position',[(xyc - 0.5 * dim) dim], ...
                         'Renderer','zbuffer', ...
                         'Resize','off', ...
                         'Color',this.GRAY, ...
                         'DockControl','off', ...
                         'WindowButtonDownFcn',@(s,e)MouseDown(this), ...
                         'WindowButtonMotionFcn',@(s,e)MouseMove(this), ...
                         'WindowButtonUpFcn',@(s,e)MouseUp(this), ...
                         'CloseRequestFcn',@(s,e)Close(this));
            
            % Create menus, no need for this part in our project
            % gamem = uimenu(this.fig,'Label','Game');
            % beginner_cb = @(s,e)SetBoardDims(this,'BEGINNER');
            % uimenu(gamem,'Label','Beginner', ...
            %                      'Callback',beginner_cb, ...
            %                      'Accelerator','1');
            % intermediate_cb = @(s,e)SetBoardDims(this,'INTERMEDIATE');
            % uimenu(gamem,'Label','Intermediate', ...
            %                      'Callback',intermediate_cb, ...
            %                      'Accelerator','2');
            % expert_cb = @(s,e)SetBoardDims(this,'EXPERT');
            % uimenu(gamem,'Label','Expert', ...
            %                      'Callback',expert_cb, ...
            %                      'Accelerator','3');
            % custom_cb = @(s,e)SetBoardDims(this,'CUSTOM');
            % uimenu(gamem,'Label','Custom...', ...
            %                      'Callback',custom_cb);
            % uimenu(gamem,'Label','Reset Board', ...
            %                      'Callback',@(s,e)ResetBoard(this), ...
            %                      'Separator','on', ...
            %                      'Accelerator','R');
            % uimenu(gamem,'Label','Close', ...
            %                      'Callback',@(s,e)Close(this), ...
            %                      'Separator','on', ...
            %                      'Accelerator','W');
            % solvem = uimenu(this.fig,'Label','Solve');
            % uimenu(solvem,'Label','Auto-Solve', ...
            %                      'Callback',@(s,e)AutoSolve(this), ...
            %                      'Accelerator','S');
            % hintm = uimenu(this.fig,'Label','Hint');
            % uimenu(hintm,'Label','Hint...', ...
            %                      'Callback',@(s,e)Hint(this), ...
            %                      'Accelerator','H');
            % recordm = uimenu(this.fig,'Label','Records');
            % uimenu(recordm,'Label','Leaderboard', ...
            %                      'Callback',@(s,e)Leaderboard(this), ...
            %                      'Accelerator','L');
            % uimenu(recordm,'Label','Clear...', ...
            %                      'Callback',@(s,e)ClearLeaders(this), ...
            %                      'Separator','on');
            % helpm = uimenu(this.fig,'Label','Help');
            % uimenu(helpm,'Label','Help...', ...
            %                      'Callback',@(s,e)Help(this));
            % uimenu(helpm,'Label','About', ...
            %                      'Callback',@(s,e)About(this), ...
            %                      'Separator','on');
            
            % Format the game axis
            this.ax = gca;
            set(this.ax,'Position',[0 0 1 1]);
            set(this.ax,'DrawMode','fast');
            axis(this.ax,'off');
            hold(this.ax,'all');
            axis(this.ax,[(-gap - bw) ...
                          (gap + bw + sw * this.nCols) ...
                          (-gap - bw) ...
                          (2 * gap + 5 * bw + sw * (this.nRows + 1))]);
            
            % Get border color scheme
            bcolor = permute([this.DARK_GRAY' ...
                             this.GRAY' ...
                             this.LIGHT_GRAY'],[3 2 1]);
            
            % Generate game border
            xg0 = -bw;
            yg0 = -bw;
            bdgx = 2 * bw + sw * this.nCols;
            bdgy = 2 * bw + sw * this.nRows;
            patch(xg0 + this.patches.X(bdgx,bw / bdgx), ...
                  yg0 + this.patches.Y(bdgy,bw / bdgy), ...
                  bcolor, ...
                  'edgecolor','none');
            
            % Generate menu border
            xm0 = -bw;
            ym0 = gap + bw + sw * this.nRows;
            bdmx = 2 * bw + this.nCols * sw;
            bdmy = 4 * bw + sw;
            patch(xm0 + this.patches.X(bdmx,bw / bdmx), ...
                  ym0 + this.patches.Y(bdmy,bw / bdmy), ...
                  bcolor, ...
                  'edgecolor','none');
            
            % Generate mines counter panel
            mcdx = bw;
            mcdy = 3 * bw + gap + sw * this.nRows;
            rectangle('FaceColor',this.BLACK, ...
                      'Position',[mcdx mcdy ((5 * sw) / 3) sw]);
            
            % Generate time counter panel
            tcdx = sw * this.nCols - bw - (5 * sw) / 3;
            tcdy = 3 * bw + gap + sw * this.nRows;
            rectangle('FaceColor',this.BLACK, ...
                      'Position',[tcdx tcdy ((5 * sw) / 3) sw]);
            
            % Generate seven-segment display parameters
            this.digits.mines.lims.x = mcdx + sw * [0 26] / 60;
            this.digits.mines.lims.y = mcdy + sw * [0 46] / 60;
            this.digits.time.lims.x = tcdx + sw * [0 26] / 60;
            this.digits.time.lims.y = tcdy + sw * [0 46] / 60;
            this.digits.x = sw * [7 37 68] / 60;
            this.digits.y = sw * [7  7  7] / 60;
            
            % Generate and initialize smiley button
            xs0 = 0.5 * (dimx - sw) - gap - bw;
            ys0 = dimy - 2 * gap - 3 * bw - sw;
            this.smileyCoords.x = xs0 + [0 sw]; % Bounding box
            this.smileyCoords.y = ys0 + [0 sw]; % Bounding box
            patch(xs0 + this.unclicked.X, ...
                  ys0 + this.unclicked.Y, ...
                  this.unclicked.C, ...
                  'edgecolor','none');
            this.smileyh = image(xs0 + this.lims.smiley, ...
                                 ys0 + this.lims.smiley, ...
                                 this.sprites.smileyface, ...
                                 'Parent',this.ax);
            
            % Initialize board state structure
            this.board = repmat(struct('open',false, ...
                                       'clicked',false, ...
                                       'flagged',false, ...
                                       'queued',false, ...
                                       'mine',false, ...
                                       'num',0, ...
                                       'ph',[], ...
                                       'imh',[]),this.nCols,this.nRows);
            
            % Create board squares (unclicked/invisible by default)
            this.borderCoords.x = [0 sw * this.nCols]; % Bounding box
            this.borderCoords.y = [0 sw * this.nRows]; % Bounding box
            this.sqCoords.x = @(i) sw * (i - 1); % Coordinate fcn
            this.sqCoords.y = @(j) sw * (this.nRows - j); % Coordinate fcn
            for i = 1:this.nCols
                for j = 1:this.nRows
                    % Square patch
                    x0 = this.sqCoords.x(i);
                    y0 = this.sqCoords.y(j);
                    this.board(i,j).ph = patch(x0 + this.unclicked.X, ...
                                               y0 + this.unclicked.Y, ...
                                               this.unclicked.C, ...
                                               'edgecolor','none');
                    
                    % Square images
                    this.board(i,j).imh = image(1,'Visible','off');
                end
            end
            
            % Initialize mine display (to zeros)
            this.mineh = [0 0 0];
            for i = 1:3
                xm0 = this.digits.x(i) + this.digits.mines.lims.x;
                ym0 = this.digits.y(i) + this.digits.mines.lims.y;
                this.mineh(i) = image(xm0,ym0, ...
                                      this.sevenSeg.(this.NUMBERS{1}), ...
                                      'Parent',this.ax);
            end
            
            % Initialize time display (to zeros)
            this.timeh = [0 0 0];
            for i = 1:3
                xt0 = this.digits.x(i) + this.digits.time.lims.x;
                yt0 = this.digits.y(i) + this.digits.time.lims.y;
                this.timeh(i) = image(xt0,yt0, ...
                                      this.sevenSeg.(this.NUMBERS{1}), ...
                                      'Parent',this.ax);
            end
            
            % Create timer object
            this.timerobj = timer('TimerFcn',@(s,e)UpdateTime(this), ...
                                  'ExecutionMode','FixedRate', ...
                                  'Period',1, ...
                                  'StartDelay',1);
        end
        
        %
        % Get center coordinates of GUI
        %
        function xyc = GetCenterCoordinates(this)
            % Infer center coordinates from GUI position
            pos = get(this.fig,'Position');
            xyc = pos(1:2) + 0.5 * pos(3:4);
        end
        
        %
        % Close GUI gracefully
        %
        function CloseGUI(this)
            try
                % Delete timer
                stop(this.timerobj);
                delete(this.timerobj);
            catch %#ok
                % Graceful exit
            end
            
            try
                % Delete the figure
                delete(this.fig);
            catch %#ok
                % Something strange happened to the figure handle, so
                % delete using gcf
                delete(gcf);
            end
        end
    end
    
    %
    % Private static methods
    %
    methods (Access = private, Static = true)
        %
        % Shuffle random number stream for unique gameplay
        %
        function ShuffleRandStream()
            try
                % >= MATLAB 2011
                rng('shuffle');
            catch %#ok
                % >= MATLAB 2006
                rand('twister',sum(100 * clock)); %#ok
            end
        end
        
        %
        % Compute the maximum board size
        %
        function [nRows nCols] = MaxBoardSize()
            % Get board spacing constants
            sw = Minesweeper.SQUARE_WIDTH;
            bw = Minesweeper.BORDER_WIDTH;
        	gap = Minesweeper.PANEL_GAP;
            
            % Compute available board real-estate, in pixels
            scrsz = get(0,'Screensize');
            width = scrsz(3) - 50 - 2 * bw - 2 * gap;
            height = scrsz(4) - 100 - 6 * bw - 3 * gap - sw;
            
            % Compute max allowed board size
            nRows = floor(height / sw);
            nCols = floor(width / sw);
        end
        
        %
        % Get base directory of this class
        %
        function dir = GetBaseDir()
            [dir name ext] = fileparts(mfilename('fullpath')); %#ok
        end
    end
    
    %
    % Hidden methods (cleans up tab-completion and disp() calls)
    %
    methods (Hidden = true, Access = public)
        % Custom (empty) display method
        function display(varargin)
            % Empty
        end
        
        % Hide handle's addlistener() method
        function out = addlistener(varargin)
            out = addlistener@handle(varargin{:});
        end
        
        % Hide handle's eq() method
        function out = eq(varargin)
            out = eq@handle(varargin{:});
        end
        
        % Hide handle's findobj() method
        function out = findobj(varargin)
            out = findobj@handle(varargin{:});
        end
        
        % Hide handle's findprop() method
        function out = findprop(varargin)
            out = findprop@handle(varargin{:});
        end
        
        % Hide handle's ge() method
        function out = ge(varargin)
            out = ge@handle(varargin{:});
        end
        
        % Hide handle's gt() method
        function out = gt(varargin)
            out = gt@handle(varargin{:});
        end
        
        % Hide handle's le() method
        function out = le(varargin)
            out = le@handle(varargin{:});
        end
        
        % Hide handle's lt() method
        function out = lt(varargin)
            out = lt@handle(varargin{:});
        end
        
        % Hide handle's ne() method
        function out = ne(varargin)
            out = ne@handle(varargin{:});
        end
        
        % Hide handle's notify() method
        function notify(varargin)
            notify@handle(varargin{:});
        end
    end
end
