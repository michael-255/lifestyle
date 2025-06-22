--
-- ENUMS
--
CREATE TYPE exercise_type AS ENUM (
    'Checklist',
    'Cardio',
    'Weight',
    'Sided Weight',
    'Climbing'
);

COMMENT ON TYPE exercise_type IS 'Types of exercises supported in the application.';

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
    'Saturday'
);

COMMENT ON TYPE recurrence_type IS 'Types of recurrences supported in the application.';

--
-- Template Tables
--
CREATE TABLE exercises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    type exercise_type NOT NULL,
    default_sets INTEGER DEFAULT 1,
    rest_timer INTEGER,
    is_locked BOOLEAN DEFAULT FALSE
)

COMMENT ON TABLE exercises IS 'Stores exercise templates for each user.';
COMMENT ON COLUMN exercises.id IS 'Primary key for the exercise.';
COMMENT ON COLUMN exercises.user_id IS 'The user who owns this exercise.';
COMMENT ON COLUMN exercises.created_at IS 'Timestamp when the exercise was created.';
COMMENT ON COLUMN exercises.name IS 'Name of the exercise.';
COMMENT ON COLUMN exercises.description IS 'Optional description of the exercise.';
COMMENT ON COLUMN exercises.type IS 'Type of exercise (e.g., Cardio, Weight, etc.).';
COMMENT ON COLUMN exercises.default_sets IS 'Default number of sets for this exercise.';
COMMENT ON COLUMN exercises.rest_timer IS 'Default rest timer (in seconds) between sets.';
COMMENT ON COLUMN exercises.is_locked IS 'Indicates if the exercise is locked from editing.';

CREATE TABLE workouts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    is_locked BOOLEAN DEFAULT FALSE
)

COMMENT ON TABLE workouts IS 'Stores workout templates for each user.';
COMMENT ON COLUMN workouts.id IS 'Primary key for the workout.';
COMMENT ON COLUMN workouts.user_id IS 'The user who owns this workout.';
COMMENT ON COLUMN workouts.created_at IS 'Timestamp when the workout was created.';
COMMENT ON COLUMN workouts.name IS 'Name of the workout.';
COMMENT ON COLUMN workouts.description IS 'Optional description of the workout.';
COMMENT ON COLUMN workouts.is_locked IS 'Indicates if the workout is locked from editing.';

CREATE TABLE exercise_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL,
    note TEXT,
    data JSONB, -- For all potential exercise data
    is_locked BOOLEAN DEFAULT FALSE
)

COMMENT ON TABLE exercise_results IS 'Stores results for individual exercises performed by users.';
COMMENT ON COLUMN exercise_results.id IS 'Primary key for the exercise result.';
COMMENT ON COLUMN exercise_results.user_id IS 'The user who performed the exercise.';
COMMENT ON COLUMN exercise_results.created_at IS 'Timestamp when the exercise was performed.';
COMMENT ON COLUMN exercise_results.note IS 'Optional note about the exercise result.';
COMMENT ON COLUMN exercise_results.data IS 'JSONB data for all potential exercise result details.';
COMMENT ON COLUMN exercise_results.is_locked IS 'Indicates if the result is locked from editing.';

CREATE TABLE workout_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL,
    finished_at TIMESTAMPTZ,
    note TEXT,
    is_locked BOOLEAN DEFAULT FALSE
)

COMMENT ON TABLE workout_results IS 'Stores results for completed workouts by users.';
COMMENT ON COLUMN workout_results.id IS 'Primary key for the workout result.';
COMMENT ON COLUMN workout_results.user_id IS 'The user who performed the workout.';
COMMENT ON COLUMN workout_results.created_at IS 'Timestamp when the workout was started.';
COMMENT ON COLUMN workout_results.finished_at IS 'Timestamp when the workout was finished.';
COMMENT ON COLUMN workout_results.note IS 'Optional note about the workout result.';
COMMENT ON COLUMN workout_results.is_locked IS 'Indicates if the result is locked from editing.';

