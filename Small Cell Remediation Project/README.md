# Deidentification & Small Cell Suppression Utilities

## Overview 

This repository contains SQL-based logic developed by Enterprise
Analytics and Data Services (EADS) at UC Davis Health to support the
delivery of deidentified, privacy-preserving clinical data that retains
analytic value. The work was completed in collaboration with Privacy &
Compliance, the Institutional Review Board (IRB), and additional
stakeholders.

The primary objective is to prevent patient reidentification by
addressing small cell counts (fewer than 10 patients) and extreme values
while maintaining usable levels of data granularity.

## Key Privacy Principles

* Suppress or generalize data elements with < 10 patients

* Preserve analytic usefulness through hierarchical rollups rather than
removal

* Apply consistent, auditable rules across diagnoses, procedures,
insurance, height, and weight

## Supported Data Domains 

1. ### Diagnoses & Procedures (ICD-10)

    This logic applies to both diagnosis and procedure ICD-10 codes.

    #### Methodology

    All ICD-10 diagnosis and procedure codes are loaded from the ICD-10 hierarchy table (##ICD10_HIERARCHY).

    Patient counts are calculated per ICD-10 code (##DiagnosisRecode).

    Codes with fewer than 10 patients are iteratively rolled up by removing characters from the right.

    Character stripping does not cross the decimal point.

    The roll-up continues until the resulting ICD-10 code has ≥ 10 patients.

    #### Output

    ##ICD10GranularityCalc provides:
    * Original ICD-10 code
    * Rolled-up ICD-10 code that meets privacy thresholds

    This table can be used to:
    * Build views
    * Create stored procedures
    * Integrate directly into analytic queries


2. ### Insurance / Beneficiary Data

    #### Methodology

    Patient counts are calculated by financial category / beneficiary.

    If a beneficiary has < 10 patients, the data is generalized by extracting the provider instead.

    #### Output

    A table suitable for use in views, stored procedures, or downstream analytic logic

3. ### Height & Weight 

    Height and weight deidentification uses last recorded measurement and applies categorical suppression for extreme values.

    **Male Patients**

        Height > 84 inches → >84
        Weight < 5 pounds → <5
        Weight > 400 pounds → >400

    **Female or Not Male Patients**

        Height > 78 inches → >78
        Weight < 5 pounds → >5
        Weight >350 pounds → >350

## Implementation Notes

Logic is implemented using CTEs

Output CTEs can be consumed in the same way as diagnosis and procedure
rollups

## Technology 

Language: T-SQL

Database: SQL Server–compatible platforms

Although authored in T-SQL, the logic can be easily adapted to other
programming languages or SQL dialects.


## Intended Use

This code is intended for:
* Deidentified research datasets
* Regulatory-compliant analytics
* IRB-approved data extracts
* Population health and quality reporting

## Privacy & Compliance 

All transformations were designed to align with:
* HIPAA deidentification standards
* UC Davis Health privacy requirements
* IRB-approved data handling practices

## Contributing

Enhancements, optimizations, or language adaptations are welcome. Please
ensure that any changes:

* Maintain or improve privacy protections
* Preserve reproducibility and auditability


## Acknowledgements

* Enterprise Analytics and Data Services (EADS)
* UC Davis Health Privacy & Compliance
* Institutional Review Board (IRB)


## Contact

For questions related to methodology or implementation, please contact
the Enterprise Analytics and Data Services team
(<data@health.ucdavis.edu>) at UC Davis Health.
