## Stock-Database
<img src="https://d1.awsstatic.com/logos/partners/microsoft/logo-SQLServer-vert.c0cb0df0cd1d6c8469d792abb5929239da36611a.png" width="233" height="190">

```diff 
- Stock Demo 備份檔因儲存在Git LFS必須進入檔案頁面下載, 直接download zip內容是空的 
```
[https://github.com/hanyang0721/Stock-Database/blob/master/StockDemo.bak](https://github.com/hanyang0721/Stock-Database/blob/master/StockDemo.bak)
### 功能提供
報價, 下單, 回測所用的資料庫. 大部分程式run的query都已SP的方式儲存在資料庫\
\
回測\
dbo.sp_GetMDD 回傳策略最大DD\
view GetMonthlyPerformanceDetails\
view GetMonthlyPerformanceSum\
\
報價\
驗證資料須用群益超級贏家裡的技術分析資料, 因元大K線使用的是後歸法, OHLC與volume都不會一致. 可自行改寫\
\
dbo.sp_GetTickData(使用前歸法)\
dbo.sp_GetTickInHour(尚未驗證正確性)\
dbo.sp_GetTicksDaily 回傳日K OHLC\
dbo.sp_GetTicksIn5Min 回傳五分K OHLC\
\
其他\
dbo.sp_RestartSKOrder 重啟下單程式\
dbo.sp_GetNotifyOrders Line reply下單通知\
dbo.dbo.sp_ChkLatest_KLine 每日檢查是否日K, 分K都是最新的\
dbo.dbo.ChkTick 確保Tick都是最新的

### 設定步驟
避免Tick報價程式在盤中出錯, 設定agent job每隔一段時間執行dbo.ChkTick, 確保資料一直都有進來


提供兩種模式還原

1. **bak檔還原**\
   必須是SQL Server 2016版本, 目前使用版本13.0.4001.0. Bak檔已包含分K, 日K從2000年的歷史資料. 可直接執行

2. **Script檔還原**\
   這不包含任何台指期歷史資料, 需用報價程式導入, 或手動導入歷史資料. 群益報價僅提供約1~2個月的日K
