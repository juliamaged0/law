// generate_sql_349.js - generate complete standalone SQL query for exactly 349 investigations
const ExcelJS = require('exceljs');
const fs = require('fs');
const path = require('path');

function sqlEscape(val) {
    if (val === null || val === undefined || val === '') return 'NULL';
    const s = String(val).replace(/'/g, "''").trim();
    return `N'${s}'`;
}

function cleanText(txt) {
    if (!txt) return '';
    return String(txt)
        .replace(/\r?\n/g, ' ')
        .replace(/[\u200B-\u200D\uFEFF]/g, '')
        .replace(/\s+/g, ' ')
        .trim();
}

function normalizeArabic(txt) {
    if (!txt) return '';
    return String(txt)
        .replace(/[إأآا]/g, 'ا')
        .replace(/[ىي]/g, 'ي')
        .replace(/[ةه]/g, 'ه')
        .replace(/[\u064B-\u065F]/g, '')
        .trim();
}

function sanitizeDate(year, month, day) {
    let y = parseInt(year, 10);
    let m = parseInt(month, 10);
    let d = parseInt(day, 10);

    if (isNaN(y) || y < 1900 || y > 2100) y = 2026;

    if (m > 12 && d <= 12) {
        const tmp = m;
        m = d;
        d = tmp;
    }

    if (m < 1) m = 1;
    if (m > 12) m = 12;

    const isLeap = (y % 4 === 0 && y % 100 !== 0) || (y % 400 === 0);
    const maxDays = [31, isLeap ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][m - 1];

    if (d < 1) d = 1;
    if (d > maxDays) d = maxDays;

    return `${y}-${String(m).padStart(2, '0')}-${String(d).padStart(2, '0')}`;
}

function parseDate(val) {
    if (!val) return null;
    if (val instanceof Date) {
        if (isNaN(val.getTime())) return null;
        return sanitizeDate(val.getFullYear(), val.getMonth() + 1, val.getDate());
    }
    const str = String(val).trim();
    if (!str || str === 'null') return null;

    const isoMatch = str.match(/^(\d{4})-(\d{1,2})-(\d{1,2})/);
    if (isoMatch) {
        return sanitizeDate(isoMatch[1], isoMatch[2], isoMatch[3]);
    }

    const slashMatch = str.match(/(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})/);
    if (slashMatch) {
        return sanitizeDate(slashMatch[3], slashMatch[2], slashMatch[1]);
    }

    const shortMatch = str.match(/(\d{1,2})[\/\-](\d{1,2})/);
    if (shortMatch) {
        return sanitizeDate(2026, shortMatch[2], shortMatch[1]);
    }

    return null;
}

function extractDateFromText(text) {
    if (!text) return null;
    const m = text.match(/(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})/);
    if (m) {
        return sanitizeDate(m[3], m[2], m[1]);
    }
    const m2 = text.match(/(\d{1,2})[\/\-](\d{1,2})/);
    if (m2) {
        return sanitizeDate(2026, m2[2], m2[1]);
    }
    return null;
}

function extractCellValue(cell) {
    if (!cell) return null;
    let val = cell.value;
    if (val && typeof val === 'object') {
        if (val.richText) {
            val = val.richText.map(r => r.text).join('');
        } else if (val.result !== undefined) {
            val = (val.result && typeof val.result === 'object') ? null : val.result;
        } else if (val.text) {
            val = val.text;
        } else if (val.error) {
            return null;
        }
    }
    if (val instanceof Date) {
        val = val.toISOString().split('T')[0];
    }
    if (val && typeof val === 'object') return null;
    return val;
}

function extractMemoNumber(cell, rowNumber) {
    const expected = rowNumber - 2;
    if (!cell) return String(expected);
    const val = extractCellValue(cell);
    if (val === null || val === undefined) return String(expected);
    if (typeof val === 'number' && !isNaN(val) && val > 0) {
        return String(Math.round(val));
    }
    const str = String(val).trim();
    const num = parseInt(str, 10);
    if (!isNaN(num) && num > 0) {
        return String(num);
    }
    return String(expected);
}

