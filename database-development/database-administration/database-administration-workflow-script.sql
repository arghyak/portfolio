--**********************************************************************************************--
-- Title: Assigment06 
-- Author: AKannadaguli
-- Desc: This file demonstrates how to design and create; 
--       tables, constraints, views, stored procedures, and permissions
-- Change Log: When,Who,What
-- 2020-06-04,AKannadaguli,Created File
--***********************************************************************************************--
-- Note from author: When this script runs, the results will include the following
/*
Test results (feedback and the appropriate updated View) for the following transactional sprocs
  - pInsCourses
  - pUpdCourses
  - pDelCourses
  - pInsStudents
  - pUpdStudents
  - pDelStudents
  - pInsEnrollments
  - pUpdEnrollments
  - pDelEnrollments
The following views (after enrollment data has been inserted into database using pInputData sproc)
  - Courses
  - Students
  - Enrollments
*/
---------------------------------------------------------------------------------------------------



Begin Try
	Use Master;
	If Exists(Select Name From SysDatabases Where Name = 'Assignment06DB_AKannadaguli')
	 Begin 
	  Alter Database [Assignment06DB_AKannadaguli] set Single_user With Rollback Immediate;
	  Drop Database Assignment06DB_AKannadaguli;
	 End
	Create Database Assignment06DB_AKannadaguli;
End Try
Begin Catch
	Print Error_Number();
End Catch
go
Use Assignment06DB_AKannadaguli;

-- Create Tables (Module 01)-- 

-- Courses table
Create Table tCourses(
  CourseID int Identity(1,1) not null
  ,CourseName nvarchar(100) not null
  ,CourseStartDate date
  ,CourseEndDate date
  ,CourseStartTime time
  ,CourseEndTime time
  ,CourseWeekDays nvarchar(100)
  ,CourseCurrentPrice money
);
go

-- Students table
Create Table tStudents(
  StudentID int Identity(1,1) not null
  ,StudentNumber nvarchar(100) not null
  ,StudentFirstName nvarchar(100) not null
  ,StudentLastName nvarchar(100) not null
  ,StudentEmail nvarchar(100) not null
  ,StudentPhone nvarchar(100)
  ,StudentAddress1 nvarchar(100) not null
  ,StudentAddress2 nvarchar(100)
  ,StudentCity nvarchar(100) not null
  ,StudentStateCode nvarchar(100) not null
  ,StudentZipCode nvarchar(100) not null
);
go

-- Enrollments table
Create Table tEnrollments(
  EnrollmentID int Identity(1,1) not null
  ,StudentID int not null
  ,CourseID int not null
  ,EnrollmentDateTime datetime not null
  ,EnrollmentPrice money not null
);
go


-- Add Constraints (Module 02) -------------------------------------------------------------------- 


-- Courses table constraints
Alter Table tCourses with Check Add
  Constraint pkCourses Primary Key (CourseID)
  ,Constraint uqCourseName Unique (CourseName)
  ,Constraint ckCourseEndDate Check(Datediff(day, CourseStartDate, CourseEndDate) > 0)
  ,Constraint ckCourseEndTime Check(Datediff(minute, Convert(datetime, CourseStartTime), Convert(datetime, CourseEndTime)) > 0)
;
go

-- Students table constraints
Alter Table tStudents with Check Add
  Constraint pkStudents Primary Key (StudentID)
  ,Constraint uqStudentNumber Unique (StudentNumber)
  ,Constraint uqStudentEmail Unique (StudentEmail)
  ,Constraint ckStudentPhone Check(StudentPhone like '[0-9][0-9][0-9]-[0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]')
  ,Constraint ckStudentZipCode Check(StudentZipCode like '[0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]'
                                     or StudentZipCode like '[0-9][0-9][0-9][0-9][0-9]') 
									 -- I tried using the "in" operator but it kept giving me issues
;
go


-- Enrollments table constraints
-- I couldn't figure out how to access the CourseStartDate column for the ckEnrollmentDateTime constraint
-- from within the constraint definition/addition, so I made a function to help me compare EnrollmentDateTime
-- and CourseStartDate. I don't know if this is good form or the best way to do this, but it made my 
-- life a bit easier so no ragrets here
Create Function dbo.ckEnrollmentDateTimeFunction(@EnrollmentID int)
Returns int
As
  Begin
    Return(
	  Select DateDiff(day,EnrollmentDateTime,CourseStartDate)
	  From tCourses as c Join tEnrollments as e
	  On c.CourseID = e.CourseID
	  Where EnrollmentID = @EnrollmentID
	)
  End
go

