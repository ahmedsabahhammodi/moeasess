-- ============================================================
-- 🏫 بوابة المؤسسين - سكريبت إنشاء الجداول على Supabase الجديدة
-- يُشغَّل مرة واحدة فقط في SQL Editor بـ Supabase Dashboard
-- ============================================================

-- 1. جدول تسجيل المدارس
CREATE TABLE IF NOT EXISTS schools_registry (
    id BIGSERIAL PRIMARY KEY,
    school_code TEXT UNIQUE NOT NULL,
    school_name TEXT NOT NULL DEFAULT 'مدرسة غير مسماة',
    director_name TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    last_sync_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);

-- 2. جدول مصادقة المؤسسين
CREATE TABLE IF NOT EXISTS founders_auth (
    id BIGSERIAL PRIMARY KEY,
    school_code TEXT NOT NULL REFERENCES schools_registry(school_code) ON DELETE CASCADE,
    username TEXT NOT NULL,
    password_hash TEXT NOT NULL,
    full_name TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(school_code, username)
);

-- 3. جدول الطلاب (معلومات أساسية)
CREATE TABLE IF NOT EXISTS students (
    id BIGSERIAL PRIMARY KEY,
    school_code TEXT NOT NULL,
    local_id BIGINT NOT NULL,
    name TEXT,
    class_name TEXT,
    division_name TEXT,
    student_status TEXT DEFAULT 'active',
    synced_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(school_code, local_id)
);

-- 4. رسوم الصفوف
CREATE TABLE IF NOT EXISTS class_fees (
    id BIGSERIAL PRIMARY KEY,
    school_code TEXT NOT NULL,
    local_id BIGINT NOT NULL,
    class_name TEXT,
    academic_year TEXT,
    total_fee NUMERIC(10,2) NOT NULL DEFAULT 0,
    default_installments INTEGER DEFAULT 1,
    synced_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(school_code, local_id)
);

-- 5. خطط الدفع
CREATE TABLE IF NOT EXISTS student_payment_plans (
    id BIGSERIAL PRIMARY KEY,
    school_code TEXT NOT NULL,
    local_id BIGINT NOT NULL,
    student_local_id BIGINT,
    class_fee_local_id BIGINT,
    payment_type TEXT,
    total_amount_due NUMERIC(10,2) DEFAULT 0,
    number_of_installments INTEGER DEFAULT 1,
    down_payment_amount NUMERIC(10,2) DEFAULT 0,
    status TEXT DEFAULT 'pending_setup',
    total_paid_so_far NUMERIC(10,2) DEFAULT 0,
    discount_amount NUMERIC(10,2) DEFAULT 0,
    is_withdrawn BOOLEAN DEFAULT FALSE,
    notes TEXT,
    created_at TIMESTAMP,
    synced_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(school_code, local_id)
);

-- 6. الأقساط
CREATE TABLE IF NOT EXISTS student_installments (
    id BIGSERIAL PRIMARY KEY,
    school_code TEXT NOT NULL,
    local_id BIGINT NOT NULL,
    payment_plan_local_id BIGINT,
    installment_number INTEGER,
    due_date DATE,
    amount_due NUMERIC(10,2) DEFAULT 0,
    amount_paid NUMERIC(10,2) DEFAULT 0,
    payment_date DATE,
    status TEXT DEFAULT 'pending',
    payment_method TEXT,
    transaction_reference TEXT,
    receipt_code TEXT,
    notes TEXT,
    synced_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(school_code, local_id)
);

-- 7. الاشتراكات الشهرية
CREATE TABLE IF NOT EXISTS monthly_activations (
    id BIGSERIAL PRIMARY KEY,
    school_code TEXT NOT NULL,
    local_id BIGINT NOT NULL,
    student_local_id BIGINT,
    student_name TEXT,
    class_name TEXT,
    activation_date DATE,
    expiry_date DATE,
    amount_paid NUMERIC(10,2) DEFAULT 0,
    total_amount_due NUMERIC(10,2) DEFAULT 0,
    payment_status TEXT DEFAULT 'unpaid',
    months INTEGER DEFAULT 1,
    activation_type TEXT DEFAULT 'monthly',
    receipt_code TEXT,
    deleted_at TIMESTAMP,
    synced_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(school_code, local_id)
);

-- 8. حركات الصندوق (كشف الصندوق)
CREATE TABLE IF NOT EXISTS cash_box_transactions (
    id BIGSERIAL PRIMARY KEY,
    school_code TEXT NOT NULL,
    local_id BIGINT NOT NULL,
    transaction_date TIMESTAMP,
    transaction_type TEXT NOT NULL,
    source_type TEXT,
    source_id BIGINT,
    source_reference TEXT,
    amount NUMERIC(12,2) NOT NULL DEFAULT 0,
    description TEXT,
    student_name TEXT,
    student_class TEXT,
    created_at TIMESTAMP,
    synced_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(school_code, local_id)
);

-- 9. المصروفات
CREATE TABLE IF NOT EXISTS expenses (
    id BIGSERIAL PRIMARY KEY,
    school_code TEXT NOT NULL,
    local_id BIGINT NOT NULL,
    expense_date DATE,
    description TEXT,
    amount NUMERIC(12,2) NOT NULL DEFAULT 0,
    is_recurring BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP,
    synced_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(school_code, local_id)
);