function extractFinancialValue(topic, decision) {
    const combined = `${topic || ''} ${decision || ''}`;
    
    // Pattern 1: بمبلغ 15104318 جنيه / مبلغ 208029083 مصرى / بتكلفة 50 جنيه / 46000 جنيه / 600 جنيه
    const p1 = combined.match(/(?:بمبلغ|مبلغ|قيمة|تحميله|مبالغ|بتكلفة|تغريم الشركة)\s*[:\-]?\s*([0-9\.,]+)\s*(?:جنيهاً|جنيه|جنية|مصرى|مصري|ج)?/i);
    if (p1 && p1[1]) {
        const num = p1[1].replace(/,/g, '').trim();
        if (Number(num) > 0) {
            const currency = combined.includes('مصر') ? 'جنيه مصري' : 'جنيه';
            return `${num} ${currency}`;
        }
    }

    // Pattern 2: 15104318 جنيه
    const p2 = combined.match(/([0-9\.,]+)\s*(?:جنيهاً|جنيه|جنية)/i);
    if (p2 && p2[1]) {
        const num = p2[1].replace(/,/g, '').trim();
        if (Number(num) > 0) return `${num} جنيه`;
    }

    // Pattern 3: تفاوض مبلغ مالي
    if (combined.includes('مبلغ مالي') || combined.includes('مبالغ مالية')) {
        return 'مبلغ مالي';
    }

    return null;
}

function extractIncidentPlace(text) {
    if (!text) return 'ديوان عام الشركة';
    const t = cleanText(text);

    const patterns = [
        /(?:بمحطة|محطة|بمحطه|محطه)\s+([^\s\/\,\.\-]+(?:\s+[^\s\/\,\.\-]+){0,4})/i,
        /(?:بموقع|موقع)\s+([^\s\/\,\.\-]+(?:\s+[^\s\/\,\.\-]+){0,3})/i,
        /(?:بمنطقة|منطقة|بمنطقه|منطقه)\s+([^\s\/\,\.\-]+(?:\s+[^\s\/\,\.\-]+){0,3})/i,
        /(?:بإدارة|إدارة|بادارة|ادارة)\s+([^\s\/\,\.\-]+(?:\s+[^\s\/\,\.\-]+){0,3})/i,
        /(?:بمبنى|مبنى)\s+([^\s\/\,\.\-]+(?:\s+[^\s\/\,\.\-]+){0,3})/i,
        /(?:بمخزن|مخزن|مخازن|بالمخازن)\s+([^\s\/\,\.\-]+(?:\s+[^\s\/\,\.\-]+){0,3})/i,
        /(?:بحملة|حملة)\s+([^\s\/\,\.\-]+(?:\s+[^\s\/\,\.\-]+){0,3})/i,
        /(?:ببنزينة|بنزينة|بنزينه|ببنزينه)\s+([^\s\/\,\.\-]+(?:\s+[^\s\/\,\.\-]+){0,3})/i,
        /(?:بقطاع|قطاع)\s+([^\s\/\,\.\-]+(?:\s+[^\s\/\,\.\-]+){0,3})/i,
        /(?:بمسجد|مسجد)\s+([^\s\/\,\.\-]+(?:\s+[^\s\/\,\.\-]+){0,3})/i,
        /(?:بغرفة عمليات|غرفة عمليات)\s+([^\s\/\,\.\-]+(?:\s+[^\s\/\,\.\-]+){0,3})/i,
        /(?:مركز سيطرة|مركز سطرة)\s+([^\s\/\,\.\-]+(?:\s+[^\s\/\,\.\-]+){0,3})/i,
        /(?:مكتب)\s+([^\s\/\,\.\-]+(?:\s+[^\s\/\,\.\-]+){0,3})/i
    ];

    for (const pat of patterns) {
        const m = t.match(pat);
        if (m) {
            let place = m[0].trim();
            place = place.replace(/\s+(يوم|اثناء|أثناء|بتاريخ|تلاحظ|للسيد|للأستاذ|لعدم|الساعة|الساعه|وذلك|نظرا|نظراً).*$/, '').trim();
            if (place.length >= 4) return place;
        }
    }

    return 'ديوان عام الشركة';
}