Alter Table tEnrollments with Check Add
  Constraint pkEnrollments Primary Key (EnrollmentID)
  ,Constraint fkStudentID Foreign Key (StudentID) References tStudents(StudentID)
  ,Constraint fkCourseID Foreign Key (CourseID) References tCourses(CourseID)
  ,Constraint dfEnrollmentDateTime Default(GetDate()) For EnrollmentDateTime
  ,Constraint ckEnrollmentDateTime Check(dbo.ckEnrollmentDateTimeFunction(EnrollmentID) > 0)
;
go

-- used to test and troubleshoot pCkEnrollmentDateTimeFunction
/*
Select dbo.ckEnrollmentDateTimeFunction(2);
*/

-- used to check table columns, column data types, and constraints
/*
sp_help Courses;
sp_help Students;
sp_help Enrollments;
go
*/

-- Add Views (Module 03 and 04) ------------------------------------------------------------------- 

-- View for tCourses table
Create View Courses
As
  Select 
    CourseID
    ,CourseName
    ,CourseStartDate = Format(CourseStartDate, 'd', 'en-US') 
    ,CourseEndDate = Format(CourseEndDate, 'd', 'en-US')
    ,CourseStartTime = right('0' + ltrim(right(convert(varchar, cast(CourseStartTime as dateTime), 100), 7)), 7)
    ,CourseEndTime = right('0' + ltrim(right(convert(varchar, cast(CourseEndTime as dateTime), 100), 7)), 7)
    ,CourseWeekDays 
    ,CourseCurrentPrice = '$ ' + cast(CourseCurrentPrice as nvarchar)
  From tCourses;
go

-- View for tStudents table
Create View Students
As
  Select
    StudentID  
    ,StudentNumber 
    ,StudentFirstName
    ,StudentLastName 
    ,StudentEmail 
    ,StudentPhone 
    ,StudentAddress1 
    ,StudentAddress2 
    ,StudentCity 
    ,StudentStateCode
    ,StudentZipCode 
  From tStudents;
go

-- View for tEnrollments table
Create View Enrollments
As
  Select
    EnrollmentID  
	,StudentID   
	,CourseID
	,EnrollmentDateTime = Format(EnrollmentDateTime, 'd', 'en-US') + ' ' + Format(EnrollmentDateTime, N'hh\:mm')
	,EnrollmentPrice = '$ ' + cast(EnrollmentPrice as nvarchar)
  From tEnrollments;
go

/*
-- This view feels kind of excessive so I'm not sure it's what the assignment
-- is asking for. I'm going to go ahead and model the "reporting view" off the 
-- Enrollment Tracker in the MetaDataWorksheet Excel file

Create View FullEnrollmentReport
As
  Select
    EnrollmentID  
	,e.StudentID   
	,e.CourseID
	,EnrollmentDateTime
	,EnrollmentPrice
	,CourseName
    ,CourseStartDate 
    ,CourseEndDate 
    ,CourseStartTime 
    ,CourseEndTime 
    ,CourseWeekDays 
    ,CourseCurrentPrice
	,StudentNumber 
    ,StudentFirstName
    ,StudentLastName 
    ,StudentEmail 
    ,StudentPhone 
    ,StudentAddress1 
    ,StudentAddress2 
    ,StudentCity 
    ,StudentStateCode
    ,StudentZipCode
  From tStudents as s Join tEnrollments as e
  On s.StudentID = e.StudentID
  Join tCourses as c
  On e.CourseID = c.CourseID;
go
*/

-- Create Reporting View
Create --Alter
View EnrollmentTracker
As
  Select
    Course = CourseName
	,Dates = Format(CourseStartDate, 'd', 'en-US') + ' to ' + Format(CourseEndDate, 'd', 'en-US') 
	,[Start] = right('0' + ltrim(right(convert(varchar, cast(CourseStartTime as dateTime), 100), 7)), 7)
	,[End] = right('0' + ltrim(right(convert(varchar, cast(CourseEndTime as dateTime), 100), 7)), 7)
	,[Days] = CourseWeekDays
	,Price = '$ ' + Convert(nvarchar, CourseCurrentPrice)
	,Student = StudentFirstName + ' ' + StudentLastName
	,Number = StudentNumber
	,Email = StudentEmail
	,Phone = StudentPhone
	,[Address] = StudentAddress1 + ', ' + StudentCity + ', ' + StudentStateCode + ', ' + StudentZipCode
	-- did not include Address 2 because there is no Address 2 data given anywhere in the input table
	,[SignupDate] = Format(EnrollmentDateTime, 'd', 'en-US')
	,Paid = '$ ' + Convert(nvarchar, EnrollmentPrice)
  From tStudents as s Join tEnrollments as e
  On s.StudentID = e.StudentID
  Join tCourses as c
  On e.CourseID = c.CourseID;
go

Select  * From EnrollmentTracker
go

