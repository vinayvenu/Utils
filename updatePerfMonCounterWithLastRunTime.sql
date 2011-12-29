--Updates last run time of a SQL Server job to one of the custom counters provided by SQL Server (There are 10 counters provided. This puts it into one of them). 
CREATE PROCEDURE updatePerfMonCounterWithLastRunTime
      @sqlAgentJobName NVARCHAR (100), 
            @perfMonCounterNumber int
	    AS
	    BEGIN
	        DECLARE @timeTaken AS INT;
		DECLARE @procedure AS NVARCHAR (500);
		DECLARE @parms as  NVARCHAR (500);
			    
                --Figure out the time taken from sysjobs
                SET @timeTaken = (SELECT 
                                      CAST (substring(t.duration, 1, 2) AS INT) * 3600 + 
                                      CAST (substring(t.duration, 3, 2) AS INT) * 60 + 
                                      CAST (substring(t.duration, 5, 2) AS INT)
                                  FROM  
				      (SELECT TOP(1) RIGHT('000000' + CONVERT (VARCHAR (6), run_duration), 6) AS duration, 
                                           (CONVERT (DATETIME, RTRIM(run_date)) + (run_time * 9 + run_time % 10000 * 6 + run_time % 100 * 10) / 216e4) AS runDate
                                       FROM msdb..sysjobhistory AS h, msdb..sysjobs AS s
                                       WHERE s.name = @sqlAgentJobName
                                         AND h.job_id = s.job_id
                                         AND h.step_id = 0
                                       ORDER BY runDate DESC) AS t);

             SET @procedure = 'exec sp_user_counter' + CAST (@perfMonCounterNumber AS NVARCHAR) + ' @newvalue';

             SET @parms = N'@newvalue int';

             EXECUTE sp_executesql  @procedure, @parms, @newvalue = @timeTaken;
           END
