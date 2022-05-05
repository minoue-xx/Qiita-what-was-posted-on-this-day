% Run on 4 hours interval to make tweet the articles 
% that were posted during the same time period in the previous years.
% Check tweetOnThisDayPost.yml
% Copyright (c) 2022 Michio Inoue.

% Load the list into timetable (make sure if it was generated)
nYear = year(datetime);

try
    data = readtimetable("onThisDayQiita" + nYear + ".csv");
catch ME
    disp("There is an issue with onThisDayQiita" + nYear + ".csv")
    disp("Please run getAllQiitaArticles.m to regenerate the file.")
    disp("This program ends here.")
    rethrow(ME)
end

data.twitterID = string(data.twitterID);

% Check the item with more than 2 likes and posted in the previous years.
idx2 = data.likes_count > 2 & data.howOld > 0;
data2 = data(idx2,:);

%% 
% This script runs on 4 hours interval.
% Extract the articles within the range.

% Shift datetimes back to hour (GitHub Actions does not start at the top of
% the hour. Assume it does not delay more than an hour.
tnow = dateshift(datetime,'start','hour');
t1 = tnow - calyears(year(datetime));
trange = timerange(t1, t1+hours(4));
subdata = data2(trange,:);

% Generate twitter ID to mantion on Twitter 
idxTwitterTrue = strlength(subdata.twitterID) > 0;
subdata.twitterID(idxTwitterTrue) = "(@" + subdata.twitterID(idxTwitterTrue) + ")";

% A function to generate a tweet
string2tweet = @(howOld, user, url, twitterID) ...
"["+string(howOld)+"年前の投稿] #qiita #matlab #simulink #onthisday" + newline ...
+ "by " + user + " さん " + twitterID + newline ...
+ url;


%% ThingTweet set-up
tturl='https://api.thingspeak.com/apps/thingtweet/1/statuses/update';
api_key = getenv('THINGTWEETAPIKEY');
options = weboptions('MediaType','application/x-www-form-urlencoded');
options.Timeout = 10;

%% Tweet if any with in the time period
tweetFlag = false;
N = height(subdata);
for ii=1:N
    str = string2tweet(subdata.howOld(ii), subdata.user(ii), ...
        subdata.url(ii), subdata.twitterID(ii));
    
    % Display Tweet sentense
    disp(str);
    
    if tweetFlag
        try
            webwrite(tturl, 'api_key', api_key, 'status', str, options);
        catch ME
            disp(ME)
        end
    end
end