-- Add Stored Procedures (Module 04 and 05) -------------------------------------------------------

-- Courses Table Stored Procedures --
Create Procedure pInsCourses (
        @CourseName nvarchar(100)
       ,@CourseStartDate date
       ,@CourseEndDate date
       ,@CourseStartTime time
       ,@CourseEndTime time
       ,@CourseWeekDays nvarchar(100)
       ,@CourseCurrentPrice money
	   )
/* Author: <AKannadaguli>
** Desc: Processes <Insert Into Courses Table>
** Change Log: When,Who,What
** <2020-06-04>,<AKannadaguli>,Created stored procedure.
*/
AS
 Begin
  Declare @RC int = 0;
  Begin Try
   Begin Transaction 
    Insert Into tCourses(
        CourseName
       ,CourseStartDate 
       ,CourseEndDate 
       ,CourseStartTime 
       ,CourseEndTime 
       ,CourseWeekDays 
       ,CourseCurrentPrice
	   ) 
	Values(
        @CourseName
       ,@CourseStartDate 
       ,@CourseEndDate 
       ,@CourseStartTime 
       ,@CourseEndTime 
       ,@CourseWeekDays 
       ,@CourseCurrentPrice
	   );
   Commit Transaction
   Set @RC = +1
  End Try
  Begin Catch
   If(@@Trancount > 0) Rollback Transaction
   Print Error_Message()
   Set @RC = -1
  End Catch
  Return @RC;
 End
go

Create Procedure pUpdCourses (
        @CourseID int 
	   ,@CourseName nvarchar(100)	  
       ,@CourseStartDate date 		  
       ,@CourseEndDate date			  
       ,@CourseStartTime time		  
       ,@CourseEndTime time			  
       ,@CourseWeekDays nvarchar(100) 
       ,@CourseCurrentPrice money     
	   )
/* Author: <AKannadaguli>
** Desc: Processes <Updates Courses Table>
** Change Log: When,Who,What
** <2020-06-04>,<AKannadaguli>,Created stored procedure.
*/
AS
 Begin
  Declare @RC int = 0;
  Begin Try
   Begin Transaction 
    Update tCourses
	Set CourseName		   = @CourseName
       ,CourseStartDate    = @CourseStartDate 
       ,CourseEndDate 	   = @CourseEndDate 
       ,CourseStartTime    = @CourseStartTime 
       ,CourseEndTime 	   = @CourseEndTime 
       ,CourseWeekDays 	   = @CourseWeekDays 
       ,CourseCurrentPrice = @CourseCurrentPrice
	Where CourseID = @CourseID;
   Commit Transaction
   Set @RC = +1
  End Try
  Begin Catch
   If(@@Trancount > 0) Rollback Transaction
   Print Error_Message()
   Set @RC = -1
  End Catch
  Return @RC;
 End
go

Create Procedure pDelCourses (
        @CourseID int
       )
/* Author: <AKannadaguli>
** Desc: Processes <Delete From Courses Table>
** Change Log: When,Who,What
** <2020-06-04>,<AKannadaguli>,Created stored procedure.
*/
AS
 Begin
  Declare @RC int = 0;
  Begin Try
   Begin Transaction 
    Delete From Enrollments Where CourseID = @CourseID;
	Delete From Courses Where CourseID = @CourseID;
   Commit Transaction
   Set @RC = +1
  End Try
  Begin Catch
   If(@@Trancount > 0) Rollback Transaction
   Print Error_Message()
   Set @RC = -1
  End Catch
  Return @RC;
 End
go

-- Students Table Stored Procedures --
Create Procedure pInsStudents (
	    @StudentNumber nvarchar(100)
       ,@StudentFirstName nvarchar(100)
       ,@StudentLastName nvarchar(100)
       ,@StudentEmail nvarchar(100)
       ,@StudentPhone nvarchar(100)
       ,@StudentAddress1 nvarchar(100)
       ,@StudentAddress2 nvarchar(100)
       ,@StudentCity nvarchar(100)
       ,@StudentStateCode nvarchar(100)
       ,@StudentZipCode nvarchar(100)
	   )
/* Author: <AKannadaguli>
** Desc: Processes <Insert Into Students Table>
** Change Log: When,Who,What
** <2020-06-04>,<AKannadaguli>,Created stored procedure.
*/
AS
 Begin
  Declare @RC int = 0;
  Begin Try
   Begin Transaction 
    Insert Into tStudents(
	    StudentNumber 
	   ,StudentFirstName
	   ,StudentLastName 
	   ,StudentEmail 
	   ,StudentPhone 
	   ,StudentAddress1 
	   ,StudentAddress2 
	   ,StudentCity 
	   ,StudentStateCode
	   ,StudentZipCode 
	   ) 
	Values(
	    @StudentNumber 
	   ,@StudentFirstName
	   ,@StudentLastName 
	   ,@StudentEmail 
	   ,@StudentPhone 
	   ,@StudentAddress1 
	   ,@StudentAddress2 
	   ,@StudentCity 
	   ,@StudentStateCode
	   ,@StudentZipCode 
	   );
   Commit Transaction
   Set @RC = +1
  End Try
  Begin Catch
   If(@@Trancount > 0) Rollback Transaction
   Print Error_Message()
   Set @RC = -1
  End Catch
  Return @RC;
 End
