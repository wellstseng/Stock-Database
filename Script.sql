USE [Stock_Demo]
GO
/****** Object:  UserDefinedFunction [dbo].[PtrValue]    Script Date: 9/26/2019 00:32:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[PtrValue]
(
	@ptr int
)
RETURNS float
AS
BEGIN
	RETURN (SELECT nClose FROM TickData WHERE Ptr=@ptr)

END
GO
/****** Object:  UserDefinedFunction [dbo].[GetTicksHour]    Script Date: 9/26/2019 00:32:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE function [dbo].[GetTicksHour](
@from date,
@to date,
@stockID varchar(8)
)
RETURNS TABLE AS RETURN

WITH CTE AS (
	SELECT (CAST([sdate] AS DATE)) [sdate], 
	CAST(CASE WHEN SUBSTRING(stime,5,2)>=46 THEN SUBSTRING(stime,2,2)+1 ELSE SUBSTRING(stime,2,2) END as varchar)+':45'stime2,
	CONVERT(DECIMAL(8,2), [open]/100) [open] , 
	CONVERT(DECIMAL(8,2), [highest]/100) [highest],
	CONVERT(DECIMAL(8,2), [lowest]/100) [lowest], 
	CONVERT(DECIMAL(8,2), [close]/100) [close], [vol] ,
	RANK() OVER (partition by CONVERT(varchar, (cast([sdate] as date))) +' ' + cast(CASE WHEN SUBSTRING(stime,5,2)>=46 THEN SUBSTRING(stime,2,2)+1 ELSE SUBSTRING(stime,2,2) END as varchar)+':45'  ORDER BY CAST([sdate] AS DATE), stime) [Rank]
	FROM  Stock..StockHisotryMin WHERE [sdate] BETWEEN @from AND @to

), CTE2 AS (
	SELECT S.stime2, 
	CASE WHEN [Rank]=1 THEN [open] ELSE 0 END [open], highest, lowest,
	CASE WHEN [Rank]=RK THEN [close] ELSE 0 END [close] , vol, T.RK 
	FROM CTE S INNER JOIN  (SELECT stime2, MAX([Rank] ) RK FROM CTE GROUP BY stime2) T ON S.stime2=T.stime2
)

SELECT  CAST(stime2 AS datetime) stime2, 
		MAX([open]) [open], 
		MAX(highest) highest, 
		MIN(lowest) lowest,
		MAX([close]) [close], 
		SUM(vol) vol FROM CTE2
WHERE CAST(stime2 as time) Between '00:45:00' AND '13:45:00'
GROUP BY stime2



GO
/****** Object:  UserDefinedFunction [dbo].[GetTicksIn5Min]    Script Date: 9/26/2019 00:32:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE function [dbo].[GetTicksIn5Min](
@from date,
@to date,
@stockID varchar(8)
)
RETURNS TABLE AS RETURN

WITH CTE AS (
	SELECT (CAST([sdate] AS DATE)) [sdate], 
	--(stime),LEFT(stime,4) + case when RIGHT(stime,1)<='5' then '0' else '5' END stimeround,
	CONVERT(varchar, (cast([sdate] as date))) +' ' + SUBSTRING(stime,2,4) + case when RIGHT(stime,1)<'5' then '0' else '5' END stime2,
	CONVERT(DECIMAL(8,2), [open]/100) [open] , 
	CONVERT(DECIMAL(8,2), [highest]/100) [highest],
	CONVERT(DECIMAL(8,2), [lowest]/100) [lowest], 
	CONVERT(DECIMAL(8,2), [close]/100) [close], [vol] ,
	RANK() OVER (partition by CONVERT(varchar, (cast([sdate] as date))) +' ' + SUBSTRING(stime,2,4) + CASE WHEN RIGHT(stime,1)<'5' then '0' else '5' END  ORDER BY CAST([sdate] AS DATE), stime) [Rank]
	FROM  Stock..StockHisotryMin WHERE stockNo=@stockID
	AND [sdate] BETWEEN @from AND @to

), CTE2 AS (
	SELECT S.stime2, 
	CASE WHEN [Rank]=1 THEN [open] ELSE 0 END [open], highest, lowest,
	CASE WHEN [Rank]=RK THEN [close] ELSE 0 END [close] , vol, T.RK 
	FROM CTE S INNER JOIN  (SELECT stime2, MAX([Rank] ) RK FROM CTE GROUP BY stime2) T ON S.stime2=T.stime2
)

SELECT  CAST(stime2 AS datetime) stime2, 
		MAX([open]) [open], 
		MAX(highest) highest, 
		MIN(lowest) lowest,
		MAX([close]) [close], 
		SUM(vol) vol FROM CTE2
WHERE CAST(stime2 as time) Between '08:45:00' AND '13:45:00'
GROUP BY stime2



GO
/****** Object:  UserDefinedFunction [dbo].[GetTodayTickAM]    Script Date: 9/26/2019 00:32:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[GetTodayTickAM]
(	
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT stockIdx,sdate, ' ' + LEFT(stime,5) AS stime ,  nOpen, High, Low, nClose, nQty AS vol FROM (
	SELECT stockIdx, SUBSTRING(LTRIM(Str(S.ndate)),5,2) +'/'+RIGHT(S.ndate,2)+'/'+ LEFT(S.ndate,4) AS sdate,
					   DATEADD(MINUTE, 1 ,DATEADD(hour, (Time2 / 100) % 100,
					   DATEADD(minute, (Time2 / 1) % 100, cast('00:00:00' as time(0)))))  AS stime,
       Max(nClose)                                                                AS High,
       Min(nClose)                                                                AS Low,
       dbo.Ptrvalue(Min(Ptr))                                                     AS nOpen,
       dbo.Ptrvalue(Max(Ptr))                                                     AS nClose,
       Sum(nQty)                                                                  AS nQty
	FROM   [Stock].[dbo].[TickData] X
    INNER JOIN (SELECT ndate, lTimehms / 100 AS Time2 FROM   [Stock].[dbo].[TickData] 
				GROUP  BY ndate,lTimehms / 100) S
                ON S.ndate = X.ndate AND S.Time2 = X.lTimehms / 100 --WHERE lTimehms <=104959
	GROUP  BY Time2, S.ndate, stockIdx) E
	WHERE  CAST(stime as time(0)) >= '08:45:00' AND CAST(stime as time(0)) <= '13:45:00' 
	--AND cast(sdate as date) = cast(GETDATE() as date) 
)
GO
/****** Object:  View [dbo].[GetCurrentOrder]    Script Date: 9/26/2019 00:32:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[GetCurrentOrder] AS

SELECT TOP 1 orderid,[stockNo] ,[TradeType], DayTrade ,
CASE WHEN [BuyOrSell]='buy' then 0 ELSE 1 END AS [BuyOrSell] ,[Size] FROM [Stock].[dbo].[Orders] 
                        
WHERE EntryDate BETWEEN DATEADD(SECOND,-10,GETDATE()) AND GETDATE()
GO
/****** Object:  View [dbo].[GetMonthlyPerformanceDetails]    Script Date: 9/26/2019 00:32:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/****** Script for SelectTopNRows command from SSMS  ******/
CREATE VIEW [dbo].[GetMonthlyPerformanceDetails] AS
	WITH CTE AS
	(
	  SELECT StrName,coalesce (FORMAT(selltime,'yyyyMM'), 'All Time') AS [Month], 
	  CASE WHEN TradeType=1 THEN
				CAST(SUM(buyprice-sellprice) AS numeric(8,2))
		   ELSE	
				CAST(SUM(sellprice-buyprice) AS numeric(8,2)) END  AS SumProfit, 
	  count(*) AS NumTrades, 
	  CASE WHEN TradeType=1 THEN
				CAST(SUM(buyprice-sellprice)/count(*) AS numeric(8,2)) 
		   ELSE
				CAST(SUM(sellprice-buyprice)/count(*) AS numeric(8,2)) END AS AvgProfit, TradeType
		
		
		,SUM(CASE WHEN TradeType=1 and buyprice-sellprice>0 THEN 1 END) AS ShortWins
		,SUM(CASE WHEN TradeType=0 and sellprice-buyprice>0 THEN 1 END) AS LongWins
	  FROM [Stock].[dbo].[StrategyPerformanceHis]
	  GROUP BY StrName, rollup( FORMAT(selltime,'yyyyMM')), TradeType
	
	),

	WORST_SumProfit AS
	(
		SELECT S.* FROM CTE S INNER JOIN (
		SELECT MIN(SumProfit) AS MinSumProfit  FROM CTE) X ON S.SumProfit=X.MinSumProfit
	),
	WORST_AvgProfit AS
	(
		SELECT S.* FROM CTE S INNER JOIN (
		SELECT MIN(AvgProfit) AS MinAvgProfit  FROM CTE) X ON S.AvgProfit=X.MinAvgProfit
	)

	SELECT StrName, [Month],'Normal' AS Type ,SumProfit, NumTrades, 
			CAST(AvgProfit as numeric(8,2)) AS AvgProfit,TradeType,ISNULL(ShortWins,0) AS ShortWins, ISNULl(CAST(CAST(ShortWins as float)/NumTrades as numeric(5,2)),0) AS ShortWinRate, 
			ISNULL(LongWins,0) AS LongWins, ISNULL(CAST(CAST(LongWins as float)/NumTrades as numeric(5,2)),0) AS LongWinRate FROM CTE
	UNION ALL
	SELECT StrName, [Month],'Worst Sum',  SumProfit, NumTrades, CAST(AvgProfit as numeric(8,2)),TradeType,ShortWins,ShortWins/NumTrades,
			LongWins, CAST(CAST(LongWins as float)/NumTrades as numeric(5,2)) AS LongWinRate FROM WORST_SumProfit
	UNION ALL
	SELECT StrName, [Month],'Worst Avg', SumProfit, NumTrades, CAST(AvgProfit as numeric(8,2)),TradeType,ShortWins,ShortWins/NumTrades,
			LongWins, CAST(CAST(LongWins as float)/NumTrades as numeric(5,2)) AS LongWinRate FROM WORST_AvgProfit
	UNION ALL
	SELECT StrName, LEFT([Month],4) AS [YEAR],'Yearly' AS Type , SUM(SumProfit),SUM(NumTrades) , CAST(SUM(SumProfit)/SUM(NumTrades) as numeric(8,2)),TradeType,
			SUM(ShortWins),CAST(CAST(SUM(ShortWins) as float)/SUM(NumTrades) AS numeric(8,2)) AS ShortWinRate, SUM(LongWins), CAST(CAST(SUM(LongWins) as float)/SUM(NumTrades) AS numeric(8,2)) AS LongWinRate FROM CTE
	GROUP BY StrName, LEFT([Month],4), TradeType
	

  
  

  

  
