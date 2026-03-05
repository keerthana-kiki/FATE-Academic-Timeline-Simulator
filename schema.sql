-- FATE - Alternate Academic Timeline Simulator
-- Database schema for MySQL

CREATE DATABASE IF NOT EXISTS fate_db;
USE fate_db;

-- ---------------------------------------------------------------------------
-- Reference / lookup tables
-- ---------------------------------------------------------------------------

CREATE TABLE courses (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    category ENUM('CORE', 'ELECTIVE') NOT NULL,
    credits INT NOT NULL DEFAULT 3,
    domain ENUM('CS', 'MATH', 'ENGINEERING', 'ARTS', 'BUSINESS', 'SCIENCE') NOT NULL,
    INDEX idx_courses_domain (domain)
);

CREATE TABLE skills (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(80) NOT NULL,
    category ENUM('TECHNICAL', 'SOFT', 'DOMAIN') NOT NULL,
    INDEX idx_skills_category (category)
);

CREATE TABLE interests (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(80) NOT NULL
);

-- ---------------------------------------------------------------------------
-- Student and academic data
-- ---------------------------------------------------------------------------

CREATE TABLE students (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(120) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_students_email (email)
);

CREATE TABLE academic_snapshots (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    semester_label VARCHAR(20) NOT NULL,
    gpa DECIMAL(3,2) NOT NULL CHECK (gpa >= 0 AND gpa <= 4),
    total_credits INT NOT NULL DEFAULT 0,
    standing ENUM('DEANS_LIST', 'GOOD_STANDING', 'PROBATION', 'WARNING') NOT NULL DEFAULT 'GOOD_STANDING',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_snapshot_student_semester (student_id, semester_label),
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    INDEX idx_snapshots_student_semester (student_id, semester_label)
);

CREATE TABLE enrollments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    course_id INT NOT NULL,
    semester_label VARCHAR(20) NOT NULL,
    grade VARCHAR(5) NOT NULL,
    is_alternate BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE,
    INDEX idx_enrollments_student (student_id),
    INDEX idx_enrollments_semester (student_id, semester_label)
);

CREATE TABLE student_skills (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    skill_id INT NOT NULL,
    level TINYINT NOT NULL CHECK (level >= 1 AND level <= 5),
    semester_acquired VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_student_skill (student_id, skill_id),
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    FOREIGN KEY (skill_id) REFERENCES skills(id) ON DELETE CASCADE,
    INDEX idx_student_skills_student (student_id)
);

CREATE TABLE student_interests (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    interest_id INT NOT NULL,
    strength TINYINT NOT NULL CHECK (strength >= 1 AND strength <= 5),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_student_interest (student_id, interest_id),
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    FOREIGN KEY (interest_id) REFERENCES interests(id) ON DELETE CASCADE,
    INDEX idx_student_interests_student (student_id)
);

-- ---------------------------------------------------------------------------
-- Decision points and simulations
-- ---------------------------------------------------------------------------

CREATE TABLE decision_points (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    semester_label VARCHAR(20) NOT NULL,
    decision_type VARCHAR(40) NOT NULL,
    choice_detail TEXT,
    impact_weight TINYINT NOT NULL DEFAULT 3 CHECK (impact_weight >= 1 AND impact_weight <= 5),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    INDEX idx_decision_points_student (student_id)
);

CREATE TABLE simulations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    name VARCHAR(100) NOT NULL,
    scenario_note TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    INDEX idx_simulations_student (student_id)
);

CREATE TABLE simulation_decisions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    simulation_id INT NOT NULL,
    decision_point_id INT NOT NULL,
    alternate_choice TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_sim_decision (simulation_id, decision_point_id),
    FOREIGN KEY (simulation_id) REFERENCES simulations(id) ON DELETE CASCADE,
    FOREIGN KEY (decision_point_id) REFERENCES decision_points(id) ON DELETE CASCADE,
    INDEX idx_simulation_decisions_sim (simulation_id)
);

CREATE TABLE timeline_events (
    id INT AUTO_INCREMENT PRIMARY KEY,
    simulation_id INT NOT NULL,
    sequence_order INT NOT NULL,
    semester_label VARCHAR(20),
    event_type VARCHAR(30) NOT NULL,
    description TEXT,
    impact_score TINYINT DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (simulation_id) REFERENCES simulations(id) ON DELETE CASCADE,
    INDEX idx_timeline_events_sim (simulation_id),
    INDEX idx_timeline_events_order (simulation_id, sequence_order)
);

CREATE TABLE career_outcomes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    simulation_id INT NOT NULL,
    predicted_role VARCHAR(80) NOT NULL,
    industry VARCHAR(60) NOT NULL,
    confidence TINYINT NOT NULL CHECK (confidence >= 0 AND confidence <= 100),
    reasoning_text TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (simulation_id) REFERENCES simulations(id) ON DELETE CASCADE,
    INDEX idx_career_outcomes_sim (simulation_id)
);

-- ---------------------------------------------------------------------------
-- Seed data: sample courses, skills, interests
-- ---------------------------------------------------------------------------

INSERT INTO courses (code, name, category, credits, domain) VALUES
('CS101', 'Introduction to Programming', 'CORE', 4, 'CS'),
('CS201', 'Data Structures', 'CORE', 4, 'CS'),
('CS301', 'Algorithms', 'CORE', 3, 'CS'),
('MATH101', 'Calculus I', 'CORE', 4, 'MATH'),
('MATH201', 'Linear Algebra', 'CORE', 3, 'MATH'),
('ENG101', 'Engineering Fundamentals', 'CORE', 3, 'ENGINEERING'),
('BUSA101', 'Principles of Management', 'ELECTIVE', 3, 'BUSINESS'),
('BUSA201', 'Marketing', 'ELECTIVE', 3, 'BUSINESS'),
('SCI101', 'General Chemistry', 'CORE', 4, 'SCIENCE'),
('SCI201', 'Physics I', 'CORE', 4, 'SCIENCE'),
('ARTS101', 'Creative Writing', 'ELECTIVE', 3, 'ARTS'),
('CS401', 'Machine Learning', 'ELECTIVE', 3, 'CS'),
('MATH301', 'Probability & Statistics', 'CORE', 3, 'MATH');

INSERT INTO skills (name, category) VALUES
('Java Programming', 'TECHNICAL'),
('Python', 'TECHNICAL'),
('SQL', 'TECHNICAL'),
('Data Analysis', 'TECHNICAL'),
('Communication', 'SOFT'),
('Teamwork', 'SOFT'),
('Problem Solving', 'SOFT'),
('Research', 'DOMAIN'),
('Project Management', 'DOMAIN');

INSERT INTO interests (name) VALUES
('Machine Learning'),
('Software Development'),
('Data Science'),
('Research'),
('Writing'),
('Business Strategy'),
('Consulting'),
('Quantitative Finance');
