DECLARE @StartDate DATE; 
SET @StartDate = '1-JAN-2015';

DROP TABLE ##ICD10_HIERARCHY;

SELECT 
DiagnosisReference.ClinicalCodeKey
,DiagnosisReference.DiagnosisID
,DiagnosisReference.DiagnosisInternalId
,DiagnosisReference.DisplayValue
,DiagnosisReference.Value ICD10Code
,(SUBSTRING(DiagnosisReference.Value, 0, 3)) ICD10Code_1
,(SUBSTRING(DiagnosisReference.Value, 0, 4)) ICD10Code_2
,(SUBSTRING(DiagnosisReference.Value, 0, 6)) ICD10Code_3
,(SUBSTRING(DiagnosisReference.Value, 0, 7)) ICD10Code_4
,(SUBSTRING(DiagnosisReference.Value, 0, 8)) ICD10Code_5
,(SUBSTRING(DiagnosisReference.Value, 0, 9)) ICD10Code_6
INTO ##ICD10_HIERARCHY 
FROM DiagnosisReference
WHERE 
	DiagnosisReference.Type = 'ICD-10-CM';

DROP TABLE ##DiagnosisRecode;
SELECT 
PatientDiagnosisFact.ClinicalDiagnosisId 
,PatientDiagnosisFact.PatientIdentifier
,PatientDiagnosisFact.DiagnosisID
,##ICD10_Hierarchy.DiagnosisInternalId
,##ICD10_Hierarchy.DisplayValue
,##ICD10_Hierarchy.ICD10Code
,##ICD10_Hierarchy.ICD10Code_1
,##ICD10_Hierarchy.ICD10Code_2
,##ICD10_Hierarchy.ICD10Code_3
,##ICD10_Hierarchy.ICD10Code_4
,##ICD10_Hierarchy.ICD10Code_5
,##ICD10_Hierarchy.ICD10Code_6
INTO ##DiagnosisRecode 
FROM PatientDiagnosisFact
INNER JOIN ##ICD10_Hierarchy
	ON PatientDiagnosisFact.DiagnosisID = ##ICD10_HIERARCHY.DiagnosisID 
INNER JOIN 	DateReference StartDate
	ON PatientDiagnosisFact.StartDateKey = StartDate.DateKey 
INNER JOIN FunctionalAreaDim
	ON PatientDiagnosisFact.DepartmentKey = FunctionalAreaDim.DepartmentKey
WHERE 
	StartDate.DateValue >= @StartDate;	

DROP TABLE ##ICD10HierarchyCalc; 

