Drop Table If Exists #Height

select
distinct
lst.PatientID
, case
	when lst.sex = 'Male' and ladl.Value > 84 then '>84' 
	when lst.sex = 'Female' and ladl.Value > 78 then '>78' 
	when lst.sex not in ('Male', 'Female') and ladl.Value > 78 then '>78' 
	else ladl.Value end 	as HeightInInches
into #Height
from (
	select
	distinct
	pd.PatientID
	, pd.sex
	, max(adl.MeasurementDateAndTime) as LastFlw
	from Patient pd
	join Measure adl
		on pd.PatientID=adl.PatientID	
			and adl.MeasureId = 'Height in inches'
			and adl.Value is not null
	group by 
		pd.PatientID
		, pd.sex)lst
join Measure ladl
	on lst.PatientID=ladl.PatientID
		and ladl.MeasureId = '162' --Height in inches
		and ladl.MeasurementDateAndTime = lst.MeasurementDateAndTime