function extractPartiesAndEmployees(text) {
    const t = cleanText(text);
    let plaintiff = '';
    let defendant = '';
    const employees = [];

    const titleRegex = /^(السيد|السيدة|الفني|الفنى|السائق|العامل|المهندس|م\/|أ\/|الأستاذ|الاستاذ|الكهربائي|حارس الامن|حارس الأمن|مشرف|مشرفي)\/?\s*/i;

    const pVsD = t.match(/(?:الشكوى المقدمة من|مذكرة مقدمة من|شكوى من|مقدمة من)\s+(.*?)\s+(?:ضد|علي|على)\s+(.*)/i);
    if (pVsD) {
        plaintiff = pVsD[1].replace(titleRegex, '').trim();
        defendant = pVsD[2].split(/(?:حيث|بشأن|بشان|لقيامه|لقيامها|نظراً|نظرا|بسبب|للتعدي|لتعدي)/i)[0].trim();
    } else {
        const vsMatch = t.match(/(?:ضد)\s+(.*)/i);
        if (vsMatch) {
            defendant = vsMatch[1].split(/(?:حيث|بشأن|بشان|لقيامه|نظراً|نظرا|بسبب|لعمل)/i)[0].trim();
        }

        const fromMatch = t.match(/(?:الشكوى المقدمة من|مذكرة من|شكوى من|تقرير من|مقدمة من)\s+(.*)/i);
        if (fromMatch) {
            plaintiff = fromMatch[1].split(/(?:بشأن|بشان|ضد|علي|على|حيث|نظرا)/i)[0].trim();
        }

        if (t.match(/^(مرور|المرور|مرور الامن|مرور الأمن|تفتيش|لجنة المرور)/i)) {
            plaintiff = 'إدارة الأمن والتفتيش';
        }
    }

    if (!defendant) {
        const empMatch = t.match(/(?:غياب|ترك عمل|ترك العمل|انقطاع|تغيب|مخالفة|امتناع|قيام|موقف العامل|السائق|الفني|الفنى|العامل|حارس الامن|الكهربائي)\s*(?:\/|\:)?\s*(?:كلا من|كل من|كلا من :|السيد\/|السيدة\/|السيد|السيدة|العامل\/|الفني\/|الفنى\/|السائق\/|م\/|أ\/)?\s*([^\s\/\,\.\-]+(?:\s+[^\s\/\,\.\-]+){1,4})/i);
        if (empMatch) {
            defendant = empMatch[1].split(/(?:يوم|بتاريخ|اثناء|أثناء|في|فى|عن|بسبب|اثناء النوة|بدون|بمحطة|بموقع|نام|عمل|مما|وقد|لعدم)/i)[0].trim();
        }
    }

    if (!defendant && t.includes('المحامي/')) {
        const lawyerRef = t.match(/المحام[يى]\/\s*([^\s\/\,\.\-]+(?:\s+[^\s\/\,\.\-]+){1,3})/i);
        if (lawyerRef) defendant = lawyerRef[1].trim();
    }

    if (!plaintiff) {
        plaintiff = 'شركة الصرف الصحي بالإسكندرية';
    }

    const codeMatches = t.matchAll(/(?:كود|كود\s*\-|رقم)\s*(\d{4,6})/gi);
    const codesFound = [];
    for (const cm of codeMatches) {
        codesFound.push(cm[1]);
    }

    const listMatches = t.matchAll(/(?:1|2|3|4|5|6)[\-\:]\s*([^\d\:\-\,\.\/]+?)(?=(?:2|3|4|5|6)[\-\:]|يوم|اثناء|بمحطة|بتاريخ|\.|\,|$)/gi);
    for (const lm of listMatches) {
        const nameClean = lm[1].replace(titleRegex, '').trim();
        if (nameClean.length >= 3 && !nameClean.includes('الوردية')) {
            employees.push({ name: nameClean, code: codesFound.shift() || null });
        }
    }

    if (employees.length === 0 && defendant) {
        const nameClean = defendant.replace(titleRegex, '').trim();
        if (nameClean.length >= 3) {
            employees.push({ name: nameClean, code: codesFound[0] || null });
        }
    }

    if (employees.length === 0) {
        employees.push({ name: 'موظف محال للتحقيق', code: null });
    }

    plaintiff = plaintiff.replace(/[\:\-\|\,\.]/g, '').trim();
    defendant = defendant ? defendant.replace(/[\:\-\|\,\.]/g, '').trim() : employees.map(e => e.name).join(', ');

    return { plaintiff, defendant, employees };
}