SELECT 
##DiagnosisRecode.ICD10Code_1
,##DiagnosisRecode.ICD10Code_2
,##DiagnosisRecode.ICD10Code_3
,##DiagnosisRecode.ICD10Code_4
,##DiagnosisRecode.ICD10Code_5
,##DiagnosisRecode.ICD10Code_6
,##DiagnosisRecode.ICD10Code
,COUNT(DISTINCT ##DiagnosisRecode.PatientIdentifier) Patients
INTO ##ICD10HierarchyCalc
FROM ##DiagnosisRecode  
GROUP BY 
	ROLLUP(	
	##DiagnosisRecode.ICD10Code_1
	,##DiagnosisRecode.ICD10Code_2
	,##DiagnosisRecode.ICD10Code_3
	,##DiagnosisRecode.ICD10Code_4
	,##DiagnosisRecode.ICD10Code_5
	,##DiagnosisRecode.ICD10Code_6
	,##DiagnosisRecode.ICD10Code
	)
	;

DROP TABLE ##ICD10GranularityCalc;

SELECT DISTINCT 
ICD10Union.ICD10Code
,ICD10Union.ICD10Code_1
,ICD10Union.ICD10Code_2
,ICD10Union.ICD10Code_3
,ICD10Union.ICD10Code_4
,ICD10Union.ICD10Code_5
,ICD10Union.ICD10Code_6
--,ICD10Union.ICD10Code ICD10Code_Raw
,COALESCE(ICD10Union.ICD10Code_6,ICD10Union.ICD10Code_5,ICD10Union.ICD10Code_4,ICD10Union.ICD10Code_3,ICD10Union.ICD10Code_2,ICD10Union.ICD10Code_1) ICD10Recode 
,ICD10Union.Patients
,((CASE WHEN ICD10Union.ICD10Code_1 IS NOT NULL THEN 1 ELSE 0 END) + 
	(CASE WHEN ICD10Union.ICD10Code_2 IS NOT NULL THEN 1 ELSE 0 END) + 
		(CASE WHEN ICD10Union.ICD10Code_3 IS NOT NULL THEN 1 ELSE 0 END) + 
			(CASE WHEN ICD10Union.ICD10Code_4 IS NOT NULL THEN 1 ELSE 0 END) + 
				(CASE WHEN ICD10Union.ICD10Code_5 IS NOT NULL THEN 1 ELSE 0 END) + 
					(CASE WHEN ICD10Union.ICD10Code_6 IS NOT NULL THEN 1 ELSE 0 END)) *
						(CASE WHEN ICD10Union.Patients >= 10 THEN 1 ELSE 0 END) GranularityCalc 
,DENSE_RANK() OVER (PARTITION BY 	ICD10Union.ICD10Code ORDER BY 
															((CASE WHEN ICD10Union.ICD10Code_1 IS NOT NULL THEN 1 ELSE 0 END) + 
																(CASE WHEN ICD10Union.ICD10Code_2 IS NOT NULL THEN 1 ELSE 0 END) + 
																	(CASE WHEN ICD10Union.ICD10Code_3 IS NOT NULL THEN 1 ELSE 0 END) + 
																		(CASE WHEN ICD10Union.ICD10Code_4 IS NOT NULL THEN 1 ELSE 0 END) + 
																			(CASE WHEN ICD10Union.ICD10Code_5 IS NOT NULL THEN 1 ELSE 0 END) + 
																				(CASE WHEN ICD10Union.ICD10Code_6 IS NOT NULL THEN 1 ELSE 0 END)) *
																					(CASE WHEN ICD10Union.Patients >= 10 THEN 1 ELSE 0 END) DESC) DenseRankDesc 
	,((CASE WHEN ICD10Union.ICD10Code_1 IS NOT NULL THEN 1 ELSE 0 END) + 
	(CASE WHEN ICD10Union.ICD10Code_2 IS NOT NULL THEN 1 ELSE 0 END) + 
		(CASE WHEN ICD10Union.ICD10Code_3 IS NOT NULL THEN 1 ELSE 0 END) + 
			(CASE WHEN ICD10Union.ICD10Code_4 IS NOT NULL THEN 1 ELSE 0 END) + 
				(CASE WHEN ICD10Union.ICD10Code_5 IS NOT NULL THEN 1 ELSE 0 END) + 
					(CASE WHEN ICD10Union.ICD10Code_6 IS NOT NULL THEN 1 ELSE 0 END)) HierarchyLevel

,(LEN(REPLACE(ICD10Union.ICD10Code,'.','')) - LEN(REPLACE(COALESCE(ICD10Union.ICD10Code_6,ICD10Union.ICD10Code_5,ICD10Union.ICD10Code_4,ICD10Union.ICD10Code_3,ICD10Union.ICD10Code_2,ICD10Union.ICD10Code_1),'.',''))) DigitsTrimmed 
INTO ##ICD10GranularityCalc
FROM (
	SELECT 
	##ICD10_HIERARCHY.ICD10Code
	,##ICD10HierarchyCalc.ICD10Code_1
	,##ICD10HierarchyCalc.ICD10Code_2
	,##ICD10HierarchyCalc.ICD10Code_3
	,##ICD10HierarchyCalc.ICD10Code_4
	,##ICD10HierarchyCalc.ICD10Code_5
	,##ICD10HierarchyCalc.ICD10Code_6
	,##ICD10HierarchyCalc.ICD10Code ICD10Code_Raw
	,##ICD10HierarchyCalc.Patients
	FROM ##ICD10_HIERARCHY
	INNER JOIN ##ICD10HierarchyCalc
		ON ##ICD10_HIERARCHY.ICD10Code_1 = ##ICD10HierarchyCalc.ICD10Code_1
	WHERE ##ICD10HierarchyCalc.ICD10Code_2 IS NULL

	UNION ALL 

	SELECT 
	##ICD10_HIERARCHY.ICD10Code
	,##ICD10HierarchyCalc.ICD10Code_1
	,##ICD10HierarchyCalc.ICD10Code_2
	,##ICD10HierarchyCalc.ICD10Code_3
	,##ICD10HierarchyCalc.ICD10Code_4
	,##ICD10HierarchyCalc.ICD10Code_5
	,##ICD10HierarchyCalc.ICD10Code_6
	,##ICD10HierarchyCalc.ICD10Code ICD10Code_Raw
	,##ICD10HierarchyCalc.Patients
	FROM ##ICD10_HIERARCHY
	INNER JOIN ##ICD10HierarchyCalc
		ON ##ICD10_HIERARCHY.ICD10Code_2 = ##ICD10HierarchyCalc.ICD10Code_2
	WHERE	
		##ICD10HierarchyCalc.ICD10Code_3 IS NULL

	UNION ALL 

	SELECT 
	##ICD10_HIERARCHY.ICD10Code
	,##ICD10HierarchyCalc.ICD10Code_1
	,##ICD10HierarchyCalc.ICD10Code_2
	,##ICD10HierarchyCalc.ICD10Code_3
	,##ICD10HierarchyCalc.ICD10Code_4
	,##ICD10HierarchyCalc.ICD10Code_5
	,##ICD10HierarchyCalc.ICD10Code_6
	,##ICD10HierarchyCalc.ICD10Code ICD10Code_Raw
	,##ICD10HierarchyCalc.Patients
	FROM ##ICD10_HIERARCHY
	INNER JOIN ##ICD10HierarchyCalc
		ON ##ICD10_HIERARCHY.ICD10Code_3 = ##ICD10HierarchyCalc.ICD10Code_3
	WHERE	
		##ICD10HierarchyCalc.ICD10Code_4 IS NULL

UNION ALL 

	SELECT 
	##ICD10_HIERARCHY.ICD10Code
	,##ICD10HierarchyCalc.ICD10Code_1
	,##ICD10HierarchyCalc.ICD10Code_2
	,##ICD10HierarchyCalc.ICD10Code_3
	,##ICD10HierarchyCalc.ICD10Code_4
	,##ICD10HierarchyCalc.ICD10Code_5
	,##ICD10HierarchyCalc.ICD10Code_6
	,##ICD10HierarchyCalc.ICD10Code ICD10Code_Raw
	,##ICD10HierarchyCalc.Patients
	FROM ##ICD10_HIERARCHY
	INNER JOIN 	##ICD10HierarchyCalc
		ON ##ICD10_HIERARCHY.ICD10Code_4 = ##ICD10HierarchyCalc.ICD10Code_4
	WHERE	
		##ICD10HierarchyCalc.ICD10Code_5 IS NULL

	UNION ALL 

	SELECT 
	##ICD10_HIERARCHY.ICD10Code
	,##ICD10HierarchyCalc.ICD10Code_1
	,##ICD10HierarchyCalc.ICD10Code_2
	,##ICD10HierarchyCalc.ICD10Code_3
	,##ICD10HierarchyCalc.ICD10Code_4
	,##ICD10HierarchyCalc.ICD10Code_5
	,##ICD10HierarchyCalc.ICD10Code_6
	,##ICD10HierarchyCalc.ICD10Code ICD10Code_Raw
	,##ICD10HierarchyCalc.Patients
	FROM ##ICD10_HIERARCHY
	INNER JOIN ##ICD10HierarchyCalc
		ON ##ICD10_HIERARCHY.ICD10Code_5 = ##ICD10HierarchyCalc.ICD10Code_5
	WHERE	
		##ICD10HierarchyCalc.ICD10Code_6 IS NULL 

	UNION ALL 

	SELECT 
	##ICD10_HIERARCHY.ICD10Code
	,##ICD10HierarchyCalc.ICD10Code_1
	,##ICD10HierarchyCalc.ICD10Code_2
	,##ICD10HierarchyCalc.ICD10Code_3
	,##ICD10HierarchyCalc.ICD10Code_4
	,##ICD10HierarchyCalc.ICD10Code_5
	,##ICD10HierarchyCalc.ICD10Code_6
	,##ICD10HierarchyCalc.ICD10Code ICD10Code_Raw
	,##ICD10HierarchyCalc.Patients
	FROM ##ICD10_HIERARCHY
	INNER JOIN ##ICD10HierarchyCalc
		ON ##ICD10_HIERARCHY.ICD10Code_6 = ##ICD10HierarchyCalc.ICD10Code_6
	WHERE	
		##ICD10HierarchyCalc.ICD10Code IS NULL 

	UNION ALL 

	SELECT 
	##ICD10_HIERARCHY.ICD10Code
	,##ICD10HierarchyCalc.ICD10Code_1
	,##ICD10HierarchyCalc.ICD10Code_2
	,##ICD10HierarchyCalc.ICD10Code_3
	,##ICD10HierarchyCalc.ICD10Code_4
	,##ICD10HierarchyCalc.ICD10Code_5
	,##ICD10HierarchyCalc.ICD10Code_6
	,##ICD10HierarchyCalc.ICD10Code ICD10Code_Raw
	,##ICD10HierarchyCalc.Patients
	FROM ##ICD10_HIERARCHY
	INNER JOIN ##ICD10HierarchyCalc
		ON ##ICD10_HIERARCHY.ICD10Code = ##ICD10HierarchyCalc.ICD10Code
	) ICD10Union

SELECT 
##ICD10GranularityCalc.ICD10Code
,##ICD10GranularityCalc.ICD10Code_1
,##ICD10GranularityCalc.ICD10Code_2
,##ICD10GranularityCalc.ICD10Code_3
,##ICD10GranularityCalc.ICD10Code_4
,##ICD10GranularityCalc.ICD10Code_4
,##ICD10GranularityCalc.ICD10Code_6
,##ICD10GranularityCalc.ICD10Recode
,##ICD10GranularityCalc.Patients
,##ICD10GranularityCalc.DigitsTrimmed
FROM ##ICD10GranularityCalc
WHERE 
	##ICD10GranularityCalc.DenseRankDesc = 1 
	AND ##ICD10GranularityCalc.GranularityCalc > 0 
ORDER BY 
		##ICD10GranularityCalc.ICD10Code