GO
/****** Object:  View [dbo].[GetMonthlyPerformanceSum]    Script Date: 9/26/2019 00:32:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/****** Script for SelectTopNRows command from SSMS  ******/

CREATE VIEW [dbo].[GetMonthlyPerformanceSum] AS
  SELECT  [StrName]
      ,[Month]
      ,[Type]
      ,SUM([SumProfit]) [SumProfit]
      ,SUM([NumTrades]) [NumTrades]
      ,CAST(SUM([SumProfit])/SUM([NumTrades]) as numeric(8,2)) [AvgProfit]
  FROM [Stock].[dbo].[GetMonthlyPerformanceDetails]
  WHERE Type IN ('All Time','Normal', 'Yearly')
  GROUP BY [StrName], [Month] ,[Type]
  
 
GO
/****** Object:  View [dbo].[StrPerformanceView]    Script Date: 9/26/2019 00:32:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE view [dbo].[StrPerformanceView] AS
SELECT 
	   DATEPART(YEAR, selltime ) AS sYear, 
	   DATEPART(MONTH, selltime ) AS sMonth,
	   cast(buytime as datetime2(0)) AS Buytime, 
	   cast(selltime as datetime2(0)) AS SellTime,
	   buyprice, sellprice, TradeType, case when TradeType=0 then sellprice-buyprice else buyprice-sellprice end AS Profit   FROM [Stock].[dbo].[StrategyPerformanceHis]
GO
/****** Object:  View [dbo].[View_BuyTimeAnalysis]    Script Date: 9/26/2019 00:32:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/****** Script for SelectTopNRows command from SSMS  ******/