go

Create Procedure pUpdStudents (
        @StudentID int  
	   ,@StudentNumber nvarchar(100)	
       ,@StudentFirstName nvarchar(100)	
       ,@StudentLastName nvarchar(100)	
       ,@StudentEmail nvarchar(100)		
       ,@StudentPhone nvarchar(100)		
       ,@StudentAddress1 nvarchar(100)	
       ,@StudentAddress2 nvarchar(100)	
       ,@StudentCity nvarchar(100)		
       ,@StudentStateCode nvarchar(100)	
       ,@StudentZipCode nvarchar(100)   
	   )
/* Author: <AKannadaguli>
** Desc: Processes <Update Students Table>
** Change Log: When,Who,What
** <2020-06-04>,<AKannadaguli>,Created stored procedure.
*/
AS
 Begin
  Declare @RC int = 0;
  Begin Try
   Begin Transaction 
    Update tStudents
	Set StudentNumber      = @StudentNumber 
	   ,StudentFirstName   = @StudentFirstName
	   ,StudentLastName    = @StudentLastName 
	   ,StudentEmail 	   = @StudentEmail 
	   ,StudentPhone 	   = @StudentPhone 
	   ,StudentAddress1    = @StudentAddress1 
	   ,StudentAddress2    = @StudentAddress2 
	   ,StudentCity 	   = @StudentCity 
	   ,StudentStateCode   = @StudentStateCode
	   ,StudentZipCode 	   = @StudentZipCode 
	Where StudentID = @StudentID; 
   Commit Transaction
   Set @RC = +1
  End Try
  Begin Catch
   If(@@Trancount > 0) Rollback Transaction
   Print Error_Message()
   Set @RC = -1
  End Catch
  Return @RC;
 End
go

Create Procedure pDelStudents (
        @StudentID int
	   )
/* Author: <AKannadaguli>
** Desc: Processes <Delete From Students Table>
** Change Log: When,Who,What
** <2020-06-04>,<AKannadaguli>,Created stored procedure.
*/
AS
 Begin
  Declare @RC int = 0;
  Begin Try
   Begin Transaction 
    Delete From Enrollments Where StudentID = @StudentID; 
	Delete From Students Where StudentID = @StudentID;
   Commit Transaction
   Set @RC = +1
  End Try
  Begin Catch
   If(@@Trancount > 0) Rollback Transaction
   Print Error_Message()
   Set @RC = -1
  End Catch
  Return @RC;
 End
go

-- Enrollments Table Stored Procedures --
Create Procedure pInsEnrollments(
	    @StudentID int  
	   ,@CourseID int  
	   ,@EnrollmentDateTime datetime  
	   ,@EnrollmentPrice money  
	   )
/* Author: <AKannadaguli>
** Desc: Processes <Insert Into Enrollments Table>
** Change Log: When,Who,What
** <2020-05-11>,<AKannadaguli>,Created stored procedure.
*/
AS
 Begin
  Declare @RC int = 0;
  Begin Try
   Begin Transaction 
    Insert Into tEnrollments(
	    StudentID   
	   ,CourseID
	   ,EnrollmentDateTime
	   ,EnrollmentPrice
	   ) 
	Values (
	    @StudentID   
	   ,@CourseID
	   ,@EnrollmentDateTime
	   ,@EnrollmentPrice
	   )
   Commit Transaction
   Set @RC = +1
  End Try
  Begin Catch
   If(@@Trancount > 0) Rollback Transaction
   Print Error_Message()
   Set @RC = -1
  End Catch
  Return @RC;
 End
go

Create Procedure pUpdEnrollments( 
	    @EnrollmentID int -- since each instance of an enrollment is specific to one student and one course, 
		                  -- it doesn't make sense to give the option to change StudentID or CourseID. If one 
						  -- of those were to change, it would make the most sense for the user to delete the 
						  -- enrollment altogether and create a new one.
	   ,@EnrollmentDateTime datetime  
	   ,@EnrollmentPrice money        
	   )
