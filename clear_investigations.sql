-- ==========================================================================
-- SQL SCRIPT: CLEAR / EMPTY ALL INVESTIGATION TABLES & RESET IDENTITY
-- Target Database: law_project
-- ==========================================================================

USE [law_project];
GO

SET NOCOUNT ON;
BEGIN TRANSACTION;

PRINT N'⏳ جاري تفريغ جداول التحقيقات بالكامل بالترتيب الصحيح لمنع أخطاء الـ Foreign Keys...';

DELETE FROM InvestigationWitnesses;
DELETE FROM FinalMemos;
DELETE FROM FinalDecisions;
DELETE FROM Appeals;
DELETE FROM InvestigationDecisions;
DELETE FROM Summons;
DELETE FROM InvestigationEmployees;

IF OBJECT_ID('InvestigationNotifications', 'U') IS NOT NULL 
    DELETE FROM InvestigationNotifications WHERE EntityUrl LIKE '%investigation%';

DELETE FROM Investigations;

-- إعادة ضبط تسلسل الـ Identity لجدول Investigations ليبدأ من 1 مجدداً
DBCC CHECKIDENT ('Investigations', RESEED, 0);

COMMIT TRANSACTION;

PRINT N'====================================================================';
PRINT N'✅ تم تفريغ جميع جداول التحقيقات بنجاح وتصفير العداد (Identity Reseeded).';
PRINT N'====================================================================';