CREATE VIEW [dbo].[View_BuyTimeAnalysis] AS

WITH CTE_MA (MarketDate, ClosingPrice, RowNumber,CloseMA5, CloseMA10, CloseMA30, VolMA5, VolMA10, VolMA30)
AS
(
SELECT stime2,
sclose,
ROW_NUMBER() OVER (ORDER BY stime2 ASC) RowNumber,
AVG(sclose) OVER (ORDER BY stime2 ASC ROWS 4 PRECEDING) AS CloseMA5,
AVG(sclose) OVER (ORDER BY stime2 ASC ROWS 9 PRECEDING) AS CloseMA10,
AVG(sclose) OVER (ORDER BY stime2 ASC ROWS 29 PRECEDING) AS CloseMA30,
AVG(svol) OVER (ORDER BY stime2 ASC ROWS 4 PRECEDING) AS VolMA5,
AVG(svol) OVER (ORDER BY stime2 ASC ROWS 9 PRECEDING) AS VolMA10,
AVG(svol) OVER (ORDER BY stime2 ASC ROWS 29 PRECEDING) AS VolMA30
FROM Stock..TempTicksIn5Min
)

SELECT  FORMAT(V.stime2,'yyyy-MM-dd HH:mm') stime2, 
		CAST(V.shigh as int) sHigh, 
		CAST(V.slowest as int) sLow,
		CAST(V.sopen as int) sOpen, 
		CAST(V.sclose as int) sClose,
		V.svol,
		sclose-sopen AS TickDiff,
		CAST(X.CloseMA5 as int) CloseMA5, 
		CAST(X.CloseMA10 as int) CloseMA10, 
		CAST(X.CloseMA30 as int) CloseMA30, 
		CAST(X.VolMA5 as int) VolMA5, 
		CAST(X.VolMA10 as int) VolMA10, 
		CAST(X.VolMA30 as int) VolMA30,
		FORMAT(S.selltime,'yyyy-MM-dd HH:mm') selltime, 
		S.buyprice, S.sellprice, S.TradeType, 
		CASE WHEN TradeType=1 THEN buyprice-sellprice
			 ELSE sellprice-buyprice END AS Profit, 
		DATEDIFF(DAY,stime2,selltime) AS TradeDays
		,PreClose
		,CASE WHEN PreClose IS NOT NULL AND abs(PreClose-sopen)>=120 THEN 'Gap' ELSE NULL END AS IsGap
		,PreClose-sopen AS GapSpan