/* Author: <AKannadaguli>
** Desc: Processes <Update Enrollments Table>
** Change Log: When,Who,What
** <2020-05-11>,<AKannadaguli>,Created stored procedure.
*/
AS
 Begin
  Declare @RC int = 0;
  Begin Try
   Begin Transaction 
    Update tEnrollments
	Set EnrollmentDateTime = @EnrollmentDateTime
	   ,EnrollmentPrice	   = @EnrollmentPrice
	Where EnrollmentID = @EnrollmentID;
   Commit Transaction
   Set @RC = +1
  End Try
  Begin Catch
   If(@@Trancount > 0) Rollback Transaction
   Print Error_Message()
   Set @RC = -1
  End Catch
  Return @RC;
 End
go

Create Procedure pDelEnrollments(
	    @EnrollmentID int
	   )
/* Author: <AKannadaguli>
** Desc: Processes <Delete From Enrollments Table>
** Change Log: When,Who,What
** <2020-05-11>,<AKannadaguli>,Created stored procedure.
*/
AS
 Begin
  Declare @RC int = 0;
  Begin Try
   Begin Transaction 
    Delete From tEnrollments Where EnrollmentID = @EnrollmentID;
   Commit Transaction
   Set @RC = +1
  End Try
  Begin Catch
   If(@@Trancount > 0) Rollback Transaction
   Print Error_Message()
   Set @RC = -1
  End Catch
  Return @RC;
 End
go

-- Set Permissions (Module 06) --------------------------------------------------------------------

-- Denying public access of any kind to database tables
Deny Select, Insert, Update, Delete on tCourses to Public;
Deny Select, Insert, Update, Delete on tStudents to Public;
Deny Select, Insert, Update, Delete on tEnrollments to Public;

-- Granting public access to views
Grant Select on Courses to Public;
Grant Select on Students to Public;
Grant Select on Enrollments to Public;

-- Granting public access to Courses TSPs
Grant Execute on pInsCourses to Public;
Grant Execute on pUpdCourses to Public;
Grant Execute on pDelCourses to Public;

-- Granting public access to Students TSPs
Grant Execute on pInsStudents to Public;
Grant Execute on pUpdStudents to Public;
Grant Execute on pDelStudents to Public;

-- Granting public access to Enrollments TSPs
Grant Execute on pInsEnrollments to Public;
Grant Execute on pUpdEnrollments to Public;
Grant Execute on pDelEnrollments to Public;


--< Test Views and Sprocs >------------------------------------------------------------------------

-- Testing TSPs for Courses table --
-- insert into Courses table
Declare @Status int; -- store return code
Exec @Status = pInsCourses 
        @CourseName = 'poodle'
       ,@CourseStartDate = '01/01/2020'
       ,@CourseEndDate = '06/01/2020'
       ,@CourseStartTime = '09:30:00'
       ,@CourseEndTime = '10:20:00'
       ,@CourseWeekDays = 'MTWThF'
       ,@CourseCurrentPrice = 300
	   ;
Select Case @Status -- output feedback
  When +1 Then 'Course insert test was successful!'
  When -1 Then 'Course insert test failed! Common Issues: Duplicate Data'
  End 
As [Status]
go
Select * From Courses; -- check formatted view
go
-- update Courses table
Declare @Status int; -- store return code
Exec @Status = pUpdCourses 
        @CourseID = @@IDENTITY
	   ,@CourseName         = 'noodle'
       ,@CourseStartDate    = '01/01/2020'
       ,@CourseEndDate      = '06/01/2020'
       ,@CourseStartTime    = '09:30:00'
       ,@CourseEndTime      = '10:20:00'
       ,@CourseWeekDays     = 'MTWThF'
       ,@CourseCurrentPrice = 300
	   ;
Select Case @Status -- output feedback
  When +1 Then 'Course update test was successful!'
  When -1 Then 'Course update test failed! Common Issues: Duplicate Data, Foreign Key Constraint'
  End 
As [Status]
go
Select * From Courses; -- check formatted view
go
-- delete from Courses table
Declare @Status int; -- store return code
Exec @Status = pDelCourses 
        @CourseID = @@IDENTITY
	   ;
Select Case @Status -- output feedback
  When +1 Then 'Course deletion test was successful!'
  When -1 Then 'Course deletion test failed! Inputed ID does not exist, Foreign Key Constraint'
  End 
As [Status]
go
Select * From Courses; -- check formatted view
go

-- Testing TSPs for Students table --
-- insert into Students table
Declare @Status int; -- store return code
Exec @Status = pInsStudents
	    @StudentNumber      = 'abcdefg'
       ,@StudentFirstName   = 'Taco'
       ,@StudentLastName    = 'Bella'
       ,@StudentEmail       = 'tacobella@applebees.gov'
       ,@StudentPhone       = '123-456-7890' 
       ,@StudentAddress1    = '1234 Yesler Way'
       ,@StudentAddress2    = null
       ,@StudentCity        = 'Seattle'
       ,@StudentStateCode   = 'WA'
       ,@StudentZipCode     = '98122-6300'
	   ;
