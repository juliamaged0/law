// sidebar.js - نظام القائمة الجانبية الموحد مع نظام الصلاحيات
// الشؤون القانونية - شركة الصرف الصحي بالإسكندرية
// ثيم: Navy & Gold Premium

(function() {
  'use strict';

  // متغيّر على مستوى الملف عشان initNotifications و initTodaySessions
  // يقدروا يوصلوا له برضو (مش بس initSidebar)
  let isInvPage = false;

  // ============================================================
  // جميع الصفحات المتاحة
  // ============================================================
  const ALL_PAGES = [
    { id: 'dashboard', label: 'لوحة التحكم', href: 'Dashboard.html', section: 'الرئيسية', icon: '⊞' },
    { id: 'cases', label: 'جميع القضايا', href: 'Cases.html', section: 'الرئيسية', icon: '◫' },
    { id: 'calendar', label: 'النتيجة', href: 'calender.html', section: 'الرئيسية', icon: '◱' },
    { id: 'appeals-tracking', label: 'متابعة الدعاوى والأحكام', href: 'cases2.html', section: 'الرئيسية', icon: '◈' },
    { id: 'new-case', label: 'قضية جديدة', href: 'new_case.html', section: 'إدارة القضايا', icon: '＋' },
    { id: 'litigation-level', label: 'درجات التقاضي', href: 'litigation-level.html', section: 'إدارة القضايا', icon: '⇧' },
    { id: 'sessions', label: 'الجلسات', href: 'sessions.html', section: 'إدارة القضايا', icon: '◷' },
    { id: 'lawyers', label: 'المحامون', href: 'lawyers.html', section: 'الموارد البشرية', icon: '◉' },
    { id: 'courts', label: 'المحاكم والدوائر', href: 'courts.html', section: 'الموارد البشرية', icon: '◧' },
    { id: 'reports-hub', label: 'تقارير', href: 'reports.html', section: 'التقارير', icon: '📄' },
    { id: 'reports', label: ' الحركات', href: 'logs.html', section: 'التقارير', icon: '◻' },
    { id: 'archive', label: 'الأرشيف', href: 'archive.html', section: 'التقارير', icon: '▣' },
    { id: 'users', label: 'المستخدمون', href: 'access.html', section: 'الإعدادات', icon: '◍' },
    { id: 'investigations-dashboard', label: 'لوحة التحقيقات', href: 'investigations_dashboard.html', section: 'التحقيقات', icon: '🔍' },
    { id: 'new-investigation', label: 'تحقيق جديد', href: 'new_investigation.html', section: 'التحقيقات', icon: '➕' },
    { id: 'investigation-details', label: 'متابعة التحقيقات', href: 'investigation_details.html', section: 'التحقيقات', icon: '📋' },
    { id: 'investigation-reports', label: 'تقارير التحقيقات', href: 'investigation_reports.html', section: 'التحقيقات', icon: '📊' },
    { id: 'investigation-archive', label: 'أرشيف التحقيقات', href: 'investigation_archive.html', section: 'التحقيقات', icon: '▣' },
    { id: 'investigation-logs', label: 'سجل تتبعات التحقيقات', href: 'investigation_logs.html', section: 'التحقيقات', icon: '🕘' },
    { id: 'investigation-users', label: 'مستخدمو التحقيقات', href: 'investigation_access.html', section: 'التحقيقات', icon: '◍' }
  ];

  // ============================================================
  // 1. نظام الصلاحيات
  // ============================================================

  function getCasesRole() {
    return localStorage.getItem('casesRole') || null;
  }

  function getUserRole() {
    const username = getUsername();
    if (username === 'inv') return 'investigator';
    const casesRole = getCasesRole();
    if (casesRole) return casesRole.toLowerCase(); // 'it', 'admin', 'ceo', 'user'
    if (username === 'admin') return 'admin';
    if (username === 'CEO') return 'ceo';
    return localStorage.getItem('userRole') || null;
  }

  function getUsername() {
    return localStorage.getItem('username') || 'زائر';
  }

  function getUserPermissions() {
    const username = getUsername();
    const role = localStorage.getItem('userRole') || '';
    const casesRole = getCasesRole() || '';
    const isInvUser = username === 'inv' || role.startsWith('Investigation');

    try {
        const data = localStorage.getItem('userPermissions');
        if (data) {
            let parsed = JSON.parse(data);
            if (Array.isArray(parsed) && parsed.length > 0) {
                if (isInvUser && !parsed.includes('investigation-reports')) {
                    parsed.push('investigation-reports');
                    localStorage.setItem('userPermissions', JSON.stringify(parsed));
                }
                return parsed;
            }
        }
    } catch (e) {}

    // صلاحيات يوزرز التحقيقات حسب الدور
    if (username === 'inv') {
      return ['investigations-dashboard', 'new-investigation', 'investigation-details', 'investigation-reports', 'investigation-archive', 'investigation-logs', 'investigation-users'];
    }
    if (role === 'InvestigationAdmin') {
      return ['investigations-dashboard', 'new-investigation', 'investigation-details', 'investigation-reports', 'investigation-archive', 'investigation-logs', 'investigation-users'];
    }
    if (role === 'InvestigationUser' || role === 'InvestigationDataEntry') {
      return ['investigations-dashboard', 'new-investigation', 'investigation-details', 'investigation-reports', 'investigation-archive', 'investigation-logs'];
    }
    if (role === 'InvestigationViewer') {
      return ['investigations-dashboard', 'investigation-details', 'investigation-reports'];
    }
    if (isInvUser) {
      return ['investigations-dashboard', 'new-investigation', 'investigation-details', 'investigation-reports', 'investigation-archive', 'investigation-logs'];
    }

    // صلاحيات يوزرز القضايا
    if (username === 'admin' || casesRole === 'Admin') {
      return ALL_PAGES.filter(p => p.section !== 'التحقيقات').map(p => p.id);
    }

    return [];
}

async function refreshUserPermissions() {
    const username = getUsername();
    if (!username || username === 'زائر') {
        return [];
    }

    try {
        const role = localStorage.getItem('userRole') || '';
        const isInvUser = username === 'inv' || role.startsWith('Investigation');

        const endpoint = isInvUser ? '/api/investigation-users' : '/api/users';
        const response = await fetch(endpoint);
        const result = await response.json();
        
        if (result.success) {
            const user = result.data.find(u => (u.username || u.Username) === username);
            if (user) {
                let perms = [];
                if (user.permissions) {
                    perms = user.permissions;
                } else if (user.RoleName) {
                    const roleMap = {
                        'InvestigationAdmin': ['investigations-dashboard', 'new-investigation', 'investigation-details', 'investigation-reports', 'investigation-archive', 'investigation-logs', 'investigation-users'],
                        'InvestigationUser': ['investigations-dashboard', 'new-investigation', 'investigation-details', 'investigation-reports', 'investigation-archive', 'investigation-logs'],
                        'InvestigationDataEntry': ['investigations-dashboard', 'new-investigation', 'investigation-details', 'investigation-reports', 'investigation-archive', 'investigation-logs'],
                        'InvestigationViewer': ['investigations-dashboard', 'investigation-details', 'investigation-reports']
                    };
                    perms = roleMap[user.RoleName] || [];
                }
                
                if (perms.length > 0) {
                    localStorage.setItem('userPermissions', JSON.stringify(perms));
                }
                if (user.casesRole || user.RoleName) {
                    localStorage.setItem('casesRole', user.casesRole || user.RoleName);
                    localStorage.setItem('userRole', user.RoleName || user.casesRole);
                }
                console.log(`✅ تم تحديث صلاحيات المستخدم ${username}:`, perms);
                return perms;
            }
        }
    } catch (e) {
        console.warn('⚠️ تعذر تحديث الصلاحيات من الخادم:', e.message);
    }
    
    return getUserPermissions();
}

  // ===== هل الصفحة الحالية محظورة للـ Admin (readonly فقط)؟ =====
  // Admin: الأرشيف والحركات للعرض فقط بدون حذف أو تعديل
  function isAdminReadonlyPage() {
    const role = getCasesRole();
    if (role !== 'Admin') return false;
    const page = window.location.pathname.split('/').pop();
    return page === 'logs.html' || page === 'archive.html';
  }

  // ===== هل المستخدم الحالي له دور IT في القضايا؟ =====
  function isCasesIT() { return getCasesRole() === 'IT'; }
  function isCasesAdmin() { return getCasesRole() === 'Admin'; }
  function isCasesCEO() { return getCasesRole() === 'CEO' || getUsername() === 'CEO'; }

  // ===== تعيين الـ readonly badge وحماية الصفحة حسب الدور =====
  function applyCasesRoleRestrictions() {
    const role = getCasesRole();
    const page = window.location.pathname.split('/').pop();

    // CEO: readonly على كل شيء
    if (role === 'CEO') {
      document.querySelectorAll('button:not(.logout-btn):not(.sb-close):not([data-allow-ceo])').forEach(btn => {
        if (!btn.closest('.sidebar') && !btn.closest('.topbar')) {
          btn.disabled = true;
          btn.style.opacity = '0.45';
          btn.style.cursor = 'not-allowed';
          btn.title = 'القراءة فقط — لا يمكن التعديل';
        }
      });
      document.querySelectorAll('input:not([type=search]):not([type=date]):not([type=text][readonly]), select, textarea').forEach(el => {
        if (!el.closest('.sidebar') && !el.closest('.topbar') && !el.closest('.filters-group')) {
          el.disabled = true;
        }
      });
      // إظهار شريط readonly
      showReadonlyBanner('🔒 وضع القراءة فقط — المدير التنفيذي');
    }

    // Admin: readonly للأرشيف وصفحة الحركات (إخفاء زرار المسح فقط)
    if (role === 'Admin' && (page === 'logs.html' || page === 'archive.html')) {
      document.querySelectorAll('.btn-danger, [data-action=delete], [onclick*="clear"], [onclick*="Clear"], [onclick*="مسح"]').forEach(btn => {
        btn.style.display = 'none';
      });
      showReadonlyBanner('👁️ عرض فقط — لا يمكن الحذف أو المسح');
    }
  }

  function showReadonlyBanner(msg) {
    let banner = document.getElementById('casesRoleBanner');
    if (!banner) {
      banner = document.createElement('div');
      banner.id = 'casesRoleBanner';
      banner.style.cssText = 'position:fixed;top:0;left:0;right:0;z-index:9999;background:linear-gradient(135deg,#0f172a,#1e3a5f);color:#fff;text-align:center;padding:8px 16px;font-family:Tajawal,sans-serif;font-size:13px;font-weight:700;letter-spacing:0.3px;box-shadow:0 2px 8px rgba(0,0,0,0.3);';
      document.body.prepend(banner);
      document.body.style.paddingTop = '36px';
    }
    banner.textContent = msg;
  }

  function checkPageAccess() {
    const currentPage = window.location.pathname.split('/').pop();
    
    if (currentPage === 'index.html' || currentPage === '' || currentPage === 'login.html') {
      return true;
    }

    const permissions = getUserPermissions();
    
    if (!localStorage.getItem('username')) {
      window.location.href = 'index.html';
      return false;
    }

    const pageInfo = ALL_PAGES.find(p => p.href === currentPage);
    if (!pageInfo) return true;

    // الفصل التام بين التحقيقات والقضايا لمنع الدخول اليدوي
    const username = getUsername();
    const role = localStorage.getItem('userRole') || '';
    const isInvUser = username === 'inv' || role.startsWith('Investigation');

    if (isInvUser && pageInfo.section !== 'التحقيقات') {
      alert('⛔ غير مصرح لك بدخول صفحات القضايا.');
      window.location.href = 'investigations_dashboard.html';
      return false;
    }
    if (!isInvUser && pageInfo.section === 'التحقيقات') {
      alert('⛔ غير مصرح لك بدخول صفحات التحقيقات.');
      window.location.href = 'Dashboard.html';
      return false;
    }

    if (!permissions.includes(pageInfo.id)) {
      alert('⛔ غير مصرح لك بدخول هذه الصفحة.');
      if (permissions.length > 0) {
        const firstPage = ALL_PAGES.find(p => p.id === permissions[0]);
        if (firstPage) {
          window.location.href = firstPage.href;
        } else {
          window.location.href = 'index.html';
        }
      } else {
        window.location.href = 'index.html';
      }
      return false;
    }

    return true;
  }

  function isReadonlyUser() {
    try {
      const data = localStorage.getItem('userReadonly');
      if (data) return JSON.parse(data);
    } catch (e) {}
    return false;
  }

  // ============================================================
  // 2. الحصول على روابط القائمة حسب الصلاحيات
  // ============================================================
  function getSidebarLinks() {
    const permissions = getUserPermissions();
    
    if (permissions.length === 0) {
      return [];
    }

    let links = ALL_PAGES.filter(page => permissions.includes(page.id) && !page.hidden);

    // الفصل التام في القائمة الجانبية بين القضايا والتحقيقات
    const username = getUsername();
    const role = localStorage.getItem('userRole') || '';
    const isInvUser = username === 'inv' || role.startsWith('Investigation');

    if (isInvUser) {
      links = links.filter(page => page.section === 'التحقيقات');
      if (!links.some(l => l.id === 'investigation-reports')) {
        const repPage = ALL_PAGES.find(p => p.id === 'investigation-reports');
        if (repPage) {
          const idx = links.findIndex(l => l.id === 'investigation-details');
          if (idx !== -1) {
            links.splice(idx + 1, 0, repPage);
          } else {
            links.push(repPage);
          }
        }
      }
    } else {
      links = links.filter(page => page.section !== 'التحقيقات');
    }

    return links;
  }

  // ============================================================
  // 3. العناصر المحمية
  // ============================================================
  const PROTECTED_ELEMENTS = [
    'mizanSmartModal',
    'deleteConfirmationBox',
    'toastHub'
  ];

  // ============================================================
  // 4. هيكل القائمة الجانبية
  // ============================================================
  function buildSidebarHTML() {
    const username = getUsername();
    const initial = username.charAt(0).toUpperCase();
    const permissions = getUserPermissions();
    const invRole = localStorage.getItem('userRole') || '';
    const isInv = username === 'inv' || invRole.startsWith('Investigation') || (permissions.includes('investigations-dashboard') && !permissions.includes('dashboard'));
    const isCEO = username === 'CEO';

    const INV_ROLE_LABELS = {
      'InvestigationAdmin': '👑 أدمن التحقيقات',
      'InvestigationDataEntry': '✍️ مدخل بيانات',
      'InvestigationViewer': '👁️ مشاهد'
    };
    const CASES_ROLE_LABELS = {
      'IT': '🛡️ مسؤول تقنية المعلومات',
      'Admin': '👑 مدير النظام',
      'CEO': '👔 المدير التنفيذي',
      'User': '👤 مستخدم'
    };
    const casesRole = getCasesRole();

    let roleDisplay = '👑 مسؤول النظام';
    if (isInv && INV_ROLE_LABELS[invRole]) roleDisplay = INV_ROLE_LABELS[invRole];
    else if (isInv) roleDisplay = '🔍 محقق';
    else if (casesRole && CASES_ROLE_LABELS[casesRole]) roleDisplay = CASES_ROLE_LABELS[casesRole];
    else if (isCEO) roleDisplay = '👔 المدير التنفيذي';

    return `
    <aside class="sidebar" id="sidebar">
    <div class="sidebar-header">
      <div class="sb-logo">
        <div class="sb-logo-icon">
          <svg viewBox="0 0 24 24" fill="none" width="20" height="20">
            <path d="M12 2L3 7v4c0 5.5 3.8 10.7 9 12 5.2-1.3 9-6.5 9-12V7L12 2z" fill="white" opacity="0.9"/>
            <path d="M9 12l2 2 4-4" stroke="#D4AF37" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>
          </svg>
        </div>
        <div>
          <div class="sb-title">${isInv ? 'التحقيقات' : 'الشؤون القانونية'}</div>
          <div class="sb-sub">${isInv ? 'قسم التحقيقات · الإسكندرية' : 'الصرف الصحي · الإسكندرية'}</div>
        </div>
      </div>
      <button class="sb-close" onclick="toggleSidebar()" aria-label="إغلاق">✕</button>
    </div>

    <nav class="sb-nav" id="sidebarNav"></nav>

    <div class="sb-footer-container" style="flex-shrink:0;border-top:1px solid rgba(255,255,255,0.08);background:rgba(0,0,0,0.15);">
      <div class="sb-change-pwd-wrapper" style="padding:10px 14px 4px;">
        <button type="button" onclick="openChangePasswordModal(event)" class="sb-change-pwd-btn" style="width:100%;display:flex;align-items:center;justify-content:center;gap:8px;background:rgba(212,175,55,0.12);color:#F2DC8A;border:1px solid rgba(212,175,55,0.3);border-radius:9px;padding:7.5px 12px;font-size:12.5px;font-family:'Cairo',sans-serif;font-weight:700;cursor:pointer;transition:all 0.2s;" onmouseover="this.style.background='rgba(212,175,55,0.22)';this.style.borderColor='#D4AF37';this.style.color='#FFFFFF';" onmouseout="this.style.background='rgba(212,175,55,0.12)';this.style.borderColor='rgba(212,175,55,0.3)';this.style.color='#F2DC8A';">
          <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="flex-shrink:0;"><path d="M21 2l-2 2m-1.5 1.5L14 9a5 5 0 1 0 3 3l3.5-3.5 1.5 1.5 2-2-3-3z"/></svg>
          <span>تغيير كلمة المرور</span>
        </button>
      </div>

      <div class="sb-footer" style="border-top:none;padding-top:6px;">
        <div class="sb-user">
          <div class="sb-avatar">${initial}</div>
          <div>
            <div class="sb-uname">${username}</div>
            <div class="sb-urole">${roleDisplay}</div>
          </div>
        </div>
        <div style="display:flex;align-items:center;gap:12px;">
          <a href="#" class="sb-profile" onclick="openChangePasswordModal(event)" title="تغيير كلمة المرور" style="color:rgba(212,175,55,0.7);font-size:15px;text-decoration:none;transition:var(--transition);line-height:1;cursor:pointer;display:flex;align-items:center;"><svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 2l-2 2m-1.5 1.5L14 9a5 5 0 1 0 3 3l3.5-3.5 1.5 1.5 2-2-3-3z"/></svg></a>
          <a href="#" class="sb-logout" onclick="openLogoutModal()" title="تسجيل الخروج">⏻</a>
        </div>
      </div>
    </div>
    </aside>
    <div class="overlay" id="overlay" onclick="toggleSidebar()"></div>
    `;
  }

  // ============================================================
  // 5. بناء الروابط في القائمة الجانبية
  // ============================================================
  function buildNavLinks(activePage) {
    const nav = document.getElementById('sidebarNav');
    if (!nav) return;

    const links = getSidebarLinks();

    let currentSection = '';
    let html = '';

    links.forEach(link => {
      if (link.section !== currentSection) {
        currentSection = link.section;
        html += `<div class="sb-section-label">${currentSection}</div>`;
      }
      const activeClass = link.id === activePage ? 'active' : '';
      html += `
        <a href="${link.href}" class="sb-link ${activeClass}" data-page="${link.id}">
          <span class="sb-icon">${link.icon}</span> ${link.label}
        </a>
      `;
    });

    nav.innerHTML = html || '<div style="padding:20px;color:rgba(255,255,255,0.3);text-align:center;">لا توجد صلاحيات</div>';
  }

  // ============================================================
  // 6. CSS الثابت
  // ============================================================
  const SIDEBAR_CSS = `
  @import url('https://fonts.googleapis.com/css2?family=Cairo:wght@300;400;500;600;700;800;900&family=Tajawal:wght@400;500;700;800&display=swap');

  :root {
    --navy-900: #0a1628;
    --navy-800: #0f2240;
    --navy-700: #1a3a5c;
    --navy-600: #1e4976;
    --navy-500: #2563a8;
    --gold-500: #D4AF37;
    --gold-400: #E8C84A;
    --gold-300: #F2DC8A;
    --gold-100: #FDF8E8;
    --bg-page: #F4F6FA;
    --surface: #FFFFFF;
    --surface-2: #F8FAFD;
    --border: #E4EAF2;
    --border-strong: #C8D4E3;
    --green-600: #059669;
    --green-50: #ECFDF5;
    --green-100: #D1FAE5;
    --red-600: #DC2626;
    --red-50: #FEF2F2;
    --amber-600: #D97706;
    --amber-50: #FFFBEB;
    --blue-600: #2563EB;
    --blue-50: #EFF6FF;
    --purple-600: #7C3AED;
    --purple-50: #F5F3FF;
    --text-primary: #0F172A;
    --text-secondary: #475569;
    --text-muted: #94A3B8;
    --shadow-xs: 0 1px 3px rgba(10,22,40,0.06);
    --shadow-sm: 0 4px 12px rgba(10,22,40,0.07);
    --shadow-md: 0 8px 24px rgba(10,22,40,0.09);
    --shadow-lg: 0 16px 40px rgba(10,22,40,0.12);
    --radius-sm: 8px;
    --radius-md: 12px;
    --radius-lg: 16px;
    --radius-xl: 20px;
    --transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
  }

  *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

  html, body {
    height: 100%;
    font-family: 'Cairo', 'Tajawal', system-ui, sans-serif;
    direction: rtl;
    background: var(--bg-page);
    color: var(--text-primary);
  }

  body { display: block !important; }

  .dynamic-layout-wrapper {
    display: flex;
    flex-direction: row;
    min-height: 100vh;
    width: 100%;
  }

  .dynamic-main-content {
    flex: 1;
    min-width: 0;
    overflow-x: hidden;
    display: flex;
    flex-direction: column;
    background: var(--bg-page);
  }

  .custom-modern-topbar {
    display: flex;
    justify-content: space-between;
    align-items: center;
    background: var(--surface);
    padding: 0 28px;
    height: 64px;
    border-bottom: 1px solid var(--border);
    box-shadow: var(--shadow-xs);
    position: sticky;
    top: 0;
    z-index: 50;
    flex-shrink: 0;
  }

  .topbar-right-info {
    display: flex;
    flex-direction: column;
    gap: 2px;
  }

  .topbar-page-title {
    font-size: 17px;
    font-weight: 800;
    color: var(--navy-700);
    margin: 0;
    line-height: 1.2;
  }

  .topbar-breadcrumbs {
    font-size: 11.5px;
    color: var(--text-muted);
    margin: 0;
    font-weight: 500;
  }

  .topbar-left-actions {
    display: flex;
    align-items: center;
    gap: 12px;
  }

  .topbar-notif-btn {
    position: relative;
    width: 40px;
    height: 40px;
    border-radius: 50%;
    background: var(--surface-2);
    border: 1px solid var(--border);
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    font-size: 17px;
    transition: var(--transition);
  }

  .topbar-notif-btn:hover { background: var(--blue-50); border-color: var(--blue-600); }

  .topbar-notif-badge {
    position: absolute;
    top: -3px;
    right: -3px;
    background: var(--red-600);
    color: white;
    font-size: 9px;
    font-weight: 800;
    border-radius: 50%;
    width: 17px;
    height: 17px;
    display: flex;
    align-items: center;
    justify-content: center;
    border: 2px solid white;
  }

  .notif-dropdown {
    position: absolute;
    top: 50px;
    left: 0;
    width: 320px;
    background: white;
    border: 1px solid var(--border);
    border-radius: var(--radius-md);
    box-shadow: var(--shadow-lg);
    display: none;
    flex-direction: column;
    z-index: 1000;
    direction: rtl;
    text-align: right;
  }
  .notif-dropdown.show {
    display: flex;
  }
  .notif-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 12px 16px;
    border-bottom: 1px solid var(--border);
    font-weight: 700;
    color: var(--text-primary);
    font-size: 14px;
  }
  .notif-header-mark-all {
    color: var(--blue-600);
    cursor: pointer;
    font-size: 12px;
    transition: var(--transition);
  }
  .notif-header-mark-all:hover {
    text-decoration: underline;
  }
  .notif-list {
    max-height: 250px;
    overflow-y: auto;
  }
  .notif-item {
    padding: 12px 16px;
    border-bottom: 1px solid var(--surface-2);
    display: flex;
    flex-direction: column;
    gap: 4px;
    cursor: pointer;
    transition: var(--transition);
    text-decoration: none;
    color: inherit;
  }
  .notif-item:hover {
    background: var(--surface-2);
  }
  .notif-item.unread {
    background: var(--blue-50);
  }
  .notif-item-title {
    font-weight: 700;
    font-size: 13px;
    color: var(--text-primary);
  }
  .notif-item-msg {
    font-size: 12px;
    color: var(--text-secondary);
  }
  .notif-item-time {
    font-size: 10px;
    color: var(--text-muted);
  }
  .notif-empty {
    padding: 20px;
    text-align: center;
    color: var(--text-muted);
    font-size: 13px;
  }
  .today-session-item {
    display: flex;
    justify-content: space-between;
    align-items: center;
    gap: 8px;
  }
  .today-session-info {
    display: flex;
    flex-direction: column;
    gap: 2px;
  }
  .today-session-time {
    background: var(--blue-50);
    color: var(--blue-600);
    font-weight: 800;
    font-size: 11px;
    padding: 3px 8px;
    border-radius: 20px;
    white-space: nowrap;
    flex-shrink: 0;
  }

  .topbar-date-chip {
    background: var(--navy-800);
    color: var(--gold-300);
    padding: 7px 16px;
    border-radius: 20px;
    font-size: 12px;
    font-weight: 600;
    letter-spacing: 0.2px;
  }

  .topbar-hamburger {
    display: none;
    width: 40px;
    height: 40px;
    align-items: center;
    justify-content: center;
    background: none;
    border: 1px solid var(--border);
    border-radius: var(--radius-sm);
    font-size: 18px;
    cursor: pointer;
    color: var(--navy-700);
  }

  .sidebar {
    width: 256px;
    min-width: 256px;
    background: var(--navy-900);
    display: flex;
    flex-direction: column;
    position: sticky;
    top: 0;
    height: 100vh;
    overflow-y: auto;
    overflow-x: hidden;
    flex-shrink: 0;
    z-index: 200;
    scrollbar-width: thin;
    scrollbar-color: rgba(255,255,255,0.1) transparent;
  }

  .sidebar::-webkit-scrollbar { width: 4px; }
  .sidebar::-webkit-scrollbar-thumb { background: rgba(255,255,255,0.12); border-radius: 4px; }

  .sidebar-header {
    padding: 20px 16px 16px;
    border-bottom: 1px solid rgba(255,255,255,0.07);
    display: flex;
    align-items: center;
    justify-content: space-between;
    flex-shrink: 0;
  }

  .sb-logo {
    display: flex;
    align-items: center;
    gap: 10px;
  }

  .sb-logo-icon {
    width: 38px;
    height: 38px;
    background: linear-gradient(135deg, var(--navy-600), var(--navy-500));
    border: 1px solid rgba(212,175,55,0.35);
    border-radius: 10px;
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
  }

  .sb-title {
    font-size: 13.5px;
    font-weight: 800;
    color: white;
    line-height: 1.3;
  }

  .sb-sub {
    font-size: 10.5px;
    color: rgba(255,255,255,0.4);
    margin-top: 1px;
  }

  .sb-close {
    display: none;
    background: none;
    border: none;
    color: rgba(255,255,255,0.5);
    font-size: 16px;
    cursor: pointer;
    padding: 4px;
    line-height: 1;
  }

  .sb-nav {
    flex: 1;
    overflow-y: auto;
    padding: 10px 0 16px;
  }

  .sb-section-label {
    font-size: 9.5px;
    font-weight: 700;
    color: rgba(255,255,255,0.25);
    text-transform: uppercase;
    letter-spacing: 1.2px;
    padding: 16px 18px 5px;
  }

  .sb-link {
    display: flex;
    align-items: center;
    gap: 9px;
    padding: 9px 18px;
    color: rgba(255,255,255,0.6);
    text-decoration: none;
    font-size: 13px;
    font-weight: 500;
    transition: var(--transition);
    border-right: 3px solid transparent;
    position: relative;
  }

  .sb-link:hover {
    background: rgba(255,255,255,0.06);
    color: rgba(255,255,255,0.9);
  }

  .sb-link.active {
    background: rgba(212,175,55,0.1);
    color: var(--gold-400);
    border-right-color: var(--gold-500);
    font-weight: 700;
  }

  .sb-icon {
    font-size: 14px;
    width: 20px;
    text-align: center;
    opacity: 0.85;
    font-style: normal;
  }

  .sb-footer {
    padding: 14px 16px;
    border-top: 1px solid rgba(255,255,255,0.07);
    display: flex;
    align-items: center;
    justify-content: space-between;
    flex-shrink: 0;
  }

  .sb-user {
    display: flex;
    align-items: center;
    gap: 10px;
  }

  .sb-avatar {
    width: 34px;
    height: 34px;
    background: linear-gradient(135deg, var(--gold-500), var(--gold-400));
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 13px;
    font-weight: 800;
    color: var(--navy-900);
    flex-shrink: 0;
  }

  .sb-uname {
    font-size: 12.5px;
    font-weight: 700;
    color: white;
  }

  .sb-urole {
    font-size: 10.5px;
    color: rgba(255,255,255,0.4);
    margin-top: 1px;
  }

  .sb-logout {
    color: rgba(255,255,255,0.3);
    font-size: 18px;
    text-decoration: none;
    transition: var(--transition);
    line-height: 1;
    cursor: pointer;
  }

  .sb-logout:hover { color: #ef4444; }

  .overlay {
    display: none;
    position: fixed;
    inset: 0;
    background: rgba(0,0,0,0.55);
    z-index: 150;
    backdrop-filter: blur(2px);
  }

  /* ===== Logout Modal ===== */
  .logout-modal-overlay {
    position: fixed !important;
    inset: 0 !important;
    background: rgba(10,22,40,0.65) !important;
    backdrop-filter: blur(6px) !important;
    display: none !important;
    align-items: center !important;
    justify-content: center !important;
    z-index: 999999 !important;
  }

  .logout-modal-overlay.open {
    display: flex !important;
  }

  .logout-modal-box {
    background: white !important;
    border-radius: 24px !important;
    width: 100% !important;
    max-width: 420px !important;
    padding: 36px 40px 32px !important;
    box-shadow: 0 24px 64px rgba(10,22,40,0.25) !important;
    text-align: center !important;
    position: relative !important;
  }

  .logout-modal-box .logout-icon {
    width: 64px !important;
    height: 64px !important;
    border-radius: 50% !important;
    background: #FEF2F2 !important;
    display: flex !important;
    align-items: center !important;
    justify-content: center !important;
    margin: 0 auto 14px !important;
    font-size: 30px !important;
  }

  .logout-modal-box h3 {
    font-size: 20px !important;
    font-weight: 800 !important;
    color: var(--navy-800) !important;
    margin-bottom: 4px !important;
  }

  .logout-modal-box p {
    color: var(--text-muted) !important;
    font-size: 14px !important;
    margin-bottom: 24px !important;
    font-weight: 500 !important;
  }

  .logout-modal-box .logout-actions {
    display: flex !important;
    gap: 12px !important;
    justify-content: center !important;
    width: 100% !important;
    flex-direction: row !important;
  }

  .logout-modal-box .btn {
    display: inline-flex !important;
    align-items: center !important;
    justify-content: center !important;
    padding: 12px 24px !important;
    height: 44px !important;
    border-radius: 10px !important;
    font-size: 14px !important;
    font-weight: 700 !important;
    font-family: 'Cairo', sans-serif !important;
    cursor: pointer !important;
    border: none !important;
    transition: all 0.2s ease !important;
    min-width: 100px !important;
    flex: 1 !important;
  }

  .logout-modal-box .btn-outline {
    background: #F8FAFD !important;
    color: #475569 !important;
    border: 1.5px solid #E4EAF2 !important;
  }
  .logout-modal-box .btn-outline:hover {
    background: #F1F5F9 !important;
  }

  .logout-modal-box .btn-danger {
    background: #DC2626 !important;
    color: white !important;
  }
  .logout-modal-box .btn-danger:hover {
    background: #B91C1C !important;
    transform: translateY(-1px) !important;
    box-shadow: 0 8px 20px rgba(220,38,38,0.25) !important;
  }

  @media (max-width: 1024px) {
    .sidebar {
      position: fixed;
      right: 0;
      top: 0;
      bottom: 0;
      transform: translateX(100%);
      transition: transform 0.3s cubic-bezier(0.4, 0, 0.2, 1);
      height: 100vh;
    }
    .sidebar.open { transform: translateX(0); }
    .overlay.open { display: block; }
    .sb-close { display: flex; }
    .topbar-hamburger { display: flex; }
    .topbar-date-chip { display: none; }
  }

  @media (max-width: 768px) {
    /* تجاوب شبكات النماذج والكروت المكررة على الموبايل والتابلت الصغير */
    .form-grid,
    .grid-container,
    .grid-2,
    .grid-3,
    .grid-4,
    .row,
    .stats-row,
    .kpi-grid,
    .court-stats-grid,
    .charts-grid,
    .charts-grid-2,
    .stages-container,
    .resources-grid,
    .pending-container,
    .details-grid {
      grid-template-columns: 1fr !important;
      flex-direction: column !important;
    }

    /* شريط البحث والتصفية والطباعة */
    .filter-bar,
    .filter-print-bar,
    .header-actions {
      flex-direction: column !important;
      align-items: stretch !important;
      gap: 12px !important;
    }

    .filter-bar input,
    .filter-bar select,
    .filter-print-bar input,
    .filter-print-bar select,
    .filter-print-bar button,
    .filter-print-bar .search-wrap,
    .header-actions button {
      width: 100% !important;
    }
  }

  @media (min-width: 769px) and (max-width: 1024px) {
    /* تجاوب شبكات النماذج والكروت المكررة على شاشات التابلت المتوسطة */
    .grid-3,
    .grid-4,
    .kpi-grid,
    .stats-row,
    .court-stats-grid,
    .charts-grid,
    .stages-container,
    .resources-grid {
      grid-template-columns: repeat(2, 1fr) !important;
    }
  }

  @media (max-width: 600px) {
    .page-body { padding: 12px !important; }
    .logout-modal-box { margin: 16px; padding: 28px 20px; }
  }

  /* ============================================================
     قواعد التجاوب العالمية الموحدة للجداول والبطاقات
  ============================================================ */
  /* منع الجداول من الخروج عن نطاق الصفحة وجعلها قابلة للتمرير الأفقي بشكل سلس */
  .table-wrap, 
  .table-card, 
  .table-container, 
  .table-responsive,
  div:has(> table) {
    width: 100% !important;
    overflow-x: auto !important;
    -webkit-overflow-scrolling: touch !important;
  }

  /* جعل الأزرار والإجراءات داخل الجداول والبطاقات مرنة */
  .btn, .button {
    max-width: 100%;
    box-sizing: border-box;
  }

  /* ===== Readonly Mode Hiding Rules ===== */
  body.readonly-mode .btn-edit-row,
  body.readonly-mode .btn-delete-row,
  body.readonly-mode .btn-inline-add,
  body.readonly-mode .btn-submit-form,
  body.readonly-mode .btn-confirm-del,
  body.readonly-mode .btn-confirm,
  body.readonly-mode .btn-add,
  body.readonly-mode .btn-edit,
  body.readonly-mode .btn-delete,
  body.readonly-mode .btn-danger,
  body.readonly-mode .delete-btn,
  body.readonly-mode .edit-btn,
  body.readonly-mode .btn-save-inline,
  body.readonly-mode .btn-save,
  body.readonly-mode .btn-action,
  body.readonly-mode .btn-modal-confirm,
  body.readonly-mode .btn-primary:not(.no-protect):not(.topbar-hamburger):not(.sb-close):not(#cancelLogoutBtn):not(#confirmLogoutBtn):not(#cancelChangePasswordBtn):not(#confirmChangePasswordBtn),
  body.readonly-mode button:not(.topbar-hamburger):not(.sb-close):not(#cancelLogoutBtn):not(#confirmLogoutBtn):not(#cancelChangePasswordBtn):not(#confirmChangePasswordBtn),
  body.readonly-mode input[type="submit"],
  body.readonly-mode input[type="button"],
  body.readonly-mode .btn:not(.topbar-hamburger):not(.sb-close):not(#cancelLogoutBtn):not(#confirmLogoutBtn):not(#cancelChangePasswordBtn):not(#confirmChangePasswordBtn):not([href="Cases.html"]),
  body.readonly-mode .button,
  body.readonly-mode [onclick*="add"],
  body.readonly-mode [onclick*="edit"],
  body.readonly-mode [onclick*="delete"],
  body.readonly-mode [onclick*="save"],
  body.readonly-mode [onclick*="update"],
  body.readonly-mode [onclick*="remove"],
  body.readonly-mode [onclick*="create"],
  body.readonly-mode [onclick*="submit"],
  body.readonly-mode [onclick*="اتخاذ"],
  body.readonly-mode [onclick*="اجراء"] {
      display: none !important;
  }

  body.readonly-mode form:not(#logoutModalContainer form):not(#changePasswordModalContainer form) input:not([type="search"]),
  body.readonly-mode form:not(#logoutModalContainer form):not(#changePasswordModalContainer form) textarea,
  body.readonly-mode form:not(#logoutModalContainer form):not(#changePasswordModalContainer form) select,
  body.readonly-mode .form-card input,
  body.readonly-mode .form-card textarea,
  body.readonly-mode .form-card select,
  body.readonly-mode .modal-box input,
  body.readonly-mode .modal-box textarea,
  body.readonly-mode .modal-box select {
      pointer-events: none !important;
      opacity: 0.7 !important;
      background-color: #f1f5f9 !important;
  }

  body.readonly-mode .form-card {
      display: none !important;
  }

  body.readonly-mode .grid-container,
  body.readonly-mode .lawyers-grid {
      grid-template-columns: 1fr !important;
  }

  .sb-profile:hover {
      color: var(--gold-400) !important;
  }
  `;

  // ============================================================
  // 7. الدوال المساعدة
  // ============================================================
  function getNowAr() {
    const n = new Date();
    const days = ['الأحد','الاثنين','الثلاثاء','الأربعاء','الخميس','الجمعة','السبت'];
    const months = ['يناير','فبراير','مارس','أبريل','مايو','يونيو','يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر'];
    return `${days[n.getDay()]} ${String(n.getDate()).padStart(2,'0')}/${String(n.getMonth()+1).padStart(2,'0')}/${n.getFullYear()}`;
  }

  window.toggleSidebar = function() {
    const s = document.getElementById('sidebar');
    const o = document.getElementById('overlay');
    if (s) s.classList.toggle('open');
    if (o) o.classList.toggle('open');
  };

  // ============================================================
  // 8. Logout Modal - الحل النهائي مع ستايل مضمون
  // ============================================================
  function buildLogoutModal() {
    // حذف أي مودال قديم
    const oldModal = document.getElementById('logoutModalContainer');
    if (oldModal) oldModal.remove();

    // بناء المودال بستايل مضمون
    const modalHTML = `
    <div class="logout-modal-overlay" id="logoutModalContainer" style="position:fixed;inset:0;background:rgba(10,22,40,0.65);backdrop-filter:blur(6px);display:none;align-items:center;justify-content:center;z-index:999999;">
        <div style="background:white;border-radius:24px;width:100%;max-width:420px;padding:36px 40px 32px;box-shadow:0 24px 64px rgba(10,22,40,0.25);text-align:center;">
            <div style="width:64px;height:64px;border-radius:50%;background:#FEF2F2;display:flex;align-items:center;justify-content:center;margin:0 auto 14px;font-size:30px;">⍈</div>
            <h3 style="font-size:20px;font-weight:800;color:#0f2240;margin-bottom:4px;">تسجيل الخروج</h3>
            <p style="color:#94A3B8;font-size:14px;margin-bottom:24px;font-weight:500;">هل أنت متأكد من رغبتك في تسجيل الخروج من النظام؟</p>
            <div style="display:flex;gap:12px;justify-content:center;width:100%;">
                <button id="cancelLogoutBtn" style="flex:1;padding:12px 24px;height:44px;border-radius:10px;font-size:14px;font-weight:700;font-family:'Cairo',sans-serif;cursor:pointer;border:1.5px solid #E4EAF2;background:#F8FAFD;color:#475569;min-width:100px;">إلغاء</button>
                <button id="confirmLogoutBtn" style="flex:1;padding:12px 24px;height:44px;border-radius:10px;font-size:14px;font-weight:700;font-family:'Cairo',sans-serif;cursor:pointer;border:none;background:#DC2626;color:white;min-width:100px;">تسجيل الخروج</button>
            </div>
        </div>
    </div>
    `;
    document.body.insertAdjacentHTML('beforeend', modalHTML);

    // ✅ زر الإلغاء
    const cancelBtn = document.getElementById('cancelLogoutBtn');
    if (cancelBtn) {
        cancelBtn.addEventListener('click', function(e) {
            e.stopPropagation();
            closeLogoutModal();
        });
    }

    // ✅ زر تسجيل الخروج
    const confirmBtn = document.getElementById('confirmLogoutBtn');
    if (confirmBtn) {
        confirmBtn.addEventListener('click', function(e) {
            e.stopPropagation();
            console.log('🚪 جاري تسجيل الخروج...');

            // ✅ لازم يتسجل الحدث قبل ما نمسح اسم المستخدم من localStorage
            // الإرسال هنا مباشر (keepalive) فمش معتمد على إن activity-logger.js يكون محمّل في الصفحة،
            // ومش بيتأثر بأي تعريف تاني لـ logAction في الصفحات (زي logs.html).
            try {
                const logoutUser = localStorage.getItem('username') || '';
                const skipLogout = ['', 'زائر', 'CEO', 'inv'].includes(logoutUser);
                if (!skipLogout) {
                    const isInvUser = logoutUser.toLowerCase().includes('inv') ||
                        (localStorage.getItem('userRole') || '').startsWith('Investigation');
                    fetch('/api/logs', {
                        method: 'POST',
                        keepalive: true,
                        headers: { 'Content-Type': 'application/json', 'X-Username': logoutUser },
                        body: JSON.stringify({
                            action: 'logout',
                            description: `تسجيل خروج المستخدم: ${logoutUser}`,
                            page: 'تسجيل الخروج',
                            category: isInvUser ? 'investigation' : 'cases'
                        })
                    }).catch(function () {});
                }
            } catch (err) { console.log('⚠️ تعذر تسجيل الخروج في السجل:', err.message); }
            sessionStorage.removeItem('loginLogged');

            localStorage.removeItem('userRole');
            localStorage.removeItem('username');
            localStorage.removeItem('userPermissions');
            localStorage.removeItem('userReadonly');
            window.location.href = 'index.html';
        });
    }

    // إغلاق عند الضغط على الخلفية
    const modal = document.getElementById('logoutModalContainer');
    if (modal) {
        modal.addEventListener('click', function(e) {
            if (e.target === this) closeLogoutModal();
        });
    }
  }

  // دالة فتح المودال
  window.openLogoutModal = function() {
    console.log('🚪 فتح مودال تسجيل الخروج');
    const modal = document.getElementById('logoutModalContainer');
    if (modal) {
        modal.classList.add('open');
    } else {
        buildLogoutModal();
        setTimeout(() => {
            const m = document.getElementById('logoutModalContainer');
            if (m) m.classList.add('open');
        }, 50);
    }
  };

  // دالة إغلاق المودال
  window.closeLogoutModal = function() {
    const modal = document.getElementById('logoutModalContainer');
    if (modal) modal.classList.remove('open');
  };

  // ============================================================
  // 8.5. Change Password Modal - تغيير كلمة المرور للمستخدم الحالي
  // ============================================================
  function buildChangePasswordModal() {
    const oldModal = document.getElementById('changePasswordModalContainer');
    if (oldModal) oldModal.remove();

    const modalHTML = `
    <div class="logout-modal-overlay" id="changePasswordModalContainer" style="position:fixed;inset:0;background:rgba(10,22,40,0.65);backdrop-filter:blur(6px);display:none;align-items:center;justify-content:center;z-index:999999;direction:rtl;">
        <div style="background:white;border-radius:24px;width:100%;max-width:420px;padding:32px 30px;box-shadow:0 24px 64px rgba(10,22,40,0.25);text-align:right;font-family:'Cairo',sans-serif;box-sizing:border-box;">
            <div style="width:56px;height:56px;border-radius:50%;background:#FFFBEB;border:1px solid #FDE68A;display:flex;align-items:center;justify-content:center;margin:0 auto 14px;font-size:26px;color:#D97706;">🔑</div>
            <h3 style="font-size:18px;font-weight:800;color:#0f2240;margin-bottom:4px;text-align:center;">تغيير كلمة المرور</h3>
            <p style="color:#64748B;font-size:13px;margin-bottom:20px;font-weight:500;text-align:center;">قم بتعيين كلمة مرور جديدة لحسابك</p>
            
            <div style="margin-bottom: 14px;">
                <label style="display:block;font-size:12.5px;font-weight:700;color:#1a3a5c;margin-bottom:6px;">كلمة المرور الحالية <span style="color:#DC2626;">*</span></label>
                <input type="password" id="currentPasswordInput" placeholder="أدخل كلمة المرور الحالية" autocomplete="current-password" style="width:100%;height:42px;padding:0 12px;border-radius:9px;border:1.5px solid #E4EAF2;font-size:13.5px;font-family:'Cairo',sans-serif;outline:none;background:#F8FAFD;box-sizing:border-box;transition:all 0.2s;" onfocus="this.style.borderColor='#D4AF37';this.style.background='#fff';" onblur="this.style.borderColor='#E4EAF2';this.style.background='#F8FAFD';">
            </div>
            <div style="margin-bottom: 14px;">
                <label style="display:block;font-size:12.5px;font-weight:700;color:#1a3a5c;margin-bottom:6px;">كلمة المرور الجديدة <span style="color:#DC2626;">*</span></label>
                <input type="password" id="newPasswordInput" placeholder="أدخل كلمة المرور الجديدة (4 أحرف أو أرقام على الأقل)" autocomplete="new-password" style="width:100%;height:42px;padding:0 12px;border-radius:9px;border:1.5px solid #E4EAF2;font-size:13.5px;font-family:'Cairo',sans-serif;outline:none;background:#F8FAFD;box-sizing:border-box;transition:all 0.2s;" onfocus="this.style.borderColor='#D4AF37';this.style.background='#fff';" onblur="this.style.borderColor='#E4EAF2';this.style.background='#F8FAFD';">
            </div>
            <div style="margin-bottom: 18px;">
                <label style="display:block;font-size:12.5px;font-weight:700;color:#1a3a5c;margin-bottom:6px;">تأكيد كلمة المرور الجديدة <span style="color:#DC2626;">*</span></label>
                <input type="password" id="confirmPasswordInput" placeholder="أعد إدخال كلمة المرور الجديدة" autocomplete="new-password" style="width:100%;height:42px;padding:0 12px;border-radius:9px;border:1.5px solid #E4EAF2;font-size:13.5px;font-family:'Cairo',sans-serif;outline:none;background:#F8FAFD;box-sizing:border-box;transition:all 0.2s;" onfocus="this.style.borderColor='#D4AF37';this.style.background='#fff';" onblur="this.style.borderColor='#E4EAF2';this.style.background='#F8FAFD';">
            </div>
            
            <div id="changePasswordErrorMsg" style="color:#DC2626;background:#FEF2F2;border:1px solid #FCA5A5;border-radius:8px;padding:8px 12px;font-size:12.5px;margin-bottom:14px;text-align:center;display:none;font-weight:700;"></div>
            <div id="changePasswordSuccessMsg" style="color:#059669;background:#ECFDF5;border:1px solid #6EE7B7;border-radius:8px;padding:8px 12px;font-size:12.5px;margin-bottom:14px;text-align:center;display:none;font-weight:700;"></div>

            <div style="display:flex;gap:10px;justify-content:center;width:100%;box-sizing:border-box;">
                <button id="cancelChangePasswordBtn" type="button" style="flex:1;padding:10px 18px;height:42px;border-radius:9px;font-size:13px;font-weight:700;font-family:'Cairo',sans-serif;cursor:pointer;border:1.5px solid #E4EAF2;background:#F8FAFD;color:#475569;min-width:90px;outline:none;transition:all 0.2s;" onmouseover="this.style.background='#E2E8F0';" onmouseout="this.style.background='#F8FAFD';">إلغاء</button>
                <button id="confirmChangePasswordBtn" type="button" style="flex:1;padding:10px 18px;height:42px;border-radius:9px;font-size:13px;font-weight:700;font-family:'Cairo',sans-serif;cursor:pointer;border:none;background:#D4AF37;color:#0a1628;min-width:90px;outline:none;transition:all 0.2s;" onmouseover="this.style.background='#E8C84A';" onmouseout="this.style.background='#D4AF37';">حفظ</button>
            </div>
        </div>
    </div>
    `;
    document.body.insertAdjacentHTML('beforeend', modalHTML);

    const cancelBtn = document.getElementById('cancelChangePasswordBtn');
    if (cancelBtn) {
        cancelBtn.addEventListener('click', function(e) {
            e.stopPropagation();
            closeChangePasswordModal();
        });
    }

    // Trigger save on Enter inside inputs
    ['currentPasswordInput', 'newPasswordInput', 'confirmPasswordInput'].forEach(id => {
        const inp = document.getElementById(id);
        if (inp) {
            inp.addEventListener('keydown', function(e) {
                if (e.key === 'Enter') {
                    e.preventDefault();
                    document.getElementById('confirmChangePasswordBtn')?.click();
                }
            });
        }
    });

    const confirmBtn = document.getElementById('confirmChangePasswordBtn');
    if (confirmBtn) {
        confirmBtn.addEventListener('click', async function(e) {
            e.stopPropagation();
            
            const currentPassword = document.getElementById('currentPasswordInput').value.trim();
            const newPassword = document.getElementById('newPasswordInput').value.trim();
            const confirmPassword = document.getElementById('confirmPasswordInput').value.trim();
            
            const errEl = document.getElementById('changePasswordErrorMsg');
            const succEl = document.getElementById('changePasswordSuccessMsg');
            
            errEl.style.display = 'none';
            succEl.style.display = 'none';

            if (!currentPassword || !newPassword || !confirmPassword) {
                errEl.textContent = '❌ يرجى إدخال جميع الحقول المطلوبة';
                errEl.style.display = 'block';
                return;
            }

            if (newPassword !== confirmPassword) {
                errEl.textContent = '❌ كلمة المرور الجديدة وتأكيدها غير متطابقين';
                errEl.style.display = 'block';
                return;
            }

            if (newPassword.length < 4) {
                errEl.textContent = '❌ يجب أن تتكون كلمة المرور من 4 أحرف أو أرقام على الأقل';
                errEl.style.display = 'block';
                return;
            }

            const username = localStorage.getItem('username') || '';
            if (!username) {
                errEl.textContent = '❌ يرجى تسجيل الدخول أولاً';
                errEl.style.display = 'block';
                return;
            }

            confirmBtn.disabled = true;
            confirmBtn.textContent = 'جاري الحفظ...';

            try {
                const response = await fetch('/api/auth/change-password', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'X-Username': encodeURIComponent(username)
                    },
                    body: JSON.stringify({
                        currentPassword,
                        newPassword,
                        currentUser: username
                    })
                });
                
                const result = await response.json();
                
                if (response.ok && result.success) {
                    succEl.textContent = '✅ ' + result.message;
                    succEl.style.display = 'block';
                    
                    document.getElementById('currentPasswordInput').value = '';
                    document.getElementById('newPasswordInput').value = '';
                    document.getElementById('confirmPasswordInput').value = '';
                    
                    setTimeout(() => {
                        closeChangePasswordModal();
                    }, 1400);
                } else {
                    errEl.textContent = '❌ ' + (result.message || 'فشلت العملية');
                    errEl.style.display = 'block';
                }
            } catch (err) {
                console.error('Change password error:', err);
                errEl.textContent = '❌ حدث خطأ في الاتصال بالخادم';
                errEl.style.display = 'block';
            } finally {
                confirmBtn.disabled = false;
                confirmBtn.textContent = 'حفظ';
            }
        });
    }

    const modal = document.getElementById('changePasswordModalContainer');
    if (modal) {
        modal.addEventListener('click', function(e) {
            if (e.target === this) closeChangePasswordModal();
        });
    }
  }

  window.openChangePasswordModal = function(e) {
    if (e) {
        e.preventDefault();
        e.stopPropagation();
    }
    console.log('🔑 فتح مودال تغيير كلمة المرور');
    let modal = document.getElementById('changePasswordModalContainer');
    if (!modal) {
        buildChangePasswordModal();
        modal = document.getElementById('changePasswordModalContainer');
    }
    if (modal) {
        modal.classList.add('open');
        setTimeout(() => {
            const input = document.getElementById('currentPasswordInput');
            if (input) input.focus();
        }, 60);
    }
  };

  window.closeChangePasswordModal = function() {
    const modal = document.getElementById('changePasswordModalContainer');
    if (modal) {
        modal.classList.remove('open');
        const errEl = document.getElementById('changePasswordErrorMsg');
        const succEl = document.getElementById('changePasswordSuccessMsg');
        if (errEl) errEl.style.display = 'none';
        if (succEl) succEl.style.display = 'none';
        
        const i1 = document.getElementById('currentPasswordInput');
        const i2 = document.getElementById('newPasswordInput');
        const i3 = document.getElementById('confirmPasswordInput');
        if (i1) i1.value = '';
        if (i2) i2.value = '';
        if (i3) i3.value = '';
    }
  };

  // ============================================================
  // 9. دالة حماية الصفحات (قراءة فقط)
  // ============================================================
  function protectReadonlyPage() {
    if (!isReadonlyUser()) return false;
    
    console.log('🔒 وضع قراءة فقط - التعديل غير مسموح');
    
    const actionButtons = document.querySelectorAll(
      '.btn-add, .btn-edit, .btn-delete, .btn-danger, ' +
      '.btn-primary:not(.no-protect), ' +
      '[onclick*="add"], [onclick*="edit"], [onclick*="delete"], ' +
      '[onclick*="save"], [onclick*="update"], [onclick*="remove"], ' +
      '[onclick*="create"], [onclick*="submit"], [onclick*="اتخاذ"], [onclick*="اجراء"]'
    );
    
    actionButtons.forEach(el => {
      if (!el.closest('nav') && !el.closest('.topbar') && !el.closest('.sidebar') && !el.closest('.sb-nav')) {
        el.style.display = 'none';
      }
    });
    
    document.querySelectorAll('input:not([readonly]):not([type="search"]), textarea:not([readonly]), select:not([disabled])')
      .forEach(el => {
        if (!el.closest('.search-box') && !el.closest('.topbar') &&
            !el.closest('.modal-overlay-print') && !el.closest('#printModal') &&
            !el.closest('.print-modal-fields')) {
          el.disabled = true;
          el.style.opacity = '0.7';
          el.style.cursor = 'not-allowed';
        }
      });
    
    document.querySelectorAll('form').forEach(form => {
      form.removeEventListener('submit', preventFormSubmit);
      form.addEventListener('submit', preventFormSubmit);
    });
    
    return true;
  }

  function preventFormSubmit(e) {
    e.preventDefault();
    alert('⚠️ أنت في وضع قراءة فقط، لا يمكنك حفظ التغييرات.');
    return false;
  }

  // ============================================================
  // 10. الدالة الرئيسية
  // ============================================================
  async function initSidebar(activePage) {
    // التحقق من صلاحية الوصول للصفحة
    checkPageAccess();

    // إضافة الـ CSS الخاص بالقائمة الجانبية
    const styleEl = document.createElement('style');
    styleEl.textContent = SIDEBAR_CSS;
    document.head.appendChild(styleEl);

    // إضافة رابط خط Cairo
    if (!document.getElementById('sb-font-link')) {
        const l = document.createElement('link');
        l.id = 'sb-font-link';
        l.rel = 'stylesheet';
        l.href = 'https://fonts.googleapis.com/css2?family=Cairo:wght@400;500;600;700;800;900&family=Tajawal:wght@400;500;700;800&display=swap';
        document.head.appendChild(l);
    }

    // ✅ تحديث الصلاحيات من الخادم قبل بناء القائمة
    await refreshUserPermissions();

    // حماية العناصر المحمية
    const protectedElements = {};
    PROTECTED_ELEMENTS.forEach(id => {
        const el = document.getElementById(id);
        if (el) {
            protectedElements[id] = el.cloneNode(true);
            el.remove();
        }
    });

    // حفظ عناصر الصفحة الحالية
    const childrenToKeep = [];
    document.body.childNodes.forEach(node => {
        if (node.tagName && node.tagName !== 'SCRIPT') {
            childrenToKeep.push(node);
        }
    });
    childrenToKeep.forEach(node => node.remove());

    // عناوين الصفحات
    const pageTitles = {
        'dashboard': { title: 'لوحة التحكم', crumb: 'الرئيسية' },
        'cases': { title: 'جميع القضايا', crumb: 'الرئيسية ← إدارة القضايا' },
        'new-case': { title: 'قضية جديدة', crumb: 'الرئيسية ← إدارة القضايا' },
        'litigation-level': { title: 'درجة التقاضى', crumb: 'الرئيسية ← إدارة القضايا' },
        'appeals-tracking': { title: 'متابعة الدعاوى والأحكام', crumb: 'الرئيسية' },
        'sessions': { title: 'الجلسات', crumb: 'الرئيسية ← إدارة القضايا' },
        'calendar': { title: 'النتيجة', crumb: 'الرئيسية ← إدارة القضايا' },
        'lawyers': { title: 'المحامون', crumb: 'الرئيسية ← الموارد البشرية' },
        'courts': { title: 'المحاكم والدوائر', crumb: 'الرئيسية ← الموارد البشرية' },
        'logs': { title: ' الحركات', crumb: 'الرئيسية ← الحركات' },
        'reports-hub': { title: 'تقارير', crumb: 'الرئيسية ← التقارير' },
        'mamoriyat': { title: 'تقرير المأموريات', crumb: 'الرئيسية ← التقارير' },
        'reports': { title: 'الحركات', crumb: 'الرئيسية ← التقارير' },
        'archive': { title: 'الأرشيف', crumb: 'الرئيسية ← التقارير' },
        'users': { title: 'المستخدمون', crumb: 'الرئيسية ← الإعدادات' },
        'investigations-dashboard': { title: 'لوحة التحقيقات', crumb: 'الرئيسية ← التحقيقات' },
        'new-investigation': { title: 'تحقيق جديد', crumb: 'الرئيسية ← التحقيقات' },
        'investigation-details': { title: 'متابعة التحقيقات', crumb: 'الرئيسية ← التحقيقات' },
        'investigation-archive': { title: 'أرشيف التحقيقات', crumb: 'الرئيسية ← التحقيقات' },
        'investigation-logs': { title: 'سجل تتبعات التحقيقات', crumb: 'الرئيسية ← التحقيقات' },
        'investigation-users': { title: 'مستخدمو التحقيقات', crumb: 'الرئيسية ← التحقيقات' }
    };

    const { title, crumb } = pageTitles[activePage] || { title: 'النظام', crumb: 'الرئيسية' };
    isInvPage = activePage.startsWith('investigation') || activePage.includes('investigation');

    // محتوى الإشعارات
    const notifDropdownContent = isInvPage ? `
        <div class="notif-dropdown" id="notifDropdown">
          <div class="notif-header">
            <span>🔍 إشعارات التحقيقات</span>
            <span class="notif-header-mark-all" id="notifMarkAllBtn">تحديد الكل كمقروء</span>
          </div>
          <div class="notif-list" id="notifList">
            <div class="notif-empty">لا توجد إشعارات جديدة</div>
          </div>
        </div>
    ` : `
        <div class="notif-dropdown" id="notifDropdown">
          <div class="notif-header">
            <span>📅 جلسات اليوم <span id="todaySessionsCount"></span></span>
          </div>
          <div class="notif-list" id="todaySessionsList">
            <div class="notif-empty">جاري التحميل...</div>
          </div>
          <div class="notif-header" style="border-top:1px solid var(--border);">
            <span>🔔 الإشعارات</span>
            <span class="notif-header-mark-all" id="notifMarkAllBtn">تحديد الكل كمقروء</span>
          </div>
          <div class="notif-list" id="notifList">
            <div class="notif-empty">لا توجد إشعارات جديدة</div>
          </div>
        </div>
    `;

    // بناء الـ Topbar
    const topbarHTML = `
    <header class="custom-modern-topbar">
      <div style="display:flex;align-items:center;gap:12px;">
        <button class="topbar-hamburger" onclick="toggleSidebar()" aria-label="القائمة">☰</button>
        <div class="topbar-right-info">
          <h1 class="topbar-page-title">${title}</h1>
          <p class="topbar-breadcrumbs">${crumb}</p>
        </div>
      </div>
      <div class="topbar-left-actions" style="position: relative;">
        <div class="topbar-notif-btn" id="notifBellBtn" title="الإشعارات">
          🔔
          <span class="topbar-notif-badge" id="notifBadge" style="display: none;">0</span>
        </div>
        ${notifDropdownContent}
        <div class="topbar-date-chip">${getNowAr()}</div>
      </div>
    </header>
    `;

    // بناء الهيكل الرئيسي
    const wrapper = document.createElement('div');
    wrapper.className = 'dynamic-layout-wrapper';
    const main = document.createElement('div');
    main.className = 'dynamic-main-content';
    main.insertAdjacentHTML('afterbegin', topbarHTML);

    childrenToKeep.forEach(node => {
        if (node.id && PROTECTED_ELEMENTS.includes(node.id)) {
        } else {
            main.appendChild(node);
        }
    });

    document.body.appendChild(wrapper);
    wrapper.insertAdjacentHTML('afterbegin', buildSidebarHTML());
    wrapper.appendChild(main);

    buildNavLinks(activePage);

    // استعادة العناصر المحمية
    Object.keys(protectedElements).forEach(id => {
        const existing = document.getElementById(id);
        if (!existing) {
            document.body.appendChild(protectedElements[id]);
        }
    });

    // بناء مودال تسجيل الخروج وتغيير كلمة المرور
    buildLogoutModal();
    buildChangePasswordModal();

    // تطبيق الحماية إذا كان المستخدم في وضع قراءة فقط
    if (isReadonlyUser()) {
        document.body.classList.add('readonly-mode');
        setTimeout(() => {
            protectReadonlyPage();
        }, 100);
    }

    // تحميل FontAwesome
    if (!document.querySelector('link[href*="font-awesome"]')) {
        const fa = document.createElement('link');
        fa.rel = 'stylesheet';
        fa.href = 'https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css';
        document.head.appendChild(fa);
    }

    // تشغيل نظام الإشعارات
    initNotifications();

    // تشغيل عرض جلسات اليوم في الجرس
    initTodaySessions();

    // تطبيق صلاحيات دور القضايا (Admin readonly / CEO readonly)
    setTimeout(() => { applyCasesRoleRestrictions(); }, 200);

    console.log(`✅ تم تحميل القائمة الجانبية - الصفحة: ${activePage}`);
}

  // ============================================================
  // دالة الإشعارات (مع إلغاء تحديث البادج)
  // ============================================================
  async function initNotifications() {
    const bellBtn = document.getElementById('notifBellBtn');
    const dropdown = document.getElementById('notifDropdown');
    const list = document.getElementById('notifList');
    const markAllBtn = document.getElementById('notifMarkAllBtn');

    if (!bellBtn) return;

    bellBtn.addEventListener('click', (e) => {
      e.stopPropagation();
      dropdown.classList.toggle('show');
    });

    document.addEventListener('click', () => {
      dropdown.classList.remove('show');
    });

    dropdown.addEventListener('click', (e) => {
      e.stopPropagation();
    });

    async function fetchNotifications() {
      try {
        const username = localStorage.getItem('username') || '';
        const response = await fetch('/api/notifications', {
          headers: {
            'X-Username': username
          }
        });
        const result = await response.json();
        if (result.success) {
          updateNotifUI(result.data, result.unreadCount);
        }
      } catch (err) {
        console.warn('Failed to fetch notifications:', err);
      }
    }

    function updateNotifUI(notifications, unreadCount) {
      const badge = document.getElementById('notifBadge');
      if (isInvPage && badge) {
        if (unreadCount > 0) {
          badge.textContent = unreadCount;
          badge.style.display = 'flex';
          badge.style.background = '#DC2626';
        } else {
          badge.style.display = 'none';
        }
      }

      if (notifications && notifications.length > 0) {
        let html = '';
        notifications.forEach(n => {
          const itemClass = n.IsRead ? 'notif-item' : 'notif-item unread';
          const _nd = new Date(n.CreatedAt);
          const timeStr = isNaN(_nd.getTime()) ? '' : `${String(_nd.getDate()).padStart(2,'0')}/${String(_nd.getMonth()+1).padStart(2,'0')}/${_nd.getFullYear()} ${String(_nd.getHours()).padStart(2,'0')}:${String(_nd.getMinutes()).padStart(2,'0')}`;
          html += `
            <a href="${n.EntityUrl || '#'}" class="${itemClass}" data-id="${n.Id}">
              <div class="notif-item-title">${n.Title}</div>
              <div class="notif-item-msg">${n.Message || ''}</div>
              <div class="notif-item-time">${timeStr}</div>
            </a>
          `;
        });
        list.innerHTML = html;

        list.querySelectorAll('.notif-item').forEach(item => {
          item.addEventListener('click', async (e) => {
            e.preventDefault();
            const id = item.getAttribute('data-id');
            const url = item.getAttribute('href');
            try {
              const username = localStorage.getItem('username') || '';
              await fetch('/api/notifications/read', {
                method: 'POST',
                headers: {
                  'Content-Type': 'application/json',
                  'X-Username': username
                },
                body: JSON.stringify({ id: parseInt(id) })
              });
            } catch (err) {
              console.error(err);
            }
            if (url && url !== '#') {
              window.location.href = url;
            }
          });
        });
      } else {
        list.innerHTML = '<div class="notif-empty">لا توجد إشعارات جديدة</div>';
      }
    }

    markAllBtn.addEventListener('click', async () => {
      try {
        const username = localStorage.getItem('username') || '';
        const response = await fetch('/api/notifications/read', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-Username': username
          },
          body: JSON.stringify({ markAll: true })
        });
        const result = await response.json();
        if (result.success) {
          fetchNotifications();
        }
      } catch (err) {
        console.error(err);
      }
    });

    fetchNotifications();
    setInterval(fetchNotifications, 30000);
  }

  // ============================================================
  // دالة جلسات اليوم (داخل جرس الإشعارات) - مع تحديث البادج
  // ============================================================
  async function initTodaySessions() {
    const list = document.getElementById('todaySessionsList');
    const countEl = document.getElementById('todaySessionsCount');
    if (!list || isInvPage) return;

    function getTodayDateStr() {
      const d = new Date();
      const yyyy = d.getFullYear();
      const mm = String(d.getMonth() + 1).padStart(2, '0');
      const dd = String(d.getDate()).padStart(2, '0');
      return `${yyyy}-${mm}-${dd}`;
    }

    async function fetchTodaySessions() {
      try {
        const response = await fetch('/api/sessions');
        const result = await response.json();
        if (!result.success) return;

        const todayStr = getTodayDateStr();
        const todaySessions = (result.data || [])
          .filter(s => s.SessionDate === todayStr)
          .sort((a, b) => (a.SessionTime || '99:99').localeCompare(b.SessionTime || '99:99'));

        renderTodaySessions(todaySessions);
      } catch (err) {
        console.warn('Failed to fetch today sessions:', err);
        list.innerHTML = '<div class="notif-empty">تعذّر تحميل جلسات اليوم</div>';
      }
    }

    function renderTodaySessions(sessions) {
      const badge = document.getElementById('notifBadge');
      
      // ✅ تحديث البادج بعدد جلسات اليوم
      if (sessions.length > 0) {
        badge.textContent = sessions.length;
        badge.style.display = 'flex';
        badge.style.background = '#DC2626';
      } else {
        badge.style.display = 'none';
      }

      if (countEl) {
        countEl.textContent = sessions.length > 0 ? `(${sessions.length})` : '';
      }

      if (sessions.length === 0) {
        list.innerHTML = '<div class="notif-empty">لا توجد جلسات اليوم</div>';
        return;
      }

      let html = '';
      sessions.forEach(s => {
        html += `
          <a href="sessions.html?viewSession=${s.Id}" class="notif-item">
            <div class="today-session-item">
              <div class="today-session-info">
                <div class="notif-item-title">${s.CaseNumber || '—'} — ${s.Stage || ''}</div>
                <div class="notif-item-msg">${s.CourtName || ''} ${s.CircuitName ? '- ' + s.CircuitName : ''}</div>
                <div class="notif-item-msg">👤 ${s.LawyerName || '—'}</div>
              </div>
              <span class="today-session-time">${s.SessionTime || '—'}</span>
            </div>
          </a>
        `;
      });
      list.innerHTML = html;
    }

    fetchTodaySessions();
    setInterval(fetchTodaySessions, 60000);
  }

  // ============================================================
  // 11. تصدير الدوال
  // ============================================================
  window.initSidebar = initSidebar;
  window.getUserRole = getUserRole;
  window.getUsername = getUsername;
  window.getUserPermissions = getUserPermissions;
  window.checkPageAccess = checkPageAccess;
  window.openLogoutModal = openLogoutModal;
  window.closeLogoutModal = closeLogoutModal;
  window.isReadonlyUser = isReadonlyUser;
  window.protectReadonlyPage = protectReadonlyPage;

  // ============================================================
  // 12. مستبدل الأيقونات التلقائي برموز SVG برمجية (بينت على أي جهاز)
  // ============================================================
  function initGlobalIconReplacer() {
    // 1. إضافة تنسيق CSS مخصص لأيقونات SVG
    const style = document.createElement('style');
    style.id = 'global-svg-icons-style';
    style.textContent = `
      .svg-icon {
        display: inline-block;
        width: 1.1em;
        height: 1.1em;
        vertical-align: -0.15em;
        fill: none;
        stroke: currentColor;
        stroke-width: 2;
        stroke-linecap: round;
        stroke-linejoin: round;
      }
      /* إبعاد الأيقونة عن النص قليلاً في اللغتين العربية والإنجليزية */
      button .svg-icon, a .svg-icon, span .svg-icon, div .svg-icon, td .svg-icon {
        margin-inline-end: 5px;
        margin-inline-start: 2px;
      }
      button:empty .svg-icon, a:empty .svg-icon,
      .svg-icon:only-child,
      button > .svg-icon:only-child, a > .svg-icon:only-child,
      td > .svg-icon:only-child {
        margin-inline-end: 0 !important;
        margin-inline-start: 0 !important;
      }
    `;
    document.head.appendChild(style);

    const SVGS = {
      edit: `<svg viewBox="0 0 24 24" class="svg-icon svg-edit"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path></svg>`,
      delete: `<svg viewBox="0 0 24 24" class="svg-icon svg-delete"><polyline points="3 6 5 6 21 6"></polyline><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path><line x1="10" y1="11" x2="10" y2="17"></line><line x1="14" y1="11" x2="14" y2="17"></line></svg>`,
      view: `<svg viewBox="0 0 24 24" class="svg-icon svg-view"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path><circle cx="12" cy="12" r="3"></circle></svg>`,
      print: `<svg viewBox="0 0 24 24" class="svg-icon svg-print"><polyline points="6 9 6 2 18 2 18 9"></polyline><path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"></path><rect x="6" y="14" width="12" height="8"></rect></svg>`,
      calendar: `<svg viewBox="0 0 24 24" class="svg-icon svg-calendar"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect><line x1="16" y1="2" x2="16" y2="6"></line><line x1="8" y1="2" x2="8" y2="6"></line><line x1="3" y1="10" x2="21" y2="10"></line></svg>`,
      search: `<svg viewBox="0 0 24 24" class="svg-icon svg-search"><circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line></svg>`,
      plus: `<svg viewBox="0 0 24 24" class="svg-icon svg-plus"><line x1="12" y1="5" x2="12" y2="19"></line><line x1="5" y1="12" x2="19" y2="12"></line></svg>`,
      save: `<svg viewBox="0 0 24 24" class="svg-icon svg-save"><path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"></path><polyline points="17 21 17 13 7 13 7 21"></polyline><polyline points="7 3 7 8 15 8"></polyline></svg>`,
      close: `<svg viewBox="0 0 24 24" class="svg-icon svg-close"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>`,
      folder: `<svg viewBox="0 0 24 24" class="svg-icon svg-folder"><path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"></path></svg>`,
      scale: `<svg viewBox="0 0 24 24" class="svg-icon svg-scale"><path d="M12 2v20M20 7H4M18 7c0 5-6 5-6 5s-6 0-6-5M12 7c0 5 6 5 6 5M2 22h20"></path></svg>`,
      check: `<svg viewBox="0 0 24 24" class="svg-icon svg-check"><polyline points="20 6 9 17 4 12"></polyline></svg>`
    };

    function replaceIcons(root) {
      if (!root) return;

      // 1. استبدال أيقونات FontAwesome
      try {
        const faIcons = root.querySelectorAll('i[class*="fa-"]');
        faIcons.forEach(icon => {
          const classes = icon.className.toLowerCase();
          let svg = null;
          if (classes.includes('pen') || classes.includes('edit')) {
            svg = SVGS.edit;
          } else if (classes.includes('trash') || classes.includes('delete') || classes.includes('remove')) {
            svg = SVGS.delete;
          } else if (classes.includes('eye') || classes.includes('view') || classes.includes('show')) {
            svg = SVGS.view;
          } else if (classes.includes('print')) {
            svg = SVGS.print;
          } else if (classes.includes('calendar')) {
            svg = SVGS.calendar;
          } else if (classes.includes('search')) {
            svg = SVGS.search;
          } else if (classes.includes('plus')) {
            svg = SVGS.plus;
          } else if (classes.includes('xmark') || classes.includes('close')) {
            svg = SVGS.close;
          } else if (classes.includes('check')) {
            svg = SVGS.check;
          }
          
          if (svg) {
            const temp = document.createElement('div');
            temp.innerHTML = svg;
            icon.replaceWith(temp.firstElementChild);
          }
        });
      } catch (e) {}

      // 2. استبدال الإيموجي في النصوص
      try {
        const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT, null, false);
        let textNode;
        const toReplace = [];
        while (textNode = walker.nextNode()) {
          const text = textNode.nodeValue;
          if (/[✏🗑👁🖨🔍📅➕💾✕📂🗂⚖📁✖✅]/.test(text)) {
            toReplace.push(textNode);
          }
        }

        toReplace.forEach(node => {
          const text = node.nodeValue;
          const parent = node.parentNode;
          if (!parent) return;
          
          const parentTagName = parent.tagName.toLowerCase();
          if (parentTagName === 'script' || parentTagName === 'style' || parentTagName === 'svg' || parentTagName === 'path') {
            return;
          }

          let hasChange = false;
          let html = text
            .replace(/✏️|✏/g, () => { hasChange = true; return SVGS.edit; })
            .replace(/🗑️|🗑/g, () => { hasChange = true; return SVGS.delete; })
            .replace(/👁️|👁/g, () => { hasChange = true; return SVGS.view; })
            .replace(/🖨️|🖨/g, () => { hasChange = true; return SVGS.print; })
            .replace(/🔍/g, () => { hasChange = true; return SVGS.search; })
            .replace(/📅/g, () => { hasChange = true; return SVGS.calendar; })
            .replace(/➕|＋/g, () => { hasChange = true; return SVGS.plus; })
            .replace(/💾/g, () => { hasChange = true; return SVGS.save; })
            .replace(/✕|✖️|✖|❌/g, () => { hasChange = true; return SVGS.close; })
            .replace(/📂|🗂️|🗂|📁/g, () => { hasChange = true; return SVGS.folder; })
            .replace(/⚖️|⚖/g, () => { hasChange = true; return SVGS.scale; })
            .replace(/✅/g, () => { hasChange = true; return SVGS.check; });

          if (hasChange) {
            const temp = document.createElement('div');
            temp.innerHTML = html;
            while (temp.firstChild) {
              parent.insertBefore(temp.firstChild, node);
            }
            parent.removeChild(node);
          }
        });
      } catch (e) {}
    }

    // تشغيل الاستبدال لأول مرة
    replaceIcons(document.body);

    // مراقبة التغييرات في DOM لاستبدال الأيقونات في المحتوى الديناميكي تلقائياً
    const observer = new MutationObserver((mutations) => {
      observer.disconnect();
      try {
        for (const mutation of mutations) {
          if (mutation.addedNodes.length > 0) {
            for (const node of mutation.addedNodes) {
              if (node.nodeType === Node.ELEMENT_NODE) {
                const tag = node.tagName.toLowerCase();
                if (tag !== 'svg' && tag !== 'path' && !node.classList.contains('svg-icon')) {
                  replaceIcons(node);
                }
              }
            }
          }
        }
      } finally {
        observer.observe(document.body, {
          childList: true,
          subtree: true
        });
      }
    });

    observer.observe(document.body, {
      childList: true,
      subtree: true
    });
  }

  // ============================================================
  // 13. إعادة بناء المودال عند تحميل الصفحة
  // ============================================================
  document.addEventListener('DOMContentLoaded', function() {
    buildLogoutModal();
    buildChangePasswordModal();
    initGlobalIconReplacer(); // تفعيل مستبدل الأيقونات البرمجية SVG
  });

})();