--
-- Join Tables
--
CREATE TABLE workout_exercises (
    workout_id UUID NOT NULL REFERENCES workouts(id) ON DELETE CASCADE,
    exercise_id UUID NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
    position INTEGER NOT NULL,
    PRIMARY KEY (workout_id, exercise_id)
)

COMMENT ON TABLE workout_exercises IS 'Join table linking exercises to workouts, with position.';
COMMENT ON COLUMN workout_exercises.workout_id IS 'The workout this exercise belongs to.';
COMMENT ON COLUMN workout_exercises.exercise_id IS 'The exercise included in the workout.';
COMMENT ON COLUMN workout_exercises.position IS 'Order of the exercise within the workout.';

CREATE TABLE workout_result_exercise_results (
    workout_result_id UUID NOT NULL REFERENCES workout_results(id) ON DELETE CASCADE,
    exercise_result_id UUID NOT NULL REFERENCES exercise_results(id) ON DELETE CASCADE,
    position INTEGER NOT NULL,
    PRIMARY KEY (workout_result_id, exercise_result_id)
)

COMMENT ON TABLE workout_result_exercise_results IS 'Join table linking exercise results to workout results, with position.';
COMMENT ON COLUMN workout_result_exercise_results.workout_result_id IS 'The workout result this exercise result belongs to.';
COMMENT ON COLUMN workout_result_exercise_results.exercise_result_id IS 'The exercise result included in the workout result.';
COMMENT ON COLUMN workout_result_exercise_results.position IS 'Order of the exercise result within the workout result.';

CREATE TABLE user_workout_recurrence (
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    workout_id UUID NOT NULL REFERENCES workouts(id) ON DELETE CASCADE,
    recurrence recurrence_type NOT NULL,
    PRIMARY KEY (user_id, recurrence, workout_id)
);

COMMENT ON TABLE user_workout_recurrence IS 'Tracks which workouts recur for a user and their recurrence pattern.';
COMMENT ON COLUMN user_workout_recurrence.user_id IS 'The user who owns the recurrence.';
COMMENT ON COLUMN user_workout_recurrence.workout_id IS 'The workout that recurs.';
COMMENT ON COLUMN user_workout_recurrence.recurrence IS 'The recurrence pattern (e.g., Daily, Weekly, etc.).';

--
-- Functions
--
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

COMMENT ON FUNCTION rebalance_workout_exercise_positions IS 'Rebalances the positions of exercises in a workout after any insert, update, or delete operation.';

CREATE FUNCTION rebalance_workout_result_exercise_positions()
RETURNS TRIGGER AS $$
BEGIN
    WITH ordered AS (
        SELECT
            workout_result_id,
            exercise_result_id,
            ROW_NUMBER() OVER (
                PARTITION BY workout_result_id
                ORDER BY position
            ) AS new_position
        FROM workout_result_exercise_results
    )
    UPDATE workout_result_exercise_results wre
    SET position = ordered.new_position
    FROM ordered
    WHERE wre.workout_result_id = ordered.workout_result_id
      AND wre.exercise_result_id = ordered.exercise_result_id;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION rebalance_workout_result_exercise_positions IS 'Rebalances the positions of exercise results in a workout result after any insert, update, or delete operation.';

--
-- Triggers
--
CREATE TRIGGER workout_exercises_rebalance_positions
AFTER INSERT OR UPDATE OR DELETE ON workout_exercises
FOR EACH STATEMENT
EXECUTE FUNCTION rebalance_workout_exercise_positions();

CREATE TRIGGER workout_result_exercise_results_rebalance_positions
AFTER INSERT OR UPDATE OR DELETE ON workout_result_exercise_results
FOR EACH STATEMENT
EXECUTE FUNCTION rebalance_workout_result_exercise_positions();

--
-- RLS Policies
--
ALTER TABLE exercises ENABLE ROW LEVEL SECURITY;
CREATE POLICY authenticated_select_exercises ON exercises
  FOR SELECT USING (auth.uid() IS NOT NULL AND user_id = auth.uid());
CREATE POLICY authenticated_insert_exercises ON exercises
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL AND user_id = auth.uid());
CREATE POLICY authenticated_update_exercises ON exercises
  FOR UPDATE USING (auth.uid() IS NOT NULL AND user_id = auth.uid());