Select Case @Status -- output feedback
  When +1 Then 'New student addition test was successful!'
  When -1 Then 'New student addition test failed! Common Issues: Duplicate Data'
  End 
As [Status]
go
Select * From Students; -- check formatted view
go

-- update Students table
Declare @Status int; -- store return code
Exec @Status = pUpdStudents 
        @StudentID = @@IDENTITY
	   ,@StudentNumber      = 'abcdefg'
       ,@StudentFirstName   = 'Jelly'
       ,@StudentLastName    = 'Beans'
       ,@StudentEmail       = 'billyjean@cia.gov'
       ,@StudentPhone       = '456-856-8374' 
       ,@StudentAddress1    = '1234 Broadway Ave'
       ,@StudentAddress2    = null
       ,@StudentCity        = 'Seattle'
       ,@StudentStateCode   = 'WA'
       ,@StudentZipCode     = '98102'
	   ;
Select Case @Status -- output feedback
  When +1 Then 'Student update test was successful!'
  When -1 Then 'Student update test failed! Common Issues: Duplicate Data, Foreign Key Constraint'
  End 
As [Status]
go
Select * From Students; -- check formatted view
go

-- delete from Students table
Declare @Status int; -- store return code
Exec @Status = pDelStudents 
        @StudentID = @@IDENTITY
	   ;
Select Case @Status -- output feedback
  When +1 Then 'Deletion of student data test was successful!'
  When -1 Then 'Deletion of student data test failed! Inputed ID does not exist, Foreign Key Constraint'
  End 
As [Status]
go
Select * From Students; -- check formatted view
go


-- Testing TSPs for Enrollments table --
-- Since enrollment data requires foreign keys from both the Courses and Students tables, 
-- there has to be some sort of data in those tables so that I can test the Enrollments TSPs

Insert Into tCourses(CourseName,CourseStartDate,CourseEndDate,CourseStartTime,CourseEndTime,CourseWeekDays,CourseCurrentPrice) 
Values('a','01/01/2020','06/01/2020','04:30','05:40','MWF',250);
Declare @tempCourseID int = @@IDENTITY;

Insert Into tStudents(StudentNumber,StudentFirstName,StudentLastName,StudentEmail,StudentPhone,StudentAddress1,StudentAddress2,
  StudentCity,StudentStateCode,StudentZipCode)
Values('abc123','Chameleon','Jones','karmachameleon@cultureclub.org','678-999-8212','123 apple street',null,'Venice','CA','90291');
Declare @tempStudentID int = @@IDENTITY;

-- insert into Enrollments table
Declare @Status int; -- store return code
Exec @Status = pInsEnrollments
	    @StudentID          = @tempCourseID
	   ,@CourseID   		= @tempStudentID
	   ,@EnrollmentDateTime = '2020-06-04 23:10:43.687'
	   ,@EnrollmentPrice    = 1000
	   ;
Select Case @Status -- output feedback
  When +1 Then 'New enrollment test was successful!'
  When -1 Then 'New enrollment test failed! Common Issues: Duplicate Data'
  End 
As [Status]
go
Select * From Enrollments; -- check formatted view
go

-- update Enrollments table
Declare @Status int; -- store return code
Exec @Status = pUpdEnrollments
	    @EnrollmentID = @@IDENTITY
	   ,@EnrollmentDateTime = '1999-03-11 00:45:00.00'
	   ,@EnrollmentPrice    = 6
	   ;
Select Case @Status -- output feedback
  When +1 Then 'Enrollment update test was successful!'
  When -1 Then 'Enrollment update test failed! Common Issues: Duplicate Data, Foreign Key Constraint'
  End 
As [Status]
go
Select * From Enrollments; -- check formatted view
go

-- delete from Enrollments table
Declare @Status int; -- store return code
Exec @Status = pDelEnrollments
        @EnrollmentID = @@IDENTITY
	   ;
Select Case @Status -- output feedback
  When +1 Then 'Deletion of enrollment test was successful!'
  When -1 Then 'Deletion of enrollment test failed! Inputed ID does not exist, Foreign Key Constraint'
  End 
As [Status]
go
Select * From Enrollments; -- check formatted view
go

-- empty the Courses and Students tables of the random testing entries
Delete From Courses; --don't need to use a where clause because no relevant data has been entered yet
Delete From Students;
go

--< Insert Enrollment Data into Database >---------------------------------------------------------

Create Procedure pInputData (
        @InputString nvarchar(300)
	   )
/* Author: <AKannadaguli>
** Desc: Processes <Clearning inputted data and feeding it to the appropriate sprocs>
** Change Log: When,Who,What
** <2020-06-05>,<AKannadaguli>,Created stored procedure.
*/