FROM [Stock].[dbo].[TempTicksIn5Min] V LEFT JOIN  (SELECT [buytime] ,[selltime] ,[buyprice] ,[sellprice] ,[TradeType] FROM [Stock].[dbo].[StrategyPerformanceHis]) S ON V.stime2=S.buytime
LEFT JOIN (SELECT LAG([Close]/100,1,0) OVER (ORDER BY CAST(sdate as date) ) AS PreClose, sdate FROM Stock..StockHistoryDaily) D  ON  cast(sdate as date)=CAST(V.stime2 as date) AND FORMAT(stime2,'HH:mm')='08:45'
LEFT JOIN (SELECT 
MarketDate,
--RowNumber,
--ClosingPrice,
IIF(RowNumber > 4, CloseMA5, NULL) CloseMA5,
IIF(RowNumber > 9, CloseMA10, NULL) CloseMA10,
IIF(RowNumber > 29, CloseMA30, NULL) CloseMA30,
IIF(RowNumber > 4, VolMA5, NULL) VolMA5,
IIF(RowNumber > 9, VolMA10, NULL) VolMA10,
IIF(RowNumber > 29, VolMA30, NULL) VolMA30
--CASE WHEN RowNumber > 29 AND MA10 > MA30 THEN 'Over'
--	 WHEN RowNumber > 29 AND MA10 < MA30 THEN 'Below' ELSE NULL END as TradeSignal
FROM CTE_MA) X ON V.stime2=X.MarketDate






  
GO
/****** Object:  Table [dbo].[ATM_DailyLog]    Script Date: 9/26/2019 00:32:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ATM_DailyLog](
	[ExecTime] [datetime] NULL,
	[Steps] [varchar](128) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ATM_Enviroment]    Script Date: 9/26/2019 00:32:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ATM_Enviroment](
	[Parameter] [varchar](64) NULL,
	[value] [varchar](64) NULL,
	[EntryDate] [datetime] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[LineNotifyLog]    Script Date: 9/26/2019 00:32:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LineNotifyLog](
	[orderid] [int] NOT NULL,
	[stockNo] [varchar](10) NOT NULL,
	[SignalTime] [smalldatetime] NOT NULL,
	[BuyOrSell] [varchar](4) NOT NULL,
	[Price] [float] NULL,
	[Size] [int] NULL,
	[NotifyTime] [datetime] NULL,
	[Result] [varchar](1) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Orders]    Script Date: 9/26/2019 00:32:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Orders](
	[orderid] [int] IDENTITY(1,1) NOT NULL,
	[stockNo] [varchar](10) NOT NULL,
	[SignalTime] [smalldatetime] NOT NULL,
	[BuyOrSell] [varchar](4) NOT NULL,
	[Size] [int] NOT NULL,
	[Price] [float] NULL,
	[DayTrade] [int] NULL,
	[Result] [varchar](12) NULL,
	[EntryDate] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[SignalTime] ASC,
	[BuyOrSell] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[StockHisotryMin]    Script Date: 9/26/2019 00:32:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[StockHisotryMin](
	[stockNo] [varchar](10) NOT NULL,
	[sdate] [varchar](10) NOT NULL,
	[stime] [varchar](6) NOT NULL,
	[open] [float] NULL,
	[highest] [float] NULL,
	[lowest] [float] NULL,
	[Close] [float] NULL,
	[vol] [float] NULL,
	[EntryDate] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[sdate] ASC,
	[stime] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[StockHistoryDaily]    Script Date: 9/26/2019 00:32:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[StockHistoryDaily](
	[stockNo] [varchar](10) NOT NULL,
	[sdate] [varchar](16) NOT NULL,
	[open] [float] NOT NULL,
	[highest] [float] NOT NULL,
	[lowest] [float] NOT NULL,
	[Close] [float] NOT NULL,
	[vol] [float] NOT NULL,
	[EntryDate] [datetime] NULL,
 CONSTRAINT [PK__StockHis__C90EA5065E5826F7] PRIMARY KEY CLUSTERED 
(
	[stockNo] ASC,
	[sdate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[StockList]    Script Date: 9/26/2019 00:32:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[StockList](
	[StockNo] [varchar](12) NOT NULL,
	[StockName] [nvarchar](32) NULL,
	[PageNo] [int] NULL,
	[EntryDate] [datetime] NULL,
 CONSTRAINT [PK__StockLis__2C8517D17188EC79] PRIMARY KEY CLUSTERED 
(
	[StockNo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[StockQuoteDetails]    Script Date: 9/26/2019 00:32:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[StockQuoteDetails](
	[m_sStockidx] [int] NULL,
	[m_sDecimal] [float] NULL,
	[m_sTypeNo] [int] NULL,
	[m_cMarketNo] [int] NULL,
	[m_caStockNo] [int] NULL,
	[m_caName] [varchar](50) NULL,
	[m_nOpen] [float] NULL,
	[m_nHigh] [float] NULL,
	[m_nLow] [float] NULL,
	[m_nClose] [float] NULL,
	[m_nTickQty] [int] NULL,
	[m_nRef] [float] NULL,
	[m_nBid] [float] NULL,
	[m_nBc] [int] NULL,
	[m_nAsk] [float] NULL,
	[m_nAc] [int] NULL,
	[m_nTBc] [int] NULL,
	[m_nTAc] [int] NULL,
	[m_nTQty] [int] NULL,
	[m_nYQty] [int] NULL,
	[m_nUp] [float] NULL,
	[m_nDown] [float] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[StrategyPerformanceHis]    Script Date: 9/26/2019 00:32:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[StrategyPerformanceHis](
	[StrName] [varchar](32) NOT NULL,
	[buytime] [datetime] NULL,
	[selltime] [datetime] NULL,
	[buyprice] [float] NULL,
	[sellprice] [float] NULL,
	[TradeType] [int] NULL,
	[Entrydate] [datetime] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TickData]    Script Date: 9/26/2019 00:32:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TickData](
	[stockIdx] [varchar](16) NOT NULL,
	[Ptr] [int] NOT NULL,
	[ndate] [int] NULL,
	[lTimehms] [int] NULL,
	[lTimeMS] [int] NULL,
	[nBid] [float] NULL,
	[nAsk] [float] NULL,
	[nClose] [float] NULL,
	[nQty] [int] NULL,
	[Source] [varchar](8) NULL,
	[EntryDate] [datetime] NULL,
 CONSTRAINT [PK_TickData] PRIMARY KEY CLUSTERED 
(
	[Ptr] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TickData_bak]    Script Date: 9/26/2019 00:32:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TickData_bak](
	[stockIdx] [varchar](16) NOT NULL,
	[Ptr] [int] NOT NULL,
	[ndate] [int] NOT NULL,
	[lTimehms] [int] NULL,
	[lTimeMS] [int] NULL,
	[nBid] [float] NULL,
	[nAsk] [float] NULL,
	[nClose] [float] NULL,
	[nQty] [int] NULL,
	[Source] [varchar](8) NULL,
	[EntryDate] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[ndate] ASC,
	[Ptr] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ATM_DailyLog] ADD  CONSTRAINT [DF__ATM_Daily__ExecT__625A9A57]  DEFAULT (getdate()) FOR [ExecTime]
GO
ALTER TABLE [dbo].[ATM_Enviroment] ADD  DEFAULT (getdate()) FOR [EntryDate]
GO
ALTER TABLE [dbo].[Orders] ADD  CONSTRAINT [DF__Orders__EntryDat__76969D2E]  DEFAULT (getdate()) FOR [EntryDate]
GO
ALTER TABLE [dbo].[StockHisotryMin] ADD  CONSTRAINT [dfxx1]  DEFAULT (getdate()) FOR [EntryDate]
GO
ALTER TABLE [dbo].[StockHistoryDaily] ADD  CONSTRAINT [DF__StockHist__Entry__5DCAEF64]  DEFAULT (getdate()) FOR [EntryDate]
GO
ALTER TABLE [dbo].[StockList] ADD  CONSTRAINT [DF__StockList__Entry__5535A963]  DEFAULT (getdate()) FOR [EntryDate]
GO
ALTER TABLE [dbo].[StrategyPerformanceHis] ADD  DEFAULT (getdate()) FOR [Entrydate]
GO
ALTER TABLE [dbo].[TickData] ADD  DEFAULT (getdate()) FOR [EntryDate]
GO
/****** Object:  StoredProcedure [dbo].[ChkTick]    Script Date: 9/26/2019 00:32:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[ChkTick] AS

BEGIN

IF EXISTS (SELECT 1 FROM dbo.TickData WITH (NOLOCK) HAVING ISNULL(MAX(EntryDate),0) < DATEADD(MINUTE, -1,GETDATE()))
BEGIN
    EXEC xp_cmdshell 'powershell.exe ""E:\stopprocess.ps1""  '
    EXEC xp_cmdshell 'powershell.exe Start-Process -FilePath ""C:\Users\HY\Dropbox\SKQuotes\obj\Debug\SKQuote.exe"" '
END



END
GO
/****** Object:  StoredProcedure [dbo].[sp_BakupTick]    Script Date: 9/26/2019 00:32:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Script for SelectTopNRows command from SSMS  ******/

