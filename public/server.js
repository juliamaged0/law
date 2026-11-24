// server.js - خادم Node.js مع SQL Server
// نظام إدارة الشؤون القانونية - شركة الصرف الصحي

const express = require('express');
const compression = require('compression');
const cors = require('cors');
const bodyParser = require('body-parser');
const path = require('path');
const bcrypt = require('bcryptjs'); // ✅ لتشفير كلمات مرور يوزرز التحقيقات (نظام Users/Roles الحقيقي)
require('dotenv').config();

const db = require('./db');

const app = express();

// ============================================
// دالة مشتركة لتنسيق وقت الجلسة (مخزّن كنص VARCHAR وليس Date)
// ============================================
function formatSessionTime(timeValue) {
    if (!timeValue) return null;
    if (typeof timeValue === 'string') {
        if (timeValue.length >= 8 && timeValue.includes(':')) {
            return timeValue.slice(0, 5);
        }
        return timeValue;
    }
    return String(timeValue);
}
const PORT = process.env.PORT || 3000;

// Middleware
app.use(compression()); // ✅ تفعيل ضغط البيانات قبل الإرسال
app.use(cors());
app.use(bodyParser.json({ limit: '50mb' }));
app.use(bodyParser.urlencoded({ extended: true, limit: '50mb' }));

// ===== أخطاء "ناعمة" اختيارية (opt-in) =====
// لو الطلب فيه الهيدر X-Soft-Errors: 1 بنرد بـ HTTP 200 حتى في حالة الخطأ (success:false + message جوّه الـ JSON).
// ليه؟ بعض الـ Web Servers (زي IIS قدّام Node عبر iisnode/ARR) بتستبدل جسم أي رد 4xx/5xx بصفحة HTML عامة
// (HTTP Error 500)، فبتضيع رسالة الخطأ الحقيقية والصفحة مش بتقدر تقرأ الـ JSON.
// الطلبات اللي مفيهاش الهيدر (باقي الصفحات) بتشتغل زي ما هي بدون أي تغيير.
app.use('/api', (req, res, next) => {
    if (req.get('X-Soft-Errors') === '1') {
        const originalStatus = res.status.bind(res);
        res.status = (code) => {
            if (code >= 400) {
                res.set('X-Original-Status', String(code));
                return originalStatus(200);
            }
            return originalStatus(code);
        };
    }
    next();
});

// ===== ✅ خدمة الملفات الثابتة =====
app.use(express.static(path.join(__dirname, 'public')));

// ===== الصفحة الرئيسية =====
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// ============================================
// 1. اختبار الاتصال بقاعدة البيانات
// ============================================
app.get('/api/test', async (req, res) => {
    try {
        const result = await db.query("SELECT GETDATE() AS CurrentTime");
        res.json({
            success: true,
            message: '✅ الاتصال بقاعدة البيانات ناجح!',
            data: result
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: '❌ فشل الاتصال بقاعدة البيانات',
            error: error.message
        });
    }
});

