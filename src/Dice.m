% Ethan He

classdef Dice
    properties (Access = private)
        frontFace;   % int 1-6
    end

    methods (Access = public)
        function obj = Dice(frontFace_arg)
            switch nargin
            case 0
                obj.frontFace = randi([1,6], 1, 1);
            case 1
                obj.frontFace = frontFace_arg;
            end
        end

        function obj = setFront(obj, newFront)
            obj.frontFace = newFront;
        end

        function front = getFront(obj)
            front = obj.frontFace;
        end

        function obj = roll(obj)
            obj.frontFace = randi([1,6], 1, 1);
        end

        % =============================================
        %       JSON factions
        % =============================================
        function json_txt = dumpJ(obj)
            s = struct("frontFace", obj.frontFace);
            json_txt = jsonencode(s);
        end

    end
end