CREATE POLICY authenticated_delete_exercises ON exercises
  FOR DELETE USING (auth.uid() IS NOT NULL AND user_id = auth.uid());

ALTER TABLE workouts ENABLE ROW LEVEL SECURITY;
CREATE POLICY authenticated_select_workouts ON workouts
  FOR SELECT USING (auth.uid() IS NOT NULL AND user_id = auth.uid());
CREATE POLICY authenticated_insert_workouts ON workouts
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL AND user_id = auth.uid());
CREATE POLICY authenticated_update_workouts ON workouts
  FOR UPDATE USING (auth.uid() IS NOT NULL AND user_id = auth.uid());
CREATE POLICY authenticated_delete_workouts ON workouts
  FOR DELETE USING (auth.uid() IS NOT NULL AND user_id = auth.uid());

ALTER TABLE exercise_results ENABLE ROW LEVEL SECURITY;
CREATE POLICY authenticated_select_exercise_results ON exercise_results
  FOR SELECT USING (auth.uid() IS NOT NULL AND user_id = auth.uid());
CREATE POLICY authenticated_insert_exercise_results ON exercise_results
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL AND user_id = auth.uid());
CREATE POLICY authenticated_update_exercise_results ON exercise_results
  FOR UPDATE USING (auth.uid() IS NOT NULL AND user_id = auth.uid());
CREATE POLICY authenticated_delete_exercise_results ON exercise_results
  FOR DELETE USING (auth.uid() IS NOT NULL AND user_id = auth.uid());

ALTER TABLE workout_results ENABLE ROW LEVEL SECURITY;
CREATE POLICY authenticated_select_workout_results ON workout_results
  FOR SELECT USING (auth.uid() IS NOT NULL AND user_id = auth.uid());
CREATE POLICY authenticated_insert_workout_results ON workout_results
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL AND user_id = auth.uid());
CREATE POLICY authenticated_update_workout_results ON workout_results
  FOR UPDATE USING (auth.uid() IS NOT NULL AND user_id = auth.uid());
CREATE POLICY authenticated_delete_workout_results ON workout_results
  FOR DELETE USING (auth.uid() IS NOT NULL AND user_id = auth.uid());

ALTER TABLE user_workout_recurrence ENABLE ROW LEVEL SECURITY;
CREATE POLICY authenticated_select_user_workout_recurrence ON user_workout_recurrence
  FOR SELECT USING (auth.uid() IS NOT NULL AND user_id = auth.uid());
CREATE POLICY authenticated_insert_user_workout_recurrence ON user_workout_recurrence
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL AND user_id = auth.uid());
CREATE POLICY authenticated_update_user_workout_recurrence ON user_workout_recurrence
  FOR UPDATE USING (auth.uid() IS NOT NULL AND user_id = auth.uid());
CREATE POLICY authenticated_delete_user_workout_recurrence ON user_workout_recurrence
  FOR DELETE USING (auth.uid() IS NOT NULL AND user_id = auth.uid());

ALTER TABLE workout_exercises ENABLE ROW LEVEL SECURITY;
CREATE POLICY authenticated_select_workout_exercises ON workout_exercises
  FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY authenticated_insert_workout_exercises ON workout_exercises
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY authenticated_update_workout_exercises ON workout_exercises
  FOR UPDATE USING (auth.uid() IS NOT NULL);
CREATE POLICY authenticated_delete_workout_exercises ON workout_exercises
  FOR DELETE USING (auth.uid() IS NOT NULL);

ALTER TABLE workout_result_exercise_results ENABLE ROW LEVEL SECURITY;
CREATE POLICY authenticated_select_workout_result_exercise_results ON workout_result_exercise_results
  FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY authenticated_insert_workout_result_exercise_results ON workout_result_exercise_results
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY authenticated_update_workout_result_exercise_results ON workout_result_exercise_results
  FOR UPDATE USING (auth.uid() IS NOT NULL);
CREATE POLICY authenticated_delete_workout_result_exercise_results ON workout_result_exercise_results
  FOR DELETE USING (auth.uid() IS NOT NULL);
