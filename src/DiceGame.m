classdef DiceGame

    % =============================================
    %       Interaction Keys to ThingSpeak
    % =============================================
    properties (Constant)
        WRITE_KEY = 'TS5IXZHX5UWGCWQE';
        READ_KEY = 'F6M5NKR91J9RRSBD';
        CHANNEL_ID = 1252481;
        delay = 5;
    end

    properties (Access = private)
        ID; % id of this client, 1 or 2
        score; % score of this client
        pointThisRound; % boolean, currently believe or not
        name; % user name of this client
        status; % char array of json, game status, sync from server
        dice; % vector of 5 Dice objects
    end

    methods (Access = public)
        % =============================================
        %       Interaction to Object Fields
        % =============================================
        function obj = DiceGame(ID, name)
            obj.ID = ID;
            obj.score = 0;
            obj.name = "Anonymous Player";
            obj.dice = [
                    Dice()
                    Dice()
                    Dice()
                    Dice()
                    Dice()
                    ];
            % obj.status = char(thingSpeakRead(obj.CHANNEL_ID, 'ReadKey', obj.READ_KEY, 'OutputFormat', 'timetable').desp);
            if nargin == 2
                obj.name = name;
            end

        end

        function isMyRound = isMyRound(obj)
            readStatus = thingSpeakRead(obj.CHANNEL_ID, 'Fields', 1, 'ReadKey', obj.READ_KEY);
            isMyRound = (readStatus == obj.ID);
        end

        function ID = getID(obj)
            ID = obj.ID;
        end

        function name = getName(obj)
            name = obj.name;
        end

        function score = getScore(obj)
            score = obj.score;
        end

        function prompt = getPrompt(obj)
            prompt = obj.name ...
                + " #" + string(obj.ID) ...
                + " (" + string(obj.score) + ")" ...
                + " $ ";
        end

        function obj = addScore(obj, num)
            obj.score = obj.score + num;
        end

        % function obj = getResults(obj)
        %     disp("====");
        %     disp(obj.status)
        %     disp("====");
        %     s = jsondecode(obj.status);

        %     switch obj.ID
        %         case 1
        %             opponentDice = s.client2.dice;
        %         case 2
        %             opponentDice = s.client1.dice;
        %     end

        %     myPoint = getListPoint(obj.dice);
        %     opponentPoint = getListPoint(opponentDice);

        %     % display the points and dice
        %     disp("My dice, point = " + string(myPoint));
        %     disp(obj.dice);
        %     disp("Opponent's Dice, point = " + string(opponentPoint));
        %     disp(opponentDice);

        %     if myPoint >= opponentPoint
        %         obj.score = obj.score + myPoint;
        %     end

        % end

        % =============================================
        %       Dice Functions
        % =============================================
        function obj = setDieFront(obj, index, num)
            % add the ith die to num
            obj.dice(index) = obj.dice(index).setFront(num);
        end

        function dice = getDice(obj, index)

            switch nargin
                case 1
                    dice = obj.dice;
                case 2
                    dice = obj.dice(index);
            end

        end

        function str = getDiceStr(obj)
            str = "";

            for i = 1:5
                str = str + string(obj.dice(i).getFront()) + "    ";
            end

        end

        function diceFronts = getDiceFronts(obj, index)
            diceFronts = [];

            switch nargin
                case 1
                    % diceFronts = zeros(1, 5); %   as defined, there are only 5 dices

                    for i = 1:5
                        diceFronts(end + 1) = obj.dice(i).getFront();
                    end

                case 2
                    diceFronts = obj.dice(index).getFront();
            end

        end

        function obj = rollAllDice(obj, rollTimes)

            switch nargin
                case 1
                    t = 1;
                case 2
                    t = rollTimes;
            end

            % roll all the dice!
            for i = 1:t

                for j = 1:5
                    obj.dice(j) = obj.dice(j).roll();
                end

            end

        end

        % =============================================
        %       JSON factions
        % =============================================
        function json_txt = dumpJ(obj)
            s = struct("ID", obj.ID, "score", obj.score, "name", obj.name, "dice", obj.dice);
            json_txt = jsonencode(s);
        end

        % =============================================
        %       ThingSpeak
        % =============================================
        function updateRound(obj, roundPoints)
            arr = obj.getNewServerArr(obj.ID, roundPoints);
            thingSpeakWrite(obj.CHANNEL_ID, arr, 'WriteKey', obj.WRITE_KEY);
            pause(obj.delay);
        end

        function updateGlobalScore(obj, score)
            arr = obj.getNewServerArr(obj.ID + 2, score);
            thingSpeakWrite(obj.CHANNEL_ID, arr, 'WriteKey', obj.WRITE_KEY);
            pause(obj.delay);
            % pause(obj.delay);
            % thingSpeakWrite(obj.CHANNEL_ID, 'Field', obj.ID+2, 'Values', score, 'WriteKey', obj.WRITE_KEY);
        end

        function updateStatus(obj, status)
            arr = obj.getNewServerArr(obj.ID + 4, status);
            pause(obj.delay);
            thingSpeakWrite(obj.CHANNEL_ID, arr, 'WriteKey', obj.WRITE_KEY);
            pause(obj.delay);
            %     pause(obj.delay);
            %     thingSpeakWrite(obj.CHANNEL_ID, 'Field', obj.ID+4, 'Values', status, 'WriteKey', obj.WRITE_KEY);
        end

        function initServer(obj)
            thingSpeakWrite(obj.CHANNEL_ID, {0, 0, 0, 0, 0, 0}, 'WriteKey', obj.WRITE_KEY);
            pause(obj.delay);
        end

        function otherPlayerRoundPoint = getOtherPlayerRoundPoint(obj)
            % pause(obj.delay);
            otherPlayerRoundPoint = 0;
            readStatus = thingSpeakRead(obj.CHANNEL_ID, 'ReadKey', obj.READ_KEY, 'OutputFormat', 'timetable');

            switch obj.ID
                case 1
                    otherPlayerRoundPoint = readStatus.player2Round;
                case 2
                    otherPlayerRoundPoint = readStatus.player1Round;
            end

            % pause(obj.delay);
        end

        function otherPlayerScore = getOtherPlayerScore(obj)
            % pause(obj.delay);
            otherPlayerScore = 0;
            readStatus = thingSpeakRead(obj.CHANNEL_ID, 'ReadKey', obj.READ_KEY, 'OutputFormat', 'timetable');

            switch obj.ID
                case 1
                    otherPlayerScore = readStatus.player2Global;
                case 2
                    otherPlayerScore = readStatus.player1Global;
            end

            % pause(obj.delay);
        end

        function serverStatus = getServerStatus(obj)
            % pause(obj.delay);
            serverStatus = thingSpeakRead(obj.CHANNEL_ID, 'ReadKey', obj.READ_KEY, 'OutputFormat', 'timetable');
            % pause(obj.delay);
        end

        function cellarr = getNewServerArr(obj, index, newValue)
            % pause(obj.delay);
            serverStatus = thingSpeakRead(obj.CHANNEL_ID, 'ReadKey', obj.READ_KEY, 'OutputFormat', 'table');
            arr = [
                serverStatus.player1Round
                serverStatus.player2Round
                serverStatus.player1Global
                serverStatus.player2Global
                serverStatus.player1Status
                serverStatus.player2Status
                ];
            arr(index) = newValue;
            cellarr = {
                    arr(1), ...
                        arr(2), ...
                        arr(3), ...
                        arr(4), ...
                        arr(5), ...
                        arr(6)
                    };
            % pause(obj.delay);
        end

        function waitForOtherPlayer(obj)
            readStatus = thingSpeakRead(obj.CHANNEL_ID, 'ReadKey', obj.READ_KEY, 'OutputFormat', 'timetable');

            while ~(readStatus.player1Status == 1 && readStatus.player2Status == 1)
                % pause(obj.delay);
                readStatus = thingSpeakRead(obj.CHANNEL_ID, 'ReadKey', obj.READ_KEY, 'OutputFormat', 'timetable');
                disp("--------- Waiting ------------"); % for testing
                disp(readStatus.player1Status);
                disp(readStatus.player2Status);
                disp("------------------------------");
            end

        end

    end

end
