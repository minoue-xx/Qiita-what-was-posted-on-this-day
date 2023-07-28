% Run on 1st of Jan every year to make a list of all the contents with MATLAB/Simulink tag
% Check getAllQiitaArticles.yml
% Copyright (c) 2022 Michio Inoue.

% Use Qiita API to extract articles
loadFlag = true;
if loadFlag
    % accessToken = 'Bearer xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
    accessToken = getenv('QIITAACCESSTOKEN');
    opts = weboptions('HeaderFields',{'Authorization',accessToken});

    page = 1;
    data = [];
    tags = ["matlab","simulink"];
    for ii=1:length(tags)
        page = 1;
        while true
            url = "https://qiita.com/api/v2/tags/" + tags(ii) + "/items?page="+page+"&per_page=100";
            tmp = webread(url,opts);
            if isempty(tmp)
                break;
            end
            data = [data;tmp]; %#ok<AGROW>
            page = page + 1;
        end
    end
    data = struct2table(data);
    [~,ia,~] = unique(data.id);
    data = data(ia,:);
    %     save('allArticles.mat','data')
else
    load allArticles.mat %#ok<UNRCH>
end


%% Convert date types to timetable
% Qiita is on Tokyo Time
created_at = datetime(vertcat(data.created_at),...
    'InputFormat', "uuuu-MM-dd'T'HH:mm:ss'+09:00",'TimeZone','Asia/Tokyo');
% Change that to UTC
created_at.TimeZone = 'UTC';
% Keep some of the data
tData = table2timetable(data(:,{'title','user','likes_count','tags','url'}),'RowTimes', created_at);

%% convert url (char), users (struct), and tags (struct) to string
tData.url = string(tData.url);
tData.twitterID = rowfun(@(x) getTwitterID(x),tData,'InputVariable','user','ExtractCellContents',true,'OutputFormat','uniform');
tData.user = rowfun(@(x) string(x.id),tData,'InputVariable','user','ExtractCellContents',true,'OutputFormat','uniform');
tData.tags = rowfun(@(x) string({x.name}),tData,'InputVariable','tags','ExtractCellContents',true,'SeparateInputs',true,'OutputFormat','cell');

%% get the month/day of when the post is created
[y,m,d] = ymd(tData.Time);
daysofYear = tData.Time - calyears(y);
% How old the posts are
tData.howOld = year(datetime) - y;

% sort by the days of the year
[~,idx] = sort(daysofYear,'ascend');
tData = tData(idx,:);

% generate another timetable with the daysofYear as time variable
t = table2timetable(timetable2table(tData),'RowTimes',daysofYear(idx));

% check data
head(t)

nYear = year(datetime);
writetimetable(t,"onThisDayQiita" + nYear + ".csv");


%%
function twitterID = getTwitterID(x)

if isempty(x.twitter_screen_name)
    twitterID = "";
else
    twitterID = string(x.twitter_screen_name);
end

end