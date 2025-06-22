-- ENUMS
CREATE TYPE exercise_type AS ENUM (
    'Checklist',
    'Cardio',
    'Weight',
    'Sided Weight',
    'Climbing',
);

CREATE TYPE recurrence_type AS ENUM (
    -- By Time
    'Daily',
    'Weekly',
    'Monthly',
    -- By Weekday
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
);

-- Template Tables
CREATE TABLE exercises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    type exercise_type NOT NULL,
    default_sets INTEGER DEFAULT 1,
    rest_timer INTEGER,
    is_locked BOOLEAN DEFAULT FALSE,
)

CREATE TABLE workouts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    is_locked BOOLEAN DEFAULT FALSE,
)

-- Result Tables
CREATE TABLE exercise_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL,
    note TEXT,
    data JSONB, -- For all potential exercise data
    is_locked BOOLEAN DEFAULT FALSE,
)

CREATE TABLE workout_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL,
    finished_at TIMESTAMPTZ,
    note TEXT,
    is_locked BOOLEAN DEFAULT FALSE,
)

-- Join Tables
CREATE TABLE workout_exercises (
    workout_id UUID NOT NULL REFERENCES workouts(id) ON DELETE CASCADE,
    exercise_id UUID NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
    PRIMARY KEY (workout_id, exercise_id)
    position INTEGER NOT NULL,
)

CREATE TABLE workout_result_exercise_results (
    workout_result_id UUID NOT NULL REFERENCES workout_results(id) ON DELETE CASCADE,
    exercise_result_id UUID NOT NULL REFERENCES exercise_results(id) ON DELETE CASCADE,
    PRIMARY KEY (workout_result_id, exercise_result_id)
    position INTEGER NOT NULL,
)

CREATE TABLE user_workout_recurrence (
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    workout_id UUID NOT NULL REFERENCES workouts(id) ON DELETE CASCADE,
    recurrence recurrence_type NOT NULL,
    PRIMARY KEY (user_id, recurrence, workout_id)
);

-- Functions
CREATE FUNCTION rebalance_workout_exercise_positions()
RETURNS TRIGGER AS $$
BEGIN
    WITH ordered AS (
        SELECT
            workout_id,
            exercise_id,
            ROW_NUMBER() OVER (
                PARTITION BY workout_id
                ORDER BY position
            ) AS new_position
        FROM workout_exercises
    )
    UPDATE workout_exercises we
    SET position = ordered.new_position
    FROM ordered
    WHERE we.workout_id = ordered.workout_id
      AND we.exercise_id = ordered.exercise_id;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER workout_exercises_rebalance_positions
AFTER INSERT OR UPDATE OR DELETE ON workout_exercises
FOR EACH STATEMENT
EXECUTE FUNCTION rebalance_workout_exercise_positions();
