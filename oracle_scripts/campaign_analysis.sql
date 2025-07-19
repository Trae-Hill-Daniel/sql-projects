-- Created By: Trae HD
-- Created On: 2025-07-01
-- Last Modified By: Trae HD
-- Last Modified On: 2025-07-19
-- Description: Campaign Analysis - This script analyzes the performance of CRM campaigns by examining player transactions, and campaign details.


WITH
-- All active players.
Players AS (
    SELECT 
        pp.CustomerID,
        pp.FirstName,
        pp.LastName,
        pp.Country,
        pp.AccountStatus

    FROM 
        player_profile pp
    WHERE 
        pp.AccountStatus = 'Active'
),

-- All campaign contacts in the last 3 months.
Campaigns AS (
    SELECT DISTINCT
        cf.CustomerID,
        cf.TargetGroupID,
        cf.TargetGroupName,
        cf.CampaignID,
        cf.CampaignType,
        cf.CampaignGroupType,
        TRUNC(cf.ScheduleTime) AS CampaignContactDate, -- Use TRUNC for date-only comparison
        cf.TemplateID,
        cf.TemplateName,
        cf.ChannelID,
        cf.ChannelName,
        cf.PromoCode
    FROM 
        campaign_contact_fact cf
    WHERE 
        cf.ScheduleTime >= ADD_MONTHS(TRUNC(SYSDATE, 'MM'), -3)
),

-- Player transactions and active player counts aggregated by campaign contact.
CampaignPerformance AS (
    SELECT
        c.CustomerID,
        c.CampaignID,
        c.CampaignContactDate,
        
        -- Totals & Active Player Counts (Day 0)
        SUM(CASE WHEN pt.TransactionDate = c.CampaignContactDate THEN pt.DepositAmount ELSE 0 END) AS TotalDepositAmount0DaysPost,
        SUM(CASE WHEN pt.TransactionDate = c.CampaignContactDate THEN pt.Turnover ELSE 0 END) AS TotalTurnover0DaysPost,
        SUM(CASE WHEN pt.TransactionDate = c.CampaignContactDate THEN pt.NGR ELSE 0 END) AS TotalNGR0DaysPost,
        COUNT(DISTINCT CASE WHEN pt.Turnover > 0 AND pt.TransactionDate = c.CampaignContactDate THEN c.CustomerID END) AS ActivePlayers0DaysPost,
        
        -- Totals & Active Player Counts (Cumulative 3-Day)
        SUM(CASE WHEN pt.TransactionDate BETWEEN c.CampaignContactDate AND c.CampaignContactDate + 2 THEN pt.DepositAmount ELSE 0 END) AS TotalDepositAmount3DaysPost,
        SUM(CASE WHEN pt.TransactionDate BETWEEN c.CampaignContactDate AND c.CampaignContactDate + 2 THEN pt.Turnover ELSE 0 END) AS TotalTurnover3DaysPost,
        SUM(CASE WHEN pt.TransactionDate BETWEEN c.CampaignContactDate AND c.CampaignContactDate + 2 THEN pt.NGR ELSE 0 END) AS TotalNGR3DaysPost,
        COUNT(DISTINCT CASE WHEN pt.Turnover > 0 AND pt.TransactionDate BETWEEN c.CampaignContactDate AND c.CampaignContactDate + 2 THEN c.CustomerID END) AS ActivePlayers3DaysPost,

        -- Totals & Active Player Counts (Cumulative 7-Day)
        SUM(CASE WHEN pt.TransactionDate BETWEEN c.CampaignContactDate AND c.CampaignContactDate + 6 THEN pt.DepositAmount ELSE 0 END) AS TotalDepositAmount7DaysPost,
        SUM(CASE WHEN pt.TransactionDate BETWEEN c.CampaignContactDate AND c.CampaignContactDate + 6 THEN pt.Turnover ELSE 0 END) AS TotalTurnover7DaysPost,
        SUM(CASE WHEN pt.TransactionDate BETWEEN c.CampaignContactDate AND c.CampaignContactDate + 6 THEN pt.NGR ELSE 0 END) AS TotalNGR7DaysPost,
        COUNT(DISTINCT CASE WHEN pt.Turnover > 0 AND pt.TransactionDate BETWEEN c.CampaignContactDate AND c.CampaignContactDate + 6 THEN c.CustomerID END) AS ActivePlayers7DaysPost,

        -- Totals & Active Player Counts (Cumulative 14-Day)
        SUM(CASE WHEN pt.TransactionDate BETWEEN c.CampaignContactDate AND c.CampaignContactDate + 13 THEN pt.DepositAmount ELSE 0 END) AS TotalDepositAmount14DaysPost,
        SUM(CASE WHEN pt.TransactionDate BETWEEN c.CampaignContactDate AND c.CampaignContactDate + 13 THEN pt.Turnover ELSE 0 END) AS TotalTurnover14DaysPost,
        SUM(CASE WHEN pt.TransactionDate BETWEEN c.CampaignContactDate AND c.CampaignContactDate + 13 THEN pt.NGR ELSE 0 END) AS TotalNGR14DaysPost,
        COUNT(DISTINCT CASE WHEN pt.Turnover > 0 AND pt.TransactionDate BETWEEN c.CampaignContactDate AND c.CampaignContactDate + 13 THEN c.CustomerID END) AS ActivePlayers14DaysPost,

        -- Totals & Active Player Counts (Cumulative 21-Day)
        SUM(CASE WHEN pt.TransactionDate BETWEEN c.CampaignContactDate AND c.CampaignContactDate + 20 THEN pt.DepositAmount ELSE 0 END) AS TotalDepositAmount21DaysPost,
        SUM(CASE WHEN pt.TransactionDate BETWEEN c.CampaignContactDate AND c.CampaignContactDate + 20 THEN pt.Turnover ELSE 0 END) AS TotalTurnover21DaysPost,
        SUM(CASE WHEN pt.TransactionDate BETWEEN c.CampaignContactDate AND c.CampaignContactDate + 20 THEN pt.NGR ELSE 0 END) AS TotalNGR21DaysPost,
        COUNT(DISTINCT CASE WHEN pt.Turnover > 0 AND pt.TransactionDate BETWEEN c.CampaignContactDate AND c.CampaignContactDate + 20 THEN c.CustomerID END) AS ActivePlayers21DaysPost

    FROM
        Campaigns c
    LEFT JOIN PlayerTransactions pt
        ON c.CustomerID = pt.CustomerID
        AND pt.TransactionDate BETWEEN c.CampaignContactDate AND c.CampaignContactDate + 20
    WHERE
        pt.TransactionDate >= ADD_MONTHS(TRUNC(SYSDATE, 'MM'), -3)
    GROUP BY
        c.CustomerID,
        c.CampaignID,
        c.CampaignContactDate
),

