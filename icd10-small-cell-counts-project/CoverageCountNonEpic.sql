SELECT 
    FinancialCategory
    ,ProductType
    ,InsuranceProvider
    ,PatientCount 
    ,(CASE WHEN PatientCount <= 10 THEN FinancialCategory ELSE InsuranceProvider END) AS RecodedInsuranceProvider 

FROM (
    SELECT
        InsuranceCoverage.FinancialCategory
        ,InsuranceCoverage.ProductType
        ,InsuranceCoverage.InsuranceProvider
        ,COUNT(DISTINCT InsuranceCoverage.SubscriberID) AS PatientCount 


    FROM 
        InsuranceCoverage 

    WHERE 
        InsuranceCoverage.CoverageEndDate IS NOT NULL 
        AND 
        InsuranceCoverage.HasCoverage = 1 

    GROUP BY 
        InsuranceCoverage.FinancialCategory
        ,InsuranceCoverage.ProductType
        ,InsuranceCoverage.InsuranceProvider
) AS InsuranceSummary;