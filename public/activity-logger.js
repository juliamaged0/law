// ============================================================
// activity-logger.js
// نظام تتبع الإجراءات المشترك — يُضاف بـ <script> في كل صفحات النظام
// ============================================================
// ماذا يفعل هذا الملف؟
// 1) يعترض (intercept) كل نداءات fetch() الموجهة إلى /api/ ويرفق معها
//    اسم المستخدم الحالي (من localStorage) في هيدر X-Username تلقائياً،
//    حتى يقدر السيرفر يعرف "مين" نفّذ كل عملية إضافة/تعديل/حذف.
// 2) يوفر دالة window.logAction(action, description, page) لتسجيل
//    إجراءات لا تمر عبر السيرفر مباشرة (تسجيل دخول/خروج، عرض، طباعة، تصدير).
//
// طريقة الاستخدام: أضف هذا السطر قبل أي كود آخر في كل صفحة:
//   <script src="activity-logger.js"></script>
//
// ولتسجيل دخول المستخدم بعد نجاح تسجيل الدخول في صفحة اللوجين:
//   localStorage.setItem('username', theUsername);
//   window.logAction('login', `تسجيل دخول المستخدم: ${theUsername}`, 'تسجيل الدخول');
// ============================================================

(function () {
    'use strict';

    // اليوزرات دي مستثناة من تسجيل الدخول/الخروج في سجل التتبعات
    const EXCLUDED_FROM_LOGGING = ['CEO', 'inv'];

    function getCurrentUsername() {
        return localStorage.getItem('username') || 'زائر';
    }

    // ===== 1) اعتراض fetch لإرفاق اسم المستخدم تلقائياً مع كل طلب API =====
    const originalFetch = window.fetch.bind(window);

    window.fetch = function (input, init) {
    try {
        const url = typeof input === 'string' ? input : (input && input.url) || '';
        const isApiCall = url.includes('/api/');

        if (isApiCall) {
            init = init || {};
            const headers = new Headers(init.headers || {});
            headers.set('X-Username', getCurrentUsername());
            init.headers = headers;
        }
    } catch (e) {}
    return originalFetch(input, init);
};

    // ===== 2) تسجيل إجراء يدوي (دخول/خروج/عرض/طباعة/تصدير...) في سجل التتبعات =====
    window.logAction = function (action, description, page, category) {
        try {
            // حماية من التكرار: نفس إجراء الدخول/الخروج خلال 5 ثواني يتجاهل
            if (action === 'login' || action === 'logout') {
                const key = 'lastLog_' + action;
                const last = parseInt(sessionStorage.getItem(key) || '0', 10);
                if (Date.now() - last < 5000) return;
                sessionStorage.setItem(key, String(Date.now()));
            }
            let cat = category;
            if (!cat) {
                const username = getCurrentUsername().toLowerCase();
                const path = window.location.pathname.toLowerCase();
                const pName = String(page || document.title || '').toLowerCase();
                if (username === 'inv' || username.includes('inv') || path.includes('investigation') || pName.includes('investigation') || pName.includes('تحقيق')) {
                    cat = 'investigation';
                } else {
                    cat = 'cases';
                }
            }
            originalFetch('/api/logs', {
                method: 'POST',
                keepalive: true, // ✅ يضمن إرسال الطلب حتى لو الصفحة بتتنقل فوراً (مهم لحدث logout)
                headers: {
                    'Content-Type': 'application/json',
                    'X-Username': getCurrentUsername()
                },
                body: JSON.stringify({
                    action: action,
                    description: description || '',
                    page: page || document.title || 'غير معروف',
                    category: cat
                })
            }).catch(function (err) {
                console.log('⚠️ تعذر تسجيل التتبعة:', err.message);
            });
        } catch (e) {
            console.log('⚠️ تعذر تسجيل التتبعة:', e.message);
        }
    };

    // ===== 3) تسجيل الدخول =====
    // تم إلغاء التسجيل التلقائي من هنا: السيرفر بيسجل الدخول مرة واحدة فقط
    // داخل /api/auth/login، فتسجيله هنا كمان كان بيسبب تكرار.

    // ===== 4) دالة تُستدعى من sidebar.js عند الـ logout =====
    // بتسجل حدث الخروج (ما عدا اليوزرات المستثناة)، وبتمسح فلاج تسجيل الدخول
    // عشان لو دخل يوزر تاني في نفس التاب يتسجل login بتاعه بشكل صحيح.
    window.logLogoutAndClearFlag = function () {
        const username = getCurrentUsername();
        if (username !== 'زائر' && !EXCLUDED_FROM_LOGGING.includes(username)) {
            window.logAction('logout', `تسجيل خروج المستخدم: ${username}`, 'تسجيل الخروج');
        }
        sessionStorage.removeItem('loginLogged');
    };
})();