function parseDecision(decisionText) {
    if (!decisionText) return null;
    const raw = String(decisionText).trim();
    if (!raw || raw === 'null') return null;

    const norm = normalizeArabic(raw);
    const isDecided = norm.match(/انته[يا]|مجازا[هت]|خصم|حفظ|انذار|توصي[هت]|لفت نظر|علاو[هت]|خفض|ضم|تحميل/i);
    if (!isDecided) return null;

    let decisionType = '';
    let penaltyValue = '';

    if (norm.includes('حفظ')) {
        decisionType = 'حفظ التحقيق';
        penaltyValue = 'حفظ التحقيق';
    } else if (norm.includes('خصم') || norm.includes('مجازا')) {
        decisionType = 'مجازاة بخصم من الراتب';
    } else if (norm.includes('انذار')) {
        decisionType = 'إنذار وتنبيه';
        penaltyValue = 'إنذار';
    } else if (norm.includes('نقل') || norm.includes('توصي')) {
        decisionType = 'توصية بالنقل';
        penaltyValue = 'توصية بالنقل';
    } else if (norm.includes('علاو') || norm.includes('خفض')) {
        decisionType = 'خفض الأجر بمقدار العلاوة';
        penaltyValue = 'خفض العلاوة';
    } else if (norm.includes('ضم')) {
        decisionType = 'ضم التحقيق لملف آخر';
        penaltyValue = 'ضم الملف';
    } else {
        decisionType = 'قرار لجنة التحقيق';
    }

    const decisionOnly = raw.replace(/ورد من ر[\.\s]*م[\.\s]*أ.*?\|\s*/i, '');
    const days = decisionOnly.match(/(\d+|يوم|يومين|يومان|ثلاثة ايام|ثلاث ايام|اربعة ايام|اربع ايام|خمس ايام|خمسة ايام|اسبوع)\s*(?:ايام|أيام|يوم)?\s*(?:من الراتب|من راتبه|من راتبهم)?/i);
    if (days) {
        penaltyValue = days[0].trim();
    } else if (!penaltyValue) {
        penaltyValue = decisionOnly.substring(0, 50).trim();
    }

    return {
        isDecided: true,
        decisionType,
        penaltyValue,
        fullText: raw.replace(/\r?\n/g, ' ')
    };
}