-- Bonus performance aggregated by campaign contact
BonusPerformance AS (
    SELECT
        c.CustomerID,
        c.CampaignID,
        c.CampaignContactDate,

        COUNT(DISTINCT CASE 
            WHEN bt.BonusRedeemedDate BETWEEN c.CampaignContactDate AND c.CampaignContactDate + 6 
            THEN c.CustomerID 
        END) AS BonusOptInPlayers,

        SUM(CASE 
            WHEN bt.BonusRedeemedDate BETWEEN c.CampaignContactDate AND c.CampaignContactDate + 6 
            THEN bt.RedeemedAmount 
            ELSE 0 
        END) AS TotalBonusRedeemed,

        SUM(CASE 
            WHEN bt.BonusRedeemedDate IS NOT NULL 
                 AND bt.BonusRedeemedDate <= bt.BonusExpiryDate 
            THEN bt.BonusAchievedAmount 
            ELSE 0 
        END) AS TotalBonusAchieved

    FROM
        Campaigns c
    JOIN bonus_transaction bt
        ON c.CustomerID = bt.CustomerID
        AND c.PromoCode = bt.BonusID 

    WHERE
        bt.BonusRedeemedDate >= ADD_MONTHS(TRUNC(SYSDATE, 'MM'), -3)

    GROUP BY
        c.CustomerID,
        c.CampaignID,
        c.CampaignContactDate
)