-- Not using a try/catch + transaction combination here because when I execute the insert sprocs
-- for student/course/enrollment data, if it throws a unique constraint error, the insert sprocs will
-- fail the insert transaction and make sure duplicate values are not added into the tables
-- If duplicate student/course data is inputted into this pInputData procedure, I want those fails to work

AS
 Begin
       
	-- Delete Tables used in this pInputData if they have been created from previous execution 
	/*
    If (Exists (Select * From Information_Schema.Tables Where Table_Name = 'RawInputData'))
	Begin Drop Table RawInputData;
	End
	If (Exists (Select * From Information_Schema.Tables Where Table_Name = 'CourseDates'))
	Begin Drop Table CourseDates;
	End
    If (Exists (Select * From Information_Schema.Tables Where Table_Name = 'InputStudentFullName'))
    Begin Drop Table InputStudentFullName;
    End
	If (Exists (Select * From Information_Schema.Tables Where Table_Name = 'InputAddress'))
	Begin Drop Table InputAddress;
	End
	*/
	-- Edit: Actually, I have decided that I don't want these tables to exist after pInputData 
	-- finishes executing, so I'm just going to drop them at the end of the sproc instead
    
	
	-- used while troubleshooting pInputData sproc
	/*
	Delete From Enrollments;
	Delete From Courses;
	Delete From Students;
    

    Declare @InputString nvarchar(300);
	Set @InputString = 'SQL1 - Winter 2017,1/10/2017 to 1/24/2017 ,6PM,8:50PM,T,399,Bob Smith,B-Smith-071,Bsmith@HipMail.com,(206)-111-2222,"123 Main St. Seattle, WA., 98001",1/3/2017,399'
    ;
    */

 	Select Row_Number() Over(
	  Order By(Select null)
	  ) Row_Num, Value 
	Into RawInputData 
	From String_Split(@InputString, ',');
	-- Select * From RawInputData;

	-- Clean data for Courses table --
	  -- name
	  Declare @OutputCourseName nvarchar(100) = (Select Value From RawInputData Where row_num = 1);
	  -- dates
	  Select Row_Number() Over(
	    Order By(Select null)
	    ) Row_Num, Value 
		Into CourseDates
		From String_Split((Select Value From RawInputData Where Row_Num = 2), ' ');
	  Declare @OutputCourseStartDate date = (Select Value From CourseDates Where Row_Num = 1);
	  Declare @OutputCourseEndDate date = (Select Value From CourseDates Where Row_Num = 3);
	  -- times
	  Declare @OutputCourseStartTime time = (Select Value From RawInputData Where row_num = 3);
	  Declare @OutputCourseEndTime time = (Select Value From RawInputData Where row_num = 4);
	  Declare @OutputCourseWeekDays nvarchar(100) = (Select Value From RawInputData Where row_num = 5);
	  -- price
	  Declare @OutputCourseCurrentPrice money = (Select Value From RawInputData Where row_num = 6);

	-- Insert cleaned data into Courses table --
	  Execute pInsCourses
          @CourseName 		  = @OutputCourseName 		
         ,@CourseStartDate 	  = @OutputCourseStartDate 	
         ,@CourseEndDate 	  = @OutputCourseEndDate 		
         ,@CourseStartTime 	  = @OutputCourseStartTime 	
         ,@CourseEndTime 	  = @OutputCourseEndTime 		
         ,@CourseWeekDays 	  = @OutputCourseWeekDays 	
         ,@CourseCurrentPrice = @OutputCourseCurrentPrice
	  ;

	-- Clean data for Students Table --
	  --name
	  Select Row_Number() Over(
	    Order By(Select null)
	    ) Row_Num, Value 
		Into InputStudentFullName -- Drop Table InputStudentFullName
		From String_Split((Select Value From RawInputData Where Row_Num = 7), ' ');
	  Declare @OutputStudentFirstName nvarchar(100) = (Select Value From InputStudentFullName Where Row_Num = 1);
	  Declare @OutputStudentLastName nvarchar(100) = (Select Value From InputStudentFullName Where Row_Num = 2);
	  --student number and contact
	  Declare @OutputStudentNumber nvarchar(100) = (Select Value From RawInputData Where Row_Num = 8);
      Declare @OutputStudentEmail nvarchar(100) = (Select Value From RawInputData Where Row_Num = 9);
	  Declare @OutputStudentPhone nvarchar(100) = (Select Replace(Replace(
													      (Select Value From RawInputData Where Row_Num = 10), 
														  '(', ''), ')', '')); -- removing the unnecessary parentheses from the original format
	  --address
	  Select Row_Number() Over(
	    Order By(Select null)
	    ) Row_Num, Value 
		Into InputAddress -- Drop Table InputAddress
		From String_Split((Select Value From RawInputData Where Row_Num = 11), ' ')
	  Declare @OutputStudentCity nvarchar(100) = (Select Value From InputAddress Where Row_Num = (Select max(Row_Num) From InputAddress));
	  Declare @OutputStudentAddress1 nvarchar(100) = (Select Replace(Replace(Replace((Select Value From RawInputData Where Row_Num = 11), @OutputStudentCity, ''), '"', ''), '. ', '.'));
	  Declare @OutputStudentAddress2 nvarchar(100) = null; -- there is no Address2 data anywhere in the Enrollment Tracker, 
	                                                       -- so I'm not going to bother trying to record it
	  Declare @OutputStudentStateCode nvarchar(100) = (Select Value From RawInputData Where Row_Num = 12);
      Declare @OutputStudentZipCode nvarchar(100) = (Select Replace(Replace((Select Value From RawInputData Where Row_Num = 13), '"',''),' ',''));

	-- Insert cleaned data into Students table --
	  Execute pInsStudents
	      @StudentNumber 	  = @OutputStudentNumber 	 
	     ,@StudentFirstName   = @OutputStudentFirstName
	     ,@StudentLastName    = @OutputStudentLastName 
	     ,@StudentEmail 	  = @OutputStudentEmail 	 
	     ,@StudentPhone 	  = @OutputStudentPhone 	 
	     ,@StudentAddress1    = @OutputStudentAddress1 
	     ,@StudentAddress2    = @OutputStudentAddress2 
	     ,@StudentCity 	      = @OutputStudentCity 	 
	     ,@StudentStateCode   = @OutputStudentStateCode
	     ,@StudentZipCode     = @OutputStudentZipCode  
	  ;

	-- Clean data for Enrollments Table --
	  -- date/time and price
	  Declare @OutputEnrollmentDateTime datetime = (Select Value From RawInputData Where Row_Num = 14);
	  Declare @OutputEnrollmentPrice money = (Select Value From RawInputData Where Row_Num = 15);
	  -- must link enrollment with CourseID and StudentID, use inputted information that has uq constraints to ensure the right student/course is selected
	  Declare @OutputCourseID int = (Select CourseID From tCourses Where CourseName = @OutputCourseName);
	  Declare @OutputStudentID int = (Select StudentID From tStudents Where StudentNumber = @OutputStudentNumber);

	-- Insert cleaned data into Enrollments Table --
	  Execute pInsEnrollments
	    @StudentID            = @OutputStudentID         
	   ,@CourseID             = @OutputCourseID          
	   ,@EnrollmentDateTime   = @OutputEnrollmentDateTime
	   ,@EnrollmentPrice   	  = @OutputEnrollmentPrice   
	   ;

	   -- drop all tables created in this execution of pInputData
       Drop Table CourseDates;
	   Drop Table RawInputData;
	   Drop Table InputAddress;
	   Drop Table InputStudentFullName;

	   -- used while troubleshooting pInputData sproc
       /*
	   Select * From Courses;
	   Select * From Students;
	   Select * From Enrollments;
       */
 End
