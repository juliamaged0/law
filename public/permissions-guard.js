// ============================================================
// permissions-guard.js
// نظام موحّد للتحقق من صلاحيات المستخدم داخل كل صفحة:
// - هل يقدر يفتح الصفحة أصلاً (view)
// - هل يقدر يضيف (add)  🖊️
// - هل يقدر يعدل (edit) ✏️
// - هل يقدر يمسح (delete) 🗑️
//
// الصلاحيات متخزنة في localStorage['userPermissions'] كمصفوفة نصوص:
// ['cases', 'cases:add', 'cases:edit', ...]
// (بيتم حفظها من صفحة إدارة المستخدمين access.html)
// ============================================================

(function (global) {

  function getPermissions() {
    try {
      const raw = localStorage.getItem('userPermissions');
      if (raw) {
        const parsed = JSON.parse(raw);
        if (Array.isArray(parsed)) return parsed;
      }
    } catch (e) {}
    return [];
  }

  function hasPage(pageId) {
    return getPermissions().includes(pageId);
  }

  function canAdd(pageId) {
    const perms = getPermissions();
    return perms.includes(pageId) && perms.includes(pageId + ':add');
  }

  function canEdit(pageId) {
    const perms = getPermissions();
    return perms.includes(pageId) && perms.includes(pageId + ':edit');
  }

  function canDelete(pageId) {
    const perms = getPermissions();
    return perms.includes(pageId) && perms.includes(pageId + ':delete');
  }

  // تستخدم مرة واحدة في بداية كل صفحة (قبل تحميل أي بيانات)
  // لو المستخدم مش معاه صلاحية فتح الصفحة، بيتقفل محتوى الصفحة وتظهر رسالة.
  function blockPageIfNoAccess(pageId) {
    if (!hasPage(pageId)) {
      document.body.innerHTML = `
        <div style="display:flex;align-items:center;justify-content:center;height:100vh;
                    font-family:'Cairo',sans-serif;text-align:center;padding:20px;background:#F4F6FA;">
          <div>
            <div style="font-size:52px;margin-bottom:14px;">🚫</div>
            <h2 style="color:#DC2626;margin-bottom:8px;font-size:20px;">غير مصرح لك بالدخول</h2>
            <p style="color:#64748B;font-size:14px;">ليس لديك صلاحية الوصول إلى هذه الصفحة.</p>
          </div>
        </div>`;
      return false;
    }
    return true;
  }

  // رسالة موحّدة لو حد حاول ينفّذ إجراء (إضافة/تعديل/مسح) من غير ما يكون معاه الصلاحية
  // (خط دفاع إضافي حتى لو الزرار مخفي، في حالة استدعاء الدالة مباشرة من الـ console مثلاً)
  function denyAction(message) {
    alert('⚠️ ' + (message || 'ليس لديك صلاحية تنفيذ هذا الإجراء.'));
  }

  global.PermGuard = {
    getPermissions,
    hasPage,
    canAdd,
    canEdit,
    canDelete,
    blockPageIfNoAccess,
    denyAction
  };

})(window);
