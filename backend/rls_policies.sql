-- Row Level Security (RLS) policies skeleton for Supabase Phase 2+
-- Fulfills safety requirements and privacy requirements (NFR-03)

-- Ensure table uses RLS
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE health_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE unlock_requests ENABLE ROW LEVEL SECURITY;

-- Students can only read their own health profiles
CREATE POLICY "Students can view own health profile" ON health_profiles
  FOR SELECT USING (auth.uid() = student_id);

-- Students can only update their own health profiles
CREATE POLICY "Students can update own health profile" ON health_profiles
  FOR UPDATE USING (auth.uid() = student_id);

-- Teachers can view health profiles of students assigned to them
CREATE POLICY "Teachers can view assigned students profiles" ON health_profiles
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM teacher_students
      WHERE teacher_students.teacher_id = auth.uid()
      AND teacher_students.student_id = health_profiles.student_id
    )
  );

-- Unlock requests: Students can insert their own requests
CREATE POLICY "Students can insert unlock requests" ON unlock_requests
  FOR INSERT WITH CHECK (auth.uid() = student_id);

-- Unlock requests: Students can read their own requests
CREATE POLICY "Students can view own unlock requests" ON unlock_requests
  FOR SELECT USING (auth.uid() = student_id);

-- Unlock requests: Teachers can view and update requests of their assigned students
CREATE POLICY "Teachers can manage assigned students requests" ON unlock_requests
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM teacher_students
      WHERE teacher_students.teacher_id = auth.uid()
      AND teacher_students.student_id = unlock_requests.student_id
    )
  );