-- Final report joining all data sources and calculating averages.
SELECT
    p.CustomerID,
    p.FirstName,
    p.LastName,
    p.Country,
    c.TargetGroupID,
    c.TargetGroupName,
    c.CampaignID,
    c.CampaignType,
    c.CampaignContactDate,
    c.ChannelName,
    c.PromoCode,

    -- Bonus Metrics
    COALESCE(bp.BonusOptInPlayers, 0) AS BonusOptInPlayers,
    COALESCE(bp.TotalBonusRedeemed, 0) AS TotalBonusRedeemed,
    COALESCE(bp.TotalBonusAchieved, 0) AS TotalBonusAchieved,

    -- Totals
    COALESCE(perf.TotalDepositAmount0DaysPost, 0) AS TotalDepositAmount0DaysPost,
    COALESCE(perf.TotalDepositAmount3DaysPost, 0) AS TotalDepositAmount3DaysPost,
    COALESCE(perf.TotalDepositAmount7DaysPost, 0) AS TotalDepositAmount7DaysPost,
    COALESCE(perf.TotalDepositAmount14DaysPost, 0) AS TotalDepositAmount14DaysPost,
    COALESCE(perf.TotalDepositAmount21DaysPost, 0) AS TotalDepositAmount21DaysPost,

    COALESCE(perf.TotalTurnover0DaysPost, 0) AS TotalTurnover0DaysPost,
    COALESCE(perf.TotalTurnover3DaysPost, 0) AS TotalTurnover3DaysPost,
    COALESCE(perf.TotalTurnover7DaysPost, 0) AS TotalTurnover7DaysPost,
    COALESCE(perf.TotalTurnover14DaysPost, 0) AS TotalTurnover14DaysPost,
    COALESCE(perf.TotalTurnover21DaysPost, 0) AS TotalTurnover21DaysPost,

    COALESCE(perf.TotalNGR0DaysPost, 0) AS TotalNGR0DaysPost,
    COALESCE(perf.TotalNGR3DaysPost, 0) AS TotalNGR3DaysPost,
    COALESCE(perf.TotalNGR7DaysPost, 0) AS TotalNGR7DaysPost,
    COALESCE(perf.TotalNGR14DaysPost, 0) AS TotalNGR14DaysPost,
    COALESCE(perf.TotalNGR21DaysPost, 0) AS TotalNGR21DaysPost,
    
    -- Active Players
    COALESCE(perf.ActivePlayers0DaysPost, 0) AS ActivePlayers0DaysPost,
    COALESCE(perf.ActivePlayers3DaysPost, 0) AS ActivePlayers3DaysPost,
    COALESCE(perf.ActivePlayers7DaysPost, 0) AS ActivePlayers7DaysPost,
    COALESCE(perf.ActivePlayers14DaysPost, 0) AS ActivePlayers14DaysPost,
    COALESCE(perf.ActivePlayers21DaysPost, 0) AS ActivePlayers21DaysPost,
    
    -- Averages (Total / Active Players)
    COALESCE(perf.TotalDepositAmount0DaysPost / NULLIF(perf.ActivePlayers0DaysPost, 0), 0) AS AvgDepositAmount0DaysPost,
    COALESCE(perf.TotalDepositAmount3DaysPost / NULLIF(perf.ActivePlayers3DaysPost, 0), 0) AS AvgDepositAmount3DaysPost,
    COALESCE(perf.TotalDepositAmount7DaysPost / NULLIF(perf.ActivePlayers7DaysPost, 0), 0) AS AvgDepositAmount7DaysPost,
    COALESCE(perf.TotalDepositAmount14DaysPost / NULLIF(perf.ActivePlayers14DaysPost, 0), 0) AS AvgDepositAmount14DaysPost,
    COALESCE(perf.TotalDepositAmount21DaysPost / NULLIF(perf.ActivePlayers21DaysPost, 0), 0) AS AvgDepositAmount21DaysPost,
    
    COALESCE(perf.TotalTurnover0DaysPost / NULLIF(perf.ActivePlayers0DaysPost, 0), 0) AS AvgTurnover0DaysPost,
    COALESCE(perf.TotalTurnover3DaysPost / NULLIF(perf.ActivePlayers3DaysPost, 0), 0) AS AvgTurnover3DaysPost,
    COALESCE(perf.TotalTurnover7DaysPost / NULLIF(perf.ActivePlayers7DaysPost, 0), 0) AS AvgTurnover7DaysPost,
    COALESCE(perf.TotalTurnover14DaysPost / NULLIF(perf.ActivePlayers14DaysPost, 0), 0) AS AvgTurnover14DaysPost,
    COALESCE(perf.TotalTurnover21DaysPost / NULLIF(perf.ActivePlayers21DaysPost, 0), 0) AS AvgTurnover21DaysPost,

    COALESCE(perf.TotalNGR0DaysPost / NULLIF(perf.ActivePlayers0DaysPost, 0), 0) AS AvgNGR0DaysPost,
    COALESCE(perf.TotalNGR3DaysPost / NULLIF(perf.ActivePlayers3DaysPost, 0), 0) AS AvgNGR3DaysPost,
    COALESCE(perf.TotalNGR7DaysPost / NULLIF(perf.ActivePlayers7DaysPost, 0), 0) AS AvgNGR7DaysPost,
    COALESCE(perf.TotalNGR14DaysPost / NULLIF(perf.ActivePlayers14DaysPost, 0), 0) AS AvgNGR14DaysPost,
    COALESCE(perf.TotalNGR21DaysPost / NULLIF(perf.ActivePlayers21DaysPost, 0), 0) AS AvgNGR21DaysPost

FROM 
    Players p
JOIN Campaigns c
    ON p.CustomerID = c.CustomerID
LEFT JOIN CampaignPerformance perf
    ON p.CustomerID = perf.CustomerID
    AND c.CampaignID = perf.CampaignID
    AND c.CampaignContactDate = perf.CampaignContactDate
LEFT JOIN BonusPerformance bp
    ON c.CustomerID = bp.CustomerID
    AND c.CampaignID = bp.CampaignID
    AND c.CampaignContactDate = bp.CampaignContactDate;