CREATE PROCEDURE [dbo].[sp_BakupTick] AS
INSERT INTO  [Stock].[dbo].[TickData_bak]
SELECT *
  FROM [Stock].[dbo].[TickData]
  WHERE lTimehms between 84500 and 134500 
GO
/****** Object:  StoredProcedure [dbo].[sp_ChkLatest_KLine]    Script Date: 9/26/2019 00:32:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[sp_ChkLatest_KLine] 
@Chktype int = 0
AS 
BEGIN

DECLARE @exists int
SET @exists=1

IF @Chktype=0 --- Check daily k bar
BEGIN
	IF EXISTS(SELECT 1 FROM Stock..StockHistoryDaily HAVING MAX(CAST(sdate as DATE))=(SELECT CAST(DATEADD(DAY, CASE DATENAME(WEEKDAY, GETDATE())  WHEN 'Sunday' THEN -2  WHEN 'Monday' THEN -3 
																					  ELSE -1 END, DATEDIFF(DAY, 0, GETDATE())) AS DATE)))
	BEGIN
		SET @exists=0	
	END
END
ELSE --- Check minute k bar
BEGIN
	IF EXISTS(SELECT 1 FROM Stock..StockHisotryMin HAVING MAX(CAST(sdate as DATE))=(SELECT CAST(DATEADD(DAY, CASE DATENAME(WEEKDAY, GETDATE())  WHEN 'Sunday' THEN -2  WHEN 'Monday' THEN -3 
																					  ELSE -1 END, DATEDIFF(DAY, 0, GETDATE())) AS DATE)))
	BEGIN
		SET @exists=0	
	END
END

SELECT @exists
END
		



GO
/****** Object:  StoredProcedure [dbo].[sp_GetMDD]    Script Date: 9/26/2019 00:32:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Script for SelectTopNRows command from SSMS  ******/


CREATE PROCEDURE [dbo].[sp_GetMDD] 
@Function int=0 
AS

DECLARE @MDD float, @sYear int, @sMonth int, @TradeType int, @Profit int, @MAX int, @buytime datetime, @selltime datetime
DECLARE cur cursor for 
SELECT sYear, sMonth, TradeType, Profit, Buytime, SellTime
  FROM [Stock].[dbo].[StrPerformanceView]
  ORDER BY Buytime

SELECT @MDD=0, @MAX=0

OPEN cur

FETCH NEXT FROM cur INTO @sYear, @sMonth, @TradeType, @Profit, @buytime, @selltime

WHILE @@FETCH_STATUS=0
BEGIN
	IF @Profit<=1
		SET @MDD = @MDD + abs(@Profit)
		IF @Function=1
			PRINT 'Buy: ' + CAST(@buytime as varchar) + '   Sell: ' + CAST(@selltime as varchar) + '  TradeType: ' +CASt(@TradeType as varchar) + ' MDD: ' + CAST(@MDD As varchar)
		
		IF @MDD > @MAX 
		BEGIN
			SET @MAX = @MDD
		END
	ELSE
		SET @MDD=0
	
	FETCH NEXT FROM cur INTO @sYear, @sMonth, @TradeType, @Profit, @buytime, @selltime
END

CLOSE cur
DEALLOCATE cur 

PRINT 'MDD:' +  CAST(@MAX as char(4))
GO
/****** Object:  StoredProcedure [dbo].[sp_GetNotifyOrders]    Script Date: 9/26/2019 00:32:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Script for SelectTopNRows command from SSMS  ******/

CREATE PROCEDURE [dbo].[sp_GetNotifyOrders] AS
BEGIN
	SET NOCOUNT ON

	INSERT INTO [Stock].[dbo].LineNotifyLog( [orderid] ,[stockNo] ,[SignalTime] ,[BuyOrSell] ,[Size] ,[Price])
	SELECT [orderid] ,[stockNo] ,[SignalTime] ,[BuyOrSell] ,[Size] ,[Price]
	FROM [Stock].[dbo].[Orders] X
	WHERE FORMAT(SignalTime,'yyyyMMdd')=FORMAT(GETDATE(),'yyyyMMdd') AND NOT EXISTS 
	(SELECT 1 FROM [Stock].[dbo].LineNotifyLog S WHERE S.[stockNo]=X.[stockNo] AND S.SignalTime=X.SignalTime AND S.BuyOrSell=X.BuyOrSell)

	SELECT [orderid] ,[stockNo] ,[SignalTime] ,[BuyOrSell] ,[Size] ,[Price] FROM LineNotifyLog
	WHERE FORMAT(SignalTime,'yyyyMMdd')=FORMAT(GETDATE(),'yyyyMMdd') AND Result IS NULL


 END
