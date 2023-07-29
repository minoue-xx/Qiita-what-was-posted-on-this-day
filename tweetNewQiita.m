% アクセストークン使用
accessToken = getenv('QIITAACCESSTOKEN');
opts = weboptions('HeaderFields',{'Authorization',accessToken});

% ここから新着記事のチェック（最新20個取ればOKでしょう・・）
url = "https://qiita.com/api/v2/tags/matlab/items?page=1&per_page=20";
tmp = webread(url,opts);
url = "https://qiita.com/api/v2/tags/simulink/items?page=1&per_page=20";
tmp = [tmp; webread(url,opts)]; % Simulink もついでに


% 投稿時刻をチェック（TimeZone は日本時間に設定）
created_at = datetime(vertcat(tmp.created_at),...
    'InputFormat', "uuuu-MM-dd'T'HH:mm:ss'+09:00",'TimeZone','Asia/Tokyo');
titles = string({tmp.title}');
urls = string({tmp.url}');
userids = string(struct2table([tmp.user]).id);

twitterids = strings(length(tmp),1);
ttmp = struct2table([tmp.user]).twitter_screen_name;
idx = cellfun(@(x) ~isempty(x), ttmp);
twitterids(idx) = string(ttmp(idx));
idx = strlength(twitterids) > 0;
twitterids(idx) = "(@" + twitterids(idx) + ")";

item_list = timetable(titles, urls, userids, twitterids, 'RowTimes', created_at,...
    'VariableNames',{'titles', 'urls', 'userids', 'twitterids'});

%%
% 新着かどうかのチェック
% このスクリプトは 2時間に1回実行する設定にします。（GitHub Action 設定）
% なので、、現時刻から2時間以内に投稿されていればそれは新着記事とします。
interval = duration(2,0,0);
tnow = datetime;
% GitHub Actions が動いているところでは TimeZone が UTC であるところに注意
tnow.TimeZone = 'UTC'; 
trange = timerange(tnow-interval,tnow) % 過去2時間以内の投稿だけを抽出
newitem_list = item_list(trange,:);

tweetFlag = true;
% 新着の数だけ呟きます（無ければ呟かない）
N = height(newitem_list);
for ii=1:N
    
    % 投稿文
    status = "#Qiita #MATLAB #Simulink" + newline;
    status = status + newitem_list.titles(ii);
    status = status + " by " + newitem_list.userids(ii) + " さん " ...
        + newitem_list.twitterids(ii) + newline;
    status = status + newitem_list.urls(ii);
    
    disp(status);
    
    if tweetFlag
        try
            disp("Tweeting " + ii + "/" + N + "...");
            py.tweetQiita.tweetV2(status)
        catch ME
            disp(ME)
        end
    end
end