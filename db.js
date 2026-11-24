// db.js - في البداية
const sql = require('mssql');
require('dotenv').config();

console.log('📄 DB_SERVER from .env:', process.env.DB_SERVER);
console.log('📄 DB_PASSWORD from .env:', process.env.DB_PASSWORD);

// إعدادات الاتصال
const config = {
    server: process.env.DB_SERVER || 'LAPTOP-6TU4IDUS\ASDCO',
    database: process.env.DB_NAME || 'law_project',
    user: process.env.DB_USER || 'sa',
    password: process.env.DB_PASSWORD || '1',
    options: {
        encrypt: false,
        trustServerCertificate: true,
        enableArithAbort: true
        // تأكد مفيش instanceName
    },
    pool: {
        max: 10,
        min: 0,
        idleTimeoutMillis: 60000
    },
    // ⏱️ زيادة مهلة تنفيذ الاستعلام (كانت 15 ثانية افتراضيًا وده اللي بيسبب ETIMEOUT)
    requestTimeout: 300000, // 300 ثانية - مهلة أطول للبيانات الكبيرة
    connectionTimeout: 30000 // مهلة الاتصال بالسيرفر نفسه (منفصلة عن requestTimeout)
};

console.log(' Final Config:', {
    server: config.server,
    database: config.database,
    user: config.user,
    // مش هنطبع الباسورد عشان الأمان
});

// باقي الكود كما هو...
// إذا كنتِ تستخدمين مصادقة Windows
if (process.env.DB_TRUSTED_CONNECTION === 'true') {
    delete config.user;
    delete config.password;
    config.options.trustedConnection = true;
}

// إنشاء Pool Connection
const pool = new sql.ConnectionPool(config);
const poolConnect = pool.connect();

// دالة لتنفيذ الاستعلامات
async function query(sqlQuery, params = []) {
    try {
        await poolConnect;
        const request = pool.request();
        
        // إضافة المعاملات
        params.forEach((param, index) => {
            request.input(`p${index}`, param);
        });
        
        const result = await request.query(sqlQuery);
        return result.recordset;
    } catch (error) {
        console.error('❌ خطأ في الاستعلام:', error);
        throw error;
    }
}

// دالة لتنفيذ استعلام واحد (INSERT, UPDATE, DELETE)
async function execute(sqlQuery, params = []) {
    try {
        await poolConnect;
        const request = pool.request();
        
        params.forEach((param, index) => {
            request.input(`p${index}`, param);
        });
        
        const result = await request.query(sqlQuery);
        return result;
    } catch (error) {
        console.error('❌ خطأ في التنفيذ:', error);
        throw error;
    }
}

// دالة للحصول على آخر ID
async function getLastInsertId() {
    const result = await query("SELECT SCOPE_IDENTITY() AS Id");
    return result[0]?.Id || null;
}

module.exports = {
    pool,
    poolConnect,
    query,
    execute,
    getLastInsertId,
    sql
};