GO
/****** Object:  StoredProcedure [dbo].[sp_GetTickData]    Script Date: 9/26/2019 00:32:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Script for SelectTopNRows command from SSMS  ******/



CREATE PROCEDURE [dbo].[sp_GetTickData] As

--加一分鐘使用後歸法
SELECT DATEADD(MINUTE,1,Cast(Str(S.ndate) + ' '
            + LEFT(Replicate(0, 4-Len(Time2))+Ltrim(Str(Time2)), 2)
            + ':'
            + RIGHT(Replicate(0, 4-Len(Time2))+Ltrim(Str(Time2)), 2) AS DATETIME)) AS Time2,
       Max(nClose)                                                                AS High,
       Min(nClose)                                                                AS Low,
       dbo.Ptrvalue(Min(Ptr))                                                     AS nOpen,
       dbo.Ptrvalue(Max(Ptr))                                                     AS nClose,
       Sum(nQty)                                                                  AS nQty
FROM   [Stock].[dbo].[TickData] X
       INNER JOIN (SELECT ndate,
                          lTimehms / 100 AS Time2
                   FROM   [Stock].[dbo].[TickData]
                   GROUP  BY ndate,
                             lTimehms / 100) S
               ON S.ndate = X.ndate
                  AND S.Time2 = X.lTimehms / 100
GROUP  BY Time2,
          S.ndate
ORDER  BY Time2


--select cast('00:00' as time)
/*
SELECT ndate,lTimehms/100 , SUM(nQty)
FROM [Stock].[dbo].[TickData]
GROUP BY ndate,lTimehms/100
order by lTimehms/100
*/
GO
/****** Object:  StoredProcedure [dbo].[sp_GetTickInHour]    Script Date: 9/26/2019 00:32:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  UserDefinedFunction [dbo].[GetTicksIn5Min]    Script Date: 2019/6/26 下午 11:00:50 ******/

CREATE PROCEDURE [dbo].[sp_GetTickInHour] 
@from date,
@to date,
@stockID varchar(8)
AS
	SET NOCOUNT ON-----This make sp work like a query, prevent any insert rowcount returns
	
	-----------------------------------History minute data-------------------------------
	SELECT (CAST([sdate] AS DATE)) [sdate], 
	CONVERT(varchar, (cast([sdate] as date))) + ' ' + CAST(CASE WHEN SUBSTRING(stime,5,2)>=46 AND SUBSTRING(stime,2,2)<23 THEN SUBSTRING(stime,2,2)+1 
																WHEN SUBSTRING(stime,5,2)>=46 AND SUBSTRING(stime,2,2)=23 THEN '00'
																ELSE SUBSTRING(stime,2,2) END as varchar)+':45'stime2,
	CONVERT(DECIMAL(8,2), [open]/100) [open] , 
	CONVERT(DECIMAL(8,2), [highest]/100) [highest],
	CONVERT(DECIMAL(8,2), [lowest]/100) [lowest], 
	CONVERT(DECIMAL(8,2), [close]/100) [close], [vol] ,
	RANK() OVER (partition by CONVERT(varchar, (cast([sdate] as date))) +' ' + cast(CASE WHEN SUBSTRING(stime,5,2)>=46 
	THEN SUBSTRING(stime,2,2)+1 ELSE SUBSTRING(stime,2,2) END as varchar)+':45'  ORDER BY CAST([sdate] AS DATE), stime) [Rank] INTO #TEMP1
	FROM  Stock..StockHisotryMin WHERE CAST(sdate as date) BETWEEN @from AND @to

	-----------------------------------Tick data--------------------------------------
	
	IF NOT EXISTS(SELECT TOP 1 1 FROM StockHisotryMin WHERE cast(sdate as date) = (SELECT  MAX(cast(cast(ndate as varchar) as date))  FROM dbo.[TickData]))
	BEGIN
		INSERT INTO #TEMP1
		SELECT (CAST([sdate] AS DATE)) [sdate], 
		CONVERT(varchar, (cast([sdate] as date))) + ' ' + CAST(CASE WHEN SUBSTRING(stime,5,2)>=46 AND SUBSTRING(stime,2,2)<23 THEN SUBSTRING(stime,2,2)+1 
																	WHEN SUBSTRING(stime,5,2)>=46 AND SUBSTRING(stime,2,2)=23 THEN '00'
																	ELSE SUBSTRING(stime,2,2) END as varchar)+':45'stime2,
		CONVERT(DECIMAL(8,2), [nopen]/100) [open] , 
		CONVERT(DECIMAL(8,2), High/100) [High],
		CONVERT(DECIMAL(8,2), Low/100) [lowest], 
		CONVERT(DECIMAL(8,2), nClose/100) [close], [vol] ,
		RANK() OVER (partition by CONVERT(varchar, (cast([sdate] as date))) +' ' + cast(CASE WHEN SUBSTRING(stime,5,2)>=46 
		THEN SUBSTRING(stime,2,2)+1 ELSE SUBSTRING(stime,2,2) END as varchar)+':45'  ORDER BY CAST([sdate] AS DATE), stime) [Rank] 
		FROM  Stock..GetTodayTickAM()
	END
	------------use max to find open and close for the period
	SELECT stime2, MAX([Rank] ) RK INTO #TEMP2 FROM #TEMP1 GROUP BY stime2

	------------prepare index for later join
	create index idx on #TEMP1 (stime2) 
	create index idx on #TEMP2 (stime2) 