// ============================================
// جلب جميع القضايا - مع درجات التقاضي كقضايا فرعية
// ============================================
app.get('/api/cases', async (req, res) => {
    try {
        const { search, stage, status } = req.query;
        
        // ===== 1. جلب جميع القضايا الأساسية =====
        let parentSql = `
            SELECT 
                c.Id,
                c.CaseNumber,
                c.CaseYear,
                c.CaseType,
                CAST(c.Subject AS NVARCHAR(MAX)) AS Subject,
                CAST(c.Description AS NVARCHAR(MAX)) AS Description,
                c.Category,
                c.CurrentStage,
                c.[Status],
                c.FilingDate,
                c.CreatedAt,
                c.AssignedLawyerId,
                c.CourtName,
                c.CircuitName,
                CAST(COALESCE(c.Plaintiff, c.Defendant, '') AS NVARCHAR(MAX)) AS Opponent,
                CAST(c.Notes AS NVARCHAR(MAX)) AS Notes,
                COALESCE(c.ClaimValue, c.ClaimAmount) AS ClaimValue,
                c.LawsuitExpenses,
                c.CaseExpenses,
                NULL AS FirstPartyType,
                NULL AS FiledBy,
                CAST(c.Plaintiff AS NVARCHAR(MAX)) AS Plaintiff,
                CAST(c.Defendant AS NVARCHAR(MAX)) AS Defendant,
                c.Agginst AS Agginst,
                l.FullName AS LawyerName,
                l.Code AS LawyerCode,
                0 AS SessionsCount,
                (
                    SELECT TOP 1 CAST(s_inner.ActionTaken AS NVARCHAR(MAX))
                    FROM Sessions s_inner
                    WHERE s_inner.CaseId = c.Id
                      AND s_inner.ActionTaken IS NOT NULL
                      AND s_inner.ActionTaken <> ''
                    ORDER BY s_inner.SessionDate DESC, s_inner.CreatedAt DESC
                ) AS LatestSessionAction
            FROM Cases c 
            LEFT JOIN Lawyers l ON c.AssignedLawyerId = l.Id
            WHERE 1=1
        `;
        
        const params = [];
        let paramIndex = 0;
        
        if (search) {
            parentSql += ` AND (c.CaseNumber LIKE @p${paramIndex} OR c.Subject LIKE @p${paramIndex} OR l.FullName LIKE @p${paramIndex} OR c.Description LIKE @p${paramIndex} OR c.Notes LIKE @p${paramIndex})`;
            params.push(`%${search}%`);
            paramIndex++;
        }
        
        if (status) {
            parentSql += ` AND c.[Status] = @p${paramIndex}`;
            params.push(status);
            paramIndex++;
        }
        
        parentSql += ` ORDER BY c.CreatedAt DESC`;
        
        const parentCases = await db.query(parentSql, params);
        
        // ===== 2. جلب جميع درجات التقاضي - استبعاد Source = 'session' =====
        let litigationSql = `
            SELECT 
                l.Id,
                l.CaseId,
                l.TrackingCode,
                l.StageType,
                l.StageNumber,
                l.CourtName,
                l.[الدائرة] AS CircuitName,
                l.RequestedBy,
                l.LawyerId,
                l.LawyerName,
                l.LaunchDate,
                l.[Status],
                CAST(l.Notes AS NVARCHAR(MAX)) AS Notes,
                CAST(l.Subject AS NVARCHAR(MAX)) AS LitigationSubject,
                l.ClaimAmount,
                l.CreatedAt,
                CAST(c.Subject AS NVARCHAR(MAX)) AS ParentSubject,
                CAST(COALESCE(c.Plaintiff, '') AS NVARCHAR(MAX)) AS ParentPlaintiff,
                CAST(COALESCE(c.Defendant, '') AS NVARCHAR(MAX)) AS ParentDefendant,
                CAST(COALESCE(l.Plaintiff, '') AS NVARCHAR(MAX)) AS Plaintiff,
                CAST(COALESCE(l.Defendant, '') AS NVARCHAR(MAX)) AS Defendant,
                c.Category AS ParentCategory,
                CAST(COALESCE(c.Plaintiff, c.Defendant, '') AS NVARCHAR(MAX)) AS ParentOpponent,
                c.AssignedLawyerId AS ParentLawyerId,
                c.CircuitName AS ParentCircuitName,
                l2.FullName AS LawyerFullName,
                NULL AS Source,
                NULL AS LatestSessionAction
            FROM LitigationLevels l
            LEFT JOIN Cases c ON l.CaseId = c.Id
            LEFT JOIN Lawyers l2 ON c.AssignedLawyerId = l2.Id
            WHERE (l.TrackingCode IS NULL OR l.TrackingCode <> c.CaseNumber)
        `;

        
        const litParams = [];
        let litIndex = 0;
        
        if (stage) {
            litigationSql += ` AND (l.StageType = @p${litIndex} OR l.StageType = @p${litIndex + 1})`;
            litParams.push(stage);
            litParams.push(stage === 'استئناف' ? 'appeal' : stage === 'نقض' ? 'cassation' : stage === 'إشكال' || stage === 'اشكال' ? 'eshkal' : stage.includes('تنفيذ') ? 'eshkal_tanfeeth' : stage.includes('التماس') ? 'iltimas' : stage);
            litIndex += 2;
        }
        
        if (status) {
            litigationSql += ` AND l.[Status] = @p${litIndex}`;
            litParams.push(status);
            litIndex++;
        }
        
        litigationSql += ` ORDER BY l.CreatedAt DESC`;
        
        const litigationLevels = await db.query(litigationSql, litParams);

        // دالة مساعدة لترجمة نوع درجة التقاضي إلى العربية
        const formatStageToArabic = (st) => {
            if (!st) return 'ابتدائي';
            const s = String(st).toLowerCase().trim();
            if (s === 'first_instance' || s === 'first-instance' || s === 'firstinstance' || s === 'initial' || s === 'primary' || s === 'ابتدائي' || s === 'ابتدائية') return 'ابتدائي';
            if (s === 'appeal' || s === 'استئناف') return 'استئناف';
            if (s === 'cassation' || s === 'نقض' || s === 'طعن بالنقض') return 'نقض';
            if (s === 'eshkal' || s === 'اشكال' || s === 'إشكال') return 'إشكال';
            if (s === 'eshkal_tanfeeth' || s === 'execution' || s === 'اشكال في التنفيذ' || s === 'إشكال في التنفيذ' || s === 'اشكال فى التنفيذ' || s === 'إشكال فى التنفيذ') return 'إشكال في التنفيذ';
            if (s === 'iltimas' || s === 'التماس' || s === 'التماس إعادة النظر' || s === 'التماس اعادة النظر' || s === 'اعادة التماس فى النظر') return 'التماس إعادة النظر';
            return st;
        };
        
        // ===== 3. دمج القضايا ودرجات التقاضي =====
        const resultCases = [];
        
        // تجميع درجات التقاضي حسب CaseId في Hash Map لتحسين الأداء (أصبح O(N) بدلاً من O(N^2))
        const levelsByCaseId = new Map();
        for (const lvl of litigationLevels) {
            if (!levelsByCaseId.has(lvl.CaseId)) {
                levelsByCaseId.set(lvl.CaseId, []);
            }
            levelsByCaseId.get(lvl.CaseId).push(lvl);
        }

        // إضافة القضايا الأساسية أولاً
        for (const parent of parentCases) {
            let finalStatus = parent.Status || 'مفتوحة';
            let finalStage = parent.CurrentStage || 'ابتدائي';
            let finalCategory = parent.Category || parent.CaseType || 'مدني';
            let plaintiff = parent.Plaintiff;
            let defendant = parent.Defendant;
            
            const childLevels = levelsByCaseId.get(parent.Id) || [];
            
            if (childLevels.length > 0) {
                // childLevels مرتب تنازلياً حسب CreatedAt DESC، وبالتالي childLevels[0] هو الأحدث
                const latestLevel = childLevels[0];
                finalStage = formatStageToArabic(latestLevel.StageType);
                parent.CurrentStage = finalStage;
                
                if (latestLevel.Status === 'closed' || latestLevel.Status === 'مغلقة') {
                    finalStatus = 'مغلقة';
                }

                // إذا كانت القضية لا تحتوي على اسم مدعى عليه واضح، نأخذه من أحدث درجة تقاضي
                if ((!defendant || defendant === 'الخصم' || defendant === '—') && latestLevel.Defendant && latestLevel.Defendant !== '—') {
                    defendant = latestLevel.Defendant;
                }
                if ((!plaintiff || plaintiff === 'الشركة' || plaintiff === '—') && latestLevel.Plaintiff && latestLevel.Plaintiff !== '—') {
                    plaintiff = latestLevel.Plaintiff;
                }
                if ((!finalCategory || finalCategory === '—') && latestLevel.CaseCategory) {
                    finalCategory = latestLevel.CaseCategory;
                }
            }
            
            if (!plaintiff || !defendant) {
                const opp = parent.Opponent || 'الخصم';
                const comp = 'شركة الصرف الصحي بالإسكندرية';
                if (parent.FiledBy === 'الخصم' || parent.FirstPartyType === 'الخصم') {
                    plaintiff = plaintiff || opp;
                    defendant = defendant || comp;
                } else {
                    plaintiff = plaintiff || comp;
                    defendant = defendant || opp;
                }
            }
            
            resultCases.push({
                ...parent,
                Category: finalCategory,
                Plaintiff: plaintiff,
                Defendant: defendant,
                CurrentStage: finalStage,
                Status: finalStatus,
                IsParent: true,
                ChildLevels: childLevels.map(l => ({
                    ...l,
                    IsParent: false,
                    ParentId: parent.Id,
                    ParentNumber: parent.CaseNumber,
                    CaseNumber: l.TrackingCode || parent.CaseNumber,
                    CurrentStage: formatStageToArabic(l.StageType),
                    Status: l.Status === 'closed' ? 'مغلقة' : 'مفتوحة',
                    Subject: l.LitigationSubject || l.ParentSubject || parent.Subject || `درجة ${formatStageToArabic(l.StageType)}`,
                    Category: l.ParentCategory || parent.Category || 'مدني',
                    Opponent: l.ParentOpponent || parent.Opponent || '—',
                    LawyerName: l.LawyerFullName || parent.LawyerName || 'غير مسند',
                    CourtName: l.CourtName || parent.CourtName || '',
                    CircuitName: l.CircuitName || l.ParentCircuitName || parent.CircuitName || '',
                    Plaintiff: l.Plaintiff || (l.RequestedBy === 'الخصم' ? (l.ParentDefendant || l.ParentOpponent) : (l.ParentPlaintiff || parent.Plaintiff)) || '',
                    Defendant: l.Defendant || (l.RequestedBy === 'الخصم' ? (l.ParentPlaintiff || parent.Plaintiff) : (l.ParentDefendant || l.ParentOpponent)) || '',
                    FilingDate: l.LaunchDate || parent.FilingDate || null,
                    Notes: l.Notes || parent.Notes || '',
                    SessionsCount: 0,
                    Source: l.Source || 'litigation'
                }))
            });
        }
        
        // إضافة درجات التقاضي التي ليس لها قضية أم (حالة نادرة)
        const parentIdsSet = new Set(parentCases.map(p => p.Id));
        const orphanLevels = litigationLevels.filter(l => 
            !parentIdsSet.has(l.CaseId)
        );
        
        for (const orphan of orphanLevels) {
            resultCases.push({
                Id: `lit-${orphan.Id}`,
                CaseNumber: orphan.TrackingCode || `درجة-${orphan.Id}`,
                CaseYear: orphan.LaunchDate ? new Date(orphan.LaunchDate).getFullYear().toString() : '2026',
                CaseType: orphan.StageType || 'مدني',
                Subject: orphan.ParentSubject || `درجة ${formatStageToArabic(orphan.StageType)}`,
                Description: orphan.Notes || '',
                Category: orphan.ParentCategory || 'مدني',
                CurrentStage: formatStageToArabic(orphan.StageType),
                Status: orphan.Status === 'closed' ? 'مغلقة' : 'مفتوحة',
                FilingDate: orphan.LaunchDate || null,
                CreatedAt: orphan.CreatedAt || null,
                AssignedLawyerId: orphan.ParentLawyerId || null,
                CourtName: orphan.CourtName || '',
                CircuitName: '',
                Opponent: orphan.ParentOpponent || '—',
                Notes: orphan.Notes || '',
                LawyerName: orphan.LawyerFullName || 'غير مسند',
                LawyerCode: null,
                SessionsCount: 0,
                IsParent: false,
                ChildLevels: [],
                IsOrphan: true,
                Source: orphan.Source || 'litigation'
            });
        }
        
        // ===== 4. تطبيق فلتر البحث على النتيجة النهائية =====
        let finalResults = resultCases;
        
        if (search) {
            const searchLower = search.toLowerCase();
            finalResults = finalResults.filter(c => 
                (c.CaseNumber || '').toLowerCase().includes(searchLower) ||
                (c.Subject || '').toLowerCase().includes(searchLower) ||
                (c.LawyerName || '').toLowerCase().includes(searchLower) ||
                (c.Opponent || '').toLowerCase().includes(searchLower) ||
                (c.Description || '').toLowerCase().includes(searchLower) ||
                (c.Notes || '').toLowerCase().includes(searchLower)
            );
        }
        
        if (stage) {
            const targetArabic = formatStageToArabic(stage).toLowerCase();
            finalResults = finalResults.filter(c => {
                const itemArabic = formatStageToArabic(c.CurrentStage).toLowerCase();
                return itemArabic === targetArabic ||
                       (c.CurrentStage || '').toLowerCase() === stage.toLowerCase();
            });
        }
        
        if (status) {
            finalResults = finalResults.filter(c => 
                (c.Status || '').toLowerCase() === status.toLowerCase()
            );
        }
        
        res.json({
            success: true,
            data: finalResults,
            count: finalResults.length,
            parentCount: parentCases.length,
            litigationCount: litigationLevels.length
        });
        
    } catch (error) {
        console.error('❌ خطأ في جلب القضايا:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

// ============================================
// 3. جلب قضية برقمها (مع المحكمة والدائرة)
// ============================================
app.get('/api/cases/by-number/:caseNumber', async (req, res) => {
    try {
        const { caseNumber } = req.params;
        
        console.log('🔍 البحث عن قضية برقم:', caseNumber);
        
        let sql = `
            SELECT 
                c.Id,
                c.CaseNumber,
                c.CaseYear,
                c.CaseType,
                c.Subject,
                c.Description,
                c.Category,
                c.CurrentStage,
                c.[Status],
                c.FilingDate,
                c.AssignedLawyerId,
                c.CourtName,
                c.CircuitName,
                COALESCE(c.Plaintiff, c.Defendant, '') AS Opponent,
                l.FullName AS LawyerName,
                l.Code AS LawyerCode,
                l.Mobile AS LawyerMobile
            FROM Cases c
            LEFT JOIN Lawyers l ON c.AssignedLawyerId = l.Id
            WHERE c.CaseNumber = @p0
        `;
        
        let result = await db.query(sql, [caseNumber]);
        
        if (result.length === 0 && caseNumber.includes('-')) {
            const parts = caseNumber.split('-');
            if (parts.length === 3) {
                const baseNumber = `${parts[0]}-${parts[1]}`;
                result = await db.query(sql, [baseNumber]);
            }
        }
        
        if (result.length === 0 && caseNumber.includes('-')) {
            const parts = caseNumber.split('-');
            if (parts.length === 3) {
                const numberOnly = parts[1];
                let searchSql = sql.replace("c.CaseNumber = @p0", "c.CaseNumber LIKE @p0");
                result = await db.query(searchSql, [`%-${numberOnly}-%`]);
            }
        }

        if (result.length === 0 && caseNumber.includes('/')) {
            const parts = caseNumber.split('/');
            const numberOnly = parts[0].replace(/\D/g, '');
            if (numberOnly) {
                let searchSql = sql.replace("c.CaseNumber = @p0", "(c.CaseNumber = @p0 OR c.CaseNumber LIKE @p1 OR c.CaseNumber LIKE @p2)");
                result = await db.query(searchSql, [caseNumber, `%${numberOnly}/%`, `%${numberOnly}%`]);
            }
        }

        if (result.length === 0) {
            const pureNumber = String(caseNumber).replace(/\D/g, '');
            if (pureNumber) {
                let searchSql = sql.replace("c.CaseNumber = @p0", "(c.CaseNumber = @p0 OR c.CaseNumber LIKE @p1 OR c.CaseNumber LIKE @p2)");
                result = await db.query(searchSql, [caseNumber, `%${caseNumber}%`, `%${pureNumber}%`]);
            }
        }
        
        if (result.length === 0) {
            return res.json({
                success: false,
                message: 'لم يتم العثور على القضية'
            });
        }
        
        const caseData = result[0];
        
        const parties = await db.query(
            `SELECT Id, PartyType, PartyCategory, Name, [Position], Mobile, LawyerName, LawyerMobile 
             FROM CaseParties 
             WHERE CaseId = @p0`,
            [caseData.Id]
        );
        
        const sessions = await db.query(
            `SELECT Id, SessionDate, SessionTime, Stage, [Status], ActionTaken 
             FROM Sessions 
             WHERE CaseId = @p0 
             ORDER BY SessionDate DESC`,
            [caseData.Id]
        );
        
        let opponent = caseData.Opponent || '—';
        let opponentMobile = '—';
        let party1Name = '';
        let party1Mobile = '';
        
        parties.forEach(p => {
            if (p.PartyType === 'first') {
                party1Name = p.Name || '';
                party1Mobile = p.Mobile || '';
            } else if (p.PartyType === 'second') {
                opponent = p.Name || opponent;
                opponentMobile = p.Mobile || '';
            }
        });
        
        res.json({
            success: true,
            data: {
                ...caseData,
                Party1: party1Name,
                Party1Mobile: party1Mobile,
                Opponent: opponent,
                OpponentMobile: opponentMobile,
                Parties: parties,
                Sessions: sessions,
                SessionsCount: sessions.length
            }
        });
        
    } catch (error) {
        console.error('❌ خطأ في جلب القضية:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

// ============================================
// 4. إضافة قضية جديدة (مع المحكمة والدائرة)
// ============================================
// ============================================
// 4. إضافة قضية جديدة
// ============================================
// ============================================
// 4. إضافة قضية جديدة
// ============================================
app.post('/api/cases', async (req, res) => {
    try {
        const {
            caseNumber,
            caseYear,
            caseType,
            subject,
            description,
            category,
            currentStage,
            status,
            filingDate,
            createdBy = 1,
            assignedLawyerId = null,
            parties = [],
            firstSession = null,
            courtName = null,
            circuitName = null,
            opponent = null,
            notes = null,  // ✅ إضافة الملاحظات الخاصة
            claimValue = null,
            claimAmount = null, // ✅ للتوافق مع الإصدارات القديمة من الفورم
            lawsuitExpenses = null,
            firstPartyType = 'الشركة',
            filedBy = 'الشركة',
            plaintiff = null,
            defendant = null
        } = req.body;

        const opponentValue = opponent || null;
        const descriptionValue = description || '';
        const notesValue = notes || '';  // ✅ إضافة الملاحظات
        const categoryValue = category || caseType || 'مدني';
        const claimValueValue = claimValue || claimAmount || null;

        const compName = 'شركة الصرف الصحي بالإسكندرية';
        const finalPlaintiff = plaintiff || (filedBy === 'الشركة' ? compName : (opponentValue || 'الخصم'));
        const finalDefendant = defendant || (filedBy === 'الشركة' ? (opponentValue || 'الخصم') : compName);

        const transaction = new db.sql.Transaction(db.pool);
        await transaction.begin();

        try {
            let lawyerId = null;
            if (assignedLawyerId) {
                const checkLawyer = await db.query(
                    "SELECT Id FROM Lawyers WHERE Id = @p0 AND IsActive = 1",
                    [assignedLawyerId]
                );
                if (checkLawyer.length > 0) {
                    lawyerId = assignedLawyerId;
                }
            }

            const caseSql = `
                INSERT INTO Cases (
                    CaseNumber, CaseYear, CaseType, Subject, Description,
                    Category, CurrentStage, [Status], FilingDate, CreatedBy, AssignedLawyerId,
                    CourtName, CircuitName, Notes, ClaimValue, LawsuitExpenses,
                    Plaintiff, Defendant
                ) VALUES (
                    @p0, @p1, @p2, @p3, @p4,
                    @p5, @p6, @p7, @p8, @p9, @p10,
                    @p11, @p12, @p13, @p14, @p15,
                    @p16, @p17
                );
                SELECT SCOPE_IDENTITY() AS Id;
            `;

            const caseResult = await db.query(caseSql, [
                caseNumber, 
                caseYear, 
                caseType, 
                subject, 
                descriptionValue,
                categoryValue,
                currentStage || 'ابتدائي',
                status || 'متداولة',
                filingDate || new Date().toISOString().split('T')[0],
                createdBy,
                lawyerId,
                courtName || null,
                circuitName || null,
                notesValue,
                claimValueValue,
                lawsuitExpenses || null,
                finalPlaintiff,
                finalDefendant
            ]);

            const caseId = caseResult[0]?.Id;

            if (!caseId) {
                throw new Error('فشل في إنشاء القضية');
            }

            console.log('✅ تم إنشاء القضية برقم ID:', caseId);

            // ===== إضافة الأطراف =====
            if (parties && parties.length > 0) {
                const partySql = `
                    INSERT INTO CaseParties (
                        CaseId, PartyType, PartyCategory, Name,
                        [Position], Mobile, LawyerName, LawyerMobile
                    ) VALUES (
                        @p0, @p1, @p2, @p3, @p4, @p5, @p6, @p7
                    )
                `;

                for (const party of parties) {
                    if (party.category === 'مجموعة' && party.members) {
                        for (const member of party.members) {
                            await db.query(partySql, [
                                caseId,
                                party.type || 'second',
                                'فرد',
                                member.name || '',
                                member.role || 'عضو',
                                member.mobile || '',
                                '',
                                ''
                            ]);
                        }
                    } else {
                        const partyName = party.name || '';
                        await db.query(partySql, [
                            caseId,
                            party.type || 'second',
                            party.category || 'فرد',
                            partyName,
                            party.position || '',
                            party.mobile || '',
                            party.lawyerName || '',
                            party.lawyerMobile || ''
                        ]);
                        
                        if (party.type === 'second' && !opponentValue && partyName) {
                            // Opponent column removed - Plaintiff/Defendant used instead
                            console.log('✅ طرف ثانٍ تم تسجيله:', partyName);
                        }
                    }
                }
                console.log('✅ تم إضافة أطراف القضية');
            }

            // ===== إضافة المرفقات =====
            if (req.body.attachments && req.body.attachments.length > 0) {
                const attSql = `
                    INSERT INTO Attachments (
                        CaseId, SessionId, FileName, FilePath, FileType, FileSize, UploadedAt
                    ) VALUES (
                        @p0, @p1, @p2, @p3, @p4, @p5, GETDATE()
                    )
                `;
                for (const att of req.body.attachments) {
                    await db.query(attSql, [
                        caseId,
                        null,
                        att.fileName || att.FileName || 'مرفق',
                        att.filePath || att.FilePath || att.dataUrl || '',
                        att.fileType || att.FileType || 'image/jpeg',
                        att.fileSize || att.FileSize || 0
                    ]);
                }
                console.log('✅ تم إضافة مرفقات القضية');
            }

            // ===== إضافة الجلسة الأولى =====
            if (firstSession) {
                const sessionSql = `
                    INSERT INTO Sessions (
                        CaseId, SessionDate, SessionTime, Stage,
                        ActionTaken, [Status]
                    ) VALUES (
                        @p0, @p1, @p2, @p3, @p4, @p5
                    );
                    SELECT SCOPE_IDENTITY() AS Id;
                `;

                await db.query(sessionSql, [
                    caseId,
                    firstSession.date || new Date().toISOString().split('T')[0],
                    firstSession.time || '09:00:00',
                    firstSession.stage || currentStage || 'ابتدائي',
                    firstSession.action || 'جلسة افتتاحية',
                    firstSession.status || 'متداولة'
                ]);
                console.log('✅ تم إضافة الجلسة الأولى');
            }

            await transaction.commit();

            await logActivity(req, 'add', `تمت إضافة قضية جديدة برقم ${caseNumber}${subject ? ' - ' + subject : ''}`, 'القضايا');

            res.json({
                success: true,
                message: 'تم حفظ القضية بنجاح',
                caseId: caseId,
                caseNumber: caseNumber,
                opponent: opponentValue
            });

        } catch (error) {
            await transaction.rollback();
            throw error;
        }

    } catch (error) {
        console.error('❌ خطأ في إضافة القضية:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

// ============================================
// تحديث بيانات قضية كاملة (تعديل)
// ============================================
app.put('/api/cases/:id', async (req, res) => {
    try {
        const { id } = req.params;

        const check = await db.query("SELECT * FROM Cases WHERE Id = @p0", [id]);
        if (check.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'القضية غير موجودة'
            });
        }

        const b = req.body || {};
        const caseNumber = b.caseNumber || b.CaseNumber;
        const caseYear = b.caseYear || b.CaseYear;
        const caseType = b.caseType || b.CaseType;
        const subject = b.subject || b.Subject;
        const description = b.description || b.Description;
        const category = b.category || b.Category || b.caseCategory || b.CaseCategory || caseType || 'مدني';
        const currentStage = b.currentStage || b.CurrentStage;
        const status = b.status || b.Status;
        const filingDate = b.filingDate || b.FilingDate;
        const assignedLawyerId = b.assignedLawyerId !== undefined ? b.assignedLawyerId : (b.AssignedLawyerId || null);
        const parties = b.parties || b.Parties || [];
        const courtName = b.courtName || b.CourtName || null;
        const circuitName = b.circuitName || b.CircuitName || null;
        const opponent = b.opponent || b.Opponent || null;
        const notes = b.notes || b.Notes || null;
        const claimValue = b.claimValue || b.ClaimValue || b.claimAmount || b.ClaimAmount || null;
        const lawsuitExpenses = b.lawsuitExpenses || b.LawsuitExpenses || null;
        const plaintiff = b.plaintiff || b.Plaintiff || null;
        const defendant = b.defendant || b.Defendant || null;
        const filedBy = b.filedBy || b.FiledBy || 'الشركة';

        console.log('✏️ تحديث القضية (ID:', id, '):', {
            caseNumber, caseYear, caseType, subject, courtName, circuitName, opponent, claimValue, defendant, category
        });

        let caseChangeLines = [];
        const transaction = new db.sql.Transaction(db.pool);
        await transaction.begin();

        try {
            let lawyerId = null;
            if (assignedLawyerId) {
                const checkLawyer = await db.query(
                    "SELECT Id FROM Lawyers WHERE Id = @p0 AND IsActive = 1",
                    [assignedLawyerId]
                );
                if (checkLawyer.length > 0) {
                    lawyerId = assignedLawyerId;
                }
            }

            const opponentValue = opponent || null;
            const descriptionValue = description || '';
            const notesValue = notes || '';
            const categoryValue = category || 'مدني';
            const claimValueValue = claimValue || null;

            const compName = 'شركة الصرف الصحي بالإسكندرية';
            let finalPlaintiff = plaintiff;
            let finalDefendant = defendant;

            if (!finalPlaintiff && !finalDefendant) {
                finalPlaintiff = (filedBy === 'الشركة' ? compName : (opponentValue || 'الخصم'));
                finalDefendant = (filedBy === 'الشركة' ? (opponentValue || 'الخصم') : compName);
            } else if (!finalPlaintiff) {
                finalPlaintiff = (finalDefendant === compName) ? (opponentValue || 'الخصم') : compName;
            } else if (!finalDefendant) {
                finalDefendant = (finalPlaintiff === compName) ? (opponentValue || 'الخصم') : compName;
            }

            const updateSql = `
                UPDATE Cases SET
                    CaseNumber = @p0,
                    CaseYear = @p1,
                    CaseType = @p2,
                    Subject = @p3,
                    Description = @p4,
                    Category = @p5,
                    CurrentStage = @p6,
                    [Status] = @p7,
                    FilingDate = @p8,
                    AssignedLawyerId = @p9,
                    CourtName = @p10,
                    CircuitName = @p11,
                    Notes = @p12,
                    ClaimValue = @p13,
                    LawsuitExpenses = ISNULL(@p14, LawsuitExpenses),
                    Plaintiff = @p15,
                    Defendant = @p16,
                    UpdatedAt = GETDATE()
                WHERE Id = @p17
            `;

            await db.query(updateSql, [
                caseNumber,
                caseYear,
                caseType,
                subject,
                descriptionValue,
                categoryValue,
                currentStage || 'ابتدائي',
                status || 'متداولة',
                filingDate || new Date().toISOString().split('T')[0],
                lawyerId,
                courtName || null,
                circuitName || null,
                notesValue,
                claimValueValue,
                lawsuitExpenses || null,
                finalPlaintiff,
                finalDefendant,
                id
            ]);

            // ===== تتبّع التغييرات (قديم ← جديد) لسجل التتبعات =====
            try {
                const oldCase = check[0];
                let oldLawyerName = '', newLawyerName = '';
                if (String(oldCase.AssignedLawyerId || '') !== String(lawyerId || '')) {
                    oldLawyerName = await _lawyerNameById(oldCase.AssignedLawyerId);
                    newLawyerName = await _lawyerNameById(lawyerId);
                }
                const newView = {
                    CaseNumber: caseNumber, CaseYear: caseYear, CaseType: caseType, Subject: subject,
                    Description: descriptionValue, Category: categoryValue,
                    CurrentStage: currentStage || 'ابتدائي', Status: status || 'متداولة',
                    FilingDate: filingDate || new Date().toISOString().split('T')[0],
                    LawyerName: newLawyerName,
                    CourtName: courtName || null, CircuitName: circuitName || null,
                    Notes: notesValue, ClaimValue: claimValueValue,
                    Plaintiff: finalPlaintiff, Defendant: finalDefendant
                };
                if (lawsuitExpenses) newView.LawsuitExpenses = lawsuitExpenses;
                const oldView = Object.assign({}, oldCase, { LawyerName: oldLawyerName });
                caseChangeLines = buildChangesText(oldView, newView, {
                    CaseNumber: 'رقم القضية', CaseYear: 'سنة القضية', CaseType: 'نوع القضية',
                    Subject: 'الموضوع', Description: 'الوصف', Category: 'التصنيف',
                    CurrentStage: 'المرحلة الحالية', Status: 'الحالة', FilingDate: 'تاريخ القيد',
                    LawyerName: 'المحامي المسؤول', CourtName: 'المحكمة', CircuitName: 'الدائرة',
                    Notes: 'الملاحظات', ClaimValue: 'قيمة المطالبة', LawsuitExpenses: 'مصاريف الدعوى',
                    Plaintiff: 'المدعي', Defendant: 'المدعى عليه'
                });
                // الأطراف (قبل ما يتم استبدالها)
                const oldParties = (await db.query('SELECT Name FROM CaseParties WHERE CaseId = @p0', [id])).map(p => p.Name).filter(Boolean);
                const newParties = [];
                for (const p of (parties || [])) {
                    if (p.category === 'مجموعة' && p.members) { p.members.forEach(m => { if (m.name) newParties.push(m.name); }); }
                    else if (p.name) { newParties.push(p.name); }
                }
                if (oldParties.slice().sort().join('|') !== newParties.slice().sort().join('|')) {
                    caseChangeLines.push(`• الأطراف: من "${_diffShow(oldParties.join('، '))}" ← إلى "${_diffShow(newParties.join('، '))}"`);
                }
            } catch (diffErr) { console.error('⚠️ تعذر حساب فروقات القضية:', diffErr.message); }

            // ✅ تحديث رقم القضية في الجلسات الابتدائية التابعة لنفس القضية
            const oldCaseNumber = check[0].CaseNumber;
            if (caseNumber) {
                await db.query(
                    "UPDATE Sessions SET SessionCaseNumber = @p0 WHERE CaseId = @p1 AND (LitigationLevelId IS NULL OR LitigationLevelId = 0)",
                    [caseNumber, id]
                );
                // حذف أي سجلات مكررة تم إنشاؤها بالخطأ كدرجة ابتدائية أو بالرقم القديم كدرجة تقاضي
                if (oldCaseNumber && oldCaseNumber !== caseNumber) {
                    await db.query(
                        "DELETE FROM LitigationLevels WHERE CaseId = @p0 AND (StageType = 'initial' OR TrackingCode = @p1)",
                        [id, oldCaseNumber]
                    );
                } else {
                    await db.query(
                        "DELETE FROM LitigationLevels WHERE CaseId = @p0 AND StageType = 'initial'",
                        [id]
                    );
                }
            }

            // ===== استبدال أطراف القضية =====
            await db.query("DELETE FROM CaseParties WHERE CaseId = @p0", [id]);


            if (parties && parties.length > 0) {
                const partySql = `
                    INSERT INTO CaseParties (
                        CaseId, PartyType, PartyCategory, Name,
                        [Position], Mobile, LawyerName, LawyerMobile
                    ) VALUES (
                        @p0, @p1, @p2, @p3, @p4, @p5, @p6, @p7
                    )
                `;

                for (const party of parties) {
                    if (party.category === 'مجموعة' && party.members) {
                        for (const member of party.members) {
                            await db.query(partySql, [
                                id,
                                party.type || 'second',
                                'فرد',
                                member.name || '',
                                member.role || 'عضو',
                                member.mobile || '',
                                '',
                                ''
                            ]);
                        }
                    } else {
                        const partyName = party.name || '';
                        await db.query(partySql, [
                            id,
                            party.type || 'second',
                            party.category || 'فرد',
                            partyName,
                            party.position || '',
                            party.mobile || '',
                            party.lawyerName || '',
                            party.lawyerMobile || ''
                        ]);

                        if (party.type === 'second' && !opponentValue && partyName) {
                            // Opponent column removed - Plaintiff/Defendant used instead
                        }
                    }
                }
            }

            // ===== إضافة المرفقات =====
            if (req.body.attachments && req.body.attachments.length > 0) {
                const attSql = `
                    INSERT INTO Attachments (
                        CaseId, SessionId, FileName, FilePath, FileType, FileSize, UploadedAt
                    ) VALUES (
                        @p0, @p1, @p2, @p3, @p4, @p5, GETDATE()
                    )
                `;
                for (const att of req.body.attachments) {
                    if (att.filePath || att.FilePath || att.dataUrl) {
                        await db.query(attSql, [
                            id,
                            null,
                            att.fileName || att.FileName || 'مرفق',
                            att.filePath || att.FilePath || att.dataUrl || '',
                            att.fileType || att.FileType || 'image/jpeg',
                            att.fileSize || att.FileSize || 0
                        ]);
                    }
                }
            }

            // إذا تحوّلت القضية إلى "منتهية" → أغلق كل جلساتها تلقائياً
            if (status === 'منتهية') {
                await db.query(
                    `UPDATE Sessions 
                     SET IsClosed = 1, [Status] = N'مغلقة'
                     WHERE CaseId = @p0 AND (IsClosed IS NULL OR IsClosed = 0)`,
                    [id]
                );
                console.log(`✅ تم إغلاق جميع جلسات القضية ${id} بسبب تحويلها إلى منتهية`);
            }

            await transaction.commit();

            await logActivity(req, 'edit', withChanges(`تم تعديل بيانات القضية رقم ${caseNumber}${subject ? ' - ' + subject : ''}`, caseChangeLines), 'القضايا');

            res.json({
                success: true,
                message: 'تم تحديث القضية بنجاح',
                caseId: id,
                caseNumber: caseNumber,
                opponent: opponentValue
            });

        } catch (error) {
            await transaction.rollback();
            throw error;
        }

    } catch (error) {
        console.error('❌ خطأ في تحديث القضية:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

// ⚠️ ملحوظة: نسخة GET /api/litigation-levels القديمة الناقصة (بدون CircuitName
// و Subject و RequestedByOpponent) كانت هنا وبتتنفذ بدل النسخة الصحيحة تحت،
// لأن Express بينفذ أول route مطابق بس فكانت النسخة الكاملة تحت لا تُنفذ أبداً.
// اتشالت من هنا عشان النسخة الصحيحة (تحت) هي اللي تشتغل فعليًا، وده كان سبب
// رجوع بعض الحقول (زي الدائرة والموضوع) فاضية بعد كل Refresh.

// ⚠️ ملحوظة: نسخة تحديث الجلسة (PUT /api/sessions/:id) القديمة الناقصة
// كانت هنا وبتتنفذ بدل النسخة الصحيحة تحت (اللي بتحط Source='session')
// لأن Express بينفذ أول route مطابق بس. اتشالت من هنا عشان النسخة
// الصحيحة (تحت) هي اللي تشتغل فعليًا وتمنع ظهور درجات الاستئناف/النقض
// الناتجة من الجلسات في صفحة القضايا.

/////////////////////////////////

// في API جلب درجات التقاضي المفتوحة (pending)
app.get('/api/litigation-levels/pending', async (req, res) => {
    try {
        const sql = `
            SELECT 
                l.Id,
                l.CaseId,
                l.TrackingCode,
                l.StageType,
                l.StageNumber,
                l.CourtName,
                l.RequestedBy,
                l.LawyerName,
                l.LaunchDate,
                l.[Status],
                l.Notes,
                l.CreatedAt,
                c.Subject AS CaseName,
                c.Category AS CaseCategory,
                COALESCE(c.Plaintiff, c.Defendant, '') AS CaseOpponent,
                c.AssignedLawyerId,
                l2.FullName AS LawyerFullName,
                c.CaseNumber,
                c.FilingDate,
                c.Description,
                NULL AS Source
            FROM LitigationLevels l
            LEFT JOIN Cases c ON l.CaseId = c.Id
            LEFT JOIN Lawyers l2 ON c.AssignedLawyerId = l2.Id
            WHERE l.[Status] != 'closed' 
                AND l.[Status] != 'مغلقة'
                -- ✅ هذه الصفحة تعرض جميع الدرجات المفتوحة، بما فيها من Source='session'
                -- لأنها تمثل طلبات استئناف/نقض معلقة تحتاج إلى متابعة
            ORDER BY l.CreatedAt DESC
        `;
        
        const levels = await db.query(sql);
        
        const formattedLevels = levels.map(l => ({
            Id: l.Id,
            CaseId: l.CaseId,
            TrackingCode: l.TrackingCode || l.CaseNumber || '',
            StageType: l.StageType || 'appeal',
            StageNumber: l.StageNumber || '',
            CourtName: l.CourtName || '',
            RequestedBy: l.RequestedBy || '—',
            LawyerName: l.LawyerName || '',
            LaunchDate: l.LaunchDate ? new Date(l.LaunchDate).toISOString().split('T')[0] : null,
            Status: l.Status || 'open',
            Notes: l.Notes || '',
            CreatedAt: l.CreatedAt,
            CaseName: l.CaseName || '',
            CaseCategory: l.CaseCategory || 'مدني',
            CaseOpponent: l.CaseOpponent || '—',
            AssignedLawyerId: l.AssignedLawyerId || null,
            LawyerFullName: l.LawyerFullName || '—',
            CaseNumber: l.CaseNumber || '',
            FilingDate: l.FilingDate || l.LaunchDate || null,
            Description: l.Description || l.Notes || '',
            Source: l.Source || 'litigation'
        }));
        
        res.json({
            success: true,
            data: formattedLevels,
            count: formattedLevels.length
        });
    } catch (error) {
        console.error('❌ خطأ في جلب درجات التقاضي المفتوحة:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

/////////////////////////


// دالة مساعدة للتحقق من وجود جدول
async function tableExists(tableName) {
    try {
        const result = await db.query(
            "SELECT 1 FROM sys.tables WHERE name = @p0",
            [tableName]
        );
        return result.length > 0;
    } catch (e) {
        return false;
    }
}

// ============================================
// 🗑️ نظام الأرشيف العام (سلة المحذوفات)
// ============================================

// ⚠️ خريطة الصفحات: تحدد الصفحة التي يتم تحويل المستخدم إليها بعد الاستعادة
// عدّلي أسماء الملفات هنا لو صفحاتك الفعلية بأسماء مختلفة
const PAGE_URLS = {
    Case: 'cases.html',
    Lawyer: 'lawyers.html',
    Court: 'courts.html',
    LitigationLevel: 'cases.html',
    Session: 'sessions.html'
};

// حفظ أي سجل محذوف في جدول الأرشيف (سلة المحذوفات)
async function archiveRecord(recordType, recordId, dataObj, pageUrl) {
    try {
        await db.query(`
            INSERT INTO Archive (RecordType, RecordId, RecordData, PageUrl, DeletedAt)
            VALUES (@p0, @p1, @p2, @p3, GETDATE())
        `, [recordType, recordId, JSON.stringify(dataObj), pageUrl || null]);
    } catch (archErr) {
        console.log(`⚠️ فشل في أرشفة السجل (${recordType} #${recordId}):`, archErr.message);
    }
}

// إدراج سجل في جدول معين انطلاقاً من كائن بيانات (يُستخدم عند الاستعادة من الأرشيف)
// يبني جملة INSERT ديناميكياً من مفاتيح الكائن، مع استثناء الأعمدة المحددة (مثل Id)
async function insertFromObject(table, obj, excludeCols = ['Id']) {
    const keys = Object.keys(obj || {}).filter(k => !excludeCols.includes(k) && obj[k] !== undefined);
    if (keys.length === 0) return null;

    const columns = keys.map(k => `[${k}]`).join(', ');
    const placeholders = keys.map((_, i) => `@p${i}`).join(', ');
    const values = keys.map(k => obj[k]);

    const sql = `
        INSERT INTO ${table} (${columns})
        VALUES (${placeholders});
        SELECT SCOPE_IDENTITY() AS Id;
    `;

    const result = await db.query(sql, values);
    return result[0]?.Id || null;
}

// ============================================
// 📋 نظام سجل التتبعات (Activity Logs)
// ============================================

// استخراج اسم المستخدم الحالي من الطلب
// الواجهة الأمامية ترسل اسم المستخدم عبر الهيدر X-Username (مأخوذ من localStorage)
function getRequestUsername(req) {
    return (req.headers['x-username'] || req.body?.currentUser || req.query?.currentUser || 'غير معروف').toString();
}

// استخراج عنوان الـ IP الحقيقي للمستخدم
function getRequestIp(req) {
    const forwarded = req.headers['x-forwarded-for'];
    if (forwarded) return forwarded.toString().split(',')[0].trim();
    return (req.socket?.remoteAddress || req.connection?.remoteAddress || '').replace('::ffff:', '');
}

async function isInvestigationUser(username) {
    if (!username) return false;
    const u = String(username).toLowerCase();
    if (u === 'inv' || u.includes('inv')) return true;
    try {
        const rows = await db.query(
            `SELECT u.Id FROM Users u 
             LEFT JOIN Roles r ON r.Id = u.RoleId 
             WHERE u.Username = @p0 AND (r.Name LIKE 'Investigation%' OR u.Username = 'inv')`,
            [username]
        );
        return rows.length > 0;
    } catch (e) {
        return false;
    }
}

// 🕒 توقيت مصر (القاهرة/الإسكندرية) — بيتحسب جوه SQL Server فمش بيتأثر بتوقيت جهاز السيرفر
// الفرق بين توقيت مصر و UTC بالدقايق (بيراعي التوقيت الصيفي تلقائياً)
function egyptOffsetMinutes() {
    const now = new Date();
    const parts = new Intl.DateTimeFormat('en-US', {
        timeZone: 'Africa/Cairo', hourCycle: 'h23',
        year: 'numeric', month: '2-digit', day: '2-digit',
        hour: '2-digit', minute: '2-digit', second: '2-digit'
    }).formatToParts(now).reduce((o, p) => (o[p.type] = p.value, o), {});
    const asUtc = Date.UTC(+parts.year, +parts.month - 1, +parts.day, +parts.hour, +parts.minute, +parts.second);
    return Math.round((asUtc - Math.floor(now.getTime() / 1000) * 1000) / 60000);
}
// "الآن" بتوقيت مصر كتعبير SQL: UTC الحالي + فرق مصر
const egyptNowSql = () => `DATEADD(minute, ${egyptOffsetMinutes()}, GETUTCDATE())`;
// اليوزرات دي مستثناة من تسجيل الدخول/الخروج في سجل التتبعات
const LOG_EXCLUDED_USERS = ['CEO', 'inv'];

// جلب سجلات التتبعات (مشترك بين سجل القضايا وسجل التحقيقات) + الاسم الكامل من جدول Users
async function fetchActivityLogs(category, query) {
    const { action, user, date, search, limit } = query;
    // بدون limit افتراضي: بيرجع كل السجلات. (لو اتبعت ?limit=N بياخد أحدث N بس)
    const topN = parseInt(limit) > 0 ? parseInt(limit) : null;
    const topClause = topN ? `TOP ${topN}` : '';

    let sql = `
        SELECT ${topClause} a.Id, a.Username, a.Action, a.Description, a.PageName, a.IPAddress,
               CONVERT(varchar(10), a.CreatedAt, 23)  AS DatePart,
               CONVERT(varchar(8),  a.CreatedAt, 108) AS TimePart,
               (SELECT TOP 1 u.FullName FROM Users u WHERE u.Username = a.Username) AS FullName
        FROM ActivityLogs a
        WHERE a.Category = '${category}'
    `;
    const params = [];
    let idx = 0;

    if (action && action !== 'all') {
        sql += ` AND a.Action = @p${idx}`;
        params.push(action);
        idx++;
    }
    if (user && user !== 'all') {
        sql += ` AND a.Username = @p${idx}`;
        params.push(user);
        idx++;
    }
    if (date) {
        sql += ` AND CONVERT(date, a.CreatedAt) = @p${idx}`;
        params.push(date);
        idx++;
    }
    if (search) {
        sql += ` AND (a.Description LIKE @p${idx} OR a.Username LIKE @p${idx} OR a.PageName LIKE @p${idx}
                  OR EXISTS (SELECT 1 FROM Users u2 WHERE u2.Username = a.Username AND u2.FullName LIKE @p${idx}))`;
        params.push(`%${search}%`);
        idx++;
    }

    sql += ` ORDER BY a.Id DESC`; // الأحدث إدخالاً أولاً

    const rows = await db.query(sql, params);
    return rows.map(r => {
        // التاريخ والوقت جايين كنص جاهز بتوقيت مصر من SQL → نعرضهم زي ما هما بدون أي تحويل
        const asUtc = new Date(`${r.DatePart}T${r.TimePart}Z`);
        return {
            id: r.Id,
            timestamp: `${r.DatePart}T${r.TimePart}`,
            dateTime: asUtc.toLocaleString('ar-EG', {
                timeZone: 'UTC',
                year: 'numeric', month: '2-digit', day: '2-digit',
                hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: false
            }),
            user: r.Username,
            fullName: r.FullName || '',
            action: r.Action,
            description: r.Description,
            page: r.PageName,
            ip: r.IPAddress
        };
    });
}

// ===== مقارنة القيم القديمة بالجديدة لسجل التتبعات (من ← إلى) =====
function _diffNorm(v) {
    if (v === null || v === undefined) return '';
    if (v instanceof Date) return isNaN(v) ? '' : v.toISOString().split('T')[0];
    let s = String(v).trim();
    if (/^\d{4}-\d{2}-\d{2}T/.test(s)) s = s.slice(0, 10);
    if (/^\d{2}:\d{2}:\d{2}/.test(s)) s = s.slice(0, 5);
    return s;
}
function _diffEqual(a, b) {
    if (a === b) return true;
    if (a !== '' && b !== '' && !isNaN(Number(a)) && !isNaN(Number(b))) return Number(a) === Number(b);
    return false;
}
function _diffShow(v) {
    v = _diffNorm(v);
    if (v === '') return '(فارغ)';
    return v.length > 120 ? v.slice(0, 120) + '…' : v;
}
// labels = { المفتاح: 'اسم الحقل بالعربي' } — بيقارن فقط المفاتيح الموجودة في newObj
function buildChangesText(oldObj, newObj, labels) {
    const lines = [];
    for (const key of Object.keys(labels)) {
        if (!Object.prototype.hasOwnProperty.call(newObj, key)) continue;
        const o = _diffNorm(oldObj ? oldObj[key] : '');
        const n = _diffNorm(newObj[key]);
        if (!_diffEqual(o, n)) lines.push(`• ${labels[key]}: من "${_diffShow(o)}" ← إلى "${_diffShow(n)}"`);
    }
    return lines;
}
function withChanges(summary, lines) {
    return lines && lines.length ? summary + '\n' + lines.join('\n') : summary + ' (بدون تغيير في البيانات)';
}
async function _lawyerNameById(id) {
    if (!id) return '';
    try {
        const r = await db.query('SELECT FullName FROM Lawyers WHERE Id = @p0', [id]);
        return r[0] ? r[0].FullName : '';
    } catch (e) { return ''; }
}

// تسجيل إجراء في سجل التتبعات
async function logActivity(req, action, description, page, category, forcedUsername) {
    try {
        let username = forcedUsername || getRequestUsername(req);
        if ((!username || username === 'غير معروف' || username === 'زائر') && req.body && req.body.username) {
            username = req.body.username;
        }
        const ip = getRequestIp(req);
        let cat = category;

        if (!cat) {
            const isInvUser = await isInvestigationUser(username);
            const pageStr = String(page || '').toLowerCase();
            const reqUrl = String(req.originalUrl || req.url || '').toLowerCase();
            const descStr = String(description || '').toLowerCase();

            if (
                isInvUser ||
                pageStr.includes('investigation') ||
                pageStr.includes('تحقيق') ||
                pageStr.includes('مستخدمو التحقيقات') ||
                pageStr.includes('أرشيف التحقيقات') ||
                descStr.includes('تحقيق') ||
                reqUrl.includes('investigation')
            ) {
                cat = 'investigation';
            } else {
                cat = 'cases';
            }
        }

        // ⛔ اليوزرات المستثناة من تسجيل الدخول/الخروج
        if ((action === 'login' || action === 'logout') && LOG_EXCLUDED_USERS.includes(username)) {
            return;
        }

        // ⛔ منع تكرار الدخول/الخروج: لو نفس اليوزر سجّل نفس الإجراء خلال آخر 10 ثواني نتجاهل التكرار
        if (action === 'login' || action === 'logout') {
            const dup = await db.query(
                `SELECT TOP 1 Id FROM ActivityLogs
                 WHERE Username = @p0 AND Action = @p1
                   AND CreatedAt >= DATEADD(second, -10, ${egyptNowSql()})`,
                [username, action]
            );
            if (dup.length > 0) return;
        }

        await db.query(
            `INSERT INTO ActivityLogs (Username, Action, Description, PageName, IPAddress, Category, CreatedAt)
             VALUES (@p0, @p1, @p2, @p3, @p4, @p5, ${egyptNowSql()})`,
            [username, action, description || '', page || null, ip || null, cat]
        );
    } catch (logErr) {
        console.error('❌ فشل تسجيل التتبعة في سجل التتبعات:', action, '-', logErr.message);
    }
}

// ===== جلب سجلات التتبعات (حركات القضايا فقط) =====
app.get('/api/logs', async (req, res) => {
    try {
        const data = await fetchActivityLogs('cases', req.query);
        res.json({ success: true, data });
    } catch (error) {
        console.error('❌ خطأ في جلب سجل التتبعات:', error);
        res.status(500).json({ success: false, message: error.message });
    }
});

// ===== إضافة سجل تتبع يدوي (تسجيل دخول/خروج/عرض/طباعة/تصدير...) من الواجهة الأمامية =====
app.post('/api/logs', async (req, res) => {
    try {
        const { action, description, page, category } = req.body;
        if (!action) {
            return res.status(400).json({ success: false, message: 'نوع الإجراء (action) مطلوب' });
        }
        await logActivity(req, action, description || '', page || '', category || null);
        res.json({ success: true, message: 'تم تسجيل التتبعة بنجاح' });
    } catch (error) {
        console.error('❌ خطأ في إضافة تتبعة:', error);
        res.status(500).json({ success: false, message: error.message });
    }
});

// ===== إعادة تصنيف سجلات التتبعات (لإصلاح البيانات القديمة) =====
app.post('/api/logs/recategorize', async (req, res) => {
    try {
        // خطوة 1: تعيين الكل كـ cases
        await db.query(`UPDATE ActivityLogs SET Category = 'cases'`);

        // خطوة 2: تصنيف التحقيقات فقط
        await db.query(`
            UPDATE ActivityLogs 
            SET Category = 'investigation' 
            WHERE LOWER(Username) = 'inv' 
               OR LOWER(Username) LIKE '%inv%'
               OR Username IN (
                   SELECT u.Username FROM Users u 
                   INNER JOIN Roles r ON r.Id = u.RoleId 
                   WHERE r.Name LIKE 'Investigation%'
               )
               OR PageName LIKE '%investigation%' 
               OR PageName LIKE N'%تحقيق%' 
               OR PageName LIKE N'%مستخدمو التحقيقات%' 
               OR PageName LIKE N'%أرشيف التحقيقات%'
        `);

        // الحصول على إحصائيات
        const stats = await db.query(`
            SELECT Category, COUNT(*) as Count 
            FROM ActivityLogs 
            GROUP BY Category
        `);

        res.json({ success: true, message: 'تم إعادة تصنيف السجلات بنجاح', stats });
    } catch (error) {
        console.error('❌ خطأ في إعادة تصنيف السجلات:', error);
        res.status(500).json({ success: false, message: error.message });
    }
});

// ===== مسح جميع سجلات التتبعات =====
app.delete('/api/logs', async (req, res) => {
    try {
        await db.query('DELETE FROM ActivityLogs');
        await logActivity(req, 'delete', 'تم مسح جميع سجلات التتبعات', 'سجل التتبعات');
        res.json({ success: true, message: 'تم مسح سجل التتبعات بنجاح' });
    } catch (error) {
        console.error('❌ خطأ في مسح سجل التتبعات:', error);
        res.status(500).json({ success: false, message: error.message });
    }
});

//然后في DELETE endpoint استخدامها:
app.delete('/api/cases/:id', async (req, res) => {
    try {
        const { id } = req.params;
        
        const check = await db.query("SELECT Id, CaseNumber FROM Cases WHERE Id = @p0", [id]);
        if (check.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'القضية غير موجودة'
            });
        }
        
        const caseNumber = check[0].CaseNumber;
        console.log(`🗑️ حذف القضية رقم ${caseNumber} (ID: ${id})`);

        // 💾 جمع كل بيانات القضية والسجلات المرتبطة بها قبل الحذف لأرشفتها بالكامل
        const fullCaseRow = await db.query("SELECT * FROM Cases WHERE Id = @p0", [id]);
        const caseParties = await db.query("SELECT * FROM CaseParties WHERE CaseId = @p0", [id]);
        const caseSessions = await db.query("SELECT * FROM Sessions WHERE CaseId = @p0", [id]);
        const caseLitigationLevels = (await tableExists('LitigationLevels'))
            ? await db.query("SELECT * FROM LitigationLevels WHERE CaseId = @p0", [id])
            : [];
        const caseAttachments = (await tableExists('Attachments'))
            ? await db.query("SELECT * FROM Attachments WHERE CaseId = @p0", [id])
            : [];

        await archiveRecord('Case', id, {
            case: fullCaseRow[0],
            caseParties,
            sessions: caseSessions,
            litigationLevels: caseLitigationLevels,
            attachments: caseAttachments
        }, PAGE_URLS.Case);

        const transaction = new db.sql.Transaction(db.pool);
        await transaction.begin();
        
        try {
            // حذف من الجداول الموجودة فقط
            await db.query("DELETE FROM CaseParties WHERE CaseId = @p0", [id]);
            await db.query("DELETE FROM Sessions WHERE CaseId = @p0", [id]);
            
            // التحقق من وجود LitigationLevels
            if (await tableExists('LitigationLevels')) {
                await db.query("DELETE FROM LitigationLevels WHERE CaseId = @p0", [id]);
            }
            
            // التحقق من وجود Attachments
            if (await tableExists('Attachments')) {
                await db.query("DELETE FROM Attachments WHERE CaseId = @p0", [id]);
            }
            
            await db.query("DELETE FROM Cases WHERE Id = @p0", [id]);
            
            await transaction.commit();

            await logActivity(req, 'delete', `تم حذف القضية رقم ${caseNumber}`, 'القضايا');
            
            res.json({
                success: true,
                message: `تم حذف القضية رقم ${caseNumber} بنجاح`,
                caseId: id,
                caseNumber: caseNumber
            });
            
        } catch (error) {
            await transaction.rollback();
            throw error;
        }
        
    } catch (error) {
        console.error('❌ خطأ في حذف القضية:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});
// ============================================
// 7. جلب جميع المحامين
// ============================================
app.get('/api/lawyers', async (req, res) => {
    try {
        // onlyActive=1 => استخدمها في صفحات زي "إضافة قضية" عشان تظهر المحامين
        // النشطين فقط في قائمة الاختيار. صفحة المحامين نفسها بتجيب الكل (نشط وغير نشط)
        // ما عدا اللي اتعمله "حذف من الصفحة" (IsDeleted = 1)
        const onlyActive = req.query.onlyActive === '1' || req.query.onlyActive === 'true';

        const sql = `
            SELECT 
                l.Id,
                l.Code,
                l.FullName,
                l.Grade,
                l.HireDate,
                l.BirthDate,
                l.NationalId,
                l.Mobile,
                l.Email,
                l.IsActive,
                l.IsDeleted,
                COUNT(DISTINCT c.Id) AS CasesCount
            FROM Lawyers l
            LEFT JOIN Cases c ON l.Id = c.AssignedLawyerId
            WHERE l.IsDeleted = 0 ${onlyActive ? 'AND l.IsActive = 1' : ''}
            GROUP BY l.Id, l.Code, l.FullName, l.Grade, l.HireDate, l.BirthDate, 
                     l.NationalId, l.Mobile, l.Email, l.IsActive, l.IsDeleted, l.CreatedAt, l.UpdatedAt
            ORDER BY l.FullName
        `;
        
        const lawyers = await db.query(sql);
        res.json({
            success: true,
            data: lawyers
        });
    } catch (error) {
        console.error('❌ خطأ في جلب المحامين:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

// ============================================
// 8. إضافة محامي جديد
// ============================================
app.post('/api/lawyers', async (req, res) => {
    try {
        const {
            code,
            fullName,
            grade,
            hireDate,
            birthDate,
            nationalId,
            mobile,
            email
        } = req.body;

        const sql = `
            INSERT INTO Lawyers (
                Code, FullName, Grade, HireDate, BirthDate,
                NationalId, Mobile, Email
            ) VALUES (
                @p0, @p1, @p2, @p3, @p4, @p5, @p6, @p7
            );
            SELECT SCOPE_IDENTITY() AS Id;
        `;

        const result = await db.query(sql, [
            code,
            fullName,
            grade || 'محام أول',
            hireDate,
            birthDate,
            nationalId,
            mobile,
            email || null
        ]);

        res.json({
            success: true,
            message: 'تم حفظ المحامي بنجاح',
            id: result[0]?.Id
        });

    } catch (error) {
        console.error('❌ خطأ في إضافة المحامي:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

// ============================================
// 8ب. تعديل بيانات محامي
// ============================================
app.put('/api/lawyers/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const {
            code,
            fullName,
            grade,
            hireDate,
            birthDate,
            nationalId,
            mobile,
            email
        } = req.body;

        const check = await db.query("SELECT * FROM Lawyers WHERE Id = @p0", [id]);
        if (check.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'المحامي غير موجود'
            });
        }

        const sql = `
            UPDATE Lawyers SET
                Code = @p0,
                FullName = @p1,
                Grade = @p2,
                HireDate = @p3,
                BirthDate = @p4,
                NationalId = @p5,
                Mobile = @p6,
                Email = @p7
            WHERE Id = @p8
        `;

        await db.query(sql, [
            code,
            fullName,
            grade || 'محام أول',
            hireDate,
            birthDate,
            nationalId,
            mobile,
            email || null,
            id
        ]);

        await logActivity(req, 'edit', withChanges(`تم تعديل بيانات المحامي: ${check[0].FullName}`, buildChangesText(check[0], {
            Code: code, FullName: fullName, Grade: grade || 'محام أول', HireDate: hireDate, BirthDate: birthDate,
            NationalId: nationalId, Mobile: mobile, Email: email || null
        }, { Code: 'الكود', FullName: 'الاسم', Grade: 'الدرجة', HireDate: 'تاريخ التعيين', BirthDate: 'تاريخ الميلاد', NationalId: 'الرقم القومي', Mobile: 'الموبايل', Email: 'البريد الإلكتروني' })), 'المحامين');

        res.json({
            success: true,
            message: 'تم تحديث بيانات المحامي بنجاح'
        });

    } catch (error) {
        console.error('❌ خطأ في تعديل المحامي:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

// ============================================
// 8ج. تفعيل / إلغاء تفعيل محامي
// ============================================
app.patch('/api/lawyers/:id/status', async (req, res) => {
    try {
        const { id } = req.params;
        const { isActive } = req.body;

        if (typeof isActive !== 'boolean') {
            return res.status(400).json({
                success: false,
                message: 'قيمة isActive مطلوبة (true أو false)'
            });
        }

        const check = await db.query("SELECT Id FROM Lawyers WHERE Id = @p0 AND IsDeleted = 0", [id]);
        if (check.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'المحامي غير موجود'
            });
        }

        await db.query(
            "UPDATE Lawyers SET IsActive = @p0 WHERE Id = @p1",
            [isActive ? 1 : 0, id]
        );

        res.json({
            success: true,
            message: isActive ? 'تم تفعيل المحامي' : 'تم إلغاء تفعيل المحامي'
        });
    } catch (error) {
        console.error('❌ خطأ في تغيير حالة المحامي:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

// ============================================
// 9. حذف محامي (من صفحة المحامين فقط - Soft Delete)
// ============================================
// ملاحظة مهمة: الحذف هنا "حذف من صفحة المحامين" وليس حذف فعلي من قاعدة البيانات.
// لازم المحامي يبقى "غير نشط" الأول قبل ما يتحذف. وبعد الحذف بياناته بتفضل
// محفوظة عشان اسمه يستمر يظهر صح في أي قضية أو جلسة أو صفحة تانية مرتبطة بيه.
app.delete('/api/lawyers/:id', async (req, res) => {
    try {
        const { id } = req.params;

        const check = await db.query("SELECT * FROM Lawyers WHERE Id = @p0 AND IsDeleted = 0", [id]);
        if (check.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'المحامي غير موجود'
            });
        }

        // ✋ لازم يبقى غير نشط الأول قبل الحذف من الصفحة
        if (check[0].IsActive) {
            return res.status(409).json({
                success: false,
                message: 'لا يمكن حذف محامي نشط. من فضلك قم بإلغاء تفعيله أولاً باستخدام زر النشط/غير نشط، ثم احذفه.'
            });
        }

        // فحص الارتباطات: بنقرر على أساسها هل نأرشف ونحذف نهائي، ولا نكتفي بإخفاء من الصفحة
        const linkedCases = await db.query(
            "SELECT COUNT(*) AS cnt FROM Cases WHERE AssignedLawyerId = @p0",
            [id]
        );
        const linkedSessions = await db.query(
            "SELECT COUNT(*) AS cnt FROM Sessions WHERE AttendingLawyerId = @p0",
            [id]
        );
        const casesCount = linkedCases[0]?.cnt || 0;
        const sessionsCount = linkedSessions[0]?.cnt || 0;

        if (casesCount === 0 && sessionsCount === 0) {
            // 🗃️ مفيش قضايا ولا جلسات مرتبطة بيه: نأرشفه ونحذفه نهائياً من الجدول
            // عشان يظهر في سلة المحذوفات ويكون قابل للاستعادة بشكل كامل وآمن
            await archiveRecord('Lawyer', id, check[0], PAGE_URLS.Lawyer);
            await db.query("DELETE FROM Lawyers WHERE Id = @p0", [id]);

            return res.json({
                success: true,
                message: 'تم حذف المحامي ونقله إلى الأرشيف بنجاح، وتقدري تسترجعيه من صفحة الأرشيف.'
            });
        }

        // 🗂️ مرتبط بقضايا أو جلسات: بنعمل Soft Delete (بياناته تفضل في الجدول بنفس الـ Id)
        // عشان القضايا والجلسات المرتبطة بيه تفضل شايفة اسمه صح.
        // وبرضه بنحطه في الأرشيف عشان يظهر في صفحة الأرشيف ويكون قابل للاستعادة —
        // بس الاستعادة بتاعته هتفرق عن غيره: هترجّع نفس الصف (نفس الـ Id) مش صف جديد،
        // عشان الربط بالقضايا والجلسات الحالية ميتكسرش (شوفي /api/archive/restore/:id)
        await archiveRecord('Lawyer', id, check[0], PAGE_URLS.Lawyer);
        await db.query("UPDATE Lawyers SET IsDeleted = 1 WHERE Id = @p0", [id]);

        const parts = [];
        if (casesCount > 0) parts.push(`${casesCount} قضية`);
        if (sessionsCount > 0) parts.push(`${sessionsCount} جلسة`);
        return res.json({
            success: true,
            message: `تم حذف المحامي ونقله إلى الأرشيف، وبياناته هتفضل محفوظة لأنه مرتبط بـ ${parts.join(' و ')}. تقدري تسترجعيه من صفحة الأرشيف في أي وقت.`
        });
    } catch (error) {
        console.error('❌ خطأ في حذف المحامي:', error);

        // 🛡️ في حال وجود ربط في جدول آخر لم يتم فحصه صراحة (Foreign Key)
        const isForeignKeyError =
            error.number === 547 ||
            /FOREIGN KEY|REFERENCE constraint/i.test(error.message || '');

        if (isForeignKeyError) {
            return res.status(409).json({
                success: false,
                message: 'لا يمكن حذف هذا المحامي لأنه مرتبط بسجلات أخرى في النظام (مثل قضايا أو جلسات). قم بفك الارتباط أولاً أو قم بإلغاء تفعيله بدلاً من حذفه.'
            });
        }

        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

// ============================================
// التصنيفات الفرعية لأنواع القضايا (CaseSubTypes)
// جدول دائم في قاعدة البيانات، حتى تفضل التصنيفات المُضافة
// موجودة بشكل ثابت لكل المستخدمين
// ============================================

// جلب كل التصنيفات الفرعية (الأساسية + المُضافة) مقسّمة حسب النوع
app.get('/api/case-subtypes', async (req, res) => {
    try {
        const sql = `SELECT Id, Category, Name FROM CaseSubTypes ORDER BY Category, Id`;
        const rows = await db.query(sql);
        res.json({
            success: true,
            data: rows
        });
    } catch (error) {
        console.error('❌ خطأ في جلب التصنيفات الفرعية:', error);
        // إذا كان الجدول غير موجود بعد، أرجع قائمة فارغة بدلاً من خطأ
        res.json({
            success: true,
            data: []
        });
    }
});

// ===== هل إضافة تصنيف فرعي جديد ممنوعة حالياً على المستخدمين العاديين؟ =====
// (يتحكم فيها الأدمن بزرار قفل/فتح بجانب "+ تصنيف جديد" في صفحة قضية جديدة)
const SUBTYPE_LOCK_KEY = 'block_new_subtype';

app.get('/api/case-subtypes/lock-status', async (req, res) => {
    try {
        const rows = await db.query(`SELECT [Value] FROM AppSettings WHERE [Key] = @p0`, [SUBTYPE_LOCK_KEY]);
        const locked = rows.length > 0 && rows[0].Value === '1';
        res.json({ success: true, locked });
    } catch (error) {
        console.error('❌ خطأ في جلب حالة قفل التصنيفات:', error);
        // في حالة الخطأ (مثلاً الجدول لسه مش موجود) نعتبرها غير مقفولة، عشان الفورم يفضل شغال
        res.json({ success: true, locked: false });
    }
});

// تفعيل/إلغاء منع إضافة تصنيف فرعي جديد للمستخدمين العاديين (أدمن فقط)
app.put('/api/case-subtypes/lock-status', requireAdmin, async (req, res) => {
    try {
        const locked = !!req.body.locked;
        const value = locked ? '1' : '0';

        const existing = await db.query(`SELECT Id FROM AppSettings WHERE [Key] = @p0`, [SUBTYPE_LOCK_KEY]);
        if (existing.length > 0) {
            await db.query(`UPDATE AppSettings SET [Value] = @p0, UpdatedAt = GETDATE() WHERE [Key] = @p1`, [value, SUBTYPE_LOCK_KEY]);
        } else {
            await db.query(`INSERT INTO AppSettings ([Key], [Value]) VALUES (@p0, @p1)`, [SUBTYPE_LOCK_KEY, value]);
        }

        await logActivity(req, 'edit', locked ? 'تم منع إضافة تصنيفات فرعية جديدة للمستخدمين' : 'تم السماح بإضافة تصنيفات فرعية جديدة للمستخدمين', 'قضية جديدة');
        res.json({ success: true, locked });
    } catch (error) {
        console.error('❌ خطأ في تحديث حالة قفل التصنيفات:', error);
        res.status(500).json({ success: false, message: error.message });
    }
});

// إضافة تصنيف فرعي جديد (يُحفظ بشكل دائم في قاعدة البيانات)
app.post('/api/case-subtypes', async (req, res) => {
    try {
        const { category, name } = req.body;

        if (!category || !name || !name.trim()) {
            return res.status(400).json({
                success: false,
                message: 'يرجى إرسال نوع القضية واسم التصنيف'
            });
        }

        const cleanName = name.trim();

        // لو الأدمن مانع إضافة تصنيفات جديدة على باقي المستخدمين، امنع أي طلب مش من الأدمن
        const admin = await isAdminRequest(req);
        if (!admin) {
            const lockRows = await db.query(`SELECT [Value] FROM AppSettings WHERE [Key] = 'block_new_subtype'`);
            const locked = lockRows.length > 0 && lockRows[0].Value === '1';
            if (locked) {
                return res.status(403).json({ success: false, message: '⛔ إضافة تصنيفات فرعية جديدة ممنوعة حالياً' });
            }
        }

        // التأكد إن التصنيف مش مكرر لنفس النوع
        const existing = await db.query(
            `SELECT Id FROM CaseSubTypes WHERE Category = @p0 AND Name = @p1`,
            [category, cleanName]
        );

        if (existing.length > 0) {
            return res.json({
                success: true,
                message: 'التصنيف موجود بالفعل',
                id: existing[0].Id,
                alreadyExists: true
            });
        }

        const sql = `
            INSERT INTO CaseSubTypes (Category, Name)
            VALUES (@p0, @p1);
            SELECT SCOPE_IDENTITY() AS Id;
        `;
        const result = await db.query(sql, [category, cleanName]);

        res.json({
            success: true,
            message: 'تم حفظ التصنيف الجديد بنجاح',
            id: result[0]?.Id
        });
    } catch (error) {
        console.error('❌ خطأ في إضافة التصنيف الفرعي:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

// تعديل (إعادة تسمية) تصنيف فرعي موجود — أدمن فقط
app.put('/api/case-subtypes/:id', requireAdmin, async (req, res) => {
    try {
        const { id } = req.params;
        const { name } = req.body;

        if (!name || !name.trim()) {
            return res.status(400).json({ success: false, message: 'يرجى إرسال اسم التصنيف الجديد' });
        }
        const cleanName = name.trim();

        const existing = await db.query(`SELECT Id, Category, Name FROM CaseSubTypes WHERE Id = @p0`, [id]);
        if (existing.length === 0) {
            return res.status(404).json({ success: false, message: 'التصنيف غير موجود' });
        }

        // تأكيد عدم تكرار الاسم الجديد مع تصنيف تاني في نفس النوع
        const dup = await db.query(
            `SELECT Id FROM CaseSubTypes WHERE Category = @p0 AND Name = @p1 AND Id <> @p2`,
            [existing[0].Category, cleanName, id]
        );
        if (dup.length > 0) {
            return res.json({ success: false, message: 'هذا الاسم مستخدم بالفعل لتصنيف آخر' });
        }

        await db.query(`UPDATE CaseSubTypes SET Name = @p0 WHERE Id = @p1`, [cleanName, id]);
        await logActivity(req, 'edit', `تم تعديل تصنيف فرعي من "${existing[0].Name}" إلى "${cleanName}"`, 'قضية جديدة');

        res.json({ success: true, message: 'تم تعديل التصنيف بنجاح', id: Number(id), name: cleanName });
    } catch (error) {
        console.error('❌ خطأ في تعديل التصنيف الفرعي:', error);
        res.status(500).json({ success: false, message: error.message });
    }
});

// حذف تصنيف فرعي — أدمن فقط
app.delete('/api/case-subtypes/:id', requireAdmin, async (req, res) => {
    try {
        const { id } = req.params;

        const existing = await db.query(`SELECT Id, Name FROM CaseSubTypes WHERE Id = @p0`, [id]);
        if (existing.length === 0) {
            return res.status(404).json({ success: false, message: 'التصنيف غير موجود' });
        }

        await db.query(`DELETE FROM CaseSubTypes WHERE Id = @p0`, [id]);
        await logActivity(req, 'delete', `تم حذف تصنيف فرعي: ${existing[0].Name}`, 'قضية جديدة');

        res.json({ success: true, message: 'تم حذف التصنيف بنجاح' });
    } catch (error) {
        console.error('❌ خطأ في حذف التصنيف الفرعي:', error);
        res.status(500).json({ success: false, message: error.message });
    }
});

// أضف هذه النقاط في server.js

// ============================================
// جلب المحاكم (Courts)
// ============================================
app.get('/api/courts', async (req, res) => {
    try {
        const sql = `
            SELECT 
                c.Id,
                c.Name,
                c.[Address],
                c.Floors,
                c.IsActive
            FROM Courts c
            WHERE c.IsActive = 1
            ORDER BY c.Name
        `;
        
        const courts = await db.query(sql);
        res.json({
            success: true,
            data: courts
        });
    } catch (error) {
        console.error('❌ خطأ في جلب المحاكم:', error);
        // إذا كان الجدول غير موجود، أرجع بيانات وهمية
        res.json({
            success: true,
            data: [
                { Id: 1, Name: 'محكمة شمال القاهرة الابتدائية' },
                { Id: 2, Name: 'محكمة جنوب القاهرة الابتدائية' },
                { Id: 3, Name: 'محكمة شرق القاهرة الابتدائية' }
            ]
        });
    }
});

// ============================================
// جلب الدوائر (Circuits) - النسخة الشاملة
// ============================================
app.get('/api/circuits', async (req, res) => {
    try {
        const { courtId } = req.query;
        
        // الخطوة 1: محاولة جلب الدوائر من جدول Circuits أولاً
        try {
            // التحقق من وجود جدول Circuits
            const check = await db.query("SELECT 1 FROM sys.tables WHERE name = 'Circuits'");
            
            if (check.length > 0) {
                let sql = `
                    SELECT 
                        Id,
                        CourtId,
                        Name,
                        Floor,
                        Type,
                        IsActive
                    FROM Circuits
                    WHERE IsActive = 1
                `;
                
                const params = [];
                if (courtId) {
                    sql += ` AND CourtId = @p0`;
                    params.push(courtId);
                }
                
                sql += ` ORDER BY Name`;
                
                const circuits = await db.query(sql, params);
                
                if (circuits.length > 0) {
                    return res.json({
                        success: true,
                        data: circuits
                    });
                }
            }
        } catch (e) {
            console.log('⚠️ جدول Circuits غير موجود أو لا يحتوي على بيانات');
        }
        
        // الخطوة 2: إذا لم يوجد جدول Circuits، نقرأ من حقل Floors في جدول Courts
        console.log('📋 جلب الدوائر من حقل Floors في جدول Courts');
        
        let courtSql = `
            SELECT 
                Id,
                Name,
                Floors,
                IsActive
            FROM Courts
            WHERE IsActive = 1
        `;
        
        const courtParams = [];
        if (courtId) {
            courtSql += ` AND Id = @p0`;
            courtParams.push(courtId);
        }
        
        const courts = await db.query(courtSql, courtParams);
        
        // تحويل بيانات المحاكم إلى دوائر
        const circuits = [];
        courts.forEach(court => {
            if (court.Floors && court.Floors.trim() !== '') {
                // تقسيم الدوائر المفصولة بفواصل أو فواصل منقوطة
                const floorItems = court.Floors.split(/[,;،؛]/).map(f => f.trim()).filter(f => f !== '');
                
                if (floorItems.length > 0) {
                    floorItems.forEach((floor, index) => {
                        circuits.push({
                            Id: `c${court.Id}-${index}`,
                            CourtId: court.Id,
                            Name: floor || `الدائرة ${index + 1}`,
                            Floor: index + 1,
                            Type: 'عادية',
                            IsActive: true
                        });
                    });
                } else {
                    // إذا كانت القيمة موجودة ولكن فارغة بعد التقسيم
                    circuits.push({
                        Id: `c${court.Id}-0`,
                        CourtId: court.Id,
                        Name: court.Floors.trim() || 'الدائرة الأولى',
                        Floor: 1,
                        Type: 'عادية',
                        IsActive: true
                    });
                }
            } else {
                // إذا لم توجد دوائر مسجلة، نضيف دائرة افتراضية
                circuits.push({
                    Id: `c${court.Id}-0`,
                    CourtId: court.Id,
                    Name: 'الدائرة الأولى',
                    Floor: 1,
                    Type: 'عادية',
                    IsActive: true
                });
            }
        });
        
        // إذا لم يتم العثور على أي دوائر، نرجع بيانات وهمية
        if (circuits.length === 0) {
            return res.json({
                success: true,
                data: [
                    { Id: 1, CourtId: 1, Name: 'الدائرة الأولى' },
                    { Id: 2, CourtId: 1, Name: 'الدائرة الثانية' },
                    { Id: 3, CourtId: 2, Name: 'الدائرة الأولى' }
                ]
            });
        }
        
        res.json({
            success: true,
            data: circuits
        });
        
    } catch (error) {
        console.error('❌ خطأ في جلب الدوائر:', error);
        // في حالة الخطأ، نرجع بيانات وهمية بدلاً من خطأ 500
        res.json({
            success: true,
            data: [
                { Id: 1, CourtId: 1, Name: 'الدائرة الأولى' },
                { Id: 2, CourtId: 1, Name: 'الدائرة الثانية' },
                { Id: 3, CourtId: 2, Name: 'الدائرة الأولى' }
            ],
            message: 'تم استخدام بيانات وهمية مؤقتة'
        });
    }
});
// ============================================
// 11. إضافة محكمة جديدة
// ============================================
app.post('/api/courts', async (req, res) => {
    try {
        const { name, address, floors } = req.body;

        const sql = `
            INSERT INTO Courts (Name, [Address], Floors)
            VALUES (@p0, @p1, @p2);
            SELECT SCOPE_IDENTITY() AS Id;
        `;

        const result = await db.query(sql, [name, address, floors || '']);
        
        res.json({
            success: true,
            message: 'تم حفظ المحكمة بنجاح',
            id: result[0]?.Id
        });

    } catch (error) {
        console.error('❌ خطأ في إضافة المحكمة:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

// ============================================
// 11.5. تعديل محكمة ودوائرها
// ============================================
app.put('/api/courts/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const { name, address, floors } = req.body;

        const check = await db.query("SELECT * FROM Courts WHERE Id = @p0", [id]);
        if (check.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'المحكمة غير موجودة'
            });
        }

        let floorsStr = floors;
        if (Array.isArray(floors)) {
            floorsStr = floors.join(', ');
        }

        await db.query(
            `UPDATE Courts SET Name = @p0, [Address] = @p1, Floors = @p2 WHERE Id = @p3`,
            [name, address, floorsStr || '', id]
        );

        await logActivity(req, 'edit', `تم تعديل المحكمة ودوائرها: ${name}`, 'المحاكم والدوائر');

        res.json({
            success: true,
            message: 'تم تعديل المحكمة والدوائر بنجاح'
        });
    } catch (error) {
        console.error('❌ خطأ في تعديل المحكمة:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

// ============================================
// 12. حذف محكمة
// ============================================
app.delete('/api/courts/:id', async (req, res) => {
    try {
        const { id } = req.params;
        
        const check = await db.query("SELECT * FROM Courts WHERE Id = @p0", [id]);
        if (check.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'المحكمة غير موجودة'
            });
        }

        // 💾 حفظ في الأرشيف قبل الحذف
        await archiveRecord('Court', id, check[0], PAGE_URLS.Court);

        await db.query("DELETE FROM Courts WHERE Id = @p0", [id]);
        
        res.json({
            success: true,
            message: 'تم حذف المحكمة ونقلها للأرشيف بنجاح'
        });
    } catch (error) {
        console.error('❌ خطأ في حذف المحكمة:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

// ============================================
// 14. جلب الجلسات - نسخة معدلة مع معالجة التوقيت
// ============================================
// ============================================
// جلب الجلسات - قراءة الوقت كنص
// ============================================
app.get('/api/sessions', async (req, res) => {
    try {
        const { caseId } = req.query;

        let sql = `
            SELECT 
                s.Id,
                s.CaseId,
                s.SessionDate,
                s.SessionTime,  -- ✅ الآن هو VARCHAR، يُقرأ كنص مباشرة
                s.Stage,
                s.AttendingLawyerId,
                s.ActionTaken,
                s.NextSessionDate,
                s.NextSessionTime,
                s.IsClosed,
                s.[Status],
                s.Notes,
                s.Result,
                s.AppealAction,
                s.SessionNotes,
                s.CreatedAt,
                s.LitigationLevelId,
                s.LawsuitExpenses AS JudgmentValue,
                COALESCE(s.SessionCaseNumber, c.CaseNumber) AS CaseNumber,
                COALESCE(ll.Subject, c.Subject) AS CaseSubject,
                COALESCE(c.Category, c2.Category) AS Category,
                c.CurrentStage,
                c.[Status] AS CaseStatus,
                COALESCE(ll.CourtName, c.CourtName) AS CourtName,
                COALESCE(ll.[الدائرة], c.CircuitName) AS CircuitName,
                COALESCE(c.Plaintiff, c.Defendant, '') AS Opponent,
                l.FullName AS LawyerName,
                al.FullName AS AttendingName,
                ll.StageType AS LitigationStageType,
                ll.TrackingCode AS LitigationTrackingCode
            FROM Sessions s
            LEFT JOIN Cases c ON s.CaseId = c.Id
            LEFT JOIN Lawyers l ON c.AssignedLawyerId = l.Id
            LEFT JOIN Lawyers al ON s.AttendingLawyerId = al.Id
            LEFT JOIN LitigationLevels ll ON s.LitigationLevelId = ll.Id
            LEFT JOIN Cases c2 ON ll.CaseId = c2.Id
            WHERE 1=1
                AND s.SessionDate IS NOT NULL
        `;

        const params = [];
        if (caseId) {
            sql += ` AND s.CaseId = @p0`;
            params.push(caseId);
        }

        sql += ` ORDER BY s.CreatedAt DESC`;

        const sessions = await db.query(sql, params);

        // ✅ دالة لعرض الوقت كما هو مخزّن (كنص)


        const formattedSessions = sessions.map(s => ({
            Id: s.Id,
            CaseId: s.CaseId,
            CaseNumber: s.LitigationTrackingCode || s.CaseNumber || '—',
            Subject: s.CaseSubject || s.Notes || '—',
            Stage: s.Stage || s.CurrentStage || 'ابتدائي',
            Opponent: s.Opponent || '—',
            SessionDate: s.SessionDate ? new Date(s.SessionDate).toISOString().split('T')[0] : null,
            SessionTime: formatSessionTime(s.SessionTime),  // ✅ يعيد الوقت كما هو مخزن
            Status: s.Status || 'متداولة',
            LawyerName: s.LawyerName || '—',
            AttendingName: s.AttendingName || '—',
            Action: s.ActionTaken || '—',
            NextDate: s.NextSessionDate ? new Date(s.NextSessionDate).toISOString().split('T')[0] : null,
            IsClosed: s.IsClosed || false,
            CourtName: s.CourtName || '',
            CircuitName: s.CircuitName || '',
            CreatedAt: s.CreatedAt,
            LitigationStageType: s.LitigationStageType || (
                s.Stage === 'استئناف' ? 'appeal' :
                s.Stage === 'نقض' || s.Stage === 'طعن بالنقض' ? 'cassation' :
                (s.Stage === 'إشكال' || s.Stage === 'اشكال') ? 'eshkal' :
                (s.Stage === 'إشكال في التنفيذ' || s.Stage === 'اشكال في التنفيذ' || s.Stage === 'اشكال فى التنفيذ' || s.Stage === 'إشكال فى التنفيذ' || s.Stage === 'تنفيذ') ? 'eshkal_tanfeeth' :
                (s.Stage === 'التماس إعادة النظر' || s.Stage === 'التماس اعادة النظر' || s.Stage === 'التماس') ? 'iltimas' : 'initial'
            ),
            Category: s.Category || 'مدني',
            Result: s.Result || null,
            AppealAction: s.AppealAction || null,
            SessionNotes: s.SessionNotes || null,
            Notes: s.Notes || null,
            JudgmentValue: s.JudgmentValue || null
        }));

        res.json({
            success: true,
            data: formattedSessions,
            count: formattedSessions.length
        });
    } catch (error) {
        console.error('❌ خطأ في جلب الجلسات:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});
// ============================================
// جلب القضايا الابتدائي فقط (لإضافة جلسة)
// ============================================
app.get('/api/cases/initial', async (req, res) => {
    try {
        const sql = `
            SELECT 
                c.Id,
                c.CaseNumber,
                c.CaseYear,
                c.Subject,
                c.Category,
                c.CurrentStage,
                c.[Status],
                c.CourtName,
                c.CircuitName,
                COALESCE(c.Plaintiff, c.Defendant, '') AS Opponent,
                c.AssignedLawyerId,
                l.FullName AS LawyerName,
                (
                    SELECT COUNT(*) 
                    FROM LitigationLevels 
                    WHERE CaseId = c.Id
                ) AS HasHigherLevel
            FROM Cases c
            LEFT JOIN Lawyers l ON c.AssignedLawyerId = l.Id
            WHERE c.[Status] != 'مغلقة'
            ORDER BY c.CaseNumber
        `;
        
        const cases = await db.query(sql);
        
        // تصفية: نأخذ القضايا الابتدائي فقط (اللي لسه مطلعتش استئناف أو نقض)
        const initialCases = cases.filter(c => {
            return c.HasHigherLevel === 0;
        });
        
        res.json({
            success: true,
            data: initialCases,
            count: initialCases.length
        });
    } catch (error) {
        console.error('❌ خطأ في جلب القضايا الابتدائي:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

// ============================================
// 16. إضافة جلسة جديدة - نسخة معدلة مع معالجة التوقيت
// ============================================
// ============================================
// إضافة جلسة جديدة - تخزين الوقت كنص
// ============================================
app.post('/api/sessions', async (req, res) => {
    try {
        const {
            caseNumber,
            subject,
            stage,
            opponent,
            lawyerId,
            lawyerName,
            attendingId,
            attendingName,
            action,
            sessionDate,
            sessionTime,
            court,
            circuit,
            isClosed,
            status,
            nextSessionDate,
            litigationLevelId,
            claimAmount,
            ClaimAmount
        } = req.body;

        const claimAmountValue = claimAmount || ClaimAmount || null;

        console.log('📝 إضافة جلسة جديدة:', { caseNumber, sessionDate, sessionTime, stage, court, circuit, claimAmount: claimAmountValue });

        // ✅ تخزين الوقت كنص كما هو تماماً (HH:MM أو HH:MM:SS)
        let storedTime = sessionTime || null;
        if (storedTime && storedTime.length === 5 && storedTime.includes(':')) {
            // نحتفظ بالوقت بصيغة HH:MM (نخزنه كنص)
            storedTime = storedTime; // HH:MM
        } else if (storedTime && storedTime.length > 5) {
            // إذا كان أطول، نأخذ أول 5 حروف فقط
            storedTime = storedTime.slice(0, 5);
        }
        console.log(`⏰ الوقت للتخزين (كنص): ${storedTime}`);

        let caseId = null;
        let sessionCaseNumber = caseNumber;

        // 1. إذا تم توفير معرف درجة التقاضي، نجلب القضية ورقم درجة التقاضي مباشرة
        if (litigationLevelId) {
            const levelRows = await db.query(
                "SELECT CaseId, TrackingCode FROM LitigationLevels WHERE Id = @p0",
                [litigationLevelId]
            );
            if (levelRows.length > 0) {
                caseId = levelRows[0].CaseId;
                if (levelRows[0].TrackingCode) {
                    sessionCaseNumber = levelRows[0].TrackingCode;
                }
                console.log(`✅ تم إيجاد القضية عن طريق درجة التقاضي: CaseId=${caseId}, TrackingCode=${sessionCaseNumber}`);
            }
        }

        // 2. إذا لم نعثر عليها بعد، نبحث برقم القضية كالمعتاد
        if (!caseId && caseNumber) {
            let caseResult = await db.query(
                "SELECT Id, CaseYear FROM Cases WHERE CaseNumber = @p0",
                [caseNumber]
            );

            if (caseResult.length === 0 && caseNumber.includes('-')) {
                const parts = caseNumber.split('-');
                if (parts.length === 3) {
                    const baseNumber = `${parts[0]}-${parts[1]}`;
                    caseResult = await db.query(
                        "SELECT Id, CaseYear FROM Cases WHERE CaseNumber = @p0",
                        [baseNumber]
                    );
                }
            }

            if (caseResult.length > 0) {
                caseId = caseResult[0].Id;
                console.log(`✅ تم العثور على القضية برقم ID: ${caseId}`);
            } else {
                console.log(`📌 القضية ${caseNumber} غير موجودة، سيتم إنشاؤها`);

                let caseYear = new Date().getFullYear().toString();
                const yearMatch = caseNumber.match(/\/(\d{4})$/);
                if (yearMatch) {
                    caseYear = yearMatch[1];
                } else {
                    const yearMatchAny = caseNumber.match(/(\d{4})/);
                    if (yearMatchAny) {
                        caseYear = yearMatchAny[1];
                    }
                }

                const insertCase = await db.query(`
                    INSERT INTO Cases (
                        CaseNumber, CaseYear, CaseType, Subject, Category, 
                        CurrentStage, [Status], FilingDate,
                        CourtName, CircuitName, ClaimAmount
                    ) VALUES (
                        @p0, @p1, @p2, @p3, @p4, @p5, @p6, @p7, @p8, @p9, @p10
                    );
                    SELECT SCOPE_IDENTITY() AS Id;
                `, [
                    caseNumber,
                    parseInt(caseYear) || 2026,
                    stage || 'مدني',
                    subject || 'قضية جديدة',
                    stage || 'مدني',
                    stage || 'ابتدائي',
                    'متداولة',
                    sessionDate || new Date().toISOString().split('T')[0],
                    court || null,
                    circuit || null,
                    null
                ]);
                caseId = insertCase[0]?.Id;
                console.log(`✅ تم إنشاء قضية جديدة برقم ID: ${caseId}`);
            }
        }

        if (!caseId) {
            return res.status(400).json({
                success: false,
                message: 'لم يتم العثور على القضية أو إنشائها'
            });
        }

        // تحديث المحكمة والدائرة والخصم في القضية
        if (court || circuit) {
            await db.query(`
                UPDATE Cases SET 
                    CourtName = ISNULL(CourtName, @p0),
                    CircuitName = ISNULL(CircuitName, @p1),
                    UpdatedAt = GETDATE()
                WHERE Id = @p2
            `, [court || null, circuit || null, caseId]);
        }

        // ✅ حفظ موضوع الجلسة (subject) في نفس المكان الذي تُقرأ منه شاشة العرض:
        // شاشة sessions/details بتعرض الموضوع عن طريق COALESCE(ll.Subject, c.Subject)
        // — أي أن قيمة درجة التقاضي (LitigationLevels) لها الأولوية دائماً طالما
        // الجلسة مرتبطة بدرجة تقاضي. من قبل كان "subject" بيوصل من الفورم لكن
        // مكنش بيتحفظ في أي مكان إلا لو القضية جديدة بتتنشئ لأول مرة، فكان بيختفي
        // من الجدول تحت بعد الحفظ (خصوصاً في جلسات الاستئناف/النقض).
        if (subject && subject !== '') {
            await db.query(
                "UPDATE Cases SET Subject = @p0, UpdatedAt = GETDATE() WHERE Id = @p1",
                [subject, caseId]
            );

            if (litigationLevelId) {
                await db.query(
                    "UPDATE LitigationLevels SET Subject = @p0 WHERE Id = @p1",
                    [subject, litigationLevelId]
                );
            }
        }

        // ✅ تخزين الوقت كنص VARCHAR مع حفظ معرف ورقم درجة التقاضي
        const sessionSql = `
            INSERT INTO Sessions (
                CaseId, SessionDate, SessionTime, Stage,
                AttendingLawyerId, ActionTaken,
                NextSessionDate, IsClosed, [Status], Notes,
                Result, AppealAction, SessionNotes, LitigationLevelId, SessionCaseNumber
            ) VALUES (
                @p0, @p1, @p2, @p3, @p4, @p5, @p6, @p7, @p8, @p9,
                @p10, @p11, @p12, @p13, @p14
            );
            SELECT SCOPE_IDENTITY() AS Id;
        `;

        const result = await db.query(sessionSql, [
            caseId,
            sessionDate,
            storedTime,
            stage || 'ابتدائي',
            attendingId || null,
            action || '',
            nextSessionDate || null,
            isClosed || 0,
            status || 'متداولة',
            null,
            null,
            null,
            null,
            litigationLevelId || null,
            sessionCaseNumber || null
        ]);

        const newSessionId = result[0]?.Id;

        if (isClosed || status === 'مغلقة' || status === 'عُقدت') {
            await db.query(
                "UPDATE Cases SET [Status] = N'مغلقة', CurrentStage = N'نهائي', UpdatedAt = GETDATE() WHERE Id = @p0",
                [caseId]
            );
            console.log(`✅ تم إغلاق القضية ${caseNumber}`);
        }

        if (litigationLevelId) {
            await db.query(
                "UPDATE LitigationLevels SET [Status] = 'open' WHERE Id = @p0",
                [litigationLevelId]
            );
            console.log(`✅ تم تحديث درجة التقاضي ${litigationLevelId}`);
        }

        console.log(`✅ تم حفظ الجلسة مع الوقت (كنص): ${storedTime}`);

        await logActivity(req, 'add', `تمت إضافة جلسة جديدة للقضية ${caseNumber || ''} بتاريخ ${sessionDate || ''}`, 'الجلسات');

        res.json({
            success: true,
            message: 'تم حفظ الجلسة بنجاح',
            id: newSessionId,
            caseId: caseId,
            savedTime: storedTime
        });

    } catch (error) {
        console.error('❌ خطأ في إضافة الجلسة:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

// ============================================
// 15. تحديث جلسة
// ============================================
// ⚠️ ملحوظة: تم حذف نسخة قديمة مكررة من هذا الـ route كانت معرّفة هنا
// (app.put('/api/sessions/:id', ...)) وكانت بتمنع تنفيذ النسخة الصحيحة
// الموجودة تحت (التي تحفظ Result / AppealAction / SessionNotes / IsClosed)
// لأن Express بينفذ أول route مطابق بس. النسخة الكاملة موجودة بالأسفل.

// ============================================
// 16. حذف جلسة
// ============================================
app.delete('/api/sessions/:id', async (req, res) => {
    try {
        const { id } = req.params;
        
        const check = await db.query("SELECT * FROM Sessions WHERE Id = @p0", [id]);
        if (check.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'الجلسة غير موجودة'
            });
        }
        
        // 💾 حفظ في الأرشيف قبل الحذف
        await archiveRecord('Session', id, check[0], PAGE_URLS.Session);
        
        await db.query("DELETE FROM Sessions WHERE Id = @p0", [id]);

        // ✅ إعادة حساب نتيجة القضية بعد حذف الجلسة — لو الجلسة المحذوفة كانت هي صاحبة
        // آخر نتيجة (تاريخياً)، القضية ترجع تاخد نتيجة الجلسة المحسومة اللي قبلها،
        // أو تفضل من غير نتيجة لو معدش فيه جلسات محسومة تانية.
        await recalculateCaseResult(check[0].CaseId);

        const sessCaseRow = await db.query("SELECT CaseNumber FROM Cases WHERE Id = @p0", [check[0].CaseId]);
        const sessCaseNumber = sessCaseRow[0]?.CaseNumber || check[0].CaseId;
        await logActivity(req, 'delete', `تم حذف جلسة بتاريخ ${check[0].SessionDate || ''} للقضية ${sessCaseNumber}`, 'الجلسات');
        
        res.json({
            success: true,
            message: 'تم حذف الجلسة ونقلها للأرشيف بنجاح'
        });
    } catch (error) {
        console.error('❌ خطأ في حذف الجلسة:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

// ============================================
// إحصائيات لوحة التحكم - نسخة معدلة
// ============================================
app.get('/api/dashboard', async (req, res) => {
    try {
        const stats = {};

        // إحصائيات القضايا
        const totalCases = await db.query("SELECT COUNT(*) AS Total FROM Cases");
        stats.totalCases = totalCases[0]?.Total || 0;

        const openCases = await db.query("SELECT COUNT(*) AS Total FROM Cases WHERE [Status] = N'مفتوحة'");
        stats.openCases = openCases[0]?.Total || 0;

        const closedCases = await db.query("SELECT COUNT(*) AS Total FROM Cases WHERE [Status] = N'مغلقة'");
        stats.closedCases = closedCases[0]?.Total || 0;

        const today = new Date().toISOString().split('T')[0];
        const todaySessions = await db.query("SELECT COUNT(*) AS Total FROM Sessions WHERE SessionDate = @p0", [today]);
        stats.todaySessions = todaySessions[0]?.Total || 0;

        const activeLawyers = await db.query("SELECT COUNT(*) AS Total FROM Lawyers WHERE IsActive = 1");
        stats.activeLawyers = activeLawyers[0]?.Total || 0;

        stats.casesByCategory = await db.query("SELECT Category, COUNT(*) AS Count FROM Cases GROUP BY Category");
        stats.casesByStage = await db.query("SELECT CurrentStage, COUNT(*) AS Count FROM Cases GROUP BY CurrentStage");
        stats.latestCases = await db.query("SELECT TOP 5 * FROM Cases ORDER BY CreatedAt DESC");

        // ====== إحصائيات درجات التقاضي ======
        
        // 1. المرحلة الابتدائية - فقط العدد الإجمالي من جدول Cases
        const initialStats = await db.query(`
            SELECT 
                COUNT(*) AS Total,
                SUM(CASE WHEN Plaintiff LIKE N'%شركة%' OR Plaintiff LIKE N'%الصرف%' OR Plaintiff LIKE N'%الشركة%' THEN 1 ELSE 0 END) AS FromCompany,
                SUM(CASE WHEN (Plaintiff NOT LIKE N'%شركة%' AND Plaintiff NOT LIKE N'%الصرف%' AND Plaintiff NOT LIKE N'%الشركة%') OR Plaintiff IS NULL THEN 1 ELSE 0 END) AS FromOpponent 
            FROM Cases 
            WHERE CurrentStage NOT LIKE N'%استئناف%' 
              AND CurrentStage NOT LIKE N'%نقض%'
              AND CurrentStage NOT LIKE N'%طعن%'
              AND CurrentStage NOT LIKE N'%التماس%'
              AND CurrentStage NOT LIKE N'%تظلم%'
              AND CurrentStage NOT LIKE N'%اشكال%'
              AND CurrentStage NOT LIKE N'%إشكال%'
              AND CurrentStage NOT LIKE N'%علية%'
              AND CurrentStage NOT LIKE N'%عليا%'
              OR CurrentStage IS NULL
        `);
        
        // 2. الاستئناف من جدول LitigationLevels
        const appealStats = await db.query(`
            SELECT 
                COUNT(*) AS Total,
                SUM(CASE WHEN RequestedBy = N'الشركة (نحن)' OR RequestedBy LIKE N'%الشركة%' OR RequestedBy IS NULL THEN 1 ELSE 0 END) AS FromCompany,
                SUM(CASE WHEN RequestedBy LIKE N'%الخصم%' THEN 1 ELSE 0 END) AS FromOpponent
            FROM LitigationLevels
            WHERE StageType = 'appeal' OR StageType = N'استئناف'
        `);

        // 3. النقض من جدول LitigationLevels
        const cassationStats = await db.query(`
            SELECT 
                COUNT(*) AS Total,
                SUM(CASE WHEN RequestedBy = N'الشركة (نحن)' OR RequestedBy LIKE N'%الشركة%' OR RequestedBy IS NULL THEN 1 ELSE 0 END) AS FromCompany,
                SUM(CASE WHEN RequestedBy LIKE N'%الخصم%' THEN 1 ELSE 0 END) AS FromOpponent
            FROM LitigationLevels
            WHERE StageType = 'cassation' OR StageType = N'نقض' OR StageType = N'طعن بالنقض'
        `);

        // 4. الإشكال من جدول LitigationLevels
        const eshkalStats = await db.query(`
            SELECT 
                COUNT(*) AS Total,
                SUM(CASE WHEN RequestedBy = N'الشركة (نحن)' OR RequestedBy LIKE N'%الشركة%' OR RequestedBy IS NULL THEN 1 ELSE 0 END) AS FromCompany,
                SUM(CASE WHEN RequestedBy LIKE N'%الخصم%' THEN 1 ELSE 0 END) AS FromOpponent
            FROM LitigationLevels
            WHERE StageType = 'eshkal' OR StageType = N'اشكال' OR StageType = N'إشكال'
        `);

        // 5. إشكال في التنفيذ من جدول LitigationLevels
        const eshkalTanfeethStats = await db.query(`
            SELECT 
                COUNT(*) AS Total,
                SUM(CASE WHEN RequestedBy = N'الشركة (نحن)' OR RequestedBy LIKE N'%الشركة%' OR RequestedBy IS NULL THEN 1 ELSE 0 END) AS FromCompany,
                SUM(CASE WHEN RequestedBy LIKE N'%الخصم%' THEN 1 ELSE 0 END) AS FromOpponent
            FROM LitigationLevels
            WHERE StageType = 'eshkal_tanfeeth' OR StageType = 'execution' OR StageType LIKE N'%تنفيذ%'
        `);

        // 6. التماس إعادة النظر من جدول LitigationLevels
        const iltimasStats = await db.query(`
            SELECT 
                COUNT(*) AS Total,
                SUM(CASE WHEN RequestedBy = N'الشركة (نحن)' OR RequestedBy LIKE N'%الشركة%' OR RequestedBy IS NULL THEN 1 ELSE 0 END) AS FromCompany,
                SUM(CASE WHEN RequestedBy LIKE N'%الخصم%' THEN 1 ELSE 0 END) AS FromOpponent
            FROM LitigationLevels
            WHERE StageType = 'iltimas' OR StageType LIKE N'%التماس%'
        `);

        // تهيئة النتائج
        stats.litigationStats = {
            initial: { total: 0, fromCompany: 0, fromOpponent: 0 },
            appeal: { total: 0, fromCompany: 0, fromOpponent: 0 },
            cassation: { total: 0, fromCompany: 0, fromOpponent: 0 },
            eshkal: { total: 0, fromCompany: 0, fromOpponent: 0 },
            eshkalTanfeeth: { total: 0, fromCompany: 0, fromOpponent: 0 },
            iltimas: { total: 0, fromCompany: 0, fromOpponent: 0 }
        };

        // إضافة المرحلة الابتدائية (عدد فقط)
        if (initialStats.length > 0) {
            stats.litigationStats.initial.total = initialStats[0]?.Total || 0;
            stats.litigationStats.initial.fromCompany = initialStats[0]?.FromCompany || 0;
            stats.litigationStats.initial.fromOpponent = initialStats[0]?.FromOpponent || 0;
        }

        // إضافة الاستئناف
        if (appealStats.length > 0) {
            stats.litigationStats.appeal.total = appealStats[0]?.Total || 0;
            stats.litigationStats.appeal.fromCompany = appealStats[0]?.FromCompany || 0;
            stats.litigationStats.appeal.fromOpponent = appealStats[0]?.FromOpponent || 0;
        }

        // إضافة النقض
        if (cassationStats.length > 0) {
            stats.litigationStats.cassation.total = cassationStats[0]?.Total || 0;
            stats.litigationStats.cassation.fromCompany = cassationStats[0]?.FromCompany || 0;
            stats.litigationStats.cassation.fromOpponent = cassationStats[0]?.FromOpponent || 0;
        }

        // إضافة الإشكال
        if (eshkalStats.length > 0) {
            stats.litigationStats.eshkal.total = eshkalStats[0]?.Total || 0;
            stats.litigationStats.eshkal.fromCompany = eshkalStats[0]?.FromCompany || 0;
            stats.litigationStats.eshkal.fromOpponent = eshkalStats[0]?.FromOpponent || 0;
        }

        // إضافة إشكال في التنفيذ
        if (eshkalTanfeethStats.length > 0) {
            stats.litigationStats.eshkalTanfeeth.total = eshkalTanfeethStats[0]?.Total || 0;
            stats.litigationStats.eshkalTanfeeth.fromCompany = eshkalTanfeethStats[0]?.FromCompany || 0;
            stats.litigationStats.eshkalTanfeeth.fromOpponent = eshkalTanfeethStats[0]?.FromOpponent || 0;
        }

        // إضافة التماس إعادة النظر
        if (iltimasStats.length > 0) {
            stats.litigationStats.iltimas.total = iltimasStats[0]?.Total || 0;
            stats.litigationStats.iltimas.fromCompany = iltimasStats[0]?.FromCompany || 0;
            stats.litigationStats.iltimas.fromOpponent = iltimasStats[0]?.FromOpponent || 0;
        }

        console.log('📊 إحصائيات درجات التقاضي:', stats.litigationStats);

        res.json({
            success: true,
            data: stats
        });

    } catch (error) {
        console.error('❌ خطأ في جلب الإحصائيات:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

// ============================================
// 19. جلب المرفقات
// ============================================
app.get('/api/attachments', async (req, res) => {
    try {
        const { caseId, sessionId } = req.query;
        
        let sql = `
            SELECT 
                Id,
                CaseId,
                SessionId,
                FileName,
                FilePath,
                FileType,
                FileSize,
                UploadedAt
            FROM Attachments
            WHERE 1=1
        `;
        
        const params = [];
        if (caseId) {
            sql += ` AND CaseId = @p0`;
            params.push(caseId);
        }
        if (sessionId) {
            sql += ` AND SessionId = @p1`;
            params.push(sessionId);
        }
        
        sql += ` ORDER BY UploadedAt DESC`;
        
        const attachments = await db.query(sql, params);
        res.json({
            success: true,
            data: attachments
        });
    } catch (error) {
        console.error('❌ خطأ في جلب المرفقات:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

// ============================================
// إضافة مرفق جديد
// ============================================
app.post('/api/attachments', async (req, res) => {
    try {
        const { caseId, sessionId, fileName, filePath, fileType, fileSize } = req.body;
        if (!fileName || (!caseId && !sessionId)) {
            return res.status(400).json({ success: false, message: 'يرجى تحديد القضية/الجلسة واسم الملف' });
        }
        const insertSql = `
            INSERT INTO Attachments (CaseId, SessionId, FileName, FilePath, FileType, FileSize, UploadedAt)
            VALUES (@p0, @p1, @p2, @p3, @p4, @p5, GETDATE());
            SELECT SCOPE_IDENTITY() AS Id;
        `;
        const result = await db.query(insertSql, [
            caseId || null,
            sessionId || null,
            fileName,
            filePath || '',
            fileType || 'image/jpeg',
            fileSize || 0
        ]);
        res.json({
            success: true,
            message: 'تم حفظ المرفق بنجاح',
            attachmentId: result[0]?.Id
        });
    } catch (error) {
        console.error('❌ خطأ في حفظ المرفق:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

// ============================================
// حذف مرفق
// ============================================
app.delete('/api/attachments/:id', async (req, res) => {
    try {
        const { id } = req.params;
        await db.query("DELETE FROM Attachments WHERE Id = @p0", [id]);
        res.json({
            success: true,
            message: 'تم حذف المرفق بنجاح'
        });
    } catch (error) {
        console.error('❌ خطأ في حذف المرفق:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

// ================================================================
// 19.5 نظام صلاحيات التحقيقات (Users / Roles / Modules الحقيقي)
// ================================================================
// ملحوظة: النظام ده خاص بس بيوزرز قسم "التحقيقات". يوزرز قسم "القضايا"
// (access.html القديمة) لسه شغالين بنفس الطريقة (localStorage) وملهمش
// علاقة بجداول Users/Roles/Modules خالص.

const INVESTIGATION_ROLE_MODULES = {
    'InvestigationIT': ['investigations-dashboard', 'new-investigation', 'investigation-details', 'investigation-reports', 'investigation-archive', 'investigation-logs', 'investigation-users'],
    'InvestigationAdmin': ['investigations-dashboard', 'new-investigation', 'investigation-details', 'investigation-reports', 'investigation-users'],
    'InvestigationUser': ['investigations-dashboard', 'new-investigation', 'investigation-details', 'investigation-reports', 'investigation-archive', 'investigation-logs'],
    'InvestigationDataEntry': ['investigations-dashboard', 'new-investigation', 'investigation-details', 'investigation-reports', 'investigation-archive', 'investigation-logs'],
    'InvestigationViewer': ['investigations-dashboard', 'investigation-details', 'investigation-reports']
};
const INVESTIGATION_ROLE_LABELS = {
    'InvestigationIT': 'مسؤول IT (صلاحية كاملة + الأرشيف والحركات واليوزرز)',
    'InvestigationAdmin': 'أدمن Admin (كل شيء ما عدا الأرشيف والحركات)',
    'InvestigationUser': 'مستخدم عادي (كل شيء ما عدا إضافة المستخدمين)',
    'InvestigationDataEntry': 'مدخل بيانات',
    'InvestigationViewer': 'مشاهد'
};

// جلب بيانات يوزر التحقيقات الحالي (من هيدر X-Username اللي بيرسله activity-logger.js تلقائياً)
// مع قائمة الموديولات (الصفحات) المسموح له بيها حسب دوره
async function getRequestInvestigationUser(req) {
    const username = getRequestUsername(req);
    if (!username || username === 'غير معروف') return { user: null, modules: [] };

    const rows = await db.query(
        `SELECT u.Id, u.Username, u.FullName, u.IsActive, r.Id AS RoleId, r.Name AS RoleName
         FROM Users u LEFT JOIN Roles r ON r.Id = u.RoleId
         WHERE u.Username = @p0`,
        [username]
    );
    if (rows.length === 0 || !rows[0].IsActive) return { user: null, modules: [] };

    const user = rows[0];
    let modules = INVESTIGATION_ROLE_MODULES[user.RoleName] || [
        'investigations-dashboard', 'new-investigation', 'investigation-details', 
        'investigation-reports', 'investigation-archive', 'investigation-logs', 'investigation-users'
    ];
    try {
        const modRows = await db.query(
            `SELECT m.Name FROM RoleModules rm JOIN Modules m ON m.Id = rm.ModuleId WHERE rm.RoleId = @p0`,
            [user.RoleId]
        );
        if (modRows.length > 0) {
            const dbMods = modRows.map(m => m.Name);
            modules = Array.from(new Set([...modules, ...dbMods]));
        }
    } catch (e) {}

    return { user, modules };
}

// Middleware: يتأكد إن يوزر التحقيقات الحالي (بناءً على هيدر X-Username) عنده صلاحية موديول معين
// لو مفيش يوزر تحقيقات بالاسم ده أصلاً (مثلاً يوزر قضايا قديم) بيترفض الطلب بـ 401/403
function requireInvestigationModule(moduleName) {
    return async (req, res, next) => {
        try {
            const username = getRequestUsername(req);
            const uLower = (username || '').toLowerCase();
            if (uLower === 'admin' || uLower === 'it' || uLower === 'inv') {
                req.invUser = { Id: 1, Username: username, FullName: 'مدير النظام', RoleName: 'InvestigationAdmin' };
                return next();
            }

            const { user, modules } = await getRequestInvestigationUser(req);
            if (!user) {
                return res.status(401).json({ success: false, message: 'يجب تسجيل الدخول بيوزر تحقيقات صالح' });
            }
            if (!modules.includes(moduleName)) {
                return res.status(403).json({ success: false, message: '⛔ ليس لديك صلاحية للقيام بهذا الإجراء' });
            }
            req.invUser = user;
            next();
        } catch (error) {
            res.status(500).json({ success: false, message: error.message });
        }
    };
}

// ===== تسجيل دخول يوزرز النظام =====
app.post('/api/auth/login', async (req, res) => {
    try {
        const { username, password } = req.body;
        if (!username || !password) {
            return res.status(400).json({ success: false, message: 'اسم المستخدم وكلمة المرور مطلوبين' });
        }

        const rows = await db.query(
            `SELECT u.Id, u.Username, u.FullName, u.PasswordHash, u.IsActive, u.Permissions, u.IsReadonly, u.CasesRole, r.Id AS RoleId, r.Name AS RoleName
             FROM Users u LEFT JOIN Roles r ON r.Id = u.RoleId
             WHERE u.Username = @p0`,
            [username]
        );

        if (rows.length === 0 || !rows[0].IsActive) {
            return res.status(401).json({ success: false, message: 'اسم المستخدم أو كلمة المرور غير صحيحة' });
        }

        const user = rows[0];
        const passwordOk = await bcrypt.compare(password, user.PasswordHash);
        if (!passwordOk) {
            return res.status(401).json({ success: false, message: 'اسم المستخدم أو كلمة المرور غير صحيحة' });
        }

        let permissions = [];
        if (user.RoleId) {
            const modRows = await db.query(
                `SELECT m.Name FROM RoleModules rm JOIN Modules m ON m.Id = rm.ModuleId WHERE rm.RoleId = @p0`,
                [user.RoleId]
            );
            permissions = modRows.map(m => m.Name);
        } else if (user.Permissions) {
            try {
                permissions = JSON.parse(user.Permissions);
            } catch (e) {
                permissions = [];
            }
        }

        await db.query(`UPDATE Users SET LastLogin = GETDATE() WHERE Id = @p0`, [user.Id]);
        const loginCat = (user.RoleName && user.RoleName.startsWith('Investigation')) || user.Username.toLowerCase() === 'inv' ? 'investigation' : 'cases';
        await logActivity(req, 'login', `تسجيل دخول المستخدم: ${user.Username}`, 'تسجيل الدخول', loginCat, user.Username);

        res.json({
            success: true,
            data: {
                username: user.Username,
                fullName: user.FullName,
                role: user.RoleName || null,
                casesRole: user.CasesRole || null,
                permissions,
                readonly: user.IsReadonly === true || user.RoleName === 'InvestigationViewer'
            }
        });
    } catch (error) {
        console.error('❌ خطأ في تسجيل الدخول:', error);
        res.status(500).json({ success: false, message: error.message });
    }
});

// ===== قائمة أدوار التحقيقات المتاحة (لقائمة اختيار الدور في صفحة اليوزرز) =====
app.get('/api/investigation-roles', async (req, res) => {
    try {
        const rows = await db.query(
            `SELECT Id, Name, Description FROM Roles WHERE Name IN (@p0, @p1, @p2, @p3) AND IsActive = 1`,
            ['InvestigationAdmin', 'InvestigationUser', 'InvestigationDataEntry', 'InvestigationViewer']
        );
        res.json({ success: true, data: rows });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
});

// ===== جلب كل يوزرز التحقيقات (أدمن التحقيقات بس) =====
app.get('/api/investigation-users', requireInvestigationModule('investigation-users'), async (req, res) => {
    try {
        const rows = await db.query(
            `SELECT u.Id, u.Username, u.FullName, u.Email, u.IsActive, u.CreatedAt, u.LastLogin, u.Permissions, u.PlainPassword, r.Id AS RoleId, r.Name AS RoleName
             FROM Users u LEFT JOIN Roles r ON r.Id = u.RoleId
             WHERE r.Name IN (@p0, @p1, @p2, @p3, @p4) OR r.Name LIKE '%Investigation%' OR u.RoleId IS NOT NULL
             ORDER BY u.CreatedAt DESC`,
            ['InvestigationIT', 'InvestigationAdmin', 'InvestigationUser', 'InvestigationDataEntry', 'InvestigationViewer']
        );
        const data = rows.map(u => {
            let perms = [];
            if (u.Permissions) {
                try { perms = JSON.parse(u.Permissions); } catch (e) { perms = []; }
            } else if (u.RoleName && INVESTIGATION_ROLE_MODULES[u.RoleName]) {
                perms = INVESTIGATION_ROLE_MODULES[u.RoleName];
            }
            return { ...u, permissions: perms, Permissions: u.Permissions };
        });
        res.json({ success: true, data });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
});

// ===== إضافة يوزر تحقيقات جديد (أدمن التحقيقات بس) =====
app.post('/api/investigation-users', requireInvestigationModule('investigation-users'), async (req, res) => {
    try {
        const { username, fullName, password, permissions } = req.body;
        const roleName = req.body.roleName || 'InvestigationUser';
        if (!username || !fullName || !password) {
            return res.status(400).json({ success: false, message: 'كل الحقول مطلوبة' });
        }
        if (!INVESTIGATION_ROLE_MODULES[roleName]) {
            return res.status(400).json({ success: false, message: 'الدور غير معروف' });
        }

        const exists = await db.query('SELECT Id FROM Users WHERE Username = @p0', [username]);
        if (exists.length > 0) {
            return res.status(409).json({ success: false, message: 'اسم المستخدم مستخدم بالفعل' });
        }

        let mappedRole = roleName;
        if (roleName === 'InvestigationUser') {
            mappedRole = 'InvestigationDataEntry';
        }

        let role = await db.query('SELECT Id FROM Roles WHERE Name = @p0 OR Name = @p1', [roleName, mappedRole]);
        let roleId = 2;
        if (role.length > 0) {
            roleId = role[0].Id;
        } else {
            const anyRole = await db.query("SELECT TOP 1 Id FROM Roles WHERE Name LIKE '%Investigation%' ORDER BY Id ASC");
            if (anyRole.length > 0) roleId = anyRole[0].Id;
        }

        const hash = await bcrypt.hash(password, 10);
        await db.query(
            `INSERT INTO Users (Username, PasswordHash, FullName, RoleId, Permissions, IsActive, PlainPassword, CreatedAt)
             VALUES (@p0, @p1, @p2, @p3, @p4, 1, @p5, GETDATE())`,
            [username, hash, fullName, roleId, JSON.stringify(permissions || INVESTIGATION_ROLE_MODULES[roleName] || []), password]
        );

        await logActivity(req, 'add', `تم إضافة يوزر تحقيقات جديد: ${username} (${INVESTIGATION_ROLE_LABELS[roleName] || roleName})`, 'مستخدمو التحقيقات');
        res.json({ success: true, message: 'تم إضافة المستخدم بنجاح' });
    } catch (error) {
        console.error('❌ خطأ في إضافة يوزر تحقيقات:', error);
        res.status(500).json({ success: false, message: error.message });
    }
});

// ===== تعديل يوزر تحقيقات (أدمن التحقيقات بس) =====
app.put('/api/investigation-users/:id', requireInvestigationModule('investigation-users'), async (req, res) => {
    try {
        const { id } = req.params;
        const { fullName, password, roleName, isActive, permissions } = req.body;

        const existing = await db.query('SELECT * FROM Users WHERE Id = @p0', [id]);
        if (existing.length === 0) {
            return res.status(404).json({ success: false, message: 'المستخدم غير موجود' });
        }

        let roleId = existing[0].RoleId;
        if (roleName) {
            let mappedRole = roleName;
            if (roleName === 'InvestigationUser') {
                mappedRole = 'InvestigationDataEntry';
            }
            const role = await db.query('SELECT Id FROM Roles WHERE Name = @p0 OR Name = @p1', [roleName, mappedRole]);
            if (role.length > 0) {
                roleId = role[0].Id;
            }
        }

        const permsJson = permissions !== undefined ? JSON.stringify(permissions) : existing[0].Permissions;

        if (password) {
            const hash = await bcrypt.hash(password, 10);
            await db.query(
                `UPDATE Users SET FullName = @p0, RoleId = @p1, IsActive = @p2, Permissions = @p3, PasswordHash = @p4, PlainPassword = @p5, UpdatedAt = GETDATE() WHERE Id = @p6`,
                [fullName || existing[0].FullName, roleId, isActive === undefined ? existing[0].IsActive : !!isActive, permsJson, hash, password, id]
            );
        } else {
            await db.query(
                `UPDATE Users SET FullName = @p0, RoleId = @p1, IsActive = @p2, Permissions = @p3, UpdatedAt = GETDATE() WHERE Id = @p4`,
                [fullName || existing[0].FullName, roleId, isActive === undefined ? existing[0].IsActive : !!isActive, permsJson, id]
            );
        }

        await logActivity(req, 'edit', `تم تعديل يوزر تحقيقات: ${existing[0].Username}`, 'مستخدمو التحقيقات');
        res.json({ success: true, message: 'تم تعديل المستخدم بنجاح' });
    } catch (error) {
        console.error('❌ خطأ في تعديل يوزر تحقيقات:', error);
        res.status(500).json({ success: false, message: error.message });
    }
});

// ===== حذف يوزر تحقيقات (أدمن التحقيقات بس) =====
app.delete('/api/investigation-users/:id', requireInvestigationModule('investigation-users'), async (req, res) => {
    try {
        const { id } = req.params;
        const existing = await db.query('SELECT Username FROM Users WHERE Id = @p0', [id]);
        if (existing.length === 0) {
            return res.status(404).json({ success: false, message: 'المستخدم غير موجود' });
        }
        if (existing[0].Username === req.invUser.Username) {
            return res.status(400).json({ success: false, message: 'لا يمكنك حذف حسابك الحالي' });
        }

        await db.query('DELETE FROM Users WHERE Id = @p0', [id]);
        await logActivity(req, 'delete', `تم حذف يوزر تحقيقات: ${existing[0].Username}`, 'مستخدمو التحقيقات');
        res.json({ success: true, message: 'تم حذف المستخدم بنجاح' });
    } catch (error) {
        console.error('❌ خطأ في حذف يوزر تحقيقات:', error);
        res.status(500).json({ success: false, message: error.message });
    }
});

// ================================================================
// 🔐 نظام صلاحيات وإدارة يوزرز القضايا (access.html) في قاعدة البيانات
// ================================================================

async function requireAdmin(req, res, next) {
    const admin = await isAdminRequest(req);
    if (admin) return next();
    return res.status(403).json({ success: false, message: '⛔ غير مصرح للقيام بهذا الإجراء' });
}

// نفس منطق requireAdmin بس كدالة بترجع true/false بدل middleware
// بتُستخدم في أماكن محتاجة تفرّق في السلوك بين الأدمن والمستخدم العادي (مش ترفض الطلب نهائياً)
// مثال: الأرشيف — الأدمن بيشوف/يمسح كل حاجة فعلياً، والمستخدم العادي بيشوف بس اللي مش مخفي، ومسحه بيكون إخفاء فقط
async function isAdminRequest(req) {
    const username = getRequestUsername(req);
    const uLower = username.toLowerCase();
    if (uLower === 'admin' || uLower === 'it') return true;
    try {
        const rows = await db.query(`SELECT CasesRole FROM Users WHERE Username = @p0`, [username]);
        if (rows.length > 0 && rows[0].CasesRole === 'IT') return true;
    } catch (e) {}
    return false;
}

// ===== تغيير كلمة المرور للمستخدم الحالي (أي مستخدم) =====
app.post('/api/auth/change-password', async (req, res) => {
    try {
        const username = getRequestUsername(req);
        const { currentPassword, newPassword } = req.body;

        if (!username || username === 'غير معروف') {
            return res.status(401).json({ success: false, message: 'يجب تسجيل الدخول أولاً' });
        }
        if (!currentPassword || !newPassword) {
            return res.status(400).json({ success: false, message: 'جميع الحقول مطلوبة' });
        }

        const rows = await db.query(
            `SELECT Id, PasswordHash, PlainPassword FROM Users WHERE Username = @p0 AND IsActive = 1`,
            [username]
        );
        if (rows.length === 0) {
            return res.status(404).json({ success: false, message: 'المستخدم غير موجود' });
        }

        const user = rows[0];
        const passwordOk = await bcrypt.compare(currentPassword, user.PasswordHash);
        if (!passwordOk) {
            return res.status(401).json({ success: false, message: 'كلمة المرور الحالية غير صحيحة' });
        }

        const hash = await bcrypt.hash(newPassword, 10);
        await db.query(
            `UPDATE Users SET PasswordHash = @p0, PlainPassword = @p1, UpdatedAt = GETDATE() WHERE Id = @p2`,
            [hash, newPassword, user.Id]
        );

        await logActivity(req, 'edit', `تم تغيير كلمة المرور للمستخدم: ${username}`, 'الملف الشخصي');
        res.json({ success: true, message: 'تم تغيير كلمة المرور بنجاح' });
    } catch (error) {
        console.error('❌ خطأ في تغيير كلمة المرور:', error);
        res.status(500).json({ success: false, message: error.message });
    }
});

// ===== جلب كل يوزرز القضايا النشطين والظاهرين (الأدمن والمستخدمين) =====
app.get('/api/users', async (req, res) => {
    try {
        const username = getRequestUsername(req);
        if (!username || username === 'غير معروف') {
            return res.status(401).json({ success: false, message: 'يجب تسجيل الدخول أولاً' });
        }
        
        const rows = await db.query(
            `SELECT Id, Username, FullName, PlainPassword, Permissions, IsReadonly, IsActive, CasesRole, CreatedAt
             FROM Users
             WHERE IsHidden = 0 OR IsHidden IS NULL
             ORDER BY CreatedAt DESC`
        );
        
        const users = rows.map(r => {
            let permissions = [];
            if (r.Permissions) {
                try {
                    permissions = JSON.parse(r.Permissions);
                } catch (e) {
                    permissions = [];
                }
            }
            return {
                Id: r.Id,
                username: r.Username,
                fullName: r.FullName,
                password: r.PlainPassword || '',
                permissions: permissions,
                casesRole: r.CasesRole || null,
                readonly: r.IsReadonly === true,
                isActive: r.IsActive === true
            };
        });
        
        res.json({ success: true, data: users });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
});

// ===== إضافة يوزر قضايا جديد (للأدمن فقط) =====
app.post('/api/users', requireAdmin, async (req, res) => {
    try {
        const { username, fullName, password, permissions, casesRole } = req.body;
        if (!username || !fullName || !password) {
            return res.status(400).json({ success: false, message: 'كل الحقول مطلوبة' });
        }

        const exists = await db.query('SELECT Id FROM Users WHERE Username = @p0', [username]);
        if (exists.length > 0) {
            return res.status(409).json({ success: false, message: 'اسم المستخدم مستخدم بالفعل' });
        }

        const hash = await bcrypt.hash(password, 10);
        await db.query(
            `INSERT INTO Users (Username, PasswordHash, FullName, Permissions, IsReadonly, IsHidden, PlainPassword, CasesRole, IsActive, CreatedAt)
             VALUES (@p0, @p1, @p2, @p3, 0, 0, @p4, @p5, 1, GETDATE())`,
            [username, hash, fullName, JSON.stringify(permissions || []), password, casesRole || 'User']
        );

        await logActivity(req, 'add', `تم إضافة مستخدم قضايا جديد: ${username}`, 'المستخدمون');
        res.json({ success: true, message: 'تم إضافة المستخدم بنجاح' });
    } catch (error) {
        console.error('❌ خطأ في إضافة مستخدم:', error);
        res.status(500).json({ success: false, message: error.message });
    }
});

// ===== تعديل يوزر قضايا (للأدمن فقط) =====
app.put('/api/users/:id', requireAdmin, async (req, res) => {
    try {
        const { id } = req.params;
        const { username, fullName, password, permissions, casesRole } = req.body;

        const existing = await db.query('SELECT * FROM Users WHERE Id = @p0', [id]);
        if (existing.length === 0) {
            return res.status(404).json({ success: false, message: 'المستخدم غير موجود' });
        }

        if (username && username.toLowerCase() !== existing[0].Username.toLowerCase()) {
            const exists = await db.query('SELECT Id FROM Users WHERE Username = @p0', [username]);
            if (exists.length > 0) {
                return res.status(409).json({ success: false, message: 'اسم المستخدم مستخدم بالفعل' });
            }
        }

        let hash = existing[0].PasswordHash;
        if (password && password !== existing[0].PlainPassword) {
            hash = await bcrypt.hash(password, 10);
        }

        await db.query(
            `UPDATE Users 
             SET Username = @p0, FullName = @p1, PasswordHash = @p2, PlainPassword = @p3, Permissions = @p4, CasesRole = @p5, UpdatedAt = GETDATE()
             WHERE Id = @p6`,
            [username || existing[0].Username, fullName || existing[0].FullName, hash, password || existing[0].PlainPassword, JSON.stringify(permissions || []), casesRole || existing[0].CasesRole || 'User', id]
        );

        let userLines = buildChangesText(existing[0], {
            Username: username || existing[0].Username,
            FullName: fullName || existing[0].FullName,
            CasesRole: casesRole || existing[0].CasesRole || 'User'
        }, { Username: 'اسم المستخدم', FullName: 'الاسم الكامل', CasesRole: 'الدور' });
        try {
            const oldPerms = JSON.parse(existing[0].Permissions || '[]');
            const newPerms = permissions || [];
            const added = newPerms.filter(p => !oldPerms.includes(p));
            const removed = oldPerms.filter(p => !newPerms.includes(p));
            if (added.length) userLines.push(`• صلاحيات تمت إضافتها: ${added.join('، ')}`);
            if (removed.length) userLines.push(`• صلاحيات تمت إزالتها: ${removed.join('، ')}`);
        } catch (e) {}
        if (password && password !== existing[0].PlainPassword) userLines.push('• كلمة المرور: تم تغييرها');
        await logActivity(req, 'edit', withChanges(`تم تعديل مستخدم قضايا: ${existing[0].Username}`, userLines), 'المستخدمون');
        res.json({ success: true, message: 'تم تعديل المستخدم بنجاح' });
    } catch (error) {
        console.error('❌ خطأ في تعديل مستخدم:', error);
        res.status(500).json({ success: false, message: error.message });
    }
});

// ===== حذف يوزر قضايا (للأدمن فقط) =====
app.delete('/api/users/:id', requireAdmin, async (req, res) => {
    try {
        const { id } = req.params;
        const existing = await db.query('SELECT Username, IsHidden FROM Users WHERE Id = @p0', [id]);
        if (existing.length === 0) {
            return res.status(404).json({ success: false, message: 'المستخدم غير موجود' });
        }
        if (existing[0].IsHidden === true) {
            return res.status(400).json({ success: false, message: 'لا يمكن حذف هذا المستخدم المحمي' });
        }
        if (existing[0].Username === req.headers['x-username']) {
            return res.status(400).json({ success: false, message: 'لا يمكنك حذف حسابك الحالي' });
        }

        await db.query('DELETE FROM Users WHERE Id = @p0', [id]);
        await logActivity(req, 'delete', `تم حذف مستخدم: ${existing[0].Username}`, 'المستخدمون');
        res.json({ success: true, message: 'تم حذف المستخدم بنجاح' });
    } catch (error) {
        console.error('❌ خطأ في حذف مستخدم:', error);
        res.status(500).json({ success: false, message: error.message });
    }
});

// ================================================================
// 20. نقاط نهاية التحقيقات (Investigations)
// ================================================================

// 20.1 جلب جميع التحقيقات مع بيانات الموظفين
app.get('/api/investigations', async (req, res) => {
    try {
        const { search, type, status } = req.query;
        
        // التأكد من وجود عمود ReceiptDate لتجنب الأخطاء عند أول تحميل للصفحة
        try {
            await db.query(`
                IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Investigations' AND COLUMN_NAME = 'ReceiptDate')
                BEGIN
                    ALTER TABLE Investigations ADD ReceiptDate DATE NULL;
                END
            `);
            await db.query(`
                IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Investigations' AND COLUMN_NAME = 'MaterialValue')
                BEGIN
                    ALTER TABLE Investigations ADD MaterialValue DECIMAL(18,2) NULL;
                END
            `);
        } catch (e) { /* تجاهل الخطأ */ }
        
        // ✅ المحامي المسؤول عن التحقيق: بنجيب اسمه من جدول المحامين (Lawyers.FullName)
        // أو من عمود LawyerName لو موجود في جدول Investigations، ولو مفيش أي منهم بنرجع لـ ManagerName
        let lawyerExpr = 'i.ManagerName';
        let lawyerJoin = '';
        try {
            const invCols = await db.query(`SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Investigations'`);
            const names = invCols.map(c => String(c.COLUMN_NAME).toLowerCase());
            const idCol = ['lawyerid', 'assignedlawyerid'].find(n => names.includes(n));
            const parts = [];
            if (idCol) {
                const realCol = invCols.find(c => String(c.COLUMN_NAME).toLowerCase() === idCol).COLUMN_NAME;
                lawyerJoin = `LEFT JOIN Lawyers lw ON lw.Id = i.[${realCol}]`;
                parts.push(`NULLIF(LTRIM(RTRIM(lw.FullName)), '')`);
            }
            if (names.includes('lawyername')) parts.push(`NULLIF(LTRIM(RTRIM(i.LawyerName)), '')`);
            if (parts.length) lawyerExpr = `COALESCE(${parts.join(', ')}, i.ManagerName)`;
        } catch (e) { /* لو فشل الاستعلام نفضل على ManagerName */ }

        let sql = `
            SELECT 
                i.Id,
                i.MemoNumber,
                i.MemoDate,
                i.ReceiptDate,
                i.MaterialValue,
                i.InvestigationType,
                i.ManagerName,
                ${lawyerExpr} AS LawyerName,
                i.MemoSummary,
                i.IncidentDate,
                i.IncidentPlace,
                i.IncidentDescription,
                i.[Status],
                i.CreatedAt,
                (SELECT STRING_AGG(em.FullName, ', ') FROM InvestigationEmployees ie JOIN EmployeesMaster em ON em.Id = ie.EmployeeMasterId WHERE ie.InvestigationId = i.Id) AS EmployeeNames,
                (SELECT STRING_AGG(em.Code, ', ') FROM InvestigationEmployees ie JOIN EmployeesMaster em ON em.Id = ie.EmployeeMasterId WHERE ie.InvestigationId = i.Id) AS EmployeeCodes,
                (SELECT COUNT(*) FROM Summons WHERE InvestigationId = i.Id) AS SummonsCount,
                (SELECT COUNT(*) FROM InvestigationWitnesses WHERE InvestigationId = i.Id) AS WitnessesCount,
                (SELECT COUNT(*) FROM InvestigationDecisions WHERE InvestigationId = i.Id) AS DecisionsCount,
                (SELECT COUNT(*) FROM Appeals WHERE InvestigationId = i.Id) AS AppealsCount,
                (SELECT COUNT(*) FROM FinalDecisions WHERE InvestigationId = i.Id) AS FinalDecisionsCount,
                (SELECT COUNT(*) FROM FinalMemos WHERE InvestigationId = i.Id) AS FinalMemosCount,
                (SELECT COUNT(*) FROM InvestigationEmployees WHERE InvestigationId = i.Id AND EmployeeStatement IS NOT NULL AND TRIM(EmployeeStatement) <> '') AS StatementsCount,
                (SELECT COUNT(*) FROM InvestigationEmployees WHERE InvestigationId = i.Id) AS EmployeeCount,
                (SELECT TOP 1 DecisionType FROM InvestigationDecisions WHERE InvestigationId = i.Id ORDER BY CreatedAt DESC) AS LastDecision
            FROM Investigations i
            ${lawyerJoin}
            WHERE 1=1
        `;
        
        const params = [];
        let paramIndex = 0;
        
        if (search) {
            sql += ` AND (
                i.MemoNumber LIKE @p${paramIndex} OR 
                i.ManagerName LIKE @p${paramIndex} OR 
                i.MemoSummary LIKE @p${paramIndex} OR
                EXISTS (SELECT 1 FROM InvestigationEmployees ie2 JOIN EmployeesMaster em2 ON em2.Id = ie2.EmployeeMasterId WHERE ie2.InvestigationId = i.Id AND (em2.FullName LIKE @p${paramIndex} OR em2.Code LIKE @p${paramIndex}))
            )`;
            params.push(`%${search}%`);
            paramIndex++;
        }
        if (type) {
            sql += ` AND i.InvestigationType = @p${paramIndex}`;
            params.push(type);
            paramIndex++;
        }
        if (status) {
            sql += ` AND i.[Status] = @p${paramIndex}`;
            params.push(status);
            paramIndex++;
        }
        
        sql += ` ORDER BY i.CreatedAt DESC`;
        
        const investigations = await db.query(sql, params);
        
        const data = investigations.map(inv => ({
            ...inv,
            hasDuplicate: false
        }));
        
        res.json({
            success: true,
            data: data,
            count: data.length
        });
    } catch (error) {
        console.error('❌ خطأ في جلب التحقيقات:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

// 20.2 سجل التتبعات للتحقيقات - يجب أن يكون قبل /:id لتجنب التعارض
app.get('/api/investigations/logs', async (req, res) => {
    try {
        const data = await fetchActivityLogs('investigation', req.query);
        res.json({ success: true, data });
    } catch (error) {
        console.error('❌ خطأ في جلب سجل تتبعات التحقيقات:', error);
        res.status(500).json({ success: false, message: error.message });
    }
});

// 20.3 جلب تحقيق برقمه (لصفحة التفاصيل)
app.get('/api/investigations/:id', async (req, res) => {
    try {
        const { id } = req.params;
        
        const invSql = `
            SELECT 
                i.*,
                (SELECT STRING_AGG(em.FullName, ', ') FROM InvestigationEmployees ie JOIN EmployeesMaster em ON em.Id = ie.EmployeeMasterId WHERE ie.InvestigationId = i.Id) AS EmployeeNames,
                (SELECT STRING_AGG(em.Code, ', ') FROM InvestigationEmployees ie JOIN EmployeesMaster em ON em.Id = ie.EmployeeMasterId WHERE ie.InvestigationId = i.Id) AS EmployeeCodes
            FROM Investigations i
            WHERE i.Id = @p0
        `;
        const invResult = await db.query(invSql, [id]);
        if (invResult.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'التحقيق غير موجود'
            });
        }
        const investigation = invResult[0];
        
        // جلب الموظفين مع WorkArea و JobGrade (عبر الجدول الرئيسي EmployeesMaster)
        const employees = await db.query(
            `SELECT ie.Id, em.Code AS EmployeeCode, em.FullName AS EmployeeName, em.JobGrade, em.WorkArea, ie.EmployeeStatement 
             FROM InvestigationEmployees ie
             JOIN EmployeesMaster em ON em.Id = ie.EmployeeMasterId
             WHERE ie.InvestigationId = @p0`,
            [id]
        );
        
        const summons = await db.query(
            `SELECT * FROM Summons WHERE InvestigationId = @p0 ORDER BY SummonsDate ASC`,
            [id]
        );
        
        const decision = await db.query(
            `SELECT * FROM InvestigationDecisions WHERE InvestigationId = @p0 ORDER BY CreatedAt DESC`,
            [id]
        );
        
        const appeal = await db.query(
            `SELECT * FROM Appeals WHERE InvestigationId = @p0`,
            [id]
        );
        
        const finalDecision = await db.query(
            `SELECT * FROM FinalDecisions WHERE InvestigationId = @p0`,
            [id]
        );
        
        const finalMemo = await db.query(
            `SELECT * FROM FinalMemos WHERE InvestigationId = @p0`,
            [id]
        );
        
        const witnesses = await db.query(
            `SELECT 
                iw.Id, iw.InvestigationId, iw.[Statement], iw.CreatedAt,
                wm.FullName AS Name, wm.NationalId, wm.Mobile, wm.[Address],
                em.Code AS EmployeeCode
             FROM InvestigationWitnesses iw
             JOIN WitnessesMaster wm ON wm.Id = iw.WitnessMasterId
             LEFT JOIN EmployeesMaster em ON em.Code = wm.Code AND em.IsActive = 1
             WHERE iw.InvestigationId = @p0
             ORDER BY iw.CreatedAt DESC`,
            [id]
        );
        
        res.json({
            success: true,
            data: {
                investigation,
                employees,
                summons,
                decision: decision[0] || null,
                appeal: appeal[0] || null,
                finalDecision: finalDecision[0] || null,
                finalMemo: finalMemo[0] || null,
                witnesses: witnesses
            }
        });
    } catch (error) {
        console.error('❌ خطأ في جلب التحقيق:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

// 20.3 إنشاء تحقيق جديد
app.post('/api/investigations', requireInvestigationModule('new-investigation'), async (req, res) => {
    try {
        const {
            memoNumber,
            memoDate,
            receiptDate,
            investigationType,
            managerName,
            memoSummary,
            materialValue,
            incidentDate,
            incidentPlace,
            incidentDescription,
            employees,
            summons
        } = req.body;

        if (!memoNumber || !memoDate || !investigationType || !managerName || !incidentDate || !employees || employees.length === 0) {
            return res.status(400).json({
                success: false,
                message: 'الرجاء ملء جميع الحقول المطلوبة'
            });
        }

        // إتاحة إضافة عمود ReceiptDate تلقائياً إذا لم يكن موجوداً
        try {
            await db.query(`
                IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Investigations' AND COLUMN_NAME = 'ReceiptDate')
                BEGIN
                    ALTER TABLE Investigations ADD ReceiptDate DATE NULL;
                END
            `);
            await db.query(`
                IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Investigations' AND COLUMN_NAME = 'MaterialValue')
                BEGIN
                    ALTER TABLE Investigations ADD MaterialValue DECIMAL(18,2) NULL;
                END
            `);
        } catch (e) { /* تجاهل الخطأ إن كان موجوداً */ }

        const transaction = new db.sql.Transaction(db.pool);
        await transaction.begin();

        try {
            const invSql = `
                INSERT INTO Investigations (
                    MemoNumber, MemoDate, ReceiptDate, InvestigationType, ManagerName, MemoSummary,
                    IncidentDate, IncidentPlace, IncidentDescription, [Status], MaterialValue
                ) VALUES (
                    @p0, @p1, @p2, @p3, @p4, @p5, @p6, @p7, @p8, @p9, @p10
                );
                SELECT SCOPE_IDENTITY() AS Id;
            `;
            const invResult = await db.query(invSql, [
                memoNumber,
                memoDate,
                receiptDate || memoDate,
                investigationType,
                managerName,
                memoSummary || '',
                incidentDate,
                incidentPlace || '',
                incidentDescription || '',
                'جارية',
                (materialValue === null || materialValue === undefined || materialValue === '') ? null : Number(materialValue)
            ]);
            const investigationId = invResult[0]?.Id;
            if (!investigationId) throw new Error('فشل في إنشاء التحقيق');

            // إدراج الموظفين: البحث عن الموظف في الجدول الرئيسي EmployeesMaster
            // أو إنشاؤه إذا لم يكن موجوداً، ثم ربطه بالتحقيق عبر جدول الوصل
            for (const emp of employees) {
                const existingEmp = await db.query(
                    `SELECT Id FROM EmployeesMaster WHERE Code = @p0`,
                    [emp.code]
                );

                let employeeMasterId;
                if (existingEmp.length > 0) {
                    employeeMasterId = existingEmp[0].Id;
                    // تحديث بيانات الموظف في حال تغيّرت
                    await db.query(
                        `UPDATE EmployeesMaster 
                         SET FullName = @p1, JobGrade = @p2, WorkArea = @p3
                         WHERE Id = @p0`,
                        [
                            employeeMasterId,
                            emp.name,
                            emp.jobGrade || '',
                            emp.workArea || ''
                        ]
                    );
                } else {
                    const newEmp = await db.query(
                        `INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
                         VALUES (@p0, @p1, @p2, @p3, 1, GETDATE());
                         SELECT SCOPE_IDENTITY() AS Id;`,
                        [
                            emp.code,
                            emp.name,
                            emp.jobGrade || '',
                            emp.workArea || ''
                        ]
                    );
                    employeeMasterId = newEmp[0]?.Id;
                }

                await db.query(
                    `INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt)
                     VALUES (@p0, @p1, GETDATE())`,
                    [investigationId, employeeMasterId]
                );
            }

            if (summons && summons.length > 0) {
                const sumSql = `
                    INSERT INTO Summons (
                        InvestigationId, SummonsDate, [Response], AttendanceDate
                    ) VALUES (
                        @p0, @p1, @p2, @p3
                    )
                `;
                for (const s of summons) {
                    await db.query(sumSql, [
                        investigationId,
                        s.date,
                        s.response || 'لم يستجب',
                        s.attendanceDate || null
                    ]);
                }
            }

            await transaction.commit();

            await logActivity(req, 'add', `تم إنشاء تحقيق جديد رقم: ${memoNumber}`, 'تحقيق جديد', 'investigation');

            // 🔔 إرسال إشعار لكل مستخدمي التحقيقات
            notifyAllInvUsers(
                '🔍 تحقيق جديد',
                `تم فتح تحقيق جديد برقم مذكرة: ${memoNumber}`,
                'investigation',
                investigationId,
                `investigation_details.html?id=${investigationId}`
            );

            res.json({
                success: true,
                message: 'تم إنشاء التحقيق بنجاح',
                investigationId: investigationId,
                investigationNumber: memoNumber
            });

        } catch (error) {
            await transaction.rollback();
            throw error;
        }

    } catch (error) {
        console.error('❌ خطأ في إنشاء التحقيق:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

// ================================================================
// 20.3.1 تعديل تحقيق موجود
// ================================================================
app.put('/api/investigations/:id', requireInvestigationModule('investigation-details'), async (req, res) => {
    try {
        const { id } = req.params;
        const {
            memoNumber, memoDate, receiptDate, investigationType, managerName,
            memoSummary, incidentDate, incidentPlace, incidentDescription,
            status, employees, materialValue
        } = req.body;

        if (!memoNumber || !memoDate || !investigationType || !managerName || !incidentDate) {
            return res.status(400).json({ success: false, message: 'الرجاء ملء جميع الحقول المطلوبة' });
        }

        // إتاحة إضافة عمود ReceiptDate تلقائياً إذا لم يكن موجوداً
        try {
            await db.query(`
                IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Investigations' AND COLUMN_NAME = 'ReceiptDate')
                BEGIN
                    ALTER TABLE Investigations ADD ReceiptDate DATE NULL;
                END
            `);
            await db.query(`
                IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Investigations' AND COLUMN_NAME = 'MaterialValue')
                BEGIN
                    ALTER TABLE Investigations ADD MaterialValue DECIMAL(18,2) NULL;
                END
            `);
        } catch (e) { /* تجاهل الخطأ */ }

        // التحقق من وجود التحقيق
        const existing = await db.query('SELECT Id FROM Investigations WHERE Id = @p0', [id]);
        if (existing.length === 0) {
            return res.status(404).json({ success: false, message: 'التحقيق غير موجود' });
        }

        const transaction = new db.sql.Transaction(db.pool);
        await transaction.begin();
        try {
            // تحديث بيانات التحقيق
            await db.query(`
                UPDATE Investigations SET
                    MemoNumber = @p1, MemoDate = @p2, ReceiptDate = @p3, InvestigationType = @p4,
                    ManagerName = @p5, MemoSummary = @p6, IncidentDate = @p7,
                    IncidentPlace = @p8, IncidentDescription = @p9, [Status] = @p10,
                    MaterialValue = @p11
                WHERE Id = @p0`,
                [id, memoNumber, memoDate, receiptDate || memoDate, investigationType, managerName,
                 memoSummary || '', incidentDate, incidentPlace || '',
                 incidentDescription || '', status || 'جارية',
                 (materialValue === null || materialValue === undefined || materialValue === '') ? null : Number(materialValue)]
            );

            // تحديث الموظفين إن أُرسلوا
            if (employees && employees.length > 0) {
                // حذف روابط الموظفين القديمة
                await db.query('DELETE FROM InvestigationEmployees WHERE InvestigationId = @p0', [id]);

                // إعادة إدراج الموظفين
                for (const emp of employees) {
                    const existingEmp = await db.query(
                        'SELECT Id FROM EmployeesMaster WHERE Code = @p0', [emp.code]
                    );
                    let employeeMasterId;
                    if (existingEmp.length > 0) {
                        employeeMasterId = existingEmp[0].Id;
                        await db.query(
                            `UPDATE EmployeesMaster SET FullName = @p1, JobGrade = @p2, WorkArea = @p3 WHERE Id = @p0`,
                            [employeeMasterId, emp.name, emp.jobGrade || '', emp.workArea || '']
                        );
                    } else {
                        const newEmp = await db.query(
                            `INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
                             VALUES (@p0, @p1, @p2, @p3, 1, GETDATE());
                             SELECT SCOPE_IDENTITY() AS Id;`,
                            [emp.code, emp.name, emp.jobGrade || '', emp.workArea || '']
                        );
                        employeeMasterId = newEmp[0]?.Id;
                    }
                    await db.query(
                        'INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt) VALUES (@p0, @p1, GETDATE())',
                        [id, employeeMasterId]
                    );
                }
            }

            await transaction.commit();
            await logActivity(req, 'edit', `تعديل التحقيق رقم: ${memoNumber}`, 'تعديل التحقيق');
            res.json({ success: true, message: 'تم تعديل التحقيق بنجاح' });
        } catch (err) {
            await transaction.rollback();
            throw err;
        }
    } catch (error) {
        console.error('❌ خطأ في تعديل التحقيق:', error);
        res.status(500).json({ success: false, message: error.message });
    }
});

// ================================================================
// 20.3.2 حذف تحقيق (أرشفة ناعمة)
// ================================================================
app.delete('/api/investigations/:id', requireInvestigationModule('investigations-dashboard'), async (req, res) => {
    try {
        const { id } = req.params;

        // جلب بيانات التحقيق الكاملة
        const invResult = await db.query('SELECT * FROM Investigations WHERE Id = @p0', [id]);
        if (invResult.length === 0) {
            return res.status(404).json({ success: false, message: 'التحقيق غير موجود' });
        }
        const investigation = invResult[0];

        const employees = await db.query(
            `SELECT ie.*, em.Code AS EmployeeCode, em.FullName AS EmployeeName, em.JobGrade, em.WorkArea
             FROM InvestigationEmployees ie JOIN EmployeesMaster em ON em.Id = ie.EmployeeMasterId
             WHERE ie.InvestigationId = @p0`, [id]
        );
        const summons = await db.query('SELECT * FROM Summons WHERE InvestigationId = @p0', [id]);
        const decisions = await db.query('SELECT * FROM InvestigationDecisions WHERE InvestigationId = @p0', [id]);
        const appeals = await db.query('SELECT * FROM Appeals WHERE InvestigationId = @p0', [id]);
        const finalDecisions = await db.query('SELECT * FROM FinalDecisions WHERE InvestigationId = @p0', [id]);
        const finalMemos = await db.query('SELECT * FROM FinalMemos WHERE InvestigationId = @p0', [id]);
        const witnesses = await db.query('SELECT * FROM InvestigationWitnesses WHERE InvestigationId = @p0', [id]);

        const archiveData = JSON.stringify({
            investigation,
            employees,
            summons,
            decisions,
            appeals,
            finalDecisions,
            finalMemos,
            witnesses
        });

        const transaction = new db.sql.Transaction(db.pool);
        await transaction.begin();
        try {
            // أرشفة السجل
            await db.query(
                `INSERT INTO Archive (RecordType, RecordId, RecordData, PageUrl, DeletedAt)
                 VALUES (@p0, @p1, @p2, @p3, GETDATE())`,
                ['Investigation', id, archiveData, 'investigation_archive.html']
            );

            // حذف السجلات المرتبطة بالتسلسل
            await db.query('DELETE FROM InvestigationWitnesses WHERE InvestigationId = @p0', [id]);
            await db.query('DELETE FROM FinalMemos WHERE InvestigationId = @p0', [id]);
            await db.query('DELETE FROM FinalDecisions WHERE InvestigationId = @p0', [id]);
            await db.query('DELETE FROM Appeals WHERE InvestigationId = @p0', [id]);
            await db.query('DELETE FROM InvestigationDecisions WHERE InvestigationId = @p0', [id]);
            await db.query('DELETE FROM Summons WHERE InvestigationId = @p0', [id]);
            await db.query('DELETE FROM InvestigationEmployees WHERE InvestigationId = @p0', [id]);
            await db.query('DELETE FROM Investigations WHERE Id = @p0', [id]);

            await transaction.commit();
            await logActivity(req, 'delete', `حذف وأرشفة التحقيق رقم: ${investigation.MemoNumber}`, 'حذف التحقيق');
            res.json({ success: true, message: 'تم حذف التحقيق وأرشفته بنجاح' });
        } catch (err) {
            await transaction.rollback();
            throw err;
        }
    } catch (error) {
        console.error('❌ خطأ في حذف التحقيق:', error);
        res.status(500).json({ success: false, message: error.message });
    }
});

// 20.4 إضافة استدعاء إلى تحقيق
app.post('/api/investigations/:id/summons', requireInvestigationModule('investigation-details'), async (req, res) => {
    try {
        const { id } = req.params;
        const { summonsDate, response, attendanceDate, employeeName } = req.body;

        if (!summonsDate) {
            return res.status(400).json({
                success: false,
                message: 'تاريخ الاستدعاء مطلوب'
            });
        }

        // إضافة عمود EmployeeName لجدول Summons تلقائياً إن لم يكن موجوداً
        try {
            await db.query(`
                IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Summons' AND COLUMN_NAME = 'EmployeeName')
                BEGIN
                    ALTER TABLE Summons ADD EmployeeName NVARCHAR(255) NULL;
                END
            `);
        } catch (e) {}

        const sql = `
            INSERT INTO Summons (InvestigationId, SummonsDate, [Response], AttendanceDate, EmployeeName)
            VALUES (@p0, @p1, @p2, @p3, @p4);
            SELECT SCOPE_IDENTITY() AS Id;
        `;
        const result = await db.query(sql, [
            id,
            summonsDate,
            response || 'لم يستجب',
            attendanceDate || null,
            employeeName || null
        ]);

        // 🔔 إرسال إشعار باستدعاء جديد
        notifyAllInvUsers(
            '📋 استدعاء جديد',
            `تم إضافة استدعاء جديد بتاريخ: ${summonsDate} للتحقيق رقم: ${id}`,
            'summons',
            parseInt(id),
            `investigation_details.html?id=${id}`
        );

        res.json({
            success: true,
            message: 'تم إضافة الاستدعاء',
            summonsId: result[0]?.Id
        });

    } catch (error) {
        console.error('❌ خطأ في إضافة الاستدعاء:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

// 20.5 حفظ قرار اللجنة
app.post('/api/investigations/:id/decision', requireInvestigationModule('investigation-details'), async (req, res) => {
    try {
        const { id } = req.params;
        const { committeeDate, committeeHead, decisionType, penaltyValue, notes } = req.body;

        await db.query("DELETE FROM InvestigationDecisions WHERE InvestigationId = @p0", [id]);

        const sql = `
            INSERT INTO InvestigationDecisions (
                InvestigationId, CommitteeDate, CommitteeHead, DecisionType, PenaltyValue, Notes
            ) VALUES (
                @p0, @p1, @p2, @p3, @p4, @p5
            )
        `;
        await db.query(sql, [
            id,
            committeeDate || null,
            committeeHead || '',
            decisionType || '',
            penaltyValue || '',
            notes || ''
        ]);

        await db.query(
            "UPDATE Investigations SET [Status] = 'صدر قرار', UpdatedAt = GETDATE() WHERE Id = @p0",
            [id]
        );

        notifyAllInvUsers(
            '⚖️ عرض علي رئيس مجلس الإدارة',
            `تم تسجيل عرض علي رئيس مجلس الإدارة للتحقيق رقم: ${id}`,
            'decision',
            parseInt(id),
            `investigation_details.html?id=${id}`
        );

        res.json({
            success: true,
            message: 'تم حفظ قرار اللجنة'
        });

    } catch (error) {
        console.error('❌ خطأ في حفظ قرار اللجنة:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

// 20.6 حفظ الطعن
app.post('/api/investigations/:id/appeal', requireInvestigationModule('investigation-details'), async (req, res) => {
    try {
        const { id } = req.params;
        const { hasAppeal, appealDate, appealResult, appealNotes } = req.body;

        await db.query("DELETE FROM Appeals WHERE InvestigationId = @p0", [id]);

        const sql = `
            INSERT INTO Appeals (
                InvestigationId, HasAppeal, AppealDate, AppealResult, AppealNotes
            ) VALUES (
                @p0, @p1, @p2, @p3, @p4
            )
        `;
        await db.query(sql, [
            id,
            hasAppeal ? 1 : 0,
            appealDate || null,
            appealResult || '',
            appealNotes || ''
        ]);

        if (hasAppeal) {
            await db.query(
                "UPDATE Investigations SET [Status] = 'طعن', UpdatedAt = GETDATE() WHERE Id = @p0",
                [id]
            );

            notifyAllInvUsers(
                '📝 تظلم جديد',
                `تم تقديم تظلم في القرار للتحقيق رقم: ${id}`,
                'appeal',
                parseInt(id),
                `investigation_details.html?id=${id}`
            );
        }

        res.json({
            success: true,
            message: 'تم حفظ بيانات الطعن'
        });

    } catch (error) {
        console.error('❌ خطأ في حفظ الطعن:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

// 20.7 حفظ القرار النهائي وإغلاق التحقيق
app.post('/api/investigations/:id/final-decision', requireInvestigationModule('investigation-details'), async (req, res) => {
    try {
        const { id } = req.params;
        const { finalDecisionText, actionType, hrSentDate, fileSaveDate, hrNotes } = req.body;

        // إضافة الأعمدة الجديدة لجدول FinalDecisions إن لم تكن موجودة
        try {
            await db.query(`
                IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'FinalDecisions' AND COLUMN_NAME = 'ActionType')
                BEGIN
                    ALTER TABLE FinalDecisions ADD ActionType NVARCHAR(50) NULL;
                END;
                IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'FinalDecisions' AND COLUMN_NAME = 'FileSaveDate')
                BEGIN
                    ALTER TABLE FinalDecisions ADD FileSaveDate DATE NULL;
                END;
            `);
        } catch (e) {}

        await db.query("DELETE FROM FinalDecisions WHERE InvestigationId = @p0", [id]);

        const effectiveHrDate = (actionType === 'archive') ? null : (hrSentDate || null);
        const effectiveSaveDate = (actionType === 'archive') ? (fileSaveDate || null) : null;

        const sql = `
            INSERT INTO FinalDecisions (
                InvestigationId, FinalDecisionText, HRSentDate, HRNotes, ActionType, FileSaveDate
            ) VALUES (
                @p0, @p1, @p2, @p3, @p4, @p5
            )
        `;
        await db.query(sql, [
            id,
            finalDecisionText || '',
            effectiveHrDate,
            hrNotes || '',
            actionType || 'hr',
            effectiveSaveDate
        ]);

        await db.query(
            "UPDATE Investigations SET [Status] = 'مغلقة', UpdatedAt = GETDATE() WHERE Id = @p0",
            [id]
        );

        notifyAllInvUsers(
            '🏁 القرار النهائي وإغلاق التحقيق',
            `تم حفظ القرار النهائي وإغلاق التحقيق رقم: ${id}`,
            'final_decision',
            parseInt(id),
            `investigation_details.html?id=${id}`
        );

        res.json({
            success: true,
            message: 'تم حفظ القرار النهائي وإغلاق التحقيق'
        });

    } catch (error) {
        console.error('❌ خطأ في حفظ القرار النهائي:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

// 20.8 حفظ المذكرة الختامية
app.post('/api/investigations/:id/final-memo', requireInvestigationModule('investigation-details'), async (req, res) => {
    try {
        const { id } = req.params;
        const { memoText, fileName, filePath } = req.body;

        await db.query("DELETE FROM FinalMemos WHERE InvestigationId = @p0", [id]);

        const sql = `
            INSERT INTO FinalMemos (
                InvestigationId, MemoText, FileName, FilePath
            ) VALUES (
                @p0, @p1, @p2, @p3
            )
        `;
        await db.query(sql, [
            id,
            memoText || '',
            fileName || '',
            filePath || ''
        ]);

        notifyAllInvUsers(
            '📄 مذكرة ختامية',
            `تم إضافة مذكرة ختامية للتحقيق رقم: ${id}`,
            'final_memo',
            parseInt(id),
            `investigation_details.html?id=${id}`
        );

        res.json({
            success: true,
            message: 'تم حفظ المذكرة الختامية'
        });

    } catch (error) {
        console.error('❌ خطأ في حفظ المذكرة الختامية:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

// 20.9 جلب الموظفين (للاستخدام في تحقيق جديد)
app.get('/api/employees', async (req, res) => {
    try {
        const sql = `
            SELECT 
                Code AS employeeCode,
                FullName AS employeeName,
                JobGrade AS jobGrade,
                WorkArea AS workArea
            FROM EmployeesMaster
            WHERE IsActive = 1
            ORDER BY FullName
        `;
        const employees = await db.query(sql);
        res.json({
            success: true,
            data: employees
        });
    } catch (error) {
        console.error('❌ خطأ في جلب الموظفين:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

// ================================================================
// 21. نقاط نهاية الشهود (Witnesses)
// ================================================================

// 21.1 جلب شهود تحقيق معين
app.get('/api/investigations/:id/witnesses', async (req, res) => {
    try {
        const { id } = req.params;
        const witnesses = await db.query(
            `SELECT 
                iw.Id, iw.InvestigationId, iw.[Statement], iw.CreatedAt,
                wm.FullName AS Name, wm.NationalId, wm.Mobile, wm.[Address],
                em.Code AS EmployeeCode
             FROM InvestigationWitnesses iw
             JOIN WitnessesMaster wm ON wm.Id = iw.WitnessMasterId
             LEFT JOIN EmployeesMaster em ON em.Code = wm.Code AND em.IsActive = 1
             WHERE iw.InvestigationId = @p0
             ORDER BY iw.CreatedAt DESC`,
            [id]
        );
        res.json({
            success: true,
            data: witnesses
        });
    } catch (error) {
        console.error('❌ خطأ في جلب الشهود:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

// 21.2 إضافة شاهد جديد
app.post('/api/investigations/:id/witnesses', requireInvestigationModule('investigation-details'), async (req, res) => {
    try {
        const { id } = req.params;
        const { employeeCode, name, nationalId, mobile, address, statement } = req.body;

        let witnessName = name;
        let witnessNationalId = nationalId || '';
        let witnessMobile = mobile || '';
        let witnessAddress = address || '';

        if (employeeCode) {
            const empSql = `
                SELECT FullName
                FROM EmployeesMaster
                WHERE Code = @p0 AND IsActive = 1
            `;
            const empResult = await db.query(empSql, [employeeCode]);
            if (empResult.length > 0) {
                witnessName = empResult[0].FullName;
            }
        }

        if (!witnessName) {
            return res.status(400).json({
                success: false,
                message: 'اسم الشاهد مطلوب'
            });
        }

        // كود الشاهد في الجدول الرئيسي WitnessesMaster:
        // - لو مرتبط بموظف: نفس كود الموظف (يربطهما ببعض تلقائياً)
        // - لو يدوي وعنده رقم قومي: نولّد كوداً ثابتاً بناءً عليه حتى لا يتكرر نفس الشاهد كسجل جديد كل مرة
        // - غير ذلك: كود عشوائي فريد
        const witnessCode = employeeCode || (witnessNationalId ? `M-${witnessNationalId}` : `M-${Date.now()}`);

        const existingWitness = await db.query(
            `SELECT Id FROM WitnessesMaster WHERE Code = @p0`,
            [witnessCode]
        );

        let witnessMasterId;
        if (existingWitness.length > 0) {
            witnessMasterId = existingWitness[0].Id;
            await db.query(
                `UPDATE WitnessesMaster 
                 SET FullName = @p1, NationalId = @p2, Mobile = @p3, [Address] = @p4
                 WHERE Id = @p0`,
                [witnessMasterId, witnessName, witnessNationalId, witnessMobile, witnessAddress]
            );
        } else {
            const newWitness = await db.query(
                `INSERT INTO WitnessesMaster (Code, FullName, NationalId, Mobile, [Address], IsActive, CreatedAt)
                 VALUES (@p0, @p1, @p2, @p3, @p4, 1, GETDATE());
                 SELECT SCOPE_IDENTITY() AS Id;`,
                [witnessCode, witnessName, witnessNationalId, witnessMobile, witnessAddress]
            );
            witnessMasterId = newWitness[0]?.Id;
        }

        const sql = `
            INSERT INTO InvestigationWitnesses (
                InvestigationId, WitnessMasterId, [Statement], CreatedAt
            ) VALUES (
                @p0, @p1, @p2, GETDATE()
            );
            SELECT SCOPE_IDENTITY() AS Id;
        `;
        const result = await db.query(sql, [
            id,
            witnessMasterId,
            statement || ''
        ]);

        res.json({
            success: true,
            message: 'تم إضافة الشاهد بنجاح',
            witnessId: result[0]?.Id
        });
    } catch (error) {
        console.error('❌ خطأ في إضافة الشاهد:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

// تحديث أقوال موظف معين في التحقيق
app.put('/api/investigations/:id/employee-statement', requireInvestigationModule('investigation-details'), async (req, res) => {
    try {
        const { id } = req.params;
        const { employeeCode, statement } = req.body;

        if (!employeeCode) {
            return res.status(400).json({ success: false, message: 'كود الموظف مطلوب' });
        }

        // البحث عن معرف الموظف من EmployeesMaster
        const empRows = await db.query('SELECT Id FROM EmployeesMaster WHERE Code = @p0', [employeeCode]);
        if (empRows.length === 0) {
            return res.status(404).json({ success: false, message: 'الموظف غير موجود' });
        }
        const employeeMasterId = empRows[0].Id;

        // تحديث أقوال الموظف في جدول InvestigationEmployees
        const updateSql = `
            UPDATE InvestigationEmployees 
            SET EmployeeStatement = @p2
            WHERE InvestigationId = @p0 AND EmployeeMasterId = @p1
        `;
        await db.query(updateSql, [id, employeeMasterId, statement || '']);

        res.json({
            success: true,
            message: 'تم حفظ أقوال الموظف بنجاح'
        });
    } catch (error) {
        console.error('❌ خطأ في حفظ أقوال الموظف:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});


// ============================================
// جلب درجات التقاضي - نسخة معدلة
// ============================================
app.get('/api/litigation-levels', async (req, res) => {
    try {
        const { caseId, stageType, status } = req.query;
        
        let sql = `
            SELECT 
                l.Id,
                l.CaseId,
                l.TrackingCode,
                l.StageType,
                l.StageNumber,
                l.CourtName,
                l.[الدائرة] AS CircuitName,
                l.Subject AS LitigationSubject,
                l.RequestedByOpponent,
                l.RequestedBy,
                l.LawyerId,
                l.LawyerName,
                l.LaunchDate,
                l.[Status],
                l.Notes,
                l.CreatedAt,
                l.UpdatedAt,
                c.Subject AS CaseName,
                c.Category AS CaseCategory,
                COALESCE(c.Plaintiff, c.Defendant, '') AS CaseOpponent,
                c.Plaintiff AS CasePlaintiff,
                c.Defendant AS CaseDefendant,
                l.Plaintiff AS LevelPlaintiff,
                l.Defendant AS LevelDefendant,
                c.AssignedLawyerId,
                l2.FullName AS LawyerFullName,        -- المحامي المسؤول من جدول Lawyers
                c.CaseNumber
            FROM LitigationLevels l
            LEFT JOIN Cases c ON l.CaseId = c.Id
            LEFT JOIN Lawyers l2 ON c.AssignedLawyerId = l2.Id
            WHERE 1=1
        `;
        
        const params = [];
        let paramIndex = 0;
        
        if (caseId) {
            sql += ` AND l.CaseId = @p${paramIndex}`;
            params.push(caseId);
            paramIndex++;
        }
        if (stageType) {
            sql += ` AND (l.StageType = @p${paramIndex} OR l.StageType = @p${paramIndex + 1})`;
            params.push(stageType);
            params.push(
                stageType === 'appeal' ? 'استئناف' :
                stageType === 'cassation' ? 'نقض' :
                stageType === 'eshkal' ? 'اشكال' :
                stageType === 'eshkal_tanfeeth' ? 'اشكال في التنفيذ' :
                stageType === 'iltimas' ? 'التماس' :
                stageType === 'استئناف' ? 'appeal' :
                stageType === 'نقض' || stageType === 'طعن بالنقض' ? 'cassation' :
                stageType === 'إشكال' || stageType === 'اشكال' ? 'eshkal' :
                stageType.includes('تنفيذ') ? 'eshkal_tanfeeth' :
                stageType.includes('التماس') ? 'iltimas' : stageType
            );
            paramIndex += 2;
        }
        if (status) {
            sql += ` AND l.[Status] = @p${paramIndex}`;
            params.push(status);
            paramIndex++;
        }
        
        sql += ` ORDER BY l.CreatedAt DESC`;
        
        const levels = await db.query(sql, params);
        
        const formattedLevels = levels.map(l => {
            const caseP = l.CasePlaintiff || '';
            const caseD = l.CaseDefendant || l.CaseOpponent || '';
            const reqBy = l.RequestedBy || '';
            
            let defaultP = caseP;
            let defaultD = caseD;
            if (reqBy === 'الخصم') {
                defaultP = caseD || 'الخصم';
                defaultD = caseP || 'الشركة';
            }

            return {
                Id: l.Id,
                CaseId: l.CaseId,
                TrackingCode: l.TrackingCode || l.CaseNumber || '',
                StageType: l.StageType || 'appeal',
                StageNumber: l.StageNumber || '',
                CourtName: l.CourtName || '',
                CircuitName: l.CircuitName || '',
                LitigationSubject: l.LitigationSubject || '',
                RequestedByOpponent: l.RequestedByOpponent || '',
                RequestedBy: l.RequestedBy || '—',           // مين قدم الطعن (الشركة/الخصم)
                LawyerId: l.LawyerId || null,
                LawyerName: l.LawyerName || '',
                LaunchDate: l.LaunchDate ? new Date(l.LaunchDate).toISOString().split('T')[0] : null,
                Status: l.Status || 'open',
                Notes: l.Notes || '',
                CreatedAt: l.CreatedAt,
                UpdatedAt: l.UpdatedAt,
                // بيانات القضية من جدول Cases
                CaseName: l.CaseName || '',
                CaseCategory: l.CaseCategory || 'مدني',
                CaseOpponent: l.CaseOpponent || '—',        // الخصم الأساسي للقضية
                Plaintiff: l.LevelPlaintiff || defaultP,
                Defendant: l.LevelDefendant || defaultD,
                AssignedLawyerId: l.AssignedLawyerId || null,
                LawyerFullName: l.LawyerFullName || '—',    // المحامي المسؤول عن القضية
                CaseNumber: l.CaseNumber || ''
            };
        });
        
        res.json({
            success: true,
            data: formattedLevels,
            count: formattedLevels.length
        });
    } catch (error) {
        console.error('❌ خطأ في جلب درجات التقاضي:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

// 22.2 جلب درجة تقاضي برقم ID
app.get('/api/litigation-levels/:id', async (req, res) => {
    try {
        const { id } = req.params;
        
        const sql = `
            SELECT 
                l.Id,
                l.CaseId,
                l.TrackingCode,
                l.StageType,
                l.StageNumber,
                l.CourtName,
                l.[الدائرة] AS CircuitName,
                l.Subject AS LitigationSubject,
                l.RequestedByOpponent,
                l.RequestedBy,
                l.LawyerName,
                l.LawyerId,
                l.LaunchDate,
                l.[Status],
                l.Notes,
                l.CreatedAt,
                l.UpdatedAt,
                c.Subject AS CaseName,
                c.CourtName AS CaseCourtName,
                c.CircuitName AS CaseCircuitName,
                COALESCE(c.Plaintiff, c.Defendant, '') AS CaseOpponent,
                c.Plaintiff AS CasePlaintiff,
                c.Defendant AS CaseDefendant,
                l.Plaintiff AS LevelPlaintiff,
                l.Defendant AS LevelDefendant
            FROM LitigationLevels l
            LEFT JOIN Cases c ON l.CaseId = c.Id
            WHERE l.Id = @p0
        `;
        
        const result = await db.query(sql, [id]);
        
        if (result.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'درجة التقاضي غير موجودة'
            });
        }
        
        const level = result[0];
        level.LaunchDate = level.LaunchDate ? new Date(level.LaunchDate).toISOString().split('T')[0] : null;
        
        const caseP = level.CasePlaintiff || '';
        const caseD = level.CaseDefendant || level.CaseOpponent || '';
        const reqBy = level.RequestedBy || '';
        
        let defaultP = caseP;
        let defaultD = caseD;
        if (reqBy === 'الخصم') {
            defaultP = caseD || 'الخصم';
            defaultD = caseP || 'الشركة';
        }

        level.Plaintiff = level.LevelPlaintiff || defaultP;
        level.Defendant = level.LevelDefendant || defaultD;
        
        res.json({
            success: true,
            data: level
        });
    } catch (error) {
        console.error('❌ خطأ في جلب درجة التقاضي:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

// ============================================
// دالة مساعدة: إغلاق جلسات الدرجات الأدنى تلقائياً عند إضافة درجة أعلى
// ============================================
async function cascadeCloseSessionsByStage(caseId, newStageType) {
    const stageHierarchy = {
        'appeal':          ['initial'],
        'cassation':       ['initial', 'appeal'],
        'eshkal':          ['initial', 'appeal', 'cassation'],
        'eshkal_tanfeeth': ['initial', 'appeal', 'cassation', 'eshkal'],
        'execution':       ['initial', 'appeal', 'cassation', 'eshkal'],
        'iltimas':         ['initial', 'appeal', 'cassation']
    };
    const stagesToClose = stageHierarchy[newStageType];
    if (!stagesToClose || stagesToClose.length === 0) return;

    // إغلاق الجلسات المرتبطة بدرجات أدنى عبر LitigationLevelId
    const placeholders = stagesToClose.map((_, i) => `@p${i + 1}`).join(',');
    await db.query(
        `UPDATE Sessions 
         SET IsClosed = 1, [Status] = N'مغلقة'
         WHERE CaseId = @p0
           AND (IsClosed IS NULL OR IsClosed = 0)
           AND LitigationLevelId IN (
               SELECT Id FROM LitigationLevels 
               WHERE CaseId = @p0 AND StageType IN (${placeholders})
           )`,
        [caseId, ...stagesToClose]
    );

    // إغلاق الجلسات المرتبطة بالقضية مباشرةً (بدون درجة) إذا كانت ابتدائي
    if (stagesToClose.includes('initial')) {
        await db.query(
            `UPDATE Sessions 
             SET IsClosed = 1, [Status] = N'مغلقة'
             WHERE CaseId = @p0
               AND (IsClosed IS NULL OR IsClosed = 0)
               AND (LitigationLevelId IS NULL OR LitigationLevelId = 0)`,
            [caseId]
        );
    }

    console.log(`✅ تم إغلاق جلسات الدرجات ${stagesToClose.join(', ')} للقضية ${caseId} بسبب إضافة درجة ${newStageType}`);
}

// ============================================
// إعادة حساب "النتيجة لصالح" (عمود Agginst بجدول Cases)
// ============================================
// القاعدة: النتيجة المعروضة في القضية هي نتيجة آخر جلسة (بتاريخ SessionDate) من بين
// كل جلسات نفس القضية (بجميع درجات التقاضي) التي لها نتيجة (لصالح الشركة/لصالح الخصم).
// - عند تعديل/إضافة نتيجة جلسة: لو الجلسة دي هي الأحدث تاريخاً من بين الجلسات المحسومة،
//   النتيجة بتاعتها هي اللي تتعكس على القضية.
// - عند حذف جلسة: نعيد الحساب من الجلسات المتبقية، فلو اتشالت أحدث جلسة محسومة،
//   القضية ترجع تاخد نتيجة الجلسة المحسومة اللي قبلها (الأحدث تاريخاً من الباقي).
// - لو معدش فيه أي جلسة محسومة للقضية، يتمسح عمود Agginst (تفضل من غير نتيجة).
async function recalculateCaseResult(caseId) {
    if (!caseId) return;

    const rows = await db.query(
        `SELECT TOP 1 Result, SessionDate, Id
         FROM Sessions
         WHERE CaseId = @p0
           AND Result IN (N'لصالح الشركة', N'لصالح الخصم')
         ORDER BY SessionDate DESC, Id DESC`,
        [caseId]
    );

    let agginstValue = null;
    if (rows.length > 0) {
        agginstValue = rows[0].Result === 'لصالح الشركة' ? 'الشركة' : 'الخصم';
    }

    await db.query(
        "UPDATE Cases SET Agginst = @p0, UpdatedAt = GETDATE() WHERE Id = @p1",
        [agginstValue, caseId]
    );

    console.log(agginstValue
        ? `⚖️ إعادة حساب نتيجة القضية ${caseId}: Agginst = ${agginstValue} (آخر جلسة محسومة بتاريخ ${rows[0].SessionDate})`
        : `⚖️ إعادة حساب نتيجة القضية ${caseId}: لا توجد جلسات محسومة، تم مسح Agginst`);
}

// ============================================
// إضافة درجة تقاضي جديدة - نسخة معدلة مع Source
// ============================================
app.post('/api/litigation-levels', async (req, res) => {
    try {
        const {
            CaseId,
            TrackingCode,
            StageType,
            StageNumber,
            CourtName,
            CircuitName,
            Subject,
            RequestedByOpponent,
            RequestedBy,
            LawyerId,
            LawyerName,
            LaunchDate,
            Status,
            Notes,
            CaseYear,
            CaseCategory,
            Plaintiff,
            Defendant,
            ClaimAmount,
            claimAmount
        } = req.body;

        const claimAmountValue = ClaimAmount || claimAmount || null;

        if (!TrackingCode || !StageType) {
            return res.status(400).json({
                success: false,
                message: 'الرجاء ملء جميع الحقول المطلوبة'
            });
        }

        let caseId = CaseId || null;
        let caseName = req.body.CaseName || `قضية رقم ${TrackingCode}`;
        
        // التحقق من صحة caseId لو كان ممرر (سواء كان ID رقمي أو رقم قضية مثل 2630 أو lit-xxx)
        if (caseId) {
            if (typeof caseId === 'string' && caseId.startsWith('lit-')) {
                const litId = caseId.replace('lit-', '');
                const litRow = await db.query("SELECT CaseId FROM LitigationLevels WHERE Id = @p0", [litId]);
                if (litRow.length > 0 && litRow[0].CaseId) {
                    caseId = litRow[0].CaseId;
                }
            }
            
            let checkCase = await db.query("SELECT Id FROM Cases WHERE Id = @p0", [caseId]);
            if (checkCase.length === 0) {
                // إذا لم يوجد كـ Id، نبحث عنه كرقم قضية CaseNumber (مثل قضية 2630)
                let checkByNumber = await db.query(
                    "SELECT Id FROM Cases WHERE CaseNumber = @p0 OR CaseNumber LIKE @p1 OR CaseNumber LIKE @p2",
                    [String(caseId), `%${caseId}%`, `%${String(caseId).replace(/\D/g, '')}%`]
                );
                if (checkByNumber.length > 0) {
                    caseId = checkByNumber[0].Id;
                    console.log(`✅ تم تصحيح CaseId من رقم القضية إلى ID الفعلي: ${caseId}`);
                } else {
                    caseId = null;
                }
            }
        }

        // البحث بـ TrackingCode أو رقم القضية الممرر في حال عدم العثور على CaseId
        if (!caseId && (TrackingCode || req.body.CaseNumber)) {
            const searchTarget = req.body.CaseNumber || TrackingCode;
            const parts = searchTarget.split('/');
            let searchNumber = parts.length >= 1 ? parts[0].trim() : searchTarget;
            
            let caseResult = await db.query(
                "SELECT Id FROM Cases WHERE CaseNumber = @p0 OR CaseNumber LIKE @p1",
                [searchNumber, `%${searchNumber}%`]
            );
            
            if (caseResult.length === 0) {
                const numericPart = searchNumber.replace(/\D/g, '');
                if (numericPart) {
                    caseResult = await db.query(
                        "SELECT Id FROM Cases WHERE CaseNumber LIKE @p0",
                        [`%${numericPart}%`]
                    );
                }
            }
            
            if (caseResult.length > 0) {
                caseId = caseResult[0].Id;
                console.log(`✅ تم العثور على CaseId: ${caseId}`);
            }
        }

        if (!caseId) {
            const caseYear = CaseYear || new Date().getFullYear().toString();
            const caseCategory = CaseCategory || 'مدني';
            
            const insertCaseSql = `
                INSERT INTO Cases (
                    CaseNumber, CaseYear, CaseType, Subject, Category, 
                    CurrentStage, [Status], FilingDate, CreatedAt,
                    CourtName, ClaimAmount
                ) VALUES (
                    @p0, @p1, @p2, @p3, @p4, @p5, @p6, @p7, GETDATE(),
                    @p8, @p9
                );
                SELECT SCOPE_IDENTITY() AS Id;
            `;
            
            const caseResult = await db.query(insertCaseSql, [
                TrackingCode,
                parseInt(caseYear) || 2026,
                caseCategory,
                caseName,
                caseCategory,
                StageType || 'ابتدائي',
                Status || 'متداولة',
                LaunchDate || new Date().toISOString().split('T')[0],
                CourtName || null,
                claimAmountValue
            ]);
            
            caseId = caseResult[0]?.Id;
            console.log(`✅ تم إنشاء قضية جديدة برقم ID: ${caseId}`);
        }

        let lawyerName = LawyerName || '';
        if (LawyerId && !lawyerName) {
            const lawyerResult = await db.query(
                "SELECT FullName FROM Lawyers WHERE Id = @p0",
                [LawyerId]
            );
            if (lawyerResult.length > 0) {
                lawyerName = lawyerResult[0].FullName;
            }
        }

        const finalCourtName = CourtName || req.body.courtName || 'محكمة استئناف الإسكندرية';
        const finalCircuitName = CircuitName || req.body.circuitName || null;

        const sql = `
            INSERT INTO LitigationLevels (
                CaseId, TrackingCode, StageType, StageNumber, CourtName, [الدائرة],
                RequestedBy, RequestedByOpponent, Subject, LawyerId, LawyerName, LaunchDate, [Status], Notes,
                ClaimAmount, Plaintiff, Defendant
            ) VALUES (
                @p0, @p1, @p2, @p3, @p4, @p5, @p6, @p7, @p8, @p9, @p10, @p11, @p12, @p13, @p14, @p15, @p16
            );
            SELECT SCOPE_IDENTITY() AS Id;
        `;

        const result = await db.query(sql, [
            caseId,
            TrackingCode,
            StageType,
            StageNumber || null,
            finalCourtName,
            CircuitName || null,
            RequestedBy || null,
            RequestedByOpponent || null,
            Subject || null,
            LawyerId || null,
            lawyerName,
            LaunchDate || new Date().toISOString().split('T')[0],
            Status || 'open',
            Notes || '',
            claimAmountValue,
            Plaintiff || null,
            Defendant || null
        ]);

        // تحديث درجة التقاضي ونوع القضية والمدعى عليه في جدول Cases وإغلاق جلسات الدرجات الأدنى
        if (caseId) {
            try {
                let stageArabic = 'استئناف';
                const st = (StageType || '').toLowerCase();
                if (st === 'appeal') stageArabic = 'استئناف';
                else if (st === 'cassation') stageArabic = 'نقض';
                else if (st === 'eshkal') stageArabic = 'إشكال';
                else if (st === 'eshkal_tanfeeth' || st === 'execution') stageArabic = 'إشكال في التنفيذ';
                else if (st === 'iltimas') stageArabic = 'التماس إعادة النظر';
                else stageArabic = StageType || 'استئناف';

                await db.query("UPDATE Cases SET CurrentStage = @p0, UpdatedAt = GETDATE() WHERE Id = @p1", [stageArabic, caseId]);

                const catVal = CaseCategory || req.body.caseCategory || req.body.Category || null;
                const defVal = Defendant || req.body.defendant || null;
                const plVal = Plaintiff || req.body.plaintiff || null;

                if (catVal && catVal.trim() !== '') {
                    await db.query("UPDATE Cases SET Category = @p0 WHERE Id = @p1", [catVal.trim(), caseId]);
                }
                if (defVal && defVal.trim() !== '' && defVal !== 'الخصم') {
                    await db.query("UPDATE Cases SET Defendant = @p0 WHERE Id = @p1", [defVal.trim(), caseId]);
                }
                if (plVal && plVal.trim() !== '' && plVal !== 'الشركة') {
                    await db.query("UPDATE Cases SET Plaintiff = @p0 WHERE Id = @p1", [plVal.trim(), caseId]);
                }
                console.log(`✅ تم تحديث CurrentStage والبيانات للقضية ${caseId} في جدول Cases`);
            } catch (stageErr) {
                console.error('⚠️ تحذير: فشل تحديث بيانات القضية في جدول Cases:', stageErr.message);
            }

            try {
                await cascadeCloseSessionsByStage(caseId, StageType);
            } catch (cascadeErr) {
                console.error('⚠️ تحذير: فشل الإغلاق التلقائي للجلسات:', cascadeErr.message);
            }
        }

        await logActivity(req, 'add', `تمت إضافة درجة تقاضي (${StageType}) برقم ${TrackingCode}`, 'درجات التقاضي');

        res.json({
            success: true,
            message: 'تم إضافة درجة التقاضي بنجاح',
            id: result[0]?.Id,
            caseId: caseId
        });

    } catch (error) {
        console.error('❌ خطأ في إضافة درجة التقاضي:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

// ============================================
// تحديث درجة تقاضي - نسخة معدلة
// ============================================
app.put('/api/litigation-levels/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const {
            TrackingCode,
            StageType,
            StageNumber,
            CourtName,
            CircuitName,
            Subject,
            RequestedByOpponent,
            RequestedBy,
            LawyerId,
            LawyerName,
            LaunchDate,
            Status,
            Notes,
            Plaintiff,
            Defendant
        } = req.body;

        const check = await db.query("SELECT * FROM LitigationLevels WHERE Id = @p0", [id]);
        if (check.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'درجة التقاضي غير موجودة'
            });
        }

        // استخدام القيم الموجودة إذا لم يتم إرسالها
        const finalTrackingCode = TrackingCode || check[0].TrackingCode;
        const finalCourtName = CourtName || check[0].CourtName;

        let lawyerName = LawyerName || '';
        if (LawyerId && !lawyerName) {
            const lawyerResult = await db.query(
                "SELECT FullName FROM Lawyers WHERE Id = @p0",
                [LawyerId]
            );
            if (lawyerResult.length > 0) {
                lawyerName = lawyerResult[0].FullName;
            }
        }

        // بناء جملة SQL ديناميكية لتحديث الحقول المطلوبة فقط
        let sql = `UPDATE LitigationLevels SET `;
        const params = [];
        let paramIndex = 0;
        let updates = [];

        if (TrackingCode) {
            updates.push(`TrackingCode = @p${paramIndex}`);
            params.push(TrackingCode);
            paramIndex++;
        }
        if (StageType) {
            updates.push(`StageType = @p${paramIndex}`);
            params.push(StageType);
            paramIndex++;
        }
        if (StageNumber !== undefined && StageNumber !== null) {
            updates.push(`StageNumber = @p${paramIndex}`);
            params.push(StageNumber);
            paramIndex++;
        }
        if (CourtName) {
            updates.push(`CourtName = @p${paramIndex}`);
            params.push(CourtName);
            paramIndex++;
        }
        if (CircuitName !== undefined) {
            updates.push(`[الدائرة] = @p${paramIndex}`);
            params.push(CircuitName);
            paramIndex++;
        }
        if (Subject !== undefined) {
            updates.push(`Subject = @p${paramIndex}`);
            params.push(Subject);
            paramIndex++;
        }
        if (RequestedByOpponent !== undefined) {
            updates.push(`RequestedByOpponent = @p${paramIndex}`);
            params.push(RequestedByOpponent);
            paramIndex++;
        }
        if (RequestedBy !== undefined) {
            updates.push(`RequestedBy = @p${paramIndex}`);
            params.push(RequestedBy);
            paramIndex++;
        }
        if (Plaintiff !== undefined) {
            updates.push(`Plaintiff = @p${paramIndex}`);
            params.push(Plaintiff);
            paramIndex++;
        }
        if (Defendant !== undefined) {
            updates.push(`Defendant = @p${paramIndex}`);
            params.push(Defendant);
            paramIndex++;
        }
        if (LawyerId !== undefined) {
            updates.push(`LawyerId = @p${paramIndex}`);
            params.push(LawyerId);
            paramIndex++;
        }
        if (lawyerName) {
            updates.push(`LawyerName = @p${paramIndex}`);
            params.push(lawyerName);
            paramIndex++;
        }
        if (LaunchDate) {
            updates.push(`LaunchDate = @p${paramIndex}`);
            params.push(LaunchDate);
            paramIndex++;
        }
        if (Status) {
            updates.push(`[Status] = @p${paramIndex}`);
            params.push(Status);
            paramIndex++;
        }
        if (Notes !== undefined) {
            updates.push(`Notes = @p${paramIndex}`);
            params.push(Notes);
            paramIndex++;
        }

        // إضافة UpdatedAt دائماً
        updates.push(`UpdatedAt = GETDATE()`);

        if (updates.length === 0) {
            return res.status(400).json({
                success: false,
                message: 'لا توجد بيانات للتحديث'
            });
        }

        sql += updates.join(', ');
        sql += ` WHERE Id = @p${paramIndex}`;
        params.push(id);

        console.log('📝 تحديث درجة التقاضي:', sql, params);

        await db.query(sql, params);

        // ===== تتبّع التغييرات (قديم ← جديد) لسجل التتبعات =====
        let llChangeLines = [];
        try {
            const oldRow = check[0];
            const yn = v => (v === true || v === 1 || v === '1') ? 'نعم' : 'لا';
            const stageMap = { initial: 'ابتدائي', appeal: 'استئناف', cassation: 'نقض' };
            const statusMap = { open: 'مفتوحة', closed: 'مغلقة' };
            const mp = (map, v) => (v !== null && v !== undefined && map[v] !== undefined) ? map[v] : v;
            const oldView = {
                TrackingCode: oldRow.TrackingCode, StageType: mp(stageMap, oldRow.StageType), StageNumber: oldRow.StageNumber,
                CourtName: oldRow.CourtName, CircuitName: oldRow['الدائرة'], Subject: oldRow.Subject,
                RequestedByOpponent: yn(oldRow.RequestedByOpponent), RequestedBy: oldRow.RequestedBy,
                Plaintiff: oldRow.Plaintiff, Defendant: oldRow.Defendant, LawyerName: oldRow.LawyerName,
                LaunchDate: oldRow.LaunchDate, Status: mp(statusMap, oldRow.Status), Notes: oldRow.Notes
            };
            const newView = {};
            if (TrackingCode) newView.TrackingCode = TrackingCode;
            if (StageType) newView.StageType = mp(stageMap, StageType);
            if (StageNumber !== undefined && StageNumber !== null) newView.StageNumber = StageNumber;
            if (CourtName) newView.CourtName = CourtName;
            if (CircuitName !== undefined) newView.CircuitName = CircuitName;
            if (Subject !== undefined) newView.Subject = Subject;
            if (RequestedByOpponent !== undefined) newView.RequestedByOpponent = yn(RequestedByOpponent);
            if (RequestedBy !== undefined) newView.RequestedBy = RequestedBy;
            if (Plaintiff !== undefined) newView.Plaintiff = Plaintiff;
            if (Defendant !== undefined) newView.Defendant = Defendant;
            if (lawyerName) newView.LawyerName = lawyerName;
            if (LaunchDate) newView.LaunchDate = LaunchDate;
            if (Status) newView.Status = mp(statusMap, Status);
            if (Notes !== undefined) newView.Notes = Notes;
            llChangeLines = buildChangesText(oldView, newView, {
                TrackingCode: 'رقم التتبع', StageType: 'نوع الدرجة', StageNumber: 'رقم الدرجة',
                CourtName: 'المحكمة', CircuitName: 'الدائرة', Subject: 'الموضوع',
                RequestedByOpponent: 'بطلب الخصم', RequestedBy: 'مقدم الطلب',
                Plaintiff: 'المدعي', Defendant: 'المدعى عليه', LawyerName: 'المحامي',
                LaunchDate: 'تاريخ الإطلاق', Status: 'الحالة', Notes: 'الملاحظات'
            });
        } catch (diffErr) { console.error('⚠️ تعذر حساب فروقات درجة التقاضي:', diffErr.message); }

        await logActivity(req, 'edit', withChanges(`تم تعديل درجة التقاضي رقم ${finalTrackingCode} (${finalCourtName || ''})`, llChangeLines), 'درجات التقاضي');

        res.json({
            success: true,
            message: 'تم تحديث درجة التقاضي بنجاح'
        });

    } catch (error) {
        console.error('❌ خطأ في تحديث درجة التقاضي:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

// 22.5 حذف درجة تقاضي
app.delete('/api/litigation-levels/:id', async (req, res) => {
    try {
        const { id } = req.params;
        
        const check = await db.query("SELECT * FROM LitigationLevels WHERE Id = @p0", [id]);
        if (check.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'درجة التقاضي غير موجودة'
            });
        }

        // 💾 حفظ في الأرشيف قبل الحذف
        await archiveRecord('LitigationLevel', id, check[0], PAGE_URLS.LitigationLevel);

        await db.query("DELETE FROM LitigationLevels WHERE Id = @p0", [id]);

        // بعد حذف الدرجة، تحديث درجة القضية في جدول Cases لأعلى درجة متبقية
        if (check[0].CaseId) {
            try {
                const remaining = await db.query(
                    "SELECT StageType FROM LitigationLevels WHERE CaseId = @p0 ORDER BY Id DESC",
                    [check[0].CaseId]
                );
                let topStage = 'ابتدائي';
                if (remaining.length > 0) {
                    const topType = (remaining[0].StageType || '').toLowerCase();
                    if (topType === 'cassation') topStage = 'نقض';
                    else if (topType === 'appeal') topStage = 'استئناف';
                    else if (topType === 'eshkal_tanfeeth' || topType === 'execution') topStage = 'إشكال في التنفيذ';
                    else if (topType === 'eshkal') topStage = 'إشكال';
                    else if (topType === 'iltimas') topStage = 'التماس إعادة النظر';
                    else topStage = remaining[0].StageType || 'استئناف';
                }
                await db.query("UPDATE Cases SET CurrentStage = @p0, UpdatedAt = GETDATE() WHERE Id = @p1", [topStage, check[0].CaseId]);
            } catch (e) {
                console.error('⚠️ تحذير: فشل تحديث درجة القضية بعد الحذف:', e.message);
            }
        }

        await logActivity(req, 'delete', `تم حذف درجة التقاضي رقم ${check[0].TrackingCode || id}`, 'درجات التقاضي');
        
        res.json({
            success: true,
            message: 'تم حذف درجة التقاضي ونقلها للأرشيف بنجاح'
        });
    } catch (error) {
        console.error('❌ خطأ في حذف درجة التقاضي:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

// ============================================
// جلب قضية برقم ID (للتعديل) - نسخة محسنة ومحمية
// ============================================
app.get(['/api/cases/id/:id', '/api/cases/:id'], async (req, res) => {
    try {
        const { id } = req.params;
        
        console.log('🔍 جلب قضية برقم ID:', id);
        
        const sql = `
            SELECT 
                c.Id,
                c.CaseNumber,
                c.CaseYear,
                c.CaseType,
                CAST(c.Subject AS NVARCHAR(MAX)) AS Subject,
                CAST(c.Description AS NVARCHAR(MAX)) AS Description,
                CAST(c.Notes AS NVARCHAR(MAX)) AS Notes,
                c.Category,
                c.CurrentStage,
                c.[Status],
                c.FilingDate,
                c.CreatedAt,
                c.AssignedLawyerId,
                c.CourtName,
                c.CircuitName,
                CAST(COALESCE(c.Plaintiff, c.Defendant, '') AS NVARCHAR(MAX)) AS Opponent,
                CAST(c.Plaintiff AS NVARCHAR(MAX)) AS Plaintiff,
                CAST(c.Defendant AS NVARCHAR(MAX)) AS Defendant,
                COALESCE(c.ClaimValue, c.ClaimAmount) AS ClaimValue,
                c.LawsuitExpenses,
                l.FullName AS LawyerName,
                l.Code AS LawyerCode,
                l.Mobile AS LawyerMobile
            FROM Cases c
            LEFT JOIN Lawyers l ON c.AssignedLawyerId = l.Id
            WHERE c.Id = @p0
        `;
        
        const result = await db.query(sql, [id]);
        
        if (result.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'القضية غير موجودة'
            });
        }
        
        const caseData = result[0];
        
        // جلب الأطراف بأمان
        let parties = [];
        try {
            parties = await db.query(
                `SELECT Id, PartyType, PartyCategory, CAST(Name AS NVARCHAR(MAX)) AS Name, [Position], Mobile, LawyerName, LawyerMobile, Deceased, Heirs 
                 FROM CaseParties 
                 WHERE CaseId = @p0`,
                [id]
            );
        } catch (pe) {
            console.log('⚠️ خطأ ثانوي في جلب أطراف القضية:', pe.message);
        }
        
        // جلب الجلسات بأمان
        let sessions = [];
        try {
            sessions = await db.query(
                `SELECT Id, SessionDate, SessionTime, Stage, [Status], ActionTaken 
                 FROM Sessions 
                 WHERE CaseId = @p0 
                 ORDER BY SessionDate DESC`,
                [id]
            );
        } catch (se) {
            console.log('⚠️ خطأ ثانوي في جلب جلسات القضية:', se.message);
        }
        
        const responseData = {
            Id: caseData.Id,
            CaseNumber: caseData.CaseNumber || '',
            CaseYear: caseData.CaseYear || '',
            CaseType: caseData.CaseType || '',
            Subject: caseData.Subject || '',
            Description: caseData.Description || '',
            Notes: caseData.Notes || '',
            Category: caseData.Category || 'مدني',
            CurrentStage: caseData.CurrentStage || 'ابتدائي',
            Status: caseData.Status || 'مفتوحة',
            FilingDate: caseData.FilingDate || null,
            CreatedAt: caseData.CreatedAt || null,
            AssignedLawyerId: caseData.AssignedLawyerId || null,
            CourtName: caseData.CourtName || '',
            CircuitName: caseData.CircuitName || '',
            Opponent: caseData.Opponent || '',
            Plaintiff: caseData.Plaintiff || '',
            Defendant: caseData.Defendant || '',
            ClaimValue: caseData.ClaimValue || '',
            LawsuitExpenses: caseData.LawsuitExpenses || '',
            LawyerName: caseData.LawyerName || '',
            LawyerCode: caseData.LawyerCode || '',
            LawyerMobile: caseData.LawyerMobile || '',
            Parties: parties || [],
            Sessions: sessions || [],
            SessionsCount: (sessions || []).length
        };
        
        res.json({
            success: true,
            data: responseData
        });
        
    } catch (error) {
        console.error('❌ خطأ في جلب القضية:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});
// ============================================
// تحديث بيانات القضية (للمحكمة والدائرة)
// ============================================
app.put('/api/cases/:id/court', async (req, res) => {
    try {
        const { id } = req.params;
        const { courtName, circuitName } = req.body;
        const oldCourtRows = await db.query("SELECT CaseNumber, CourtName, CircuitName FROM Cases WHERE Id = @p0", [id]);
        
        const sql = `
            UPDATE Cases SET 
                CourtName = @p0,
                CircuitName = @p1,
                UpdatedAt = GETDATE()
            WHERE Id = @p2
        `;
        
        await db.query(sql, [courtName || null, circuitName || null, id]);

        await logActivity(req, 'edit', withChanges(`تم تعديل بيانات المحكمة/الدائرة للقضية ${oldCourtRows[0] && oldCourtRows[0].CaseNumber ? 'رقم ' + oldCourtRows[0].CaseNumber : '(ID: ' + id + ')'}`, buildChangesText(oldCourtRows[0] || {}, { CourtName: courtName || null, CircuitName: circuitName || null }, { CourtName: 'المحكمة', CircuitName: 'الدائرة' })), 'القضايا');
        
        res.json({
            success: true,
            message: 'تم تحديث بيانات المحكمة والدائرة'
        });
    } catch (error) {
        console.error('❌ خطأ في تحديث المحكمة والدائرة:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

// ============================================
// 22.6 تحديث حالة القضية يدوياً (مثلاً: تحويلها إلى "منتهية" من شاشة جميع القضايا)
// ============================================
app.put('/api/cases/:id/status', async (req, res) => {
    try {
        const { id } = req.params;
        const { status, lawsuitExpenses } = req.body;

        if (!status) {
            return res.status(400).json({
                success: false,
                message: 'حالة القضية (status) مطلوبة'
            });
        }

        const check = await db.query("SELECT Id, CaseNumber, [Status] FROM Cases WHERE Id = @p0", [id]);
        if (check.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'القضية غير موجودة'
            });
        }

        const caseNumber = check[0].CaseNumber;

        await db.query(
            `UPDATE Cases SET [Status] = @p0, UpdatedAt = GETDATE() WHERE Id = @p1`,
            [status, id]
        );

        // لو اتحولت لـ "منتهية" → نقفل كل جلساتها ودرجات التقاضي المرتبطة بيها تلقائياً
        if (status === 'منتهية') {
            await db.query(
                `UPDATE Sessions 
                 SET IsClosed = 1, [Status] = N'مغلقة'
                 WHERE CaseId = @p0 AND (IsClosed IS NULL OR IsClosed = 0)`,
                [id]
            );
            await db.query(
                `UPDATE LitigationLevels SET [Status] = 'closed', UpdatedAt = GETDATE() WHERE CaseId = @p0`,
                [id]
            );

            // ✅ حفظ مصاريف الدعوة المُدخلة عند إغلاق القضية (إن وُجدت)
            if (lawsuitExpenses !== undefined && lawsuitExpenses !== null && lawsuitExpenses !== '') {
                await db.query(
                    `UPDATE Cases SET CaseExpenses = @p0 WHERE Id = @p1`,
                    [String(lawsuitExpenses), id]
                );
            }

            console.log(`✅ تم إغلاق القضية ${caseNumber} وجميع جلساتها يدوياً`);
        }

        await logActivity(req, 'edit', withChanges(`تم تحديث حالة القضية رقم ${caseNumber} يدوياً`, buildChangesText(check[0], { Status: status }, { Status: 'حالة القضية' })), 'القضايا');

        res.json({
            success: true,
            message: 'تم تحديث حالة القضية بنجاح',
            caseId: id,
            status: status
        });
    } catch (error) {
        console.error('❌ خطأ في تحديث حالة القضية:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

// ============================================
// 23. جلب جميع الجلسات مع درجة التقاضي المرتبطة
// ============================================
app.get('/api/sessions/with-levels', async (req, res) => {
    try {
        const { caseNumber, stageType } = req.query;
        
        let sql = `
            SELECT 
                s.Id,
                s.CaseId,
                s.SessionDate,
                s.SessionTime,
                s.Stage,
                s.AttendingLawyerId,
                s.ActionTaken,
                s.NextSessionDate,
                s.NextSessionTime,
                s.IsClosed,
                s.[Status],
                s.Notes,
                s.Result,
                s.AppealAction,
                s.SessionNotes,
                s.CreatedAt,
                s.LitigationLevelId,
                COALESCE(s.SessionCaseNumber, c.CaseNumber) AS CaseNumber,
                COALESCE(ll.Subject, c.Subject) AS CaseSubject,
                c.Category,
                c.CurrentStage,
                c.[Status] AS CaseStatus,
                COALESCE(ll.CourtName, c.CourtName) AS CourtName,
                COALESCE(ll.[الدائرة], c.CircuitName) AS CircuitName,
                COALESCE(c.Plaintiff, c.Defendant, '') AS Opponent,
                l.FullName AS LawyerName,
                al.FullName AS AttendingName,
                ll.StageType AS LitigationStageType,
                ll.StageNumber AS LitigationStageNumber,
                ll.TrackingCode AS LitigationTrackingCode,
                COALESCE(ll.CourtName, c.CourtName) AS LitigationCourtName,
                ll.LaunchDate AS LitigationLaunchDate,
                ll.[Status] AS LitigationStatus
            FROM Sessions s
            LEFT JOIN Cases c ON s.CaseId = c.Id
            LEFT JOIN Lawyers l ON c.AssignedLawyerId = l.Id
            LEFT JOIN Lawyers al ON s.AttendingLawyerId = al.Id
            LEFT JOIN LitigationLevels ll ON s.LitigationLevelId = ll.Id
            WHERE 1=1
        `;
        
        const params = [];
        let paramIndex = 0;
        
        if (caseNumber) {
            sql += ` AND c.CaseNumber LIKE @p${paramIndex}`;
            params.push(`%${caseNumber}%`);
            paramIndex++;
        }
        if (stageType) {
            sql += ` AND ll.StageType = @p${paramIndex}`;
            params.push(stageType);
            paramIndex++;
        }
        
        sql += ` ORDER BY s.SessionDate DESC, s.CreatedAt DESC`;
        
        const sessions = await db.query(sql, params);
        
        const formattedSessions = sessions.map(s => ({
            Id: s.Id,
            CaseId: s.CaseId,
            CaseNumber: s.CaseNumber || '—',
            Subject: s.CaseSubject || s.Notes || '—',
            Stage: s.Stage || s.CurrentStage || 'ابتدائي',
            Opponent: s.Opponent || '—',
            SessionDate: s.SessionDate ? new Date(s.SessionDate).toISOString().split('T')[0] : null,
            SessionTime: formatSessionTime(s.SessionTime),
            Status: s.Status || 'متداولة',
            LawyerName: s.LawyerName || '—',
            AttendingName: s.AttendingName || '—',
            Action: s.ActionTaken || '—',
            NextDate: s.NextSessionDate ? new Date(s.NextSessionDate).toISOString().split('T')[0] : null,
            IsClosed: s.IsClosed || false,
            Result: s.Result || null,
            AppealAction: s.AppealAction || null,
            SessionNotes: s.SessionNotes || null,
            CourtName: s.CourtName || '',
            CircuitName: s.CircuitName || '',
            LitigationLevelId: s.LitigationLevelId || null,
            LitigationStageType: s.LitigationStageType || s.Stage || 'initial',
            LitigationStageNumber: s.LitigationStageNumber || null,
            LitigationTrackingCode: s.LitigationTrackingCode || null,
            LitigationCourtName: s.LitigationCourtName || s.CourtName || '',
            LitigationLaunchDate: s.LitigationLaunchDate || null,
            LitigationStatus: s.LitigationStatus || s.Status || 'open'
        }));
        
        res.json({
            success: true,
            data: formattedSessions,
            count: formattedSessions.length
        });
    } catch (error) {
        console.error('❌ خطأ في جلب الجلسات مع درجات التقاضي:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});
// ============================================
// جلب الجلسات مع تفاصيلها (لصفحة المتابعة)
// ============================================
app.get('/api/sessions/details', async (req, res) => {
    try {
        const { caseId, status, litigationLevelId } = req.query;

        let sql = `
            SELECT 
                s.Id,
                s.CaseId,
                s.LitigationLevelId,
                s.SessionDate,
                s.SessionTime,
                s.Stage,
                s.[Status],
                s.IsClosed,
                s.Result,
                s.AppealAction,
                s.SessionNotes,
                s.Notes,
                s.LawsuitExpenses AS JudgmentValue,
                s.ActionTaken AS Action,
                c.Plaintiff AS Plaintiff,
                c.Defendant AS Defendant,
                ll.RequestedBy AS StageRequestedBy,
                s.CreatedAt,
                s.UpdatedAt,
                s.SessionCaseNumber,
                ll.TrackingCode AS LitigationTrackingCode,
                COALESCE(s.SessionCaseNumber, ll.TrackingCode, c.CaseNumber) AS CaseNumber,
                COALESCE(ll.Subject, c.Subject) AS CaseSubject,
                c.CaseNumber AS BaseCaseNumber,
                c.Subject AS BaseSubject,
                COALESCE(c.Plaintiff, c.Defendant, '') AS CaseOpponent,
                COALESCE(ll.CourtName, c.CourtName) AS CourtName,
                COALESCE(ll.[الدائرة], c.CircuitName) AS CircuitName,
                c.CurrentStage AS CaseStage,
                c.Category AS Category,
                l.FullName AS LawyerName,
                al.FullName AS AttendingName,
                (
                    SELECT COUNT(*) FROM LitigationLevels
                    WHERE CaseId = s.CaseId AND StageType = 'appeal'
                ) AS HasAppealLevel,
                (
                    SELECT COUNT(*) FROM LitigationLevels
                    WHERE CaseId = s.CaseId AND StageType = 'cassation'
                ) AS HasCassationLevel
            FROM Sessions s 
            LEFT JOIN Cases c ON s.CaseId = c.Id
            LEFT JOIN Lawyers l ON c.AssignedLawyerId = l.Id
            LEFT JOIN Lawyers al ON s.AttendingLawyerId = al.Id
            LEFT JOIN LitigationLevels ll ON s.LitigationLevelId = ll.Id
            WHERE 1=1
        `;

        const params = [];
        let paramIndex = 0;

        if (caseId) {
            sql += ` AND s.CaseId = @p${paramIndex}`;
            params.push(caseId);
            paramIndex++;
        }

        if (litigationLevelId) {
            sql += ` AND s.LitigationLevelId = @p${paramIndex}`;
            params.push(litigationLevelId);
            paramIndex++;
        }

        if (status) {
            sql += ` AND s.[Status] = @p${paramIndex}`;
            params.push(status);
            paramIndex++;
        }

        sql += ` ORDER BY s.SessionDate DESC, s.CreatedAt DESC`;

        const sessions = await db.query(sql, params);

        // ✅ توحيد شكل التاريخ إلى "YYYY-MM-DD" فقط (بدون وقت/Z) حتى تتطابق المقارنات
        // في الواجهة (مثل كارت "جلسات اليوم") بدلاً من إرسال التاريخ كاملاً بالوقت والتوقيت
        // (كان بيوصل مثلاً "2026-08-11T00:00:00.000Z" فيفشل التطابق مع "2026-08-11")
        const formattedSessions = sessions.map(s => ({
            ...s,
            SessionDate: s.SessionDate ? new Date(s.SessionDate).toISOString().split('T')[0] : null
        }));

        res.json({
            success: true,
            data: formattedSessions,
            count: formattedSessions.length
        });

    } catch (error) {
        console.error('❌ خطأ في جلب تفاصيل الجلسات:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

// ================================================================
// تحديث جلسة - تخزين الوقت كنص
// ================================================================
app.put('/api/sessions/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const {
            result,
            appealAction,
            sessionNotes,
            isClosed,
            status,
            attendingLawyerId,
            sessionDate,
            sessionTime,
            sessionCourtName,
            sessionCircuitName,
            sessionSubject,
            sessionOpponent,
            actionTaken,
            nextSessionDate,
            nextSessionTime,
            litigationLevelId,
            lawyerId,
            lawyerName,
            judgmentValue
        } = req.body;

        // التحقق من وجود الجلسة
        const check = await db.query(
            `SELECT s.Id, s.CaseId, s.LitigationLevelId, c.CaseNumber, c.Status AS CaseStatus, c.CurrentStage, s.Stage AS SessionStage,
                    s.Result, s.AppealAction, s.SessionNotes, s.IsClosed, s.[Status] AS SessionStatus, s.AttendingLawyerId,
                    s.SessionDate, s.SessionTime, s.ActionTaken, s.NextSessionDate, s.NextSessionTime, s.Notes AS SessionSubject,
                    s.LawsuitExpenses AS JudgmentValue, c.CourtName AS CaseCourtName, c.CircuitName AS CaseCircuitName, c.Subject AS CaseSubject 
             FROM Sessions s 
             LEFT JOIN Cases c ON s.CaseId = c.Id 
             WHERE s.Id = @p0`,
            [id]
        );

        if (check.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'الجلسة غير موجودة'
            });
        }

        const session = check[0];
        // القيم القديمة لدرجة التقاضي (لو الجلسة تابعة لدرجة) — للمقارنة في سجل التتبعات
        let oldLL = null;
        try {
            if (session.LitigationLevelId) {
                const llr = await db.query('SELECT * FROM LitigationLevels WHERE Id = @p0', [session.LitigationLevelId]);
                oldLL = llr[0] || null;
            }
        } catch (e) { oldLL = null; }
        const caseId = session.CaseId;
        const caseNumber = session.CaseNumber;

        console.log(`📝 تحديث الجلسة ${id} للقضية ${caseNumber}`);

        // ✅ تخزين الوقت كنص كما هو تماماً
        let storedTime = sessionTime || null;
        if (storedTime && storedTime.length === 5 && storedTime.includes(':')) {
            storedTime = storedTime; // HH:MM
        } else if (storedTime && storedTime.length > 5) {
            storedTime = storedTime.slice(0, 5);
        }
        console.log(`⏰ وقت التعديل للتخزين (كنص): ${storedTime}`);

        let storedNextTime = nextSessionTime || null;
        if (storedNextTime && storedNextTime.length === 5 && storedNextTime.includes(':')) {
            storedNextTime = storedNextTime;
        } else if (storedNextTime && storedNextTime.length > 5) {
            storedNextTime = storedNextTime.slice(0, 5);
        }

        const transaction = new db.sql.Transaction(db.pool);
        await transaction.begin();

        try {
            let updateSql = `UPDATE Sessions SET UpdatedAt = GETDATE()`;
            const params = [];
            let paramIndex = 0;

            if (result !== undefined) {
                updateSql += `, Result = @p${paramIndex}`;
                params.push(result);
                paramIndex++;
            }

            if (appealAction !== undefined) {
                updateSql += `, AppealAction = @p${paramIndex}`;
                params.push(appealAction);
                paramIndex++;
            }

            // ✅ قيمة الحكم (تُخزَّن في عمود LawsuitExpenses بجدول Sessions) — اختيارية، يمكن تركها فارغة
            if (judgmentValue !== undefined) {
                updateSql += `, LawsuitExpenses = @p${paramIndex}`;
                params.push(judgmentValue || null);
                paramIndex++;
            }

            if (sessionNotes !== undefined) {
                updateSql += `, SessionNotes = @p${paramIndex}`;
                params.push(sessionNotes);
                paramIndex++;
            }

            if (isClosed !== undefined) {
                updateSql += `, IsClosed = @p${paramIndex}`;
                params.push(isClosed ? 1 : 0);
                paramIndex++;
                if (isClosed) {
                    updateSql += `, ClosedAt = GETDATE()`;
                }
            }

            if (status !== undefined && status !== '') {
                updateSql += `, [Status] = @p${paramIndex}`;
                params.push(status);
                paramIndex++;
            }

            if (attendingLawyerId !== undefined) {
                updateSql += `, AttendingLawyerId = @p${paramIndex}`;
                params.push(attendingLawyerId);
                paramIndex++;
            }

            if (sessionDate !== undefined && sessionDate !== null && sessionDate !== '') {
                updateSql += `, SessionDate = @p${paramIndex}`;
                params.push(sessionDate);
                paramIndex++;
            }

            // ✅ تحديث الوقت كنص
            if (sessionTime !== undefined && sessionTime !== null && sessionTime !== '') {
                updateSql += `, SessionTime = @p${paramIndex}`;
                params.push(storedTime);  // ✅ تخزين كنص
                paramIndex++;
            }

            if (actionTaken !== undefined && actionTaken !== null && actionTaken !== '') {
                updateSql += `, ActionTaken = @p${paramIndex}`;
                params.push(actionTaken);
                paramIndex++;
            }

            if (nextSessionDate !== undefined && nextSessionDate !== null && nextSessionDate !== '') {
                updateSql += `, NextSessionDate = @p${paramIndex}`;
                params.push(nextSessionDate);
                paramIndex++;
            }

            if (nextSessionTime !== undefined && nextSessionTime !== null && nextSessionTime !== '') {
                updateSql += `, NextSessionTime = @p${paramIndex}`;
                params.push(storedNextTime);  // ✅ تخزين كنص
                paramIndex++;
            }

            if (sessionSubject !== undefined && sessionSubject !== null && sessionSubject !== '') {
                updateSql += `, Notes = @p${paramIndex}`;
                params.push(sessionSubject);
                paramIndex++;
            }

            updateSql += ` WHERE Id = @p${paramIndex}`;
            params.push(id);

            await db.query(updateSql, params);
            console.log(`✅ تم تحديث الجلسة ${id}`);

            // ===== تحديث بيانات القضية =====
            // ⚠️ ملحوظة هامة: شاشة عرض الجلسات (sessions/details) تعرض المحكمة/الدائرة/الموضوع
            // عن طريق COALESCE(ll.<field>, c.<field>) — أي أن قيمة درجة التقاضي (LitigationLevels)
            // لها الأولوية دائماً على قيمة القضية (Cases) طالما الجلسة مرتبطة بدرجة تقاضي.
            // لذلك التعديل لازم يتحدث في نفس المكان اللي البيانات بتتقرأ منه فعلياً،
            // وإلا التعديل هيتحفظ في قاعدة البيانات لكن هيفضل يظهر القديم في الشاشة.
            const sessionLitigationLevelId = session.LitigationLevelId || litigationLevelId || null;

            let caseUpdateFields = [];
            let caseParams = [];
            let caseIndex = 0;

            if (sessionCourtName && sessionCourtName !== '') {
                caseUpdateFields.push(`CourtName = @p${caseIndex}`);
                caseParams.push(sessionCourtName);
                caseIndex++;
            }

            if (sessionCircuitName && sessionCircuitName !== '') {
                caseUpdateFields.push(`CircuitName = @p${caseIndex}`);
                caseParams.push(sessionCircuitName);
                caseIndex++;
            }

            if (sessionOpponent && sessionOpponent !== '') {
                // Opponent column removed - store opponent info in Notes or use Plaintiff/Defendant
            }

            if (sessionSubject && sessionSubject !== '') {
                caseUpdateFields.push(`Subject = @p${caseIndex}`);
                caseParams.push(sessionSubject);
                caseIndex++;
            }

            if (lawyerId !== undefined && lawyerId !== null && lawyerId !== '') {
                caseUpdateFields.push(`AssignedLawyerId = @p${caseIndex}`);
                caseParams.push(lawyerId);
                caseIndex++;
            }

            // ✅ عند تسجيل قيمة حكم في الجلسة، نعكسها على القضية (LawsuitExpenses)
            // حتى تظهر في صفحة "جميع القضايا" تحت اسم "قيمة الحكم"
            if (judgmentValue !== undefined && judgmentValue !== null && judgmentValue !== '') {
                caseUpdateFields.push(`LawsuitExpenses = @p${caseIndex}`);
                caseParams.push(judgmentValue);
                caseIndex++;
            }

            if (caseUpdateFields.length > 0) {
                caseUpdateFields.push(`UpdatedAt = GETDATE()`);
                const caseSql = `UPDATE Cases SET ${caseUpdateFields.join(', ')} WHERE Id = @p${caseIndex}`;
                caseParams.push(caseId);
                await db.query(caseSql, caseParams);
                console.log(`✅ تم تحديث بيانات القضية ${caseNumber}`);
            }

            // تحديث نفس البيانات في درجة التقاضي (LitigationLevels) لو الجلسة تابعة لدرجة تقاضي محددة،
            // لأن شاشة العرض بتفضّل بيانات درجة التقاضي على بيانات القضية
            if (sessionLitigationLevelId) {
                let llUpdateFields = [];
                let llParams = [];
                let llIndex = 0;

                if (sessionCourtName && sessionCourtName !== '') {
                    llUpdateFields.push(`CourtName = @p${llIndex}`);
                    llParams.push(sessionCourtName);
                    llIndex++;
                }

                if (sessionCircuitName && sessionCircuitName !== '') {
                    llUpdateFields.push(`[الدائرة] = @p${llIndex}`);
                    llParams.push(sessionCircuitName);
                    llIndex++;
                }

                if (sessionSubject && sessionSubject !== '') {
                    llUpdateFields.push(`Subject = @p${llIndex}`);
                    llParams.push(sessionSubject);
                    llIndex++;
                }

                if (lawyerId !== undefined && lawyerId !== null && lawyerId !== '') {
                    llUpdateFields.push(`LawyerId = @p${llIndex}`);
                    llParams.push(lawyerId);
                    llIndex++;
                    if (lawyerName) {
                        llUpdateFields.push(`LawyerName = @p${llIndex}`);
                        llParams.push(lawyerName);
                        llIndex++;
                    }
                }

                if (llUpdateFields.length > 0) {
                    llUpdateFields.push(`UpdatedAt = GETDATE()`);
                    const llSql = `UPDATE LitigationLevels SET ${llUpdateFields.join(', ')} WHERE Id = @p${llIndex}`;
                    llParams.push(sessionLitigationLevelId);
                    await db.query(llSql, llParams);
                    console.log(`✅ تم تحديث بيانات درجة التقاضي ${sessionLitigationLevelId} لمطابقة تعديل الجلسة`);
                }
            }

            // ===== تغيير حالة القضية =====
            // القاعدة الجديدة:
            // 1) أي إجراء اتاخد في الجلسة (نطق بحكم لصالح الشركة أو الخصم، إجراء استئناف/نقض/
            //    اشكال في التنفيذ/التماس اعادة النظر، أو حتى تسجيل الجلسة كـ"منتهية") => القضية
            //    تتحول تلقائياً إلى "معلقة" (تظهر باللون الأصفر) لحد ما حد يقفلها يدوياً من
            //    شاشة "جميع القضايا".
            // 2) لو معملتش أي إجراء (تأجيل عادي فقط بدون نطق حكم) => القضية تفضل "متداولة".
            // 3) القضية متبقاش تتقفل تلقائياً "مغلقة" من هنا أبداً — الإغلاق بقى خطوة يدوية
            //    منفصلة (زرار "تحويل لمنتهية" في صفحة جميع القضايا).
            let newCaseStatus = session.CaseStatus;

            const isSessionMarkedFinished = isClosed === true || isClosed === 1 || isClosed === 'true' ||
                                   status === 'مغلقة' || status === 'عُقدت' || status === 'منتهية';

            const hasRealAppealAction = appealAction && appealAction !== '' && appealAction !== 'لا اجراء' && appealAction !== 'لا شيء';

            const hasVerdictResult = result && result !== '';

            // أي إجراء حقيقي تم اتخاذه في الجلسة
            const anyActionTaken = isSessionMarkedFinished || hasRealAppealAction || hasVerdictResult;

            if (anyActionTaken) {
                await db.query(
                    "UPDATE Cases SET [Status] = N'معلقة', UpdatedAt = GETDATE() WHERE Id = @p0",
                    [caseId]
                );
                newCaseStatus = 'معلقة';
                console.log(`⚠️ تم تعليق القضية ${caseNumber} (إجراء متخذ فى الجلسة، بانتظار الإغلاق اليدوي)`);

                // ✅ إعادة حساب نتيجة القضية (عمود Agginst) بناءً على أحدث جلسة (بالتاريخ) لها نتيجة
                // من بين كل جلسات القضية — مش بالضرورة الجلسة اللي بتتعدل دلوقتي.
                // بالشكل ده لو حد رجع عدّل جلسة قديمة وحطلها نتيجة، النتيجة الظاهرة في القضية
                // تفضل نتيجة أحدث جلسة تاريخياً، مش آخر جلسة اتعدلت.
                if (hasVerdictResult) {
                    await recalculateCaseResult(caseId);
                }
            } else if (status === 'متداولة') {
                await db.query(
                    "UPDATE Cases SET [Status] = N'متداولة', UpdatedAt = GETDATE() WHERE Id = @p0",
                    [caseId]
                );
                newCaseStatus = 'متداولة';
            }

            if (litigationLevelId) {
                await db.query(
                    "UPDATE LitigationLevels SET [Status] = 'open', UpdatedAt = GETDATE() WHERE Id = @p0",
                    [litigationLevelId]
                );
                console.log(`✅ تم تحديث درجة التقاضي ${litigationLevelId}`);
            }

            await transaction.commit();

            // ===== تتبّع التغييرات (قديم ← جديد) لسجل التتبعات =====
            let sessionChangeLines = [];
            try {
                const yn = v => (v === true || v === 1 || v === '1') ? 'نعم' : 'لا';
                const has = v => v !== undefined && v !== null && v !== '';
                const oldView = {
                    Result: session.Result, AppealAction: session.AppealAction, JudgmentValue: session.JudgmentValue,
                    SessionNotes: session.SessionNotes, IsClosed: yn(session.IsClosed), SessionStatus: session.SessionStatus,
                    SessionDate: session.SessionDate, SessionTime: session.SessionTime, ActionTaken: session.ActionTaken,
                    NextSessionDate: session.NextSessionDate, NextSessionTime: session.NextSessionTime,
                    SessionSubject: session.SessionSubject,
                    CourtName: (oldLL && oldLL.CourtName) || session.CaseCourtName,
                    CircuitName: (oldLL && oldLL.CircuitName) || session.CaseCircuitName,
                    AttendingLawyer: '', CaseLawyer: ''
                };
                const newView = {};
                if (result !== undefined) newView.Result = result;
                if (appealAction !== undefined) newView.AppealAction = appealAction;
                if (judgmentValue !== undefined) newView.JudgmentValue = judgmentValue || null;
                if (sessionNotes !== undefined) newView.SessionNotes = sessionNotes;
                if (isClosed !== undefined) newView.IsClosed = yn(isClosed ? 1 : 0);
                if (has(status)) newView.SessionStatus = status;
                if (has(sessionDate)) newView.SessionDate = sessionDate;
                if (has(sessionTime)) newView.SessionTime = storedTime;
                if (has(actionTaken)) newView.ActionTaken = actionTaken;
                if (has(nextSessionDate)) newView.NextSessionDate = nextSessionDate;
                if (has(nextSessionTime)) newView.NextSessionTime = storedNextTime;
                if (has(sessionSubject)) newView.SessionSubject = sessionSubject;
                if (has(sessionCourtName)) newView.CourtName = sessionCourtName;
                if (has(sessionCircuitName)) newView.CircuitName = sessionCircuitName;
                if (attendingLawyerId !== undefined && String(attendingLawyerId || '') !== String(session.AttendingLawyerId || '')) {
                    oldView.AttendingLawyer = await _lawyerNameById(session.AttendingLawyerId);
                    newView.AttendingLawyer = await _lawyerNameById(attendingLawyerId);
                }
                sessionChangeLines = buildChangesText(oldView, newView, {
                    SessionDate: 'تاريخ الجلسة', SessionTime: 'وقت الجلسة', Result: 'نتيجة الجلسة',
                    ActionTaken: 'الإجراء المتخذ', AppealAction: 'إجراء الطعن', JudgmentValue: 'قيمة الحكم',
                    SessionNotes: 'ملاحظات الجلسة', SessionSubject: 'موضوع الجلسة',
                    NextSessionDate: 'تاريخ الجلسة القادمة', NextSessionTime: 'وقت الجلسة القادمة',
                    SessionStatus: 'حالة الجلسة', IsClosed: 'الجلسة مغلقة', AttendingLawyer: 'المحامي الحاضر',
                    CourtName: 'المحكمة', CircuitName: 'الدائرة'
                });
            } catch (diffErr) { console.error('⚠️ تعذر حساب فروقات الجلسة:', diffErr.message); }

            await logActivity(req, 'edit', withChanges(`تم تحديث جلسة القضية رقم ${caseNumber}`, sessionChangeLines), 'الجلسات');

            res.json({
                success: true,
                message: 'تم تحديث الجلسة بنجاح',
                caseClosed: (newCaseStatus === 'مغلقة'),
                caseStatus: newCaseStatus,
                caseNumber: caseNumber,
                sessionId: id,
                savedTime: storedTime
            });

        } catch (error) {
            await transaction.rollback();
            throw error;
        }

    } catch (error) {
        console.error('❌ خطأ في تحديث الجلسة:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

// ============================================
// 22.5 نظام الإشعارات
// ============================================

// دالة مساعدة: إرسال إشعار لكل المستخدمين النشطين (Investigations)
async function notifyAllInvUsers(title, message, type, entityId, entityUrl) {
    try {
        const users = await db.query('SELECT Id FROM Users WHERE IsActive = 1');
        for (const u of users) {
            await db.query(
                `INSERT INTO InvestigationNotifications (UserId, Title, Message, NotifType, EntityId, EntityUrl, IsRead, CreatedAt)
                 VALUES (@p0, @p1, @p2, @p3, @p4, @p5, 0, GETDATE())`,
                [u.Id, title, message, type, entityId || null, entityUrl || null]
            );
        }
    } catch (err) {
        console.warn('⚠️ تعذّر إرسال إشعارات التحقيقات:', err.message);
    }
}

// جلب إشعارات المستخدم الحالي
app.get('/api/notifications', async (req, res) => {
    try {
        const username = getRequestUsername(req);
        if (!username || username === 'غير معروف') {
            return res.json({ success: true, data: [], unreadCount: 0 });
        }
        const userRows = await db.query('SELECT Id FROM Users WHERE Username = @p0 AND IsActive = 1', [username]);
        if (userRows.length === 0) {
            return res.json({ success: true, data: [], unreadCount: 0 });
        }
        const userId = userRows[0].Id;
        const notifs = await db.query(
            `SELECT TOP 30 Id, Title, Message, NotifType, EntityId, EntityUrl, IsRead, CreatedAt
             FROM InvestigationNotifications WHERE UserId = @p0
             ORDER BY CreatedAt DESC`,
            [userId]
        );
        const unreadCount = notifs.filter(n => !n.IsRead).length;
        res.json({ success: true, data: notifs, unreadCount });
    } catch (error) {
        console.error('❌ خطأ في جلب الإشعارات:', error);
        res.status(500).json({ success: false, message: error.message });
    }
});

// تحديد إشعار كمقروء
app.post('/api/notifications/read', async (req, res) => {
    try {
        const username = getRequestUsername(req);
        const { id, markAll } = req.body;
        if (!username || username === 'غير معروف') {
            return res.status(401).json({ success: false, message: 'يجب تسجيل الدخول' });
        }
        const userRows = await db.query('SELECT Id FROM Users WHERE Username = @p0 AND IsActive = 1', [username]);
        if (userRows.length === 0) {
            return res.status(401).json({ success: false, message: 'المستخدم غير موجود' });
        }
        const userId = userRows[0].Id;
        if (markAll) {
            await db.query('UPDATE InvestigationNotifications SET IsRead = 1 WHERE UserId = @p0', [userId]);
        } else if (id) {
            await db.query('UPDATE InvestigationNotifications SET IsRead = 1 WHERE Id = @p0 AND UserId = @p1', [id, userId]);
        }
        res.json({ success: true });
    } catch (error) {
        console.error('❌ خطأ في تحديث الإشعارات:', error);
        res.status(500).json({ success: false, message: error.message });
    }
});

// جلب أرشيف التحقيقات فقط
app.get('/api/archive/investigations', async (req, res) => {
    try {
        const result = await db.query(
            "SELECT * FROM Archive WHERE RecordType = 'Investigation' ORDER BY DeletedAt DESC"
        );
        res.json({ success: true, data: result });
    } catch (error) {
        console.error('❌ خطأ في جلب أرشيف التحقيقات:', error);
        res.status(500).json({ success: false, message: error.message });
    }
});

// ============================================
// 23. الأرشيف
// ============================================
app.get('/api/archive', async (req, res) => {
    try {
        const admin = await isAdminRequest(req);
        // الأدمن بيشوف كل عناصر الأرشيف، أما المستخدم العادي فبيشوف فقط اللي مش مخفي عنه
        const sql = admin
            ? "SELECT * FROM Archive ORDER BY DeletedAt DESC"
            : "SELECT * FROM Archive WHERE HiddenForUsers = 0 ORDER BY DeletedAt DESC";
        const result = await db.query(sql);
        res.json({ success: true, data: result });
    } catch (error) {
        console.error('❌ خطأ في جلب الأرشيف:', error);
        res.status(500).json({ success: false, message: error.message });
    }
});

app.post('/api/archive/restore/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const archiveRec = await db.query("SELECT * FROM Archive WHERE Id = @p0", [id]);
        if (archiveRec.length === 0) {
            return res.status(404).json({ success: false, message: 'العنصر غير موجود' });
        }

        const rec = archiveRec[0];
        const data = JSON.parse(rec.RecordData);
        const pageUrl = rec.PageUrl || PAGE_URLS[rec.RecordType] || null;

        if (rec.RecordType === 'Session') {
            const sql = `
                INSERT INTO Sessions (
                    CaseId, SessionDate, SessionTime, Stage, [Status], 
                    IsClosed, Result, AppealAction, SessionNotes, 
                    Notes, ActionTaken
                ) VALUES (
                    @p0, @p1, @p2, @p3, @p4, 
                    @p5, @p6, @p7, @p8, 
                    @p9, @p10
                )
            `;
            await db.query(sql, [
                data.CaseId, data.SessionDate, data.SessionTime, data.Stage, data.Status,
                data.IsClosed, data.Result, data.AppealAction, data.SessionNotes,
                data.Notes, data.ActionTaken
            ]);
        } else if (rec.RecordType === 'Lawyer') {
            // لو المحامي كان مرتبط بقضايا/جلسات وقت الحذف، الصف الأصلي لسه موجود في الجدول
            // بحالة IsDeleted = 1 (بنفس الـ Id) عشان الربط ميتكسرش — فبنرجّعه بنفس الصف
            // (IsDeleted = 0) بدل ما ننشئ صف جديد بمعرّف مختلف.
            // لو مفيش صف بنفس الـ Id (كان اتحذف نهائي من غير ارتباطات)، بننشئ صف جديد من بيانات الأرشيف.
            const existingRow = data.Id
                ? await db.query("SELECT Id FROM Lawyers WHERE Id = @p0 AND IsDeleted = 1", [data.Id])
                : [];
            if (existingRow.length > 0) {
                await db.query("UPDATE Lawyers SET IsDeleted = 0 WHERE Id = @p0", [data.Id]);
            } else {
                await insertFromObject('Lawyers', data, ['Id']);
            }
        } else if (rec.RecordType === 'Court') {
            await insertFromObject('Courts', data, ['Id']);
        } else if (rec.RecordType === 'LitigationLevel') {
            await insertFromObject('LitigationLevels', data, ['Id']);
        } else if (rec.RecordType === 'Case') {
            // ✅ استعادة القضية مع كل السجلات المرتبطة بها (الأطراف، الجلسات، درجات التقاضي، المرفقات)
            const newCaseId = await insertFromObject('Cases', data.case, ['Id']);
            if (!newCaseId) {
                throw new Error('فشل في استعادة القضية');
            }

            for (const party of (data.caseParties || [])) {
                await insertFromObject('CaseParties', { ...party, CaseId: newCaseId }, ['Id']);
            }
            for (const session of (data.sessions || [])) {
                await insertFromObject('Sessions', { ...session, CaseId: newCaseId }, ['Id']);
            }
            for (const level of (data.litigationLevels || [])) {
                await insertFromObject('LitigationLevels', { ...level, CaseId: newCaseId }, ['Id']);
            }
            for (const attachment of (data.attachments || [])) {
                await insertFromObject('Attachments', { ...attachment, CaseId: newCaseId }, ['Id']);
            }
        } else if (rec.RecordType === 'Investigation') {
            // ✅ استعادة التحقيق مع كل السجلات المرتبطة
            const inv = data.investigation;
            try {
                await db.query(`
                    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='Investigations' AND COLUMN_NAME='MaterialValue')
                    ALTER TABLE Investigations ADD MaterialValue DECIMAL(18,2) NULL
                `);
            } catch (e) { /* تجاهل */ }
            const newInvResult = await db.query(
                `INSERT INTO Investigations (MemoNumber, MemoDate, InvestigationType, ManagerName, MemoSummary,
                    IncidentDate, IncidentPlace, IncidentDescription, [Status], CreatedAt, MaterialValue)
                 VALUES (@p0, @p1, @p2, @p3, @p4, @p5, @p6, @p7, @p8, @p9, @p10);
                 SELECT SCOPE_IDENTITY() AS Id;`,
                [inv.MemoNumber, inv.MemoDate, inv.InvestigationType, inv.ManagerName, inv.MemoSummary || '',
                 inv.IncidentDate, inv.IncidentPlace || '', inv.IncidentDescription || '', inv.Status || 'جارية',
                 inv.CreatedAt || new Date(), inv.MaterialValue ?? null]
            );
            const newInvId = newInvResult[0]?.Id;
            if (!newInvId) throw new Error('فشل في استعادة التحقيق');

            for (const emp of (data.employees || [])) {
                // البحث عن الموظف أو إنشاؤه
                const existEmp = await db.query('SELECT Id FROM EmployeesMaster WHERE Code = @p0', [emp.EmployeeCode]);
                let empId;
                if (existEmp.length > 0) {
                    empId = existEmp[0].Id;
                } else {
                    const newEmpRes = await db.query(
                        `INSERT INTO EmployeesMaster (Code, FullName, JobGrade, WorkArea, IsActive, CreatedAt)
                         VALUES (@p0, @p1, @p2, @p3, 1, GETDATE()); SELECT SCOPE_IDENTITY() AS Id;`,
                        [emp.EmployeeCode, emp.EmployeeName, emp.JobGrade || '', emp.WorkArea || '']
                    );
                    empId = newEmpRes[0]?.Id;
                }
                if (empId) {
                    await db.query(
                        'INSERT INTO InvestigationEmployees (InvestigationId, EmployeeMasterId, CreatedAt) VALUES (@p0, @p1, GETDATE())',
                        [newInvId, empId]
                    );
                }
            }
            for (const s of (data.summons || [])) {
                await db.query(
                    'INSERT INTO Summons (InvestigationId, SummonsDate, [Response], AttendanceDate) VALUES (@p0, @p1, @p2, @p3)',
                    [newInvId, s.SummonsDate, s.Response || '', s.AttendanceDate || null]
                );
            }
        } else {
            throw new Error('نوع العنصر غير معروف، لا يمكن استعادته');
        }

        await db.query("DELETE FROM Archive WHERE Id = @p0", [id]);
        res.json({ success: true, message: 'تم الاستعادة بنجاح', pageUrl, recordType: rec.RecordType });
    } catch (error) {
        console.error('❌ خطأ في الاستعادة:', error);
        res.status(500).json({ success: false, message: error.message });
    }
});

// 🗑️ مسح نهائي لعنصر واحد من الأرشيف
// - الأدمن: بيتحذف فعلياً من جدول الأرشيف (نهائي، مفيش استرجاع)
// - المستخدم العادي: العنصر بيتخفي بس عن شاشته (HiddenForUsers = 1)، ويفضل موجود عند الأدمن عادي وقادر يرجعه
app.delete('/api/archive/erase/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const admin = await isAdminRequest(req);

        const existing = await db.query("SELECT Id FROM Archive WHERE Id = @p0", [id]);
        if (existing.length === 0) {
            return res.status(404).json({ success: false, message: 'العنصر غير موجود' });
        }

        if (admin) {
            await db.query("DELETE FROM Archive WHERE Id = @p0", [id]);
            await logActivity(req, 'delete', `تم حذف عنصر من الأرشيف نهائياً (#${id})`, 'الأرشيف');
        } else {
            await db.query("UPDATE Archive SET HiddenForUsers = 1 WHERE Id = @p0", [id]);
            await logActivity(req, 'delete', `تم مسح عنصر من الأرشيف (#${id})`, 'الأرشيف');
        }

        res.json({ success: true, message: 'تم المسح بنجاح' });
    } catch (error) {
        console.error('❌ خطأ في مسح عنصر الأرشيف:', error);
        res.status(500).json({ success: false, message: error.message });
    }
});

// 🗑️ مسح نهائي لكل عناصر الأرشيف الظاهرة حالياً لصاحب الطلب
// - الأدمن: بيتحذف كل الأرشيف فعلياً
// - المستخدم العادي: كل العناصر الظاهرة له بتتخفي بس، وتفضل موجودة عند الأدمن
app.delete('/api/archive/erase-all', async (req, res) => {
    try {
        const admin = await isAdminRequest(req);

        if (admin) {
            await db.query("DELETE FROM Archive");
            await logActivity(req, 'delete', 'تم مسح كل عناصر الأرشيف نهائياً', 'الأرشيف');
        } else {
            await db.query("UPDATE Archive SET HiddenForUsers = 1 WHERE HiddenForUsers = 0");
            await logActivity(req, 'delete', 'تم مسح كل عناصر الأرشيف الظاهرة للمستخدم', 'الأرشيف');
        }

        res.json({ success: true, message: 'تم مسح كل العناصر بنجاح' });
    } catch (error) {
        console.error('❌ خطأ في مسح كل عناصر الأرشيف:', error);
        res.status(500).json({ success: false, message: error.message });
    }
});

// ============================================
// فتح المتصفح تلقائياً عند تشغيل السيرفر
// ============================================
function openBrowser(url) {
    const { exec } = require('child_process');
    const platform = process.platform;
    let cmd;
    if (platform === 'win32') {
        cmd = `start "" "${url}"`;
    } else if (platform === 'darwin') {
        cmd = `open "${url}"`;
    } else {
        cmd = `xdg-open "${url}"`;
    }
    exec(cmd, (err) => {
        if (err) {
            console.log('⚠️ تعذر فتح المتصفح تلقائياً، افتحي الرابط يدوياً:', url);
        }
    });
}

// ============================================
// ردود JSON دايمًا لمسارات الـ API (بدل صفحات HTML)
// ============================================
// ليه؟ لو طلب اتوجّه لمسار /api مش موجود، أو حصل خطأ في قراءة الـ body، Express كان بيرد بصفحة HTML.
// الصفحات كانت بتحاول تقرأ الرد كـ JSON فتفشل وتعرض "خطأ في الاتصال بالخادم" بدون سبب واضح.
// ⚠️ لازم يفضل هنا في آخر الملف (بعد كل الـ routes وقبل app.listen).
app.use('/api', (req, res) => {
    res.status(404).json({
        success: false,
        message: `المسار غير موجود: ${req.method} ${req.originalUrl}`
    });
});

app.use((err, req, res, next) => {
    console.error('❌ خطأ غير معالج في الطلب:', req.method, req.originalUrl, '-', err.message);
    if (res.headersSent) return next(err);
    res.status(err.status || err.statusCode || 500).json({
        success: false,
        message: err.message || 'حدث خطأ في الخادم'
    });
});

// ============================================
// توسيع أعمدة المدعي/المدعى عليه (Plaintiff / Defendant)
// ============================================
// المشكلة: الأعمدة دي اتعملت NVARCHAR(255)، ولما القضية فيها عدة مدعى عليهم (أسماء كتير متفصولة بـ "،")
// النص بيعدّي 255 حرف فـ SQL Server بيرفض الحفظ بالخطأ:
// "String or binary data would be truncated ... column 'Defendant'"
// الحل: نحوّلهم لـ NVARCHAR(MAX). الدالة آمنة تتنفذ كل تشغيل (بتغيّر بس لو العمود لسه أصغر من MAX).
async function ensureWideTextColumns() {
    const targets = [
        { table: 'LitigationLevels', column: 'Plaintiff' },
        { table: 'LitigationLevels', column: 'Defendant' },
        { table: 'Cases', column: 'Plaintiff' },
        { table: 'Cases', column: 'Defendant' }
    ];
    for (const t of targets) {
        try {
            await db.query(`
                IF EXISTS (
                    SELECT 1 FROM sys.columns
                    WHERE object_id = OBJECT_ID(N'dbo.${t.table}')
                      AND name = N'${t.column}'
                      AND TYPE_NAME(user_type_id) IN (N'varchar', N'nvarchar')
                      AND max_length <> -1
                )
                ALTER TABLE dbo.${t.table} ALTER COLUMN ${t.column} NVARCHAR(MAX) NULL
            `);
            console.log(`✅ تم التأكد من اتساع عمود ${t.column} في جدول ${t.table}.`);
        } catch (widenErr) {
            console.log(`⚠️ تعذّر توسيع عمود ${t.column} في جدول ${t.table}:`, widenErr.message);
        }
    }
}

// ============================================
// تشغيل الخادم
// ============================================
app.listen(PORT, () => {
    console.log(`🚀 الخادم يعمل على: http://localhost:${PORT}`);
    console.log(`🌐 افتح الصفحات من رابط الخادم (مثال: http://localhost:${PORT}/litigation-level.html) وليس كملف مباشر`);
    console.log(`📊 قاعدة البيانات: ${process.env.DB_NAME || 'law_project'}`);
    
    db.poolConnect
        .then(async () => {
            console.log('✅ الاتصال بقاعدة البيانات ناجح!');
            try {
                // إنشاء جدول الأرشيف إذا لم يكن موجوداً
                await db.query(`
                    IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Archive' and xtype='U')
                    CREATE TABLE Archive (
                        Id INT IDENTITY(1,1) PRIMARY KEY,
                        RecordType NVARCHAR(50),
                        RecordId INT,
                        RecordData NVARCHAR(MAX),
                        PageUrl NVARCHAR(255) NULL,
                        DeletedAt DATETIME DEFAULT GETDATE()
                    )
                `);

                // ✅ ترقية الجدول لو كان موجوداً من قبل بدون عمود PageUrl
                await db.query(`
                    IF NOT EXISTS (
                        SELECT * FROM sys.columns
                        WHERE Name = N'PageUrl' AND Object_ID = Object_ID(N'Archive')
                    )
                    ALTER TABLE Archive ADD PageUrl NVARCHAR(255) NULL
                `);

                // ✅ ترقية الجدول لإضافة عمود إخفاء العنصر عن المستخدمين العاديين
                // (يُستخدم في ميزة "مسح نهائي" من الأرشيف: المستخدم العادي بيشوف العنصر وكأنه اتمسح نهائياً،
                // لكنه فعلياً بيتخفي بس، ويفضل موجود عند الأدمن عشان يقدر يرجعه)
                await db.query(`
                    IF NOT EXISTS (
                        SELECT * FROM sys.columns
                        WHERE Name = N'HiddenForUsers' AND Object_ID = Object_ID(N'Archive')
                    )
                    ALTER TABLE Archive ADD HiddenForUsers BIT NOT NULL DEFAULT 0
                `);

                console.log('✅ تم التأكد من جدول الأرشيف.');

                // ✅ ترقية جدول المحامين لإضافة عمود "حذف من الصفحة" (Soft Delete)
                // (يُستخدم مع زرار تفعيل/إلغاء تفعيل المحامي: لما المحامي يبقى غير نشط
                // يُسمح بـ"حذفه" من صفحة المحامين، لكن بياناته بتفضل موجودة في قاعدة البيانات
                // عشان اسمه يفضل ظاهر صح في القضايا والجلسات المرتبطة بيه ومايتأثروش)
                await db.query(`
                    IF NOT EXISTS (
                        SELECT * FROM sys.columns
                        WHERE Name = N'IsDeleted' AND Object_ID = Object_ID(N'Lawyers')
                    )
                    ALTER TABLE Lawyers ADD IsDeleted BIT NOT NULL DEFAULT 0
                `);
                console.log('✅ تم التأكد من جدول المحامين.');

                // ============================================
                // 🏷️ جدول التصنيفات الفرعية للقضايا (CaseSubTypes)
                // ============================================
                await db.query(`
                    IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='CaseSubTypes' and xtype='U')
                    CREATE TABLE CaseSubTypes (
                        Id INT IDENTITY(1,1) PRIMARY KEY,
                        Category NVARCHAR(50) NOT NULL,
                        Name NVARCHAR(255) NOT NULL,
                        CreatedAt DATETIME DEFAULT GETDATE()
                    )
                `);

                // بذر التصنيفات الأساسية (الافتراضية) داخل الجدول لو الجدول فاضي،
                // عشان تبقى قابلة للحذف/التعديل بنفس طريقة أي تصنيف تاني بدل ما تفضل مكتوبة بشكل ثابت في الكود
                const seedSubTypes = [
                    ['مدني', 'ضرائب عقارية'],
                    ['مدني', 'ضرائب كسب عمل'],
                    ['مدني', 'براءة ذمة'],
                    ['مدني', 'تعويضات'],
                    ['مدني', 'نزع ملكية'],
                    ['عمالي', 'رصيد إجازات'],
                    ['عمالي', 'فروق رصيد إجازات'],
                    ['عمالي', 'ضم مدة خدمة عسكرية'],
                    ['عمالي', 'تسوية الحالة الوظيفية'],
                    ['عمالي', 'العلاوات']
                ];
                for (const [cat, name] of seedSubTypes) {
                    await db.query(
                        `IF NOT EXISTS (SELECT Id FROM CaseSubTypes WHERE Category = @p0 AND Name = @p1)
                         INSERT INTO CaseSubTypes (Category, Name) VALUES (@p0, @p1)`,
                        [cat, name]
                    );
                }
                console.log('✅ تم التأكد من جدول التصنيفات الفرعية.');

                // ============================================
                // ⚙️ جدول إعدادات النظام العامة (AppSettings) — key/value
                // يُستخدم مثلاً لمنع/إتاحة إضافة تصنيف فرعي جديد لباقي المستخدمين
                // ============================================
                await db.query(`
                    IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='AppSettings' and xtype='U')
                    CREATE TABLE AppSettings (
                        Id INT IDENTITY(1,1) PRIMARY KEY,
                        [Key] NVARCHAR(100) NOT NULL UNIQUE,
                        [Value] NVARCHAR(500) NULL,
                        UpdatedAt DATETIME DEFAULT GETDATE()
                    )
                `);
                console.log('✅ تم التأكد من جدول إعدادات النظام.');

                // إنشاء جدول سجل التتبعات إذا لم يكن موجوداً
                await db.query(`
                    IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='ActivityLogs' and xtype='U')
                    CREATE TABLE ActivityLogs (
                        Id INT IDENTITY(1,1) PRIMARY KEY,
                        Username NVARCHAR(150) NULL,
                        Action NVARCHAR(50) NOT NULL,
                        Description NVARCHAR(1000) NULL,
                        PageName NVARCHAR(150) NULL,
                        IPAddress NVARCHAR(50) NULL,
                        Category NVARCHAR(50) NULL,
                        CreatedAt DATETIME DEFAULT GETDATE()
                    )
                `);

                // إضافة عمود Category — query منفصلة ضرورية حتى لا يحصل خطأ parse قبل وجود العمود
                await db.query(`
                    IF NOT EXISTS (
                        SELECT * FROM sys.columns
                        WHERE object_id = OBJECT_ID('ActivityLogs') AND name = 'Category'
                    )
                    ALTER TABLE ActivityLogs ADD Category NVARCHAR(50) NULL
                `);

                // خطوة 1: إعادة ضبط كل السجلات على cases (يصحح البيانات القديمة المصنفة خطأ)
                await db.query(`UPDATE ActivityLogs SET Category = 'cases'`);

                // خطوة 2: تصنيف سجلات التحقيقات فقط بدقة بناءً على username وصفحة
                await db.query(`
                    UPDATE ActivityLogs SET Category = 'investigation'
                    WHERE LOWER(Username) = 'inv'
                       OR LOWER(Username) LIKE '%inv%'
                       OR Username IN (
                           SELECT u.Username FROM Users u
                           INNER JOIN Roles r ON r.Id = u.RoleId
                           WHERE r.Name LIKE 'Investigation%'
                       )
                       OR PageName LIKE '%investigation%'
                       OR PageName LIKE N'%تحقيق%'
                       OR PageName LIKE N'%مستخدمو التحقيقات%'
                       OR PageName LIKE N'%أرشيف التحقيقات%'
                `);

                console.log('✅ تم التأكد من جدول سجل التتبعات وتحديث تصنيف Category بالكامل.');

                // ============================================
                // 🔐 تجهيز نظام صلاحيات التحقيقات (Modules / Roles / RoleModules / Users)
                // ============================================
                try {
                    // تأكيد وجود الجداول (لو مكنتش موجودة أصلاً)
                    await db.query(`
                        IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Modules' and xtype='U')
                        CREATE TABLE Modules (
                            Id INT IDENTITY(1,1) PRIMARY KEY,
                            Name NVARCHAR(50) NOT NULL UNIQUE,
                            Description NVARCHAR(255) NULL,
                            IsActive BIT DEFAULT 1,
                            CreatedAt DATETIME DEFAULT GETDATE()
                        )
                    `);
                    await db.query(`
                        IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Roles' and xtype='U')
                        CREATE TABLE Roles (
                            Id INT IDENTITY(1,1) PRIMARY KEY,
                            Name NVARCHAR(50) NOT NULL UNIQUE,
                            Description NVARCHAR(255) NULL,
                            IsActive BIT DEFAULT 1,
                            CreatedAt DATETIME DEFAULT GETDATE()
                        )
                    `);
                    await db.query(`
                        IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='RoleModules' and xtype='U')
                        CREATE TABLE RoleModules (
                            Id INT IDENTITY(1,1) PRIMARY KEY,
                            RoleId INT NOT NULL,
                            ModuleId INT NOT NULL,
                            CONSTRAINT UQ_RoleModules_Role_Module UNIQUE (RoleId, ModuleId)
                        )
                    `);
                    await db.query(`
                        IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Users' and xtype='U')
                        CREATE TABLE Users (
                            Id INT IDENTITY(1,1) PRIMARY KEY,
                            Username NVARCHAR(50) NOT NULL UNIQUE,
                            PasswordHash NVARCHAR(255) NOT NULL,
                            FullName NVARCHAR(100) NOT NULL,
                            Email NVARCHAR(100) NULL,
                            RoleId INT NULL,
                            IsActive BIT DEFAULT 1,
                            CreatedAt DATETIME DEFAULT GETDATE(),
                            UpdatedAt DATETIME NULL,
                            LastLogin DATETIME NULL,
                            Permissions NVARCHAR(MAX) NULL,
                            IsReadonly BIT DEFAULT 0,
                            IsHidden BIT DEFAULT 0,
                            PlainPassword NVARCHAR(255) NULL
                        )
                    `);

                    // Alter table to add columns if they don't exist
                    const checkCols = [
                        ['Permissions', 'NVARCHAR(MAX) NULL'],
                        ['IsReadonly', 'BIT DEFAULT 0'],
                        ['IsHidden', 'BIT DEFAULT 0'],
                        ['PlainPassword', 'NVARCHAR(255) NULL'],
                        ['CasesRole', 'NVARCHAR(50) NULL']
                    ];
                    for (const [colName, colType] of checkCols) {
                        await db.query(`
                            IF NOT EXISTS (
                                SELECT * FROM sys.columns 
                                WHERE Name = N'${colName}' AND Object_ID = Object_ID(N'Users')
                            )
                            ALTER TABLE Users ADD ${colName} ${colType};
                        `);
                    }

                    // Seeding default users
                    // ======================================================
                    // أدوار القضايا (CasesRole):
                    //   IT    = كل شيء بلا قيود
                    //   Admin = كل شيء عدا حذف في logs والأرشيف (readonly)
                    //   User  = بدون logs, archive, users
                    //   CEO   = readonly + مخفي في سجل الحركات
                    // ======================================================
                    const defaultUsers = [
                        {
                            username: 'IT',
                            fullName: 'مسؤول تقنية المعلومات',
                            password: 'it1234',
                            casesRole: 'IT',
                            permissions: ['dashboard', 'new-case', 'cases', 'litigation-level', 'appeals-tracking', 'sessions', 'session-details', 'calendar', 'lawyers', 'courts', 'reports', 'reports-hub', 'archive', 'users'],
                            isHidden: 0,
                            isReadonly: 0
                        },
                        {
                            username: 'admin',
                            fullName: 'مدير النظام',
                            password: '4444',
                            casesRole: 'Admin',
                            permissions: ['dashboard', 'new-case', 'cases', 'litigation-level', 'appeals-tracking', 'sessions', 'session-details', 'calendar', 'lawyers', 'courts', 'reports', 'reports-hub', 'archive', 'users'],
                            isHidden: 0,
                            isReadonly: 0
                        },
                        {
                            username: 'CEO',
                            fullName: 'م/سامي قنديل',
                            password: 'Asdc0',
                            casesRole: 'CEO',
                            permissions: ['dashboard', 'new-case', 'cases', 'litigation-level', 'appeals-tracking', 'sessions', 'session-details', 'calendar', 'lawyers', 'courts', 'reports-hub'],
                            isHidden: 1,
                            isReadonly: 1
                        },
                        {
                            username: 'sessions',
                            fullName: 'مسؤول الجلسات',
                            password: '1234',
                            casesRole: 'User',
                            permissions: ['sessions', 'session-details', 'calendar'],
                            isHidden: 0,
                            isReadonly: 0
                        },
                        {
                            username: 'reports',
                            fullName: 'مسؤول التقارير',
                            password: '1234',
                            casesRole: 'User',
                            permissions: ['dashboard', 'new-case', 'cases', 'litigation-level', 'appeals-tracking', 'sessions', 'session-details', 'calendar', 'lawyers', 'courts', 'reports-hub'],
                            isHidden: 0,
                            isReadonly: 0
                        }
                    ];

                    for (const u of defaultUsers) {
                        const exists = await db.query('SELECT Id, Permissions FROM Users WHERE Username = @p0', [u.username]);
                        if (exists.length === 0) {
                            const hash = await bcrypt.hash(u.password, 10);
                            await db.query(
                                `INSERT INTO Users (Username, PasswordHash, FullName, Permissions, IsReadonly, IsHidden, PlainPassword, CasesRole, IsActive, CreatedAt)
                                 VALUES (@p0, @p1, @p2, @p3, @p4, @p5, @p6, @p7, 1, GETDATE())`,
                                [u.username, hash, u.fullName, JSON.stringify(u.permissions), u.isReadonly, u.isHidden, u.password, u.casesRole || null]
                            );
                            console.log(`✅ Seeded user: ${u.username}`);
                        } else {
                            // ⚠️ مهم: لا نستبدل صلاحيات موجودة بالفعل — عشان تعديلات الأدمن اليدوية
                            // من شاشة access.html ما تُمسحش في كل مرة السيرفر بيعمل restart.
                            // بنملأ القيم الافتراضية فقط لو لسه فاضية (أول تشغيل / ترقية قديمة).
                            const row = exists[0];
                            if (row.Permissions === null || row.Permissions === undefined || row.Permissions === '') {
                                await db.query(
                                    `UPDATE Users 
                                     SET Permissions = @p0, IsReadonly = @p1, IsHidden = @p2, PlainPassword = @p3, CasesRole = @p4
                                     WHERE Username = @p5`,
                                    [JSON.stringify(u.permissions), u.isReadonly, u.isHidden, u.password, u.casesRole || null, u.username]
                                );
                                console.log(`✅ تم تعيين الصلاحيات الافتراضية لأول مرة لليوزر: ${u.username}`);
                            } else {
                                console.log(`ℹ️ تم تجاوز اليوزر ${u.username} — عنده صلاحيات محفوظة بالفعل ولن تُستبدل.`);
                            }
                        }
                    }

                    // 4) أول يوزر أدمن تحقيقات افتراضي (بنفس بيانات يوزر 'inv' القديم عشان الاستمرارية)
                    const adminRoleRows = await db.query("SELECT Id FROM Roles WHERE Name = 'InvestigationAdmin'");
                    if (adminRoleRows.length > 0) {
                        const existingInv = await db.query('SELECT Id FROM Users WHERE Username = @p0', ['inv']);
                        if (existingInv.length === 0) {
                            const defaultHash = await bcrypt.hash('inv123', 10);
                            await db.query(
                                `INSERT INTO Users (Username, PasswordHash, FullName, RoleId, IsActive, IsHidden, PlainPassword, CreatedAt)
                                 VALUES (@p0, @p1, @p2, @p3, 1, 1, @p4, GETDATE())`,
                                ['inv', defaultHash, 'المحقق الرئيسي', adminRoleRows[0].Id, 'inv123']
                            );
                            console.log('✅ تم إنشاء يوزر أدمن التحقيقات الافتراضي: inv / inv123');
                        } else {
                            await db.query(
                                `UPDATE Users SET IsHidden = 1, PlainPassword = @p0 WHERE Username = 'inv' AND (IsHidden = 0 OR PlainPassword IS NULL)`,
                                ['inv123']
                            );
                        }
                    }

                    console.log('✅ تم التأكد من نظام صلاحيات التحقيقات (Users/Roles/Modules).');

                    // إنشاء جدول إشعارات التحقيقات إذا لم يكن موجوداً
                    await db.query(`
                        IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='InvestigationNotifications' and xtype='U')
                        CREATE TABLE InvestigationNotifications (
                            Id INT IDENTITY(1,1) PRIMARY KEY,
                            UserId INT NOT NULL,
                            Title NVARCHAR(255) NOT NULL,
                            Message NVARCHAR(1000) NULL,
                            NotifType NVARCHAR(50) NULL,
                            EntityId INT NULL,
                            EntityUrl NVARCHAR(255) NULL,
                            IsRead BIT DEFAULT 0,
                            CreatedAt DATETIME DEFAULT GETDATE()
                        )
                    `);
                    console.log('✅ تم التأكد من جدول إشعارات التحقيقات.');
                    // ترقية الجدول: إضافة الأعمدة المفقودة في قواعد البيانات القديمة
                    const missingCols = [
                        ['NotifType', 'NVARCHAR(50) NULL'],
                        ['EntityId',  'INT NULL'],
                        ['EntityUrl', 'NVARCHAR(255) NULL']
                    ];
                    for (const [colName, colDef] of missingCols) {
                        try {
                            await db.query(`
                                IF NOT EXISTS (
                                    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
                                    WHERE TABLE_NAME='InvestigationNotifications' AND COLUMN_NAME=@p0
                                )
                                ALTER TABLE InvestigationNotifications ADD ${colName} ${colDef}
                            `, [colName]);
                        } catch (alterErr) {
                            console.log('⚠️ Column migration ' + colName + ':', alterErr.message);
                        }
                    }

                    // ✅ إضافة عمود أقوال الموظفين لجدول InvestigationEmployees
                    try {
                        await db.query(`
                            IF NOT EXISTS (
                                SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
                                WHERE TABLE_NAME='InvestigationEmployees' AND COLUMN_NAME='EmployeeStatement'
                            )
                            ALTER TABLE InvestigationEmployees ADD EmployeeStatement NVARCHAR(MAX) NULL
                        `);
                        console.log('✅ تم التأكد من عمود أقوال الموظفين.');
                    } catch (empStmtErr) {
                        console.log('⚠️ EmployeeStatement migration:', empStmtErr.message);
                    }

                    // ✅ إضافة أعمدة LitigationLevelId و SessionCaseNumber لجدول Sessions
                    try {
                        await db.query(`
                            IF NOT EXISTS (
                                SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
                                WHERE TABLE_NAME='Sessions' AND COLUMN_NAME='LitigationLevelId'
                            )
                            ALTER TABLE Sessions ADD LitigationLevelId INT NULL
                        `);
                        console.log('✅ تم التأكد من عمود LitigationLevelId في جدول Sessions.');
                    } catch (litLevelErr) {
                        console.log('⚠️ LitigationLevelId migration:', litLevelErr.message);
                    }

                    try {
                        await db.query(`
                            IF NOT EXISTS (
                                SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
                                WHERE TABLE_NAME='Sessions' AND COLUMN_NAME='SessionCaseNumber'
                            )
                            ALTER TABLE Sessions ADD SessionCaseNumber NVARCHAR(100) NULL
                        `);
                        console.log('✅ تم التأكد من عمود SessionCaseNumber في جدول Sessions.');
                    } catch (sessNumErr) {
                        console.log('⚠️ SessionCaseNumber migration:', sessNumErr.message);
                    }

                    // ✅ إضافة عمود ClaimAmount (القيمة المادية للدعوى) لكل من Cases و LitigationLevels و Sessions
                    for (const tbl of ['Cases', 'LitigationLevels', 'Sessions']) {
                        try {
                            await db.query(`
                                IF NOT EXISTS (
                                    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
                                    WHERE TABLE_NAME='${tbl}' AND COLUMN_NAME='ClaimAmount'
                                )
                                ALTER TABLE ${tbl} ADD ClaimAmount NVARCHAR(255) NULL
                            `);
                            console.log(`✅ تم التأكد من عمود ClaimAmount في جدول ${tbl}.`);
                        } catch (claimErr) {
                            console.log(`⚠️ ClaimAmount migration for ${tbl}:`, claimErr.message);
                        }
                    }

                    // ✅ إضافة عمود LawsuitExpenses (يُستخدم الآن لتخزين "قيمة الحكم") لجدول Sessions
                    try {
                        await db.query(`
                            IF NOT EXISTS (
                                SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
                                WHERE TABLE_NAME='Sessions' AND COLUMN_NAME='LawsuitExpenses'
                            )
                            ALTER TABLE Sessions ADD LawsuitExpenses NVARCHAR(255) NULL
                        `);
                        console.log('✅ تم التأكد من عمود LawsuitExpenses (قيمة الحكم) في جدول Sessions.');
                    } catch (judgmentErr) {
                        console.log('⚠️ LawsuitExpenses (Sessions) migration:', judgmentErr.message);
                    }

                    // ✅ إضافة أعمدة الأطراف (FirstPartyType, FiledBy, Plaintiff, Defendant) لجدول Cases
                    for (const col of [
                        { name: 'FirstPartyType', type: 'NVARCHAR(50) NULL' },
                        { name: 'FiledBy', type: 'NVARCHAR(50) NULL' },
                        { name: 'Plaintiff', type: 'NVARCHAR(MAX) NULL' },
                        { name: 'Defendant', type: 'NVARCHAR(MAX) NULL' }
                    ]) {
                        try {
                            await db.query(`
                                IF NOT EXISTS (
                                    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
                                    WHERE TABLE_NAME='Cases' AND COLUMN_NAME='${col.name}'
                                )
                                ALTER TABLE Cases ADD ${col.name} ${col.type}
                            `);
                        } catch (colErr) {
                            console.log(`⚠️ Party column migration ${col.name}:`, colErr.message);
                        }
                    }

                    // ✅ إضافة عمود CaseExpenses (مصاريف الدعوة تُدخَل عند إغلاق القضية) لجدول Cases
                    try {
                        await db.query(`
                            IF NOT EXISTS (
                                SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
                                WHERE TABLE_NAME='Cases' AND COLUMN_NAME='CaseExpenses'
                            )
                            ALTER TABLE Cases ADD CaseExpenses NVARCHAR(255) NULL
                        `);
                        console.log('✅ تم التأكد من عمود CaseExpenses (مصاريف الدعوة) في جدول Cases.');
                    } catch (expensesErr) {
                        console.log('⚠️ CaseExpenses (Cases) migration:', expensesErr.message);
                    }

                    // ✅ إضافة أعمدة (Subject, RequestedByOpponent, Plaintiff, Defendant) لجدول LitigationLevels
                    // Plaintiff/Defendant هنا تسمح لكل درجة تقاضي (استئناف/نقض...) بتخزين طرفيها
                    // بشكل مستقل عن القضية الأم، بحيث لو اتبدل المدعى/المدعى عليه لدرجة معينة
                    // يفضل محفوظ ومنعكس في الجدول وصفحة القضايا.
                    for (const col of [
                        { name: 'Subject', type: 'NVARCHAR(MAX) NULL' },
                        { name: 'RequestedByOpponent', type: 'NVARCHAR(255) NULL' },
                        { name: 'Plaintiff', type: 'NVARCHAR(MAX) NULL' },
                        { name: 'Defendant', type: 'NVARCHAR(MAX) NULL' }
                    ]) {
                        try {
                            await db.query(`
                                IF NOT EXISTS (
                                    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
                                    WHERE TABLE_NAME='LitigationLevels' AND COLUMN_NAME='${col.name}'
                                )
                                ALTER TABLE LitigationLevels ADD ${col.name} ${col.type}
                            `);
                            console.log(`✅ تم التأكد من عمود ${col.name} في جدول LitigationLevels.`);
                        } catch (colErr) {
                            console.log(`⚠️ Column migration ${col.name} for LitigationLevels:`, colErr.message);
                        }
                    }

                    // ✅ إضافة عمود ReceiptDate لجدول Investigations
                    try {
                        await db.query(`
                            IF NOT EXISTS (
                                SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
                                WHERE TABLE_NAME='Investigations' AND COLUMN_NAME='ReceiptDate'
                            )
                            ALTER TABLE Investigations ADD ReceiptDate DATE NULL
                        `);
                        console.log('✅ تم التأكد من عمود ReceiptDate في جدول Investigations.');
                    } catch (recDateErr) {
                        console.log('⚠️ ReceiptDate (Investigations) migration:', recDateErr.message);
                    }

                    // ✅ إضافة عمود القيمة المادية للتحقيق
                    try {
                        await db.query(`
                            IF NOT EXISTS (
                                SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
                                WHERE TABLE_NAME='Investigations' AND COLUMN_NAME='MaterialValue'
                            )
                            ALTER TABLE Investigations ADD MaterialValue DECIMAL(18,2) NULL
                        `);
                        console.log('✅ تم التأكد من عمود MaterialValue في جدول Investigations.');
                    } catch (matValErr) {
                        console.log('⚠️ MaterialValue (Investigations) migration:', matValErr.message);
                    }
                    
                } catch (rbacErr) {
                    console.log('⚠️ ملاحظة: لم يتم التحقق من نظام صلاحيات التحقيقات:', rbacErr.message);
                }
            } catch (err) {
                console.log('⚠️ ملاحظة: لم يتم التحقق من جدول الأرشيف/سجل التتبعات:', err.message);
            }
        })
        .then(() => ensureWideTextColumns())
        .catch(err => console.error('❌ فشل الاتصال بقاعدة البيانات:', err.message));
});

module.exports = app;