-- 10. رواتب المعلمين (مجاميع فقط بدون أسماء)
CREATE TABLE IF NOT EXISTS teacher_salaries (
    id BIGSERIAL PRIMARY KEY,
    school_code TEXT NOT NULL,
    local_id BIGINT NOT NULL,
    month INTEGER NOT NULL,
    year INTEGER NOT NULL,
    base_salary NUMERIC(10,2) DEFAULT 0,
    deduction_amount NUMERIC(10,2) DEFAULT 0,
    final_amount_paid NUMERIC(10,2) DEFAULT 0,
    is_cancelled BOOLEAN DEFAULT FALSE,
    synced_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(school_code, local_id)
);

-- ============================================================
-- فهارس للأداء
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_founders_auth_school ON founders_auth(school_code);
CREATE INDEX IF NOT EXISTS idx_students_school ON students(school_code);
CREATE INDEX IF NOT EXISTS idx_payment_plans_school ON student_payment_plans(school_code);
CREATE INDEX IF NOT EXISTS idx_installments_school ON student_installments(school_code);
CREATE INDEX IF NOT EXISTS idx_cash_box_school ON cash_box_transactions(school_code);
CREATE INDEX IF NOT EXISTS idx_cash_box_date ON cash_box_transactions(school_code, transaction_date);
CREATE INDEX IF NOT EXISTS idx_expenses_school ON expenses(school_code);
CREATE INDEX IF NOT EXISTS idx_salaries_school ON teacher_salaries(school_code);
CREATE INDEX IF NOT EXISTS idx_activations_school ON monthly_activations(school_code);

-- ============================================================
-- تفعيل Row Level Security
-- ============================================================
ALTER TABLE schools_registry ENABLE ROW LEVEL SECURITY;
ALTER TABLE founders_auth ENABLE ROW LEVEL SECURITY;
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE class_fees ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_payment_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_installments ENABLE ROW LEVEL SECURITY;
ALTER TABLE monthly_activations ENABLE ROW LEVEL SECURITY;
ALTER TABLE cash_box_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE teacher_salaries ENABLE ROW LEVEL SECURITY;

-- سياسات القراءة العامة (للبوابة)
DROP POLICY IF EXISTS "public_read_schools" ON schools_registry;
CREATE POLICY "public_read_schools" ON schools_registry FOR SELECT USING (true);

DROP POLICY IF EXISTS "public_read_founders" ON founders_auth;
CREATE POLICY "public_read_founders" ON founders_auth FOR SELECT USING (true);

DROP POLICY IF EXISTS "public_read_students" ON students;
CREATE POLICY "public_read_students" ON students FOR SELECT USING (true);

DROP POLICY IF EXISTS "public_read_class_fees" ON class_fees;
CREATE POLICY "public_read_class_fees" ON class_fees FOR SELECT USING (true);

DROP POLICY IF EXISTS "public_read_plans" ON student_payment_plans;
CREATE POLICY "public_read_plans" ON student_payment_plans FOR SELECT USING (true);

DROP POLICY IF EXISTS "public_read_installments" ON student_installments;
CREATE POLICY "public_read_installments" ON student_installments FOR SELECT USING (true);

DROP POLICY IF EXISTS "public_read_activations" ON monthly_activations;
CREATE POLICY "public_read_activations" ON monthly_activations FOR SELECT USING (true);

DROP POLICY IF EXISTS "public_read_cashbox" ON cash_box_transactions;
CREATE POLICY "public_read_cashbox" ON cash_box_transactions FOR SELECT USING (true);

DROP POLICY IF EXISTS "public_read_expenses" ON expenses;
CREATE POLICY "public_read_expenses" ON expenses FOR SELECT USING (true);

DROP POLICY IF EXISTS "public_read_salaries" ON teacher_salaries;
CREATE POLICY "public_read_salaries" ON teacher_salaries FOR SELECT USING (true);

-- سياسات الكتابة (للسيرفر فقط عبر الاتصال المباشر)
DROP POLICY IF EXISTS "service_write_schools" ON schools_registry;
CREATE POLICY "service_write_schools" ON schools_registry FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "service_write_founders" ON founders_auth;
CREATE POLICY "service_write_founders" ON founders_auth FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "service_write_students" ON students;
CREATE POLICY "service_write_students" ON students FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "service_write_class_fees" ON class_fees;
CREATE POLICY "service_write_class_fees" ON class_fees FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "service_write_plans" ON student_payment_plans;
CREATE POLICY "service_write_plans" ON student_payment_plans FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "service_write_installments" ON student_installments;
CREATE POLICY "service_write_installments" ON student_installments FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "service_write_activations" ON monthly_activations;
CREATE POLICY "service_write_activations" ON monthly_activations FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "service_write_cashbox" ON cash_box_transactions;
CREATE POLICY "service_write_cashbox" ON cash_box_transactions FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "service_write_expenses" ON expenses;
CREATE POLICY "service_write_expenses" ON expenses FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "service_write_salaries" ON teacher_salaries;
CREATE POLICY "service_write_salaries" ON teacher_salaries FOR ALL USING (true) WITH CHECK (true);

-- ============================================================
-- ✅ اكتمل الإعداد!
-- ============================================================