async function main() {
    let sql = '';
    sql += `-- ==========================================================================\n`;
    sql += `-- SQL SCRIPT: RESTRUCTURE & IMPORT 349 INVESTIGATIONS (ديوان عام أ & ب 2026)\n`;
    sql += `-- Target Database: law_project\n`;
    sql += `-- Total Investigations: Exactly 349 (194 Type أ + 155 Type ب)\n`;
    sql += `-- Generated on: ${new Date().toISOString()}\n`;
    sql += `-- ==========================================================================\n\n`;

    sql += `USE [law_project];\n`;
    sql += `GO\n\n`;

    sql += `-- 1. التأكد من وجود الأعمدة الجديدة بجدول التحقيقات (Investigations)\n`;
    sql += `IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='Investigations' AND COLUMN_NAME='ClaimValue')\n`;
    sql += `BEGIN\n`;
    sql += `    ALTER TABLE Investigations ADD ClaimValue NVARCHAR(255) NULL;\n`;
    sql += `    PRINT N'✅ تم إضافة عمود ClaimValue (القيمة المادية) لجدول Investigations';\n`;
    sql += `END;\n`;
    sql += `GO\n\n`;

    sql += `IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='Investigations' AND COLUMN_NAME='ReceiptDate')\n`;
    sql += `BEGIN\n`;
    sql += `    ALTER TABLE Investigations ADD ReceiptDate DATE NULL;\n`;
    sql += `    PRINT N'✅ تم التأكد من عمود ReceiptDate بجدول Investigations';\n`;
    sql += `END;\n`;
    sql += `GO\n\n`;

    sql += `IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='Investigations' AND COLUMN_NAME='Plaintiff')\n`;
    sql += `BEGIN\n`;
    sql += `    ALTER TABLE Investigations ADD Plaintiff NVARCHAR(255) NULL;\n`;
    sql += `    PRINT N'✅ تم إضافة عمود Plaintiff (مرفوع من) لجدول Investigations';\n`;
    sql += `END;\n`;
    sql += `GO\n\n`;

    sql += `IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='Investigations' AND COLUMN_NAME='Defendant')\n`;
    sql += `BEGIN\n`;
    sql += `    ALTER TABLE Investigations ADD Defendant NVARCHAR(255) NULL;\n`;
    sql += `    PRINT N'✅ تم إضافة عمود Defendant (ضد) لجدول Investigations';\n`;
    sql += `END;\n`;
    sql += `GO\n\n`;

    sql += `-- 2. مسح بيانات التحقيقات القديمة بالترتيب الصحيح لمنع أخطاء الـ Foreign Keys وإدراج الـ 349 تحقيق\n`;
    sql += `SET NOCOUNT ON;\n`;
    sql += `BEGIN TRANSACTION;\n\n`;
    sql += `DECLARE @InvId INT;\n`;
    sql += `DECLARE @EmpMasterId INT;\n`;
    sql += `DECLARE @NewCode NVARCHAR(50);\n\n`;
    sql += `PRINT N'⏳ جاري مسح بيانات التحقيقات القديمة...';\n`;
    sql += `DELETE FROM InvestigationWitnesses;\n`;
    sql += `DELETE FROM FinalMemos;\n`;
    sql += `DELETE FROM FinalDecisions;\n`;
    sql += `DELETE FROM Appeals;\n`;
    sql += `DELETE FROM InvestigationDecisions;\n`;
    sql += `DELETE FROM Summons;\n`;
    sql += `DELETE FROM InvestigationEmployees;\n`;
    sql += `IF OBJECT_ID('InvestigationNotifications', 'U') IS NOT NULL DELETE FROM InvestigationNotifications WHERE EntityUrl LIKE '%investigation%';\n`;
    sql += `DELETE FROM Investigations;\n\n`;

    sql += `-- إعادة ضبط تسلسل الـ Identity لجدول Investigations\n`;
    sql += `DBCC CHECKIDENT ('Investigations', RESEED, 0);\n`;
    sql += `PRINT N'✅ تم مسح البيانات وتصفير عداد الـ Id للتحقيقات.';\n\n`;

    sql += `-- 3. إدراج التحقيقات الـ 349 من ملفات الإكسل\n`;
    sql += `PRINT N'⏳ جاري إدراج بيانات الـ 349 تحقيق...';\n\n`;

    let totalInserted = 0;
    let totalDecided = 0;

    // --- FILE A: Rows 3 to 196 (Exactly 194 investigations: 1 to 194) ---
    const wbA = new ExcelJS.Workbook();
    await wbA.xlsx.readFile('تحقيقات ديوان عام (أ)2026.xlsx');
    const wsA = wbA.worksheets[0];

    sql += `-- --------------------------------------------------------------------------\n`;
    sql += `-- تحقيقات ديوان عام (أ) 2026 (نوع أ) - من رقم 1 إلى رقم 194 (إجمالي: 194 تحقيق)\n`;
    sql += `-- --------------------------------------------------------------------------\n\n`;

    for (let r = 3; r <= 196; r++) {
        totalInserted++;
        const row = wsA.getRow(r);
        const memoNum = extractMemoNumber(row.getCell(1), r);

        const topicRaw = extractCellValue(row.getCell(3)) || '';
        const lawyerName = cleanText(extractCellValue(row.getCell(4))) || 'غير مسند';
        const presRaw = extractCellValue(row.getCell(5));
        const returnRaw = extractCellValue(row.getCell(6));
        const decRaw = extractCellValue(row.getCell(7));
        const recDate = parseDate(extractCellValue(row.getCell(8)));

        const place = extractIncidentPlace(topicRaw);
        const { plaintiff, defendant, employees } = extractPartiesAndEmployees(topicRaw);
        const claimValue = extractFinancialValue(topicRaw, decRaw);
        const dec = parseDecision(decRaw);
        const incDate = extractDateFromText(topicRaw) || recDate || '2026-01-01';
        const memoDate = recDate || incDate || '2026-01-01';

        const hasPres = (presRaw && String(presRaw).trim() !== '' && String(presRaw).trim() !== 'null') ||
                        (returnRaw && String(returnRaw).trim() !== '' && String(returnRaw).trim() !== 'null') ||
                        (decRaw && String(decRaw).includes('ورد من ر.م.أ'));
        
        const presDate = extractDateFromText(String(presRaw || '')) ||
                         extractDateFromText(String(decRaw || '')) ||
                         extractDateFromText(String(returnRaw || '')) ||
                         recDate || '2026-02-01';

        let status = 'جارية';
        if (dec && dec.isDecided) {
            status = 'مغلقة';
            totalDecided++;
        } else if (hasPres) {
            status = 'صدر قرار';
        }

        const summaryClean = cleanText(topicRaw) || (decRaw ? cleanText(decRaw) : `تحقيق ديوان عام أ رقم ${memoNum}`);

        sql += `BEGIN\n`;
        sql += `    SET @InvId = NULL;\n`;
        sql += `    SET @EmpMasterId = NULL;\n`;
        sql += `    INSERT INTO Investigations (\n`;
        sql += `        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,\n`;
        sql += `        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt\n`;
        sql += `    ) VALUES (\n`;
        sql += `        ${sqlEscape(memoNum)},\n`;
        sql += `        '${memoDate}',\n`;
        sql += `        ${recDate ? `'${recDate}'` : 'NULL'},\n`;
        sql += `        N'أ',\n`;
        sql += `        ${sqlEscape(lawyerName)},\n`;
        sql += `        ${sqlEscape(summaryClean.length > 250 ? summaryClean.substring(0, 247) + '...' : summaryClean)},\n`;
        sql += `        '${incDate}',\n`;
        sql += `        ${sqlEscape(place)},\n`;
        sql += `        ${sqlEscape(summaryClean)},\n`;
        sql += `        N'${status}',\n`;
        sql += `        ${sqlEscape(claimValue)},\n`;
        sql += `        ${sqlEscape(plaintiff)},\n`;
        sql += `        ${sqlEscape(defendant)},\n`;
        sql += `        '${memoDate} 09:00:00'\n`;
        sql += `    );\n`;
        sql += `    SET @InvId = SCOPE_IDENTITY();\n\n`;

        const uniqueEmployeesA = [];
        const seenNamesA = new Set();
        for (const emp of employees) {
            const empName = cleanText(emp.name);
            if (empName && !seenNamesA.has(empName)) {
                seenNamesA.add(empName);
                uniqueEmployeesA.push({ name: empName, code: emp.code ? String(emp.code).trim() : null });
            }
        }

        for (const emp of uniqueEmployeesA) {
            const empName = emp.name;
            const empCode = emp.code;
            sql += `    -- موظف: ${empName}\n`;
            sql += `    SET @EmpMasterId = NULL;\n`;
            sql += `    SET @NewCode = NULL;\n`;
            if (empCode) {
                sql += `    SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE Code = ${sqlEscape(empCode)};\n`;
            }
            sql += `    IF @EmpMasterId IS NULL\n`;
            sql += `        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = ${sqlEscape(empName)};\n`;
            sql += `    IF @EmpMasterId IS NULL\n`;
            sql += `        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE ${sqlEscape('%' + empName + '%')};\n`;
            sql += `    IF @EmpMasterId IS NULL\n`;
            sql += `    BEGIN\n`;
            if (empCode) {
                sql += `        IF NOT EXISTS (SELECT 1 FROM EmployeesMaster WHERE Code = ${sqlEscape(empCode)})\n`;
                sql += `            SET @NewCode = ${sqlEscape(empCode)};\n`;
                sql += `        ELSE\n`;
                sql += `            SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));\n`;
            } else {
                sql += `        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));\n`;
            }
            sql += `        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)\n`;
            sql += `        VALUES (@NewCode, ${sqlEscape(empName)}, N'موظف', ${sqlEscape(place)}, 1, GETDATE());\n`;
            sql += `        SET @EmpMasterId = SCOPE_IDENTITY();\n`;
            sql += `    END;\n`;
            sql += `    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)\n`;
            sql += `    BEGIN\n`;
            sql += `        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)\n`;
            sql += `        VALUES (@InvId, @EmpMasterId, GETDATE());\n`;
            sql += `    END;\n\n`;
        }

        if (hasPres || (dec && dec.isDecided)) {
            const decType = dec ? dec.decisionType : (hasPres ? 'عرض على رئيس مجلس الإدارة' : '');
            const penVal = dec ? dec.penaltyValue : '';
            const combinedNotes = cleanText(`${presRaw || ''} | ${returnRaw || ''} | ${decRaw || ''}`);

            sql += `    -- عرض ر.م.أ / القرار\n`;
            sql += `    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)\n`;
            sql += `    VALUES (@InvId, '${presDate}', N'رئيس مجلس الإدارة', ${sqlEscape(decType)}, ${sqlEscape(penVal)}, ${sqlEscape(combinedNotes)}, GETDATE());\n`;

            if (dec && dec.isDecided) {
                const actionType = dec.decisionType.includes('حفظ') ? 'archive' : 'hr';
                sql += `    INSERT INTO FinalDecisions (InvestigationId, FinalDecisionText, ActionType, HRSentDate, HRNotes, CreatedAt)\n`;
                sql += `    VALUES (@InvId, ${sqlEscape(dec.fullText)}, '${actionType}', '${presDate}', ${sqlEscape(combinedNotes)}, GETDATE());\n`;
            }
            sql += `\n`;
        }

        sql += `END;\n\n`;
    }

    // --- FILE B: Rows 3 to 157 (Exactly 155 investigations: 1 to 155) ---
    const wbB = new ExcelJS.Workbook();
    await wbB.xlsx.readFile('تحقيقات ديوان عام (ب) 2026.xlsx');
    const wsB = wbB.worksheets[0];

    sql += `-- --------------------------------------------------------------------------\n`;
    sql += `-- تحقيقات ديوان عام (ب) 2026 (نوع ب) - من رقم 1 إلى رقم 155 (إجمالي: 155 تحقيق)\n`;
    sql += `-- --------------------------------------------------------------------------\n\n`;

    for (let r = 3; r <= 157; r++) {
        totalInserted++;
        const row = wsB.getRow(r);
        const memoNum = extractMemoNumber(row.getCell(1), r);

        const topicRaw = extractCellValue(row.getCell(3)) || '';
        const lawyerName = cleanText(extractCellValue(row.getCell(4))) || 'غير مسند';
        const presRaw = extractCellValue(row.getCell(5));
        const decRaw = extractCellValue(row.getCell(6));
        const recDate = parseDate(extractCellValue(row.getCell(7)));

        const place = extractIncidentPlace(topicRaw);
        const { plaintiff, defendant, employees } = extractPartiesAndEmployees(topicRaw);
        const claimValue = extractFinancialValue(topicRaw, decRaw);
        const dec = parseDecision(decRaw);
        const incDate = extractDateFromText(topicRaw) || recDate || '2026-01-01';
        const memoDate = recDate || incDate || '2026-01-01';

        const hasPres = (presRaw && String(presRaw).trim() !== '' && String(presRaw).trim() !== 'null') ||
                        (decRaw && String(decRaw).includes('ورد من ر.م.أ'));
        
        const presDate = extractDateFromText(String(presRaw || '')) ||
                         extractDateFromText(String(decRaw || '')) ||
                         recDate || '2026-02-01';

        let status = 'جارية';
        if (dec && dec.isDecided) {
            status = 'مغلقة';
            totalDecided++;
        } else if (hasPres) {
            status = 'صدر قرار';
        }

        const summaryClean = cleanText(topicRaw) || (decRaw ? cleanText(decRaw) : `تحقيق ديوان عام ب رقم ${memoNum}`);

        sql += `BEGIN\n`;
        sql += `    SET @InvId = NULL;\n`;
        sql += `    SET @EmpMasterId = NULL;\n`;
        sql += `    INSERT INTO Investigations (\n`;
        sql += `        MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,\n`;
        sql += `        IncidentDate, IncidentPlace, IncidentDescription, [Status], ClaimValue, Plaintiff, Defendant, CreatedAt\n`;
        sql += `    ) VALUES (\n`;
        sql += `        ${sqlEscape(memoNum)},\n`;
        sql += `        '${memoDate}',\n`;
        sql += `        ${recDate ? `'${recDate}'` : 'NULL'},\n`;
        sql += `        N'ب',\n`;
        sql += `        ${sqlEscape(lawyerName)},\n`;
        sql += `        ${sqlEscape(summaryClean.length > 250 ? summaryClean.substring(0, 247) + '...' : summaryClean)},\n`;
        sql += `        '${incDate}',\n`;
        sql += `        ${sqlEscape(place)},\n`;
        sql += `        ${sqlEscape(summaryClean)},\n`;
        sql += `        N'${status}',\n`;
        sql += `        ${sqlEscape(claimValue)},\n`;
        sql += `        ${sqlEscape(plaintiff)},\n`;
        sql += `        ${sqlEscape(defendant)},\n`;
        sql += `        '${memoDate} 09:00:00'\n`;
        sql += `    );\n`;
        sql += `    SET @InvId = SCOPE_IDENTITY();\n\n`;

        const uniqueEmployeesB = [];
        const seenNamesB = new Set();
        for (const emp of employees) {
            const empName = cleanText(emp.name);
            if (empName && !seenNamesB.has(empName)) {
                seenNamesB.add(empName);
                uniqueEmployeesB.push({ name: empName, code: emp.code ? String(emp.code).trim() : null });
            }
        }

        for (const emp of uniqueEmployeesB) {
            const empName = emp.name;
            const empCode = emp.code;
            sql += `    -- موظف: ${empName}\n`;
            sql += `    SET @EmpMasterId = NULL;\n`;
            sql += `    SET @NewCode = NULL;\n`;
            if (empCode) {
                sql += `    SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE Code = ${sqlEscape(empCode)};\n`;
            }
            sql += `    IF @EmpMasterId IS NULL\n`;
            sql += `        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName = ${sqlEscape(empName)};\n`;
            sql += `    IF @EmpMasterId IS NULL\n`;
            sql += `        SELECT TOP 1 @EmpMasterId = Id FROM EmployeesMaster WHERE FullName LIKE ${sqlEscape('%' + empName + '%')};\n`;
            sql += `    IF @EmpMasterId IS NULL\n`;
            sql += `    BEGIN\n`;
            if (empCode) {
                sql += `        IF NOT EXISTS (SELECT 1 FROM EmployeesMaster WHERE Code = ${sqlEscape(empCode)})\n`;
                sql += `            SET @NewCode = ${sqlEscape(empCode)};\n`;
                sql += `        ELSE\n`;
                sql += `            SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));\n`;
            } else {
                sql += `        SET @NewCode = N'TMP-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(20));\n`;
            }
            sql += `        INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)\n`;
            sql += `        VALUES (@NewCode, ${sqlEscape(empName)}, N'موظف', ${sqlEscape(place)}, 1, GETDATE());\n`;
            sql += `        SET @EmpMasterId = SCOPE_IDENTITY();\n`;
            sql += `    END;\n`;
            sql += `    IF @EmpMasterId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM InvestigationEmployees WHERE InvestigationId = @InvId AND EmployeeMasterId = @EmpMasterId)\n`;
            sql += `    BEGIN\n`;
            sql += `        INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)\n`;
            sql += `        VALUES (@InvId, @EmpMasterId, GETDATE());\n`;
            sql += `    END;\n\n`;
        }

        if (hasPres || (dec && dec.isDecided)) {
            const decType = dec ? dec.decisionType : (hasPres ? 'عرض على رئيس مجلس الإدارة' : '');
            const penVal = dec ? dec.penaltyValue : '';
            const combinedNotes = cleanText(`${presRaw || ''} | ${decRaw || ''}`);

            sql += `    -- عرض ر.م.أ / القرار\n`;
            sql += `    INSERT INTO InvestigationDecisions (InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes, CreatedAt)\n`;
            sql += `    VALUES (@InvId, '${presDate}', N'رئيس مجلس الإدارة', ${sqlEscape(decType)}, ${sqlEscape(penVal)}, ${sqlEscape(combinedNotes)}, GETDATE());\n`;

            if (dec && dec.isDecided) {
                const actionType = dec.decisionType.includes('حفظ') ? 'archive' : 'hr';
                sql += `    INSERT INTO FinalDecisions (InvestigationId, FinalDecisionText, ActionType, HRSentDate, HRNotes, CreatedAt)\n`;
                sql += `    VALUES (@InvId, ${sqlEscape(dec.fullText)}, '${actionType}', '${presDate}', ${sqlEscape(combinedNotes)}, GETDATE());\n`;
            }
            sql += `\n`;
        }

        sql += `END;\n\n`;
    }

    sql += `COMMIT TRANSACTION;\n`;
    sql += `PRINT N'====================================================================';\n`;
    sql += `PRINT N'✅ تم استيراد جميع التحقيقات بنجاح!';\n`;
    sql += `PRINT N'إجمالي التحقيقات المضافة: ${totalInserted} (194 نوع أ + 155 نوع ب)';\n`;
    sql += `PRINT N'إجمالي التحقيقات الصادر بها قرارات ومنتهية: ${totalDecided}';\n`;
    sql += `PRINT N'====================================================================';\n`;

    const outputPath = path.join(__dirname, 'import_investigations.sql');
    fs.writeFileSync(outputPath, sql, 'utf8');

    console.log(`\nGenerated SQL Script successfully at: ${outputPath}`);
    console.log(`File Size: ${(fs.statSync(outputPath).size / 1024).toFixed(2)} KB`);
    console.log(`Total Investigations Generated: ${totalInserted}`);
    console.log(`Total Decided: ${totalDecided}`);
}

main().catch(err => console.error(err));