SELECT  CAST(stime2 AS datetime) stime2, 
		MAX([open]) [open], 
		MAX(highest) highest, 
		MIN(lowest) lowest,
		MAX([close]) [close], 
		SUM(vol) vol FROM (
	SELECT S.stime2, 
	CASE WHEN [Rank]=1 THEN [open] ELSE 0 END [open], highest, lowest,
	CASE WHEN [Rank]=RK THEN [close] ELSE 0 END [close] , vol, T.RK 
	FROM #TEMP1 S INNER JOIN #TEMP2 T ON S.stime2=T.stime2) E
--WHERE CAST(stime2 as time) Between '00:45:00' AND '13:45:00'
GROUP BY stime2
ORDER BY stime2



GO
/****** Object:  StoredProcedure [dbo].[sp_GetTicksDaily]    Script Date: 9/26/2019 00:32:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[sp_GetTicksDaily]
@from date,
@to date,
@stockID varchar(8)

AS
BEGIN

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @dtdaily date, @ticktime date
SELECT @dtdaily = MAX(CAST([sdate] as date)) FROM Stock.dbo.StockHistoryDaily
SELECT @ticktime = MAX(CONVERT(datetime,convert(char(8),ndate))) FROM Stock.dbo.TickData WHERE lTimehms BETWEEN 84500 AND 134500

--select FORMAT(@ticktime,'yyyyMMdd')

--DECLARE @testtime int 
--select @testtime=100955

IF @ticktime>@dtdaily
BEGIN
	DECLARE @tickopen float, @tickclose float, @tickhigh float, @ticklow float, @tickvol int
	SELECT @tickopen = nClose FROM Stock.dbo.TickData WHERE Ptr=(SELECT MIN(Ptr) FROM Stock.dbo.TickData WHERE ndate=FORMAT(@ticktime,'yyyyMMdd') AND lTimehms BETWEEN 84500 AND 134500)
	SELECT @tickclose = nClose FROM Stock.dbo.TickData WHERE Ptr=(SELECT MAX(Ptr) FROM Stock.dbo.TickData WHERE ndate=FORMAT(@ticktime,'yyyyMMdd') AND lTimehms BETWEEN 84500 AND 134500)
	SELECT @tickhigh = MAX(nClose) FROM Stock.dbo.TickData WHERE ndate=FORMAT(@ticktime,'yyyyMMdd') AND lTimehms BETWEEN 84500 AND 134500
	SELECT @ticklow = MIN(nClose) FROM Stock.dbo.TickData WHERE ndate=FORMAT(@ticktime,'yyyyMMdd') AND lTimehms BETWEEN 84500 AND 134500
	SELECT @tickvol = SUM(nQty) FROM Stock.dbo.TickData WHERE ndate=FORMAT(@ticktime,'yyyyMMdd') AND lTimehms BETWEEN 84500 AND 134500

	SELECT @ticktime AS [sdate] , CONVERT(DECIMAL(8,2), @tickopen/100), CONVERT(DECIMAL(8,2), @tickhigh/100), CONVERT(DECIMAL(8,2), @ticklow/100), CONVERT(DECIMAL(8,2), @tickclose/100), @tickvol
	UNION

	SELECT CAST([sdate] as date) AS [sdate],CONVERT(DECIMAL(8,2), [open]/100) , CONVERT(DECIMAL(8,2), [highest]/100)  ,CONVERT(DECIMAL(8,2), [lowest]/100),  
				CONVERT(DECIMAL(8,2), [close]/100), [vol] FROM Stock.dbo.StockHistoryDaily WHERE stockNo=@stockID AND CAST([sdate] as date) 
				 BETWEEN @from AND @to 
	ORDER BY [sdate] ASC
END

ELSE
BEGIN
	SELECT CAST([sdate] as date) AS [sdate],CONVERT(DECIMAL(8,2), [open]/100) , CONVERT(DECIMAL(8,2), [highest]/100)  ,CONVERT(DECIMAL(8,2), [lowest]/100),  
				CONVERT(DECIMAL(8,2), [close]/100), [vol] FROM Stock.dbo.StockHistoryDaily WHERE stockNo=@stockID AND CAST([sdate] as date) 
				 BETWEEN @from AND @to 
	ORDER BY [sdate] ASC
END
END
GO
/****** Object:  StoredProcedure [dbo].[sp_GetTicksIn5Min]    Script Date: 9/26/2019 00:32:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_GetTicksIn5Min] 
@from date,
@to date,
@stockID varchar(8)

AS
	SET NOCOUNT ON-----This make sp work like a query, prevent any insert rowcount returns
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @dtdaily date, @ticktime date
	SELECT @dtdaily = MAX(CAST([sdate] as date)) FROM Stock.dbo.StockHisotryMin
	SELECT @ticktime = MAX(CONVERT(datetime,convert(char(8),ndate))) FROM Stock.dbo.TickData

	SELECT (CAST([sdate] AS DATE)) [sdate], 
	--(stime),LEFT(stime,4) + case when RIGHT(stime,1)<='5' then '0' else '5' END stimeround,
	CAST(CAST([sdate] AS DATE) AS VARCHAR) + ' ' +
			LEFT(CASE WHEN RIGHT(stime,1)='0' THEN DATEADD(MINUTE,-5,cast(stime as time(0)))
			WHEN RIGHT(stime,1)>='1' AND RIGHT(stime,1)<='5'THEN DATEADD(MINUTE,-CAST(RIGHT(stime,1) as int),cast(stime as time(0)))
			WHEN RIGHT(stime,1)>='6' AND RIGHT(stime,1)<='9'THEN DATEADD(MINUTE,-(CAST(RIGHT(stime,1) as int)-5),cast(stime as time(0)))
			END,5) AS stime2 ,
	CONVERT(DECIMAL(8,2), [open]/100) [open] , 
	CONVERT(DECIMAL(8,2), [highest]/100) [highest],
	CONVERT(DECIMAL(8,2), [lowest]/100) [lowest], 
	CONVERT(DECIMAL(8,2), [close]/100) [close], [vol] ,
	RANK() OVER (partition by 
	CAST(CAST([sdate] AS DATE) AS VARCHAR) + ' ' +
			LEFT(CASE WHEN RIGHT(stime,1)='0' THEN DATEADD(MINUTE,-5,CAST(stime as time(0)))
			WHEN RIGHT(stime,1)>='1' AND RIGHT(stime,1)<='5'THEN DATEADD(MINUTE,-CAST(RIGHT(stime,1) as int),cast(stime as time(0)))
			WHEN RIGHT(stime,1)>='6' AND RIGHT(stime,1)<='9'THEN DATEADD(MINUTE,-(CAST(RIGHT(stime,1) as int)-5),cast(stime as time(0)))
			END,5) 
	ORDER BY CAST([sdate] AS DATE), stime) [Rank]
    INTO #TEMP1
	FROM  Stock..StockHisotryMin WHERE stockNo=@stockID
	AND [sdate] BETWEEN @from AND @to 

	--If tick data is greater than StockHistoryMin, then it's today
	IF @ticktime>@dtdaily
	BEGIN
		INSERT INTO #TEMP1
		SELECT (CAST([sdate] AS DATE)) [sdate], 
		CAST(CAST([sdate] AS DATE) AS VARCHAR) + ' ' +
			LEFT(CASE WHEN RIGHT(stime,1)='0' THEN DATEADD(MINUTE,-5,cast(stime as time(0)))
			WHEN RIGHT(stime,1)>='1' AND RIGHT(stime,1)<='5'THEN DATEADD(MINUTE,-CAST(RIGHT(stime,1) as int),cast(stime as time(0)))
			WHEN RIGHT(stime,1)>='6' AND RIGHT(stime,1)<='9'THEN DATEADD(MINUTE,-(CAST(RIGHT(stime,1) as int)-5),cast(stime as time(0)))
			END,5) AS stime2,
		CONVERT(DECIMAL(8,2), [nopen]/100) [open] , 
		CONVERT(DECIMAL(8,2), High/100) [High],
		CONVERT(DECIMAL(8,2), Low/100) [lowest], 
		CONVERT(DECIMAL(8,2), nClose/100) [close], [vol] ,
		RANK() OVER (partition by 
		CAST(CAST([sdate] AS DATE) AS VARCHAR) + ' ' +
			LEFT(CASE WHEN RIGHT(stime,1)='0' THEN DATEADD(MINUTE,-5,cast(stime as time(0)))
			WHEN RIGHT(stime,1)>='1' AND RIGHT(stime,1)<='5'THEN DATEADD(MINUTE,-CAST(RIGHT(stime,1) as int),cast(stime as time(0)))
			WHEN RIGHT(stime,1)>='6' AND RIGHT(stime,1)<='9'THEN DATEADD(MINUTE,-(CAST(RIGHT(stime,1) as int)-5),cast(stime as time(0)))
			END,5) 
		ORDER BY CAST([sdate] AS DATE), stime) [Rank]
		FROM  Stock..GetTodayTickAM()
		WHERE CAST([sdate] AS DATE) BETWEEN @from AND @to 
	END

	SELECT stime2, MAX([Rank] ) RK INTO #TEMP2 FROM #TEMP1 GROUP BY stime2

	------------prepare index for later join
	create index idx on #TEMP1 (stime2) 
	create index idx on #TEMP2 (stime2) 

	--This part remove the latest bar if the bar isn't compeleted yet
	--If we only want up to 08:45 bar, but we have a new bar 09:00 at current time 09:00:01
	--Then remove this uncompeleted bar, this only gurantee this bar is at least 4 minutes
	------------------------------------------------------------------------------------
	DECLARE @fullrnk smallint, @MaxTime datetime
	SELECT @fullrnk=MAX([Rank]), @MaxTime=stime2 FROM #TEMP1 WHERE stime2=(SELECT MAX(stime2) FROM #TEMP1) GROUP BY stime2

	IF @fullrnk<>5 --If the bar doesn't consist 5 minutes
	BEGIN
		print (@MaxTime)
		print (@fullrnk)
			DELETE FROM #TEMP1 WHERE stime2=@MaxTime
	END
	--------------------------------------------------------------------------------------

	SELECT  CAST(stime2 AS datetime) stime2, 
			MAX([open]) [open], 
			MAX(highest) highest, 
			MIN(lowest) lowest,
			MAX([close]) [close], 
			SUM(vol) vol FROM (
		SELECT S.stime2, 
		CASE WHEN [Rank]=1 THEN [open] ELSE 0 END [open], highest, lowest,
		CASE WHEN [Rank]=RK THEN [close] ELSE 0 END [close] , vol, T.RK 
		FROM #TEMP1 S INNER JOIN #TEMP2 T ON S.stime2=T.stime2) E
	--WHERE CAST(stime2 as time) Between '00:45:00' AND '13:45:00'
	GROUP BY stime2 
	ORDER BY stime2 ASC



GO
/****** Object:  StoredProcedure [dbo].[sp_RestartSKOrder]    Script Date: 9/26/2019 00:32:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_RestartSKOrder] AS

BEGIN

BEGIN
    EXEC xp_cmdshell 'powershell.exe ""E:\stopSKOrder.ps1""  '
    --EXEC xp_cmdshell 'powershell.exe Start-Process -FilePath ""C:\Users\HY\Dropbox\SKOrders\MyDebug\StockATM.exe"" '
END



END
GO
