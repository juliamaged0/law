-- ==========================================================================
-- SQL SCRIPT: RESTRUCTURE & IMPORT 349 INVESTIGATIONS (ديوان عام أ & ب 2026)
-- Target Database: law_project
-- Total Investigations: Exactly 349 (194 Type أ + 155 Type ب)
-- Generated on: 2026-10-20T18:42:32.007Z
-- ==========================================================================

USE [law_project];
GO

-- 1. التأكد من وجود الأعمدة الجديدة بجدول التحقيقات (Investigations)
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='Investigations' AND COLUMN_NAME='ClaimValue')
BEGIN
    ALTER TABLE Investigations ADD ClaimValue NVARCHAR(255) NULL;
    PRINT N'✅ تم إضافة عمود ClaimValue (القيمة المادية) لجدول Investigations';
END;
GO

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='Investigations' AND COLUMN_NAME='ReceiptDate')
BEGIN
    ALTER TABLE Investigations ADD ReceiptDate DATE NULL;
    PRINT N'✅ تم التأكد من عمود ReceiptDate بجدول Investigations';
END;
GO

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='Investigations' AND COLUMN_NAME='Plaintiff')
BEGIN
    ALTER TABLE Investigations ADD Plaintiff NVARCHAR(255) NULL;
    PRINT N'✅ تم إضافة عمود Plaintiff (مرفوع من) لجدول Investigations';
END;
GO

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='Investigations' AND COLUMN_NAME='Defendant')
BEGIN
    ALTER TABLE Investigations ADD Defendant NVARCHAR(255) NULL;
    PRINT N'✅ تم إضافة عمود Defendant (ضد) لجدول Investigations';
END;
GO

-- 2. مسح بيانات التحقيقات القديمة بالترتيب الصحيح لمنع أخطاء الـ Foreign Keys وإدراج الـ 349 تحقيق
SET NOCOUNT ON;
BEGIN TRANSACTION;

DECLARE @InvId INT;
DECLARE @EmpMasterId INT;
DECLARE @NewCode NVARCHAR(50);

PRINT N'⏳ جاري مسح بيانات التحقيقات القديمة...';
DELETE FROM InvestigationWitnesses;
DELETE FROM FinalMemos;
DELETE FROM FinalDecisions;
DELETE FROM Appeals;
DELETE FROM InvestigationDecisions;
DELETE FROM Summons;
DELETE FROM InvestigationEmployees;
IF OBJECT_ID('InvestigationNotifications', 'U') IS NOT NULL DELETE FROM InvestigationNotifications WHERE EntityUrl LIKE '%investigation%';
DELETE FROM Investigations;

-- إعادة ضبط تسلسل الـ Identity لجدول Investigations
DBCC CHECKIDENT ('Investigations', RESEED, 0);
PRINT N'✅ تم مسح البيانات وتصفير عداد الـ Id للتحقيقات.';

-- 3. إدراج التحقيقات الـ 349 من ملفات الإكسل
PRINT N'⏳ جاري إدراج بيانات الـ 349 تحقيق...';

-- --------------------------------------------------------------------------
-- تحقيقات ديوان عام (أ) 2026 (نوع أ) - من رقم 1 إلى رقم 194 (إجمالي: 194 تحقيق)
-- --------------------------------------------------------------------------

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'1',
        '2026-01-15',
        '2026-01-15',
        N'أ',
        N'ايمن توفيق',
        N'الشكوى المقدمة من أ/محمد سعد ضد الفنى/احمد خميس يوسف حيث المذكور تحدث بأسلوب غير لائق',
        '2026-01-15',
        N'ديوان عام الشركة',
        N'الشكوى المقدمة من أ/محمد سعد ضد الفنى/احمد خميس يوسف حيث المذكور تحدث بأسلوب غير لائق',
        N'جارية',
        NULL,
        N'محمد سعد',
        N'الفنى/احمد خميس يوسف',
        '2026-01-15 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: احمد خميس يوسف
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'احمد خميس يوسف';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%احمد خميس يوسف%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'احمد خميس يوسف', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'2',
        '2026-01-02',
        '2026-01-02',
        N'أ',
        N'ايمن توفيق',
        N'السائق/ تامر مصطفى اتلاف ماتاور السيارة رقم (3936) مماادى لدخول السيارة فى عمرة ماتور كاملة من التحقيق مع مسئول السيارة بالادارة العامة للسيارات الركوب لاهمالة فى مهام عملة',
        '2026-01-02',
        N'ادارة العامة للسيارات الركوب لاهمالة',
        N'السائق/ تامر مصطفى اتلاف ماتاور السيارة رقم (3936) مماادى لدخول السيارة فى عمرة ماتور كاملة من التحقيق مع مسئول السيارة بالادارة العامة للسيارات الركوب لاهمالة فى مهام عملة',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'تامر مصط',
        '2026-01-02 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: تامر مصط
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'تامر مصط';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%تامر مصط%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'تامر مصط', N'موظف', N'ادارة العامة للسيارات الركوب لاهمالة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'3',
        '2026-01-18',
        '2026-01-18',
        N'أ',
        N'اشرف عبد العظيم',
        N'قيام بعض المحامين بالادارة العامة للشؤن القانونية الموظفين بالشركة برفع الدعوى قضائية علية بالشركة بدون وجود وكالة المحامية',
        '2026-01-18',
        N'ادارة العامة للشؤن القانونية الموظفين',
        N'قيام بعض المحامين بالادارة العامة للشؤن القانونية الموظفين بالشركة برفع الدعوى قضائية علية بالشركة بدون وجود وكالة المحامية',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'بعض المحامين بالادارة العامة للشؤن',
        '2026-01-18 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: بعض المحامين بالادارة العامة للشؤن
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'بعض المحامين بالادارة العامة للشؤن';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%بعض المحامين بالادارة العامة للشؤن%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'بعض المحامين بالادارة العامة للشؤن', N'موظف', N'ادارة العامة للشؤن القانونية الموظفين', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-03-15', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 15/3/2026 اعادة عرض 1/4/2026 | |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'4',
        '2026-01-19',
        '2026-01-19',
        N'أ',
        N'تامر الحداد',
        N'عدم استلام الاستاذ المحامي/ياسر الشربينى ملف مذكرة لهيئة الاثار بالاسكندرية بمبلغ 15104318 جنية',
        '2026-01-19',
        N'ديوان عام الشركة',
        N'عدم استلام الاستاذ المحامي/ياسر الشربينى ملف مذكرة لهيئة الاثار بالاسكندرية بمبلغ 15104318 جنية',
        N'جارية',
        N'15104318 جنيه',
        N'شركة الصرف الصحي بالإسكندرية',
        N'ياسر الشربينى ملف مذكرة',
        '2026-01-19 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: ياسر الشربينى ملف مذكرة
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'ياسر الشربينى ملف مذكرة';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%ياسر الشربينى ملف مذكرة%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'ياسر الشربينى ملف مذكرة', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'5',
        '2026-01-19',
        '2026-01-19',
        N'أ',
        N'نرمين قنديل',
        N'قيام شركة دلتامك محمد حسين بعملية تاهيل بمحطة 2العجمى محطة 3 العجمى وسهلة نشأت وعدم افادة اجراء حتى تاريخة',
        '2026-01-19',
        N'بمحطة 2العجمى محطة 3 العجمى وسهلة',
        N'قيام شركة دلتامك محمد حسين بعملية تاهيل بمحطة 2العجمى محطة 3 العجمى وسهلة نشأت وعدم افادة اجراء حتى تاريخة',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'شركة دلتامك محمد حسين ب',
        '2026-01-19 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: شركة دلتامك محمد حسين ب
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'شركة دلتامك محمد حسين ب';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%شركة دلتامك محمد حسين ب%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'شركة دلتامك محمد حسين ب', N'موظف', N'بمحطة 2العجمى محطة 3 العجمى وسهلة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'6',
        '2026-01-18',
        '2026-01-18',
        N'أ',
        N'ريهام شفيق',
        N'قيام الفنى/ محمد عبد الرازق ابراهيم نام داخل المسجد المحطة بالوردية الثالثة',
        '2026-01-18',
        N'محطة بالوردية الثالثة',
        N'قيام الفنى/ محمد عبد الرازق ابراهيم نام داخل المسجد المحطة بالوردية الثالثة',
        N'مغلقة',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'محمد عبد الرازق ابراهيم',
        '2026-01-18 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: محمد عبد الرازق ابراهيم
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمد عبد الرازق ابراهيم';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمد عبد الرازق ابراهيم%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمد عبد الرازق ابراهيم', N'موظف', N'محطة بالوردية الثالثة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-01-22', N'رئيس مجلس الإدارة', N'مجازاة بخصم من الراتب', N'3 ايام من الراتب', N'عرض على ر.م.أ 22/1/2026 | ورد من ر.م.أ 8/2/2026 | تم الانتهاء بمجازات السيد/ محمد عبد الرازق 3 ايام من الراتب', GETDATE());
    INSERT INTO FinalDecisions (InvestigationId, FinalDecisionText, ActionType, HRSentDate, HRNotes, CreatedAt)
    VALUES (@InvId, N'تم الانتهاء  بمجازات السيد/ محمد عبد الرازق 3 ايام من الراتب', 'hr', '2026-01-22', N'عرض على ر.م.أ 22/1/2026 | ورد من ر.م.أ 8/2/2026 | تم الانتهاء بمجازات السيد/ محمد عبد الرازق 3 ايام من الراتب', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'7',
        '2026-01-19',
        '2026-01-19',
        N'أ',
        N'ايناس جلال',
        N'المرور على محطة الكوبانية يوم الاثنين 5/1/2026 الساعة 9 ص تلاحظ تواجد عدم تلاحظ افراد الوردية بالوردية مع العلم قد تم البنية بفردين فقط',
        '2026-01-05',
        N'محطة الكوبانية',
        N'المرور على محطة الكوبانية يوم الاثنين 5/1/2026 الساعة 9 ص تلاحظ تواجد عدم تلاحظ افراد الوردية بالوردية مع العلم قد تم البنية بفردين فقط',
        N'صدر قرار',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'موظف محال للتحقيق',
        '2026-01-19 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'محطة الكوبانية', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-05-10', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 10/5/2026 | ورد من ر.م.أ 14/5/2026 |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'8',
        '2026-01-22',
        '2026-01-22',
        N'أ',
        N'شعبان السيد',
        N'المرور على موقع الرأس السودا يوم السبت الموافق 27/12/2025 ووجود مخالفات وتقصيرة فى مهام اعمالهم 1- سامى محمد 2- سعد السيد احمد',
        '2025-12-27',
        N'موقع الرأس السودا',
        N'المرور على موقع الرأس السودا يوم السبت الموافق 27/12/2025 ووجود مخالفات وتقصيرة فى مهام اعمالهم 1- سامى محمد 2- سعد السيد احمد',
        N'صدر قرار',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'سامى محمد, سعد السيد احمد',
        '2026-01-22 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: سامى محمد
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'سامى محمد';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%سامى محمد%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'سامى محمد', N'موظف', N'موقع الرأس السودا', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: سعد السيد احمد
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'سعد السيد احمد';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%سعد السيد احمد%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'سعد السيد احمد', N'موظف', N'موقع الرأس السودا', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-01-22', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض | |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'9',
        '2026-01-19',
        '2026-01-19',
        N'أ',
        N'هانى احمد',
        N'المرور على محطة معالجة ك 26 ,ك 21 ومعالجة الهانوفيل تلاحظ عدم تواجد العدد المسموح بة من العاملين',
        '2026-01-19',
        N'محطة معالجة ك 26',
        N'المرور على محطة معالجة ك 26 ,ك 21 ومعالجة الهانوفيل تلاحظ عدم تواجد العدد المسموح بة من العاملين',
        N'صدر قرار',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'موظف محال للتحقيق',
        '2026-01-19 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'محطة معالجة ك 26', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-04-08', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 8/4/2026 | ورد من ر.م.أ 14/4/2026 |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'10',
        '2026-01-18',
        '2026-01-18',
        N'أ',
        N'وفاء رمزى',
        N'عدم تواجد احد بموقع هوافدى يوم 2/1/2026 الساعة 3:35 ص',
        '2026-01-02',
        N'بموقع هوافدى',
        N'عدم تواجد احد بموقع هوافدى يوم 2/1/2026 الساعة 3:35 ص',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'موظف محال للتحقيق',
        '2026-01-18 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'بموقع هوافدى', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-04-08', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 8/4/2026 | ورد من ر.م.أ 14/4/2026 |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'11',
        '2026-01-18',
        '2026-01-18',
        N'أ',
        N'غادة شكرى',
        N'المرور على محطة ابيس 11/8 يوم الخميس الموافق 8/1/2026 الساعة 11:30 اثناء النوة وجود انبوبة بوتجاز بحمام المحطة',
        '2026-01-08',
        N'محطة ابيس 11',
        N'المرور على محطة ابيس 11/8 يوم الخميس الموافق 8/1/2026 الساعة 11:30 اثناء النوة وجود انبوبة بوتجاز بحمام المحطة',
        N'مغلقة',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'موظف محال للتحقيق',
        '2026-01-18 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'محطة ابيس 11', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-02-04', N'رئيس مجلس الإدارة', N'حفظ التحقيق', N'يوم', N'عرض على ر.م.أ 4/2/2026 | ورد من ر.م.أ 23/2/2026 | تم الانتهاء بمجازاة السيد/ محمد طلعت حسن بخصم يوم وحفظ التحقيق بالنسبة لخميس سعيد عبدالعاطى', GETDATE());
    INSERT INTO FinalDecisions (InvestigationId, FinalDecisionText, ActionType, HRSentDate, HRNotes, CreatedAt)
    VALUES (@InvId, N'تم الانتهاء  بمجازاة السيد/ محمد طلعت حسن بخصم يوم وحفظ التحقيق بالنسبة لخميس سعيد عبدالعاطى', 'archive', '2026-02-04', N'عرض على ر.م.أ 4/2/2026 | ورد من ر.م.أ 23/2/2026 | تم الانتهاء بمجازاة السيد/ محمد طلعت حسن بخصم يوم وحفظ التحقيق بالنسبة لخميس سعيد عبدالعاطى', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'12',
        '2026-01-18',
        '2026-01-18',
        N'أ',
        N'شعبان السيد',
        N'امتناع السائق احمد مختار عبد العزيز كود 8541 عن العمل يوم 29/12/2026 اثناء التمركزات',
        '2026-12-29',
        N'ديوان عام الشركة',
        N'امتناع السائق احمد مختار عبد العزيز كود 8541 عن العمل يوم 29/12/2026 اثناء التمركزات',
        N'مغلقة',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'السائق احمد مختار عبد العزيز',
        '2026-01-18 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: احمد مختار عبد العزيز
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE Code = N'8541';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'احمد مختار عبد العزيز';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%احمد مختار عبد العزيز%';
    IF @EmpMasterId IS NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM EmployeesMaster WHERE Code = N'8541')
            SET @NewCode = N'8541';
        ELSE
            SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'احمد مختار عبد العزيز', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-02-19', N'رئيس مجلس الإدارة', N'حفظ التحقيق', N'حفظ التحقيق', N'عرض على ر.م.أ 19/2/2026 | ورد من ر.م.أ 25/2/2026 | تم الانتهاء بلحفظ', GETDATE());
    INSERT INTO FinalDecisions (InvestigationId, FinalDecisionText, ActionType, HRSentDate, HRNotes, CreatedAt)
    VALUES (@InvId, N'تم الانتهاء بلحفظ', 'archive', '2026-02-19', N'عرض على ر.م.أ 19/2/2026 | ورد من ر.م.أ 25/2/2026 | تم الانتهاء بلحفظ', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'13',
        '2026-01-25',
        '2026-01-25',
        N'أ',
        N'نورة عباس',
        N'مرور الامن يوم 3/1/2026 بالوردية الصباحية تلاحظ محطة ابيس 12/8 الساعة 1:30 مغلقة محطة ابيس 11/8 الساعة 1:40 لا يوجد احد من العاملين',
        '2026-01-03',
        N'محطة ابيس 12',
        N'مرور الامن يوم 3/1/2026 بالوردية الصباحية تلاحظ محطة ابيس 12/8 الساعة 1:30 مغلقة محطة ابيس 11/8 الساعة 1:40 لا يوجد احد من العاملين',
        N'صدر قرار',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'موظف محال للتحقيق',
        '2026-01-25 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'محطة ابيس 12', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-02-17', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 17/2/2026 | ورد من ر.م.أ 22/2/2026 |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'14',
        '2026-01-19',
        '2026-01-19',
        N'أ',
        N'خالد احمد',
        N'الشكوى المقدمة من السيد/ حمدى احمد صبحى بشأن تواجد شخص غريب بتمتع العامل من الركاب بأتوبيس التنقية الشرقية',
        '2026-01-19',
        N'ديوان عام الشركة',
        N'الشكوى المقدمة من السيد/ حمدى احمد صبحى بشأن تواجد شخص غريب بتمتع العامل من الركاب بأتوبيس التنقية الشرقية',
        N'صدر قرار',
        NULL,
        N'السيد/ حمدى احمد صبحى',
        N'من الركاب بأتوبيس التنقية الشرقية',
        '2026-01-19 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: من الركاب بأتوبيس التنقية الشرقية
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'من الركاب بأتوبيس التنقية الشرقية';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%من الركاب بأتوبيس التنقية الشرقية%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'من الركاب بأتوبيس التنقية الشرقية', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-01-19', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض | |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'15',
        '2026-01-18',
        '2026-01-18',
        N'أ',
        N'شعبان السيد',
        N'الشكوى المقدمة من السيد/ اسماعيل السيد ذكى من السيد/ محمد مصطفى احمد احمد',
        '2026-01-18',
        N'ديوان عام الشركة',
        N'الشكوى المقدمة من السيد/ اسماعيل السيد ذكى من السيد/ محمد مصطفى احمد احمد',
        N'صدر قرار',
        NULL,
        N'السيد/ اسماعيل السيد ذكى من السيد/ محمد مصطفى احمد احمد',
        N'موظف محال للتحقيق',
        '2026-01-18 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-04-01', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 1/4/2026 | ورد من ر.م.أ 18/4/2026 |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'16',
        '2026-01-22',
        '2026-01-22',
        N'أ',
        N'صباح رمضان',
        N'قيام الكهربائى / محمد على السيد يوم الثلاثاء الموافق 6/1/2026 فقد مفتاح مبنى المحطة ومدير عام المحطة التنقية الشرقية',
        '2026-01-06',
        N'محطة ومدير عام المحطة التنقية الشرقية',
        N'قيام الكهربائى / محمد على السيد يوم الثلاثاء الموافق 6/1/2026 فقد مفتاح مبنى المحطة ومدير عام المحطة التنقية الشرقية',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'موظف محال للتحقيق',
        '2026-01-22 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'محطة ومدير عام المحطة التنقية الشرقية', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-03-12', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 12/3/2026 | ورد من ر.م.أ 15/3/2026 |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'17',
        '2026-01-13',
        '2026-01-13',
        N'أ',
        N'خالد احمد',
        N'الشكوى المقدمة من مدير عام معالجات غرب مهندس/ احمد عبد الفتاح بتوقيع المتعهد حسن ابو سمرة مدير معالجة الكيلو 21 بدلا منةالشكوى المقدمة من المهندس / احمد عبد الفتاح عيد ضد المهندس / حسن ابوسمرة والتعدى علية لفظاً',
        '2026-01-13',
        N'ديوان عام الشركة',
        N'الشكوى المقدمة من مدير عام معالجات غرب مهندس/ احمد عبد الفتاح بتوقيع المتعهد حسن ابو سمرة مدير معالجة الكيلو 21 بدلا منةالشكوى المقدمة من المهندس / احمد عبد الفتاح عيد ضد المهندس / حسن ابوسمرة والتعدى علية لفظاً',
        N'جارية',
        NULL,
        N'مدير عام معالجات غرب مهندس/ احمد عبد الفتاح بتوقيع المتعهد حسن ابو سمرة مدير معالجة الكيلو 21 بدلا منةالشكوى المقدمة من المهندس / احمد عبد الفتاح عيد',
        N'المهندس / حسن ابوسمرة والتعدى علية لفظاً',
        '2026-01-13 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: / حسن ابوسمرة والتعدى علية لفظاً
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'/ حسن ابوسمرة والتعدى علية لفظاً';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%/ حسن ابوسمرة والتعدى علية لفظاً%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'/ حسن ابوسمرة والتعدى علية لفظاً', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'18',
        '2026-01-01',
        NULL,
        N'أ',
        N'غير مسند',
        N'تحقيق ديوان عام أ رقم 18',
        '2026-01-01',
        N'ديوان عام الشركة',
        N'تحقيق ديوان عام أ رقم 18',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'موظف محال للتحقيق',
        '2026-01-01 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'19',
        '2026-01-22',
        '2026-01-22',
        N'أ',
        N'شعبان السيد',
        N'المرور على محطة معالجة مبارك يوم الجمعة 9/1/2026 الساعة 8ك15ص تلاحظ وجود الفنى / محمد ابو يزيد وعلية اثار نوم ووجود شيشة وسرير مجهز بالمحطة',
        '2026-01-09',
        N'محطة معالجة مبارك',
        N'المرور على محطة معالجة مبارك يوم الجمعة 9/1/2026 الساعة 8ك15ص تلاحظ وجود الفنى / محمد ابو يزيد وعلية اثار نوم ووجود شيشة وسرير مجهز بالمحطة',
        N'صدر قرار',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'محمد ابو يزيد وعلية اثار',
        '2026-01-22 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: محمد ابو يزيد وعلية اثار
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمد ابو يزيد وعلية اثار';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمد ابو يزيد وعلية اثار%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمد ابو يزيد وعلية اثار', N'موظف', N'محطة معالجة مبارك', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-04-01', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 1/4/2026 | ورد من ر.م.أ 5/4/2026 |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'20',
        '2026-01-25',
        '2026-01-25',
        N'أ',
        N'هدى رجب',
        N'فقد اذن التشغيل رقم 32655 يوم 8/1/2026 من السائق /محمد محمود احمد',
        '2026-01-08',
        N'ديوان عام الشركة',
        N'فقد اذن التشغيل رقم 32655 يوم 8/1/2026 من السائق /محمد محمود احمد',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'محمد محمود احمد',
        '2026-01-25 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: محمد محمود احمد
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE Code = N'32655';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمد محمود احمد';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمد محمود احمد%';
    IF @EmpMasterId IS NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM EmployeesMaster WHERE Code = N'32655')
            SET @NewCode = N'32655';
        ELSE
            SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمد محمود احمد', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-05-05', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 5/5/2026 | ورد من ر.م.أ 6/5/2026 |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'21',
        '2026-01-19',
        '2026-01-19',
        N'أ',
        N'خالد احمد',
        N'فقد السائق /احمد السيد عثمان يوم 24/12/2025 اذن التشغيل الخامس بالسياره رقم1421',
        '2025-12-24',
        N'ديوان عام الشركة',
        N'فقد السائق /احمد السيد عثمان يوم 24/12/2025 اذن التشغيل الخامس بالسياره رقم1421',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'احمد السيد عثمان',
        '2026-01-19 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: احمد السيد عثمان
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE Code = N'1421';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'احمد السيد عثمان';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%احمد السيد عثمان%';
    IF @EmpMasterId IS NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM EmployeesMaster WHERE Code = N'1421')
            SET @NewCode = N'1421';
        ELSE
            SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'احمد السيد عثمان', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-01-19', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض | |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'22',
        '2026-01-21',
        '2026-01-21',
        N'أ',
        N'طارق السيد',
        N'مرور الامن يوم 7/1/2026الساعه 4 م تلاحظ قيام الفني / احمد حسنين',
        '2026-01-07',
        N'ديوان عام الشركة',
        N'مرور الامن يوم 7/1/2026الساعه 4 م تلاحظ قيام الفني / احمد حسنين',
        N'جارية',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'احمد حسنين',
        '2026-01-21 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: احمد حسنين
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'احمد حسنين';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%احمد حسنين%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'احمد حسنين', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'23',
        '2026-01-22',
        '2026-01-22',
        N'أ',
        N'نرمين قنديل',
        N'متابعة خروج السيارات المتواجدة بالتمركزات بالشركة يوم 15/1/2026 من 7ص حت 7م',
        '2026-01-15',
        N'ديوان عام الشركة',
        N'متابعة خروج السيارات المتواجدة بالتمركزات بالشركة يوم 15/1/2026 من 7ص حت 7م',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'موظف محال للتحقيق',
        '2026-01-22 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'24',
        '2026-01-25',
        '2026-01-25',
        N'أ',
        N'مروة حمزة',
        N'سرقة واقى المقر الخاص بالفنى/ خالد محمود محمد من العامل ابراهيم ابو حمزة عيادى',
        '2026-01-25',
        N'ديوان عام الشركة',
        N'سرقة واقى المقر الخاص بالفنى/ خالد محمود محمد من العامل ابراهيم ابو حمزة عيادى',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'خالد محمود محمد من العامل',
        '2026-01-25 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: خالد محمود محمد من العامل
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'خالد محمود محمد من العامل';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%خالد محمود محمد من العامل%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'خالد محمود محمد من العامل', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-03-31', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 31/3/2026 | ورد من ر.م.أ 3/4/2026 |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'25',
        '2026-01-22',
        '2026-01-22',
        N'أ',
        N'صباح رمضان',
        N'فقد اذن التشغيل رقم 33103 بالسيارة 6535 يوم 6/1/2026 قيادة السائق/ رامى لطيف عبد الحميد',
        '2026-01-06',
        N'ديوان عام الشركة',
        N'فقد اذن التشغيل رقم 33103 بالسيارة 6535 يوم 6/1/2026 قيادة السائق/ رامى لطيف عبد الحميد',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'رامى لطيف عبد الحميد',
        '2026-01-22 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: رامى لطيف عبد الحميد
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE Code = N'33103';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'رامى لطيف عبد الحميد';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%رامى لطيف عبد الحميد%';
    IF @EmpMasterId IS NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM EmployeesMaster WHERE Code = N'33103')
            SET @NewCode = N'33103';
        ELSE
            SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'رامى لطيف عبد الحميد', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-03-03', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 3/3/2026 | ورد من ر.م.أ 4/3/2026 |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'26',
        '2026-01-23',
        '2026-01-23',
        N'أ',
        N'ايمن توفيق',
        N'مخالفة كلا من 1- مدير ادارة المحطات 2- ايمن عبد المنعم عبد الله 3- سمير ابراهيم فرج بالعمل ورديتين يوميا بمحطة 3 العجمى',
        '2026-01-23',
        N'بمحطة 3 العجمى',
        N'مخالفة كلا من 1- مدير ادارة المحطات 2- ايمن عبد المنعم عبد الله 3- سمير ابراهيم فرج بالعمل ورديتين يوميا بمحطة 3 العجمى',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'كلا من 1',
        '2026-01-23 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: مدير ادارة المحطات
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'مدير ادارة المحطات';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%مدير ادارة المحطات%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'مدير ادارة المحطات', N'موظف', N'بمحطة 3 العجمى', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: ايمن عبد المنعم عبد الله
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'ايمن عبد المنعم عبد الله';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%ايمن عبد المنعم عبد الله%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'ايمن عبد المنعم عبد الله', N'موظف', N'بمحطة 3 العجمى', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: سمير ابراهيم فرج بالعمل ورديتين
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'سمير ابراهيم فرج بالعمل ورديتين';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%سمير ابراهيم فرج بالعمل ورديتين%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'سمير ابراهيم فرج بالعمل ورديتين', N'موظف', N'بمحطة 3 العجمى', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'27',
        '2026-01-22',
        '2026-01-22',
        N'أ',
        N'ريهام شفيق',
        N'رفض كلامن السائق خالد يوسف عبد الرحيم السائق محمد سمير حسن تحميل النقلة الثالثة من الساعة 5ص',
        '2026-01-22',
        N'ديوان عام الشركة',
        N'رفض كلامن السائق خالد يوسف عبد الرحيم السائق محمد سمير حسن تحميل النقلة الثالثة من الساعة 5ص',
        N'مغلقة',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'خالد يوسف عبد الرحيم السائق',
        '2026-01-22 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: خالد يوسف عبد الرحيم السائق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'خالد يوسف عبد الرحيم السائق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%خالد يوسف عبد الرحيم السائق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'خالد يوسف عبد الرحيم السائق', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-02-04', N'رئيس مجلس الإدارة', N'حفظ التحقيق', N'حفظ التحقيق', N'عرض على ر.م.أ 4/2/2026 | ورد من ر.م.أ 6/2/2026 | تم الانتهاء بحفظ الملف', GETDATE());
    INSERT INTO FinalDecisions (InvestigationId, FinalDecisionText, ActionType, HRSentDate, HRNotes, CreatedAt)
    VALUES (@InvId, N'تم الانتهاء بحفظ الملف', 'archive', '2026-02-04', N'عرض على ر.م.أ 4/2/2026 | ورد من ر.م.أ 6/2/2026 | تم الانتهاء بحفظ الملف', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'28',
        '2026-01-27',
        '2026-01-27',
        N'أ',
        N'غادة شكرى',
        N'الشكوى المقدمة من السائق عمرو محمد عبدالله بتعدى كلا من علية السائق هانى ابراهيم والسائق حسام نور منطقة العامرية',
        '2026-01-27',
        N'منطقة العامرية',
        N'الشكوى المقدمة من السائق عمرو محمد عبدالله بتعدى كلا من علية السائق هانى ابراهيم والسائق حسام نور منطقة العامرية',
        N'صدر قرار',
        NULL,
        N'السائق عمرو محمد عبدالله بتعدى كلا من',
        N'عمرو محمد عبدالله بتعدى كلا',
        '2026-01-27 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: عمرو محمد عبدالله بتعدى كلا
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'عمرو محمد عبدالله بتعدى كلا';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%عمرو محمد عبدالله بتعدى كلا%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'عمرو محمد عبدالله بتعدى كلا', N'موظف', N'منطقة العامرية', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-02-12', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 12/2/2026 | ورد من ر.م.أ 12/2/2026 |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'29',
        '2026-02-02',
        '2026-02-02',
        N'أ',
        N'ريهام شفيق',
        N'الشكوى المقدمة من السائق محمود احمد محمد عبدالله ضد السيد اسلام الطحان لعمل شغل غير رسمى وتفاوض مبلغ مالى',
        '2026-02-02',
        N'ديوان عام الشركة',
        N'الشكوى المقدمة من السائق محمود احمد محمد عبدالله ضد السيد اسلام الطحان لعمل شغل غير رسمى وتفاوض مبلغ مالى',
        N'صدر قرار',
        NULL,
        N'محمود احمد محمد عبدالله',
        N'السيد اسلام الطحان لعمل شغل غير رسمى وتفاوض مبلغ مالى',
        '2026-02-02 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: اسلام الطحان لعمل شغل غير رسمى وتفاوض مبلغ مالى
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'اسلام الطحان لعمل شغل غير رسمى وتفاوض مبلغ مالى';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%اسلام الطحان لعمل شغل غير رسمى وتفاوض مبلغ مالى%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'اسلام الطحان لعمل شغل غير رسمى وتفاوض مبلغ مالى', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-04-01', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 1/4/2026 | ورد من ر.م.أ 5/4/2026 |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'30',
        '2026-01-02',
        '2026-01-02',
        N'أ',
        N'تامر الحداد',
        N'الشكوى المقدمة من رئيس القطاع المالى والادارى ضد مدير عام',
        '2026-01-02',
        N'قطاع المالى والادارى ضد مدير',
        N'الشكوى المقدمة من رئيس القطاع المالى والادارى ضد مدير عام',
        N'صدر قرار',
        NULL,
        N'رئيس القطاع المالى والادارى',
        N'مدير عام',
        '2026-01-02 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: مدير عام
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'مدير عام';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%مدير عام%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'مدير عام', N'موظف', N'قطاع المالى والادارى ضد مدير', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-05-05', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 5/5/2026 | ورد من ر.م.أ 6/5/2026 |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'31',
        '2026-01-02',
        '2026-01-02',
        N'أ',
        N'خالد احمد',
        N'المرور على محطة مراقبة الوقت السيوف يوم 21/1/2026 بالوردية الاولى الساعة 9:45',
        '2026-01-21',
        N'محطة مراقبة الوقت السيوف',
        N'المرور على محطة مراقبة الوقت السيوف يوم 21/1/2026 بالوردية الاولى الساعة 9:45',
        N'جارية',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'موظف محال للتحقيق',
        '2026-01-02 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'محطة مراقبة الوقت السيوف', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'32',
        '2026-01-28',
        '2026-01-28',
        N'أ',
        N'هدى رجب',
        N'عدم تنفيذ كلا من السائق احمد عصام محمد والسائق احمد عبد السميع احمد التعليمات اثناء النوة',
        '2026-01-28',
        N'ديوان عام الشركة',
        N'عدم تنفيذ كلا من السائق احمد عصام محمد والسائق احمد عبد السميع احمد التعليمات اثناء النوة',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'احمد عصام محمد والسائق احمد',
        '2026-01-28 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: احمد عصام محمد والسائق احمد
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'احمد عصام محمد والسائق احمد';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%احمد عصام محمد والسائق احمد%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'احمد عصام محمد والسائق احمد', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-04-22', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 22/4/2026 | ورد من ر.م.أ 29/4/2026 |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'33',
        '2026-01-27',
        '2026-01-27',
        N'أ',
        N'ايمن توفيق',
        N'سرقة بعض الاصناف الحديدية من محطة اسكان مرغم يوم 13/1/2026 عند استلام الوردية الثالثة من الوردية الثالثة',
        '2026-01-13',
        N'محطة اسكان مرغم',
        N'سرقة بعض الاصناف الحديدية من محطة اسكان مرغم يوم 13/1/2026 عند استلام الوردية الثالثة من الوردية الثالثة',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'موظف محال للتحقيق',
        '2026-01-27 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'محطة اسكان مرغم', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'34',
        '2026-02-02',
        '2026-02-02',
        N'أ',
        N'خالد احمد',
        N'المرور على محطات الشركة يومين 22"24/1/2026 محطة ابو تلات مغلقة الساعة 12م ومحطة رفع طوسون مغلقة الساعة 10:15 ص محطة ابو قير عدم الاطلاع على السجل',
        '2026-01-24',
        N'محطة ابو تلات مغلقة',
        N'المرور على محطات الشركة يومين 22"24/1/2026 محطة ابو تلات مغلقة الساعة 12م ومحطة رفع طوسون مغلقة الساعة 10:15 ص محطة ابو قير عدم الاطلاع على السجل',
        N'جارية',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'موظف محال للتحقيق',
        '2026-02-02 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'محطة ابو تلات مغلقة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'35',
        '2026-03-02',
        '2026-03-02',
        N'أ',
        N'وفاء رمزى',
        N'واقعه شركه كلابلات يوم 17/11/2026 المسولين 1-محمد ريحان محمد 2-نادر عيد الناصريه واقعه سرقه كابلات يوم 23/1/2026 المسؤلين 1-سامي محمد جوده 2-رمضان صبحي عبد الحميد بان فى يوم الثلاثاء 27/1/2026 تم اكتشاف وجود اص داخل الموقع امام مخزن الاحلال والتجد...',
        '2026-11-17',
        N'موقع امام مخزن الاحلال والتجديد',
        N'واقعه شركه كلابلات يوم 17/11/2026 المسولين 1-محمد ريحان محمد 2-نادر عيد الناصريه واقعه سرقه كابلات يوم 23/1/2026 المسؤلين 1-سامي محمد جوده 2-رمضان صبحي عبد الحميد بان فى يوم الثلاثاء 27/1/2026 تم اكتشاف وجود اص داخل الموقع امام مخزن الاحلال والتجديد ووجد قطع عدد 6 كابلات',
        N'مغلقة',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'محمد ريحان محمد, نادر عيد الناصريه واقعه سرقه كابلات, سامي محمد جوده, رمضان صبحي عبد الحميد بان فى',
        '2026-03-02 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: محمد ريحان محمد
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمد ريحان محمد';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمد ريحان محمد%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمد ريحان محمد', N'موظف', N'موقع امام مخزن الاحلال والتجديد', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: نادر عيد الناصريه واقعه سرقه كابلات
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'نادر عيد الناصريه واقعه سرقه كابلات';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%نادر عيد الناصريه واقعه سرقه كابلات%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'نادر عيد الناصريه واقعه سرقه كابلات', N'موظف', N'موقع امام مخزن الاحلال والتجديد', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: سامي محمد جوده
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'سامي محمد جوده';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%سامي محمد جوده%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'سامي محمد جوده', N'موظف', N'موقع امام مخزن الاحلال والتجديد', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: رمضان صبحي عبد الحميد بان فى
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'رمضان صبحي عبد الحميد بان فى';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%رمضان صبحي عبد الحميد بان فى%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'رمضان صبحي عبد الحميد بان فى', N'موظف', N'موقع امام مخزن الاحلال والتجديد', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-03-29', N'رئيس مجلس الإدارة', N'ضم التحقيق لملف آخر', N'37', N'عرض على ر.م.أ 29/3/2026 | | تم ضم اللية ملف رقم 37', GETDATE());
    INSERT INTO FinalDecisions (InvestigationId, FinalDecisionText, ActionType, HRSentDate, HRNotes, CreatedAt)
    VALUES (@InvId, N'تم ضم اللية ملف رقم 37', 'hr', '2026-03-29', N'عرض على ر.م.أ 29/3/2026 | | تم ضم اللية ملف رقم 37', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'36',
        '2026-08-02',
        '2026-08-02',
        N'أ',
        N'نرمين قنديل',
        N'المرور على موقع اباطة يوم 21/1/2026 فى تمام الساعة 4:35 ص كان مغلق علما بأن الشخص المسئول عن الموقع اسامة وليد حسن',
        '2026-01-21',
        N'موقع اباطة',
        N'المرور على موقع اباطة يوم 21/1/2026 فى تمام الساعة 4:35 ص كان مغلق علما بأن الشخص المسئول عن الموقع اسامة وليد حسن',
        N'صدر قرار',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'موظف محال للتحقيق',
        '2026-08-02 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'موقع اباطة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-03-31', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 31/3/2026 | ورد من ر.م.أ 3/4/2026 |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'37',
        '2026-01-01',
        NULL,
        N'أ',
        N'غير مسند',
        N'تم ضمة لرقم 35',
        '2026-01-01',
        N'ديوان عام الشركة',
        N'تم ضمة لرقم 35',
        N'مغلقة',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'موظف محال للتحقيق',
        '2026-01-01 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-02-01', N'رئيس مجلس الإدارة', N'ضم التحقيق لملف آخر', N'35', N'| | تم ضمة لرقم 35', GETDATE());
    INSERT INTO FinalDecisions (InvestigationId, FinalDecisionText, ActionType, HRSentDate, HRNotes, CreatedAt)
    VALUES (@InvId, N'تم ضمة لرقم 35', 'hr', '2026-02-01', N'| | تم ضمة لرقم 35', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'38',
        '2026-09-02',
        '2026-09-02',
        N'أ',
        N'مروة حمزة',
        N'المرور على محطات الشركة المختلفة يوم الجمعة 23/1/2026 تلاحظ وجود محطة باب 18 الجمرك مغلقة الساعة 4:50 م',
        '2026-01-23',
        N'محطة باب 18 الجمرك مغلقة',
        N'المرور على محطات الشركة المختلفة يوم الجمعة 23/1/2026 تلاحظ وجود محطة باب 18 الجمرك مغلقة الساعة 4:50 م',
        N'صدر قرار',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'موظف محال للتحقيق',
        '2026-09-02 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'محطة باب 18 الجمرك مغلقة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-04-15', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 15/4/2026 | ورد من ر.م.أ 20/4/2026 |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'39',
        '2026-09-02',
        '2026-09-02',
        N'أ',
        N'هانى احمد',
        N'السائق رضا عبد العال رقم 5236 قد قام بالخروج السيارة المصرح بها بالمبيت بمحطة التنقية الشرقية يوم الخميس 22/1/2026 وتم عودة السيارة للمبيت بنفس المحطة ولم يتم خروج السيارة من المحطة يوم الجمعة 23/1/2026',
        '2026-01-22',
        N'بمحطة التنقية الشرقية',
        N'السائق رضا عبد العال رقم 5236 قد قام بالخروج السيارة المصرح بها بالمبيت بمحطة التنقية الشرقية يوم الخميس 22/1/2026 وتم عودة السيارة للمبيت بنفس المحطة ولم يتم خروج السيارة من المحطة يوم الجمعة 23/1/2026',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'رضا عبد العال رقم 5236',
        '2026-09-02 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: رضا عبد العال رقم 5236
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE Code = N'5236';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'رضا عبد العال رقم 5236';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%رضا عبد العال رقم 5236%';
    IF @EmpMasterId IS NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM EmployeesMaster WHERE Code = N'5236')
            SET @NewCode = N'5236';
        ELSE
            SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'رضا عبد العال رقم 5236', N'موظف', N'بمحطة التنقية الشرقية', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'40',
        '2026-10-02',
        '2026-10-02',
        N'أ',
        N'طارق السيد',
        N'قيام السيد/ صبحى محمد محمد بالتحدث بأسلوب غير لائق وبه استهزاء مع القائم بالمرور وهو السيد / صابر عبد الحميد',
        '2026-10-02',
        N'ديوان عام الشركة',
        N'قيام السيد/ صبحى محمد محمد بالتحدث بأسلوب غير لائق وبه استهزاء مع القائم بالمرور وهو السيد / صابر عبد الحميد',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'صبحى محمد محمد بالتحدث بأسلوب',
        '2026-10-02 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: صبحى محمد محمد بالتحدث بأسلوب
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'صبحى محمد محمد بالتحدث بأسلوب';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%صبحى محمد محمد بالتحدث بأسلوب%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'صبحى محمد محمد بالتحدث بأسلوب', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-10-02', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض | |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'41',
        '2026-02-18',
        '2026-02-18',
        N'أ',
        N'ايناس جلال',
        N'مخالفة كلا من 1- احمد محمد محمد على يعمل بالوردية المسائية الساعة (3م:11م) 2- اسلام عيد محمود يعمل بالوردية الليلية من الساعة (11م:7ص) لارتكابهم مخالفة ترك العمل وعدم تسليم الوردية المسائية وكذلك الليلية وتعريض المحطة للخطر والسرقة او الغرق وفقد س...',
        '2026-02-18',
        N'محطة للخطر والسرقة او الغرق وفقد',
        N'مخالفة كلا من 1- احمد محمد محمد على يعمل بالوردية المسائية الساعة (3م:11م) 2- اسلام عيد محمود يعمل بالوردية الليلية من الساعة (11م:7ص) لارتكابهم مخالفة ترك العمل وعدم تسليم الوردية المسائية وكذلك الليلية وتعريض المحطة للخطر والسرقة او الغرق وفقد سجل الحضور والانصراف الخاص بالمحطة',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'كلا من 1',
        '2026-02-18 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: كلا من 1
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'كلا من 1';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%كلا من 1%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'كلا من 1', N'موظف', N'محطة للخطر والسرقة او الغرق وفقد', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'42',
        '2026-02-08',
        NULL,
        N'أ',
        N'تامر الحداد',
        N'قيام السيد/ محمد اشرف عبد المولى يوم الاحد الموافق 8/2/2026 بتحميل مخلفات على المعدة التى يقودها السائق عبد الحميد السيد كود 7135 بمحطة التنقية الشرقية والتعدى بالسب والقذف ولم يراعى سن السائق',
        '2026-02-08',
        N'بمحطة التنقية الشرقية والتعدى بالسب والقذف',
        N'قيام السيد/ محمد اشرف عبد المولى يوم الاحد الموافق 8/2/2026 بتحميل مخلفات على المعدة التى يقودها السائق عبد الحميد السيد كود 7135 بمحطة التنقية الشرقية والتعدى بالسب والقذف ولم يراعى سن السائق',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'محمد اشرف عبد المولى',
        '2026-02-08 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: محمد اشرف عبد المولى
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE Code = N'7135';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمد اشرف عبد المولى';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمد اشرف عبد المولى%';
    IF @EmpMasterId IS NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM EmployeesMaster WHERE Code = N'7135')
            SET @NewCode = N'7135';
        ELSE
            SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمد اشرف عبد المولى', N'موظف', N'بمحطة التنقية الشرقية والتعدى بالسب والقذف', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-03-25', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 25/3/2026 | ورد من ر.م.أ 5/4/2026 |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'43',
        '2026-02-15',
        '2026-02-15',
        N'أ',
        N'حنان الخشاب',
        N'السيد محمد حسن القبيصى لارتكابة عدة محالفات وهى خروج الدلايل من الحملة دون معرفة مسئول الامن منطقة العجمى',
        '2026-02-15',
        N'منطقة العجمى',
        N'السيد محمد حسن القبيصى لارتكابة عدة محالفات وهى خروج الدلايل من الحملة دون معرفة مسئول الامن منطقة العجمى',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'موظف محال للتحقيق',
        '2026-02-15 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'منطقة العجمى', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'44',
        '2026-01-01',
        NULL,
        N'أ',
        N'صباح رمضان',
        N'الشكوى المقدمة من كلا من 1-مدير عام منطقة العجمى 2- السيد/ اسلام رمضان محمود مدير ادارة التنقية ضد القائم بأعمال ظابط امن منطقة العجمى',
        '2026-01-01',
        N'منطقة العجمى 2',
        N'الشكوى المقدمة من كلا من 1-مدير عام منطقة العجمى 2- السيد/ اسلام رمضان محمود مدير ادارة التنقية ضد القائم بأعمال ظابط امن منطقة العجمى',
        N'صدر قرار',
        NULL,
        N'كلا من 1مدير عام منطقة العجمى 2 السيد/ اسلام رمضان محمود مدير ادارة التنقية',
        N'القائم بأعمال ظابط امن منطقة العجمى',
        '2026-01-01 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: مدير عام منطقة العجمى
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'مدير عام منطقة العجمى';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%مدير عام منطقة العجمى%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'مدير عام منطقة العجمى', N'موظف', N'منطقة العجمى 2', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-04-26', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 26/4/2026 | ورد من ر.م.أ 29/4/2026 |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'45',
        '2026-02-10',
        NULL,
        N'أ',
        N'غادة شكرى',
        N'نوم الحارس الامن السيد/عبدالسلام مؤمن عبد السلام يوم الثلاثاء 10/2/2026 بالوردية المسائية',
        '2026-02-10',
        N'ديوان عام الشركة',
        N'نوم الحارس الامن السيد/عبدالسلام مؤمن عبد السلام يوم الثلاثاء 10/2/2026 بالوردية المسائية',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'عبدالسلام مؤمن عبد السلام',
        '2026-02-10 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: عبدالسلام مؤمن عبد السلام
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'عبدالسلام مؤمن عبد السلام';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%عبدالسلام مؤمن عبد السلام%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'عبدالسلام مؤمن عبد السلام', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-02-19', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 19/2/2026 | ورد من ر.م.أ 4/3/2026 |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'46',
        '2026-02-17',
        '2026-02-17',
        N'أ',
        N'طارق السيد',
        N'الفنى محمد موسى سعيد لم يخفى لاستلام المخزن من 12/1/2026 حتى تاريخة رغم تكرار التنبية علية هاتفيا وعن طريق مدير عام مخالفا غرب',
        '2026-01-12',
        N'مخزن من 12',
        N'الفنى محمد موسى سعيد لم يخفى لاستلام المخزن من 12/1/2026 حتى تاريخة رغم تكرار التنبية علية هاتفيا وعن طريق مدير عام مخالفا غرب',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'محمد موسى سعيد لم يخ',
        '2026-02-17 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: محمد موسى سعيد لم يخ
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمد موسى سعيد لم يخ';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمد موسى سعيد لم يخ%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمد موسى سعيد لم يخ', N'موظف', N'مخزن من 12', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'47',
        '2026-02-18',
        '2026-02-18',
        N'أ',
        N'هدى رجب',
        N'هبة ناجى التى ارتكبت المخالفات ولايوجد لها توقيع بسجل الادارة العامة للصرف الصناعى بمحطة التنقية الشرقية',
        '2026-02-18',
        N'بمحطة التنقية الشرقية',
        N'هبة ناجى التى ارتكبت المخالفات ولايوجد لها توقيع بسجل الادارة العامة للصرف الصناعى بمحطة التنقية الشرقية',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'موظف محال للتحقيق',
        '2026-02-18 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'بمحطة التنقية الشرقية', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'48',
        '2026-02-18',
        '2026-02-18',
        N'أ',
        N'نرمين قنديل',
        N'قيام العامل/ ايمن سامى بترك العمل فى الساعة 5ص والتلاعب بدفتر الحضور والانصراف والتوقيع لزملائة وسرقة التليفون للعامل محمد شعبان',
        '2026-02-18',
        N'ديوان عام الشركة',
        N'قيام العامل/ ايمن سامى بترك العمل فى الساعة 5ص والتلاعب بدفتر الحضور والانصراف والتوقيع لزملائة وسرقة التليفون للعامل محمد شعبان',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'ايمن سامى بترك ال',
        '2026-02-18 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: ايمن سامى بترك ال
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'ايمن سامى بترك ال';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%ايمن سامى بترك ال%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'ايمن سامى بترك ال', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-02-18', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض | |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'49',
        '2026-02-25',
        '2026-02-25',
        N'أ',
        N'غادة شكرى',
        N'قبام السائق/ محمد عادل الذى كان يعمل لدى ر.م.أ بفك عدد 2 سرينة من عدد 2 سيارة مخصصة ل ر.م.أ والذى تسلم منة السيارة بعد فك السرينة هما 1- السائق احمد حمدى 2- السائق خالد عيد محمود',
        '2026-02-25',
        N'ديوان عام الشركة',
        N'قبام السائق/ محمد عادل الذى كان يعمل لدى ر.م.أ بفك عدد 2 سرينة من عدد 2 سيارة مخصصة ل ر.م.أ والذى تسلم منة السيارة بعد فك السرينة هما 1- السائق احمد حمدى 2- السائق خالد عيد محمود',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'محمد عادل الذى كان ي',
        '2026-02-25 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: احمد حمدى
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'احمد حمدى';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%احمد حمدى%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'احمد حمدى', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: خالد عيد محمود
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'خالد عيد محمود';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%خالد عيد محمود%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'خالد عيد محمود', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-03-12', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 12/3/2026 | ورد من ر.م.أ 15/3/2026 |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'50',
        '2026-02-23',
        '2026-02-23',
        N'أ',
        N'تامر الحداد',
        N'العامل/ محمد اشرف عبد المولى الذى قام بالتحدث بأسلوب غير لائق والتلفظ بالفاظ سيئة والتلويح باليد وذلك بعد طلبة يوم اجازة وتم ابلاغة خلال يوم الثلاثاء او الاربعاء',
        '2026-02-23',
        N'ديوان عام الشركة',
        N'العامل/ محمد اشرف عبد المولى الذى قام بالتحدث بأسلوب غير لائق والتلفظ بالفاظ سيئة والتلويح باليد وذلك بعد طلبة يوم اجازة وتم ابلاغة خلال يوم الثلاثاء او الاربعاء',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'محمد اشرف عبد المولى الذى',
        '2026-02-23 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: محمد اشرف عبد المولى الذى
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمد اشرف عبد المولى الذى';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمد اشرف عبد المولى الذى%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمد اشرف عبد المولى الذى', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-03-25', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 25/3/2026 | ورد من ر.م.أ 5/4/2026 |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'51',
        '2026-02-24',
        '2026-02-24',
        N'أ',
        N'نورة عباس',
        N'مرور الامن على محطة التنقية الشرقية ومراجعة سجل الحضور والانصراف بقطاع المعالجة بالمحطة وذلك يوم السبت الموافق 14/2/2026 الساعة 9:156 ص اولهم اية محمد على واخرهم ثروت عبد الغنى الاسيوطى',
        '2026-02-14',
        N'محطة التنقية الشرقية ومراجعة سجل الحضور',
        N'مرور الامن على محطة التنقية الشرقية ومراجعة سجل الحضور والانصراف بقطاع المعالجة بالمحطة وذلك يوم السبت الموافق 14/2/2026 الساعة 9:156 ص اولهم اية محمد على واخرهم ثروت عبد الغنى الاسيوطى',
        N'صدر قرار',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'موظف محال للتحقيق',
        '2026-02-24 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'محطة التنقية الشرقية ومراجعة سجل الحضور', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-04-22', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 22/4/2026 | ورد من ر.م.أ 19/4/2026 |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'52',
        '2026-02-25',
        '2026-02-25',
        N'أ',
        N'غادة شكرى',
        N'موقف العامل احمد محمد سيف المنتدب بالمحطة الميكانيكية',
        '2026-02-25',
        N'محطة الميكانيكية',
        N'موقف العامل احمد محمد سيف المنتدب بالمحطة الميكانيكية',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'احمد محمد سيف المنتدب بالمحطة',
        '2026-02-25 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: احمد محمد سيف المنتدب بالمحطة
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'احمد محمد سيف المنتدب بالمحطة';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%احمد محمد سيف المنتدب بالمحطة%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'احمد محمد سيف المنتدب بالمحطة', N'موظف', N'محطة الميكانيكية', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-04-09', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 9/4/2026 | ورد من ر.م.أ 19/4/2026 |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'53',
        '2026-03-05',
        '2026-03-05',
        N'أ',
        N'ريهام شفيق',
        N'السائق عبد الغنى محمد عبدالغنى قد حضر يوم 19/2/2026 الى مقر الجواهر وطالب بكارنية العلاج لزوجة سائق اخر وعندما افادت الموظفة بأن الاستلام من الراعية قام برفع صوتة والتحدث باسلوب غير لائق',
        '2026-02-19',
        N'ديوان عام الشركة',
        N'السائق عبد الغنى محمد عبدالغنى قد حضر يوم 19/2/2026 الى مقر الجواهر وطالب بكارنية العلاج لزوجة سائق اخر وعندما افادت الموظفة بأن الاستلام من الراعية قام برفع صوتة والتحدث باسلوب غير لائق',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'عبد الغنى محمد عبدالغنى قد',
        '2026-03-05 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: عبد الغنى محمد عبدالغنى قد
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'عبد الغنى محمد عبدالغنى قد';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%عبد الغنى محمد عبدالغنى قد%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'عبد الغنى محمد عبدالغنى قد', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-03-17', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 17/3/2026 | ورد من ر.م.أ 28/3/2026 |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'54',
        '2026-03-02',
        '2026-03-02',
        N'أ',
        N'غادة شكرى',
        N'المرور على محطة عزبة الشامى يوم 18/2/2026 الساعة 6:30 منتزة اول تلاحظ وجود العامل ياسر محمد السيد وهو يعمل بالوردية المسائية ووجود المسئولين نائمين',
        '2026-02-18',
        N'محطة عزبة الشامى',
        N'المرور على محطة عزبة الشامى يوم 18/2/2026 الساعة 6:30 منتزة اول تلاحظ وجود العامل ياسر محمد السيد وهو يعمل بالوردية المسائية ووجود المسئولين نائمين',
        N'صدر قرار',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'ياسر محمد السيد وهو ي',
        '2026-03-02 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: ياسر محمد السيد وهو ي
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'ياسر محمد السيد وهو ي';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%ياسر محمد السيد وهو ي%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'ياسر محمد السيد وهو ي', N'موظف', N'محطة عزبة الشامى', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-03-10', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 10/3/2026 | ورد من ر.م.أ 15/3/2026 |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'55',
        '2026-03-02',
        '2026-03-02',
        N'أ',
        N'صباح رمضان',
        N'المرور على محة مبارك 4ب العامرية يوم السبت الموافق 21/2/2026 الساعة 12ص حتى الساعة 12:30 وتلاحظ عدم وجود احد',
        '2026-02-21',
        N'ديوان عام الشركة',
        N'المرور على محة مبارك 4ب العامرية يوم السبت الموافق 21/2/2026 الساعة 12ص حتى الساعة 12:30 وتلاحظ عدم وجود احد',
        N'صدر قرار',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'موظف محال للتحقيق',
        '2026-03-02 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-03-02', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض | |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'56',
        '2026-08-03',
        '2026-08-03',
        N'أ',
        N'ايمن توفيق',
        N'بشأن سرقة سجل الحضور والانصراف الخاص بمحطة مدخل المدينة يوم 4/2/2026 وقد قام بالابلاغ عن سرقة السجل السيد/ غريب محمود غريب',
        '2026-02-04',
        N'بمحطة مدخل المدينة',
        N'بشأن سرقة سجل الحضور والانصراف الخاص بمحطة مدخل المدينة يوم 4/2/2026 وقد قام بالابلاغ عن سرقة السجل السيد/ غريب محمود غريب',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'موظف محال للتحقيق',
        '2026-08-03 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'بمحطة مدخل المدينة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-08-03', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض | |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'57',
        '2026-09-03',
        '2026-09-03',
        N'أ',
        N'ايناس جلال',
        N'بشأن السائقين/ رمضان السيد على وعبدالسلام عبد اللله عبد السلام قد اخلو بمهامهم الوظيفية مما ادى لتعطيل العمل اثناء التمركزات',
        '2026-09-03',
        N'ديوان عام الشركة',
        N'بشأن السائقين/ رمضان السيد على وعبدالسلام عبد اللله عبد السلام قد اخلو بمهامهم الوظيفية مما ادى لتعطيل العمل اثناء التمركزات',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'موظف محال للتحقيق',
        '2026-09-03 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'58',
        '2026-03-15',
        '2026-03-15',
        N'أ',
        N'خالد احمد',
        N'فقد الاذن يوم 21/2/2026 بسيارة رقم 7353 من السائق مصطفى ابراهيم محمد كود 10528',
        '2026-02-21',
        N'ديوان عام الشركة',
        N'فقد الاذن يوم 21/2/2026 بسيارة رقم 7353 من السائق مصطفى ابراهيم محمد كود 10528',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'مصط',
        '2026-03-15 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: مصط
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE Code = N'7353';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'مصط';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%مصط%';
    IF @EmpMasterId IS NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM EmployeesMaster WHERE Code = N'7353')
            SET @NewCode = N'7353';
        ELSE
            SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'مصط', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'59',
        '2026-03-25',
        '2026-03-25',
        N'أ',
        N'تامر الحداد',
        N'وجود محطة اسكان مرغم الساعة 10م ومحطة 5 العجمى الساعة 11:20م مغلقة ولايوجد بها احد وتم ابلاغ لخط الساخن',
        '2026-03-25',
        N'محطة اسكان مرغم',
        N'وجود محطة اسكان مرغم الساعة 10م ومحطة 5 العجمى الساعة 11:20م مغلقة ولايوجد بها احد وتم ابلاغ لخط الساخن',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'موظف محال للتحقيق',
        '2026-03-25 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'محطة اسكان مرغم', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-03-25', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض | |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'60',
        '2026-11-03',
        '2026-11-03',
        N'أ',
        N'هانى احمد',
        N'مخالفة السائق كريم حمدى فتحى بخروج خراطيم سيارة الشفط الى جراج محرم بك على الرغم من التنبية علية بانزال الخراطيم داخل محطة الناصرية',
        '2026-11-03',
        N'محطة الناصرية',
        N'مخالفة السائق كريم حمدى فتحى بخروج خراطيم سيارة الشفط الى جراج محرم بك على الرغم من التنبية علية بانزال الخراطيم داخل محطة الناصرية',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'السائق كريم حمدى فتحى بخروج',
        '2026-11-03 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: كريم حمدى فتحى بخروج
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'كريم حمدى فتحى بخروج';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%كريم حمدى فتحى بخروج%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'كريم حمدى فتحى بخروج', N'موظف', N'محطة الناصرية', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'61',
        '2026-08-03',
        '2026-08-03',
        N'أ',
        N'حنان الخشاب',
        N'أ/ حسن ذكى فرج الذى قام بالتحدث بأسلوب غير لائق وترك عمل يوم السبت الموافق 28/2/2026',
        '2026-02-28',
        N'ديوان عام الشركة',
        N'أ/ حسن ذكى فرج الذى قام بالتحدث بأسلوب غير لائق وترك عمل يوم السبت الموافق 28/2/2026',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'موظف محال للتحقيق',
        '2026-08-03 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-08-03', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض | |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'62',
        '2026-03-29',
        '2026-03-29',
        N'أ',
        N'شعبان السيد',
        N'ماقام السيد عوض بسيونى عوض بالتشهير بالمدير العام وقام بالاتهام الصريح لجميع العاملين بالموافقة على الوصلات خلسة واتهم رئيس محطة الشمعدان انه ياخذ المال من نوات افراد المحطة',
        '2026-03-29',
        N'محطة الشمعدان انه ياخذ المال من',
        N'ماقام السيد عوض بسيونى عوض بالتشهير بالمدير العام وقام بالاتهام الصريح لجميع العاملين بالموافقة على الوصلات خلسة واتهم رئيس محطة الشمعدان انه ياخذ المال من نوات افراد المحطة',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'ين بالموافقة على الوصلات خلسة',
        '2026-03-29 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: ين بالموافقة على الوصلات خلسة
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'ين بالموافقة على الوصلات خلسة';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%ين بالموافقة على الوصلات خلسة%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'ين بالموافقة على الوصلات خلسة', N'موظف', N'محطة الشمعدان انه ياخذ المال من', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'63',
        '2026-08-03',
        '2026-08-03',
        N'أ',
        N'غادة شكرى',
        N'مخالفة التعليمات بوجود عامل واحد فقط وهو السيد سامح احمد محمد وقد توفى يوم الجمعة 27/2/2026 الساعة 3:15م ومن المفترض عدم وجود شخص واحد فقط',
        '2026-02-27',
        N'ديوان عام الشركة',
        N'مخالفة التعليمات بوجود عامل واحد فقط وهو السيد سامح احمد محمد وقد توفى يوم الجمعة 27/2/2026 الساعة 3:15م ومن المفترض عدم وجود شخص واحد فقط',
        N'مغلقة',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'التعليمات بوجود عامل واحد فقط',
        '2026-08-03 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: التعليمات بوجود عامل واحد فقط
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'التعليمات بوجود عامل واحد فقط';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%التعليمات بوجود عامل واحد فقط%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'التعليمات بوجود عامل واحد فقط', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-03-07', N'رئيس مجلس الإدارة', N'حفظ التحقيق', N'حفظ التحقيق', N'عرض على ر.م.أ 7/3/2026 | ورد من ر.م.أ 28/3/2026 | بالحفظ', GETDATE());
    INSERT INTO FinalDecisions (InvestigationId, FinalDecisionText, ActionType, HRSentDate, HRNotes, CreatedAt)
    VALUES (@InvId, N'بالحفظ', 'archive', '2026-03-07', N'عرض على ر.م.أ 7/3/2026 | ورد من ر.م.أ 28/3/2026 | بالحفظ', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'64',
        '2026-11-03',
        '2026-11-03',
        N'أ',
        N'غادة شكرى',
        N'بشان اجمالى المديونية الخاصة بحسابتكم رقم # 8288066181 شركة الصرف الصحى الخاصة بالمفوضة السابقة أ/ سهى بعد مراجعة الحسابات من طرفكم مبلغ 208029083 مصرى',
        '2026-11-03',
        N'ديوان عام الشركة',
        N'بشان اجمالى المديونية الخاصة بحسابتكم رقم # 8288066181 شركة الصرف الصحى الخاصة بالمفوضة السابقة أ/ سهى بعد مراجعة الحسابات من طرفكم مبلغ 208029083 مصرى',
        N'صدر قرار',
        N'208029083 جنيه مصري',
        N'شركة الصرف الصحي بالإسكندرية',
        N'موظف محال للتحقيق',
        '2026-11-03 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-05-20', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 20/5/2026 | |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'65',
        '2026-03-26',
        '2026-03-26',
        N'أ',
        N'هدى رجب',
        N'نوم العامل محمد سعد عبد العزيز مما تسبب فى ارتفاع منسوب المياه فى الشوارع وغرق المنازل والمحلات',
        '2026-03-26',
        N'ديوان عام الشركة',
        N'نوم العامل محمد سعد عبد العزيز مما تسبب فى ارتفاع منسوب المياه فى الشوارع وغرق المنازل والمحلات',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'محمد سعد عبد العزيز',
        '2026-03-26 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: محمد سعد عبد العزيز
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمد سعد عبد العزيز';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمد سعد عبد العزيز%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمد سعد عبد العزيز', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-03-26', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض | |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'66',
        '2026-03-29',
        '2026-03-29',
        N'أ',
        N'وفاء رمزى',
        N'اثناء مرور لجنة يوم 8/3/2026 بمحطة نوبار 2 وجدو المحطة مغلقة',
        '2026-03-08',
        N'بمحطة نوبار 2 وجدو المحطة مغلقة',
        N'اثناء مرور لجنة يوم 8/3/2026 بمحطة نوبار 2 وجدو المحطة مغلقة',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'موظف محال للتحقيق',
        '2026-03-29 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'بمحطة نوبار 2 وجدو المحطة مغلقة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-03-29', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض | |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'67',
        '2026-03-29',
        '2026-03-29',
        N'أ',
        N'مروة حمزة',
        N'عند المرور محطة الشامى منتزة اول يوم الثلاثاء 3/3/2026 الساعة 9ص وجدت المحطة مفتوحة ولايتواجد بها احد واسماء العاملين بالوردية الصباحية هم 1- رضا عبد الفتاح عبد الله 2- محمد محمد رمضان قنديل مسائية 3- موسى محمد موسى 4- ياسر محمد السيد',
        '2026-03-03',
        N'محطة الشامى منتزة اول',
        N'عند المرور محطة الشامى منتزة اول يوم الثلاثاء 3/3/2026 الساعة 9ص وجدت المحطة مفتوحة ولايتواجد بها احد واسماء العاملين بالوردية الصباحية هم 1- رضا عبد الفتاح عبد الله 2- محمد محمد رمضان قنديل مسائية 3- موسى محمد موسى 4- ياسر محمد السيد',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'ين بالوردية الصباحية هم 1',
        '2026-03-29 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: رضا عبد الفتاح عبد الله
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'رضا عبد الفتاح عبد الله';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%رضا عبد الفتاح عبد الله%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'رضا عبد الفتاح عبد الله', N'موظف', N'محطة الشامى منتزة اول', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: محمد محمد رمضان قنديل مسائية
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمد محمد رمضان قنديل مسائية';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمد محمد رمضان قنديل مسائية%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمد محمد رمضان قنديل مسائية', N'موظف', N'محطة الشامى منتزة اول', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: موسى محمد موسى
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موسى محمد موسى';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موسى محمد موسى%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موسى محمد موسى', N'موظف', N'محطة الشامى منتزة اول', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: ياسر محمد السيد
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'ياسر محمد السيد';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%ياسر محمد السيد%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'ياسر محمد السيد', N'موظف', N'محطة الشامى منتزة اول', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'68',
        '2026-03-29',
        '2026-03-29',
        N'أ',
        N'ايناس جلال',
        N'مرور الامن على محطة قلعة قايتباى يوم الاربع 4/3/2026 الساعة 10:15 م وجد تلاعب فى السجل',
        '2026-03-04',
        N'محطة قلعة قايتباى',
        N'مرور الامن على محطة قلعة قايتباى يوم الاربع 4/3/2026 الساعة 10:15 م وجد تلاعب فى السجل',
        N'جارية',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'موظف محال للتحقيق',
        '2026-03-29 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'محطة قلعة قايتباى', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'69',
        '2026-03-16',
        '2026-03-16',
        N'أ',
        N'غادة شكرى',
        N'تأخر السائق/محمود صابر عبد الراضى عن العمل يوم الاربعاء 11/3/2026 وذلك ادى الى عرقلة العمل بالادارة المعدات للمرور على المواقع',
        '2026-03-11',
        N'ادارة المعدات للمرور على المواقع',
        N'تأخر السائق/محمود صابر عبد الراضى عن العمل يوم الاربعاء 11/3/2026 وذلك ادى الى عرقلة العمل بالادارة المعدات للمرور على المواقع',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'محمود صابر عبد الراضى',
        '2026-03-16 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: محمود صابر عبد الراضى
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمود صابر عبد الراضى';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمود صابر عبد الراضى%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمود صابر عبد الراضى', N'موظف', N'ادارة المعدات للمرور على المواقع', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-04-08', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 8/4/2026 | ورد من ر.م.أ 14/4/2026 |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'70',
        '2026-05-04',
        '2026-05-04',
        N'أ',
        N'تامر الحداد',
        N'السائق/ حسن جمال قام بالتحدث بأسلوبغيرلائق مع السيد/ منصور فتحى الخولى رئيس مجموعة العمل',
        '2026-05-04',
        N'ديوان عام الشركة',
        N'السائق/ حسن جمال قام بالتحدث بأسلوبغيرلائق مع السيد/ منصور فتحى الخولى رئيس مجموعة العمل',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'حسن جمال قام بالتحدث بأسلوبغيرلائق',
        '2026-05-04 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: حسن جمال قام بالتحدث بأسلوبغيرلائق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'حسن جمال قام بالتحدث بأسلوبغيرلائق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%حسن جمال قام بالتحدث بأسلوبغيرلائق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'حسن جمال قام بالتحدث بأسلوبغيرلائق', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-05-12', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 12/5/2026 | ورد من ر.م.أ 12/5/2026 |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'71',
        '2026-05-04',
        '2026-05-04',
        N'أ',
        N'ايمن توفيق',
        N'العامل/ محمد عبد المنعم عبد الرحمن الذى يعمل بمحطة فضة تلاحظ اثناء المراجعة تلاعب فى سجل الحضور والانصراف',
        '2026-05-04',
        N'بمحطة فضة',
        N'العامل/ محمد عبد المنعم عبد الرحمن الذى يعمل بمحطة فضة تلاحظ اثناء المراجعة تلاعب فى سجل الحضور والانصراف',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'محمد عبد المنعم عبد الرحمن',
        '2026-05-04 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: محمد عبد المنعم عبد الرحمن
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمد عبد المنعم عبد الرحمن';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمد عبد المنعم عبد الرحمن%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمد عبد المنعم عبد الرحمن', N'موظف', N'بمحطة فضة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-05-19', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 19/5/2026 | ورد من ر.م.أ 21/5/2026 |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'72',
        '2026-02-28',
        '2026-02-28',
        N'أ',
        N'خالد احمد',
        N'قيام العامل/ كريم محمد هاشم باامخالفة بالحضور الساعة 8م لمدة يومين 8/3،9/3 بالاتفاق مع زميلة العامل / محمد ماجد عبد الفتاح مع العلم ان الاثنين يعملون بالوردية الثانية 11:3م',
        '2026-03-08',
        N'ديوان عام الشركة',
        N'قيام العامل/ كريم محمد هاشم باامخالفة بالحضور الساعة 8م لمدة يومين 8/3،9/3 بالاتفاق مع زميلة العامل / محمد ماجد عبد الفتاح مع العلم ان الاثنين يعملون بالوردية الثانية 11:3م',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'كريم محمد هاشم باامخالفة بالحضور',
        '2026-02-28 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: كريم محمد هاشم باامخالفة بالحضور
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'كريم محمد هاشم باامخالفة بالحضور';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%كريم محمد هاشم باامخالفة بالحضور%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'كريم محمد هاشم باامخالفة بالحضور', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'73',
        '2026-01-04',
        '2026-01-04',
        N'أ',
        N'هاني احمد',
        N'انقطاع السيد/اشرف محمد محمد سالم بمنطة العجمي اعتبارا من 22/2/2026 حتى 28/2/2026',
        '2026-02-22',
        N'قطاع السيد',
        N'انقطاع السيد/اشرف محمد محمد سالم بمنطة العجمي اعتبارا من 22/2/2026 حتى 28/2/2026',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'اشرف محمد محمد سالم بمنطة',
        '2026-01-04 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: اشرف محمد محمد سالم بمنطة
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'اشرف محمد محمد سالم بمنطة';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%اشرف محمد محمد سالم بمنطة%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'اشرف محمد محمد سالم بمنطة', N'موظف', N'قطاع السيد', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-06-02', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 2/6/2026 | |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'74',
        '2026-03-26',
        '2026-03-26',
        N'أ',
        N'هدى رجب',
        N'عدم تواجد مسؤل السلامة والهيئة بالمحطة وقت حدوث الواقعة',
        '2026-03-26',
        N'محطة وقت حدوث الواقعة',
        N'عدم تواجد مسؤل السلامة والهيئة بالمحطة وقت حدوث الواقعة',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'موظف محال للتحقيق',
        '2026-03-26 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'محطة وقت حدوث الواقعة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'75',
        '2026-03-26',
        '2026-03-26',
        N'أ',
        N'شعبان السيد',
        N'مرور الادارة العامة للامن يوم الاحد 15/3/2026 بالوردية الليلية (نوه) على محطة 5 (المنتزه اول) وجود المحطة المفتوحة ولا يتواجد بها احد العاملين لتشغيلها اثناء النوه حيث انها تعمل اثناء النوه فقط',
        '2026-03-15',
        N'محطة 5 (المنتزه اول) وجود المحطة',
        N'مرور الادارة العامة للامن يوم الاحد 15/3/2026 بالوردية الليلية (نوه) على محطة 5 (المنتزه اول) وجود المحطة المفتوحة ولا يتواجد بها احد العاملين لتشغيلها اثناء النوه حيث انها تعمل اثناء النوه فقط',
        N'جارية',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'ين لتشغيلها',
        '2026-03-26 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: ين لتشغيلها
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'ين لتشغيلها';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%ين لتشغيلها%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'ين لتشغيلها', N'موظف', N'محطة 5 (المنتزه اول) وجود المحطة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'76',
        '2026-03-17',
        NULL,
        N'أ',
        N'تامر الحداد',
        N'البلاغ الذي ورد من الادارة العامة للامن يوم الثلاثاء 17/3/2026 بقيام احد سيارات الشفط بتفريغ حمولتها في الطريق العام وقيام احد المواطنين بتصوير الواقعة والسيارة رقم (س ف ح 6727) منطقة العجمي للتشغيل والصيانة بقيادة السائق/ محمود سليم سيد كود (9991)',
        '2026-03-17',
        N'منطقة العجمي للتشغيل والصيانة بقيادة',
        N'البلاغ الذي ورد من الادارة العامة للامن يوم الثلاثاء 17/3/2026 بقيام احد سيارات الشفط بتفريغ حمولتها في الطريق العام وقيام احد المواطنين بتصوير الواقعة والسيارة رقم (س ف ح 6727) منطقة العجمي للتشغيل والصيانة بقيادة السائق/ محمود سليم سيد كود (9991)',
        N'مغلقة',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'احد سيارات الشفط بتفريغ حمولتها',
        '2026-03-17 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: احد سيارات الشفط بتفريغ حمولتها
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'احد سيارات الشفط بتفريغ حمولتها';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%احد سيارات الشفط بتفريغ حمولتها%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'احد سيارات الشفط بتفريغ حمولتها', N'موظف', N'منطقة العجمي للتشغيل والصيانة بقيادة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-04-08', N'رئيس مجلس الإدارة', N'مجازاة بخصم من الراتب', N'ثلاثة ايام من راتبه', N'عرض على ر.م.أ 8/4/2026 | ورد من ر.م.أ 14/4/2026 | تم الانتهاء بمجازاة السائق/محمود سليم محمد سيد بخفض الاجر بمقدار العلاوة ومجازات السي/محمود فتوح مدير الحملة بخصم ثلاثة ايام من راتبه', GETDATE());
    INSERT INTO FinalDecisions (InvestigationId, FinalDecisionText, ActionType, HRSentDate, HRNotes, CreatedAt)
    VALUES (@InvId, N'تم الانتهاء  بمجازاة السائق/محمود سليم محمد سيد بخفض الاجر بمقدار العلاوة  ومجازات السي/محمود فتوح مدير الحملة بخصم ثلاثة ايام من راتبه', 'hr', '2026-04-08', N'عرض على ر.م.أ 8/4/2026 | ورد من ر.م.أ 14/4/2026 | تم الانتهاء بمجازاة السائق/محمود سليم محمد سيد بخفض الاجر بمقدار العلاوة ومجازات السي/محمود فتوح مدير الحملة بخصم ثلاثة ايام من راتبه', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'77',
        '2026-08-04',
        '2026-08-04',
        N'أ',
        N'شعبان السيد',
        N'قضية دخل عن السنوات 2015, 2016,2017 والتأخير في متابعة القضية أ/محمد عبدالحي علي أ/مصطفى حسن الاشقر',
        '2026-08-04',
        N'ديوان عام الشركة',
        N'قضية دخل عن السنوات 2015, 2016,2017 والتأخير في متابعة القضية أ/محمد عبدالحي علي أ/مصطفى حسن الاشقر',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'موظف محال للتحقيق',
        '2026-08-04 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-08-04', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض | |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'78',
        '2026-03-30',
        '2026-03-30',
        N'أ',
        N'مروة حمزة',
        N'امتناع الفني/ حسن محمد حسن عبده عن حضور نوباتية عيد الفطر بالمحطة كما امتنع عن حضور التمركز يوم 13/3/2026',
        '2026-03-13',
        N'محطة كما امتنع عن حضور التمركز',
        N'امتناع الفني/ حسن محمد حسن عبده عن حضور نوباتية عيد الفطر بالمحطة كما امتنع عن حضور التمركز يوم 13/3/2026',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'حسن محمد حسن عبده',
        '2026-03-30 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: حسن محمد حسن عبده
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'حسن محمد حسن عبده';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%حسن محمد حسن عبده%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'حسن محمد حسن عبده', N'موظف', N'محطة كما امتنع عن حضور التمركز', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-04-23', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 23/4/2026 | |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'79',
        '2026-03-30',
        '2026-03-30',
        N'أ',
        N'ايناس جلال',
        N'انقطاع السيد/ محمود فكري شحاتة عبدالوهاب بمنطقة العامرية اعتبارا من يوم 28/2/2026 وردت مذكرة تقيد عودة المذكرة للعمل اعتبارا من 4/3/2026',
        '2026-02-28',
        N'بمنطقة العامرية اعتبارا من',
        N'انقطاع السيد/ محمود فكري شحاتة عبدالوهاب بمنطقة العامرية اعتبارا من يوم 28/2/2026 وردت مذكرة تقيد عودة المذكرة للعمل اعتبارا من 4/3/2026',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'محمود فكري شحاتة عبدالوهاب بمنطقة',
        '2026-03-30 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: محمود فكري شحاتة عبدالوهاب بمنطقة
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمود فكري شحاتة عبدالوهاب بمنطقة';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمود فكري شحاتة عبدالوهاب بمنطقة%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمود فكري شحاتة عبدالوهاب بمنطقة', N'موظف', N'بمنطقة العامرية اعتبارا من', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-05-10', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 10/5/2026 | ورد من ر.م.أ 14/5/2026 |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'80',
        '2026-03-31',
        '2026-03-31',
        N'أ',
        N'خالد احمد',
        N'سرقة شباك حديد من خلف مصنع التجفيف الخاص بمنطقة الكهنة خلف المصنع ببلاغ من الفني/ عبدالهادي محمود الى السيد/وليد رغيب وتم ابلاغ م/ احمد مرسي مدير عام محطة التنقية الغربية',
        '2026-03-31',
        N'محطة التنقية الغربية',
        N'سرقة شباك حديد من خلف مصنع التجفيف الخاص بمنطقة الكهنة خلف المصنع ببلاغ من الفني/ عبدالهادي محمود الى السيد/وليد رغيب وتم ابلاغ م/ احمد مرسي مدير عام محطة التنقية الغربية',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'عبدالهادي محمود الى السيد',
        '2026-03-31 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: عبدالهادي محمود الى السيد
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'عبدالهادي محمود الى السيد';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%عبدالهادي محمود الى السيد%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'عبدالهادي محمود الى السيد', N'موظف', N'محطة التنقية الغربية', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'81',
        '2026-04-14',
        '2026-04-14',
        N'أ',
        N'مروة حمزة',
        N'الفني احمد مصطفى محمد رئيس محطة 4ب تقدم بشكوى ضد العامل/ احمد عبده خلف والعامل/ هاني علي محمد احمد الشربيني العاملين بالمحطة حيث ان الاول قام بأخذ كرسي معدني ودكة خشبية ملك المحطة دون وجه الحق والثاني لمساعدته في اخراج هذه الاشياء من المحطة دون ال...',
        '2026-04-14',
        N'محطة 4ب تقدم بشكوى ضد العامل',
        N'الفني احمد مصطفى محمد رئيس محطة 4ب تقدم بشكوى ضد العامل/ احمد عبده خلف والعامل/ هاني علي محمد احمد الشربيني العاملين بالمحطة حيث ان الاول قام بأخذ كرسي معدني ودكة خشبية ملك المحطة دون وجه الحق والثاني لمساعدته في اخراج هذه الاشياء من المحطة دون الرجوع لرئيس المحطة',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'العامل/ احمد عبده خلف والعامل/ هاني علي محمد احمد الشربيني العاملين بالمحطة',
        '2026-04-14 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: احمد عبده خلف والعامل/ هاني علي محمد احمد الشربيني العاملين بالمحطة
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'احمد عبده خلف والعامل/ هاني علي محمد احمد الشربيني العاملين بالمحطة';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%احمد عبده خلف والعامل/ هاني علي محمد احمد الشربيني العاملين بالمحطة%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'احمد عبده خلف والعامل/ هاني علي محمد احمد الشربيني العاملين بالمحطة', N'موظف', N'محطة 4ب تقدم بشكوى ضد العامل', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'82',
        '2026-06-04',
        '2026-06-04',
        N'أ',
        N'طارق السيد',
        N'قيام السيد/ محمود عبدالله علي بقيام بسرقة ردياتير من الورشه ووضعه بالسيارة الساعة 10:15 صباحا',
        '2026-06-04',
        N'ديوان عام الشركة',
        N'قيام السيد/ محمود عبدالله علي بقيام بسرقة ردياتير من الورشه ووضعه بالسيارة الساعة 10:15 صباحا',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'محمود عبدالله علي بقيام بسرقة',
        '2026-06-04 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: محمود عبدالله علي بقيام بسرقة
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمود عبدالله علي بقيام بسرقة';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمود عبدالله علي بقيام بسرقة%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمود عبدالله علي بقيام بسرقة', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-04-27', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 27/4/2026 | |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'83',
        '2026-08-04',
        '2026-08-04',
        N'أ',
        N'ايناس جلال',
        N'امتناع السائق / احمد عصام محمد كود(11175) عن العمل عن سيارة شفط تمركز الهانوفيل بالوردية الثانية يوم 23/3/2026',
        '2026-03-23',
        N'ديوان عام الشركة',
        N'امتناع السائق / احمد عصام محمد كود(11175) عن العمل عن سيارة شفط تمركز الهانوفيل بالوردية الثانية يوم 23/3/2026',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'احمد عصام محمد كود(11175)',
        '2026-08-04 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: احمد عصام محمد كود(11175)
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'احمد عصام محمد كود(11175)';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%احمد عصام محمد كود(11175)%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'احمد عصام محمد كود(11175)', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-05-10', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 10/5/2026 | ورد من ر.م.أ 10/5/2026 |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'84',
        '2026-05-04',
        '2026-05-04',
        N'أ',
        N'ايمن توفيق',
        N'وجود بعض المخالفات بمحطة المنشية البحرية منتزه ثان , تلاحظ قيام السيد/ احمد عبدالسلام رئيس المحطة والفني/ محمد نصر قد قاموا بالاستيلاء على الكابلات الكهربائية الخاصة بأعمدة الانارة',
        '2026-05-04',
        N'بمحطة المنشية البحرية منتزه ثان',
        N'وجود بعض المخالفات بمحطة المنشية البحرية منتزه ثان , تلاحظ قيام السيد/ احمد عبدالسلام رئيس المحطة والفني/ محمد نصر قد قاموا بالاستيلاء على الكابلات الكهربائية الخاصة بأعمدة الانارة',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'احمد عبدالسلام رئيس المحطة والفني',
        '2026-05-04 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: احمد عبدالسلام رئيس المحطة والفني
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'احمد عبدالسلام رئيس المحطة والفني';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%احمد عبدالسلام رئيس المحطة والفني%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'احمد عبدالسلام رئيس المحطة والفني', N'موظف', N'بمحطة المنشية البحرية منتزه ثان', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'85',
        '2026-03-27',
        NULL,
        N'أ',
        N'تامر الحداد',
        N'اهمال السائق/ عبدالمنعم ابراهيم شبل العمل يوم الجمعة 27/3/2026 الساعة 8 السيارة رقم 9434 الجامبو اثناء التمركز',
        '2026-03-27',
        N'ديوان عام الشركة',
        N'اهمال السائق/ عبدالمنعم ابراهيم شبل العمل يوم الجمعة 27/3/2026 الساعة 8 السيارة رقم 9434 الجامبو اثناء التمركز',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'عبدالمنعم ابراهيم شبل ال',
        '2026-03-27 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: عبدالمنعم ابراهيم شبل ال
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE Code = N'9434';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'عبدالمنعم ابراهيم شبل ال';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%عبدالمنعم ابراهيم شبل ال%';
    IF @EmpMasterId IS NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM EmployeesMaster WHERE Code = N'9434')
            SET @NewCode = N'9434';
        ELSE
            SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'عبدالمنعم ابراهيم شبل ال', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-02-01', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض | |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'86',
        '2026-05-04',
        '2026-05-04',
        N'أ',
        N'ريهام شفيق',
        N'قيام السيدة/ فاتن زكريا المحلاوي مدير عام الحدائق والتشجير بقيام المخالفات الاتيه : عدم القيام المذكورة بالعمل لمدة 8ساعات , عدم تقديم اجازات عن الايام التي لم تتواجد العمل , الحصول على مبالغ مالية ترشيد العمل اول ايام الشهر',
        '2026-05-04',
        N'ديوان عام الشركة',
        N'قيام السيدة/ فاتن زكريا المحلاوي مدير عام الحدائق والتشجير بقيام المخالفات الاتيه : عدم القيام المذكورة بالعمل لمدة 8ساعات , عدم تقديم اجازات عن الايام التي لم تتواجد العمل , الحصول على مبالغ مالية ترشيد العمل اول ايام الشهر',
        N'صدر قرار',
        N'مبلغ مالي',
        N'شركة الصرف الصحي بالإسكندرية',
        N'فاتن زكريا المحلاوي مدير عام',
        '2026-05-04 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: فاتن زكريا المحلاوي مدير عام
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'فاتن زكريا المحلاوي مدير عام';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%فاتن زكريا المحلاوي مدير عام%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'فاتن زكريا المحلاوي مدير عام', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-05-04', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض | |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'87',
        '2026-05-04',
        '2026-05-04',
        N'أ',
        N'صباح رمضان',
        N'عدم تسليم السائق/ محمود سليم محمد اذن التشغيل للسيارة رقم 6727 للعمل بالكسح رقم الاذن 48327 في تاريخه',
        '2026-05-04',
        N'ديوان عام الشركة',
        N'عدم تسليم السائق/ محمود سليم محمد اذن التشغيل للسيارة رقم 6727 للعمل بالكسح رقم الاذن 48327 في تاريخه',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'محمود سليم محمد اذن التشغيل',
        '2026-05-04 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: محمود سليم محمد اذن التشغيل
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE Code = N'6727';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمود سليم محمد اذن التشغيل';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمود سليم محمد اذن التشغيل%';
    IF @EmpMasterId IS NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM EmployeesMaster WHERE Code = N'6727')
            SET @NewCode = N'6727';
        ELSE
            SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمود سليم محمد اذن التشغيل', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-05-11', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 11/5/2026 | ورد من ر.م.أ 17/5/2026 |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'88',
        '2026-07-04',
        '2026-07-04',
        N'أ',
        N'وفاء رمزى',
        N'قيام سائق السيارة رقم 2665 بالوقف فوق البيار وضبط السكينة بمحبس الطارء العمومي بمحطة المراغي الجديد',
        '2026-07-04',
        N'بمحطة المراغي الجديد',
        N'قيام سائق السيارة رقم 2665 بالوقف فوق البيار وضبط السكينة بمحبس الطارء العمومي بمحطة المراغي الجديد',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'سائق السيارة رقم 2665 بالوقف',
        '2026-07-04 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: سائق السيارة رقم 2665 بالوقف
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE Code = N'2665';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'سائق السيارة رقم 2665 بالوقف';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%سائق السيارة رقم 2665 بالوقف%';
    IF @EmpMasterId IS NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM EmployeesMaster WHERE Code = N'2665')
            SET @NewCode = N'2665';
        ELSE
            SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'سائق السيارة رقم 2665 بالوقف', N'موظف', N'بمحطة المراغي الجديد', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-07-04', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض | |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'89',
        '2026-04-14',
        '2026-04-14',
        N'أ',
        N'مروة حمزة',
        N'عدم تنفيذ التعليمات من ادارة المحطات ومدير عام منطقة المنتزه رئيس محطة الصاعيده الفني/ هارون خليل عبده بشأن مسئول الوردية الثانيه للعمل بمفرده للعامل/عبدالهادي موسى',
        '2026-04-14',
        N'محطة الصاعيده الفني',
        N'عدم تنفيذ التعليمات من ادارة المحطات ومدير عام منطقة المنتزه رئيس محطة الصاعيده الفني/ هارون خليل عبده بشأن مسئول الوردية الثانيه للعمل بمفرده للعامل/عبدالهادي موسى',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'هارون خليل عبده بشأن مسئول',
        '2026-04-14 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: هارون خليل عبده بشأن مسئول
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'هارون خليل عبده بشأن مسئول';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%هارون خليل عبده بشأن مسئول%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'هارون خليل عبده بشأن مسئول', N'موظف', N'محطة الصاعيده الفني', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'90',
        '2026-07-04',
        '2026-07-04',
        N'أ',
        N'صباح رمضان',
        N'قيام رئيس محطة 4 منتزه اول السيد/ رضا ياقوت باجراء صيانه لاحدى الطلبات بدون ابلاغ رساءة العملاثناء النوه',
        '2026-07-04',
        N'محطة 4 منتزه اول السيد',
        N'قيام رئيس محطة 4 منتزه اول السيد/ رضا ياقوت باجراء صيانه لاحدى الطلبات بدون ابلاغ رساءة العملاثناء النوه',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'رئيس محطة 4 منتزه اول',
        '2026-07-04 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: رئيس محطة 4 منتزه اول
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'رئيس محطة 4 منتزه اول';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%رئيس محطة 4 منتزه اول%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'رئيس محطة 4 منتزه اول', N'موظف', N'محطة 4 منتزه اول السيد', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-07-04', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض | |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'91',
        '2026-07-04',
        '2026-07-04',
        N'أ',
        N'نرمين قنديل',
        N'تحدث العامل/ السيد مجدي السيد محمود كود(10988) باسلوب غير لائق مع زملائه في العمل وغير منتظم بالعمل',
        '2026-07-04',
        N'ديوان عام الشركة',
        N'تحدث العامل/ السيد مجدي السيد محمود كود(10988) باسلوب غير لائق مع زملائه في العمل وغير منتظم بالعمل',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'مجدي السيد محمود كود(10988) باسلوب',
        '2026-07-04 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: مجدي السيد محمود كود(10988) باسلوب
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'مجدي السيد محمود كود(10988) باسلوب';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%مجدي السيد محمود كود(10988) باسلوب%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'مجدي السيد محمود كود(10988) باسلوب', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-04-16', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 16/4/2026 | ورد من ر.م.أ 18/4/2026 |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'92',
        '2026-04-14',
        '2026-04-14',
        N'أ',
        N'وفاء رمزى',
        N'قيام السيد/ حسن فرج زكي كود(8665) بالتحدث باسلوب غير لائق مع رئيسه',
        '2026-04-14',
        N'ديوان عام الشركة',
        N'قيام السيد/ حسن فرج زكي كود(8665) بالتحدث باسلوب غير لائق مع رئيسه',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'حسن فرج زكي كود(8665) بالتحدث',
        '2026-04-14 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: حسن فرج زكي كود(8665) بالتحدث
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'حسن فرج زكي كود(8665) بالتحدث';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%حسن فرج زكي كود(8665) بالتحدث%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'حسن فرج زكي كود(8665) بالتحدث', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'93',
        '2026-04-15',
        '2026-04-15',
        N'أ',
        N'نرمين قنديل',
        N'سرقة الكابلات المولد رقم 2 بمحطة معالجة المعمورة لاتهام موجه الى الفني/ محمد مسعود مفتاح',
        '2026-04-15',
        N'بمحطة معالجة المعمورة لاتهام موجه الى',
        N'سرقة الكابلات المولد رقم 2 بمحطة معالجة المعمورة لاتهام موجه الى الفني/ محمد مسعود مفتاح',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'محمد مسعود مفتاح',
        '2026-04-15 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: محمد مسعود مفتاح
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمد مسعود مفتاح';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمد مسعود مفتاح%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمد مسعود مفتاح', N'موظف', N'بمحطة معالجة المعمورة لاتهام موجه الى', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-04-15', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض | |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'94',
        '2026-04-14',
        '2026-04-14',
        N'أ',
        N'مروة حمزة',
        N'امتناع العامل/ جابر ابواليزيد عن العمل بالورديه الثانية بمحطة التنقيه الشرقيه',
        '2026-04-14',
        N'بمحطة التنقيه الشرقيه',
        N'امتناع العامل/ جابر ابواليزيد عن العمل بالورديه الثانية بمحطة التنقيه الشرقيه',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'جابر ابواليزيد',
        '2026-04-14 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: جابر ابواليزيد
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'جابر ابواليزيد';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%جابر ابواليزيد%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'جابر ابواليزيد', N'موظف', N'بمحطة التنقيه الشرقيه', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'95',
        '2026-04-14',
        '2026-04-14',
        N'أ',
        N'هاني احمد',
        N'المرور على محطة رفع السيوف شرق يوم 1/4/2026 الساعة 10 تلاحظ نوم كلا من في العمل/ علي محمد و احمد الخضري احمد والتحدث باسلوب غير لائق',
        '2026-04-01',
        N'محطة رفع السيوف شرق',
        N'المرور على محطة رفع السيوف شرق يوم 1/4/2026 الساعة 10 تلاحظ نوم كلا من في العمل/ علي محمد و احمد الخضري احمد والتحدث باسلوب غير لائق',
        N'صدر قرار',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'موظف محال للتحقيق',
        '2026-04-14 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'محطة رفع السيوف شرق', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-05-20', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 20/5/2026 | ورد من ر.م.أ 1/6/2026 |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'96',
        '2026-04-14',
        '2026-04-14',
        N'أ',
        N'ايناس جلال',
        N'المرور على محطة الشمعدان يوم 16/4/2026 الوردية الثانية تلاحظ ان المحطة مغلقة',
        '2026-04-16',
        N'محطة الشمعدان',
        N'المرور على محطة الشمعدان يوم 16/4/2026 الوردية الثانية تلاحظ ان المحطة مغلقة',
        N'جارية',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'موظف محال للتحقيق',
        '2026-04-14 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'محطة الشمعدان', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'97',
        '2026-04-14',
        '2026-04-14',
        N'أ',
        N'غادة شكرى',
        N'قيام السيد المهندس / احمد عبدالفاتح عيد مير عام معالجة غرب بالتحدث باسلوب غير لائق مع السيد المهندس رئيس الشركة',
        '2026-04-14',
        N'ديوان عام الشركة',
        N'قيام السيد المهندس / احمد عبدالفاتح عيد مير عام معالجة غرب بالتحدث باسلوب غير لائق مع السيد المهندس رئيس الشركة',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'السيد المهندس',
        '2026-04-14 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: المهندس
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'المهندس';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%المهندس%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'المهندس', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-04-27', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 27/4/2026 | ورد من ر.م.أ 30/4/2026 |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'98',
        '2026-04-02',
        NULL,
        N'أ',
        N'تامر الحداد',
        N'المرور على محطة ارض ميدان العجمي يوم الخميس 2/4/2026 الساعة 3 تلاحظ ان كل فرد بالمحطة بشتغل يومان المسئول مدير اداراة محطات العجمي',
        '2026-04-02',
        N'محطة ارض ميدان العجمي',
        N'المرور على محطة ارض ميدان العجمي يوم الخميس 2/4/2026 الساعة 3 تلاحظ ان كل فرد بالمحطة بشتغل يومان المسئول مدير اداراة محطات العجمي',
        N'صدر قرار',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'موظف محال للتحقيق',
        '2026-04-02 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'محطة ارض ميدان العجمي', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-02-01', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض | |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'99',
        '2026-04-15',
        '2026-04-15',
        N'أ',
        N'ريهام شفيق',
        N'المرور على مناطق الشركة المختلفة تلاحظ موقع اباظه مغلق يوم 4/4/2026 الساعة 4:45ص و موقع جهينه العجمي مغلق يوم 7/4/2026 الساعة 4:55 م',
        '2026-04-04',
        N'موقع اباظه مغلق',
        N'المرور على مناطق الشركة المختلفة تلاحظ موقع اباظه مغلق يوم 4/4/2026 الساعة 4:45ص و موقع جهينه العجمي مغلق يوم 7/4/2026 الساعة 4:55 م',
        N'صدر قرار',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'موظف محال للتحقيق',
        '2026-04-15 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'موقع اباظه مغلق', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-03-18', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 18/3/2026 | ورد من ر.م.أ 21/5/2026 |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'100',
        '2026-04-16',
        '2026-04-16',
        N'أ',
        N'وفاء رمزى',
        N'مرور الامن على محطة عبدالقادر بحري العامرية تلاحظ وجود مخالفات استلام منظومة الحريق لاطفاء التلقائي',
        '2026-04-16',
        N'محطة عبدالقادر بحري العامرية',
        N'مرور الامن على محطة عبدالقادر بحري العامرية تلاحظ وجود مخالفات استلام منظومة الحريق لاطفاء التلقائي',
        N'جارية',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'موظف محال للتحقيق',
        '2026-04-16 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'محطة عبدالقادر بحري العامرية', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'101',
        '2026-04-30',
        '2026-04-30',
        N'أ',
        N'خالد احمد',
        N'مرور الامن على محطة معالجة ابو تلات يوم الثلاثاء الموافق 7/4/2026 التى وجدت مغلقة وغير متواجد بها احد',
        '2026-04-07',
        N'محطة معالجة ابو تلات',
        N'مرور الامن على محطة معالجة ابو تلات يوم الثلاثاء الموافق 7/4/2026 التى وجدت مغلقة وغير متواجد بها احد',
        N'جارية',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'موظف محال للتحقيق',
        '2026-04-30 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'محطة معالجة ابو تلات', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'102',
        '2026-01-01',
        NULL,
        N'أ',
        N'ايمن توفيق',
        N'السيد/احمد عبد الفتاح الذى قام بعدة مخالفات صريحة وقد تسبب اضرار مباشر لسمعة الشركة ومصلحتها العامة',
        '2026-01-01',
        N'ديوان عام الشركة',
        N'السيد/احمد عبد الفتاح الذى قام بعدة مخالفات صريحة وقد تسبب اضرار مباشر لسمعة الشركة ومصلحتها العامة',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'موظف محال للتحقيق',
        '2026-01-01 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-05-18', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 18/5/2026 | ورد من ر.م.أ 21/5/2026 |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'103',
        '2026-01-01',
        NULL,
        N'أ',
        N'نورة عباس',
        N'بشان لفنى/هارون خليل عبده كود (8058) بعدم تنفيذ تعليمات الادارة محطة المنتزة',
        '2026-01-01',
        N'محطة المنتزة',
        N'بشان لفنى/هارون خليل عبده كود (8058) بعدم تنفيذ تعليمات الادارة محطة المنتزة',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'موظف محال للتحقيق',
        '2026-01-01 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'محطة المنتزة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-05-10', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 10/5/2026 | ورد من ر.م.أ 14/5/2026 |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'104',
        '2026-04-21',
        '2026-04-21',
        N'أ',
        N'طارق السيد',
        N'السائق/ حمدى حامد عامر الذى خالف خط السير حيث كان من المفترض العمل مع الشبكة والصيانة الدخيلة ش المطافى ولكن تم ضبطة بشارع نور الاسلام طريق ام زغيو امام غرفة الكهرباء',
        '2026-04-21',
        N'ديوان عام الشركة',
        N'السائق/ حمدى حامد عامر الذى خالف خط السير حيث كان من المفترض العمل مع الشبكة والصيانة الدخيلة ش المطافى ولكن تم ضبطة بشارع نور الاسلام طريق ام زغيو امام غرفة الكهرباء',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'حمدى حامد عامر الذى خالف',
        '2026-04-21 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: حمدى حامد عامر الذى خالف
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'حمدى حامد عامر الذى خالف';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%حمدى حامد عامر الذى خالف%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'حمدى حامد عامر الذى خالف', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'105',
        '2026-04-23',
        '2026-04-23',
        N'أ',
        N'مروة حمزة',
        N'وجود محطة ونيس منطقة العجمى مغلقة يوم 12/4/2026 الساعة 12:15 وكان من المفترض وجود عامل بالوردية الاولى هو مصطفى السيد عمرو افادت المذكور قام بفتح المحطة بعد علمة بمرور التفتيش',
        '2026-04-12',
        N'محطة ونيس منطقة العجمى مغلقة',
        N'وجود محطة ونيس منطقة العجمى مغلقة يوم 12/4/2026 الساعة 12:15 وكان من المفترض وجود عامل بالوردية الاولى هو مصطفى السيد عمرو افادت المذكور قام بفتح المحطة بعد علمة بمرور التفتيش',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'موظف محال للتحقيق',
        '2026-04-23 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'محطة ونيس منطقة العجمى مغلقة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'106',
        '2026-05-06',
        '2026-05-06',
        N'أ',
        N'ايناس جلال',
        N'المرور على محطة (5) يوم الاحد الموافق 12/4/2026 الساعة 9م بالوردية الثانية وجدت مغلقة وكان المسئول العامل / ايمن محمد مصطفى سيد (8692)',
        '2026-04-12',
        N'محطة (5)',
        N'المرور على محطة (5) يوم الاحد الموافق 12/4/2026 الساعة 9م بالوردية الثانية وجدت مغلقة وكان المسئول العامل / ايمن محمد مصطفى سيد (8692)',
        N'جارية',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'ايمن محمد مصط',
        '2026-05-06 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: ايمن محمد مصط
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'ايمن محمد مصط';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%ايمن محمد مصط%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'ايمن محمد مصط', N'موظف', N'محطة (5)', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'107',
        '2026-04-22',
        '2026-04-22',
        N'أ',
        N'هدى رجب',
        N'بشأن تقديم مجموعة من السادة 1- جليلة محمود 2- احمد محمد 3- مدحت محمود 4- محمد نصر الدين 5- ابراهيم عبد المنعم ضد السيد/ عبد الفتاح حسن لان يثير الفوضى والبلبلة وتهديد الزملاء',
        '2026-04-22',
        N'ديوان عام الشركة',
        N'بشأن تقديم مجموعة من السادة 1- جليلة محمود 2- احمد محمد 3- مدحت محمود 4- محمد نصر الدين 5- ابراهيم عبد المنعم ضد السيد/ عبد الفتاح حسن لان يثير الفوضى والبلبلة وتهديد الزملاء',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'السيد/ عبد الفتاح حسن لان يثير الفوضى والبلبلة وتهديد الزملاء',
        '2026-04-22 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: جليلة محمود
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'جليلة محمود';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%جليلة محمود%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'جليلة محمود', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: احمد محمد
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'احمد محمد';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%احمد محمد%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'احمد محمد', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: مدحت محمود
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'مدحت محمود';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%مدحت محمود%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'مدحت محمود', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: محمد نصر الدين
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمد نصر الدين';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمد نصر الدين%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمد نصر الدين', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-04-22', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض | |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'108',
        '2026-04-21',
        '2026-04-21',
        N'أ',
        N'وفاء رمزى',
        N'بشان مرور الامن على محطة معالجة ابو تلات غرب عدة مرات وجدت مغلقة يوم 15/4/2026',
        '2026-04-15',
        N'محطة معالجة ابو تلات غرب عدة',
        N'بشان مرور الامن على محطة معالجة ابو تلات غرب عدة مرات وجدت مغلقة يوم 15/4/2026',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'موظف محال للتحقيق',
        '2026-04-21 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'محطة معالجة ابو تلات غرب عدة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-04-21', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض | |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'109',
        '2026-02-01',
        NULL,
        N'أ',
        N'ريهام شفيق',
        N'اجراء التحقيق مع السيد/ حسام عجمى لتقديمة اجازة من يوم 1/2/2026 حتى 4/4/2026',
        '2026-02-01',
        N'ديوان عام الشركة',
        N'اجراء التحقيق مع السيد/ حسام عجمى لتقديمة اجازة من يوم 1/2/2026 حتى 4/4/2026',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'موظف محال للتحقيق',
        '2026-02-01 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-04-23', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 23/4/2026 | ورد من ر.م.أ 30/4/2026 |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'110',
        '2026-04-12',
        NULL,
        N'أ',
        N'هانى احمد',
        N'بشأن وجود محطات مغلقة فى لعامرية يوم 12/4/2026 الساعة 2:15ص يوم 17/4/2026',
        '2026-04-12',
        N'ديوان عام الشركة',
        N'بشأن وجود محطات مغلقة فى لعامرية يوم 12/4/2026 الساعة 2:15ص يوم 17/4/2026',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'موظف محال للتحقيق',
        '2026-04-12 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-05-20', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 20/5/2026 | |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'111',
        '2026-03-16',
        NULL,
        N'أ',
        N'صباح رمضان',
        N'نقل السيد/ احمد محمد احمد بالدرجة الثالثة بتاريخ 16/3/2026 وحيث ان المذكور من قطاع الصرف الصناعى بتاريخ 24/3/2026',
        '2026-03-16',
        N'قطاع الصرف الصناعى',
        N'نقل السيد/ احمد محمد احمد بالدرجة الثالثة بتاريخ 16/3/2026 وحيث ان المذكور من قطاع الصرف الصناعى بتاريخ 24/3/2026',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'موظف محال للتحقيق',
        '2026-03-16 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'قطاع الصرف الصناعى', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-06-01', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 1/6/2026 | |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'112',
        '2026-04-21',
        '2026-04-21',
        N'أ',
        N'طارق السيد',
        N'بشان محمد تامر محمد لارتكابة المخالفات بدل راحة عيد فطر والتلاعب فى سجلات الحضور والانصراف',
        '2026-04-21',
        N'ديوان عام الشركة',
        N'بشان محمد تامر محمد لارتكابة المخالفات بدل راحة عيد فطر والتلاعب فى سجلات الحضور والانصراف',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'موظف محال للتحقيق',
        '2026-04-21 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'113',
        '2026-04-29',
        '2026-04-29',
        N'أ',
        N'ايمن توفيق',
        N'بشان تتبع السيارة (6559) على برنامج GPS يوم 18/4/2026 وجد ان السيارة تتحرك مخالف للانزار',
        '2026-04-18',
        N'ديوان عام الشركة',
        N'بشان تتبع السيارة (6559) على برنامج GPS يوم 18/4/2026 وجد ان السيارة تتحرك مخالف للانزار',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'موظف محال للتحقيق',
        '2026-04-29 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'114',
        '2026-03-29',
        '2026-03-29',
        N'أ',
        N'شعبان السيد',
        N'عدم وجود السيد/ محمد رزق عبد الفتاح مسئول الوردية الليلية ووجود عبث بلوح الكهرباء بتعليمات المرفع وتعاطى مواد مخدرة بموقع العمل',
        '2026-03-29',
        N'بموقع العمل',
        N'عدم وجود السيد/ محمد رزق عبد الفتاح مسئول الوردية الليلية ووجود عبث بلوح الكهرباء بتعليمات المرفع وتعاطى مواد مخدرة بموقع العمل',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'موظف محال للتحقيق',
        '2026-03-29 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'بموقع العمل', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'115',
        '2026-04-27',
        '2026-04-27',
        N'أ',
        N'حنان الخشاب',
        N'مرور الامن على محطة معالجة او تلات يوم 21/4/2026 الساعة 4:35 م وجدت مغلقة',
        '2026-04-21',
        N'محطة معالجة او تلات',
        N'مرور الامن على محطة معالجة او تلات يوم 21/4/2026 الساعة 4:35 م وجدت مغلقة',
        N'جارية',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'موظف محال للتحقيق',
        '2026-04-27 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'محطة معالجة او تلات', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'116',
        '2026-05-12',
        '2026-05-12',
        N'أ',
        N'هانى احمد',
        N'التحقيق مع رئي اللجنة المشكلة الاستلام بالمحطة وذلك لعدم اشكال الاعمال المدنية من حوالى 3 سنوات',
        '2026-05-12',
        N'محطة',
        N'التحقيق مع رئي اللجنة المشكلة الاستلام بالمحطة وذلك لعدم اشكال الاعمال المدنية من حوالى 3 سنوات',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'موظف محال للتحقيق',
        '2026-05-12 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'محطة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'117',
        '2026-05-11',
        '2026-05-11',
        N'أ',
        N'مروة حمزة',
        N'مرور الامن على محطة مرغم العامرية يوم 21/4/2026 الساعة 4:5 م وجدت مغلقة',
        '2026-04-21',
        N'محطة مرغم العامرية',
        N'مرور الامن على محطة مرغم العامرية يوم 21/4/2026 الساعة 4:5 م وجدت مغلقة',
        N'صدر قرار',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'موظف محال للتحقيق',
        '2026-05-11 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'محطة مرغم العامرية', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-05-11', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض | |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'118',
        '2026-04-17',
        NULL,
        N'أ',
        N'ايناس جلال',
        N'المرور محطة 5.23 فى يوم 17/4/2026 فى تمام الساعة 2:30ص وجدت مغلقة وبعد الانتظار لمدة 20 د ان عامل الوردية ياسر محمد جميل قال بعض الالفاظ الخارجة',
        '2026-04-17',
        N'محطة 5',
        N'المرور محطة 5.23 فى يوم 17/4/2026 فى تمام الساعة 2:30ص وجدت مغلقة وبعد الانتظار لمدة 20 د ان عامل الوردية ياسر محمد جميل قال بعض الالفاظ الخارجة',
        N'جارية',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'موظف محال للتحقيق',
        '2026-04-17 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'محطة 5', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'119',
        '2026-05-12',
        '2026-05-12',
        N'أ',
        N'هاني احمد',
        N'الشكاوي المقدمة من ك/عصام عبدالرحيم محمد من السائق/محمد بدري سعد-كود10824 حيث المذكور قام بسبي على موقع التواصل الاجتماعي',
        '2026-05-12',
        N'موقع التواصل الاجتماعي',
        N'الشكاوي المقدمة من ك/عصام عبدالرحيم محمد من السائق/محمد بدري سعد-كود10824 حيث المذكور قام بسبي على موقع التواصل الاجتماعي',
        N'مغلقة',
        NULL,
        N'ك/عصام عبدالرحيم محمد من السائق/محمد بدري سعدكود10824 حيث المذكور قام بسبي',
        N'موقع التواصل الاجتماعي',
        '2026-05-12 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موقع التواصل الاجتماعي
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE Code = N'10824';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موقع التواصل الاجتماعي';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موقع التواصل الاجتماعي%';
    IF @EmpMasterId IS NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM EmployeesMaster WHERE Code = N'10824')
            SET @NewCode = N'10824';
        ELSE
            SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موقع التواصل الاجتماعي', N'موظف', N'موقع التواصل الاجتماعي', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-06-09', N'رئيس مجلس الإدارة', N'مجازاة بخصم من الراتب', N'ثلاثة ايام من راتبه', N'عرض ر.م.أ 9/6/2026 | ورد ر.م.أ 16/6/2026 | بمجازات أ/محمود صلاح مرسي و فضل ابراهيم فضل بخصم ثلاثة ايام من راتبهم', GETDATE());
    INSERT INTO FinalDecisions (InvestigationId, FinalDecisionText, ActionType, HRSentDate, HRNotes, CreatedAt)
    VALUES (@InvId, N'بمجازات أ/محمود صلاح مرسي و فضل ابراهيم فضل بخصم ثلاثة ايام من راتبهم', 'hr', '2026-06-09', N'عرض ر.م.أ 9/6/2026 | ورد ر.م.أ 16/6/2026 | بمجازات أ/محمود صلاح مرسي و فضل ابراهيم فضل بخصم ثلاثة ايام من راتبهم', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'120',
        '2026-05-11',
        '2026-05-11',
        N'أ',
        N'شعبان السيد',
        N'عدم تواجد الماسورة بمحول 2م بالسيارة المدمجة رقم 1826 , قيام السائق/ يوسف خميس عز الدين كود 11168',
        '2026-05-11',
        N'ديوان عام الشركة',
        N'عدم تواجد الماسورة بمحول 2م بالسيارة المدمجة رقم 1826 , قيام السائق/ يوسف خميس عز الدين كود 11168',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'يوسف خميس عز الدين كود',
        '2026-05-11 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: يوسف خميس عز الدين كود
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE Code = N'1826';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'يوسف خميس عز الدين كود';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%يوسف خميس عز الدين كود%';
    IF @EmpMasterId IS NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM EmployeesMaster WHERE Code = N'1826')
            SET @NewCode = N'1826';
        ELSE
            SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'يوسف خميس عز الدين كود', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'121',
        '2026-05-12',
        '2026-05-12',
        N'أ',
        N'وفاء رمزى',
        N'المرور على محطة التنقية الغربيه يوم 22/4/2026 الساعة 2 ص تلاحظ البوابه مفتوحه ونوم حارس الامن /علي السيد هلال',
        '2026-04-22',
        N'محطة التنقية الغربيه',
        N'المرور على محطة التنقية الغربيه يوم 22/4/2026 الساعة 2 ص تلاحظ البوابه مفتوحه ونوم حارس الامن /علي السيد هلال',
        N'جارية',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'علي السيد هلال',
        '2026-05-12 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: علي السيد هلال
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'علي السيد هلال';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%علي السيد هلال%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'علي السيد هلال', N'موظف', N'محطة التنقية الغربيه', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'122',
        '2026-05-06',
        '2026-05-06',
        N'أ',
        N'نورة عباس',
        N'الشكوى المقدمه من كلا من : 1-رجب شعبان رمضان , 2- محمد مبارك علي ضد السيد/فتحي امير فتحي مبروك من العاملين بمنطقة العجمي للاساءه والتشهير بهم بموقع التواصل الاجتماعي',
        '2026-05-06',
        N'بموقع التواصل الاجتماعي',
        N'الشكوى المقدمه من كلا من : 1-رجب شعبان رمضان , 2- محمد مبارك علي ضد السيد/فتحي امير فتحي مبروك من العاملين بمنطقة العجمي للاساءه والتشهير بهم بموقع التواصل الاجتماعي',
        N'مغلقة',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'السيد/فتحي امير فتحي مبروك من العاملين بمنطقة العجمي للاساءه والتشهير بهم بموقع التواصل الاجتماعي',
        '2026-05-06 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: رجب شعبان رمضان
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'رجب شعبان رمضان';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%رجب شعبان رمضان%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'رجب شعبان رمضان', N'موظف', N'بموقع التواصل الاجتماعي', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-06-03', N'رئيس مجلس الإدارة', N'مجازاة بخصم من الراتب', N'اربعة ايام من راتبه', N'عرض ر.م.أ 3/6/2026 | ورد ر.م.أ 15/6/2026 | بمجازات السيد/فتحي امير فتحي احمد بخصم اربعة ايام من راتبه+التشديد في حالة العوده', GETDATE());
    INSERT INTO FinalDecisions (InvestigationId, FinalDecisionText, ActionType, HRSentDate, HRNotes, CreatedAt)
    VALUES (@InvId, N'بمجازات السيد/فتحي امير فتحي احمد بخصم اربعة ايام من راتبه+التشديد في حالة العوده', 'hr', '2026-06-03', N'عرض ر.م.أ 3/6/2026 | ورد ر.م.أ 15/6/2026 | بمجازات السيد/فتحي امير فتحي احمد بخصم اربعة ايام من راتبه+التشديد في حالة العوده', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'123',
        '2026-05-24',
        '2026-05-24',
        N'أ',
        N'ايمن توفيق',
        N'سوء سلوك العامل/محمد اشرف عبدالمولى كود 11030 اثناء العمل والعودة من محطة السيوف',
        '2026-05-24',
        N'محطة السيوف',
        N'سوء سلوك العامل/محمد اشرف عبدالمولى كود 11030 اثناء العمل والعودة من محطة السيوف',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'محمد اشرف عبدالمولى كود 11030',
        '2026-05-24 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: محمد اشرف عبدالمولى كود 11030
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE Code = N'11030';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمد اشرف عبدالمولى كود 11030';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمد اشرف عبدالمولى كود 11030%';
    IF @EmpMasterId IS NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM EmployeesMaster WHERE Code = N'11030')
            SET @NewCode = N'11030';
        ELSE
            SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمد اشرف عبدالمولى كود 11030', N'موظف', N'محطة السيوف', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'124',
        '2026-05-04',
        '2026-05-04',
        N'أ',
        N'ريهام شفيق',
        N'قيام كلا من :1-احمد انور كمال 2-محمد احمد ابراهيم بسرقة بعض الاشياء الكهنه المتواجدة بمحطة البوصيري الجمرك',
        '2026-05-04',
        N'بمحطة البوصيري الجمرك',
        N'قيام كلا من :1-احمد انور كمال 2-محمد احمد ابراهيم بسرقة بعض الاشياء الكهنه المتواجدة بمحطة البوصيري الجمرك',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'كلا من 1',
        '2026-05-04 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: احمد انور كمال
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'احمد انور كمال';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%احمد انور كمال%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'احمد انور كمال', N'موظف', N'بمحطة البوصيري الجمرك', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: محمد احمد ابراهيم بسرقة بعض الاشياء الكهنه المتواجدة
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمد احمد ابراهيم بسرقة بعض الاشياء الكهنه المتواجدة';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمد احمد ابراهيم بسرقة بعض الاشياء الكهنه المتواجدة%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمد احمد ابراهيم بسرقة بعض الاشياء الكهنه المتواجدة', N'موظف', N'بمحطة البوصيري الجمرك', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-06-04', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض ر.م.ا 04/06/2026 | |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'125',
        '2026-05-16',
        '2026-05-16',
        N'أ',
        N'طارق السيد',
        N'قيام ك/محمد محمود السيد يعمل بمحطة ابيس 8/6 بالتدوين اسمه المعامل المركزيه مع عدم وجود اي مأمورية انها وهميه',
        '2026-06-08',
        N'بمحطة ابيس 8',
        N'قيام ك/محمد محمود السيد يعمل بمحطة ابيس 8/6 بالتدوين اسمه المعامل المركزيه مع عدم وجود اي مأمورية انها وهميه',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'موظف محال للتحقيق',
        '2026-05-16 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'بمحطة ابيس 8', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'126',
        '2026-05-10',
        '2026-05-10',
        N'أ',
        N'نورة عباس',
        N'قام نشره من خلال السيد/ ابو عمر ابو ضيف على الفيس بوك وتم الرد عليه من قبل السيد/رمضان محمد',
        '2026-05-10',
        N'ديوان عام الشركة',
        N'قام نشره من خلال السيد/ ابو عمر ابو ضيف على الفيس بوك وتم الرد عليه من قبل السيد/رمضان محمد',
        N'مغلقة',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'موظف محال للتحقيق',
        '2026-05-10 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-05-11', N'رئيس مجلس الإدارة', N'حفظ التحقيق', N'حفظ التحقيق', N'عرض ر.م.أ 11/5/2026 | ارسال اصل الملف للموارد البشريه 17/5/2026 | حفظ التحقيق', GETDATE());
    INSERT INTO FinalDecisions (InvestigationId, FinalDecisionText, ActionType, HRSentDate, HRNotes, CreatedAt)
    VALUES (@InvId, N'حفظ التحقيق', 'archive', '2026-05-11', N'عرض ر.م.أ 11/5/2026 | ارسال اصل الملف للموارد البشريه 17/5/2026 | حفظ التحقيق', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'127',
        '2026-05-24',
        '2026-05-24',
        N'أ',
        N'ايمن توفيق',
        N'التلاعب في سجلات الحضور والانصراف ونبغ عنه وجود حضور الفني/سالم شحات السيد الورديه الثانيه متأخر يوم 23/4/2026 بتوقيت 6 م والوردية الثانيه وذلك بدون اذن',
        '2026-04-23',
        N'ديوان عام الشركة',
        N'التلاعب في سجلات الحضور والانصراف ونبغ عنه وجود حضور الفني/سالم شحات السيد الورديه الثانيه متأخر يوم 23/4/2026 بتوقيت 6 م والوردية الثانيه وذلك بدون اذن',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'سالم شحات السيد الورديه الثانيه',
        '2026-05-24 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: سالم شحات السيد الورديه الثانيه
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'سالم شحات السيد الورديه الثانيه';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%سالم شحات السيد الورديه الثانيه%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'سالم شحات السيد الورديه الثانيه', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-06-22', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض ر.م.أ 22/6/2026 | |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'128',
        '2026-05-14',
        '2026-05-14',
        N'أ',
        N'وفاء رمزى',
        N'تحدث الفني/علي رمضان علي حسين بأسلوب غير لائق يعمل بمحطة نوبار 2 منتزه اول',
        '2026-05-14',
        N'بمحطة نوبار 2 منتزه اول',
        N'تحدث الفني/علي رمضان علي حسين بأسلوب غير لائق يعمل بمحطة نوبار 2 منتزه اول',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'علي رمضان علي حسين بأسلوب',
        '2026-05-14 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: علي رمضان علي حسين بأسلوب
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'علي رمضان علي حسين بأسلوب';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%علي رمضان علي حسين بأسلوب%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'علي رمضان علي حسين بأسلوب', N'موظف', N'بمحطة نوبار 2 منتزه اول', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'129',
        '2026-05-19',
        '2026-05-19',
        N'أ',
        N'شعبان السيد',
        N'سرقة بعض الاصناف من عنابر منظومة الكلور والغاز من محطة معالجة خورشيد والزاويده',
        '2026-05-19',
        N'محطة معالجة خورشيد والزاويده',
        N'سرقة بعض الاصناف من عنابر منظومة الكلور والغاز من محطة معالجة خورشيد والزاويده',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'موظف محال للتحقيق',
        '2026-05-19 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'محطة معالجة خورشيد والزاويده', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'130',
        '2026-05-24',
        '2026-05-24',
        N'أ',
        N'وفاء رمزى',
        N'اختفاء عدد(3) مشايا يوم الخميس 7/5/2026 وتم الابلاغ من قبل الفني/محمود محمد رفعت وتم التنبيه على الفني/احمد خميس ابوضيف بضرورة التأمين وتم الابلاغ مرة اخرى عن اختفاء عدد(1)مشايا يوم 10/5/2026',
        '2026-05-07',
        N'ديوان عام الشركة',
        N'اختفاء عدد(3) مشايا يوم الخميس 7/5/2026 وتم الابلاغ من قبل الفني/محمود محمد رفعت وتم التنبيه على الفني/احمد خميس ابوضيف بضرورة التأمين وتم الابلاغ مرة اخرى عن اختفاء عدد(1)مشايا يوم 10/5/2026',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'محمود محمد رفعت وتم التنبيه',
        '2026-05-24 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: محمود محمد رفعت وتم التنبيه
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمود محمد رفعت وتم التنبيه';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمود محمد رفعت وتم التنبيه%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمود محمد رفعت وتم التنبيه', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'131',
        '2026-05-25',
        '2026-05-25',
        N'أ',
        N'طارق السيد',
        N'فقد شاشة 32 بوصه جاك خاصه بمنظومة كاميرات المراقبه بمحطة معالجة الهانوفيل',
        '2026-05-25',
        N'بمحطة معالجة الهانوفيل',
        N'فقد شاشة 32 بوصه جاك خاصه بمنظومة كاميرات المراقبه بمحطة معالجة الهانوفيل',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'موظف محال للتحقيق',
        '2026-05-25 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'بمحطة معالجة الهانوفيل', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'132',
        '2026-05-20',
        '2026-05-20',
        N'أ',
        N'خالد احمد',
        N'المرور على محطة معالجة ابيس العاشره يوم 10/5/2026 تلاحظ قيام السيد/احمد محمد شبل بالتدوين بالسجل مأمورية وهميه',
        '2026-05-10',
        N'محطة معالجة ابيس العاشره',
        N'المرور على محطة معالجة ابيس العاشره يوم 10/5/2026 تلاحظ قيام السيد/احمد محمد شبل بالتدوين بالسجل مأمورية وهميه',
        N'جارية',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'احمد محمد شبل بالتدوين بالسجل',
        '2026-05-20 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: احمد محمد شبل بالتدوين بالسجل
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'احمد محمد شبل بالتدوين بالسجل';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%احمد محمد شبل بالتدوين بالسجل%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'احمد محمد شبل بالتدوين بالسجل', N'موظف', N'محطة معالجة ابيس العاشره', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'133',
        '2026-06-02',
        '2026-06-02',
        N'أ',
        N'مروة حمزة',
        N'تقاعس السائق/ عادل محمود محمد كود10846 عن العمل يوم الجمعه 8/5/2026 برفع تجمعات المياه عن الطريق الصحراوي',
        '2026-05-08',
        N'ديوان عام الشركة',
        N'تقاعس السائق/ عادل محمود محمد كود10846 عن العمل يوم الجمعه 8/5/2026 برفع تجمعات المياه عن الطريق الصحراوي',
        N'مغلقة',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'عادل محمود محمد كود10846',
        '2026-06-02 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: عادل محمود محمد كود10846
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE Code = N'10846';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'عادل محمود محمد كود10846';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%عادل محمود محمد كود10846%';
    IF @EmpMasterId IS NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM EmployeesMaster WHERE Code = N'10846')
            SET @NewCode = N'10846';
        ELSE
            SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'عادل محمود محمد كود10846', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-06-28', N'رئيس مجلس الإدارة', N'إنذار وتنبيه', N'إنذار', N'عرض ر.م.أ 28/6/2026 | | مجازة السائق عادل محمود محمد بالانذار والتشديد', GETDATE());
    INSERT INTO FinalDecisions (InvestigationId, FinalDecisionText, ActionType, HRSentDate, HRNotes, CreatedAt)
    VALUES (@InvId, N'مجازة السائق عادل محمود محمد بالانذار والتشديد', 'hr', '2026-06-28', N'عرض ر.م.أ 28/6/2026 | | مجازة السائق عادل محمود محمد بالانذار والتشديد', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'134',
        '2026-06-01',
        '2026-06-01',
        N'أ',
        N'ايناس جلال',
        N'المرور على محطة جوانيدر يوم 6/5/2026 بالوردية المسائيه الساعه 2:5 م تلاحظ ان المحطه مغلقه',
        '2026-05-06',
        N'محطة جوانيدر',
        N'المرور على محطة جوانيدر يوم 6/5/2026 بالوردية المسائيه الساعه 2:5 م تلاحظ ان المحطه مغلقه',
        N'جارية',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'موظف محال للتحقيق',
        '2026-06-01 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'محطة جوانيدر', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'135',
        '2026-05-20',
        '2026-05-20',
        N'أ',
        N'هدى رجب',
        N'الابلاغ عن محطة ونيس بوجود طفح وغرق بالشوارع المحيطه بالمحطه وتلاحظ عدم وجود اي فرد في المحطة برغم من توقيع الفني/مصطفى السيد وعند تشغيل المحطة بمعرفة الفني/محمد فضل الذي تم استعارة للمحطة',
        '2026-05-20',
        N'محطة ونيس بوجود طفح وغرق بالشوارع',
        N'الابلاغ عن محطة ونيس بوجود طفح وغرق بالشوارع المحيطه بالمحطه وتلاحظ عدم وجود اي فرد في المحطة برغم من توقيع الفني/مصطفى السيد وعند تشغيل المحطة بمعرفة الفني/محمد فضل الذي تم استعارة للمحطة',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'مصط',
        '2026-05-20 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: مصط
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'مصط';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%مصط%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'مصط', N'موظف', N'محطة ونيس بوجود طفح وغرق بالشوارع', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-05-20', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض | |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'136',
        '2026-05-20',
        '2026-05-20',
        N'أ',
        N'صباح رمضان',
        N'فقد السائق/محمد رضوان الاذن بتاريخ 7/5/2026 اثناء العمل بالسيارة ببلاغ بمنطقة محرم بك وقد افاد بأنه سقط منه اثناء العمل بموجوده مراقب الورديه أ/محمود ابراهيم',
        '2026-05-07',
        N'بمنطقة محرم بك وقد افاد',
        N'فقد السائق/محمد رضوان الاذن بتاريخ 7/5/2026 اثناء العمل بالسيارة ببلاغ بمنطقة محرم بك وقد افاد بأنه سقط منه اثناء العمل بموجوده مراقب الورديه أ/محمود ابراهيم',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'محمد رضوان الاذن',
        '2026-05-20 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: محمد رضوان الاذن
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمد رضوان الاذن';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمد رضوان الاذن%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمد رضوان الاذن', N'موظف', N'بمنطقة محرم بك وقد افاد', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-05-20', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض | |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'137',
        '2026-05-20',
        '2026-05-20',
        N'أ',
        N'غادة شكرى',
        N'محمود احمد مصطفى 2-اسلام احمد الحوشي 3-ابراهيم فتحي يوسف لارتكابهم المخالفات الاتيه: سرقة كابل نحاسي وكابل طلمبه غاطس وتعطيل عهده عن العمل بقطع الكابل النحاسي و الاتفاق لتشكيل عصابي لسرقة وتعطيل الكاميرات ومسح الداتا الخاصه بالكاميرا',
        '2026-05-20',
        N'ديوان عام الشركة',
        N'محمود احمد مصطفى 2-اسلام احمد الحوشي 3-ابراهيم فتحي يوسف لارتكابهم المخالفات الاتيه: سرقة كابل نحاسي وكابل طلمبه غاطس وتعطيل عهده عن العمل بقطع الكابل النحاسي و الاتفاق لتشكيل عصابي لسرقة وتعطيل الكاميرات ومسح الداتا الخاصه بالكاميرا',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'اسلام احمد الحوشي',
        '2026-05-20 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: اسلام احمد الحوشي
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'اسلام احمد الحوشي';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%اسلام احمد الحوشي%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'اسلام احمد الحوشي', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-06-14', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض ر.م.أ 14/6/2026 | |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'138',
        '2026-06-02',
        '2026-06-02',
        N'أ',
        N'مروة حمزة',
        N'قيام العامل/محمد احمد ابراهيم كود 9824 بسرقة عدد3 اغطيه سيفونات حديد تابع لمنطقة الجمرك',
        '2026-06-02',
        N'منطقة الجمرك',
        N'قيام العامل/محمد احمد ابراهيم كود 9824 بسرقة عدد3 اغطيه سيفونات حديد تابع لمنطقة الجمرك',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'محمد احمد ابراهيم كود 9824',
        '2026-06-02 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: محمد احمد ابراهيم كود 9824
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE Code = N'9824';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمد احمد ابراهيم كود 9824';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمد احمد ابراهيم كود 9824%';
    IF @EmpMasterId IS NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM EmployeesMaster WHERE Code = N'9824')
            SET @NewCode = N'9824';
        ELSE
            SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمد احمد ابراهيم كود 9824', N'موظف', N'منطقة الجمرك', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-06-28', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض ر.م.أ 28/6/2026 | |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'139',
        '2026-06-11',
        '2026-06-11',
        N'أ',
        N'نورة عباس',
        N'مرور السائق/رمضان هلال السيد كود 9943 بالسيارة رقم 1741 يوم 20/5/2026 بدون الاجراءات على الوقود مما تسبب في عطل السيارة وتغريم الشركة 600 جنيه',
        '2026-05-20',
        N'ديوان عام الشركة',
        N'مرور السائق/رمضان هلال السيد كود 9943 بالسيارة رقم 1741 يوم 20/5/2026 بدون الاجراءات على الوقود مما تسبب في عطل السيارة وتغريم الشركة 600 جنيه',
        N'مغلقة',
        N'600 جنيه',
        N'إدارة الأمن والتفتيش',
        N'رمضان هلال السيد كود 9943',
        '2026-06-11 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: رمضان هلال السيد كود 9943
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE Code = N'9943';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'رمضان هلال السيد كود 9943';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%رمضان هلال السيد كود 9943%';
    IF @EmpMasterId IS NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM EmployeesMaster WHERE Code = N'9943')
            SET @NewCode = N'9943';
        ELSE
            SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'رمضان هلال السيد كود 9943', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-06-29', N'رئيس مجلس الإدارة', N'مجازاة بخصم من الراتب', N'يوم', N'عرض ر.م.أ 29/6/2026 | | مجازة كل من المذكورين بخصم يوم في راتبه وتحميله مبلغ 600 جنيه', GETDATE());
    INSERT INTO FinalDecisions (InvestigationId, FinalDecisionText, ActionType, HRSentDate, HRNotes, CreatedAt)
    VALUES (@InvId, N'مجازة كل من المذكورين بخصم يوم في راتبه وتحميله مبلغ 600 جنيه', 'hr', '2026-06-29', N'عرض ر.م.أ 29/6/2026 | | مجازة كل من المذكورين بخصم يوم في راتبه وتحميله مبلغ 600 جنيه', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'140',
        '2026-06-04',
        '2026-06-04',
        N'أ',
        N'ريهام شفيق',
        N'الشكاوى المقدمه من ك/جورجينا وهبي ناجي ضد الفني/على محمد عبدالمجيد بتطاول عليها بمكتبها',
        '2026-06-04',
        N'ديوان عام الشركة',
        N'الشكاوى المقدمه من ك/جورجينا وهبي ناجي ضد الفني/على محمد عبدالمجيد بتطاول عليها بمكتبها',
        N'مغلقة',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'الفني/على محمد عبدالمجيد بتطاول عليها بمكتبها',
        '2026-06-04 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: على محمد عبدالمجيد بتطاول عليها بمكتبها
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'على محمد عبدالمجيد بتطاول عليها بمكتبها';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%على محمد عبدالمجيد بتطاول عليها بمكتبها%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'على محمد عبدالمجيد بتطاول عليها بمكتبها', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-06-21', N'رئيس مجلس الإدارة', N'حفظ التحقيق', N'حفظ التحقيق', N'عرض ر.م.أ 21/6/2026 | ورد ر.م.أ 23/6/2026 | بحفظ التحقيق ضد السيد/علي محمد عبدالمجيد', GETDATE());
    INSERT INTO FinalDecisions (InvestigationId, FinalDecisionText, ActionType, HRSentDate, HRNotes, CreatedAt)
    VALUES (@InvId, N'بحفظ التحقيق ضد السيد/علي محمد عبدالمجيد', 'archive', '2026-06-21', N'عرض ر.م.أ 21/6/2026 | ورد ر.م.أ 23/6/2026 | بحفظ التحقيق ضد السيد/علي محمد عبدالمجيد', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'141',
        '2026-06-09',
        '2026-06-09',
        N'أ',
        N'ايناس جلال',
        N'الشكاوي المقدمه من ك/جورجينا وهبي ناجي ضد الفني/مصطفى عبدالمولى عبدالمجيد بتطاول عليها بمكتبها',
        '2026-06-09',
        N'ديوان عام الشركة',
        N'الشكاوي المقدمه من ك/جورجينا وهبي ناجي ضد الفني/مصطفى عبدالمولى عبدالمجيد بتطاول عليها بمكتبها',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'الفني/مصطفى عبدالمولى عبدالمجيد بتطاول عليها بمكتبها',
        '2026-06-09 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: مصطفى عبدالمولى عبدالمجيد بتطاول عليها بمكتبها
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'مصطفى عبدالمولى عبدالمجيد بتطاول عليها بمكتبها';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%مصطفى عبدالمولى عبدالمجيد بتطاول عليها بمكتبها%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'مصطفى عبدالمولى عبدالمجيد بتطاول عليها بمكتبها', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'142',
        '2026-06-02',
        '2026-06-02',
        N'أ',
        N'غادة شكرى',
        N'تعدي العامل/محمد السيد ايوب بالورديه الثانيه على مراقب الورديه السيد/محمد طارق عباس بالالفاظ غير لائقه',
        '2026-06-02',
        N'ديوان عام الشركة',
        N'تعدي العامل/محمد السيد ايوب بالورديه الثانيه على مراقب الورديه السيد/محمد طارق عباس بالالفاظ غير لائقه',
        N'مغلقة',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'محمد السيد ايوب بالورديه الثانيه',
        '2026-06-02 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: محمد السيد ايوب بالورديه الثانيه
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمد السيد ايوب بالورديه الثانيه';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمد السيد ايوب بالورديه الثانيه%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمد السيد ايوب بالورديه الثانيه', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-06-28', N'رئيس مجلس الإدارة', N'مجازاة بخصم من الراتب', N'يوم', N'عرض ر.م.أ 28/6/2026 | | مجازة السيد/محمد السيد ايوب بخصم يومين من راتبه', GETDATE());
    INSERT INTO FinalDecisions (InvestigationId, FinalDecisionText, ActionType, HRSentDate, HRNotes, CreatedAt)
    VALUES (@InvId, N'مجازة السيد/محمد السيد ايوب بخصم يومين من راتبه', 'hr', '2026-06-28', N'عرض ر.م.أ 28/6/2026 | | مجازة السيد/محمد السيد ايوب بخصم يومين من راتبه', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'143',
        '2026-06-09',
        '2026-06-09',
        N'أ',
        N'هدى رجب',
        N'قيام اعمال صيانه كهربائيه على طلمبه رفع رقم 6 تلاحظ عدم توجد مسئول السلامه والصحه المهنيه',
        '2026-06-09',
        N'ديوان عام الشركة',
        N'قيام اعمال صيانه كهربائيه على طلمبه رفع رقم 6 تلاحظ عدم توجد مسئول السلامه والصحه المهنيه',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'اعمال صيانه كهربائيه على طلمبه',
        '2026-06-09 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: اعمال صيانه كهربائيه على طلمبه
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'اعمال صيانه كهربائيه على طلمبه';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%اعمال صيانه كهربائيه على طلمبه%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'اعمال صيانه كهربائيه على طلمبه', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-06-09', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض | |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'144',
        '2026-06-02',
        '2026-06-02',
        N'أ',
        N'خالد احمد',
        N'قيام السيد/محمود بسيوني السعيد بالدرجه الرابعه بمنطقه منتزه اول بتزوير تقرير من مركز السموم الاسكندريه',
        '2026-06-02',
        N'بمنطقه منتزه اول بتزوير تقرير',
        N'قيام السيد/محمود بسيوني السعيد بالدرجه الرابعه بمنطقه منتزه اول بتزوير تقرير من مركز السموم الاسكندريه',
        N'جارية',
        NULL,
        N'مركز السموم الاسكندريه',
        N'محمود بسيوني السعيد بالدرجه الرابعه',
        '2026-06-02 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: محمود بسيوني السعيد بالدرجه الرابعه
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمود بسيوني السعيد بالدرجه الرابعه';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمود بسيوني السعيد بالدرجه الرابعه%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمود بسيوني السعيد بالدرجه الرابعه', N'موظف', N'بمنطقه منتزه اول بتزوير تقرير', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'145',
        '2026-06-08',
        '2026-06-08',
        N'أ',
        N'شعبان السيد',
        N'تلاحظ ان السيد/سفيان محمود محروس كود 10671 تلاعب في دفتر الحضور والانصراف انه تخلف عن حضور ثالث يوم العيد وقام بتسجيل نفسه وذلك يوم الجمعه الموافق 29/5/2026 وحيث اخطرنا بنوباتجيه عيد الاضحى ولم يحضر',
        '2026-05-29',
        N'ديوان عام الشركة',
        N'تلاحظ ان السيد/سفيان محمود محروس كود 10671 تلاعب في دفتر الحضور والانصراف انه تخلف عن حضور ثالث يوم العيد وقام بتسجيل نفسه وذلك يوم الجمعه الموافق 29/5/2026 وحيث اخطرنا بنوباتجيه عيد الاضحى ولم يحضر',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'موظف محال للتحقيق',
        '2026-06-08 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'146',
        '2026-06-22',
        '2026-06-22',
        N'أ',
        N'خالد احمد',
        N'بخصوص مرور على سيادتكم محطة المنتزه يوم 31/5/2026 وجد الفني/عبدالفتاح في محطة 1 نائما اثناء الورديه الليليه وتم تصويره',
        '2026-05-31',
        N'محطة المنتزه',
        N'بخصوص مرور على سيادتكم محطة المنتزه يوم 31/5/2026 وجد الفني/عبدالفتاح في محطة 1 نائما اثناء الورديه الليليه وتم تصويره',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'عبدالفتاح',
        '2026-06-22 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: عبدالفتاح
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'عبدالفتاح';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%عبدالفتاح%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'عبدالفتاح', N'موظف', N'محطة المنتزه', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'147',
        '2026-06-10',
        '2026-06-10',
        N'أ',
        N'صباح رمضان',
        N'نوم حارس الامن/ علي السيد هلال اثناء العمل بمحطة التنقيه الغربيه يوم 22/4/2026',
        '2026-04-22',
        N'بمحطة التنقيه الغربيه',
        N'نوم حارس الامن/ علي السيد هلال اثناء العمل بمحطة التنقيه الغربيه يوم 22/4/2026',
        N'مغلقة',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'علي السيد هلال',
        '2026-06-10 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: علي السيد هلال
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'علي السيد هلال';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%علي السيد هلال%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'علي السيد هلال', N'موظف', N'بمحطة التنقيه الغربيه', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-06-21', N'رئيس مجلس الإدارة', N'مجازاة بخصم من الراتب', N'خمس ايام من راتبه', N'عرض ر.م.أ 21/6/2026 | ورد ر.م.أ 28/6/2026 | بخصم خمس ايام من راتبه', GETDATE());
    INSERT INTO FinalDecisions (InvestigationId, FinalDecisionText, ActionType, HRSentDate, HRNotes, CreatedAt)
    VALUES (@InvId, N'بخصم خمس ايام من راتبه', 'hr', '2026-06-21', N'عرض ر.م.أ 21/6/2026 | ورد ر.م.أ 28/6/2026 | بخصم خمس ايام من راتبه', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'148',
        '2026-06-10',
        '2026-06-10',
        N'أ',
        N'حنان الخشاب',
        N'المرور على محطة 5 شرمله يوم 5/6/2026-مغلقه',
        '2026-06-05',
        N'محطة 5 شرمله',
        N'المرور على محطة 5 شرمله يوم 5/6/2026-مغلقه',
        N'جارية',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'مغلقه',
        '2026-06-10 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: مغلقه
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'مغلقه';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%مغلقه%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'مغلقه', N'موظف', N'محطة 5 شرمله', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'149',
        '2026-06-16',
        '2026-06-16',
        N'أ',
        N'طارق السيد',
        N'اكتشف وجود عجز في المخزن 1-جهاز قياس التصرفات مستعمل -2-كشافات 3 في 120 ليد 40 وات جديد عدد2',
        '2026-06-16',
        N'مخزن 1',
        N'اكتشف وجود عجز في المخزن 1-جهاز قياس التصرفات مستعمل -2-كشافات 3 في 120 ليد 40 وات جديد عدد2',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'موظف محال للتحقيق',
        '2026-06-16 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'مخزن 1', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'150',
        '2026-06-11',
        '2026-06-11',
        N'أ',
        N'غادة شكرى',
        N'قيام كلا من مراقبه المنشيه البحريه السيد/عصام جميل السائق/احمد نور السيد بالعمل بالسياره رقم 6495 يوم السبت 6/6/2026 والتربح من العمل بالسياره',
        '2026-06-06',
        N'ديوان عام الشركة',
        N'قيام كلا من مراقبه المنشيه البحريه السيد/عصام جميل السائق/احمد نور السيد بالعمل بالسياره رقم 6495 يوم السبت 6/6/2026 والتربح من العمل بالسياره',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'مراقبه المنشيه البحريه السيد',
        '2026-06-11 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: مراقبه المنشيه البحريه السيد
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE Code = N'6495';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'مراقبه المنشيه البحريه السيد';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%مراقبه المنشيه البحريه السيد%';
    IF @EmpMasterId IS NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM EmployeesMaster WHERE Code = N'6495')
            SET @NewCode = N'6495';
        ELSE
            SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'مراقبه المنشيه البحريه السيد', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-06-21', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض ر.م.أ 21/6/2026 | |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'151',
        '2026-06-10',
        '2026-06-10',
        N'أ',
        N'صباح رمضان',
        N'الشكاوي المقدمه من المهندسه/صباح عباس-مدير عام الطاقه الكهربائيه ضد السيد/وليد محمد عبدالله-كود7921 بتطاول عليه بالغاز غير مقبوله والخروج بدون اذن',
        '2026-06-10',
        N'ديوان عام الشركة',
        N'الشكاوي المقدمه من المهندسه/صباح عباس-مدير عام الطاقه الكهربائيه ضد السيد/وليد محمد عبدالله-كود7921 بتطاول عليه بالغاز غير مقبوله والخروج بدون اذن',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'السيد/وليد محمد عبداللهكود7921 بتطاول عليه بالغاز غير مقبوله والخروج بدون اذن',
        '2026-06-10 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: وليد محمد عبدالله-كود7921 بتطاول عليه بالغاز غير مقبوله والخروج بدون اذن
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE Code = N'7921';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'وليد محمد عبدالله-كود7921 بتطاول عليه بالغاز غير مقبوله والخروج بدون اذن';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%وليد محمد عبدالله-كود7921 بتطاول عليه بالغاز غير مقبوله والخروج بدون اذن%';
    IF @EmpMasterId IS NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM EmployeesMaster WHERE Code = N'7921')
            SET @NewCode = N'7921';
        ELSE
            SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'وليد محمد عبدالله-كود7921 بتطاول عليه بالغاز غير مقبوله والخروج بدون اذن', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'152',
        '2026-06-14',
        '2026-06-14',
        N'أ',
        N'غاده شكري',
        N'قيام السيده/ندى احمد محمد كود 10095 بالتطاول علي مسئول الامن بصوت عالي',
        '2026-06-14',
        N'ديوان عام الشركة',
        N'قيام السيده/ندى احمد محمد كود 10095 بالتطاول علي مسئول الامن بصوت عالي',
        N'مغلقة',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'موظف محال للتحقيق',
        '2026-06-14 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-06-28', N'رئيس مجلس الإدارة', N'حفظ التحقيق', N'يوم من راتبه', N'عرض ر.م.أ 28/6/2026 | ورد ر.م.أ 2/7/2026 | مجازه بخصم يوم من راتبه وحفظ واقعه حضورها لعمل', GETDATE());
    INSERT INTO FinalDecisions (InvestigationId, FinalDecisionText, ActionType, HRSentDate, HRNotes, CreatedAt)
    VALUES (@InvId, N'مجازه بخصم يوم من راتبه وحفظ واقعه حضورها لعمل', 'archive', '2026-06-28', N'عرض ر.م.أ 28/6/2026 | ورد ر.م.أ 2/7/2026 | مجازه بخصم يوم من راتبه وحفظ واقعه حضورها لعمل', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'153',
        '2026-06-08',
        NULL,
        N'أ',
        N'غاده شكري',
        N'تحقيق مع مدير محطة معالجة خورشيد القديمه والجديده يوم الاثنين 8/6/2026 تبين ان عدد افراد محطة خورشيد الجديده 8 افراد اثناء مرور الامن تلاحظ عدد فردين فقط هذا التحقيق مع مدير محطة لعدم تواجد العدد الكافي في محطة معالجة خورشيد القديمه والجديده كما ي...',
        '2026-06-08',
        N'محطة معالجة خورشيد القديمه والجديده',
        N'تحقيق مع مدير محطة معالجة خورشيد القديمه والجديده يوم الاثنين 8/6/2026 تبين ان عدد افراد محطة خورشيد الجديده 8 افراد اثناء مرور الامن تلاحظ عدد فردين فقط هذا التحقيق مع مدير محطة لعدم تواجد العدد الكافي في محطة معالجة خورشيد القديمه والجديده كما يعرض المحطة لمخاطر السرقه او الغرف او الاتلاف حيث يتواجد بالمحطتان عدد 4 عمال من اصل عدد14 عامل',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'موظف محال للتحقيق',
        '2026-06-08 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'محطة معالجة خورشيد القديمه والجديده', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'154',
        '2026-06-04',
        NULL,
        N'أ',
        N'غاده شكري ايمن توفيق',
        N'مرور الامن على محطة طلعت مصطفى العجمي يوم الخميس 4/6/2026 ساعه 2 ص عدم تواجد احمد من العاملين الحمله او الصيانه او مدير مناوب منطقة الورديه بمراجعه سجل سيارات تلاحظ خروج عدد 1 سياره فقط وهي سياره نافوري رقم 9661 تم البحث في سجل حضور والانصراف ان س...',
        '2026-06-04',
        N'محطة طلعت مصطفى العجمي',
        N'مرور الامن على محطة طلعت مصطفى العجمي يوم الخميس 4/6/2026 ساعه 2 ص عدم تواجد احمد من العاملين الحمله او الصيانه او مدير مناوب منطقة الورديه بمراجعه سجل سيارات تلاحظ خروج عدد 1 سياره فقط وهي سياره نافوري رقم 9661 تم البحث في سجل حضور والانصراف ان سجل مغلق عليه ولذلك لم يتم اثبات حضور بالسجل',
        N'جارية',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'ين الحمله او الصيانه او',
        '2026-06-04 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: ين الحمله او الصيانه او
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE Code = N'9661';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'ين الحمله او الصيانه او';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%ين الحمله او الصيانه او%';
    IF @EmpMasterId IS NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM EmployeesMaster WHERE Code = N'9661')
            SET @NewCode = N'9661';
        ELSE
            SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'ين الحمله او الصيانه او', N'موظف', N'محطة طلعت مصطفى العجمي', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'155',
        '2026-06-21',
        '2026-06-21',
        N'أ',
        N'ياسر الشربيني',
        N'عدم وجود مستند لعمليه صندوق تروس التوربينه بمحطة معالجه العامريه الالماني بمبلغ 46000 جنيه دون اي مستندات',
        '2026-06-21',
        N'بمحطة معالجه العامريه الالماني بمبلغ 46000',
        N'عدم وجود مستند لعمليه صندوق تروس التوربينه بمحطة معالجه العامريه الالماني بمبلغ 46000 جنيه دون اي مستندات',
        N'جارية',
        N'46000 جنيه',
        N'شركة الصرف الصحي بالإسكندرية',
        N'موظف محال للتحقيق',
        '2026-06-21 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'بمحطة معالجه العامريه الالماني بمبلغ 46000', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'156',
        '2026-06-16',
        '2026-06-16',
        N'أ',
        N'ايناس جلال',
        N'مرور الامن يوم 8/6/2026 على محطتي معالجه خورشيد القديمه والجديده تلاحظ عدم تواجد العدد الكافي من العاملين',
        '2026-06-08',
        N'ديوان عام الشركة',
        N'مرور الامن يوم 8/6/2026 على محطتي معالجه خورشيد القديمه والجديده تلاحظ عدم تواجد العدد الكافي من العاملين',
        N'جارية',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'موظف محال للتحقيق',
        '2026-06-16 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'157',
        '2026-06-16',
        '2026-06-16',
        N'أ',
        N'مروة حمزة',
        N'وجود طفح في شارع مسجد المليار بالعجمي نتيجه عدم متابعه تشغيل محطة 5 العجمي',
        '2026-06-16',
        N'محطة 5 العجمي',
        N'وجود طفح في شارع مسجد المليار بالعجمي نتيجه عدم متابعه تشغيل محطة 5 العجمي',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'موظف محال للتحقيق',
        '2026-06-16 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'محطة 5 العجمي', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'158',
        '2026-06-28',
        '2026-06-28',
        N'أ',
        N'وفاء رمزى',
        N'قيام كلا من : السائق/اشرف سلام تمام كود7104 , السائق/محمود احمد محمد عبدالله كود10327 , العامل/ماهر جلال مصطفى كود9194 باستخدام السياره مدمجه رقم 1226 اعمال خاصه',
        '2026-06-28',
        N'ديوان عام الشركة',
        N'قيام كلا من : السائق/اشرف سلام تمام كود7104 , السائق/محمود احمد محمد عبدالله كود10327 , العامل/ماهر جلال مصطفى كود9194 باستخدام السياره مدمجه رقم 1226 اعمال خاصه',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'السائق',
        '2026-06-28 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: : السائق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE Code = N'7104';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N': السائق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%: السائق%';
    IF @EmpMasterId IS NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM EmployeesMaster WHERE Code = N'7104')
            SET @NewCode = N'7104';
        ELSE
            SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N': السائق', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'159',
        '2026-06-23',
        '2026-06-23',
        N'أ',
        N'شعبان السيد',
        N'قيام رئيس محطة رفع الطاروطي منتزه ثان بالتزوير والتلاعب بسجل الحضور والانصراف',
        '2026-06-23',
        N'محطة رفع الطاروطي منتزه ثان بالتزوير',
        N'قيام رئيس محطة رفع الطاروطي منتزه ثان بالتزوير والتلاعب بسجل الحضور والانصراف',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'رئيس محطة رفع الطاروطي منتزه',
        '2026-06-23 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: رئيس محطة رفع الطاروطي منتزه
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'رئيس محطة رفع الطاروطي منتزه';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%رئيس محطة رفع الطاروطي منتزه%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'رئيس محطة رفع الطاروطي منتزه', N'موظف', N'محطة رفع الطاروطي منتزه ثان بالتزوير', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'160',
        '2026-06-24',
        '2026-06-24',
        N'أ',
        N'ايمن توفيق',
        N'سرقة كابل نحاس بأحدى الطلمبات بمحطة الملك بمنطقه المنتزه ثان قد اسفرت التحريات 1-من خارج الخدمه منذ اكثر من ست سنوات 2-طول يقارب 7 امتار 3-تم اكتشاف واقعه السرقه بتاريخ 12/6/2026الموافق يوم الجمعه احالت رئيس محطة محمد محمد بسيوني لم يقوم بابلاغ 4-...',
        '2026-06-12',
        N'بمحطة الملك بمنطقه المنتزه ثان قد',
        N'سرقة كابل نحاس بأحدى الطلمبات بمحطة الملك بمنطقه المنتزه ثان قد اسفرت التحريات 1-من خارج الخدمه منذ اكثر من ست سنوات 2-طول يقارب 7 امتار 3-تم اكتشاف واقعه السرقه بتاريخ 12/6/2026الموافق يوم الجمعه احالت رئيس محطة محمد محمد بسيوني لم يقوم بابلاغ 4-تم ابلاغ مدير عام منطقه بواقعه سرقه الكابل يوم الثلاثاء 16/6/2026',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'من خارج الخدمه منذ اكثر من ست سنوات, تم اكتشاف واقعه السرقه, تم ابلاغ مدير عام منطقه بواقعه سرقه الكابل',
        '2026-06-24 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: من خارج الخدمه منذ اكثر من ست سنوات
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'من خارج الخدمه منذ اكثر من ست سنوات';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%من خارج الخدمه منذ اكثر من ست سنوات%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'من خارج الخدمه منذ اكثر من ست سنوات', N'موظف', N'بمحطة الملك بمنطقه المنتزه ثان قد', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: تم اكتشاف واقعه السرقه
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'تم اكتشاف واقعه السرقه';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%تم اكتشاف واقعه السرقه%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'تم اكتشاف واقعه السرقه', N'موظف', N'بمحطة الملك بمنطقه المنتزه ثان قد', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: تم ابلاغ مدير عام منطقه بواقعه سرقه الكابل
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'تم ابلاغ مدير عام منطقه بواقعه سرقه الكابل';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%تم ابلاغ مدير عام منطقه بواقعه سرقه الكابل%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'تم ابلاغ مدير عام منطقه بواقعه سرقه الكابل', N'موظف', N'بمحطة الملك بمنطقه المنتزه ثان قد', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'161',
        '2026-06-24',
        '2026-06-24',
        N'أ',
        N'حنان الخشاب',
        N'بالتوجه السيد/كريم حسني الى اسواق فتح الله لصرف البون الذي تم توزيع عن طريق الشركة للعاملين الا انه وجد الكارت فارغ',
        '2026-06-24',
        N'ديوان عام الشركة',
        N'بالتوجه السيد/كريم حسني الى اسواق فتح الله لصرف البون الذي تم توزيع عن طريق الشركة للعاملين الا انه وجد الكارت فارغ',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'موظف محال للتحقيق',
        '2026-06-24 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'162',
        '2026-06-28',
        '2026-06-28',
        N'أ',
        N'ايناس جلال',
        N'بأن العامل/رمضان علي واصل متغيب عن العمل يوم الاحد 14/6/2026 حتى تاريخه في ظل هذه الظروف مخازن الرئيسيه',
        '2026-06-14',
        N'مخازن الرئيسيه',
        N'بأن العامل/رمضان علي واصل متغيب عن العمل يوم الاحد 14/6/2026 حتى تاريخه في ظل هذه الظروف مخازن الرئيسيه',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'رمضان علي واصل متغيب',
        '2026-06-28 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: رمضان علي واصل متغيب
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'رمضان علي واصل متغيب';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%رمضان علي واصل متغيب%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'رمضان علي واصل متغيب', N'موظف', N'مخازن الرئيسيه', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'163',
        '2026-06-28',
        '2026-06-28',
        N'أ',
        N'طارق السيد',
        N'مرور على محطة رفع السنان يوم 21/6/2026 توجد عدد 11منتج لتسليك جديد+34 سيخ لسليك الاخر قديم كهنه وسؤال المشرف عن مراقبه السنان قال نصار بشري جديد من حسابنا الخاص لان الشركة لا توفر العدد الكافي في سياخ التسليلك',
        '2026-06-21',
        N'محطة رفع السنان',
        N'مرور على محطة رفع السنان يوم 21/6/2026 توجد عدد 11منتج لتسليك جديد+34 سيخ لسليك الاخر قديم كهنه وسؤال المشرف عن مراقبه السنان قال نصار بشري جديد من حسابنا الخاص لان الشركة لا توفر العدد الكافي في سياخ التسليلك',
        N'جارية',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'موظف محال للتحقيق',
        '2026-06-28 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'محطة رفع السنان', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'164',
        '2026-06-28',
        '2026-06-28',
        N'أ',
        N'وفاء رمزى',
        N'مرور الادارة العامة للاحتياجات ومتابعه المخزون يوم 21/6/2026 بمعرفة مفتش الادارة وقد اسفر المرور 1-محمود السيد محمد 2-ياسر محمد 3-تامر مصطفى محمد 4-عمرو محمد السيد 5-محمود عبدالفتاح عبدالله وباقي العاملين بالادارة الاشراف على لجان الجرد السنوي لجا...',
        '2026-06-21',
        N'ادارة العامة للاحتياجات ومتابعه المخزون',
        N'مرور الادارة العامة للاحتياجات ومتابعه المخزون يوم 21/6/2026 بمعرفة مفتش الادارة وقد اسفر المرور 1-محمود السيد محمد 2-ياسر محمد 3-تامر مصطفى محمد 4-عمرو محمد السيد 5-محمود عبدالفتاح عبدالله وباقي العاملين بالادارة الاشراف على لجان الجرد السنوي لجان مخزون-لجان الاصوال الثانيه',
        N'جارية',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'ين بالادارة الاشراف على لجان',
        '2026-06-28 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: محمود السيد محمد
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمود السيد محمد';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمود السيد محمد%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمود السيد محمد', N'موظف', N'ادارة العامة للاحتياجات ومتابعه المخزون', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: ياسر محمد
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'ياسر محمد';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%ياسر محمد%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'ياسر محمد', N'موظف', N'ادارة العامة للاحتياجات ومتابعه المخزون', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: تامر مصطفى محمد
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'تامر مصطفى محمد';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%تامر مصطفى محمد%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'تامر مصطفى محمد', N'موظف', N'ادارة العامة للاحتياجات ومتابعه المخزون', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: عمرو محمد السيد
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'عمرو محمد السيد';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%عمرو محمد السيد%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'عمرو محمد السيد', N'موظف', N'ادارة العامة للاحتياجات ومتابعه المخزون', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'165',
        '2026-06-28',
        '2026-06-28',
        N'أ',
        N'ريهام شفيق',
        N'بخصوص بأن السيدة ومدير عام الحدائق والشجر قامت بتعند بغرض ايذائي مقدمة لسيادتكم م/احمد عبدالفتاح عيد',
        '2026-06-28',
        N'ديوان عام الشركة',
        N'بخصوص بأن السيدة ومدير عام الحدائق والشجر قامت بتعند بغرض ايذائي مقدمة لسيادتكم م/احمد عبدالفتاح عيد',
        N'مغلقة',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'موظف محال للتحقيق',
        '2026-06-28 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-07-05', N'رئيس مجلس الإدارة', N'توصية بالنقل', N'توصية بالنقل', N'عرض ر.م.أ 5/7/2026 | | بالتوصيه بنقل م/احمد عبدالفتاح عيد في الحدائق والتشجير', GETDATE());
    INSERT INTO FinalDecisions (InvestigationId, FinalDecisionText, ActionType, HRSentDate, HRNotes, CreatedAt)
    VALUES (@InvId, N'بالتوصيه بنقل م/احمد عبدالفتاح عيد في الحدائق والتشجير', 'hr', '2026-07-05', N'عرض ر.م.أ 5/7/2026 | | بالتوصيه بنقل م/احمد عبدالفتاح عيد في الحدائق والتشجير', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'166',
        '2026-06-15',
        NULL,
        N'أ',
        N'خالد احمد',
        N'لحدوث يوم 15/6/2026 مع سائق/رمضان عبدالمنعم رمضان مشاده كلاميه بين مراقب الصيانه وافراد مرور بسبب طبيعة العمل الجاريه بموقع',
        '2026-06-15',
        N'ديوان عام الشركة',
        N'لحدوث يوم 15/6/2026 مع سائق/رمضان عبدالمنعم رمضان مشاده كلاميه بين مراقب الصيانه وافراد مرور بسبب طبيعة العمل الجاريه بموقع',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'موظف محال للتحقيق',
        '2026-06-15 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'167',
        '2026-06-30',
        '2026-06-30',
        N'أ',
        N'مروة حمزة',
        N'تلعب في سجلات الحضور والانصراف العامل/وليد حامد عبده يومي19,22/6/2026',
        '2026-06-22',
        N'ديوان عام الشركة',
        N'تلعب في سجلات الحضور والانصراف العامل/وليد حامد عبده يومي19,22/6/2026',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'وليد حامد عبده',
        '2026-06-30 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: وليد حامد عبده
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'وليد حامد عبده';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%وليد حامد عبده%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'وليد حامد عبده', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'168',
        '2026-06-30',
        '2026-06-30',
        N'أ',
        N'هدى رجب',
        N'دوث مشاجرة بين السائق/رمضان السيد والعامل/احمد محمد نور يوم 22/6/2026 بشارع 45 حيث نتج عن ذلك كسر بذراع السائق واصابات متعددة العامل وذلك امام الاستاذ/ عبدالفتاح المغربي ومهندس/محمد سعد عبدالرازق مسئول السلامه ومراقب الورديه السيد/عصام رحال',
        '2026-06-22',
        N'ديوان عام الشركة',
        N'دوث مشاجرة بين السائق/رمضان السيد والعامل/احمد محمد نور يوم 22/6/2026 بشارع 45 حيث نتج عن ذلك كسر بذراع السائق واصابات متعددة العامل وذلك امام الاستاذ/ عبدالفتاح المغربي ومهندس/محمد سعد عبدالرازق مسئول السلامه ومراقب الورديه السيد/عصام رحال',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'رمضان السيد والعامل',
        '2026-06-30 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: رمضان السيد والعامل
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'رمضان السيد والعامل';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%رمضان السيد والعامل%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'رمضان السيد والعامل', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'169',
        '2026-06-30',
        '2026-06-30',
        N'أ',
        N'هاني احمد',
        N'بخصوص الاهمال وعدم تطهير عدة مناطق(عجمي-شرق-جمرك-العامريه-المنتزه ثان) يوم 20/6/2026',
        '2026-06-20',
        N'ديوان عام الشركة',
        N'بخصوص الاهمال وعدم تطهير عدة مناطق(عجمي-شرق-جمرك-العامريه-المنتزه ثان) يوم 20/6/2026',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'موظف محال للتحقيق',
        '2026-06-30 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'170',
        '2026-06-30',
        '2026-06-30',
        N'أ',
        N'شعبان السيد',
        N'بخصوص فني السيد/رأفت محمدي علي قد قام بمسح جميع الملفات والرسومات الخاصه بادراة التصميم من على جهاز الكمبيوتر الذي بعهدته مما اضر باعمال الادارة',
        '2026-06-30',
        N'ديوان عام الشركة',
        N'بخصوص فني السيد/رأفت محمدي علي قد قام بمسح جميع الملفات والرسومات الخاصه بادراة التصميم من على جهاز الكمبيوتر الذي بعهدته مما اضر باعمال الادارة',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'موظف محال للتحقيق',
        '2026-06-30 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-06-30', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض | |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'171',
        '2026-06-30',
        '2026-06-30',
        N'أ',
        N'نرمين قنديل',
        N'بخصوص مرور الامن على محطة معالجة قرية بنجر السكر يوم الاربعاء 24/6/2026 الساعه 5 مساء تلاحظ لا يوجد احد بمحطة مغلقه بواسطه ترباس غياب كلا من:اسلام ربيع عبدالعزيز , علاء عبدالسلام اسماعيل',
        '2026-06-24',
        N'محطة معالجة قرية بنجر السكر',
        N'بخصوص مرور الامن على محطة معالجة قرية بنجر السكر يوم الاربعاء 24/6/2026 الساعه 5 مساء تلاحظ لا يوجد احد بمحطة مغلقه بواسطه ترباس غياب كلا من:اسلام ربيع عبدالعزيز , علاء عبدالسلام اسماعيل',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'اسلام ربيع عبدالعزيز',
        '2026-06-30 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: :اسلام ربيع عبدالعزيز
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N':اسلام ربيع عبدالعزيز';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%:اسلام ربيع عبدالعزيز%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N':اسلام ربيع عبدالعزيز', N'موظف', N'محطة معالجة قرية بنجر السكر', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'172',
        '2026-07-05',
        '2026-07-05',
        N'أ',
        N'حنان الخشاب',
        N'عدم حضور كلا من : 1-محمد مجدي عبدالله علي-يعمل بمنطقة العجمي من الفتره 4/4/2026 حتى 9/4/2026 2-السيد حسن احمد حسن يعمل بمنطقة العجمي من الفتره 25/4/2026 حتى 30/4/2026 برنامج الالغالء بمركز تدريب الدفاع المدني بتكلفة 50 جنيه للفرد',
        '2026-04-04',
        N'بمنطقة العجمي من الفتره 4',
        N'عدم حضور كلا من : 1-محمد مجدي عبدالله علي-يعمل بمنطقة العجمي من الفتره 4/4/2026 حتى 9/4/2026 2-السيد حسن احمد حسن يعمل بمنطقة العجمي من الفتره 25/4/2026 حتى 30/4/2026 برنامج الالغالء بمركز تدريب الدفاع المدني بتكلفة 50 جنيه للفرد',
        N'جارية',
        N'50 جنيه',
        N'شركة الصرف الصحي بالإسكندرية',
        N'موظف محال للتحقيق',
        '2026-07-05 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'بمنطقة العجمي من الفتره 4', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'173',
        '2026-07-05',
        '2026-07-05',
        N'أ',
        N'غاده شكري',
        N'طلب النقل المقدم من م/عبدالله سامر , والفني/وحيد بشري عبيد من العمل بحضانة البتروكيماويات',
        '2026-07-05',
        N'ديوان عام الشركة',
        N'طلب النقل المقدم من م/عبدالله سامر , والفني/وحيد بشري عبيد من العمل بحضانة البتروكيماويات',
        N'مغلقة',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'وحيد بشري عبيد من ال',
        '2026-07-05 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: وحيد بشري عبيد من ال
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'وحيد بشري عبيد من ال';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%وحيد بشري عبيد من ال%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'وحيد بشري عبيد من ال', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-07-06', N'رئيس مجلس الإدارة', N'مجازاة بخصم من الراتب', N'1', N'عرض ر.م.أ 6/7/2026 | | مجازاة كلا من :1-م/عبدالله سامر محمد بالانذار 2-السيد/وحيد بشري عبيد بالانذار , نزولا بالجزاء والشديد في حالة العود كلاهم والعرض على مجلس الادارة لكونه صاحب الاختصاص حتى توقيع الجزاء لكونه في شاغلي درجه كبيره', GETDATE());
    INSERT INTO FinalDecisions (InvestigationId, FinalDecisionText, ActionType, HRSentDate, HRNotes, CreatedAt)
    VALUES (@InvId, N'مجازاة كلا من :1-م/عبدالله سامر محمد بالانذار  2-السيد/وحيد بشري عبيد بالانذار , نزولا بالجزاء والشديد في حالة العود كلاهم والعرض على مجلس الادارة لكونه صاحب الاختصاص حتى توقيع الجزاء لكونه في شاغلي درجه كبيره', 'hr', '2026-07-06', N'عرض ر.م.أ 6/7/2026 | | مجازاة كلا من :1-م/عبدالله سامر محمد بالانذار 2-السيد/وحيد بشري عبيد بالانذار , نزولا بالجزاء والشديد في حالة العود كلاهم والعرض على مجلس الادارة لكونه صاحب الاختصاص حتى توقيع الجزاء لكونه في شاغلي درجه كبيره', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'174',
        '2026-07-08',
        '2026-07-08',
        N'أ',
        N'ايناس جلال',
        N'بخصوص السائق/محمد خميس عبدالفتاح يوم 12/6/2026 تم عمل اذن تشغيل للسياره رقم 5899 س ف ج للعمل مع اعادة الصيانه قرنيه وعند عوده السائق افاد يفقد اذن تشغيل',
        '2026-06-12',
        N'ديوان عام الشركة',
        N'بخصوص السائق/محمد خميس عبدالفتاح يوم 12/6/2026 تم عمل اذن تشغيل للسياره رقم 5899 س ف ج للعمل مع اعادة الصيانه قرنيه وعند عوده السائق افاد يفقد اذن تشغيل',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'محمد خميس عبدالفتاح',
        '2026-07-08 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: محمد خميس عبدالفتاح
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE Code = N'5899';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمد خميس عبدالفتاح';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمد خميس عبدالفتاح%';
    IF @EmpMasterId IS NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM EmployeesMaster WHERE Code = N'5899')
            SET @NewCode = N'5899';
        ELSE
            SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمد خميس عبدالفتاح', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'175',
        '2026-07-07',
        '2026-07-07',
        N'أ',
        N'وفاء رمزى',
        N'بخصوص التأخير في صدور نتائج الغياب الخاصه بادراة العينات السائله الرقابيه الوارد بتاريخ 16/6/2026 , المسئول/كيميائي-محمود السيد عثمان او ماينوب عنه/كيميائي علي محمد السيد',
        '2026-06-16',
        N'ديوان عام الشركة',
        N'بخصوص التأخير في صدور نتائج الغياب الخاصه بادراة العينات السائله الرقابيه الوارد بتاريخ 16/6/2026 , المسئول/كيميائي-محمود السيد عثمان او ماينوب عنه/كيميائي علي محمد السيد',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'الخاصه بادراة العينات السائله الرقابيه',
        '2026-07-07 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: الخاصه بادراة العينات السائله الرقابيه
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'الخاصه بادراة العينات السائله الرقابيه';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%الخاصه بادراة العينات السائله الرقابيه%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'الخاصه بادراة العينات السائله الرقابيه', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'176',
        '2026-07-08',
        '2026-07-08',
        N'أ',
        N'هاني احمد',
        N'مرور المكتب الفني على محطة منشيه الاوقاف يوم 29/6/2026 الساعه 4 عصرا تلاحظ ان المحطه مغلقه , محكة الكومبائيه مغلقه يوم 25/6/2026 الساعه 4:30 عصرا',
        '2026-06-29',
        N'محطة منشيه الاوقاف',
        N'مرور المكتب الفني على محطة منشيه الاوقاف يوم 29/6/2026 الساعه 4 عصرا تلاحظ ان المحطه مغلقه , محكة الكومبائيه مغلقه يوم 25/6/2026 الساعه 4:30 عصرا',
        N'جارية',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'على محطة منشيه الاوقاف',
        '2026-07-08 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: على محطة منشيه الاوقاف
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'على محطة منشيه الاوقاف';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%على محطة منشيه الاوقاف%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'على محطة منشيه الاوقاف', N'موظف', N'محطة منشيه الاوقاف', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'177',
        '2026-07-09',
        '2026-07-09',
        N'أ',
        N'ريهام شفيق',
        N'تحدث السيد/عادل جمال الدين كود 816 بأسلوب غير لائق مع بعض الالفاظ مع المهندس/احمد عبدالفتاح احمد',
        '2026-07-09',
        N'ديوان عام الشركة',
        N'تحدث السيد/عادل جمال الدين كود 816 بأسلوب غير لائق مع بعض الالفاظ مع المهندس/احمد عبدالفتاح احمد',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'موظف محال للتحقيق',
        '2026-07-09 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'178',
        '2026-01-01',
        NULL,
        N'أ',
        N'حنان الخشاب',
        N'تصدم السياره نقل الثنبل على طريف بشربرعه عاليا جدا على طريف كارفور حتى التنقيه الشرقيه مما ادى الحاق بالضرر بكاوتش السيارات المحيطه , السائق/محمد سمير حسن',
        '2026-01-01',
        N'ديوان عام الشركة',
        N'تصدم السياره نقل الثنبل على طريف بشربرعه عاليا جدا على طريف كارفور حتى التنقيه الشرقيه مما ادى الحاق بالضرر بكاوتش السيارات المحيطه , السائق/محمد سمير حسن',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'محمد سمير حسن',
        '2026-01-01 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: محمد سمير حسن
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمد سمير حسن';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمد سمير حسن%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمد سمير حسن', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'179',
        '2026-07-09',
        '2026-07-09',
        N'أ',
        N'ريهام شفيق',
        N'بخصوص مرور الامن على محطة التنقيه الشرقيه تلاحظ نوم كلا من اثناء العمل :1-رزق محمد رزق 2-عبدالسلام عوض 3-ايمن محمد حسني يوم 5/7/2026',
        '2026-07-05',
        N'محطة التنقيه الشرقيه',
        N'بخصوص مرور الامن على محطة التنقيه الشرقيه تلاحظ نوم كلا من اثناء العمل :1-رزق محمد رزق 2-عبدالسلام عوض 3-ايمن محمد حسني يوم 5/7/2026',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'رزق محمد رزق, عبدالسلام عوض, ايمن محمد حسني',
        '2026-07-09 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: رزق محمد رزق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'رزق محمد رزق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%رزق محمد رزق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'رزق محمد رزق', N'موظف', N'محطة التنقيه الشرقيه', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: عبدالسلام عوض
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'عبدالسلام عوض';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%عبدالسلام عوض%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'عبدالسلام عوض', N'موظف', N'محطة التنقيه الشرقيه', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: ايمن محمد حسني
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'ايمن محمد حسني';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%ايمن محمد حسني%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'ايمن محمد حسني', N'موظف', N'محطة التنقيه الشرقيه', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'180',
        '2026-07-02',
        NULL,
        N'أ',
        N'خالد احمد',
        N'بخصوص القبض على العامل محمود علي سالم يوم الخميس 2/7/2026 الذي يعمل بمحطة باب 18 منطقه الجمرك وتحقيق مع رئيس محطة/ يحيى الدندراوي لذلك عمل بدل راحة واجازة اعتيادي للعامل المذكور على الرغم من علمه بالقبض عليه باحدى الجهات الامنيه',
        '2026-07-02',
        N'بمحطة باب 18 منطقه الجمرك وتحقيق',
        N'بخصوص القبض على العامل محمود علي سالم يوم الخميس 2/7/2026 الذي يعمل بمحطة باب 18 منطقه الجمرك وتحقيق مع رئيس محطة/ يحيى الدندراوي لذلك عمل بدل راحة واجازة اعتيادي للعامل المذكور على الرغم من علمه بالقبض عليه باحدى الجهات الامنيه',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'محمود علي سالم',
        '2026-07-02 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: محمود علي سالم
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمود علي سالم';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمود علي سالم%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمود علي سالم', N'موظف', N'بمحطة باب 18 منطقه الجمرك وتحقيق', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'181',
        '2026-01-01',
        NULL,
        N'أ',
        N'خالد احمد',
        N'بخصوص اثناء العمل بمحطة ابراهيم صالح الوردية الثانية تلاحظ ان السيد/على عمر ابراهيم وقيام العامل/ ابراهيم عاشور رجب بيتعاطو مادة الايس المخدرة تلاحظ وجود علبة فيها عدد اتنين سرنجة ومادة الايس',
        '2026-01-01',
        N'بمحطة ابراهيم صالح الوردية الثانية',
        N'بخصوص اثناء العمل بمحطة ابراهيم صالح الوردية الثانية تلاحظ ان السيد/على عمر ابراهيم وقيام العامل/ ابراهيم عاشور رجب بيتعاطو مادة الايس المخدرة تلاحظ وجود علبة فيها عدد اتنين سرنجة ومادة الايس',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'ابراهيم عاشور رجب بيتعاطو مادة',
        '2026-01-01 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: ابراهيم عاشور رجب بيتعاطو مادة
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'ابراهيم عاشور رجب بيتعاطو مادة';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%ابراهيم عاشور رجب بيتعاطو مادة%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'ابراهيم عاشور رجب بيتعاطو مادة', N'موظف', N'بمحطة ابراهيم صالح الوردية الثانية', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'182',
        '2026-01-01',
        NULL,
        N'أ',
        N'ايناس جلال',
        N'قيام السيد/احمد ممدوح بالاسائة للسائق احمد جابر الازرق وكان يامرة بالخروج معه الى مامورية وتكلم معة بصوت عالى',
        '2026-01-01',
        N'ديوان عام الشركة',
        N'قيام السيد/احمد ممدوح بالاسائة للسائق احمد جابر الازرق وكان يامرة بالخروج معه الى مامورية وتكلم معة بصوت عالى',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'احمد ممدوح بالاسائة للسائق احمد',
        '2026-01-01 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: احمد ممدوح بالاسائة للسائق احمد
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'احمد ممدوح بالاسائة للسائق احمد';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%احمد ممدوح بالاسائة للسائق احمد%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'احمد ممدوح بالاسائة للسائق احمد', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'183',
        '2026-07-07',
        NULL,
        N'أ',
        N'صباح رمضان',
        N'قبام العامل كريم سمير عبد النبى يوم 7/7/2026 بالتطاول برسالة على السيدة اميرة يحيى مدير العلاج الطبى',
        '2026-07-07',
        N'ديوان عام الشركة',
        N'قبام العامل كريم سمير عبد النبى يوم 7/7/2026 بالتطاول برسالة على السيدة اميرة يحيى مدير العلاج الطبى',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'كريم سمير عبد النبى',
        '2026-07-07 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: كريم سمير عبد النبى
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'كريم سمير عبد النبى';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%كريم سمير عبد النبى%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'كريم سمير عبد النبى', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'184',
        '2026-01-01',
        NULL,
        N'أ',
        N'مروة حمزة',
        N'قيام العامل احمد رمزى احمد يعمل بمحطة الشمعدان بالوردية الاولى بسبب الدين لرئيس المحطة السيد/ حمدى وقيام المذكور بالتلاعب فى سجل الحضور والانصراف',
        '2026-01-01',
        N'بمحطة الشمعدان بالوردية الاولى بسبب الدين',
        N'قيام العامل احمد رمزى احمد يعمل بمحطة الشمعدان بالوردية الاولى بسبب الدين لرئيس المحطة السيد/ حمدى وقيام المذكور بالتلاعب فى سجل الحضور والانصراف',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'العامل احمد رمزى احمد ي',
        '2026-01-01 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: احمد رمزى احمد ي
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'احمد رمزى احمد ي';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%احمد رمزى احمد ي%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'احمد رمزى احمد ي', N'موظف', N'بمحطة الشمعدان بالوردية الاولى بسبب الدين', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'185',
        '2026-06-09',
        NULL,
        N'أ',
        N'نرمين قنديل',
        N'قيام السيد/محمد على محمد بمخالفة التوقيع بسجل الحضور بعدم الشطب على غياب يوم 9/6/2026 السيد/محمد الاشقر للتوقيع بالسجل',
        '2026-06-09',
        N'ديوان عام الشركة',
        N'قيام السيد/محمد على محمد بمخالفة التوقيع بسجل الحضور بعدم الشطب على غياب يوم 9/6/2026 السيد/محمد الاشقر للتوقيع بالسجل',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'محمد على محمد بمخالفة التوقيع',
        '2026-06-09 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: محمد على محمد بمخالفة التوقيع
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمد على محمد بمخالفة التوقيع';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمد على محمد بمخالفة التوقيع%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمد على محمد بمخالفة التوقيع', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'186',
        '2026-07-16',
        '2026-07-16',
        N'أ',
        N'غادة شكرى',
        N'السيد/محمد السيد ايوب برفض وترك العمل والانصراف يوم 14/6/2026 وسؤ معاملة المواطنين منطقة العجمى',
        '2026-06-14',
        N'منطقة العجمى',
        N'السيد/محمد السيد ايوب برفض وترك العمل والانصراف يوم 14/6/2026 وسؤ معاملة المواطنين منطقة العجمى',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'والانصراف',
        '2026-07-16 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: والانصراف
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'والانصراف';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%والانصراف%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'والانصراف', N'موظف', N'منطقة العجمى', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-07-16', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض | |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'187',
        '2026-07-21',
        '2026-07-21',
        N'أ',
        N'طارق السيد',
        N'بشأن السيد/ اشرف محمد تم نقل المذكور من محطة (5) البيئة للعمل اعتبارا من 2/7/2026 وتم ابلاغة ولكن امتنع وتغيب حتى 5/7/2026 بدون اذن',
        '2026-07-02',
        N'محطة (5) البيئة للعمل اعتبارا من',
        N'بشأن السيد/ اشرف محمد تم نقل المذكور من محطة (5) البيئة للعمل اعتبارا من 2/7/2026 وتم ابلاغة ولكن امتنع وتغيب حتى 5/7/2026 بدون اذن',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'حتى 5',
        '2026-07-21 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: حتى 5
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'حتى 5';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%حتى 5%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'حتى 5', N'موظف', N'محطة (5) البيئة للعمل اعتبارا من', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'188',
        '2026-07-15',
        '2026-07-15',
        N'أ',
        N'ريهام شفيق',
        N'الفنى /على السيد على قد تحدث مع رئيس المحطة باسلوب غير لائق وتهديد رئيس المحطة وشتمة بالام',
        '2026-07-15',
        N'محطة باسلوب غير لائق وتهديد رئيس',
        N'الفنى /على السيد على قد تحدث مع رئيس المحطة باسلوب غير لائق وتهديد رئيس المحطة وشتمة بالام',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'على السيد على قد تحدث',
        '2026-07-15 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: على السيد على قد تحدث
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'على السيد على قد تحدث';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%على السيد على قد تحدث%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'على السيد على قد تحدث', N'موظف', N'محطة باسلوب غير لائق وتهديد رئيس', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-07-15', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض | |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'189',
        '2026-07-15',
        '2026-07-15',
        N'أ',
        N'صباح رمضان',
        N'السيد/ احمد عويس لارتكابة مخالفة التحدث بالوب غير لائق مع القائم بالمرور',
        '2026-07-15',
        N'ديوان عام الشركة',
        N'السيد/ احمد عويس لارتكابة مخالفة التحدث بالوب غير لائق مع القائم بالمرور',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'التحدث بالوب غير لائق مع',
        '2026-07-15 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: التحدث بالوب غير لائق مع
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'التحدث بالوب غير لائق مع';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%التحدث بالوب غير لائق مع%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'التحدث بالوب غير لائق مع', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'190',
        '2026-07-15',
        '2026-07-15',
        N'أ',
        N'حنان الخشاب',
        N'رئيس محطة باب 18 والعاملين يوم 5/7/2026 لارتكابهم مخالفة ترك العمل وقيامهم بأعمال محظورة عليهم',
        '2026-07-05',
        N'محطة باب 18 والعاملين',
        N'رئيس محطة باب 18 والعاملين يوم 5/7/2026 لارتكابهم مخالفة ترك العمل وقيامهم بأعمال محظورة عليهم',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'ين',
        '2026-07-15 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'محطة باب 18 والعاملين', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'191',
        '2026-07-15',
        '2026-07-15',
        N'أ',
        N'وفاء رمزى',
        N'نوم العامل مازن مؤمن محطة طوسون والعامل ناصر سالم على موقع احمد عرابى وترك البيارة ممتلئة مما ادى الى ارتفاع منسوب المياه داخل الشوارع',
        '2026-07-15',
        N'محطة طوسون والعامل ناصر سالم على',
        N'نوم العامل مازن مؤمن محطة طوسون والعامل ناصر سالم على موقع احمد عرابى وترك البيارة ممتلئة مما ادى الى ارتفاع منسوب المياه داخل الشوارع',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'مازن مؤمن محطة طوسون والعامل',
        '2026-07-15 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: مازن مؤمن محطة طوسون والعامل
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'مازن مؤمن محطة طوسون والعامل';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%مازن مؤمن محطة طوسون والعامل%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'مازن مؤمن محطة طوسون والعامل', N'موظف', N'محطة طوسون والعامل ناصر سالم على', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'192',
        '2026-07-30',
        '2026-07-30',
        N'أ',
        N'هانى احمد',
        N'اختفاء تيلفون الفنى سامحمحمد يوم الخميس 9/7/2026 وبعد سؤال الزملاء والمترددين على العمل وجد بحيازة السيد / رمضان عبدالسلام امين مخزن المستديم',
        '2026-07-09',
        N'مخزن المستديم',
        N'اختفاء تيلفون الفنى سامحمحمد يوم الخميس 9/7/2026 وبعد سؤال الزملاء والمترددين على العمل وجد بحيازة السيد / رمضان عبدالسلام امين مخزن المستديم',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'سامحمحمد',
        '2026-07-30 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: سامحمحمد
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'سامحمحمد';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%سامحمحمد%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'سامحمحمد', N'موظف', N'مخزن المستديم', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'193',
        '2026-07-27',
        '2026-07-27',
        N'أ',
        N'هدى رجب',
        N'مرور الامن على محطة غرب النوباتجية يومى 4-5/7/2026 ووجدت مغلقة وموقع المول العجمى 7/7/2026 مغلقة',
        '2026-07-05',
        N'محطة غرب النوباتجية',
        N'مرور الامن على محطة غرب النوباتجية يومى 4-5/7/2026 ووجدت مغلقة وموقع المول العجمى 7/7/2026 مغلقة',
        N'جارية',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'موظف محال للتحقيق',
        '2026-07-27 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'محطة غرب النوباتجية', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'194',
        '2026-07-19',
        '2026-07-19',
        N'أ',
        N'شعبان السيد',
        N'قيام السيد/حمدى رمضان بمنع مسئول متابعة رئيس مجلس الادارة يوم 11/7/2026',
        '2026-07-11',
        N'ادارة',
        N'قيام السيد/حمدى رمضان بمنع مسئول متابعة رئيس مجلس الادارة يوم 11/7/2026',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'حمدى رمضان بمنع مسئول متابعة',
        '2026-07-19 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: حمدى رمضان بمنع مسئول متابعة
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'حمدى رمضان بمنع مسئول متابعة';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%حمدى رمضان بمنع مسئول متابعة%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'حمدى رمضان بمنع مسئول متابعة', N'موظف', N'ادارة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

-- --------------------------------------------------------------------------
-- تحقيقات ديوان عام (ب) 2026 (نوع ب) - من رقم 1 إلى رقم 155 (إجمالي: 155 تحقيق)
-- --------------------------------------------------------------------------

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'1',
        '2026-01-11',
        '2026-01-11',
        N'ب',
        N'حنان الخشاب',
        N'غياب السيد/اشرف محمد محمد سالم',
        '2026-01-11',
        N'ديوان عام الشركة',
        N'غياب السيد/اشرف محمد محمد سالم',
        N'مغلقة',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'اشرف محمد محمد سالم',
        '2026-01-11 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: اشرف محمد محمد سالم
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'اشرف محمد محمد سالم';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%اشرف محمد محمد سالم%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'اشرف محمد محمد سالم', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-02-25', N'رئيس مجلس الإدارة', N'مجازاة بخصم من الراتب', N'4', N'عرض علي ر.م.ا 25/2/2026 | ورد من ر.م.أ 4/3/2026 انتهى بمجازاة السيد اشرف محمد محمد سالم بخصم 4 ايام', GETDATE());
    INSERT INTO FinalDecisions (InvestigationId, FinalDecisionText, ActionType, HRSentDate, HRNotes, CreatedAt)
    VALUES (@InvId, N'ورد من ر.م.أ 4/3/2026 انتهى بمجازاة  السيد اشرف محمد محمد سالم بخصم 4 ايام', 'hr', '2026-02-25', N'عرض علي ر.م.ا 25/2/2026 | ورد من ر.م.أ 4/3/2026 انتهى بمجازاة السيد اشرف محمد محمد سالم بخصم 4 ايام', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'2',
        '2026-01-11',
        '2026-01-11',
        N'ب',
        N'خالد احمد',
        N'قيام كلا من 1-الفني احمد محمد حسن 2- ايمن عبد الخالق محمد يوم الاتنين 28/12/2025 يوم الاتنين 28/12/2025 بترك العمل الساعه 10 اثناء النوه',
        '2025-12-28',
        N'ديوان عام الشركة',
        N'قيام كلا من 1-الفني احمد محمد حسن 2- ايمن عبد الخالق محمد يوم الاتنين 28/12/2025 يوم الاتنين 28/12/2025 بترك العمل الساعه 10 اثناء النوه',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'كلا من 1',
        '2026-01-11 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: احمد محمد حسن
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'احمد محمد حسن';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%احمد محمد حسن%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'احمد محمد حسن', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: ايمن عبد الخالق محمد
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'ايمن عبد الخالق محمد';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%ايمن عبد الخالق محمد%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'ايمن عبد الخالق محمد', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'3',
        '2026-01-19',
        '2026-01-19',
        N'ب',
        N'غاده شكري',
        N'بشان تحقيق الفني / رجب العوض في مهام عمله مما ادي الي تعدد البلاغات وعدم تواجد اي سيارات الشفط',
        '2026-01-19',
        N'ديوان عام الشركة',
        N'بشان تحقيق الفني / رجب العوض في مهام عمله مما ادي الي تعدد البلاغات وعدم تواجد اي سيارات الشفط',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'رجب العوض',
        '2026-01-19 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: رجب العوض
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'رجب العوض';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%رجب العوض%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'رجب العوض', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-01-26', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض علي ر.م.ا M.2521بتاريخ 26/1/2026 برقم صادر 734/2026 | ورد من ر.م.أ 30/1/2026', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'4',
        '2026-01-25',
        '2026-01-25',
        N'ب',
        N'نوره عباس',
        N'ترك عمل السيد /وليد عبد الجابر يوم 31/12/2025 اثناء النوه بالمحمودية الثالثه',
        '2025-12-31',
        N'ديوان عام الشركة',
        N'ترك عمل السيد /وليد عبد الجابر يوم 31/12/2025 اثناء النوه بالمحمودية الثالثه',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'موظف محال للتحقيق',
        '2026-01-25 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-04-18', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 18/4/2026 | ورد من ر.م.أ 14/4/2026', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'5',
        '2026-01-25',
        '2026-01-25',
        N'ب',
        N'مروه مصطفى',
        N'غياب السيد/ محمد سعيد محمد خميس يومي 31/12/2025-3/1/2026',
        '2025-12-31',
        N'ديوان عام الشركة',
        N'غياب السيد/ محمد سعيد محمد خميس يومي 31/12/2025-3/1/2026',
        N'مغلقة',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'محمد سعيد محمد خميس',
        '2026-01-25 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: محمد سعيد محمد خميس
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمد سعيد محمد خميس';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمد سعيد محمد خميس%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمد سعيد محمد خميس', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-04-12', N'رئيس مجلس الإدارة', N'مجازاة بخصم من الراتب', N'14', N'عرض على ر.م.أ 12/4/2026 | ورد من ر.م.أ 14/4/2026 بخصم خمسة ايام من الراتب من محمد سعيد وخصم ثلاث ايام من اشرف محمد محمد سالم', GETDATE());
    INSERT INTO FinalDecisions (InvestigationId, FinalDecisionText, ActionType, HRSentDate, HRNotes, CreatedAt)
    VALUES (@InvId, N'ورد من ر.م.أ 14/4/2026 بخصم خمسة ايام من الراتب من محمد سعيد  وخصم ثلاث ايام من اشرف محمد محمد سالم', 'hr', '2026-04-12', N'عرض على ر.م.أ 12/4/2026 | ورد من ر.م.أ 14/4/2026 بخصم خمسة ايام من الراتب من محمد سعيد وخصم ثلاث ايام من اشرف محمد محمد سالم', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'6',
        '2026-01-25',
        '2026-01-25',
        N'ب',
        N'هدى رجب',
        N'غياب السائق/ احمد عصام محمد كود11175 عن العمل ايام 2,3/1/2026',
        '2026-01-03',
        N'ديوان عام الشركة',
        N'غياب السائق/ احمد عصام محمد كود11175 عن العمل ايام 2,3/1/2026',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'احمد عصام محمد كود11175',
        '2026-01-25 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: احمد عصام محمد كود11175
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE Code = N'11175';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'احمد عصام محمد كود11175';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%احمد عصام محمد كود11175%';
    IF @EmpMasterId IS NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM EmployeesMaster WHERE Code = N'11175')
            SET @NewCode = N'11175';
        ELSE
            SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'احمد عصام محمد كود11175', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-06-22', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 22/6/2026 | ورد من ر.م.أ 29/4/2026', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'7',
        '2026-01-25',
        '2026-01-25',
        N'ب',
        N'نوره عبدالرحمن',
        N'غياب السيد/ محمد عبدالتواب كود 8762 يوم الجمعه 2/1/2026',
        '2026-01-02',
        N'ديوان عام الشركة',
        N'غياب السيد/ محمد عبدالتواب كود 8762 يوم الجمعه 2/1/2026',
        N'مغلقة',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'محمد عبدالتواب كود 8762',
        '2026-01-25 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: محمد عبدالتواب كود 8762
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE Code = N'8762';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمد عبدالتواب كود 8762';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمد عبدالتواب كود 8762%';
    IF @EmpMasterId IS NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM EmployeesMaster WHERE Code = N'8762')
            SET @NewCode = N'8762';
        ELSE
            SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمد عبدالتواب كود 8762', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-02-07', N'رئيس مجلس الإدارة', N'حفظ التحقيق', N'22', N'عرض علي ر.م.ا 7/2/2026 | ورد من ر.م.أ 22/2/2026 بالحفظ', GETDATE());
    INSERT INTO FinalDecisions (InvestigationId, FinalDecisionText, ActionType, HRSentDate, HRNotes, CreatedAt)
    VALUES (@InvId, N'ورد من ر.م.أ 22/2/2026 بالحفظ', 'archive', '2026-02-07', N'عرض علي ر.م.ا 7/2/2026 | ورد من ر.م.أ 22/2/2026 بالحفظ', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'8',
        '2026-01-19',
        '2026-01-19',
        N'ب',
        N'ريهام شفيق',
        N'المرور على محطة معالجة الهانوفيل تلاحظ ان كلا من :1- محمد علي حسن مامورية يومي 4,5/1/2026 والعامل يوسف ابراهيم حسن مامورية يوم 5/1/2026 دون وجه حق انتهى التحقيق : بحفظ التحقيق لكلا من 1- محمد علي حسن 2- يوسف ابراهيم حسن التوصية بمجازات السيدة / هب...',
        '2026-01-05',
        N'محطة معالجة الهانوفيل',
        N'المرور على محطة معالجة الهانوفيل تلاحظ ان كلا من :1- محمد علي حسن مامورية يومي 4,5/1/2026 والعامل يوسف ابراهيم حسن مامورية يوم 5/1/2026 دون وجه حق انتهى التحقيق : بحفظ التحقيق لكلا من 1- محمد علي حسن 2- يوسف ابراهيم حسن التوصية بمجازات السيدة / هبه مجدي عبدالقادر بالدرجه الاولى بالعرض على مجلس الادارة',
        N'صدر قرار',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'يوسف ابراهيم حسن مامورية',
        '2026-01-19 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: محمد علي حسن مامورية
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمد علي حسن مامورية';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمد علي حسن مامورية%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمد علي حسن مامورية', N'موظف', N'محطة معالجة الهانوفيل', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: محمد علي حسن
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمد علي حسن';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمد علي حسن%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمد علي حسن', N'موظف', N'محطة معالجة الهانوفيل', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-01-26', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض علي ر.م.ا 26/1/2026 | ورد من ر.م.أ 1/2/2026', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'9',
        '2026-01-19',
        '2026-01-19',
        N'ب',
        N'وفاء رمزي',
        N'غياب السيد/ابوزيد احمد ابوزيد احمد كود 10920 غياب يومي 29,30/12/2025 بموقع محطة مصر اثناء التمركزات',
        '2025-12-30',
        N'محطة مصر',
        N'غياب السيد/ابوزيد احمد ابوزيد احمد كود 10920 غياب يومي 29,30/12/2025 بموقع محطة مصر اثناء التمركزات',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'ابوزيد احمد ابوزيد احمد كود',
        '2026-01-19 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: ابوزيد احمد ابوزيد احمد كود
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE Code = N'10920';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'ابوزيد احمد ابوزيد احمد كود';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%ابوزيد احمد ابوزيد احمد كود%';
    IF @EmpMasterId IS NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM EmployeesMaster WHERE Code = N'10920')
            SET @NewCode = N'10920';
        ELSE
            SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'ابوزيد احمد ابوزيد احمد كود', N'موظف', N'محطة مصر', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-05-13', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض علي ر.م.ا 13/5/2026 | ورد من ر.م.أ 14/5/2026', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'10',
        '2026-01-19',
        '2026-01-19',
        N'ب',
        N'ايناس جلال',
        N'ترك عمل كلا من 1-هاني السيد علي 2-محمود ماهر فرج يوم 30/12/2025 اثناء النوه بمحطة تقسيم ابوقيرغياب السيد/ عمرو محمد عبدالسلام الديب كود 7911 يوم30/12/2025 وترك عمل كلا من 1-هاني اليد علي 2-محمود ماهر فرج يوم 30/12/2025',
        '2025-12-30',
        N'بمحطة تقسيم ابوقيرغياب السيد',
        N'ترك عمل كلا من 1-هاني السيد علي 2-محمود ماهر فرج يوم 30/12/2025 اثناء النوه بمحطة تقسيم ابوقيرغياب السيد/ عمرو محمد عبدالسلام الديب كود 7911 يوم30/12/2025 وترك عمل كلا من 1-هاني اليد علي 2-محمود ماهر فرج يوم 30/12/2025',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'كلا من 1',
        '2026-01-19 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: هاني السيد علي
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE Code = N'7911';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'هاني السيد علي';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%هاني السيد علي%';
    IF @EmpMasterId IS NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM EmployeesMaster WHERE Code = N'7911')
            SET @NewCode = N'7911';
        ELSE
            SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'هاني السيد علي', N'موظف', N'بمحطة تقسيم ابوقيرغياب السيد', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: محمود ماهر فرج
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمود ماهر فرج';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمود ماهر فرج%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمود ماهر فرج', N'موظف', N'بمحطة تقسيم ابوقيرغياب السيد', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: هاني اليد علي
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'هاني اليد علي';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%هاني اليد علي%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'هاني اليد علي', N'موظف', N'بمحطة تقسيم ابوقيرغياب السيد', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-02-17', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض علي ر.م.ا 17/2/2026 | ورد من ر.م.أ 22/2/2026', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'11',
        '2026-01-19',
        '2026-01-19',
        N'ب',
        N'طارق السيد',
        N'المرور يوم الاحد 28/12/2025 بالورديه المسائيه على الادارة العامه والكسح التجاري تلاحظ سجلات الحضور والانصراف مدون عليه ساعة الحضور اعطاء السائقين والعمال بدل راحه عن يوم الجمعه على الرغم من تقاضيهم مبالغ ماليه',
        '2025-12-28',
        N'ادارة العامه والكسح التجاري',
        N'المرور يوم الاحد 28/12/2025 بالورديه المسائيه على الادارة العامه والكسح التجاري تلاحظ سجلات الحضور والانصراف مدون عليه ساعة الحضور اعطاء السائقين والعمال بدل راحه عن يوم الجمعه على الرغم من تقاضيهم مبالغ ماليه',
        N'جارية',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'ين والعمال بدل راحه',
        '2026-01-19 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: ين والعمال بدل راحه
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'ين والعمال بدل راحه';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%ين والعمال بدل راحه%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'ين والعمال بدل راحه', N'موظف', N'ادارة العامه والكسح التجاري', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'12',
        '2026-01-19',
        '2026-01-19',
        N'ب',
        N'غاده شكري',
        N'المرور الامن ايام 8,9,10/1/2026 اثناء النوه تلاحظ غياب: 1-هلال عطيه ابراهيم 2- ابراهيم عياد 3-عادل عبدالمجيد 4-احمد محمد حسن 5-رمضان محمد نوح 6-محمد جلال 7-ابراهيم السيد احمد 8-حسين محمد عبده 9-عادل محمد 10-محمد عبدالحميد خميس 11-رجب السيد ابراهيم...',
        '2026-01-10',
        N'ديوان عام الشركة',
        N'المرور الامن ايام 8,9,10/1/2026 اثناء النوه تلاحظ غياب: 1-هلال عطيه ابراهيم 2- ابراهيم عياد 3-عادل عبدالمجيد 4-احمد محمد حسن 5-رمضان محمد نوح 6-محمد جلال 7-ابراهيم السيد احمد 8-حسين محمد عبده 9-عادل محمد 10-محمد عبدالحميد خميس 11-رجب السيد ابراهيم 12-يوسف رزق 13-محمد ابراهيم عبدالحميد 14-محمد حمدي وهبة 15-محمد كمال احمد 16-احمد عبدالناصر احمد ونوم السيد/ رجب حسن عبدالله حسنين اثناء العمل',
        N'صدر قرار',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'1',
        '2026-01-19 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: هلال عطيه ابراهيم
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'هلال عطيه ابراهيم';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%هلال عطيه ابراهيم%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'هلال عطيه ابراهيم', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: ابراهيم عياد
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'ابراهيم عياد';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%ابراهيم عياد%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'ابراهيم عياد', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: عادل عبدالمجيد
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'عادل عبدالمجيد';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%عادل عبدالمجيد%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'عادل عبدالمجيد', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: احمد محمد حسن
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'احمد محمد حسن';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%احمد محمد حسن%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'احمد محمد حسن', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: رمضان محمد نوح
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'رمضان محمد نوح';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%رمضان محمد نوح%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'رمضان محمد نوح', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-02-17', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض علي ر.م.ا 17/2/2026 | ورد من ر.م.أ 22/2/2026', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'13',
        '2026-01-19',
        '2026-01-19',
        N'ب',
        N'وفاء رمزي',
        N'ترك عمل العامل/ عبدالله مجدي يوم 8/1/2026 اثناء النوه يعمل بمحطة ابيس 12/8',
        '2026-01-08',
        N'بمحطة ابيس 12',
        N'ترك عمل العامل/ عبدالله مجدي يوم 8/1/2026 اثناء النوه يعمل بمحطة ابيس 12/8',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'عبدالله مجدي',
        '2026-01-19 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: عبدالله مجدي
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'عبدالله مجدي';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%عبدالله مجدي%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'عبدالله مجدي', N'موظف', N'بمحطة ابيس 12', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-02-17', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض علي ر.م.ا 17/2/2026 |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'14',
        '2026-01-19',
        '2026-01-19',
        N'ب',
        N'هاني احمد',
        N'ترك عمل كلا من :1-هاني السيد علي 2-مدحت عبدالعزيز يعملان بمحطة تقسيم ابوقير الوردية المسائية',
        '2026-01-19',
        N'بمحطة تقسيم ابوقير الوردية المسائية',
        N'ترك عمل كلا من :1-هاني السيد علي 2-مدحت عبدالعزيز يعملان بمحطة تقسيم ابوقير الوردية المسائية',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'كلا من 1',
        '2026-01-19 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: هاني السيد علي
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'هاني السيد علي';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%هاني السيد علي%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'هاني السيد علي', N'موظف', N'بمحطة تقسيم ابوقير الوردية المسائية', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: مدحت عبدالعزيز يعملان
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'مدحت عبدالعزيز يعملان';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%مدحت عبدالعزيز يعملان%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'مدحت عبدالعزيز يعملان', N'موظف', N'بمحطة تقسيم ابوقير الوردية المسائية', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-03-15', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض علي ر.م.ا 15/3/2026 | ورد من ر.م.أ 16/3/2026', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'15',
        '2026-01-19',
        '2026-01-19',
        N'ب',
        N'غاده شكري',
        N'غياب كلا من 1-محمود محمد مرسي 27,28,29/12 2-ابراهيم عبدالصابور29/12 3-محمد عبدالحميد خميس 30/12 4-رجب حافظ احمد 29/12 5-حسين محمد عبده 29/12 اثناء النوه',
        '2026-12-29',
        N'ديوان عام الشركة',
        N'غياب كلا من 1-محمود محمد مرسي 27,28,29/12 2-ابراهيم عبدالصابور29/12 3-محمد عبدالحميد خميس 30/12 4-رجب حافظ احمد 29/12 5-حسين محمد عبده 29/12 اثناء النوه',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'كلا من 1',
        '2026-01-19 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: كلا من 1
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'كلا من 1';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%كلا من 1%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'كلا من 1', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-02-19', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض علي ر.م.ا 19/2/2026 | ورد من ر.م.أ 25/2/2026', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'16',
        '2026-01-20',
        '2026-01-20',
        N'ب',
        N'ياسر الحداد',
        N'غياب الفني/ مينا باسم موريس كود8029 يومي 14,30/12/2025 العامل مصطفى خميس عبدالمنعم كود 9088 يوم 14/12/2025 اثناء التمركزات',
        '2025-12-30',
        N'ديوان عام الشركة',
        N'غياب الفني/ مينا باسم موريس كود8029 يومي 14,30/12/2025 العامل مصطفى خميس عبدالمنعم كود 9088 يوم 14/12/2025 اثناء التمركزات',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'مينا باسم موريس كود8029',
        '2026-01-20 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: مينا باسم موريس كود8029
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE Code = N'8029';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'مينا باسم موريس كود8029';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%مينا باسم موريس كود8029%';
    IF @EmpMasterId IS NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM EmployeesMaster WHERE Code = N'8029')
            SET @NewCode = N'8029';
        ELSE
            SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'مينا باسم موريس كود8029', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-03-04', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض علي ر.م.ا 4/3/2026 | ورد من ر.م.أ 10/3/2026', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'17',
        '2026-01-19',
        '2026-01-19',
        N'ب',
        N'نرمين قنديل',
        N'المرور يوم 3/1/2026 الورديه الاولى على محطة معالجة ابيس 11/8, ابيس2/8 ابيس السابعه تلاحظ تواجد عامل واحد بالوردية',
        '2026-01-03',
        N'محطة معالجة ابيس 11',
        N'المرور يوم 3/1/2026 الورديه الاولى على محطة معالجة ابيس 11/8, ابيس2/8 ابيس السابعه تلاحظ تواجد عامل واحد بالوردية',
        N'صدر قرار',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'موظف محال للتحقيق',
        '2026-01-19 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'محطة معالجة ابيس 11', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-04-01', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض علي ر.م.ا 1/4/2026 | ورد من ر.م.أ 5/4/2026', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'18',
        '2026-01-21',
        '2026-01-21',
        N'ب',
        N'مروة مصطفى',
        N'المرور على محطة طلعت مصطفى يوم2/1/2026 تلاحظ ترك كلا من 1-عاطف امام 2-عبدالحميد متولي , مطالبة مدير ادارة المعدات بالعجمي لعدم تواجده , مدير محطة العجمي لتواجد عدد 1 سائق بالوردية',
        '2026-01-02',
        N'محطة طلعت مصطفى',
        N'المرور على محطة طلعت مصطفى يوم2/1/2026 تلاحظ ترك كلا من 1-عاطف امام 2-عبدالحميد متولي , مطالبة مدير ادارة المعدات بالعجمي لعدم تواجده , مدير محطة العجمي لتواجد عدد 1 سائق بالوردية',
        N'جارية',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'عاطف امام, عبدالحميد متولي',
        '2026-01-21 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: عاطف امام
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'عاطف امام';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%عاطف امام%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'عاطف امام', N'موظف', N'محطة طلعت مصطفى', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: عبدالحميد متولي
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'عبدالحميد متولي';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%عبدالحميد متولي%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'عبدالحميد متولي', N'موظف', N'محطة طلعت مصطفى', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'19',
        '2026-01-19',
        '2026-01-19',
        N'ب',
        N'وفاء رمزي',
        N'غياب السيد/شعبان صابر محمد كود 7753 رئيس محطة ابيس 1/10وسط يوم 29/12/2025 اثناء التمركزات',
        '2025-12-29',
        N'محطة ابيس 1',
        N'غياب السيد/شعبان صابر محمد كود 7753 رئيس محطة ابيس 1/10وسط يوم 29/12/2025 اثناء التمركزات',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'شعبان صابر محمد كود 7753',
        '2026-01-19 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: شعبان صابر محمد كود 7753
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE Code = N'7753';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'شعبان صابر محمد كود 7753';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%شعبان صابر محمد كود 7753%';
    IF @EmpMasterId IS NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM EmployeesMaster WHERE Code = N'7753')
            SET @NewCode = N'7753';
        ELSE
            SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'شعبان صابر محمد كود 7753', N'موظف', N'محطة ابيس 1', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-04-16', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض علي ر.م.ا 16/4/2026 | ورد من ر.م.أ 18/4/2026', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'20',
        '2026-01-25',
        '2026-01-25',
        N'ب',
        N'هدى رجب',
        N'غياب السيد/احمد عبدالفتاح دياب ايام 2,20,25/12/2025 وتاخير كلا من 1-محمود رشاد 2-احمد عبدالفتاح 3-احمد سمير عن العمل بالمحافظه',
        '2025-12-25',
        N'ديوان عام الشركة',
        N'غياب السيد/احمد عبدالفتاح دياب ايام 2,20,25/12/2025 وتاخير كلا من 1-محمود رشاد 2-احمد عبدالفتاح 3-احمد سمير عن العمل بالمحافظه',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'احمد عبدالفتاح دياب ايام 2',
        '2026-01-25 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: محمود رشاد
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمود رشاد';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمود رشاد%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمود رشاد', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: احمد عبدالفتاح
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'احمد عبدالفتاح';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%احمد عبدالفتاح%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'احمد عبدالفتاح', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: احمد سمير عن العمل بالمحافظه
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'احمد سمير عن العمل بالمحافظه';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%احمد سمير عن العمل بالمحافظه%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'احمد سمير عن العمل بالمحافظه', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'21',
        '2026-01-19',
        '2026-01-19',
        N'ب',
        N'هاني احمد',
        N'غياب عن العمل العامل/يوسف احمد عبدالمجيد يومي 31/12/2025 , 1/1/2026 اثناء النوه',
        '2025-12-31',
        N'ديوان عام الشركة',
        N'غياب عن العمل العامل/يوسف احمد عبدالمجيد يومي 31/12/2025 , 1/1/2026 اثناء النوه',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'موظف محال للتحقيق',
        '2026-01-19 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-02-19', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض علي ر.م.ا 19/2/2026 | ورد من ر.م.أ 24/2/2026', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'22',
        '2026-01-01',
        NULL,
        N'ب',
        N'غير مسند',
        N'تحقيق ديوان عام ب رقم 22',
        '2026-01-01',
        N'ديوان عام الشركة',
        N'تحقيق ديوان عام ب رقم 22',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'موظف محال للتحقيق',
        '2026-01-01 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'23',
        '2026-01-20',
        '2026-01-20',
        N'ب',
        N'ايمن توفيق',
        N'غياب السيد/محمود محمد محمد مرسي كود9295 من يوم 27/12/2025حتى 31/12/2025 بمحطة السيوف الجديدة اثناء التمركزات',
        '2025-12-27',
        N'بمحطة السيوف الجديدة',
        N'غياب السيد/محمود محمد محمد مرسي كود9295 من يوم 27/12/2025حتى 31/12/2025 بمحطة السيوف الجديدة اثناء التمركزات',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'محمود محمد محمد مرسي كود9295',
        '2026-01-20 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: محمود محمد محمد مرسي كود9295
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE Code = N'9295';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمود محمد محمد مرسي كود9295';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمود محمد محمد مرسي كود9295%';
    IF @EmpMasterId IS NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM EmployeesMaster WHERE Code = N'9295')
            SET @NewCode = N'9295';
        ELSE
            SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمود محمد محمد مرسي كود9295', N'موظف', N'بمحطة السيوف الجديدة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'24',
        '2026-01-19',
        '2026-01-19',
        N'ب',
        N'حنان الخشاب',
        N'غياب السيد اسلام سمير احمد بسيوني يوم28/12/2025 اثناء النوة بعمل بمحطة العامرية',
        '2025-12-28',
        N'بمحطة العامرية',
        N'غياب السيد اسلام سمير احمد بسيوني يوم28/12/2025 اثناء النوة بعمل بمحطة العامرية',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'اسلام سمير احمد بسيوني',
        '2026-01-19 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: اسلام سمير احمد بسيوني
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'اسلام سمير احمد بسيوني';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%اسلام سمير احمد بسيوني%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'اسلام سمير احمد بسيوني', N'موظف', N'بمحطة العامرية', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-02-25', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 25/2/2026 | ورد من ر.م.أ 4/3/2026', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'25',
        '2026-01-19',
        '2026-01-19',
        N'ب',
        N'غاده شكري',
        N'غياب السيد/علي يوسف محمد ابوالدهب من27/12/2025حتى 29/12/2025 يعمل بمحطة التنقية الشرقية , انتهى التحقيق بمجازاته خصم يوم من راتبه',
        '2025-12-27',
        N'بمحطة التنقية الشرقية',
        N'غياب السيد/علي يوسف محمد ابوالدهب من27/12/2025حتى 29/12/2025 يعمل بمحطة التنقية الشرقية , انتهى التحقيق بمجازاته خصم يوم من راتبه',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'علي يوسف محمد ابوالدهب من27',
        '2026-01-19 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: علي يوسف محمد ابوالدهب من27
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'علي يوسف محمد ابوالدهب من27';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%علي يوسف محمد ابوالدهب من27%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'علي يوسف محمد ابوالدهب من27', N'موظف', N'بمحطة التنقية الشرقية', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-01-27', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 27/1/2026 | ورد من ر.م.أ 8/2/2026', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'26',
        '2026-01-19',
        '2026-01-19',
        N'ب',
        N'حنان الخشاب',
        N'ترك عمل السائق/حنفي محمود يوم7/1/2026 بالوردية المسائية',
        '2026-01-07',
        N'ديوان عام الشركة',
        N'ترك عمل السائق/حنفي محمود يوم7/1/2026 بالوردية المسائية',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'حن',
        '2026-01-19 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-03-04', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 4/3/2026 | ورد من ر.م.أ 10/3/2026', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'27',
        '2026-01-17',
        '2026-01-17',
        N'ب',
        N'تامر الحداد',
        N'المرور عللا محطات الشركة المختلفة ايام13,15,16/1/2026 اثناء النوه تلاحظ غياب كلا من 1-اسلام سمير احمد 2-احمد رجب عبدالغني 3-ايهاب رجب يونس 4-محمد عبدالعاطي غازي 5-مصطفى خميس عبدالمنعم 6-اسامه وليد حسن 7-السيد مجدي السيد 8-محمد علي محمد',
        '2026-01-16',
        N'ديوان عام الشركة',
        N'المرور عللا محطات الشركة المختلفة ايام13,15,16/1/2026 اثناء النوه تلاحظ غياب كلا من 1-اسلام سمير احمد 2-احمد رجب عبدالغني 3-ايهاب رجب يونس 4-محمد عبدالعاطي غازي 5-مصطفى خميس عبدالمنعم 6-اسامه وليد حسن 7-السيد مجدي السيد 8-محمد علي محمد',
        N'جارية',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'كلا من 1',
        '2026-01-17 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: اسلام سمير احمد
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'اسلام سمير احمد';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%اسلام سمير احمد%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'اسلام سمير احمد', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: احمد رجب عبدالغني
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'احمد رجب عبدالغني';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%احمد رجب عبدالغني%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'احمد رجب عبدالغني', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: ايهاب رجب يونس
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'ايهاب رجب يونس';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%ايهاب رجب يونس%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'ايهاب رجب يونس', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: محمد عبدالعاطي غازي
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمد عبدالعاطي غازي';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمد عبدالعاطي غازي%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمد عبدالعاطي غازي', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: مصطفى خميس عبدالمنعم
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'مصطفى خميس عبدالمنعم';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%مصطفى خميس عبدالمنعم%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'مصطفى خميس عبدالمنعم', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'28',
        '2026-02-01',
        '2026-02-01',
        N'ب',
        N'طارق السيد',
        N'قيام الفني/محمد العمري يعمل بمحطة التنقية الشرقية يوم11/1/2026 الحضور الساعه6م والانصراف8م',
        '2026-01-11',
        N'بمحطة التنقية الشرقية',
        N'قيام الفني/محمد العمري يعمل بمحطة التنقية الشرقية يوم11/1/2026 الحضور الساعه6م والانصراف8م',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'محمد العمري ي',
        '2026-02-01 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: محمد العمري ي
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمد العمري ي';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمد العمري ي%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمد العمري ي', N'موظف', N'بمحطة التنقية الشرقية', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'29',
        '2026-01-21',
        '2026-01-21',
        N'ب',
        N'حنان الخشاب',
        N'غياب السيد فرج عبدالمنعم احمد كود9673 يومي9,10/1/2026 بالوردية المسائية بمحطة رفع ابيس',
        '2026-01-10',
        N'بمحطة رفع ابيس',
        N'غياب السيد فرج عبدالمنعم احمد كود9673 يومي9,10/1/2026 بالوردية المسائية بمحطة رفع ابيس',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'فرج عبدالمنعم احمد كود9673',
        '2026-01-21 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: فرج عبدالمنعم احمد كود9673
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE Code = N'9673';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'فرج عبدالمنعم احمد كود9673';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%فرج عبدالمنعم احمد كود9673%';
    IF @EmpMasterId IS NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM EmployeesMaster WHERE Code = N'9673')
            SET @NewCode = N'9673';
        ELSE
            SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'فرج عبدالمنعم احمد كود9673', N'موظف', N'بمحطة رفع ابيس', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-04-08', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 8/4/2026 | ورد من ر.م.أ 14/4/2026', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'30',
        '2026-01-25',
        '2026-01-25',
        N'ب',
        N'نوره عباس',
        N'ترك عمل السائق/رضا عبدالقادر العمل بالتمركزات على السيارة1425 يوم15/1/2026 امام محطة 2 منتزه اول',
        '2026-01-15',
        N'محطة 2 منتزه اول',
        N'ترك عمل السائق/رضا عبدالقادر العمل بالتمركزات على السيارة1425 يوم15/1/2026 امام محطة 2 منتزه اول',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'رضا عبدالقادر ال',
        '2026-01-25 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: رضا عبدالقادر ال
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'رضا عبدالقادر ال';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%رضا عبدالقادر ال%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'رضا عبدالقادر ال', N'موظف', N'محطة 2 منتزه اول', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-04-15', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 15/4/2026 | ورد من ر.م.أ 20/4/2026', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'31',
        '2026-01-27',
        '2026-01-27',
        N'ب',
        N'وفاء رمزي',
        N'غياب كلا من 1-السيد حسن احمد يومي 7,8,9/1 2-عمرو محمد شحاته الهادي 8/1 3-عبدالعزيز عوض صابر 8/1 4-علي حنفي علي عيسى 29/12 5-احمد عبدالنبي عطيه29/12',
        '2026-01-09',
        N'ديوان عام الشركة',
        N'غياب كلا من 1-السيد حسن احمد يومي 7,8,9/1 2-عمرو محمد شحاته الهادي 8/1 3-عبدالعزيز عوض صابر 8/1 4-علي حنفي علي عيسى 29/12 5-احمد عبدالنبي عطيه29/12',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'كلا من 1',
        '2026-01-27 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: حسن احمد
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'حسن احمد';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%حسن احمد%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'حسن احمد', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'32',
        '2026-01-28',
        '2026-01-28',
        N'ب',
        N'هاني احمد',
        N'غياب السيد/عصام عطوه محمد كود8177 يوم8/1/2026 بدون اذن محطة 2بورسعيد',
        '2026-01-08',
        N'محطة 2بورسعيد',
        N'غياب السيد/عصام عطوه محمد كود8177 يوم8/1/2026 بدون اذن محطة 2بورسعيد',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'عصام عطوه محمد كود8177',
        '2026-01-28 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: عصام عطوه محمد كود8177
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE Code = N'8177';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'عصام عطوه محمد كود8177';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%عصام عطوه محمد كود8177%';
    IF @EmpMasterId IS NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM EmployeesMaster WHERE Code = N'8177')
            SET @NewCode = N'8177';
        ELSE
            SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'عصام عطوه محمد كود8177', N'موظف', N'محطة 2بورسعيد', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-06-01', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 1/6/2026 |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'33',
        '2026-02-09',
        '2026-02-09',
        N'ب',
        N'ايناس جلال',
        N'غياب كلا من 1-اسامه وليد حسن والعامل/السيد مجدي السيد يوم15/12026 اثناء التمركزات',
        '2026-12-15',
        N'ديوان عام الشركة',
        N'غياب كلا من 1-اسامه وليد حسن والعامل/السيد مجدي السيد يوم15/12026 اثناء التمركزات',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'كلا من 1',
        '2026-02-09 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: كلا من 1
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'كلا من 1';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%كلا من 1%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'كلا من 1', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-05-10', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 10/5/2026 |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'34',
        '2026-01-28',
        '2026-01-28',
        N'ب',
        N'حنان الخشاب',
        N'قيام الفني/كريم محمد هاشم يعمل بمحطة 3سيدي بشر منتزه اول بالنوم اثناء العمل يوم16/1/2026 بالوردية',
        '2026-01-16',
        N'بمحطة 3سيدي بشر منتزه اول بالنوم',
        N'قيام الفني/كريم محمد هاشم يعمل بمحطة 3سيدي بشر منتزه اول بالنوم اثناء العمل يوم16/1/2026 بالوردية',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'كريم محمد هاشم ي',
        '2026-01-28 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: كريم محمد هاشم ي
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'كريم محمد هاشم ي';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%كريم محمد هاشم ي%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'كريم محمد هاشم ي', N'موظف', N'بمحطة 3سيدي بشر منتزه اول بالنوم', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-02-25', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 25/2/2026 | ورد من ر.م.أ 4/3/2026', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'35',
        '2026-01-27',
        '2026-01-27',
        N'ب',
        N'غاده شكري',
        N'انقطاع السيد/محمد جمال الدين السيد عبدالرزق يعمل بمحطة معالجة العامرية من6/1/2026 حتى 11/1/2026',
        '2026-01-06',
        N'بمحطة معالجة العامرية من6',
        N'انقطاع السيد/محمد جمال الدين السيد عبدالرزق يعمل بمحطة معالجة العامرية من6/1/2026 حتى 11/1/2026',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'محمد جمال الدين السيد عبدالرزق',
        '2026-01-27 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: محمد جمال الدين السيد عبدالرزق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمد جمال الدين السيد عبدالرزق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمد جمال الدين السيد عبدالرزق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمد جمال الدين السيد عبدالرزق', N'موظف', N'بمحطة معالجة العامرية من6', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-02-04', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 4/2/2026 | ورد من ر.م.أ 6/2/2026', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'36',
        '2026-01-27',
        '2026-01-27',
        N'ب',
        N'غاده شكري',
        N'غياب السيد/ايمن محمد حسني محمد من الفتره 9/1/2026 حتى 14/1/2026 يعمل خدمه معاونه بادارة العجمي',
        '2026-01-09',
        N'بادارة العجمي',
        N'غياب السيد/ايمن محمد حسني محمد من الفتره 9/1/2026 حتى 14/1/2026 يعمل خدمه معاونه بادارة العجمي',
        N'مغلقة',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'ايمن محمد حسني محمد من',
        '2026-01-27 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: ايمن محمد حسني محمد من
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'ايمن محمد حسني محمد من';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%ايمن محمد حسني محمد من%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'ايمن محمد حسني محمد من', N'موظف', N'بادارة العجمي', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-02-04', N'رئيس مجلس الإدارة', N'مجازاة بخصم من الراتب', N'6', N'عرض علي ر.م.ا 4/2/2026 | ورد من ر.م.أ 6/2/2026 بمجازات السيد ايمن محمد بخصم 2 يوم من راتبة', GETDATE());
    INSERT INTO FinalDecisions (InvestigationId, FinalDecisionText, ActionType, HRSentDate, HRNotes, CreatedAt)
    VALUES (@InvId, N'ورد من ر.م.أ 6/2/2026 بمجازات السيد ايمن  محمد بخصم 2 يوم من  راتبة', 'hr', '2026-02-04', N'عرض علي ر.م.ا 4/2/2026 | ورد من ر.م.أ 6/2/2026 بمجازات السيد ايمن محمد بخصم 2 يوم من راتبة', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'37',
        '2026-01-27',
        '2026-01-27',
        N'ب',
        N'غاده شكري',
        N'غياب السيد/عبدالرحمن صالح حسن يومي15,16/1/2026 يعمل بمحطة الرابعه الناصرية',
        '2026-01-16',
        N'بمحطة الرابعه الناصرية',
        N'غياب السيد/عبدالرحمن صالح حسن يومي15,16/1/2026 يعمل بمحطة الرابعه الناصرية',
        N'مغلقة',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'عبدالرحمن صالح حسن',
        '2026-01-27 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: عبدالرحمن صالح حسن
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'عبدالرحمن صالح حسن';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%عبدالرحمن صالح حسن%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'عبدالرحمن صالح حسن', N'موظف', N'بمحطة الرابعه الناصرية', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-02-09', N'رئيس مجلس الإدارة', N'مجازاة بخصم من الراتب', N'12', N'عرض علي ر.م.ا 9/2/2026 | ورد من ر.م.أ 12/2/2026 بمجازات السيد عبد الرحمن صالح بخصم 5 ايام من الراتب + غياب 2 يوم', GETDATE());
    INSERT INTO FinalDecisions (InvestigationId, FinalDecisionText, ActionType, HRSentDate, HRNotes, CreatedAt)
    VALUES (@InvId, N'ورد من ر.م.أ 12/2/2026 بمجازات السيد عبد الرحمن صالح بخصم 5 ايام من الراتب + غياب 2 يوم', 'hr', '2026-02-09', N'عرض علي ر.م.ا 9/2/2026 | ورد من ر.م.أ 12/2/2026 بمجازات السيد عبد الرحمن صالح بخصم 5 ايام من الراتب + غياب 2 يوم', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'38',
        '2026-02-01',
        '2026-02-01',
        N'ب',
        N'صباح رمضان',
        N'غياب السيد/ عوض بسيوني اسماعيل يوم15/1/2026 اثناء التمركزات',
        '2026-01-15',
        N'ديوان عام الشركة',
        N'غياب السيد/ عوض بسيوني اسماعيل يوم15/1/2026 اثناء التمركزات',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'عوض بسيوني اسماعيل',
        '2026-02-01 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: عوض بسيوني اسماعيل
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'عوض بسيوني اسماعيل';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%عوض بسيوني اسماعيل%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'عوض بسيوني اسماعيل', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-03-15', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض علي ر.م.ا 15/3/2026 | ورد من ر.م.أ 16/3/2026', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'39',
        '2026-02-03',
        '2026-02-03',
        N'ب',
        N'وفاء رمزي',
        N'قيام الفني/عوض بسيوني اسماعيل يوم18/1/2026 بتوقيع حضور وانصراف وترك العمل الساعه8:15',
        '2026-01-18',
        N'ديوان عام الشركة',
        N'قيام الفني/عوض بسيوني اسماعيل يوم18/1/2026 بتوقيع حضور وانصراف وترك العمل الساعه8:15',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'عوض بسيوني اسماعيل',
        '2026-02-03 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: عوض بسيوني اسماعيل
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'عوض بسيوني اسماعيل';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%عوض بسيوني اسماعيل%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'عوض بسيوني اسماعيل', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'40',
        '2026-02-01',
        '2026-02-01',
        N'ب',
        N'غاده شكري',
        N'غياب السيد/ احمد عبدالفتاح دياب عن نوباتجيه غرفة عمليات المحتفظه ايام9,16,22/1/2026',
        '2026-01-22',
        N'غرفة عمليات المحتفظه ايام9',
        N'غياب السيد/ احمد عبدالفتاح دياب عن نوباتجيه غرفة عمليات المحتفظه ايام9,16,22/1/2026',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'احمد عبدالفتاح دياب',
        '2026-02-01 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: احمد عبدالفتاح دياب
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'احمد عبدالفتاح دياب';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%احمد عبدالفتاح دياب%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'احمد عبدالفتاح دياب', N'موظف', N'غرفة عمليات المحتفظه ايام9', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-02-17', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض علي ر.م.ا 17/2/2026 | ورد من ر.م.أ 22/2/2026', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'41',
        '2026-02-01',
        '2026-02-01',
        N'ب',
        N'غاده شكري',
        N'مرور الامن يوم الاحد 18/1/2026 اثناء النوه تلاحظ غياب 1-رياض منصور رياض 2-حسن فوزي ابراهيم 3-احمد رمضان سليمان 4-خالد عبدالحميد عبدالنبي 5-ايمن سامي حامد 6-ربيع محمد علي محمد محطة زكريا جودة يوم 18/1/2026 الساعه1:5ص',
        '2026-01-18',
        N'محطة زكريا جودة',
        N'مرور الامن يوم الاحد 18/1/2026 اثناء النوه تلاحظ غياب 1-رياض منصور رياض 2-حسن فوزي ابراهيم 3-احمد رمضان سليمان 4-خالد عبدالحميد عبدالنبي 5-ايمن سامي حامد 6-ربيع محمد علي محمد محطة زكريا جودة يوم 18/1/2026 الساعه1:5ص',
        N'صدر قرار',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'رياض منصور رياض, حسن فوزي ابراهيم, احمد رمضان سليمان, خالد عبدالحميد عبدالنبي, ايمن سامي حامد, ربيع محمد علي محمد محطة زكريا جودة',
        '2026-02-01 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: رياض منصور رياض
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'رياض منصور رياض';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%رياض منصور رياض%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'رياض منصور رياض', N'موظف', N'محطة زكريا جودة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: حسن فوزي ابراهيم
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'حسن فوزي ابراهيم';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%حسن فوزي ابراهيم%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'حسن فوزي ابراهيم', N'موظف', N'محطة زكريا جودة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: احمد رمضان سليمان
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'احمد رمضان سليمان';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%احمد رمضان سليمان%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'احمد رمضان سليمان', N'موظف', N'محطة زكريا جودة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: خالد عبدالحميد عبدالنبي
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'خالد عبدالحميد عبدالنبي';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%خالد عبدالحميد عبدالنبي%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'خالد عبدالحميد عبدالنبي', N'موظف', N'محطة زكريا جودة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: ايمن سامي حامد
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'ايمن سامي حامد';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%ايمن سامي حامد%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'ايمن سامي حامد', N'موظف', N'محطة زكريا جودة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: ربيع محمد علي محمد محطة زكريا جودة
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'ربيع محمد علي محمد محطة زكريا جودة';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%ربيع محمد علي محمد محطة زكريا جودة%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'ربيع محمد علي محمد محطة زكريا جودة', N'موظف', N'محطة زكريا جودة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-03-05', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض علي ر.م.ا 5/3/2026 |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'42',
        '2026-02-02',
        '2026-02-02',
        N'ب',
        N'طارق السيد',
        N'المرور على محطة معالجة الهانوفيل يوم الجمعه 16/1/2026 الساعه11:30م تلاحظ غياب كلا من اثناء النوه 1-ابراهيم بخيت احمد 2-اسامه هاني علي 3-محمد حمدي وهبه 4-رجب السيد ابراهيم',
        '2026-01-16',
        N'محطة معالجة الهانوفيل',
        N'المرور على محطة معالجة الهانوفيل يوم الجمعه 16/1/2026 الساعه11:30م تلاحظ غياب كلا من اثناء النوه 1-ابراهيم بخيت احمد 2-اسامه هاني علي 3-محمد حمدي وهبه 4-رجب السيد ابراهيم',
        N'جارية',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'ابراهيم بخيت احمد, اسامه هاني علي, محمد حمدي وهبه, رجب السيد ابراهيم',
        '2026-02-02 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: ابراهيم بخيت احمد
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'ابراهيم بخيت احمد';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%ابراهيم بخيت احمد%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'ابراهيم بخيت احمد', N'موظف', N'محطة معالجة الهانوفيل', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: اسامه هاني علي
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'اسامه هاني علي';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%اسامه هاني علي%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'اسامه هاني علي', N'موظف', N'محطة معالجة الهانوفيل', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: محمد حمدي وهبه
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمد حمدي وهبه';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمد حمدي وهبه%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمد حمدي وهبه', N'موظف', N'محطة معالجة الهانوفيل', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: رجب السيد ابراهيم
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'رجب السيد ابراهيم';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%رجب السيد ابراهيم%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'رجب السيد ابراهيم', N'موظف', N'محطة معالجة الهانوفيل', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'43',
        '2026-02-18',
        '2026-02-18',
        N'ب',
        N'هدى رجب',
        N'غياب السيد احمد سمير فرغلى كود 8209 عن نوباتجية غرفة العامليات المحافظة يومى 25،31/1/2026 من الساعة 8ص الى 8م',
        '2026-01-31',
        N'ديوان عام الشركة',
        N'غياب السيد احمد سمير فرغلى كود 8209 عن نوباتجية غرفة العامليات المحافظة يومى 25،31/1/2026 من الساعة 8ص الى 8م',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'احمد سمير فرغلى كود 8209',
        '2026-02-18 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: احمد سمير فرغلى كود 8209
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE Code = N'8209';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'احمد سمير فرغلى كود 8209';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%احمد سمير فرغلى كود 8209%';
    IF @EmpMasterId IS NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM EmployeesMaster WHERE Code = N'8209')
            SET @NewCode = N'8209';
        ELSE
            SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'احمد سمير فرغلى كود 8209', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-05-06', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض علي ر.م.ا 6/5/2026 |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'44',
        '2026-02-09',
        '2026-02-09',
        N'ب',
        N'نورة عباس',
        N'شكوى من بعض العاملين ضد السيد حمدى عبد الحليم اعتراضا منهم على تولية منص مدير الشؤن الادارية',
        '2026-02-09',
        N'ديوان عام الشركة',
        N'شكوى من بعض العاملين ضد السيد حمدى عبد الحليم اعتراضا منهم على تولية منص مدير الشؤن الادارية',
        N'جارية',
        NULL,
        N'بعض العاملين',
        N'السيد حمدى عبد الحليم اعتراضا منهم على تولية منص مدير الشؤن الادارية',
        '2026-02-09 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: حمدى عبد الحليم اعتراضا منهم على تولية منص مدير الشؤن الادارية
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'حمدى عبد الحليم اعتراضا منهم على تولية منص مدير الشؤن الادارية';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%حمدى عبد الحليم اعتراضا منهم على تولية منص مدير الشؤن الادارية%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'حمدى عبد الحليم اعتراضا منهم على تولية منص مدير الشؤن الادارية', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'45',
        '2026-02-09',
        '2026-02-09',
        N'ب',
        N'تامر الحداد',
        N'المرور على محطة رفع5 العجمي تلاحظ عدم تواجد السيد/عمرو محمد رياض كود(9088) مدون اسمه في دفتر الحضور والانصراف وهو لا يوجد لديه اجازات يومي 27,26/1/2026',
        '2026-01-26',
        N'محطة رفع5 العجمي',
        N'المرور على محطة رفع5 العجمي تلاحظ عدم تواجد السيد/عمرو محمد رياض كود(9088) مدون اسمه في دفتر الحضور والانصراف وهو لا يوجد لديه اجازات يومي 27,26/1/2026',
        N'جارية',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'موظف محال للتحقيق',
        '2026-02-09 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'محطة رفع5 العجمي', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'46',
        '2026-02-09',
        '2026-02-09',
        N'ب',
        N'حنان الخشاب',
        N'المرور على محطة رفع11بمنطقة شرق يوم28/1/2026الساعه 9:30م تلاحظ عدم تواجد كلا من الفني/ عصام جمعه حجازي والفني/عماد عبدالغفار',
        '2026-01-28',
        N'محطة رفع11بمنطقة شرق',
        N'المرور على محطة رفع11بمنطقة شرق يوم28/1/2026الساعه 9:30م تلاحظ عدم تواجد كلا من الفني/ عصام جمعه حجازي والفني/عماد عبدالغفار',
        N'صدر قرار',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'عصام جمعه حجازي والفني',
        '2026-02-09 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: عصام جمعه حجازي والفني
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'عصام جمعه حجازي والفني';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%عصام جمعه حجازي والفني%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'عصام جمعه حجازي والفني', N'موظف', N'محطة رفع11بمنطقة شرق', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-04-21', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض علي ر.م.ا 21/4/2026 |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'47',
        '2026-02-08',
        '2026-02-08',
        N'ب',
        N'شعبان السيد',
        N'المرور اثناء النوه على محطات الشركة يوم28/1/2026 اثناء النوه تلاحظ غياب كلا من 1-حسين محمد عبده (محطة معالجة الهانوفيل) 2-اسلام محمد علي (باب18جمرك) 3-علي البدري الدندراوي (باب 18جمرك) 4-رجب السيد ابراهيم (معالجة الهانوفيل) 5-بهاء بدر (معالجة الها...',
        '2026-01-28',
        N'محطة معالجة الهانوفيل) 2',
        N'المرور اثناء النوه على محطات الشركة يوم28/1/2026 اثناء النوه تلاحظ غياب كلا من 1-حسين محمد عبده (محطة معالجة الهانوفيل) 2-اسلام محمد علي (باب18جمرك) 3-علي البدري الدندراوي (باب 18جمرك) 4-رجب السيد ابراهيم (معالجة الهانوفيل) 5-بهاء بدر (معالجة الهانوفيل) 6-يوسف مروان يوسف(معالجة الهانوفيل) 7-محمد ابراهيم حسن(المراغي منتزه اول) ويلاحظ عدم تواجد احد من العاملين على البداليه اثناء التمركز',
        N'جارية',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'كلا من 1',
        '2026-02-08 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: حسين محمد عبده (محطة معالجة الهانوفيل)
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'حسين محمد عبده (محطة معالجة الهانوفيل)';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%حسين محمد عبده (محطة معالجة الهانوفيل)%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'حسين محمد عبده (محطة معالجة الهانوفيل)', N'موظف', N'محطة معالجة الهانوفيل) 2', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: رجب السيد ابراهيم (معالجة الهانوفيل)
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'رجب السيد ابراهيم (معالجة الهانوفيل)';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%رجب السيد ابراهيم (معالجة الهانوفيل)%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'رجب السيد ابراهيم (معالجة الهانوفيل)', N'موظف', N'محطة معالجة الهانوفيل) 2', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: بهاء بدر (معالجة الهانوفيل)
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'بهاء بدر (معالجة الهانوفيل)';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%بهاء بدر (معالجة الهانوفيل)%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'بهاء بدر (معالجة الهانوفيل)', N'موظف', N'محطة معالجة الهانوفيل) 2', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'48',
        '2026-02-09',
        '2026-02-09',
        N'ب',
        N'ايناس جلال',
        N'غياب المندوبين المكلفين للعمل بنوباتجية غرفة العاملات داخل مركز سطره الشبكه الوطنيه وهما السيد/احمد عبدالفتاح دياب في ايام 6,8,15,16,30/1/2026 وردية ليلية والسيد/ احمد سمير فرغلي في ايام 25,31,21/1/2026 الوردية الصباحيه',
        '2026-01-30',
        N'ديوان عام الشركة',
        N'غياب المندوبين المكلفين للعمل بنوباتجية غرفة العاملات داخل مركز سطره الشبكه الوطنيه وهما السيد/احمد عبدالفتاح دياب في ايام 6,8,15,16,30/1/2026 وردية ليلية والسيد/ احمد سمير فرغلي في ايام 25,31,21/1/2026 الوردية الصباحيه',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'المندوبين المكل',
        '2026-02-09 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: المندوبين المكل
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'المندوبين المكل';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%المندوبين المكل%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'المندوبين المكل', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'49',
        '2026-02-08',
        '2026-02-08',
        N'ب',
        N'ايمن توفيق',
        N'المرور على محطة محرم بك وسط تلاحظ عدم تواجد العامل/محمد جمال محروس الساعه11ص , وبالمرور على محطة رفع الهجانه الساعه11:10ص العامرية تلاحظ عدم تواجد كلا من 1-محمد عاشور عبدالحميد 2-احمد عاشور عبدالحميد بدون مامورية تؤيد ذلك في الدفتر وبالمرور على مح...',
        '2026-02-08',
        N'محطة محرم بك وسط',
        N'المرور على محطة محرم بك وسط تلاحظ عدم تواجد العامل/محمد جمال محروس الساعه11ص , وبالمرور على محطة رفع الهجانه الساعه11:10ص العامرية تلاحظ عدم تواجد كلا من 1-محمد عاشور عبدالحميد 2-احمد عاشور عبدالحميد بدون مامورية تؤيد ذلك في الدفتر وبالمرور على محطة رفع السنان الساعه5:40م الجمرك مغلقة بالقفل والجنزير وعدم تواجد ايا من العاملين, وبالمرور على منطقة منتزه ثان الساعه2:40ص يلاحظ عدم تواجد مراقب او ملاحظ بالوردية الثالثه , وبالمرور على محطة رفع(5) منتزه اول الساعه 1ص يلاحظ عدم تواجد ايا من العاملين وقت المرور وتعذر الاطلاع على سجل الحضور والانصراف',
        N'جارية',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'محمد جمال محروس الساعه11ص',
        '2026-02-08 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: محمد عاشور عبدالحميد
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمد عاشور عبدالحميد';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمد عاشور عبدالحميد%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمد عاشور عبدالحميد', N'موظف', N'محطة محرم بك وسط', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: احمد عاشور عبدالحميد بدون مامورية تؤيد ذلك في الدفتر وبالمرور على محطة رفع السنان الساعه
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'احمد عاشور عبدالحميد بدون مامورية تؤيد ذلك في الدفتر وبالمرور على محطة رفع السنان الساعه';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%احمد عاشور عبدالحميد بدون مامورية تؤيد ذلك في الدفتر وبالمرور على محطة رفع السنان الساعه%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'احمد عاشور عبدالحميد بدون مامورية تؤيد ذلك في الدفتر وبالمرور على محطة رفع السنان الساعه', N'موظف', N'محطة محرم بك وسط', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'50',
        '2026-02-09',
        '2026-02-09',
        N'ب',
        N'صباح رمضان',
        N'المرور على بنزينه التنقيه الشرقية اثناء النوه الساعه9:30م يلاحظ ان العاملين بالبنزينه يعملون يوم واليوم التالي تم شد خط دون تدوين اي شيئ ان جميع العاملين في البنزينه وعددهم 6افراد- الوردية الصباحيه 1-احمد كمال 2-السيد محمد اسماعيل , الوردية المسائ...',
        '2026-02-09',
        N'بنزينه التنقيه الشرقية',
        N'المرور على بنزينه التنقيه الشرقية اثناء النوه الساعه9:30م يلاحظ ان العاملين بالبنزينه يعملون يوم واليوم التالي تم شد خط دون تدوين اي شيئ ان جميع العاملين في البنزينه وعددهم 6افراد- الوردية الصباحيه 1-احمد كمال 2-السيد محمد اسماعيل , الوردية المسائية : 1-محمد سمير عبدالنبي 2-عاطف محمد يوسف , الوردية : 1-احمد عبدالرازق حسن 2-مصطفى محمد ويقوموا بالعمل لمدة 15يوم فقط طول الشهر ويتم شطب امام اسمائهم والنصف الاخر من الشهر دون تقدير اجازات',
        N'صدر قرار',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'ين بالبنزينه ي',
        '2026-02-09 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: احمد كمال
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'احمد كمال';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%احمد كمال%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'احمد كمال', N'موظف', N'بنزينه التنقيه الشرقية', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: محمد اسماعيل
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمد اسماعيل';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمد اسماعيل%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمد اسماعيل', N'موظف', N'بنزينه التنقيه الشرقية', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: محمد سمير عبدالنبي
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمد سمير عبدالنبي';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمد سمير عبدالنبي%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمد سمير عبدالنبي', N'موظف', N'بنزينه التنقيه الشرقية', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: عاطف محمد يوسف
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'عاطف محمد يوسف';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%عاطف محمد يوسف%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'عاطف محمد يوسف', N'موظف', N'بنزينه التنقيه الشرقية', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: احمد عبدالرازق حسن
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'احمد عبدالرازق حسن';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%احمد عبدالرازق حسن%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'احمد عبدالرازق حسن', N'موظف', N'بنزينه التنقيه الشرقية', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-03-03', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 3/3/2026 | ورد من ر.م.أ 4/3/2026', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'51',
        '2026-02-11',
        '2026-02-11',
        N'ب',
        N'مروة مصطفى',
        N'ترك عمل يوم الاثنين الموافق 2/2/2026 بمحطة نشأت بالوردية الليلية السيد/محمد عادل عبد الكريم',
        '2026-02-02',
        N'بمحطة نشأت بالوردية الليلية السيد',
        N'ترك عمل يوم الاثنين الموافق 2/2/2026 بمحطة نشأت بالوردية الليلية السيد/محمد عادل عبد الكريم',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'موظف محال للتحقيق',
        '2026-02-11 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'بمحطة نشأت بالوردية الليلية السيد', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-04-12', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 12/4/2026 | ورد من ر.م.أ 14/4/2026', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'52',
        '2026-02-11',
        '2026-02-11',
        N'ب',
        N'ريهام شفيق',
        N'غياب وترك عمل كلا من 1- جميل ربيع عبد المولى بتاريخ 3/2/2026 الساعة 2:30م محطة 11 شرق 2- عاطف حسين محمود بتاريخ 3/2/2026 الساعة 2:30م محطة 11 شرق',
        '2026-02-03',
        N'محطة 11 شرق 2',
        N'غياب وترك عمل كلا من 1- جميل ربيع عبد المولى بتاريخ 3/2/2026 الساعة 2:30م محطة 11 شرق 2- عاطف حسين محمود بتاريخ 3/2/2026 الساعة 2:30م محطة 11 شرق',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'وترك',
        '2026-02-11 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: جميل ربيع عبد المولى
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'جميل ربيع عبد المولى';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%جميل ربيع عبد المولى%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'جميل ربيع عبد المولى', N'موظف', N'محطة 11 شرق 2', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: عاطف حسين محمود
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'عاطف حسين محمود';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%عاطف حسين محمود%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'عاطف حسين محمود', N'موظف', N'محطة 11 شرق 2', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-03-29', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 29/3/2026 |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'53',
        '2026-02-18',
        '2026-02-18',
        N'ب',
        N'هدى رجب',
        N'العامل/ايمن محمد مصطفى يعمل بمحطة 5 لقد قام بالتوقيع فى سجل الحضور والانصراف الساعة 11 م حتى الساعة7ص واثناء المرور الساعة 1:30ص تلاحظ انة غير متواجد رغم توقيعة بالسجل يوم 29/1/2026',
        '2026-01-29',
        N'بمحطة 5 لقد قام بالتوقيع فى',
        N'العامل/ايمن محمد مصطفى يعمل بمحطة 5 لقد قام بالتوقيع فى سجل الحضور والانصراف الساعة 11 م حتى الساعة7ص واثناء المرور الساعة 1:30ص تلاحظ انة غير متواجد رغم توقيعة بالسجل يوم 29/1/2026',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'ايمن محمد مصط',
        '2026-02-18 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: ايمن محمد مصط
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'ايمن محمد مصط';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%ايمن محمد مصط%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'ايمن محمد مصط', N'موظف', N'بمحطة 5 لقد قام بالتوقيع فى', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-05-11', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 11/5/2026 |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'54',
        '2026-02-18',
        '2026-02-18',
        N'ب',
        N'ريهام شفيق',
        N'ترك عمل السيد /حسين محمد عبدة يوم الخميس 29/1/2026 بالوردية المسائية دون ابلاغ احد فى حوالى الساعة 2:15ص',
        '2026-01-29',
        N'ديوان عام الشركة',
        N'ترك عمل السيد /حسين محمد عبدة يوم الخميس 29/1/2026 بالوردية المسائية دون ابلاغ احد فى حوالى الساعة 2:15ص',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'موظف محال للتحقيق',
        '2026-02-18 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-03-31', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 31/3/2026 | ورد من ر.م.أ 5/4/2026', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'55',
        '2026-02-24',
        '2026-02-24',
        N'ب',
        N'نورة عباس',
        N'مرور الامن على عدة محطات ووجدها مغلقة وهى: 1- محطة ابيس 8/8 وسط الساعة 8:35م 2- محطة ابوزيد وسط يوم 5/2/2026 الساعة 5:30م 3- محطة اباظة العامرية يوم 6/2/2026 الساعة 6:45م 4- محطة 5 العجمى يوم 6/2/2026 الساعة 8:50م',
        '2026-02-05',
        N'محطة ابيس 8',
        N'مرور الامن على عدة محطات ووجدها مغلقة وهى: 1- محطة ابيس 8/8 وسط الساعة 8:35م 2- محطة ابوزيد وسط يوم 5/2/2026 الساعة 5:30م 3- محطة اباظة العامرية يوم 6/2/2026 الساعة 6:45م 4- محطة 5 العجمى يوم 6/2/2026 الساعة 8:50م',
        N'جارية',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'محطة ابوزيد وسط, محطة اباظة العامرية',
        '2026-02-24 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: محطة ابوزيد وسط
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محطة ابوزيد وسط';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محطة ابوزيد وسط%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محطة ابوزيد وسط', N'موظف', N'محطة ابيس 8', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: محطة اباظة العامرية
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محطة اباظة العامرية';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محطة اباظة العامرية%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محطة اباظة العامرية', N'موظف', N'محطة ابيس 8', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'56',
        '2026-02-18',
        '2026-02-18',
        N'ب',
        N'خالد احمد',
        N'غياب كلا من 1- بيومى محمود محمد يومى 26،15/1/2026 2- محمود عبد الحميد شفيق يومى 21،17/1/2026 وهما يبدلا راحتهم دون إذن مسبق',
        '2026-01-15',
        N'ديوان عام الشركة',
        N'غياب كلا من 1- بيومى محمود محمد يومى 26،15/1/2026 2- محمود عبد الحميد شفيق يومى 21،17/1/2026 وهما يبدلا راحتهم دون إذن مسبق',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'كلا من 1',
        '2026-02-18 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: محمود عبد الحميد شفيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمود عبد الحميد شفيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمود عبد الحميد شفيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمود عبد الحميد شفيق', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'57',
        '2026-02-11',
        '2026-02-11',
        N'ب',
        N'شعبان السيد',
        N'ترك عمل كلامن 1- احمد جابر ابو غزالة 2- محمد عادل عبد الكريم لارتكابهم مخالفات وتعريض المحطات لمخاطر السرقة او الغرق او الاتلاف',
        '2026-02-11',
        N'ديوان عام الشركة',
        N'ترك عمل كلامن 1- احمد جابر ابو غزالة 2- محمد عادل عبد الكريم لارتكابهم مخالفات وتعريض المحطات لمخاطر السرقة او الغرق او الاتلاف',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'كلامن 1',
        '2026-02-11 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: احمد جابر ابو غزالة
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'احمد جابر ابو غزالة';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%احمد جابر ابو غزالة%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'احمد جابر ابو غزالة', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: محمد عادل عبد الكريم لارتكابهم مخالفات وتعريض المحطات لمخاطر السرقة او الغرق او الاتلاف
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمد عادل عبد الكريم لارتكابهم مخالفات وتعريض المحطات لمخاطر السرقة او الغرق او الاتلاف';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمد عادل عبد الكريم لارتكابهم مخالفات وتعريض المحطات لمخاطر السرقة او الغرق او الاتلاف%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمد عادل عبد الكريم لارتكابهم مخالفات وتعريض المحطات لمخاطر السرقة او الغرق او الاتلاف', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'58',
        '2026-02-16',
        '2026-02-16',
        N'ب',
        N'ايمن توفيق',
        N'مرور الادارة العامة للمراجعة والتفتيش يوم السبت الموافق 27/2/2026 تلاحظ وجود بعض الملاحظات بكلا من 1- محطة اسكان طوسون 2- محطة رفع نوبار 3- محطة اسكان حجر النواتية',
        '2026-02-27',
        N'محطة اسكان طوسون 2',
        N'مرور الادارة العامة للمراجعة والتفتيش يوم السبت الموافق 27/2/2026 تلاحظ وجود بعض الملاحظات بكلا من 1- محطة اسكان طوسون 2- محطة رفع نوبار 3- محطة اسكان حجر النواتية',
        N'جارية',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'محطة اسكان طوسون, محطة رفع نوبار, محطة اسكان حجر النواتية',
        '2026-02-16 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: محطة اسكان طوسون
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محطة اسكان طوسون';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محطة اسكان طوسون%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محطة اسكان طوسون', N'موظف', N'محطة اسكان طوسون 2', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: محطة رفع نوبار
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محطة رفع نوبار';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محطة رفع نوبار%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محطة رفع نوبار', N'موظف', N'محطة اسكان طوسون 2', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: محطة اسكان حجر النواتية
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محطة اسكان حجر النواتية';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محطة اسكان حجر النواتية%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محطة اسكان حجر النواتية', N'موظف', N'محطة اسكان طوسون 2', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'59',
        '2026-02-26',
        '2026-02-26',
        N'ب',
        N'هانى احمد',
        N'ترك عمل الفنى / محمد ماهر حمدالله كود 7687 يوم 7/2/2026 الساعة 5:30 م',
        '2026-02-07',
        N'ديوان عام الشركة',
        N'ترك عمل الفنى / محمد ماهر حمدالله كود 7687 يوم 7/2/2026 الساعة 5:30 م',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'محمد ماهر حمدالله كود 7687',
        '2026-02-26 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: محمد ماهر حمدالله كود 7687
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE Code = N'7687';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمد ماهر حمدالله كود 7687';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمد ماهر حمدالله كود 7687%';
    IF @EmpMasterId IS NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM EmployeesMaster WHERE Code = N'7687')
            SET @NewCode = N'7687';
        ELSE
            SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمد ماهر حمدالله كود 7687', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-06-01', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 1/6/2026 |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'60',
        '2026-02-17',
        '2026-02-17',
        N'ب',
        N'وفاء رمزي',
        N'غياب الفنى / مصطفى السيد عمر ابراهيم كود 7603 عن العمل يومى 7،8/2/2026 الساعة 1:30 منطقة العامرية',
        '2026-02-08',
        N'منطقة العامرية',
        N'غياب الفنى / مصطفى السيد عمر ابراهيم كود 7603 عن العمل يومى 7،8/2/2026 الساعة 1:30 منطقة العامرية',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'مصط',
        '2026-02-17 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: مصط
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE Code = N'7603';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'مصط';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%مصط%';
    IF @EmpMasterId IS NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM EmployeesMaster WHERE Code = N'7603')
            SET @NewCode = N'7603';
        ELSE
            SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'مصط', N'موظف', N'منطقة العامرية', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'61',
        '2026-02-17',
        '2026-02-17',
        N'ب',
        N'شعبان السيد',
        N'غياب العامل محمد مجدى عبدالله على منطقة العجمى ايام 28،29/1/2026 علما بان 28/1/2026 كان نوة',
        '2026-01-29',
        N'منطقة العجمى ايام 28،29',
        N'غياب العامل محمد مجدى عبدالله على منطقة العجمى ايام 28،29/1/2026 علما بان 28/1/2026 كان نوة',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'العامل محمد مجدى عبدالله على',
        '2026-02-17 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: محمد مجدى عبدالله على
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمد مجدى عبدالله على';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمد مجدى عبدالله على%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمد مجدى عبدالله على', N'موظف', N'منطقة العجمى ايام 28،29', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'62',
        '2026-02-26',
        '2026-02-26',
        N'ب',
        N'وفاء رمزي',
        N'غياب السيد/ اسلام يسرى عبدالمنعم ابراهيم دياب من الفترة من 1/2/2026 حتى 7/2/2026 فى منطقة العجمى',
        '2026-02-01',
        N'منطقة العجمى',
        N'غياب السيد/ اسلام يسرى عبدالمنعم ابراهيم دياب من الفترة من 1/2/2026 حتى 7/2/2026 فى منطقة العجمى',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'اسلام يسرى عبدالمنعم ابراهيم دياب',
        '2026-02-26 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: اسلام يسرى عبدالمنعم ابراهيم دياب
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'اسلام يسرى عبدالمنعم ابراهيم دياب';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%اسلام يسرى عبدالمنعم ابراهيم دياب%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'اسلام يسرى عبدالمنعم ابراهيم دياب', N'موظف', N'منطقة العجمى', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-03-29', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 29/3/2026 | ورد من ر.م.أ 3/4/2026', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'63',
        '2026-03-02',
        '2026-03-02',
        N'ب',
        N'مروة مصطفى',
        N'المرور على محطة 1 خورشيد القبلية شرق يوم 10/2/2026 الساعة 3:30ص تعين وجود المحطة مغلقة ولايتواجد بها احد من العاملين وتم ابلاغ الخط الساخن',
        '2026-02-10',
        N'محطة 1 خورشيد القبلية شرق',
        N'المرور على محطة 1 خورشيد القبلية شرق يوم 10/2/2026 الساعة 3:30ص تعين وجود المحطة مغلقة ولايتواجد بها احد من العاملين وتم ابلاغ الخط الساخن',
        N'صدر قرار',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'ين وتم ابلاغ الخط الساخن',
        '2026-03-02 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: ين وتم ابلاغ الخط الساخن
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'ين وتم ابلاغ الخط الساخن';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%ين وتم ابلاغ الخط الساخن%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'ين وتم ابلاغ الخط الساخن', N'موظف', N'محطة 1 خورشيد القبلية شرق', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-04-16', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 16/4/2026 | ورد من ر.م.أ 22/4/2026', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'64',
        '2026-02-26',
        '2026-02-26',
        N'ب',
        N'هانى احمد',
        N'المرور عاى محطة حملة وصيانة طلعت مصطفى بمنطقة العجمى يوم 30/2/2026 الساعة 1:40 الوردية الليلية توجد مراقب الصيانة علاء الدين محمود',
        '2026-02-28',
        N'محطة حملة وصيانة طلعت مصطفى بمنطقة',
        N'المرور عاى محطة حملة وصيانة طلعت مصطفى بمنطقة العجمى يوم 30/2/2026 الساعة 1:40 الوردية الليلية توجد مراقب الصيانة علاء الدين محمود',
        N'جارية',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'موظف محال للتحقيق',
        '2026-02-26 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'محطة حملة وصيانة طلعت مصطفى بمنطقة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'65',
        '2026-03-02',
        '2026-03-02',
        N'ب',
        N'حنان الخشاب',
        N'المرور على محطة (ب) منتزة اول محطة صرف امطار يوم الثلاثاء 17/2/2026 الساعة 3:40م',
        '2026-02-17',
        N'محطة (ب) منتزة اول محطة صرف',
        N'المرور على محطة (ب) منتزة اول محطة صرف امطار يوم الثلاثاء 17/2/2026 الساعة 3:40م',
        N'صدر قرار',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'موظف محال للتحقيق',
        '2026-03-02 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'محطة (ب) منتزة اول محطة صرف', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-05-12', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 12/5/2026 |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'66',
        '2026-03-08',
        '2026-03-08',
        N'ب',
        N'طارق السيد',
        N'بمرور الادارة العامة للامن بمنطقة العامرية يوم 21/2/2026 تلاحظ الاتى تواجد العامل ايلام فتحى ثلاث ورادى والعامل محمد احمد مدون امامة بدل راحة وابراهيم السيد اجازة غير موضحة نوعها',
        '2026-02-21',
        N'بمنطقة العامرية',
        N'بمرور الادارة العامة للامن بمنطقة العامرية يوم 21/2/2026 تلاحظ الاتى تواجد العامل ايلام فتحى ثلاث ورادى والعامل محمد احمد مدون امامة بدل راحة وابراهيم السيد اجازة غير موضحة نوعها',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'ايلام فتحى ثلاث ورادى والعامل',
        '2026-03-08 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: ايلام فتحى ثلاث ورادى والعامل
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'ايلام فتحى ثلاث ورادى والعامل';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%ايلام فتحى ثلاث ورادى والعامل%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'ايلام فتحى ثلاث ورادى والعامل', N'موظف', N'بمنطقة العامرية', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-05-13', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 13/5/2026 |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'67',
        '2026-03-03',
        '2026-03-03',
        N'ب',
        N'نرمين قنديل',
        N'بمرور الادارة العامة يوم 24/2/2026 على محطة 5 منتزة اةل تلاحظ تواجد احد من العاملين مع تواجدمن العاملين مع تواجد مندوب المقاول حفظ وعدم التزام الفنى جون ماجد فهمى دون تواجد بديل والفنى محمود عبد الحميد راحتة اسبوعية اثناء التمركز',
        '2026-02-24',
        N'محطة 5 منتزة اةل',
        N'بمرور الادارة العامة يوم 24/2/2026 على محطة 5 منتزة اةل تلاحظ تواجد احد من العاملين مع تواجدمن العاملين مع تواجد مندوب المقاول حفظ وعدم التزام الفنى جون ماجد فهمى دون تواجد بديل والفنى محمود عبد الحميد راحتة اسبوعية اثناء التمركز',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'ين مع تواجدمن العاملين مع',
        '2026-03-03 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: ين مع تواجدمن العاملين مع
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'ين مع تواجدمن العاملين مع';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%ين مع تواجدمن العاملين مع%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'ين مع تواجدمن العاملين مع', N'موظف', N'محطة 5 منتزة اةل', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'68',
        '2026-08-03',
        '2026-08-03',
        N'ب',
        N'مروة مصطفى',
        N'مرور الادارة يوم 22/2/2026 تلاحظ انتظام العامل بمحطة 3-4-6 منتزة اول يوم 23/2/2026 تلاحظ تواجد عامل واحد فقط بمحطة رفع المعالجة',
        '2026-02-22',
        N'بمحطة 3',
        N'مرور الادارة يوم 22/2/2026 تلاحظ انتظام العامل بمحطة 3-4-6 منتزة اول يوم 23/2/2026 تلاحظ تواجد عامل واحد فقط بمحطة رفع المعالجة',
        N'جارية',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'موظف محال للتحقيق',
        '2026-08-03 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'بمحطة 3', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'69',
        '2026-04-03',
        '2026-04-03',
        N'ب',
        N'هدى رجب',
        N'تغيب السيد/ عصام عطوة محمد العامل بمحطة 2 خورشيد منتزة اول يوم 24/2/2026 تمركز',
        '2026-02-24',
        N'بمحطة 2 خورشيد منتزة اول',
        N'تغيب السيد/ عصام عطوة محمد العامل بمحطة 2 خورشيد منتزة اول يوم 24/2/2026 تمركز',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'عصام عطوة محمد العامل',
        '2026-04-03 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: عصام عطوة محمد العامل
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'عصام عطوة محمد العامل';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%عصام عطوة محمد العامل%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'عصام عطوة محمد العامل', N'موظف', N'بمحطة 2 خورشيد منتزة اول', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'70',
        '2026-04-03',
        '2026-04-03',
        N'ب',
        N'غاده شكري',
        N'تغيب السيد/ اسامة وليد حسن اعتبارا من 7/2/2026 وبتاريخ 23/2/2026 وردت مذكرة تفيد عودة المذكور اعتبارا من 16/2/2026',
        '2026-02-07',
        N'ديوان عام الشركة',
        N'تغيب السيد/ اسامة وليد حسن اعتبارا من 7/2/2026 وبتاريخ 23/2/2026 وردت مذكرة تفيد عودة المذكور اعتبارا من 16/2/2026',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'اسامة وليد حسن اعتبارا من',
        '2026-04-03 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: اسامة وليد حسن اعتبارا من
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'اسامة وليد حسن اعتبارا من';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%اسامة وليد حسن اعتبارا من%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'اسامة وليد حسن اعتبارا من', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-03-05', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 5/3/2026 | ورد من ر.م.أ 10/3/2026', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'71',
        '2026-05-03',
        '2026-05-03',
        N'ب',
        N'وفاء رمزي',
        N'غياب العامل / حسام محمد السعيد كود 10401 حيث تغيب عن العمل اثناء التمركز يوم 22/2/2026',
        '2026-02-22',
        N'ديوان عام الشركة',
        N'غياب العامل / حسام محمد السعيد كود 10401 حيث تغيب عن العمل اثناء التمركز يوم 22/2/2026',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'حسام محمد السعيد كود 10401',
        '2026-05-03 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: حسام محمد السعيد كود 10401
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE Code = N'10401';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'حسام محمد السعيد كود 10401';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%حسام محمد السعيد كود 10401%';
    IF @EmpMasterId IS NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM EmployeesMaster WHERE Code = N'10401')
            SET @NewCode = N'10401';
        ELSE
            SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'حسام محمد السعيد كود 10401', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-06-02', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 2/6/2026 |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'72',
        '2026-03-04',
        NULL,
        N'ب',
        N'طارق السيد',
        N'بمرور الامن يوم 4/3/2026 بمحطة رفع تلاحظ ان خالد ابراهيم حسن اجازة برج العرب وغريب محمود غريب حتى 8/4/2026 وابراهيم ابو زيد ترك عمل 12:30',
        '2026-03-04',
        N'بمحطة رفع',
        N'بمرور الامن يوم 4/3/2026 بمحطة رفع تلاحظ ان خالد ابراهيم حسن اجازة برج العرب وغريب محمود غريب حتى 8/4/2026 وابراهيم ابو زيد ترك عمل 12:30',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'موظف محال للتحقيق',
        '2026-03-04 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'بمحطة رفع', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'73',
        '2026-11-03',
        '2026-11-03',
        N'ب',
        N'ريهام شفيق',
        N'بمرور الامن يومى 1،2/3/2026 بالوردية المسائية تلاحظ الاتى غياب محمد عبد المنعم وخالد يوسف ومحمد عبد الراضى وعد انتظام العمل داخل محطة',
        '2026-03-02',
        N'ديوان عام الشركة',
        N'بمرور الامن يومى 1،2/3/2026 بالوردية المسائية تلاحظ الاتى غياب محمد عبد المنعم وخالد يوسف ومحمد عبد الراضى وعد انتظام العمل داخل محطة',
        N'مغلقة',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'محمد عبد المنعم وخالد يوسف',
        '2026-11-03 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: محمد عبد المنعم وخالد يوسف
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمد عبد المنعم وخالد يوسف';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمد عبد المنعم وخالد يوسف%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمد عبد المنعم وخالد يوسف', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-04-08', N'رئيس مجلس الإدارة', N'حفظ التحقيق', N'حفظ التحقيق', N'عرض على ر.م.أ 8/4/2026 | تم الانتهاء بمجازات محمد عبد المعم وخالد يوسف ومحمد عبد الراضى بخصم ارعة ايام وحفظ التحقيق للباقى', GETDATE());
    INSERT INTO FinalDecisions (InvestigationId, FinalDecisionText, ActionType, HRSentDate, HRNotes, CreatedAt)
    VALUES (@InvId, N'تم الانتهاء  بمجازات محمد عبد المعم وخالد يوسف ومحمد عبد الراضى بخصم  ارعة ايام وحفظ التحقيق للباقى', 'archive', '2026-04-08', N'عرض على ر.م.أ 8/4/2026 | تم الانتهاء بمجازات محمد عبد المعم وخالد يوسف ومحمد عبد الراضى بخصم ارعة ايام وحفظ التحقيق للباقى', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'74',
        '2026-11-03',
        '2026-11-03',
        N'ب',
        N'صباح رمضان',
        N'بمرور الامن على محطة طلعت مصطفى العجمى يوم ترك عمل حارس الامن عمرو مجدى',
        '2026-11-03',
        N'محطة طلعت مصطفى العجمى',
        N'بمرور الامن على محطة طلعت مصطفى العجمى يوم ترك عمل حارس الامن عمرو مجدى',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'حارس الامن عمرو مجدى',
        '2026-11-03 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: عمرو مجدى
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'عمرو مجدى';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%عمرو مجدى%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'عمرو مجدى', N'موظف', N'محطة طلعت مصطفى العجمى', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-05-14', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 14/5/2026 |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'75',
        '2026-03-30',
        '2026-03-30',
        N'ب',
        N'نورة عباس',
        N'غياب السيد/شحاتة على بالوردية الثانية من 3م الى 11م يوم 6/3/2026',
        '2026-03-06',
        N'ديوان عام الشركة',
        N'غياب السيد/شحاتة على بالوردية الثانية من 3م الى 11م يوم 6/3/2026',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'شحاتة على بالوردية الثانية من',
        '2026-03-30 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: شحاتة على بالوردية الثانية من
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'شحاتة على بالوردية الثانية من';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%شحاتة على بالوردية الثانية من%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'شحاتة على بالوردية الثانية من', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-04-21', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 21/4/2026 | ورد من ر.م.أ 22/4/2026', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'76',
        '2026-03-30',
        '2026-03-30',
        N'ب',
        N'نيرمين قنديل',
        N'غياب السيد/ عوض بسيوني اسماعيل من 3/3/2026 الى 6/3/2026',
        '2026-03-03',
        N'ديوان عام الشركة',
        N'غياب السيد/ عوض بسيوني اسماعيل من 3/3/2026 الى 6/3/2026',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'عوض بسيوني اسماعيل من 3',
        '2026-03-30 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: عوض بسيوني اسماعيل من 3
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'عوض بسيوني اسماعيل من 3';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%عوض بسيوني اسماعيل من 3%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'عوض بسيوني اسماعيل من 3', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'77',
        '2026-03-30',
        '2026-03-30',
        N'ب',
        N'نورة عباس',
        N'غياب السيد/ حسن سلطان حسن مهران يوم 2/3/2026 منطقة العجمى اثناء التمركزات',
        '2026-03-02',
        N'منطقة العجمى',
        N'غياب السيد/ حسن سلطان حسن مهران يوم 2/3/2026 منطقة العجمى اثناء التمركزات',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'حسن سلطان حسن مهران',
        '2026-03-30 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: حسن سلطان حسن مهران
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'حسن سلطان حسن مهران';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%حسن سلطان حسن مهران%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'حسن سلطان حسن مهران', N'موظف', N'منطقة العجمى', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-05-10', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 10/5/2026 |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'78',
        '2026-03-30',
        '2026-03-30',
        N'ب',
        N'صباح رمضان',
        N'غياب وترك عمل السيد/ عبد الرحمن صالح حسن ترك يوم 6/3/2026 وغياب 7/3/2026',
        '2026-03-06',
        N'ديوان عام الشركة',
        N'غياب وترك عمل السيد/ عبد الرحمن صالح حسن ترك يوم 6/3/2026 وغياب 7/3/2026',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'وترك',
        '2026-03-30 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: وترك
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'وترك';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%وترك%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'وترك', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'79',
        '2026-03-26',
        '2026-03-26',
        N'ب',
        N'ريهام شفيق',
        N'مرور ادارة الامن يومى 13-15/3/ 2026 اثناء النوة بالوردية المسائية غياب الاتى 1- علاء جمال مرسى 2- فكرى عبد العليم 3- محمد عبد الحميد 4- هانى السيد على 5- محمد عبد النبى 6- نورة احمد نور',
        '2026-12-13',
        N'ادارة الامن',
        N'مرور ادارة الامن يومى 13-15/3/ 2026 اثناء النوة بالوردية المسائية غياب الاتى 1- علاء جمال مرسى 2- فكرى عبد العليم 3- محمد عبد الحميد 4- هانى السيد على 5- محمد عبد النبى 6- نورة احمد نور',
        N'صدر قرار',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'الاتى 1',
        '2026-03-26 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: علاء جمال مرسى
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'علاء جمال مرسى';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%علاء جمال مرسى%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'علاء جمال مرسى', N'موظف', N'ادارة الامن', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: فكرى عبد العليم
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'فكرى عبد العليم';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%فكرى عبد العليم%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'فكرى عبد العليم', N'موظف', N'ادارة الامن', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: محمد عبد الحميد
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمد عبد الحميد';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمد عبد الحميد%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمد عبد الحميد', N'موظف', N'ادارة الامن', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: هانى السيد على
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'هانى السيد على';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%هانى السيد على%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'هانى السيد على', N'موظف', N'ادارة الامن', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: محمد عبد النبى
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمد عبد النبى';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمد عبد النبى%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمد عبد النبى', N'موظف', N'ادارة الامن', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: نورة احمد نور
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'نورة احمد نور';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%نورة احمد نور%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'نورة احمد نور', N'موظف', N'ادارة الامن', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-05-06', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 6/5/2026 |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'80',
        '2026-02-04',
        '2026-02-04',
        N'ب',
        N'هانى احمد',
        N'ترك عمل السيد/ جون ماجد فهمى الفنى بمحطة 4 منتزة اول قد ترك العمل يوم 16/3/2026 بدون اذن',
        '2026-03-16',
        N'بمحطة 4 منتزة اول قد ترك',
        N'ترك عمل السيد/ جون ماجد فهمى الفنى بمحطة 4 منتزة اول قد ترك العمل يوم 16/3/2026 بدون اذن',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'جون ماجد فهمى الفنى',
        '2026-02-04 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: جون ماجد فهمى الفنى
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'جون ماجد فهمى الفنى';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%جون ماجد فهمى الفنى%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'جون ماجد فهمى الفنى', N'موظف', N'بمحطة 4 منتزة اول قد ترك', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'81',
        '2026-03-29',
        '2026-03-29',
        N'ب',
        N'حنان الخشاب',
        N'غياب كلا من 1- محمود محمد 2- محمد احمد 3- احمد رجب علام 4- احمد انور كمال 5- محمد جابر محمد 6- مصطفى السيد خليل',
        '2026-03-29',
        N'ديوان عام الشركة',
        N'غياب كلا من 1- محمود محمد 2- محمد احمد 3- احمد رجب علام 4- احمد انور كمال 5- محمد جابر محمد 6- مصطفى السيد خليل',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'كلا من 1',
        '2026-03-29 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: محمود محمد
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمود محمد';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمود محمد%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمود محمد', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: محمد احمد
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمد احمد';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمد احمد%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمد احمد', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: احمد رجب علام
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'احمد رجب علام';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%احمد رجب علام%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'احمد رجب علام', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: احمد انور كمال
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'احمد انور كمال';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%احمد انور كمال%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'احمد انور كمال', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: محمد جابر محمد
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمد جابر محمد';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمد جابر محمد%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمد جابر محمد', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: مصطفى السيد خليل
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'مصطفى السيد خليل';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%مصطفى السيد خليل%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'مصطفى السيد خليل', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'82',
        '2026-05-04',
        '2026-05-04',
        N'ب',
        N'هدى رجب',
        N'العامل محمود فكرى شحاتة قد تغيب عن العمل يوم الاربعاء 25/3/2026 بدون اذن وذلك اثناء التمركزات والنوة وقد تغيب',
        '2026-03-25',
        N'ديوان عام الشركة',
        N'العامل محمود فكرى شحاتة قد تغيب عن العمل يوم الاربعاء 25/3/2026 بدون اذن وذلك اثناء التمركزات والنوة وقد تغيب',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'محمود فكرى شحاتة قد تغيب',
        '2026-05-04 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: محمود فكرى شحاتة قد تغيب
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمود فكرى شحاتة قد تغيب';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمود فكرى شحاتة قد تغيب%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمود فكرى شحاتة قد تغيب', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'83',
        '2026-01-04',
        '2026-01-04',
        N'ب',
        N'هانى احمد',
        N'العامل صالح على على يوم الخميس 19/3/2026 اثناء النوة نوباتجية عيد الفطر نوباتجية بالبنزينة بمحطة التنقية الشرقية بالوردية الصباحية قام بغلق الحجرة الملحقة بالبنزينة والانصراف دون تسليم',
        '2026-03-19',
        N'بمحطة التنقية الشرقية بالوردية الصباحية قام',
        N'العامل صالح على على يوم الخميس 19/3/2026 اثناء النوة نوباتجية عيد الفطر نوباتجية بالبنزينة بمحطة التنقية الشرقية بالوردية الصباحية قام بغلق الحجرة الملحقة بالبنزينة والانصراف دون تسليم',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'صالح على على',
        '2026-01-04 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: صالح على على
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'صالح على على';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%صالح على على%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'صالح على على', N'موظف', N'بمحطة التنقية الشرقية بالوردية الصباحية قام', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'84',
        '2026-02-04',
        '2026-02-04',
        N'ب',
        N'ريهام شفيق',
        N'الفنى/ محمد السيد عبد العليم قد تغيب عن العمل يوم الاربعاء 18/3/2026 بدون اذن مسبق اثناء النوة والسائق/ احمد عاطف ابراهيم قد تغيب عن العمل يوم 19/3/2026 بدون اذن مسبق',
        '2026-03-18',
        N'ديوان عام الشركة',
        N'الفنى/ محمد السيد عبد العليم قد تغيب عن العمل يوم الاربعاء 18/3/2026 بدون اذن مسبق اثناء النوة والسائق/ احمد عاطف ابراهيم قد تغيب عن العمل يوم 19/3/2026 بدون اذن مسبق',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'محمد السيد عبد العليم قد',
        '2026-02-04 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: محمد السيد عبد العليم قد
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمد السيد عبد العليم قد';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمد السيد عبد العليم قد%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمد السيد عبد العليم قد', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-05-18', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 18/5/2026 |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'85',
        '2026-05-04',
        '2026-05-04',
        N'ب',
        N'وفاء رمزي',
        N'السيد/ ابراهيم ابو زيد ابراهيم الذى يعمل بمحطة مدخل المدينة تغيب عن العمل يومى 22،23/3/2026 بدون اذن مسبق والسيد/احمد شعبان الذى يعمل بمحطة المراجعة الناصرية تغيب يوم 18/3/2026 ويوم 24/3/2026 السيد/ محمود السيد عارف تغيب عن العمل يوم 19/3/2026',
        '2026-03-23',
        N'بمحطة مدخل المدينة تغيب عن العمل',
        N'السيد/ ابراهيم ابو زيد ابراهيم الذى يعمل بمحطة مدخل المدينة تغيب عن العمل يومى 22،23/3/2026 بدون اذن مسبق والسيد/احمد شعبان الذى يعمل بمحطة المراجعة الناصرية تغيب يوم 18/3/2026 ويوم 24/3/2026 السيد/ محمود السيد عارف تغيب عن العمل يوم 19/3/2026',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'موظف محال للتحقيق',
        '2026-05-04 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'بمحطة مدخل المدينة تغيب عن العمل', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'86',
        '2026-03-25',
        NULL,
        N'ب',
        N'طارق السيد',
        N'بشان مرور الادارة العامة للامن على محطات الشركة ايام 18،24،25/3/2026 اثناء النوة بالوردية المسائية تلاحظ غياب كلا من سعد على سعد ومسعود مصطفى السيد و عمرو محمد عبد اللطيف وعصام عطوة محمد ورمضان خميس محمد',
        '2026-03-25',
        N'ادارة العامة للامن على محطات',
        N'بشان مرور الادارة العامة للامن على محطات الشركة ايام 18،24،25/3/2026 اثناء النوة بالوردية المسائية تلاحظ غياب كلا من سعد على سعد ومسعود مصطفى السيد و عمرو محمد عبد اللطيف وعصام عطوة محمد ورمضان خميس محمد',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'سعد على سعد ومسعود مصط',
        '2026-03-25 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: سعد على سعد ومسعود مصط
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'سعد على سعد ومسعود مصط';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%سعد على سعد ومسعود مصط%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'سعد على سعد ومسعود مصط', N'موظف', N'ادارة العامة للامن على محطات', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'87',
        '2026-02-04',
        '2026-02-04',
        N'ب',
        N'غاده شكري',
        N'انقطاع السيد/ السيد مجدى السيد محمد بمنطقة العامرية اعتبارا من 20/2/2026 الى 3/3/2026 وبتاريخ 18/3/2026 وردت مذكرة قيض عودتة يوم 3/3/2026',
        '2026-02-20',
        N'بمنطقة العامرية اعتبارا من 20',
        N'انقطاع السيد/ السيد مجدى السيد محمد بمنطقة العامرية اعتبارا من 20/2/2026 الى 3/3/2026 وبتاريخ 18/3/2026 وردت مذكرة قيض عودتة يوم 3/3/2026',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'السيد مجدى السيد محمد بمنطقة',
        '2026-02-04 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: مجدى السيد محمد بمنطقة
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'مجدى السيد محمد بمنطقة';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%مجدى السيد محمد بمنطقة%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'مجدى السيد محمد بمنطقة', N'موظف', N'بمنطقة العامرية اعتبارا من 20', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-04-07', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 7/4/2026 | ورد من ر.م.أ 14/4/2026', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'88',
        '2026-05-04',
        '2026-05-04',
        N'ب',
        N'صباح رمضان',
        N'العامل/رجب شحاتة محمد غياب عن التمركز اعتبارا من 19/3/2026 حتى 22/3/2026',
        '2026-03-19',
        N'ديوان عام الشركة',
        N'العامل/رجب شحاتة محمد غياب عن التمركز اعتبارا من 19/3/2026 حتى 22/3/2026',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'رجب شحاتة محمد غياب',
        '2026-05-04 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: رجب شحاتة محمد غياب
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'رجب شحاتة محمد غياب';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%رجب شحاتة محمد غياب%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'رجب شحاتة محمد غياب', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-05-05', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 5/5/2026 |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'89',
        '2026-05-04',
        '2026-05-04',
        N'ب',
        N'ايمن توفيق',
        N'بمرور الادارة العامة للامن على محطة السيوف يوم الاربعاء 25/3/2026 اثناء النوة تلاحظ غياب الاتى 1- محمود محمد محمديوم 18-23-24-25/ 3/ 2026 2- احمد رجب علام 20-22-23 /3/ 2026 3- ابراهيم عبد الصبور من 19 الى 23 / 3/ 2026',
        '2026-03-25',
        N'محطة السيوف',
        N'بمرور الادارة العامة للامن على محطة السيوف يوم الاربعاء 25/3/2026 اثناء النوة تلاحظ غياب الاتى 1- محمود محمد محمديوم 18-23-24-25/ 3/ 2026 2- احمد رجب علام 20-22-23 /3/ 2026 3- ابراهيم عبد الصبور من 19 الى 23 / 3/ 2026',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'الاتى 1',
        '2026-05-04 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: محمود محمد محمد
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمود محمد محمد';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمود محمد محمد%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمود محمد محمد', N'موظف', N'محطة السيوف', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'90',
        '2026-02-04',
        '2026-02-04',
        N'ب',
        N'نرمين قنديل',
        N'الفنى/ اسامة وليد حسن بموقع اباظة قد ترك العمل يوم 18/3/2026 بدون اذن اثناء النوة الساعة 1:40 ص',
        '2026-03-18',
        N'بموقع اباظة قد ترك العمل',
        N'الفنى/ اسامة وليد حسن بموقع اباظة قد ترك العمل يوم 18/3/2026 بدون اذن اثناء النوة الساعة 1:40 ص',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'اسامة وليد حسن',
        '2026-02-04 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: اسامة وليد حسن
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'اسامة وليد حسن';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%اسامة وليد حسن%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'اسامة وليد حسن', N'موظف', N'بموقع اباظة قد ترك العمل', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'91',
        '2026-02-04',
        '2026-02-04',
        N'ب',
        N'غاده شكري',
        N'انقطاع السيد/ عماد محمد عامر بيومى اعتبارا من يوم 12/3/2026 حتى تاريخة بالادارة العامة للحملة الميكانيكية',
        '2026-03-12',
        N'ادارة العامة للحملة الميكانيكية',
        N'انقطاع السيد/ عماد محمد عامر بيومى اعتبارا من يوم 12/3/2026 حتى تاريخة بالادارة العامة للحملة الميكانيكية',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'عماد محمد عامر ب',
        '2026-02-04 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: عماد محمد عامر ب
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'عماد محمد عامر ب';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%عماد محمد عامر ب%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'عماد محمد عامر ب', N'موظف', N'ادارة العامة للحملة الميكانيكية', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-04-07', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 7/4/2026 | ورد من ر.م.أ 14/4/2026', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'92',
        '2026-02-04',
        '2026-02-04',
        N'ب',
        N'غاده شكري',
        N'انقطاع السيد/اسامة السيد ابو الدهب بالادارة العامة للحملة الميكانيكية',
        '2026-02-04',
        N'ادارة العامة للحملة الميكانيكية',
        N'انقطاع السيد/اسامة السيد ابو الدهب بالادارة العامة للحملة الميكانيكية',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'اسامة السيد ابو الدهب بالادارة',
        '2026-02-04 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: اسامة السيد ابو الدهب بالادارة
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'اسامة السيد ابو الدهب بالادارة';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%اسامة السيد ابو الدهب بالادارة%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'اسامة السيد ابو الدهب بالادارة', N'موظف', N'ادارة العامة للحملة الميكانيكية', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-04-07', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 7/4/2026 | ورد من ر.م.أ 14/4/2026', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'93',
        '2026-08-04',
        '2026-08-04',
        N'ب',
        N'شعبان السيد',
        N'غياب السيد/ محمد محمود سلامة بمحطة هلش بالوردية الثانية يوم 25/3/2026',
        '2026-03-25',
        N'بمحطة هلش بالوردية الثانية',
        N'غياب السيد/ محمد محمود سلامة بمحطة هلش بالوردية الثانية يوم 25/3/2026',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'محمد محمود سلامة',
        '2026-08-04 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: محمد محمود سلامة
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمد محمود سلامة';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمد محمود سلامة%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمد محمود سلامة', N'موظف', N'بمحطة هلش بالوردية الثانية', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'94',
        '2026-09-02',
        '2026-09-02',
        N'ب',
        N'خالد احمد',
        N'عدم تواجد السائق/ احمد عباس بمكان التمركز باب 10 يوم 25/3/2026 الساعة 4:3 حتى 7',
        '2026-03-25',
        N'ديوان عام الشركة',
        N'عدم تواجد السائق/ احمد عباس بمكان التمركز باب 10 يوم 25/3/2026 الساعة 4:3 حتى 7',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'احمد عباس بمكان التمركز باب',
        '2026-09-02 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: احمد عباس بمكان التمركز باب
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'احمد عباس بمكان التمركز باب';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%احمد عباس بمكان التمركز باب%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'احمد عباس بمكان التمركز باب', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'95',
        '2026-05-04',
        '2026-05-04',
        N'ب',
        N'نورة عباس',
        N'غياب السيد/ عصمت عبد الحميد حامد يوم 26/3/2026 بالادارة العامة للامن محطة الهجتنة العامرية مغلقة يوم 27/3/2026 الساعة10:35 محطة اسكان عبد القادر مغلقة يوم 27/3/2026 الساعة 10:36',
        '2026-03-26',
        N'محطة الهجتنة العامرية مغلقة',
        N'غياب السيد/ عصمت عبد الحميد حامد يوم 26/3/2026 بالادارة العامة للامن محطة الهجتنة العامرية مغلقة يوم 27/3/2026 الساعة10:35 محطة اسكان عبد القادر مغلقة يوم 27/3/2026 الساعة 10:36',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'عصمت عبد الحميد حامد',
        '2026-05-04 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: عصمت عبد الحميد حامد
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'عصمت عبد الحميد حامد';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%عصمت عبد الحميد حامد%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'عصمت عبد الحميد حامد', N'موظف', N'محطة الهجتنة العامرية مغلقة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-05-13', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 13/5/2026 |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'96',
        '2026-05-04',
        '2026-05-04',
        N'ب',
        N'حنان الخشاب',
        N'غياب كلا من بدون اذن اثناء التمركزات 1- محمد ابراهيم محمود 22/3/2026 2- احمد على 24/3/2026 3- حسام 24/3/2026 4- فواد فتحى سعد 23/3/2026',
        '2026-03-22',
        N'ديوان عام الشركة',
        N'غياب كلا من بدون اذن اثناء التمركزات 1- محمد ابراهيم محمود 22/3/2026 2- احمد على 24/3/2026 3- حسام 24/3/2026 4- فواد فتحى سعد 23/3/2026',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'موظف محال للتحقيق',
        '2026-05-04 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'97',
        '2026-05-04',
        '2026-05-04',
        N'ب',
        N'هدى رجب',
        N'المرور على محطات الشركة المختلفة يوم 26/3/2026 تلاحظ غياب عمرو ممدوح محمد يوم 26/3/2026 ترك عمل اشرف محمد حسن يوم 26/3/2026 الساعة 9:15 وترك عمل احمد عبد الله مبروك يوم 26/3/2026',
        '2026-03-26',
        N'ديوان عام الشركة',
        N'المرور على محطات الشركة المختلفة يوم 26/3/2026 تلاحظ غياب عمرو ممدوح محمد يوم 26/3/2026 ترك عمل اشرف محمد حسن يوم 26/3/2026 الساعة 9:15 وترك عمل احمد عبد الله مبروك يوم 26/3/2026',
        N'جارية',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'عمرو ممدوح محمد',
        '2026-05-04 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: عمرو ممدوح محمد
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'عمرو ممدوح محمد';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%عمرو ممدوح محمد%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'عمرو ممدوح محمد', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'98',
        '2026-03-26',
        NULL,
        N'ب',
        N'هانى احمد',
        N'غياب كلامن 1- عمرو محمود محمد يوم 26/3/2026 2- حسين محمد عيد 31/3/2026 3- بيومى محمود محمد 31/3/2026',
        '2026-03-26',
        N'ديوان عام الشركة',
        N'غياب كلامن 1- عمرو محمود محمد يوم 26/3/2026 2- حسين محمد عيد 31/3/2026 3- بيومى محمود محمد 31/3/2026',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'كلامن 1',
        '2026-03-26 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: عمرو محمود محمد
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'عمرو محمود محمد';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%عمرو محمود محمد%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'عمرو محمود محمد', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'99',
        '2026-09-04',
        '2026-09-04',
        N'ب',
        N'تامر الحداد',
        N'غياب السيد/ السيد احمد محمد نصار ايام التمركزات 13،14،15،21/4/2026',
        '2026-04-21',
        N'ديوان عام الشركة',
        N'غياب السيد/ السيد احمد محمد نصار ايام التمركزات 13،14،15،21/4/2026',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'السيد احمد محمد نصار ايام',
        '2026-09-04 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: احمد محمد نصار ايام
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'احمد محمد نصار ايام';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%احمد محمد نصار ايام%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'احمد محمد نصار ايام', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'100',
        '2026-09-04',
        '2026-09-04',
        N'ب',
        N'خالد احمد',
        N'قيام رئيس محطة مدخل المدينة السيد/ خالد ابراهيم حسن اعطاء العامل / احمد محمد على اذن ساعتين اثناء النوة وغياب السيد/ محمد احمد ابوالحداد يوم 31/3/2026 اثناء التمركزات وغياب السيد / محمد محمود محمود سلامة يوم 1/4/2026 اثناء التمركزات',
        '2026-03-31',
        N'محطة مدخل المدينة السيد',
        N'قيام رئيس محطة مدخل المدينة السيد/ خالد ابراهيم حسن اعطاء العامل / احمد محمد على اذن ساعتين اثناء النوة وغياب السيد/ محمد احمد ابوالحداد يوم 31/3/2026 اثناء التمركزات وغياب السيد / محمد محمود محمود سلامة يوم 1/4/2026 اثناء التمركزات',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'رئيس محطة مدخل المدينة السيد',
        '2026-09-04 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: رئيس محطة مدخل المدينة السيد
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'رئيس محطة مدخل المدينة السيد';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%رئيس محطة مدخل المدينة السيد%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'رئيس محطة مدخل المدينة السيد', N'موظف', N'محطة مدخل المدينة السيد', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'101',
        '2026-04-01',
        NULL,
        N'ب',
        N'هدى رجب',
        N'غياب السيد/ نصر عيسى ابراهيم يوم 1/4/2026 اثناء التمركزات وترك عمل الفنى / عصام جمعة حجازى يوم 1/42026 اثناء التمركزات',
        '2026-04-01',
        N'ديوان عام الشركة',
        N'غياب السيد/ نصر عيسى ابراهيم يوم 1/4/2026 اثناء التمركزات وترك عمل الفنى / عصام جمعة حجازى يوم 1/42026 اثناء التمركزات',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'نصر عيسى ابراهيم',
        '2026-04-01 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: نصر عيسى ابراهيم
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'نصر عيسى ابراهيم';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%نصر عيسى ابراهيم%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'نصر عيسى ابراهيم', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'102',
        '2026-08-04',
        '2026-08-04',
        N'ب',
        N'حنان الخشاب',
        N'ترك عمل العامل/ محمود فكرى شحاتة كود 9804 يوم الثلاثاء الموافق 31/3/2026 الساعة 9:30ص اثناء التمركزات',
        '2026-03-31',
        N'ديوان عام الشركة',
        N'ترك عمل العامل/ محمود فكرى شحاتة كود 9804 يوم الثلاثاء الموافق 31/3/2026 الساعة 9:30ص اثناء التمركزات',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'محمود فكرى شحاتة كود 9804',
        '2026-08-04 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: محمود فكرى شحاتة كود 9804
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE Code = N'9804';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمود فكرى شحاتة كود 9804';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمود فكرى شحاتة كود 9804%';
    IF @EmpMasterId IS NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM EmployeesMaster WHERE Code = N'9804')
            SET @NewCode = N'9804';
        ELSE
            SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمود فكرى شحاتة كود 9804', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'103',
        '2026-09-04',
        '2026-09-04',
        N'ب',
        N'ايمن توفيق',
        N'غياب السيد/ابراهيم عبد الصبور كود 5063 يوم الاربعاء 18/3/2026 بمحطة السيوف اثناء التمركزات',
        '2026-03-18',
        N'بمحطة السيوف',
        N'غياب السيد/ابراهيم عبد الصبور كود 5063 يوم الاربعاء 18/3/2026 بمحطة السيوف اثناء التمركزات',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'ابراهيم عبد الصبور كود 5063',
        '2026-09-04 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: ابراهيم عبد الصبور كود 5063
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE Code = N'5063';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'ابراهيم عبد الصبور كود 5063';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%ابراهيم عبد الصبور كود 5063%';
    IF @EmpMasterId IS NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM EmployeesMaster WHERE Code = N'5063')
            SET @NewCode = N'5063';
        ELSE
            SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'ابراهيم عبد الصبور كود 5063', N'موظف', N'بمحطة السيوف', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'104',
        '2026-04-12',
        '2026-04-12',
        N'ب',
        N'غاده شكري',
        N'انقطاع السيد/ عوض بسيونى عوض اسماعيل عن العمل من 3/3/2026حتى 18/3/2026 يعمل بمنطقة العجمى',
        '2026-03-03',
        N'بمنطقة العجمى',
        N'انقطاع السيد/ عوض بسيونى عوض اسماعيل عن العمل من 3/3/2026حتى 18/3/2026 يعمل بمنطقة العجمى',
        N'مغلقة',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'عوض بسيونى عوض اسماعيل',
        '2026-04-12 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: عوض بسيونى عوض اسماعيل
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'عوض بسيونى عوض اسماعيل';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%عوض بسيونى عوض اسماعيل%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'عوض بسيونى عوض اسماعيل', N'موظف', N'بمنطقة العجمى', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-04-12', N'رئيس مجلس الإدارة', N'مجازاة بخصم من الراتب', N'14', N'عرض على ر.م.أ 12/4/2026 | ورد من ر.م.أ 14/4/2026 بمجازتة بخصم اربعة ايام من الراتب + استنزال ايام الراتب', GETDATE());
    INSERT INTO FinalDecisions (InvestigationId, FinalDecisionText, ActionType, HRSentDate, HRNotes, CreatedAt)
    VALUES (@InvId, N'ورد من ر.م.أ 14/4/2026 بمجازتة  بخصم اربعة ايام من الراتب + استنزال ايام الراتب', 'hr', '2026-04-12', N'عرض على ر.م.أ 12/4/2026 | ورد من ر.م.أ 14/4/2026 بمجازتة بخصم اربعة ايام من الراتب + استنزال ايام الراتب', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'105',
        '2026-04-14',
        '2026-04-14',
        N'ب',
        N'نورة عباس',
        N'غياب السيد/ سعيد عبد العادلى بغدادى على يوم 18/3/2026 اثناءالنوة يعمل بمنطقة العامرية',
        '2026-03-18',
        N'بمنطقة العامرية',
        N'غياب السيد/ سعيد عبد العادلى بغدادى على يوم 18/3/2026 اثناءالنوة يعمل بمنطقة العامرية',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'سعيد عبد العادلى بغدادى على',
        '2026-04-14 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: سعيد عبد العادلى بغدادى على
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'سعيد عبد العادلى بغدادى على';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%سعيد عبد العادلى بغدادى على%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'سعيد عبد العادلى بغدادى على', N'موظف', N'بمنطقة العامرية', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-04-26', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 26/4/2026 |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'106',
        '2026-04-15',
        '2026-04-15',
        N'ب',
        N'ريهام شفيق',
        N'انقطاع العامل زكريا احمد زكاريا محمد كود 10943 عن العمل من 31/3/2026 حتى 6/4/2026 يعمل بمحطة الناموية عامرية',
        '2026-03-31',
        N'بمحطة الناموية عامرية',
        N'انقطاع العامل زكريا احمد زكاريا محمد كود 10943 عن العمل من 31/3/2026 حتى 6/4/2026 يعمل بمحطة الناموية عامرية',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'العامل زكريا احمد زكاريا محمد',
        '2026-04-15 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: زكريا احمد زكاريا محمد
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE Code = N'10943';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'زكريا احمد زكاريا محمد';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%زكريا احمد زكاريا محمد%';
    IF @EmpMasterId IS NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM EmployeesMaster WHERE Code = N'10943')
            SET @NewCode = N'10943';
        ELSE
            SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'زكريا احمد زكاريا محمد', N'موظف', N'بمحطة الناموية عامرية', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-05-06', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 6/5/2026 |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'107',
        '2026-04-16',
        '2026-04-16',
        N'ب',
        N'حنان الخشاب',
        N'غياب السيد هانى على محمد احمد يومى 24،25/3/2026 يعمل بمنطقة العامرية اثناء النوة',
        '2026-03-25',
        N'بمنطقة العامرية',
        N'غياب السيد هانى على محمد احمد يومى 24،25/3/2026 يعمل بمنطقة العامرية اثناء النوة',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'هانى على محمد احمد',
        '2026-04-16 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: هانى على محمد احمد
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'هانى على محمد احمد';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%هانى على محمد احمد%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'هانى على محمد احمد', N'موظف', N'بمنطقة العامرية', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'108',
        '2026-04-19',
        '2026-04-19',
        N'ب',
        N'هدى رجب',
        N'غياب العامل بيومى محمود محمد كود 3218 يوم 1/4/2026 اثناء التمركزات بدون اذن يعمل بمحطة 3 سيدى بشر',
        '2026-04-01',
        N'بمحطة 3 سيدى بشر',
        N'غياب العامل بيومى محمود محمد كود 3218 يوم 1/4/2026 اثناء التمركزات بدون اذن يعمل بمحطة 3 سيدى بشر',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'العامل ب',
        '2026-04-19 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'بمحطة 3 سيدى بشر', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'109',
        '2026-04-20',
        '2026-04-20',
        N'ب',
        N'وفاء رمزي',
        N'بشان ترك العمل السيد/احمد عبد اللطيف مصطفى يوم 1/4/2026',
        '2026-04-01',
        N'ديوان عام الشركة',
        N'بشان ترك العمل السيد/احمد عبد اللطيف مصطفى يوم 1/4/2026',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'احمد عبد اللطيف مصط',
        '2026-04-20 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: احمد عبد اللطيف مصط
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'احمد عبد اللطيف مصط';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%احمد عبد اللطيف مصط%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'احمد عبد اللطيف مصط', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'110',
        '2026-04-06',
        NULL,
        N'ب',
        N'شعبان السيد',
        N'ترك عمل السيد/ بيومى محمود محمد يالوردية الثالثة (11م-7ص) بمحطة 3 سيدى بشر 6/4/2026',
        '2026-04-06',
        N'بمحطة 3 سيدى بشر 6',
        N'ترك عمل السيد/ بيومى محمود محمد يالوردية الثالثة (11م-7ص) بمحطة 3 سيدى بشر 6/4/2026',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'ب',
        '2026-04-06 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'بمحطة 3 سيدى بشر 6', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'111',
        '2026-04-20',
        '2026-04-20',
        N'ب',
        N'حنان الخشاب',
        N'بشأن ترك عمل محطة 11 شرق الساعة 2م لكلامن 1- احمد محمد يوسف 2- محمد عبد العزيز رشدى 3- عاطف حسين محمود والعامل سمير زيدان مسعد مدون امام اسمة بدل جمعة',
        '2026-04-20',
        N'محطة 11 شرق',
        N'بشأن ترك عمل محطة 11 شرق الساعة 2م لكلامن 1- احمد محمد يوسف 2- محمد عبد العزيز رشدى 3- عاطف حسين محمود والعامل سمير زيدان مسعد مدون امام اسمة بدل جمعة',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'محطة 11 شرق الساعة 2م',
        '2026-04-20 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: احمد محمد يوسف
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'احمد محمد يوسف';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%احمد محمد يوسف%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'احمد محمد يوسف', N'موظف', N'محطة 11 شرق', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: محمد عبد العزيز رشدى
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمد عبد العزيز رشدى';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمد عبد العزيز رشدى%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمد عبد العزيز رشدى', N'موظف', N'محطة 11 شرق', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: عاطف حسين محمود والعامل سمير زيدان مسعد مدون امام اسمة بدل جمعة
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'عاطف حسين محمود والعامل سمير زيدان مسعد مدون امام اسمة بدل جمعة';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%عاطف حسين محمود والعامل سمير زيدان مسعد مدون امام اسمة بدل جمعة%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'عاطف حسين محمود والعامل سمير زيدان مسعد مدون امام اسمة بدل جمعة', N'موظف', N'محطة 11 شرق', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'112',
        '2026-04-21',
        '2026-04-21',
        N'ب',
        N'غاده شكري',
        N'انقطاع السيد المهندس محمد جابر محمد حسن عن العمل من 19/3/2026 حتى 29/3/2026 يعمل بمنطقة العامرية',
        '2026-03-19',
        N'بمنطقة العامرية',
        N'انقطاع السيد المهندس محمد جابر محمد حسن عن العمل من 19/3/2026 حتى 29/3/2026 يعمل بمنطقة العامرية',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'المهندس محمد جابر محمد حسن',
        '2026-04-21 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: محمد جابر محمد حسن
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمد جابر محمد حسن';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمد جابر محمد حسن%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمد جابر محمد حسن', N'موظف', N'بمنطقة العامرية', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-05-12', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 12/5/2026 |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'113',
        '2026-03-31',
        NULL,
        N'ب',
        N'خالد احمد',
        N'غياب مجوعة من السادة بمنطقة العامرية 1- محمد السيد على عبد العليم 31/3/2026 2- محمد عبد ربه محمد 1/4/2026 3- امير يحيى عبد الفتاح 1/4/2026 4- عمر عبدالله سامح 1/4/2026',
        '2026-03-31',
        N'بمنطقة العامرية 1',
        N'غياب مجوعة من السادة بمنطقة العامرية 1- محمد السيد على عبد العليم 31/3/2026 2- محمد عبد ربه محمد 1/4/2026 3- امير يحيى عبد الفتاح 1/4/2026 4- عمر عبدالله سامح 1/4/2026',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'مجوعة من السادة بمنطقة العامرية',
        '2026-03-31 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: مجوعة من السادة بمنطقة العامرية
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'مجوعة من السادة بمنطقة العامرية';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%مجوعة من السادة بمنطقة العامرية%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'مجوعة من السادة بمنطقة العامرية', N'موظف', N'بمنطقة العامرية 1', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'114',
        '2026-01-01',
        NULL,
        N'ب',
        N'نرمين قنديل',
        N'ترك عمل السيد/ عصام جمعة حجازى الساعة 4:30م',
        '2026-01-01',
        N'ديوان عام الشركة',
        N'ترك عمل السيد/ عصام جمعة حجازى الساعة 4:30م',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'عصام جمعة حجازى الساعة 430م',
        '2026-01-01 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: عصام جمعة حجازى الساعة 4:30م
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'عصام جمعة حجازى الساعة 4:30م';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%عصام جمعة حجازى الساعة 4:30م%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'عصام جمعة حجازى الساعة 4:30م', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'115',
        '2026-01-01',
        NULL,
        N'ب',
        N'غير مسند',
        N'تحقيق ديوان عام ب رقم 115',
        '2026-01-01',
        N'ديوان عام الشركة',
        N'تحقيق ديوان عام ب رقم 115',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'موظف محال للتحقيق',
        '2026-01-01 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'116',
        '2026-03-26',
        NULL,
        N'ب',
        N'ايناس جلال',
        N'غياب السيد / احمد رجب علام محمد على يوم 26/3/2026 اثناء التمركزات',
        '2026-03-26',
        N'ديوان عام الشركة',
        N'غياب السيد / احمد رجب علام محمد على يوم 26/3/2026 اثناء التمركزات',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'موظف محال للتحقيق',
        '2026-03-26 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'117',
        '2026-04-27',
        '2026-04-27',
        N'ب',
        N'طارق السيد',
        N'غياب الامن من 1- سعد عبد المولى السيد عمران 2- خميس على حسين على بدون اذن مسبق علما بانه كان يوم 18/4/2026 تمركز بمحطة عزبة الشيخ',
        '2026-04-18',
        N'بمحطة عزبة الشيخ',
        N'غياب الامن من 1- سعد عبد المولى السيد عمران 2- خميس على حسين على بدون اذن مسبق علما بانه كان يوم 18/4/2026 تمركز بمحطة عزبة الشيخ',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'الامن من 1',
        '2026-04-27 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: سعد عبد المولى السيد عمران
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'سعد عبد المولى السيد عمران';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%سعد عبد المولى السيد عمران%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'سعد عبد المولى السيد عمران', N'موظف', N'بمحطة عزبة الشيخ', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: خميس على حسين على بدون اذن مسبق علما بانه كان
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'خميس على حسين على بدون اذن مسبق علما بانه كان';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%خميس على حسين على بدون اذن مسبق علما بانه كان%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'خميس على حسين على بدون اذن مسبق علما بانه كان', N'موظف', N'بمحطة عزبة الشيخ', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'118',
        '2026-05-05',
        '2026-05-05',
        N'ب',
        N'غادة شكرى',
        N'انقطاع السائق/يوسف خميس عز الدين عن العمل من 19/4/2026 حتى 21/4/2026 اثناء النوة',
        '2026-04-19',
        N'قطاع السائق',
        N'انقطاع السائق/يوسف خميس عز الدين عن العمل من 19/4/2026 حتى 21/4/2026 اثناء النوة',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'يوسف خميس عز الدين',
        '2026-05-05 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: يوسف خميس عز الدين
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'يوسف خميس عز الدين';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%يوسف خميس عز الدين%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'يوسف خميس عز الدين', N'موظف', N'قطاع السائق', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-06-01', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض على ر.م.أ 1/6/2026 |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'119',
        '2026-10-05',
        '2026-10-05',
        N'ب',
        N'هدى رجب',
        N'المرور على محطة فرعون منتزة الساعة 8م تلاحظ عدم تواجد 1-اشرف ابراهيم على 2- سمير عبدالخالق صالح وارتفاع منسوب المياه',
        '2026-10-05',
        N'محطة فرعون منتزة',
        N'المرور على محطة فرعون منتزة الساعة 8م تلاحظ عدم تواجد 1-اشرف ابراهيم على 2- سمير عبدالخالق صالح وارتفاع منسوب المياه',
        N'جارية',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'اشرف ابراهيم على, سمير عبدالخالق صالح وارتفاع منسوب المياه',
        '2026-10-05 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: اشرف ابراهيم على
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'اشرف ابراهيم على';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%اشرف ابراهيم على%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'اشرف ابراهيم على', N'موظف', N'محطة فرعون منتزة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: سمير عبدالخالق صالح وارتفاع منسوب المياه
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'سمير عبدالخالق صالح وارتفاع منسوب المياه';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%سمير عبدالخالق صالح وارتفاع منسوب المياه%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'سمير عبدالخالق صالح وارتفاع منسوب المياه', N'موظف', N'محطة فرعون منتزة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'120',
        '2026-05-05',
        '2026-05-05',
        N'ب',
        N'نرمين قنديل',
        N'غياب السيد/ احمد سمير فرغلى عن نوباتجية غرفة عمليات المحافظة يوم 25/4/2026 الساعة 8ص',
        '2026-04-25',
        N'غرفة عمليات المحافظة',
        N'غياب السيد/ احمد سمير فرغلى عن نوباتجية غرفة عمليات المحافظة يوم 25/4/2026 الساعة 8ص',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'احمد سمير فرغلى',
        '2026-05-05 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: احمد سمير فرغلى
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'احمد سمير فرغلى';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%احمد سمير فرغلى%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'احمد سمير فرغلى', N'موظف', N'غرفة عمليات المحافظة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'121',
        '2026-10-05',
        '2026-10-05',
        N'ب',
        N'صباح رمضان',
        N'غياب السيد/يوسف سالم حسين اثناء النوة يعمل بمنطقة العجمى',
        '2026-10-05',
        N'بمنطقة العجمى',
        N'غياب السيد/يوسف سالم حسين اثناء النوة يعمل بمنطقة العجمى',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'يوسف سالم حسين',
        '2026-10-05 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: يوسف سالم حسين
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'يوسف سالم حسين';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%يوسف سالم حسين%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'يوسف سالم حسين', N'موظف', N'بمنطقة العجمى', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'122',
        '2026-10-05',
        '2026-10-05',
        N'ب',
        N'مروة مصطفى',
        N'بسبب نشب حريق بمنطقة غرب عجمى بمبنى المخازن الغعامة يوم 26/4/2026 الساعة 10:50م تلاحظ مشرفى الحملة وسائقين بمنطقة غرب الانصرف الساعة 10:50م السائق /عبد السميع لاطفاء الحريق وعدم حضور كلا من1- ابراهيم على 2- احمد عبد الوهاب 3- على محمد 4- احمد السي...',
        '2026-04-26',
        N'بمنطقة غرب عجمى بمبنى المخازن',
        N'بسبب نشب حريق بمنطقة غرب عجمى بمبنى المخازن الغعامة يوم 26/4/2026 الساعة 10:50م تلاحظ مشرفى الحملة وسائقين بمنطقة غرب الانصرف الساعة 10:50م السائق /عبد السميع لاطفاء الحريق وعدم حضور كلا من1- ابراهيم على 2- احمد عبد الوهاب 3- على محمد 4- احمد السيد بمواعيد العمل الرسمية',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'عبد السميع لاطفاء الحريق وعدم',
        '2026-10-05 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: ابراهيم على
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'ابراهيم على';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%ابراهيم على%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'ابراهيم على', N'موظف', N'بمنطقة غرب عجمى بمبنى المخازن', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: احمد عبد الوهاب
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'احمد عبد الوهاب';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%احمد عبد الوهاب%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'احمد عبد الوهاب', N'موظف', N'بمنطقة غرب عجمى بمبنى المخازن', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: على محمد
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'على محمد';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%على محمد%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'على محمد', N'موظف', N'بمنطقة غرب عجمى بمبنى المخازن', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: احمد السيد بمواعيد العمل الرسمية
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'احمد السيد بمواعيد العمل الرسمية';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%احمد السيد بمواعيد العمل الرسمية%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'احمد السيد بمواعيد العمل الرسمية', N'موظف', N'بمنطقة غرب عجمى بمبنى المخازن', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'123',
        '2026-11-05',
        '2026-11-05',
        N'ب',
        N'حنان الخشاب',
        N'غياب السيد/ محمود محمد محمد مرسى يوم 8/4/2026 اثناء التمركزات محطة السيوف الجديدة',
        '2026-04-08',
        N'محطة السيوف الجديدة',
        N'غياب السيد/ محمود محمد محمد مرسى يوم 8/4/2026 اثناء التمركزات محطة السيوف الجديدة',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'محمود محمد محمد مرسى',
        '2026-11-05 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: محمود محمد محمد مرسى
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمود محمد محمد مرسى';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمود محمد محمد مرسى%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمود محمد محمد مرسى', N'موظف', N'محطة السيوف الجديدة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'124',
        '2026-07-05',
        '2026-07-05',
        N'ب',
        N'هدى رجب',
        N'غياب كلا من 1- احمد عبد الفتاح ايام 3،4/4/2026 2- احمد سمير فرغلى ايام 12،19،25/4/2026 نوباتجية',
        '2026-04-04',
        N'ديوان عام الشركة',
        N'غياب كلا من 1- احمد عبد الفتاح ايام 3،4/4/2026 2- احمد سمير فرغلى ايام 12،19،25/4/2026 نوباتجية',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'كلا من 1',
        '2026-07-05 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: كلا من 1
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'كلا من 1';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%كلا من 1%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'كلا من 1', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'125',
        '2026-05-21',
        '2026-05-21',
        N'ب',
        N'نرمين قنديل',
        N'غياب العامل/ السيد مجدى السيد يومى 3،4/5/2026 اثناء النوة يعمل بمحطة عبدالقادر بحرى',
        '2026-05-04',
        N'بمحطة عبدالقادر بحرى',
        N'غياب العامل/ السيد مجدى السيد يومى 3،4/5/2026 اثناء النوة يعمل بمحطة عبدالقادر بحرى',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'السيد مجدى السيد',
        '2026-05-21 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: مجدى السيد
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'مجدى السيد';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%مجدى السيد%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'مجدى السيد', N'موظف', N'بمحطة عبدالقادر بحرى', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'126',
        '2026-05-19',
        '2026-05-19',
        N'ب',
        N'ريهام شفيق',
        N'قيام الفنى/امير يحيى عبد الفتاح يعمل بدل 3/5/2026 اثناء النوة',
        '2026-05-03',
        N'ديوان عام الشركة',
        N'قيام الفنى/امير يحيى عبد الفتاح يعمل بدل 3/5/2026 اثناء النوة',
        N'مغلقة',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'امير يحيى عبد الفتاح ي',
        '2026-05-19 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: امير يحيى عبد الفتاح ي
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'امير يحيى عبد الفتاح ي';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%امير يحيى عبد الفتاح ي%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'امير يحيى عبد الفتاح ي', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-06-09', N'رئيس مجلس الإدارة', N'مجازاة بخصم من الراتب', N'16', N'عرض على ر.م.أ 9/6/2026 برقم صادر 960/2026 | ورد من ر.م.أ 16/6/2026 بمجازات السيد امير يحيي عبدالفتاح بخصم 4 ايام من الراتب لغيابة يوم 3/5/2026 يوم النوة ارسل اصل المذكرة ل رئيس قطاع الموارد البشرية 22/6/2026', GETDATE());
    INSERT INTO FinalDecisions (InvestigationId, FinalDecisionText, ActionType, HRSentDate, HRNotes, CreatedAt)
    VALUES (@InvId, N'ورد من ر.م.أ 16/6/2026 بمجازات السيد امير يحيي عبدالفتاح بخصم 4 ايام من الراتب لغيابة يوم 3/5/2026 يوم النوة  ارسل اصل المذكرة ل رئيس قطاع الموارد البشرية 22/6/2026', 'hr', '2026-06-09', N'عرض على ر.م.أ 9/6/2026 برقم صادر 960/2026 | ورد من ر.م.أ 16/6/2026 بمجازات السيد امير يحيي عبدالفتاح بخصم 4 ايام من الراتب لغيابة يوم 3/5/2026 يوم النوة ارسل اصل المذكرة ل رئيس قطاع الموارد البشرية 22/6/2026', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'127',
        '2026-05-19',
        '2026-05-19',
        N'ب',
        N'غادة شكري',
        N'انقطاع السيد/ محمد فكرى شحاتة عن العمل من الفترة',
        '2026-05-19',
        N'قطاع السيد',
        N'انقطاع السيد/ محمد فكرى شحاتة عن العمل من الفترة',
        N'مغلقة',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'محمد فكرى شحاتة',
        '2026-05-19 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: محمد فكرى شحاتة
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمد فكرى شحاتة';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمد فكرى شحاتة%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمد فكرى شحاتة', N'موظف', N'قطاع السيد', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-05-20', N'رئيس مجلس الإدارة', N'مجازاة بخصم من الراتب', N'24', N'عرض على ر.م.أ 20/5/2026 برقم صادر 932/2026 | ورد من ر.م.أ 24/5/2026 بمجازات السيد محمد فكري شحاته بخصم 3 ايام من الراتب واستبدال ايم الانقطاع من 19/4/2026حتي 24/4/2026 ارسل اصل المذكرة ل رئيس قطاع الموارد البشرية 1/6/2026', GETDATE());
    INSERT INTO FinalDecisions (InvestigationId, FinalDecisionText, ActionType, HRSentDate, HRNotes, CreatedAt)
    VALUES (@InvId, N'ورد من ر.م.أ 24/5/2026 بمجازات السيد محمد فكري شحاته بخصم 3 ايام من الراتب واستبدال ايم الانقطاع من 19/4/2026حتي 24/4/2026  ارسل اصل المذكرة ل رئيس قطاع الموارد البشرية 1/6/2026', 'hr', '2026-05-20', N'عرض على ر.م.أ 20/5/2026 برقم صادر 932/2026 | ورد من ر.م.أ 24/5/2026 بمجازات السيد محمد فكري شحاته بخصم 3 ايام من الراتب واستبدال ايم الانقطاع من 19/4/2026حتي 24/4/2026 ارسل اصل المذكرة ل رئيس قطاع الموارد البشرية 1/6/2026', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'128',
        '2026-05-25',
        '2026-05-25',
        N'ب',
        N'هاني السيد',
        N'غياب العامل/ احمد محمد حسن عن العمل اثناء التمركزات',
        '2026-05-25',
        N'ديوان عام الشركة',
        N'غياب العامل/ احمد محمد حسن عن العمل اثناء التمركزات',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'احمد محمد حسن',
        '2026-05-25 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: احمد محمد حسن
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'احمد محمد حسن';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%احمد محمد حسن%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'احمد محمد حسن', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'129',
        '2026-05-20',
        '2026-05-20',
        N'ب',
        N'صباح رمضان',
        N'غياب كلامن / حارس الامن 1-احمد عبدالكريم صابر 2- محمد صبحي عبدالحميد',
        '2026-05-20',
        N'ديوان عام الشركة',
        N'غياب كلامن / حارس الامن 1-احمد عبدالكريم صابر 2- محمد صبحي عبدالحميد',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'احمد عبدالكريم صابر, محمد صبحي عبدالحميد',
        '2026-05-20 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: احمد عبدالكريم صابر
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'احمد عبدالكريم صابر';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%احمد عبدالكريم صابر%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'احمد عبدالكريم صابر', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: محمد صبحي عبدالحميد
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمد صبحي عبدالحميد';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمد صبحي عبدالحميد%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمد صبحي عبدالحميد', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'130',
        '2026-06-04',
        '2026-06-04',
        N'ب',
        N'هاني السيد',
        N'تغيب حارس الامن/ايمن سيد احمد عن العمل يوم 20/5/2026 بيجمع المصانع محطه وسط',
        '2026-05-20',
        N'محطه وسط',
        N'تغيب حارس الامن/ايمن سيد احمد عن العمل يوم 20/5/2026 بيجمع المصانع محطه وسط',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'حارس الامن',
        '2026-06-04 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'محطه وسط', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'131',
        '2026-06-02',
        '2026-06-02',
        N'ب',
        N'نرمين قنديل',
        N'عدم تواجد السيد/احمد محمد احمد علي عن العمل يوم 1/5/2026 وتوقيعه حضور وانصراف في نفس اليوم بالورديه',
        '2026-05-01',
        N'ديوان عام الشركة',
        N'عدم تواجد السيد/احمد محمد احمد علي عن العمل يوم 1/5/2026 وتوقيعه حضور وانصراف في نفس اليوم بالورديه',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'موظف محال للتحقيق',
        '2026-06-02 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'132',
        '2026-06-03',
        '2026-06-03',
        N'ب',
        N'ايمن توفيق',
        N'قيام المهندس/عمرو عبده حسني بالانصراف الساعه 3 م قبل مواعيد العمل من الساعه 7 ص حتى 7م',
        '2026-06-03',
        N'ديوان عام الشركة',
        N'قيام المهندس/عمرو عبده حسني بالانصراف الساعه 3 م قبل مواعيد العمل من الساعه 7 ص حتى 7م',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'موظف محال للتحقيق',
        '2026-06-03 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'133',
        '2026-06-08',
        '2026-06-08',
        N'ب',
        N'صباح رمضان',
        N'مرور الامن يوم 21/5/2026 تلاحظ ترك العمل السيد/محمد احمد محمد مجدي الساعه 8:30 محطة سموحه الجديده محطة العجمي مغلقه الساعه 5م',
        '2026-05-21',
        N'محطة سموحه الجديده محطة العجمي مغلقه',
        N'مرور الامن يوم 21/5/2026 تلاحظ ترك العمل السيد/محمد احمد محمد مجدي الساعه 8:30 محطة سموحه الجديده محطة العجمي مغلقه الساعه 5م',
        N'مغلقة',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'محمد احمد محمد مجدي الساعه',
        '2026-06-08 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: محمد احمد محمد مجدي الساعه
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمد احمد محمد مجدي الساعه';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمد احمد محمد مجدي الساعه%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمد احمد محمد مجدي الساعه', N'موظف', N'محطة سموحه الجديده محطة العجمي مغلقه', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-06-29', N'رئيس مجلس الإدارة', N'مجازاة بخصم من الراتب', N'يوم من راتبه', N'عرض ر.م.أ 29/6/2026 ورد ر.م.أ 7/7/2026 | بخصم من راتبه يوم من راتبه/محمد احمد محمد مجدي حرمانه من اجر ساعات الترك 2-اشرف محمد محمد سالم خصم اربعة ايام من راتبه وحرمانه من اجر يوم الترك', GETDATE());
    INSERT INTO FinalDecisions (InvestigationId, FinalDecisionText, ActionType, HRSentDate, HRNotes, CreatedAt)
    VALUES (@InvId, N'بخصم من راتبه يوم من راتبه/محمد احمد محمد مجدي حرمانه من اجر ساعات الترك  2-اشرف محمد محمد سالم  خصم اربعة ايام من راتبه وحرمانه من اجر يوم الترك', 'hr', '2026-06-29', N'عرض ر.م.أ 29/6/2026 ورد ر.م.أ 7/7/2026 | بخصم من راتبه يوم من راتبه/محمد احمد محمد مجدي حرمانه من اجر ساعات الترك 2-اشرف محمد محمد سالم خصم اربعة ايام من راتبه وحرمانه من اجر يوم الترك', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'134',
        '2026-06-09',
        '2026-06-09',
        N'ب',
        N'طارق السيد',
        N'مرور يوم 25,26/31/5/2026 تلاحظ المحطه مغلقه الساعه 3 ص محطة موقع نون مغلقه الساعه 3:30 ص',
        '2026-05-31',
        N'محطه مغلقه',
        N'مرور يوم 25,26/31/5/2026 تلاحظ المحطه مغلقه الساعه 3 ص محطة موقع نون مغلقه الساعه 3:30 ص',
        N'جارية',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'موظف محال للتحقيق',
        '2026-06-09 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'محطه مغلقه', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'135',
        '2026-06-04',
        '2026-06-04',
        N'ب',
        N'ريهام شفيق',
        N'مرور على محطة عجمي يوم 14/5/2026 الورديه الاولى تلاحظ ترك عمل السيد/معاذ عبدالله محمد الساعه 12:35 ظهرا موقع نون مغلق الساعه 10:30 ص',
        '2026-05-14',
        N'محطة عجمي',
        N'مرور على محطة عجمي يوم 14/5/2026 الورديه الاولى تلاحظ ترك عمل السيد/معاذ عبدالله محمد الساعه 12:35 ظهرا موقع نون مغلق الساعه 10:30 ص',
        N'صدر قرار',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'معاذ عبدالله محمد الساعه 1235',
        '2026-06-04 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: معاذ عبدالله محمد الساعه 12:35
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'معاذ عبدالله محمد الساعه 12:35';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%معاذ عبدالله محمد الساعه 12:35%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'معاذ عبدالله محمد الساعه 12:35', N'موظف', N'محطة عجمي', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-07-07', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض ر.م.أ 7/7/2026 |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'136',
        '2026-06-11',
        '2026-06-11',
        N'ب',
        N'هاني السيد',
        N'غياب كلا من :1-احمد السيد علي كود 8830 يوم الاحد31/5/2026 محطة معالجة الهانوفيل , 2-نبيل مصباح مصباح احمد كود 4137 يوم 27/5/2026 محطة معالجة ابوتلات',
        '2026-05-31',
        N'محطة معالجة الهانوفيل',
        N'غياب كلا من :1-احمد السيد علي كود 8830 يوم الاحد31/5/2026 محطة معالجة الهانوفيل , 2-نبيل مصباح مصباح احمد كود 4137 يوم 27/5/2026 محطة معالجة ابوتلات',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'كلا من 1',
        '2026-06-11 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: كلا من :1
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE Code = N'8830';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'كلا من :1';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%كلا من :1%';
    IF @EmpMasterId IS NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM EmployeesMaster WHERE Code = N'8830')
            SET @NewCode = N'8830';
        ELSE
            SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'كلا من :1', N'موظف', N'محطة معالجة الهانوفيل', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'137',
        '2026-11-06',
        '2026-11-06',
        N'ب',
        N'نوره عباس',
        N'مرور الامن يوم 25/5/2026 بالوردية المساية نلاحظ غياب افراد اولهم احمد رجب اسماعيل واخرهم سامح السيد طه محطة ارض الهبش مغلقة السعة 2:50 ص',
        '2026-05-25',
        N'محطة ارض الهبش مغلقة السعة 2:50',
        N'مرور الامن يوم 25/5/2026 بالوردية المساية نلاحظ غياب افراد اولهم احمد رجب اسماعيل واخرهم سامح السيد طه محطة ارض الهبش مغلقة السعة 2:50 ص',
        N'مغلقة',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'افراد اولهم احمد رجب اسماعيل',
        '2026-11-06 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: افراد اولهم احمد رجب اسماعيل
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'افراد اولهم احمد رجب اسماعيل';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%افراد اولهم احمد رجب اسماعيل%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'افراد اولهم احمد رجب اسماعيل', N'موظف', N'محطة ارض الهبش مغلقة السعة 2:50', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-06-29', N'رئيس مجلس الإدارة', N'مجازاة بخصم من الراتب', N'7', N'عرض علي ر.م.أ برقم MEMO-17448 بتاريخ 29/6/2026 برقم صادر992/2026 | ورد من ر.م.أ بتاريخ 7/7/2026 انتهت بمجازة كلا من المذكورين بخصم ثلاثة ايام من راتبهم و حرمانه من اجر يوم الترك عن يوم 25/5/2026', GETDATE());
    INSERT INTO FinalDecisions (InvestigationId, FinalDecisionText, ActionType, HRSentDate, HRNotes, CreatedAt)
    VALUES (@InvId, N'ورد من ر.م.أ  بتاريخ  7/7/2026 انتهت بمجازة كلا من المذكورين بخصم ثلاثة ايام من راتبهم  و حرمانه من اجر يوم الترك عن يوم 25/5/2026', 'hr', '2026-06-29', N'عرض علي ر.م.أ برقم MEMO-17448 بتاريخ 29/6/2026 برقم صادر992/2026 | ورد من ر.م.أ بتاريخ 7/7/2026 انتهت بمجازة كلا من المذكورين بخصم ثلاثة ايام من راتبهم و حرمانه من اجر يوم الترك عن يوم 25/5/2026', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'138',
        '2026-04-06',
        '2026-04-06',
        N'ب',
        N'خالد احمد',
        N'غياب المندوب احمد عبدالفتاح دياب المكلف للعمل بنوبتاجية غرفة العمليات داخل مركز سطرة الشبكة يم 23-30/5/2026 فترة مسائية',
        '2026-05-30',
        N'مركز سطرة الشبكة يم 23',
        N'غياب المندوب احمد عبدالفتاح دياب المكلف للعمل بنوبتاجية غرفة العمليات داخل مركز سطرة الشبكة يم 23-30/5/2026 فترة مسائية',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'المندوب احمد عبدالفتاح دياب المكلف',
        '2026-04-06 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: المندوب احمد عبدالفتاح دياب المكلف
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'المندوب احمد عبدالفتاح دياب المكلف';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%المندوب احمد عبدالفتاح دياب المكلف%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'المندوب احمد عبدالفتاح دياب المكلف', N'موظف', N'مركز سطرة الشبكة يم 23', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'139',
        '2026-08-06',
        '2026-08-06',
        N'ب',
        N'حنان الخشاب',
        N'الموضوع بشأن غياب العامل/ خميس سعيد عبدالعاطي بالوردية الثالثة 27/5/2026 وقد تلاعب في سجل الحضور و الانصراف',
        '2026-05-27',
        N'ديوان عام الشركة',
        N'الموضوع بشأن غياب العامل/ خميس سعيد عبدالعاطي بالوردية الثالثة 27/5/2026 وقد تلاعب في سجل الحضور و الانصراف',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'خميس سعيد عبدالعاطي بالوردية الثالثة',
        '2026-08-06 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: خميس سعيد عبدالعاطي بالوردية الثالثة
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'خميس سعيد عبدالعاطي بالوردية الثالثة';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%خميس سعيد عبدالعاطي بالوردية الثالثة%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'خميس سعيد عبدالعاطي بالوردية الثالثة', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'140',
        '2026-09-06',
        '2026-09-06',
        N'ب',
        N'هدى رجب',
        N'الموضوع بشان غياب السيد/ اسلام عيد محمود عن العمل بدون اذن سيق يوم 25/5/2026 وقد قام بترك العمل يوم 28/5/2026',
        '2026-05-25',
        N'ديوان عام الشركة',
        N'الموضوع بشان غياب السيد/ اسلام عيد محمود عن العمل بدون اذن سيق يوم 25/5/2026 وقد قام بترك العمل يوم 28/5/2026',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'اسلام عيد محمود',
        '2026-09-06 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: اسلام عيد محمود
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'اسلام عيد محمود';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%اسلام عيد محمود%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'اسلام عيد محمود', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'141',
        '2026-06-16',
        '2026-06-16',
        N'ب',
        N'ايمن توفيق',
        N'الموضوع بشأن مرور الامن علي محطة مدخل المدينة وسط 2/6/2026 الساعة 12:15ص نلاحظ ان المحطة مغلقة ولا يوجد بها احد',
        '2026-06-02',
        N'محطة مدخل المدينة وسط 2',
        N'الموضوع بشأن مرور الامن علي محطة مدخل المدينة وسط 2/6/2026 الساعة 12:15ص نلاحظ ان المحطة مغلقة ولا يوجد بها احد',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'موظف محال للتحقيق',
        '2026-06-16 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'محطة مدخل المدينة وسط 2', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'142',
        '2026-09-06',
        '2026-09-06',
        N'ب',
        N'ايناس جلال',
        N'الموضوع بشأن انقطاع السيد/ ناجي حسين راي عن العمل بمنطقة التنقية الغربية يوم 23/2/2026 ثم عودة 22/5/2026',
        '2026-02-23',
        N'بمنطقة التنقية الغربية',
        N'الموضوع بشأن انقطاع السيد/ ناجي حسين راي عن العمل بمنطقة التنقية الغربية يوم 23/2/2026 ثم عودة 22/5/2026',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'ناجي حسين راي',
        '2026-09-06 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: ناجي حسين راي
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'ناجي حسين راي';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%ناجي حسين راي%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'ناجي حسين راي', N'موظف', N'بمنطقة التنقية الغربية', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'143',
        '2026-09-06',
        '2026-09-06',
        N'ب',
        N'نرمين قنديل',
        N'الموضوعبشأن ترك عمل كلا من السيد/ مهدي سعيد فتحي كود -11089 يوم 17/5/2026 والسيد/ محمد عبدالفتاح محمد كود -10104 يوم 25/5/2026',
        '2026-05-17',
        N'ديوان عام الشركة',
        N'الموضوعبشأن ترك عمل كلا من السيد/ مهدي سعيد فتحي كود -11089 يوم 17/5/2026 والسيد/ محمد عبدالفتاح محمد كود -10104 يوم 25/5/2026',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'كلا من السيد',
        '2026-09-06 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: كلا من السيد
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE Code = N'11089';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'كلا من السيد';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%كلا من السيد%';
    IF @EmpMasterId IS NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM EmployeesMaster WHERE Code = N'11089')
            SET @NewCode = N'11089';
        ELSE
            SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'كلا من السيد', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'144',
        '2026-02-12',
        NULL,
        N'ب',
        N'ايناس جلال',
        N'انقطاع السيد/ ناجى حسين عن العمل بمنطقة التنقية الشرقية يوم12/2/2026 ثم العودة 22/5/2026',
        '2026-02-12',
        N'بمنطقة التنقية الشرقية',
        N'انقطاع السيد/ ناجى حسين عن العمل بمنطقة التنقية الشرقية يوم12/2/2026 ثم العودة 22/5/2026',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'ناجى حسين',
        '2026-02-12 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: ناجى حسين
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'ناجى حسين';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%ناجى حسين%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'ناجى حسين', N'موظف', N'بمنطقة التنقية الشرقية', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'145',
        '2026-05-17',
        NULL,
        N'ب',
        N'نرمين قنديل',
        N'ترك عمل كلا من السيد/ مهدى سعيد يوم 17/5/2026 والسيد/ محمد عبد الفتاح يوم 25/5/2026',
        '2026-05-17',
        N'ديوان عام الشركة',
        N'ترك عمل كلا من السيد/ مهدى سعيد يوم 17/5/2026 والسيد/ محمد عبد الفتاح يوم 25/5/2026',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'كلا من السيد',
        '2026-05-17 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: كلا من السيد
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'كلا من السيد';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%كلا من السيد%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'كلا من السيد', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'146',
        '2026-05-05',
        NULL,
        N'ب',
        N'مروة مصطفى',
        N'انقطاع السيد/ على السيد على عن العمل من الفترة 5/5/2026 حتى 14/5/2026 يعمل بمنطقة منتزة اول',
        '2026-05-05',
        N'بمنطقة منتزة اول',
        N'انقطاع السيد/ على السيد على عن العمل من الفترة 5/5/2026 حتى 14/5/2026 يعمل بمنطقة منتزة اول',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'على السيد على',
        '2026-05-05 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: على السيد على
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'على السيد على';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%على السيد على%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'على السيد على', N'موظف', N'بمنطقة منتزة اول', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'147',
        '2026-06-02',
        NULL,
        N'ب',
        N'خالد احمد',
        N'مرور على محطات الشركة المختلفة تلاحظ غياب 1- محمد سالم محمود 2/6/2026 2- محمد على محمد يوم 4/6/2026 3- السيد محمد السيد 4/6/2026 محطة 5 مغلقة يوم 4/6/2026 الساعة 2:50ص',
        '2026-06-02',
        N'محطة 5 مغلقة',
        N'مرور على محطات الشركة المختلفة تلاحظ غياب 1- محمد سالم محمود 2/6/2026 2- محمد على محمد يوم 4/6/2026 3- السيد محمد السيد 4/6/2026 محطة 5 مغلقة يوم 4/6/2026 الساعة 2:50ص',
        N'جارية',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'محمد على محمد',
        '2026-06-02 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: محمد على محمد
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمد على محمد';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمد على محمد%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمد على محمد', N'موظف', N'محطة 5 مغلقة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'148',
        '2026-06-04',
        NULL,
        N'ب',
        N'شعبان السيد',
        N'مرور الامن على محطة التنقية الغربية 4/6/2026 تلاحظ غياب 1- على السيد هلال 2- غريب نعمان 3- منتصر 4- ابراهيم عبد العزيز',
        '2026-06-04',
        N'محطة التنقية الغربية 4',
        N'مرور الامن على محطة التنقية الغربية 4/6/2026 تلاحظ غياب 1- على السيد هلال 2- غريب نعمان 3- منتصر 4- ابراهيم عبد العزيز',
        N'جارية',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'على السيد هلال, غريب نعمان, منتصر, ابراهيم عبد العزيز',
        '2026-06-04 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: على السيد هلال
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'على السيد هلال';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%على السيد هلال%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'على السيد هلال', N'موظف', N'محطة التنقية الغربية 4', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: غريب نعمان
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'غريب نعمان';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%غريب نعمان%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'غريب نعمان', N'موظف', N'محطة التنقية الغربية 4', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: منتصر
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'منتصر';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%منتصر%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'منتصر', N'موظف', N'محطة التنقية الغربية 4', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: ابراهيم عبد العزيز
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'ابراهيم عبد العزيز';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%ابراهيم عبد العزيز%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'ابراهيم عبد العزيز', N'موظف', N'محطة التنقية الغربية 4', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'149',
        '2026-01-01',
        NULL,
        N'ب',
        N'هدى رجب',
        N'ترك عمل العامل محمد مصطفى وغياب 1- محمد السيد 2- محمد محمود السيد المهندس مدير محطات وسط لعدم متابعة انتظام العمل',
        '2026-01-01',
        N'ديوان عام الشركة',
        N'ترك عمل العامل محمد مصطفى وغياب 1- محمد السيد 2- محمد محمود السيد المهندس مدير محطات وسط لعدم متابعة انتظام العمل',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'العامل محمد مصط',
        '2026-01-01 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: محمد السيد
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمد السيد';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمد السيد%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمد السيد', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: محمد محمود السيد المهندس مدير محطات وسط لعدم متابعة انتظام العمل
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمد محمود السيد المهندس مدير محطات وسط لعدم متابعة انتظام العمل';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمد محمود السيد المهندس مدير محطات وسط لعدم متابعة انتظام العمل%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمد محمود السيد المهندس مدير محطات وسط لعدم متابعة انتظام العمل', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'150',
        '2026-06-07',
        NULL,
        N'ب',
        N'هاني السيد',
        N'عصام جمعة 7/6 مصطفى خميس7/6 ياسر محمود 7/6 اسلام محمد 8/6 سامية الخضر 9/6 محمد على 9/6 اسلام سعد 9/6 ايمان ناجى 9/6 ندى احمد 9/6 زياد محمد 9/6 محمد ماهر 7/6 الساعة 70:30 موقع اباظة 7/6/2026 لا يوجد به احد من العاملين محطة مدخل المدينة وسط يوم 8/6 ...',
        '2026-06-07',
        N'محطة مدخل المدينة وسط',
        N'عصام جمعة 7/6 مصطفى خميس7/6 ياسر محمود 7/6 اسلام محمد 8/6 سامية الخضر 9/6 محمد على 9/6 اسلام سعد 9/6 ايمان ناجى 9/6 ندى احمد 9/6 زياد محمد 9/6 محمد ماهر 7/6 الساعة 70:30 موقع اباظة 7/6/2026 لا يوجد به احد من العاملين محطة مدخل المدينة وسط يوم 8/6 مغلقة ولا يوجد احد بها',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'ين محطة مدخل المدينة وسط',
        '2026-06-07 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: ين محطة مدخل المدينة وسط
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'ين محطة مدخل المدينة وسط';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%ين محطة مدخل المدينة وسط%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'ين محطة مدخل المدينة وسط', N'موظف', N'محطة مدخل المدينة وسط', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'151',
        '2026-06-07',
        NULL,
        N'ب',
        N'غادة شكرى',
        N'مرور الامن على حملة الميكانيكية محرم بك يوجد الاحد الموافق 7/6/2026 وردية مسائية تلاحظ ان قوة الاجمالية الافراد الامن عددهم 4 افراد متواجد منهم 2 فقط 1- محمود سلامة 2-عمر ابراهيم 3-محمد عبد الجابر 4-محمد سلامة',
        '2026-06-07',
        N'حملة الميكانيكية محرم بك يوجد',
        N'مرور الامن على حملة الميكانيكية محرم بك يوجد الاحد الموافق 7/6/2026 وردية مسائية تلاحظ ان قوة الاجمالية الافراد الامن عددهم 4 افراد متواجد منهم 2 فقط 1- محمود سلامة 2-عمر ابراهيم 3-محمد عبد الجابر 4-محمد سلامة',
        N'صدر قرار',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'محمود سلامة, عمر ابراهيم, محمد عبد الجابر, محمد سلامة',
        '2026-06-07 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: محمود سلامة
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمود سلامة';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمود سلامة%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمود سلامة', N'موظف', N'حملة الميكانيكية محرم بك يوجد', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: عمر ابراهيم
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'عمر ابراهيم';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%عمر ابراهيم%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'عمر ابراهيم', N'موظف', N'حملة الميكانيكية محرم بك يوجد', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: محمد عبد الجابر
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمد عبد الجابر';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمد عبد الجابر%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمد عبد الجابر', N'موظف', N'حملة الميكانيكية محرم بك يوجد', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: محمد سلامة
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'محمد سلامة';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%محمد سلامة%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'محمد سلامة', N'موظف', N'حملة الميكانيكية محرم بك يوجد', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-02-01', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'152',
        '2026-06-08',
        NULL,
        N'ب',
        N'ريهام شفيق',
        N'ترك العمل العامل/ احمد محمد بموقع جهينة يوم 8/6/2026 الساعة 8م',
        '2026-06-08',
        N'بموقع جهينة',
        N'ترك العمل العامل/ احمد محمد بموقع جهينة يوم 8/6/2026 الساعة 8م',
        N'صدر قرار',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'احمد محمد',
        '2026-06-08 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: احمد محمد
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'احمد محمد';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%احمد محمد%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'احمد محمد', N'موظف', N'بموقع جهينة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- عرض ر.م.أ / القرار
    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)
    VALUES (@InvId, '2026-02-01', N'رئيس مجلس الإدارة', N'عرض على رئيس مجلس الإدارة', NULL, N'عرض |', GETDATE());

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'153',
        '2026-06-04',
        NULL,
        N'ب',
        N'ايمن توفيق',
        N'مرور الامن على محطة طلعت مصطفى العجمى يوم 4/6/2026 بالوردية المسائية 1- عاطف امام 2- بسام احمد 3- عبد الحميد متولى 4- باقى سائقى الحملة 5- نوباتجية ادارة العجمى',
        '2026-06-04',
        N'محطة طلعت مصطفى العجمى',
        N'مرور الامن على محطة طلعت مصطفى العجمى يوم 4/6/2026 بالوردية المسائية 1- عاطف امام 2- بسام احمد 3- عبد الحميد متولى 4- باقى سائقى الحملة 5- نوباتجية ادارة العجمى',
        N'جارية',
        NULL,
        N'إدارة الأمن والتفتيش',
        N'عاطف امام, بسام احمد, عبد الحميد متولى, باقى سائقى الحملة, نوباتجية ادارة العجمى',
        '2026-06-04 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: عاطف امام
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'عاطف امام';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%عاطف امام%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'عاطف امام', N'موظف', N'محطة طلعت مصطفى العجمى', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: بسام احمد
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'بسام احمد';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%بسام احمد%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'بسام احمد', N'موظف', N'محطة طلعت مصطفى العجمى', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: عبد الحميد متولى
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'عبد الحميد متولى';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%عبد الحميد متولى%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'عبد الحميد متولى', N'موظف', N'محطة طلعت مصطفى العجمى', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: باقى سائقى الحملة
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'باقى سائقى الحملة';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%باقى سائقى الحملة%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'باقى سائقى الحملة', N'موظف', N'محطة طلعت مصطفى العجمى', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: نوباتجية ادارة العجمى
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'نوباتجية ادارة العجمى';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%نوباتجية ادارة العجمى%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'نوباتجية ادارة العجمى', N'موظف', N'محطة طلعت مصطفى العجمى', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'154',
        '2026-06-13',
        NULL,
        N'ب',
        N'هدى رجب',
        N'ترك عمل 1- ابراهيم جابر 2- غريب نعمان ابو زيد 3- ابراهيم عبدالعزيز يوم 13-6-2026',
        '2026-06-13',
        N'ديوان عام الشركة',
        N'ترك عمل 1- ابراهيم جابر 2- غريب نعمان ابو زيد 3- ابراهيم عبدالعزيز يوم 13-6-2026',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'ابراهيم جابر, غريب نعمان ابو زيد, ابراهيم عبدالعزيز',
        '2026-06-13 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: ابراهيم جابر
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'ابراهيم جابر';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%ابراهيم جابر%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'ابراهيم جابر', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: غريب نعمان ابو زيد
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'غريب نعمان ابو زيد';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%غريب نعمان ابو زيد%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'غريب نعمان ابو زيد', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

    -- موظف: ابراهيم عبدالعزيز
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'ابراهيم عبدالعزيز';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%ابراهيم عبدالعزيز%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'ابراهيم عبدالعزيز', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

BEGIN
    SET @InvId = NULL;
    SET @EmpMasterId = NULL;
    INSERT INTO Investigations (
        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt
    ) VALUES (
        N'155',
        '2026-01-01',
        NULL,
        N'ب',
        N'غير مسند',
        N'تحقيق ديوان عام ب رقم 155',
        '2026-01-01',
        N'ديوان عام الشركة',
        N'تحقيق ديوان عام ب رقم 155',
        N'جارية',
        NULL,
        N'شركة الصرف الصحي بالإسكندرية',
        N'موظف محال للتحقيق',
        '2026-01-01 09:00:00'
    );
    SET @InvId = SCOPE_IDENTITY();

    -- موظف: موظف محال للتحقيق
    SET @EmpMasterId = NULL;
    SET @NewCode = NULL;
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = N'موظف محال للتحقيق';
    IF @EmpMasterId IS NULL
        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE N'%موظف محال للتحقيق%';
    IF @EmpMasterId IS NULL
    BEGIN
        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));
        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
        VALUES (@NewCode, N'موظف محال للتحقيق', N'موظف', N'ديوان عام الشركة', 1, GETDATE());
        SET @EmpMasterId = SCOPE_IDENTITY();
    END;
    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)
    BEGIN
        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
        VALUES (@InvId, @EmpMasterId, GETDATE());
    END;

END;

COMMIT TRANSACTION;
PRINT N'====================================================================';
PRINT N'✅ تم استيراد جميع التحقيقات بنجاح!';
PRINT N'إجمالي التحقيقات المضافة: 349 (194 نوع أ + 155 نوع ب)';
PRINT N'إجمالي التحقيقات الصادر بها قرارات ومنتهية: 30';
PRINT N'====================================================================';
