--USE [IQCare_WRP]
--GO
/****** Object:  StoredProcedure [dbo].[PatientBaselineVariables_To_Greencard]    Script Date: 11/5/2018 8:56:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[PatientBaselineVariables_To_Greencard]
@ptn_pk int, 
@transferIn int, 
@ARTStartDate datetime, 
@Sex int, 
@LocationId int, 
@StartDate datetime, 
@EnrollmentDate datetime OUTPUT, 
@VisitDate datetime OUTPUT, 
@artstart datetime OUTPUT, 
@visit_id int OUTPUT, 
@Pregnant bit OUTPUT, 
@HBVInfected bit OUTPUT, 
@TBinfected bit OUTPUT, 
@WHOStage int OUTPUT, 
@WHOStageString varchar(50) OUTPUT, 
@BreastFeeding bit OUTPUT, 
@CD4Count decimal OUTPUT, 
@MUAC decimal OUTPUT, 
@Weight decimal OUTPUT, 
@Height decimal OUTPUT, 
@ClosestARVDate datetime OUTPUT, 
@PatientMasterVisitId int OUTPUT, 
@HIVDiagnosisDate datetime OUTPUT, 
@EnrollmentWHOStage int OUTPUT, 
@EnrollmentWHOStageString varchar(50) OUTPUT, 
@Cohort varchar(50) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
IF @transferIn = 1
				BEGIN
					SET @artstart = @ARTStartDate
				END
			ELSE
				BEGIN
					Select TOP 1 @artstart = ARTStartDate	From mst_Patient	Where Ptn_Pk = @ptn_pk	And LocationID = @LocationId;
				END

			select TOP 1 @visit_id = visit_id from dtl_PatientARVEligibility where ptn_pk = @ptn_pk And LocationID = @LocationId;
		
			--print 'set @artstart and @visit_id';

			SET @Pregnant = 0;

			IF @Sex = (SELECT TOP 1 ItemId FROM LookupItemView WHERE MasterName like '%gender%' and ItemName like 'Female%')
				BEGIN
					--SET @Pregnant = 0;
					IF EXISTS(select TOP 1 Name from mst_Decode where id=(select TOP 1 eligibleThrough from dtl_PatientARVEligibility where ptn_pk = @ptn_pk And LocationID = @LocationId) and name like 'Pregnancy')
						BEGIN
							SET @Pregnant = 1;
						END
				END
			
			--print 'set @Sex';

			If EXISTS(SELECT * FROM dtl_PatientVitals dtl WHERE dtl.Visit_pk = @visit_id ) Begin
				SET @Weight = (Select Top (1) dtl.[Weight]
				From ord_Visit As ord
				Inner Join
					dtl_PatientVitals As dtl On dtl.Visit_pk = ord.Visit_Id
				Where (ord.Ptn_Pk = @ptn_pk)
				And (dtl.[Weight] Is Not Null)
				And (ord.Visit_Id = @visit_id));
			End 
			Else Begin
				SET @Weight = NULL;
			End
		
			--print 'set @Weight';

			If exists (SELECT * FROM dtl_PatientVitals dtl WHERE dtl.Visit_pk = @visit_id) Begin
				SET @Height = (Select Top 1 dtl.Height
				From Ord_visit ord
				Inner Join
					dtl_PatientVitals dtl On dtl.visit_pk = ord.Visit_Id
				Where ord.ptn_pk = @ptn_pk
				And dtl.Height Is Not Null
				And (ord.Visit_Id = @visit_id));
			End 
			Else Begin
				SET @Height = NULL;
			End
		
			--print 'set @Height';

			If EXISTS(SELECT * FROM dtl_PatientVitals dtl WHERE dtl.Visit_pk = @visit_id) Begin
				SET @MUAC = (Select Top (1) dtl.Muac
				From ord_Visit As ord
				Inner Join
					dtl_PatientVitals As dtl On dtl.Visit_pk = ord.Visit_Id
				Where (ord.Ptn_Pk = @ptn_pk)
				And (dtl.Muac Is Not Null)
				And (ord.Visit_Id = @visit_id));
			End
		
			--print 'set @MUAC';

			SET @TBinfected = 0;
			IF EXISTS(select TOP 1 Name from mst_Decode where id=(select TOP 1 eligibleThrough from dtl_PatientARVEligibility where ptn_pk = @ptn_pk And LocationID = @LocationId) and name like 'TB/HIV')
				BEGIN
					SET @TBinfected = 1;
				END
			
			--print 'set @TBinfected';

			SET @BreastFeeding = 0;
			IF EXISTS(select TOP 1 Name from mst_Decode where id=(select TOP 1 eligibleThrough from dtl_PatientARVEligibility where ptn_pk = @ptn_pk And LocationID = @LocationId) and name like 'BreastFeeding')
				BEGIN
					SET @TBinfected = 1;
				END
			
			--print 'set @BreastFeeding';

			--okay remove 1900
			SET @HIVDiagnosisDate = (SELECT TOP 1 dbo.dtl_PatientHivPrevCareEnrollment.ConfirmHIVPosDate
			FROM dbo.dtl_PatientHivPrevCareEnrollment INNER JOIN
				dbo.ord_Visit ON dbo.dtl_PatientHivPrevCareEnrollment.ptn_pk = dbo.ord_Visit.Ptn_Pk 
				AND dbo.dtl_PatientHivPrevCareEnrollment.Visit_pk = dbo.ord_Visit.Visit_Id INNER JOIN
				dbo.mst_VisitType ON dbo.ord_Visit.VisitType = dbo.mst_VisitType.VisitTypeID
				WHERE (dbo.mst_VisitType.VisitName = 'ART History') AND dbo.dtl_PatientHivPrevCareEnrollment.ptn_pk = @ptn_pk);

			--print 'set @HIVDiagnosisDate';
			SET @EnrollmentDate = (select TOP 1 DateEnrolledInCare from dtl_PatientHivPrevCareEnrollment where ptn_pk=@ptn_pk);
			if(@EnrollmentDate  Is Null) Select top 1 @EnrollmentDate = StartDate From Lnk_PatientProgramStart where Ptn_pk=@ptn_pk and ModuleId = 5
			--print 'set @EnrollmentDate';
			SET @EnrollmentWHOStageString = (SELECT TOP 1 Name FROM mst_Decode WHERE ID = (SELECT TOP 1 WHOStage FROM dtl_PatientARVEligibility where WHOStage > 0 AND ptn_pk=@ptn_pk) and codeid=22 AND Name <> 'N/A');
		--	print 'set @EnrollmentWHOStage';
			SET @Cohort = (select  TOP 1 convert(char(3),[FirstLineRegStDate] , 0) + ' ' + CONVERT(varchar(10), year([FirstLineRegStDate])) from [dbo].[dtl_PatientARTCare] WHERE ptn_pk = @ptn_pk);
			--print 'set @Cohort';
			SET @CD4Count = (SELECT top 1 CD4 FROM dtl_PatientARVEligibility WHERE ptn_pk = @ptn_pk)
		--	print 'set @CD4Count';
			SET @WHOStageString = (SELECT TOP 1 WHOStage FROM dtl_PatientARVEligibility where ptn_pk = @ptn_pk);

		--	print 'set @HIVDiagnosisDate, @EnrollmentDate, @EnrollmentWHOStage, @Cohort, @CD4Count, @WHOStage';
		
			SET @EnrollmentWHOStage = CASE @EnrollmentWHOStageString  
					WHEN '1' THEN (SELECT TOP 1 ItemId FROM LookupItemView WHERE MasterName ='WHOStage' AND ItemName = 'Stage' + '1') 
					WHEN '2' THEN (SELECT TOP 1 ItemId FROM LookupItemView WHERE MasterName ='WHOStage' AND ItemName = 'Stage' + '2')   
					WHEN '3' THEN (SELECT TOP 1 ItemId FROM LookupItemView WHERE MasterName ='WHOStage' AND ItemName = 'Stage' + '3')   
					WHEN '4' THEN (SELECT TOP 1 ItemId FROM LookupItemView WHERE MasterName ='WHOStage' AND ItemName = 'Stage' + '4')
					WHEN 'T1' THEN (SELECT TOP 1 ItemId FROM LookupItemView WHERE MasterName ='WHOStage' AND ItemName = 'Stage' + '1') 
					WHEN 'T2' THEN (SELECT TOP 1 ItemId FROM LookupItemView WHERE MasterName ='WHOStage' AND ItemName = 'Stage' + '2')   
					WHEN 'T3' THEN (SELECT TOP 1 ItemId FROM LookupItemView WHERE MasterName ='WHOStage' AND ItemName = 'Stage' + '3')   
					WHEN 'T4' THEN (SELECT TOP 1 ItemId FROM LookupItemView WHERE MasterName ='WHOStage' AND ItemName = 'Stage' + '4')
					ELSE (select TOP 1 ItemId from LookupItemView where MasterName = 'Unknown' and ItemName = 'Unknown')
				END
		  
			SET @WHOStage = CASE @WHOStageString  
					WHEN '1' THEN (SELECT TOP 1 ItemId FROM LookupItemView WHERE MasterName ='WHOStage' AND ItemName = 'Stage' + '1') 
					WHEN '2' THEN (SELECT TOP 1 ItemId FROM LookupItemView WHERE MasterName ='WHOStage' AND ItemName = 'Stage' + '2')   
					WHEN '3' THEN (SELECT TOP 1 ItemId FROM LookupItemView WHERE MasterName ='WHOStage' AND ItemName = 'Stage' + '3')   
					WHEN '4' THEN (SELECT TOP 1 ItemId FROM LookupItemView WHERE MasterName ='WHOStage' AND ItemName = 'Stage' + '4')
					WHEN 'T1' THEN (SELECT TOP 1 ItemId FROM LookupItemView WHERE MasterName ='WHOStage' AND ItemName = 'Stage' + '1') 
					WHEN 'T2' THEN (SELECT TOP 1 ItemId FROM LookupItemView WHERE MasterName ='WHOStage' AND ItemName = 'Stage' + '2')   
					WHEN 'T3' THEN (SELECT TOP 1 ItemId FROM LookupItemView WHERE MasterName ='WHOStage' AND ItemName = 'Stage' + '3')   
					WHEN 'T4' THEN (SELECT TOP 1 ItemId FROM LookupItemView WHERE MasterName ='WHOStage' AND ItemName = 'Stage' + '4')
					ELSE (select TOP 1 ItemId from LookupItemView where MasterName = 'Unknown' and ItemName = 'Unknown')
				END
		  
			SET @VisitDate = (SELECT TOP 1 [VisitDate] FROM [dbo].[ord_Visit] where [Ptn_Pk] = @ptn_pk AND [VisitType] in(18, 19));
			IF @EnrollmentDate IS NULL BEGIN SET @EnrollmentDate =@StartDate; END;

		--SELECT @EnrollmentDate, @VisitDate, @artstart, @visit_id, @Pregnant, @HBVInfected, @TBinfected, @WHOStage, @WHOStageString, @BreastFeeding, @CD4Count, @MUAC, @Weight, @Height, @ClosestARVDate, @PatientMasterVisitId, @HIVDiagnosisDate, @EnrollmentWHOStage, @EnrollmentWHOStageString, @Cohort;
END

