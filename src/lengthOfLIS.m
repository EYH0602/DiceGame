% Ethan He

function maxres = lengthOfLIS(nums)
    %% * calculate the points of a given array
    % Input:
    %   nums: integer array
    % Output: 
    %   maxres: points get based on this array

    %% ! =================================== IDEA =============================================
    % Given an integer array nums,
    %   return the length of the longest strictly increasing subsequence.
    % A **subsequence** is a sequence that can be derived from an array 
    %   by deleting some or no elements without changing the order of  the remaining elements. 
    % For example, [3,6,2,7] is a subsequence of the array [0,3,1,6,2,2,7].
    %% ! =======================================================================================

    % there must be a longest at lest at len 1
    % let dp[i] denotes the the length of longest subsequence ending at the ith element.
    % dp[i] = max(dp[before i]) + 1.

    n = length(nums);
    dp = ones(1,n);
    
    % dp
    for i = 1:n
        for j = 1:i-1
            if nums(j) < nums(i)
                dp(i) = max([dp(i), dp(j) + 1]);
            end
        end
    end

    maxres = max(dp);
end