go


-- Putting the data from the CSV file through the InputData sproc

Execute pInputData 
  @InputString = 'SQL1 - Winter 2017,1/10/2017 to 1/24/2017 ,6PM,8:50PM,T,399,Bob Smith,B-Smith-071,Bsmith@HipMail.com,(206)-111-2222,"123 Main St. Seattle, WA., 98001",1/3/2017,399'
;
Execute pInputData
  @InputString = 'SQL1 - Winter 2017,1/10/2017 to 1/24/2017 ,6PM,8:50PM,T,399,Sue Jones,S-Jones-003,SueJones@YaYou.com,(206)-231-4321,"333 1st Ave. Seattle, WA., 98001",12/14/2016,349'
;
Execute pInputData
  @InputString = 'SQL2 - Winter 2017,1/31/2017 to 2/14/2017,6PM,8:50PM,T,399,Sue Jones,S-Jones-003,SueJones@YaYou.com,(206)-231-4321,"333 1st Ave. Seattle, WA., 98001",12/14/2016,349'
;
Execute pInputData
  @InputString = 'SQL2 - Winter 2017,1/31/2017 to 2/14/2017,6PM,8:50PM,T,399,Bob Smith,B-Smith-071,Bsmith@HipMail.com,(206)-111-2222,"123 Main St. Seattle, WA., 98001",1/12/2017,399'
;

-- Final check to see inserted data
Select * From Courses;
Select * From Students;
Select * From Enrollments;



--{ IMPORTANT }--
-- To get full credit, your script must run without having to highlight individual statements!!!  
/**************************************************************************************************/

