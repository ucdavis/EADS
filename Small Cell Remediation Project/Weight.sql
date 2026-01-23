Drop Table If Exists #Weight

select
distinct
lst.PatientID
, case	
	when lst.Sex = 'Male' and ladl.value < 5 then '<5'
	when lst.Sex = 'Male' and ladl.value > 400 then '>400'
	when lst.Sex = 'Female' and ladl.value < 5 then '<5'
	when lst.Sex = 'Female' and ladl.value > 350 then '>350'
	when lst.sex not in ('Male', 'Female') and ladl.value < 5 then '<5'
	when lst.sex not in ('Male', 'Female') and ladl.value > 350 then '>350'
	else null end as WeightInLbs
into #Weight
from (
	select
	distinct
	pd.PatientID
	, pd.sex
	, max(adl.MeasurementDateAndTime) as LastFlw
	from Patient pd
	join Measure adl
		on pd.PatientID=adl.PatientID	
			and adl.MeasureId = 'Weight in pounds'
			and adl.value is not null
	group by 
		pd.PatientID
		, pd.sex)lst
join Measure ladl
	on lst.PatientID=ladl.PatientID
		and ladl.MeasureId = 'Weight in pounds'
		and ladl.MeasurementDateAndTime = lst.LastFlw